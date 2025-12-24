print("EXC FREEMIUM - Loading Modules...")

-- [[ 1. LOAD MODULES DARI GITHUB ]]
local GITHUB_BASE = "https://raw.githubusercontent.com/lilyml2222/tst/main/"

local Config = loadstring(game:HttpGet(GITHUB_BASE .. "config.lua"))()
local Core = loadstring(game:HttpGet(GITHUB_BASE .. "core.lua"))()

-- Link Config ke Core
Core.Config = Config

print("✅ Modules Loaded!")

-- [[ 2. SERVICES ]]
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- [[ 3. SETUP WINDUI ]]
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/lilyml2222-source/tst/refs/heads/main/WindUI.lua"))()
Core.WindUI = WindUI

local Window = WindUI:CreateWindow({
    Title = "EXC FREEMIUM",
    Icon = "rbxassetid://9603961137",
    Author = "Anonymous",
    Folder = "exc freemium",
    Transparent = true,
    Theme = "Dark",
    ToggleKeybind = Enum.KeyCode.RightControl
})

local AutoWalkTab = Window:Tab({ Title = "Auto Walk", Icon = "footprints" })
Window:Tab({ Title = "Authentication", Icon = "key" })
Window:Tab({ Title = "Account", Icon = "user" })

-- [[ 4. SETUP FLOATING MENU ]]
local function CreateMiniMenu()
    if getgenv().MiniUI then getgenv().MiniUI:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoWalkMiniMenu"
    if pcall(function() ScreenGui.Parent = CoreGui end) then
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    getgenv().MiniUI = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.Position = UDim2.new(0.1, 0, 0.65, 0)
    MainFrame.Size = UDim2.new(0, 220, 0, 50)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 0, 0)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = MainFrame
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Padding = UDim.new(0, 10)

    local function CreateButton(text, callback)
        local Btn = Instance.new("TextButton")
        Btn.Parent = MainFrame
        Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Btn.Size = UDim2.new(0, 60, 0, 30)
        Btn.Font = Enum.Font.GothamBold
        Btn.Text = text
        Btn.TextColor3 = Color3.fromRGB(255, 0, 0)
        Btn.TextSize = 14
        local BtnCorner = Instance.new("UICorner", Btn)
        BtnCorner.CornerRadius = UDim.new(0, 6)
        Btn.MouseButton1Click:Connect(callback)
        return Btn
    end

    CreateButton("PLAY", function()
        if Config.isPlaying then WindUI:Notify({Title="Info", Content="Sedang berjalan...", Duration=1}) return end
        if Config.CurrentRepoURL == "" then WindUI:Notify({Title="Error", Content="Pilih Track Dulu!", Duration=2}) return end
        
        Config.isPlaying = true
        WindUI:Notify({Title="Play", Content="Auto Walk Aktif", Duration=2})
        
        task.spawn(function()
            if not Config.isCached then
                WindUI:Notify({Title="Download", Content="Mengunduh data...", Duration=2})
                local success = Core.DownloadData(Config.CurrentRepoURL)
                if not success then
                    Config.isPlaying = false
                    WindUI:Notify({Title="Gagal", Content="Repo Error / Kosong", Duration=3})
                    return
                end
                Config.isCached = true
            end
            Core.RunPlayback()
        end)
    end)

    CreateButton("STOP", function()
        if Config.isPlaying then
            Config.isPlaying = false
            task.wait(0.1)
            Core.ResetCharacter()
            WindUI:Notify({Title="Stopped", Content="Script dipause.", Duration=3})
        else
            WindUI:Notify({Title="Info", Content="Script sudah berhenti.", Duration=1})
        end
    end)

    CreateButton("FLIP", function()
        if Config.FlipOffset == 0 then
            Config.FlipOffset = math.pi
            WindUI:Notify({Title="Flip", Content="Menghadap Belakang", Duration=1})
        else
            Config.FlipOffset = 0
            WindUI:Notify({Title="Flip", Content="Menghadap Normal", Duration=1})
        end
    end)
end

-- [[ 5. WINDUI CONTENT ]]
local WalkSection = AutoWalkTab:Section({ Title = "Settings", TextXAlignment = "Left" })

WalkSection:Toggle({
    Title = "Enable Loop",
    Desc = "Ulangi jalan terus menerus.",
    Value = false,
    Callback = function(state) Config.isLooping = state end
})

WalkSection:Slider({
    Title = "Speed Multiplier",
    Desc = "Atur kecepatan karakter (1 = normal)",
    Min = 0.1,
    Max = 3,
    Default = 1,
    Decimals = 1,
    Callback = function(v)
        Config.SpeedMultiplier = v
        WindUI:Notify({Title="Speed", Content="Speed: "..v.."x", Duration=1})
    end
})

local MenuSection = AutoWalkTab:Section({ Title = "Select Track", TextXAlignment = "Left" })

local TrackDropdown = MenuSection:Dropdown({
    Title = "[O] SELECT TRACK",
    Multi = false,
    Options = {"Loading..."},
    Default = "Loading...",
    Callback = function(value)
        if value ~= "Loading..." then
            Config.CurrentRepoURL = Core.GetRepoURL(value)
            Config.isCached = false
            Config.SavedCP = 0
            Config.SavedFrame = 1
            Config.TASDataCache = {}
            WindUI:Notify({Title="Selected", Content=value.." siap.", Duration=2})
        end
    end
})

MenuSection:Toggle({
    Title = "[O] Show/Hide Auto Walk",
    Desc = "Tampilkan tombol PLAY | STOP | FLIP",
    Value = false,
    Callback = function(state)
        if state then CreateMiniMenu() else if getgenv().MiniUI then getgenv().MiniUI:Destroy() end end
    end
})

MenuSection:Button({
    Title = "Refresh List",
    Callback = function() TrackDropdown:Refresh(Config.MountList, "Mount Funny") end
})

task.spawn(function()
    wait(1)
    TrackDropdown:Refresh(Config.MountList, "Mount Funny")
end)

WindUI:Notify({Title = "EXC FREEMIUM", Content = "Modular System Ready!", Duration = 3})
