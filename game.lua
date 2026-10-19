local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local LobbyPlaceId = 18186775539

-- Everything below runs inside this function so the main chunk keeps only the
-- service imports. Luau allows at most 200 locals per function, and the script
-- body had just crossed that limit (which made loadstring fail).
local function __entry()

-- Current floor, read from ReplicatedStorage.GameInfo.GameStyle (a StringValue).
-- Known floors: "Foundation" (main floor) and "Graveyard".
local GameInfo = ReplicatedStorage:WaitForChild("GameInfo", 10)
local GameStyleValue = GameInfo and GameInfo:FindFirstChild("GameStyle")
local GameStyle = (GameStyleValue and GameStyleValue.Value) or ""
local IsGraveyard = string.lower(GameStyle) == "graveyard"

-- Place-specific variant: only Character + Visuals, ESP targeting the "VER" model.
local IsVerPlace = game.PlaceId == 134208374070897

-- Add any other workspace entity names here as you discover them
local EntityNames = { "Rush", "Ram", "Stare", "Eyes", "Hisoka", "Ambush" }
local AvoidEntityNames = { "Rush", "Ram", "Ambush" }
local EntityEspNames = { "Rush", "Ram", "Stare", "Eyes", "Peakaboo", "Hisoka", "Ambush" }
local GraveyardEntityEspNames = { "Hisoka" }
local GraveyardEntityNames = { "Hisoka" }

if IsVerPlace then
	EntityNames = { "VER" }
	AvoidEntityNames = { "VER" }
	EntityEspNames = { "VER" }
	GraveyardEntityEspNames = { "VER" }
	GraveyardEntityNames = { "VER" }
end

local RoomNamePattern = "^[Rr]oom%d+$"

local entityEspSelections = {}

local function initializeEntityEspSelections()
	entityEspSelections = {}
	if IsVerPlace then
		entityEspSelections["VER"] = true
	elseif IsGraveyard then
		entityEspSelections["Hisoka"] = true
	else
		for _, name in ipairs(EntityEspNames) do
			entityEspSelections[name] = true
		end
	end
end

initializeEntityEspSelections()

