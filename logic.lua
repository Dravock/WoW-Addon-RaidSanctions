-- Core Logic für RaidSanctions Addon
-- Behandelt Geschäftslogik, Events und Datenpersistenz

local addonName, addonTable = ...

-- Namespace erstellen
RaidSanctions = RaidSanctions or {}
RaidSanctions.Logic = {}

-- Lokale Referenzen für bessere Performance
local Logic = RaidSanctions.Logic
local format = string.format
local pairs, ipairs = pairs, ipairs
local wipe = table.wipe or wipe

-- Konstanten
local ADDON_VERSION = "1.1"
local DEBUG_MODE = false

-- Standard-Sanktionen (können konfiguriert werden)
local DEFAULT_PENALTIES = {
    ["Zu spät"] = 10000,
    ["AFK"] = 5000,
    ["Falsches Gear"] = 7500,
    ["Falsche Taktik"] = 3000,
    ["Störung"] = 2500
}

-- Lokalisierung
local L = {
    ["LATE"] = "Zu spät",
    ["AFK"] = "AFK", 
    ["WRONG_GEAR"] = "Falsches Gear",
    ["WRONG_TACTIC"] = "Falsche Taktik",
    ["DISRUPTION"] = "Störung",
    ["TOTAL"] = "Gesamt",
    ["ADDON_LOADED"] = "RaidSanctions v%s geladen.",
    ["PENALTY_APPLIED"] = "%s bestraft mit '%s': +%s | Gesamt: %s",
    ["DATA_RESET"] = "Alle Sanktionsdaten wurden zurückgesetzt."
}

-- Datenbank-Funktionen
function Logic:InitializeDatabase()
    -- Globale Datenbank
    RaidSanctionsDB = RaidSanctionsDB or {
        version = ADDON_VERSION,
        penalties = DEFAULT_PENALTIES,
        settings = {
            showInCombat = false,
            autoHide = true,
            soundEnabled = true
        }
    }
    
    -- Charakter-spezifische Datenbank
    RaidSanctionsCharDB = RaidSanctionsCharDB or {
        sessions = {},
        currentSession = nil
    }
    
    -- Version-Check und Migration falls nötig
    if RaidSanctionsDB.version ~= ADDON_VERSION then
        self:MigrateDatabase()
    end
end

function Logic:MigrateDatabase()
    -- Hier können Datenmigrations-Logic für zukünftige Versionen hinzugefügt werden
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
    -- Unterstützung für Raid UND Party/Gruppe
    if not (IsInRaid() or IsInGroup()) then
        return
    end
    
    local session = self:GetCurrentSession()
    if not session then
        session = self:CreateNewSession()
    end
    
    -- Aktuelle Gruppen-Mitglieder erfassen (Raid oder Party)
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local name, rank, subgroup, level, class
        
        if IsInRaid() then
            -- Raid-Modus
            name, rank, subgroup, level, class = GetRaidRosterInfo(i)
        else
            -- Party-Modus
            if i == 1 then
                -- Eigener Spieler
                name = UnitName("player")
                class = select(2, UnitClass("player"))
                level = UnitLevel("player")
                rank = 0
                subgroup = 1
            else
                -- Party-Mitglieder
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
    
    -- Penalty-Eintrag erstellen
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
    
    -- Sound abspielen falls aktiviert
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
    
    -- Spielerdaten zurücksetzen
    session.players[playerName].penalties = {}
    session.players[playerName].total = 0
    
    print("Strafen für " .. playerName .. " wurden zurückgesetzt - Spieler als bezahlt markiert.")
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
    
    -- Prüfen ob Spieler bereits existiert
    if session.players[playerName] then
        return false -- Spieler existiert bereits
    end
    
    -- Spieler hinzufügen mit Standard-Daten
    session.players[playerName] = {
        class = "UNKNOWN", -- Klasse unbekannt da manuell hinzugefügt
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
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100
    
    local result = ""
    
    if gold > 0 then
        result = result .. gold .. "g"
    end
    
    if silver > 0 then
        if result ~= "" then
            result = result .. " "
        end
        result = result .. silver .. "s"
    end
    
    if copper > 0 then
        if result ~= "" then
            result = result .. " "
        end
        result = result .. copper .. "c"
    end
    
    -- Falls alles 0 ist
    if result == "" then
        result = "0c"
    end
    
    return result
end

function Logic:GetPenalties()
    return RaidSanctionsDB.penalties
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

-- Event-Handler
function Logic:OnAddonLoaded()
    self:InitializeDatabase()
    print(format(L["ADDON_LOADED"], ADDON_VERSION))
end

function Logic:OnPlayerEnteringWorld()
    -- Prüfen ob in Raid oder Gruppe und Session aktualisieren
    if IsInRaid() or IsInGroup() then
        self:UpdateRaidMembers()
    end
end

function Logic:OnGroupRosterUpdate()
    if IsInRaid() or IsInGroup() then
        self:UpdateRaidMembers()
        -- UI aktualisieren falls sichtbar
        if RaidSanctions.UI and RaidSanctions.UI.RefreshPlayerList then
            RaidSanctions.UI:RefreshPlayerList()
        end
    else
        -- Nicht mehr in Gruppe - Session als inaktiv markieren
        local session = self:GetCurrentSession()
        if session then
            session.isActive = false
        end
    end
end

-- Export für andere Module
RaidSanctions.Logic = Logic
