all: clean plugins-text build databases
	zip all_data DFLDB.zip StarwindDB.zip Starwind.omwaddon

build: plugins-bin
	./build.sh grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

plugins-bin:
	mkdir -p build
	find ./src -type f -name "*.json" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.json$$/.esp/")"; tes3conv "$$1" "$$OUT_FILE"; mv "$$OUT_FILE" ./build/' sh {} \;

plugins-text:
	find . -type f -name "*.omwaddon" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.omwaddon$$/.json/")"; tes3conv "$$1" "$$OUT_FILE"; rm -rf src/"$$OUT_FILE"; mv "$$OUT_FILE" src/' sh {} \;

deploy:
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

deploy-only: plugins-text build
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

MIG:
	merchantIndexGrabber

espParser:
	./espParser.sh

tes3conv:
	mkdir -p data/custom/DFL_input
	find ./src -type f -name "*.json" -exec cp {} data/custom/DFL_input/ \;
	zip -r DFLDB data/custom/DFL_input/
	rm -rf data/

databases: MIG espParser tes3conv

clean:
	rm -rf *.tmp *\~* src/*.esp build *.zip *.gz* TES3MP-server StarwindDB.zip Starwind.omwaddon merchantIndexDatabase.json DFLDB.zip
