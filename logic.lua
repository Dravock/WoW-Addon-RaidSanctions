-- Core Logic for RaidSanctions Addon
-- Handles business logic, events and data persistence

local addonName, addonTable = ...

-- Create namespace
RaidSanctions = RaidSanctions or {}
RaidSanctions.Logic = {}

-- Local references for better performance
local Logic = RaidSanctions.Logic
local format = string.format
local pairs, ipairs = pairs, ipairs
local wipe = table.wipe or wipe

-- Constants
local ADDON_VERSION = "1.1"
local DEBUG_MODE = false

-- Default penalties (can be configured)
local DEFAULT_PENALTIES = {
    ["Late"] = 10000,          -- 1g
    ["AFK"] = 10000,           -- 1g
    ["Wrong Gear"] = 10000,    -- 1g
    ["Wrong Tactic"] = 10000,  -- 1g
    ["Disruption"] = 10000     -- 1g
}

-- Localization
local L = {
    ["LATE"] = "Late",
    ["AFK"] = "AFK", 
    ["WRONG_GEAR"] = "Wrong Gear",
    ["WRONG_TACTIC"] = "Wrong Tactic",
    ["DISRUPTION"] = "Disruption",
    ["TOTAL"] = "Total",
    ["ADDON_LOADED"] = "RaidSanctions v%s loaded.",
    ["PENALTY_APPLIED"] = "%s penalized with '%s': +%s | Total: %s",
    ["DATA_RESET"] = "All sanction data has been reset."
}

-- Database functions
function Logic:InitializeDatabase()
    -- Global database
    RaidSanctionsDB = RaidSanctionsDB or {
        version = ADDON_VERSION,
        penalties = {},
        settings = {
            showInCombat = false,
            autoHide = true,
            soundEnabled = true
        }
    }
    
    -- Initialize penalties if they don't exist
    if not RaidSanctionsDB.penalties or next(RaidSanctionsDB.penalties) == nil then
        RaidSanctionsDB.penalties = {}
        for reason, amount in pairs(DEFAULT_PENALTIES) do
            RaidSanctionsDB.penalties[reason] = amount
        end
    end
    
    -- Character-specific database
    RaidSanctionsCharDB = RaidSanctionsCharDB or {
        sessions = {},
        currentSession = nil
    }
    
    -- Version check and migration if needed
    if RaidSanctionsDB.version ~= ADDON_VERSION then
        self:MigrateDatabase()
    end
end

function Logic:MigrateDatabase()
    -- Data migration logic for future versions can be added here
    
    -- Update penalties to English names if they are still in German
    if RaidSanctionsDB.penalties then
        -- Check for German penalty names and replace with English
        local oldPenalties = RaidSanctionsDB.penalties
        local hasGermanNames = false
        
        -- Check if we have German names
        for name, _ in pairs(oldPenalties) do
            if name == "Zu spät" or name == "Falsche Taktik" or name == "Falsches Gear" or name == "Störung" then
                hasGermanNames = true
                break
            end
        end
        
        if hasGermanNames then
            -- Replace with English penalties
            RaidSanctionsDB.penalties = DEFAULT_PENALTIES
            print("RaidSanctions: Updated penalty names to English")
        end
    end
    
    RaidSanctionsDB.version = ADDON_VERSION
    if DEBUG_MODE then
        print("Database migrated to version " .. ADDON_VERSION)
    end
end

function Logic:CreateNewSession()
    local sessionId = date("%Y%m%d_%H%M%S")
    local session = {
        id = sessionId,
        date = date(),
        timestamp = time(),
        players = {},
        isActive = true
    }
    
    RaidSanctionsCharDB.sessions[sessionId] = session
    RaidSanctionsCharDB.currentSession = sessionId
    
    return session
end

function Logic:GetCurrentSession()
    local sessionId = RaidSanctionsCharDB.currentSession
    if sessionId and RaidSanctionsCharDB.sessions[sessionId] then
        return RaidSanctionsCharDB.sessions[sessionId]
    end
    return nil
end

function Logic:UpdateRaidMembers()
    -- Support for both Raid AND Party/Group
    if not (IsInRaid() or IsInGroup()) then
        return
    end
    
    local session = self:GetCurrentSession()
    if not session then
        session = self:CreateNewSession()
    end
    
    -- Get current group members (Raid or Party)
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local name, rank, subgroup, level, class
        
        if IsInRaid() then
            -- Raid mode
            name, rank, subgroup, level, class = GetRaidRosterInfo(i)
        else
            -- Party mode
            if i == 1 then
                -- Own player
                name = UnitName("player")
                class = select(2, UnitClass("player"))
                level = UnitLevel("player")
                rank = 0
                subgroup = 1
            else
                -- Party members
                local unitId = "party" .. (i - 1)
                if UnitExists(unitId) then
                    name = UnitName(unitId)
                    class = select(2, UnitClass(unitId))
                    level = UnitLevel(unitId)
                    rank = 0
                    subgroup = 1
                end
            end
        end
        
        if name and not session.players[name] then
            session.players[name] = {
                class = class or "UNKNOWN",
                level = level or 0,
                subgroup = subgroup or 1,
                rank = rank or 0,
                penalties = {},
                total = 0,
                joinedAt = time()
            }
        end
    end
