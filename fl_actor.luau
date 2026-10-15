local env = getrenv()
local g = env._G and env._G.globals
if not g then return end
local ws = game:GetService('Workspace')
if env._G.__flUnhook then pcall(env._G.__flUnhook) env._G.__flUnhook = nil end
local execMap, unhook
local eft = env._G.exe_func_t
local ruf = env._G.remove_exe_func
if eft and type(ruf) == 'function' then
	for n = 1, 25 do
		local v = debug.getupvalue(ruf, n)
		if v == nil then break end
		if type(v) == 'table' and type(rawget(v, eft.SPAWN_FPV_SOL_BULLET)) == 'function' then
			execMap = v
			break
		end
	end
end
unhook = {}
if execMap then
	for _, id in ipairs({eft.SPAWN_FPV_SOL_BULLET, eft.SPAWN_FPV_SOL_FIREARM_BULLET}) do
		local orig = rawget(execMap, id)
		if type(orig) == 'function' then
			rawset(execMap, id, function(...)
				local a = {...}
				local t = ws:GetAttribute('fl_t')
				if typeof(t) == 'Vector3' and typeof(a[3]) == 'Vector3' and typeof(a[4]) == 'Vector3' then
					a[4] = (t - a[3]).Unit * a[4].Magnitude
					ws:SetAttribute('fl_hits', (ws:GetAttribute('fl_hits') or 0) + 1)
					return orig(unpack(a))
				end
				return orig(...)
			end)
			unhook[#unhook + 1] = {id = id, orig = orig}
		end
	end
	env._G.__flUnhook = function()
		for _, h in ipairs(unhook) do pcall(rawset, execMap, h.id, h.orig) end
		unhook = {}
	end
end
print('[fl] actor hooks: ' .. #unhook)
task.spawn(function()
	while true do
		local my = g.cli_state and g.cli_state.fpv_sol_id
		local myTeam = my and g.sol_teams and g.sol_teams[my]
		if myTeam ~= nil then ws:SetAttribute('fl_myteam', myTeam) end
		for id, m in pairs(g.soldier_models or {}) do
			if m and m.Parent then
				m:SetAttribute('fl_name', (g.cli_names or {})[id])
				m:SetAttribute('fl_team', (g.sol_teams or {})[id])
				m:SetAttribute('fl_alive', (g.soldiers_alive or {})[id] == true)
				m:SetAttribute('fl_hp', (g.gbl_sol_healths or {})[id])
				m:SetAttribute('fl_mine', id == my)
			end
		end
		task.wait(0.4)
	end
end)
print('[fl] actor mirror running')
