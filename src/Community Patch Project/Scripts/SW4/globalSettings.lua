local time = require('openmw_aux.time')

local ModInfo = require('scripts.sw4.modinfo')
local I = require('openmw.interfaces')
--- Shorthand to generate Setting tables for input into `I.Settings.registerGroup`'s `settings` argument.
---@param key string The (table) key of the setting
---@param renderer DefaultSettingRenderer The type of setting to create
---@param argument SettingRendererOptions The options for the setting renderer, specific to the `renderer` type
---@param name string The displayed name of the setting in the menu
---@param description string The description of the setting in the menu
---@param default any The default value of the setting
---@return table
local function Setting(key, renderer, argument, name, description, default)
    return {
        key = key,
        renderer = renderer,
        argument = argument,
        name = name,
        description = description,
        default = default,
    }
end

local function LimitedPrecision(value)
    return tonumber(string.format("%.5f", value))
end

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'CoreGroup',
    page = ModInfo.name .. 'CorePage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Core',
    permanentStorage = true,
    settings = {
        Setting('DebugEnable', 'checkbox', {}, 'Show Debug Messages', 'Displays debug messages in the (classic) console.', false),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'BindingGroup',
    page = ModInfo.name .. 'CorePage',
    order = 1,
    l10n = ModInfo.l10nName,
    name = 'Key Bindings',
    permanentStorage = true,
    settings = {
        Setting('SW4_TargetLockBinding', "inputBinding", { key = 'SW4_TargetLock', type = "action" }, 'Target Lock Toggle', 'Keybind used to lock onto targets in combat.', 'x')
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'LockOnGroup',
    page = ModInfo.name .. 'CorePage',
    order = 2,
    l10n = ModInfo.name,
    name = 'Lock-On and Targeting',
    permanentStorage = true,
    settings = {
        Setting('TargetLockToggle', 'checkbox', {}, 'Enabled', 'If set to false, target locking is completely disabled. Recommended to leave enabled.', true),
        Setting('TargetMinSize', 'number', { min = 0, max = 64, integer = true }, 'Minimum Target Size', 'Size of the targeting icon at minimum distance.', 32),
        Setting('TargetMinDistance', 'number', { min = 0, max = 512, integer = true }, 'Minimum Target Distance', 'Distance from the locked target at which the icon will be at minimum size.', 256),
        Setting('TargetMaxSize', 'number', { min = 0, max = 128, integer = true }, 'Maximum Target Size', 'Size of the targeting icon at maximum distance.', 128),
        Setting('TargetMaxDistance', 'number', { min = 512, max = 7128, integer = true }, 'Maximum Target Distance', 'Distance from the locked target at which the icon will be at minimum size.', 3564),
        Setting('TargetColorF', 'color', {}, 'Full Target Color', 'Target Icon color when the targeted actor is at 100% health', '#ffffff'),
        Setting('TargetColorVH', 'color', {}, 'Full Target Color', 'Target Icon color when the targeted actor is between 80-100% health', '#ffffff'),
        Setting('TargetColorH', 'color', {}, 'Very Healthy Target Color', 'Target Icon color when the targeted actor is between 60-80% health', '#ffffff'),
        Setting('TargetColorW', 'color', {}, 'Healthy Target Color', 'Target Icon color when the targeted actor is between 40-60% health', '#ffffff'),
        Setting('TargetColorVW', 'color', {}, 'Wounded Target Color', 'Target Icon color when the targeted actor is between 20-40% health', '#ffffff'),
        Setting('TargetColorWD', 'color', {}, 'Dying Target Color', 'Target Icon color when the targeted actor is between 0-20% health', '#ffffff'),
        Setting('TargetColorD', 'color', {}, 'Dying Target Mix Color', 'Target Icon color when the targeted actor is at 0% health', '#ffffff'),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'BlasterGroupAutomatic',
    page = ModInfo.name .. 'BlasterPage',
    order = 0,
    l10n = ModInfo.l10nName,
    name = 'Blaster Settings',
    permanentStorage = true,
    settings = {
        Setting('AutomaticBlastersEnable', 'checkbox', {}, 'Enable Automatic Blasters', 'Controls whether any blasters are capable of automatic fire. Whether a given weapon will fire automatically depends on the below settings.\nAlso suspends animation cancelling.', true),
        Setting('AutomaticRepeatersEnable', 'checkbox', {}, 'Automatic Repeater Blasters', 'Make all repeater blasters capable of automatic fire', true),
        Setting('AutomaticRepeatersCancelAnimations', 'checkbox', {}, 'Repeaters Cancel Recoil', 'Make all repeater blasters cancel their recoil animations when firing', true),
        Setting('AutomaticRiflesEnable', 'checkbox', {}, 'Automatic Blaster Rifles', 'Make all blaster rifles capable of automatic fire', true),
        Setting('AutomaticRiflesCancelAnimations', 'checkbox', {}, 'Rifles Cancel Recoil', 'Make all blaster rifles cancel their recoil animations when firing', true),
        Setting('AutomaticSnipersEnable', 'checkbox', {}, 'Automatic Sniper Rifles', 'Make all sniper rifles capable of automatic fire', true),
        Setting('AutomaticSnipersCancelAnimations', 'checkbox', {}, 'Snipers Cancel Recoil', 'Make all sniper blasters cancel their recoil animations when firing', true),
        Setting('AutomaticPistolsEnable', 'checkbox', {}, 'Automatic Blaster Pistols', 'Make all blaster pistols capable of automatic fire', true),
        Setting('AutomaticPistolsCancelAnimations', 'checkbox', {}, 'Pistols Cancel Recoil', 'Make all blaster pistols cancel their recoil animations when firing', true),
    }
}

I.Settings.registerGroup {
    key = 'SettingsGlobal' .. ModInfo.name .. 'BlasterGroupSpeed',
    page = ModInfo.name .. 'BlasterPage',
    order = 1,
    l10n = ModInfo.l10nName,
    name = 'Blaster Speed Settings',
    permanentStorage = true,
    settings = {
        Setting('SpeedMultRepeater', 'number', { min = 0.1, max = 50.0, integer = false }, 'Repeater Speed Bonus', 'Animation speed multiplier for repeater blasters. Default: 10.0', 10.0),
        Setting('RepeaterCooldownMin', 'number', { min = 0.0, max = 0.5, integer = false }, 'Repeater Minimum Shot Delay', 'Minimum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003', 0.0003),
        Setting('RepeaterCooldownMax', 'number', { min = 0.5, max = 5.0, integer = false }, 'Repeater Maximum Shot Delay', 'Maximum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003', LimitedPrecision(time.second / 150)),
        Setting('SpeedMultRifle', 'number', { min = 0.1, max = 50.0, integer = false }, 'Blaster Rifle Speed Multiplier', 'Animation speed multiplier for blaster rifles. Default: 1.5', 1.5),
        Setting('RifleCooldownMin', 'number', { min = 0.0, max = 0.5, integer = false }, 'Rifle Minimum Shot Delay', 'Minimum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003', 0.0003),
        Setting('RifleCooldownMax', 'number', { min = 0.5, max = 5.0, integer = false }, 'Rifle Maximum Shot Delay', 'Maximum delay in seconds between shots for repeater blasters.\nBe careful setting stupid values on this one.\nDefault: 0.0003', LimitedPrecision(time.second / 50)),
        Setting('SpeedMultSniper', 'number', { min = 0.1, max = 50.0, integer = false }, 'Sniper Speed Multiplier', 'Animation speed multiplier for sniper blasters. Default: 0.5', 0.5),
        Setting('SniperCooldownMin', 'number', { min = 0.0, max = 0.5, integer = false }, 'Sniper Minimum Shot Delay', 'Minimum delay in seconds between shots for sniper rifles.\nBe careful setting stupid values on this one.\nDefault: 0.0003', 0.0003),
        Setting('SniperCooldownMax', 'number', { min = 0.5, max = 5.0, integer = false }, 'Sniper Maximum Shot Delay', 'Maximum delay in seconds between shots for sniper rifles.\nBe careful setting stupid values on this one.\nDefault: 1', LimitedPrecision(time.second / 1)),
        Setting('SpeedMultPistol', 'number', { min = 0.1, max = 50.0, integer = false }, 'Pistol Speed Multiplier', 'Animation speed multiplier for blaster pistols. Default: 2.5', 2.5),
        Setting('PistolCooldownMin', 'number', { min = 0.0, max = 0.5, integer = false }, 'Pistol Minimum Shot Delay', 'Minimum delay in seconds between shots for blaster pistols.\nBe careful setting stupid values on this one.\nDefault: 0.0003', LimitedPrecision(time.second / 125)),
        Setting('PistolCooldownMax', 'number', { min = 0.5, max = 5.0, integer = false }, 'Pistol Maximum Shot Delay', 'Maximum delay in seconds between shots for blaster pistols.\nBe careful setting stupid values on this one.\nDefault: 0.0003', LimitedPrecision(time.second / 75)),
    }
}
