-- UI Management for RaidSanctions Addon
-- Handles all UI operations and interface interactions

local addonName, addonTable = ...

-- UI Namespace
RaidSanctions = RaidSanctions or {}
RaidSanctions.UI = {}

-- Local references
local UI = RaidSanctions.UI
local Logic = RaidSanctions.Logic
local format = string.format
local pairs, ipairs = pairs, ipairs

-- UI Constants
local FRAME_WIDTH = 900  -- Increased from 800 to 900
local FRAME_HEIGHT = 700  -- More height for bottom button bar
local ROW_HEIGHT = 30
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 25
local BOTTOM_PANEL_HEIGHT = 110  -- More height for two button rows

-- Local UI variables
local mainFrame = nil
local playerRows = {}
local headerButtons = {}
local selectedPlayer = nil

function UI:Initialize()
    if mainFrame then
        return -- Already initialized
    end
    
    self:CreateMainFrame()
    self:CreateHeader()
    self:CreateScrollFrame()
    self:CreateBottomPanel()
    self:SetupEventHandlers()
end

function UI:CreateMainFrame()
    -- Main frame with improved styling
    mainFrame = CreateFrame("Frame", "RaidSanctionsMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(100)
    
    -- Backdrop with modern design
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
    
    -- Make movable
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    -- Hidden by default
    mainFrame:Hide()
end

function UI:CreateHeader()
    -- Title
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Raid Sanctions")
    title:SetTextColor(1, 0.8, 0)
    
    -- Options button (top left corner)
    local optionsButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    optionsButton:SetSize(80, 25)
    optionsButton:SetText("Options")
    optionsButton:SetPoint("TOPLEFT", 10, -10)
    optionsButton:SetScript("OnClick", function()
        UI:ShowOptionsWindow()
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        mainFrame:Hide()
    end)
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(80, 25)
    resetButton:SetText("Reset")
    resetButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -10, -10)
    resetButton:SetScript("OnClick", function()
        UI:ShowResetConfirmation()
    end)
    
    -- Add Raid Button
    local addPlayerButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    addPlayerButton:SetSize(100, 25)
    addPlayerButton:SetText("Add Player")
    addPlayerButton:SetPoint("TOPRIGHT", resetButton, "TOPLEFT", -10, 0)
    addPlayerButton:SetScript("OnClick", function()
        UI:ShowAddPlayerDialog()
    end)
    
    -- Header row for column titles
    local headerFrame = CreateFrame("Frame", nil, mainFrame)
    headerFrame:SetSize(FRAME_WIDTH - 20, 25)
    headerFrame:SetPoint("TOPLEFT", 10, -50)
    
    -- Player name label
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", 5, 0)
    nameHeader:SetText("Player")
    nameHeader:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create penalty headers dynamically (now as counter)
    local xOffset = 150
    for reason, amount in pairs(Logic:GetPenalties()) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", xOffset, 0)
        header:SetText(reason) -- Nur Penalty-Name, Counter kommen in die Zeilen
        header:SetTextColor(0.8, 0.8, 0.8)
        header:SetWidth(BUTTON_WIDTH) -- Set width for centering
        header:SetJustifyH("CENTER") -- Centered alignment
        headerButtons[reason] = header
        xOffset = xOffset + (BUTTON_WIDTH + 15)
    end
    
    -- Total header
    local totalHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalHeader:SetPoint("RIGHT", -10, 0)
    totalHeader:SetText("Total")
    totalHeader:SetTextColor(0.8, 0.8, 0.8)
    totalHeader:SetWidth(120) -- Set width for centering
    totalHeader:SetJustifyH("CENTER") -- Centered alignment
end

function UI:CreateScrollFrame()
    -- Scroll container for player list (now with space for bottom panel)
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, BOTTOM_PANEL_HEIGHT + 10) -- Space for button panel
    
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(FRAME_WIDTH - 50, 1) -- Height is adjusted dynamically
    scrollFrame:SetScrollChild(contentFrame)
    
    mainFrame.scrollFrame = scrollFrame
    mainFrame.contentFrame = contentFrame
end

