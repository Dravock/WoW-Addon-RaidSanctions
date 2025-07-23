-- UI-Management für RaidSanctions Addon
-- Behandelt alle UI-Operationen und Interface-Interaktionen

local addonName, addonTable = ...

-- UI-Namespace
RaidSanctions = RaidSanctions or {}
RaidSanctions.UI = {}

-- Lokale Referenzen
local UI = RaidSanctions.UI
local Logic = RaidSanctions.Logic
local format = string.format
local pairs, ipairs = pairs, ipairs

-- UI-Konstanten
local FRAME_WIDTH = 800
local FRAME_HEIGHT = 700  -- Mehr Höhe für Button-Leiste unten
local ROW_HEIGHT = 30
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 25
local BOTTOM_PANEL_HEIGHT = 110  -- Mehr Höhe für zwei Button-Reihen

-- Lokale UI-Variablen
local mainFrame = nil
local playerRows = {}
local headerButtons = {}
local selectedPlayer = nil

function UI:Initialize()
    if mainFrame then
        return -- Bereits initialisiert
    end
    
    self:CreateMainFrame()
    self:CreateHeader()
    self:CreateScrollFrame()
    self:CreateBottomPanel()
    self:SetupEventHandlers()
end

function UI:CreateMainFrame()
    -- Hauptframe mit verbessertem Styling
    mainFrame = CreateFrame("Frame", "RaidSanctionsMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(100)
    
    -- Backdrop mit modernem Design
    mainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    mainFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    mainFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Bewegbar machen
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Standardmäßig versteckt
    mainFrame:Hide()
end

function UI:CreateHeader()
    -- Titel
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Raid Sanctions")
    title:SetTextColor(1, 0.8, 0)
    
    -- Optionen-Button (obere linke Ecke)
    local optionsButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    optionsButton:SetSize(80, 25)
    optionsButton:SetText("Optionen")
    optionsButton:SetPoint("TOPLEFT", 10, -10)
    optionsButton:SetScript("OnClick", function()
        UI:ShowOptionsWindow()
    end)
    
    -- Schließen-Button
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        mainFrame:Hide()
    end)
    
    -- Reset-Button
    local resetButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(80, 25)
    resetButton:SetText("Reset")
    resetButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -10, -10)
    resetButton:SetScript("OnClick", function()
        UI:ShowResetConfirmation()
    end)
    
    -- Raid Hinzufügen Button
    local addPlayerButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    addPlayerButton:SetSize(100, 25)
    addPlayerButton:SetText("Add Player")
    addPlayerButton:SetPoint("TOPRIGHT", resetButton, "TOPLEFT", -10, 0)
    addPlayerButton:SetScript("OnClick", function()
        UI:ShowAddPlayerDialog()
    end)
    
    -- Header-Zeile für Spaltenüberschriften
    local headerFrame = CreateFrame("Frame", nil, mainFrame)
    headerFrame:SetSize(FRAME_WIDTH - 20, 25)
    headerFrame:SetPoint("TOPLEFT", 10, -50)
    
    -- Spielername-Label
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", 5, 0)
    nameHeader:SetText("Spieler")
    nameHeader:SetTextColor(0.8, 0.8, 0.8)
    
    -- Penalty-Headers dynamisch erstellen (jetzt als Counter)
    local xOffset = 150
    for reason, amount in pairs(Logic:GetPenalties()) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", xOffset, 0)
        header:SetText(reason) -- Nur Penalty-Name, Counter kommen in die Zeilen
        header:SetTextColor(0.8, 0.8, 0.8)
        header:SetWidth(BUTTON_WIDTH) -- Breite setzen für Zentrierung
        header:SetJustifyH("CENTER") -- Zentrierte Ausrichtung
        headerButtons[reason] = header
        xOffset = xOffset + (BUTTON_WIDTH + 15)
    end
    
    -- Gesamt-Header
    local totalHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalHeader:SetPoint("RIGHT", -10, 0)
    totalHeader:SetText("Gesamt")
    totalHeader:SetTextColor(0.8, 0.8, 0.8)
    totalHeader:SetWidth(120) -- Breite setzen für Zentrierung
    totalHeader:SetJustifyH("CENTER") -- Zentrierte Ausrichtung
