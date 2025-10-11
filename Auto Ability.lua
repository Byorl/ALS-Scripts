repeat task.wait() until game:IsLoaded()

-- ========================================
-- CONFIGURATION - Edit settings below
-- ========================================

-- Enable/disable the script
getgenv().AutoAbilitiesEnabled = true

-- Game speed multiplier (affects cooldown calculations)
-- Set to 3 if playing on 3x speed, 1 for normal speed, etc.
local GAME_SPEED = 3

-- Tower ability configurations
-- Format: [TowerName] = { ability1, ability2, ... }
-- 
-- Available options for each ability:
-- - name: Ability name (required) - cooldown and requiredLevel auto-detected from TowerInfo
-- - onlyOnBoss: Only use when boss exists (true/false)
-- - onSpecificWaves: Only use on specific waves (e.g., {25, 50} or single wave 50)
-- - minWave: Only use on or after this wave number
-- - maxWave: Only use on or before this wave number
-- - requireBossInRange: Wait for boss to be in tower's range (true/false)
-- - rangeDelay: How long (seconds) boss must be in range before using ability
-- - delayAfterBossSpawn: Wait X seconds after boss spawns before using ability

local TOWER_ABILITIES = {
    ["AiHoshinoEvo"] = {
        {name = "Concert"}
    },
    ["Bulma"] = {
        {name = "Summon Wish Dragon"},
        {name = "Wish: Power"}
    },
    ["AsuraEvo"] = {
        {name = "Lines of Sanzu", onlyOnBoss = true, onSpecificWaves = 50}
    },
    ["NarutoBaryon"] = {
        {name = "Spiralling Shuriken"},
        {name = "Lava Release: Spiralling Shuriken", onlyOnBoss = true, onSpecificWaves = 50}
    },
    ["LelouchEvo"] = {
        {name = "All of you, Die!", onlyOnBoss = true, onSpecificWaves = 50, requireBossInRange = true},
        {name = "Submission", onlyOnBoss = true, onSpecificWaves = 50, requireBossInRange = true}
    },
    ["LightEvo"] = {
        {name = "Write Names", onlyOnBoss = true, onSpecificWaves = 50, delayAfterBossSpawn = 1}
    }
}

-- ========================================
-- SCRIPT CODE - Do not edit below unless you know what you're doing
-- ========================================

local RS = game:GetService("ReplicatedStorage")
local Towers = workspace.Towers

local bossSpawnTime = nil
local lightAbilityUsed = false
local bossInRangeTracker = {}
local abilityCooldowns = {}
local towerInfoCache = {}
local generalBossSpawnTime = nil
local lastWave = 0

local function resetRoundTrackers()
    bossSpawnTime = nil
    lightAbilityUsed = false
    bossInRangeTracker = {}
    generalBossSpawnTime = nil
    print("[Auto Ability] Round trackers reset for new round")
end



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

local function getAbilityData(towerName, abilityName)
    local towerInfo = getTowerInfo(towerName)
    if not towerInfo then 
        return nil 
    end
    
    for level = 0, 50 do
        if towerInfo[level] then
            if towerInfo[level].Ability then
                local abilityData = towerInfo[level].Ability
                if abilityData.Name == abilityName and not abilityData.AttributeRequired then
                    return {
                        cooldown = abilityData.Cd,
                        requiredLevel = level,
                        isGlobal = abilityData.IsCdGlobal
                    }
                end
            end
            
            if towerInfo[level].Abilities then
                for _, abilityData in pairs(towerInfo[level].Abilities) do
                    if abilityData.Name == abilityName and not abilityData.AttributeRequired then
                        return {
                            cooldown = abilityData.Cd,
                            requiredLevel = level,
                            isGlobal = abilityData.IsCdGlobal
                        }
                    end
                end
            end
        end
    end
    return nil
end 

local function getCurrentWave()
    local ok, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local gui = player.PlayerGui:FindFirstChild("Top")
        if not gui then return 0 end
        local frame = gui:FindFirstChild("Frame")
        if not frame then return 0 end
        frame = frame:FindFirstChild("Frame")
        if not frame then return 0 end
        frame = frame:FindFirstChild("Frame")
        if not frame then return 0 end
        frame = frame:FindFirstChild("Frame")
        if not frame then return 0 end
        local button = frame:FindFirstChild("TextButton")
        if not button then return 0 end
        local children = button:GetChildren()
        if #children < 3 then return 0 end
        local text = children[3].Text
        return tonumber(text) or 0
    end)
    return ok and result or 0
