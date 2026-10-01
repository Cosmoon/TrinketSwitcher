local ATS = CreateFrame("Frame", "TrinketSwitcherFrame")

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function NormalizeCooldown(start, duration, enable)
    if type(start) == "table" then
        local info = start
        start = info.startTime or info.start or info[1] or 0
        duration = info.duration or info[2] or 0
        enable = info.isEnabled or info.enable or info[3]
    end
    return start or 0, duration or 0, enable
end

local function GetItemCooldownSafe(itemID)
    if not itemID then return 0, 0, 0 end
    if C_Item and C_Item.GetItemCooldown then
        return NormalizeCooldown(C_Item.GetItemCooldown(itemID))
    end
    if GetItemCooldown then
        return NormalizeCooldown(GetItemCooldown(itemID))
    end
    return 0, 0, 0
end

local function GetInventoryItemCooldownSafe(unit, slot)
    if GetInventoryItemCooldown then
        return NormalizeCooldown(GetInventoryItemCooldown(unit, slot))
    end
    local itemID = GetInventoryItemID and GetInventoryItemID(unit, slot)
    if itemID then
        return GetItemCooldownSafe(itemID)
    end
    return 0, 0, 0
end

local function IsActiveCooldown(start, duration)
    if IsSecret(start) or IsSecret(duration) then return false end
    return start and duration and start > 0 and duration > 0
end

local function GetCooldownRemaining(start, duration)
    if IsSecret(start) or IsSecret(duration) then return math.huge end
    if not start or not duration or start == 0 or duration == 0 then
        return 0
    end
    local remaining = duration - (GetTime() - start)
    if remaining < 0 then remaining = 0 end
    return remaining
end

function ATS:GetItemCooldownSafe(itemID)
    return GetItemCooldownSafe(itemID)
end

function ATS:GetItemInfoSafe(itemInfo)
    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if getter then return getter(itemInfo) end
end

function ATS:GetItemSpellSafe(itemInfo)
    local getter = C_Item and C_Item.GetItemSpell or GetItemSpell
    if getter then return getter(itemInfo) end
end

function ATS:GetItemCountSafe(itemInfo, includeBank)
    local getter = C_Item and C_Item.GetItemCount or GetItemCount
    if getter then return getter(itemInfo, includeBank or false) or 0 end
    return 0
end

function ATS:GetItemIconSafe(itemInfo)
    if C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(itemInfo)
    end
    if GetItemIcon then return GetItemIcon(itemInfo) end
end

function ATS:GetCooldownRemaining(start, duration)
    return GetCooldownRemaining(start, duration)
end

function ATS:IsActiveCooldown(start, duration)
    return IsActiveCooldown(start, duration)
end

function ATS:GetDisplayItemCooldown(itemID, fallbackStart, fallbackDuration, fallbackEnable)
    if fallbackStart ~= nil or fallbackDuration ~= nil then
        return fallbackStart or 0, fallbackDuration or 0, fallbackEnable, itemID
    end

    local start, duration, enable = GetItemCooldownSafe(itemID)
    return start, duration, enable, itemID
end

function ATS:GetEffectiveItemCooldown(itemID, fallbackStart, fallbackDuration, fallbackEnable)
    if fallbackStart ~= nil or fallbackDuration ~= nil then
        return fallbackStart or 0, fallbackDuration or 0, fallbackEnable, itemID
    end

    local start, duration, enable = GetItemCooldownSafe(itemID)
    return start, duration, enable, itemID
end

local function EquipItemSafe(itemID, slot)
    if not itemID then return end
    if C_Item and C_Item.EquipItemByName then
        C_Item.EquipItemByName(itemID, slot)
        return
    end
    if EquipItemByName then
        if type(itemID) == "number" then
            EquipItemByName("item:" .. itemID, slot)
        else
            EquipItemByName(itemID, slot)
        end
    end
end

function ATS:EquipItemSafe(itemID, slot)
    EquipItemSafe(itemID, slot)
end

local function UseActionKeyDown()
    return GetCVar and GetCVar("ActionButtonUseKeyDown") == "1"
end

function ATS:GetTrinketClickBinding()
    return UseActionKeyDown() and "LeftButtonDown" or "LeftButtonUp"
end

function ATS:UpdateTrinketClickBinding()
    if not self.buttons then return end
    local click = self:GetTrinketClickBinding()
    for _, btn in pairs(self.buttons) do
        if btn and btn.RegisterForClicks then
            btn:RegisterForClicks(click)
        end
    end
end

local function NormalizeQueueSet(queue)
    if not queue then queue = {} end
    queue[13] = queue[13] or {}
    queue[14] = queue[14] or {}
    return queue
end

local EnsureDB

local function NormalizePoint(point, fallback)
    fallback = fallback or {}
    if type(point) ~= "table" then point = {} end

    point.point = point.point or fallback.point or "CENTER"
    point.relativePoint = point.relativePoint or fallback.relativePoint or "CENTER"
    point.x = tonumber(point.x) or fallback.x or 0
    point.y = tonumber(point.y) or fallback.y or 0
    return point
end

function ATS:SaveFramePosition(frame, key)
    EnsureDB()
    if not frame or not key then return end

    local db = TrinketSwitcherCharDB
    db[key] = NormalizePoint(db[key])

    local frameX, frameY = frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    local hasSecretGeometry = issecretvalue and (
        issecretvalue(frameX) or issecretvalue(frameY) or
        issecretvalue(parentX) or issecretvalue(parentY)
    )

    if frameX and frameY and parentX and parentY and not hasSecretGeometry then
        db[key].point = "CENTER"
        db[key].relativePoint = "CENTER"
        db[key].x = frameX - parentX
        db[key].y = frameY - parentY
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint()
    if not point then return end
    db[key].point = point
    db[key].relativePoint = relativePoint or "CENTER"
    db[key].x = x or 0
    db[key].y = y or 0
