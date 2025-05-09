local core = require('openmw.core')
local modInfo = require('scripts.sw4.modinfo')
local I = require('openmw.interfaces')

local revision = core.API_REVISION
local RequiredRevision = 71

assert(revision >= RequiredRevision,
    string.format("This mod requires OpenMW version %s or higher. Current version: %s",
        RequiredRevision, revision))

I.Settings.registerPage {
    key = modInfo.name .. 'CorePage',
    l10n = modInfo.l10nName,
    name = "SWAMP - Starwind Modernization",
    description = "Wot are ye doing in mah SWAMP?\nRequires OpenMW 0.49."
}

I.Settings.registerPage {
    key = modInfo.name .. 'BlasterPage',
    l10n = modInfo.l10nName,
    name = "SWAMP - Blaster Settings",
    description = "Settings related to blaster damage and automatic firing. Speed multipliers scale based on your Marksman skill, with the full multiplier value being used at >= 100 Marksman.\nRequires OpenMW 0.49."
}

print(string.format("%s loaded version %s. Thank you for playing %s! <3",
    modInfo.logPrefix,
    modInfo.version,
    modInfo.name))
