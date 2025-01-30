#!/usr/bin/env bash

JUNK_CELL=("ashinabi, smuggler den"
"balmora, drarayne thelas' storage"
"balmora, hecerinde's house"
"baram ancestral tomb"
"berandas, propylon chamber"
"cavern of the incarnate"
"dantooine"
"dantooine, cavern"
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
"Nar Shaddaa, Hutt Base"
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
    # All mods dependent on enhanced are merged in the first phase
    # merge_to_master "bings race pack.esp" "Starwind Enhanced.esm"
    # merge_to_master "StarwindRacesJMC.esp" "Starwind Enhanced.esm"
    # merge_to_master "Starwind Enhanced.esm" StarwindRemasteredPatch.esm
    # Vanilla phase
    # merge_to_master alt_start1.5.esp StarwindRemasteredPatch.esm
    merge_to_master StarwindVvardenfell.esp StarwindRemasteredPatch.esm
    merge_to_master "Starwind Community Patch Project.esp" StarwindRemasteredPatch.esm
    merge_to_master naboo.esp StarwindRemasteredPatch.esm
    merge_to_master --remove-deleted StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
    mv StarwindRemasteredV1.15.esm Starwind.omwaddon

    # Patch phase to implement components which cannot otherwise be repaired, primarily due to --remove-deleted removing deleted records we actually totally did want
    merge_to_master deletedbirthsigns.esp Starwind.omwaddon
    merge_to_master beastlair.esp Starwind.omwaddon

    if [ "$1" != "nomp" ]; then
        merge_to_master StarwindMPRecords.esp Starwind.omwaddon
    fi
    # Independent phase
    merge_to_master PartyHats.esp Starwind.omwaddon
    # There be dragons in the dialog trees (spicy)
    mv Starwind.omwaddon Starwind.esp
    # tes3cmd delete --type INFO --type DIAL --match "DELE" --match "Greeting 0" Starwind.esp
    # tes3cmd delete --type INFO --exact-id "19191290671947220251" Starwind.esp
    # Normalize enchantment values
    tes3cmd modify --sub-no-match "ENAM:" --type CLOT --type ARMO --type WEAP --run '$R->set({f=>"enchantment"}, 375)' Starwind.esp
    mv Starwind.esp Starwind.omwaddon
}

do_sp_merge() {
    merge_to_master "Starwind Enhanced.esm" StarwindRemasteredPatch.esm
    merge_to_master "Starwind Community Patch Project.esp" StarwindRemasteredPatch.esm
    merge_to_master --remove-deleted StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
    mv StarwindRemasteredV1.15.esm vanilla_Starwind.omwaddon
    merge_to_master deletedbirthsigns.esp vanilla_Starwind.omwaddon
}

