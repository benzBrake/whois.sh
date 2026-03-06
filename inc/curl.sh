#!/usr/bin/env bash
# curl 请求模块
# 负责管理 CA 证书和执行安全的 HTTPS 请求

# 加载依赖
WHOIS_WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$WHOIS_WORKING_DIR/inc/functions.sh"

# ============ 配置常量 ============

# CA 证书配置
__CURL_CERT_DIR="${WHOIS_WORKING_DIR}/data"
__CURL_CERT_FILE="${__CURL_CERT_DIR}/cacert.pem"
__CURL_CERT_VERSION_FILE="${__CURL_CERT_DIR}/cacert.version"
__CURL_CERT_CHECK_FILE="${__CURL_CERT_DIR}/cacert.check"  # 上次检查时间
__CURL_CERT_EXPIRE_DAYS=${WHOIS_CERT_EXPIRE_DAYS:-30}     # 证书过期天数（可通过环境变量配置）
__CURL_CERT_CHECK_INTERVAL=${WHOIS_CERT_CHECK_INTERVAL:-7} # 检查间隔天数（默认 7 天）

# CA 证书下载源
__CURL_CERT_URL="https://curl.se/ca/cacert.pem"
__CURL_CERT_HASH_URL="https://curl.se/ca/cacert.pem.sha256"

# ============ 证书管理函数 ============

# 检查是否需要进行证书检查
# 返回 0 表示需要检查，返回 1 表示不需要检查
__cert_check_needed() {
    local check_file="$__CURL_CERT_CHECK_FILE"
    local check_interval="$__CURL_CERT_CHECK_INTERVAL"

    # 如果检查记录文件不存在，需要检查
    if [[ ! -f "$check_file" ]]; then
        return 0
    fi

    # 读取上次检查时间
    local last_check_time
    last_check_time=$(cat "$check_file" 2>/dev/null)

    # 如果无法读取或为空，需要检查
    if [[ -z "$last_check_time" ]] || ! [[ "$last_check_time" =~ ^[0-9]+$ ]]; then
        return 0
    fi

    # 获取当前时间
    local current_time
    current_time=$(date +%s)

    # 计算距离上次检查的天数
    local days_since_check
    days_since_check=$(( (current_time - last_check_time) / 86400 ))

    # 如果超过检查间隔，需要检查
    if [[ $days_since_check -ge $check_interval ]]; then
        return 0
    fi

    return 1
}

# 更新检查时间记录
__cert_update_check_time() {
    local check_file="$__CURL_CERT_CHECK_FILE"
    mkdir -p "$(dirname "$check_file")"
    date +%s > "$check_file"
}

# 获取证书文件修改时间（Unix 时间戳）
__cert_get_mtime() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # macOS 和 Linux 兼容的获取修改时间方式
        if stat -c "%Y" "$file" 2>/dev/null; then
            # Linux (GNU stat)
            return 0
        elif stat -f "%m" "$file" 2>/dev/null; then
            # macOS (BSD stat)
            return 0
        else
            # 备选方案：使用 ls
            ls -l "$file" | awk '{print $6, $7, $8}' | date -f "%b %d %H:%M" +%s 2>/dev/null
            return 0
        fi
    fi
    return 1
}

# 检查证书是否需要更新
__cert_needs_update() {
    local cert_file="$1"
    local expire_days="$2"

    # 如果证书文件不存在，需要更新
    if [[ ! -f "$cert_file" ]]; then
        return 0
    fi

    # 检查文件是否为空
    if [[ ! -s "$cert_file" ]]; then
        return 0
    fi

    # 获取当前时间和证书修改时间
    local current_time
    local cert_time

    current_time=$(date +%s)
    cert_time=$(__cert_get_mtime "$cert_file")

    # 如果无法获取修改时间，需要更新
    if [[ -z "$cert_time" ]]; then
        return 0
    fi

    # 计算证书年龄（天数）
    local cert_age_days
    cert_age_days=$(( (current_time - cert_time) / 86400 ))

    # 如果证书超过过期天数，需要更新
    if [[ $cert_age_days -ge $expire_days ]]; then
        return 0
    fi

    return 1
}

# 下载 CA 证书
__cert_download() {
    local url="$1"
    local output="$2"
    local temp_output="${output}.tmp"

    # 创建临时目录
    mkdir -p "$(dirname "$temp_output")"

    # 使用 curl 下载证书
    # 如果系统 curl 不可用或没有证书，尝试使用不验证证书的方式
    local curl_cmd="curl"
    local curl_args=(-s -L)

    # 检查是否需要跳过 SSL 验证（仅用于下载 CA 证书本身）
    if [[ ! -f "$output" ]]; then
        curl_args+=(-k)
    fi

    curl_args+=("$url")
    curl_args+=(-o "$temp_output")

    if ! "$curl_cmd" "${curl_args[@]}" 2>/dev/null; then
        # 备选方案：使用 wget
        if command -v wget &>/dev/null; then
            wget -q -O "$temp_output" "$url" 2>/dev/null || return 1
        else
            return 1
        fi
    fi

    # 验证下载的文件
    if [[ ! -s "$temp_output" ]]; then
        rm -f "$temp_output"
        return 1
    fi

    # 验证是否为有效的 PEM 格式（简单检查）
    if ! grep -q "BEGIN CERTIFICATE" "$temp_output" 2>/dev/null; then
        rm -f "$temp_output"
        return 1
    fi

    # 原子替换
    mv "$temp_output" "$output"

    return 0
}

