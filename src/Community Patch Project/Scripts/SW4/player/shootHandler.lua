local animation = require('openmw.animation')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local I = require('openmw.interfaces')

local forceAttack = false
local forceRelease = false
local BlasterData = require('scripts.sw4.data.blasters')
local LogMessage = require('scripts.sw4.helper.logmessage')
local ModInfo = require('scripts.sw4.modinfo')

local AutoBlasterStorage = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'BlasterGroupAutomatic')
local SpeedBlasterStorage = storage.globalSection('SettingsGlobal' .. ModInfo.name .. 'BlasterGroupSpeed')

local WeaponSlot = self.type.EQUIPMENT_SLOT.CarriedRight
local CrossbowType = types.Weapon.TYPE.MarksmanCrossbow
local BowType = types.Weapon.TYPE.MarksmanBow

local Stats = self.type.stats
local Skills = Stats.skills
local Attributes = Stats.attributes

local SkillMarksman = Skills.marksman(self)

--- Handles animation text keys and shoot overrides for the player
--- Allows automatic shooting of blasters
---@class ShootManager
---@field onFrame fun(dt: number): nil If signalled by the animation handlers, will force the player to engage or release an attack
---@field textKeyHandler fun(_: string, key: string): nil Signals the onFrame handler to start/release an attack depending on animation state
local ShootManager = {
    BlasterTypes = BlasterData.Types,
    SpeedMultipliers = {
        [BlasterData.Types.Pistol] = 2.5,
        [BlasterData.Types.Rifle] = 1.5,
        [BlasterData.Types.Repeater] = 10.0,
        [BlasterData.Types.Sniper] = 0.5,
    },

    SettingNames = {
        AutoBlasters = 'AutomaticBlastersEnable',
        AutoPistols = 'AutomaticPistolsEnable',
        AutoRepeaters = 'AutomaticRepeatersEnable',
        AutoRifles = 'AutomaticRiflesEnable',
        AutoSnipers = 'AutomaticSnipersEnable',
        SpeedMultPistol = 'SpeedMultPistol',
        SpeedMultRifle = 'SpeedMultRifle',
        SpeedMultRepeater = 'SpeedMultRepeater',
        SpeedMultSniper = 'SpeedMultSniper',
    },

    onFrame = function(dt)
        if forceAttack then
            self.controls.use = 1
        elseif forceRelease then
            self.controls.use = 0
            forceRelease = false
        end
    end,
}

--- Maps blaster types to their respective speed setting names for fast access
local BlasterTypesToAutoSettings = {
    [BlasterData.Types.Pistol] = ShootManager.SettingNames.AutoPistols,
    [BlasterData.Types.Rifle] = ShootManager.SettingNames.AutoRifles,
    [BlasterData.Types.Repeater] = ShootManager.SettingNames.AutoRepeaters,
    [BlasterData.Types.Sniper] = ShootManager.SettingNames.AutoSnipers,
}

local BlasterTypesToSpeedSettings = {
    [BlasterData.Types.Pistol] = ShootManager.SettingNames.SpeedMultPistol,
    [BlasterData.Types.Rifle] = ShootManager.SettingNames.SpeedMultRifle,
    [BlasterData.Types.Repeater] = ShootManager.SettingNames.SpeedMultRepeater,
    [BlasterData.Types.Sniper] = ShootManager.SettingNames.SpeedMultSniper,
}

---@alias BlasterType number

---@param blasterType BlasterType
---@return boolean
function ShootManager.canFireAutomatically(blasterType)
    local blasterSetting = AutoBlasterStorage:get(ShootManager.SettingNames.AutoBlasters)
    if not blasterSetting then return false end

    return AutoBlasterStorage:get(BlasterTypesToAutoSettings[blasterType])
end

function ShootManager.isRangedWeapon(equippedWeapon)
    local weaponRecord = equippedWeapon.type.records[equippedWeapon.recordId]
    return weaponRecord.type == CrossbowType or weaponRecord.type == BowType
end

function ShootManager.getBlasterType()
    local blaster = self.type.getEquipment(self, WeaponSlot)

    if not blaster or not ShootManager.isRangedWeapon(blaster) then return BlasterData.Types.None end

    local blasterId = blaster.recordId

    for blasterType, blasterGroup in pairs(BlasterData) do
        if blasterGroup[blasterId] then
            LogMessage('Shoot Handler: Found blaster type: ' .. tostring(blasterType) .. ' ' .. blasterId)
            return BlasterData.Types[blasterType]
        end
    end

    LogMessage('Shoot Handler: Unknown blaster type: ' .. blasterId)
    return BlasterData.Types.None
end

--- Get the speed multiplier for the current blaster type
function ShootManager.getBlasterSpeedMultiplier()
    local blasterType = ShootManager.getBlasterType()

    local speedFactor = math.min(100, SkillMarksman.base) / 100
    local blasterMultiplier = SpeedBlasterStorage:get(BlasterTypesToSpeedSettings[blasterType])
    assert(blasterMultiplier, 'Shoot Handler: No blaster multiplier found for blaster type: ' .. blasterType)

    local speed = blasterMultiplier * speedFactor
    LogMessage('Shoot Handler: Blaster speed multiplier: ' .. tostring(speed))

    return 1 + speed
end

function ShootManager.textKeyHandler(group, key)
    if not ShootManager.canFireAutomatically(ShootManager.getBlasterType()) then
        LogMessage('Shoot Handler: Automatic fire not enabled for the current blaster type.')
        return
    end

    if key == 'shoot start' or key == 'shoot follow start' then
        LogMessage("Shoot Handler: Increasing shoot speed!")

        animation.setSpeed(self, group, ShootManager.getBlasterSpeedMultiplier())
    elseif key == 'shoot min hit' or key == 'shoot max attack' then
        if self.controls.use == 0 or not input.getBooleanActionValue('Use') then return end

        LogMessage('Shoot Handler: Releasing shot!')

        forceRelease = true
    elseif key == 'follow stop' then
        forceAttack = input.getBooleanActionValue('Use')
    end
end

I.AnimationController.addTextKeyHandler('crossbow', ShootManager.textKeyHandler)
I.AnimationController.addTextKeyHandler('bowandarrow', ShootManager.textKeyHandler)

return ShootManager
