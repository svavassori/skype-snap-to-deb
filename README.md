# Creates a .deb package from latest Skype snap version

## dependencies used by the script
* dpkg-deb
* jq
* sha512sum
* squashfs-tools
* wget

## how to run
```bash
fakeroot ./repack.sh
```

This will create a .deb package named `skypeforlinux_<version>_amd64-sv.deb`

## How to install

```bash
apt-get install ./skypeforlinux_<version>_amd64-sv.deb
```