end

function ATS:SetButtonFrameHidden(hidden)
    EnsureDB()
    hidden = hidden == true
    TrinketSwitcherCharDB.buttonFrameHidden = hidden

    if self.buttonFrame then
        if hidden then
            self.buttonFrame:Hide()
        else
            self.buttonFrame:Show()
        end
    end
end

function ATS:SaveCharacterState()
    EnsureDB()

    if self.buttonFrame then
        self:SaveFramePosition(self.buttonFrame, "buttonPos")
    end

    if self.optionsWindow then
        self:SaveFramePosition(self.optionsWindow, "optionsPos")
    end
end

function ATS:ApplyCharacterState()
    EnsureDB()
    local db = TrinketSwitcherCharDB

    if self.buttonFrame then
        local pos = db.buttonPos
        self.buttonFrame:ClearAllPoints()
        self.buttonFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        self:SetButtonFrameHidden(db.buttonFrameHidden)
    end

    if self.optionsWindow then
        local pos = db.optionsPos
        self.optionsWindow:ClearAllPoints()
        self.optionsWindow:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

-- Ensure saved variables exist after they are loaded
EnsureDB = function()
    TrinketSwitcherCharDB = TrinketSwitcherCharDB or {}
    local db = TrinketSwitcherCharDB

    db.queues = NormalizeQueueSet(db.queues or { [13] = {}, [14] = {} })
    if db.queueSets then
        db.queueSets[1] = NormalizeQueueSet(db.queueSets[1])
        db.queueSets[2] = NormalizeQueueSet(db.queueSets[2])
        if db.activeQueueSet ~= 1 and db.activeQueueSet ~= 2 then
            db.activeQueueSet = 1
        end
        if db.queues and db.queueSets[db.activeQueueSet] ~= db.queues then
            db.queueSets[db.activeQueueSet] = db.queues
        end
    else
        db.queueSets = {
            [1] = db.queues,
            [2] = { [13] = {}, [14] = {} },
        }
        db.activeQueueSet = (db.activeQueueSet == 2) and 2 or 1
    end
    db.queues = db.queueSets[db.activeQueueSet]
    db.menuOnlyOutOfCombat = db.menuOnlyOutOfCombat ~= false
    db.autoSwitch = db.autoSwitch ~= false
    db.readyGlowEnabled = db.readyGlowEnabled ~= false

    if db.showCooldowns ~= nil and db.showCooldownNumbers == nil then
        db.showCooldownNumbers = db.showCooldowns
        db.showCooldowns = nil
    end
    db.showCooldownNumbers = db.showCooldownNumbers ~= false
    db.largeNumbers = db.largeNumbers or false
    db.lockWindows = db.lockWindows or false
    db.tooltipMode = db.tooltipMode or "ON"
    if db.tooltipMode ~= "OFF" then
        db.tooltipMode = "ON"
    end
    db.useDefaultTooltipAnchor = (db.useDefaultTooltipAnchor ~= false)
    db.tinyTooltips = db.tinyTooltips or false
    db.cleanTooltips = db.cleanTooltips or false
    db.menuPosition = db.menuPosition or "BOTTOM"
    db.wrapAt = db.wrapAt or 10

    db.colors = db.colors or {}
    db.colors.slot13 = db.colors.slot13 or { r = 0, g = 1, b = 0 }
    db.colors.slot14 = db.colors.slot14 or { r = 1, g = 0.82, b = 0 }
    db.colors.glow   = db.colors.glow   or { r = 1, g = 1, b = 0 }
    db.colors.manualBadge = db.colors.manualBadge or { r = 1, g = 1, b = 1 }
    db.colors.readyGlow = db.colors.readyGlow or { r = 1, g = 1, b = 1 }

    db.buttonPos = NormalizePoint(db.buttonPos, { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 })
    db.optionsPos = NormalizePoint(db.optionsPos, { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 })
    db.minimap = db.minimap or { hide = false }
    db.manual = db.manual or { [13] = false, [14] = false }
    db.manualPreferred = db.manualPreferred or { [13] = nil, [14] = nil }
    db.buttonFrameHidden = db.buttonFrameHidden == true
    db.queueNumberSize = db.queueNumberSize or 12
    db.wrapDirection = db.wrapDirection or "HORIZONTAL" -- or VERTICAL
    db.altFullTooltips = db.altFullTooltips or false
    db.menuSortMode = db.menuSortMode or "QUEUED_FIRST" -- QUEUED_FIRST | ALPHA | ILEVEL
    db.mountOverrideActive = db.mountOverrideActive or false
    if not db.mountOverrideActive then
        db.mountOverridePrevAutoSwitch = nil
    end
    db.mountSpeedActive = nil
    db.mountSpeedPrevious = nil
    db.mountSpeedTrinketsEnabled = nil
    db.useMountSpeedManager = nil
end

function ATS:EnsureDB()
    EnsureDB()
end

local function PlayerCanSwap()
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return false end
    if UnitIsDead and UnitIsDead("player") then return false end
    if UnitIsGhost and UnitIsGhost("player") then return false end
    if UnitCastingInfo and UnitCastingInfo("player") then return false end
    if UnitChannelInfo and UnitChannelInfo("player") then return false end
    if SpellIsTargeting and SpellIsTargeting() then return false end
    return true
