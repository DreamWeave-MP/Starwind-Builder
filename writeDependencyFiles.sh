#!/usr/bin/env sh

set -euo

DIR="${1:-.}"

mkdir -p $HOME/.local/share/openmw/data
mkdir -p $HOME/.config/openmw

echo "data=\"$(pwd)\"\ncontent=Morrowind.esm\ncontent=Tribunal.esm\ncontent=Bloodmoon.esm\ncontent=Starwind.omwaddon" >> $HOME/.config/openmw/openmw.cfg

printf ${MTM_DECRYPT_KEY} | gpg --batch --passphrase-fd 0 --decrypt /plugins/DATA.tar.gz.gpg | tar xzvf - -C ${DIR}
