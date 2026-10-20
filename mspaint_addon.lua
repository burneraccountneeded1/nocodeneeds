mspaint.AddonInfo = {
	Name = "mspaint_extra",
	Title = "mspaint Extras",
	Description = "Third person toggle and an on-screen keybind list",
	Game = "*",
}

local Library = mspaint.Library
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local thirdPersonBackup
local function applyThirdPerson(enabled)
	if enabled then
		if not thirdPersonBackup then
			thirdPersonBackup = {
				CameraMode = LocalPlayer.CameraMode,
				MinZoom = LocalPlayer.CameraMinZoomDistance,
				MaxZoom = LocalPlayer.CameraMaxZoomDistance,
			}
		end
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		LocalPlayer.CameraMaxZoomDistance = math.max(thirdPersonBackup.MaxZoom, 128)
		LocalPlayer.CameraMinZoomDistance = math.max(thirdPersonBackup.MinZoom, 12)
	elseif thirdPersonBackup then
		LocalPlayer.CameraMode = thirdPersonBackup.CameraMode
		LocalPlayer.CameraMinZoomDistance = thirdPersonBackup.MinZoom
		LocalPlayer.CameraMaxZoomDistance = thirdPersonBackup.MaxZoom
		thirdPersonBackup = nil
	end
end

mspaint.Groupbox:AddToggle("ExtrasThirdPerson", {
	Text = "Third Person",
	Default = false,
	Tooltip = "Locks the camera to third person (V)",
	Callback = function(Value)
		applyThirdPerson(Value)
	end,
}):AddKeyPicker("ExtrasThirdPersonKeybind", {
	Default = "V",
	Mode = "Toggle",
	SyncToggleState = true,
	Text = "Third person keybind",
})

mspaint.Groupbox:AddDivider()

local keybindOverlay
local keybindList
local lastSignature

local function escapeRichText(text)
	return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function collectKeybinds()
	local entries = {}
	for idx, opt in pairs(Library.Options) do
		if type(opt) == "table" and opt.Type == "KeyPicker" and opt.Value and opt.Value ~= "None" then
			local label = tostring(opt.Text or idx)
			entries[#entries + 1] = {
				Key = tostring(opt.DisplayValue or opt.Value),
				Label = label,
				Sort = label:lower(),
			}
		end
	end
	table.sort(entries, function(a, b)
		return a.Sort < b.Sort
	end)
	return entries
end

local function updateKeybindOverlay()
	if not keybindList then
		return
	end

	local entries = collectKeybinds()
	local parts = {}
	for _, entry in ipairs(entries) do
		parts[#parts + 1] = entry.Key .. "=" .. entry.Label
	end
	local signature = table.concat(parts, "|")
	if signature == lastSignature then
		return
	end
	lastSignature = signature

	for _, child in ipairs(keybindList:GetChildren()) do
		if child.Name == "Row" then
			child:Destroy()
		end
	end

	for _, entry in ipairs(entries) do
		local label = Instance.new("TextLabel")
		label.Name = "Row"
		label.Size = UDim2.new(1, 0, 0, 18)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(225, 225, 232)
		label.RichText = true
		label.Text = string.format(
			'<font color="#89b4fa"><b>%s</b></font>  %s',
			escapeRichText(entry.Key),
			escapeRichText(entry.Label)
		)
		label.Parent = keybindList
	end
end

local function createKeybindOverlay()
	local parent = (type(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "mspaint_extras_keybinds"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.Enabled = false
	gui.Parent = parent
	keybindOverlay = gui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Position = UDim2.new(0, 12, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	local list = Instance.new("Frame")
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundTransparency = 1
	list.Parent = frame
	keybindList = list

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 0
	title.Size = UDim2.new(1, 0, 0, 16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(137, 180, 250)
	title.Text = "KEYBINDS"
	title.Parent = list

	updateKeybindOverlay()
end

createKeybindOverlay()

local showKeybindsToggle = mspaint.Groupbox:AddToggle("ExtrasShowKeybinds", {
	Text = "Show Keybinds",
	Default = false,
	Tooltip = "Shows your keybinds on the left side of the screen",
	Callback = function(Value)
		if keybindOverlay then
			keybindOverlay.Enabled = Value
		end
		updateKeybindOverlay()
	end,
})

if showKeybindsToggle.Value then
	keybindOverlay.Enabled = true
	updateKeybindOverlay()
end

task.spawn(function()
	while keybindOverlay and keybindOverlay.Parent do
		if showKeybindsToggle.Value then
			updateKeybindOverlay()
		end
		task.wait(0.5)
	end
end)

if Library and Library.OnUnload then
	Library:OnUnload(function()
		applyThirdPerson(false)
		if keybindOverlay then
			keybindOverlay:Destroy()
		end
	end)
end
