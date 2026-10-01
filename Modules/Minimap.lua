local ATS = TrinketSwitcherFrame
local ATS_MINIMAP_LOGO = "Interface\\AddOns\\TrinketSwitcher\\Media\\TrinketSwitcher_Logo.blp"

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

function ATS:OnMinimapClick(mouse)
    if self.EnsureDB then self:EnsureDB() end

    if mouse == "LeftButton" then
        if self.buttonFrame then
            self:SetButtonFrameHidden(self.buttonFrame:IsShown())
        end
    elseif mouse == "RightButton" then
        if IsShiftKeyDown() then
            TrinketSwitcherCharDB.lockWindows = not TrinketSwitcherCharDB.lockWindows
            if self.UpdateLockState then self:UpdateLockState() end
        elseif IsControlKeyDown() then
            local manual = TrinketSwitcherCharDB.manual or {}
            local on = not ((manual[13]) and (manual[14]))
            self:SetGlobalAutoSwitch(not on)
        else
            if self.optionsWindow then
                if self.optionsWindow:IsShown() then
                    self.optionsWindow:Hide()
                    if self.optionsPanel then self.optionsPanel:Hide() end
                else
                    if self.optionsPanel then self.optionsPanel:Show() end
                    self.optionsWindow:Show()
                end
            end
        end
        if self.menu and self.menu:IsShown() then self.menu:Hide() end
    end
end

function ATS:OnMinimapTooltipShow(tooltip)
    if not tooltip then return end
    tooltip:SetText("TrinketSwitcher")
    local WHITE = "FFFFFFFF"
    local GOLD  = "FFFFD100"
    local function line(label, text)
        return "|c"..WHITE..label.."|r |c"..GOLD..text.."|r"
    end
    tooltip:AddLine(line("Left-Click:", "Show/Hide Trinkets"))
    tooltip:AddLine(line("Right-Click:", "Open Option Menu"))
    tooltip:AddLine(line("Ctrl + Right-Click:", "Toggle Auto Switching"))
    tooltip:AddLine(line("Shift + Right-Click:", "Lock/Unlock Buttons"))
    tooltip:Show()
end

function ATS:UpdateMinimapIcon()
    if self.minimapLDB then
        self.minimapLDB.icon = ATS_MINIMAP_LOGO
        self.minimapLDB.iconCoords = {0.08, 0.92, 0.08, 0.92}
    end

    if not self.minimapButton or not self.minimapButton.icon then
        return
    end

    self.minimapButton.icon:SetTexture(ATS_MINIMAP_LOGO)
    if self.minimapButton.icon.SetTexCoord then
        self.minimapButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

function ATS:CreateMinimapButton()
    if self.EnsureDB then self:EnsureDB() end
    local db = TrinketSwitcherCharDB

    if LDB and LDBIcon then
        if not self.minimapLDB then
            self.minimapLDB = LDB:NewDataObject("TrinketSwitcher", {
                type = "launcher",
                icon = ATS_MINIMAP_LOGO,
                iconCoords = {0.08, 0.92, 0.08, 0.92},
                OnClick = function(_, mouse) ATS:OnMinimapClick(mouse) end,
                OnTooltipShow = function(tooltip) ATS:OnMinimapTooltipShow(tooltip) end,
            })
        else
            self.minimapLDB.icon = ATS_MINIMAP_LOGO
            self.minimapLDB.iconCoords = {0.08, 0.92, 0.08, 0.92}
        end

        db.minimap = db.minimap or { hide = false }

        if not LDBIcon:IsRegistered("TrinketSwitcher") then
            LDBIcon:Register("TrinketSwitcher", self.minimapLDB, db.minimap)
        end

        if db.minimap.hide then
            LDBIcon:Hide("TrinketSwitcher")
        else
            LDBIcon:Show("TrinketSwitcher")
        end

        if LDBIcon.GetMinimapButton then
            self.minimapButton = LDBIcon:GetMinimapButton("TrinketSwitcher") or self.minimapButton
        end

        self:UpdateMinimapIcon()
        return
    end

    local btn = CreateFrame("Button", "TS_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("CENTER", 0, 0)
    btn.icon:SetSize(20, 20)
    btn.icon:SetTexture(ATS_MINIMAP_LOGO)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    btn.border:SetSize(54, 54)
    btn.border:ClearAllPoints()
    btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    btn:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

    btn:SetScript("OnClick", function(_, mouse) ATS:OnMinimapClick(mouse) end)

    btn:SetScript("OnEnter", function(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        ATS:OnMinimapTooltipShow(GameTooltip)
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.minimapButton = btn
    self:UpdateMinimapIcon()
end
