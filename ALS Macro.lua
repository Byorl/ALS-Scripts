repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

task.wait(2)

local function isTeleportUIVisible()
    local tpUI = LocalPlayer.PlayerGui:FindFirstChild("TeleportUI")
    if not tpUI then return false end
    local ok, visible = pcall(function() return tpUI.Enabled end)
    return ok and visible
end

local function isPlayerInValidState()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    return true
end

local maxWaitTime = 0
local maxWait = 20
repeat
    task.wait(0.2)
    maxWaitTime = maxWaitTime + 0.2
until (not isTeleportUIVisible() and isPlayerInValidState()) or maxWaitTime > maxWait

if maxWaitTime > maxWait and not isPlayerInValidState() then
    task.wait(3)
end

task.wait(1)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local oldLogWarn = logwarn or warn
local function filteredWarn(...)
    local msg = tostring(...)
    if not (msg:find("ImageLabel") or msg:find("not a valid member") or msg:find("is not a valid member")) then
        oldLogWarn(...)
    end
end
if logwarn then logwarn = filteredWarn end
warn = filteredWarn

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CONFIG_FOLDER = "ALSHalloweenEvent"
local MACRO_FOLDER = CONFIG_FOLDER .. "/macros"
if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

local STATE_FILE = MACRO_FOLDER .. "/playback_state.json"
local SETTINGS_FILE = MACRO_FOLDER .. "/settings.json"

local Macros = {}
local CurrentMacro = nil
local recording = false
local playing = false
local macroData = {}
local StepDelay = 0
local resumeFromStep = 0

local StatusText = "Idle"
local ActionText = ""
local UnitText = ""
local WaitingText = ""
local CurrentStep = 0
local TotalSteps = 0

local TowerInfoCache = {}
local RemoteCache = {}

local lastCash = 0
local cashHistory = {}
local MAX_CASH_HISTORY = 30

local StatusLabel, StepLabel, ActionLabel, UnitLabel, WaitingLabel

local seamlessMode = false
local autoReplayOnRestart = false

local function loadSettings()
    local settings = {
        playMacroEnabled = false,
        selectedMacro = nil,
        macroMaps = {},
        seamlessMode = false,
        autoReplayOnRestart = false,
        stepDelay = 0
    }
    pcall(function()
        if isfile(SETTINGS_FILE) then
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            if type(data) == "table" then
                settings = data
            end
        end
    end)
    return settings
end

local function saveSettings()
    pcall(function()
        local settings = {
            playMacroEnabled = playing,
            selectedMacro = CurrentMacro,
            macroMaps = getgenv().MacroMaps or {},
            seamlessMode = seamlessMode,
            autoReplayOnRestart = autoReplayOnRestart,
            stepDelay = StepDelay
        }
        writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
    end)
end

local function notify(title, content, duration)
    WindUI:Notify({
        Title = title or "Macro",
        Content = content or "",
        Duration = duration or 3,
    })
end

