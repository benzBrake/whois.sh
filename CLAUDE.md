# 约定
shell 脚本使用 LF 作为换行符

# 模块说明

## inc/curl.sh - curl 请求模块

**重要：** 所有 curl 请求都应通过 `inc/curl.sh` 模块调用，不要直接使用 `curl` 命令。

### 功能
- CA 证书自动管理（从 curl.se 下载最新证书）
- 智能更新策略（检查间隔 + 证书过期双重机制）
- 安全的 HTTPS/HTTP 请求封装

### 使用方式

```bash
# 在脚本中 source 后使用
source "$WHOIS_WORKING_DIR/inc/curl.sh"

# GET 请求
__curl_get "https://example.com"

# POST 请求
__curl_post "https://example.com/api" "key=value"

# 带额外参数的请求
__curl_get "https://example.com" -H "Authorization: Bearer xxx"
```

### 配置环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `WHOIS_CERT_EXPIRE_DAYS` | 证书过期天数 | 30 |
| `WHOIS_CERT_CHECK_INTERVAL` | 检查间隔天数 | 7 |

### 更新策略
- 每次调用时检查是否超过 7 天未检查
- 超过检查间隔时，判断证书是否超过 30 天需要更新
- 检查后无论是否更新，都会刷新检查时间

### 文件结构
```
data/
├── cacert.pem       # CA 证书
├── cacert.version   # 证书更新时间
└── cacert.check     # 上次检查时间
```