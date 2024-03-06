#!/usr/bin/env bash

set -eu

wget https://github.com/TES3MP/TES3MP/releases/download/tes3mp-0.8.1/tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz
tar -xvf tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz

cd TES3MP-server/server

mkdir data/custom/Starwind data/custom/esps data/custom/Starwind/Cell

cp ../../Starwind.omwaddon data/custom/esps/

cp ../../src/DataBaseScript.lua scripts/custom/

wget -P scripts/custom/DataManager https://raw.githubusercontent.com/tes3mp-scripts/DataManager/master/main.lua
wget -P scripts/custom/espParser https://raw.githubusercontent.com/JakobCh/tes3mp_scripts/master/espParser/main.lua
wget -P scripts/custom/espParser https://raw.githubusercontent.com/JakobCh/tes3mp_scripts/master/espParser/initialConfig.lua
wget -P scripts/custom/ https://raw.githubusercontent.com/iryont/lua-struct/master/src/struct.lua

echo "struct = require(\"custom.struct\")
require(\"custom.DataManager.main\")
require(\"custom.espParser.main\")
DataBaseScript = require(\"custom.DataBaseScript\")" >> scripts/customScripts.lua

../tes3mp-server

zip -r9 ../../StarwindDB.zip data/custom/Starwind/

cd ../../ && rm -rf TES3MP-server tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz
