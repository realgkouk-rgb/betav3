-- RELOAD SETUP: store the main run function in _G so reload can call it again
local function GkoukHubMain()

-- Clean up any previous instance
if _G.GkoukHubCleanup then
	_G.GkoukHubCleanup()
end

local _connections = {}
local function trackConn(c) table.insert(_connections, c) end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

----------------------------------------------------
-- STATE
----------------------------------------------------
local flyEnabled = false
local noclipEnabled = false
local waterWalkEnabled = false
local waterPlatform
local waterLevel
local speedEnabled = false
local espEnabled = false

local speed = 140
local minSpeed, maxSpeed = 20, 350

local flyConn, bv, bg

local minimized = false
local normalSize
----------------------------------------------------
-- GUI
----------------------------------------------------
-- Destroy any leftover GUI from a previous run
if _G.GkoukHubGui and _G.GkoukHubGui.Parent then
	_G.GkoukHubGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "GkouksHub"
gui.ResetOnSpawn = false
gui.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui") or player:FindFirstChild("PlayerGui")
_G.GkoukHubGui = gui  -- store so next run can destroy it

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 440)
frame.Position = UDim2.new(0.35, 0, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)
frame.BorderSizePixel = 0
frame.Parent = gui

--
normalSize = frame.Size
Instance.new("UICorner", frame)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70,70,80)
stroke.Parent = frame
---------------------------------------------------
waterPlatform = Instance.new("Part")
waterPlatform.Name = "WaterWalkPlatform"
waterPlatform.Size = Vector3.new(8, 1, 8)
waterPlatform.Anchored = true
waterPlatform.Transparency = 1
waterPlatform.CanCollide = true
waterPlatform.Parent = workspace

----------------------------------------------------
-- TOP BAR
----------------------------------------------------
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 35)
top.BackgroundColor3 = Color3.fromRGB(20,20,25)
top.Parent = frame
Instance.new("UICorner", top)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -140, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ G.kouk's Hub"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

----------------------------------------------------
-- CLOSE
----------------------------------------------------
local close = Instance.new("TextButton")
Instance.new("UICorner", close)
close.Size = UDim2.new(0, 30, 0, 25)
close.Position = UDim2.new(1, -35, 0, 5)
close.Text = "✖"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.BackgroundColor3 = Color3.fromRGB(170,50,50)
close.TextColor3 = Color3.new(1,1,1)
close.Parent = top
Instance.new("UICorner", close)

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 30, 0, 25)
minimize.Position = UDim2.new(1, -70, 0, 5)
minimize.Text = "—"
minimize.Font = Enum.Font.GothamBold
minimize.TextSize = 16
minimize.BackgroundColor3 = Color3.fromRGB(60,60,70)
minimize.TextColor3 = Color3.new(1,1,1)
minimize.Parent = top
Instance.new("UICorner", minimize)

----------------------------------------------------
-- RELOAD BUTTON
----------------------------------------------------
local reloadBtn = Instance.new("TextButton")
reloadBtn.Size = UDim2.new(0, 55, 0, 25)
reloadBtn.Position = UDim2.new(1, -130, 0, 5)
reloadBtn.Text = "🔄 Reload"
reloadBtn.Font = Enum.Font.GothamBold
reloadBtn.TextSize = 11
reloadBtn.BackgroundColor3 = Color3.fromRGB(40,100,60)
reloadBtn.TextColor3 = Color3.new(1,1,1)
reloadBtn.Parent = top
Instance.new("UICorner", reloadBtn)

reloadBtn.MouseButton1Click:Connect(function()
	-- Delay one frame so the click handler finishes before cleanup destroys this GUI
	task.defer(function()
		if _G.GkoukHubRun then
			_G.GkoukHubRun()
		end
	end)
end)

----------------------------------------------------
-- DRAG
----------------------------------------------------
local dragging, dragStart, startPos

trackConn(top.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
	end
end))

trackConn(UserInputService.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = i.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end))

trackConn(UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end))

----------------------------------------------------
-- BUTTONS
----------------------------------------------------
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0.42, 0, 0, 35)
flyBtn.Position = UDim2.new(0.05, 0, 0, 75)
flyBtn.Text = "✈ FLY: OFF"
flyBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
flyBtn.TextColor3 = Color3.new(1,1,1)
flyBtn.Parent = frame
Instance.new("UICorner", flyBtn)

