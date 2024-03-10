all: clean plugins-text tsi databases
	zip -r9 all_data DFLDB.zip StarwindDB.zip Starwind.omwaddon requiredDataFiles.json

tsi: plugins-bin
	./build.sh tsi | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

vanilla: plugins-bin
	./build.sh vanilla | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

test-cs: plugins-bin
	./build.sh tsi nomp | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

cpp: plugins-bin
	cp -r ./src/"Community Patch Project"/Meshes .
	cp ./build/"Starwind Community Patch Project.esp" ./"Starwind Community Patch Project.omwaddon"

plugins-bin:
	mkdir -p build
	find ./src -type f -name "*.json" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.json$$/.esp/")"; tes3conv "$$1" "$$OUT_FILE"; mv "$$OUT_FILE" ./build/' sh {} \;

plugins-text:
	rm -rf Starwind.omwaddon StarwindMPRecords.omwaddon "Starwind Community Patch Project.omwaddon"
	cp $$HOME/.local/share/openmw/data/Starwind.omwaddon \
	$$HOME/.local/share/openmw/data/StarwindMPRecords.omwaddon \
	"$$HOME/.local/share/openmw/data/Starwind Community Patch Project.omwaddon" .
	find . -type f -name "*.omwaddon" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.omwaddon$$/.json/")"; tes3conv "$$1" "$$OUT_FILE"; rm -rf src/"$$OUT_FILE"; mv "$$OUT_FILE" src/' sh {} \;

deploy: clean plugins-text tsi
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

test: deploy
	rm -rf ~/openmw/tsi-client/server/data/cell/* ~/openmw/tsi-client/server/data/player/* ~/openmw/tsi-client/server/data/world/world.json
	~/openmw/tsi-client/tes3mp-server &
	~/openmw/tsi-client/tes3mp
	kill -9 $$(pgrep tes3mp-server)

edit-tsi: deploy
	openmw-cs $$HOME/.local/share/openmw/data/Starwind.omwaddon

edit-cpp: deploy
	openmw-cs $$HOME/.local/share/openmw/data/"Starwind Community Patch Project.omwaddon"

edit-mponly: clean plugins-text test-cs
	mv Starwind.omwaddon StarwindMPRecords.omwaddon $$HOME/.local/share/openmw/data/
	openmw-cs $$HOME/.local/share/openmw/data/"StarwindMPRecords.omwaddon"

databases: requiredfiles DFL espParser MIG

DFL:
	./databaseWriter.sh DFL

espParser:
	./databaseWriter.sh espParser

MIG:
	merchantIndexGrabber

requiredfiles:
	if ! grep -q "data=\"$$(pwd)\"" "$$HOME/.config/openmw/openmw.cfg"; then \
		echo "data=\"$$(pwd)\"" >> $$HOME/.config/openmw/openmw.cfg; \
	fi; \

	for m in Morrowind.esm Tribunal.esm Bloodmoon.esm Starwind.omwaddon; do \
		if ! grep -q "content=$$m" "$$HOME/.config/openmw/openmw.cfg"; then \
	        echo "content=$$m" >> "$$HOME/.config/openmw/openmw.cfg"; \
			touch $$m; \
		fi; \
	done; \

	t3crc

update-dialog:
	rm src/StarwindMPRecords.json
	tes3conv $$HOME/Downloads/StarwindMPRecords.json ./StarwindMPRecords.omwaddon && rm $$HOME/Downloads/StarwindMPRecords.json
	tes3conv ./StarwindMPRecords.omwaddon ./src/StarwindMPRecords.json
	mv ./StarwindMPRecords.omwaddon $$HOME/.local/share/openmw/data/

clean:
	rm -rf *.tmp *\~* src/*.esp *.omwaddon *.zip *.gz* *.json TES3MP-server build Meshes Morrowind.esm Tribunal.esm Bloodmoon.esm
