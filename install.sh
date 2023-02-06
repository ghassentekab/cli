#!/bin/bash
## Replace gitpod.yml with devfactory.yml
# if [ -f $THEIA_WORKSPACE_ROOT/.devfactory.yml ]; then
#     cp $THEIA_WORKSPACE_ROOT/.devfactory.yml $THEIA_WORKSPACE_ROOT/.gitpod.yml
# fi
# git config --global core.excludesFile '/home/gitpod/.dotfiles/.gitexclude'

echo "export USER_ID=$(id -u) GROUP_ID=$(id -g)" >> /home/gitpod/.bashrc

curl https://rclone.org/install.sh | sudo bash

mkdir -p /home/gitpod/.config/rclone
sudo mkdir -p /root/.config/rclone

echo ""[google_drive]"" > rclone.conf
echo "type = drive" >> rclone.conf
echo "scope = drive" >> rclone.conf
echo 'token = {"access_token":"Access","token_type":"Bearer","refresh_token":"Refresh","expiry":"Expiry"}' >> rclone.conf
echo "team_drive = " >> rclone.conf


cp rclone.conf /home/gitpod/.config/rclone && cd /home/gitpod/.config/rclone && sed -i 's/Access/'$Access_Token'/' rclone.conf && sed -i "s@Refresh@$Refresh_Token@g" rclone.conf && sed -i "s@Expiry@$Expiry@g" rclone.conf
sudo cp rclone.conf /root/.config/rclone && cd /root/.config/rclone && sed -i 's/Access/'$Access_Token'/' rclone.conf && sed -i "s@Refresh@$Refresh_Token@g" rclone.conf && sed -i "s@Expiry@$Expiry@g" rclone.conf

# upload from git-pod >>>>>>>> google drive
#/usr/bin/rclone copy --update --verbose --transfers 30 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 1s "/home/gitpod/db_backups" "google_drive:storage"

sudo apt install fuse -y
sudo usermod -a -G root gitpod
sudo groupadd -g 999 postgres
sudo useradd -u 999 -g 999 postgres
sudo usermod -a -G postgres postgres
# sudo usermod -a -G docker postgres
mkdir ${THEIA_WORKSPACE_ROOT}/${GITPOD_WORKSPACE_ID}
# sudo chmod 750 ${THEIA_WORKSPACE_ROOT}/${GITPOD_WORKSPACE_ID}
# sudo chown postgres:root -R ${THEIA_WORKSPACE_ROOT}/${GITPOD_WORKSPACE_ID}
# rcone sync --transfers 30 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --stats skip-del

# echo "'access_token":"ya29.A0ARrdaM_JbTBnvyvmxStiXm242iTu9dhVr9mwIq5kbXDc6C2QbI4YfYhxv0KfV197e_iEt33weP9dLZnyKTqg-iqPuoA5DOy7Hc90ZoUbdPaPnQh1qoOrMwK22C1WkxcLJoMSrP9gf8FR0zZ2AdJzsA_bZ6d7","token_type":"Bearer","refresh_token":"1//03QXNXOOPRHKeCgYIARAAGAMSNwF-L9IrMjA__EI_M3PnkuYpalQ_yZoUZi42raVV-WGBWwodVsK6zoC-cVmRxzQEo7y6hxG29Xc","expiry":"2022-05-10T17:58:55.604506529+02:00'"

printf "%s\n" '
ACCOUNT_default_CLIENT_ID="client id"
ACCOUNT_default_CLIENT_SECRET="client secret"
ACCOUNT_default_REFRESH_TOKEN="refresh token"
' >| "${HOME}/.googledrive.conf"

# ./gdrive upload /home/documents/file_name.zip

rclone mkdir google_drive:${THEIA_WORKSPACE_ROOT}
rclone mkdir google_drive:${THEIA_WORKSPACE_ROOT}/DATABASE_BACKUP

sudo bash -c "echo 'user_allow_other' >> /etc/fuse.conf"

rclone mount --allow-other --allow-root --uid $(id -u) --gid $(id -g) --daemon google_drive:${THEIA_WORKSPACE_ROOT} ${THEIA_WORKSPACE_ROOT}/${GITPOD_WORKSPACE_ID}
# --daemon --uid $(id -u) --gid $(id -g) --allow-other 

sudo bash -c 'docker plugin install sapk/plugin-rclone --grant-all-permissions'
shopt -s expand_aliases
echo 'alias devfactory_backup="/home/gitpod/.dotfiles/bootstrap_backup.sh"' >> /home/gitpod/.bashrc
echo 'alias devfactory_restore="/home/gitpod/.dotfiles/bootstrap_restore.sh"' >> /home/gitpod/.bashrc

# sudo bash -c 'docker volume create --driver sapk/plugin-rclone --opt config="$(base64 ~/.config/rclone/rclone.conf)" --opt args="--allow-root --allow-other --allow-non-empty" --opt remote=google_drive:${THEIA_WORKSPACE_ROOT} --name postgres'



# rclone sync /workspace/dev-factory-api/tekabdevtea-devfactorya-cavw0bxw40c google_drive:${THEIA_WORKSPACE_ROOT} --bwlimit=8.5M --progress
# rclone sync google_drive:${THEIA_WORKSPACE_ROOT} /workspace/dev-factory-api/tekabdevtea-devfactorya-cavw0bxw40c --bwlimit=8.5M --progress


# docker volume create --driver sapk/plugin-rclone --opt config="$(base64 ~/.config/rclone/rclone.conf)" --opt remote=google_drive:test --name vol



# docker plugin install sapk/plugin-rclone
# docker volume create --driver sapk/plugin-rclone --opt config="$(base64 ~/.config/rclone/rclone.conf)" --opt args="--uid 33333 --gid 33333 --allow-root --allow-other" --opt remote=google_drive:test/ --name vol
# docker run -i -t -u 33333:33333 --rm -v vol:/mnt ubuntu /bin/ls -lah /mnt



# docker volume create --driver sapk/plugin-rclone --opt config="$(base64 ~/.config/rclone/rclone.conf)" --opt args="--uid 999 --gid 0 --allow-root --allow-other" --opt remote=google_drive:test/ --name post
# docker run -i -t -u 999:0 -v post:/var/lib/postgresql/data -e POSTGRES_PASSWORD=test postgres

# docker run --rm --log-opt max-size=10m -v /workspace/dev-factory-api/config.json:/usr/local/bin/google-sync/etc/config.json -v /workspace/dev-factory-api/package:/var/target -v /home/gitpod/.config/rclone:/root/.config/rclone richardregeer/google-drive-sync 

# sudo docker run --rm --log-opt max-size=50m -v /workspace/dev-factory-api/config.json:/usr/local/bin/google-sync/etc/config.json -v /workspace/.docker-root/volumes/dev-factory-api_postgres:/var/target -v /root/.config/rclone:/root/.config/rclone richardregeer/google-drive-sync