local noclipBtn = Instance.new("TextButton")
noclipBtn.Size = UDim2.new(0.42, 0, 0, 35)
noclipBtn.Position = UDim2.new(0.53, 0, 0, 75)
noclipBtn.Text = "🧱 NOCLIP: OFF"
noclipBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
noclipBtn.TextColor3 = Color3.new(1,1,1)
noclipBtn.Parent = frame
Instance.new("UICorner", noclipBtn)

local waterBtn = Instance.new("TextButton")
waterBtn.Size = UDim2.new(0.9, 0, 0, 35)
waterBtn.Position = UDim2.new(0.05, 0, 0, 395)
waterBtn.Text = "🌊 WATER WALK: OFF"
waterBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
waterBtn.TextColor3 = Color3.new(1,1,1)
waterBtn.Parent = frame
Instance.new("UICorner", waterBtn)

local fruitEspBtn = Instance.new("TextButton")
fruitEspBtn.Size = UDim2.new(0.9, 0, 0, 35)
fruitEspBtn.Position = UDim2.new(0.05, 0, 0, 305)
fruitEspBtn.Text = "🍎 FRUIT ESP: OFF"
fruitEspBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
fruitEspBtn.TextColor3 = Color3.new(1,1,1)
fruitEspBtn.Parent = frame
Instance.new("UICorner", fruitEspBtn)

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0.9, 0, 0, 35)
espBtn.Position = UDim2.new(0.05, 0, 0, 350)
espBtn.Text = "👀 ESP: OFF"
espBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
espBtn.TextColor3 = Color3.new(1,1,1)
espBtn.Parent = frame
Instance.new("UICorner", espBtn)

----------------------------------------------------
-- SPEED
----------------------------------------------------
local speedText = Instance.new("TextLabel")
speedText.Size = UDim2.new(1, -20, 0, 20)
speedText.Position = UDim2.new(0, 10, 0, 120)
speedText.BackgroundTransparency = 1
speedText.Text = "⚡ SPEED: "..speed
speedText.TextColor3 = Color3.fromRGB(200,200,200)
speedText.Parent = frame

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0.9, 0, 0, 8)
bar.Position = UDim2.new(0.05, 0, 0, 145)
bar.BackgroundColor3 = Color3.fromRGB(40,40,45)
bar.Parent = frame
Instance.new("UICorner", bar)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.4, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0,170,255)
fill.Parent = bar
Instance.new("UICorner", fill)

local draggingSlider = false

trackConn(bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
	end
end))

trackConn(UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end))

trackConn(UserInputService.InputChanged:Connect(function(i)
	if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
		local x = i.Position.X
		local bx = bar.AbsolutePosition.X
		local w = bar.AbsoluteSize.X

		local a = math.clamp((x - bx) / w, 0, 1)

		fill.Size = UDim2.new(a, 0, 1, 0)

		speed = math.floor(minSpeed + (maxSpeed - minSpeed) * a)
		speedText.Text = "⚡ SPEED: "..speed
	end
end))

----------------------------------------------------
-- CHARACTER
----------------------------------------------------
local function char()
	local c = player.Character
	if not c then return end
	return c, c:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------
-- NOCLIP
----------------------------------------------------
local function setNoclip(state)
	local c = player.Character
	if not c then return end

	for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not state
		end
	end
end

----------------------------------------------------
-- ESP
----------------------------------------------------
local espConnections = {}

local function removeESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			local highlight = plr.Character:FindFirstChild("ESPHighlight")
			if highlight then
				highlight:Destroy()
			end

			local head = plr.Character:FindFirstChild("Head")
			if head then
				local tag = head:FindFirstChild("ESPTag")
				if tag then
					tag:Destroy()
				end
			end
		end
	end

	for _, conn in ipairs(espConnections) do
		conn:Disconnect()
	end

	table.clear(espConnections)
end

local function createESP(plr)
	if plr == player then
		return
	end

	local function setup(character)
		if not espEnabled then
			return
		end

		local head = character:WaitForChild("Head", 5)
		if not head then
			return
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.FillTransparency = 1
		highlight.OutlineColor = Color3.fromRGB(255,0,0)
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = character

		local gui = Instance.new("BillboardGui")
		gui.Name = "ESPTag"
		gui.Size = UDim2.new(0,200,0,50)
		gui.StudsOffset = Vector3.new(0,2.5,0)
		gui.AlwaysOnTop = true
		gui.Parent = head

		local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.Parent = gui

		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not espEnabled then
				return
			end

			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local targetRoot = character:FindFirstChild("HumanoidRootPart")

			if myRoot and targetRoot then
				local distance = math.floor(
					(myRoot.Position - targetRoot.Position).Magnitude
				)

				label.Text = plr.Name .. "\n" .. distance .. " studs"
			end
		end)

		table.insert(espConnections, conn)
	end

	if plr.Character then
		setup(plr.Character)
	end

	plr.CharacterAdded:Connect(setup)
