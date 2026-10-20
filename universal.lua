local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local LobbyPlaceId = 18186775539
local StatusUrl = "https://raw.githubusercontent.com/burneraccountneeded1/nocodeneeds/refs/heads/main/STATUS.txt"

local function notifyCore(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 10,
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

local Status = readStatus()

if Status == "BROKEN" then
	local message = "This script is marked BROKEN in STATUS.txt. Please wait for a fix."
	pcall(function()
		Library:Notify({
			Title = "SCRIPT BROKEN",
			Description = message,
			Icon = "circle-x",
			Time = 15,
		})
	end)
	notifyCore("SCRIPT BROKEN", message, 15)
	warn("[universal] STATUS.txt says BROKEN - aborting.")
	return
end

local Window = Library:CreateWindow({
	Title = "mspaint universal",
	Icon = 95816097006870,
	NotifySide = "Right",
})

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

if Status == "FIXING" then
	Library:Notify({
		Title = "Script status: FIXING",
		Description = "This script is being fixed. Some features may be unstable.",
		Icon = "triangle-alert",
		Time = 8,
	})
elseif Status == "WORKING" then
	Library:Notify({
		Title = "Script status: WORKING",
		Description = "Universal script loaded for this place.",
		Icon = "circle-check",
		Time = 5,
	})
end

local Tab = Window:AddTab("Character", "person-standing")

local MovementGroupbox = Tab:AddGroupbox({
	Side = "Left",
	Name = "Movement",
	Description = "Character modifiers",
	IconName = "person-standing",
})

MovementGroupbox:AddToggle("EnableWalkSpeed", {
	Text = "WalkSpeed",
	Default = false,
	Tooltip = "Constantly re-applies WalkSpeed",
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

MovementGroupbox:AddDivider()

MovementGroupbox:AddToggle("Noclip", {
	Text = "Noclip",
	Default = false,
	Tooltip = "Disables collision on your character",
})

local ActionGroupbox = Tab:AddGroupbox({
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

local MenuGroupbox = Tab:AddGroupbox({
	Side = "Right",
	Name = "Menu",
	Description = "Menu settings",
	IconName = "wrench",
})

MenuGroupbox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

Library.ToggleKeybind = Options.MenuKeybind

MenuGroupbox:AddDivider()

MenuGroupbox:AddButton("Unload", function()
	Library:Unload()
end)

local walkSpeedEnabled = false
local walkSpeedValue = 16
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

Library:OnUnload(function()
	if movementConnection then
		movementConnection:Disconnect()
	end
	stopFly()
	restoreNoclip()
end)