function UI:CreateBottomPanel()
    -- Bottom panel for penalty buttons
    local bottomPanel = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    bottomPanel:SetSize(FRAME_WIDTH - 20, BOTTOM_PANEL_HEIGHT)
    bottomPanel:SetPoint("BOTTOMLEFT", 10, 10)
    
    -- Panel background
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
    
    -- "Penalties:" Label
    local actionsLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionsLabel:SetPoint("TOPLEFT", 10, -8)
    actionsLabel:SetText("Penalties:")
    actionsLabel:SetTextColor(1, 0.8, 0)
    
    -- ERSTE REIHE: Penalty-Buttons
    local xOffset = 10
    local yOffset = -30
    for reason, amount in pairs(Logic:GetPenalties()) do
        local button = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        button:SetSize(160, BUTTON_HEIGHT) -- Increased from 140 to 160
        button:SetPoint("TOPLEFT", xOffset, yOffset)
        button:SetText(reason .. " (" .. Logic:FormatGold(amount) .. ")")
        
        -- Click handler for currently selected player
        button:SetScript("OnClick", function()
            UI:ApplyPenaltyToSelectedPlayer(reason, amount)
        end)
        
        -- Tooltip
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Apply penalty: " .. reason)
            GameTooltip:AddLine("Amount: " .. Logic:FormatGold(amount))
            GameTooltip:AddLine("Click to give this penalty to the selected player.", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        xOffset = xOffset + 170 -- Increased spacing from 150 to 170
        if xOffset > FRAME_WIDTH - 180 then -- Adjusted break point from 160 to 180
            xOffset = 10
            yOffset = yOffset - 30
        end
    end
    
    -- "Management:" label for second row
    local managementLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    managementLabel:SetPoint("TOPLEFT", 10, -60)
    managementLabel:SetText("Management:")
    managementLabel:SetTextColor(1, 0.8, 0)
    
    -- SECOND ROW: Management Buttons
    local managementYOffset = -80
    
    -- "Paid" Button
    local paidButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
    paidButton:SetSize(120, BUTTON_HEIGHT)
    paidButton:SetPoint("TOPLEFT", 10, managementYOffset)
    paidButton:SetText("Paid")
    paidButton:GetFontString():SetTextColor(0.2, 1, 0.2) -- Green
    
    paidButton:SetScript("OnClick", function()
        UI:ResetSelectedPlayerPenalties()
    end)
    
    paidButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Mark player as paid")
        GameTooltip:AddLine("Resets all penalties for the selected player.", 1, 1, 1)
        GameTooltip:AddLine("Use this when the player has settled their debts.", 0.8, 0.8, 0.8)
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
        GameTooltip:SetText("Send penalty via whisper")
        GameTooltip:AddLine("Sends the selected player their current penalty via whisper.", 1, 1, 1)
        GameTooltip:AddLine("Shows all penalties and the total amount.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    whisperButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- "Post Stats in Raid Chat" Button
    local postStatsButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
    postStatsButton:SetSize(160, BUTTON_HEIGHT)
    postStatsButton:SetPoint("TOPLEFT", 290, managementYOffset)
    postStatsButton:SetText("Post Stats in Raid Chat")
    postStatsButton:GetFontString():SetTextColor(1, 0.8, 0.2) -- Gold
    
    postStatsButton:SetScript("OnClick", function()
        UI:PostStatsToRaidChat()
    end)
    
    postStatsButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Post penalty statistics to raid chat")
        GameTooltip:AddLine("Posts a sorted list of all players with their penalty amounts.", 1, 1, 1)
        GameTooltip:AddLine("Only shows players with penalties > 0.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    postStatsButton:SetScript("OnLeave", function()
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
    
    -- Enable keyboard input when frame is shown
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
    
    -- Remove old rows
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
    
    -- Adjust content frame height
    mainFrame.contentFrame:SetHeight(math.max(contentHeight, mainFrame.scrollFrame:GetHeight()))
end

function UI:CreatePlayerRow(playerName, playerData, yOffset)
    local row = CreateFrame("Button", nil, mainFrame.contentFrame) -- Button for selection
    row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Background for better readability
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if math.floor(math.abs(yOffset) / ROW_HEIGHT) % 2 == 0 then
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.3)
    else
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.2)
    end
    
    -- Selection background
    local selectedBg = row:CreateTexture(nil, "HIGHLIGHT")
    selectedBg:SetAllPoints()
    selectedBg:SetColorTexture(0.3, 0.6, 1, 0.3)
    
    -- Click handler for player selection
    row:SetScript("OnClick", function()
        UI:SelectPlayer(playerName)
    end)
    
    -- Player name with class color
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
        
        -- Calculate counter value
        local count = 0
        if playerData.penalties then
            for _, penalty in ipairs(playerData.penalties) do
                if penalty.reason == reason then
                    count = count + 1
                end
            end
        end
        
        counter:SetText(tostring(count))
        
        -- Color based on count
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
    
    -- Total display
    local totalLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalLabel:SetPoint("RIGHT", -10, 0)
    totalLabel:SetText(Logic:FormatGold(playerData.total))
    totalLabel:SetWidth(120)
    totalLabel:SetJustifyH("RIGHT")
    
    -- Color based on penalty amount
    if playerData.total > 50000 then -- > 5g
        totalLabel:SetTextColor(1, 0.2, 0.2) -- Rot
    elseif playerData.total > 20000 then -- > 2g
        totalLabel:SetTextColor(1, 0.8, 0.2) -- Orange
    else
        totalLabel:SetTextColor(0.8, 0.8, 0.8) -- Grau
    end
    
    -- Save row for selection system
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
        print("Player '" .. playerName .. "' added to current session.")
        self:RefreshPlayerList()
    else
        print("Error: Player '" .. playerName .. "' could not be added or already exists.")
    end
end

function UI:SelectPlayer(playerName)
    selectedPlayer = playerName
    print("Player selected: " .. playerName)
    
    -- Visual update of selection
    for _, row in ipairs(playerRows) do
        if row.playerName == playerName then
            -- Highlight selected row
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.2, 0.5, 1, 0.4)
        end
    end