end

local function setesp(state)
	if state then
		for _, plr in ipairs(Players:GetPlayers()) do
			createESP(plr)
		end
	else
		removeESP()
	end
end

----------------------------------------------------
-- FRUIT ESP
----------------------------------------------------

local fruitESPEnabled = false
local fruitESPObjects = {} -- stores {highlight, billboardGui, label, hrp, itemName}
local fruitESPConn = nil

-- Keywords that identify devil fruits in Blox Fruits workspace
local FRUIT_KEYWORDS = {"fruit ", "venom fruit", "t-rex", "spirit", "kitsune fruit", "gravity", "shadow fruit", "control fruit", "quake", "spider", "lighting fruit", "phoenix", "creation", "love", "blizzard", "sound", "buddha", "light fruit", "magma fruit", "ghost fruit", "rubber", "ice fruit", "diamond fruit", "dark fruit", "eagle fruit", "flame fruit", "sand fruit", "spin", "smoke fruit", "spring fruit", "blade fruit", "spike fruit", "rocket", "bomb", "pain fruit", "portal fruit", "mammoth", "dough", "gas", "tiger", "yeti", "dragon (west) fruit", "dragon (east) fruit"}

local function clearFruitESP()
	if fruitESPConn then
		fruitESPConn:Disconnect()
		fruitESPConn = nil
	end
	for _, obj in ipairs(fruitESPObjects) do
		pcall(function()
			-- obj.highlight may be a Connection (the watcher) or an Instance
			if typeof(obj.highlight) == "RBXScriptConnection" then
				obj.highlight:Disconnect()
			elseif obj.highlight and obj.highlight.Parent then
				obj.highlight:Destroy()
			end
			if obj.billboard and obj.billboard.Parent then obj.billboard:Destroy() end
		end)
	end
	table.clear(fruitESPObjects)
