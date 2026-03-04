A light weight whois tools written by shell.

## Features

- **Automatic WHOIS Server Detection**: Automatically retrieve WHOIS server from IANA
- **Custom WHOIS Server**: Specify custom WHOIS server and port for domain queries
- **IP WHOIS**: Support for both IPv4 and IPv6 address queries
- **RDAP Protocol**: Modern RDAP protocol support for new TLDs (.dev, .app, etc.)
- **Web WHOIS**: For TLDs that only provide web-based WHOIS (e.g., .tt), automatically calls `TLD.sh` from `api/` folder
- **Smart Caching**: Caches WHOIS servers and IP prefixes to improve performance
- **Secure by Design**: Input validation, path traversal protection, and injection prevention

## Project Structure

```
whois.sh/
├── whois.sh              # Main entry script
├── whois.sh.env          # Environment configuration
├── servers.list          # TLD to WHOIS server mapping
├── api/                  # Custom API scripts for special TLDs
│   ├── al.sh            # .al domain API
│   ├── com.sh           # .com domain special handling
│   └── tt.sh            # .tt domain web API
└── inc/                  # Core function modules
    ├── functions.sh      # Core function library
    ├── getwhois.sh       # WHOIS query logic
    ├── ip.sh            # IP address query module
    ├── rdap.sh          # RDAP protocol module
    └── tcp.sh           # TCP connection utility
```

## Usage
### Install
```
yum install git curl -y # CentOS/RHEL
apt install git curl -y # Debian/Ubuntu/WSL
cd ~
git clone https://github.com/benzBrake/whois.sh.git .whois.sh
chmod +x ~/.whois.sh/*.sh ~/.whois.sh/*/*.sh
echo '. ~/.whois.sh/whois.sh.env' >> ~/.bash_profile
exec $SHELL
```
### Basic Query

```bash
# Query domain
whois.sh example.com
whois.sh github.com

# Query IPv4 address
whois.sh 8.8.8.8

# Query IPv6 address
whois.sh 2001:4860:4860::8888
```

### Custom WHOIS Server

```bash
# Specify custom WHOIS server
whois.sh -H whois.example.com example.com

# Specify custom port
whois.sh -H whois.example.com -p 4343 example.com

# Query from IANA
whois.sh -i example.com
```

### API Extensions

To add support for a TLD that only provides web-based WHOIS, create a `TLD.sh` script in the `api/` folder:

```bash
#!/bin/bash
# api/yourtld.sh
# Your custom logic to fetch and parse whois data
# Output should be in standard whois format
```

The script will be automatically called when querying domains with that TLD.

## License
[Anti-996 License](LICENSE)

 - The purpose of this license is to prevent anti-labour-law companies from using the software or codes under the license, and force those companies to weigh their way of working
 - It is an idea of @xushunke: [Design A Software License Of Labor Protection -- Anti 996 License](https://github.com/996icu/996.ICU/pull/15642)
 - This version of Anti-996 License is drafted by [Katt Gu, J.D, University of Illinois, College of Law](https://scholar.google.com.sg/citations?user=PTcpQwcAAAAJ&hl=en&oi=ao); advised by [Suji Yan](https://www.linkedin.com/in/tedkoyan/), CEO of [Dimension](https://www.dimension.im).  
 - This draft is adapted from the MIT license. For more detailed explanation, please see [Wiki](https://github.com/kattgu7/996-License-Draft/wiki). This license is designed to be compatible with all major open source licenses.  
 - For law professionals or anyone who is willing to contribute to future version directly, please go to [Anti-996-License-1.0](https://github.com/kattgu7/996-License-Draft). Thank you.
