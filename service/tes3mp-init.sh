#!/usr/bin/env sh

set -eu

cd $HOME/TES3MP-server/server

VERSION_FILE="$HOME/TES3MP-server/server/.starwind_version"
LATEST_COMMIT=$(curl -s https://api.github.com/repos/DreamWeave-MP/Starwind-Builder/commits/HEAD | grep '"sha": *"[^"]*' | head -1 | cut -f 4 -d \")

if [ ! -f "$VERSION_FILE" ] || [ "$(cat $VERSION_FILE)" != "$LATEST_COMMIT" ]; then
    echo "New version detected, updating data..."

    # bsdtar provided by libarchive-tools on ubuntu 22.04 and up
    # It's needed here because other archivers don't necessarily allow reading from stdin
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/requiredDataFiles.json | bsdtar -xvf- -C data
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/kToolsDB.tar.gz | bsdtar -xvf- -O | tar -xz -C data/custom
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/merchantIndexDatabase.json | bsdtar -xvf- -C data/custom

    echo "$LATEST_COMMIT" > "$VERSION_FILE"
else
    echo "Data is up to date, skipping download"
fi

../tes3mp-server
