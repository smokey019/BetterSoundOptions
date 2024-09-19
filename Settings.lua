local addon = LibStub("AceAddon-3.0"):GetAddon("BetterSoundOptions")
BetterSoundOptionsMinimapButton = LibStub("LibDBIcon-1.0", true)

local checkboxes = 0

local settings = {
	{
		settingText = "Randomize Music",
		settingKey = "randomizeMusic",
		settingTooltip = "While enabled, music will be ranzomized. Avoid music by using /avoid musicID",
		checked = true,
	},
	{
		settingText = "Automatically change music after 3 minutes to prevent infinite loop.",
		settingKey = "autoMusicTimer",
		settingTooltip =
		"While enabled, this addon will change music after 3 minutes to another random song.",
		checked = true,
	},
	{
		settingText = "Disable Dialogue In Instances After First Visit",
		settingKey = "disableDialogue",
		settingTooltip =
		"While enabled, dialogue will be disabled after first visit of an instance.  This will take effect after initial installation.",
		checked = false,
	},
	{
		settingText = "Always close Talking Head dialogue.",
		settingKey = "alwaysDisableTH",
		settingTooltip =
		"While enabled, this addon will always close talking head dialogues even outside of dungeons.",
		checked = false,
	},
	{
		settingText = "Only close Talking Head dialogue in dungeons.",
		settingKey = "dungeonDisableTH",
		settingTooltip =
		"While enabled, this addon will close talking head dialogues while inside of dungeons.",
		checked = false,
	},
	{
		settingText = "Enable Debug Text",
		settingKey = "debugText",
		settingTooltip = "While enabled, debug text will display in chat to help diagnose errors.",
		checked = true,
	},
}

local settingsFrame = CreateFrame("Frame", "BetterSoundOptionsSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetSize(400, 400)
settingsFrame:SetPoint("CENTER")
settingsFrame.TitleBg:SetHeight(30)
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsFrame.title:SetPoint("TOP", settingsFrame.TitleBg, "TOP", 0, -3)
settingsFrame.title:SetText("Better Sound Options by Smokey")
settingsFrame:Hide()
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)

settingsFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

local function CreateCheckbox(checkboxText, key, checkboxTooltip, checked)
	local checkbox = CreateFrame("CheckButton", "BetterSoundOptionsCheckboxID" .. checkboxes, settingsFrame,
		"UICheckButtonTemplate")
	checkbox.Text:SetText(checkboxText)
	checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30 + (checkboxes * -30))

	if BetterSoundOptionsDB.settingsKeys[key] == nil then
		BetterSoundOptionsDB.settingsKeys[key] = checked
	end

	checkbox:SetChecked(BetterSoundOptionsDB.settingsKeys[key])

	checkbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(checkboxTooltip, nil, nil, nil, nil, true)
	end)

	checkbox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	checkbox:SetScript("OnClick", function(self)
		BetterSoundOptionsDB.settingsKeys[key] = self:GetChecked()
	end)

	checkboxes = checkboxes + 1

	return checkbox
end

local eventListenerFrame = CreateFrame("Frame", "BetterSoundOptionsSettingsEventListenerFrame", UIParent)

eventListenerFrame:RegisterEvent("PLAYER_LOGIN")

eventListenerFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		if not BetterSoundOptionsDB.settingsKeys then
			BetterSoundOptionsDB.settingsKeys = {}
		end

		for _, setting in pairs(settings) do
			CreateCheckbox(setting.settingText, setting.settingKey, setting.settingTooltip, setting.checked)
		end
	end
end)

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("BetterSoundOptions", {
	type = "data source",
	text = "BetterSoundOptions",
	icon = "Interface/Icons/TRADE_ARCHAEOLOGY_DELICATEMUSICBOX",
	OnClick = function(self, btn)
		if btn == "LeftButton" and BetterSoundOptionsDB.settingsKeys.randomizeMusic then
			addon:SetMusic()
		elseif btn == "RightButton" then
			if settingsFrame:IsShown() then
				settingsFrame:Hide()
			else
				settingsFrame:Show()
			end
		end
	end,

	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end

		tooltip:AddLine(
			"BetterSoundOptions\n\nLeft-click: Change random music (if enabled). \nRight-click: Open Better Sound Options Settings",
			nil,
			nil, nil, nil)
	end,
})

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("BetterSoundOptionsMinimapPOS", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	BetterSoundOptionsMinimapButton:Register("BetterSoundOptions", miniButton, self.db.profile.minimap)
end

BetterSoundOptionsMinimapButton:Show("BetterSoundOptions")
