#!/usr/bin/env sh

set -euo pipefail

KEY="$1"
DIR="${2:-.}"

printf ${KEY} | gpg --batch --passphrase-fd 0 --decrypt /plugins/DATA.tar.gz.gpg | tar xzvf - -C ${DIR}
