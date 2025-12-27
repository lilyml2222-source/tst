-- CORE.LUA (EXC FREEMIUM) -- Ready-to-upload GitHub version -- Integrated with WindUI Auto Walk menu -- Speed system: EXC Playback (frame-skip & slow-motion)

local Players = game:GetService("Players") local RunService = game:GetService("RunService") local HttpService = game:GetService("HttpService")

local Core = {} Core.Config = Core.Config or {}

-- ================= CONFIG DEFAULT ================= 
Core.Config.SpeedMultiplier = Core.Config.SpeedMultiplier or 1 Core.Config.isPlaying = false Core.Config.isLooping = Core.Config.isLooping or false Core.Config.FlipOffset = Core.Config.FlipOffset or 0 Core.Config.SavedCP = Core.Config.SavedCP or 0 Core.Config.SavedFrame = Core.Config.SavedFrame or 1 Core.Config.TASDataCache = Core.Config.TASDataCache or {}

-- ================= PLAYER =================
local LocalPlayer = Players.LocalPlayer local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local Root = Character:WaitForChild("HumanoidRootPart") local Hum = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(char) Character = char Root = char:WaitForChild("HumanoidRootPart") Hum = char:WaitForChild("Humanoid") end)

-- ================= UTIL ================= 
function Core.ResetCharacter() if Hum then Hum.PlatformStand = false Hum.AutoRotate = true Hum:ChangeState(Enum.HumanoidStateType.Running) end if Root then Root.AssemblyLinearVelocity = Vector3.zero Root.AssemblyAngularVelocity = Vector3.zero end end

-- ================= DATA DOWNLOAD =================
function Core.DownloadData(baseURL) local cache = {} for i = 0, 100 do if not Core.Config.isPlaying then return false end local url = baseURL .. "/cp_" .. i .. ".json" local ok, res = pcall(function() return game:HttpGet(url) end) if not ok then if i == 0 then return false end break end cache[i] = HttpService:JSONDecode(res) task.wait() end Core.Config.TASDataCache = cache Core.Config.SavedCP = 0 Core.Config.SavedFrame = 1 return true end

-- ================= SPEED API ================= 
function Core.SetSpeed(v) Core.Config.SpeedMultiplier = math.clamp(v, 0.1, 10) end

-- ================= STOP =================
function Core.Stop() Core.Config.isPlaying = false task.wait() Core.ResetCharacter() end

-- ================= PLAYBACK =================
function Core.RunPlayback() if Core.Config.isPlaying then return end Core.Config.isPlaying = true

Hum.AutoRotate = false
Hum.PlatformStand = false

local dataCache = Core.Config.TASDataCache

while Core.Config.isPlaying do
    for cp = Core.Config.SavedCP, #dataCache do
        if not Core.Config.isPlaying then break end
        Core.Config.SavedCP = cp

        local data = dataCache[cp]
        if not data then continue end

        for f = Core.Config.SavedFrame, #data do
            if not Core.Config.isPlaying then break end
            Core.Config.SavedFrame = f

            local frame = data[f]
            if not frame then continue end

            local rotY = (frame.ROT or 0) + (Core.Config.FlipOffset or 0)

            Root.CFrame = CFrame.new(
                frame.POS.x,
                frame.POS.y,
                frame.POS.z
            ) * CFrame.Angles(0, rotY, 0)

            if frame.VEL then
                Root.AssemblyLinearVelocity = Vector3.new(
                    frame.VEL.x,
                    frame.VEL.y,
                    frame.VEL.z
                )
            end

            if frame.STA then
                local s = frame.STA
                if s == "Jumping" then Hum:ChangeState(Enum.HumanoidStateType.Jumping) Hum.Jump = true
                elseif s == "Freefall" then Hum:ChangeState(Enum.HumanoidStateType.Freefall)
                elseif s == "Landed" then Hum:ChangeState(Enum.HumanoidStateType.Landed)
                elseif s == "Running" then Hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end

            -- ===== SPEED SYSTEM =====
            local speed = Core.Config.SpeedMultiplier or 1
            if speed >= 1 then
                if f % math.floor(speed) == 0 then
                    RunService.Heartbeat:Wait()
                end
            else
                local t = tick()
                while tick() - t < (1/60) / speed do
                    RunService.Heartbeat:Wait()
                end
            end
        end

        if Core.Config.isPlaying then
            Core.Config.SavedFrame = 1
        end
    end

    if Core.Config.isLooping then
        Core.Config.SavedCP = 0
        Core.Config.SavedFrame = 1
    else
        break
    end
end

Core.Config.isPlaying = false
Core.Config.SavedCP = 0
Core.Config.SavedFrame = 1
Core.ResetCharacter()

end

-- ================= GOD MODE (OPTIONAL) ================= function Core.EnableGodMode() if Hum then Hum.MaxHealth = math.huge Hum.Health = math.huge end end

function Core.DisableGodMode() if Hum then Hum.MaxHealth = 100 Hum.Health = math.clamp(Hum.Health, 0, 100) end end

return Core
