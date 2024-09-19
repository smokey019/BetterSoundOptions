--[[
	Let's do some functions shall we?

	This will help clean things up and what-not. No more clutter!
	++01/16/2011
--]]

function TextureIcon(arg1)
	return format("|T%s:15:15:0:0|t", type(arg1) == "number" and C_Item.GetItemIconByID(arg1) or arg1)
end

function PurpleText(text)
	if (text) then
		return "|cffa335ee" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function OrangeText(text)
	if (text) then
		return "|cffff8000" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function GreyText(text)
	if (text) then
		return "|cff9d9d9d" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function GreenText(text)
	if (text) then
		return "|cff00ff00" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function RedText(text)
	if (text) then
		return "|cffff0000" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function BlueText(text)
	if (text) then
		return "|cff0000ff" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function GetHighText(text)
	if (text) then
		return "|cffffffff" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function GoldText(text)
	if (text) then
		return "|cffffd700" .. text .. _G["FONT_COLOR_CODE_CLOSE"]
	end
end

function NormalText(text)
	if (text) then
		return _G["NORMAL_FONT_COLOR_CODE"] .. text .. _G["FONT_COLOR_CODE_CLOSE"];
	end
end

function ColoredText(text, color)
	if (text and color) then
		local redColorCode = format("%02x", color.r * 255);
		local greenColorCode = format("%02x", color.g * 255);
		local blueColorCode = format("%02x", color.b * 255);
		local colorCode = "|cff" .. redColorCode .. greenColorCode .. blueColorCode;
		return colorCode .. text .. _G["FONT_COLOR_CODE_CLOSE"];
	end
end

function Should_I_Be_Red(text)
	if (text == "N/A") then
		return GreenText(text)
	elseif (tonumber(text)) then
		if (tonumber(format("%d", text)) <= 0) then
			return RedText(text)
		else
			return GreenText(text)
		end
	end
end

function SiUnits(value)
	if (not value or value == 0) then
		return 0
	elseif (value >= 10 ^ 6) then
		return ("%.1fm"):format(value / 10 ^ 6)
	elseif (value >= 10 ^ 3) then
		return ("%.1fk"):format(value / 10 ^ 3)
	else
		return value
	end
end

function FormatNumber(amount)
	local formatted = amount
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break
		end
	end
	return formatted
end
