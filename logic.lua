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
        currentSession = nil,
        seasonData = {} -- Initialize season data
    }
    
    -- Initialize season data if it doesn't exist
    if not RaidSanctionsCharDB.seasonData then
        RaidSanctionsCharDB.seasonData = {}
    end
    
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
    
    -- Create unique ID for this penalty (combining timestamp with random component)
    local uniqueId = timestamp .. "_" .. math.random(1000, 9999)
    
    -- Create penalty entry
    local penaltyEntry = {
        reason = reason,
        amount = amount,
        timestamp = timestamp,
        date = date("%H:%M:%S"),
        uniqueId = uniqueId -- Add unique identifier
    }
    
    table.insert(player.penalties, penaltyEntry)
    player.total = player.total + amount
    
    -- Update season data automatically
    self:UpdateSeasonData()
    
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
    
    -- Format large amounts with k suffix
    if gold >= 1000000 then
        -- Millions: 1500000g -> 1500k Gold
        local millions = math.floor(gold / 1000)
        return millions .. "k Gold"
    elseif gold >= 1000 then
        -- Thousands: 1500g -> 1.5k Gold or 1000g -> 1k Gold
        local thousands = gold / 1000
        if thousands == math.floor(thousands) then
            -- Whole thousands
            return math.floor(thousands) .. "k Gold"
        else
            -- Decimal thousands (1 decimal place)
            return string.format("%.1fk Gold", thousands)
        end
    elseif gold > 0 then
        -- Regular gold amounts
        return gold .. " Gold"
    else
        return "0 Gold"
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

-- Season Stats Functionality
function Logic:GetSeasonData()
    -- Initialize season data if it doesn't exist
    if not RaidSanctionsCharDB.seasonData then
        RaidSanctionsCharDB.seasonData = {}
    end
    
    -- Migrate existing season data to add processedSessionPenalties field
    for playerName, playerData in pairs(RaidSanctionsCharDB.seasonData) do
        if not playerData.processedSessionPenalties then
            playerData.processedSessionPenalties = {}
            
            -- Mark all existing penalties as processed to avoid duplicates
            for i, penalty in ipairs(playerData.penalties or {}) do
                -- Use uniqueId if available, fallback to old system for compatibility
                local penaltyId = penalty.uniqueId or (penalty.timestamp .. "_" .. penalty.reason .. "_" .. penalty.amount .. "_" .. i)
                playerData.processedSessionPenalties[penaltyId] = true
            end
        end
    end
    
    return RaidSanctionsCharDB.seasonData
end

function Logic:UpdateSeasonData()
    -- Get current session data
    local session = self:GetCurrentSession()
    if not session or not session.players then
        return
    end
    
    -- Initialize season data if needed
    local seasonData = self:GetSeasonData()
    
    -- Update season data with current session
    for playerName, playerData in pairs(session.players) do
        if not seasonData[playerName] then
            seasonData[playerName] = {
                class = playerData.class,
                penalties = {},
                totalAmount = 0,
                totalPenalties = 0,
                lastSeen = time(),
                processedSessionPenalties = {} -- Track which penalties we've already processed
            }
        end
        
        -- Update player's season data
        local seasonPlayer = seasonData[playerName]
        seasonPlayer.class = playerData.class or seasonPlayer.class
        seasonPlayer.lastSeen = time()
        
        -- Initialize processed penalties tracker if it doesn't exist
        if not seasonPlayer.processedSessionPenalties then
            seasonPlayer.processedSessionPenalties = {}
        end
        
        -- Add new penalties from current session to season data (avoid duplicates)
        for i, penalty in ipairs(playerData.penalties) do
            -- Use uniqueId if available, fallback to old system for compatibility
            local penaltyId = penalty.uniqueId or (penalty.timestamp .. "_" .. penalty.reason .. "_" .. penalty.amount .. "_" .. i)
            
            -- Check if we've already processed this penalty
            if not seasonPlayer.processedSessionPenalties[penaltyId] then
                -- Add penalty to season data
                table.insert(seasonPlayer.penalties, {
                    reason = penalty.reason,
                    amount = penalty.amount,
                    timestamp = penalty.timestamp,
                    date = penalty.date,
                    sessionId = session.id,
                    uniqueId = penalty.uniqueId -- Preserve uniqueId
                })
                
                -- Update totals
                seasonPlayer.totalAmount = seasonPlayer.totalAmount + penalty.amount
                seasonPlayer.totalPenalties = seasonPlayer.totalPenalties + 1
                
                -- Mark penalty as processed
                seasonPlayer.processedSessionPenalties[penaltyId] = true
            end
        end
    end
