local addon = LibStub("AceAddon-3.0"):GetAddon("BetterSoundOptions")

-- Constants
local CONSTANTS = {
    FRAME_WIDTH = 400,
    FRAME_HEIGHT = 400,
    TITLE_HEIGHT = 30,
    CHECKBOX_HEIGHT = 30,
    CHECKBOX_SPACING = -30,
    FRAME_PADDING = 10,
    TITLE_OFFSET = -3,
    MUSIC_BOX_ICON = "Interface/Icons/TRADE_ARCHAEOLOGY_DELICATEMUSICBOX"
}

-- Library references with error checking
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
local LibDataBroker = LibStub("LibDataBroker-1.1", true)
local AceDB = LibStub("AceDB-3.0", true)

if not LibDBIcon then
    error("BetterSoundOptions: LibDBIcon-1.0 is required but not found!")
end

if not LibDataBroker then
    error("BetterSoundOptions: LibDataBroker-1.1 is required but not found!")
end

if not AceDB then
    error("BetterSoundOptions: AceDB-3.0 is required but not found!")
end

-- Global reference for backwards compatibility
BetterSoundOptionsMinimapButton = LibDBIcon

-- Local state management
local settingsState = {
    checkboxCount = 0,
    createdCheckboxes = {},
    isInitialized = false
}

-- Settings configuration
local settingsConfig = {
    {
        settingText = "Randomize Music",
        settingKey = "randomizeMusic",
        settingTooltip = "While enabled, music will be randomized. Avoid music by using /avoid musicID",
        defaultValue = true,
    },
    {
        settingText = "Automatically change music after 3 minutes to prevent infinite loop",
        settingKey = "autoMusicTimer",
        settingTooltip = "While enabled, this addon will change music after 3 minutes to another random song.",
        defaultValue = true,
    },
    {
        settingText = "Disable Dialogue In Instances After First Visit",
        settingKey = "disableDialogue",
        settingTooltip = "While enabled, dialogue will be disabled after first visit of an instance. This will take effect after initial installation.",
        defaultValue = false,
    },
    {
        settingText = "Always close Talking Head dialogue",
        settingKey = "alwaysDisableTH",
        settingTooltip = "While enabled, this addon will always close talking head dialogues even outside of dungeons.",
        defaultValue = false,
    },
    {
        settingText = "Only close Talking Head dialogue in dungeons",
        settingKey = "dungeonDisableTH",
        settingTooltip = "While enabled, this addon will close talking head dialogues while inside of dungeons.",
        defaultValue = false,
    },
    {
        settingText = "Enable Debug Text",
        settingKey = "debugText",
        settingTooltip = "While enabled, debug text will display in chat to help diagnose errors.",
        defaultValue = true,
    },
}

-- Utility Functions
local function validateSetting(setting)
    return setting and
           setting.settingText and
           setting.settingKey and
           setting.settingTooltip and
           setting.defaultValue ~= nil
end

local function initializeSettingsDB()
    if not BetterSoundOptionsDB then
        BetterSoundOptionsDB = {}
    end

    if not BetterSoundOptionsDB.settingsKeys then
        BetterSoundOptionsDB.settingsKeys = {}
    end
end

local function getSettingValue(key, defaultValue)
    initializeSettingsDB()

    if BetterSoundOptionsDB.settingsKeys[key] == nil then
        BetterSoundOptionsDB.settingsKeys[key] = defaultValue
    end

    return BetterSoundOptionsDB.settingsKeys[key]
end

local function setSettingValue(key, value)
    initializeSettingsDB()
    BetterSoundOptionsDB.settingsKeys[key] = value
end

-- UI Creation Functions
local function createMainSettingsFrame()
    local frame = CreateFrame("Frame", "BetterSoundOptionsSettingsFrame", UIParent, "BasicFrameTemplateWithInset")

    if not frame then
        error("Failed to create settings frame")
        return nil
    end

    -- Frame properties
    frame:SetSize(CONSTANTS.FRAME_WIDTH, CONSTANTS.FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    -- Title configuration
    if frame.TitleBg then
        frame.TitleBg:SetHeight(CONSTANTS.TITLE_HEIGHT)
    end

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame.TitleBg or frame, "TOP", 0, CONSTANTS.TITLE_OFFSET)
    frame.title:SetText("Better Sound Options by Smokey")

    -- Drag functionality
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    return frame
end

