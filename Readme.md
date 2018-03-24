A light weight whois tools written by shell.

## Features
** Get whois server for iana automatic. **
** Custom whois server ** support, only support domain whois currently.
** IP Whois ** support
** Web whois ** support. If a TLD only can whois on website, for example, tt, whois.sh will checkout `TLD.sh` in api folder, if exist, call `TLD.sh` to get whois info.

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
Put your `TLD.sh` in folder.

## License

[MIT License](https://github.com/benzBrake/whois.sh/blob/master/LICENSE)