local function cacheTowerInfo()
    if next(TowerInfoCache) then return end
    local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
    for _, mod in pairs(towerInfoPath:GetChildren()) do
        if mod:IsA("ModuleScript") then
            local ok, data = pcall(function() return require(mod) end)
            if ok then TowerInfoCache[mod.Name] = data end
        end
    end
    print("[Macro] Cached tower info for " .. tostring(#TowerInfoCache) .. " towers")
end

local function cacheRemotes()
    if next(RemoteCache) then return end
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            RemoteCache[v.Name:lower()] = v
        end
    end
    print("[Macro] Cached " .. tostring(#RemoteCache) .. " remotes")
end

task.spawn(function()
    task.wait(2)
    cacheTowerInfo()
    cacheRemotes()
end)

local cashTrackingActive = false
local function trackCash()
    if cashTrackingActive then return end
    cashTrackingActive = true
    
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            
            local currentCash = 0
            pcall(function()
                currentCash = LocalPlayer.Cash.Value
            end)
            
            if lastCash > 0 and currentCash < lastCash then
                local decrease = lastCash - currentCash
                table.insert(cashHistory, 1, {
                    time = tick(),
                    decrease = decrease,
                    before = lastCash,
                    after = currentCash
                })
                
                if #cashHistory > MAX_CASH_HISTORY then
                    table.remove(cashHistory, #cashHistory)
                end
            end
            
            lastCash = currentCash
        end
    end)
end

trackCash()

local function getRecentCashDecrease(withinSeconds)
    withinSeconds = withinSeconds or 1
    local now = tick()
    for _, entry in ipairs(cashHistory) do
        if (now - entry.time) <= withinSeconds then
            return entry.decrease
        end
    end
    return 0
end

local function getPlaceCost(towerName)
    cacheTowerInfo()
    if not TowerInfoCache[towerName] then return 0 end
    if TowerInfoCache[towerName][0] then
        return TowerInfoCache[towerName][0].Cost or 0
    end
    return 0
end

local function loadMacros()
    Macros = {}
    if not isfolder(MACRO_FOLDER) then return end
    for _, file in pairs(listfiles(MACRO_FOLDER)) do
        if file:sub(-5) == ".json" then
            local fileName = file:match("([^/\\]+)%.json$")
            
            if fileName ~= "settings" and fileName ~= "playback_state" then
                local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
                if ok and type(data) == "table" then
                    local isSettings = (data.playMacroEnabled ~= nil or data.selectedMacro ~= nil or data.macroMaps ~= nil)
                    if not isSettings then
                        Macros[fileName] = data
                    end
                end
            end
        end
    end
end

local function saveMacro(name, data)
    local success, err = pcall(function()
        writefile(MACRO_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        Macros[name] = data
    end)
    if not success then
        warn("[Macro] Failed to save:", err)
    end
    return success
end

local function savePlaybackState(macroName, currentStep)
    pcall(function()
        local state = {
            macro = macroName,
            step = currentStep,
            timestamp = tick()
        }
        writefile(STATE_FILE, HttpService:JSONEncode(state))
    end)
end

local function loadPlaybackState()
    local state = nil
    pcall(function()
        if isfile(STATE_FILE) then
            state = HttpService:JSONDecode(readfile(STATE_FILE))
        end
    end)
    return state
end

local function clearPlaybackState()
    pcall(function()
        if isfile(STATE_FILE) then
            delfile(STATE_FILE)
        end
    end)
end

local function isAutoUpgradeClone(towerName)
    local autoUpgradeClones = {
        "NarutoBaryonClone",
        "WukongClone",
    }
    
    for _, cloneName in ipairs(autoUpgradeClones) do
        if towerName == cloneName then
            return true
        end
    end
    
    return false
end

local function getMacroNames()
    local names = {}
    for name in pairs(Macros) do table.insert(names, name) end
    table.sort(names)
    return names
end

local Window = WindUI:CreateWindow({
    Title = "Macro System",
    Author = "ALS - Macro",
    Folder = "ALS-Macro",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Macro System",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 1,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromRGB(48, 255, 106), Color3.fromRGB(231, 255, 47)),
    },
})

local MainSection = Window:Section({
    Title = "Main",
    Icon = "play",
})

local MapsSection = Window:Section({
    Title = "Macro Maps",
    Icon = "map",
})

local SettingsSection = Window:Section({
    Title = "Settings",
    Icon = "settings",
})

local Tabs = {
    Main = MainSection:Tab({ Title = "Controls", Icon = "play" }),
    Maps = MapsSection:Tab({ Title = "Map Assignment", Icon = "map" }),
    Settings = SettingsSection:Tab({ Title = "Settings", Icon = "settings" }),
}

loadMacros()

local savedSettings = loadSettings()
getgenv().MacroMaps = savedSettings.macroMaps or {}
seamlessMode = savedSettings.seamlessMode or false
autoReplayOnRestart = savedSettings.autoReplayOnRestart or false
StepDelay = savedSettings.stepDelay or 0
local MapData = nil
pcall(function()
    local mapDataModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
    if mapDataModule and mapDataModule:IsA("ModuleScript") then
        MapData = require(mapDataModule)
    end
end)

local function getMapsByGamemode(gamemode)
    if not MapData then return {} end
    if gamemode == "ElementalCaverns" then return {"Light","Nature","Fire","Dark","Water"} end
    local maps = {}
    for mapName, mapInfo in pairs(MapData) do
        if mapInfo.Type and type(mapInfo.Type) == "table" then
            for _, mapType in ipairs(mapInfo.Type) do
                if mapType == gamemode then
                    table.insert(maps, mapName)
                    break
                end
            end
        end
    end
    table.sort(maps)
    return maps
end

local lastStatusUpdate = 0
local updateStatus
updateStatus = function()
    local now = tick()
    if now - lastStatusUpdate < 0.03 then return end
    lastStatusUpdate = now
    
    pcall(function()
        if StatusLabel then StatusLabel:SetTitle("Status: " .. StatusText) end
        if StepLabel then StepLabel:SetTitle("📝 Step: " .. CurrentStep .. "/" .. TotalSteps) end
        if ActionLabel then ActionLabel:SetTitle("⚡ Action: " .. ActionText) end
        if UnitLabel then UnitLabel:SetTitle("🗼 Unit: " .. UnitText) end
        if WaitingLabel then WaitingLabel:SetTitle("⏳ Waiting: " .. WaitingText) end
    end)
end

Tabs.Main:Paragraph({
    Title = "🎬 Macro System",
    Desc = ""
})

Tabs.Main:Space()
Tabs.Main:Divider()
Tabs.Main:Space()

Tabs.Main:Paragraph({
    Title = "📝 Macro Management",
    Desc = "Create, select, and manage your macros"
})

Tabs.Main:Space()

local macroDropdown = Tabs.Main:Dropdown({
    Flag = "MacroSelect",
    Title = "Select Macro",
    Values = getMacroNames(),
    Callback = function(v)
        CurrentMacro = v
        if v and Macros[v] then
            macroData = Macros[v]
            TotalSteps = #macroData
            notify("Macro Selected", v .. " (" .. #macroData .. " steps)", 3)
            updateStatus()
            saveSettings()
        end
    end,
    Searchable = true,
})

if savedSettings.selectedMacro and Macros[savedSettings.selectedMacro] then
    task.spawn(function()
        task.wait(0.3)
        pcall(function()
            macroDropdown:Select(savedSettings.selectedMacro)
            CurrentMacro = savedSettings.selectedMacro
            macroData = Macros[CurrentMacro]
            TotalSteps = #macroData
            updateStatus()
        end)
    end)
end

Tabs.Main:Space()

Tabs.Main:Input({
    Flag = "MacroName",
    Title = "Create New Macro",
    Placeholder = "Enter macro name",
    Callback = function(v)
        if v and v ~= "" and not Macros[v] then
            print("[Macro] Creating macro: " .. v)
            
            saveMacro(v, {})
            
            task.wait(0.1)
            loadMacros()
            
            Macros[v] = Macros[v] or {}
            CurrentMacro = v
            macroData = {}
            TotalSteps = 0
            
            print("[Macro] Macro created successfully!")
            print("[Macro] CurrentMacro set to: " .. v)
            
            task.spawn(function()
                task.wait(0.1)
                
                loadMacros()
                local newMacroNames = getMacroNames()
                print("[Macro] Refreshing dropdown with " .. #newMacroNames .. " macros:", table.concat(newMacroNames, ", "))
                
                if macroDropdown then
                    pcall(function()
                        macroDropdown:Refresh(newMacroNames)
                    end)
                    
                    task.wait(0.2)
                    
                    pcall(function()
                        macroDropdown:Select(v)
                        print("[Macro] Selected '" .. v .. "' in dropdown")
                    end)
                end
                
                print("[Macro] Refreshing map assignment dropdowns...")
                pcall(function()
                    updateMapDisplay()
                end)
                
                updateStatus()
                notify("Macro Created", v .. " - Ready to record!", 3)
                saveSettings()
            end)
        elseif Macros[v] then
            notify("Error", "Macro '" .. v .. "' already exists!", 3)
        end
    end
})

Tabs.Main:Space()
Tabs.Main:Divider()
Tabs.Main:Space()

Tabs.Main:Paragraph({
    Title = "🎮 Recording & Playback",
    Desc = "Control macro recording and playback"
})

Tabs.Main:Space()

Tabs.Main:Toggle({
    Flag = "RecordMacro",
    Title = "🔴 Record Macro",
    Default = false,
    Callback = function(v)
        recording = v
        if v then
            if not CurrentMacro then
                notify("Error", "Please select or create a macro first", 5)
                recording = false
                return
            end
            macroData = {}
            StatusText = "Recording"
            getgenv().TowerPlaceCounts = {}
            cashHistory = {}
            CurrentStep = 0
            TotalSteps = 0
            ActionText = ""
            UnitText = ""
            WaitingText = ""
            updateStatus()
            notify("Recording Started", CurrentMacro, 3)
        else
            StatusText = "Idle"
            ActionText = ""
            UnitText = ""
            WaitingText = ""
            updateStatus()
            if CurrentMacro and #macroData > 0 then
                local success = saveMacro(CurrentMacro, macroData)
                if success then
                    notify("Recording Saved", #macroData .. " steps saved to " .. CurrentMacro, 5)
                else
                    notify("Save Failed", "Could not save macro", 5)
                end
            end
        end
    end
})

Tabs.Main:Space()

local playToggle = Tabs.Main:Toggle({
    Flag = "PlayMacro",
    Title = "▶️ Play Macro",
    Default = savedSettings.playMacroEnabled or false,
    Callback = function(v)
        playing = v
        saveSettings()
        if v then
            local mapMacroLoaded = false
            pcall(function()
                local gamemode = RS:FindFirstChild("Gamemode")
                local mapName = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MapName")
                if gamemode and mapName then
                    local gm = gamemode.Value
                    local mn = mapName.Value
                    local key = gm .. "_" .. mn
                    if getgenv().MacroMaps[key] and getgenv().MacroMaps[key] ~= "--" and Macros[getgenv().MacroMaps[key]] then
                        CurrentMacro = getgenv().MacroMaps[key]
                        macroData = Macros[CurrentMacro] or {}
                        TotalSteps = #macroData
                        mapMacroLoaded = true
                        
                        task.spawn(function()
                            task.wait(0.2)
                            pcall(function()
                                macroDropdown:Select(CurrentMacro)
                            end)
                        end)
                        
                        notify("Map Macro Loaded", "Using " .. CurrentMacro .. " for " .. mn, 3)
                    end
                end
            end)
            
            if not CurrentMacro or #macroData == 0 then
                notify("Error", "No macro selected or macro is empty", 5)
                playing = false
                return
            end
            
            local savedState = loadPlaybackState()
            if savedState and savedState.macro == CurrentMacro and (tick() - savedState.timestamp) < 300 then
                resumeFromStep = savedState.step
                notify("Resuming Playback", CurrentMacro .. " from step " .. resumeFromStep, 4)
            else
                resumeFromStep = 0
                notify("Playback Started", CurrentMacro, 3)
            end
            
            task.spawn(function()
                local step = resumeFromStep > 0 and resumeFromStep or 1
                local lastWave = 0
                
                local function hasStartButton()
                    local hasStart = false
                    pcall(function()
                        local b = LocalPlayer.PlayerGui:FindFirstChild("Bottom")
                        if b and b.Frame and b.Frame:GetChildren()[2] then
                            local sub = b.Frame:GetChildren()[2]:GetChildren()[6]
                            if sub and sub.TextButton and sub.TextButton.TextLabel then
                                hasStart = sub.TextButton.TextLabel.Text == "Start"
                            end
                        end
                    end)
                    return hasStart
                end
                
                if resumeFromStep == 0 then
                    StatusText = "Waiting for Start"
                    WaitingText = ""
                    ActionText = ""
                    UnitText = ""
                    updateStatus()
                    
                    repeat task.wait(0.1) until not hasStartButton() or not playing
                    if not playing then return end
                    
                    pcall(function() lastWave = RS.Wave.Value end)
                    task.wait(0.5)
                else
                    StatusText = "Resuming"
                    updateStatus()
                    task.wait(0.5)
                end
                
                while playing or (seamlessMode and autoReplayOnRestart) do
                    if step > #macroData then
                        StatusText = "Waiting Next Round"
                        WaitingText = ""
                        ActionText = ""
                        UnitText = ""
                        updateStatus()
                        
                        local currentWave = 0
                        repeat
                            task.wait(0.1)
                            pcall(function() currentWave = RS.Wave.Value end)
                            
                            if currentWave < lastWave and not hasStartButton() then
                                lastWave = currentWave
                                step = 1
                                task.wait(0.5)
                                if seamlessMode then
                                    notify("Seamless Mode", "Restarting macro...", 2)
                                end
                                break
                            end
                            
                            lastWave = currentWave
                        until not playing and not (seamlessMode and autoReplayOnRestart)
                        
                        if not playing and not (seamlessMode and autoReplayOnRestart) then break end
                        continue
                    end
                    
                    local action = macroData[step]
                    
                    if not action then
                        print("[Macro] Error: No action at step " .. step)
                        step = step + 1
                        continue
                    end
                    
                    CurrentStep = step
                    TotalSteps = #macroData
                    
                    savePlaybackState(CurrentMacro, step)
                                        
                    local cash = 0
                    pcall(function() cash = LocalPlayer.Cash.Value end)
                    
                    local actionCost = action.Cost or 0
                    
                    if actionCost > 0 and cash < actionCost then
                        if not action.waitStartTime then
                            action.waitStartTime = tick()
                        end
                        
                        local waitTime = tick() - action.waitStartTime
                        
                        if waitTime > 60 then
                            print("[Macro] Warning: Waited 60s for cash at step " .. step .. ", skipping...")
                            action.waitStartTime = nil
                            step = step + 1
                            continue
                        end
                        
                        StatusText = "Waiting Cash"
                        WaitingText = "$" .. actionCost .. " (" .. math.floor(waitTime) .. "s)"
                        ActionText = action.ActionType or "Action"
                        UnitText = action.TowerName or "?"
                        updateStatus()
                        RunService.Heartbeat:Wait()
                        continue
                    end
                    
                    action.waitStartTime = nil
                    
                    print("[Macro] Executing step " .. step .. ": " .. (action.ActionType or "Unknown") .. " - " .. (action.TowerName or "Unknown") .. " (Cost: $" .. actionCost .. ", Cash: $" .. cash .. ")")
                    
                    StatusText = "Playing"
                    WaitingText = ""
                    ActionText = action.ActionType or "Action"
                    UnitText = action.TowerName or "?"
                    updateStatus()
                    
                    if action.TowerName and action.ActionType == "Upgrade" and isAutoUpgradeClone(action.TowerName) then
                        print("[Macro] Skipping auto-clone: " .. action.TowerName)
                        step = step + 1
                        continue
                    end
                    
                    local actionSuccess = false
                    local retryCount = 0
                    local maxRetries = 5
                    
                    while not actionSuccess and retryCount < maxRetries and playing do
                        local success = pcall(function()
                            if not action.RemoteName then
                                print("[Macro] Error: No RemoteName at step " .. step)
                                actionSuccess = true
                                return
                            end
                            
                            local remote = RemoteCache[action.RemoteName:lower()]
                            if not remote then 
                                print("[Macro] Warning: Remote not found: " .. action.RemoteName)
                                actionSuccess = true
                                return 
                            end
                            
                            if action.RemoteName:lower():find("upgrade") then
                                local foundTower = false
                                local towerToUpgrade = nil
                                
                                for _, t in pairs(workspace.Towers:GetChildren()) do
                                    if t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer and t.Name == action.TowerName then
                                        towerToUpgrade = t
                                        foundTower = true
                                        break
                                    end
                                end
                                
                                if not foundTower then
                                    print("[Macro] Warning: Tower not found for upgrade: " .. (action.TowerName or "Unknown"))
                                    actionSuccess = true
                                    return
                                end
                                
                                if towerToUpgrade then
                                    local beforeLevel = 0
                                    if towerToUpgrade:FindFirstChild("Upgrade") then
                                        beforeLevel = towerToUpgrade.Upgrade.Value
                                    end
                                    
                                    local maxLevel = 999
                                    if towerToUpgrade:FindFirstChild("MaxUpgrade") then
                                        maxLevel = towerToUpgrade.MaxUpgrade.Value
                                    end
                                    
                                    if beforeLevel >= maxLevel then
                                        print("[Macro] Info: " .. action.TowerName .. " already at max level (" .. beforeLevel .. "/" .. maxLevel .. ")")
                                        actionSuccess = true
                                        return
                                    end
                                    
                                    if remote:IsA("RemoteFunction") then
                                        remote:InvokeServer(towerToUpgrade)
                                    else
                                        remote:FireServer(towerToUpgrade)
                                    end
                                    
                                    local upgradeWaitTime = 0
                                    local maxUpgradeWait = 2
                                    local afterLevel = beforeLevel
                                    
                                    while upgradeWaitTime < maxUpgradeWait do
                                        task.wait(0.05)
                                        upgradeWaitTime = upgradeWaitTime + 0.05
                                        
                                        if towerToUpgrade:FindFirstChild("Upgrade") then
                                            afterLevel = towerToUpgrade.Upgrade.Value
                                        end
                                        
                                        if afterLevel > beforeLevel then
                                            break
                                        end
                                    end
                                    
                                    if afterLevel > beforeLevel then
                                        actionSuccess = true
                                        print("[Macro] ✓ Success: " .. action.TowerName .. " upgraded from Lv" .. beforeLevel .. " to Lv" .. afterLevel)
                                    else
                                        if retryCount >= maxRetries - 1 then
                                            print("[Macro] ✗ FAILED: Upgrade didn't complete after " .. maxRetries .. " retries - SKIPPING STEP")
                                            actionSuccess = true
                                        else
                                            print("[Macro] ⚠ Retry " .. (retryCount + 1) .. ": Upgrade level didn't increase for " .. action.TowerName .. " (Before: Lv" .. beforeLevel .. ", After: Lv" .. afterLevel .. ")")
                                        end
                                    end
                                end
                            else
                                local towerName = action.TowerName or "Unknown"
                                
                                local countBefore = 0
                                pcall(function()
                                    for _, t in pairs(workspace.Towers:GetChildren()) do
                                        if t.Name == towerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                                            countBefore = countBefore + 1
                                        end
                                    end
                                end)
                                
                                local args = {action.Args[1]}
                                if action.Args[2] and type(action.Args[2]) == "table" then
                                    args[2] = CFrame.new(unpack(action.Args[2]))
                                else
                                    args[2] = action.Args[2]
                                end
                                
                                print("[Macro] Placing: " .. towerName .. " (Current count: " .. countBefore .. ")")
                                
                                if remote:IsA("RemoteFunction") then
                                    remote:InvokeServer(unpack(args))
                                else
                                    remote:FireServer(unpack(args))
                                end
                                
                                local placementWaitTime = 0
                                local maxPlacementWait = 3
                                local countAfter = countBefore
                                
                                while placementWaitTime < maxPlacementWait do
                                    task.wait(0.1)
                                    placementWaitTime = placementWaitTime + 0.1
                                    
                                    countAfter = 0
                                    pcall(function()
                                        for _, t in pairs(workspace.Towers:GetChildren()) do
                                            if t.Name == towerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                                                countAfter = countAfter + 1
                                            end
                                        end
                                    end)
                                    
                                    if countAfter > countBefore then
                                        actionSuccess = true
                                        print("[Macro] Success: Placed " .. towerName .. " (New count: " .. countAfter .. ")")
                                        break
                                    end
                                end
                                
                                if not actionSuccess then
                                    if retryCount >= maxRetries - 1 then
                                        print("[Macro] Warning: Placement failed after " .. retryCount .. " retries, moving on...")
                                        actionSuccess = true
                                    else
                                        print("[Macro] Warning: Tower count didn't increase for " .. towerName .. " (Before: " .. countBefore .. ", After: " .. countAfter .. ", Retry: " .. retryCount .. ")")
                                    end
                                end
                            end
                        end)
                        
                        if not success or not actionSuccess then
                            retryCount = retryCount + 1
                            if retryCount < maxRetries then
                                print("[Macro] Retry " .. retryCount .. "/" .. maxRetries .. " for step " .. step)
                                task.wait(0.1)
                            else
                                print("[Macro] Max retries reached for step " .. step .. ", moving on...")
                                actionSuccess = true
                            end
                        end
                    end
                    
                    if actionSuccess then
                        step = step + 1
                        print("[Macro] ✓ Step " .. (step - 1) .. " completed, moving to step " .. step)
                    else
                        print("[Macro] ✗ CRITICAL: Step " .. step .. " failed verification - NOT MOVING TO NEXT STEP")
                        print("[Macro] This should never happen - check the retry logic!")
                        step = step + 1
                    end
                    
                    if StepDelay > 0 then
                        task.wait(StepDelay)
                    else
                        RunService.Heartbeat:Wait()
                    end
                end
                
                CurrentStep = 0
                StatusText = "Idle"
                ActionText = ""
                UnitText = ""
                WaitingText = ""
                clearPlaybackState()
                updateStatus()
                notify("Playback Finished", CurrentMacro, 3)
            end)
        else
            StatusText = "Idle"
            WaitingText = ""
            ActionText = ""
            UnitText = ""
            clearPlaybackState()
            updateStatus()
        end
    end
})

Tabs.Main:Space()
Tabs.Main:Divider()
Tabs.Main:Space()

Tabs.Main:Paragraph({
    Title = "⚙️ Playback Settings",
    Desc = "Configure playback behavior"
})

Tabs.Main:Space()

Tabs.Main:Input({
    Flag = "StepDelay",
    Title = "Step Delay (seconds)",
    Value = tostring(StepDelay),
    Placeholder = "0",
    Callback = function(v)
        StepDelay = tonumber(v) or 0
        saveSettings()
    end
})

Tabs.Main:Space()
Tabs.Main:Divider()
Tabs.Main:Space()

Tabs.Main:Paragraph({
    Title = "📊 Live Status",
    Desc = "Real-time information about macro recording and playback."
})

StatusLabel = Tabs.Main:Paragraph({ Title = "📊 Status: Idle", Desc = "" })
StepLabel = Tabs.Main:Paragraph({ Title = "📝 Step: 0/0", Desc = "" })
ActionLabel = Tabs.Main:Paragraph({ Title = "⚡ Action: ", Desc = "" })
UnitLabel = Tabs.Main:Paragraph({ Title = "🗼 Unit: ", Desc = "" })
WaitingLabel = Tabs.Main:Paragraph({ Title = "⏳ Waiting: ", Desc = "" })

Tabs.Maps:Paragraph({
    Title = "🗺️ Dynamic Map Assignment",
    Desc = "Assign macros to specific maps - automatically updates based on gamemode!"
})

Tabs.Maps:Space()

local selectedGamemode = "Story"
local currentMapSection = nil

local function updateMapDisplay()
    if currentMapSection then
        pcall(function()
            currentMapSection:Destroy()
        end)
        currentMapSection = nil
    end
    
    task.wait(0.05)
    
    local maps = getMapsByGamemode(selectedGamemode)
    
    if #maps == 0 then
        currentMapSection = Tabs.Maps:Section({
            Title = "⚠️ No Maps Available",
            Opened = true,
        })
        currentMapSection:Paragraph({
            Title = "No Maps Found",
            Desc = "No maps available for " .. selectedGamemode
        })
        return
    end
    
    currentMapSection = Tabs.Maps:Section({
        Title = "📍 " .. selectedGamemode .. " Maps",
        Opened = true,
    })
    
    for _, mapName in ipairs(maps) do
        local key = selectedGamemode .. "_" .. mapName
        local currentMacro = getgenv().MacroMaps[key] or "--"
        
        local macroNames = getMacroNames()
        table.insert(macroNames, 1, "--")
        
        currentMapSection:Dropdown({
            Flag = "MacroFor_" .. key,
            Title = mapName,
            Values = macroNames,
            Value = currentMacro,
            Callback = function(value)
                if value ~= "--" then
                    getgenv().MacroMaps[key] = value
                    notify("Map Assignment", mapName .. " → " .. value, 3)
                else
                    getgenv().MacroMaps[key] = nil
                    notify("Map Assignment", mapName .. " cleared", 3)
                end
                saveSettings()
            end,
            Searchable = true,
        })
    end
end

Tabs.Maps:Dropdown({
    Flag = "MacroGamemodeSelect",
    Title = "Select Gamemode",
    Values = {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "Event", "MidnightHunt", "Portal", "BossRush", "Siege", "Breach"},
    Value = "Story",
    Callback = function(value)
        selectedGamemode = value
        task.spawn(function()
            updateMapDisplay()
        end)
    end,
})

Tabs.Maps:Space()
Tabs.Maps:Divider()
Tabs.Maps:Space()

task.spawn(function()
    task.wait(0.1)
    updateMapDisplay()
end)

task.spawn(function()
    task.wait(2)
    pcall(function()
        local gamemode = RS:FindFirstChild("Gamemode")
        local mapName = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MapName")
        if gamemode and mapName then
            local gm = gamemode.Value
            local mn = mapName.Value
            local key = gm .. "_" .. mn
            if getgenv().MacroMaps[key] and getgenv().MacroMaps[key] ~= "--" and Macros[getgenv().MacroMaps[key]] then
                CurrentMacro = getgenv().MacroMaps[key]
                macroData = Macros[CurrentMacro] or {}
                TotalSteps = #macroData
                
                task.wait(0.3)
                if macroDropdown then
                    pcall(function()
                        macroDropdown:Select(CurrentMacro)
                    end)
                end
                
                notify("Auto-Selected", CurrentMacro .. " for " .. mn, 5)
            end
        end
    end)
end)

Tabs.Settings:Paragraph({
    Title = "⚙️ Settings",
    Desc = "Manage your macros and UI settings."
})

Tabs.Settings:Space()

Tabs.Settings:Button({
    Title = "🔄 Refresh Macro List",
    Callback = function()
        loadMacros()
        local newMacroNames = getMacroNames()
        if macroDropdown then
            pcall(function()
                macroDropdown:Refresh(newMacroNames)
            end)
        end
        notify("Refreshed", "Macro list updated", 3)
    end
})

Tabs.Settings:Button({
    Title = "🔁 Clear Resume State",
    Callback = function()
        clearPlaybackState()
        resumeFromStep = 0
        notify("Cleared", "Resume state cleared - will start from beginning", 3)
    end
})

Tabs.Settings:Space()
Tabs.Settings:Divider()
Tabs.Settings:Space()

Tabs.Settings:Paragraph({
    Title = "🔄 Seamless Mode",
    Desc = "Automatically restart macro when round ends"
})

Tabs.Settings:Space()

Tabs.Settings:Toggle({
    Flag = "SeamlessMode",
    Title = "Enable Seamless Mode",
    Default = seamlessMode,
    Callback = function(v)
        seamlessMode = v
        saveSettings()
        if v then
            notify("Seamless Mode", "Enabled - Macro will auto-restart", 3)
        else
            notify("Seamless Mode", "Disabled", 3)
        end
    end
})

Tabs.Settings:Toggle({
    Flag = "AutoReplayOnRestart",
    Title = "Auto Replay on Restart",
    Default = autoReplayOnRestart,
    Callback = function(v)
        autoReplayOnRestart = v
        saveSettings()
    end
})

Tabs.Settings:Space()
Tabs.Settings:Divider()
Tabs.Settings:Space()

Tabs.Settings:Button({
    Title = "🗑️ Unload UI",
    Callback = function()
        clearPlaybackState()
        pcall(function()
            if Window and Window.Destroy then
                Window:Destroy()
            end
        end)
        notify("Unloaded", "Macro System UI closed", 3)
    end
})

local towerMonitor = {}
local lastRecordedUpgrade = {}

local monitorConnection
monitorConnection = RunService.Heartbeat:Connect(function()
    if not recording then return end
    
    pcall(function()
        for _, tower in pairs(workspace.Towers:GetChildren()) do
            if tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
                local towerName = tower.Name
                local upgradeLevel = 0
                
                if tower:FindFirstChild("Upgrade") then
                    upgradeLevel = tower.Upgrade.Value
                end
                
                if not towerMonitor[towerName] then
                    towerMonitor[towerName] = {
                        lastLevel = upgradeLevel,
                        lastRecordTime = 0,
                        lastCost = 0
                    }
                end
                
                if upgradeLevel > towerMonitor[towerName].lastLevel then
                    local now = tick()
                    
                    if isAutoUpgradeClone(towerName) then
                        towerMonitor[towerName].lastLevel = upgradeLevel
                        return
                    end
                    
                    if (now - towerMonitor[towerName].lastRecordTime) > 0.12 then
                        task.spawn(function()
                            task.wait(0.08)
                            
                            local cost = getRecentCashDecrease(2.5)
                            local levelBefore = towerMonitor[towerName].lastLevel
                            
                            local upgradeKey = towerName .. "_" .. levelBefore .. "_" .. upgradeLevel
                            if lastRecordedUpgrade[upgradeKey] and (now - lastRecordedUpgrade[upgradeKey]) < 0.8 then
                                towerMonitor[towerName].lastLevel = upgradeLevel
                                return
                            end
                            
                            if cost == 0 and towerMonitor[towerName].lastCost > 0 then
                                cost = towerMonitor[towerName].lastCost
                            end
                            
                            if cost == towerMonitor[towerName].lastCost and cost > 0 and (now - towerMonitor[towerName].lastRecordTime) < 0.4 then
                                towerMonitor[towerName].lastLevel = upgradeLevel
                                return
                            end
                            
                            table.insert(macroData, {
                                RemoteName = "Upgrade",
                                Args = {nil},
                                Time = now,
                                IsInvoke = true,
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Upgrade"
                            })
                            
                            towerMonitor[towerName].lastLevel = upgradeLevel
                            towerMonitor[towerName].lastRecordTime = now
                            if cost > 0 then
                                towerMonitor[towerName].lastCost = cost
                            end
                            lastRecordedUpgrade[upgradeKey] = now
                            
                            StatusText = "Recording"
                            CurrentStep = #macroData
                            TotalSteps = #macroData
                            ActionText = "Upgrade"
                            UnitText = towerName
                            WaitingText = ""
                            updateStatus()
                            
                            print("[Macro] ✓ Recorded Upgrade:", towerName, "Lv" .. levelBefore, "→", "Lv" .. upgradeLevel, "($" .. cost .. ")", "[Total:", #macroData .. "]")
                        end)
                    end
                end
            end
        end
    end)
    
    if not recording then
        towerMonitor = {}
        lastRecordedUpgrade = {}
    end
end)

local placementMonitor = {}

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method, args = getnamecallmethod(), {...}
    local remoteName = tostring(self.Name or "")
    
    local result = old(self, ...)
    
    if recording and (method == "FireServer" or method == "InvokeServer") then
        if remoteName:lower():find("place") or remoteName:lower():find("tower") then
            if args[1] then
                task.spawn(function()
                    local success, err = pcall(function()
                        local towerName = tostring(args[1])
                        local now = tick()
                        local actionKey = towerName .. "_" .. now
                        
                        if placementMonitor[actionKey] then return end
                        placementMonitor[actionKey] = true
                        
                        if not getgenv().TowerPlaceCounts then getgenv().TowerPlaceCounts = {} end
                        local countBefore = getgenv().TowerPlaceCounts[towerName] or 0
                        
                        local placementLimit = 999
                        pcall(function()
                            local existingTower = workspace.Towers:FindFirstChild(towerName)
                            if existingTower and existingTower:FindFirstChild("PlacementLimit") then
                                placementLimit = existingTower.PlacementLimit.Value
                            end
                        end)
                        
                        if countBefore >= placementLimit then
                            placementMonitor[actionKey] = nil
                            return
                        end
                        
                        StatusText = "Recording"
                        ActionText = "Placing..."
                        UnitText = towerName
                        WaitingText = ""
                        updateStatus()
                        
                        task.wait(0.65)
                        
                        local countAfter = 0
                        pcall(function()
                            for _, t in pairs(workspace.Towers:GetChildren()) do
                                if t.Name == towerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                                    countAfter = countAfter + 1
                                end
                            end
                        end)
                        
                        if countAfter > countBefore and countAfter <= placementLimit then
                            task.wait(0.12)
                            
                            local cost = getRecentCashDecrease(2.5)
                            if cost == 0 then
                                cost = getPlaceCost(towerName)
                            end
                            
                            local savedArgs = {}
                            savedArgs[1] = args[1]
                            if args[2] and typeof(args[2]) == "CFrame" then
                                savedArgs[2] = {args[2]:GetComponents()}
                            end
                            
                            getgenv().TowerPlaceCounts[towerName] = countAfter
                            
                            if not towerMonitor[towerName] then
                                towerMonitor[towerName] = {
                                    lastLevel = 0,
                                    lastRecordTime = 0,
                                    lastCost = 0
                                }
                            end
                            
                            table.insert(macroData, {
                                RemoteName = remoteName,
                                Args = savedArgs,
                                Time = now,
                                IsInvoke = (method == "InvokeServer"),
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Place"
                            })
                            
                            StatusText = "Recording"
                            CurrentStep = #macroData
                            TotalSteps = #macroData
                            ActionText = "Place"
                            UnitText = towerName
                            WaitingText = ""
                            updateStatus()
                            
                            print("[Macro] ✓ Recorded Place:", towerName, "($" .. cost .. ")", countBefore, "→", countAfter, "/", placementLimit, "[Total:", #macroData .. "]")
                        else
                            StatusText = "Recording"
                            ActionText = ""
                            UnitText = ""
                            WaitingText = ""
                            updateStatus()
                        end
                        
                        placementMonitor[actionKey] = nil
                    end)
                    
                    if not success then
                        warn("[Macro] Recording error:", err)
                    end
                end)
            end
        end
    end
    
    return result
end

setreadonly(mt, true)

task.spawn(function()
    while true do
        task.wait(3)
        local now = tick()
        for key, _ in pairs(placementMonitor) do
            if placementMonitor[key] and (now - placementMonitor[key]) > 5 then
                placementMonitor[key] = nil
            end
        end
        for key, time in pairs(lastRecordedUpgrade) do
            if (now - time) > 5 then
                lastRecordedUpgrade[key] = nil
            end
        end
    end
end)

notify("🎬 Macro System ", "Macro Script!", 5)
print("[Macro System] Loaded successfully!")
