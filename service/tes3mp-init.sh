#!/usr/bin/env sh

set -eu

cd $HOME/TES3MP-server/server

VERSION_FILE="$HOME/TES3MP-server/server/.starwind_version"
LATEST_COMMIT=$(curl -s 'https://gitlab.com/api/v4/projects/modding-openmw%2FStarwind-Builder/repository/branches/master' | grep -o '"commit":{"id":"\w\+"' | cut -d'"' -f6)

if [ ! -f "$VERSION_FILE" ] || [ "$(cat $VERSION_FILE)" != "$LATEST_COMMIT" ]; then
    echo "New version detected, updating data..."

    # bsdtar provided by libarchive-tools on ubuntu 22.04 and up
    # It's needed here because other archivers don't necessarily allow reading from stdin
    curl -L 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_requiredDataFiles' | bsdtar -xvf- -C data
    curl -L 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_kTools' | bsdtar -xvf- -O | tar -xz -C data/custom
    curl -L 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_merchants' | bsdtar -xvf- -C data/custom

    echo "$LATEST_COMMIT" > "$VERSION_FILE"
else
    echo "Data is up to date, skipping download"
fi

../tes3mp-server