end

function ATS:PlayerCanSwap()
    return PlayerCanSwap()
end

-- Sync the options panel 'Enable auto switching' checkbox (if present)
function ATS:UpdateOptionsAutoCheckbox()
    if self.optionCheckboxes and self.optionCheckboxes.autoSwitch then
        local cb = self.optionCheckboxes.autoSwitch
        if cb.SetChecked then
            local db = TrinketSwitcherCharDB or {}
            local m13 = db.manual and db.manual[13]
            local m14 = db.manual and db.manual[14]
            local derivedOn = not (m13 and m14) -- ON if at least one slot is auto
            cb:SetChecked(derivedOn)
        end
    end
end

-- Centralized setter for global auto-switch state, with manual-slot reconciliation.
function ATS:SetGlobalAutoSwitch(enabled)
    EnsureDB()
    local db = TrinketSwitcherCharDB
    enabled = not not enabled

    if not db.manual then db.manual = { [13]=false, [14]=false } end
    if not db.manualPreferred then db.manualPreferred = { [13] = nil, [14] = nil } end
    local previousManual = { [13] = db.manual[13], [14] = db.manual[14] }

    if enabled then
        -- Turning ON: both slots go auto
        db.manual[13] = false
        db.manual[14] = false
        if previousManual[13] then self:RestoreManualTrinket(13) end
        if previousManual[14] then self:RestoreManualTrinket(14) end
    else
        -- Turning OFF: both slots go manual
        db.manual[13] = true
        db.manual[14] = true
        db.manualPreferred[13] = GetInventoryItemID("player", 13)
        db.manualPreferred[14] = GetInventoryItemID("player", 14)
    end

    db.autoSwitch = enabled
    self:UpdateButtons()
    self:UpdateOptionsAutoCheckbox()
end

function ATS:SetActiveQueueSet(index)
    EnsureDB()
    local db = TrinketSwitcherCharDB
    index = (index == 2) and 2 or 1
    if db.activeQueueSet == index then return end

    db.activeQueueSet = index
    db.queues = db.queueSets[index]

    if db.talentProfiles and db.activeTalentSignature then
        local profile = db.talentProfiles[db.activeTalentSignature]
        if profile then
            profile.queueSets = db.queueSets
            profile.activeQueueSet = db.activeQueueSet
            profile.queues = db.queues
        end
    end

    if self.menu and self.menu:IsShown() then
        self:RefreshMenuNumbers()
        self:UpdateMenuCooldowns()
    end
    if self.UpdateQueueSetButtons then self:UpdateQueueSetButtons() end
    self:UpdateButtons()
end

function ATS:UpdateQueueSetButtons()
    if not self.queueSetButtons then return end
    local active = (TrinketSwitcherCharDB and TrinketSwitcherCharDB.activeQueueSet) or 1
    for i, btn in ipairs(self.queueSetButtons) do
        local isActive = (i == active)
        if btn.text then
            if isActive then
                btn.text:SetTextColor(1, 0.82, 0, 1)
            else
                btn.text:SetTextColor(1, 1, 1, 1)
            end
        end
        btn:SetAlpha(isActive and 1 or 0.7)
    end
end

function ATS:RestoreManualTrinket(slot)
    EnsureDB()
    local db = TrinketSwitcherCharDB
    if not db.manualPreferred then return end
    if not PlayerCanSwap() then return end
    if InCombatLockdown and InCombatLockdown() then return end

    local itemID = db.manualPreferred[slot]
    if not itemID then return end

    local current = GetInventoryItemID("player", slot)
    if current == itemID then return end

    local count = self:GetItemCountSafe(itemID, false)
    if count == 0 then return end

    EquipItemSafe(itemID, slot)

    self.lastEquip = self.lastEquip or {}
    self.lastEquip[slot] = GetTime()
end

function ATS:RestoreManualSlots()
    EnsureDB()
    local db = TrinketSwitcherCharDB
    if not db.manual then return end

    for _, slot in ipairs({13, 14}) do
        if db.manual[slot] then
            self:RestoreManualTrinket(slot)
        end
    end
end

-- Called after a per-slot manual toggle to keep global in sync
function ATS:OnManualToggle()
    EnsureDB()
    -- Only refresh UI/checkbox to reflect derived ON/OFF from per-slot manual flags
    self:UpdateButtons()
    self:UpdateOptionsAutoCheckbox()
end

-- Talent profile functions moved to Modules\Profiles.lua

-- Helper to position the tooltip at the game's default location (or legacy side-anchored)
-- Tooltip helpers moved to Modules\Tooltips.lua

local function TrackItemCooldown(itemID, start, duration)
    if IsSecret(start) or IsSecret(duration) then return end
    if not itemID or not start or not duration or start == 0 or duration == 0 then
        return
    end
    ATS.itemCooldowns = ATS.itemCooldowns or {}
    ATS.itemCooldowns[itemID] = { start = start, duration = duration }
end

local function GetTrackedItemRemaining(itemID)
    if not itemID or not ATS.itemCooldowns then return 0 end
    local info = ATS.itemCooldowns[itemID]
    if not info then return 0 end
    local remaining = GetCooldownRemaining(info.start, info.duration)
    if remaining <= 0 then
        ATS.itemCooldowns[itemID] = nil
        return 0
    end
    return remaining
end

