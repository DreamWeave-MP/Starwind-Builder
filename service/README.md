# Usage

This folder contains files necessary for the automatic updating and deployment of your DreamScripts server.

1. Install [`t3crc`](https://github.com/DreamWeave-MP/motherJungle/releases/download/development/t3crc-Linux-X64.zip), which is used to automatically generate `requiredDataFiles.json` for your server:
```sh
wget https://github.com/DreamWeave-MP/motherJungle/releases/download/development/t3crc-Linux-X64.zip
unzip t3crc-Linux-X64.zip
# OPTIONAL: If you have cosign installed, verify the t3crc binary's integrity
cosign verify-blob ./t3crc --certificate-identity-regexp="https://github.com/DreamWeave-MP/motherJungle/.github/workflows/" --certificate-oidc-issuer="https://token.actions.githubusercontent.com" --bundle ./t3crc-Linux-X64.bundle
rm t3crc-Linux-X64.bundle
chmod +x ./t3crc
sudo mv ./t3crc /usr/bin/t3crc
```
2. Download the tes3mp server and extract it into the root of the home folder
3. Place `tes3mp-init.sh` in the root of your home folder
4. Copy `tes3mp@service` to `/etc/systemd/system`
5. Create the `tes3mp-update-deploy` user, and prepare their account for SSH setup:
```sh
  sudo useradd -m -s /bin/bash tes3mp-update-deploy
  sudo mkdir -p /home/tes3mp-update-deploy/.ssh
  sudo chmod 700 /home/tes3mp-update-deploy/.ssh
  sudo chown -R tes3mp-update-deploy:tes3mp-update-deploy /home/tes3mp-update-deploy/.ssh
  sudo touch /home/tes3mp-update-deploy/.ssh/authorized_keys
  sudo chmod 600 /home/tes3mp-update-deploy/.ssh/authorized_keys
```
6. Add your public SSH key for GitHub deployments to the `tes3mp-update-deploy` user's `authorized_keys` file: `echo $(cat your_key.pub) >> /home/tes3mp-update-deploy/.ssh/authorized_keys`
7. Decide what user account should run the tes3mp service, then start the tes3mp service using it. We'll use `cyanideandfiberglass` as an example:
```sh
sudo systemctl enable --now tes3mp@cyanideandfiberglass
```

8. Edit the sudoers file to restrict permissions on the `tes3mp-update-deploy` user, by adding this line:
```sh
tes3mp-update-deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart tes3mp@cyanideandfiberglass
```
This will allow the tes3mp-update-deploy user to restart the tes3mp service with elevated permissions. Bear in mind you must replace `cyanideandfiberglass` with the username of the account which is actually running the tes3mp service.

9. Finally, edit your sshd_config by running: `sudo vi /etc/ssh/sshd_config` and add the following:
```sh
Match User tes3mp-update-deploy
    ForceCommand sudo systemctl restart tes3mp@cyanideandfiberglass
    PermitTTY no
```

This will prevent the tes3mp-update-deploy user from doing anything upon login except restart the tes3mp service, which we gave them permission to do in the previous step.
