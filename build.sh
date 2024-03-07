#!/usr/bin/env bash

JUNK_CELL=("ashinabi, smuggler den"
"balmora, drarayne thelas' storage"
"balmora, hecerinde's house"
"baram ancestral tomb"
"berandas, propylon chamber"
"cavern of the incarnate"
"falensarano, propylon chamber"
"gnisis, arvs-drelen"
"gnisis, madach tradehouse"
"hairat-vassamsi egg mine, queen's lair"
"kashyyk"
"koal cave"
"kogoruhn, hall of maki"
"kogoruhn, vault of aerode"
"moonmoth legion fort, prison towers"
"mournhold, great bazaar"
"mournhold, plaza brindisi dorom"
"mournhold, royal palace: basement"
"mournhold, royal palace: helseth's chambers"
"nerano ancestral tomb"
"pelagiad, south wall"
"seyda neen, census and excise office"
"solstheim, gyldenhul barrow"
"solstheim, legge"
"surirulk"
"testcell"
"toddtest"
"tukushapal"
"vivec, palace of vivec"
"yakin")

do_mp_merge() {
    # Merge the plugins into the master
    merge_to_master alt_start1.5.esp StarwindRemasteredPatch.esm
    merge_to_master StarwindVvardenfell.esp StarwindRemasteredPatch.esm
    merge_to_master "bings race pack.esp" StarwindRemasteredPatch.esm
    merge_to_master "StarwindRacesJMC.esp" StarwindRemasteredPatch.esm
    merge_to_master "Starwind Community Patch Project.esp" StarwindRemasteredPatch.esm
    merge_to_master --remove-deleted StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
    mv StarwindRemasteredV1.15.esm Starwind.omwaddon
    merge_to_master deletedbirthsigns.esp Starwind.omwaddon
    merge_to_master StarwindMPRecords.esp Starwind.omwaddon
}

do_sp_merge() {
    # Merge the plugins into the master
    merge_to_master "Starwind Community Patch Project.esp" StarwindRemasteredPatch.esm
    merge_to_master --remove-deleted StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
    mv StarwindRemasteredV1.15.esm Starwind.omwaddon
    merge_to_master deletedbirthsigns.esp Starwind.omwaddon
}

cd build

if [ -f "../StarwindRemasteredV1.15.esm" ]; then
    cp "../StarwindRemasteredV1.15.esm" .
else
    cp "/plugins/StarwindRemasteredV1.15.esm" .
fi

if [ "$1" = "tsi" ]; then
    if [ -f "../nomq_StarwindRemasteredPatch.esm" ]; then
        cp "../nomq_StarwindRemasteredPatch.esm" StarwindRemasteredPatch.esm
    else
        cp "/plugins/nomq_StarwindRemasteredPatch.esm" StarwindRemasteredPatch.esm
    fi
else
    if [ -f "../base_StarwindRemasteredPatch.esm" ]; then
        cp "../base_StarwindRemasteredPatch.esm" StarwindRemasteredPatch.esm
    else
        cp "/plugins/base_StarwindRemasteredPatch.esm" StarwindRemasteredPatch.esm
    fi
fi

# Remove replaced records, make mp-specific patches

