repeat task.wait() until game:IsLoaded()

_G.ForkyHUB = _G.ForkyHUB or {}

_G.ForkyHUB.Games = {
    [2693023319] = {
        name = "Expedition Antarctica",
        url = "https://gitlab.com/forky1/forkyHUB/-/raw/main/artic.lua"
    },
    [129118369937980] = {
        name = "Eagle Nation",
        url = "https://gitlab.com/forky1/forkyHUB/-/raw/main/eagle.lua"
    },
    [129866685202296] = {
        name = "Last Letter",
        url = "https://gitlab.com/forky1/forkyHUB/-/raw/main/lastletter.lua"
    },
    [131378148336503] = {
        name = "Drag Drive Simulator",
        url = "https://gitlab.com/forky1/forkyHUB/-/raw/main/ddds.lua"
    },
    [114862923457266] = {
        name = "Mandalika Drag Drive Simulator",
        url = "https://gitlab.com/forky1/forkyHUB/-/raw/main/ddds.lua"
    },
    [92416421522960] = {
        name = "Slime RNG",
        url = "https://gitlab.com/forky1/other/-/raw/main/srng.lua"
    },
    [77747658251236] = {
        name = "Sailor Piece",
        url = "https://raw.githubusercontent.com/forky-y/UI/refs/heads/main/ssl.lua"
    },
    [110369730911937] = {
        name = "CDID",
        url = "https://pastefy.app/1tjD28LE/raw"
    },
    [132986577553100] = {
        name = "Seasonal CDID",
        url = "https://pastefy.app/HvjRamJZ/raw"
    },
    [89469502395769] = {
        name = "Kick a Lucky Block",
        url = "https://pastefy.app/nqaprTdX/raw"
    }
}

function _G.ForkyHUB.Load(url)
    return loadstring(game:HttpGet(url))()
end

local gameData = _G.ForkyHUB.Games[game.PlaceId]

local url = gameData and gameData.url
    or "https://gitlab.com/forky1/forkyHUB/-/raw/main/mts.lua"

_G.ForkyHUB.Load(url)
