repeat task.wait() until game:IsLoaded()

-- ========================================
-- CONFIGURATION - Edit settings below
-- ========================================

if game.Players.LocalPlayer.UserId == 9213180540 then
    getgenv().Enabled = true
end

local TOWER_PLACEMENTS = {
    {name = "AiHoshinoEvo", cframe = CFrame.new(251.74304199219, 1.5027506351471, 125.06447601318, 1, 0, 0, 0, 1, 0, 0, 0, 1), priority = 1},
    {name = "Bulma", cframe = CFrame.new(232.15802001953, 1.5027525424957, 130.35104370117, 1, 0, 0, 0, 1, 0, 0, 0, 1), priority = 1},
    
    {name = "AsuraEvo", cframe = CFrame.new(236.97274780273, 1.5027487277985, 127.59850311279, 1, 0, 0, 0, 1, 0, 0, 0, 1), priority = 2},
    {name = "NarutoBaryon", cframe = CFrame.new(248.91377258301, 1.5027506351471, 126.83883666992, 1, 0, 0, 0, 1, 0, 0, 0, 1), priority = 2},
    {name = "LelouchEvo", cframe = CFrame.new(253.49638366699, 1.5027506351471, 129.29312133789, 1, 0, 0, 0, 1, 0, 0, 0, 1), priority = 2},
    
    {name = "LightEvo", cframe = CFrame.new(246.49560546875, 1.5027525424957, 132.48863220215, 1, 0, 0, 0, 1, 0, 0, 0, 1), priority = 3},
}

local TOWER_UPGRADES = {
    {name = "AiHoshinoEvo", upgradePhase = 1},
    {name = "Bulma", upgradePhase = 1},
    
    {name = "NarutoBaryon", upgradePhase = 2},
    {name = "AsuraEvo", upgradePhase = 2},
    
    {name = "LelouchEvo", upgradePhase = 3},
    
    {name = "LightEvo", upgradePhase = 4},
}

local PHASE_3_REQUIREMENTS = {"NarutoBaryon", "AsuraEvo"}

-- ========================================
-- SCRIPT CODE - Do not edit below unless you know what you're doing
-- ========================================

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Towers = workspace.Towers

local towerInfoCache = {}
local maxedTowers = {}
local placementCostCache = {}
local maxLevelCache = {}

local function getTowerInfo(towerName)
    if towerInfoCache[towerName] then
        return towerInfoCache[towerName]
    end
    
    local success, towerData = pcall(function()
        local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
        local towerModule = towerInfoPath:FindFirstChild(towerName)
        if towerModule and towerModule:IsA("ModuleScript") then
            return require(towerModule)
        end
        return nil
    end)
    
    if success and towerData then
        towerInfoCache[towerName] = towerData
        return towerData
    end
    return nil
end

local function getPlacementCost(towerName)
    if placementCostCache[towerName] then
        return placementCostCache[towerName]
    end
    
    local towerInfo = getTowerInfo(towerName)
    if not towerInfo or not towerInfo[0] then 
        placementCostCache[towerName] = 999999999
        return 999999999 
    end
    
    local cost = towerInfo[0].Cost or 999999999
    placementCostCache[towerName] = cost
    return cost
end

local function getMaxLevel(towerName)
    if maxLevelCache[towerName] then
        return maxLevelCache[towerName]
    end
    
    local towerInfo = getTowerInfo(towerName)
    if not towerInfo then 
        maxLevelCache[towerName] = 0
        return 0 
    end
    
    local maxLevel = 0
    for level = 1, 50 do
        if towerInfo[level] then
            maxLevel = level
        else
            break
        end
    end
    
    maxLevelCache[towerName] = maxLevel
    return maxLevel
end

local function precacheTowerInfo()
    print("[ALS Farm] Pre-caching tower info...")
    for _, config in ipairs(TOWER_PLACEMENTS) do
        getTowerInfo(config.name)
        placementCostCache[config.name] = getPlacementCost(config.name)
    end
    for _, config in ipairs(TOWER_UPGRADES) do
        getTowerInfo(config.name)
        maxLevelCache[config.name] = getMaxLevel(config.name)
    end
    print("[ALS Farm] Tower info cached!")
end

local function getCash()
    local success, cash = pcall(function()
        return Players.LocalPlayer.Cash.Value
    end)
    return success and cash or 0
end

local function getTower(name)
    return Towers:FindFirstChild(name)
end

local function getUpgradeLevel(tower)
    if not tower then return 0 end
    local upgradeVal = tower:FindFirstChild("Upgrade")
    if upgradeVal and upgradeVal:IsA("ValueBase") then
        return upgradeVal.Value or 0
    end
    return 0
end

local function placeTower(name, cframe)
    if not getTower(name) then
        local cost = placementCostCache[name] or getPlacementCost(name)
        local currentCash = getCash()
        
        if currentCash >= cost then
            pcall(function()
                local Event = RS.Remotes.PlaceTower
                Event:FireServer(name, cframe)
            end)
        end
    end
end

local autoUpgradeSet = {}
local towerPlacementTime = {}

