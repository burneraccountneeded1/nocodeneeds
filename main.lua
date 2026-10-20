local StarterGui = game:GetService("StarterGui")

local LobbyPlaceId = 18186775539
local MainPlaceId = 77614252294790
local VerPlaceId = 134208374070897
local VelocityPlaceId = 117314306495532

local GameUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/game.lua"
local LobbyUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/lobby.lua"
local UniversalUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/universal.lua"
local StatusUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/STATUS.txt"

local ScriptUrls = {
	[MainPlaceId] = GameUrl,
	[LobbyPlaceId] = LobbyUrl,
	[VerPlaceId] = GameUrl,
	[VelocityPlaceId] = GameUrl,
}

local ScriptNames = {
	[MainPlaceId] = "game.lua (main game)",
	[LobbyPlaceId] = "lobby.lua (lobby)",
	[VerPlaceId] = "game.lua (VER place)",
	[VelocityPlaceId] = "game.lua (velocity place)",
}

local function notify(message)
	print("[loader] " .. message)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Loader",
			Text = message,
			Duration = 3,
		})
	end)
end

local function readStatus()
	local ok, raw = pcall(function()
		return game:HttpGet(StatusUrl)
	end)
	if not ok or not raw then
		return "UNKNOWN"
	end

	return string.upper(string.match(raw, "^%s*(%a+)") or "")
end

local function runForPlace()
	local url = ScriptUrls[game.PlaceId] or UniversalUrl
	local label = ScriptNames[game.PlaceId] or "universal.lua (unsupported place)"

	local status = readStatus()
	if status == "BROKEN" then
		local message = "Script is marked BROKEN in STATUS.txt - not loading. Please wait for a fix."
		print("[loader] " .. message)
		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "SCRIPT BROKEN",
				Text = message,
				Duration = 15,
			})
		end)
		return
	end

	notify(string.format("Status: %s", status))
	notify(string.format("Place %d - loading %s", game.PlaceId, label))
	notify("Fetching " .. url)

	local source
	local ok, err = pcall(function()
		source = game:HttpGet(url)
	end)
	if not ok then
		notify("Fetch failed for " .. label .. ": " .. tostring(err))
		return
	end

	notify(string.format("Fetched %s (%d bytes) - executing", label, #source))

	local startedAt = os.clock()

	local ran, runErr = pcall(function()
		local chunk, compileErr = loadstring(source)
		if not chunk then
			error("loadstring failed: " .. tostring(compileErr))
		end
		chunk()
	end)
	if not ran then
		notify("Run failed for " .. label .. ": " .. tostring(runErr))
		return
	end

	notify(string.format("%s loaded in %.2fs", label, os.clock() - startedAt))
end

-- This loader does NOT queue itself: it only runs when executed directly, or when
-- game.lua's "Execute on Teleport" toggle queues it.
runForPlace()
