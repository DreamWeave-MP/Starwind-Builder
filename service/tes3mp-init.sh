#!/usr/bin/env sh

set -eu

cd /home/corleycomputerrepair/TES3MP-server/server

mkdir -p data/custom/Starwind data/custom/cell

curl -L 'https://gitlab.com/magicaldave1/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_requiredDataFiles' | bsdtar -xvf- -C data

curl -L 'https://gitlab.com/magicaldave1/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_cells' | bsdtar -xvf- -O | tar -xv -C .

curl -L 'https://gitlab.com/magicaldave1/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_merchants' | bsdtar -xvf- -C data/custom

./tes3mp-server
