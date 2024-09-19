local BetterSoundOptions = LibStub("AceAddon-3.0"):NewAddon("BetterSoundOptions")

local defaultAvoidedMusicIDs = {}
local alreadyPlayedMusicIDs = {}

BetterSoundOptionsDB = BetterSoundOptionsDB or {
	settingsKeys = {}, avoidedMusicIDs = defaultAvoidedMusicIDs
}

local f = CreateFrame("Frame")
local MusicCD = time() - 121
local currentMusicID
local AutoMusicTimer

f:RegisterEvent("PET_BATTLE_CLOSE")
f:RegisterEvent("CINEMATIC_STOP")
f:RegisterEvent("SOUND_DEVICE_UPDATE")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("TALKINGHEAD_REQUESTED")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "PET_BATTLE_CLOSE" then
		C_Timer.After(0.1, function() BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType()) end)
	elseif event == "CINEMATIC_STOP" then
		C_Timer.After(0.1, function() BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType()) end)
	elseif event == "SOUND_DEVICE_UPDATE" then
		C_Timer.After(0.1, function() BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType()) end)
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		C_Timer.After(0.1, function() BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType()) end)
	elseif event == "ZONE_CHANGED" then
		C_Timer.After(0.1, function() BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType()) end)
	elseif event == "PLAYER_LOGIN" then
		BetterSoundOptionsDB.PreviousDialogueSetting = GetCVar("Sound_EnableDialog")
		C_Timer.After(0.1, function() BetterSoundOptions:UpdateWorld(BetterSoundOptions:GetProfileType()) end)
		if not BetterSoundOptionsDB.avoidedMusicIDs then
			BetterSoundOptionsDB.avoidedMusicIDs = {}
		end
	elseif event == "TALKINGHEAD_REQUESTED" then
		local inInstance, instanceType = IsInInstance()
		if inInstance and instanceType == "party" and BetterSoundOptionsDB.settingsKeys.dungeonDisableTH or BetterSoundOptionsDB.settingsKeys.alwaysDisableTH then
			BetterSoundOptions:CloseTalkingHead()
		end
	end
end)

local function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

SLASH_AVOIDMUSIC1 = '/avoid'
function SlashCmdList.AVOIDMUSIC(msg, editBox)
	if not currentMusicID then return end

	if msg == '' and currentMusicID then
		msg = currentMusicID
	end

	if not has_value(BetterSoundOptionsDB.avoidedMusicIDs, msg) then
		table.insert(BetterSoundOptionsDB.avoidedMusicIDs, msg)
		BetterSoundOptions:DebugText('Avoiding Music ID:', msg)
		if msg == currentMusicID then
			BetterSoundOptions:PlayRandomMusic()
		end
	else
		BetterSoundOptions:DebugText('Already avoided that Music ID.')
	end
end

SLASH_CLEARAVOIDMUSIC1 = '/clearavoid'
function SlashCmdList.CLEARAVOIDMUSIC(msg, editBox)
	if msg == 'yesdoitpleaseuwu' then
		BetterSoundOptionsDB.avoidedMusicIDs = defaultAvoidedMusicIDs
		BetterSoundOptions:DebugText('Cleared avoided Music ID lists')
	end
end

function BetterSoundOptions:CloseTalkingHead(self, evt, text, source, xtra)
	if BetterSoundOptionsDB.settingsKeys.debugText then
		local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead, textureKit =
			C_TalkingHead.GetCurrentLineInfo();
	end
	TalkingHeadFrame:PlayCurrent();
	TalkingHeadFrame:CloseImmediately();
end

function BetterSoundOptions:ToggleMainFrame()
	if not f:IsShown() then
		f:Show()
	else
		f:Hide()
	end
end

function BetterSoundOptions:PlayRandomMusic(music)
	if not music then
		music = BetterSoundOptions:random_elem(BetterSoundOptions.listfile_music)
	end

	BetterSoundOptions:DebugText('Now Playing Song ID:', music)

	if not has_value(BetterSoundOptionsDB.avoidedMusicIDs, music) and not has_value(alreadyPlayedMusicIDs, music) then
		PlayMusic(music)

		MusicCD = time()
		currentMusicID = music
		table.insert(alreadyPlayedMusicIDs, music)
		if BetterSoundOptionsDB.settingsKeys.autoMusicTimer then
			if AutoMusicTimer then
				AutoMusicTimer:Cancel()
			end
			if not GetCVarBool("Sound_EnableMusic") then return end
			AutoMusicTimer = C_Timer.NewTimer(60,
				function()
					BetterSoundOptions:DebugText(
						'Timer expired. Choosing a new song.'); BetterSoundOptions:PlayRandomMusic()
				end)
		end
	else
		BetterSoundOptions:DebugText('Avoided music detected, attempting to play something else:', music)

		BetterSoundOptions:PlayRandomMusic()
	end
end

function BetterSoundOptions:SetMusic()
	BetterSoundOptions:DebugText('Playing new random music.\nPrevious music ID: ', currentMusicID)

	local music = BetterSoundOptions:random_elem(BetterSoundOptions.listfile_music)

	BetterSoundOptions:PlayRandomMusic(music)
end

function BetterSoundOptions:random_elem(tb)
	local keys = {}
	for k, v in pairs(tb) do table.insert(keys, k) end
	return tb[keys[math.random(#keys)]]
end

function BetterSoundOptions:randFrom(t)
	local choice = "F"
	local n = 0
	for i, o in pairs(t) do
		n = n + 1
		if math.random() < (1 / n) then
			choice = o
		end
	end
	return choice
end

function BetterSoundOptions:UpdateWorld(pt, subzone)
	if InCinematic() then
		return
	end

	local inInstance, instanceType = IsInInstance()

	if inInstance and BetterSoundOptionsDB.settingsKeys.disableDialogue and instanceType == "party" then
		local mapID = C_Map.GetBestMapForUnit("player");
		local parentMapID = C_Map.GetMapInfo(C_Map.GetMapInfo(mapID).parentMapID)
		if not has_value(BetterSoundOptionsDB.settingsKeys.instancesVisited, parentMapID) then
			table.insert(BetterSoundOptionsDB.settingsKeys.instancesVisited, parentMapID)
		else
			BetterSoundOptionsDB.PreviousDialogueSetting = GetCVar("Sound_EnableDialog")
			SetCVar("Sound_EnableDialog", 0)
			BetterSoundOptions:DebugText('Previously entered dungeon detected. disabling dialogue.')
		end
	elseif not IsInInstance() and BetterSoundOptionsDB.settingsKeys.disableDialogue then
		SetCVar("Sound_EnableDialog", BetterSoundOptionsDB.PreviousDialogueSetting)
	end

	if (time() - MusicCD) > 30 and BetterSoundOptionsDB.settingsKeys.randomizeMusic and GetCVarBool("Sound_EnableMusic") then
		local music = BetterSoundOptions:randFrom(BetterSoundOptions.listfile_music)
		BetterSoundOptions:PlayRandomMusic(music)
	end
end

function BetterSoundOptions:GetInstanceType()
	if IsResting() then
		return "rest"
	end
	local _, v = GetInstanceInfo()
	return v;
end

function BetterSoundOptions:GetProfileType()
	local profile = self.db.profile
	local instance = self:GetInstanceType()
	if instance ~= "none" and profile["enable_" .. instance] then
		return instance;
	end
	return "none"
end

function BetterSoundOptions:DebugText(...)
	if BetterSoundOptionsDB.settingsKeys.debugText then
		print(OrangeText('BetterSoundOptions:'), ...)
	end
end
