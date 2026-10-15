local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local http_service = game:GetService("HttpService")
local lp = players.LocalPlayer
local vec2 = Vector2.new
local cfr = CFrame.new
local rgb = Color3.fromRGB
local min, max, abs = math.min, math.max, math.abs
local FL_CONNS = {}
local function flConn(sig, fn)
	local c = sig:Connect(fn)
	table.insert(FL_CONNS, c)
	return c
end

local UI = (function()
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local lp = players.LocalPlayer

local UI = {}
UI.Flags = {}
UI.CBS = {}

local function guiParent()
	if gethui then local ok, h = pcall(gethui) if ok and h then return h end end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return lp:WaitForChild("PlayerGui")
end

local C = {
	bg = Color3.fromRGB(18, 18, 22),
	panel = Color3.fromRGB(26, 26, 33),
	head = Color3.fromRGB(34, 34, 44),
	row = Color3.fromRGB(30, 30, 40),
	rowHot = Color3.fromRGB(44, 40, 60),
	accent = Color3.fromRGB(150, 90, 255),
	accent2 = Color3.fromRGB(110, 200, 255),
	text = Color3.fromRGB(220, 220, 230),
	dim = Color3.fromRGB(140, 140, 155),
	on = Color3.fromRGB(120, 255, 140),
}

local function mk(cls, props, parent)
	local i = Instance.new(cls)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end

local function round(i, r) mk("UICorner", {CornerRadius = UDim.new(0, r or 6)}, i) end
local function pad(i, l, r, t, b)
	mk("UIPadding", {PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0)}, i)
end
local function draggable(handle, frame)
	local drag, ds, sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag, ds, sp = true, i.Position, frame.Position
		end
	end)
	uis.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - ds
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
	uis.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
	end)
end

function UI:Init(title)
	local sg = mk("ScreenGui", {Name = "waffle_clickgui", ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true}, guiParent())
	self.sg = sg
	self.x = 80
	self.title = title
	return sg
end

function UI:Category(name)
	local f = mk("Frame", {BackgroundColor3 = C.panel, BorderSizePixel = 0,
		Position = UDim2.new(0, self.x, 0, 90), Size = UDim2.new(0, 230, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y}, self.sg)
	round(f, 8)
	mk("UIStroke", {Color = Color3.fromRGB(60, 55, 80), Thickness = 1, Transparency = 0.3}, f)
	self.x = self.x + 244

	local head = mk("TextLabel", {BackgroundColor3 = C.head, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = C.accent2, Text = name}, f)
	round(head, 8)
	draggable(head, f)

	local list = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 0, 0, 32)}, f)
	mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, list)
	pad(list, 4, 4, 0, 6)

	local cat = {list = list, sg = self.sg}
	return setmetatable(cat, {__index = UI.Cat})
end

UI.Cat = {}
UI.Cat.__index = UI.Cat

local function fire(flag, v)
	local f = UI.CBS[flag]
	if f then pcall(f, v) end
end

local function bindableText(v)
	return type(v) == "string" and v or "MB2"
end

function UI.Cat:Label(text)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. text}, self.list)
	pad(self.list, 0)
end

function UI.Cat:Module(name, flag, def)
	UI.Flags[flag] = def == nil and false or def
	local holder = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y}, self.list)
	mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)}, holder)

	local btn = mk("TextButton", {BackgroundColor3 = C.row, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.GothamSemibold, TextSize = 13,
		TextColor3 = C.text, Text = "  " .. name, TextXAlignment = Enum.TextXAlignment.Left}, holder)
	round(btn, 5)

	local dot = mk("Frame", {BackgroundColor3 = C.dim, Size = UDim2.new(0, 5, 0, 16),
		Position = UDim2.new(1, -12, 0.5, -8)}, btn)
	round(dot, 3)

	local drop = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Visible = false}, holder)
	mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)}, drop)
	pad(drop, 14, 0, 0, 2)

	local mod = {drop = drop, flag = flag, sg = self.sg}
	local function paint()
		local on = UI.Flags[flag]
		btn.TextColor3 = on and C.on or C.text
		btn.BackgroundColor3 = on and C.rowHot or C.row
		dot.BackgroundColor3 = on and C.accent or C.dim
	end
	paint()
	btn.MouseButton1Click:Connect(function()
		UI.Flags[flag] = not UI.Flags[flag]
		fire(flag, UI.Flags[flag])
		paint()
	end)
	btn.MouseButton2Click:Connect(function()
		drop.Visible = not drop.Visible
	end)
	return setmetatable(mod, {__index = UI.Mod})