local function GetItemRemaining(itemID)
    if not itemID then return 0 end
    local start, duration, _, sourceItemID = ATS:GetEffectiveItemCooldown(itemID)
    local remaining = GetCooldownRemaining(start, duration)
    if remaining > 0 then return remaining end
    return GetTrackedItemRemaining(sourceItemID or itemID)
end

-- Find index of an item within a queue (or large number if not present)
local function QueueIndex(slot, itemID)
    if not itemID then return math.huge end
    local q = TrinketSwitcherCharDB.queues[slot]
    for i, id in ipairs(q) do
        if id == itemID then return i end
    end
    return math.huge
end

-- Helper: does an item have a usable effect?
local function ItemHasUse(itemID)
    if not itemID then return false end
    local useName = ATS:GetItemSpellSafe(itemID)
    return useName ~= nil
end

local function IsItemEffectActive(itemID)
    if not itemID then return false end
    local spellName = ATS:GetItemSpellSafe(itemID)
    if not spellName then return false end

    if AuraUtil and AuraUtil.FindAuraByName then
        return AuraUtil.FindAuraByName(spellName, "player", "HELPFUL") ~= nil
    end

    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end
        if name == spellName then return true end
    end

    return false
end

local function SlotTrinketReady(slot)
    local itemID = GetInventoryItemID("player", slot)
    if not itemID or not ItemHasUse(itemID) then return false end
    local fallbackStart, fallbackDuration, fallbackEnable = GetInventoryItemCooldownSafe("player", slot)
    local start, duration = ATS:GetEffectiveItemCooldown(itemID, fallbackStart, fallbackDuration, fallbackEnable)
    return GetCooldownRemaining(start, duration) <= 0
end

