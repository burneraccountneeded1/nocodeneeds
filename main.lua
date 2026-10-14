local StarterGui = game:GetService("StarterGui")

local LobbyPlaceId = 18186775539
local MainPlaceId = 77614252294790

local GameUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/game.lua"
local LobbyUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/lobby.lua"

local ScriptUrls = {
	[MainPlaceId] = GameUrl,
	[LobbyPlaceId] = LobbyUrl,
}

local ScriptNames = {
	[MainPlaceId] = "game.lua (main game)",
	[LobbyPlaceId] = "lobby.lua (lobby)",
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

local function runForPlace()
	local url = ScriptUrls[game.PlaceId]
	if not url then
		notify("No script mapped for place id " .. tostring(game.PlaceId) .. ", nothing to load")
		return
	end

	local label = ScriptNames[game.PlaceId] or "script"
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