_G.GkoukHubCleanup = function()
	-- Stop fly physics objects
	if bv then pcall(function() bv:Destroy() end) bv = nil end
	if bg then pcall(function() bg:Destroy() end) bg = nil end
	-- Clear fruit ESP (highlights, billboards, watcher connection)
	pcall(clearFruitESP)
	-- Disconnect all tracked connections
	for _, c in ipairs(_connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(_connections)
	-- Destroy water platform
	if waterPlatform and waterPlatform.Parent then
		pcall(function() waterPlatform:Destroy() end)
	end
	-- Destroy GUI
	local old = gui
	if old and old.Parent then old:Destroy() end
end

end

local function buildFruitESP()
	clearFruitESP()
	if not fruitESPEnabled then return end

	for _, item in ipairs(workspace:GetDescendants()) do
		if not (item:IsA("Model") or item:IsA("BasePart")) then continue end

		local lname = item.Name:lower()
		local isFruit = false
		for _, kw in ipairs(FRUIT_KEYWORDS) do
			if lname:find(kw) then isFruit = true break end
		end
		if not isFruit then continue end

		-- Get a BasePart to attach to
		local anchor
		if item:IsA("BasePart") then
			anchor = item
		elseif item:IsA("Model") then
			anchor = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
		end
		if not anchor then continue end

		-- Highlight
		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(255, 100, 200)
		hl.FillTransparency = 0.3
		hl.OutlineColor = Color3.fromRGB(255, 0, 150)
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = anchor
		hl.Parent = anchor

		-- Billboard
		local bb = Instance.new("BillboardGui")
		bb.Name = "FruitESP"
		bb.Size = UDim2.new(0, 180, 0, 50)
		bb.StudsOffset = Vector3.new(0, 4, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 0  -- show at any distance
		bb.Parent = anchor

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(255, 220, 255)
		lbl.TextStrokeTransparency = 0
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = item.Name
		lbl.Parent = bb

		table.insert(fruitESPObjects, {
			highlight = hl,
			billboard = bb,
			label = lbl,
			anchor = anchor,
			itemName = item.Name,
		})
	end

	-- Live distance updater (throttled: updates every 0.2s, not every frame)
	local lastUpdate = 0
	fruitESPConn = RunService.Heartbeat:Connect(function()
		if not fruitESPEnabled then return end
		local now = tick()
		if now - lastUpdate < 0.2 then return end
		lastUpdate = now

		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for _, obj in ipairs(fruitESPObjects) do
			if obj.label and obj.label.Parent then
				if hrp and obj.anchor and obj.anchor.Parent then
					local dist = math.floor((hrp.Position - obj.anchor.Position).Magnitude)
					obj.label.Text = obj.itemName .. "\n" .. dist .. "m"
				else
					obj.label.Text = obj.itemName
				end
			end
		end
	end)

	-- Watch for new fruits using DescendantAdded (no polling needed)
	local watchConn
	watchConn = workspace.DescendantAdded:Connect(function(item)
		if not fruitESPEnabled then return end
		if not (item:IsA("Model") or item:IsA("BasePart")) then return end
		local lname = item.Name:lower()
		for _, kw in ipairs(FRUIT_KEYWORDS) do
			if lname:find(kw) then
				task.wait() -- let it fully load
				local anchor
				if item:IsA("BasePart") then
					anchor = item
				elseif item:IsA("Model") then
					anchor = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
				end
				if not anchor then return end

				local hl = Instance.new("Highlight")
				hl.FillColor = Color3.fromRGB(255, 100, 200)
				hl.FillTransparency = 0.3
				hl.OutlineColor = Color3.fromRGB(255, 0, 150)
				hl.OutlineTransparency = 0
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Adornee = anchor
				hl.Parent = anchor

				local bb = Instance.new("BillboardGui")
				bb.Name = "FruitESP"
				bb.Size = UDim2.new(0, 180, 0, 50)
				bb.StudsOffset = Vector3.new(0, 4, 0)
				bb.AlwaysOnTop = true
				bb.MaxDistance = 0
				bb.Parent = anchor

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.fromScale(1, 1)
				lbl.BackgroundTransparency = 1
				lbl.TextScaled = true
				lbl.TextColor3 = Color3.fromRGB(255, 220, 255)
				lbl.TextStrokeTransparency = 0
				lbl.Font = Enum.Font.GothamBold
				lbl.Text = item.Name
				lbl.Parent = bb

				table.insert(fruitESPObjects, {
					highlight = hl,
					billboard = bb,
					label = lbl,
					anchor = anchor,
					itemName = item.Name,
				})
				break
			end
		end
	end)
	table.insert(fruitESPObjects, {highlight = watchConn}) -- reuse cleanup table to disconnect watcher
end

----------------------------------------------------
-- FLY
----------------------------------------------------
local function enableFly()
	local _, hrp = char()
	if not hrp then return end

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9,1e9,1e9)
	bv.Parent = hrp

	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
	bg.P = 10000
	bg.Parent = hrp

	flyConn = RunService.RenderStepped:Connect(function()
		local _, root = char()
		if not root then return end

		local cam = workspace.CurrentCamera
		local move = Vector3.zero

		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += look end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= look end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += right end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= right end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end

		if move.Magnitude > 0 then
			move = move.Unit * speed
		end

		bv.Velocity = move
		bg.CFrame = cam.CFrame
	end)
	trackConn(flyConn)
end

local function disableFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
end


----------------------------------------------------
-- TOGGLES
----------------------------------------------------
flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled

	if flyEnabled then
		enableFly()
		flyBtn.Text = "✈ FLY: ON"
	else
		disableFly()
		flyBtn.Text = "✈ FLY: OFF"
	end
end)

noclipBtn.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	if not noclipEnabled then
		setNoclip(false)
		noclipBtn.Text = "🧱 NOCLIP: OFF"
	else
		noclipBtn.Text = "🧱 NOCLIP: ON"
	end
end)

trackConn(RunService.Stepped:Connect(function()
	if noclipEnabled then
		setNoclip(true)
	end
end))

trackConn(RunService.RenderStepped:Connect(function()
	if not waterWalkEnabled then
		return
	end

	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if not waterLevel then
		waterLevel = hrp.Position.Y - 6
	end

	waterPlatform.Position = Vector3.new(
		hrp.Position.X,
		waterLevel,
		hrp.Position.Z
	)
end))

local minimumY = 0.1

trackConn(RunService.Heartbeat:Connect(function()
	local c = player.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if hrp and hrp.Position.Y < minimumY then
		hrp.CFrame = CFrame.new(
			hrp.Position.X,
			minimumY,
			hrp.Position.Z
		)
	end
end))

espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled

	if espEnabled then
		setesp(true)
		espBtn.Text = "👀 ESP: ON"
	else
		setesp(false)
		espBtn.Text = "👀 ESP: OFF"
	end