-- If the top-priority item for a slot isn't ready, reserve the currently equipped
-- slot item (if it is in that slot's queue) so the other slot won't steal it.
local function GetReservationForSlot(slot)
    if TrinketSwitcherCharDB.manual and TrinketSwitcherCharDB.manual[slot] then return nil end
    local q = TrinketSwitcherCharDB.queues[slot]
    if not q or #q == 0 then return nil end
    local topWanted = q[1]
    if GetItemRemaining(topWanted) > 30 then
        local equippedID = GetInventoryItemID("player", slot)
        -- Only reserve if currently equipped is part of this slot's queue
        for _, id in ipairs(q) do
            if id == equippedID then return equippedID end
        end
    end
    return nil
end

-- Choose the highest-priority ready trinket for a slot, then return a swap target only when
-- it differs from the currently equipped item (so passive-only queues stay stable).
local function ChooseCandidate(slot, avoidID)
    if TrinketSwitcherCharDB.manual and TrinketSwitcherCharDB.manual[slot] then return nil end
    local equippedID = GetInventoryItemID("player", slot)
    local equippedStart, equippedDuration = GetInventoryItemCooldownSafe("player", slot)
    equippedStart, equippedDuration = ATS:GetEffectiveItemCooldown(equippedID, equippedStart, equippedDuration)
    local equippedCD = GetCooldownRemaining(equippedStart, equippedDuration)
    local equippedHasUse = ItemHasUse(equippedID)

    if equippedHasUse and IsItemEffectActive(equippedID) then
        return nil
    end

    local queue = TrinketSwitcherCharDB.queues[slot]
    local equippedIdx = QueueIndex(slot, equippedID)

    local targetID, targetIdx
    local otherSlot = (slot == 13) and 14 or 13
    local reservedOther = GetReservationForSlot(otherSlot)
    for i, itemID in ipairs(queue) do
        if itemID ~= avoidID and itemID ~= reservedOther then
            local allowed = true
            -- Skip items not in bags/equipped
            local count = ATS:GetItemCountSafe(itemID, false)
            if count == 0 then allowed = false end
            if allowed then
                local cd = GetItemRemaining(itemID)
                if cd <= 30 then
                    targetID, targetIdx = itemID, i
                    break
                end
            end
        end
    end
    if not targetID then return nil end

    -- If the equipped trinket is already the highest-priority ready option, keep it.
    if targetID == equippedID then
        return nil
    end

    -- Apply "don't swap off a near-ready usable trinket" unless the target has strictly higher priority
    if equippedHasUse and equippedCD <= 30 then
        if targetIdx and equippedIdx and targetIdx >= equippedIdx then
            return nil
        end
    end

    return targetID
end
-- Return queue position of an item for a slot or nil
function ATS:GetQueuePosition(slot, itemID)
    for i, id in ipairs(TrinketSwitcherCharDB.queues[slot]) do
        if id == itemID then
            return i
        end
    end
end

-- Add or remove a trinket from a slot queue
function ATS:ToggleTrinket(slot, itemID)
    local queue = TrinketSwitcherCharDB.queues[slot]
    for i, id in ipairs(queue) do
        if id == itemID then
            table.remove(queue, i)
            return
        end
    end
    table.insert(queue, itemID)
end

-- Apply configured colors to active UI elements
function ATS:ApplyColorSettings()
    if self.menu and self.menu.icons then
        local c13 = TrinketSwitcherCharDB.colors.slot13
        local c14 = TrinketSwitcherCharDB.colors.slot14
        for _, btn in ipairs(self.menu.icons) do
            btn.pos13:SetTextColor(c13.r, c13.g, c13.b)
            btn.pos14:SetTextColor(c14.r, c14.g, c14.b)
        end
    end

    local glowColor = TrinketSwitcherCharDB.colors.glow
    for _, button in pairs(self.buttons or {}) do
        if button.glow then
            button.glow:SetVertexColor(glowColor.r, glowColor.g, glowColor.b, 1)
        end
        if button.manualBadge then
            local mb = TrinketSwitcherCharDB.colors.manualBadge
            button.manualBadge:SetTextColor(mb.r, mb.g, mb.b, 1)
        end
    end
end

function ATS:UpdateCooldownFont()
    local font, size = NumberFontNormal:GetFont()
    if TrinketSwitcherCharDB.largeNumbers then
        size = size + 3
    end
    for _, button in pairs(self.buttons or {}) do
        button.cdText:SetFont(font, size, "THICKOUTLINE")
    end
    if self.menu and self.menu.icons then
        for _, btn in ipairs(self.menu.icons) do
            if btn.cdText then
                btn.cdText:SetFont(font, size, "THICKOUTLINE")
            end
        end
    end
end

function ATS:UpdateLockState()
    if self.buttonFrame then
        local locked = TrinketSwitcherCharDB.lockWindows
        self.buttonFrame:EnableMouse(not locked)
        self.buttonFrame:SetMovable(not locked)
    end
end

-- Tooltip display functions moved to Modules\Tooltips.lua

-- Apply font size to queue numbers in the menu
function ATS:ApplyMenuQueueFont()
    if not (self.menu and self.menu.icons) then return end
    local f, defaultSize = GameFontNormal:GetFont()
    local size = TrinketSwitcherCharDB.queueNumberSize or defaultSize or 12
    for _, btn in ipairs(self.menu.icons) do
        if btn.pos13 then btn.pos13:SetFont(f, size) end
        if btn.pos14 then btn.pos14:SetFont(f, size) end
    end
end

-- Determine if a swap would occur for a slot when out of combat
local function PendingSwap(slot)
    local equippedID = GetInventoryItemID("player", slot)
    -- Announce a switch when a queued trinket is within 35s of being ready (or ready)
    for _, itemID in ipairs(TrinketSwitcherCharDB.queues[slot]) do
        if itemID ~= equippedID then
            local proceed = true
            local count = ATS:GetItemCountSafe(itemID, false)
            if count == 0 then proceed = false end
            if proceed then
                local cd = GetItemRemaining(itemID)
                if cd <= 35 then
                    return true
                end
            end
        end
    end
    return false
end

-- Run check for both slots if out of combat
function ATS:PerformCheck()
    -- Periodically ensure mount state is respected even if an event was missed
    if self.UpdateMountState then self:UpdateMountState() end

    if TrinketSwitcherCharDB.autoSwitch and not InCombatLockdown() and PlayerCanSwap() then
        local cand13 = ChooseCandidate(13)
        local cand14 = ChooseCandidate(14)
        if cand13 and cand14 and cand13 == cand14 then
            local alt14 = ChooseCandidate(14, cand13)
            cand14 = alt14
        end
        if cand13 then
            local allow = true
            if self.lastEquip and self.lastEquip[13] and (GetTime() - self.lastEquip[13] < 0.75) then
                allow = false
            end
            if allow then
            EquipItemSafe(cand13, 13)
            self.lastEquip = self.lastEquip or {}
            self.lastEquip[13] = GetTime()
            end
        end
        if cand14 then
            local allow = true
            if self.lastEquip and self.lastEquip[14] and (GetTime() - self.lastEquip[14] < 0.75) then
                allow = false
            end
            if allow then
            EquipItemSafe(cand14, 14)
            self.lastEquip = self.lastEquip or {}
            self.lastEquip[14] = GetTime()
            end
        end
    end
    self:UpdateButtons()
end

-- Update the icons on the slot buttons
function ATS:UpdateButtons()
    if not self.buttons then return end
    for slot, button in pairs(self.buttons) do
        local itemID = GetInventoryItemID("player", slot)
        local texture = GetInventoryItemTexture("player", slot)
        if texture then
            button.icon:SetTexture(texture)
        else
            button.icon:SetTexture(134400) -- default icon
        end
        if TrinketSwitcherCharDB.autoSwitch and not (TrinketSwitcherCharDB.manual and TrinketSwitcherCharDB.manual[slot]) and InCombatLockdown() and PendingSwap(slot) then
            local c = TrinketSwitcherCharDB.colors.glow
            button.glow:SetVertexColor(c.r, c.g, c.b, 1)
            button.glow:Show()
        else
            button.glow:Hide()
        end

        -- Mount/ready indication reuse the same highlight frame
        if button.mountGlow then
            local mountOverrideActive = (self.mountAutoModified == true) or (TrinketSwitcherCharDB and TrinketSwitcherCharDB.mountOverrideActive)
            local mountActive = self.isMounted or mountOverrideActive
            if mountActive then
                button.mountGlow:SetVertexColor(1, 0, 0, 1)
                button.mountGlow:Show()
            elseif TrinketSwitcherCharDB.readyGlowEnabled ~= false and SlotTrinketReady(slot) then
                local c = TrinketSwitcherCharDB.colors.readyGlow
                button.mountGlow:SetVertexColor(c.r, c.g, c.b, 1)
                button.mountGlow:Show()
            else
                button.mountGlow:Hide()
            end
        end

        -- Manual badge visibility
        if button.manualBadge then
            local isManualSlot = TrinketSwitcherCharDB.manual and TrinketSwitcherCharDB.manual[slot]
            -- Show badge only for per-slot manual state. Ignore global auto state.
            if isManualSlot then button.manualBadge:Show() else button.manualBadge:Hide() end
        end

        -- Handle cooldown overlay and text
        if itemID then
            local fallbackStart, fallbackDuration, fallbackEnable = GetInventoryItemCooldownSafe("player", slot)
            local start, duration, _, sourceItemID = self:GetDisplayItemCooldown(itemID, fallbackStart, fallbackDuration, fallbackEnable)
            TrackItemCooldown(sourceItemID or itemID, start, duration)
            if IsActiveCooldown(start, duration) then
                button.cooldown:SetCooldown(start, duration)
                button.cooldown:Show()
                if TrinketSwitcherCharDB.showCooldownNumbers then
                    local remaining = start + duration - GetTime()
                    if remaining > 0 then
                        if remaining >= 60 then
                            button.cdText:SetText(string.format("%d m", math.ceil(remaining / 60)))
                        else
                            button.cdText:SetText(math.ceil(remaining))
                        end
                        button.cdText:Show()
                    else
                        button.cdText:Hide()
                    end
                else
                    button.cdText:Hide()
                end
            else
                button.cooldown:Hide()
                button.cdText:Hide()
            end
        else
            button.cooldown:Hide()
            button.cdText:Hide()
        end
    end
    if self.menu and self.menu:IsShown() then
        self:UpdateMenuCooldowns()
    end
    -- Keep minimap icon in sync with slot 13
    if self.UpdateMinimapIcon then self:UpdateMinimapIcon() end
end

-- Create the two slot buttons
function ATS:CreateButtons()
    self.buttons = {}

    -- Container frame around the buttons so players can see where to drag
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", "TSButtons", UIParent, template)
    frame:SetSize(84, 60)
    local pos = TrinketSwitcherCharDB.buttonPos or {}
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
    frame:EnableMouse(not TrinketSwitcherCharDB.lockWindows)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        ATS:SaveFramePosition(self, "buttonPos")
    end)

    -- Add a subtle backdrop so the drag area is visible
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.5)
    end

    self.buttonFrame = frame
    self:SetButtonFrameHidden(TrinketSwitcherCharDB.buttonFrameHidden)

    self.queueSetButtons = {}
    for index = 1, 2 do
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(36, 16)
        btn:SetPoint("TOPLEFT", 4 + (index - 1) * 40, -4)
        btn:SetText(tostring(index))
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetHighlightFontObject("GameFontHighlightSmall")
        btn.text = btn:GetFontString()
        btn:SetScript("OnClick", function() ATS:SetActiveQueueSet(index) end)
        self.queueSetButtons[index] = btn
    end

    for index, slot in ipairs({13, 14}) do
        -- Use a secure action button so activating the trinket does not taint
        local btn = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
        btn:SetSize(36, 36)
        btn:SetPoint("BOTTOMLEFT", 4 + (index - 1) * 40, 4)

        btn:RegisterForClicks(self:GetTrinketClickBinding())
        btn:EnableMouse(true)
        btn:SetAttribute("useOnKeyDown", UseActionKeyDown())
        local macroText = "/use " .. tostring(slot)
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("type1", "macro")
        btn:SetAttribute("macrotext", macroText)
        btn:SetAttribute("macrotext1", macroText)

        btn.icon = btn:CreateTexture(nil, "BACKGROUND")
        btn.icon:SetAllPoints(true)

        -- Cooldown overlay and countdown text
        btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cooldown:SetAllPoints(true)
        btn.cooldown:SetFrameLevel(btn:GetFrameLevel())
        btn.cooldown:EnableMouse(false)
        btn.cooldown:SetDrawEdge(false)
        if btn.cooldown.SetHideCountdownNumbers then
            btn.cooldown:SetHideCountdownNumbers(true)
        end
        btn.cooldown:Hide()
        btn.cdText = btn.cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        btn.cdText:SetPoint("CENTER")
        btn.cdText:SetDrawLayer("OVERLAY", 7)
        btn.cdText:Hide()

        btn.glow = btn:CreateTexture(nil, "OVERLAY")
        btn.glow:SetTexture("Interface/Buttons/UI-ActionButton-Border")
        btn.glow:SetBlendMode("ADD")
        btn.glow:SetPoint("CENTER")
        btn.glow:SetSize(60, 60)
        btn.glow:Hide()

        -- Mount mode red glow (separate from pending swap glow)
        btn.mountGlow = btn:CreateTexture(nil, "OVERLAY")
        btn.mountGlow:SetTexture("Interface/Buttons/UI-ActionButton-Border")
        btn.mountGlow:SetBlendMode("ADD")
        btn.mountGlow:SetPoint("CENTER")
        btn.mountGlow:SetSize(64, 64)
        btn.mountGlow:Hide()

        -- Manual mode badge (bottom-left)
        btn.manualBadge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.manualBadge:SetPoint("BOTTOMLEFT", 2, 2)
        btn.manualBadge:SetText("M")
        btn.manualBadge:SetTextColor(1, 1, 1, 1)
        btn.manualBadge:SetDrawLayer("OVERLAY", 8)
        btn.manualBadge:Hide()

        btn.slot = slot

        btn:SetScript("OnEnter", function(self)
            ATS:ShowMenu(btn)
            if TrinketSwitcherCharDB.tooltipMode ~= "OFF" then
                ATS:ShowTooltip(self, slot)
            end
        end)
        btn:SetScript("OnLeave", function()
            ATS:TryHideMenu()
            ATS:HideTooltip()
            ATS.tooltipContext = nil
        end)

        self.buttons[slot] = btn
    end

    self:UpdateButtons()
    self:ApplyColorSettings()
    self:UpdateCooldownFont()
    self:UpdateLockState()
    self:UpdateQueueSetButtons()
    self:UpdateTrinketClickBinding()