end

function Logic:ClearSeasonData()
    RaidSanctionsCharDB.seasonData = {}
    print("Season data has been cleared.")
end

function Logic:GetSeasonPlayersByCategory()
    local seasonData = self:GetSeasonData()
    local guildPlayers = {}
    local randomPlayers = {}
    
    for playerName, playerData in pairs(seasonData) do
        local isGuildMember = self:IsPlayerInGuild(playerName)
        
        local playerInfo = {
            name = playerName,
            class = playerData.class,
            totalAmount = playerData.totalAmount,
            totalPenalties = playerData.totalPenalties,
            lastSeen = playerData.lastSeen,
            penalties = playerData.penalties or {} -- Include penalties array for counter calculation
        }
        
        if isGuildMember then
            table.insert(guildPlayers, playerInfo)
        else
            table.insert(randomPlayers, playerInfo)
        end
    end
    
    -- Sort both categories by total amount (highest first)
    table.sort(guildPlayers, function(a, b) return a.totalAmount > b.totalAmount end)
    table.sort(randomPlayers, function(a, b) return a.totalAmount > b.totalAmount end)
    
    return guildPlayers, randomPlayers
end

function Logic:IsPlayerInGuild(playerName)
    -- Check if player is in the same guild as the current player
    if not IsInGuild() then
        return false -- Player is not in a guild
    end
    
    -- Get number of guild members
    local numGuildMembers = GetNumGuildMembers()
    
    -- Search through guild roster
    for i = 1, numGuildMembers do
        local name = GetGuildRosterInfo(i)
        if name then
            -- Remove realm name if present (handle cross-realm players)
            local guildMemberName = name:match("([^-]+)")
            if guildMemberName == playerName then
                return true
            end
        end
    end
    
    return false
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
        -- Update season data when group changes
        self:UpdateSeasonData()
        -- Update UI if visible
        if RaidSanctions.UI and RaidSanctions.UI.RefreshPlayerList then
            RaidSanctions.UI:RefreshPlayerList()
        end
        -- Refresh Season Stats window if open
        if RaidSanctions.UI and RaidSanctions.UI.RefreshSeasonPlayerList then
            RaidSanctions.UI:RefreshSeasonPlayerList()
        end
    else
        -- No longer in group - mark session as inactive
        local session = self:GetCurrentSession()
        if session then
            session.isActive = false
        end
    end
end

function Logic:CleanupSeasonDataRandomPlayers()
    -- Clean up season data by removing random players with 0 penalties
    -- Guild members are always kept regardless of penalty amount
    local seasonData = self:GetSeasonData()
    local removedCount = 0
    
    local playersToRemove = {}
    
    for playerName, playerData in pairs(seasonData) do
        -- Check if player is NOT a guild member and has no penalties
        local isGuildMember = self:IsPlayerInGuild(playerName)
        
        if not isGuildMember and (playerData.totalAmount or 0) == 0 then
            table.insert(playersToRemove, playerName)
        end
    end
    
    -- Remove players from season data
    for _, playerName in ipairs(playersToRemove) do
        seasonData[playerName] = nil
        removedCount = removedCount + 1
    end
    
    -- Save updated season data
    if removedCount > 0 then
        -- Season data is already modified in place, no need to save separately
        print("RaidSanctions: Cleaned up " .. removedCount .. " random players with 0 penalties from season data.")
        
        -- Refresh season stats window if it's open
        if RaidSanctions.UI and RaidSanctions.UI.seasonStatsFrame and RaidSanctions.UI.seasonStatsFrame:IsShown() then
            RaidSanctions.UI:RefreshSeasonPlayerList()
        end
    end
end

-- Export for other modules
RaidSanctions.Logic = Logic
