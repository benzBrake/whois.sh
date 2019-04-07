A light weight whois tools written by shell.

## Features
**Get whois server for iana automatic.**

**Custom whois server** support, only support domain whois currently.

**IP Whois** support

**Web whois** support. If a TLD only can whois on website, for example, tt, whois.sh will checkout `TLD.sh` in api folder, if exist, call `TLD.sh` to get whois info.

## Usage
### Install
```
yum install git curl -y # CentOS/RHEL
apt install git curl -y # Debian/Ubuntu/WSL
cd ~
git clone https://github.com/benzBrake/whois.sh.git .whois.sh
chmod +x ~/.whois.sh/*.sh ~/.whois.sh/*/*.sh
echo '. ~/.whois.sh/whois.sh.env' >> ~/.bashrc
exec $SHELL
```
### How to whois
```
whois.sh domain
whois.sh ip
```
or
```
whois.sh -H whois.doufu.ru doufu.ru
```
### Custom whois method
Put your `TLD.sh` in folder `api`.

## License
[Anti-996 License](LICENSE)

 - The purpose of this license is to prevent anti-labour-law companies from using the software or codes under the license, and force those companies to weigh their way of working
 - It is an idea of @xushunke: [Design A Software License Of Labor Protection -- Anti 996 License](https://github.com/996icu/996.ICU/pull/15642)
 - This version of Anti-996 License is drafted by [Katt Gu, J.D, University of Illinois, College of Law](https://scholar.google.com.sg/citations?user=PTcpQwcAAAAJ&hl=en&oi=ao); advised by [Suji Yan](https://www.linkedin.com/in/tedkoyan/), CEO of [Dimension](https://www.dimension.im).  
 - This draft is adapted from the MIT license. For more detailed explanation, please see [Wiki](https://github.com/kattgu7/996-License-Draft/wiki). This license is designed to be compatible with all major open source licenses.  
 - For law professionals or anyone who is willing to contribute to future version directly, please go to [Anti-996-License-1.0](https://github.com/kattgu7/996-License-Draft). Thank you.
