#!/usr/bin/env bash

set -eu

if [ "$1" = "kTools" ]; then
    mkdir -p ./kTools_out
    kTools requiredDataFiles.json ./kTools_out
    tar -czf kToolsDB.tar.gz ./kTools_out
    rm -rf kTools_out
    exit 0
fi

curl -L https://github.com/TES3MP/TES3MP/releases/download/tes3mp-0.8.1/tes3mp-server-GNU+Linux-x86_64-release-0.8.1-68954091c5-6da3fdea59.tar.gz | tar -xz

cd TES3MP-server/server

if [ "$1" = "espParser" ]; then
    mkdir -p data/custom/Starwind data/custom/esps data/custom/Starwind/Cell scripts/custom/DataManager scripts/custom/espParser

    if [ $GITHUB_ACTIONS ]; then
        cp /plugins/* data/custom/esps
    else
        cp ../../Starwind-TSI.omwaddon data/custom/esps/
    fi

    cp ../../src/DataBaseScript.lua scripts/custom/

    curl -L https://raw.githubusercontent.com/tes3mp-scripts/DataManager/master/main.lua -o scripts/custom/DataManager/main.lua
    curl -L https://raw.githubusercontent.com/JakobCh/tes3mp_scripts/master/espParser/main.lua -o scripts/custom/espParser/main.lua
    curl -L https://raw.githubusercontent.com/JakobCh/tes3mp_scripts/master/espParser/initialConfig.lua -o scripts/custom/espParser/initialConfig.lua
    curl -L https://raw.githubusercontent.com/iryont/lua-struct/master/src/struct.lua -o scripts/custom/struct.lua

    echo "struct = require(\"custom.struct\")
    require(\"custom.DataManager.main\")
    require(\"custom.espParser.main\")
    DataBaseScript = require(\"custom.DataBaseScript\")" >> scripts/customScripts.lua

    ../tes3mp-server

    tar -czf ../../StarwindDB.tar.gz data/custom/Starwind/

elif [ "$1" = "DFL" ]; then
    mkdir -p scripts/custom/data-files-loader/ scripts/custom/data-files-loader/dependencies/ data/custom/DFL_input data/custom/DFL_output

    if [ $GITHUB_ACTIONS ]; then

        for plugin in Morrowind.esm Tribunal.esm Bloodmoon.esm Starwind-TSI.omwaddon; do
            tes3conv "/plugins/$plugin" "data/custom/DFL_input/${plugin%.*}.json"
        done

    else
        tes3conv ../../Starwind-TSI.omwaddon data/custom/DFL_input/Starwind.json
    fi

    cp ../../requiredDataFiles.json data/requiredDataFiles.json

    curl -L https://raw.githubusercontent.com/VidiAquam/TES3MP-Data-Files-Loader/main/dataFilesLoaderMain.lua -o scripts/custom/data-files-loader/dataFilesLoaderMain.lua
    curl -L https://raw.githubusercontent.com/VidiAquam/TES3MP-Data-Files-Loader/main/dataFilesLoaderUtilities.lua -o scripts/custom/data-files-loader/dataFilesLoaderUtilities.lua
    curl -L https://raw.githubusercontent.com/VidiAquam/TES3MP-Data-Files-Loader/main/dependencies/lua_string.lua -o scripts/custom/data-files-loader/dependencies/lua_string.lua

    sed -i 's/trimend("esm") \.\. "json"/trimend("esm") \.\. "json" elseif string.lower(entryIndex):endswith("omwaddon") then jsonDataFileList[listIndex] = string.lower(entryIndex):trimend("omwaddon") .. "json"''/g' scripts/custom/data-files-loader/dataFilesLoaderMain.lua
    sed -i "s/parseOnServerStart = false/parseOnServerStart = true/" scripts/custom/data-files-loader/dataFilesLoaderMain.lua
    sed -i "s/dataFilesLoader.loadParsedFiles()/dataFilesLoader.loadParsedFiles() tes3mp.StopServer(0)/" scripts/custom/data-files-loader/dataFilesLoaderMain.lua

    echo 'require("custom.data-files-loader.dataFilesLoaderMain")' >> scripts/customScripts.lua

    ../tes3mp-server | grep -v "morrowind.json\|tribunal.json\|bloodmoon.json"

    tar -czf ../../DFLDB.tar.gz data/custom/DFL_output/

fi

cd ../../ && rm -rf TES3MP-server
