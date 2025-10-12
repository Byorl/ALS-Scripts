repeat task.wait() until game:IsLoaded()

-- Simple Macro System (No Freezing)
local repo = "https://raw.githubusercontent.com/byorl/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

print("[ALS] Waiting for TeleportUI to disappear...")
repeat task.wait(0.1) until not LocalPlayer.PlayerGui:FindFirstChild("TeleportUI")
print("[ALS] TeleportUI gone, loading script...")

local MACRO_FOLDER = "ALSMacros"
if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

local Macros, CurrentMacro, recording, playing, macroData, StepDelay = {}, nil, false, false, {}, 0
local StatusText, ActionText, UnitText, WaitingText, CurrentStep, TotalSteps = "Idle", "", "", "", 0, 0
local TowerInfoCache = {}
local TowerUpgradeLevels = {}

local function cacheTowerInfo()
    if next(TowerInfoCache) then return end
    local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
    for _, mod in pairs(towerInfoPath:GetChildren()) do
        if mod:IsA("ModuleScript") then
            local ok, data = pcall(function() return require(mod) end)
            if ok then TowerInfoCache[mod.Name] = data end
        end
    end
    print("[Macro] Cached tower info for", #TowerInfoCache, "towers")
end

local function getPlaceCost(towerName)
    cacheTowerInfo()
    if not TowerInfoCache[towerName] then return 0 end
    if TowerInfoCache[towerName][0] then
        return TowerInfoCache[towerName][0].Cost or 0
    end
    return 0
end

local function getUpgradeCost(towerName, upgradeLevel)
    cacheTowerInfo()
    if not TowerInfoCache[towerName] then return 0 end
    
    if TowerInfoCache[towerName][upgradeLevel] then
        return TowerInfoCache[towerName][upgradeLevel].Cost or 0
    end
    return 0
end

local function loadMacros()
    Macros = {}
    if not isfolder(MACRO_FOLDER) then return end
    for _, file in pairs(listfiles(MACRO_FOLDER)) do
        if file:sub(-5) == ".json" then
            local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
            if ok then Macros[file:match("([^/\\]+)%.json$")] = data end
        end
    end
end

local function saveMacro(name, data)
    writefile(MACRO_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    Macros[name] = data
end

local function getMacroNames()
    local names = {}
    for name in pairs(Macros) do table.insert(names, name) end
    table.sort(names)
    return names
end

local Window = Library:CreateWindow({ Title = "Macro System", Size = UDim2.fromOffset(700, 500) })
local Tab = Window:AddTab("Macro", "play")
local ConfigBox, MacroMapsBox, StatusBox, ControlBox = Tab:AddLeftGroupbox("Config"), Tab:AddRightGroupbox("Macro Maps"), Tab:AddLeftGroupbox("Status"), Tab:AddLeftGroupbox("Controls")

loadMacros()

-- Macro Maps System
getgenv().MacroMaps = getgenv().MacroMaps or {}
local MapData = nil
pcall(function()
    local mapDataModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
    if mapDataModule and mapDataModule:IsA("ModuleScript") then
        MapData = require(mapDataModule)
    end
end)

local function getMapsByGamemode(gamemode)
    if not MapData then return {} end
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

local currentGamemode = "Story"
local currentMap = ""

MacroMapsBox:AddLabel("Assign macros to specific maps", true)

local selectedGamemode = "Story"
local selectedMap = ""

MacroMapsBox:AddDropdown("MacroGamemodeSelect", {
    Values = {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns"},
    Default = "Story",
    Text = "Gamemode",
    Callback = function(value)
        selectedGamemode = value
        local maps = getMapsByGamemode(value)
        if Library.Options.MacroMapDropdown then
            Library.Options.MacroMapDropdown:SetValues(maps)
            if #maps > 0 then
                Library.Options.MacroMapDropdown:SetValue(maps[1])
                selectedMap = maps[1]
                
                -- Update macro dropdown with saved value
                local key = selectedGamemode .. "_" .. selectedMap
                if Library.Options.MacroForSelectedMap and getgenv().MacroMaps[key] then
                    Library.Options.MacroForSelectedMap:SetValue(getgenv().MacroMaps[key])
                end
            end
        end
    end,
})

MacroMapsBox:AddDropdown("MacroMapDropdown", {
    Values = getMapsByGamemode("Story"),
    Text = "Map",
    Callback = function(value)
        selectedMap = value
        -- Load saved macro for this map
        local key = selectedGamemode .. "_" .. selectedMap
        if Library.Options.MacroForSelectedMap and getgenv().MacroMaps[key] then
            Library.Options.MacroForSelectedMap:SetValue(getgenv().MacroMaps[key])
        end
    end,
    Searchable = true,
})

MacroMapsBox:AddDropdown("MacroForSelectedMap", {
    Values = getMacroNames(),
    Text = "Macro",
    Callback = function(value)
        local key = selectedGamemode .. "_" .. selectedMap
        getgenv().MacroMaps[key] = value
        print("[Macro Maps] Set", key, "to use macro:", value)
    end,
    Searchable = true,
})

-- Auto-select macro based on current gamemode and map
task.spawn(function()
    task.wait(2)
    pcall(function()
        local gamemode = RS:FindFirstChild("Gamemode")
        local mapName = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MapName")
        if gamemode and mapName then
            local gm = gamemode.Value
            local mn = mapName.Value
            local key = gm .. "_" .. mn
            if getgenv().MacroMaps[key] then
                CurrentMacro = getgenv().MacroMaps[key]
                macroData = Macros[CurrentMacro] or {}
                if Library.Options.MacroSelect then
                    Library.Options.MacroSelect:SetValue(CurrentMacro)
                end
                print("[Macro Maps] Auto-selected macro:", CurrentMacro, "for", gm, mn)
            end
        end
    end)
end)

ConfigBox:AddInput("MacroName", {
    Text = "Create Macro",
    Finished = true,
    Callback = function(v)
        if v and v ~= "" and not Macros[v] then
            Macros[v], CurrentMacro, macroData = {}, v, {}
            saveMacro(v, {})
            Library.Options.MacroSelect:SetValues(getMacroNames())
            Library.Options.MacroSelect:SetValue(v)
            if Library.Options.MacroForMap then
                Library.Options.MacroForMap:SetValues(getMacroNames())
            end
            Library:Notify({ Title = "Macro", Description = "Created: " .. v, Time = 3 })
        end
    end
})

ConfigBox:AddDropdown("MacroSelect", {
    Values = getMacroNames(),
    Text = "Selected Macro",
    Callback = function(v)
        CurrentMacro = v
        if v and Macros[v] then macroData = Macros[v] end
    end
})

local StatusLabel = StatusBox:AddLabel("Status: Idle")
local StepLabel = StatusBox:AddLabel("Step: 0/0")
local ActionLabel = StatusBox:AddLabel("Action: ")
local UnitLabel = StatusBox:AddLabel("Unit: ")
local WaitingLabel = StatusBox:AddLabel("Waiting for: ")

local function updateStatus()
    pcall(function()
        StatusLabel:SetText("Status: " .. StatusText)
        StepLabel:SetText("Step: " .. CurrentStep .. "/" .. TotalSteps)
        ActionLabel:SetText("Action: " .. ActionText)
        UnitLabel:SetText("Unit: " .. UnitText)
        WaitingLabel:SetText("Waiting for: " .. WaitingText)
    end)
end

ControlBox:AddToggle("RecordMacro", {
    Text = "Record Macro",
    Callback = function(v)
        recording = v
        if v then
            if not CurrentMacro then Library.Toggles.RecordMacro:SetValue(false) return end
            macroData, StatusText, TowerUpgradeLevels = {}, "Recording", {}
            _G.TowerPlaceCounts = {}  -- Reset tower counts when starting recording
            updateStatus()
        else
            StatusText = "Idle"
            updateStatus()
            if CurrentMacro and #macroData > 0 then 
                saveMacro(CurrentMacro, macroData)
                Library:Notify({ Title = "Macro", Description = #macroData .. " steps saved", Time = 3 })
            end
        end
    end
})

ControlBox:AddInput("StepDelayInput", {
    Text = "Step Delay",
    Default = "0",
    Numeric = true,
    Finished = true,
    Callback = function(v) StepDelay = tonumber(v) or 0 end
})

-- Cache remotes and tower info on script load
local RemoteCache = {}
task.spawn(function()
    task.wait(2)
    cacheTowerInfo()
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            RemoteCache[v.Name:lower()] = v
        end
    end
    print("[Macro] Pre-cached", #RemoteCache, "remotes")
end)

local function executeAction(action)
    local remote = RemoteCache[action.RemoteName:lower()]
    if not remote then return end
    
    if action.RemoteName:lower():find("upgrade") then
        for _, t in pairs(workspace.Towers:GetChildren()) do
            if t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer and t.Name == action.TowerName then
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(t)
                else
                    remote:FireServer(t)
                end
                return
            end
        end
    else
        local args = {action.Args[1]}
        if action.Args[2] and type(action.Args[2]) == "table" then
            args[2] = CFrame.new(unpack(action.Args[2]))
        else
            args[2] = action.Args[2]
        end
        
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack(args))
        else
            remote:FireServer(unpack(args))
        end
    end
end

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

ControlBox:AddToggle("PlayMacro", {
    Text = "Play Macro",
    Callback = function(v)
        playing = v
        if v then
            if not CurrentMacro or #macroData == 0 then
                Library.Toggles.PlayMacro:SetValue(false)
                return
            end
            
            task.spawn(function()
                local step = 1
                local lastWave = 0
                
                -- Wait for initial start
                StatusText, WaitingText = "Waiting Start", ""
                updateStatus()
                repeat task.wait(0.1) until not hasStartButton() or not playing
                if not playing then return end
                
                pcall(function() lastWave = RS.Wave.Value end)
                task.wait(0.5)
                
                -- Main loop
                while playing do
                    -- Check if we need to wait for next round
                    if step > #macroData then
                        StatusText, WaitingText = "Waiting Next Round", ""
                        updateStatus()
                        
                        local currentWave = 0
                        repeat
                            task.wait(0.1)
                            pcall(function() currentWave = RS.Wave.Value end)
                            
                            -- New round detected: wave decreased and no start button
                            if currentWave < lastWave and not hasStartButton() then
                                lastWave = currentWave
                                step = 1
                                task.wait(0.5)
                                break
                            end
                            
                            lastWave = currentWave
                        until not playing
                        
                        if not playing then break end
                        continue
                    end
                    
                    local action = macroData[step]
                    CurrentStep, TotalSteps = step, #macroData
                    
                    -- Check cash
                    local cash = 0
                    pcall(function() cash = LocalPlayer.Cash.Value end)
                    
                    if action.Cost > 0 and cash < action.Cost then
                        StatusText = "Waiting Cash"
                        WaitingText = "$" .. action.Cost
                        ActionText = action.ActionType == "Place" and "Placing" or (action.ActionType == "Upgrade" and "Upgrading" or action.ActionType)
                        UnitText = action.TowerName or "?"
                        updateStatus()
                        task.wait(0.1)
                        continue
                    end
                    
                    -- Execute action
                    StatusText = "Playing"
                    WaitingText = ""
                    ActionText = action.ActionType == "Place" and "Placing" or (action.ActionType == "Upgrade" and "Upgrading" or action.ActionType)
                    UnitText = action.TowerName or "?"
                    updateStatus()
                    
                    pcall(function() executeAction(action) end)
                    
                    step = step + 1
                    
                    -- Apply step delay if set
                    if StepDelay > 0 then
                        task.wait(StepDelay)
                    else
                        task.wait(0.05)
                    end
                end
                
                CurrentStep, StatusText, ActionText, UnitText, WaitingText = 0, "Idle", "", "", ""
                updateStatus()
            end)
        else
            StatusText, WaitingText = "Idle", ""
            updateStatus()
        end
    end
})

-- Recording hook (Polished & Optimized)
do
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    local lastRecord = { time = 0, name = "", argHash = "" }
    local recordingLock = false
    
    mt.__namecall = function(self, ...)
        local method, args = getnamecallmethod(), {...}
        
        -- Capture tower reference for upgrades BEFORE remote executes
        local towerRef = nil
        if recording and not recordingLock and (method == "FireServer" or method == "InvokeServer") then
            local n = tostring(self.Name or "")
            if n:lower():find("upgrade") and args[1] and typeof(args[1]) == "Instance" then
                towerRef = args[1]
            end
        end
        
        local result = old(self, ...)
        
        if recording and not recordingLock and (method == "FireServer" or method == "InvokeServer") then
            local n = tostring(self.Name or "")
            if n:lower():find("place") or n:lower():find("tower") or n:lower():find("upgrade") then
                task.spawn(function()
                    -- Prevent overlapping recordings
                    if recordingLock then return end
                    recordingLock = true
                    
                    local success = pcall(function()
                        local now = tick()
                        local hash = ""
                        for i, v in ipairs(args) do
                            hash = hash .. tostring(v)
                        end
                        hash = hash:sub(1, 50)
                        
                        -- Debounce duplicate calls
                        if n == lastRecord.name and hash == lastRecord.argHash and (now - lastRecord.time) < 0.3 then
                            return
                        end
                        
                        lastRecord = { time = now, name = n, argHash = hash }
                        
                        local towerName, cost, actionType = "", 0, "Action"
                        local savedArgs = {}
                        
                        if n:lower():find("place") and args[1] then
                            towerName, actionType = tostring(args[1]), "Place"
                            cost = getPlaceCost(towerName)
                            
                            -- Initialize tracking
                            if not _G.TowerPlaceCounts then _G.TowerPlaceCounts = {} end
                            local countBefore = _G.TowerPlaceCounts[towerName] or 0
                            
                            -- Wait for tower to appear
                            task.wait(0.6)
                            
                            -- Count towers after placement
                            local countAfter = 0
                            pcall(function()
                                for _, t in pairs(workspace.Towers:GetChildren()) do
                                    if t.Name == towerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                                        countAfter = countAfter + 1
                                    end
                                end
                            end)
                            
                            -- Validate placement
                            if countAfter > countBefore then
                                savedArgs[1] = args[1]
                                if args[2] and typeof(args[2]) == "CFrame" then
                                    savedArgs[2] = {args[2]:GetComponents()}
                                end
                                
                                TowerUpgradeLevels[towerName] = 0
                                _G.TowerPlaceCounts[towerName] = countAfter
                                
                                table.insert(macroData, {
                                    RemoteName = n,
                                    Args = savedArgs,
                                    Time = now,
                                    IsInvoke = (method == "InvokeServer"),
                                    Cost = cost,
                                    TowerName = towerName,
                                    ActionType = actionType
                                })
                                
                                StatusText = "Recording"
                                CurrentStep = #macroData
                                TotalSteps = #macroData
                                ActionText = actionType
                                UnitText = towerName
                                WaitingText = ""
                                updateStatus()
                                
                                print("[Macro] ✓ Recorded Place:", towerName, "($" .. cost .. ")", countBefore, "→", countAfter)
                            else
                                print("[Macro] ✗ Skipped Place:", towerName, "(no new tower)")
                            end
                            
                        elseif n:lower():find("upgrade") and towerRef then
                            towerName = towerRef.Name
                            actionType = "Upgrade"
                            
                            local upgradeBefore = TowerUpgradeLevels[towerName] or 0
                            
                            -- Wait for upgrade to apply
                            task.wait(0.25)
                            
                            local upgradeAfter = 0
                            pcall(function()
                                if towerRef:FindFirstChild("Upgrade") then
                                    upgradeAfter = towerRef.Upgrade.Value
                                end
                            end)
                            
                            -- Validate upgrade
                            if upgradeAfter > upgradeBefore then
                                cost = getUpgradeCost(towerName, upgradeAfter)
                                savedArgs[1] = nil
                                TowerUpgradeLevels[towerName] = upgradeAfter
                                
                                table.insert(macroData, {
                                    RemoteName = n,
                                    Args = savedArgs,
                                    Time = now,
                                    IsInvoke = (method == "InvokeServer"),
                                    Cost = cost,
                                    TowerName = towerName,
                                    ActionType = actionType
                                })
                                
                                StatusText = "Recording"
                                CurrentStep = #macroData
                                TotalSteps = #macroData
                                ActionText = actionType
                                UnitText = towerName
                                WaitingText = ""
                                updateStatus()
                                
                                print("[Macro] ✓ Recorded Upgrade:", towerName, "Lv" .. upgradeBefore, "→", "Lv" .. upgradeAfter, "($" .. cost .. ")")
                            else
                                print("[Macro] ✗ Skipped Upgrade:", towerName, "(level didn't increase)")
                            end
                        end
                    end)
                    
                    if not success then
                        warn("[Macro] Recording error occurred")
                    end
                    
                    recordingLock = false
                end)
            end
        end
        
        return result
    end
    
    setreadonly(mt, true)
end

print("[Macro System v3] Loaded!")