end

function Logic:ApplyPenalty(playerName, reason, amount)
    local session = self:GetCurrentSession()
    if not session or not session.players[playerName] then
        return false
    end
    
    local player = session.players[playerName]
    local timestamp = time()
    
    -- Create penalty entry
    local penaltyEntry = {
        reason = reason,
        amount = amount,
        timestamp = timestamp,
        date = date("%H:%M:%S")
    }
    
    table.insert(player.penalties, penaltyEntry)
    player.total = player.total + amount
    
    -- Feedback
    local message = format(L["PENALTY_APPLIED"], 
        playerName, reason, 
        self:FormatGold(amount), 
        self:FormatGold(player.total)
    )
    print(message)
    
    -- Play sound if enabled
    if RaidSanctionsDB.settings.soundEnabled then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    
    return true
end

function Logic:GetPlayerTotal(playerName)
    local session = self:GetCurrentSession()
    if session and session.players[playerName] then
        return session.players[playerName].total
    end
    return 0
end

function Logic:ResetSessionData()
    local session = self:GetCurrentSession()
    if session then
        session.players = {}
    end
    print(L["DATA_RESET"])
end

function Logic:ResetPlayerPenalties(playerName)
    if not playerName then
        return false
    end
    
    local session = self:GetCurrentSession()
    if not session or not session.players[playerName] then
        return false
    end
    
    -- Reset player data
    session.players[playerName].penalties = {}
    session.players[playerName].total = 0
    
    print("Penalties for " .. playerName .. " have been reset - Player marked as paid.")
    return true
end

function Logic:AddPlayerManually(playerName)
    if not playerName or playerName:trim() == "" then
        return false
    end
    
    local session = self:GetCurrentSession()
    if not session then
        session = self:CreateNewSession()
    end
    
    -- Check if player already exists
    if session.players[playerName] then
        return false -- Player already exists
    end
    
    -- Add player with default data
    session.players[playerName] = {
        class = "UNKNOWN", -- Class unknown as manually added
        level = 0,
        subgroup = 0,
        rank = 0,
        penalties = {},
        total = 0,
        joinedAt = time(),
        addedManually = true
    }
    
    return true
end

function Logic:FormatGold(amount)
    local gold = math.floor(amount / 10000)
    
    -- Always display as gold only
    if gold > 0 then
        return gold .. "g"
    else
        return "0g"
    end
end

function Logic:GetPenalties()
    return RaidSanctionsDB.penalties
end

function Logic:SetCustomPenalties(newPenalties)
    -- Validate and set custom penalties
    if type(newPenalties) ~= "table" then
        return false
    end
    
    -- Update the database with new penalties
    for reason, amount in pairs(newPenalties) do
        if type(reason) == "string" and type(amount) == "number" and amount >= 0 then
            RaidSanctionsDB.penalties[reason] = amount
        end
    end
    
    return true
end

function Logic:ResetPenaltiesToDefault()
    RaidSanctionsDB.penalties = {}
    for reason, amount in pairs(DEFAULT_PENALTIES) do
        RaidSanctionsDB.penalties[reason] = amount
    end
end

function Logic:UpdatePenaltiesToEnglish()
    -- Force update penalties to English names
    RaidSanctionsDB.penalties = DEFAULT_PENALTIES
    print("RaidSanctions: Penalty names updated to English. Please reload the UI (/rs show).")
end

function Logic:SetPenalty(reason, amount)
    RaidSanctionsDB.penalties[reason] = amount
end

function Logic:GetSettings()
    return RaidSanctionsDB.settings
end

function Logic:Debug(message)
    if DEBUG_MODE then
        print("[RaidSanctions Debug]: " .. tostring(message))
    end
end

-- Event handlers
function Logic:OnAddonLoaded()
    self:InitializeDatabase()
    print(format(L["ADDON_LOADED"], ADDON_VERSION))
end

function Logic:OnPlayerEnteringWorld()
    -- Check if in raid or group and update session
    if IsInRaid() or IsInGroup() then
        self:UpdateRaidMembers()
    end
end

function Logic:OnGroupRosterUpdate()
    if IsInRaid() or IsInGroup() then
        self:UpdateRaidMembers()
        -- Update UI if visible
        if RaidSanctions.UI and RaidSanctions.UI.RefreshPlayerList then
            RaidSanctions.UI:RefreshPlayerList()
        end
    else
        -- No longer in group - mark session as inactive
        local session = self:GetCurrentSession()
        if session then
            session.isActive = false
        end
    end
end

-- Export for other modules
RaidSanctions.Logic = Logic
