local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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

-- ===================== FRONTLINES // devin =====================
local FL_G = getrenv and getrenv()._G or _G
if FL_G.__flUnload then pcall(FL_G.__flUnload) FL_G.__flUnload = nil end

local Flags = {}

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
	if type(kb) == "string" then
		if kb:match("^MouseButton") then
			local ok, e = pcall(function() return Enum.UserInputType[kb] end)
			if ok and e then return uis:IsMouseButtonPressed(e) end
		else
			local ok, e = pcall(function() return Enum.KeyCode[kb] end)
			if ok and e then return uis:IsKeyDown(e) end
		end
	end
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
	pcall(function() Window:Destroy() end)
	FL_G.__flUnload = nil
end
FL_G.__flUnload = flUnload

local Window = WindUI:CreateWindow({
	Title = "frontlines // devin",
	Icon = "crosshair",
	Author = "waffle",
	Folder = "FrontlinesWaffle",
	Size = UDim2.fromOffset(620, 480),
	Theme = "Dark",
})
pcall(function() Window:SetToggleKey(Enum.KeyCode.Delete) end)

local Els = {}
local function reg(f, el) if f then Els[f] = el end return el end

local Visuals = Window:Tab({Title = "Visuals", Icon = "eye"})
do
	local s = Visuals:Section({Title = "ESP"})
	local function T(name, f, def) return reg(f, s:Toggle({Title = name, Flag = f, Value = def, Callback = function(v) Flags[f] = v end})) end
	Flags.esp_master = true T("Enabled", "esp_master", true)
	Flags.esp_boxes = true T("Boxes", "esp_boxes", true)
	Flags.esp_names = true T("Names", "esp_names", true)
	Flags.esp_dist = true T("Distance", "esp_dist", true)
	Flags.esp_health = true T("Health", "esp_health", true)
	Flags.esp_skel = true T("Skeleton", "esp_skel", true)
	Flags.esp_chams = false T("Chams", "esp_chams", false)
	Flags.esp_tracers = true T("Tracers", "esp_tracers", true)
	Flags.esp_arrows = true T("Offscreen arrows", "esp_arrows", true)

	local s2 = Visuals:Section({Title = "Filters & Colors"})
	Flags.team_check = true
	reg("team_check", s2:Toggle({Title = "Team check", Flag = "team_check", Value = true, Callback = function(v) Flags.team_check = v end}))
	reg("col_enemy", s2:Colorpicker({Title = "Enemy color", Flag = "col_enemy", Default = colEnemy, Callback = function(c) colEnemy = c Flags.col_enemy = c end}))
	reg("col_friend", s2:Colorpicker({Title = "Friendly color", Flag = "col_friend", Default = colFriend, Callback = function(c) colFriend = c Flags.col_friend = c end}))
end

local Aiming = Window:Tab({Title = "Aiming", Icon = "locate-fixed"})
do
	local s = Aiming:Section({Title = "Silent Aim"})
	local function T(name, f, def) return reg(f, s:Toggle({Title = name, Flag = f, Value = def, Callback = function(v) Flags[f] = v end})) end
	Flags.aim_enable = true T("Enabled", "aim_enable", true)
	Flags.silent_aim = true T("Silent aim", "silent_aim", true)
	Flags.aim_showfov = true T("Show FOV", "aim_showfov", true)
	reg("aim_bind", s:Keybind({Title = "Aim key", Flag = "aim_bind", Value = "MouseButton2", Callback = function(v) Flags.aim_bind = v end}))
	reg("aim_fov", s:Slider({Title = "FOV", Flag = "aim_fov", Step = 10, Value = {Min = 40, Max = 700, Default = 220}, Callback = function(v) CFG.FOV = v Flags.aim_fov = v end}))
	reg("aim_part", s:Dropdown({Title = "Aim part", Flag = "aim_part", Values = {"Head","Head_M","TPVBodyVanillaHead","HumanoidRootPart"}, Value = "Head_M", Callback = function(v) CFG.AimPart = v Flags.aim_part = v end}))
	Flags.wall_check = true T("Wall check", "wall_check", true)
	Flags.wallbang = false T("Wallbang (ignore walls)", "wallbang", false)
	s:Button({Title = "Zero spread (experimental)", Callback = function()
		pcall(function()
			local env = getrenv()
			local g = env._G and env._G.globals
			if g and g.fpv_sol_spread then g.fpv_sol_spread.spread = 0 end
		end)
	end})

	local s2 = Aiming:Section({Title = "Camera Aim"})
	Flags.cam_aim = false
	reg("cam_aim", s2:Toggle({Title = "Camera aim (hold aim key)", Flag = "cam_aim", Value = false, Callback = function(v) Flags.cam_aim = v end}))
	reg("aim_smooth", s2:Slider({Title = "Smoothing", Flag = "aim_smooth", Step = 0.05, Value = {Min = 0, Max = 1, Default = 0}, Callback = function(v) CFG.Smooth = v Flags.aim_smooth = v end}))
end

local Misc = Window:Tab({Title = "Misc", Icon = "settings"})
do
	local s = Misc:Section({Title = "Menu"})
	s:Button({Title = "Save config", Callback = function()
		pcall(function()
			local out = {}
			for k, v in pairs(Flags) do
				if typeof(v) == "Color3" then out[k] = {__col = v:ToHex()}
				else out[k] = v end
			end
			if writefile then writefile("fl_cfg.json", http_service:JSONEncode(out)) end
		end)
	end})
	s:Button({Title = "Load config", Callback = function()
		pcall(function()
			if not (isfile and isfile("fl_cfg.json")) then return end
			local cfg = http_service:JSONDecode(readfile("fl_cfg.json"))
			for k, v in pairs(cfg) do
				if type(v) == "table" and v.__col then v = Color3.fromHex(v.__col) end
				Flags[k] = v
				local el = Els[k]
				if el then
					pcall(function() el:Set(v) end)
					pcall(function() el:Select(v) end)
					pcall(function() el:Update(v) end)
				end
			end
		end)
	end})
	s:Button({Title = "Unload", Callback = function() flUnload() end})
end

flConn(uis.InputBegan, function(input, gpe)
	if input.KeyCode == Enum.KeyCode.End then flUnload() end
end)

pcall(function()
	if isfile and isfile("fl_cfg.json") then
		local cfg = http_service:JSONDecode(readfile("fl_cfg.json"))
		for k, v in pairs(cfg) do
			if type(v) == "table" and v.__col then v = Color3.fromHex(v.__col) end
			Flags[k] = v
			local el = Els[k]
			if el then
				pcall(function() el:Set(v) end)
				pcall(function() el:Select(v) end)
				pcall(function() el:Update(v) end)
			end
		end
	end
end)
