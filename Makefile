all: clean plugins-text build-tsi databases
	zip all_data DFLDB.zip StarwindDB.zip Starwind.omwaddon

build-tsi: plugins-bin
	./build.sh tsi | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

build-vanilla: plugins-bin
	./build.sh vanilla | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

plugins-bin:
	mkdir -p build
	find ./src -type f -name "*.json" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.json$$/.esp/")"; tes3conv "$$1" "$$OUT_FILE"; mv "$$OUT_FILE" ./build/' sh {} \;

plugins-text:
	rm -rf StarwindMPRecords.omwaddon "Starwind Community Patch Project.omwaddon"
	cp $$HOME/.local/share/openmw/data/StarwindMPRecords.omwaddon "$$HOME/.local/share/openmw/data/Starwind Community Patch Project.omwaddon" .
	find . -type f -name "*.omwaddon" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.omwaddon$$/.json/")"; tes3conv "$$1" "$$OUT_FILE"; rm -rf src/"$$OUT_FILE"; mv "$$OUT_FILE" src/' sh {} \;

deploy:
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

deploy-only: clean plugins-text build-tsi
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

requiredfiles:
	echo "data=\"$(pwd)\"" >> $$HOME/.config/openmw/openmw.cfg
	for m in Morrowind.esm Tribunal.esm Bloodmoon.esm Starwind.omwaddon; do \
		touch $$m; \
		echo "content=\"$$m\"" >> $$HOME/.config/openmw/openmw.cfg; \
	done
	t3crc

MIG:
	merchantIndexGrabber

espParser:
	./databaseWriter.sh espParser

DFL:
	./databaseWriter.sh DFL

databases: MIG espParser DFL requiredfiles

clean:
	rm -rf *.tmp *\~* src/*.esp *.zip *.gz* *.json TES3MP-server build Starwind.omwaddon