end

function UI:ApplyPenaltyToSelectedPlayer(reason, amount)
    if not selectedPlayer then
        print("No player selected! Click on a player in the list first.")
        return
    end
    
    if Logic:ApplyPenalty(selectedPlayer, reason, amount) then
        self:RefreshPlayerList()
    else
        print("Error applying penalty.")
    end
end

function UI:ResetSelectedPlayerPenalties()
    if not selectedPlayer then
        print("No player selected! Click on a player in the list first.")
        return
    end
    
    -- Show confirmation dialog
    StaticPopup_Show("RAIDSANCTIONS_PLAYER_PAID_CONFIRM", selectedPlayer)
end

function UI:WhisperPlayerBalance()
    if not selectedPlayer then
        print("No player selected! Click on a player in the list first.")
        return
    end
    
    local session = Logic:GetCurrentSession()
    if not session or not session.players[selectedPlayer] then
        print("No data found for player " .. selectedPlayer .. ".")
        return
    end
    
    local playerData = session.players[selectedPlayer]
    
    -- Create whisper message
    if playerData.total > 0 then
        local penaltyDetails = {}
        local penaltyCounts = {}
        
        -- Count penalties
        if playerData.penalties then
            for _, penalty in ipairs(playerData.penalties) do
                penaltyCounts[penalty.reason] = (penaltyCounts[penalty.reason] or 0) + 1
            end
        end
        
        -- Create details string
        for reason, count in pairs(penaltyCounts) do
            table.insert(penaltyDetails, count .. "x " .. reason)
        end
        
        local detailsText = table.concat(penaltyDetails, ", ")
        local totalText = Logic:FormatGold(playerData.total)
        
        -- Send whisper (simplified message without problematic characters)
        local message = "RaidSanctions Penalties " .. detailsText .. " Total " .. totalText
        SendChatMessage(message, "WHISPER", nil, selectedPlayer)
        print("Penalty details whispered to " .. selectedPlayer .. ": " .. totalText)
    else
        SendChatMessage("RaidSanctions You have no outstanding penalties", "WHISPER", nil, selectedPlayer)
        print("Confirmation sent to " .. selectedPlayer .. ": No penalties.")
    end
end