end

UI.Mod = {}
UI.Mod.__index = UI.Mod

local function settingRow(parent, label)
	local row = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22)}, parent)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0.55, 0, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = label}, row)
	return row
end

function UI.Mod:Toggle(name, flag, def)
	UI.Flags[flag] = def == nil and false or def
	local row = settingRow(self.drop, name)
	local box = mk("TextButton", {BackgroundColor3 = C.dim, BorderSizePixel = 0,
		Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -34, 0.5, -8),
		Text = ""}, row)
	round(box, 4)
	local knob = mk("Frame", {BackgroundColor3 = C.text, Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, 3, 0.5, -5)}, box)
	round(knob, 5)
	local function paint()
		local on = UI.Flags[flag]
		box.BackgroundColor3 = on and C.accent or C.dim
		knob.Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5)
	end
	paint()
	box.MouseButton1Click:Connect(function()
		UI.Flags[flag] = not UI.Flags[flag]
		fire(flag, UI.Flags[flag])
		paint()
	end)
end

function UI.Mod:Slider(name, flag, minV, maxV, def, step)
	UI.Flags[flag] = def
	step = step or 1
	local row = settingRow(self.drop, name)
	local val = mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 40, 1, 0),
		Position = UDim2.new(1, -40, 0, 0), Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = C.accent2, Text = tostring(def), TextXAlignment = Enum.TextXAlignment.Right}, row)
	local bar = mk("Frame", {BackgroundColor3 = C.head, Size = UDim2.new(0.42, 0, 0, 6),
		Position = UDim2.new(0.55, 2, 0.5, -3)}, row)
	round(bar, 3)
	local fill = mk("Frame", {BackgroundColor3 = C.accent, Size = UDim2.new(0, 0, 1, 0)}, bar)
	round(fill, 3)
	local function set(v)
		v = math.clamp(math.floor((v / step) + 0.5) * step, minV, maxV)
		UI.Flags[flag] = v
		val.Text = tostring(v)
		fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
		fire(flag, v)
	end
	set(def)
	local slid = false
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then slid = true end
	end)
	uis.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then slid = false end
	end)
	uis.InputChanged:Connect(function(i)
		if slid and i.UserInputType == Enum.UserInputType.MouseMovement then
			set(minV + (maxV - minV) * math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))
		end
	end)
end

function UI.Mod:Bind(name, flag, def)
	UI.Flags[flag] = def
	local row = settingRow(self.drop, name)
	local btn = mk("TextButton", {BackgroundColor3 = C.head, BorderSizePixel = 0,
		Size = UDim2.new(0, 62, 0, 16), Position = UDim2.new(1, -64, 0.5, -8),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.accent2, Text = bindableText(def)}, row)
	round(btn, 4)
	local binding = false
	btn.MouseButton1Click:Connect(function()
		binding = true
		btn.Text = "..."
		btn.TextColor3 = C.on
	end)
	uis.InputBegan:Connect(function(i, gpe)
		if not binding then return end
		binding = false
		btn.TextColor3 = C.accent2
		if i.UserInputType ~= Enum.UserInputType.Keyboard then
			UI.Flags[flag] = i.UserInputType.Name
		else
			UI.Flags[flag] = i.KeyCode.Name
		end
		btn.Text = UI.Flags[flag]
		fire(flag, UI.Flags[flag])
	end)
end

