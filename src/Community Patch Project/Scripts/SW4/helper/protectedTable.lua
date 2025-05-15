local gameSelf = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0
  local iter = function()
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

---@class ProtectedTable:table table Read-only table which allows insertion of functions and hooks to a global storage section
---@field notifyPlayer fun(any) shorthand to display all arguments as a table in a Morrowind MessageBox from a protectedTable. Only works on player scripts.
---@field debuglog fun(any) If debug logging setting is enabled, then prints the arguments to log, as a concatenated table

---@param inputGroupName string Name of a global storage section where this module's settings are stored
---@param modInfo ModInfo
---@return ProtectedTable
return function(inputGroupName, modInfo)
  local requestedGroup = storage.globalSection(inputGroupName)

  assert(inputGroupName ~= nil and requestedGroup ~= nil,
    'An invalid setting group was provided!')

  local proxy = {
    thisGroup = requestedGroup,
  }

  local state = {}
  local methods = {}

  function proxy.debugLog(...)
    if gameSelf.type ~= types.Player or not proxy.DebugLog then return end
    print(modInfo.logPrefix, table.concat({ ... }, ' '))
  end

  function proxy.notifyPlayer(...)
    if gameSelf.type ~= types.Player or not proxy.MessageEnable then return end
    require('openmw.ui').showMessage(modInfo.logPrefix .. ' ' .. table.concat({ ... }, ' '))
  end

  function proxy.getState()
    return state
  end

  local meta = {
    __metatable = 'CHIMManager',
    __index = function(_, key)
      if key == 'DebugLog' then
        return storage.globalSection('SettingsGlobal' .. modInfo.name):get('DebugEnable') == true
      elseif key == 'MessageEnable' then
        return storage.globalSection('SettingsGlobal' .. modInfo.name):get('MessageEnable') == true
      elseif key == 'debugLog' then
        return proxy.debugLog
      elseif key == 'state' then
        return state
      end
      return methods[key] or proxy.thisGroup:get(key)
    end,
    __newindex = function(_, key, value)
      if key == 'state' and type(value) == 'table' then
        state = value
      elseif type(value) ~= 'function' or
          (type(value) ~= 'table' and key == 'state') then
        error(
          string.format([[%s Unauthorized table access when updating '%s' to '%s'.
This table is not writable and values must be updated through its associated storage group: '%s'.]], modInfo.logPrefix,
            tostring(key), tostring(value), inputGroupName),
          2)
      else
        rawset(methods, key, value)
      end
    end,
    __tostring = function(_)
      local members = {}
      local methodParts = {}

      for key, value in pairsByKeys(proxy.thisGroup:asTable()) do
        members[#members + 1] = string.format('%s = %s', tostring(key), tostring(value))
      end

      for key, _ in pairsByKeys(methods) do
        methodParts[#methodParts + 1] = string.format('%s', tostring(key))
      end

      return string.format('CHIMManager{ Members: %s Methods: %s }',
        table.concat(members, ', '), table.concat(methodParts, ', '))
    end,
    __pairs = function()
      return next, proxy.thisGroup:asTable(), nil
    end,
  }
  setmetatable(proxy, meta)

  return proxy
end