function UI:PostStatsToRaidChat()
    local session = Logic:GetCurrentSession()
    if not session or not session.players then
        print("No penalty data found.")
        return
    end
    
    -- Collect all players with penalties
    local playersWithPenalties = {}
    for playerName, playerData in pairs(session.players) do
        if playerData.total and playerData.total > 0 then
            table.insert(playersWithPenalties, {
                name = playerName,
                total = playerData.total
            })
        end
    end
    
    -- Check if any players have penalties
    if #playersWithPenalties == 0 then
        SendChatMessage("RaidSanctions: No outstanding penalties!", "RAID")
        print("Posted to raid: No outstanding penalties.")
        return
    end
    
    -- Sort players by penalty amount (highest first)
    table.sort(playersWithPenalties, function(a, b)
        return a.total > b.total
    end)
    
    -- Post header message
    SendChatMessage("RaidSanctions - Current Penalty Stats:", "RAID")
    
    -- Post each player's stats
    for i, player in ipairs(playersWithPenalties) do
        local message = i .. ". " .. player.name .. ": " .. Logic:FormatGold(player.total)
        SendChatMessage(message, "RAID")
    end
    
    print("Penalty statistics posted to raid chat (" .. #playersWithPenalties .. " players with penalties).")
end

function UI:Toggle()
    if not mainFrame then
        self:Initialize()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        -- Update data before showing
        Logic:UpdateRaidMembers()
        self:RefreshPlayerList() -- Update list before showing
        mainFrame:Show()
    end
end

function UI:Show()
    if not mainFrame then
        self:Initialize()
    end
    
    Logic:UpdateRaidMembers()
    self:RefreshPlayerList() -- Update list before showing
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
    -- Create options frame
    local optionsFrame = CreateFrame("Frame", "RaidSanctionsOptionsFrame", mainFrame, "BackdropTemplate")
    optionsFrame:SetSize(500, 400)
    optionsFrame:SetPoint("CENTER", mainFrame, "CENTER") -- Centered in main window
    optionsFrame:SetFrameStrata("HIGH")
    optionsFrame:SetFrameLevel(200) -- Above main window
    
    -- Backdrop for options frame
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
    
    -- Only enable mouse input (not movable)
    optionsFrame:EnableMouse(true)
    
    -- Title for options frame
    local optionsTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    optionsTitle:SetPoint("TOP", 0, -15)
    optionsTitle:SetText("RaidSanctions - Options")
    optionsTitle:SetTextColor(1, 0.8, 0)
    
    -- Close button for options frame
    local optionsCloseButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton")
    optionsCloseButton:SetPoint("TOPRIGHT", -5, -5)
    optionsCloseButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)
    
    -- Create tab system for options
    local tabs = {}
    local tabContents = {}
    local activeTab = 1
    
    -- Tab definitions
    local tabData = {
        {name = "Penalties", key = "penalties"},
        {name = "UI", key = "interface"},
        {name = "Behavior", key = "behavior"},
        {name = "Export", key = "export"}
    }
    
    -- Create tab buttons
    local tabY = -50
    for i, data in ipairs(tabData) do
        local tab = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
        tab:SetSize(100, 30)
        tab:SetPoint("TOPLEFT", 10 + (i-1) * 105, tabY)
        tab:SetText(data.name)
        
        -- Tab click handler
        tab:SetScript("OnClick", function()
            UI:SwitchToOptionsTab(i)
        end)
        
        tabs[i] = tab
    end
    
    -- Content area for tab contents
    local contentFrame = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", 10, -85)
    contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    contentFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    contentFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Create tab contents
    for i, data in ipairs(tabData) do
        local content = CreateFrame("Frame", nil, contentFrame)
        content:SetAllPoints()
        content:Hide() -- Hide all initially
        
        if data.key == "penalties" then
            -- Penalties tab content
            UI:CreatePenaltiesTabContent(content)
        else
            -- Title for each tab
            local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            title:SetPoint("TOP", 0, -15)
            title:SetText(data.name .. " Settings")
            title:SetTextColor(1, 0.8, 0)
            
            -- Placeholder for tab content
            local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            info:SetPoint("CENTER", 0, 0)
            info:SetText("Content for " .. data.name .. " will be implemented here...")
            info:SetTextColor(0.7, 0.7, 0.7)
        end
        
        tabContents[i] = content
    end
    
    -- Tab switching function
    function UI:SwitchToOptionsTab(tabIndex)
        -- Reset all tabs
        for i, tab in ipairs(tabs) do
            tab:GetFontString():SetTextColor(0.8, 0.8, 0.8)
            tabContents[i]:Hide()
        end
        
        -- Highlight active tab
        tabs[tabIndex]:GetFontString():SetTextColor(1, 1, 1)
        tabContents[tabIndex]:Show()
        activeTab = tabIndex
    end
    
    -- Activate first tab by default
    UI:SwitchToOptionsTab(1)
    
    -- Store references in frame
    optionsFrame.tabs = tabs
    optionsFrame.tabContents = tabContents
    optionsFrame.contentFrame = contentFrame
    
    -- ESC key handler for options frame
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
    
    -- Hidden by default
    optionsFrame:Hide()
    
    -- Store frame
    self.optionsFrame = optionsFrame
end

