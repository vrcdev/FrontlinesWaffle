# FrontlinesWaffle

Frontlines (Roblox) ESP + silent aim for Potassium.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vrcdev/FrontlinesWaffle/main/loader.luau"))()
```

## Files

- `loader.luau` — entrypoint; fetches and runs everything
- `milkyboy_lib.luau` — main payload (milkyboy UI, ESP, silent aim target picker)
- `fl_actor.luau` — actor-thread bridge (bullet spawn hooks + globals attribute mirror)

## Usage

- Delete — toggle menu
- End — unload
