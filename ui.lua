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
local FRAME_WIDTH = 1000  -- Increased from 900 to 1000 to accommodate wider button layout
local FRAME_HEIGHT = 700  -- More height for bottom button bar
local ROW_HEIGHT = 30
local BUTTON_WIDTH = 80
local BUTTON_HEIGHT = 25
local BOTTOM_PANEL_HEIGHT = 160  -- Increased from 140 to 160 for more space for management buttons

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
    
    -- Season Stats button (next to Options)
    local seasonStatsButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    seasonStatsButton:SetSize(100, 25)
    seasonStatsButton:SetText("Season Stats")
    seasonStatsButton:SetPoint("TOPLEFT", optionsButton, "TOPRIGHT", 10, 0)
    seasonStatsButton:SetScript("OnClick", function()
        UI:ShowSeasonStatsWindow()
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
    
    -- Player name label (more space)
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", 5, 0)
    nameHeader:SetText("Player")
    nameHeader:SetTextColor(0.8, 0.8, 0.8)
    nameHeader:SetWidth(200) -- Increased from implicit width for better spacing
    nameHeader:SetJustifyH("LEFT") -- Left aligned
    
    -- Create penalty headers dynamically (wider spacing)
    local xOffset = 210 -- Increased from 150 to give more room for player names
    for reason, amount in pairs(RaidSanctions.Logic:GetPenalties()) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", xOffset, 0)
        header:SetText(reason) -- Nur Penalty-Name, Counter kommen in die Zeilen
        header:SetTextColor(0.8, 0.8, 0.8)
        header:SetWidth(100) -- Increased from BUTTON_WIDTH for better readability
        header:SetJustifyH("CENTER") -- Centered alignment
        headerButtons[reason] = header
        xOffset = xOffset + 110 -- Increased spacing from (BUTTON_WIDTH + 15) to 110
    end
    
    -- Total header (positioned more to the left)
    local totalHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalHeader:SetPoint("LEFT", xOffset + 20, 0) -- Position based on calculated xOffset instead of RIGHT
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
    
    -- Selected Player info (next to Penalties label)
    local selectedPlayerLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedPlayerLabel:SetPoint("LEFT", actionsLabel, "RIGHT", 10, 0)
    selectedPlayerLabel:SetText("")
    selectedPlayerLabel:SetTextColor(0.8, 0.8, 0.8)
    mainFrame.selectedPlayerLabel = selectedPlayerLabel -- Store reference for updates
    
    -- ERSTE REIHE: Penalty-Buttons (2 Reihen mit je 4 Button-Paaren)
    local penalties = RaidSanctions.Logic:GetPenalties()
    local penaltyList = {}
    for reason, amount in pairs(penalties) do
        table.insert(penaltyList, {reason = reason, amount = amount})
    end
    
    local buttonsPerRow = 4
    local buttonIndex = 0
    
    for i, penaltyData in ipairs(penaltyList) do
        local reason = penaltyData.reason
        local amount = penaltyData.amount
        
        -- Calculate position (2 rows, 4 buttons each)
        local row = math.floor(buttonIndex / buttonsPerRow)
        local col = buttonIndex % buttonsPerRow
        
        local xOffset = 10 + col * 220  -- 220 pixels spacing between button pairs
        local yOffset = -30 - row * 30   -- 30 pixels between rows
        
        -- Main penalty button (add penalty) - made wider
        local button = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        button:SetSize(190, BUTTON_HEIGHT) -- Increased from 140 to 190 to fit text better
        button:SetPoint("TOPLEFT", xOffset, yOffset)
        button:SetText(reason .. " (" .. RaidSanctions.Logic:FormatGold(amount) .. ")")
        
        -- Click handler for currently selected player
        button:SetScript("OnClick", function()
            UI:ApplyPenaltyToSelectedPlayer(reason, amount)
        end)
        
        -- Tooltip
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Apply penalty: " .. reason)
            GameTooltip:AddLine("Amount: " .. RaidSanctions.Logic:FormatGold(amount))
            GameTooltip:AddLine("Click to give this penalty to the selected player.", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Minus button (remove penalty) - positioned right next to the main button
        local minusButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
        minusButton:SetSize(25, BUTTON_HEIGHT) -- Slightly wider minus button
        minusButton:SetPoint("LEFT", button, "RIGHT", 2, 0) -- 2 pixels gap
        minusButton:SetText("-")
        minusButton:GetFontString():SetTextColor(1, 0.3, 0.3) -- Reddish color
        
        -- Click handler for removing penalty
        minusButton:SetScript("OnClick", function()
            UI:RemovePenaltyFromSelectedPlayer(reason, amount)
        end)
        
        -- Tooltip for minus button
        minusButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Remove penalty: " .. reason)
            GameTooltip:AddLine("Amount: " .. RaidSanctions.Logic:FormatGold(amount))
            GameTooltip:AddLine("Click to remove this penalty from the selected player.", 1, 1, 1)
            GameTooltip:Show()
        end)
        minusButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        buttonIndex = buttonIndex + 1
    end
    
    -- "Management:" label for third row (after 2 penalty button rows)
    local managementLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    managementLabel:SetPoint("TOPLEFT", 10, -105) -- Moved down from -95 to -105 to make room for auth status
    managementLabel:SetText("Management:")
    managementLabel:SetTextColor(1, 0.8, 0)
    
    -- THIRD ROW: Management Buttons (moved down to make room for auth status)
    local managementYOffset = -125 -- Moved down from -115 to -125
    
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
    
    -- "Sync Session" Button
    local syncButton = CreateFrame("Button", nil, bottomPanel, "UIPanelButtonTemplate")
    syncButton:SetSize(100, BUTTON_HEIGHT)
    syncButton:SetPoint("TOPLEFT", 460, managementYOffset)
    syncButton:SetText("Sync Session")
    syncButton:GetFontString():SetTextColor(0.2, 1, 1) -- Cyan
    
    syncButton:SetScript("OnClick", function()
        UI:SyncSessionData()
    end)
    
    syncButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Synchronize Complete Data")
        GameTooltip:AddLine("Shares your current session data, penalty settings, and season statistics.", 1, 1, 1)
        GameTooltip:AddLine("Other players with RaidSanctions will receive all your data.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Requires raid leader or assistant permissions.", 1, 0.8, 0.2)
        GameTooltip:Show()
    end)
    syncButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Authorization status display (top right of bottom panel)
    local authStatusLabel = bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    authStatusLabel:SetPoint("TOPRIGHT", -10, -8)
    authStatusLabel:SetText("") -- Will be set by UpdateAuthorizationStatus
    mainFrame.authStatusLabel = authStatusLabel -- Store reference for updates
    
    mainFrame.bottomPanel = bottomPanel
end

function UI:HandleRaidStateChange()
    -- Automatic session cleanup when joining a raid group
    local currentlyInRaid = IsInRaid()
    
    -- Only trigger cleanup when joining a raid (not when leaving)
    if currentlyInRaid and not self.wasInRaid then
        -- Player just joined a raid group
        print("RaidSanctions: Joined raid group - automatically resetting session data for new raid.")
        
        -- Reset session data (same logic as manual reset)
        if RaidSanctions.Logic:ResetSession() then
            print("RaidSanctions: Session data cleared for new raid.")
            
            -- Refresh UI if main frame is visible
            if mainFrame and mainFrame:IsShown() then
                self:RefreshPlayerList()
            end
        else
            print("RaidSanctions: Error clearing session data.")
        end
    end
    
    -- Update stored raid state for next comparison
    self.wasInRaid = currentlyInRaid
end

function UI:SetupEventHandlers()
    -- Note: No keyboard capture for main frame to allow normal gameplay
    -- ESC key handling is removed to allow normal ESC functionality in WoW
    
    -- Clear any existing event handlers first
    if self.syncEventFrame then
        self.syncEventFrame:UnregisterAllEvents()
        self.syncEventFrame:SetScript("OnEvent", nil)
        self.syncEventFrame = nil
    end
    
    -- Register for addon communication (max 16 characters)
    C_ChatInfo.RegisterAddonMessagePrefix("RaidSanctions")
    
    -- Set up addon message handler and raid join detection
    self.syncEventFrame = CreateFrame("Frame", "RaidSanctionsSyncFrame")
    self.syncEventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.syncEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- For raid join/leave detection
    
    -- Store previous raid state for comparison
    self.wasInRaid = IsInRaid()
    
    self.syncEventFrame:SetScript("OnEvent", function(self, event, prefix, message, distribution, sender)
        if event == "CHAT_MSG_ADDON" then
            -- Ignore our own messages completely
            local playerName = UnitName("player")
            -- Also handle realm names (e.g., "Drodar-Eredar" vs "Drodar")
            local senderName = sender:match("([^-]+)") or sender
            local currentName = playerName:match("([^-]+)") or playerName
            
            if senderName == currentName then
                return
            end
            
            if prefix == "RaidSanctions" then
                UI:HandleMultiSyncMessage(message, sender, distribution)
            end
        elseif event == "GROUP_ROSTER_UPDATE" then
            -- Handle raid join detection for automatic session cleanup
            UI:HandleRaidStateChange()
        end
    end)
end

