local BASE = "https://raw.githubusercontent.com/vrcdev/FrontlinesWaffle/main/"
local function fetch(url)
	local ok, r = pcall(game.HttpGet, game, url)
	if ok and type(r) == "string" and #r > 0 then return r end
	if httpget then
		ok, r = pcall(httpget, url)
		if ok and type(r) == "string" and #r > 0 then return r end
	end
	local req = request or http_request or (http and http.request) or (syn and syn.request)
	if req then
		ok, r = pcall(req, {Url = url, Method = "GET"})
		if ok and type(r) == "table" and type(r.Body) == "string" and #r.Body > 0 then return r.Body end
	end
	error("fetch failed: " .. url .. " (HttpGet returned " .. typeof(r) .. ")")
end
for _, t in ipairs(getactorthreads()) do
	run_on_thread(t, string.format([[
		if getrenv()._G.globals then
			local BASE = %q
			local function fetch(url)
				local ok, r = pcall(game.HttpGet, game, url)
				if ok and type(r) == "string" and #r > 0 then return r end
				if httpget then
					ok, r = pcall(httpget, url)
					if ok and type(r) == "string" and #r > 0 then return r end
				end
				local req = request or http_request or (http and http.request) or (syn and syn.request)
				if req then
					ok, r = pcall(req, {Url = url, Method = "GET"})
					if ok and type(r) == "table" and type(r.Body) == "string" then return r.Body end
				end
				error("fetch failed: " .. url)
			end
			local f, e = loadstring(fetch(BASE .. "fl_actor.luau"))
			if f then
				local ok, err = pcall(f)
				print("[fl] actor-bridge:", ok, err)
			else
				print("[fl] actor compile err:", e)
			end
		end
	]], BASE))
end
local f, e = loadstring(fetch(BASE .. "click_frontlines.luau"))
assert(f, e)
local ok, err = pcall(f)
print("[fl] main-run:", ok, err)