end

function UI:CreateScrollFrame()
    -- Scroll-Container für Spielerliste (jetzt mit Platz für Bottom-Panel)
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, BOTTOM_PANEL_HEIGHT + 10) -- Platz für Button-Panel
    
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(FRAME_WIDTH - 50, 1) -- Höhe wird dynamisch angepasst
    scrollFrame:SetScrollChild(contentFrame)
    
    mainFrame.scrollFrame = scrollFrame
    mainFrame.contentFrame = contentFrame
end

function UI:CreateBottomPanel()
    -- Bottom-Panel für Penalty-Buttons
    local bottomPanel = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    bottomPanel:SetSize(FRAME_WIDTH - 20, BOTTOM_PANEL_HEIGHT)
    bottomPanel:SetPoint("BOTTOMLEFT", 10, 10)
    
    -- Panel-Hintergrund
    bottomPanel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    bottomPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    bottomPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- "Aktionen:" Label
    local actionsLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionsLabel:SetPoint("TOPLEFT", 10, -8)
    actionsLabel:SetText("Strafen:")
    actionsLabel:SetTextColor(1, 0.8, 0)
    
    -- ERSTE REIHE: Penalty-Buttons
    local xOffset = 10
    local yOffset = -30
    for reason, amount in pairs(Logic:GetPenalties()) do
        local button = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        button:SetSize(140, BUTTON_HEIGHT)
        button:SetPoint("TOPLEFT", xOffset, yOffset)
        button:SetText(reason .. " (" .. Logic:FormatGold(amount) .. ")")
        
        -- Click-Handler für aktuell ausgewählten Spieler
        button:SetScript("OnClick", function()
            UI:ApplyPenaltyToSelectedPlayer(reason, amount)
        end)
        
        -- Tooltip
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Strafe anwenden: " .. reason)
            GameTooltip:AddLine("Betrag: " .. Logic:FormatGold(amount))
            GameTooltip:AddLine("Klicke um diese Strafe dem ausgewählten Spieler zu geben.", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        xOffset = xOffset + 150
        if xOffset > FRAME_WIDTH - 160 then -- Nächste Zeile
            xOffset = 10
            yOffset = yOffset - 30
        end
    end
    
    -- "Verwaltung:" Label für zweite Reihe
    local managementLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    managementLabel:SetPoint("TOPLEFT", 10, -60)
    managementLabel:SetText("Verwaltung:")
    managementLabel:SetTextColor(1, 0.8, 0)
    
    -- ZWEITE REIHE: Management-Buttons
    local managementYOffset = -80
    
    -- "Bezahlt" Button
    local paidButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
    paidButton:SetSize(120, BUTTON_HEIGHT)
    paidButton:SetPoint("TOPLEFT", 10, managementYOffset)
    paidButton:SetText("Bezahlt")
    paidButton:GetFontString():SetTextColor(0.2, 1, 0.2) -- Grün
    
    paidButton:SetScript("OnClick", function()
        UI:ResetSelectedPlayerPenalties()
    end)
    
    paidButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Spieler als bezahlt markieren")
        GameTooltip:AddLine("Setzt alle Strafen des ausgewählten Spielers zurück.", 1, 1, 1)
        GameTooltip:AddLine("Verwende dies, wenn der Spieler seine Schulden beglichen hat.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    paidButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- "Whisper Balance" Button
    local whisperButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
    whisperButton:SetSize(140, BUTTON_HEIGHT)
    whisperButton:SetPoint("TOPLEFT", 140, managementYOffset)
    whisperButton:SetText("Whisper Balance")
    whisperButton:GetFontString():SetTextColor(0.8, 0.8, 1) -- Hellblau
    
    whisperButton:SetScript("OnClick", function()
        UI:WhisperPlayerBalance()
    end)
    
    whisperButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Strafe per Whisper senden")
        GameTooltip:AddLine("Sendet dem ausgewählten Spieler seine aktuelle Strafe per Whisper.", 1, 1, 1)
        GameTooltip:AddLine("Zeigt alle Strafen und die Gesamtsumme an.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    whisperButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    mainFrame.bottomPanel = bottomPanel
end

function UI:SetupEventHandlers()
    -- Escape-Key Handler direkt im Frame
    mainFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    
    -- Keyboard-Eingabe aktivieren wenn Frame gezeigt wird
    mainFrame:SetScript("OnShow", function(self)
        self:EnableKeyboard(true)
    end)
    
    mainFrame:SetScript("OnHide", function(self)
        self:EnableKeyboard(false)
    end)
end

function UI:RefreshPlayerList()
    if not mainFrame then
        return
    end
    
    -- Alte Rows entfernen
    for _, row in ipairs(playerRows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(playerRows)
    
    local session = Logic:GetCurrentSession()
    if not session then
        return
    end
    
    local yOffset = 0
    local contentHeight = 0
    
    for playerName, playerData in pairs(session.players) do
        local row = self:CreatePlayerRow(playerName, playerData, yOffset)
        table.insert(playerRows, row)
        yOffset = yOffset - ROW_HEIGHT
        contentHeight = contentHeight + ROW_HEIGHT
    end
    
    -- Content-Frame Höhe anpassen
    mainFrame.contentFrame:SetHeight(math.max(contentHeight, mainFrame.scrollFrame:GetHeight()))
end

function UI:CreatePlayerRow(playerName, playerData, yOffset)
    local row = CreateFrame("Button", nil, mainFrame.contentFrame) -- Button für Auswahl
    row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Hintergrund für bessere Lesbarkeit
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if math.floor(math.abs(yOffset) / ROW_HEIGHT) % 2 == 0 then
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)
    else
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.2)
    end
    
    -- Auswahlhintergrund
    local selectedBg = row:CreateTexture(nil, "HIGHLIGHT")
    selectedBg:SetAllPoints()
    selectedBg:SetColorTexture(0.3, 0.6, 1, 0.3)
    
    -- Click-Handler für Spielerauswahl
    row:SetScript("OnClick", function()
        UI:SelectPlayer(playerName)
    end)
    
    -- Spielername mit Klassenfarbe
    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", 5, 0)
    nameLabel:SetText(playerName)
    
    -- Klassenfarbe anwenden
    if playerData.class then
        local classColor = RAID_CLASS_COLORS[playerData.class]
        if classColor then
            nameLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end
    
    -- Penalty-Counter (statt Buttons)
    local xOffset = 150
    for reason, amount in pairs(Logic:GetPenalties()) do
        local counter = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        counter:SetPoint("LEFT", xOffset, 0)
        counter:SetWidth(BUTTON_WIDTH)
        counter:SetJustifyH("CENTER")
        
        -- Counter-Wert berechnen
        local count = 0
        if playerData.penalties then
            for _, penalty in ipairs(playerData.penalties) do
                if penalty.reason == reason then
                    count = count + 1
                end
            end
        end
        
        counter:SetText(tostring(count))
        
        -- Farbe je nach Anzahl
        if count > 3 then
            counter:SetTextColor(1, 0.2, 0.2) -- Rot
        elseif count > 1 then
            counter:SetTextColor(1, 0.8, 0.2) -- Orange
        elseif count > 0 then
            counter:SetTextColor(1, 1, 0.2) -- Gelb
        else
            counter:SetTextColor(0.8, 0.8, 0.8) -- Grau
        end
        
        xOffset = xOffset + (BUTTON_WIDTH + 15)
    end
    
    -- Gesamt-Anzeige
    local totalLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalLabel:SetPoint("RIGHT", -10, 0)
    totalLabel:SetText(Logic:FormatGold(playerData.total))
    totalLabel:SetWidth(120)
    totalLabel:SetJustifyH("RIGHT")
    
    -- Farbe je nach Höhe der Strafe
    if playerData.total > 50000 then -- > 5g
        totalLabel:SetTextColor(1, 0.2, 0.2) -- Rot
    elseif playerData.total > 20000 then -- > 2g
        totalLabel:SetTextColor(1, 0.8, 0.2) -- Orange
    else
        totalLabel:SetTextColor(0.8, 0.8, 0.8) -- Grau
    end
    
    -- Row speichern für Auswahl-System
    row.playerName = playerName
    
    return row
end

function UI:ShowResetConfirmation()
    StaticPopup_Show("RAIDSANCTIONS_RESET_CONFIRM")
end

function UI:ShowAddPlayerDialog()
    StaticPopup_Show("RAIDSANCTIONS_ADD_PLAYER")
end

function UI:AddPlayerManually(playerName)
    if Logic:AddPlayerManually(playerName) then
        print("Spieler '" .. playerName .. "' zur aktuellen Session hinzugefügt.")
        self:RefreshPlayerList()
    else
        print("Fehler: Spieler '" .. playerName .. "' konnte nicht hinzugefügt werden oder existiert bereits.")
    end
end

function UI:SelectPlayer(playerName)
    selectedPlayer = playerName
    print("Spieler ausgewählt: " .. playerName)
    
    -- Visuelle Aktualisierung der Auswahl
    for _, row in ipairs(playerRows) do
        if row.playerName == playerName then
            -- Ausgewählte Zeile hervorheben
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.2, 0.5, 1, 0.4)
        end
    end
end

function UI:ApplyPenaltyToSelectedPlayer(reason, amount)
    if not selectedPlayer then
        print("Kein Spieler ausgewählt! Klicke zuerst auf einen Spieler in der Liste.")
        return
    end
    
    if Logic:ApplyPenalty(selectedPlayer, reason, amount) then
        self:RefreshPlayerList()
    else
        print("Fehler beim Anwenden der Strafe.")
    end
end

function UI:ResetSelectedPlayerPenalties()
    if not selectedPlayer then
        print("Kein Spieler ausgewählt! Klicke zuerst auf einen Spieler in der Liste.")
        return
    end
    
    -- Bestätigungsdialog anzeigen
    StaticPopup_Show("RAIDSANCTIONS_PLAYER_PAID_CONFIRM", selectedPlayer)
end

function UI:WhisperPlayerBalance()
    if not selectedPlayer then
        print("Kein Spieler ausgewählt! Klicke zuerst auf einen Spieler in der Liste.")
        return
    end
    
    local session = Logic:GetCurrentSession()
    if not session or not session.players[selectedPlayer] then
        print("Keine Daten für Spieler " .. selectedPlayer .. " gefunden.")
        return
    end
    
    local playerData = session.players[selectedPlayer]
    
    -- Whisper-Nachricht erstellen
    if playerData.total > 0 then
        local penaltyDetails = {}
        local penaltyCounts = {}
        
        -- Strafen zählen
        if playerData.penalties then
            for _, penalty in ipairs(playerData.penalties) do
                penaltyCounts[penalty.reason] = (penaltyCounts[penalty.reason] or 0) + 1
            end
        end
        
        -- Details-String erstellen
        for reason, count in pairs(penaltyCounts) do
            table.insert(penaltyDetails, count .. "x " .. reason)
        end
        
        local detailsText = table.concat(penaltyDetails, ", ")
        local totalText = Logic:FormatGold(playerData.total)
        
        -- Whisper senden (vereinfachte Nachricht ohne problematische Zeichen)
        local message = "RaidSanctions Strafen " .. detailsText .. " Gesamt " .. totalText
        SendChatMessage(message, "WHISPER", nil, selectedPlayer)
        print("Strafe-Details an " .. selectedPlayer .. " gewhispert: " .. totalText)
    else
        SendChatMessage("RaidSanctions Du hast keine ausstehenden Strafen", "WHISPER", nil, selectedPlayer)
        print("Bestätigung an " .. selectedPlayer .. " gesendet: Keine Strafen.")
    end
end

function UI:Toggle()
    if not mainFrame then
        self:Initialize()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        -- Daten aktualisieren vor dem Anzeigen
        Logic:UpdateRaidMembers()
        self:RefreshPlayerList() -- Liste aktualisieren vor dem Anzeigen
        mainFrame:Show()
    end
end

function UI:Show()
    if not mainFrame then
        self:Initialize()
    end
    
    Logic:UpdateRaidMembers()
    self:RefreshPlayerList() -- Liste aktualisieren vor dem Anzeigen
    mainFrame:Show()
end

function UI:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

function UI:ShowOptionsWindow()
    if not self.optionsFrame then
        self:CreateOptionsWindow()
    end
    
    self.optionsFrame:Show()
end

function UI:CreateOptionsWindow()
    -- Options-Frame erstellen
    local optionsFrame = CreateFrame("Frame", "RaidSanctionsOptionsFrame", UIParent, "BackdropTemplate")
    optionsFrame:SetSize(500, 400)
    optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 50, 50) -- Leicht versetzt zum Hauptfenster
    optionsFrame:SetFrameStrata("HIGH")
    optionsFrame:SetFrameLevel(200) -- Über dem Hauptfenster
    
    -- Backdrop für Options-Frame
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    optionsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    optionsFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Bewegbar machen
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    optionsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Titel für Options-Frame
    local optionsTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    optionsTitle:SetPoint("TOP", 0, -15)
    optionsTitle:SetText("RaidSanctions - Optionen")
    optionsTitle:SetTextColor(1, 0.8, 0)
    
    -- Schließen-Button für Options-Frame
    local optionsCloseButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    optionsCloseButton:SetPoint("TOPRIGHT", -5, -5)
    optionsCloseButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)
    
    -- Placeholder-Text für zukünftige Optionen
    local placeholderText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholderText:SetPoint("CENTER", 0, 50)
    placeholderText:SetText("Optionen werden hier implementiert...")
    placeholderText:SetTextColor(0.8, 0.8, 0.8)
    
    local infoText = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("CENTER", 0, 20)
    infoText:SetText("Strafen-Konfiguration, UI-Einstellungen, etc.")
    infoText:SetTextColor(0.6, 0.6, 0.6)
    
    -- ESC-Key Handler für Options-Frame
    optionsFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    
    optionsFrame:SetScript("OnShow", function(self)
        self:EnableKeyboard(true)
    end)
    
    optionsFrame:SetScript("OnHide", function(self)
        self:EnableKeyboard(false)
    end)
    
    -- Standardmäßig versteckt
    optionsFrame:Hide()
    
    -- Frame speichern
    self.optionsFrame = optionsFrame