local function setAutoUpgrade(tower, enabled)
    if not tower then return end
    
    local towerName = tower.Name
    
    -- Check if tower exists in Towers folder
    local towerInWorkspace = getTower(towerName)
    if not towerInWorkspace then
        return
    end
    
    -- Track when tower was first seen
    if not towerPlacementTime[towerName] then
        towerPlacementTime[towerName] = tick()
        print("[ALS Farm] First seen: " .. towerName)
        return
    end
    
    -- Wait at least 1 second after placement
    local timeSincePlacement = tick() - towerPlacementTime[towerName]
    if timeSincePlacement < 1 then
        return
    end
    
    -- Only set once per tower
    if autoUpgradeSet[towerName] then
        return
    end
    
    local currentLevel = getUpgradeLevel(towerInWorkspace)
    local maxLevel = maxLevelCache[towerName] or getMaxLevel(towerName)
    
    if maxLevel > 0 and currentLevel >= maxLevel then
        if not maxedTowers[towerName] then
            maxedTowers[towerName] = true
            print("[ALS Farm] " .. towerName .. " reached max level " .. maxLevel)
        end
        return
    end
    
    pcall(function()
        local Event = RS.Remotes.UnitManager.SetAutoUpgrade
        Event:FireServer(towerInWorkspace, enabled)
        autoUpgradeSet[towerName] = true
        print("[ALS Farm] Set auto-upgrade for " .. towerName .. " after " .. string.format("%.1f", timeSincePlacement) .. "s")
    end)
end

-- Removed checkAndRetry() - handled by main script

precacheTowerInfo()

-- Reusable table to prevent memory allocation
local towerLevelsCache = {}

local function buildTowerLevels()
    -- Clear existing data
    for k in pairs(towerLevelsCache) do
        towerLevelsCache[k] = nil
    end
    
    for _, config in ipairs(TOWER_UPGRADES) do
        local tower = getTower(config.name)
        if tower then
            towerLevelsCache[config.name] = {
                level = getUpgradeLevel(tower),
                maxLevel = maxLevelCache[config.name]
            }
        end
    end
    return towerLevelsCache
end

-- Reset auto-upgrade tracking on new round
Players.LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
    if child.Name == "EndGameUI" then
        -- Clear tables properly
        for k in pairs(autoUpgradeSet) do autoUpgradeSet[k] = nil end
        for k in pairs(towerPlacementTime) do towerPlacementTime[k] = nil end
        for k in pairs(maxedTowers) do maxedTowers[k] = nil end
        
        print("[ALS Farm] New round - reset tracking")
    end
end)

print("[ALS Farm] Starting main loop...")
print("[ALS Farm] Enabled:", getgenv().Enabled)

local loopCount = 0

while getgenv().Enabled do
    wait(0.1)
    loopCount = loopCount + 1
    
    local towerLevels = buildTowerLevels()
    
    for _, placement in ipairs(TOWER_PLACEMENTS) do
        if placement.priority == 1 then
            placeTower(placement.name, placement.cframe)
        end
    end
    
    local priority1Exist = getTower("AiHoshinoEvo") and getTower("Bulma")
    if priority1Exist then
        for _, placement in ipairs(TOWER_PLACEMENTS) do
            if placement.priority == 2 then
                placeTower(placement.name, placement.cframe)
            end
        end
    end
    
    for _, config in ipairs(TOWER_UPGRADES) do
        if config.upgradePhase == 1 then
            local tower = getTower(config.name)
            setAutoUpgrade(tower, true)
        end
    end
    
    local phase1Complete = true
    for _, config in ipairs(TOWER_UPGRADES) do
        if config.upgradePhase == 1 then
            local info = towerLevels[config.name]
            if not info or info.level < info.maxLevel then
                phase1Complete = false
                break
            end
        end
    end
    
    if phase1Complete then
        for _, config in ipairs(TOWER_UPGRADES) do
            if config.upgradePhase == 2 then
                local tower = getTower(config.name)
                setAutoUpgrade(tower, true)
            end
        end
    end
    
    local phase3Ready = true
    for _, towerName in ipairs(PHASE_3_REQUIREMENTS) do
        local info = towerLevels[towerName]
        if not info or info.level < info.maxLevel then
            phase3Ready = false
            break
        end
    end
    
    if phase3Ready then
        for _, config in ipairs(TOWER_UPGRADES) do
            if config.upgradePhase == 3 then
                local tower = getTower(config.name)
                setAutoUpgrade(tower, true)
            end
        end
    end
    
    local allSecondaryMaxed = true
    for _, config in ipairs(TOWER_UPGRADES) do
        if config.upgradePhase == 2 or config.upgradePhase == 3 then
            local info = towerLevels[config.name]
            if not info or info.level < info.maxLevel then
                allSecondaryMaxed = false
                break
            end
        end
    end
    
    if allSecondaryMaxed then
        for _, placement in ipairs(TOWER_PLACEMENTS) do
            if placement.priority == 3 then
                placeTower(placement.name, placement.cframe)
            end
        end
        
        for _, config in ipairs(TOWER_UPGRADES) do
            if config.upgradePhase == 4 then
                local tower = getTower(config.name)
                setAutoUpgrade(tower, true)
            end
        end
    end
    
    -- Cleanup every 100 loops (10 seconds)
    if loopCount % 100 == 0 then
        towerLevels = nil
    end
end

-- Final cleanup
towerInfoCache = nil
maxedTowers = nil
placementCostCache = nil
maxLevelCache = nil
autoUpgradeSet = nil
towerPlacementTime = nil
towerLevelsCache = nil
