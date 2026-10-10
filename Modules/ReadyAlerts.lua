local ATS = TrinketSwitcherFrame
local slots = {13, 14}
local glowLibrary = LibStub("LibCustomGlow-1.0")
local glowKey = "TrinketSwitcherReady"
ATS.readySounds = {"Chime", "Bell", "Pulse"}

function ATS:PlayReadySound()
    local db = TrinketSwitcherCharDB
    local name = db.readySound
    if name ~= "Chime" and name ~= "Bell" and name ~= "Pulse" then name = "Chime" end
    local volume = math.max(10, math.min(100, math.floor((db.readySoundVolume or 70) / 10 + 0.5) * 10))
    PlaySoundFile("Interface\\AddOns\\TrinketSwitcher\\Media\\Sounds\\" .. name .. volume .. ".wav", "Master")
end

-- Only slot-use lines count, including conditional alternatives such as
-- /use [combat] 13; [nocombat] 14. Readiness is independent of macro conditions.
local function MacroSlots(body)
    local result = {}
    for line in (body or ""):gmatch("[^\r\n]+") do
        local args = line:lower():match("^%s*/use%s+(.+)")
        if args then
            args = args:gsub("%b[]", "")
            for alternative in args:gmatch("[^;]+") do
                local slot = tonumber(alternative:match("^%s*(%d+)%s*$"))
                if slot == 13 or slot == 14 then result[slot] = true end
            end
        end
    end
    return result
end

local actionButtonGroups = {
    {"ActionButton", 12},
    {"MultiBarBottomLeftButton", 12},
    {"MultiBarBottomRightButton", 12},
    {"MultiBarLeftButton", 12},
    {"MultiBarRightButton", 12},
    {"MultiBar5Button", 12},
    {"MultiBar6Button", 12},
    {"MultiBar7Button", 12},
    {"BT4Button", 180},
    {"DominosActionButton", 180},
}

local function ButtonMacroID(button)
    local kind, action
    if button.GetAction then
        -- LibActionButton (Bartender) supports direct macros as well as slots.
        kind, action = button:GetAction()
    else
        kind = "action"
        action = button.action or (button.GetAttribute and button:GetAttribute("action"))
    end
    if issecretvalue and (issecretvalue(kind) or issecretvalue(action)) then return end
    if kind == "action" and type(action) == "number" and action > 0 then
        local actionSlot = action
        kind, action = GetActionInfo(actionSlot)
        if issecretvalue and issecretvalue(kind) then return end
        if kind == "macro" then
            -- Some clients return the macro's spell/item ID, not its index.
            local name = GetActionText(actionSlot)
            if issecretvalue and issecretvalue(name) then return end
            action = name and GetMacroIndexByName(name) or nil
            if action == 0 then return end
        end
    end
    if issecretvalue and (issecretvalue(kind) or issecretvalue(action)) then return end
    if kind == "macro" and (type(action) == "number" or type(action) == "string") then
        return action
    end
end

function ATS:RefreshMacroButtons()
    self.macroButtons = self.macroButtons or {}
    -- Never enumerate unrelated UI frames: aura-provider objects can reject
    -- IsObjectType even after an IsForbidden check in this client.
    for _, group in ipairs(actionButtonGroups) do
        for index = 1, group[2] do
            local button = _G[group[1] .. index]
            if button and not button:IsForbidden() then
                self.macroButtons[button] = true
            end
        end
    end
end

function ATS:UpdateReadyAlerts()
    local db = TrinketSwitcherCharDB
    if not db then return end
    self.readyAlertState = self.readyAlertState or {}
    local ready, alert = {}, false
    for _, slot in ipairs(slots) do
        local itemID = GetInventoryItemID("player", slot)
        local start, duration, enabled
        if GetInventoryItemCooldown then
            start, duration, enabled = GetInventoryItemCooldown("player", slot)
        else
            start, duration, enabled = self:GetItemCooldownSafe(itemID)
        end
        local secret = issecretvalue and (issecretvalue(start) or issecretvalue(duration) or issecretvalue(enabled))
        if not secret then
            start, duration = start or 0, duration or 0
            -- Trinket use/equip/shared cooldowns exceed the GCD. Ignore short
            -- cooldown reports entirely, so casting never toggles readiness.
            local previous = self.readyAlertState[slot]
            local cooling = duration > 2 and self:GetCooldownRemaining(start, duration) > 0
            local endsAt = cooling and (start + duration) or nil
            -- If a short GCD report masks a known item cooldown, keep that
            -- cooldown until its recorded end rather than emitting a false alert.
            if duration > 0 and duration <= 2 and previous and previous.itemID == itemID
                and previous.endsAt and previous.endsAt > GetTime() then
                cooling, endsAt = true, previous.endsAt
            end
            -- Inventory cooldown's enable flag identifies on-use trinkets,
            -- without depending on item spell data having loaded into cache.
            local usable = itemID and enabled == 1
            if not GetInventoryItemCooldown then
                usable = itemID and self:GetItemSpellSafe(itemID) and enabled ~= 0 and enabled ~= false
            end
            ready[slot] = usable and not cooling
            if db.readySoundEnabled and ready[slot] and previous and previous.itemID == itemID and previous.cooling then
                alert = true
            end
            self.readyAlertState[slot] = {itemID = itemID, cooling = cooling, endsAt = endsAt}
        else
            self.readyAlertState[slot] = nil
        end
    end
    -- Coalesce shared cooldown completion into a single alert.
    if alert then self:PlayReadySound() end

    local macros = {}
    for button in pairs(self.macroButtons or {}) do
        -- A previously discovered button can become forbidden later.
        if button:IsForbidden() then
            self.macroButtons[button] = nil
        else
            local show = false
            if db.macroReadyGlowEnabled and button:IsVisible() then
                local id = ButtonMacroID(button)
                if id then
                    if not macros[id] then macros[id] = MacroSlots(GetMacroBody(id)) end
                    for slot in pairs(macros[id]) do
                        if ready[slot] then show = true end
                    end
                end
            end
            local color = db.colors.macroReadyGlow
            local width = math.max(1, math.min(10, math.floor((tonumber(db.macroReadyGlowWidth) or 2) + 0.5)))
            local previous = button.tsMacroReadyGlowColor
            if show then
                if not previous or previous.r ~= color.r or previous.g ~= color.g or previous.b ~= color.b or previous.width ~= width then
                    -- Use a private key so other addons' proc glows stay independent.
                    glowLibrary.PixelGlow_Start(button, {color.r, color.g, color.b, 1},
                        8, 0.25, nil, width, 0, 0, false, glowKey)
                    button.tsMacroReadyGlowColor = {r = color.r, g = color.g, b = color.b, width = width}
                end
            elseif previous then
                glowLibrary.PixelGlow_Stop(button, glowKey)
                button.tsMacroReadyGlowColor = nil
            end
        end
    end
end

function ATS:StartReadyAlerts()
    if self.readyAlertFrame then return end
    local frame = CreateFrame("Frame")
    self.readyAlertFrame = frame
    local elapsed, scanElapsed = 0, 2
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed, scanElapsed = elapsed + delta, scanElapsed + delta
        if elapsed < 0.1 then return end
        elapsed = 0
        if scanElapsed >= 2 and TrinketSwitcherCharDB.macroReadyGlowEnabled then
            scanElapsed = 0
            ATS:RefreshMacroButtons()
        end
        ATS:UpdateReadyAlerts()
    end)
end
