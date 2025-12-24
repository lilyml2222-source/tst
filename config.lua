-- CONFIG.LUA - Configuration & Variables
local Config = {}

-- GitHub Settings
Config.GitHubUser = "crystalknight-svg"
Config.Branch = "main"

-- Mount List
Config.MountList = {
    "Mount Funny", "Mount Yahayuk", "Mount Gemi", "Mount Age",
    "Mount Runia", "Mount Yubi", "Mount Anjir", "Mount Velora",
    "Mount Freestyle", "Mount Aethria", "Mount Luna",
    "Mount Wasabi", "Mount Kita"
}

-- Internal Variables (akan diakses oleh core.lua)
Config.TASDataCache = {}
Config.isCached = false
Config.isPlaying = false
Config.isLooping = false
Config.SavedCP = 0
Config.SavedFrame = 1
Config.END_CP = 1000
Config.CurrentRepoURL = ""
Config.FlipOffset = 0
Config.SpeedMultiplier = 1
Config.godMode = false
Config.autoRespawn = false
return Config