# 更新 CA 证书
__cert_update() {
    local force="${1:-false}"

    # 强制更新时跳过检查间隔判断
    if [[ "$force" != "true" ]]; then
        # 检查是否需要进行证书检查（基于检查间隔）
        if ! __cert_check_needed; then
            # 未超过检查间隔，跳过
            return 0
        fi

        # 检查证书是否需要更新（基于过期时间）
        if ! __cert_needs_update "$__CURL_CERT_FILE" "$__CURL_CERT_EXPIRE_DAYS"; then
            # 证书未过期，仅更新检查时间
            __cert_update_check_time
            return 0
        fi
    fi

    # 创建证书目录
    mkdir -p "$__CURL_CERT_DIR"

    # 下载证书
    if ! __cert_download "$__CURL_CERT_URL" "$__CURL_CERT_FILE"; then
        echo "Warning: Failed to download CA certificate from $__CURL_CERT_URL" >&2
        # 如果证书文件存在且不为空，继续使用旧证书
        if [[ -f "$__CURL_CERT_FILE" && -s "$__CURL_CERT_FILE" ]]; then
            __cert_update_check_time
            return 0
        fi
        return 1
    fi

    # 记录更新时间和检查时间
    date +%s > "$__CURL_CERT_VERSION_FILE"
    __cert_update_check_time

    return 0
}

# ============ curl 请求函数 ============

# 执行安全的 HTTPS 请求
# 参数:
#   $1 - URL
#   $2 - 额外的 curl 参数（可选）
# 返回: 响应内容
__curl_get() {
    local url="$1"
    shift
    local extra_args=("$@")

    # 确保 CA 证书可用
    if ! __cert_update; then
        echo "Error: CA certificate not available and download failed." >&2
        return 1
    fi

    # 构建 curl 命令
    local curl_args=(
        -s
        --cacert "$__CURL_CERT_FILE"
        --connect-timeout 10
        --max-time 30
    )

    # 添加额外参数
    [[ ${#extra_args[@]} -gt 0 ]] && curl_args+=("${extra_args[@]}")

    # 添加 URL
    curl_args+=("$url")

    # 执行请求
    curl "${curl_args[@]}"
}

# 执行 HTTP POST 请求
# 参数:
#   $1 - URL
#   $2 - POST 数据
#   $3 - Content-Type (可选，默认 application/x-www-form-urlencoded)
__curl_post() {
    local url="$1"
    local data="$2"
    local content_type="${3:-application/x-www-form-urlencoded}"

    __curl_get "$url" \
        -X POST \
        -H "Content-Type: $content_type" \
        -d "$data"
}

# ============ 公开 API ============

# 手动更新证书（供外部调用）
curl_update_certs() {
    echo "Updating CA certificates..." >&2
    if __cert_update "true"; then
        echo "CA certificates updated successfully." >&2
        return 0
    else
        echo "Failed to update CA certificates." >&2
        return 1
    fi
}

# 检查证书状态
curl_check_certs() {
    local cert_file="$__CURL_CERT_FILE"
    local check_file="$__CURL_CERT_CHECK_FILE"

    if [[ ! -f "$cert_file" ]]; then
        echo "CA certificate: Not found" >&2
        return 1
    fi

    if [[ ! -s "$cert_file" ]]; then
        echo "CA certificate: Empty" >&2
        return 1
    fi

    local cert_time
    cert_time=$(__cert_get_mtime "$cert_file")

    if [[ -n "$cert_time" ]]; then
        local cert_date
        local current_time
        local cert_age_days

        cert_date=$(date -r "$cert_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || \
                   date -d "@$cert_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)

        current_time=$(date +%s)
        cert_age_days=$(( (current_time - cert_time) / 86400 ))

        echo "CA certificate: OK" >&2
        echo "  File: $cert_file" >&2
        echo "  Updated: $cert_date" >&2
        echo "  Age: $cert_age_days days" >&2
        echo "  Expires in: $((__CURL_CERT_EXPIRE_DAYS - cert_age_days)) days" >&2

        # 显示检查时间信息
        if [[ -f "$check_file" ]]; then
            local last_check_time
            local last_check_date
            local days_since_check

            last_check_time=$(cat "$check_file" 2>/dev/null)
            if [[ -n "$last_check_time" && "$last_check_time" =~ ^[0-9]+$ ]]; then
                last_check_date=$(date -r "$last_check_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || \
                                 date -d "@$last_check_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
                days_since_check=$(( (current_time - last_check_time) / 86400 ))

                echo "  Last check: $last_check_date (${days_since_check} days ago)" >&2
                echo "  Check interval: $__CURL_CERT_CHECK_INTERVAL days" >&2
                echo "  Next check in: $((__CURL_CERT_CHECK_INTERVAL - days_since_check)) days" >&2
            fi
        else
            echo "  Last check: Never" >&2
        fi

        if [[ $cert_age_days -ge $__CURL_CERT_EXPIRE_DAYS ]]; then
            echo "  Status: EXPIRED - Please update with curl_update_certs" >&2
            return 1
        fi

        return 0
    fi

    echo "CA certificate: Unknown status" >&2
    return 1
}

# ============ 初始化 ============

# 模块初始化时检查证书
__curl_init() {
    # 静默更新证书（仅在需要时）
    __cert_update 2>/dev/null
}

# 执行初始化
__curl_init

# ============ 命令行接口 ============

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        update|--update|-u)
            curl_update_certs
            ;;
        check|--check|-c|status|--status)
            curl_check_certs
            ;;
        "")
            # 无参数：显示帮助
            cat <<EOF
Usage: $0 <command>

Commands:
  update, -u, --update    Update CA certificates (force)
  check, -c, --check      Check CA certificate status

Environment Variables:
  WHOIS_CERT_EXPIRE_DAYS     Certificate expiry threshold in days (default: 30)
  WHOIS_CERT_CHECK_INTERVAL  Check interval in days (default: 7)
EOF
            ;;
        *)
            echo "Error: Unknown command '$1'" >&2
            exit 1
            ;;
    esac
fi
