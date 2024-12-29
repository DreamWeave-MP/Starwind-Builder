#!/usr/bin/env sh

set -euo

KEY="$1"
DIR="${2:-.}"

mkdir -p $HOME/.local/share/openmw/data

echo -e "data=\"$(pwd)\"\ncontent=Morrowind.esm\ncontent=Tribunal.esm\ncontent=Bloodmoon.esm\ncontent=Starwind.omwaddon" >> $HOME/.config/openmw/openmw.cfg

printf ${KEY} | gpg --batch --passphrase-fd 0 --decrypt /plugins/DATA.tar.gz.gpg | tar xzvf - -C ${DIR}
