local BetterSoundOptions = LibStub("AceAddon-3.0"):NewAddon("BetterSoundOptions")

-- Constants
local CONSTANTS = {
	MUSIC_COOLDOWN_INITIAL = 121,
	MUSIC_COOLDOWN_THRESHOLD = 30,
	AUTO_MUSIC_TIMER_DURATION = 60,
	EVENT_DELAY = 0.1,
	MAX_PLAYED_MUSIC_HISTORY = 100, -- Prevent memory bloat!
}

-- Local variables
local defaultAvoidedMusicIDs = {}
local alreadyPlayedMusicIDs = {}
local eventFrame = CreateFrame("Frame")
local musicCooldown = time() - CONSTANTS.MUSIC_COOLDOWN_INITIAL
local currentMusicID
local autoMusicTimer

-- Initialize database with proper structure
BetterSoundOptionsDB = BetterSoundOptionsDB or {
	settingsKeys = {
		debugText = false,
		randomizeMusic = false,
		autoMusicTimer = false,
		disableDialogue = false,
		dungeonDisableTH = false,
		alwaysDisableTH = false,
		instancesVisited = {}
	},
	avoidedMusicIDs = defaultAvoidedMusicIDs,
	PreviousDialogueSetting = nil
}

-- Utility Functions
local function validateMusicID(musicID)
	return musicID and type(musicID) == "string" and musicID ~= ""
end

local function hasValue(table, value)
	if not table or not value then return false end

	for _, tableValue in ipairs(table) do
		if tableValue == value then
			return true
		end
	end
	return false
end

local function manageMusicHistory()
	if #alreadyPlayedMusicIDs > CONSTANTS.MAX_PLAYED_MUSIC_HISTORY then
		-- Remove oldest entries to prevent memory bloat
		local removeCount = #alreadyPlayedMusicIDs - CONSTANTS.MAX_PLAYED_MUSIC_HISTORY
		for i = 1, removeCount do
			table.remove(alreadyPlayedMusicIDs, 1)
		end
	end
end

local function updateWorldDelayed()
	C_Timer.After(CONSTANTS.EVENT_DELAY, function()
		BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType())
	end)
end

-- Event Handlers
local eventHandlers = {
	["PET_BATTLE_CLOSE"] = updateWorldDelayed,
	["CINEMATIC_STOP"] = updateWorldDelayed,
	["SOUND_DEVICE_UPDATE"] = updateWorldDelayed,
	["ZONE_CHANGED_NEW_AREA"] = updateWorldDelayed,
	["ZONE_CHANGED"] = updateWorldDelayed,

	["PLAYER_LOGIN"] = function()
		-- Initialize dialogue setting
		BetterSoundOptionsDB.PreviousDialogueSetting = GetCVar("Sound_EnableDialog")

		-- Ensure avoided music IDs table exists
		if not BetterSoundOptionsDB.avoidedMusicIDs then
			BetterSoundOptionsDB.avoidedMusicIDs = {}
		end

		-- Ensure settings keys are initialized
		if not BetterSoundOptionsDB.settingsKeys.instancesVisited then
			BetterSoundOptionsDB.settingsKeys.instancesVisited = {}
		end

		updateWorldDelayed()
	end,

	["TALKINGHEAD_REQUESTED"] = function()
		local inInstance, instanceType = IsInInstance()
		local shouldDisable = (inInstance and instanceType == "party" and BetterSoundOptionsDB.settingsKeys.dungeonDisableTH)
			or BetterSoundOptionsDB.settingsKeys.alwaysDisableTH

		if shouldDisable then
			BetterSoundOptions:CloseTalkingHead()
		end
	end
}

-- Register events and set up event handling
for event, _ in pairs(eventHandlers) do
	eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	local handler = eventHandlers[event]
	if handler then
		handler(...)
	end
end)

-- Slash Commands
SLASH_AVOIDMUSIC1 = '/avoid'
function SlashCmdList.AVOIDMUSIC(msg, editBox)
	if not currentMusicID then
		BetterSoundOptions:DebugText('No current music playing to avoid.')
		return
	end

	local musicID = (msg == '') and currentMusicID or msg

	if not validateMusicID(musicID) then
		BetterSoundOptions:DebugText('Invalid music ID provided.')
		return
	end

	if not hasValue(BetterSoundOptionsDB.avoidedMusicIDs, musicID) then
		table.insert(BetterSoundOptionsDB.avoidedMusicIDs, musicID)
		BetterSoundOptions:DebugText('Avoiding Music ID:', musicID)

		if musicID == currentMusicID then
			BetterSoundOptions:PlayRandomMusic()
		end
	else
		BetterSoundOptions:DebugText('Music ID already in avoided list.')
	end
end

SLASH_CLEARAVOIDMUSIC1 = '/clearavoid'
function SlashCmdList.CLEARAVOIDMUSIC(msg, editBox)
	if msg == 'yesdoitpleaseuwu' then
		BetterSoundOptionsDB.avoidedMusicIDs = {}
		BetterSoundOptions:DebugText('Cleared avoided music ID list')
	else
		BetterSoundOptions:DebugText('Use "/clearavoid yesdoitpleaseuwu" to confirm clearing the avoided music list.')
	end
end

-- Core Functions
function BetterSoundOptions:CloseTalkingHead()
	if not TalkingHeadFrame then return end

	if BetterSoundOptionsDB.settingsKeys.debugText then
		local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead, textureKit =
			C_TalkingHead.GetCurrentLineInfo()
		self:DebugText('Closing talking head:', name or 'Unknown')
	end

	TalkingHeadFrame:PlayCurrent()
	TalkingHeadFrame:CloseImmediately()