local function createCheckbox(parent, setting, index)
    if not validateSetting(setting) then
        error("Invalid setting configuration provided")
        return nil
    end

    local checkboxName = "BetterSoundOptionsCheckbox_" .. setting.settingKey
    local checkbox = CreateFrame("CheckButton", checkboxName, parent, "UICheckButtonTemplate")

    if not checkbox then
        error("Failed to create checkbox for setting: " .. setting.settingKey)
        return nil
    end

    -- Position the checkbox
    local yOffset = -CONSTANTS.CHECKBOX_HEIGHT + (index * CONSTANTS.CHECKBOX_SPACING)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", CONSTANTS.FRAME_PADDING, yOffset)

    -- Set checkbox text
    if checkbox.Text then
        checkbox.Text:SetText(setting.settingText)
    end

    -- Initialize and set checkbox state
    local currentValue = getSettingValue(setting.settingKey, setting.defaultValue)
    checkbox:SetChecked(currentValue)

    -- Tooltip functionality
    checkbox:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(setting.settingTooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end
    end)

    checkbox:SetScript("OnLeave", function(self)
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    -- Click handler
    checkbox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        setSettingValue(setting.settingKey, isChecked)

        -- Handle conflicting settings
        if setting.settingKey == "alwaysDisableTH" and isChecked then
            setSettingValue("dungeonDisableTH", false)
            local dungeonCheckbox = settingsState.createdCheckboxes["dungeonDisableTH"]
            if dungeonCheckbox then
                dungeonCheckbox:SetChecked(false)
            end
        elseif setting.settingKey == "dungeonDisableTH" and isChecked then
            setSettingValue("alwaysDisableTH", false)
            local alwaysCheckbox = settingsState.createdCheckboxes["alwaysDisableTH"]
            if alwaysCheckbox then
                alwaysCheckbox:SetChecked(false)
            end
        end
    end)

    -- Store reference for later access
    settingsState.createdCheckboxes[setting.settingKey] = checkbox

    return checkbox
end

local function createAllCheckboxes(parent)
    if not parent then
        error("Parent frame required for creating checkboxes")
        return
    end

    for index, setting in ipairs(settingsConfig) do
        local checkbox = createCheckbox(parent, setting, index)
        if checkbox then
            settingsState.checkboxCount = settingsState.checkboxCount + 1
        end
    end
end

-- Minimap Button Functions
local function handleMinimapButtonClick(self, button)
    if button == "LeftButton" then
        if addon and addon.SetMusic and getSettingValue("randomizeMusic", true) then
            addon:SetMusic()
        end
    elseif button == "RightButton" then
        local frame = _G["BetterSoundOptionsSettingsFrame"]
        if frame then
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end
end

local function showMinimapTooltip(tooltip)
    if not tooltip or not tooltip.AddLine then
        return
    end

    tooltip:AddLine("BetterSoundOptions")
    tooltip:AddLine(" ")
    tooltip:AddLine("|cffFFFFFFLeft-click:|r Change random music (if enabled)")
    tooltip:AddLine("|cffFFFFFFRight-click:|r Open settings")
end

local function createMinimapButton()
    if not LibDataBroker then
        error("LibDataBroker not available for minimap button creation")
        return nil
    end

    local dataObject = LibDataBroker:NewDataObject("BetterSoundOptions", {
        type = "data source",
        text = "BetterSoundOptions",
        icon = CONSTANTS.MUSIC_BOX_ICON,
        OnClick = handleMinimapButtonClick,
        OnTooltipShow = showMinimapTooltip,
    })

    return dataObject
end

-- Event Handling
local function handlePlayerLogin()
    if settingsState.isInitialized then
        return
    end

    initializeSettingsDB()

    -- Create main settings frame
    local settingsFrame = createMainSettingsFrame()
    if settingsFrame then
        createAllCheckboxes(settingsFrame)
        settingsState.isInitialized = true
    end
end

-- Event Listener Setup
local function initializeEventListener()
    local eventFrame = CreateFrame("Frame", "BetterSoundOptionsSettingsEventListener", UIParent)

    if not eventFrame then
        error("Failed to create event listener frame")
        return
    end

    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            handlePlayerLogin()
        end
    end)

    return eventFrame
end

-- Addon Integration
function addon:OnInitialize()
    if not AceDB then
        error("AceDB not available for addon initialization")
        return
    end

    -- Initialize database
    self.db = AceDB:New("BetterSoundOptionsMinimapPOS", {
        profile = {
            minimap = {
                hide = false,
            },
        },
    })

    -- Create and register minimap button
    local minimapButton = createMinimapButton()
    if minimapButton and LibDBIcon then
        LibDBIcon:Register("BetterSoundOptions", minimapButton, self.db.profile.minimap)
        LibDBIcon:Show("BetterSoundOptions")
    end
end

-- Cleanup function
function addon:OnDisable()
    -- Hide settings frame if shown
    local frame = _G["BetterSoundOptionsSettingsFrame"]
    if frame and frame:IsShown() then
        frame:Hide()
    end

    -- Hide minimap button
    if LibDBIcon then
        LibDBIcon:Hide("BetterSoundOptions")
    end
end

-- Public API for external access
addon.SettingsAPI = {
    GetSetting = function(key)
        return getSettingValue(key, false)
    end,

    SetSetting = function(key, value)
        setSettingValue(key, value)

        -- Update checkbox if it exists
        local checkbox = settingsState.createdCheckboxes[key]
        if checkbox then
            checkbox:SetChecked(value)
        end
    end,

    ToggleSettingsFrame = function()
        local frame = _G["BetterSoundOptionsSettingsFrame"]
        if frame then
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end,

    RefreshSettings = function()
        for key, checkbox in pairs(settingsState.createdCheckboxes) do
            local currentValue = getSettingValue(key, false)
            checkbox:SetChecked(currentValue)
        end
    end
}

-- Initialize the event listener
initializeEventListener()