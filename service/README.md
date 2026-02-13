# Usage

This folder contains files necessary for the automatic updating and deployment of your DreamScripts server.

Before getting started, you need the following dependencies:
- 7-Zip (Standalone!)
- git
- unzip
- wget (instructions use wget, curl may be substituted)

1. Install [`t3crc`](https://github.com/DreamWeave-MP/motherJungle/releases/download/development/t3crc-Linux-X64.zip), which is used to automatically generate `requiredDataFiles.json` for your server:
```sh
wget https://github.com/DreamWeave-MP/motherJungle/releases/download/development/t3crc-Linux-X64.zip
unzip t3crc-Linux-X64.zip
# OPTIONAL: If you have cosign installed, verify the t3crc binary's integrity
cosign verify-blob ./t3crc --certificate-identity-regexp="https://github.com/DreamWeave-MP/motherJungle/.github/workflows/" --certificate-oidc-issuer="https://token.actions.githubusercontent.com" --bundle ./t3crc-Linux-X64.bundle
rm t3crc-Linux-X64.bundle t3crc-Linux-X64.zip
chmod +x ./t3crc
sudo mv ./t3crc /usr/bin/t3crc
```
1. Download the tes3mp server and extract it into the root of the home folder:
```sh
cd
wget https://github.com/TES3MP/TES3MP/releases/download/tes3mp-0.8.1/tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz
tar xvf ./tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz
rm ./tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz
cd TES3MP-server/server
git remote add DW https://github.com/DreamWeave-MP/DreamScripts.git
git fetch --all
git reset --hard DW/0.8.1
```
1. Install the necessary dependences, `luajit`, `cjson`, and `tes3_lua`:
```sh
cd ../lib
wget https://github.com/DreamWeave-MP/luajit2/releases/download/Stable-CI/LuaJIT-Linux.7z
7zz x LuaJIT-Linux.7z bin/jit/ bin/libluajit.so
mv bin/jit .
mv bin/libluajit.so libluajit-5.1.so.2
rm -rf LuaJIT-Linux.7z ./bin/
cd ../server/lib
wget https://github.com/DreamWeave-MP/lua-cjson/releases/download/Stable-CI/cjson-Linux.so && mv cjson-Linux.so cjson.so
```
1. Download `tes3mp-init.sh` and place it in the root of your home folder:
```sh
wget https://raw.githubusercontent.com/DreamWeave-MP/Starwind-Builder/refs/heads/master/service/tes3mp-init.sh
chmod +x ./tes3mp-init.sh
```
1. Download `tes3mp@service` to `/etc/systemd/system`:
```sh
sudo wget https://raw.githubusercontent.com/DreamWeave-MP/Starwind-Builder/refs/heads/master/service/tes3mp%40.service -P /etc/systemd/system
```
1. Create the `tes3mp-update-deploy` user, and prepare their account for SSH setup:
```sh
  sudo useradd -m -s /bin/bash tes3mp-update-deploy
  sudo mkdir -p /home/tes3mp-update-deploy/.ssh
  sudo chmod 700 /home/tes3mp-update-deploy/.ssh
  sudo chown -R tes3mp-update-deploy:tes3mp-update-deploy /home/tes3mp-update-deploy/.ssh
  sudo touch /home/tes3mp-update-deploy/.ssh/authorized_keys
  sudo chmod 600 /home/tes3mp-update-deploy/.ssh/authorized_keys
```
1. Add your public SSH key for GitHub deployments to the `tes3mp-update-deploy` user's `authorized_keys` file: `echo $(cat your_key.pub) >> /home/tes3mp-update-deploy/.ssh/authorized_keys`
1. Decide what user account should run the tes3mp service, then start the tes3mp service using it. We'll use the current user account:
```sh
sudo systemctl enable --now tes3mp@$USER
```
1. Edit the sudoers file to restrict permissions on the `tes3mp-update-deploy` user, by adding this line:
```sh
echo "tes3mp-update-deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tes3mp@$USER" | sudo tee /etc/sudoers.d/99-tes3mp-update-sudoer
```
This will allow the tes3mp-update-deploy user to restart the tes3mp service with elevated permissions.

1. Finally, edit your sshd_config by running:
```sh
printf "Match User tes3mp-update-deploy\\n    ForceCommand sudo systemctl restart tes3mp@$USER\\n    PermitTTY no\\n" | sudo tee /etc/ssh/sshd_config.d/tes3mp-deploy.conf
```

This will prevent the tes3mp-update-deploy user from doing anything upon login except restart the tes3mp service, which we gave them permission to do in the previous step.
