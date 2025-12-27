-- CORE.LUA - Main Logic Functions (FIXED & OPTIMIZED)
local Core = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Ini akan di-set dari main script
Core.Config = nil
Core.WindUI = nil

-- =====================================================
-- ================= CHARACTER FUNCTIONS ===============
-- =====================================================

function Core.ResetCharacter()
    local Char = LocalPlayer.Character
    if Char then
        local Hum = Char:FindFirstChild("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        if Hum then
            Hum.PlatformStand = false
            Hum.AutoRotate = true
            Hum:ChangeState(Enum.HumanoidStateType.Running)
        end
        if Root then
            Root.Anchored = false
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function Core.FindClosestPoint()
    local Config = Core.Config
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local bestCP = Config.SavedCP
    local bestFrame = Config.SavedFrame
    local bestPos = myPos
    local minDist = math.huge
    
    for i = 0, #Config.TASDataCache do
        local data = Config.TASDataCache[i]
        if data then
            for f = 1, #data, 10 do
                local frame = data[f]
                local fPos = Vector3.new(frame.POS.x, frame.POS.y, frame.POS.z)
                local dist = (myPos - fPos).Magnitude
                
                if dist < minDist then
                    minDist = dist
                    bestCP = i
                    bestFrame = f
                    bestPos = fPos
                end
            end
        end
    end
    return bestCP, bestFrame, bestPos, minDist
end

function Core.WalkToTarget(targetPos)
    local Config = Core.Config
    local Char = LocalPlayer.Character
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    
    if not Hum or not Root then return end
    
    -- ✅ FIX: Sync WalkSpeed dengan SpeedMultiplier
    if Hum then
        Hum.WalkSpeed = 16 * Config.SpeedMultiplier
    end
    
    Hum.AutoRotate = true
    Hum.PlatformStand = false
    Root.Anchored = false
    
    local oldSpeed = Hum.WalkSpeed
    Hum.WalkSpeed = 60
    
    while Config.isPlaying do
        local dist = (Root.Position - targetPos).Magnitude
        if dist < 5 then break end
        Hum:MoveTo(targetPos)
        if Root.Position.Y < -50 then Root.CFrame = CFrame.new(targetPos) break end
        RunService.Heartbeat:Wait()
    end
    
    Hum.WalkSpeed = oldSpeed
end

-- =====================================================
-- ================= TAS DATA FUNCTIONS ================
-- =====================================================

function Core.DownloadData(repoURL)
    local Config = Core.Config
    local count = 0
    Config.TASDataCache = {}
    
    for i = 0, Config.END_CP do
        if not Config.isPlaying then return false end
        local url = repoURL .. "cp_" .. i .. ".json"
        
        local success, response = pcall(function() return game:HttpGet(url) end)
        
        if success then
            local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
            if decodeSuccess then
                Config.TASDataCache[i] = data
            end
        else
            break
        end
        
        count = count + 1
        if i % 5 == 0 then RunService.Heartbeat:Wait() end
    end
    return count > 0
end

function Core.RunPlayback()
    local Config = Core.Config
    local foundCP, foundFrame, foundPos, dist = Core.FindClosestPoint()
    if dist > 5 then Core.WalkToTarget(foundPos) end
    
    Config.SavedCP = foundCP
    Config.SavedFrame = foundFrame
    
    local Char = LocalPlayer.Character
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")

    -- ✅ ACCUMULATOR SYSTEM
    local accumulator = 0
    local baseFrameTime = 0.03 -- 30 FPS default
    local lastFrameTime = tick()

    while Config.isPlaying do
        Root.Anchored = false
        Hum.PlatformStand = false
        Hum.AutoRotate = false
        
        -- ✅ Update WalkSpeed untuk animasi
        local speedMultiplier = Config.SpeedMultiplier or 1
        Hum.WalkSpeed = 16 * speedMultiplier
        
        for i = Config.SavedCP, #Config.TASDataCache do
            if not Config.isPlaying then break end
            Config.SavedCP = i
            local data = Config.TASDataCache[i]
            if not data then continue end
            
            for f = Config.SavedFrame, #data do
                if not Config.isPlaying then break end
                
                -- ✅ ACCUMULATOR LOGIC
                local currentTime = tick()
                local deltaTime = currentTime - lastFrameTime
                lastFrameTime = currentTime
                
                -- Tambah accumulator berdasarkan speed multiplier
                accumulator = accumulator + (deltaTime * speedMultiplier)
                
                -- Skip frame jika accumulator belum cukup
                if accumulator < baseFrameTime then
                    task.wait()
                    continue
                end
                
                -- Reset accumulator setelah frame diproses
                accumulator = accumulator - baseFrameTime
                
                -- ✅ Proses frame
                Config.SavedFrame = f
                local frame = data[f]
                
                if not Char or not Root then Config.isPlaying = false break end

                -- Deteksi State Climbing
                local isClimbing = false
                if frame.STA then
                    local s = frame.STA
                    if s == "Climbing" then
                        isClimbing = true
                    end
                end

                -- Auto Height Fix
                local recordedHip = frame.HIP or 2
                local currentHip = Hum.HipHeight
                if currentHip <= 0 then currentHip = 2 end
                local heightDiff = currentHip - recordedHip
                
                local posX = frame.POS.x
                local posY = frame.POS.y + heightDiff
                local posZ = frame.POS.z
                local rotY = frame.ROT or 0
                
                -- Update CFrame dengan Flip Offset
                if isClimbing then
                    Root.CFrame = CFrame.new(posX, posY, posZ) * CFrame.Angles(0, rotY + Config.FlipOffset, 0)
                    Hum.AutoRotate = true
                else
                    Root.CFrame = CFrame.new(posX, posY, posZ) * CFrame.Angles(0, rotY + Config.FlipOffset, 0)
                    Hum.AutoRotate = false
                end

                -- ✅ Terapkan Velocity dengan Speed Multiplier
                if frame.VEL then
                    local vel = Vector3.new(frame.VEL.x, frame.VEL.y, frame.VEL.z)
                    
                    if isClimbing then
                        Root.AssemblyLinearVelocity = vel * speedMultiplier * 0.8
                    else
                        Root.AssemblyLinearVelocity = vel * speedMultiplier
                    end
                else
                    Root.AssemblyLinearVelocity = Vector3.zero
                end
                
                -- Override State
                if frame.STA then
                    local s = frame.STA
                    if s == "Jumping" then
                        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        Hum.Jump = true
                    elseif s == "Freefall" then
                        Hum:ChangeState(Enum.HumanoidStateType.Freefall)
                    elseif s == "Landed" then
                        Hum:ChangeState(Enum.HumanoidStateType.Landed)
                    elseif s == "Climbing" then
                        Hum:ChangeState(Enum.HumanoidStateType.Climbing)
                    elseif s == "Running" or s == "RunningNoPhysics" then
                        Hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                else
                    if not isClimbing then
                        Hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end

                RunService.Heartbeat:Wait()
            end
            if Config.isPlaying then 
                Config.SavedFrame = 1
                accumulator = 0  -- Reset accumulator saat ganti checkpoint
            end
        end

        if Config.isPlaying then
            if Config.isLooping then
                Config.SavedCP = 0
                Config.SavedFrame = 1
                accumulator = 0  -- Reset accumulator saat loop
                
                -- ✅ Auto Respawn jika aktif
                if Config.autoRespawn then
                    Core.ResetCharacter()
                    task.wait(0.5)
                    Char = LocalPlayer.Character
                    Hum = Char:FindFirstChild("Humanoid")
                    Root = Char:FindFirstChild("HumanoidRootPart")
                end
            else
                Config.isPlaying = false
                Config.SavedCP = 0
                Config.SavedFrame = 1
                Core.ResetCharacter()
                break
            end
        else
            break
        end
    end
    
    -- ✅ Reset speed saat berhenti
    if Hum then
        Hum.WalkSpeed = 16
    end
end
                -- Deteksi State Climbing
                local isClimbing = false
                if frame.STA then
                    local s = frame.STA
                    if s == "Climbing" then
                        isClimbing = true
                    end
                end

                -- Auto Height Fix
                local recordedHip = frame.HIP or 2
                local currentHip = Hum.HipHeight
                if currentHip <= 0 then currentHip = 2 end
                local heightDiff = currentHip - recordedHip
                
                local posX = frame.POS.x
                local posY = frame.POS.y + heightDiff
                local posZ = frame.POS.z
                local rotY = frame.ROT or 0
                
                -- Update CFrame dengan Flip Offset
                if isClimbing then
                    Root.CFrame = CFrame.new(posX, posY, posZ) * CFrame.Angles(0, rotY + Config.FlipOffset, 0)
                    Hum.AutoRotate = true
                else
                    Root.CFrame = CFrame.new(posX, posY, posZ) * CFrame.Angles(0, rotY + Config.FlipOffset, 0)
                    Hum.AutoRotate = false
                end

                -- Terapkan Velocity
                if frame.VEL then
                    local vel = Vector3.new(frame.VEL.x, frame.VEL.y, frame.VEL.z)
                    
                    if isClimbing then
                        Root.AssemblyLinearVelocity = vel * Config.SpeedMultiplier * 0.8
                    else
                        Root.AssemblyLinearVelocity = vel * Config.SpeedMultiplier
                    end
                else
                    Root.AssemblyLinearVelocity = Vector3.zero
                end
                
                -- Override State
                if frame.STA then
                    local s = frame.STA
                    if s == "Jumping" then
                        Hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        Hum.Jump = true
                    elseif s == "Freefall" then
                        Hum:ChangeState(Enum.HumanoidStateType.Freefall)
                    elseif s == "Landed" then
                        Hum:ChangeState(Enum.HumanoidStateType.Landed)
                    elseif s == "Climbing" then
                        Hum:ChangeState(Enum.HumanoidStateType.Climbing)
                    elseif s == "Running" or s == "RunningNoPhysics" then
                        Hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                else
                    if not isClimbing then
                        Hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end

                RunService.Heartbeat:Wait()
            end
            if Config.isPlaying then Config.SavedFrame = 1 end
        end

        if Config.isPlaying then
            if Config.isLooping then
                Config.SavedCP = 0
                Config.SavedFrame = 1
            else
                Config.isPlaying = false
                Config.SavedCP = 0
                Config.SavedFrame = 1
                Core.ResetCharacter()
                break
            end
        else
            break
        end
    end
end

function Core.GetRepoURL(trackName)
    local Config = Core.Config
    if not trackName then return "" end
    local repoName = string.lower(string.match(trackName, "%S+$"))
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/", Config.GitHubUser, repoName, Config.Branch)
end

-- =====================================================
-- ================= GOD MODE FUNCTIONS ================
-- =====================================================

local GodModeConnection = nil
local OriginalHealth = nil

function Core.EnableGodMode()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Simpan health asli
    OriginalHealth = humanoid.MaxHealth
    
    -- Set health jadi infinite
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge
    
    -- Monitor terus health agar tetap infinite
    if GodModeConnection then GodModeConnection:Disconnect() end
    GodModeConnection = humanoid.HealthChanged:Connect(function()
        if Core.Config.godMode then
            humanoid.Health = math.huge
        end
    end)
    
    print("✅ God Mode Enabled")
end

function Core.DisableGodMode()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Disconnect connection
    if GodModeConnection then
        GodModeConnection:Disconnect()
        GodModeConnection = nil
    end
    
    -- Restore health asli
    if OriginalHealth then
        humanoid.MaxHealth = OriginalHealth
        humanoid.Health = OriginalHealth
    else
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
    
    print("❌ God Mode Disabled")
end

-- =====================================================
-- ================= AUTO RESPAWN ======================
-- =====================================================

function Core.AutoRespawn()
    if not Core.Config.autoRespawn then return end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            wait(0.5)
            LocalPlayer.Character:BreakJoints()
            wait(Players.RespawnTime + 0.5)
        end
    end
end

-- =====================================================
-- ================= PLAYER MENU =======================
-- =====================================================

-- WalkSpeed Manager
Core.SetWalkSpeed = function(speed)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = speed
        Core.Config.PlayerMenu.WalkSpeed.Current = speed
        return true
    end
    return false
end

-- Restore default walkspeed
Core.ResetWalkSpeed = function()
    return Core.SetWalkSpeed(Core.Config.PlayerMenu.WalkSpeed.Default)
end

-- Infinite Jump Manager
Core.InfiniteJump = {
    Connection = nil,
    Enabled = false,
    
    Enable = function()
        if Core.InfiniteJump.Enabled then return end
        Core.InfiniteJump.Enabled = true
        Core.Config.PlayerMenu.InfiniteJump = true
        
        local UserInputService = game:GetService("UserInputService")
        
        Core.InfiniteJump.Connection = UserInputService.JumpRequest:Connect(function()
            if Core.InfiniteJump.Enabled then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end,
    
    Disable = function()
        Core.InfiniteJump.Enabled = false
        Core.Config.PlayerMenu.InfiniteJump = false
        
        if Core.InfiniteJump.Connection then
            Core.InfiniteJump.Connection:Disconnect()
            Core.InfiniteJump.Connection = nil
        end
    end
}

-- Full Bright Manager
Core.FullBright = {
    Enabled = false,
    
    Enable = function()
        if Core.FullBright.Enabled then return end
        Core.FullBright.Enabled = true
        Core.Config.PlayerMenu.FullBright = true
        
        local Lighting = game:GetService("Lighting")
        
        -- Save original settings (hanya sekali)
        if not Core.Config.PlayerMenu.OriginalLighting.Brightness then
            Core.Config.PlayerMenu.OriginalLighting = {
                Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd
            }
        end
        
        -- Apply full bright
        Lighting.Brightness = Core.Config.PlayerMenu.FullBrightIntensity
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        
        -- Disable visual effects
        for _, v in pairs(Lighting:GetChildren()) do
            pcall(function()
                if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
                   v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
                   v:IsA("Atmosphere") then
                    v.Enabled = false
                end
            end)
        end
    end,
    
    Disable = function()
        if not Core.FullBright.Enabled then return end
        Core.FullBright.Enabled = false
        Core.Config.PlayerMenu.FullBright = false
        
        local Lighting = game:GetService("Lighting")
        local original = Core.Config.PlayerMenu.OriginalLighting
        
        -- Restore original settings
        if original.Brightness then
            Lighting.Brightness = original.Brightness
            Lighting.Ambient = original.Ambient
            Lighting.OutdoorAmbient = original.OutdoorAmbient
            Lighting.ClockTime = original.ClockTime
            Lighting.FogEnd = original.FogEnd
        end
        
        -- Re-enable visual effects
        for _, v in pairs(Lighting:GetChildren()) do
            pcall(function()
                if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
                   v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
                   v:IsA("Atmosphere") then
                    v.Enabled = true
                end
            end)
        end
    end
}

-- FPS Booster Manager
Core.FPSBooster = {
    Enabled = false,
    
    Enable = function()
        if Core.FPSBooster.Enabled then return end
        Core.FPSBooster.Enabled = true
        Core.Config.PlayerMenu.FPSBooster = true
        
        local decalsyeeted = true
        local workspace = game.Workspace
        local lighting = game.Lighting
        local terrain = workspace.Terrain
        
        -- Apply FPS boost settings
        pcall(function()
            sethiddenproperty(lighting, "Technology", Enum.Technology.Compatibility)
            sethiddenproperty(terrain, "Decoration", false)
        end)
        
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        lighting.Brightness = 0
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        -- Optimize all parts and effects
        for _, v in pairs(game:GetDescendants()) do
            pcall(function()
                if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                elseif v:IsA("Explosion") then
                    v.BlastPressure = 1
                    v.BlastRadius = 1
                elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                elseif v:IsA("MeshPart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                    v.TextureID = ""
                end
            end)
        end
        
        -- Disable lighting effects
        for _, e in pairs(lighting:GetChildren()) do
            pcall(function()
                if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or 
                   e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or 
                   e:IsA("DepthOfFieldEffect") then
                    e.Enabled = false
                end
            end)
        end
    end,
    
    Disable = function()
        Core.FPSBooster.Enabled = false
        Core.Config.PlayerMenu.FPSBooster = false
        -- Note: Graphics can't be fully restored without rejoining
    end
}

-- =====================================================
-- ================= UTILITY FUNCTIONS =================
-- =====================================================

-- Reset all player menu features
Core.ResetPlayerMenu = function()
    Core.InfiniteJump.Disable()
    Core.FullBright.Disable()
    Core.FPSBooster.Disable()
    Core.ResetWalkSpeed()
    
    if Core.WindUI then
        Core.WindUI:Notify({
            Title = "Reset", 
            Content = "All player features reset", 
            Duration = 2
        })
    end
end

-- Get current player menu status
Core.GetPlayerMenuStatus = function()
    return {
        WalkSpeed = Core.Config.PlayerMenu.WalkSpeed.Current,
        InfiniteJump = Core.Config.PlayerMenu.InfiniteJump,
        FullBright = Core.Config.PlayerMenu.FullBright,
        FPSBooster = Core.Config.PlayerMenu.FPSBooster
    }
end

-- =====================================================
-- ================= ANIMATION SYSTEM ==================
-- =====================================================

Core.Controller = {
    Tracks = {},
    Connections = {},
    State = "Idle",
    Preset = nil,
    IsDefault = false
}

-- Utility Functions
local function stopAllTracks()
    for _, track in pairs(Core.Controller.Tracks) do
        pcall(function()
            track:Stop(0.15)
            track:Destroy()
        end)
    end
    Core.Controller.Tracks = {}
end

local function disconnectAll()
    for _, c in pairs(Core.Controller.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Core.Controller.Connections = {}
end

local function cleanup()
    stopAllTracks()
    disconnectAll()
    Core.Controller.State = "Idle"
end

-- Character / Humanoid
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid(char)
    return char:WaitForChild("Humanoid")
end

local function getAnimator(humanoid)
    return humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
end

-- Default Restore
function Core.RestoreDefault()
    cleanup()
    Core.Controller.Preset = nil
    Core.Controller.IsDefault = true

    local char = getCharacter()
    local humanoid = getHumanoid(char)

    -- stop all custom tracks
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function()
                track:Stop(0)
                track:Destroy()
            end)
        end
    end

    -- restore Animate script
    local animate = char:FindFirstChild("Animate")
    if not animate then
        local defaultAnimate = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        humanoid:ApplyDescription(defaultAnimate)
    end
end

-- Apply Preset
function Core.ApplyPreset(preset)
    if not preset then return end

    -- DEFAULT
    if preset.__DEFAULT then
        Core.RestoreDefault()
        return
    end

    cleanup()

    Core.Controller.Preset = preset
    Core.Controller.IsDefault = false

    local char = getCharacter()
    local humanoid = getHumanoid(char)
    local root = char:WaitForChild("HumanoidRootPart")
    local animator = getAnimator(humanoid)

    -- remove Roblox Animate
    local animate = char:FindFirstChild("Animate")
    if animate then animate:Destroy() end

    -- Load Track
    local function load(id)
        if not id then return nil end
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local track = animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Movement
        return track
    end

    Core.Controller.Tracks = {
        Idle = load(preset.Idle),
        Walk = load(preset.Walk),
        Run  = load(preset.Run),
        Jump = load(preset.Jump),
        Fall = load(preset.Fall)
    }

    if Core.Controller.Tracks.Idle then
        Core.Controller.Tracks.Idle:Play(0.2)
        Core.Controller.State = "Idle"
    end

    -- State Loop (Anti Bug)
    Core.Controller.Connections.Heartbeat =
        RunService.Heartbeat:Connect(function()
            if humanoid.Health <= 0 then return end

            local velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z).Magnitude
            local state = humanoid:GetState()

            local function switch(name)
                if Core.Controller.State == name then return end
                for k, t in pairs(Core.Controller.Tracks) do
                    if k ~= name and t then t:Stop(0.15) end
                end
                if Core.Controller.Tracks[name] then
                    Core.Controller.Tracks[name]:Play(0.15)
                    Core.Controller.State = name
                end
            end

            if state == Enum.HumanoidStateType.Jumping then
                switch("Jump")
            elseif state == Enum.HumanoidStateType.Freefall then
                switch("Fall")
            elseif velocity > 14 then
                switch("Run")
            elseif velocity > 1 then
                switch("Walk")
            else
                switch("Idle")
            end
        end)
end

-- Respawn Safe
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Core.Controller.Preset then
        Core.ApplyPreset(Core.Controller.Preset)
    end
end)

-- =====================================================
-- ================= SKYBOX FUNCTIONS ==================
-- =====================================================

local OriginalSky = nil
local CurrentSkybox = nil

function Core.ApplySkybox(skyName)
    local Lighting = game:GetService("Lighting")
    local preset = Core.Config.Skybox.Presets[skyName]
    
    if not preset then
        warn("Sky preset not found: " .. skyName)
        return false
    end
    
    -- Simpan original sky jika belum
    if not OriginalSky then
        local existingSky = Lighting:FindFirstChildOfClass("Sky")
        if existingSky then
            OriginalSky = existingSky:Clone()
        end
    end
    
    -- Hapus skybox yang ada
    Core.RemoveSkybox()
    
    -- Buat skybox baru
    local sky = Instance.new("Sky")
    sky.Name = "CustomSkybox"
    sky.SkyboxBk = preset.SkyboxBk
    sky.SkyboxDn = preset.SkyboxDn
    sky.SkyboxFt = preset.SkyboxFt
    sky.SkyboxLf = preset.SkyboxLf
    sky.SkyboxRt = preset.SkyboxRt
    sky.SkyboxUp = preset.SkyboxUp
    sky.Parent = Lighting
    
    CurrentSkybox = sky
    Core.Config.Skybox.Current = skyName
    Core.Config.Skybox.Active = true
    
    return true
end

function Core.RemoveSkybox()
    local Lighting = game:GetService("Lighting")
    
    -- Hapus custom skybox
    local customSky = Lighting:FindFirstChild("CustomSkybox")
    if customSky then
        customSky:Destroy()
    end
    
    CurrentSkybox = nil
    Core.Config.Skybox.Current = "None"
    Core.Config.Skybox.Active = false
    
    -- Restore original sky jika ada
    if OriginalSky then
        local existingSky = Lighting:FindFirstChildOfClass("Sky")
        if existingSky then
            existingSky:Destroy()
        end
        local restoredSky = OriginalSky:Clone()
        restoredSky.Parent = Lighting
    end
    
    return true
end

-- Reset skybox saat respawn
LocalPlayer.CharacterAdded:Connect(function()
    if Core.Config.Skybox.Active then
        task.wait(0.5)
        Core.ApplySkybox(Core.Config.Skybox.Current)
    end
end)

print("✅ CORE.LUA - All Systems Ready")

return Core