end

local function getTowerInfoName(tower)
    if not tower then return nil end
    
    local candidates = {
        tower:GetAttribute("TowerType"),
        tower:GetAttribute("Type"),
        tower:GetAttribute("TowerName"),
        tower:GetAttribute("BaseTower"),
        tower:FindFirstChild("TowerType") and tower.TowerType:IsA("ValueBase") and tower.TowerType.Value,
        tower:FindFirstChild("Type") and tower.Type:IsA("ValueBase") and tower.Type.Value,
        tower:FindFirstChild("TowerName") and tower.TowerName:IsA("ValueBase") and tower.TowerName.Value,
        tower.Name 
    }
    
    for _, candidate in ipairs(candidates) do
        if candidate and type(candidate) == "string" and candidate ~= "" then
            return candidate
        end
    end
    
    return tower.Name 
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

local function useAbility(tower, abilityName)
    if tower then
        pcall(function()
            local Event = RS.Remotes.Ability
            Event:InvokeServer(tower, abilityName)
        end)
    end
end

local function isOnCooldown(towerName, abilityName)
    local abilityData = getAbilityData(towerName, abilityName)
    if not abilityData or not abilityData.cooldown then return false end
    
    local key = towerName .. "_" .. abilityName
    local lastUsed = abilityCooldowns[key]
    
    if not lastUsed then return false end
    
    local adjustedCooldown = abilityData.cooldown / GAME_SPEED
    local elapsed = tick() - lastUsed
    return elapsed < adjustedCooldown
end

local function setAbilityUsed(towerName, abilityName)
    local key = towerName .. "_" .. abilityName
    abilityCooldowns[key] = tick()
end

local function hasAbilityBeenUnlocked(towerName, abilityName, towerLevel)
    local abilityData = getAbilityData(towerName, abilityName)
    if not abilityData then 
        return false 
    end
    
    local unlocked = towerLevel >= abilityData.requiredLevel
    if not unlocked then
    end
    return unlocked
end

local function isWave50()
    local ok, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local gui = player.PlayerGui:FindFirstChild("Top")
        if not gui then return false end
        local frame = gui:FindFirstChild("Frame")
        if not frame then return false end
        frame = frame:FindFirstChild("Frame")
        if not frame then return false end
        frame = frame:FindFirstChild("Frame")
        if not frame then return false end
        frame = frame:FindFirstChild("Frame")
        if not frame then return false end
        local button = frame:FindFirstChild("TextButton")
        if not button then return false end
        local children = button:GetChildren()
        if #children < 3 then return false end
        local text = children[3].Text
        return text == tostring(BOSS_WAVE) or text == BOSS_WAVE
    end)
    return ok and result
end

local function bossExists()
    local ok, result = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return false end
        return enemies:FindFirstChild("Boss") ~= nil
    end)
    return ok and result
end

local function bossReadyForAbilities()
    if bossExists() then
        if not generalBossSpawnTime then
            generalBossSpawnTime = tick()
        end
        local elapsed = tick() - generalBossSpawnTime
        return elapsed >= 1
    else
        generalBossSpawnTime = nil
        return false
    end
end

local function checkBossSpawnTime()
    if bossExists() then
        if not bossSpawnTime then
            bossSpawnTime = tick()
            lightAbilityUsed = false
        end
        local elapsed = tick() - bossSpawnTime
        if elapsed >= 16 and not lightAbilityUsed then
            return true
        end
        return false
    else
        bossSpawnTime = nil
        lightAbilityUsed = false
        return false
    end
end

local function getBossPosition()
    local ok, result = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        local boss = enemies:FindFirstChild("Boss")
        if not boss then return nil end
        local hrp = boss:FindFirstChild("HumanoidRootPart")
        if hrp then
            return hrp.Position
        end
        return nil
    end)
    return ok and result or nil
end

local function getTowerPosition(tower)
    if not tower then return nil end
    local ok, result = pcall(function()
        local hrp = tower:FindFirstChild("HumanoidRootPart")
        if hrp then
            return hrp.Position
        end
        return nil
    end)
    return ok and result or nil
end

