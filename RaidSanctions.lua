-- Hauptdatei für RaidSanctions Addon
-- Event-Management und Addon-Initialisierung

local addonName, addonTable = ...

-- Event-Frame erstellen
local eventFrame = CreateFrame("Frame", "RaidSanctionsEventFrame")
local isInitialized = false

-- Event-Handler
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
    -- Logic-Modul initialisieren
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnAddonLoaded()
        isInitialized = true
    end
end

function OnPlayerEnteringWorld()
    if not isInitialized then
        return
    end
    
    -- Logic-Event weiterleiten
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnPlayerEnteringWorld()
    end
end

function OnGroupRosterUpdate()
    if not isInitialized then
        return
    end
    
    -- Logic-Event weiterleiten
    if RaidSanctions.Logic then
        RaidSanctions.Logic:OnGroupRosterUpdate()
    end
end

-- Events registrieren
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
        -- UI anzeigen/verstecken
        if RaidSanctions.UI then
            RaidSanctions.UI:Toggle()
        end
    elseif command == "reset" then
        -- Daten zurücksetzen
        if RaidSanctions.Logic then
            RaidSanctions.Logic:ResetSessionData()
        end
    elseif command == "help" then
        -- Hilfe anzeigen
        print("RaidSanctions Befehle:")
        print("/rs oder /rs show - UI öffnen/schließen")
        print("/rs reset - Aktuelle Session-Daten zurücksetzen")
        print("/rs debug - Zeige erkannte Spieler")
        print("/rs help - Diese Hilfe anzeigen")
    elseif command == "debug" then
        -- Debug-Informationen anzeigen
        if RaidSanctions.Logic then
            local session = RaidSanctions.Logic:GetCurrentSession()
            if session then
                print("Aktuelle Session: " .. session.id)
                print("Erkannte Spieler:")
                for name, data in pairs(session.players) do
                    print("  - " .. name .. " (" .. (data.class or "UNKNOWN") .. ", Level " .. (data.level or "?") .. ")")
                end
            else
                print("Keine aktive Session gefunden.")
            end
            
            if IsInRaid() then
                print("Status: Im Raid (" .. GetNumGroupMembers() .. " Mitglieder)")
            elseif IsInGroup() then
                print("Status: In Gruppe (" .. GetNumGroupMembers() .. " Mitglieder)")
            else
                print("Status: Solo")
            end
        end
    else
        print("Unbekannter Befehl. Verwende '/rs help' für Hilfe.")
    end
end

-- Kompatibilitäts-Funktionen für alte API (falls andere Addons diese verwenden)
function RaidSanctions_OnLoad(self)
    -- Deprecated - wird für Rückwärtskompatibilität beibehalten
    print("Warnung: RaidSanctions_OnLoad ist veraltet. Das Addon wurde bereits initialisiert.")
end

function RaidSanctions_OnEvent(self, event, ...)
    -- Deprecated - wird für Rückwärtskompatibilität beibehalten
    OnEvent(self, event, ...)
end

-- Global verfügbare Funktionen für andere Addons
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