function UI.Mod:Dropdown(name, flag, values, def)
	UI.Flags[flag] = def
	local row = settingRow(self.drop, name)
	local btn = mk("TextButton", {BackgroundColor3 = C.head, BorderSizePixel = 0,
		Size = UDim2.new(0, 100, 0, 16), Position = UDim2.new(1, -102, 0.5, -8),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.accent2, Text = def}, row)
	round(btn, 4)
	btn.MouseButton1Click:Connect(function()
		local idx = table.find(values, UI.Flags[flag]) or 0
		idx = idx % #values + 1
		UI.Flags[flag] = values[idx]
		btn.Text = values[idx]
		fire(flag, values[idx])
	end)
	btn.MouseButton2Click:Connect(function()
		local idx = (table.find(values, UI.Flags[flag]) or 2) - 1
		if idx < 1 then idx = #values end
		UI.Flags[flag] = values[idx]
		btn.Text = values[idx]
		fire(flag, values[idx])
	end)
end

local PALETTE = {
	Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 230, 60),
	Color3.fromRGB(120, 255, 120), Color3.fromRGB(60, 200, 255), Color3.fromRGB(80, 200, 255),
	Color3.fromRGB(150, 90, 255), Color3.fromRGB(255, 100, 200), Color3.fromRGB(255, 255, 255),
}

function UI.Mod:Palette(name, flag, def)
	UI.Flags[flag] = def
	local row = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20)}, self.drop)
	mk("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = name}, row)
	local holder = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0)}, row)
	mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center}, holder)
	for _, c in ipairs(PALETTE) do
		local b = mk("TextButton", {BackgroundColor3 = c, Size = UDim2.new(0, 14, 0, 14),
			BorderSizePixel = 0, Text = ""}, holder)
		round(b, 3)
		b.MouseButton1Click:Connect(function() UI.Flags[flag] = c fire(flag, c) end)
	end
end

function UI.Cat:Button(name, cb)
	local btn = mk("TextButton", {BackgroundColor3 = C.row, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = C.text, Text = name}, self.list)
	round(btn, 5)
	btn.MouseButton1Click:Connect(function() pcall(cb) end)
end

function UI:Destroy()
	if self.sg then pcall(function() self.sg:Destroy() end) end
end

return UI

end)()

-- ===================== FRONTLINES // devin =====================
local FL_G = getrenv and getrenv()._G or _G
if FL_G.__flUnload then pcall(FL_G.__flUnload) FL_G.__flUnload = nil end

local Flags = UI.Flags

local function flag(name, default)
	local v = Flags[name]
	if v == nil then return default end
	return v
end

local CFG = {
	FOV = 220,
	AimPart = "Head",
	WallCheck = true,
	Smooth = 0,
}