local function getTowerRange(tower)
    if not tower then return 0 end
    local ok, result = pcall(function()
        local stats = tower:FindFirstChild("Stats")
        if not stats then return 0 end
        local range = stats:FindFirstChild("Range")
        if not range then return 0 end
        return range.Value or 0
    end)
    return ok and result or 0
end

local function isBossInRange(tower)
    local bossPos = getBossPosition()
    local towerPos = getTowerPosition(tower)
    
    if not bossPos or not towerPos then
        return false
    end
    
    local range = getTowerRange(tower)
    if range <= 0 then return false end
    
    local distance = (bossPos - towerPos).Magnitude
    return distance <= range
end

local function checkBossInRangeForDuration(tower, requiredDuration)
    if not tower then return false end
    
    local towerName = tower.Name
    local currentTime = tick()
    
    if isBossInRange(tower) then
        if requiredDuration == 0 then
            return true
        end
        
        if not bossInRangeTracker[towerName] then
            bossInRangeTracker[towerName] = currentTime
            return false
        else
            local timeInRange = currentTime - bossInRangeTracker[towerName]
            if timeInRange >= requiredDuration then
                return true
            end
        end
    else
        bossInRangeTracker[towerName] = nil
    end
    
    return false
end


while getgenv().AutoAbilitiesEnabled do
    wait(0.5)
    
    local currentWave = getCurrentWave()
    local hasBoss = bossExists()
    
    if currentWave < lastWave then
        resetRoundTrackers()
    end
    lastWave = currentWave
    
    for towerName, abilities in pairs(TOWER_ABILITIES) do
        local tower = getTower(towerName)
        
        if tower then
            local towerInfoName = getTowerInfoName(tower)
            local towerLevel = getUpgradeLevel(tower)
            
            for _, abilityConfig in ipairs(abilities) do
                local shouldUse = true
                local failReason = nil
                
                if not hasAbilityBeenUnlocked(towerInfoName, abilityConfig.name, towerLevel) then
                    shouldUse = false
                    failReason = "Not unlocked (Level " .. towerLevel .. ")"
                end
                
                if isOnCooldown(towerInfoName, abilityConfig.name) then
                    shouldUse = false
                    failReason = "On cooldown"
                end
                
                if abilityConfig.onlyOnBoss and not hasBoss then
                    shouldUse = false
                    failReason = "Boss required but not present"
                end
                
                if abilityConfig.onlyOnBoss and hasBoss and shouldUse then
                    if not bossReadyForAbilities() then
                        shouldUse = false
                        failReason = "Waiting 1s after boss spawn"
                    end
                end
                
                if abilityConfig.onSpecificWaves and shouldUse then
                    local onCorrectWave = false
                    if type(abilityConfig.onSpecificWaves) == "table" then
                        for _, wave in ipairs(abilityConfig.onSpecificWaves) do
                            if currentWave == wave then
                                onCorrectWave = true
                                break
                            end
                        end
                    else
                        onCorrectWave = (currentWave == abilityConfig.onSpecificWaves)
                    end
                    if not onCorrectWave then
                        shouldUse = false
                        failReason = "Wrong wave (Current: " .. currentWave .. ")"
                    end
                end
                
                if abilityConfig.minWave and currentWave < abilityConfig.minWave then
                    shouldUse = false
                end
                
                if abilityConfig.maxWave and currentWave > abilityConfig.maxWave then
                    shouldUse = false
                end
                
                if abilityConfig.requireBossInRange and shouldUse then
                    local rangeDelay = abilityConfig.rangeDelay or 0
                    if not checkBossInRangeForDuration(tower, rangeDelay) then
                        shouldUse = false
                        failReason = "Boss not in range" .. (rangeDelay > 0 and " for " .. rangeDelay .. "s" or "")

                    end
                end
                
                if shouldUse then
                    if abilityConfig.delayAfterBossSpawn then
                        if checkBossSpawnTime() then
                            useAbility(tower, abilityConfig.name)
                            lightAbilityUsed = true
                            setAbilityUsed(towerInfoName, abilityConfig.name)
                            print("[Auto Ability] Used " .. abilityConfig.name .. " on " .. towerName .. " (after boss spawn delay)")
                        end
                    else
                        useAbility(tower, abilityConfig.name)
                        setAbilityUsed(towerInfoName, abilityConfig.name)
                        print("[Auto Ability] Used " .. abilityConfig.name .. " on " .. towerName)
                    end

                end
            end
        end
    end
end
