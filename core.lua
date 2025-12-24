-- CORE.LUA - Main Logic Functions
local Core = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Ini akan di-set dari main script
Core.Config = nil
Core.WindUI = nil

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

    while Config.isPlaying do
        Root.Anchored = false
        Hum.PlatformStand = false
        Hum.AutoRotate = false
        
        for i = Config.SavedCP, #Config.TASDataCache do
            if not Config.isPlaying then break end
            Config.SavedCP = i
            local data = Config.TASDataCache[i]
            if not data then continue end
            
            for f = Config.SavedFrame, #data do
                if not Config.isPlaying then break end
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

-- [[ GOD MODE FUNCTIONS ]]
local GodModeConnection = nil
local OriginalHealth = nil

function Core.EnableGodMode()
    local character = game.Players.LocalPlayer.Character
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
    local character = game.Players.LocalPlayer.Character
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

-- [[ AUTO RESPAWN FUNCTION ]]
function Core.AutoRespawn()
    if not Core.Config.autoRespawn then return end
    
    local character = game.Players.LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            wait(0.5)
            game.Players.LocalPlayer.Character:BreakJoints()
            wait(game.Players.RespawnTime + 0.5)
        end
    end
end

-- WalkSpeed Manager
Core.SetWalkSpeed = function(speed)
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = speed
        return true
    end
    return false
end

-- Infinite Jump Manager
Core.InfiniteJump = {
    Connection = nil,
    Enabled = false,
    
    Enable = function()
        if Core.InfiniteJump.Enabled then return end
        Core.InfiniteJump.Enabled = true
        
        local UserInputService = game:GetService("UserInputService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
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
        if Core.InfiniteJump.Connection then
            Core.InfiniteJump.Connection:Disconnect()
            Core.InfiniteJump.Connection = nil
        end
    end
}

-- Full Bright Manager
Core.FullBright = {
    Enabled = false,
    OriginalSettings = {},
    
    Enable = function()
        if Core.FullBright.Enabled then return end
        Core.FullBright.Enabled = true
        
        local Lighting = game:GetService("Lighting")
        
        -- Save original settings
        Core.FullBright.OriginalSettings = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd
        }
        
        -- Apply full bright
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        
        -- Disable visual effects
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
               v:IsA("Atmosphere") then
                v.Enabled = false
            end
        end
    end,
    
    Disable = function()
        if not Core.FullBright.Enabled then return end
        Core.FullBright.Enabled = false
        
        local Lighting = game:GetService("Lighting")
        
        -- Restore original settings
        if Core.FullBright.OriginalSettings.Brightness then
            Lighting.Brightness = Core.FullBright.OriginalSettings.Brightness
            Lighting.Ambient = Core.FullBright.OriginalSettings.Ambient
            Lighting.OutdoorAmbient = Core.FullBright.OriginalSettings.OutdoorAmbient
            Lighting.ClockTime = Core.FullBright.OriginalSettings.ClockTime
            Lighting.FogEnd = Core.FullBright.OriginalSettings.FogEnd
        end
        
        -- Re-enable visual effects
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or 
               v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or 
               v:IsA("Atmosphere") then
                v.Enabled = true
            end
        end
    end
}

-- FPS Booster Manager
Core.FPSBooster = {
    Enabled = false,
    
    Enable = function()
        if Core.FPSBooster.Enabled then return end
        Core.FPSBooster.Enabled = true
        
        local decalsyeeted = true
        local game = game
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
        -- Note: Graphics can't be fully restored without rejoining
    end
}

return Core