end

function BetterSoundOptions:ToggleMainFrame()
	if eventFrame:IsShown() then
		eventFrame:Hide()
	else
		eventFrame:Show()
	end
end

function BetterSoundOptions:PlayRandomMusic(musicID)
	if not musicID then
		if not self.listfile_music then
			self:DebugText('No music list available.')
			return
		end
		musicID = self:GetRandomElement(self.listfile_music)
	end

	if not validateMusicID(musicID) then
		self:DebugText('Invalid music ID, cannot play.')
		return
	end

	self:DebugText('Attempting to play Song ID:', musicID)

	-- Check if music should be avoided or was recently played
	if hasValue(BetterSoundOptionsDB.avoidedMusicIDs, musicID) or
		hasValue(alreadyPlayedMusicIDs, musicID) then
		self:DebugText('Music avoided or recently played, selecting alternative:', musicID)
		self:PlayRandomMusic() -- Recursively find alternative
		return
	end

	-- Play the music
	PlayMusic(musicID)
	musicCooldown = time()
	currentMusicID = musicID

	-- Track played music and manage history
	table.insert(alreadyPlayedMusicIDs, musicID)
	manageMusicHistory()

	-- Set up auto music timer if enabled
	if BetterSoundOptionsDB.settingsKeys.autoMusicTimer then
		if autoMusicTimer then
			autoMusicTimer:Cancel()
		end

		if GetCVarBool("Sound_EnableMusic") then
			autoMusicTimer = C_Timer.NewTimer(CONSTANTS.AUTO_MUSIC_TIMER_DURATION, function()
				self:DebugText('Auto music timer expired, selecting new song.')
				self:PlayRandomMusic()
			end)
		end
	end
end

function BetterSoundOptions:SetMusic()
	self:DebugText('Playing new random music. Previous music ID:', currentMusicID)

	if not self.listfile_music then
		self:DebugText('No music list available.')
		return
	end

	local musicID = self:GetRandomElement(self.listfile_music)
	self:PlayRandomMusic(musicID)
end

function BetterSoundOptions:GetRandomElement(table)
	if not table or type(table) ~= "table" then return nil end

	local keys = {}
	for key, _ in pairs(table) do
		table.insert(keys, key)
	end

	if #keys == 0 then return nil end

	return table[keys[math.random(#keys)]]
end

function BetterSoundOptions:SelectRandomFromTable(inputTable)
	if not inputTable or type(inputTable) ~= "table" then return nil end

	local choice = nil
	local count = 0

	for _, value in pairs(inputTable) do
		count = count + 1
		if math.random() < (1 / count) then
			choice = value
		end
	end

	return choice
end

function BetterSoundOptions:UpdateWorld(profileType, subzone)
	if InCinematic() then return end

	local inInstance, instanceType = IsInInstance()

	-- Handle dialogue settings for instances
	if inInstance and instanceType == "party" and BetterSoundOptionsDB.settingsKeys.disableDialogue then
		local mapID = C_Map.GetBestMapForUnit("player")
		if mapID then
			local mapInfo = C_Map.GetMapInfo(mapID)
			if mapInfo and mapInfo.parentMapID then
				local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)

				if parentMapInfo and not hasValue(BetterSoundOptionsDB.settingsKeys.instancesVisited, parentMapInfo.name) then
					table.insert(BetterSoundOptionsDB.settingsKeys.instancesVisited, parentMapInfo.name)
					self:DebugText('First visit to dungeon:', parentMapInfo.name)
				else
					-- Previously visited dungeon, disable dialogue
					BetterSoundOptionsDB.PreviousDialogueSetting = GetCVar("Sound_EnableDialog")
					SetCVar("Sound_EnableDialog", 0)
					self:DebugText('Previously visited dungeon detected, disabling dialogue.')
				end
			end
		end
	elseif not inInstance and BetterSoundOptionsDB.settingsKeys.disableDialogue and BetterSoundOptionsDB.PreviousDialogueSetting then
		SetCVar("Sound_EnableDialog", BetterSoundOptionsDB.PreviousDialogueSetting)
		self:DebugText('Left instance, restoring dialogue setting.')
	end

	-- Handle music randomization
	local timeSinceLastMusic = time() - musicCooldown
	if timeSinceLastMusic > CONSTANTS.MUSIC_COOLDOWN_THRESHOLD and
		BetterSoundOptionsDB.settingsKeys.randomizeMusic and
		GetCVarBool("Sound_EnableMusic") then
		if self.listfile_music then
			local musicID = self:SelectRandomFromTable(self.listfile_music)
			self:PlayRandomMusic(musicID)
		end
	end
end

function BetterSoundOptions:GetInstanceType()
	if IsResting() then
		return "rest"
	end

	local _, instanceType = GetInstanceInfo()
	return instanceType or "none"
end

function BetterSoundOptions:GetProfileType()
	if not self.db or not self.db.profile then
		return "none"
	end

	local profile = self.db.profile
	local instanceType = self:GetInstanceType()

	if instanceType ~= "none" and profile["enable_" .. instanceType] then
		return instanceType
	end

	return "none"
end

function BetterSoundOptions:DebugText(...)
	if BetterSoundOptionsDB.settingsKeys.debugText then
		local args = { ... }
		local message = ""

		for i, arg in ipairs(args) do
			if i > 1 then message = message .. " " end
			message = message .. tostring(arg)
		end

		print("|cffff8000BetterSoundOptions:|r", message)
	end
end

-- Cleanup function for proper addon lifecycle management
function BetterSoundOptions:OnDisable()
	if autoMusicTimer then
		autoMusicTimer:Cancel()
		autoMusicTimer = nil
	end
end