end

function ATS:ADDON_LOADED(addonName)
    if addonName ~= "TrinketSwitcher" then return end
    if TrinketSwitcherMirror then
        TrinketSwitcherCharDB = TrinketSwitcherMirror:Load(TrinketSwitcherCharDB) or {}
    end
    EnsureDB()
    if TrinketSwitcherMirror then
        TrinketSwitcherMirror:Watch(TrinketSwitcherCharDB)
    end
    self.savedVariablesReady = true
    self:UnregisterEvent("ADDON_LOADED")
end

function ATS:PLAYER_LOGIN()
    local function ReadActiveTalentGroup()
        local function pick(...)
            for i = 1, select("#", ...) do
                local v = tonumber(select(i, ...))
                if v and v >= 1 then
                    return math.floor(v)
                end
            end
            return nil
        end

        if type(GetActiveTalentGroup) == "function" then
            local okA, a1, a2, a3 = pcall(GetActiveTalentGroup, false, false)
            if okA then
                local g = pick(a1, a2, a3)
                if g then return g end
            end
            local okB, b1, b2, b3 = pcall(GetActiveTalentGroup)
            if okB then
                local g = pick(b1, b2, b3)
                if g then return g end
            end
        end

        if type(GetActiveSpecGroup) == "function" then
            local okC, c1, c2, c3 = pcall(GetActiveSpecGroup)
            if okC then
                local g = pick(c1, c2, c3)
                if g then return g end
            end
        end

        if type(C_SpecializationInfo) == "table" and type(C_SpecializationInfo.GetActiveSpecGroup) == "function" then
            local okD, d1, d2, d3 = pcall(C_SpecializationInfo.GetActiveSpecGroup)
            if okD then
                local g = pick(d1, d2, d3)
                if g then return g end
            end
        end

        return nil
    end

    self.lastKnownTalentGroup = ReadActiveTalentGroup() or self.lastKnownTalentGroup
    EnsureDB()
    -- Initialize or attach to the talent-based profile for the current build
    self:SyncActiveTalentProfile({ silent = true })
    -- Prune missing items from queues on login
    if self.PruneMissingFromQueues then self:PruneMissingFromQueues() end
    self:CreateOptions()
    self:CreateButtons()
    self:CreateMinimapButton()
    self:ApplyCharacterState()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if ATS and ATS.ApplyCharacterState then
                ATS:ApplyCharacterState()
            end
        end)
    end
    self.elapsed = 0
    self.cdElapsed = 0
    self.mountAutoModified = false
    self.prevAutoSwitch = nil
    self.isMounted = false
    self:SetScript("OnUpdate", function(_, e)
        self.elapsed = self.elapsed + e
        self.cdElapsed = self.cdElapsed + e
        if self.elapsed > 1 then
            self.elapsed = 0
            self:PerformCheck()
        end
        if self.cdElapsed > 0.1 then
            self.cdElapsed = 0
            self:UpdateButtons()
        end
    end)
    -- Clear tooltip context if tooltip is hidden by any external cause
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnHide", function()
            ATS.tooltipContext = nil
        end)
    end
    -- Initialize mount state
    if self.UpdateMountState then self:UpdateMountState() end

    -- Slash command: /ts and /trinketswitcher show quick usage help
    SLASH_TRINKETSWITCHER1 = "/ts"
    SLASH_TRINKETSWITCHER2 = "/trinketswitcher"
    SlashCmdList["TRINKETSWITCHER"] = function(msg)
        local function out(text)
            DEFAULT_CHAT_FRAME:AddMessage(text)
        end
        local function header(text)
            out("|cffffd100" .. text .. "|r")
        end
        local function bullet(text)
            out("  - " .. text)
        end

        msg = tostring(msg or ""):lower():gsub("^%s+"," "):gsub("%s+$","")
        if msg:match("^clear") then
            local which = msg:match("^clear%s+(%S+)") or ""
            local function clear(slot)
                TrinketSwitcherCharDB.queues[slot] = {}
            end
            if which == "13" then
                clear(13)
                header("Trinket Switcher")
                bullet("Cleared queue for slot 13")
            elseif which == "14" then
                clear(14)
                header("Trinket Switcher")
                bullet("Cleared queue for slot 14")
            elseif which == "both" or which == "all" then
                clear(13); clear(14)
                header("Trinket Switcher")
                bullet("Cleared queues for slot 13 and 14")
            else
                header("Trinket Switcher")
                bullet("Usage: /ts clear 13 | 14 | both")
            end
            if ATS.menu and ATS.menu:IsShown() and ATS.menu.anchor then ATS:ShowMenu(ATS.menu.anchor) end
            ATS:UpdateButtons()
            return
        end

        -- Help
        header("Trinket Switcher")
        bullet("Hover: Shows menu; also shows tooltip if enabled")
        bullet("Left-click: Use Trinket")
        bullet("Shift + Left/Right-Click: Add/Remove trinket to the priority queue (Left = slot 13, Right = slot 14)")
        bullet("Ctrl + Left/Right-Click: Equip AND toggle manual mode (Left = slot 13, Right = slot 14)")
        bullet("Slash: /ts clear 13 | 14 | both")
    end
