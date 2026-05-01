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
    [999999] = {
        name = "BiteByNight",
        url = ""
    },
    [999999999] = {
        name = "Fishzar",
        url = ""
    }
}

function _G.ForkyHUB.Load(url)
    return loadstring(game:HttpGet(url))()
end

local gameData = _G.ForkyHUB.Games[game.PlaceId]

local url = gameData and gameData.url
    or "https://gitlab.com/forky1/forkyHUB/-/raw/main/mts.lua"

_G.ForkyHUB.Load(url)
