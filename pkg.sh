#!/bin/sh
set -eu

file_name=momw-patches.zip

cat > version.txt <<EOF
Mod version: $(git describe --tags)
EOF

zip --must-match --recurse-paths \
    $file_name \
    "fomod" \
    "01 BCOM+Imperial Towns Revamp Patch" \
    "02 Uvirith's Legacy+TR Addon Patched" \
    "03 BCOM+Ghastly Glowyfence+Dynamic Distant Buildings Patch" \
    "04 Draggle-Tail Shack Price Adjustment" \
    "05 AFFresh+Samarys Ancestral Tomb Expanded Patch" \
    "06 Sophia's Clear Blue Skies" \
    "07 mtrPermanentQuestCorpsesRandomizer+Shipyards of Vvardenfell Patch" \
    "08 Trackless Grazeland For OpenMW" \
    "09 Dynamic Music - Secrets of the Crystal City Soundbank" \
    "10 Ebonheart Underworks MOMW Patch" \
    "11 Mamaea Awakened OpenMW Patch" \
    "12 AFFresh+BCOM Patch" \
    "13 Doors of Oblivion+TOTSP Patch" \
    "14 Mines and Caverns MOMW Patch" \
    "15 Perfectly Proficient Parasol Particles Performance Patch" \
    "16 Uvirith's Legacy+BCOM Arena Patch" \
    "17 Uvirith's Legacy+Daedric Shrine Overhaul Molag Bal Patch" \
    "18 Uvirith's Legacy+Daedric Shrine Overhaul Sheogorath Patch" \
    "19 Uvirith's Legacy+OAAB Tel Mora Patch" \
    "20 Netch Bump Mapped Mesh Fix" \
    "21 Imperial Factions Patched" \
    "22 AFFresh+Adanumuran Reclaimed Patch" \
    "23 Dynamic Music - Terror of Tel Amur Soundbank" \
    "24 BCOM+Dagon Fel Lighthouse+Remiros' Groundcover Patch" \
    "25 Dynamic Music - Songbook of the North Soundbank" \
    "26 Expansion Resource Conflicts MET'd" \
    "27 Sophie's BCOM Concept Art Skar Upscale" \
    "28 Morrowind Anti-Cheese+Quest Voice Greetings Patch" \
    "29 Sophie's Buoyant Armigers Armor Glow" \
    "30 Sophie's Normal Maps for Morrowind Telvanni Patch" \
    "31 Sophie's Tamriel Data Telvanni Cephalopod Armor Upscale" \
    "32 OpenMW Fixes For Uvirith's Legacy" \
    "33 AFFresh+Library of Vivec Enhanced Patch" \
    "34 Sophie's Logs On Fire+BCOM Patch" \
    "35 The Forgotten Shields - Artifacts Patched" \
    "36 Blademeister+Adanumuran Reclaimed Patch" \
    "37 Helm of Tohan Naturalized for Daedric Shrine Overhaul Sheogorath" \
    "38 Flies Patched" \
    "39 Signposts Retextured TR Updated" \
    "40 NOD+Library of Vivec Enhanced Patch" \
    "41 Better Clothes Complete Shoe Fix" \
    "42 Whiskers Patch for MMH Version All NPCs and Base Replace Fixed Meshes" \
    "43 Blademeister+Daedric Shrine Overhaul Sheogorath Patch" \
    CHANGELOG.md \
    LICENSE \
    README.md \
    version.txt \
    --exclude \*.json \
    --exclude \*.yaml \
    --exclude ./03\ BCOM+Ghastly\ Glowyfence+Dynamic\ Distant\ Buildings\ Patch/scripts\* \
    --exclude ./07\ mtrPermanentQuestCorpsesRandomizer+Shipyards\ of\ Vvardenfell\ Patch/scripts\* \
    --exclude ./10\ Ebonheart\ Underworks\ MOMW\ Patch/scripts\* \
    --exclude ./11\ Mamaea\ Awakened\ OpenMW\ Patch/scripts\* \
    --exclude ./16\ Uvirith\'s\ Legacy+BCOM\ Arena\ Patch/scripts\* \
    --exclude ./19\ Uvirith\'s\ Legacy+OAAB\ Tel\ Mora\ Patch/scripts\* \
    --exclude ./28\ Morrowind\ Anti\-Cheese+Quest\ Voice\ Greetings\ Patch/scripts\* \
    --exclude ./32\ OpenMW\ Fixes\ For\ Uvirith\'s\ Legacy/scripts\* \
    --exclude ./33\ AFFresh+Library\ of\ Vivec\ Enhanced\ Patch/scripts\* \
    --exclude ./35\ The\ Forgotten\ Shields\ \-\ Artifacts\ Patched/scripts\* \
    --exclude ./38\ Flies\ Patched/scripts\* \
    --exclude ./43\ Blademeister+Daedric\ Shrine\ Overhaul\ Sheogorath\ Patch/scripts\* 
sha256sum $file_name > $file_name.sha256sum.txt
sha512sum $file_name > $file_name.sha512sum.txt