end

function ATS:PLAYER_LOGOUT()
    self:SaveCharacterState()
    if TrinketSwitcherMirror then
        TrinketSwitcherMirror:Flush()
    end
end

local function RegisterEventSafe(event)
    pcall(ATS.RegisterEvent, ATS, event)
end

for _, event in ipairs({
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    "PLAYER_REGEN_ENABLED",
    "UNIT_AURA",
    "PLAYER_MOUNT_DISPLAY_CHANGED",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS",
    "ZONE_CHANGED_NEW_AREA",
    "MODIFIER_STATE_CHANGED",
    "CHARACTER_POINTS_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
    "TRAIT_CONFIG_UPDATED",
    "CVAR_UPDATE",
}) do
    RegisterEventSafe(event)
end
ATS:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        self:PerformCheck()
    elseif event == "UNIT_AURA" then
        -- React to mount state changes via aura changes
        self:UpdateMountState()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        self:UpdateMountState()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        self:UpdateMountState()
    elseif event == "CHARACTER_POINTS_CHANGED" then
        -- Talent points can change many times during a respec; wait for the sequence to settle.
        self:QueueTalentConfigurationChanged()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        local arg1, arg2 = ...
        if event == "ACTIVE_TALENT_GROUP_CHANGED" then
            local currentGroup = tonumber(arg1)
            local previousGroup = tonumber(arg2)
            if currentGroup and currentGroup >= 1 then
                self.lastKnownTalentGroup = currentGroup
            elseif previousGroup and previousGroup >= 1 then
                self.lastKnownTalentGroup = previousGroup
            end
        end
        local isUnitEvent = event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
        if not isUnitEvent or arg1 == nil or arg1 == "player" then
            local delay = (event == "ACTIVE_TALENT_GROUP_CHANGED" or isUnitEvent or event == "TRAIT_CONFIG_UPDATED") and 0.35 or nil
            self:QueueTalentConfigurationChanged(delay)
        end
    elseif event == "CVAR_UPDATE" then
        local cvar = ...
        if cvar == "ActionButtonUseKeyDown" then
            self:UpdateTrinketClickBinding()
            if not InCombatLockdown() then
                for _, button in pairs(self.buttons or {}) do
                    button:SetAttribute("useOnKeyDown", UseActionKeyDown())
                end
            end
        end
    elseif self[event] then
        self[event](self, ...)
    end
