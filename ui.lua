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
local FRAME_WIDTH = 700
local FRAME_HEIGHT = 600
local ROW_HEIGHT = 30
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 20

-- Lokale UI-Variablen
local mainFrame = nil
local playerRows = {}
local headerButtons = {}

function UI:Initialize()
    if mainFrame then
        return -- Bereits initialisiert
    end
    
    self:CreateMainFrame()
    self:CreateHeader()
    self:CreateScrollFrame()
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
    
    -- Penalty-Headers dynamisch erstellen
    local xOffset = 150
    for reason, amount in pairs(Logic:GetPenalties()) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", xOffset, 0)
        header:SetText(reason)
        header:SetTextColor(0.8, 0.8, 0.8)
        headerButtons[reason] = header
        xOffset = xOffset + (BUTTON_WIDTH + 15)
    end
    
    -- Gesamt-Header
    local totalHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalHeader:SetPoint("RIGHT", -20, 0)
    totalHeader:SetText("Gesamt")
    totalHeader:SetTextColor(0.8, 0.8, 0.8)
end

function UI:CreateScrollFrame()
    -- Scroll-Container für Spielerliste
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
    
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(FRAME_WIDTH - 50, 1) -- Höhe wird dynamisch angepasst
    scrollFrame:SetScrollChild(contentFrame)
    
    mainFrame.scrollFrame = scrollFrame
    mainFrame.contentFrame = contentFrame
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
    if not mainFrame or not mainFrame:IsShown() then
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
    local row = CreateFrame("Frame", nil, mainFrame.contentFrame)
    row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Hintergrund für bessere Lesbarkeit
    if math.floor(math.abs(yOffset) / ROW_HEIGHT) % 2 == 0 then
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)
    end
    
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
    
    -- Penalty-Buttons
    local xOffset = 150
    for reason, amount in pairs(Logic:GetPenalties()) do
        local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
        button:SetPoint("LEFT", xOffset, 0)
        button:SetText(Logic:FormatGold(amount))
        
        -- Click-Handler
        button:SetScript("OnClick", function()
            Logic:ApplyPenalty(playerName, reason, amount)
            UI:RefreshPlayerList() -- UI aktualisieren
        end)
        
        -- Tooltip
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(reason .. ": " .. Logic:FormatGold(amount))
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        xOffset = xOffset + (BUTTON_WIDTH + 15)
    end
    
    -- Gesamt-Anzeige
    local totalLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalLabel:SetPoint("RIGHT", -20, 0)
    totalLabel:SetText(Logic:FormatGold(playerData.total))
    
    -- Farbe je nach Höhe der Strafe
    if playerData.total > 50000 then -- > 5g
        totalLabel:SetTextColor(1, 0.2, 0.2) -- Rot
    elseif playerData.total > 20000 then -- > 2g
        totalLabel:SetTextColor(1, 0.8, 0.2) -- Orange
    else
        totalLabel:SetTextColor(0.8, 0.8, 0.8) -- Grau
    end
    
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

function UI:Toggle()
    if not mainFrame then
        self:Initialize()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        -- Daten aktualisieren vor dem Anzeigen
        Logic:UpdateRaidMembers()
        self:RefreshPlayerList()
        mainFrame:Show()
    end
end

function UI:Show()
    if not mainFrame then
        self:Initialize()
    end
    
    Logic:UpdateRaidMembers()
    self:RefreshPlayerList()
    mainFrame:Show()
end

function UI:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
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

-- Export
RaidSanctions.UI = UI