local R15BONES = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6BONES = {
	{"Head","Torso"},
	{"Torso","Left Arm"},{"Torso","Right Arm"},
	{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local FLBONES = {
	{"Root_M","Spine1_M"},{"Spine1_M","Spine2_M"},{"Spine2_M","Chest_M"},
	{"Chest_M","Neck_M"},{"Neck_M","Head_M"},
	{"Chest_M","Scapula_L"},{"Scapula_L","Shoulder_L"},{"Shoulder_L","Elbow_L"},{"Elbow_L","Wrist_L"},
	{"Chest_M","Scapula_R"},{"Scapula_R","Shoulder_R"},{"Shoulder_R","Elbow_R"},{"Elbow_R","Wrist_R"},
	{"Root_M","Hip_L"},{"Hip_L","Knee_L"},{"Knee_L","Ankle_L"},{"Ankle_L","Toes_L"},
	{"Root_M","Hip_R"},{"Hip_R","Knee_R"},{"Knee_R","Ankle_R"},{"Ankle_R","Toes_R"},
}

local function teamId(p)
	if p == lp then
		local t = ws:GetAttribute("fl_myteam")
		if t ~= nil then return t end
	end
	local c = p.Character
	if c then
		local t = c:GetAttribute("fl_team")
		if t ~= nil then return t end
		if c:FindFirstChild("friendly_marker") then return teamId(lp) end
	end
	return p.Team or p:GetAttribute("Team") or p:GetAttribute("TeamId") or p:GetAttribute("Faction")
end
local function isEnemy(p)
	if not flag("team_check", true) then return true end
	local mine, theirs = teamId(lp), teamId(p)
	if mine == nil or theirs == nil then return true end
	return mine ~= theirs
end
local function humanoidOf(p)
	local c = p.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function rootOf(p)
	local c = p.Character
	if not c then return nil end
	return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
		or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
end
local function alive(p)
	local c = p.Character
	if c then
		local a = c:GetAttribute("fl_alive")
		if a ~= nil then return a == true end
	end
	local h = humanoidOf(p)
	if h then return h.Health > 0 and h:GetState() ~= Enum.HumanoidStateType.Dead end
	return rootOf(p) ~= nil
end
local function healthFrac(p)
	local c = p.Character
	if c then
		local hp = c:GetAttribute("fl_hp")
		if type(hp) == "number" then return math.clamp(hp / 100, 0, 1) end
	end
	local h = humanoidOf(p)
	if h and h.MaxHealth > 0 then return math.clamp(h.Health / h.MaxHealth, 0, 1) end
	return 1
end
local function aimPart(char)
	local flHead = char:FindFirstChild("Head_M", true)
	return char:FindFirstChild(CFG.AimPart)
		or flHead or char:FindFirstChild("TPVBodyVanillaHead")
		or char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
		or char.PrimaryPart
end
local function w2s(v3)
	local cam = ws.CurrentCamera
	if not cam then return vec2(0,0), false, 0 end
	local v, on = cam:WorldToViewportPoint(v3)
	return vec2(v.X, v.Y), on, v.Z
end
local function rayVisible(fromPos, toPos, ignoreChar)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {lp.Character, ignoreChar, ws.CurrentCamera}
	return ws:Raycast(fromPos, toPos - fromPos, rp) == nil
end

local function mkLine() local l = Drawing.new("Line") l.Thickness = 1.5 l.Visible = false return l end
local function mkText() local t = Drawing.new("Text") t.Size = 13 t.Center = true t.Outline = true t.Visible = false return t end

local function makeESP()
	local e = {
		box = {mkLine(),mkLine(),mkLine(),mkLine()},
		name = mkText(), dist = mkText(),
		hpBg = mkLine(), hpFg = mkLine(),
		tracer = mkLine(),
		arrow = Drawing.new("Triangle"),
		skel = {},
	}
	for i = 1, math.max(#R15BONES, #FLBONES) do e.skel[i] = mkLine() end
	return e
end

local FL_DEAD = false
local esp = {}
local modelEsp = {}
local function addPlayer(p) if p ~= lp then esp[p] = makeESP() end end
for _, p in ipairs(players:GetPlayers()) do addPlayer(p) end
players.PlayerAdded:Connect(addPlayer)

local function removeESP(e)
	if not e then return end
	for _, l in ipairs(e.box) do l:Remove() end
	e.name:Remove() e.dist:Remove() e.hpBg:Remove() e.hpFg:Remove() e.tracer:Remove() e.arrow:Remove()
	for _, l in ipairs(e.skel) do l:Remove() end
	if e.cham then e.cham:Destroy() end
end

players.PlayerRemoving:Connect(function(p)
	removeESP(esp[p])
	esp[p] = nil
end)

local claimedRigs = setmetatable({}, {__mode = "k"})
local function refreshRigs()
	for _, m in ipairs(ws:GetChildren()) do
		if m:IsA("Model") and not claimedRigs[m] and not m:GetAttribute("fl_mine") then
			local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
			local parts = 0
			for _, c in ipairs(m:GetChildren()) do
				if c:IsA("BasePart") then parts = parts + 1 end
			end
			local ok = m.Name == "soldier_model" and root and parts >= 10
			if not ok then
				local hum = m:FindFirstChildOfClass("Humanoid")
				ok = hum and root
			end
			if ok then
				local isPlayerChar = lp.Character == m
				if not isPlayerChar then
					for pl in pairs(esp) do
						if pl.Character == m then isPlayerChar = true break end
					end
				end
				if not isPlayerChar then
					claimedRigs[m] = true
					modelEsp[m] = {
						e = makeESP(),
						subj = {
							Character = m,
							DisplayName = m:GetAttribute("fl_name") or m.Name,
							GetAttribute = function(_, k) return m:GetAttribute(k) end,
						},
					}
				end
			end
		end
	end
	for m, rec in pairs(modelEsp) do
		if not m.Parent then
			removeESP(rec.e)
			modelEsp[m] = nil
			claimedRigs[m] = nil
		else
			local nm = m:GetAttribute("fl_name")
			if nm then rec.subj.DisplayName = nm end
		end
	end
end

task.spawn(function()
	while not FL_DEAD do
		pcall(refreshRigs)
		task.wait(0.75)
	end
end)

local colEnemy = rgb(255, 60, 60)
local colFriend = rgb(80, 200, 255)
local function charColor(p) return isEnemy(p) and colEnemy or colFriend end

local function updateESP(e, p)
	if not e or FL_DEAD then return end
	local camera = ws.CurrentCamera
	if not camera then return end
	local char = p.Character
	local show = flag("esp_master", true) and char and alive(p)
	local function hideAll()
		for _, l in ipairs(e.box) do l.Visible = false end
		e.name.Visible = false e.dist.Visible = false
		e.hpBg.Visible = false e.hpFg.Visible = false e.tracer.Visible = false e.arrow.Visible = false
		for _, l in ipairs(e.skel) do l.Visible = false end
	end
	if not show then hideAll() if e.cham then e.cham.Enabled = false end return end

	local root = rootOf(p)
	if not root then hideAll() return end
	local cf = root.CFrame
	local camDist = (camera.CFrame.Position - cf.Position).Magnitude
	if camDist < 5 or cf.Position.Y < -200 then hideAll() if e.cham then e.cham.Enabled = false end return end
	local rootPos, onScreen, depth = w2s(cf.Position)
	local behind = depth < 0
	local top = w2s((cf * cfr(0, 3.2, 0)).Position)
	local bottom = w2s((cf * cfr(0, -3.4, 0)).Position)
	local col = charColor(p)
	local height = math.abs(top.Y - bottom.Y)
	if height ~= height or height < 8 or height > 4000 or behind then
		hideAll() if e.cham then e.cham.Enabled = false end
		if flag("esp_arrows", true) and behind then
			local center = vec2(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
			local dir = vec2(rootPos.X - center.X, rootPos.Y - center.Y)
			if dir.Magnitude > 0 then dir = dir.Unit else dir = vec2(0,-1) end
			local radius = min(camera.ViewportSize.X, camera.ViewportSize.Y) * 0.42
			local tip = center + dir * radius
			local side = vec2(-dir.Y, dir.X) * 10
			e.arrow.PointA = tip e.arrow.PointB = tip - dir * 22 + side
			e.arrow.PointC = tip - dir * 22 - side
			e.arrow.Color = col e.arrow.Filled = true e.arrow.Visible = true
		end
		return
	end
	local width = height * 0.55
	local cx = top.X
	local boxX, boxY = cx - width/2, min(top.Y, bottom.Y)

	if flag("esp_boxes", true) then
		local b = e.box
		b[1].From = vec2(boxX, boxY) b[1].To = vec2(boxX + width, boxY)
		b[2].From = vec2(boxX + width, boxY) b[2].To = vec2(boxX + width, boxY + height)
		b[3].From = vec2(boxX + width, boxY + height) b[3].To = vec2(boxX, boxY + height)
		b[4].From = vec2(boxX, boxY + height) b[4].To = vec2(boxX, boxY)
		for _, l in ipairs(b) do l.Color = col l.Visible = true end
	else for _, l in ipairs(e.box) do l.Visible = false end end

	if flag("esp_names", true) then
		e.name.Text = p.DisplayName
		e.name.Position = vec2(cx, boxY - 16)
		e.name.Color = col e.name.Visible = true
	else e.name.Visible = false end

	if flag("esp_dist", true) then
		local d = (camera.CFrame.Position - cf.Position).Magnitude
		e.dist.Text = string.format("%.0fm", d * 0.28)
		e.dist.Position = vec2(cx, boxY + height + 2)
		e.dist.Color = Color3.new(1,1,1) e.dist.Visible = true
	else e.dist.Visible = false end

	if flag("esp_health", true) then
		local frac = healthFrac(p)
		local hx = boxX - 5
		e.hpBg.From = vec2(hx, boxY) e.hpBg.To = vec2(hx, boxY + height)
		e.hpBg.Color = rgb(20,20,20) e.hpBg.Thickness = 3 e.hpBg.Visible = true
		e.hpFg.From = vec2(hx, boxY + height)
		e.hpFg.To = vec2(hx, boxY + height * (1 - frac))
		e.hpFg.Color = rgb(255 * (1-frac), 255 * frac, 40)
		e.hpFg.Thickness = 2 e.hpFg.Visible = true
	else e.hpBg.Visible = false e.hpFg.Visible = false end

	if flag("esp_skel", true) then
		local set = char:FindFirstChild("UpperTorso") and R15BONES
			or char:FindFirstChild("Head_M", true) and FLBONES or R6BONES
		for i, pair in ipairs(set) do
			local l = e.skel[i]
			local a, b = char:FindFirstChild(pair[1], true), char:FindFirstChild(pair[2], true)
			if l and a and b then
				local ap = a:IsA("Bone") and a.WorldPosition or a.Position
				local bp = b:IsA("Bone") and b.WorldPosition or b.Position
				local sa, ona = w2s(ap)
				local sb, onb = w2s(bp)
				if ona or onb then l.From = sa l.To = sb l.Color = col l.Visible = true
				else l.Visible = false end
			elseif l then l.Visible = false end
		end
		for i = #set + 1, #e.skel do e.skel[i].Visible = false end
	else for _, l in ipairs(e.skel) do l.Visible = false end end

	if flag("esp_chams", false) then
		if not e.cham or e.cham.Parent ~= char then
			if e.cham then e.cham:Destroy() end
			e.cham = Instance.new("Highlight")
			e.cham.FillTransparency = 0.6
			e.cham.OutlineTransparency = 0.2
			e.cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			e.cham.Parent = char
		end
		e.cham.FillColor = col e.cham.OutlineColor = col e.cham.Enabled = true
	elseif e.cham then e.cham.Enabled = false end

	if flag("esp_tracers", true) and onScreen then
		e.tracer.From = vec2(camera.ViewportSize.X/2, camera.ViewportSize.Y)
		e.tracer.To = rootPos e.tracer.Color = col e.tracer.Visible = true
	else e.tracer.Visible = false end

	if flag("esp_arrows", true) and not onScreen and depth < 0 then
		local center = vec2(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
		local dir = vec2(rootPos.X - center.X, rootPos.Y - center.Y)
		if dir.Magnitude > 0 then dir = dir.Unit else dir = vec2(0,-1) end
		local radius = min(camera.ViewportSize.X, camera.ViewportSize.Y) * 0.42
		local tip = center + dir * radius
		local perp = vec2(-dir.Y, dir.X)
		e.arrow.PointA = tip
		e.arrow.PointB = tip - dir * 18 + perp * 8
		e.arrow.PointC = tip - dir * 18 - perp * 8
		e.arrow.Color = col e.arrow.Filled = true e.arrow.Visible = true
	else e.arrow.Visible = false end
end

local function aimPos(part)
	return part:IsA("Bone") and part.WorldPosition or part.Position
end
local function getTarget()
	local mPos = uis:GetMouseLocation()
	local cam = ws.CurrentCamera
	local best, bestScore = nil, CFG.FOV
	local function scan(subj)
		local char = subj.Character
		if subj ~= lp and alive(subj) and isEnemy(subj) and char then
			local part = aimPart(char)
			if part then
				local pp = aimPos(part)
				local sp, on = w2s(pp)
				if on then
					local d = (sp - mPos).Magnitude
					if d < bestScore then
						if flag("wallbang", false) or not CFG.WallCheck or rayVisible(cam.CFrame.Position, pp, char) then
							best, bestScore = subj, d
						end
					end
				end
			end
		end
	end
	for _, pl in ipairs(players:GetPlayers()) do scan(pl) end
	for _, rec in pairs(modelEsp) do scan(rec.subj) end
	return best and aimPart(best.Character)
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1 fovCircle.NumSides = 60 fovCircle.Color = rgb(255,255,255)
fovCircle.Filled = false fovCircle.Visible = false

run.RenderStepped:Connect(function()
	if FL_DEAD then return end
	for p, e in pairs(esp) do
		pcall(updateESP, e, p)
	end
	for _, rec in pairs(modelEsp) do
		pcall(updateESP, rec.e, rec.subj)
	end
	local aimOn = flag("aim_enable", true) and flag("aim_showfov", true)
	fovCircle.Visible = aimOn
	fovCircle.Radius = CFG.FOV
	fovCircle.Position = uis:GetMouseLocation()
end)

local function aimHeld()
	local kb = Flags["aim_bind"]
	if type(kb) == "table" then return kb.active end
	return uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

run.RenderStepped:Connect(function()
	if FL_DEAD then return end
	if not flag("cam_aim", false) then return end
	if not aimHeld() then return end
	local part = getTarget()
	local cam = ws.CurrentCamera
	if part and cam then
		local look = (aimPos(part) - cam.CFrame.Position).Unit
		local goal = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + look)
		cam.CFrame = CFG.Smooth > 0 and cam.CFrame:Lerp(goal, math.clamp(CFG.Smooth, 0.05, 1)) or goal
	end
end)

local curTarget, curTargetAt = nil, 0
local function redirectTarget()
	if not curTarget or not curTarget.Parent or os.clock() - curTargetAt > 0.1 then
		curTarget = getTarget()
		curTargetAt = os.clock()
	end
	return curTarget
end

local silentOn = function() return not FL_DEAD and flag("silent_aim", true) and flag("aim_enable", true) end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	local method = getnamecallmethod()
	if silentOn() and not checkcaller() then
		if method == "Raycast" and self == ws then
			local args = {...}
			local origin, dir = args[1], args[2]
			if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" then
				local t = redirectTarget()
				if t then
					args[2] = (t.Position - origin)
					return oldNamecall(self, unpack(args))
				end
			end
		elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay"
			or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRayWithIgnoreListAndFilter" then
			local args = {...}
			local ray = args[1]
			if typeof(ray) == "Ray" then
				local t = redirectTarget()
				if t then
					args[1] = Ray.new(ray.Origin, t.Position - ray.Origin)
					return oldNamecall(self, unpack(args))
				end
			end
		end
	end
	return oldNamecall(self, ...)
end))

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, k)
	if not checkcaller() and silentOn() then
		if self:IsA("Mouse") and (k == "Hit" or k == "Target") then
			local t = redirectTarget()
			if t then
				if k == "Hit" then return t.CFrame end
				return t
			end
		end
	end
	return oldIndex(self, k)
end))