end)

-- Talent-change handling moved to Modules\Profiles.lua

-- Mount handling: auto-disable autoSwitch when mounting; restore previous state on dismount
function ATS:UpdateMountState()
    EnsureDB()
    local db = TrinketSwitcherCharDB
    local prevMounted = self.isMounted
    local mounted = false
    if IsMounted then
        mounted = IsMounted()
    else
        -- Fallback: simple check via movement speed or auras is omitted to avoid false positives in Classic
        mounted = false
    end

    local refreshButtons = false
    local refreshOptions = false

    if mounted then
        -- Rehydrate the mount override if we relog while already mounted
        if not self.mountAutoModified and db.mountOverrideActive then
            self.prevAutoSwitch = db.mountOverridePrevAutoSwitch
            self.mountAutoModified = true
            refreshButtons = true
            refreshOptions = true
        end

        if not self.mountAutoModified and db.autoSwitch then
            local previous = db.autoSwitch and true or false
            db.autoSwitch = false
            self.prevAutoSwitch = previous
            self.mountAutoModified = true
            db.mountOverrideActive = true
            db.mountOverridePrevAutoSwitch = previous
            refreshButtons = true
            refreshOptions = true
        end

    else
        if self.mountAutoModified or db.mountOverrideActive then
            local restore = self.prevAutoSwitch
            if restore == nil then
                restore = db.mountOverridePrevAutoSwitch
            end
            db.autoSwitch = restore and true or false
            self.prevAutoSwitch = nil
            self.mountAutoModified = false
            db.mountOverrideActive = false
            db.mountOverridePrevAutoSwitch = nil
            refreshButtons = true
            refreshOptions = true
        end

        -- Re-assert manual selections after dismount, with a short retry if equipment events lag.
        if prevMounted and not mounted then
            self:RestoreManualSlots()
            if C_Timer and C_Timer.After then
                C_Timer.After(0.35, function()
                    if ATS and ATS.isMounted then return end
                    if ATS and ATS.RestoreManualSlots then ATS:RestoreManualSlots() end
                    if ATS and ATS.UpdateButtons then ATS:UpdateButtons() end
                end)
            end
        end
    end

    self.isMounted = mounted

    if refreshOptions then
        self:UpdateOptionsAutoCheckbox()
    end

    if refreshButtons or prevMounted ~= mounted then
        self:UpdateButtons()
    end
end

-- Respond to ALT (or any modifier) changes to live-refresh tooltip details
function ATS:MODIFIER_STATE_CHANGED()
    if not TrinketSwitcherCharDB or not TrinketSwitcherCharDB.altFullTooltips then return end
    self:RefreshTooltip()
end

-- Remove any queued items that are not currently in the player's bags or equipped
function ATS:PruneMissingFromQueues()
    if not TrinketSwitcherCharDB or not TrinketSwitcherCharDB.queues then return end
    for _, slot in ipairs({13,14}) do
        local q = TrinketSwitcherCharDB.queues[slot]
        if q then
            local i = 1
            while i <= #q do
                local id = q[i]
                local count = self:GetItemCountSafe(id, false)
                local eq13 = GetInventoryItemID("player", 13)
                local eq14 = GetInventoryItemID("player", 14)
                if count == 0 and id ~= eq13 and id ~= eq14 then
                    table.remove(q, i)
                else
                    i = i + 1
                end
            end
        end
    end
    if self.menu and self.menu:IsShown() then
        self:RefreshMenuNumbers()
    end
end