function UI:CreatePenaltiesTabContent(content)
    -- Title for penalties tab
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Penalty Settings")
    title:SetTextColor(1, 0.8, 0)
    
    -- Info text
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", title, "BOTTOM", 0, -15)
    info:SetText("Customize penalty amounts (enter values in gold)")
    info:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create penalty input fields
    local yOffset = -70
    local editBoxes = {}
    
    for reason, amount in pairs(Logic:GetPenalties()) do
        -- Label for penalty type
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 20, yOffset)
        label:SetText(reason .. ":")
        label:SetTextColor(1, 1, 1)
        label:SetWidth(120)
        label:SetJustifyH("LEFT")
        
        -- Input field for penalty amount
        local editBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        editBox:SetSize(80, 30)
        editBox:SetPoint("LEFT", label, "RIGHT", 20, 0)
        editBox:SetAutoFocus(false)
        editBox:SetMaxLetters(10)
        editBox:SetNumeric(true)
        -- Convert from copper to gold for display
        local goldValue = math.floor(amount / 10000)
        editBox:SetText(tostring(goldValue))
        
        -- Gold display label
        local goldLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        goldLabel:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
        goldLabel:SetTextColor(0.8, 0.8, 0.8)
        goldLabel:SetText("Gold")
        
        -- Update gold display when value changes (no longer needed for conversion)
        editBox:SetScript("OnTextChanged", function(self)
            -- Gold label stays static as "Gold"
        end)
        
        -- Store reference
        editBoxes[reason] = editBox
        
        yOffset = yOffset - 40
    end
    
    -- Buttons section
    local buttonY = yOffset - 20
    
    -- Save button
    local saveButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 30)
    saveButton:SetPoint("TOPLEFT", 20, buttonY)
    saveButton:SetText("Save")
    saveButton:GetFontString():SetTextColor(0.2, 1, 0.2)
    
    saveButton:SetScript("OnClick", function()
        UI:SavePenaltySettings(editBoxes)
    end)
    
    -- Reset to defaults button
    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 30)
    resetButton:SetPoint("LEFT", saveButton, "RIGHT", 10, 0)
    resetButton:SetText("Reset to 1 Gold")
    resetButton:GetFontString():SetTextColor(1, 0.8, 0.2)
    
    resetButton:SetScript("OnClick", function()
        UI:ResetPenaltiesToDefault(editBoxes)
    end)
    
    -- Help text
    local helpText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("TOPLEFT", 20, buttonY - 40)
    helpText:SetWidth(400)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Note: Changes take effect immediately and will update the UI.\nEnter values in whole gold amounts (e.g., 5 for 5 Gold).")
    helpText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Store references
    content.editBoxes = editBoxes
end

function UI:SavePenaltySettings(editBoxes)
    local newPenalties = {}
    
    -- Collect values from edit boxes and convert gold to copper
    for reason, editBox in pairs(editBoxes) do
        local goldValue = tonumber(editBox:GetText()) or 1 -- Default to 1g if invalid
        if goldValue < 0 then goldValue = 0 end -- No negative values
        if goldValue > 100000 then goldValue = 100000 end -- Max 100k gold (reasonable limit)
        
        -- Convert gold to copper (multiply by 10000)
        local copperValue = goldValue * 10000
        newPenalties[reason] = copperValue
    end
    
    -- Update penalties in Logic module
    if Logic.SetCustomPenalties then
        Logic:SetCustomPenalties(newPenalties)
        print("Penalty settings saved!")
        
        -- Refresh main UI elements that show penalty values
        if mainFrame and mainFrame:IsShown() then
            -- Recreate bottom panel with new penalty values
            if mainFrame.bottomPanel then
                mainFrame.bottomPanel:Hide()
                mainFrame.bottomPanel:SetParent(nil)
                mainFrame.bottomPanel = nil
            end
            self:CreateBottomPanel()
            
            -- Refresh player list to update penalty counters
            self:RefreshPlayerList()
        end
        
        -- Close options window
        if self.optionsFrame then
            self.optionsFrame:Hide()
        end
    else
        print("Error: Cannot save penalty settings. Logic module update required.")
    end
end

function UI:ResetPenaltiesToDefault(editBoxes)
    -- Set all edit boxes to 1 (1g)
    for reason, editBox in pairs(editBoxes) do
        editBox:SetText("1")
    end
    print("All penalties reset to 1 Gold. Click 'Save' to apply changes.")
end

-- Static popup for reset confirmation
StaticPopupDialogs["RAIDSANCTIONS_RESET_CONFIRM"] = {
    text = "Reset all sanction data for the current session?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        Logic:ResetSessionData()
        UI:RefreshPlayerList()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Static popup for adding player
StaticPopupDialogs["RAIDSANCTIONS_ADD_PLAYER"] = {
    text = "Enter player name:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local playerName = self.editBox:GetText()
        if playerName and playerName:trim() ~= "" then
            -- Clean player name (normalize capitalization)
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

-- Static popup for marking player as paid
StaticPopupDialogs["RAIDSANCTIONS_PLAYER_PAID_CONFIRM"] = {
    text = "Mark player '%s' as paid?\n\nAll penalties will be reset.",
    button1 = "Paid",
    button2 = "Cancel",
    OnAccept = function()
        if Logic:ResetPlayerPenalties(selectedPlayer) then
            UI:RefreshPlayerList()
        else
            print("Error resetting player penalties.")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Export
RaidSanctions.UI = UI