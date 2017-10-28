# whois.sh
An extended whois client written by shell.

~~Base on command whois. Please install whois before using whois.sh.~~

## Features
If the whois command was returned no whois server, whois.sh would connet to iana.org and checkout the whois server automatic.

If a TLD only can whois on website, for example, tt, whois.sh will checkout `TLD.sh` in api folder, if exist, call `TLD.sh` to get whois info.

## Uasage
### Install
```
cd ~
git clone https://github.com/benzBrake/whois.sh.git .whois.sh
chmod +x ~/.whois.sh/*.sh ~/.whois.sh/api/*.sh
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
## License

[MIT License](https://github.com/benzBrake/whois.sh/blob/master/LICENSE)
