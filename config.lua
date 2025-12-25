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
-- [[ PLAYER MENU CONFIGURATION ]]
Config.PlayerMenu = {
    -- WalkSpeed Settings
    WalkSpeed = {
        Current = 16,
        Default = 16,
        Min = 16,
        Max = 200
    },
    
    -- Feature States
    InfiniteJump = false,
    FullBright = false,
    FPSBooster = false,
    
    -- Advanced Settings
    FullBrightIntensity = 2, -- Brightness level (1-3)
    FPSBoosterLevel = "High", -- "Low", "Medium", "High"
    
    -- Original Lighting Settings (untuk restore)
    OriginalLighting = {
        Brightness = nil,
        Ambient = nil,
        OutdoorAmbient = nil,
        ClockTime = nil,
        FogEnd = nil
    }
}

-- =========================
-- PRESET DATA (FULL)
-- =========================
Config.Presets = {
    ["Default"] = { __DEFAULT = true },

    ["Stylish"] = {
        Idle="rbxassetid://616136790", Walk="rbxassetid://616146177", Run="rbxassetid://616140816",
        Jump="rbxassetid://616139451", Fall="rbxassetid://616134815"
    },
    ["Zombie"] = {
        Idle="rbxassetid://616158929", Walk="rbxassetid://616163682", Run="rbxassetid://616163682",
        Jump="rbxassetid://616161997", Fall="rbxassetid://616157476"
    },
    ["Ninja"] = {
        Idle="rbxassetid://656117400", Walk="rbxassetid://656121766", Run="rbxassetid://656118852",
        Jump="rbxassetid://656117878", Fall="rbxassetid://656115606"
    },
    ["Cartoony"] = {
        Idle="rbxassetid://742637544", Walk="rbxassetid://742638445", Run="rbxassetid://742638209",
        Jump="rbxassetid://742637942", Fall="rbxassetid://742637151"
    },
    ["Toy"] = {
        Idle="rbxassetid://782841498", Walk="rbxassetid://782843345", Run="rbxassetid://782843345",
        Jump="rbxassetid://782847020", Fall="rbxassetid://782846423"
    },
    ["Pirate"] = {
        Idle="rbxassetid://750781874", Walk="rbxassetid://750785693", Run="rbxassetid://750783738",
        Jump="rbxassetid://750782230", Fall="rbxassetid://750780242"
    },
    ["Levitation"] = {
        Idle="rbxassetid://616006778", Walk="rbxassetid://616013216", Run="rbxassetid://616010382",
        Jump="rbxassetid://616008936", Fall="rbxassetid://616005863"
    },
    ["Mage"] = {
        Idle="rbxassetid://707742142", Walk="rbxassetid://707897309", Run="rbxassetid://707861613",
        Jump="rbxassetid://707853694", Fall="rbxassetid://707829716"
    },
    ["Adidas Sports"] = {
        Idle="rbxassetid://1113752682", Walk="rbxassetid://1113753818", Run="rbxassetid://1113754979",
        Jump="rbxassetid://1113752689", Fall="rbxassetid://1113751630"
    },
    ["Elder"] = {
        Idle="rbxassetid://845397899", Walk="rbxassetid://845403856", Run="rbxassetid://845386501",
        Jump="rbxassetid://845398858", Fall="rbxassetid://845396048"
    },
    ["Astronaut"] = {
        Idle="rbxassetid://891621366", Walk="rbxassetid://891633237", Run="rbxassetid://891636393",
        Jump="rbxassetid://891627522", Fall="rbxassetid://891617961"
    },
    ["Knight"] = {
        Idle="rbxassetid://734293716", Walk="rbxassetid://734294431", Run="rbxassetid://734294876",
        Jump="rbxassetid://734294114", Fall="rbxassetid://734293564"
    },
    ["Superhero"] = {
        Idle="rbxassetid://782852758", Walk="rbxassetid://782843345", Run="rbxassetid://782843345",
        Jump="rbxassetid://782847020", Fall="rbxassetid://782846423"
    },
    ["Robot"] = {
        Idle="rbxassetid://616088211", Walk="rbxassetid://616095330", Run="rbxassetid://616091570",
        Jump="rbxassetid://616090535", Fall="rbxassetid://616087089"
    },
    ["Bubbly"] = {
        Idle="rbxassetid://910004836", Walk="rbxassetid://910034870", Run="rbxassetid://910025107",
        Jump="rbxassetid://910016857", Fall="rbxassetid://910001910"
    },
    ["Werewolf"] = {
        Idle="rbxassetid://1083195517", Walk="rbxassetid://1083178339", Run="rbxassetid://1083216690",
        Jump="rbxassetid://1083218792", Fall="rbxassetid://1083189019"
    },
    ["Vampire"] = {
        Idle="rbxassetid://1083445855", Walk="rbxassetid://1083473930", Run="rbxassetid://1083462077",
        Jump="rbxassetid://1083455352", Fall="rbxassetid://1083439238"
    },
    ["Sneaky"] = {
        Idle="rbxassetid://1132473842", Walk="rbxassetid://1132510133", Run="rbxassetid://1132494274",
        Jump="rbxassetid://1132489853", Fall="rbxassetid://1132469004"
    },
    ["Rthro"] = {
        Idle="rbxassetid://2510196951", Walk="rbxassetid://2510202577", Run="rbxassetid://2510198475",
        Jump="rbxassetid://2510197830", Fall="rbxassetid://2510195892"
    }
}

-- =========================
-- STATE
-- =========================
Config.State = {
    CurrentPreset = "Default"
}

function Config:SetPreset(name)
    if self.Presets[name] then
        self.State.CurrentPreset = name
        return self.Presets[name]
    end
end
Skybox = {
    Current = "None",
    Active = false,
    Presets = {
        ["SKY 1"] = {
            SkyboxBk="rbxassetid://570557514",
            SkyboxDn="rbxassetid://570557775",
            SkyboxFt="rbxassetid://570557559",
            SkyboxLf="rbxassetid://570557620",
            SkyboxRt="rbxassetid://570557672",
            SkyboxUp="rbxassetid://570557727"
        },
        ["SKY 2"] = {
            SkyboxBk = "rbxassetid://87654321",
            SkyboxDn = "rbxassetid://87654321",
            SkyboxFt = "rbxassetid://87654321",
            SkyboxLf = "rbxassetid://87654321",
            SkyboxRt = "rbxassetid://87654321",
            SkyboxUp = "rbxassetid://87654321"
        },
        ["SKY 3"] = {
            SkyboxBk = "rbxassetid://11223344",
            SkyboxDn = "rbxassetid://11223344",
            SkyboxFt = "rbxassetid://11223344",
            SkyboxLf = "rbxassetid://11223344",
            SkyboxRt = "rbxassetid://11223344",
            SkyboxUp = "rbxassetid://11223344"
        },
        ["SKY 4"] = {
            SkyboxBk = "rbxassetid://99887766",
            SkyboxDn = "rbxassetid://99887766",
            SkyboxFt = "rbxassetid://99887766",
            SkyboxLf = "rbxassetid://99887766",
            SkyboxRt = "rbxassetid://99887766",
            SkyboxUp = "rbxassetid://99887766"
        },
        ["SKY 5"] = {
            SkyboxBk = "rbxassetid://55443322",
            SkyboxDn = "rbxassetid://55443322",
            SkyboxFt = "rbxassetid://55443322",
            SkyboxLf = "rbxassetid://55443322",
            SkyboxRt = "rbxassetid://55443322",
            SkyboxUp = "rbxassetid://55443322"
        }
    }
}
return Config