run.RenderStepped:Connect(function()
	if FL_DEAD then return end
	local t = silentOn() and redirectTarget() or nil
	if t then
		ws:SetAttribute("fl_t", aimPos(t))
	elseif ws:GetAttribute("fl_t") ~= nil then
		ws:SetAttribute("fl_t", nil)
	end
end)



UI:Init("waffle")
pcall(function() UI.sg.Enabled = false end)
local menuOn = false
local function toggleMenu()
	menuOn = not menuOn
	UI.sg.Enabled = menuOn
end

local flUnload
flUnload = function()
	if FL_DEAD then return end
	FL_DEAD = true
	for _, e in pairs(esp) do pcall(removeESP, e) end
	for _, rec in pairs(modelEsp) do pcall(removeESP, rec.e) end
	table.clear(esp) table.clear(modelEsp)
	pcall(function() fovCircle:Remove() end)
	pcall(function() ws:SetAttribute("fl_t", nil) end)
	for _, c in ipairs(FL_CONNS) do pcall(function() c:Disconnect() end) end
	UI:Destroy()
	FL_G.__flUnload = nil
end
FL_G.__flUnload = flUnload

UI.CBS.aim_fov = function(v) CFG.FOV = v end
UI.CBS.aim_part = function(v) CFG.AimPart = v end
UI.CBS.aim_smooth = function(v) CFG.Smooth = v end
UI.CBS.col_enemy = function(v) colEnemy = v end
UI.CBS.col_friend = function(v) colFriend = v end