end

-- Static Popup für Reset-Bestätigung
StaticPopupDialogs["RAIDSANCTIONS_RESET_CONFIRM"] = {
    text = "Alle Sanktionsdaten der aktuellen Session zurücksetzen?",
    button1 = "Ja",
    button2 = "Nein",
    OnAccept = function()
        Logic:ResetSessionData()
        UI:RefreshPlayerList()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static Popup für Spieler hinzufügen
StaticPopupDialogs["RAIDSANCTIONS_ADD_PLAYER"] = {
    text = "Spielername eingeben:",
    button1 = "Hinzufügen",
    button2 = "Abbrechen",
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local playerName = self.editBox:GetText()
        if playerName and playerName:trim() ~= "" then
            -- Spielername bereinigen (Groß-/Kleinschreibung normalisieren)
            playerName = playerName:gsub("^%l", string.upper)
            UI:AddPlayerManually(playerName)
        end
    end,
    OnShow = function(self)
        self.editBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local playerName = self:GetText()
        if playerName and playerName:trim() ~= "" then
            playerName = playerName:gsub("^%l", string.upper)
            UI:AddPlayerManually(playerName)
            parent:Hide()
        end
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static Popup für Spieler als bezahlt markieren
StaticPopupDialogs["RAIDSANCTIONS_PLAYER_PAID_CONFIRM"] = {
    text = "Spieler '%s' als bezahlt markieren?\n\nAlle Strafen werden zurückgesetzt.",
    button1 = "Bezahlt",
    button2 = "Abbrechen",
    OnAccept = function()
        if Logic:ResetPlayerPenalties(selectedPlayer) then
            UI:RefreshPlayerList()
        else
            print("Fehler beim Zurücksetzen der Spielerstrafen.")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Export
RaidSanctions.UI = UI
