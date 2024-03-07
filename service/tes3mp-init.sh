#!/usr/bin/env sh

set -eu

cd /home/corleycomputerrepair/TES3MP-server/
mkdir -p server/data/custom/Starwind server/data/custom/cell

curl -L 'https://gitlab.com/magicaldave1/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_requiredDataFiles' -o rdf.zip \
    && unzip -o rdf.zip -d server/data
curl -L 'https://gitlab.com/magicaldave1/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_cells' -o cellDB.zip \
    && unzip -o cellDB.zip \
    && unzip StarwindDB.zip -d server/
curl -L 'https://gitlab.com/magicaldave1/Starwind-Builder/-/jobs/artifacts/master/download?job=dump_merchants' -o merchants.zip \
    && unzip -o merchants.zip -d server/data/custom

rm merchants.zip cellDB.zip StarwindDB.zip rdf.zip

./tes3mp-server
