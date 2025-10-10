repeat task.wait() until game:IsLoaded()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local endgameCount = 0
local maxSeamlessRounds = 4
local hasRun = false

repeat task.wait(0.5) until not LocalPlayer.PlayerGui:FindFirstChild("TeleportUI")

print("[Seamless Limiter] Waiting for Settings GUI...")
repeat task.wait(0.5) until LocalPlayer.PlayerGui:FindFirstChild("Settings")
print("[Seamless Limiter] Settings GUI found!")

local function getSeamlessValue()
    local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
    if settings then
        local seamless = settings:FindFirstChild("SeamlessRetry")
        if seamless then
            print("[Seamless Limiter] SeamlessRetry.Value =", seamless.Value)
            return seamless.Value
        else
            print("[Seamless Limiter] SeamlessRetry not found in Settings")
        end
    else
        print("[Seamless Limiter] Settings not found")
    end
    return false
end

local function setSeamlessRetry()
    pcall(function()
        RS.Remotes.SetSettings:InvokeServer("SeamlessRetry")
    end)
end

local function restartMatch()
    pcall(function()
        RS.Remotes.RestartMatch:FireServer()
    end)
end

print("[Seamless Limiter] Checking initial seamless state...")
local currentSeamless = getSeamlessValue()
if endgameCount < maxSeamlessRounds then
    if not currentSeamless then
        setSeamlessRetry()
        task.wait(0.5)
        print("[Seamless Limiter] Enabled Seamless Retry")
    else
        print("[Seamless Limiter] Seamless Retry already enabled")
    end
end

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "EndGameUI" and not hasRun then
        hasRun = true
        endgameCount = endgameCount + 1
        print("[Seamless Limiter] Endgame detected. Current seamless rounds: " .. endgameCount .. "/" .. maxSeamlessRounds)
        
        if endgameCount >= maxSeamlessRounds and getSeamlessValue() then
            task.wait(0.5)
            setSeamlessRetry()
            print("[Seamless Limiter] Disabled Seamless Retry")
            task.wait(0.5)
            if not getSeamlessValue() then
                restartMatch()
                print("[Seamless Limiter] Restarted match")
            end
        end
    end
end)

LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
    if child.Name == "EndGameUI" then
        hasRun = false
        print("[Seamless Limiter] EndgameUI removed, ready for next round")
    end
end)

while true do
    task.wait(1)
end
