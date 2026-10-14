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

local StarterGui = game:GetService("StarterGui")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- =========================================================
-- Loading overlay
-- =========================================================

local loadingGui
local loadingStatusLabel
local loadingFill

local function setupLoadingGui()
	local parent = (type(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

	loadingGui = Instance.new("ScreenGui")
	loadingGui.Name = "mspaint_loading"
	loadingGui.IgnoreGuiInset = true
	loadingGui.ResetOnSpawn = false
	loadingGui.DisplayOrder = 2000
	loadingGui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 360, 0, 96)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	frame.Parent = loadingGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -24, 0, 26)
	title.Position = UDim2.new(0, 12, 0, 12)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(235, 235, 240)
	title.Text = "mspaint"
	title.Parent = frame

	loadingStatusLabel = Instance.new("TextLabel")
	loadingStatusLabel.BackgroundTransparency = 1
	loadingStatusLabel.Size = UDim2.new(1, -24, 0, 18)
	loadingStatusLabel.Position = UDim2.new(0, 12, 0, 40)
	loadingStatusLabel.Font = Enum.Font.Gotham
	loadingStatusLabel.TextSize = 14
	loadingStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	loadingStatusLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
	loadingStatusLabel.Text = "starting"
	loadingStatusLabel.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.Position = UDim2.new(0, 12, 1, -18)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	bar.BorderSizePixel = 0
	bar.Parent = frame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	loadingFill = Instance.new("Frame")
	loadingFill.Size = UDim2.new(0, 4, 1, 0)
	loadingFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	loadingFill.BorderSizePixel = 0
	loadingFill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = loadingFill
end

local function loadingStatus(text, progress)
	if loadingStatusLabel then
		loadingStatusLabel.Text = text
	end
	if loadingFill and progress then
		loadingFill.Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
	end
	print("[mspaint] " .. text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "mspaint",
			Text = text,
			Duration = 3,
		})
	end)
end

local function finishLoading()
	if loadingGui then
		loadingGui:Destroy()
		loadingGui = nil
	end
end

setupLoadingGui()
loadingStatus("loading library", 0.1)

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
loadingStatus("loading interface", 0.25)

-- =========================================================
-- Logic
-- =========================================================
loadingStatus("loading logic", 0.4)

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

loadingStatus("loading elevator", 0.6)

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

loadingStatus("loading game", 0.75)

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

loadingStatus("loading settings", 0.9)

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

loadingStatus("ready", 1)
task.delay(0.4, finishLoading)