local Combat = UI:Category("combat")
local mAim = Combat:Module("silent aim", "silent_aim", true)
mAim:Toggle("enabled", "aim_enable", true)
mAim:Bind("aim key", "aim_bind", "MouseButton2")
mAim:Slider("fov", "aim_fov", 40, 700, 220, 10)
mAim:Dropdown("bone", "aim_part", {"Head","Head_M","TPVBodyVanillaHead","HumanoidRootPart"}, "Head_M")
mAim:Toggle("show fov", "aim_showfov", true)
mAim:Toggle("wall check", "wall_check", true)
mAim:Toggle("wallbang", "wallbang", false)
local mCam = Combat:Module("camera aim", "cam_aim", false)
mCam:Slider("smoothing", "aim_smooth", 0, 1, 0, 0.05)

local Vis = UI:Category("visuals")
local mEsp = Vis:Module("esp", "esp_master", true)
mEsp:Toggle("boxes", "esp_boxes", true)
mEsp:Toggle("names", "esp_names", true)
mEsp:Toggle("distance", "esp_dist", true)
mEsp:Toggle("health", "esp_health", true)
mEsp:Toggle("skeleton", "esp_skel", true)
mEsp:Toggle("chams", "esp_chams", false)
mEsp:Toggle("tracers", "esp_tracers", true)
mEsp:Toggle("offscreen arrows", "esp_arrows", true)
mEsp:Toggle("team check", "team_check", true)
mEsp:Palette("enemy color", "col_enemy", colEnemy)
mEsp:Palette("friend color", "col_friend", colFriend)