function UI:RefreshPlayerList()
    if not mainFrame then
        return
    end
    
    -- Clear player selection when refreshing
    self:ClearAllPlayerSelections()
    
    -- Remove old rows
    for _, row in ipairs(playerRows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(playerRows)
    
    local session = RaidSanctions.Logic:GetCurrentSession()
    if not session then
        return
    end
    
    -- Check authorization and update UI accordingly
    local isAuthorized = self:IsPlayerAuthorized()
    self:UpdateAuthorizationStatus(isAuthorized)
    
    -- Separate players by guild membership
    local guildMembers = {}
    local randomPlayers = {}
    
    for playerName, playerData in pairs(session.players) do
        if RaidSanctions.Logic:IsPlayerInGuild(playerName) then
            table.insert(guildMembers, {name = playerName, data = playerData})
        else
            table.insert(randomPlayers, {name = playerName, data = playerData})
        end
    end
    
    -- Sort both lists by penalty amount (highest first)
    local sortFunction = function(a, b)
        return (a.data.total or 0) > (b.data.total or 0)
    end
    table.sort(guildMembers, sortFunction)
    table.sort(randomPlayers, sortFunction)
    
    local yOffset = 0
    local contentHeight = 0
    
    -- Add Guild Members section
    if #guildMembers > 0 then
        local guildHeader = self:CreateSectionHeader("Guild Members (" .. #guildMembers .. ")", yOffset)
        table.insert(playerRows, guildHeader)
        yOffset = yOffset - ROW_HEIGHT
        contentHeight = contentHeight + ROW_HEIGHT
        
        for _, player in ipairs(guildMembers) do
            local row = self:CreatePlayerRow(player.name, player.data, yOffset)
            table.insert(playerRows, row)
            yOffset = yOffset - ROW_HEIGHT
            contentHeight = contentHeight + ROW_HEIGHT
        end
        
        -- Add spacing between sections
        yOffset = yOffset - 10
        contentHeight = contentHeight + 10
    end
    
    -- Add Random Players section
    if #randomPlayers > 0 then
        local randomHeader = self:CreateSectionHeader("Random Players (" .. #randomPlayers .. ")", yOffset)
        table.insert(playerRows, randomHeader)
        yOffset = yOffset - ROW_HEIGHT
        contentHeight = contentHeight + ROW_HEIGHT
        
        for _, player in ipairs(randomPlayers) do
            local row = self:CreatePlayerRow(player.name, player.data, yOffset)
            table.insert(playerRows, row)
            yOffset = yOffset - ROW_HEIGHT
            contentHeight = contentHeight + ROW_HEIGHT
        end
    end
    
    -- Adjust content frame height
    mainFrame.contentFrame:SetHeight(math.max(contentHeight, mainFrame.scrollFrame:GetHeight()))
end

function UI:RefreshSeasonPlayerList()
    if not self.seasonStatsFrame then
        return
    end
    
    local seasonFrame = self.seasonStatsFrame
    
    -- Remove old rows
    for _, row in ipairs(seasonFrame.playerRows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(seasonFrame.playerRows)
    
    -- Get categorized season data from Logic module
    local guildPlayers, randomPlayers = RaidSanctions.Logic:GetSeasonPlayersByCategory()
    
    -- Check if we have any data
    if #guildPlayers == 0 and #randomPlayers == 0 then
        local placeholderText = seasonFrame.contentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        placeholderText:SetPoint("CENTER", 0, 0)
        placeholderText:SetText("No Season Data Available\n\nSeason statistics will appear here when data is collected.")
        placeholderText:SetTextColor(0.8, 0.8, 0.8)
        placeholderText:SetJustifyH("CENTER")
        return
    end
    
    local yOffset = 0
    local contentHeight = 0
    
    -- Add Guild Members section
    if #guildPlayers > 0 then
        local guildHeader = self:CreateSeasonSectionHeader("Guild Members (" .. #guildPlayers .. ")", yOffset, seasonFrame.contentFrame)
        table.insert(seasonFrame.playerRows, guildHeader)
        yOffset = yOffset - ROW_HEIGHT
        contentHeight = contentHeight + ROW_HEIGHT
        
        for _, playerData in ipairs(guildPlayers) do
            local row = self:CreateSeasonPlayerRow(playerData.name, playerData, yOffset, seasonFrame.contentFrame)
            table.insert(seasonFrame.playerRows, row)
            yOffset = yOffset - ROW_HEIGHT
            contentHeight = contentHeight + ROW_HEIGHT
        end
        
        -- Add spacing between sections
        yOffset = yOffset - 10
        contentHeight = contentHeight + 10
    end
    
    -- Add Random Players section
    if #randomPlayers > 0 then
        local randomHeader = self:CreateSeasonSectionHeader("Random Players (" .. #randomPlayers .. ")", yOffset, seasonFrame.contentFrame)
        table.insert(seasonFrame.playerRows, randomHeader)
        yOffset = yOffset - ROW_HEIGHT
        contentHeight = contentHeight + ROW_HEIGHT
        
        for _, playerData in ipairs(randomPlayers) do
            local row = self:CreateSeasonPlayerRow(playerData.name, playerData, yOffset, seasonFrame.contentFrame)
            table.insert(seasonFrame.playerRows, row)
            yOffset = yOffset - ROW_HEIGHT
            contentHeight = contentHeight + ROW_HEIGHT
        end
    end
    
    -- Adjust content frame height
    seasonFrame.contentFrame:SetHeight(math.max(contentHeight, seasonFrame.scrollFrame:GetHeight()))
end

function UI:UpdateAuthorizationStatus(isAuthorized)
    if not mainFrame or not mainFrame.bottomPanel then
        return
    end
    
    -- Create or update authorization status label
    if not mainFrame.authStatusLabel then
        mainFrame.authStatusLabel = mainFrame.bottomPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mainFrame.authStatusLabel:SetPoint("TOPRIGHT", -10, -8)
    end
    
    if isAuthorized then
        mainFrame.authStatusLabel:SetText("✓ Authorized (Leader/Assistant)")
        mainFrame.authStatusLabel:SetTextColor(0.2, 1, 0.2) -- Green
    else
        mainFrame.authStatusLabel:SetText("✗ Not Authorized (Need Leader/Assistant)")
        mainFrame.authStatusLabel:SetTextColor(1, 0.2, 0.2) -- Red
    end
    
    -- Update toolbar buttons based on authorization
    self:SetToolbarButtonsEnabled(isAuthorized)
end

function UI:IsPlayerAuthorized()
    -- Check if player has permission to use penalty actions
    -- Player must be raid leader or raid assistant
    
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    
    if inRaid then
        -- In raid: check if player is leader or assistant
        local playerName = UnitName("player")
        local numRaidMembers = GetNumGroupMembers()
        
        for i = 1, numRaidMembers do
            local name, rank = GetRaidRosterInfo(i)
            if name then
                -- Remove realm name if present
                local raidMemberName = name:match("([^-]+)")
                if raidMemberName == playerName then
                    -- Rank 2 = Leader, Rank 1 = Assistant, Rank 0 = Normal member
                    return rank >= 1
                end
            end
        end
        return false
    elseif inGroup then
        -- In party: check if player is party leader
        return UnitIsGroupLeader("player")
    else
        -- Not in group: allow (for testing/solo use)
        return true
    end
end

function UI:CreateSectionHeader(title, yOffset)
    local header = CreateFrame("Frame", nil, mainFrame.contentFrame)
    header:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
    header:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Background for section header
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    
    -- Title text
    local titleLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("LEFT", 10, 0)
    titleLabel:SetText(title)
    titleLabel:SetTextColor(1, 0.8, 0) -- Gold color
    
    return header
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
    
    -- Hover highlight (built-in WoW system)
    local hoverBg = row:CreateTexture(nil, "HIGHLIGHT")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(0.3, 0.6, 1, 0.2) -- Light blue hover
    
    -- Click handler for player selection
    row:SetScript("OnClick", function()
        UI:SelectPlayer(playerName)
    end)
    
    -- Player name with class color (more space)
    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", 5, 0)
    nameLabel:SetText(playerName)
    nameLabel:SetWidth(200) -- Match header width
    nameLabel:SetJustifyH("LEFT") -- Left aligned
    
    -- Klassenfarbe anwenden
    if playerData.class then
        local classColor = RAID_CLASS_COLORS[playerData.class]
        if classColor then
            nameLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end
    
    -- Penalty-Counter (wider spacing to match header)
    local xOffset = 210 -- Match header starting position
    for reason, amount in pairs(RaidSanctions.Logic:GetPenalties()) do
        local counter = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        counter:SetPoint("LEFT", xOffset, 0)
        counter:SetWidth(100) -- Match header width
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
        
        xOffset = xOffset + 110 -- Match header spacing
    end
    
    -- Total display (positioned to match header)
    local totalLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalLabel:SetPoint("LEFT", xOffset + 20, 0) -- Match header position
    totalLabel:SetText(RaidSanctions.Logic:FormatGold(playerData.total))
    totalLabel:SetWidth(120)
    totalLabel:SetJustifyH("CENTER") -- Center align to match header
    
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

function UI:CreateSeasonSectionHeader(title, yOffset, parentFrame)
    local header = CreateFrame("Frame", nil, parentFrame)
    header:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
    header:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Background for section header
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    
    -- Title text
    local titleLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("LEFT", 10, 0)
    titleLabel:SetText(title)
    titleLabel:SetTextColor(1, 0.8, 0) -- Gold color
    
    return header
end

function UI:CreateSeasonPlayerRow(playerName, playerData, yOffset, parentFrame)
    local row = CreateFrame("Frame", nil, parentFrame) -- Frame instead of Button (no selection needed)
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
    
    -- Player name with class color (more space)
    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", 5, 0)
    nameLabel:SetText(playerName)
    nameLabel:SetWidth(200) -- Match main window
    nameLabel:SetJustifyH("LEFT") -- Left aligned
    
    -- Apply class color if available
    if playerData.class then
        local classColor = RAID_CLASS_COLORS[playerData.class]
        if classColor then
            nameLabel:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end
    
    -- Penalty-Counter (same spacing as main window)
    local xOffset = 210 -- Match main window
    for reason, amount in pairs(RaidSanctions.Logic:GetPenalties()) do
        local counter = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        counter:SetPoint("LEFT", xOffset, 0)
        counter:SetWidth(100) -- Match main window
        counter:SetJustifyH("CENTER")
        
        -- Calculate counter value from season data
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
            counter:SetTextColor(1, 0.2, 0.2) -- Red
        elseif count > 1 then
            counter:SetTextColor(1, 0.8, 0.2) -- Orange
        elseif count > 0 then
            counter:SetTextColor(1, 1, 0.2) -- Yellow
        else
            counter:SetTextColor(0.8, 0.8, 0.8) -- Gray
        end
        
        xOffset = xOffset + 110 -- Match main window
    end
    
    -- Total display (positioned to match main window)
    local totalLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalLabel:SetPoint("LEFT", xOffset + 20, 0) -- Match main window position
    totalLabel:SetText(RaidSanctions.Logic:FormatGold(playerData.totalAmount))
    totalLabel:SetWidth(120)
    totalLabel:SetJustifyH("CENTER") -- Center align to match main window
    
    -- Color based on penalty amount
    if playerData.totalAmount > 50000 then -- > 5g
        totalLabel:SetTextColor(1, 0.2, 0.2) -- Red
    elseif playerData.totalAmount > 20000 then -- > 2g
        totalLabel:SetTextColor(1, 0.8, 0.2) -- Orange
    else
        totalLabel:SetTextColor(0.8, 0.8, 0.8) -- Gray
    end
    
    return row
end

function UI:ShowResetConfirmation()
    -- Check authorization first
    if not self:IsPlayerAuthorized() then
        print("Error: You must be raid leader or raid assistant to reset session data.")
        return
    end
    
    StaticPopup_Show("RAIDSANCTIONS_RESET_CONFIRM")
end

function UI:ShowAddPlayerDialog()
    -- Check authorization first
    if not self:IsPlayerAuthorized() then
        print("Error: You must be raid leader or raid assistant to add players manually.")
        return
    end
    
    StaticPopup_Show("RAIDSANCTIONS_ADD_PLAYER")
end

function UI:AddPlayerManually(playerName)
    if RaidSanctions.Logic:AddPlayerManually(playerName) then
        print("Player '" .. playerName .. "' added to current session.")
        self:RefreshPlayerList()
    else
        print("Error: Player '" .. playerName .. "' could not be added or already exists.")
    end
end

function UI:SelectPlayer(playerName)
    -- Deselect previously selected player first
    if selectedPlayer and selectedPlayer ~= playerName then
        self:DeselectPlayer(selectedPlayer)
    end
    
    -- Prevent double-selection of the same player
    if selectedPlayer == playerName then
        return
    end
    
    selectedPlayer = playerName
    
    -- Update selected player label
    if mainFrame and mainFrame.selectedPlayerLabel then
        mainFrame.selectedPlayerLabel:SetText("Selected for " .. playerName)
        mainFrame.selectedPlayerLabel:SetTextColor(0.2, 1, 0.2) -- Green when selected
    end
    
    -- Visual update of selection - find and highlight the selected row
    for _, row in ipairs(playerRows) do
        if row.playerName == playerName then
            -- Clear any existing selection background
            if row.selectionBg then
                row.selectionBg:Hide()
                row.selectionBg:SetParent(nil)
                row.selectionBg = nil
            end
            
            -- Create new selection background
            row.selectionBg = row:CreateTexture(nil, "BACKGROUND", nil, 1) -- Higher sublevel
            row.selectionBg:SetAllPoints()
            row.selectionBg:SetColorTexture(0.2, 0.5, 1, 0.4) -- Blue selection
            break
        end
    end
end

function UI:DeselectPlayer(playerName)
    -- Remove visual selection from a specific player
    for _, row in ipairs(playerRows) do
        if row.playerName == playerName then
            if row.selectionBg then
                row.selectionBg:Hide()
                row.selectionBg:SetParent(nil)
                row.selectionBg = nil
            end
            break
        end
    end
end

function UI:ClearAllPlayerSelections()
    -- Clear all player selections (useful when refreshing the list)
    selectedPlayer = nil
    
    -- Update selected player label
    if mainFrame and mainFrame.selectedPlayerLabel then
        mainFrame.selectedPlayerLabel:SetText("")
        mainFrame.selectedPlayerLabel:SetTextColor(0.8, 0.8, 0.8) -- Gray when none selected
    end
    
    for _, row in ipairs(playerRows) do
        if row.selectionBg then
            row.selectionBg:Hide()
            row.selectionBg:SetParent(nil)
            row.selectionBg = nil
        end
    end
end

function UI:ApplyPenaltyToSelectedPlayer(reason, amount)
    -- Check authorization first (button should be disabled, but double-check)
    if not self:IsPlayerAuthorized() then
        return
    end
    
    if not selectedPlayer then
        print("No player selected! Click on a player in the list first.")
        return
    end
    
    if RaidSanctions.Logic:ApplyPenalty(selectedPlayer, reason, amount) then
        print("Applied penalty '" .. reason .. "' to " .. selectedPlayer)
        self:RefreshPlayerList()
        -- Reselect the player after refresh to maintain selection
        self:SelectPlayer(selectedPlayer)
    else
        print("Error applying penalty to " .. selectedPlayer .. ".")
    end
end

function UI:RemovePenaltyFromSelectedPlayer(reason, amount)
    -- Check authorization first (button should be disabled, but double-check)
    if not self:IsPlayerAuthorized() then
        return
    end
    
    if not selectedPlayer then
        print("No player selected! Click on a player in the list first.")
        return
    end
    
    if RaidSanctions.Logic:RemovePenalty(selectedPlayer, reason, amount) then
        print("Removed penalty '" .. reason .. "' from " .. selectedPlayer)
        self:RefreshPlayerList()
        -- Reselect the player after refresh to maintain selection
        self:SelectPlayer(selectedPlayer)
    else
        print("Error removing penalty from " .. selectedPlayer .. " (no penalty found).")
    end
end

function UI:ResetSelectedPlayerPenalties()
    -- Check authorization first (button should be disabled, but double-check)
    if not self:IsPlayerAuthorized() then
        return
    end
    
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
    
    local session = RaidSanctions.Logic:GetCurrentSession()
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
        local totalText = RaidSanctions.Logic:FormatGold(playerData.total)
        
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
    local session = RaidSanctions.Logic:GetCurrentSession()
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
        local message = i .. ". " .. player.name .. ": " .. RaidSanctions.Logic:FormatGold(player.total)
        SendChatMessage(message, "RAID")
    end
    
    print("Penalty statistics posted to raid chat (" .. #playersWithPenalties .. " players with penalties).")
end

function UI:SyncSessionData()
    -- Check authorization first (button should be disabled, but double-check)
    local isAuthorized = self:IsPlayerAuthorized()
    if not isAuthorized then
        return
    end
    
    -- Check if we're in a raid or group
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    if not inRaid and not inGroup then
        print("You must be in a raid or group to sync data.")
        return
    end
    
    local session = RaidSanctions.Logic:GetCurrentSession()
    local penalties = RaidSanctions.Logic:GetPenalties()
    local seasonData = RaidSanctions.Logic:GetSeasonData()
    
    if not session or not session.players then
        print("No session data to sync.")
        return
    end
    
    -- Send multi-message sync
    self:SendMultiMessageSync(session, penalties, seasonData)
end

function UI:SendMultiMessageSync(session, penalties, seasonData)
    local sender = UnitName("player")
    local timestamp = time()
    local channel = IsInRaid() and "RAID" or "PARTY"
    
    local totalPlayers = 0
    for _ in pairs(session.players) do
        totalPlayers = totalPlayers + 1
    end
    
    -- Create message queue
    local messageQueue = {}
    
    -- 1. Penalty configuration message
    local penaltyConfigMsg = "CFG:PENALTIES|V:2.0|S:" .. sender .. "|T:" .. timestamp .. "|"
    for reason, amount in pairs(penalties) do
        penaltyConfigMsg = penaltyConfigMsg .. reason .. "=" .. amount .. ";"
    end
    table.insert(messageQueue, {type = "CFG:PENALTIES", message = penaltyConfigMsg})
    
    -- 2. Session start marker
    local sessionStartMsg = "CFG:SESSION_START|V:2.0|S:" .. sender .. "|T:" .. timestamp .. "|COUNT:" .. totalPlayers
    table.insert(messageQueue, {type = "CFG:SESSION_START", message = sessionStartMsg})
    
    -- 3. COMPRESSED player messages (multiple players per message)
    local currentBatch = {}
    local maxMessageSize = 190 -- Conservative limit to avoid WoW's 240 char limit
    local batchIndex = 1
    
    for playerName, playerData in pairs(session.players) do
        -- Create ultra-compact player data: name:total:class:penalties
        local playerCompact = playerName .. ":" .. (playerData.total or 0) .. ":" .. (playerData.class or "UNKNOWN")
        
        -- Add compressed penalties if present
        if playerData.penalties and #playerData.penalties > 0 then
            playerCompact = playerCompact .. ":"
            for _, penalty in ipairs(playerData.penalties) do
                -- Smart-compress: use unique identifiers for each penalty type
                local reasonShort = ""
                if penalty.reason == "Late" then reasonShort = "LAT"
                elseif penalty.reason == "AFK" then reasonShort = "AFK"
                elseif penalty.reason == "Wrong Gear" then reasonShort = "WGR"
                elseif penalty.reason == "Wrong Tactic" then reasonShort = "WTC"
                elseif penalty.reason == "Disruption" then reasonShort = "DIS"
                else
                    reasonShort = penalty.reason:sub(1,3):upper() -- Fallback
                end
                
                local compressedPenalty = reasonShort .. penalty.amount
                playerCompact = playerCompact .. compressedPenalty .. ","
            end
            playerCompact = playerCompact:sub(1, -2) -- Remove trailing comma
        end
        
        -- Check if adding this player would exceed message size
        local testMessage = "BATCH|V:2.0|S:" .. sender .. "|T:" .. timestamp .. "|IDX:" .. batchIndex .. "|" .. table.concat(currentBatch, ";") .. ";" .. playerCompact
        
        if string.len(testMessage) > maxMessageSize and #currentBatch > 0 then
            -- Send current batch
            local batchMessage = "BATCH|V:2.0|S:" .. sender .. "|T:" .. timestamp .. "|IDX:" .. batchIndex .. "|" .. table.concat(currentBatch, ";")
            table.insert(messageQueue, {type = "BATCH", message = batchMessage, batchIndex = batchIndex, playerCount = #currentBatch})
            
            -- Start new batch
            currentBatch = {playerCompact}
            batchIndex = batchIndex + 1
        else
            -- Add to current batch
            table.insert(currentBatch, playerCompact)
        end
    end
    
    -- Send final batch if not empty
    if #currentBatch > 0 then
        local batchMessage = "BATCH|V:2.0|S:" .. sender .. "|T:" .. timestamp .. "|IDX:" .. batchIndex .. "|" .. table.concat(currentBatch, ";")
        table.insert(messageQueue, {type = "BATCH", message = batchMessage, batchIndex = batchIndex, playerCount = #currentBatch})
    end
    
    -- 4. Session end marker
    local sessionEndMsg = "CFG:SESSION_END|V:2.0|S:" .. sender .. "|T:" .. timestamp .. "|SENT:" .. totalPlayers .. "|BATCHES:" .. batchIndex
    table.insert(messageQueue, {type = "CFG:SESSION_END", message = sessionEndMsg})
    
    -- Send messages with delays using our delayed sending function
    self:SendMessagesWithDelay(messageQueue, channel, timestamp)
end

function UI:SendMessagesWithDelay(messageQueue, channel, sessionTimestamp)
    if not messageQueue or #messageQueue == 0 then
        return
    end
    
    -- Initialize tracking
    local totalMessages = #messageQueue
    local sentCount = 0
    local failedCount = 0
    
    -- Send first message immediately
    local function sendNextMessage(index)
        if index > totalMessages then
            if sentCount == totalMessages then
                print("Multi-message sync completed successfully! Sent " .. sentCount .. " messages.")
            else
                print("Multi-message sync completed with " .. failedCount .. " failures out of " .. totalMessages .. " messages.")
            end
            return
        end
        
        local msgData = messageQueue[index]
        local success = C_ChatInfo.SendAddonMessage("RaidSanctions", msgData.message, channel)
        
        if success and success ~= 0 then
            sentCount = sentCount + 1
        else
            failedCount = failedCount + 1
            print("ERROR: Failed to send message " .. index .. " (" .. msgData.type .. ")")
        end
        
        -- Schedule next message with 300ms delay
        if index < totalMessages then
            C_Timer.After(0.3, function()
                sendNextMessage(index + 1)
            end)
        end
    end
    
    -- Start sending
    sendNextMessage(1)
end

function UI:SerializeSyncData(data)
    
    -- Enhanced serialization for comprehensive sync data
    local success, result = pcall(function()
        local serialized = ""
        serialized = serialized .. "VERSION:" .. data.version .. "|"
        serialized = serialized .. "TIMESTAMP:" .. data.timestamp .. "|"
        serialized = serialized .. "SENDER:" .. data.sender .. "|"
        
        
        -- Serialize penalty configuration
        if data.penaltyConfig then
            serialized = serialized .. "PENALTIES:"
            for reason, amount in pairs(data.penaltyConfig) do
                serialized = serialized .. reason .. "=" .. amount .. ";"
            end
            serialized = serialized .. "|"
        else
        end
        
        -- Serialize session data
        serialized = serialized .. "SESSION:"
        local playerCount = 0
        local totalPlayersToSync = 0
        
        -- First, count total players
        for _ in pairs(data.sessionData.players) do
            totalPlayersToSync = totalPlayersToSync + 1
        end
        
        for playerName, playerData in pairs(data.sessionData.players) do
            playerCount = playerCount + 1
            serialized = serialized .. playerName .. "=" .. (playerData.total or 0)
            
            -- Serialize penalties for this player
            if playerData.penalties and #playerData.penalties > 0 then
                local penaltyStrings = {}
                for _, penalty in ipairs(playerData.penalties) do
                    table.insert(penaltyStrings, penalty.reason .. ":" .. penalty.amount)
                end
                serialized = serialized .. ";" .. table.concat(penaltyStrings, ",")
            else
            end
            serialized = serialized .. "#"
        end
        serialized = serialized .. "|"
        
        -- Serialize season data
        if data.seasonData and data.seasonData.players then
            serialized = serialized .. "SEASON:"
            for playerName, playerData in pairs(data.seasonData.players) do
                serialized = serialized .. playerName .. "=" .. (playerData.totalAmount or 0) .. ";"
                if playerData.penalties then
                    for _, penalty in ipairs(playerData.penalties) do
                        serialized = serialized .. penalty.reason .. ":" .. penalty.amount .. "," .. (penalty.uniqueId or "") .. ","
                    end
                end
                serialized = serialized .. "#"
            end
        else
        end
        
        return serialized
    end)
    
    if success then
        return result
    else
        return nil
    end
end

function UI:DeserializeSyncData(dataString)
    
    -- Enhanced deserialization for comprehensive sync data
    local success, result = pcall(function()
        
        -- Check for compact format first
        local compactVersion = dataString:match("V:([^|]+)")
        if compactVersion then
            return self:DeserializeCompactData(dataString)
        end
        
        -- Parse basic info (full format)
        local version = dataString:match("VERSION:([^|]+)")
        local timestamp = tonumber(dataString:match("TIMESTAMP:([^|]+)"))
        local sender = dataString:match("SENDER:([^|]+)")
        
        
        if not version or not timestamp or not sender then
            return nil
        end
        
        local syncData = {
            version = version,
            timestamp = timestamp,
            sender = sender,
            sessionData = {players = {}},
            penaltyConfig = {},
            seasonData = {players = {}}
        }
        
        -- Parse penalty configuration (if present in v2.0+)
        local penaltiesSection = dataString:match("PENALTIES:([^|]+)")
        if penaltiesSection then
            for penaltyBlock in penaltiesSection:gmatch("([^;]+)") do
                if penaltyBlock ~= "" then
                    local reason, amount = penaltyBlock:match("([^=]+)=(.+)")
                    if reason and amount then
                        syncData.penaltyConfig[reason] = tonumber(amount) or 10000 -- Default 1g
                    end
                end
            end
        else
        end
        
        -- Parse session data
        local sessionSection = dataString:match("SESSION:([^|]+)")
        if sessionSection then
            
            local playersParsed = 0
            local totalBlocks = 0
            
            -- Count total blocks first
            for _ in sessionSection:gmatch("([^#]+)") do
                totalBlocks = totalBlocks + 1
            end
            
            for playerBlock in sessionSection:gmatch("([^#]+)") do
                if playerBlock ~= "" then
                    playersParsed = playersParsed + 1
                    
                    local playerName, playerInfo = playerBlock:match("([^=]+)=(.+)")
                    if playerName and playerInfo then
                        local total = tonumber(playerInfo:match("^(%d+)"))
                        local penalties = {}
                        
                        
                        -- Parse penalties (if any)
                        local penaltiesSection = playerInfo:match(";(.+)")
                        if penaltiesSection then
                            -- Split by commas and process penalty pairs
                            for penaltyPair in penaltiesSection:gmatch("([^,]+)") do
                                if penaltyPair ~= "" then
                                    local reason, amount = penaltyPair:match("([^:]+):(%d+)")
                                    if reason and amount then
                                        table.insert(penalties, {
                                            reason = reason,
                                            amount = tonumber(amount),
                                            timestamp = timestamp,
                                            uniqueId = timestamp .. "_" .. math.random(1000, 9999)
                                        })
                                    end
                                end
                            end
                        end
                        
                        syncData.sessionData.players[playerName] = {
                            total = total,
                            penalties = penalties,
                            class = nil -- Will be updated when player joins
                        }
                    else
                    end
                else
                end
            end
            
        else
        end
        
        -- Parse season data (if present)
        local seasonSection = dataString:match("SEASON:(.+)")
        if seasonSection then
            for playerBlock in seasonSection:gmatch("([^#]+)") do
                if playerBlock ~= "" then
                    local playerName, playerInfo = playerBlock:match("([^=]+)=(.+)")
                    if playerName and playerInfo then
                        local total = tonumber(playerInfo:match("^(%d+)"))
                        local penalties = {}
                        
                        
                        -- Parse season penalties (if any)
                        local penaltiesSection = playerInfo:match(";(.+)")
                        if penaltiesSection then
                            local penaltyData = ""
                            for char in penaltiesSection:gmatch(".") do
                                if char == "," then
                                    if penaltyData ~= "" then
                                        local reason, amount = penaltyData:match("([^:]+):(%d+)")
                                        if reason and amount then
                                            table.insert(penalties, {
                                                reason = reason,
                                                amount = tonumber(amount),
                                                timestamp = timestamp,
                                                uniqueId = timestamp .. "_" .. math.random(1000, 9999)
                                            })
                                        end
                                        penaltyData = ""
                                    end
                                else
                                    penaltyData = penaltyData .. char
                                end
                            end
                        end
                        
                        syncData.seasonData.players[playerName] = {
                            totalAmount = total,
                            penalties = penalties,
                            class = nil
                        }
                    end
                end
            end
        else
        end
        
        return syncData
    end)
    
    if success then
        return result
    else
        return nil
    end
end

function UI:CreateCompactSyncData(syncData)
    
    -- Ultra-compact format: only players with penalties > 0 and basic penalty config
    local success, result = pcall(function()
        local compact = "V:2.0|S:" .. syncData.sender .. "|"
        
        -- Only send essential penalty config (top 3 most common)
        compact = compact .. "P:Late=10000;AFK=10000;WrongGear=10000|"
        
        -- Only include players with penalties > 0 to save space
        compact = compact .. "D:"
        local playerCount = 0
        for playerName, playerData in pairs(syncData.sessionData.players) do
            if playerData.total and playerData.total > 0 then
                if playerCount > 0 then compact = compact .. ";" end
                -- Ultra-compact format: Name:Total
                compact = compact .. playerName .. ":" .. playerData.total
                playerCount = playerCount + 1
                
                -- Stop at 20 players to stay under limit
                if playerCount >= 20 then
                    break
                end
            end
        end
        compact = compact .. "|"
        
        return compact
    end)
    
    if success then
        return result
    else
        return nil
    end
end

function UI:DeserializeCompactData(dataString)
    
    local success, result = pcall(function()
        local version = dataString:match("V:([^|]+)")
        local sender = dataString:match("S:([^|]+)")
        
        
        if not version or not sender then
            return nil
        end
        
        local syncData = {
            version = version,
            timestamp = time(),
            sender = sender,
            sessionData = {players = {}},
            penaltyConfig = {},
            seasonData = {players = {}}
        }
        
        -- Parse compact penalty config
        local penaltiesSection = dataString:match("P:([^|]+)")
        if penaltiesSection then
            for penaltyBlock in penaltiesSection:gmatch("([^;]+)") do
                if penaltyBlock ~= "" then
                    local reason, amount = penaltyBlock:match("([^=]+)=(.+)")
                    if reason and amount then
                        syncData.penaltyConfig[reason] = tonumber(amount)
                    end
                end
            end
        end
        
        -- Parse compact player data
        local dataSection = dataString:match("D:([^|]+)")
        if dataSection then
            local playerCount = 0
            for playerBlock in dataSection:gmatch("([^;]+)") do
                if playerBlock ~= "" then
                    local playerName, total = playerBlock:match("([^:]+):(.+)")
                    if playerName and total then
                        playerCount = playerCount + 1
                        syncData.sessionData.players[playerName] = {
                            total = tonumber(total) or 0,
                            penalties = {},
                            class = nil
                        }
                    end
                end
            end
        end
        
        return syncData
    end)
    
    if success then
        return result
    else
        return nil
    end
end

function UI:HandleSyncMessage(message, sender, distribution)
    -- Emergency safety check - this should never happen now
    if sender == UnitName("player") then
        return
    end
    
    -- Deserialize the received data
    local syncData = self:DeserializeSyncData(message)
    if not syncData then
        print("Error: Failed to parse sync data from " .. sender)
        return
    end
    
    -- Show confirmation dialog with proper data passing
    local popup = StaticPopup_Show("RAIDSANCTIONS_SYNC_CONFIRM", sender)
    if popup then
        popup.data = syncData -- Store syncData in the popup for OnAccept
    else
        print("ERROR: Failed to show StaticPopup")
    end
end

function UI:HandleMultiSyncMessage(message, sender, distribution)
    
    -- Emergency safety check
    if sender == UnitName("player") then
        return
    end
    
    -- Initialize multi-sync session storage if needed
    if not self.multiSyncSessions then
        self.multiSyncSessions = {}
    end
    
    -- Detect message type
    local messageType = message:match("^([^|]+)")
    local version = message:match("V:([^|]+)")
    local msgSender = message:match("S:([^|]+)")
    local timestamp = message:match("T:([^|]+)")
    
    
    -- Create session key
    local sessionKey = sender .. "_" .. (timestamp or "unknown")
    
    if messageType == "CFG:PENALTIES" then
        if not self.multiSyncSessions[sessionKey] then
            self.multiSyncSessions[sessionKey] = {
                sender = sender,
                timestamp = timestamp,
                version = version,
                penaltyConfig = {},
                players = {},
                expectedPlayers = 0,
                receivedPlayers = 0,
                startTime = time(),
                complete = false
            }
        end
        
        -- Parse penalty config
        local session = self.multiSyncSessions[sessionKey]
        local penaltySection = message:match("T:" .. timestamp .. "|(.+)")
        if penaltySection then
            for penaltyBlock in penaltySection:gmatch("([^;]+)") do
                if penaltyBlock ~= "" then
                    local reason, amount = penaltyBlock:match("([^=]+)=(.+)")
                    if reason and amount then
                        session.penaltyConfig[reason] = tonumber(amount)
                    end
                end
            end
        end
        
    elseif messageType == "CFG:SESSION_START" then
        local playerCount = tonumber(message:match("COUNT:(%d+)"))
        if self.multiSyncSessions[sessionKey] then
            self.multiSyncSessions[sessionKey].expectedPlayers = playerCount or 0
        end
        
    elseif messageType == "BATCH" then
        if not self.multiSyncSessions[sessionKey] then
            self.multiSyncSessions[sessionKey] = {
                sender = sender,
                timestamp = timestamp,
                version = version,
                penaltyConfig = {},
                players = {},
                expectedPlayers = 0,
                receivedPlayers = 0,
                startTime = time(),
                complete = false
            }
        end
        
        local session = self.multiSyncSessions[sessionKey]
        local batchIndex = tonumber(message:match("IDX:(%d+)"))
        
        -- Parse compressed player batch: name:total:class:penalties;name:total:class:penalties;...
        local batchData = message:match("IDX:" .. batchIndex .. "|(.+)")
        if batchData then
            local playersInBatch = 0
            for playerCompact in batchData:gmatch("([^;]+)") do
                if playerCompact ~= "" then
                    -- Parse: playerName:total:class:penalties
                    local parts = {}
                    for part in playerCompact:gmatch("([^:]+)") do
                        table.insert(parts, part)
                    end
                    
                    if #parts >= 3 then
                        local playerName = parts[1]
                        local total = tonumber(parts[2]) or 0
                        local class = parts[3]
                        local penaltiesCompressed = parts[4] -- Optional
                        
                        session.receivedPlayers = session.receivedPlayers + 1
                        playersInBatch = playersInBatch + 1
                        session.players[playerName] = {
                            total = total,
                            class = class,
                            penalties = {}
                        }
                        
                        -- Parse compressed penalties if present
                        if penaltiesCompressed then
                            for penaltyCompact in penaltiesCompressed:gmatch("([^,]+)") do
                                if penaltyCompact ~= "" then
                                    -- Parse: LAT10000000 -> reason=Late, amount=10000000
                                    local reasonShort = penaltyCompact:match("([A-Z]+)")
                                    local amount = tonumber(penaltyCompact:match("([0-9]+)"))
                                    
                                    if reasonShort and amount then
                                        -- Expand short reason codes with correct mapping
                                        local fullReason = reasonShort
                                        if reasonShort == "LAT" then fullReason = "Late" 
                                        elseif reasonShort == "AFK" then fullReason = "AFK" 
                                        elseif reasonShort == "WGR" then fullReason = "Wrong Gear"
                                        elseif reasonShort == "WTC" then fullReason = "Wrong Tactic"
                                        elseif reasonShort == "DIS" then fullReason = "Disruption"
                                        end
                                        
                                        table.insert(session.players[playerName].penalties, {
                                            reason = fullReason,
                                            amount = amount,
                                            timestamp = tonumber(timestamp),
                                            uniqueId = timestamp .. "_" .. math.random(1000, 9999)
                                        })
                                        
                                    else
                                    end
                                end
                            end
                        end
                        
                    end
                end
            end
            
        end
        
    elseif messageType == "PLAYER" then
        if not self.multiSyncSessions[sessionKey] then
            self.multiSyncSessions[sessionKey] = {
                sender = sender,
                timestamp = timestamp,
                version = version,
                penaltyConfig = {},
                players = {},
                expectedPlayers = 0,
                receivedPlayers = 0,
                startTime = time(),
                complete = false
            }
        end
        
        local session = self.multiSyncSessions[sessionKey]
        
        -- Parse player data
        local playerName = message:match("N:([^|]+)")
        local total = tonumber(message:match("TOTAL:([^|]+)")) or 0
        local class = message:match("CLASS:([^|]+)")
        
        if playerName then
            session.receivedPlayers = session.receivedPlayers + 1
            session.players[playerName] = {
                total = total,
                class = class,
                penalties = {}
            }
            
            -- Parse penalties if present
            local penaltiesSection = message:match("PENALTIES:([^|]+)")
            if penaltiesSection then
                for penaltyPair in penaltiesSection:gmatch("([^,]+)") do
                    if penaltyPair ~= "" then
                        local reason, amount = penaltyPair:match("([^:]+):(%d+)")
                        if reason and amount then
                            table.insert(session.players[playerName].penalties, {
                                reason = reason,
                                amount = tonumber(amount),
                                timestamp = tonumber(timestamp),
                                uniqueId = timestamp .. "_" .. math.random(1000, 9999)
                            })
                        end
                    end
                end
            end
            
        end
        
    elseif messageType == "CFG:SESSION_END" then
        local sentCount = tonumber(message:match("SENT:(%d+)"))
        local batchCount = tonumber(message:match("BATCHES:(%d+)"))
        
        if self.multiSyncSessions[sessionKey] then
            local session = self.multiSyncSessions[sessionKey]
            session.complete = true
            
            
            -- Convert to standard sync data format
            local syncData = {
                version = session.version or "2.0",
                timestamp = tonumber(session.timestamp) or time(),
                sender = session.sender,
                sessionData = {players = session.players},
                penaltyConfig = session.penaltyConfig,
                seasonData = {players = {}}
            }
            
            -- Show confirmation dialog
            local popup = StaticPopup_Show("RAIDSANCTIONS_SYNC_CONFIRM", sender)
            if popup then
                popup.data = syncData
            else
                print("ERROR: Failed to show StaticPopup for multi-sync")
            end
            
            -- Clean up session
            self.multiSyncSessions[sessionKey] = nil
        end
        
    else
        -- Fallback to old single-message handling
        self:HandleSyncMessage(message, sender, distribution)
    end
    
    -- Cleanup old sessions (older than 30 seconds) and check for incomplete sessions
    local currentTime = time()
    for key, session in pairs(self.multiSyncSessions or {}) do
        if currentTime - session.startTime > 30 then
            self.multiSyncSessions[key] = nil
        elseif not session.complete and currentTime - session.startTime > 10 then
            -- Auto-complete sessions that haven't finished after 10 seconds
            if session.receivedPlayers > 0 and session.expectedPlayers > 0 then
                local completionRate = (session.receivedPlayers / session.expectedPlayers) * 100
                
                if completionRate >= 40 then -- At least 40% received (was 25%, now higher for better data quality)
                    session.complete = true
                    
                    -- Convert to standard sync data format
                    local syncData = {
                        version = session.version or "2.0",
                        timestamp = tonumber(session.timestamp) or time(),
                        sender = session.sender,
                        sessionData = {players = session.players},
                        penaltyConfig = session.penaltyConfig,
                        seasonData = {players = {}}
                    }
                    
                    -- Show confirmation dialog
                    local popup = StaticPopup_Show("RAIDSANCTIONS_SYNC_CONFIRM", session.sender)
                    if popup then
                        popup.data = syncData
                    else
                        print("ERROR: Failed to show StaticPopup for auto-completed sync")
                    end
                    
                    -- Clean up session
                    self.multiSyncSessions[key] = nil
                else
                    self.multiSyncSessions[key] = nil
                end
            end
        end
    end
end

function UI:ApplySyncData(syncData)
    
    -- Apply the comprehensive synchronized data
    if not syncData then
        print("Error: Invalid sync data.")
        return
    end
    
    local itemsUpdated = {}
    
    -- 1. Apply penalty configuration (if present)
    if syncData.penaltyConfig and next(syncData.penaltyConfig) then
        if RaidSanctions.Logic and RaidSanctions.Logic.SetCustomPenalties then
            RaidSanctions.Logic:SetCustomPenalties(syncData.penaltyConfig)
            table.insert(itemsUpdated, "Penalty Settings")
            print("✓ Penalty configuration updated from " .. syncData.sender)
        else
        end
    end
    
    -- 2. Apply session data
    if syncData.sessionData and syncData.sessionData.players then
        
        local syncPlayerCount = 0
        for _ in pairs(syncData.sessionData.players) do
            syncPlayerCount = syncPlayerCount + 1
        end
        
        -- List all received players
        for playerName, playerData in pairs(syncData.sessionData.players) do
        end
        
        local currentSession = nil
        if RaidSanctions.Logic and RaidSanctions.Logic.GetCurrentSession then
            currentSession = RaidSanctions.Logic:GetCurrentSession()
        end
        
        if not currentSession then
            currentSession = {players = {}}
        end
        
        local mergedPlayers = 0
        local updatedPlayers = 0
        
        for playerName, syncPlayerData in pairs(syncData.sessionData.players) do
            
            -- REPLACE player data completely (don't merge/add)
            currentSession.players[playerName] = {
                total = syncPlayerData.total or 0,
                penalties = {},
                class = syncPlayerData.class or (currentSession.players[playerName] and currentSession.players[playerName].class) or "UNKNOWN"
            }
            
            -- Copy penalties from sync data (complete replacement)
            if syncPlayerData.penalties then
                for _, penalty in ipairs(syncPlayerData.penalties) do
                    table.insert(currentSession.players[playerName].penalties, {
                        reason = penalty.reason,
                        amount = penalty.amount,
                        timestamp = penalty.timestamp,
                        uniqueId = penalty.uniqueId
                    })
                end
            else
            end
            
            mergedPlayers = mergedPlayers + 1
        end
        
        -- Update the session
        if RaidSanctions.Logic and RaidSanctions.Logic.SetCurrentSession then
            RaidSanctions.Logic:SetCurrentSession(currentSession)
        else
            print("ERROR: RaidSanctions.Logic.SetCurrentSession not available")
        end
        
        if mergedPlayers > 0 then
            table.insert(itemsUpdated, "Session Data (" .. mergedPlayers .. " players synced)")
            
            -- Debug: List all players now in current session
            local sessionAfterUpdate = RaidSanctions.Logic:GetCurrentSession()
            if sessionAfterUpdate and sessionAfterUpdate.players then
                local totalInSession = 0
                for name, data in pairs(sessionAfterUpdate.players) do
                    totalInSession = totalInSession + 1
                end
            end
        end
    end
    
    -- 3. Apply season data (if present)
    if syncData.seasonData and syncData.seasonData.players and next(syncData.seasonData.players) then
        if RaidSanctions.Logic and RaidSanctions.Logic.MergeSeasonData then
            local seasonMerged = RaidSanctions.Logic:MergeSeasonData(syncData.seasonData)
            if seasonMerged then
                table.insert(itemsUpdated, "Season Statistics")
                print("✓ Season data merged from " .. syncData.sender)
            end
        else
            -- Fallback: Direct merge if function doesn't exist
            local currentSeasonData = nil
            if RaidSanctions.Logic and RaidSanctions.Logic.GetSeasonData then
                currentSeasonData = RaidSanctions.Logic:GetSeasonData()
            end
            if not currentSeasonData then
                currentSeasonData = {players = {}}
            end
            
            for playerName, syncSeasonPlayer in pairs(syncData.seasonData.players) do
                if not currentSeasonData.players[playerName] then
                    currentSeasonData.players[playerName] = syncSeasonPlayer
                else
                    -- Merge penalties without duplicates
                    if syncSeasonPlayer.penalties then
                        for _, penalty in ipairs(syncSeasonPlayer.penalties) do
                            local exists = false
                            if currentSeasonData.players[playerName].penalties then
                                for _, existingPenalty in ipairs(currentSeasonData.players[playerName].penalties) do
                                    if existingPenalty.uniqueId == penalty.uniqueId then
                                        exists = true
                                        break
                                    end
                                end
                            else
                                currentSeasonData.players[playerName].penalties = {}
                            end
                            
                            if not exists then
                                table.insert(currentSeasonData.players[playerName].penalties, penalty)
                            end
                        end
                        
                        -- Recalculate total
                        currentSeasonData.players[playerName].totalAmount = 0
                        for _, penalty in ipairs(currentSeasonData.players[playerName].penalties) do
                            currentSeasonData.players[playerName].totalAmount = currentSeasonData.players[playerName].totalAmount + penalty.amount
                        end
                    end
                end
            end
            
            -- Save updated season data
            if RaidSanctions.Logic and RaidSanctions.Logic.SetSeasonData then
                RaidSanctions.Logic:SetSeasonData(currentSeasonData)
                table.insert(itemsUpdated, "Season Statistics")
            end
        end
    end
    
    -- Refresh all UI elements
    
    -- Debug: Check current session before refresh
    local sessionBeforeRefresh = RaidSanctions.Logic:GetCurrentSession()
    if sessionBeforeRefresh and sessionBeforeRefresh.players then
        local countBeforeRefresh = 0
        for name, data in pairs(sessionBeforeRefresh.players) do
            countBeforeRefresh = countBeforeRefresh + 1
        end
    else
    end
    
    self:RefreshPlayerList()
    
    if self.seasonStatsFrame and self.seasonStatsFrame:IsShown() then
        self:RefreshSeasonPlayerList()
    else
    end
    
    -- Refresh penalty buttons if penalty config was updated
    if syncData.penaltyConfig and next(syncData.penaltyConfig) then
        -- Recreate the bottom panel with new penalty amounts
        if mainFrame and mainFrame.bottomPanel then
            mainFrame.bottomPanel:Hide()
            mainFrame.bottomPanel:SetParent(nil)
            mainFrame.bottomPanel = nil
            self:CreateBottomPanel()
        end
        
        -- Refresh options window if open
        if self.optionsFrame and self.optionsFrame:IsShown() then
            self:RefreshOptionsAuthorization()
        end
    end
    
    -- Summary message
    if #itemsUpdated > 0 then
        local summary = "Sync complete! Updated: " .. table.concat(itemsUpdated, ", ") .. " from " .. syncData.sender .. "."
        print(summary)
    else
        print("Sync received from " .. syncData.sender .. " but no changes were needed.")
    end
end

function UI:Toggle()
    if not mainFrame then
        self:Initialize()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        -- Update data before showing
        RaidSanctions.Logic:UpdateRaidMembers()
        self:RefreshPlayerList() -- Update list before showing
        mainFrame:Show()
    end
end

function UI:Show()
    if not mainFrame then
        self:Initialize()
    end
    
    RaidSanctions.Logic:UpdateRaidMembers()
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
    
    -- Refresh authorization status when showing options
    self:RefreshOptionsAuthorization()
    
    -- Disable main frame buttons while options is open
    self:SetMainFrameButtonsEnabled(false)
    
    self.optionsFrame:Show()
end

function UI:ShowSeasonStatsWindow()
    if not self.seasonStatsFrame then
        self:CreateSeasonStatsWindow()
    end
    
    -- Update season data before showing to ensure it's current
    RaidSanctions.Logic:UpdateSeasonData()
    
    -- Disable main frame buttons while season stats is open
    self:SetMainFrameButtonsEnabled(false)
    
    self.seasonStatsFrame:Show()
end

function UI:CreateOptionsWindow()
    -- Create options frame
    local optionsFrame = CreateFrame("Frame", "RaidSanctionsOptionsFrame", mainFrame, "BackdropTemplate")
    optionsFrame:SetSize(500, 500) -- Increased from 400 to 500 for more content space
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
        -- Re-enable main frame buttons when closing
        UI:SetMainFrameButtonsEnabled(true)
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
    
    -- ESC key handler for options frame (only for this specific frame)
    optionsFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            -- Re-enable main frame buttons when closing with ESC
            UI:SetMainFrameButtonsEnabled(true)
        end
    end)
    
    optionsFrame:SetScript("OnShow", function(self)
        self:EnableKeyboard(true) -- Only capture ESC for this frame
        -- Start authorization monitoring when options window is shown
        UI:StartOptionsAuthorizationMonitoring()
    end)
    
    optionsFrame:SetScript("OnHide", function(self)
        self:EnableKeyboard(false)
        -- Stop authorization monitoring when options window is hidden
        UI:StopOptionsAuthorizationMonitoring()
        -- Re-enable main frame buttons when options is closed
        UI:SetMainFrameButtonsEnabled(true)
    end)
    
    -- Hidden by default
    optionsFrame:Hide()
    
    -- Store frame
    self.optionsFrame = optionsFrame
end

function UI:CreateSeasonStatsWindow()
    -- Create season stats frame
    local seasonStatsFrame = CreateFrame("Frame", "RaidSanctionsSeasonStatsFrame", mainFrame, "BackdropTemplate")
    seasonStatsFrame:SetSize(FRAME_WIDTH - 20, FRAME_HEIGHT - BOTTOM_PANEL_HEIGHT - 80) -- Leave more space for title and bottom panel
    seasonStatsFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -40) -- Start below title, inside main frame
    seasonStatsFrame:SetFrameStrata("HIGH")
    seasonStatsFrame:SetFrameLevel(200) -- Above main window
    
    -- Backdrop for season stats frame
    seasonStatsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    seasonStatsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    seasonStatsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Only enable mouse input (not movable)
    seasonStatsFrame:EnableMouse(true)
    
    -- Title for season stats frame
    local seasonStatsTitle = seasonStatsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    seasonStatsTitle:SetPoint("TOP", 0, -15)
    seasonStatsTitle:SetText("Season Statistics")
    seasonStatsTitle:SetTextColor(1, 0.8, 0)
    
    -- Close button for season stats frame
    local seasonStatsCloseButton = CreateFrame("Button", nil, seasonStatsFrame, "UIPanelCloseButton")
    seasonStatsCloseButton:SetPoint("TOPRIGHT", -5, -5)
    seasonStatsCloseButton:SetScript("OnClick", function()
        seasonStatsFrame:Hide()
        -- Re-enable main frame buttons when closing
        UI:SetMainFrameButtonsEnabled(true)
    end)
    
    -- Header row for column titles (same as main window)
    local headerFrame = CreateFrame("Frame", nil, seasonStatsFrame)
    headerFrame:SetSize(FRAME_WIDTH - 20, 25)
    headerFrame:SetPoint("TOPLEFT", 10, -50)
    
    -- Player name label
    local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameHeader:SetPoint("LEFT", 5, 0)
    nameHeader:SetText("Player")
    nameHeader:SetTextColor(0.8, 0.8, 0.8)
    nameHeader:SetWidth(200) -- Match main window width
    nameHeader:SetJustifyH("LEFT") -- Left aligned like main window
    
    -- Create penalty headers dynamically (match main window spacing)
    local xOffset = 210 -- Match main window starting position
    for reason, amount in pairs(Logic:GetPenalties()) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", xOffset, 0)
        header:SetText(reason)
        header:SetTextColor(0.8, 0.8, 0.8)
        header:SetWidth(100) -- Match main window width
        header:SetJustifyH("CENTER") -- Centered alignment like main window
        xOffset = xOffset + 110 -- Match main window spacing
    end
    
    -- Total header (positioned to match main window)
    local totalHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalHeader:SetPoint("LEFT", xOffset + 20, 0) -- Match main window position
    totalHeader:SetText("Total")
    totalHeader:SetTextColor(0.8, 0.8, 0.8)
    totalHeader:SetWidth(120) -- Match main window width
    totalHeader:SetJustifyH("CENTER") -- Centered alignment like main window
    
    -- Scroll container for player list (takes up most of the frame)
    local scrollFrame = CreateFrame("ScrollFrame", nil, seasonStatsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40) -- Leave space for clear button
    
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(FRAME_WIDTH - 50, 1) -- Height is adjusted dynamically
    scrollFrame:SetScrollChild(contentFrame)
    
    -- Clear Season Data button
    local clearButton = CreateFrame("Button", nil, seasonStatsFrame, "UIPanelButtonTemplate")
    clearButton:SetSize(150, 25)
    clearButton:SetPoint("BOTTOMRIGHT", -10, 10)
    clearButton:SetText("Clear Season Data")
    clearButton:SetScript("OnClick", function()
        StaticPopup_Show("RAIDSANCTIONS_CLEAR_SEASON_CONFIRM")
    end)
    
    -- Cleanup Random Players button
    local cleanupButton = CreateFrame("Button", nil, seasonStatsFrame, "UIPanelButtonTemplate")
    cleanupButton:SetSize(180, 25)
    cleanupButton:SetPoint("BOTTOMRIGHT", clearButton, "BOTTOMLEFT", -10, 0)
    cleanupButton:SetText("Cleanup Random (0g)")
    cleanupButton:GetFontString():SetTextColor(1, 0.8, 0.2) -- Gold color
    cleanupButton:SetScript("OnClick", function()
        StaticPopup_Show("RAIDSANCTIONS_CLEANUP_RANDOM_CONFIRM")
    end)
    
    -- Tooltip for cleanup button
    cleanupButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Cleanup Random Players")
        GameTooltip:AddLine("Removes all random players (non-guild) with 0 penalties from season data.", 1, 1, 1)
        GameTooltip:AddLine("Guild members are always kept regardless of penalty amount.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    cleanupButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Store references
    seasonStatsFrame.scrollFrame = scrollFrame
    seasonStatsFrame.contentFrame = contentFrame
    seasonStatsFrame.playerRows = {}
    
    -- ESC key handler for season stats frame (only for this specific frame)
    seasonStatsFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
            -- Re-enable main frame buttons when closing with ESC
            UI:SetMainFrameButtonsEnabled(true)
        end
    end)
    
    seasonStatsFrame:SetScript("OnShow", function(self)
        self:EnableKeyboard(true) -- Only capture ESC for this frame
        -- Refresh season data when showing
        UI:RefreshSeasonPlayerList()
    end)
    
    seasonStatsFrame:SetScript("OnHide", function(self)
        self:EnableKeyboard(false)
        -- Re-enable main frame buttons when season stats is closed
        UI:SetMainFrameButtonsEnabled(true)
    end)
    
    -- Hidden by default
    seasonStatsFrame:Hide()
    
    -- Store frame
    self.seasonStatsFrame = seasonStatsFrame
end

function UI:SetMainFrameButtonsEnabled(enabled)
    if not mainFrame then
        return
    end
    
    -- Store references to buttons that should be disabled when popups are open
    if not mainFrame.controllableButtons then
        mainFrame.controllableButtons = {}
        
        -- Find all buttons in main frame (except close button and child windows)
        local function findButtons(frame)
            if frame.GetObjectType and frame:GetObjectType() == "Button" then
                local name = frame:GetName()
                -- Don't disable close button, scroll bar buttons, and buttons in child windows
                if name ~= "RaidSanctionsMainFrameCloseButton" and 
                   not string.find(name or "", "ScrollBar") and
                   frame:GetParent() ~= self.optionsFrame and
                   frame:GetParent() ~= self.seasonStatsFrame then
                    -- Also check if the button is in the bottom panel or header (main UI elements)
                    local parent = frame:GetParent()
                    if parent == mainFrame or parent == mainFrame.bottomPanel then
                        table.insert(mainFrame.controllableButtons, frame)
                    end
                end
            end
            
            -- Check child frames, but skip options and season stats frames
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                if child ~= self.optionsFrame and child ~= self.seasonStatsFrame then
                    findButtons(child)
                end
            end
        end
        
        findButtons(mainFrame)
    end
    
    -- Enable/disable all controllable buttons (for popup windows)
    for _, button in ipairs(mainFrame.controllableButtons) do
        if button:IsObjectType("Button") then
            button:SetEnabled(enabled)
            if enabled then
                button:SetAlpha(1.0)
                -- Restore original colors when re-enabling
                self:RestoreButtonColors(button)
            else
                button:SetAlpha(0.5) -- Visual indication that button is disabled
            end
        end
    end
    
    -- Also disable/enable player row clicks
    for _, row in ipairs(playerRows) do
        if row:IsObjectType("Button") then
            row:SetEnabled(enabled)
            if enabled then
                row:SetAlpha(1.0)
            else
                row:SetAlpha(0.7)
            end
        end
    end
    
    -- Store the popup state so authorization system knows
    mainFrame.popupWindowOpen = not enabled
    
    -- Refresh authorization status to apply correct button states
    if enabled then
        local isAuthorized = self:IsPlayerAuthorized()
        self:SetToolbarButtonsEnabled(isAuthorized)
    end
end

function UI:SetToolbarButtonsEnabled(enabled)
    
    if not mainFrame or not mainFrame.bottomPanel then
        return
    end
    
    -- Don't override popup window state
    if mainFrame.popupWindowOpen then
        return
    end
    
    -- Store references to toolbar buttons that require authorization
    if not mainFrame.toolbarButtons then
        mainFrame.toolbarButtons = {}
        
        -- Find all buttons in bottom panel that require authorization
        local function findToolbarButtons(frame)
            if frame.GetObjectType and frame:GetObjectType() == "Button" then
                -- Get button text to identify which buttons need authorization
                local buttonText = frame:GetText()
                if buttonText then
                    -- These buttons require authorization
                    local restrictedButtons = {
                        "Wrong Gear", "Wrong Tactic", "Late", "Disruption", "AFK",
                        "Paid", "Post Stats in Raid Chat", "Sync Session", "-"
                    }
                    
                    for _, restrictedText in ipairs(restrictedButtons) do
                        if buttonText:find(restrictedText) then
                            table.insert(mainFrame.toolbarButtons, frame)
                            break
                        end
                    end
                end
            end
            
            -- Check child frames
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                findToolbarButtons(child)
            end
        end
        
        findToolbarButtons(mainFrame.bottomPanel)
    end
    
    -- Enable/disable toolbar buttons that require authorization
    for _, button in ipairs(mainFrame.toolbarButtons) do
        if button:IsObjectType("Button") then
            button:SetEnabled(enabled)
            if enabled then
                button:SetAlpha(1.0)
                self:RestoreButtonColors(button)
            else
                button:SetAlpha(0.4) -- More transparent when disabled
                button:GetFontString():SetTextColor(0.5, 0.5, 0.5) -- Gray out text
            end
        end
    end
end

function UI:RestoreButtonColors(button)
    -- Restore original text color based on button text
    local buttonText = button:GetText()
    if buttonText then
        if buttonText:find("Paid") then
            button:GetFontString():SetTextColor(0.2, 1, 0.2) -- Green
        elseif buttonText:find("Whisper Balance") then
            button:GetFontString():SetTextColor(0.8, 0.8, 1) -- Light blue
        elseif buttonText:find("Post Stats") then
            button:GetFontString():SetTextColor(1, 0.8, 0.2) -- Gold
        elseif buttonText:find("Sync Session") then
            button:GetFontString():SetTextColor(0.2, 1, 1) -- Cyan
        elseif buttonText == "-" then
            button:GetFontString():SetTextColor(1, 0.3, 0.3) -- Reddish for minus buttons
        else
            -- Penalty buttons (white text)
            button:GetFontString():SetTextColor(1, 1, 1) -- White text
        end
    end
end

function UI:CreatePenaltiesTabContent(content)
    -- Check authorization
    local isAuthorized = self:IsPlayerAuthorized()
    
    -- Title for penalties tab
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Penalty Settings")
    title:SetTextColor(1, 0.8, 0)
    
    -- Authorization status
    local authStatus = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    authStatus:SetPoint("TOP", title, "BOTTOM", 0, -5)
    if isAuthorized then
        authStatus:SetText("✓ Authorized - You can modify penalty settings")
        authStatus:SetTextColor(0.2, 1, 0.2) -- Green
    else
        authStatus:SetText("✗ Not Authorized - Only raid leaders/assistants can modify penalties")
        authStatus:SetTextColor(1, 0.2, 0.2) -- Red
    end
    
    -- Info text
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", authStatus, "BOTTOM", 0, -10)
    if isAuthorized then
        info:SetText("Customize penalty amounts (enter values in gold)")
        info:SetTextColor(0.8, 0.8, 0.8)
    else
        info:SetText("Current penalty amounts (read-only):")
        info:SetTextColor(0.6, 0.6, 0.6)
    end
    
    -- Create penalty input fields
    local yOffset = -85 -- Adjusted for additional status text
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
        
        -- Disable edit box if not authorized
        if not isAuthorized then
            editBox:SetEnabled(false)
            editBox:SetTextColor(0.5, 0.5, 0.5) -- Gray out text
        end
        
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
    
    if isAuthorized then
        saveButton:SetScript("OnClick", function()
            UI:SavePenaltySettings(editBoxes)
        end)
    else
        saveButton:SetEnabled(false)
        saveButton:GetFontString():SetTextColor(0.5, 0.5, 0.5) -- Gray out
    end
    
    -- Reset to defaults button
    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 30)
    resetButton:SetPoint("LEFT", saveButton, "RIGHT", 10, 0)
    resetButton:SetText("Reset to 1 Gold")
    resetButton:GetFontString():SetTextColor(1, 0.8, 0.2)
    
    if isAuthorized then
        resetButton:SetScript("OnClick", function()
            UI:ResetPenaltiesToDefault(editBoxes)
        end)
    else
        resetButton:SetEnabled(false)
        resetButton:GetFontString():SetTextColor(0.5, 0.5, 0.5) -- Gray out
    end
    
    -- Post to Raid button (this can be used by everyone to see current config)
    local postRaidButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    postRaidButton:SetSize(100, 30)
    postRaidButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    postRaidButton:SetText("Post to Raid")
    postRaidButton:GetFontString():SetTextColor(0.2, 0.8, 1) -- Light blue
    
    postRaidButton:SetScript("OnClick", function()
        UI:PostPenaltyConfigToRaid()
    end)
    
    postRaidButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Post penalty configuration to raid chat")
        GameTooltip:AddLine("Posts current penalty amounts to raid chat so everyone knows the rules.", 1, 1, 1)
        GameTooltip:Show()
    end)
    postRaidButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Help text
    local helpText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("TOPLEFT", 20, buttonY - 40)
    helpText:SetWidth(400)
    helpText:SetJustifyH("LEFT")
    if isAuthorized then
        helpText:SetText("Note: Changes take effect immediately and will update the UI.\nEnter values in whole gold amounts (e.g., 5 for 5 Gold).")
        helpText:SetTextColor(0.7, 0.7, 0.7)
    else
        helpText:SetText("You need raid leader or assistant permissions to modify penalty settings.\nYou can still view current settings and post them to raid chat.")
        helpText:SetTextColor(0.8, 0.4, 0.4) -- Reddish color for warning
    end
    
    -- Store references
    content.editBoxes = editBoxes
    content.saveButton = saveButton
    content.resetButton = resetButton
    content.authStatus = authStatus
    content.info = info
    content.helpText = helpText
end

function UI:RefreshOptionsAuthorization()
    -- Only refresh if options frame and penalties tab content exist
    if not self.optionsFrame or not self.optionsFrame.tabContents or not self.optionsFrame.tabContents[1] then
        return
    end
    
    local content = self.optionsFrame.tabContents[1] -- Penalties tab is index 1
    if not content.editBoxes then
        return
    end
    
    -- Check current authorization
    local isAuthorized = self:IsPlayerAuthorized()
    
    -- Update authorization status text
    if content.authStatus then
        if isAuthorized then
            content.authStatus:SetText("✓ Authorized - You can modify penalty settings")
            content.authStatus:SetTextColor(0.2, 1, 0.2) -- Green
        else
            content.authStatus:SetText("✗ Not Authorized - Only raid leaders/assistants can modify penalties")
            content.authStatus:SetTextColor(1, 0.2, 0.2) -- Red
        end
    end
    
    -- Update info text
    if content.info then
        if isAuthorized then
            content.info:SetText("Customize penalty amounts (enter values in gold)")
            content.info:SetTextColor(0.8, 0.8, 0.8)
        else
            content.info:SetText("Current penalty amounts (read-only):")
            content.info:SetTextColor(0.6, 0.6, 0.6)
        end
    end
    
    -- Update edit boxes
    for reason, editBox in pairs(content.editBoxes) do
        if isAuthorized then
            editBox:SetEnabled(true)
            editBox:SetTextColor(1, 1, 1) -- Normal white text
        else
            editBox:SetEnabled(false)
            editBox:SetTextColor(0.5, 0.5, 0.5) -- Gray out text
        end
    end
    
    -- Update save button
    if content.saveButton then
        if isAuthorized then
            content.saveButton:SetEnabled(true)
            content.saveButton:GetFontString():SetTextColor(0.2, 1, 0.2) -- Green
        else
            content.saveButton:SetEnabled(false)
            content.saveButton:GetFontString():SetTextColor(0.5, 0.5, 0.5) -- Gray out
        end
    end
    
    -- Update reset button
    if content.resetButton then
        if isAuthorized then
            content.resetButton:SetEnabled(true)
            content.resetButton:GetFontString():SetTextColor(1, 0.8, 0.2) -- Orange
        else
            content.resetButton:SetEnabled(false)
            content.resetButton:GetFontString():SetTextColor(0.5, 0.5, 0.5) -- Gray out
        end
    end
    
    -- Update help text
    if content.helpText then
        if isAuthorized then
            content.helpText:SetText("Note: Changes take effect immediately and will update the UI.\nEnter values in whole gold amounts (e.g., 5 for 5 Gold).")
            content.helpText:SetTextColor(0.7, 0.7, 0.7)
        else
            content.helpText:SetText("You need raid leader or assistant permissions to modify penalty settings.\nYou can still view current settings and post them to raid chat.")
            content.helpText:SetTextColor(0.8, 0.4, 0.4) -- Reddish color for warning
        end
    end
end

function UI:StartOptionsAuthorizationMonitoring()
    -- Create or reuse timer for authorization monitoring
    if not self.authMonitorTimer then
        self.authMonitorTimer = C_Timer.NewTicker(1.0, function() -- Check every second
            self:RefreshOptionsAuthorization()
        end)
    end
end

function UI:StopOptionsAuthorizationMonitoring()
    -- Stop the authorization monitoring timer
    if self.authMonitorTimer then
        self.authMonitorTimer:Cancel()
        self.authMonitorTimer = nil
    end
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

function UI:PostPenaltyConfigToRaid()
    -- Get current penalty configuration
    local penalties = Logic:GetPenalties()
    
    -- Check if we're in a raid or group
    if not IsInRaid() and not IsInGroup() then
        print("You must be in a raid or group to post penalty configuration.")
        return
    end
    
    -- Determine chat channel (raid takes priority over party)
    local chatChannel = IsInRaid() and "RAID" or "PARTY"
    
    -- Post header
    SendChatMessage("RaidSanctions - Current Penalty Configuration:", chatChannel)
    
    -- Sort penalties by label length (longest first) for better readability
    local sortedPenalties = {}
    for reason, amount in pairs(penalties) do
        table.insert(sortedPenalties, {reason = reason, amount = amount})
    end
    
    table.sort(sortedPenalties, function(a, b)
        -- Sort by label length first (longest first), then by amount if same length
        if string.len(a.reason) == string.len(b.reason) then
            return a.amount > b.amount
        else
            return string.len(a.reason) > string.len(b.reason)
        end
    end)
    
    -- Post each penalty configuration
    for _, penalty in ipairs(sortedPenalties) do
        local message = penalty.reason .. ": " .. Logic:FormatGold(penalty.amount)
        SendChatMessage(message, chatChannel)
    end
    
    print("Penalty configuration posted to " .. (IsInRaid() and "raid" or "party") .. " chat.")
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

StaticPopupDialogs["RAIDSANCTIONS_CLEAR_SEASON_CONFIRM"] = {
    text = "Clear all Season Statistics?\n\nThis will permanently delete all accumulated season data.",
    button1 = "Clear",
    button2 = "Cancel",
    OnAccept = function()
        RaidSanctions.Logic:ClearSeasonData()
        if RaidSanctions.UI and RaidSanctions.UI.RefreshSeasonPlayerList then
            RaidSanctions.UI:RefreshSeasonPlayerList()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["RAIDSANCTIONS_CLEANUP_RANDOM_CONFIRM"] = {
    text = "Cleanup Random Players with 0 penalties?\n\nThis will remove all non-guild players with 0 Gold from season data.\nGuild members will be kept regardless of penalty amount.",
    button1 = "Cleanup",
    button2 = "Cancel",
    OnAccept = function()
        RaidSanctions.Logic:CleanupSeasonDataRandomPlayers()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["RAIDSANCTIONS_SYNC_CONFIRM"] = {
    text = "Sync complete data from '%s'?\n\nThis will merge their session data, penalty settings, and season statistics with yours.\nExisting data will be preserved and combined.",
    button1 = "Accept",
    button2 = "Decline",
    OnAccept = function(self, data)
        
        -- In WoW StaticPopups, the extra data is stored in self.data
        local syncData = self.data
        if syncData then
            if syncData.sessionData and syncData.sessionData.players then
                local playerCount = 0
                for name, playerData in pairs(syncData.sessionData.players) do
                    playerCount = playerCount + 1
                end
            end
            UI:ApplySyncData(syncData)
        else
            print("ERROR: No sync data available in StaticPopup")
        end
    end,
    timeout = 30,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Export
RaidSanctions.UI = UI