do_standalone_merge() {
    merge_to_master "Starwind Enhanced.esm" StarwindRemasteredPatch.esm
    merge_to_master "Starwind Community Patch Project.esp" StarwindRemasteredPatch.esm
    merge_to_master --remove-deleted StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
    mv StarwindRemasteredV1.15.esm vanilla_Starwind.omwaddon
    merge_to_master deletedbirthsigns.esp vanilla_Starwind.omwaddon
    mv vanilla_Starwind.omwaddon Starwind.esp
    echo "Merging vanilla data..."
    addVanillaRefs
    echo "Successfully pulled data from vanilla ESM files"
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

    # As it turns out, placing the DELE flag on cells, much like the pirate code, is simply a guideline. This patch was always unnecessary to begin with.
    # However, it's MTM itself that's been deleting the cells on our behalf, since it *does* have the deleted flag and in theory, should be deleted.
    # We dump the cell out as a separate component here, remove deleted instances manually, then merge it back in later.
    # The resulting merged plugin should have the beast lair cell entirely removed, then have the fresh copy re-added onto it.
    # This MIGHT mean that --remove-deleted flag cannot be used on the resulting merged plugin as the beast lair cell may be at risk of being removed again.
    tes3cmd dump --type CELL --exact-id "Tatooine, Beast's Lair" --raw-with-header beastlair.esp StarwindRemasteredPatch.esm
    tes3cmd delete --instance-match "DELE" beastlair.esp

    # These instances of shade only exist in the original esm files, we'll probably not need these later when MQ is reimplemented
    #tes3cmd delete --type CELL --exact-id "Tatooine, Cantina" --instance-match "ObjIdx:1074 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade
    #tes3cmd delete --type CELL --exact-id "Tatooine, Medical Bay" --instance-match "ObjIdx:2465 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade
    #tes3cmd delete --type CELL --exact-id "Tatooine, Sandriver" --instance-match "ObjIdx:1115 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade
    #tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2955 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Thegg
    #tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2956 " StarwindRemasteredPatch.esm 2> grep -v "Can't find \"Data Files\"" # Shade

    # Bing's race pack creates a duplicate of the customs npc
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Customs" --instance-match "ObjIdx:16453 " StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Customs" --instance-match "ObjIdx:16507 " "bings race pack.esp"

    # Fuck Ny Vash
    tes3cmd delete --type CELL --exact-id "Tatooine, Sandriver" --instance-match "ObjIdx:1109 " StarwindRemasteredPatch.esm # Upgrade Droid

    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2951 " StarwindRemasteredPatch.esm # Upgrade Droid
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:2952 " StarwindRemasteredPatch.esm # meditation pillar
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:3024 " StarwindRemasteredPatch.esm # Bankref chest
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:16384 " StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm # Mods Droid (replaced by MP plugin)
    tes3cmd delete --type CELL --exact-id "The Outer Rim, Freighter" --instance-match "ObjIdx:16400 " StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm # Mods Droid platform (replaced by MP plugin)

    # Embassy doors were replaced with more lenient scripts
    tes3cmd delete --type CELL --exact-id "Manaan, Republic Embassy" --instance-match "ObjIdx:6771 " StarwindRemasteredV1.15.esm
    tes3cmd delete --type CELL --exact-id "Manaan, Sith Embassy" --instance-match "ObjIdx:9107 " StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

    # We laid out the cell ourselves
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Makacheesa Market" StarwindVvardenfell.esp
    # Moved the ramp so the door destination changed
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Vvardenfell Hanger" --instance-match "ObjIdx:14 " StarwindVvardenfell.esp
    # We use a different cell than the alt start mod
    tes3cmd delete --type CELL --exact-id "Imperial Prison Ship" alt_start1.5.esp
    # Replace vanilla leveled list with our own
    tes3cmd modify --replace "/random gold/tsi_gold/" StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm

    # Add interactive kolto tanks
    echo "Applying patches..."
    tes3cmd modify --type CELL --replace "/SW_ManaKoltoTank/tsi_kolto_nowall/" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm
    tes3cmd modify --type CELL --replace "/SW_ManaKoltoMedTank/tsi_kolto_wall/" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

    # Original plugin is dirty
    echo "Cleaning bings race pack..."
    tes3cmd delete --type GMST "bings race pack.esp"
    tes3cmd delete --type CELL --exterior "bings race pack.esp"
    tes3cmd delete --type CELL --exact-id "nar shaddaa, h.t. parnell's oddities" "bings race pack.esp"

    # Hack to remove Enhanced dependency and any modifications to its references
    # Keep the patches just in case we decide to remove enhanced for some reason
    #echo "Stripping dependency on Starwind Enhanced..."
    #tes3cmd modify --type TES3 --replace "/Starwind Enhanced/StarwindRemasteredPatch/" "bings race pack.esp" StarwindRacesJMC.esp
    #tes3cmd modify --type TES3 --replace "/431652/11437434/" "bings race pack.esp" StarwindRacesJMC.esp
    #tes3cmd delete --type CELL --instance-match "MastIdx:6" "bings race pack.esp" StarwindRacesJMC.esp
    #tes3cmd delete --type CELL --instance-match "SWE_DoorFrameLight1" "bings race pack.esp"
    #tes3cmd delete --type CELL --exterior alt_start1.5.esp "bings race pack.esp"
    #tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Club Arkngthand" "bings race pack.esp"

    # Broken mp refs from JMC's
    tes3cmd delete --type CELL --exact-id "Lok, Graveridge Pawnshop" --instance-match "SW_Vhadeer" StarwindRemasteredPatch.esm StarwindRacesJMC.esp
    tes3cmd delete --type CELL --exact-id "nar shaddaa, 168 alley east" --exact-id "nar shaddaa, office building" --instance-match "SW_DipManager" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm
    # This one is extra weird as somehow both plugins have two unique definitions of the same ref under the same index
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Speeder Shop" --instance-match "SW_NarSpeederMerch" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "manaan, yortal's junkpile" --instance-match "SW_Yortal" StarwindRemasteredV1.15.esm
    tes3cmd delete --type CELL --exact-id "nar shaddaa" --instance-match "sw_quarren" StarwindRemasteredV1.15.esm
    tes3cmd delete --type CELL --instance-match "Deleted" StarwindRacesJMC.esp

    # Broken mp refs from bing's
    tes3cmd delete --type CELL --exact-id "Taris, Upper City Cantina" --instance-match "SW_TarisHuttRagax" StarwindRemasteredPatch.esm
    tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Hutt Cartel" --instance-match "SW_HuttBadhiya" StarwindRemasteredPatch.esm

    # Remove lateng disable script
    tes3cmd delete --type SCPT --exact-id "SW_CourteCompScript" StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm
    tes3cmd modify --type NPC_ --exact-id "sw_czerkacourte22"  --replace "/SW_CourteCompScript//" StarwindRemasteredPatch.esm

    # Get rid of Killua since we don't use her
    tes3cmd delete --type CELL --instance-match "SW_ShipQuester" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

    # Actually don't use the SP DRM in our plugin :todd:
    # Heavyjunk object, then scripts, then global variables
    tes3cmd delete --exact-id "Nab_HeaviestJunk" \
        --exact-id 'passtheday' --exact-id 'nab_byebye' \
        --exact-id 'dayispassed' --exact-id 'mothball' --exact-id 'NerevarAwakened ' naboo.esp

    # Delete script attachments separately as sub-match doesn't work with the exact-id parsing
    tes3cmd delete --sub-match "Script:Nab_ByeBye" naboo.esp
    tes3cmd delete --sub-match "Script:passtheday" naboo.esp
    tes3cmd delete --type CELL --instance-match "MastIdx:4" --instance-match "MastIdx:5" naboo.esp
else
    tes3cmd modify --type SCPT --replace "/who's ship/whose ship/" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm
fi
# Just cleaning
#This script is actually SW_traveltokashyyk but I figure if anybody was actually using this script the typo would have been noticed a long time ago
# When I ran a global search against it and tried to dump instances of it out of the plugin it didn't appear to have any references
tes3cmd delete --type SCPT --exact-id sw_ StarwindRemasteredPatch.esm

# Destroy bytecode for all plugins
echo "Destroying bytecode, this may take a while..."
tes3cmd modify --type SCPT --sub-match "Bytecode:" --replace "/.*//" *.esm *.esp 2> /dev/null > /dev/null

echo "Fixing typos..."
# Fix typos in names
tes3cmd modify --type WEAP --exact-id "sw_grplasm" --replace "/Name:44mm Pasma Grenade/Name:44mm Plasma Grenade/" StarwindRemasteredPatch.esm
tes3cmd modify --type ACTI --replace "/Name:Asteriod/Name:Asteroid/" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

# Delete junk cells added by the CS bug
echo "Cleaning junk cells..."
for cell in "${JUNK_CELL[@]}"; do tes3cmd delete --type CELL --type PGRD --hide-backups --exact-id "$cell" StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm; done
tes3cmd delete --type CELL --exterior StarwindRemasteredV1.15.esm StarwindRemasteredPatch.esm

# MTM removes deleted birthsigns, which is a problem because we don't want vanilla birthsigns
tes3cmd dump --type BSGN --match "deleted" --raw-with-header deletedbirthsigns.esp StarwindRemasteredV1.15.esm

# I'll fix gavan myself in CPP because nobody seems to know exactly what's going on here
tes3cmd dump --type CELL --exact-id "Tatooine" --instance-match "ObjIdx:397 " StarwindRemasteredPatch.esm

# Turn undead was used on lightsabers because reasons
tes3cmd delete --type GMST --exact-id "sEffectTurnUndead" StarwindRemasteredPatch.esm
tes3cmd delete --type MGEF --exact-id "101" StarwindRemasteredPatch.esm # turn undead enum

# Damn sneaky rakghouls all over the galaxy!
tes3cmd delete --type LEVC --exact-id sw_sandcreatures --sub-match "SW_Rakhoul1" StarwindRemasteredPatch.esm StarwindRemasteredV1.15.esm

echo "Patching enhanced..."
# Basically every edit Enhanced attempts to make to vanilla seems to have the refNums corrupted, so we manually handle the deletions here
# Fortunately almost nothing is actively modified, just marked as deleted
# Only one single object (8517) deleted appears to have accurate refNums.
# Seems like a possible consequence of Starwind itself updating under enhanced's nose, but either way it's not a big deal.

# There are two edits to this cell - one moved rock, and tiny gavan. I don't know why either exist.
tes3cmd delete --type CELL --exact-id "Tatooine" "Starwind Enhanced.esm"
# Enhanced deletes this one table, not sure why
tes3cmd delete --type CELL --exact-id "Taris, Central Plaza" --instance-match "MastIdx:5" "Starwind Enhanced.esm"
tes3cmd delete --type CELL --exact-id "Taris, Central Plaza" --instance-match "ObjIdx:8517" StarwindRemasteredPatch.esm
# Do you have something against this table?
tes3cmd delete --type CELL --match "Taris, Central Plaza: Government Office" --instance-match "MastIdx:5" --instance-match "SW_In_TableGround" "Starwind Enhanced.esm"
tes3cmd delete --type CELL --match "Taris, Central Plaza: Government Office" --instance-match "SW_In_TableGround" StarwindRemasteredPatch.esm
tes3cmd delete --type CELL --exact-id "Taris, Central Plaza: Capital Tower Upper Level" --instance-match "SW_In_TableGround" StarwindRemasteredPatch.esm
tes3cmd delete --type CELL --exact-id "Taris, Central Plaza: Capital Tower Upper Level" --instance-match "MastIdx:5" --instance-match "SW_In_TableGround" StarwindRemasteredPatch.esm
# Cantina Signs
tes3cmd delete --type CELL --exact-id "Taris, Upper City Cantina" --instance-match "Sign" StarwindRemasteredPatch.esm
tes3cmd delete --type CELL --exact-id "Taris, Upper City Cantina" --instance-match "MastIdx:5" "Starwind Enhanced.esm"
tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Lower City" --instance-match "SW_SignCantina" --instance-match "X:9336" StarwindRemasteredPatch.esm
tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Lower City" --instance-match "SW_SignCantina" --instance-match "MastIdx:5" "Starwind Enhanced.esm"
tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Customs" --instance-match "SW_SignCantina" StarwindRemasteredPatch.esm
tes3cmd delete --type CELL --exact-id "Nar Shaddaa, Customs" --instance-match "SW_SignCantina" --instance-match "MastIdx:5" "Starwind Enhanced.esm"
# One moved object?
tes3cmd delete --type CELL --exact-id "Starwind test cell" --instance-match "MastIdx:5" "Starwind Enhanced.esm"
# Mandalorian chest pieces still use the original bodyparts
tes3cmd delete --type ARMO --match "swe_mandochest" --sub-match "Female_Body_ID:" "Starwind Enhanced.esm"
# Golden doors have the `DoNothing` script on them, for reasons
tes3cmd delete --type DOOR --sub-match "DoNothing" --exact-id "in_t_door_small" StarwindRemasteredV1.15.esm

if [ "$1" = "tsi" ]; then
    do_mp_merge "$2"
    mv Starwind.omwaddon ..
elif [ "$1" = "standalone" ]; then
    do_standalone_merge
    mv Starwind.esp ..
else
    do_sp_merge
    mv vanilla_Starwind.omwaddon ..
fi

cd .. && rm -rf build

echo "Done!"