local Misc = UI:Category("misc")
Misc:Button("save config", function()
	pcall(function()
		local out = {}
		for k, v in pairs(Flags) do
			if typeof(v) == "Color3" then out[k] = {__col = v:ToHex()}
			else out[k] = v end
		end
		if writefile then writefile("fl_cfg.json", http_service:JSONEncode(out)) end
	end)
end)
Misc:Button("load config", function()
	pcall(function()
		if not (isfile and isfile("fl_cfg.json")) then return end
		local cfg = http_service:JSONDecode(readfile("fl_cfg.json"))
		for k, v in pairs(cfg) do
			if type(v) == "table" and v.__col then v = Color3.fromHex(v.__col) end
			Flags[k] = v
			if UI.CBS[k] then pcall(UI.CBS[k], v) end
		end
	end)
end)
Misc:Button("unload", function() flUnload() end)

flConn(uis.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.Delete then toggleMenu() end
	if input.KeyCode == Enum.KeyCode.End then flUnload() end
end)
toggleMenu()

pcall(function()
	if isfile and isfile("fl_cfg.json") then
		local cfg = http_service:JSONDecode(readfile("fl_cfg.json"))
		for k, v in pairs(cfg) do
			if type(v) == "table" and v.__col then v = Color3.fromHex(v.__col) end
			Flags[k] = v
			if UI.CBS[k] then pcall(UI.CBS[k], v) end
		end
	end
end)