-- Loader that "Execute on Teleport" re-runs after a teleport.
-- Set this to your script's loader, e.g. loadstring(game:HttpGet("https://..."))()
local ExecuteOnTeleportLoader = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/main.lua"))()'

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
		Library:Notify({
			Title = "mspaint",
			Description = text,
			Icon = "loader",
			Time = 3,
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

-- =========================================================
-- Window / Tabs / Groupboxes
-- =========================================================

local Window = Library:CreateWindow({
	Title = "mspaint",
	Icon = 95816097006870,
	NotifySide = "Right",
})

-- Obsidian snapshots the mouse-icon state when the library loads. During an
-- execute-on-teleport reload the cursor is usually visible, which makes Obsidian
-- leave the cursor on screen (and the camera unlocked) once the menu closes.
if not Library.IsMobile then
	Library.OriginalMouseIconEnabled = false
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	task.spawn(function()
		local wasOpen = Library.Toggled
		while Library.Unloaded ~= true do
			if wasOpen and not Library.Toggled then
				UserInputService.MouseIconEnabled = false
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
			wasOpen = Library.Toggled
			task.wait(0.1)
		end
	end)
end

loadingStatus("loading library", 0.05)

local Tabs = {
	Changelog = Window:AddTab("Changelog", "scroll-text"),
	Character = Window:AddTab("Character", "person-standing"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Notifier = Window:AddTab("Notifier", "bell"),
	Exploit = Window:AddTab("Exploit", "shield"),
	Debug = Window:AddTab("Debug", "bug"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Floor-specific tab
if IsGraveyard then
	Tabs.Floor = Window:AddTab("Floor", "graveyard")
end
loadingStatus("loading interface", 0.12)

-- =========================================================
-- Changelog tab
-- =========================================================
loadingStatus("loading changelog", 0.15)

local ChangelogGroupbox = Tabs.Changelog:AddGroupbox({
	Side = "Left",
	Name = "Changelog",
	Description = "Recent changes",
	IconName = "scroll-text",
})

-- The changelog is fetched from .changelog in the repository.
local ChangelogUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/.changelog"

local function formatChangelogLabel(text)
	return (text:gsub("%*%*(.-)%*%*", "<b>%1</b>"))
end

local function renderChangelog(source)
	local lastWasDivider = true

	for rawLine in string.gmatch(source, "[^\r\n]+") do
		local line = rawLine:match("^%s*(.-)%s*$")

		if line == "" then
			if not lastWasDivider then
				ChangelogGroupbox:AddDivider()
				lastWasDivider = true
			end
		else
			local header = line:match("^#+%s*(.+)$")
			if header then
				ChangelogGroupbox:AddLabel("<b>" .. formatChangelogLabel(header) .. "</b>", false)
			else
				ChangelogGroupbox:AddLabel(formatChangelogLabel(line), true)
			end
			lastWasDivider = false
		end
	end
end

local changelogOk, changelogSource = pcall(game.HttpGet, game, ChangelogUrl)
if changelogOk and type(changelogSource) == "string" and #changelogSource > 0 then
	renderChangelog(changelogSource)
else
	ChangelogGroupbox:AddLabel("Could not load changelog.", true)
end

-- =========================================================
-- Character tab: movement
-- =========================================================
loadingStatus("loading movement", 0.2)

local MovementGroupbox = Tabs.Character:AddGroupbox({
	Side = "Left",
	Name = "Movement",
	Description = "Character modifiers",
	IconName = "person-standing",
})

MovementGroupbox:AddToggle("EnableWalkSpeed", {
	Text = "WalkSpeed",
	Default = false,
	Tooltip = "Constantly re-applies WalkSpeed (game resets it)",
})

MovementGroupbox:AddSlider("WalkSpeed", {
	Text = "WalkSpeed Value",
	Default = 16,
	Min = 0,
	Max = 250,
	Rounding = 0,
})

MovementGroupbox:AddDivider()

MovementGroupbox:AddToggle("EnableJump", {
	Text = "Jump Power",
	Default = false,
	Tooltip = "Constantly re-applies JumpPower",
})

MovementGroupbox:AddSlider("JumpPower", {
	Text = "Jump Power Value",
	Default = 50,
	Min = 0,
	Max = 500,
	Rounding = 0,
})

MovementGroupbox:AddDivider()

MovementGroupbox:AddToggle("Fly", {
	Text = "Fly",
	Default = false,
	Tooltip = "WASD to move, Space / LeftCtrl for up & down",
})

MovementGroupbox:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 60,
	Min = 10,
	Max = 500,
	Rounding = 0,
})

MovementGroupbox:AddToggle("Noclip", {
	Text = "Noclip",
	Default = false,
	Tooltip = "Disables collision on your character",
})

loadingStatus("loading automation", 0.3)

local AutomationGroupbox = Tabs.Character:AddGroupbox({
	Side = "Right",
	Name = "Automation",
	Description = "Play the game for you",
	IconName = "play",
})

AutomationGroupbox:AddToggle("Autoplay", {
	Text = "Autoplay",
	Default = false,
	Tooltip = "Teleports you through the doors automatically",
})

AutomationGroupbox:AddSlider("AutoplayDelay", {
	Text = "Autoplay Delay",
	Default = 0.35,
	Min = 0.1,
	Max = 3,
	Rounding = 2,
})

loadingStatus("loading actions", 0.34)

local ActionGroupbox = Tabs.Character:AddGroupbox({
	Side = "Right",
	Name = "Actions",
	Description = "Quick actions",
	IconName = "zap",
})

ActionGroupbox:AddButton("Reset Character", function()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end)

ActionGroupbox:AddButton("Teleport to Lobby", function()
	local ok, err = pcall(function()
		TeleportService:Teleport(LobbyPlaceId, LocalPlayer)
	end)
	if not ok then
		Library:Notify({
			Title = "Teleport to Lobby",
			Description = "Teleport failed: " .. tostring(err),
			Icon = "triangle-alert",
			Time = 5,
		})
	end
end)

-- =========================================================
-- Visuals tab: ESP
-- =========================================================
loadingStatus("loading visuals & entities", 0.38)

local EspGroupbox = Tabs.Visuals:AddGroupbox({
	Side = "Left",
	Name = "General",
	IconName = "eye",
})

EspGroupbox:AddToggle("DoorESP", {
	Text = "Door ESP",
	Default = false,
	Tooltip = "Highlights doors inside GeneratedRooms/room###",
}):AddColorPicker("DoorESPColor", {
	Default = Color3.fromRGB(0, 170, 255),
	Title = "Door ESP Color",
})

EspGroupbox:AddToggle("EntityESP", {
	Text = "Entity ESP",
	Default = false,
	Tooltip = "Highlights entities (Rush, ...)",
}):AddColorPicker("EntityESPColor", {
	Default = Color3.fromRGB(255, 40, 40),
	Title = "Entity ESP Color",
})

EspGroupbox:AddDropdown("EntityESPFilter", {
	Values = (IsVerPlace and EntityEspNames) or (IsGraveyard and GraveyardEntityEspNames) or EntityEspNames,
	Default = 1,
	Multi = true,
	Text = "Entities in ESP",
	Tooltip = "Choose which entities Entity ESP highlights",
})

EspGroupbox:AddToggle("EntityESPFill", {
	Text = "Entity ESP Fill",
	Default = true,
	Tooltip = "Fill the entity highlight instead of only outlining it",
})

EspGroupbox:AddSlider("EntityESPFillTransparency", {
	Text = "Entity ESP Fill Transparency",
	Default = 0.5,
	Min = 0,
	Max = 1,
	Rounding = 2,
	Tooltip = "0 = solid fill, 1 = invisible fill (outline only)",
})

EspGroupbox:AddToggle("PlayerESP", {
	Text = "Player ESP",
	Default = false,
	Tooltip = "Highlights other players",
}):AddColorPicker("PlayerESPColor", {
	Default = Color3.fromRGB(0, 255, 120),
	Title = "Player ESP Color",
})

EspGroupbox:AddToggle("LockerESP", {
	Text = "Locker ESP",
	Default = false,
	Tooltip = "Highlights lockers (Room###.AddedAssets.Locker)",
}):AddColorPicker("LockerESPColor", {
	Default = Color3.fromRGB(255, 215, 0),
	Title = "Locker ESP Color",
})

EspGroupbox:AddToggle("MinecartESP", {
	Text = "Minecart Direction ESP",
	Default = false,
	Tooltip = "Highlights minecart nodes & draws the correct path",
}):AddColorPicker("MinecartESPColor", {
	Default = Color3.fromRGB(0, 255, 255),
	Title = "Minecart ESP Color",
})

EspGroupbox:AddToggle("ObjectiveESP", {
	Text = "Objective ESP",
	Default = false,
	Tooltip = "Highlights levers (Room###.Scriptable.LeverModel)",
}):AddColorPicker("ObjectiveESPColor", {
	Default = Color3.fromRGB(180, 120, 255),
	Title = "Objective ESP Color",
})

local WorldGroupbox = Tabs.Visuals:AddGroupbox({
	Side = "Right",
	Name = "World",
	Description = "Lighting modifiers",
	IconName = "sun",
})

WorldGroupbox:AddToggle("Fullbright", {
	Text = "Fullbright",
	Default = false,
	Tooltip = "Brightens the world (Lighting)",
})

local CameraGroupbox = Tabs.Visuals:AddGroupbox({
	Side = "Right",
	Name = "Camera",
	Description = "View settings",
	IconName = "camera",
})

CameraGroupbox:AddSlider("FOV", {
	Text = "Field of View",
	Default = 70,
	Min = 60,
	Max = 120,
	Rounding = 0,
})

local initialFov = 70
do
	local camera = Workspace.CurrentCamera
	if camera then
		initialFov = camera.FieldOfView
	end
end

local function applyFov()
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = Options.FOV.Value
	end
end

Options.FOV:OnChanged(function()
	applyFov()
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(applyFov)
end)

-- =========================================================
-- Notifier tab
-- =========================================================
loadingStatus("loading notifier", 0.46)

local NotifierGroupbox = Tabs.Notifier:AddGroupbox({
	Side = "Left",
	Name = "Spawn Notifier",
	Description = "Alerts when entities spawn",
	IconName = "bell",
})

NotifierGroupbox:AddDropdown("NotifierEntities", {
	Values = (IsGraveyard and { "Hisoka" }) or { "Rush", "Screech", "Ram", "Stare", "Eyes", "Hisoka", "Ambush" },
	Default = 1,
	Multi = true,
	Tooltip = "Workspace entities spawn in the workspace, Screech spawns in the camera",
})

-- =========================================================
-- Exploit tab
-- =========================================================
loadingStatus("loading exploits", 0.52)

local ExploitGroupbox = Tabs.Exploit:AddGroupbox({
	Side = "Left",
	Name = "Entities",
	Description = "Counter entity exploits",
	IconName = "shield",
})

ExploitGroupbox:AddToggle("AntiEyes", {
	Text = "Anti-Eyes",
	Default = false,
	Tooltip = "Stops you looking at Eyes (looking at it damages you)",
})

ExploitGroupbox:AddToggle("AvoidEntities", {
	Text = "Avoid Entities",
	Default = false,
	Tooltip = "Teleports you 1000 studs away while an entity is spawned, then back",
})

local UtilityGroupbox = Tabs.Exploit:AddGroupbox({
	Side = "Right",
	Name = "Utility",
	Description = "World & interaction",
	IconName = "wrench",
})

UtilityGroupbox:AddToggle("DisableVoidEffect", {
	Text = "Disable Void Effect",
	Default = false,
	Tooltip = "Removes the screen distortion and stops the void sound",
})

UtilityGroupbox:AddToggle("AutoInteract", {
	Text = "Auto Interact",
	Default = false,
	Tooltip = "Auto-fires prompts in AddedAssets (skips lockers)",
})

local PositionGroupbox = Tabs.Exploit:AddGroupbox({
	Side = "Right",
	Name = "Position",
	Description = "Move your character",
	IconName = "move",
})

PositionGroupbox:AddToggle("PositionOffset", {
	Text = "Position Offset",
	Default = false,
	Tooltip = "Teleports you below your position; your camera stays where it was",
})

PositionGroupbox:AddSlider("PositionOffsetAmount", {
	Text = "Offset (studs)",
	Default = 35,
	Min = 1,
	Max = 150,
	Rounding = 0,
	Tooltip = "How many studs below your position to teleport",
})

-- =========================================================
-- Debug tab
-- =========================================================
loadingStatus("loading debug", 0.56)

local DebugLogGroupbox = Tabs.Debug:AddGroupbox({
	Side = "Left",
	Name = "Logging",
	Description = "Console output",
	IconName = "terminal",
})

DebugLogGroupbox:AddToggle("LogEntitySpawns", {
	Text = "Log Entity Spawns",
	Default = false,
	Tooltip = "Prints to the console when an entity spawns",
})

DebugLogGroupbox:AddToggle("LogRaycasts", {
	Text = "Log Raycasts",
	Default = false,
	Tooltip = "Prints every raycast the game performs",
})

local DebugRayGroupbox = Tabs.Debug:AddGroupbox({
	Side = "Right",
	Name = "Raycasts",
	Description = "Raycast visualiser",
	IconName = "scan",
})

DebugRayGroupbox:AddToggle("ShowRaycasts", {
	Text = "Show Raycasts",
	Default = false,
	Tooltip = "Draws a line for every raycast the game performs",
})

DebugRayGroupbox:AddSlider("RaycastVisualTime", {
	Text = "Ray Lifetime",
	Default = 0.15,
	Min = 0.05,
	Max = 2,
	Rounding = 2,
})

-- =========================================================
-- ESP engine
-- =========================================================
loadingStatus("loading esp engine", 0.62)

local EspFolder = Instance.new("Folder")
EspFolder.Name = "mspaint_esp"
EspFolder.Parent = Workspace

local doorCache = {}
local entityCache = {}
local lockerCache = {}
local playerCache = {}
local minecartCache = {}
local objectiveCache = {}

local function isEspTarget(inst)
	return inst ~= nil and (inst:IsA("BasePart") or inst:IsA("Model"))
end

local function getWorldPosition(target)
	if target:IsA("BasePart") then
		return target.Position
	end

	if target:IsA("Model") then
		if target.PrimaryPart then
			return target.PrimaryPart.Position
		end

		local hrp = target:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp.Position
		end

		local part = target:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.Position
		end

		local ok, center = pcall(function()
			return select(1, target:GetBoundingBox())
		end)
		if ok and center then
			return center
		end
	end

	return nil
end

local function getViewerPosition()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then
		return hrp.Position
	end
	local camera = Workspace.CurrentCamera
	return camera and camera.CFrame.Position or Vector3.zero
end

local function getEntityParts(target)
	local parts = {}
	if target:IsA("BasePart") then
		table.insert(parts, target)
	end
	for _, descendant in ipairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function createEntityChams(target, color, fillTransparency)
	local proxy = Instance.new("Model")
	proxy.Name = "mspaint_entity_chams"
	proxy.Parent = EspFolder

	local clones = {}
	for _, source in ipairs(getEntityParts(target)) do
		local clone = source:Clone()
		for _, child in ipairs(clone:GetDescendants()) do
			if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") or child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then
				child:Destroy()
			end
		end
		if clone:IsA("MeshPart") then
			clone.TextureID = ""
		end
		clone.Color = color
		clone.Material = Enum.Material.SmoothPlastic
		clone.Transparency = math.min(fillTransparency, 0.98)
		clone.Anchored = true
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.CastShadow = false
		clone.Massless = true
		clone.Parent = proxy
		table.insert(clones, { source = source, clone = clone })
	end

	local outline = Instance.new("Highlight")
	outline.Name = "mspaint_entity_outline"
	outline.Adornee = proxy
	outline.FillColor = color
	outline.OutlineColor = color
	outline.FillTransparency = 1
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	outline.Parent = EspFolder

	return { proxy = proxy, clones = clones, outline = outline }
end

local function updateEntityChams(chams, color, fillTransparency)
	local transparency = math.min(fillTransparency, 0.98)
	for _, pair in ipairs(chams.clones) do
		local source = pair.source
		local clone = pair.clone
		if source.Parent then
			clone.CFrame = source.CFrame
			clone.Size = source.Size
		end
		clone.Color = color
		clone.Transparency = transparency
	end
	chams.outline.FillColor = color
	chams.outline.OutlineColor = color
end

local function destroyEntityChams(chams)
	for _, pair in ipairs(chams.clones) do
		pair.clone:Destroy()
	end
	if chams.proxy then
		chams.proxy:Destroy()
	end
	if chams.outline then
		chams.outline:Destroy()
	end
end

local function destroyEntry(entry)
	if entry.highlight then
		entry.highlight:Destroy()
	end
	if entry.chams then
		destroyEntityChams(entry.chams)
	end
	if entry.billboard then
		entry.billboard:Destroy()
	end
end

local function createEntry(target, color, baseText, useChams)
	local entry = { baseText = baseText }

	if useChams then
		entry.chams = createEntityChams(target, color, 0.5)
	else
		local highlight = Instance.new("Highlight")
		highlight.Name = "mspaint_highlight"
		highlight.Adornee = target
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = EspFolder
		entry.highlight = highlight
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "mspaint_billboard"
	billboard.Adornee = target
	billboard.Size = UDim2.new(0, 220, 0, 44)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1500
	billboard.Parent = EspFolder

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 16
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Text = baseText
	label.Parent = billboard

	entry.billboard = billboard
	entry.label = label
	return entry
end

local function updateSet(cache, targets, enabled, color, textFor, fillTransparency, useChams)
	if not enabled then
		for target, entry in pairs(cache) do
			destroyEntry(entry)
			cache[target] = nil
		end
		return
	end

	local alive = {}
	local viewerPos = getViewerPosition()

	for _, target in ipairs(targets) do
		if isEspTarget(target) and target.Parent then
			alive[target] = true

			local entry = cache[target]
			if not entry then
				entry = createEntry(target, color, textFor(target), useChams)
				cache[target] = entry
			end

			if entry.highlight then
				entry.highlight.FillColor = color
				entry.highlight.OutlineColor = color
				entry.highlight.FillTransparency = fillTransparency or 0.5
			end
			if entry.chams then
				updateEntityChams(entry.chams, color, fillTransparency or 0.5)
			end
			entry.label.TextColor3 = color
			entry.baseText = textFor(target)

			local worldPos = getWorldPosition(target)
			if worldPos then
				local distance = (worldPos - viewerPos).Magnitude
				entry.label.Text = string.format("%s\n[%d studs]", entry.baseText, math.floor(distance))
			else
				entry.label.Text = entry.baseText
			end
		end
	end

	for target, entry in pairs(cache) do
		if not alive[target] then
			destroyEntry(entry)
			cache[target] = nil
		end
	end
end

-- =========================================================
-- Minecart direction ESP
--
-- Node data lives at Room###.Scriptable.MinecartNodes. The root holds the
-- trunk nodes and Path1/Path2/... subfolders hold the branch nodes. The
-- correct way to go is the path that contains a dismount, so that branch is
-- drawn in green while the trunk and the other branches use the ESP color.
-- =========================================================

loadingStatus("loading minecart esp", 0.66)

local MinecartNodeFolderName = "MinecartNodes"
local MinecartFallbackFolders = { "Assets", "Necessities", "AddedAssets" }
local MinecartCorrectColor = Color3.fromRGB(85, 255, 85)
local MinecartVehicleColor = Color3.fromRGB(255, 140, 0)

local function getNodeOrder(node)
	for _, attrName in ipairs({ "Index", "Order", "NodeIndex", "Step" }) do
		local value = node:GetAttribute(attrName)
		if typeof(value) == "number" then
			return value
		end
	end

	local number = tonumber(node.Name:match("%d+"))
	if number then
		return number
	end

	return math.huge
end

local function isCorrectNode(node)
	for attrName, value in pairs(node:GetAttributes()) do
		local lower = attrName:lower()
		local directional = lower:find("correct")
			or lower:find("right")
			or lower:find("answer")
			or lower:find("solution")
			or lower == "direction"
		if directional and value ~= false and value ~= nil then
			return true
		end
	end

	local name = node.Name:lower()
	return name:find("correct") ~= nil or name:find("right") ~= nil
end

local function findMinecartNodeContainer(room)
	local scriptable = room:FindFirstChild("Scriptable")
	if scriptable then
		local nodes = scriptable:FindFirstChild(MinecartNodeFolderName)
		if nodes then
			return nodes
		end
	end

	for _, folderName in ipairs(MinecartFallbackFolders) do
		local folder = room:FindFirstChild(folderName)
		if folder then
			local nodes = folder:FindFirstChild(MinecartNodeFolderName, true)
			if nodes then
				return nodes
			end
		end
	end

	return nil
end

local function findMinecartVehicle(room)
	local roaming = room:FindFirstChild("RoamingCart")
	if roaming and isEspTarget(roaming) then
		return roaming
	end

	local roots = {
		room:FindFirstChild("Scriptable"),
		room:FindFirstChild("Assets"),
		room:FindFirstChild("Necessities"),
		room:FindFirstChild("AddedAssets"),
	}

	for _, root in ipairs(roots) do
		if root then
			for _, descendant in ipairs(root:GetDescendants()) do
				local lower = descendant.Name:lower()
				if lower:find("minecart") and not lower:find("node") and isEspTarget(descendant) then
					return descendant
				end
			end
		end
	end

	return nil
end

local function isPathContainer(child)
	if child:IsA("BasePart") then
		return false
	end
	return child.Name:lower():match("^path%d*$") ~= nil
end

local function collectNodeParts(container, recursive)
	local nodes = {}
	local seen = {}

	local function add(part)
		if part and part:IsA("BasePart") and not seen[part] then
			seen[part] = true
			table.insert(nodes, part)
		end
	end

	for _, child in ipairs(container:GetChildren()) do
		if isPathContainer(child) then
			-- branch, handled separately
		elseif child:IsA("BasePart") then
			add(child)
		elseif child:IsA("Model") then
			add(child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true))
		elseif recursive and child:IsA("Folder") then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("BasePart") then
					add(descendant)
				end
			end
		end
	end

	table.sort(nodes, function(a, b)
		local orderA = getNodeOrder(a)
		local orderB = getNodeOrder(b)
		if orderA == orderB then
			return a.Name < b.Name
		end
		return orderA < orderB
	end)

	return nodes
end

local function findMinecartPaths(container)
	local paths = {}
	for _, child in ipairs(container:GetChildren()) do
		if isPathContainer(child) then
			table.insert(paths, child)
		end
	end
	table.sort(paths, function(a, b)
		local orderA = tonumber(a.Name:match("%d+")) or math.huge
		local orderB = tonumber(b.Name:match("%d+")) or math.huge
		return orderA < orderB
	end)
	return paths
end

local function containerHasDismount(container)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant.Name:lower():find("dismount") then
			return true
		end
		local flag = descendant:GetAttribute("Dismount")
		if flag ~= nil and flag ~= false then
			return true
		end
	end
	return false
end

local function createBeam(a, b, color, width, track)
	local attachment0 = track(Instance.new("Attachment"))
	attachment0.Parent = a

	local attachment1 = track(Instance.new("Attachment"))
	attachment1.Parent = b

	local beam = track(Instance.new("Beam"))
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(color)
	beam.FaceCamera = true
	beam.Width0 = width
	beam.Width1 = width
	beam.Transparency = NumberSequence.new(0.3)
	beam.Parent = EspFolder
	return beam
end

local function clearMinecart(room)
	local entry = minecartCache[room]
	if not entry then
		return
	end

	for _, inst in ipairs(entry.instances) do
		if inst and inst.Parent then
			inst:Destroy()
		end
	end

	minecartCache[room] = nil
end

local function clearAllMinecarts()
	for room in pairs(minecartCache) do
		clearMinecart(room)
	end
end

local function buildMinecart(room, container, color)
	local nodes = collectNodeParts(container, false)
	local paths = findMinecartPaths(container)

	if #nodes == 0 and #paths == 0 then
		return
	end

	local instances = {}
	local function track(inst)
		table.insert(instances, inst)
		return inst
	end

	local function highlightNode(node, nodeColor)
		local highlight = track(Instance.new("Highlight"))
		highlight.Adornee = node
		highlight.FillColor = nodeColor
		highlight.OutlineColor = nodeColor
		highlight.FillTransparency = 0.4
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = EspFolder
	end

	for _, node in ipairs(nodes) do
		local nodeColor = isCorrectNode(node) and MinecartCorrectColor or color
		highlightNode(node, nodeColor)
	end

	for i = 1, #nodes - 1 do
		createBeam(nodes[i], nodes[i + 1], MinecartCorrectColor, 0.15, track)
	end

	-- the correct way to go is the path that contains a dismount
	local correctPath
	for _, path in ipairs(paths) do
		if containerHasDismount(path) then
			correctPath = path
			break
		end
	end

	local lastTrunkNode = nodes[#nodes]

	for _, path in ipairs(paths) do
		local pathNodes = collectNodeParts(path, true)
		if #pathNodes > 0 then
			local isCorrect = path == correctPath
			if not correctPath then
				for _, node in ipairs(pathNodes) do
					if isCorrectNode(node) then
						isCorrect = true
						break
					end
				end
			end

			local pathColor = isCorrect and MinecartCorrectColor or color
			local width = isCorrect and 0.3 or 0.15

			for _, node in ipairs(pathNodes) do
				highlightNode(node, pathColor)
			end

			if lastTrunkNode then
				createBeam(lastTrunkNode, pathNodes[1], pathColor, width, track)
			end

			for i = 1, #pathNodes - 1 do
				createBeam(pathNodes[i], pathNodes[i + 1], pathColor, width, track)
			end
		end
	end

	local vehicle = findMinecartVehicle(room)
	if vehicle then
		local highlight = track(Instance.new("Highlight"))
		highlight.Adornee = vehicle
		highlight.FillColor = MinecartVehicleColor
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.4
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = EspFolder
	end

	minecartCache[room] = {
		instances = instances,
		color = color,
		container = container,
	}
end

local function updateMinecartEsp(enabled, color)
	if not enabled then
		clearAllMinecarts()
		return
	end

	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		clearAllMinecarts()
		return
	end

	local seen = {}
	for _, room in ipairs(generatedRooms:GetChildren()) do
		if room.Name:match(RoomNamePattern) then
			local container = findMinecartNodeContainer(room)
			if container then
				seen[room] = true
				local entry = minecartCache[room]
				if not entry then
					buildMinecart(room, container, color)
				elseif entry.color ~= color or entry.container ~= container then
					clearMinecart(room)
					buildMinecart(room, container, color)
				end
			end
		end
	end

	for room in pairs(minecartCache) do
		if not seen[room] or not room.Parent then
			clearMinecart(room)
		end
	end
end

-- =========================================================
-- Target collection
-- =========================================================
loadingStatus("loading entity collection", 0.7)

local function findDoorPart(room)
	local bestPart
	for _, child in ipairs(room:GetChildren()) do
		if child.Name:lower() == "door" and isEspTarget(child) then
			if child:IsA("Model") then
				return child
			end
			bestPart = bestPart or child
		end
	end

	local bestModel
	for _, descendant in ipairs(room:GetDescendants()) do
		if descendant.Name:lower() == "door" and isEspTarget(descendant) then
			if descendant:IsA("Model") then
				bestModel = bestModel or descendant
			elseif not bestPart then
				bestPart = descendant
			end
		end
	end

	return bestModel or bestPart
end

local function collectDoors()
	local doors = {}
	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		return doors
	end

	for _, room in ipairs(generatedRooms:GetChildren()) do
		if room.Name:match(RoomNamePattern) then
			local door = findDoorPart(room)
			if door then
				table.insert(doors, door)
			end
		end
	end

	return doors
end

local function collectPeakabooLockers()
	local lockers = {}
	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		return lockers
	end

	for _, room in ipairs(generatedRooms:GetChildren()) do
		if room.Name:match(RoomNamePattern) then
			for _, folderName in ipairs({ "AddedAssets", "Assets", "Necessities" }) do
				local folder = room:FindFirstChild(folderName)
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						local lower = child.Name:lower()
						if (lower:find("peakaboo") or lower:find("peekaboo")) and isEspTarget(child) then
							table.insert(lockers, child)
						end
					end
				end
			end
		end
	end

	return lockers
end

local function collectEntities()
	local entities = {}
	for _, name in ipairs(EntityNames) do
		if entityEspSelections[name] then
			local entity = Workspace:FindFirstChild(name, true)
			if isEspTarget(entity) then
				table.insert(entities, entity)
			end
		end
	end

	if entityEspSelections.Peakaboo then
		for _, peakaboo in ipairs(collectPeakabooLockers()) do
			table.insert(entities, peakaboo)
		end
	end

	return entities
end

local function entityDisplayName(target)
	local lower = target.Name:lower()
	if lower:find("peakaboo") or lower:find("peekaboo") then
		return "Peakaboo"
	end
	return target.Name
end

local function collectLockers()
	local lockers = {}
	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		return lockers
	end

	for _, room in ipairs(generatedRooms:GetChildren()) do
		if room.Name:match(RoomNamePattern) then
			local addedAssets = room:FindFirstChild("AddedAssets")
			if addedAssets then
				for _, descendant in ipairs(addedAssets:GetDescendants()) do
					if descendant.Name == "Locker" and isEspTarget(descendant) then
						table.insert(lockers, descendant)
					end
				end
			end
		end
	end

	return lockers
end

local function collectPlayers()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and isEspTarget(player.Character) then
			table.insert(characters, player.Character)
		end
	end
	return characters
end

local function collectObjectives()
	local objectives = {}
	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		return objectives
	end

	for _, room in ipairs(generatedRooms:GetChildren()) do
		if room.Name:match(RoomNamePattern) then
			local scriptable = room:FindFirstChild("Scriptable")
			local lever = scriptable and scriptable:FindFirstChild("LeverModel", true)
			if lever and isEspTarget(lever) then
				table.insert(objectives, lever)
			end
		end
	end

	return objectives
end

-- =========================================================
-- Character modifiers
-- =========================================================
loadingStatus("loading character modifiers", 0.74)

local walkSpeedEnabled = false
local walkSpeedValue = 16
local speedBodyVelocity
local jumpEnabled = false
local jumpPowerValue = 50
local noclipEnabled = false
local noclipSaved = {}

local function getCharacter()
	local character = LocalPlayer.Character
	if character and character:FindFirstChildOfClass("Humanoid") then
		return character
	end
	return nil
end

local function restoreNoclip()
	for part, value in pairs(noclipSaved) do
		pcall(function()
			part.CanCollide = value
		end)
	end
	table.clear(noclipSaved)
end

-- Fly

local flyEnabled = false
local flySpeedValue = 60
local flyVelocity
local flyGyro

local function stopFly()
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end
	local character = getCharacter()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function startFly()
	local character = getCharacter()
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return
	end

	stopFly()

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.MaxForce = Vector3.new(1, 1, 1) * math.huge
	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = hrp

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(1, 1, 1) * math.huge
	flyGyro.P = 10000
	flyGyro.CFrame = hrp.CFrame
	flyGyro.Parent = hrp

	humanoid.PlatformStand = true
end

Toggles.EnableWalkSpeed:OnChanged(function(Value)
	walkSpeedEnabled = Value
	if Value then
		local character = getCharacter()
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = walkSpeedValue
		end
	end
end)

Options.WalkSpeed:OnChanged(function(Value)
	walkSpeedValue = Value
end)

Toggles.EnableJump:OnChanged(function(Value)
	jumpEnabled = Value
end)

Options.JumpPower:OnChanged(function(Value)
	jumpPowerValue = Value
end)

Toggles.Noclip:OnChanged(function(Value)
	noclipEnabled = Value
	if not Value then
		restoreNoclip()
	end
end)

Toggles.Fly:OnChanged(function(Value)
	flyEnabled = Value
	if Value then
		startFly()
	else
		stopFly()
	end
end)

Options.FlySpeed:OnChanged(function(Value)
	flySpeedValue = Value
end)

-- Re-apply WalkSpeed the instant anything (e.g. the game) changes it. Some
-- places reset WalkSpeed aggressively, so the per-frame loop alone can be
-- overridden before movement is simulated.
local walkSpeedWatch = {}

local function watchWalkSpeed(humanoid)
	if not humanoid or walkSpeedWatch[humanoid] then
		return
	end

	walkSpeedWatch[humanoid] = true
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if walkSpeedEnabled and humanoid.Parent and humanoid.WalkSpeed ~= walkSpeedValue then
			humanoid.WalkSpeed = walkSpeedValue
		end
	end)
end

local function watchCurrentWalkSpeed()
	local character = getCharacter()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if walkSpeedEnabled then
			humanoid.WalkSpeed = walkSpeedValue
		end
		watchWalkSpeed(humanoid)
	end
end

watchCurrentWalkSpeed()

LocalPlayer.CharacterAdded:Connect(function()
	table.clear(noclipSaved)
	table.clear(walkSpeedWatch)
	task.wait(0.5)
	watchCurrentWalkSpeed()
	if flyEnabled then
		startFly()
	end
end)

local movementConnection
movementConnection = RunService.RenderStepped:Connect(function()
	local character = getCharacter()

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if walkSpeedEnabled then
				humanoid.WalkSpeed = walkSpeedValue
			end
			if jumpEnabled then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = jumpPowerValue
			end
		end

		if noclipEnabled then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					if noclipSaved[part] == nil then
						noclipSaved[part] = part.CanCollide
					end
					part.CanCollide = false
				end
			end
		end
	end

	-- Velocity-based speed, only for places that ignore or reset Humanoid.WalkSpeed.
	if (IsVerPlace or game.PlaceId == 117314306495532) and walkSpeedEnabled and not flyEnabled and character then
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if root and humanoid then
			if not speedBodyVelocity or speedBodyVelocity.Parent ~= root then
				if speedBodyVelocity then
					speedBodyVelocity:Destroy()
				end
				speedBodyVelocity = Instance.new("BodyVelocity")
				speedBodyVelocity.Name = "mspaint_speed"
				speedBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
				speedBodyVelocity.P = 10000
				speedBodyVelocity.Parent = root
			end

			local moveDirection = humanoid.MoveDirection
			if moveDirection.Magnitude > 0.05 then
				speedBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
				speedBodyVelocity.Velocity = Vector3.new(moveDirection.X, 0, moveDirection.Z) * walkSpeedValue
			else
				speedBodyVelocity.MaxForce = Vector3.zero
			end
		elseif speedBodyVelocity then
			speedBodyVelocity:Destroy()
			speedBodyVelocity = nil
		end
	elseif speedBodyVelocity then
		speedBodyVelocity:Destroy()
		speedBodyVelocity = nil
	end

	if flyEnabled and flyVelocity and flyVelocity.Parent then
		local camera = Workspace.CurrentCamera
		if camera then
			local move = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				move = move + camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				move = move - camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				move = move - camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				move = move + camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				move = move + Vector3.yAxis
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				move = move - Vector3.yAxis
			end

			if move.Magnitude > 0 then
				move = move.Unit
			end

			local root = flyVelocity.Parent
			flyVelocity.Velocity = move * flySpeedValue
			flyGyro.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
		end
	end
end)

-- =========================================================
-- Fullbright
-- =========================================================
loadingStatus("loading fullbright", 0.78)

local lightingBackup

local FullbrightProps = {
	"Ambient",
	"OutdoorAmbient",
	"Brightness",
	"ClockTime",
	"GlobalShadows",
	"FogEnd",
	"FogStart",
	"ExposureCompensation",
}

local function applyFullbright()
	if lightingBackup then
		return
	end

	lightingBackup = {}
	for _, prop in ipairs(FullbrightProps) do
		lightingBackup[prop] = Lighting[prop]
	end

	Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	Lighting.Brightness = 2
	Lighting.ClockTime = 12
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
	Lighting.ExposureCompensation = 0
end

local function removeFullbright()
	if not lightingBackup then
		return
	end
	for prop, value in pairs(lightingBackup) do
		Lighting[prop] = value
	end
	lightingBackup = nil
end

Toggles.Fullbright:OnChanged(function(Value)
	if Value then
		applyFullbright()
	else
		removeFullbright()
	end
end)

loadingStatus("loading anti-eyes", 0.82)

-- =========================================================
-- Anti-Eyes
--
-- Looking at Eyes damages you, so while enabled we (1) stop the Eyes parts
-- from being raycast/touched and (2) force the camera to look away whenever
-- Eyes is in view. Refine once the Eyes script is provided.
-- =========================================================

local antiEyesEnabled = false
local antiEyesSaved = {}
local antiEyesConnection
local AntiEyesRenderName = "mspaint_anti_eyes"
local AntiEyesAngle = math.rad(35)

local function getEyesPart()
	local eyes = Workspace:FindFirstChild("Eyes", true)
	if not eyes then
		return nil
	end
	if eyes:IsA("BasePart") then
		return eyes
	end
	if eyes:IsA("Model") then
		return eyes.PrimaryPart or eyes:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function neutralizeEyesPart(part)
	if not part:IsA("BasePart") then
		return
	end

	if antiEyesSaved[part] == nil then
		antiEyesSaved[part] = {
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
			CanTouch = part.CanTouch,
			CanQuery = part.CanQuery,
		}
	end

	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

local function applyAntiEyes(inst)
	if not antiEyesEnabled or not inst then
		return
	end

	if inst:IsA("BasePart") then
		neutralizeEyesPart(inst)
	end

	for _, descendant in ipairs(inst:GetDescendants()) do
		if descendant:IsA("BasePart") then
			neutralizeEyesPart(descendant)
		end
	end
end

local function restoreAntiEyes()
	for part, data in pairs(antiEyesSaved) do
		if part and part.Parent then
			part.Transparency = data.Transparency
			part.CanCollide = data.CanCollide
			part.CanTouch = data.CanTouch
			part.CanQuery = data.CanQuery
		end
	end
	table.clear(antiEyesSaved)
end

local function stopAntiEyes()
	if antiEyesConnection then
		antiEyesConnection:Disconnect()
		antiEyesConnection = nil
	end

	pcall(function()
		RunService:UnbindFromRenderStep(AntiEyesRenderName)
	end)

	restoreAntiEyes()
end

local function antiEyesStep()
	if not antiEyesEnabled then
		return
	end

	local eyesPart = getEyesPart()
	local camera = Workspace.CurrentCamera
	if not eyesPart or not camera then
		return
	end

	local camPos = camera.CFrame.Position
	local toEyes = eyesPart.Position - camPos
	if toEyes.Magnitude < 0.01 then
		return
	end

	local direction = toEyes.Unit
	if camera.CFrame.LookVector:Dot(direction) > math.cos(AntiEyesAngle) then
		camera.CFrame = CFrame.new(camPos, camPos - direction)
	end
end

local function startAntiEyes()
	stopAntiEyes()

	applyAntiEyes(Workspace:FindFirstChild("Eyes", true))

	antiEyesConnection = Workspace.DescendantAdded:Connect(function(descendant)
		if antiEyesEnabled and descendant.Name == "Eyes" then
			applyAntiEyes(descendant)
		end
	end)

	RunService:BindToRenderStep(AntiEyesRenderName, Enum.RenderPriority.Camera.Value + 1, antiEyesStep)
end

Toggles.AntiEyes:OnChanged(function(Value)
	antiEyesEnabled = Value
	if Value then
		startAntiEyes()
	else
		stopAntiEyes()
	end
end)

loadingStatus("loading avoid entities", 0.85)

-- =========================================================
-- Avoid Entities
--
-- While an entity is spawned, keep teleporting you 1000 studs away from where
-- you were; once nothing is spawned, teleport back to that spot.
-- =========================================================

local avoidEntitiesEnabled = false
local avoidEntitiesConnection
local avoidActive = false
local avoidReturnPosition
local avoidEscapePosition
local lastSafePosition

local function getRootPart()
	local character = LocalPlayer.Character
	if character then
		return character:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function getSpawnedEntity()
	for _, name in ipairs(AvoidEntityNames) do
		local entity = Workspace:FindFirstChild(name, true)
		if entity then
			return entity
		end
	end
	return nil
end

local function getEntityPosition(entity)
	if entity:IsA("BasePart") then
		return entity.Position
	end
	if entity:IsA("Model") then
		local part = entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position or nil
	end
	return nil
end

local function avoidEntitiesStep()
	if not avoidEntitiesEnabled then
		return
	end

	local root = getRootPart()
	if not root then
		return
	end

	local entity = getSpawnedEntity()

	if entity then
		if not avoidActive then
			avoidActive = true
			avoidReturnPosition = lastSafePosition or root.Position

			local entityPosition = getEntityPosition(entity)
			local direction = entityPosition and (root.Position - entityPosition) or Vector3.new(0, 0, 1)
			if direction.Magnitude < 1 then
				direction = Vector3.new(0, 0, 1)
			end

			avoidEscapePosition = avoidReturnPosition + direction.Unit * 1000
		end

		root.CFrame = CFrame.new(avoidEscapePosition)
		root.AssemblyLinearVelocity = Vector3.zero
	else
		if avoidActive then
			avoidActive = false
			if avoidReturnPosition then
				root.CFrame = CFrame.new(avoidReturnPosition)
				root.AssemblyLinearVelocity = Vector3.zero
			end
			avoidReturnPosition = nil
			avoidEscapePosition = nil
		end

		lastSafePosition = root.Position
	end
end

local function stopAvoidEntities()
	if avoidEntitiesConnection then
		avoidEntitiesConnection:Disconnect()
		avoidEntitiesConnection = nil
	end
	avoidActive = false
	avoidReturnPosition = nil
	avoidEscapePosition = nil
end

local function startAvoidEntities()
	stopAvoidEntities()
	avoidEntitiesConnection = RunService.Heartbeat:Connect(avoidEntitiesStep)
end

local voidForcedByAvoid = false

Toggles.AvoidEntities:OnChanged(function(Value)
	avoidEntitiesEnabled = Value

	if Value then
		startAvoidEntities()

		if not Toggles.DisableVoidEffect.Value then
			voidForcedByAvoid = true
			Toggles.DisableVoidEffect:SetValue(true)
		end
	else
		stopAvoidEntities()

		if voidForcedByAvoid then
			voidForcedByAvoid = false
			Toggles.DisableVoidEffect:SetValue(false)
		end
	end
end)

-- =========================================================
-- Position offset
--
-- Copies the character's position, moves it down by the configured amount, and
-- shifts the camera by the same amount so the view stays where it was.
-- =========================================================

local positionOffsetApplied = 0
local positionOffsetBaseCameraOffset = Vector3.zero

local function positionOffsetSetTotal(total)
	local delta = total - positionOffsetApplied
	local root = getRootPart()
	if root and delta ~= 0 then
		root.CFrame = root.CFrame - Vector3.new(0, delta, 0)
	end
	positionOffsetApplied = total

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.CameraOffset = positionOffsetBaseCameraOffset + Vector3.new(0, total, 0)
	end
end

local function startPositionOffset()
	if not getRootPart() then
		return false
	end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	positionOffsetBaseCameraOffset = humanoid and humanoid.CameraOffset or Vector3.zero
	positionOffsetApplied = 0
	positionOffsetSetTotal(Options.PositionOffsetAmount.Value)
	return true
end

local function stopPositionOffset()
	positionOffsetSetTotal(0)
end

Toggles.PositionOffset:OnChanged(function(Value)
	if Value then
		if not startPositionOffset() then
			Toggles.PositionOffset:SetValue(false)
		end
	else
		stopPositionOffset()
	end
end)

Options.PositionOffsetAmount:OnChanged(function(Value)
	if Toggles.PositionOffset.Value then
		positionOffsetSetTotal(Value)
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	if Toggles.PositionOffset.Value then
		task.wait(0.5)
		positionOffsetApplied = 0
		startPositionOffset()
	end
end)

loadingStatus("loading void effect", 0.88)

-- =========================================================
-- Void effect
--
-- Every few seconds the game distorts the screen and plays a sound. While
-- enabled we keep the post-processing effects neutralized and stop any
-- "void" sound. Refine once the exact effect/sound names are known.
-- =========================================================

local voidEffectEnabled = false
local voidEffectConnection
local VoidSoundName = "void"

local VoidEffectResets = {
	BlurEffect = function(effect)
		effect.Size = 0
	end,
	ColorCorrectionEffect = function(effect)
		effect.Brightness = 0
		effect.Contrast = 0
		effect.Saturation = 0
		effect.TintColor = Color3.fromRGB(255, 255, 255)
	end,
	DepthOfFieldEffect = function(effect)
		effect.FarIntensity = 0
		effect.FocusDistance = 0
		effect.InFocusRadius = 0
		effect.NearIntensity = 0
	end,
	SunRaysEffect = function(effect)
		effect.Intensity = 0
	end,
}

local function voidSoundContainers()
	local containers = { SoundService }

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		table.insert(containers, playerGui)
	end

	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	if playerScripts then
		table.insert(containers, playerScripts)
	end

	return containers
end

local function suppressVoidEffect()
	for _, child in ipairs(Lighting:GetChildren()) do
		local reset = VoidEffectResets[child.ClassName]
		if reset then
			reset(child)
		end
	end

	for _, container in ipairs(voidSoundContainers()) do
		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("Sound") and descendant.Name:lower():find(VoidSoundName) then
				pcall(function()
					descendant:Stop()
				end)
			end
		end
	end
end

local function stopVoidEffect()
	if voidEffectConnection then
		voidEffectConnection:Disconnect()
		voidEffectConnection = nil
	end
end

local function startVoidEffect()
	stopVoidEffect()
	suppressVoidEffect()
	voidEffectConnection = RunService.Heartbeat:Connect(suppressVoidEffect)
end

Toggles.DisableVoidEffect:OnChanged(function(Value)
	voidEffectEnabled = Value
	if Value then
		startVoidEffect()
	else
		stopVoidEffect()
	end
end)

loadingStatus("loading auto interact", 0.9)

-- =========================================================
-- Auto interact
--
-- Fires ProximityPrompts / ClickDetectors inside AddedAssets so you loot
-- lockers, tables, etc. The hide lockers are skipped.
-- =========================================================

local autoInteractEnabled = false
local autoInteractConnection
local autoInteractCooldowns = {}
local autoInteractAccumulator = 0
local AutoInteractCooldown = 1
local AutoInteractInterval = 0.2
local AutoInteractRange = 60

local function isLockerInteraction(inst)
	local current = inst
	while current and current ~= Workspace do
		if current.Name == "Locker" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function triggerPrompt(prompt)
	if type(fireproximityprompt) == "function" then
		pcall(fireproximityprompt, prompt)
		return
	end

	task.spawn(function()
		prompt:InputHoldBegin()
		if prompt.HoldDuration > 0 then
			task.wait(prompt.HoldDuration)
		end
		prompt:InputHoldEnd()
	end)
end

local function fireInteractable(interactable)
	local adornee = interactable.Parent
	local position
	if adornee then
		if adornee:IsA("BasePart") then
			position = adornee.Position
		elseif adornee:IsA("Model") then
			position = adornee:GetPivot().Position
		end
	end

	local root = getRootPart()
	if position and root and (position - root.Position).Magnitude > AutoInteractRange then
		return
	end

	local now = os.clock()
	local last = autoInteractCooldowns[interactable]
	if last and now - last < AutoInteractCooldown then
		return
	end
	autoInteractCooldowns[interactable] = now

	if interactable:IsA("ProximityPrompt") then
		triggerPrompt(interactable)
	elseif interactable:IsA("ClickDetector") then
		if type(fireclickdetector) == "function" then
			pcall(fireclickdetector, interactable)
		end
	end
end

local function autoInteractStep()
	if not autoInteractEnabled then
		return
	end

	local root = getRootPart()
	if not root then
		return
	end

	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		return
	end

	for _, room in ipairs(generatedRooms:GetChildren()) do
		if room.Name:match(RoomNamePattern) then
			local roomPosition = room:IsA("Model") and room:GetPivot().Position or nil
			local inRange = true
			if roomPosition then
				inRange = (roomPosition - root.Position).Magnitude <= 200
			end

			local addedAssets = inRange and room:FindFirstChild("AddedAssets") or nil
			if addedAssets then
				for _, descendant in ipairs(addedAssets:GetDescendants()) do
					if descendant:IsA("ProximityPrompt") then
						if descendant.Enabled and not isLockerInteraction(descendant) then
							fireInteractable(descendant)
						end
					elseif descendant:IsA("ClickDetector") then
						if not isLockerInteraction(descendant) then
							fireInteractable(descendant)
						end
					end
				end
			end
		end
	end
end

local function stopAutoInteract()
	if autoInteractConnection then
		autoInteractConnection:Disconnect()
		autoInteractConnection = nil
	end
	table.clear(autoInteractCooldowns)
end

local function startAutoInteract()
	stopAutoInteract()
	autoInteractAccumulator = 0
	autoInteractConnection = RunService.Heartbeat:Connect(function(deltaTime)
		autoInteractAccumulator = autoInteractAccumulator + deltaTime
		if autoInteractAccumulator < AutoInteractInterval then
			return
		end
		autoInteractAccumulator = 0
		autoInteractStep()
	end)
end

Toggles.AutoInteract:OnChanged(function(Value)
	autoInteractEnabled = Value
	if Value then
		startAutoInteract()
	else
		stopAutoInteract()
	end
end)

loadingStatus("loading debug handlers", 0.92)

-- =========================================================
-- Debug
-- =========================================================

local logEntitySpawnsEnabled = false
local logRaycastsEnabled = false
local showRaycastsEnabled = false
local raycastVisuals = {}

local RayVisualFolder = Instance.new("Folder")
RayVisualFolder.Name = "mspaint_raycasts"
RayVisualFolder.Parent = EspFolder

local function debugPrint(...)
	print("[mspaint debug]", ...)
end

local function clearRaycastVisuals()
	for _, visual in ipairs(raycastVisuals) do
		if visual and visual.Parent then
			visual:Destroy()
		end
	end
	table.clear(raycastVisuals)
end

local function createRaycastVisual(origin, direction)
	local length = direction.Magnitude
	if length < 0.01 then
		return
	end

	if #raycastVisuals >= 300 then
		local oldest = table.remove(raycastVisuals, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	local visual = Instance.new("Part")
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanQuery = false
	visual.CanTouch = false
	visual.CastShadow = false
	visual.Material = Enum.Material.Neon
	visual.Color = Color3.fromRGB(255, 90, 90)
	visual.Size = Vector3.new(0.05, 0.05, length)
	visual.CFrame = CFrame.lookAt(origin + direction * 0.5, origin + direction)
	visual.Parent = RayVisualFolder

	table.insert(raycastVisuals, visual)

	task.delay(Options.RaycastVisualTime.Value, function()
		if visual and visual.Parent then
			visual:Destroy()
		end
	end)
end

Workspace.DescendantAdded:Connect(function(descendant)
	if not logEntitySpawnsEnabled then
		return
	end

	for _, name in ipairs(EntityNames) do
		if descendant.Name == name then
			local part = descendant
			if descendant:IsA("Model") then
				part = descendant.PrimaryPart or descendant:FindFirstChildWhichIsA("BasePart", true)
			end

			local position = part and part:IsA("BasePart") and tostring(part.Position) or "?"
			debugPrint("entity spawned:", name, "at", position)
			return
		end
	end
end)

local originalNamecall
if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
	local function raycastHook(self, ...)
		if (showRaycastsEnabled or logRaycastsEnabled) and getnamecallmethod() == "Raycast" then
			local origin, direction = ...
			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				if showRaycastsEnabled then
					createRaycastVisual(origin, direction)
				end
				if logRaycastsEnabled then
					debugPrint("raycast", tostring(origin), "->", tostring(direction))
				end
			end
		end

		return originalNamecall(self, ...)
	end

	if type(newcclosure) == "function" then
		raycastHook = newcclosure(raycastHook)
	end

	originalNamecall = hookmetamethod(game, "__namecall", raycastHook)
end

Toggles.LogEntitySpawns:OnChanged(function(Value)
	logEntitySpawnsEnabled = Value
end)

Toggles.LogRaycasts:OnChanged(function(Value)
	logRaycastsEnabled = Value
end)

Toggles.ShowRaycasts:OnChanged(function(Value)
	showRaycastsEnabled = Value
	if not Value then
		clearRaycastVisuals()
	end
end)

loadingStatus("loading autoplay", 0.93)

-- =========================================================
-- Autoplay
-- =========================================================

local autoplayEnabled = false
local autoplayLastRoom = 0

local function doorRoomNumber(door)
	local current = door
	while current and current ~= Workspace do
		if current.Name:match(RoomNamePattern) then
			local number = tonumber(current.Name:match("%d+"))
			if number then
				return number
			end
		end
		current = current.Parent
	end
	return nil
end

local function doorPosition(door)
	if door:IsA("BasePart") then
		return door.Position
	end
	if door:IsA("Model") then
		return door:GetPivot().Position
	end
	return nil
end

local function playerRoomNumber()
	local root = getRootPart()
	if not root then
		return nil
	end

	local generatedRooms = Workspace:FindFirstChild("GeneratedRooms")
	if not generatedRooms then
		return nil
	end

	for _, room in ipairs(generatedRooms:GetChildren()) do
		local number = room.Name:match(RoomNamePattern) and tonumber(room.Name:match("%d+"))
		if number then
			local ok, boxCFrame, boxSize = pcall(function()
				return room:GetBoundingBox()
			end)
			if ok and boxCFrame then
				local localPosition = boxCFrame:PointToObjectSpace(root.Position)
				if math.abs(localPosition.X) <= boxSize.X / 2 + 5 and math.abs(localPosition.Z) <= boxSize.Z / 2 + 5 then
					return number
				end
			end
		end
	end

	return nil
end

local function findDoorByRoom(roomNumber)
	for _, door in ipairs(collectDoors()) do
		if doorRoomNumber(door) == roomNumber then
			return door
		end
	end
	return nil
end

local function fireInteractablesIn(container, onlyDoorNamed)
	for _, descendant in ipairs(container:GetDescendants()) do
		local relevant = not onlyDoorNamed or descendant.Name:lower():find("door") ~= nil
		if relevant and descendant:IsA("ProximityPrompt") and descendant.Enabled then
			triggerPrompt(descendant)
		elseif relevant and descendant:IsA("ClickDetector") then
			if type(fireclickdetector) == "function" then
				pcall(fireclickdetector, descendant)
			end
		end
	end
end

local function openDoor(door)
	fireInteractablesIn(door, false)
	if door.Parent then
		fireInteractablesIn(door.Parent, true)
	end
end

local function findNearestLocker()
	local root = getRootPart()
	if not root then
		return nil
	end

	local best
	local bestDistance
	for _, locker in ipairs(collectLockers()) do
		local position = getWorldPosition(locker)
		local distance = (position - root.Position).Magnitude
		if not bestDistance or distance < bestDistance then
			best = locker
			bestDistance = distance
		end
	end

	return best
end

local function autoplayStep()
	-- Hide in a locker while Rush / Ram are active
	local entity = getSpawnedEntity()
	if entity then
		local locker = findNearestLocker()
		local root = getRootPart()
		if locker and root then
			root.CFrame = CFrame.new(getWorldPosition(locker))
		end
		return
	end

	local room = playerRoomNumber()
	if room then
		autoplayLastRoom = math.max(autoplayLastRoom, room)
	end

	local door = findDoorByRoom(autoplayLastRoom + 1)
	if not door then
		return
	end

	local root = getRootPart()
	local position = doorPosition(door)
	if not root or not position then
		return
	end

	root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	openDoor(door)
end

local function startAutoplay()
	task.spawn(function()
		while autoplayEnabled and not Library.Unloaded do
			pcall(autoplayStep)
			task.wait(Options.AutoplayDelay.Value)
		end
	end)
end

Toggles.Autoplay:OnChanged(function(Value)
	autoplayEnabled = Value
	if Value then
		autoplayLastRoom = 0
		startAutoplay()
	end
end)

-- =========================================================
-- Execute on Teleport
-- =========================================================

local function queueExecuteOnTeleport()
	local loader = ExecuteOnTeleportLoader
	if loader == "" then
		Library:Notify({
			Title = "Execute on Teleport",
			Description = "Set the Teleport Loader first.",
			Icon = "triangle-alert",
			Time = 5,
		})
		return false
	end

	if type(queue_on_teleport) ~= "function" then
		Library:Notify({
			Title = "Execute on Teleport",
			Description = "queue_on_teleport is not supported by this executor.",
			Icon = "triangle-alert",
			Time = 5,
		})
		return false
	end

	queue_on_teleport(loader)
	Library:Notify({
		Title = "Execute on Teleport",
		Description = "Queued. It will run after you teleport.",
		Time = 5,
	})
	return true
end

loadingStatus("starting esp loop", 0.96)

-- =========================================================
-- Main loop
-- =========================================================

local doorEspEnabled = false
local entityEspEnabled = false
local entityEspFill = true
local entityEspFillTransparency = 0.5
local lockerEspEnabled = false
local playerEspEnabled = false
local minecartEspEnabled = false
local objectiveEspEnabled = false
local notifySelections = { Rush = true }

Toggles.DoorESP:OnChanged(function(Value)
	doorEspEnabled = Value
end)

Toggles.EntityESP:OnChanged(function(Value)
	entityEspEnabled = Value
end)

Toggles.EntityESPFill:OnChanged(function(Value)
	entityEspFill = Value
end)

Options.EntityESPFillTransparency:OnChanged(function(Value)
	entityEspFillTransparency = Value
end)

Toggles.LockerESP:OnChanged(function(Value)
	lockerEspEnabled = Value
end)

Toggles.PlayerESP:OnChanged(function(Value)
	playerEspEnabled = Value
end)

Toggles.MinecartESP:OnChanged(function(Value)
	minecartEspEnabled = Value
end)

Toggles.ObjectiveESP:OnChanged(function(Value)
	objectiveEspEnabled = Value
end)

Options.EntityESPFilter:OnChanged(function(Value)
	entityEspSelections = Value or {}
end)

if IsVerPlace then
	Options.EntityESPFilter:SetValue({ VER = true })
elseif IsGraveyard then
	Options.EntityESPFilter:SetValue({ Hisoka = true })
else
	Options.EntityESPFilter:SetValue({
		Rush = true,
		Ram = true,
		Stare = true,
		Eyes = true,
		Peakaboo = true,
		Hisoka = true,
		Ambush = true,
	})
end

loadingStatus("loading spawn notifier", 0.97)

-- =========================================================
-- Spawn notifier
-- =========================================================

local NotifyCooldown = 3
local lastNotifyAt = {}

local function notifyEntity(name)
	if not notifySelections[name] then
		return
	end

	local now = os.clock()
	if now - (lastNotifyAt[name] or -math.huge) < NotifyCooldown then
		return
	end
	lastNotifyAt[name] = now

	Library:Notify({
		Title = "Entity Spawned",
		Description = name .. " has spawned!",
		Icon = "triangle-alert",
		Time = 6,
	})
end

Options.NotifierEntities:OnChanged(function(Value)
	notifySelections = Value or {}
end)

if IsGraveyard then
	Options.NotifierEntities:SetValue({ Hisoka = true })
end

-- =========================================================
-- Floor handling (re-runs whenever GameStyle changes)
-- =========================================================

local AllNotifierEntities = { "Rush", "Screech", "Ram", "Stare", "Eyes", "Hisoka", "Ambush" }

local function applyGameStyle(style)
	if IsVerPlace then
		return
	end
	local graveyard = string.lower(style or "") == "graveyard"

	if graveyard then
		if not Tabs.Floor then
			Tabs.Floor = Window:AddTab("Floor", "graveyard")
		end
		Options.EntityESPFilter:SetValues(GraveyardEntityEspNames)
		Options.EntityESPFilter:SetValue({ Hisoka = true })
		Options.NotifierEntities:SetValues(GraveyardEntityNames)
		Options.NotifierEntities:SetValue({ Hisoka = true })
	else
		if Tabs.Floor then
			if Library.ActiveTab == Tabs.Floor then
				Tabs.Changelog:Show()
			end
			Tabs.Floor:Destroy()
			Tabs.Floor = nil
		end
		Options.EntityESPFilter:SetValues(EntityEspNames)
		Options.EntityESPFilter:SetValue({
			Rush = true,
			Ram = true,
			Stare = true,
			Eyes = true,
			Peakaboo = true,
			Hisoka = true,
			Ambush = true,
		})
		Options.NotifierEntities:SetValues(AllNotifierEntities)
		Options.NotifierEntities:SetValue({ Rush = true })
	end
end

if GameStyleValue then
	GameStyleValue:GetPropertyChangedSignal("Value"):Connect(function()
		applyGameStyle(GameStyleValue.Value)
	end)
end

-- Rush (and anything else in EntityNames) spawns in the workspace
Workspace.DescendantAdded:Connect(function(descendant)
	for _, name in ipairs(EntityNames) do
		if descendant.Name == name then
			notifyEntity(name)
			break
		end
	end
end)

-- Screech spawns inside the camera as a Model
local cameraConnection

local function bindCameraNotifier()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = camera.ChildAdded:Connect(function(child)
			if child:IsA("Model") and child.Name:lower() == "model" then
				notifyEntity("Screech")
			end
		end)
	end
end

bindCameraNotifier()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCameraNotifier)

task.spawn(function()
	while not Library.Unloaded do
		local doorColor = Options.DoorESPColor.Value
		local entityColor = Options.EntityESPColor.Value
		local lockerColor = Options.LockerESPColor.Value
		local playerColor = Options.PlayerESPColor.Value
		local objectiveColor = Options.ObjectiveESPColor.Value

		local entityFill = entityEspFill and entityEspFillTransparency or 1

		updateSet(doorCache, collectDoors(), doorEspEnabled, doorColor, function()
			return "Door"
		end)

		updateSet(entityCache, collectEntities(), entityEspEnabled, entityColor, entityDisplayName, entityFill, true)

		updateSet(lockerCache, collectLockers(), lockerEspEnabled, lockerColor, function()
			return "Locker"
		end)

		updateSet(playerCache, collectPlayers(), playerEspEnabled, playerColor, function(target)
			return target.Name
		end)

		updateSet(objectiveCache, collectObjectives(), objectiveEspEnabled, objectiveColor, function()
			return "Objective"
		end)

		updateMinecartEsp(minecartEspEnabled, Options.MinecartESPColor.Value)

		task.wait(0.1)
	end

	for _, entry in pairs(doorCache) do
		destroyEntry(entry)
	end
	for _, entry in pairs(entityCache) do
		destroyEntry(entry)
	end
	for _, entry in pairs(lockerCache) do
		destroyEntry(entry)
	end
	for _, entry in pairs(playerCache) do
		destroyEntry(entry)
	end
	for _, entry in pairs(objectiveCache) do
		destroyEntry(entry)
	end
	clearAllMinecarts()
end)

Library:OnUnload(function()
	if movementConnection then
		movementConnection:Disconnect()
	end
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	stopFly()
	if speedBodyVelocity then
		speedBodyVelocity:Destroy()
		speedBodyVelocity = nil
	end
	restoreNoclip()
	removeFullbright()
	stopAntiEyes()
	stopAvoidEntities()
	stopVoidEffect()
	stopAutoInteract()
	stopPositionOffset()
	clearRaycastVisuals()
	if originalNamecall and type(hookmetamethod) == "function" then
		pcall(function()
			hookmetamethod(game, "__namecall", originalNamecall)
		end)
	end
	clearAllMinecarts()
	if EspFolder then
		EspFolder:Destroy()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		camera.FieldOfView = initialFov
	end
end)

loadingStatus("loading settings", 0.98)

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

MenuGroup:AddInput("TeleportLoader", {
	Text = "Teleport Loader",
	Default = ExecuteOnTeleportLoader,
	Placeholder = 'loadstring(game:HttpGet("..."))()',
	Finished = false,
	Tooltip = "Script that runs after you teleport",
	Callback = function(Value)
		ExecuteOnTeleportLoader = Value
	end,
})

MenuGroup:AddToggle("ExecuteOnTeleport", {
	Text = "Execute on Teleport",
	Default = false,
	Tooltip = "Queues the Teleport Loader to run after teleporting",
	Callback = function(Value)
		if Value and not queueExecuteOnTeleport() then
			Toggles.ExecuteOnTeleport:SetValue(false)
		end
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
SaveManager:SetFolder("AnticheatTest/my-game")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- Place 134208374070897: keep only Character + Visuals, with Entity ESP on "VER".
-- The tab buttons are removed and the containers hidden (not destroyed) so the
-- menu keybind and all option objects keep working.
if IsVerPlace then
	local function hideVerTab(name)
		local tab = Tabs[name]
		if not tab then
			return
		end
		if tab.Button then
			tab.Button:Destroy()
		end
		if tab.Container then
			tab.Container.Visible = false
		end
		Library.Tabs[name] = nil
	end

	Tabs.Character:Show()
	hideVerTab("Changelog")
	hideVerTab("Notifier")
	hideVerTab("Exploit")
	hideVerTab("Debug")
	hideVerTab("UI Settings")
	hideVerTab("Floor")

	Toggles.EntityESP:SetValue(true)
end

loadingStatus("ready", 1)
task.delay(0.4, finishLoading)

end

__entry()
