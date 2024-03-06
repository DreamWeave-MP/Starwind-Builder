#!/usr/bin/env bash

set -eu

curl -L https://github.com/TES3MP/TES3MP/releases/download/tes3mp-0.8.1/tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz -o tes3mp.tar.gz
tar -xvf tes3mp.tar.gz

cd TES3MP-server/server

mkdir data/custom/Starwind data/custom/esps data/custom/Starwind/Cell scripts/custom/DataManager scripts/custom/espParser

cp ../../Starwind.omwaddon data/custom/esps/

cp ../../src/DataBaseScript.lua scripts/custom/

curl -sS https://raw.githubusercontent.com/tes3mp-scripts/DataManager/master/main.lua -o scripts/custom/DataManager/main.lua
curl -sS https://raw.githubusercontent.com/JakobCh/tes3mp_scripts/master/espParser/main.lua -o scripts/custom/espParser
curl -sS https://raw.githubusercontent.com/JakobCh/tes3mp_scripts/master/espParser/initialConfig.lua -o scripts/custom/espParser
curl -sS https://raw.githubusercontent.com/iryont/lua-struct/master/src/struct.lua -o scripts/custom/

echo "struct = require(\"custom.struct\")
require(\"custom.DataManager.main\")
require(\"custom.espParser.main\")
DataBaseScript = require(\"custom.DataBaseScript\")" >> scripts/customScripts.lua

../tes3mp-server

zip -r9 ../../StarwindDB.zip data/custom/Starwind/

cd ../../ && rm -rf TES3MP-server tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz
