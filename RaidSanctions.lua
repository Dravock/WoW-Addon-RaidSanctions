-- Main file for RaidSanctions Addon
-- Event management and addon initialization

local addonName, addonTable = ...

-- Create event frame
local eventFrame = CreateFrame("Frame", "RaidSanctionsEventFrame")
local isInitialized = false

-- Event handler
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            OnAddonLoaded()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        OnPlayerEnteringWorld()
    elseif event == "GROUP_ROSTER_UPDATE" then
        OnGroupRosterUpdate()
    end
end

function OnAddonLoaded()
    -- Initialize Logic module
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnAddonLoaded()
        isInitialized = true
    end
end

function OnPlayerEnteringWorld()
    if not isInitialized then
        return
    end
    
    -- Forward Logic event
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnPlayerEnteringWorld()
    end
end

function OnGroupRosterUpdate()
    if not isInitialized then
        return
    end
    
    -- Forward Logic event
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnGroupRosterUpdate()
    end
end

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", OnEvent)

-- Slash-Commands
SLASH_RAIDSANCTIONS1 = "/sanktions"
SLASH_RAIDSANCTIONS2 = "/rs"
SlashCmdList["RAIDSANCTIONS"] = function(msg)
    local command = msg:lower():trim()
    
    if command == "" or command == "show" then
        -- Show/hide UI
        if RaidSanctions.UI then
            RaidSanctions.UI:Toggle()
        end
    elseif command == "reset" then
        -- Reset data
        if RaidSanctions.Logic then
            RaidSanctions.Logic:ResetSessionData()
        end
    elseif command == "updatepenalties" then
        -- Force update penalties to English
        if RaidSanctions.Logic then
            RaidSanctions.Logic:UpdatePenaltiesToEnglish()
        end
    elseif command == "help" then
        -- Show help
        print("RaidSanctions Commands:")
        print("/rs or /rs show - Open/close UI")
        print("/rs reset - Reset current session data")
        print("/rs updatepenalties - Update penalty names to English")
        print("/rs debug - Show detected players")
        print("/rs help - Show this help")
    elseif command == "debug" then
        -- Show debug information
        if RaidSanctions.Logic then
            local session = RaidSanctions.Logic:GetCurrentSession()
            if session then
                print("Current Session: " .. session.id)
                print("Detected Players:")
                for name, data in pairs(session.players) do
                    print("  - " .. name .. " (" .. (data.class or "UNKNOWN") .. ", Level " .. (data.level or "?") .. ")")
                end
            else
                print("No active session found.")
            end
            
            if IsInRaid() then
                print("Status: In Raid (" .. GetNumGroupMembers() .. " members)")
            elseif IsInGroup() then
                print("Status: In Group (" .. GetNumGroupMembers() .. " members)")
            else
                print("Status: Solo")
            end
        end
    else
        print("Unknown command. Use '/rs help' for help.")
    end
end

-- Compatibility functions for old API (in case other addons use these)
function RaidSanctions_OnLoad(self)
    -- Deprecated - maintained for backward compatibility
    print("Warning: RaidSanctions_OnLoad is deprecated. The addon has already been initialized.")
end

function RaidSanctions_OnEvent(self, event, ...)
    -- Deprecated - maintained for backward compatibility
    OnEvent(self, event, ...)
end

-- Globally available functions for other addons
function RaidSanctions_ApplyPenalty(playerName, reason, amount)
    if RaidSanctions.Logic then
        return RaidSanctions.Logic:ApplyPenalty(playerName, reason, amount)
    end
    return false
end

function RaidSanctions_GetPlayerTotal(playerName)
    if RaidSanctions.Logic then
        return RaidSanctions.Logic:GetPlayerTotal(playerName)
    end
    return 0
end