if [ "$1" = "tsi" ]; then
    # Delete references which should not exist in mp
    # Pre-taris outpost, zelka forn, shade in tat cantina and shade in tat med bay
    echo "Deleting overridden references..."
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Customs" --instance-match "ObjIdx:16461 " StarwindRemasteredPatch.esm # Customs forcefield, maybe we can re-add this
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza" --instance-match "ObjIdx:6874 " StarwindRemasteredPatch.esm # Pre-Taris Outpost entrance
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza" --instance-match "ObjIdx:7201 " StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza" --instance-match "ObjIdx:7202 " StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza" --instance-match "ObjIdx:7203 " StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza" --instance-match "ObjIdx:7204 " StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza" --instance-match "ObjIdx:7205 " StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Taris, Ruined Plaza: Medical Bay" --instance-match "ObjIdx:6749 " StarwindRemasteredPatch.esm # Zelka Forn

    # The existence of this cell is in limbo it seems, idfk what's going on
    tes3cmd delete --type CELL --exact-id "Tatooine" --instance-match "Tatooine, Beast's Lair" StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm # Door to beasts lair (deleted cell)
    # These instances of shade only exist in the original esm files, we'll probably not need these later when MQ is reimplemented
    #tes3cmd delete --type CELL --exact-id "Tatooine, Cantina" --instance-match "ObjIdx:1074 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade
    #tes3cmd delete --type CELL --exact-id "Tatooine, Medical Bay" --instance-match "ObjIdx:2465 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade
    #tes3cmd delete --type CELL --exact-id "Tatooine, Sandriver" --instance-match "ObjIdx:1115 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade
    #tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2955 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Thegg
    #tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2956 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade

    # Fuck Ny Vash
    tes3cmd delete --type CELL --exact-id "Tatooine, Sandriver" --instance-match "ObjIdx:1109 " StarwindRemasteredPatch.esm # Upgrade Droid

    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2951 " StarwindRemasteredPatch.esm # Upgrade Droid
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2952 " StarwindRemasteredPatch.esm # meditation pillar
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:3024 " StarwindRemasteredPatch.esm # Bankref chest
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:16384 " StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm # Mods Droid (replaced by MP plugin)
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:16400 " StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm # Mods Droid platform (replaced by MP plugin)

    # We laid out the cell ourselves
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Makacheesa Market" StarwindVvardenfell.esp
    # We use a different cell than the alt start mod
    tes3cmd delete --type CELL --exact-id "Imperial Prison Ship" alt_start1.5.esp

    # Add interactive kolto tanks
    echo "Applying patches..."
    tes3cmd modify --type CELL --replace "/SW_ManaKoltoTank/tsi_kolto_nowall/" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm
    tes3cmd modify --type CELL --replace "/SW_ManaKoltoMedTank/tsi_kolto_wall/" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

    # Original plugin is dirty
    echo "Cleaning bings race pack..."
    tes3cmd delete --type GMST "bings race pack.esp"
    tes3cmd delete --type CELL --exterior "bings race pack.esp"
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Club Arkngthand" "bings race pack.esp"
    tes3cmd delete --type CELL --exact-id "nar shaddaa, h.t. parnell's oddities" "bings race pack.esp"

    # Hack to remove Enhanced dependency and any modifications to its references
    echo "Stripping dependency on Starwind Enhanced..."
    tes3cmd modify --type TES3 --replace "/Starwind Enhanced/StarwindRemasteredPatch/" "bings race pack.esp" StarwindRacesJMC.esp
    tes3cmd modify --type TES3 --replace "/431652/11437434/" "bings race pack.esp" StarwindRacesJMC.esp
    tes3cmd delete --type CELL --instance-match "MastIdx:6" "bings race pack.esp" StarwindRacesJMC.esp
    tes3cmd delete --type CELL --instance-match "SWE_DoorFrameLight1" "bings race pack.esp"

    tes3cmd delete --type CELL --exterior alt_start1.5.esp "bings race pack.esp"
fi

# Just cleaning
#This script is actually SW_traveltokashyyk but I figure if anybody was actually using this script the typo would have been noticed a long time ago
# When I ran a global search against it and tried to dump instances of it out of the plugin it didn't appear to have any references
tes3cmd delete --type SCPT --exact-id sw_ StarwindRemasteredV1.15.esm

# Delete junk cells added by the CS bug
echo "Cleaning junk cells..."
for cell in "${JUNK_CELL[@]}"; do tes3cmd delete --type CELL --type PGRD --hide-backups --exact-id "$cell" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm; done
tes3cmd delete --type CELL --exterior StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

# MTM removes deleted birthsigns, which is a problem because we don't want vanilla birthsigns
tes3cmd dump --type BSGN --match "deleted" --raw-with-header deletedbirthsigns.esp StarwindRemasteredV1.15.esm

if [ "$1" = "tsi" ]; then
    do_mp_merge
else
    do_sp_merge
fi

mv Starwind.omwaddon ..

cd .. && rm -rf build

echo "Done!"