end)

waterBtn.MouseButton1Click:Connect(function()
	waterWalkEnabled = not waterWalkEnabled

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

	if waterWalkEnabled then
		waterBtn.Text = "🌊 WATER WALK: ON"
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		end
	else
		waterBtn.Text = "🌊 WATER WALK: OFF"
		waterPlatform.Position = Vector3.new(0, -1000, 0)
		waterLevel = nil
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
		end
	end
end)

fruitEspBtn.MouseButton1Click:Connect(function()
	fruitESPEnabled = not fruitESPEnabled

	if fruitESPEnabled then
		fruitEspBtn.Text = "🍎 FRUIT ESP: ON"
		buildFruitESP()
	else
		fruitEspBtn.Text = "🍎 FRUIT ESP: OFF"
		clearFruitESP()
	end
end)

----------------------------------------------------
-- CLOSE
----------------------------------------------------
close.MouseButton1Click:Connect(function()
	flyEnabled = false
	noclipEnabled = false
	espEnabled = false
	fruitESPEnabled = false

	disableFly()
	setNoclip(false)
	setesp(false)

	clearFruitESP()

	gui:Destroy()
end)

----------------------------------------------------
-- RESPAWN FIX
----------------------------------------------------
trackConn(player.CharacterAdded:Connect(function()
	task.wait(0.5)
	if flyEnabled then
		enableFly()
	end
end))

----------------------------------------------------
-- GOTO VECTOR
----------------------------------------------------
local vectorBox = Instance.new("TextBox")
vectorBox.Size = UDim2.new(0.9, 0, 0, 30)
vectorBox.Position = UDim2.new(0.05, 0, 0, 175)
vectorBox.PlaceholderText = "X, Y, Z"
vectorBox.Text = ""
vectorBox.BackgroundColor3 = Color3.fromRGB(35,35,40)
vectorBox.TextColor3 = Color3.new(1,1,1)
vectorBox.ClearTextOnFocus = false
vectorBox.Parent = frame
Instance.new("UICorner", vectorBox)

local gotoBtn = Instance.new("TextButton")
gotoBtn.Size = UDim2.new(0.9, 0, 0, 35)
gotoBtn.Position = UDim2.new(0.05, 0, 0, 215)
gotoBtn.Text = "📍 GO TO VECTOR"
gotoBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
gotoBtn.TextColor3 = Color3.new(1,1,1)
gotoBtn.Parent = frame
Instance.new("UICorner", gotoBtn)

gotoBtn.MouseButton1Click:Connect(function()
	local x, y, z = string.match(
		vectorBox.Text,
		"([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)"
	)

	x, y, z = tonumber(x), tonumber(y), tonumber(z)

	if not (x and y and z) then
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return
	end

	-- Auto enable noclip
	noclipEnabled = true
	noclipBtn.Text = "🧱 NOCLIP: ON"

	local target = Vector3.new(x, y, z)
	local travelVelocity

	travelVelocity = Instance.new("BodyVelocity")
	travelVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	travelVelocity.Parent = hrp

	task.spawn(function()
		while hrp and hrp.Parent do
			local distance = (target - hrp.Position).Magnitude

			if distance <= 5 then
				break
			end

			local direction = (target - hrp.Position).Unit
			travelVelocity.Velocity = direction * speed

			task.wait()
		end

		-- Stop movement
		travelVelocity.Velocity = Vector3.zero
		travelVelocity:Destroy()

		-- Disable fly when destination reached
		flyEnabled = false
		disableFly()
		flyBtn.Text = "✈ FLY: OFF"
	end)
end)

local showVectorBtn = Instance.new("TextButton")
showVectorBtn.Size = UDim2.new(0.9, 0, 0, 35)
showVectorBtn.Position = UDim2.new(0.05, 0, 0, 260)
showVectorBtn.Text = "📍 SHOW VECTOR"
showVectorBtn.BackgroundColor3 = Color3.fromRGB(35,35,40)
showVectorBtn.TextColor3 = Color3.new(1,1,1)
showVectorBtn.Parent = frame
Instance.new("UICorner", showVectorBtn)

----------------------------------------------------
-- VECTOR WINDOW
----------------------------------------------------
local vectorGui = Instance.new("Frame")
vectorGui.Size = UDim2.new(0, 260, 0, 120)
vectorGui.Position = UDim2.new(0.5, -130, 0.3, 0)
vectorGui.BackgroundColor3 = Color3.fromRGB(25,25,30)
vectorGui.BorderSizePixel = 0
vectorGui.Visible = false
vectorGui.Parent = gui
Instance.new("UICorner", vectorGui)

