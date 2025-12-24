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

return Core
