-- [[ SCRIPT MENU HUB by KAMU ]] --

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- 1. Membuat Jendela (Window)
local Window = OrionLib:MakeWindow({
    Name = "My Custom Hub", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "MyScriptConfig",
    IntroEnabled = true,
    IntroText = "Loading Script..."
})

-- 2. Membuat Tab
local MainTab = Window:MakeTab({
    Name = "Auto Walk",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 3. Membuat Tombol (Button)
MainTab:AddSection({
	Name = "Daftar Rute"
})

-- TOMBOL UNTUK LINK YANG KAMU KIRIM
MainTab:AddButton({
	Name = "Jalankan Rute (1.lua)",
	Callback = function()
        -- Sistem Notifikasi
        OrionLib:MakeNotification({
            Name = "Status",
            Content = "Sedang memuat script dari GitHub...",
            Image = "rbxassetid://4483345998",
            Time = 3
        })

        -- >> INI BAGIAN PENTINGNYA <<
        -- Script akan mengambil kodingan dari link yang kamu kasih
        local url = "https://raw.githubusercontent.com/lilyml2222-source/tst/refs/heads/main/ts.lua"
        local success, err = pcall(function()
            loadstring(game:HttpGet(url))()
        end)

        if success then
            print("Script berhasil dijalankan!")
        else
            -- Jika link mati/error
            OrionLib:MakeNotification({
                Name = "Error",
                Content = "Gagal memuat script! Cek linknya.",
                Image = "rbxassetid://4483345998",
                Time = 5
            })
            warn("Error details: " .. err)
        end
  	end    
})

-- TOMBOL DARURAT (STOP)
MainTab:AddButton({
	Name = "Hentikan Karakter (Reset)",
	Callback = function()
        local p = game.Players.LocalPlayer
        if p.Character then
            p.Character:BreakJoints() -- Mematikan karakter
        end
  	end    
})

-- 4. Menutup Setup
OrionLib:Init()
