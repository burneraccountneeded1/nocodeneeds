local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Places this script talks to
local LobbyPlaceId = 18186775539
local MainPlaceId = 77614252294790

local Window = Library:CreateWindow({
	Title = "mspaint",
	Footer = "lobby",
	Icon = 95816097006870,
	NotifySide = "Right",
})

local Tabs = {
	Lobby = Window:AddTab("Lobby", "building"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- =========================================================
-- Logic
-- =========================================================

local joinQueued = false

local function getElevatorEvent()
	local events = ReplicatedStorage:FindFirstChild("Events")
	local elevatorEvents = events and events:FindFirstChild("ElevatorEvents")
	return elevatorEvents and elevatorEvents:FindFirstChild("RequestElevatorCreation")
end

local function joinMainGame()
	if joinQueued then
		return
	end

	joinQueued = true

	local ok, err = pcall(function()
		TeleportService:Teleport(MainPlaceId)
	end)

	if not ok then
		joinQueued = false
		Library:Notify({
			Title = "Join",
			Description = "Teleport failed: " .. tostring(err),
			Icon = "triangle-alert",
			Time = 6,
		})
	end
end

local function createElevator()
	local event = getElevatorEvent()
	if not event then
		Library:Notify({
			Title = "Elevator",
			Description = "RequestElevatorCreation remote not found.",
			Icon = "triangle-alert",
			Time = 6,
		})
		return
	end

	local payload = {
		AdminPanel = Toggles.ElevatorAdminPanel.Value,
		Floor = Options.ElevatorFloor.Value,
		StageName = Options.ElevatorStage.Value,
		FloorBackground = Options.ElevatorBackground.Value,
		FriendsOnly = Toggles.ElevatorFriendsOnly.Value,
		MaxPlayers = Options.ElevatorMaxPlayers.Value,
	}

	local ok, result = pcall(function()
		return event:InvokeServer(payload)
	end)

	if not ok then
		Library:Notify({
			Title = "Elevator",
			Description = "Failed: " .. tostring(result),
			Icon = "triangle-alert",
			Time = 6,
		})
		return
	end

	Library:Notify({
		Title = "Elevator",
		Description = "Elevator creation requested.",
		Time = 5,
	})

	if Toggles.JoinAfterCreate.Value then
		joinMainGame()
	end
end

if game.PlaceId ~= LobbyPlaceId then
	Library:Notify({
		Title = "Lobby script",
		Description = "This script is meant for the lobby (place " .. LobbyPlaceId .. ").",
		Icon = "triangle-alert",
		Time = 6,
	})
end

Library:OnUnload(function()
	joinQueued = false
end)

-- =========================================================
-- Elevator creation
-- =========================================================

local ElevatorGroupbox = Tabs.Lobby:AddGroupbox({
	Side = "Left",
	Name = "Elevator",
	Description = "Create an elevator",
	IconName = "building",
})

ElevatorGroupbox:AddInput("ElevatorFloor", {
	Text = "Floor",
	Default = "Foundation",
	Finished = false,
})

ElevatorGroupbox:AddInput("ElevatorStage", {
	Text = "StageName",
	Default = "FoundationStage",
	Finished = false,
})

ElevatorGroupbox:AddInput("ElevatorBackground", {
	Text = "FloorBackground",
	Default = "rbxassetid://105796137903232",
	Finished = false,
})

ElevatorGroupbox:AddToggle("ElevatorFriendsOnly", {
	Text = "Friends Only",
	Default = true,
})

ElevatorGroupbox:AddSlider("ElevatorMaxPlayers", {
	Text = "Max Players",
	Default = 4,
	Min = 1,
	Max = 12,
	Rounding = 0,
})

ElevatorGroupbox:AddToggle("ElevatorAdminPanel", {
	Text = "Admin Panel",
	Default = false,
})

ElevatorGroupbox:AddDivider()

ElevatorGroupbox:AddToggle("JoinAfterCreate", {
	Text = "Join Main Game After Create",
	Default = false,
	Tooltip = "Teleports to the main game once the elevator is requested",
})

ElevatorGroupbox:AddButton({
	Text = "Create Elevator",
	Tooltip = "Invokes RequestElevatorCreation",
	Func = function()
		createElevator()
	end,
})

-- =========================================================
-- Game
-- =========================================================

local GameGroupbox = Tabs.Lobby:AddGroupbox({
	Side = "Right",
	Name = "Game",
	Description = "Main game",
	IconName = "door-open",
})

GameGroupbox:AddLabel("Main game: " .. MainPlaceId)

GameGroupbox:AddButton({
	Text = "Join Main Game",
	Tooltip = "Teleports to the main game",
	Func = function()
		joinMainGame()
	end,
})

-- =========================================================
-- UI Settings
-- =========================================================

local MenuGroup = Tabs["UI Settings"]:AddGroupbox({
	Side = "Left",
	Name = "Menu",
	IconName = "wrench",
})

MenuGroup:AddToggle("CustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Tooltip = "Off = regular Roblox mouse",
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDivider()

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("AnticheatTest")
SaveManager:SetFolder("AnticheatTest/lobby")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
