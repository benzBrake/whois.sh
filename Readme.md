# whois.sh
An extended whois client written by shell.

Base on command whois. Please install whois before using whois.sh.

## Features
If the whois command was returned no whois server, whois.sh would connet to iana.org and checkout the whois server automatic.

If a TLD only can whois on website, for example, tt, whois.sh will checkout `TLD.sh` in api folder, if exist, call `TLD.sh` to get whois info.

## Uasage
### Install
```
cd /root
git clone https://github.com/benzBrake/whois.sh.git .whois.sh
chmod +x /root/.whois.sh/*.sh /root/.whois.sh/api/*.sh
echo '. "/root/.whois.sh/whois.sh.env"' >> /root/.bashrc
```
### How to whois
```
whois.sh domain
whois.sh -iana tld
```
## License

[MIT License](https://github.com/benzBrake/whois.sh/blob/master/LICENSE)