local vectorStroke = Instance.new("UIStroke")
vectorStroke.Color = Color3.fromRGB(70,70,80)
vectorStroke.Parent = vectorGui

local vectorTop = Instance.new("Frame")
vectorTop.Size = UDim2.new(1,0,0,30)
vectorTop.BackgroundColor3 = Color3.fromRGB(20,20,25)
vectorTop.Parent = vectorGui
Instance.new("UICorner", vectorTop)

local vectorTitle = Instance.new("TextLabel")
vectorTitle.Size = UDim2.new(1,-40,1,0)
vectorTitle.Position = UDim2.new(0,10,0,0)
vectorTitle.BackgroundTransparency = 1
vectorTitle.Text = "📍 Current Vector"
vectorTitle.TextColor3 = Color3.new(1,1,1)
vectorTitle.Font = Enum.Font.GothamBold
vectorTitle.TextSize = 13
vectorTitle.TextXAlignment = Enum.TextXAlignment.Left
vectorTitle.Parent = vectorTop

local vectorClose = Instance.new("TextButton")
vectorClose.Size = UDim2.new(0,25,0,25)
vectorClose.Position = UDim2.new(1,-30,0,2)
vectorClose.Text = "✖"
vectorClose.BackgroundColor3 = Color3.fromRGB(170,50,50)
vectorClose.TextColor3 = Color3.new(1,1,1)
vectorClose.Parent = vectorTop
Instance.new("UICorner", vectorClose)

local vectorLabel = Instance.new("TextLabel")
vectorLabel.Size = UDim2.new(1,-20,0,60)
vectorLabel.Position = UDim2.new(0,10,0,45)
vectorLabel.BackgroundTransparency = 1
vectorLabel.TextColor3 = Color3.new(1,1,1)
vectorLabel.Font = Enum.Font.Code
vectorLabel.TextSize = 16
vectorLabel.TextWrapped = true
vectorLabel.Parent = vectorGui

----------------------------------------------------
-- OPEN/CLOSE
----------------------------------------------------
showVectorBtn.MouseButton1Click:Connect(function()
	vectorGui.Visible = true
end)

vectorClose.MouseButton1Click:Connect(function()
	vectorGui.Visible = false
end)

----------------------------------------------------
-- UPDATE VECTOR
----------------------------------------------------
trackConn(RunService.RenderStepped:Connect(function()
	if vectorGui.Visible then
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")

		if hrp then
			local p = hrp.Position
			vectorLabel.Text = string.format(
				"X: %.2f\nY: %.2f\nZ: %.2f",
				p.X,
				p.Y,
				p.Z
			)
		end
	end
end))

----------------------------------------------------
-- DRAGGING
----------------------------------------------------
local vDragging = false
local vDragStart
local vStartPos

trackConn(vectorTop.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		vDragging = true
		vDragStart = input.Position
		vStartPos = vectorGui.Position
	end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
	if vDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - vDragStart

		vectorGui.Position = UDim2.new(
			vStartPos.X.Scale,
			vStartPos.X.Offset + delta.X,
			vStartPos.Y.Scale,
			vStartPos.Y.Offset + delta.Y
		)
	end
end))

trackConn(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		vDragging = false
	end
end))

----------------------------------------------------
-- MINIMIZE TOGGLE
----------------------------------------------------
minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		frame.Size = UDim2.new(0, 340, 0, 50)

		flyBtn.Visible = false
		noclipBtn.Visible = false
		speedText.Visible = false
		bar.Visible = false
		fill.Visible = false
		vectorBox.Visible = false
		gotoBtn.Visible = false
		showVectorBtn.Visible = false
        waterBtn.Visible = false
		espBtn.Visible = false
		fruitEspBtn.Visible = false

		minimize.Text = "+"
	else
		frame.Size = normalSize

		flyBtn.Visible = true
		noclipBtn.Visible = true
		speedText.Visible = true
		bar.Visible = true
		fill.Visible = true
		vectorBox.Visible = true
		gotoBtn.Visible = true
		showVectorBtn.Visible = true
        waterBtn.Visible = true
		espBtn.Visible = true
		fruitEspBtn.Visible = true

		minimize.Text = "—"
	end
end)

end -- end GkoukHubMain

_G.GkoukHubRun = GkoukHubMain
GkoukHubMain()