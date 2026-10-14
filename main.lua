local LobbyPlaceId = 18186775539
local MainPlaceId = 77614252294790

local EspUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/esp.lua"
local LobbyUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/lobby.lua"

local ScriptUrls = {
	[MainPlaceId] = EspUrl,
	[LobbyPlaceId] = LobbyUrl,
}

local function runForPlace()
	local url = ScriptUrls[game.PlaceId]
	if not url then
		warn("[loader] No script mapped for place id " .. tostring(game.PlaceId))
		return
	end

	local ok, err = pcall(function()
		loadstring(game:HttpGet(url))()
	end)

	if not ok then
		warn("[loader] Failed to load " .. url .. ": " .. tostring(err))
	end
end

runForPlace()

-- After a teleport (new session, new place id) re-run the matching script.
if type(queue_on_teleport) == "function" then
	local reloadScript = string.format([[
		local urls = {
			[%d] = %q,
			[%d] = %q,
		}
		local url = urls[game.PlaceId]
		if url then
			pcall(function()
				loadstring(game:HttpGet(url))()
			end)
		end
	]], MainPlaceId, EspUrl, LobbyPlaceId, LobbyUrl)

	pcall(queue_on_teleport, reloadScript)
end
