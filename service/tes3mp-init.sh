#!/usr/bin/env sh

set -eu

cd $HOME/TES3MP-server/server

VERSION_FILE="$HOME/TES3MP-server/server/.starwind_version"
LATEST_COMMIT=$(curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/DreamWeave-MP/Starwind-Builder/commits | jq .[0].sha)

if [ ! -f "$VERSION_FILE" ] || [ "$(cat $VERSION_FILE)" != "$LATEST_COMMIT" ]; then
    echo "New version detected, updating data..."

    # Fetch the latest plugin and generate a requiredDataFiles.json for it
    # Any other plugins used by the server should also be stored in data/plugins/, with an openmw.cfg defining the correct order in the data/ directory
    curl -L https://github.com/DreamWeave-MP/Starwind-Builder/releases/download/development/Starwind-TSI.omwaddon -o data/plugins/Starwind-TSI.omwaddon
    cd data && OPENMW_CONFIG="$(pwd)" t3crc && cd .. || exit 1

    if [ -f "$VERSION_FILE" ]; then
        rm "$VERSION_FILE"
    fi

    echo "$LATEST_COMMIT" > "$VERSION_FILE"
else
    echo "Data is up to date, skipping download"
fi

git pull

../tes3mp-server
