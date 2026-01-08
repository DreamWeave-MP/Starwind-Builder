#!/usr/bin/env sh

set -eu

cd $HOME/TES3MP-server/server

VERSION_FILE="$HOME/TES3MP-server/server/.starwind_version"
LATEST_COMMIT=$(curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/DreamWeave-MP/Starwind-Builder/commits | jq .[0].sha)

if [ ! -f "$VERSION_FILE" ] || [ "$(cat $VERSION_FILE)" != "$LATEST_COMMIT" ]; then
    echo "New version detected, updating data..."

    # bsdtar provided by libarchive-tools on ubuntu 22.04 and up
    # It's needed here because other archivers don't necessarily allow reading from stdin
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/requiredDataFiles.json -o data/requiredDataFiles.json
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/merchantIndexDatabase.json -o data/custom/merchantIndexDatabase.json
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/kToolsDB.tar.gz | bsdtar -xvf- -C data/custom

    echo "$LATEST_COMMIT" > "$VERSION_FILE"
else
    echo "Data is up to date, skipping download"
fi

git pull

../tes3mp-server
