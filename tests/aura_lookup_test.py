"""Run with Python and lupa; exercises the addon's actual aura lookup."""
from pathlib import Path
from lupa import LuaRuntime

source = Path('TrinketSwitcher.lua').read_text(encoding='utf-8-sig')
lookup = source.split('local function IsItemEffectActive(itemID)', 1)[1]
lookup = lookup.split('local function SlotTrinketReady', 1)[0]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
function GetItemUseSpellName(id)
    if id == 101 then return "Transformative Cocoon" end
end
-- Reproduce the broken Blizzard wrapper: it must never be called.
AuraUtil = {FindAuraByName = function() error("missing aura API") end}
''')
lua.execute('IsItemEffectActive = function(itemID)' + lookup)
lua.execute('''
assert(not IsItemEffectActive(nil))
assert(not IsItemEffectActive(102))
C_UnitAuras = {GetAuraDataBySpellName = function(unit, name, filter)
    assert(unit == "player" and filter == "HELPFUL")
    return active and {name = name} or nil
end}
active = true
assert(IsItemEffectActive(101))
active = false
assert(not IsItemEffectActive(101))
-- Classic beta: name lookup missing, indexed lookup available.
C_UnitAuras = {GetAuraDataByIndex = function(unit, index, filter)
    assert(unit == "player" and filter == "HELPFUL")
    if index == 1 then return {name = "Unrelated buff"} end
    if index == 2 and active then return {name = "Transformative Cocoon"} end
end}
active = true
assert(IsItemEffectActive(101))
active = false
assert(not IsItemEffectActive(101))
C_UnitAuras = nil
UnitBuff = function(unit, index)
    assert(unit == "player")
    if index == 1 and active then return "Transformative Cocoon" end
end
active = true
assert(IsItemEffectActive(101))
active = false
assert(not IsItemEffectActive(101))
UnitBuff = nil
assert(not IsItemEffectActive(101))
''')
print('Aura lookup compatibility checks passed')
