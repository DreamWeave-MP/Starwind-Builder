build: plugins-bin
	./build.sh 2> grep -v "Can't find \"Data Files\"" | grep -v "<DATADIR> is\|Output saved in\|Original backed up to\|Can't find \"Data Files\"\|Log"

plugins-bin:
	mkdir -p build
	find ./src -type f -name "*.json" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.json$$/.esp/")"; tes3conv "$$1" "$$OUT_FILE"; mv "$$OUT_FILE" ./build/' sh {} \;

plugins-text:
	find . -type f -name "*.omwaddon" -exec sh -c 'OUT_FILE="$$(echo "$$1" | sed "s/\.omwaddon$$/.json/")"; tes3conv "$$1" "$$OUT_FILE"; rm -rf src/"$$OUT_FILE"; mv "$$OUT_FILE" src/' sh {} \;

deploy: build
	mv Starwind.omwaddon $$HOME/.local/share/openmw/data/

clean:
	rm -rf *.tmp *\~* src/*.esp *.omwaddon build
