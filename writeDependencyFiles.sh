#!/usr/bin/env sh

set -euo
export GPG_TTY=$(tty)

DIR="${1:-.}"

mkdir -p $HOME/.local/share/openmw/data
mkdir -p $HOME/.config/openmw

echo "data=\"$(pwd)\"\ncontent=Morrowind.esm\ncontent=Tribunal.esm\ncontent=Bloodmoon.esm\ncontent=Starwind.omwaddon" >> $HOME/.config/openmw/openmw.cfg

gpg --passphrase ${MTM_DECRYPT_KEY} --decrypt /plugins/DATA.tar.gz.gpg | tar xzvf - -C ${DIR}
