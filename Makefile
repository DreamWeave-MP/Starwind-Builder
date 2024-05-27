all: clean plugins-text tsi databases
	zip -r9 all_data DFLDB.zip StarwindDB.zip Starwind.omwaddon requiredDataFiles.json

tsi: plugins-bin
	./build.sh tsi | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

vanilla: plugins-bin
	./build.sh vanilla | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

cpp: plugins-bin
	cp "build/Starwind Community Patch Project.esp" "src/Community Patch Project/Starwind Community Patch Project.omwaddon"
	cd "src/Community Patch Project" && zip -r9 --must-match --recurse-paths \
	Starwind_Community_Patch_Project.zip \
	Meshes/ \
	"Starwind Community Patch Project.omwaddon" \
	&& mv Starwind_Community_Patch_Project.zip ../../

plugins-bin:
	mkdir -p build
	find ./src -type f -name "*.json" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.json$$/.esp/")"; tes3conv "$$1" "$$OUT_FILE"; mv "$$OUT_FILE" ./build/' sh {} \;
	mv ./build/"Starwind Enhanced.esp" ./build/"Starwind Enhanced.esm"

plugins-text:
	rm -rf Starwind.omwaddon StarwindMPRecords.omwaddon "Starwind Community Patch Project.omwaddon"
	cp $$HOME/.local/share/openmw/data/Starwind.omwaddon \
	$$HOME/.local/share/openmw/data/StarwindMPRecords.omwaddon \
	"$$HOME/.local/share/openmw/data/Starwind Community Patch Project.omwaddon" .
	find . -type f -name "*.omwaddon" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.omwaddon$$/.json/")"; tes3conv "$$1" "$$OUT_FILE"; rm -rf src/"$$OUT_FILE"; mv "$$OUT_FILE" src/' sh {} \;

deploy: clean plugins-text tsi
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

mp-start:
	sed -i 's/destinationAddress = 34.123.56.114/destinationAddress = localhost/' ~/openmw/tsi-client/tes3mp-client-default.cfg
	rm -rf ~/openmw/tsi-client/server/data/cell/* ~/openmw/tsi-client/server/data/player/* ~/openmw/tsi-client/server/data/world/world.json
	~/openmw/tsi-client/tes3mp-server &
	~/openmw/tsi-client/tes3mp
	kill -9 $$(pgrep tes3mp-server)
	sed -i 's/destinationAddress = localhost/destinationAddress = 34.123.56.114/' ~/openmw/tsi-client/tes3mp-client-default.cfg

test-mp: deploy mp-start

test-full: clean plugins-text tsi
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/
	openmw-cs $$HOME/.local/share/openmw/data/Starwind.omwaddon
	rm -rf ~/openmw/tsi-client/server/data/cell/* ~/openmw/tsi-client/server/data/player/* ~/openmw/tsi-client/server/data/world/world.json
	~/openmw/tsi-client/tes3mp-server &
	~/openmw/tsi-client/tes3mp
	kill -9 $$(pgrep tes3mp-server)

edit-tsi: deploy
	openmw-cs $$HOME/.local/share/openmw/data/Starwind.omwaddon

edit-cpp: clean plugins-text plugins-bin
	mv build/"Starwind Community Patch Project.esp" $$HOME/.local/share/openmw/data/"Starwind Community Patch Project.omwaddon"
	openmw-cs $$HOME/.local/share/openmw/data/"Starwind Community Patch Project.omwaddon"

edit-mponly: clean plugins-text plugins-bin
	./build.sh tsi nomp | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"
	mv Starwind.omwaddon StarwindMPRecords.omwaddon $$HOME/.local/share/openmw/data/
	openmw-cs $$HOME/.local/share/openmw/data/"StarwindMPRecords.omwaddon"

databases: requiredfiles DFL espParser MIG

DFL: requiredfiles
	./databaseWriter.sh DFL

espParser:
	./databaseWriter.sh espParser

kTools: config
	t3crc --use-paths
	./databaseWriter.sh kTools

MIG:
	merchantIndexGrabber

config:
	if ! grep -q "data=\"$$(pwd)\"" "$$HOME/.config/openmw/openmw.cfg"; then \
		echo "data=\"$$(pwd)\"" >> $$HOME/.config/openmw/openmw.cfg; \
	fi; \

	touch fake.esp; \
	for m in Morrowind.esm Tribunal.esm Bloodmoon.esm Starwind.omwaddon; do \
		if ! grep -q "content=$$m" "$$HOME/.config/openmw/openmw.cfg"; then \
	        echo "content=$$m" >> "$$HOME/.config/openmw/openmw.cfg"; \
			echo $$m; \
			if ! [ $$m = Starwind.omwaddon ]; then \
				tes3cmd dump --raw-with-header $$m fake.esp; \
			fi; \
		fi; \
	done; \
	rm fake.esp

requiredfiles: config
	t3crc

update-dialog:
	rm src/StarwindMPRecords.json
	tes3conv $$HOME/Downloads/StarwindMPRecords.json ./StarwindMPRecords.omwaddon && rm $$HOME/Downloads/StarwindMPRecords.json
	tes3conv ./StarwindMPRecords.omwaddon ./src/StarwindMPRecords.json
	mv ./StarwindMPRecords.omwaddon $$HOME/.local/share/openmw/data/

clean:
	rm -rf *.tmp *\~* src/*.esp *.omwaddon *.zip *.gz* *.json TES3MP-server build Meshes fake.esp Morrowind.esm Tribunal.esm Bloodmoon.esm
