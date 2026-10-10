# Run with Python and lupa (pip install lupa). No game client required.
from pathlib import Path
from lupa import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
for path in Path('.').rglob('*.lua'):
    lua.execute('assert(load(...))',path.read_text(encoding='utf-8-sig'))
print('All Lua files compile')
lua.execute('''
TrinketSwitcherFrame = {}
TrinketSwitcherCharDB = {macroReadyGlowEnabled=true, readySoundEnabled=true, readySound="Chime", readySoundVolume=70, colors={macroReadyGlow={r=1,g=.8,b=0}}}
now=100; sounds=0; inventory={[13]=101,[14]=102}; cds={}; bodies={[1]="/use 13\\n/use 14",[2]="/use [combat] 13; [nocombat] 14",[3]="/use 130\\n/say /use 13"}
function GetTime() return now end
timers = {}
C_Timer = {}
function C_Timer.NewTimer(delay, callback)
 local timer={due=now+delay,callback=callback}
 function timer:Cancel() self.cancelled=true end
 timers[#timers+1]=timer
 return timer
end
function RunTimers()
 local pending=timers; timers={}
 for _,timer in ipairs(pending) do
  if not timer.cancelled then
   if timer.due <= now then timer.callback() else timers[#timers+1]=timer end
  end
 end
end
function CreateFrame()
 local frame={scripts={},events={}}
 function frame:SetScript(name,callback) self.scripts[name]=callback end
 function frame:RegisterEvent(event) self.events[event]=true end
 return frame
end
function GetInventoryItemID(_,slot) return inventory[slot] end
function GetInventoryItemCooldown(_,slot) local c=cds[slot] or {0,0,1}; return c[1],c[2],c[3] end
function GetActionInfo(action) if action==4 then return "spell",123 end return "macro",action end
function GetActionText(action) return "Macro" .. action end
function GetMacroIndexByName(name) return tonumber(name:match("^Macro(%d+)$")) or 0 end
function GetMacroBody(id) return bodies[id] end
local glowLibrary = {}
function LibStub(name) assert(name=="LibCustomGlow-1.0"); return glowLibrary end
function glowLibrary.PixelGlow_Start(button, color, count, frequency, length, width, x, y, border, key)
 assert(key=="TrinketSwitcherReady")
 assert(width>=1 and width<=10)
 button.tsMacroReadyGlow = button.tsMacroReadyGlow or {}
 local glow = button.tsMacroReadyGlow
 glow.shown=true; glow.r,glow.g,glow.b=color[1],color[2],color[3]; glow.width=width
 glow.starts=(glow.starts or 0)+1
end
function glowLibrary.PixelGlow_Stop(button,key)
 assert(key=="TrinketSwitcherReady")
 if button.tsMacroReadyGlow then button.tsMacroReadyGlow.shown=false end
end
function PlaySoundFile(path, channel) sounds=sounds+1; lastSound=path; assert(channel=="Master") end
function TrinketSwitcherFrame:GetItemSpellSafe(id) if id then return "Use" end end
function TrinketSwitcherFrame:GetCooldownRemaining(start,duration) if start==0 then return 0 end return math.max(0,start+duration-now) end
buttons={}
for i=1,4 do
 local b={action=i,visible=true}
 function b:IsForbidden() return self.forbidden or false end
 function b:IsVisible() return self.visible end
 function b:CreateTexture() local t={}; function t:SetTexture() end; function t:SetBlendMode() end; function t:SetPoint() end; function t:SetVertexColor() end; function t:SetShown(v) self.shown=v end; return t end
 buttons[i]=b
end
TrinketSwitcherFrame.macroButtons={}
for _,b in ipairs(buttons) do TrinketSwitcherFrame.macroButtons[b]=true end
''')
lua.execute(Path('Modules/ReadyAlerts.lua').read_text())
lua.execute('''
local a=TrinketSwitcherFrame
local db=TrinketSwitcherCharDB
a:UpdateReadyAlerts(); assert(sounds==0); assert(buttons[1].tsMacroReadyGlow.shown); assert(buttons[2].tsMacroReadyGlow.shown); assert(not buttons[3].tsMacroReadyGlow); assert(not buttons[4].tsMacroReadyGlow)
cds[13]={100,1.5,1}; cds[14]={100,1.5,1}
a:UpdateReadyAlerts(); now=102; a:UpdateReadyAlerts(); assert(sounds==0); assert(buttons[1].tsMacroReadyGlow.shown)
cds[13]={102,30,1}; cds[14]={102,30,1}; a:UpdateReadyAlerts(); assert(not buttons[1].tsMacroReadyGlow.shown)
now=110; cds[13]={110,1.5,1}; cds[14]={110,1.5,1}; a:UpdateReadyAlerts(); assert(sounds==0); assert(not buttons[1].tsMacroReadyGlow.shown)
cds[13]={102,30,1}; cds[14]={102,30,1}
now=132; a:UpdateReadyAlerts(); assert(sounds==1); a:UpdateReadyAlerts(); assert(sounds==1)
assert(lastSound:find("Chime70.wav",1,true))
cds[13]={132,30,1}; a:UpdateReadyAlerts(); inventory[13]=103; cds[13]={0,0,1}; a:UpdateReadyAlerts(); assert(sounds==1)
db.macroReadyGlowEnabled=false; a:UpdateReadyAlerts(); assert(not buttons[1].tsMacroReadyGlow.shown)
db.readySoundEnabled=false; cds[13]={132,30,1}; a:UpdateReadyAlerts(); now=162; a:UpdateReadyAlerts(); assert(sounds==1)
db.readySoundEnabled=true; a.readyAlertState=nil; a:UpdateReadyAlerts(); assert(sounds==1)
inventory[13]=nil; inventory[14]=nil; db.macroReadyGlowEnabled=true; a:UpdateReadyAlerts(); assert(not buttons[1].tsMacroReadyGlow.shown)
''')
print('Passed: macro slots/conditions, unrelated actions, GCD, shared cooldown, once-only sound, equipment swap, toggles, empty slots')
lua.execute('''
local forbidden = {}
function forbidden:IsForbidden() return false end
function forbidden:IsObjectType() error("Forbidden object was inspected") end
local valid = buttons[1]
function valid:IsObjectType() error("Action button type inspection is unnecessary") end
function EnumerateFrames() error("Global frame enumeration must not be used") end
ActionButton1 = valid
MultiBarBottomLeftButton1 = buttons[2]
BT4Button1 = buttons[3]
DominosActionButton1 = buttons[4]
UnrelatedAuraButton = forbidden
local a = TrinketSwitcherFrame
a.macroButtons = {}
a:RefreshMacroButtons()
assert(a.macroButtons[valid] and not a.macroButtons[forbidden])
assert(a.macroButtons[buttons[2]] and a.macroButtons[buttons[3]] and a.macroButtons[buttons[4]])
valid.forbidden = true
function valid:IsVisible() error("Forbidden button was inspected") end
a:UpdateReadyAlerts()
assert(not a.macroButtons[valid])
''')
print('Passed: named action button discovery without frame enumeration or type inspection; cached forbidden buttons removed')
lua.execute('''
local a = TrinketSwitcherFrame
local b = buttons[3]
b.action = 0
b.stateKind, b.stateAction = "macro", 1
function b:GetAction() return self.stateKind, self.stateAction end
a.macroButtons = {[b]=true}
inventory[13]=101; cds[13]={0,0,1}
TrinketSwitcherCharDB.colors.macroReadyGlow = {r=.1,g=.5,b=1}
function b:CreateTexture()
 local t={}
 function t:SetTexture(path) self.path=path end
 function t:SetBlendMode() end
 function t:SetPoint() end
 function t:SetVertexColor(r,g,b) self.r,self.g,self.b=r,g,b end
 function t:SetShown(shown) self.shown=shown end
 return t
end
a:UpdateReadyAlerts()
assert(b.tsMacroReadyGlow.shown)
assert(b.tsMacroReadyGlow.r==.1 and b.tsMacroReadyGlow.b==1)
b.stateKind,b.stateAction = "spell",123
a:UpdateReadyAlerts(); assert(not b.tsMacroReadyGlow.shown)
b.stateKind,b.stateAction = "action",1
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.shown)
cds[13]={GetTime(),30,1}
a:UpdateReadyAlerts(); assert(not b.tsMacroReadyGlow.shown)
''')
print('Passed: Bartender direct macros, action slots, page changes, glow tint, and cooldown hiding')
lua.execute('''
local a,b = TrinketSwitcherFrame,buttons[3]
-- Reproduce clients where a macro action reports its item's ID.
function GetActionInfo() return "macro",99999,"item" end
a.readyActionCache=nil
b.stateKind,b.stateAction="action",1
cds[13]={0,0,1}
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.shown)
local starts=b.tsMacroReadyGlow.starts
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.starts==starts)
TrinketSwitcherCharDB.colors.macroReadyGlow.r=.7
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.r==.7)
TrinketSwitcherCharDB.macroReadyGlowEnabled=false
a:UpdateReadyAlerts(); assert(not b.tsMacroReadyGlow.shown)
''')
print('Passed: macro name lookup with item IDs, persistent animation, live color updates, and toggle cleanup')
lua.execute('''
local a,b = TrinketSwitcherFrame,buttons[3]
TrinketSwitcherCharDB.macroReadyGlowEnabled=true
function a:GetItemSpellSafe() return nil end
cds[13]={0,0,1}; a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.shown)
cds[13]={0,0,0}; a:UpdateReadyAlerts(); assert(not b.tsMacroReadyGlow.shown)
''')
print('Passed: uncached on-use trinkets glow; passive trinkets do not')
lua.execute('''
local a,b=TrinketSwitcherFrame,buttons[3]
cds[13]={0,0,1}
TrinketSwitcherCharDB.macroReadyGlowWidth=nil
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.width==2)
for _,width in ipairs({1,5,10}) do
 TrinketSwitcherCharDB.macroReadyGlowWidth=width
 a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.width==width)
end
TrinketSwitcherCharDB.macroReadyGlowWidth=20
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.width==10)
TrinketSwitcherCharDB.macroReadyGlowWidth=0
a:UpdateReadyAlerts(); assert(b.tsMacroReadyGlow.width==1)
''')
print('Passed: default glow width, live thickness changes, and range limits')
lua.execute('''
local a,b,db=TrinketSwitcherFrame,buttons[3],TrinketSwitcherCharDB
-- Use one visible action button and count expensive lookups.
MultiBarBottomLeftButton1,DominosActionButton1=nil,nil
a.macroButtons={[b]=true}; a.readyMacroCache=nil; a.readyActionCache=nil
b.stateKind,b.stateAction="action",1
db.macroReadyGlowEnabled=true; db.readySoundEnabled=true
inventory[13]=101; inventory[14]=nil; cds[13]={0,0,1}
local reads,actionReads,inventoryReads,updates=0,0,0,0
local originalBody,originalAction,originalInventory,originalUpdate=GetMacroBody,GetActionInfo,GetInventoryItemCooldown,a.UpdateReadyAlerts
function GetMacroBody(id) reads=reads+1; return originalBody(id) end
function GetActionInfo(slot) actionReads=actionReads+1; return originalAction(slot) end
function GetInventoryItemCooldown(...) inventoryReads=inventoryReads+1; return originalInventory(...) end
function a:UpdateReadyAlerts() updates=updates+1; return originalUpdate(self) end
a:StartReadyAlerts(); RunTimers()
assert(not a.readyAlertFrame.scripts.OnUpdate)
assert(b.tsMacroReadyGlow.shown and not a.readyAlertTimer)
local idleReads,idleUpdates=inventoryReads,updates
now=now+100; RunTimers()
assert(inventoryReads==idleReads and updates==idleUpdates)
reads,actionReads=0,0
for i=1,100 do a.readyAlertFrame.scripts.OnEvent(nil,"ACTIONBAR_UPDATE_COOLDOWN") end
now=now+.11; RunTimers()
assert(updates==idleUpdates+1 and reads==0 and actionReads==0)
-- Editing a macro invalidates both caches and stops the previous glow.
bodies[1]="/say changed"
a.readyAlertFrame.scripts.OnEvent(nil,"UPDATE_MACROS")
now=now+.11; RunTimers()
assert(not b.tsMacroReadyGlow.shown and reads==1 and actionReads==1)
bodies[1]="/use 13"
a.readyAlertFrame.scripts.OnEvent(nil,"UPDATE_MACROS")
now=now+.11; RunTimers(); assert(b.tsMacroReadyGlow.shown)
-- Timer alone must complete a cooldown, without any further game events.
cds[13]={now,30,1}
a.readyAlertFrame.scripts.OnEvent(nil,"ACTIONBAR_UPDATE_COOLDOWN")
now=now+.11; RunTimers()
assert(not b.tsMacroReadyGlow.shown and a.readyAlertTimer)
local beforeSound=sounds
now=now+30; RunTimers()
assert(b.tsMacroReadyGlow.shown and sounds==beforeSound+1 and not a.readyAlertTimer)
-- Disable everything, then ensure events and time passage do no inventory work.
db.macroReadyGlowEnabled=false; db.readySoundEnabled=false
a:UpdateReadyAlerts(); assert(not b.tsMacroReadyGlow.shown and not a.readyAlertTimer)
local disabledReads=inventoryReads
for i=1,100 do a.readyAlertFrame.scripts.OnEvent(nil,"ACTIONBAR_UPDATE_COOLDOWN") end
now=now+100; RunTimers(); assert(inventoryReads==disabledReads)
''')
print('Passed: no idle polling, 100-event coalescing, cached macro/action reads, macro-edit invalidation, timer-only readiness sound, and disabled idle work')
