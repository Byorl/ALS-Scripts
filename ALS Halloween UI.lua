repeat task.wait() until game:IsLoaded()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local LOBBY_PLACEIDS = {12886143095, 18583778121}
local function checkIsInLobby()
    for _, placeId in ipairs(LOBBY_PLACEIDS) do
        if game.PlaceId == placeId then
            return true
        end
    end
    return false
end
local isInLobby = checkIsInLobby()

local CONFIG_FOLDER = "ALSHalloweenEvent"
local CONFIG_FILE = "config.json"
local USER_ID = tostring(LocalPlayer.UserId)

local function getConfigPath()
    return CONFIG_FOLDER .. "/" .. USER_ID .. "/" .. CONFIG_FILE
end

local function getUserFolder()
    return CONFIG_FOLDER .. "/" .. USER_ID
end

local function getOldConfigPath()
    return CONFIG_FOLDER .. "/" .. CONFIG_FILE
end

local function migrateOldConfig()
    local oldConfigPath = getOldConfigPath()
    local newConfigPath = getConfigPath()
    
    if isfile(oldConfigPath) and not isfile(newConfigPath) then
        print("[Config] Migrating old config to user-specific folder...")
        local ok, oldData = pcall(function()
            return readfile(oldConfigPath)
        end)
        
        if ok and oldData then
            local userFolder = getUserFolder()
            if not isfolder(userFolder) then
                makefolder(userFolder)
            end
            
            pcall(function()
                writefile(newConfigPath, oldData)
                print("[Config] Migration successful! Config moved to: " .. newConfigPath)
            end)
        end
    end
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    
    local userFolder = getUserFolder()
    if not isfolder(userFolder) then
        makefolder(userFolder)
    end
    
    migrateOldConfig()
    
    local configPath = getConfigPath()
    if isfile(configPath) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(configPath))
        end)
        if ok and type(data) == "table" then
            data.toggles = data.toggles or {}
            data.inputs = data.inputs or {}
            data.dropdowns = data.dropdowns or {}
            data.abilities = data.abilities or {}
            return data
        end
    end
    return { toggles = {}, inputs = {}, dropdowns = {}, abilities = {} }
end

local function saveConfig(config)
    local userFolder = getUserFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    if not isfolder(userFolder) then
        makefolder(userFolder)
    end
    
    local ok, err = pcall(function()
        local json = HttpService:JSONEncode(config)
        local path = getConfigPath()
        writefile(path, json)
    end)
    if not ok then
        warn("[Config] Save failed: " .. tostring(err))
    end
    return ok
end

getgenv().Config = loadConfig()
print("[Config] Loaded config for User ID: " .. USER_ID)
print("[Config] Config path: " .. getConfigPath())
print("[Config] Config keys: toggles=" .. tostring(getgenv().Config.toggles ~= nil) .. ", inputs=" .. tostring(getgenv().Config.inputs ~= nil) .. ", abilities=" .. tostring(getgenv().Config.abilities ~= nil))

getgenv().AutoEventEnabled = getgenv().Config.toggles.AutoEventToggle or false
getgenv().AutoAbilitiesEnabled = getgenv().Config.toggles.AutoAbilityToggle or false
getgenv().AutoReadyEnabled = getgenv().Config.toggles.AutoReadyToggle or false
getgenv().CardSelectionEnabled = getgenv().Config.toggles.CardSelectionToggle or false
getgenv().SlowerCardSelectionEnabled = getgenv().Config.toggles.SlowerCardSelectionToggle or false
getgenv().BossRushEnabled = getgenv().Config.toggles.BossRushToggle or false
getgenv().WebhookEnabled = getgenv().Config.toggles.WebhookToggle or false
getgenv().SeamlessLimiterEnabled = getgenv().Config.toggles.SeamlessToggle or false
getgenv().BingoEnabled = getgenv().Config.toggles.BingoToggle or false
getgenv().CapsuleEnabled = getgenv().Config.toggles.CapsuleToggle or false
getgenv().RemoveEnemiesEnabled = getgenv().Config.toggles.RemoveEnemiesToggle or false
getgenv().AntiAFKEnabled = getgenv().Config.toggles.AntiAFKToggle or false
getgenv().BlackScreenEnabled = getgenv().Config.toggles.BlackScreenToggle or false
getgenv().FPSBoostEnabled = (not isInLobby) and (getgenv().Config.toggles.FPSBoostToggle or false) or false
getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL or ""
getgenv().MaxSeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4
getgenv().UnitAbilities = getgenv().UnitAbilities or {}

local CandyCards = {
    ["Weakened Resolve I"] = 13, ["Weakened Resolve II"] = 11, ["Weakened Resolve III"] = 4,
    ["Fog of War I"] = 12, ["Fog of War II"] = 10, ["Fog of War III"] = 5,
    ["Lingering Fear I"] = 6, ["Lingering Fear II"] = 2,
    ["Power Reversal I"] = 14, ["Power Reversal II"] = 9,
    ["Greedy Vampire's"] = 8, ["Hellish Gravity"] = 3, ["Deadly Striker"] = 7,
    ["Critical Denial"] = 1, ["Trick or Treat Coin Flip"] = 15
}
local DevilSacrifice = { ["Devil's Sacrifice"] = 999 }
local OtherCards = {
    ["Bullet Breaker I"] = 999, ["Bullet Breaker II"] = 999, ["Bullet Breaker III"] = 999,
    ["Hell Merchant I"] = 999, ["Hell Merchant II"] = 999, ["Hell Merchant III"] = 999,
    ["Hellish Warp I"] = 999, ["Hellish Warp II"] = 999,
    ["Fiery Surge I"] = 999, ["Fiery Surge II"] = 999,
    ["Grevious Wounds I"] = 999, ["Grevious Wounds II"] = 999,
    ["Scorching Hell I"] = 999, ["Scorching Hell II"] = 999,
    ["Fortune Flow"] = 999, ["Soul Link"] = 999
}
getgenv().CardPriority = getgenv().CardPriority or {}
for n,v in pairs(CandyCards) do if getgenv().Config.inputs["Card_"..n] then getgenv().CardPriority[n] = tonumber(getgenv().Config.inputs["Card_"..n]) else getgenv().CardPriority[n] = v end end
for n,v in pairs(DevilSacrifice) do if getgenv().Config.inputs["Card_"..n] then getgenv().CardPriority[n] = tonumber(getgenv().Config.inputs["Card_"..n]) else getgenv().CardPriority[n] = v end end
for n,v in pairs(OtherCards) do if getgenv().Config.inputs["Card_"..n] then getgenv().CardPriority[n] = tonumber(getgenv().Config.inputs["Card_"..n]) else getgenv().CardPriority[n] = v end end

local BossRushGeneral = {
    ["Metal Skin"] = 0,["Raging Power"] = 0,["Demon Takeover"] = 0,["Fortune"] = 0,
    ["Chaos Eater"] = 0,["Godspeed"] = 0,["Insanity"] = 0,["Feeding Madness"] = 0,["Emotional Damage"] = 0
}
local BabyloniaCastle = {}
getgenv().BossRushCardPriority = getgenv().BossRushCardPriority or {}
for n,v in pairs(BossRushGeneral) do
    local key = "BossRush_"..n
    if getgenv().Config.inputs[key] then getgenv().BossRushCardPriority[n] = tonumber(getgenv().Config.inputs[key]) else getgenv().BossRushCardPriority[n] = v end
end
for n,v in pairs(BabyloniaCastle) do
    local key = "BabyloniaCastle_"..n
    if getgenv().Config.inputs[key] then getgenv().BossRushCardPriority[n] = tonumber(getgenv().Config.inputs[key]) else getgenv().BossRushCardPriority[n] = v end
end

getgenv().BreachAutoJoin = getgenv().BreachAutoJoin or {}
getgenv().BreachEnabled = getgenv().Config.toggles.BreachToggle or false

local function notify(title, content, duration)
    Fluent:Notify({ Title = title or "ALS", Content = content or "", Duration = duration or 3 })
end

local Window = Fluent:CreateWindow({
    Title = "ALS Halloween Event",
    SubTitle = "Anime Last Stand Script",
    TabWidth = 140,
    Size = UDim2.fromOffset(580, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Ability = Window:AddTab({ Title = "Ability", Icon = "star" }),
    CardSelection = Window:AddTab({ Title = "Card Selection", Icon = "layout-grid" }),
    BossRush = Window:AddTab({ Title = "Boss Rush", Icon = "shield" }),
    Breach = Window:AddTab({ Title = "Breach", Icon = "alert-triangle" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "send" }),
    SeamlessFix = Window:AddTab({ Title = "Seamless Fix", Icon = "refresh-cw" }),
    Event = Window:AddTab({ Title = "Event", Icon = "gift" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "ALS_Fluent_Toggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.Parent = game:GetService("CoreGui")

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 75, 0, 75)
ToggleButton.Position = UDim2.new(0, 24, 0, 24)
ToggleButton.AnchorPoint = Vector2.new(0, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Image = "rbxassetid://72399447876912"
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ToggleGui

local function toggleUI()
    VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
end
ToggleButton.MouseButton1Click:Connect(toggleUI)

local function getClientData()
    local ok, data = pcall(function()
        local modulePath = RS:WaitForChild("Modules"):WaitForChild("ClientData")
        if modulePath and modulePath:IsA("ModuleScript") then
            return require(modulePath)
        end
        return nil
    end)
    return ok and data or nil
end

local function getTowerInfo(unitName)
    local ok, data = pcall(function()
        local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
        local towerModule = towerInfoPath:FindFirstChild(unitName)
        if towerModule and towerModule:IsA("ModuleScript") then
            return require(towerModule)
        end
        return nil
    end)
    return ok and data or nil
end

local function getAllAbilities(unitName)
    if not unitName or unitName == "" then return {} end
    local towerNameToCheck = unitName
    if unitName == "TuskSummon_Act4" then towerNameToCheck = "JohnnyGodly" end
    local towerInfo = getTowerInfo(towerNameToCheck)
    if not towerInfo then return {} end
    local abilities = {}
    for level = 0,50 do
        if towerInfo[level] then
            if towerInfo[level].Ability then
                local a = towerInfo[level].Ability
                local nm = a.Name
                if not abilities[nm] then
                    local hasRealAttribute = false
                    if a.AttributeRequired and type(a.AttributeRequired) == "table" then
                        if a.AttributeRequired.Name ~= "JUST_TO_DISPLAY_IN_LOBBY" then
                            hasRealAttribute = true
                        end
                    elseif a.AttributeRequired and type(a.AttributeRequired) ~= "table" then
                        hasRealAttribute = true
                    end
                    abilities[nm] = { name = nm, cooldown = a.Cd, requiredLevel = level, isGlobal = a.IsCdGlobal or false, isAttribute = hasRealAttribute }
                end
            end
            if towerInfo[level].Abilities then
                for _, a in pairs(towerInfo[level].Abilities) do
                    local nm = a.Name
                    if not abilities[nm] then
                        local hasRealAttribute = false
                        if a.AttributeRequired and type(a.AttributeRequired) == "table" then
                            if a.AttributeRequired.Name ~= "JUST_TO_DISPLAY_IN_LOBBY" then
                                hasRealAttribute = true
                            end
                        elseif a.AttributeRequired and type(a.AttributeRequired) ~= "table" then
                            hasRealAttribute = true
                        end
                        abilities[nm] = { name = nm, cooldown = a.Cd, requiredLevel = level, isGlobal = a.IsCdGlobal or false, isAttribute = hasRealAttribute }
                    end
                end
            end
        end
    end
    return abilities
end

local function addToggle(tab, key, title, default, onChanged)
    local t = tab:AddToggle(key, { Title = title, Default = default })
    t:OnChanged(function()
        local val = Fluent.Options[key].Value
        if onChanged then onChanged(val) end
    end)
    return t
end

Tabs.Main:AddParagraph({ Title = "⚡ Game Automation", Content = "Streamline your gameplay with automatic actions" })

addToggle(Tabs.Main, "AutoLeaveToggle", "Auto Leave", getgenv().Config.toggles.AutoLeaveToggle or false, function(val)
    getgenv().AutoLeaveEnabled = val
    getgenv().Config.toggles.AutoLeaveToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Leave", val and "Enabled" or "Disabled", 3)
end)

addToggle(Tabs.Main, "AutoFastRetryToggle", "Auto Replay", getgenv().Config.toggles.AutoFastRetryToggle or false, function(val)
    getgenv().AutoFastRetryEnabled = val
    getgenv().Config.toggles.AutoFastRetryToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Replay", val and "Enabled" or "Disabled", 3)
end)

addToggle(Tabs.Main, "AutoNextToggle", "Auto Next", getgenv().Config.toggles.AutoNextToggle or false, function(val)
    getgenv().AutoNextEnabled = val
    getgenv().Config.toggles.AutoNextToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Next", val and "Enabled" or "Disabled", 3)
end)

addToggle(Tabs.Main, "AutoSmartToggle", "Auto Leave/Replay/Next", getgenv().Config.toggles.AutoSmartToggle or false, function(val)
    getgenv().AutoSmartEnabled = val
    getgenv().Config.toggles.AutoSmartToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Leave/Replay/Next", val and "Enabled" or "Disabled", 3)
end)

addToggle(Tabs.Main, "AutoReadyToggle", "Auto Ready", getgenv().Config.toggles.AutoReadyToggle or false, function(val)
    getgenv().AutoReadyEnabled = val
    getgenv().Config.toggles.AutoReadyToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Ready", val and "Enabled" or "Disabled", 3)
end)

if isInLobby then
    Tabs.Main:AddParagraph({ Title = "🚀 Auto Join System", Content = "Automatically join maps and start games" })

    getgenv().AutoJoinConfig = getgenv().AutoJoinConfig or {
        enabled = false,
        autoStart = false,
        friendsOnly = false,
        mode = "Story",
        map = "",
        act = 1,
        difficulty = "Normal"
    }

    local MapData = nil
    pcall(function()
        local mapDataModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
        if mapDataModule and mapDataModule:IsA("ModuleScript") then
            MapData = require(mapDataModule)
        end
    end)

    local function getMapsByMode(mode)
        if not MapData then return {} end
        
        if mode == "ElementalCaverns" then
            return {"Light", "Nature", "Fire", "Dark", "Water"}
        end
        
        local maps = {}
        for mapName, mapInfo in pairs(MapData) do
            if mapInfo.Type and type(mapInfo.Type) == "table" then
                for _, mapType in ipairs(mapInfo.Type) do
                    if mapType == mode then
                        table.insert(maps, mapName)
                        break
                    end
                end
            end
        end
        table.sort(maps)
        return maps
    end

    local function mapHasAct(mapName)
        if not MapData or not MapData[mapName] then return false end
        return MapData[mapName].HasAct == true
    end

    local modeDropdown = Tabs.Main:AddDropdown("AutoJoinMode", {
        Title = "Mode",
        Values = {"Story", "Infinite", "Raids", "ElementalCaverns", "LegendaryStages", "Dungeon", "Survival", "Challenge"},
        Default = getgenv().AutoJoinConfig.mode or "Story",
    })

    local mapDropdown = Tabs.Main:AddDropdown("AutoJoinMap", {
        Title = "Map",
        Values = getMapsByMode(getgenv().AutoJoinConfig.mode),
        Default = getgenv().AutoJoinConfig.map or "",
    })

    local actDropdown = Tabs.Main:AddDropdown("AutoJoinAct", {
        Title = "Act",
        Values = {"1", "2", "3", "4", "5", "6"},
        Default = tostring(getgenv().AutoJoinConfig.act or 1),
    })

    local difficultyDropdown = Tabs.Main:AddDropdown("AutoJoinDifficulty", {
        Title = "Difficulty",
        Values = {"Normal", "Nightmare", "Purgatory", "Insanity"},
        Default = getgenv().AutoJoinConfig.difficulty or "Normal",
    })

    modeDropdown:OnChanged(function(value)
        getgenv().AutoJoinConfig.mode = value
        
        local newMaps = getMapsByMode(value)
        mapDropdown:SetValues(newMaps)
        if #newMaps > 0 then
            mapDropdown:SetValue(newMaps[1])
            getgenv().AutoJoinConfig.map = newMaps[1]
        end
    end)

    mapDropdown:OnChanged(function(value)
        getgenv().AutoJoinConfig.map = value
    end)

    actDropdown:OnChanged(function(value)
        getgenv().AutoJoinConfig.act = tonumber(value) or 1
    end)

    difficultyDropdown:OnChanged(function(value)
        getgenv().AutoJoinConfig.difficulty = value
    end)

    addToggle(Tabs.Main, "AutoJoinToggle", "Auto Join Map", false, function(val)
        getgenv().AutoJoinConfig.enabled = val
        notify("Auto Join", val and "Enabled" or "Disabled", 3)
    end)

    addToggle(Tabs.Main, "AutoJoinStartToggle", "Auto Start", false, function(val)
        getgenv().AutoJoinConfig.autoStart = val
        notify("Auto Start", val and "Enabled" or "Disabled", 3)
    end)

    addToggle(Tabs.Main, "FriendsOnlyToggle", "Friends Only", false, function(val)
        getgenv().AutoJoinConfig.friendsOnly = val
        pcall(function()
            RS.Remotes.Teleporter.InteractEvent:FireServer("FriendsOnly")
        end)
        notify("Friends Only", val and "Enabled" or "Disabled", 3)
    end)
else
    Tabs.Main:AddParagraph({ Title = "ℹ️ Auto Join System", Content = "The Auto Join system is only available in the lobby." })
end

Tabs.Ability:AddParagraph({ Title = "⚔️ Auto Ability System", Content = "Automatically trigger tower abilities based on conditions you set" })
addToggle(Tabs.Ability, "AutoAbilityToggle", "Enable Auto Abilities", getgenv().AutoAbilitiesEnabled, function(val)
    getgenv().AutoAbilitiesEnabled = val
    getgenv().Config.toggles.AutoAbilityToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Ability", val and "Enabled" or "Disabled", 3)
end)

local function buildAutoAbilityUI()
    local clientData = getClientData()
    if not clientData or not clientData.Slots then 
        notify("Auto Ability", "ClientData not available yet, retrying...", 3)
        return 
    end
    local sortedSlots = {"Slot1","Slot2","Slot3","Slot4","Slot5","Slot6"}

    local unitCount = 0
    for _, slotName in ipairs(sortedSlots) do
        local slotData = clientData.Slots[slotName]
        if slotData and slotData.Value then
            local unitName = slotData.Value
            local abilities = getAllAbilities(unitName)
            if next(abilities) then
                unitCount = unitCount + 1

                local unitSection = Tabs.Ability:AddSection(unitName .. " (" .. slotName .. " • Lvl " .. tostring(slotData.Level or 0) .. ")")

                if not getgenv().UnitAbilities[unitName] then getgenv().UnitAbilities[unitName] = {} end

                local sortedAbilities = {}
                for abilityName, data in pairs(abilities) do
                    table.insert(sortedAbilities, { name = abilityName, data = data })
                end
                table.sort(sortedAbilities, function(a,b) return a.data.requiredLevel < b.data.requiredLevel end)

                for _, ab in ipairs(sortedAbilities) do
                    local abilityName = ab.name
                    local abilityData = ab.data
                    if not getgenv().UnitAbilities[unitName][abilityName] then
                        getgenv().UnitAbilities[unitName][abilityName] = { enabled = true, onlyOnBoss=false, specificWave=nil, requireBossInRange=false, delayAfterBossSpawn=false, useOnWave=false }
                    end
                    local cfg = getgenv().UnitAbilities[unitName][abilityName]
                    local saved = getgenv().Config.abilities[unitName] and getgenv().Config.abilities[unitName][abilityName]

                    local defaultToggle = saved and saved.enabled or false
                    if saved then
                        cfg.enabled = saved.enabled or false
                        cfg.onlyOnBoss = saved.onlyOnBoss or false
                        cfg.specificWave = saved.specificWave
                        cfg.requireBossInRange = saved.requireBossInRange or false
                        cfg.delayAfterBossSpawn = saved.delayAfterBossSpawn or false
                        cfg.useOnWave = saved.useOnWave or false
                    end

                    local abilityInfo = abilityName .. " (Lvl " .. abilityData.requiredLevel .. " • CD: " .. tostring(abilityData.cooldown) .. "s"
                    if abilityData.isAttribute then abilityInfo = abilityInfo .. " • 🔒 Attribute" end
                    abilityInfo = abilityInfo .. ")"

                    addToggle(Tabs.Ability, unitName .. "_" .. abilityName .. "_Toggle", abilityInfo, defaultToggle, function(v)
                        cfg.enabled = v
                        getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                        getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                        getgenv().Config.abilities[unitName][abilityName].enabled = v
                        saveConfig(getgenv().Config)
                    end)

                    local defaultModifiers = {}
                    if saved then
                        if saved.onlyOnBoss then defaultModifiers["Only On Boss"] = true end
                        if saved.requireBossInRange then defaultModifiers["Boss In Range"] = true end
                        if saved.delayAfterBossSpawn then defaultModifiers["Delay After Boss Spawn"] = true end
                        if saved.useOnWave then defaultModifiers["On Wave"] = true end
                    end

                    local defaultList = {}
                    for k,v in pairs(defaultModifiers) do if v then table.insert(defaultList, k) end end

                    local dd = Tabs.Ability:AddDropdown(unitName .. "_" .. abilityName .. "_Modifiers", {
                        Title = "  > Conditions",
                        Values = {"Only On Boss","Boss In Range","Delay After Boss Spawn","On Wave"},
                        Multi = true,
                        Default = defaultList,
                    })
                    dd:OnChanged(function(Value)
                        local selected = {}
                        if type(Value) == "table" then
                            for k,v in pairs(Value) do
                                if type(k) == "string" and v == true then selected[k] = true end
                            end
                            if #Value > 0 then
                                for _,opt in ipairs(Value) do selected[opt] = true end
                            end
                        end
                        cfg.onlyOnBoss = selected["Only On Boss"] or false
                        cfg.requireBossInRange = selected["Boss In Range"] or false
                        cfg.delayAfterBossSpawn = selected["Delay After Boss Spawn"] or false
                        cfg.useOnWave = selected["On Wave"] or false

                        getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                        getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                        local store = getgenv().Config.abilities[unitName][abilityName]
                        store.onlyOnBoss = cfg.onlyOnBoss
                        store.requireBossInRange = cfg.requireBossInRange
                        store.delayAfterBossSpawn = cfg.delayAfterBossSpawn
                        store.useOnWave = cfg.useOnWave
                        saveConfig(getgenv().Config)
                    end)

                    local input = Tabs.Ability:AddInput(unitName .. "_" .. abilityName .. "_Wave", {
                        Title = "  > Wave Number",
                        Default = (saved and saved.specificWave and tostring(saved.specificWave)) or "",
                        Placeholder = "Required if 'On Wave' selected",
                        Numeric = true,
                        Finished = true,
                        Callback = function(text)
                            local num = tonumber(text)
                            cfg.specificWave = num
                            getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                            getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                            getgenv().Config.abilities[unitName][abilityName].specificWave = num
                            saveConfig(getgenv().Config)
                        end
                    })
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(2)
    local maxRetries, retryDelay = 10, 3
    local ok = false
    for i=1,maxRetries do
        pcall(function()
            local cd = getClientData()
            if cd and cd.Slots then
                buildAutoAbilityUI()
                ok = true
            else
                if i <= 3 then
                    notify("Auto Ability", "Loading units... ("..i.."/"..maxRetries..")", 2)
                end
            end
        end)
        if ok then break end
        task.wait(retryDelay)
    end
    if not ok then
        pcall(function()
            Tabs.Ability:AddParagraph({ Title = "❌ Failed to Load Units", Content = "Could not load your equipped units from ClientData. Rejoin or reload the script." })
        end)
    end
end)

Tabs.CardSelection:AddParagraph({ Title = "🃏 Card Priority System", Content = "Lower number = higher priority • Set to 999 to avoid a card" })
addToggle(Tabs.CardSelection, "CardSelectionToggle", "Fast Mode", getgenv().CardSelectionEnabled, function(v)
    getgenv().CardSelectionEnabled = v
    getgenv().Config.toggles.CardSelectionToggle = v
    if v and getgenv().SlowerCardSelectionEnabled then
        getgenv().SlowerCardSelectionEnabled = false
        getgenv().Config.toggles.SlowerCardSelectionToggle = false
    end
    saveConfig(getgenv().Config)
    notify("Card Selection", v and "Fast Mode Enabled" or "Disabled", 3)
end)
addToggle(Tabs.CardSelection, "SlowerCardSelectionToggle", "Slower Mode (More Reliable)", getgenv().SlowerCardSelectionEnabled, function(v)
    getgenv().SlowerCardSelectionEnabled = v
    getgenv().Config.toggles.SlowerCardSelectionToggle = v
    if v and getgenv().CardSelectionEnabled then
        getgenv().CardSelectionEnabled = false
        getgenv().Config.toggles.CardSelectionToggle = false
    end
    saveConfig(getgenv().Config)
    notify("Card Selection", v and "Slower Mode Enabled" or "Disabled", 3)
end)

Tabs.CardSelection:AddParagraph({ Title = "🍬 Candy Cards", Content = "" })
local candyNames = {}
for k in pairs(CandyCards) do table.insert(candyNames, k) end
table.sort(candyNames, function(a,b) return (CandyCards[a] or 999) < (CandyCards[b] or 999) end)
for _, cardName in ipairs(candyNames) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(CandyCards[cardName])
    Tabs.CardSelection:AddInput(key, {
        Title = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end
    })
    getgenv().CardPriority[cardName] = tonumber(defaultValue) or CandyCards[cardName]
end

Tabs.CardSelection:AddParagraph({ Title = "😈 Devil's Sacrifice", Content = "" })
for cardName,priority in pairs(DevilSacrifice) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(priority)
    Tabs.CardSelection:AddInput(key, {
        Title = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end
    })
    getgenv().CardPriority[cardName] = tonumber(defaultValue) or priority
end

Tabs.CardSelection:AddParagraph({ Title = "📋 Other Cards", Content = "" })
local otherNames = {}
for k in pairs(OtherCards) do table.insert(otherNames, k) end
table.sort(otherNames)
for _, cardName in ipairs(otherNames) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(OtherCards[cardName])
    Tabs.CardSelection:AddInput(key, {
        Title = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end
    })
    getgenv().CardPriority[cardName] = tonumber(defaultValue) or OtherCards[cardName]
end

Tabs.BossRush:AddParagraph({ Title = "⚔️ Boss Rush Cards", Content = "Lower number = higher priority • Set to 999 to avoid" })
addToggle(Tabs.BossRush, "BossRushToggle", "Enable Boss Rush Card Selection", getgenv().BossRushEnabled, function(v)
    getgenv().BossRushEnabled = v
    getgenv().Config.toggles.BossRushToggle = v
    saveConfig(getgenv().Config)
    notify("Boss Rush", v and "Enabled" or "Disabled", 3)
end)

Tabs.BossRush:AddParagraph({ Title = "🎯 General Cards", Content = "" })
local brNames = {}
for k in pairs(BossRushGeneral) do table.insert(brNames, k) end
table.sort(brNames)
for _, cardName in ipairs(brNames) do
    local inputKey = "BossRush_"..cardName
    local defaultValue = getgenv().Config.inputs[inputKey] or tostring(BossRushGeneral[cardName])
    local cardType = "Buff"
    pcall(function()
        local bossRushModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards")
        if bossRushModule then
            local cards = require(bossRushModule)
            for _, card in pairs(cards) do if card.CardName == cardName then cardType = card.CardType or "Buff" break end end
        end
    end)
    Tabs.BossRush:AddInput(inputKey, {
        Title = cardName .. " ("..cardType..")",
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().BossRushCardPriority[cardName] = num
                getgenv().Config.inputs[inputKey] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end
    })
    getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue) or BossRushGeneral[cardName]
end

if not isInLobby then
    Tabs.BossRush:AddParagraph({ Title = "🏰 Babylonia Castle", Content = "" })
    pcall(function()
        local babyloniaModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards"):FindFirstChild("Babylonia Castle")
        if babyloniaModule then
            local cards = require(babyloniaModule)
            for _, card in pairs(cards) do
                local cardName = card.CardName
                local cardType = card.CardType or "Buff"
                local inputKey = "BabyloniaCastle_" .. cardName
                if not getgenv().BossRushCardPriority[cardName] then getgenv().BossRushCardPriority[cardName] = 999 end
                local defaultValue = getgenv().Config.inputs[inputKey] or "999"
                Tabs.BossRush:AddInput(inputKey, {
                    Title = cardName .. " ("..cardType..")",
                    Default = defaultValue,
                    Placeholder = "Priority (1-999)",
                    Numeric = true,
                    Finished = true,
                    Callback = function(Value)
                        local num = tonumber(Value)
                        if num then
                            getgenv().BossRushCardPriority[cardName] = num
                            getgenv().Config.inputs[inputKey] = tostring(num)
                            saveConfig(getgenv().Config)
                        end
                    end
                })
                getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue) or 999
            end
        end
    end)
else
    Tabs.BossRush:AddParagraph({ Title = "ℹ️ Babylonia Castle", Content = "Babylonia Castle cards are only available outside the lobby." })
end

if isInLobby then
    Tabs.Breach:AddParagraph({ Title = "⚡ Breach Auto-Join", Content = "Automatically join available breaches when they spawn in the lobby" })

    addToggle(Tabs.Breach, "BreachToggle", "Enable Breach Auto-Join", getgenv().BreachEnabled, function(v)
        getgenv().BreachEnabled = v
        getgenv().Config.toggles.BreachToggle = v
        saveConfig(getgenv().Config)
        print("[Breach] Master toggle set to:", v)
        notify("Breach Auto-Join", v and "Enabled" or "Disabled", 3)
    end)

    Tabs.Breach:AddParagraph({ Title = "📋 Available Breaches", Content = "Toggle which breaches to auto-join" })

    local breachesLoaded = false
    pcall(function()
        local mapParamsModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Breach") and RS.Modules.Breach:FindFirstChild("MapParameters")
        
        if mapParamsModule and mapParamsModule:IsA("ModuleScript") then
            local mapParams = require(mapParamsModule)
            
            if mapParams and next(mapParams) then
                local breachList = {}
                for breachName, breachInfo in pairs(mapParams) do
                    table.insert(breachList, {
                        name = breachName,
                        disabled = breachInfo.Disabled or false
                    })
                end
                
                table.sort(breachList, function(a, b) return a.name < b.name end)
                
                for _, breach in ipairs(breachList) do
                    local breachKey = "Breach_" .. breach.name
                    local savedState = getgenv().Config.toggles[breachKey] or false
                    
                    if not getgenv().BreachAutoJoin[breach.name] then
                        getgenv().BreachAutoJoin[breach.name] = savedState
                    end
                    
                    local statusText = breach.disabled and " [DISABLED]" or ""
                    local breachTitle = breach.name .. statusText
                    
                    addToggle(Tabs.Breach, breachKey, breachTitle, savedState, function(v)
                        getgenv().BreachAutoJoin[breach.name] = v
                        getgenv().Config.toggles[breachKey] = v
                        saveConfig(getgenv().Config)
                        print("[Breach] Toggle for", breach.name, "set to:", v)
                        print("[Breach] Current BreachAutoJoin table:", game:GetService("HttpService"):JSONEncode(getgenv().BreachAutoJoin))
                    end)
                end
                
                breachesLoaded = true
                print("[Breach] Loaded " .. #breachList .. " breaches from MapParameters")
            end
        end
    end)

    if not breachesLoaded then
        Tabs.Breach:AddParagraph({ Title = "⚠️ Loading Failed", Content = "Could not load breach data from MapParameters. The module may not be available." })
    end
else
    Tabs.Breach:AddParagraph({ Title = "ℹ️ Breach Auto-Join", Content = "The Auto Breach can only be used in the lobby." })
end

Tabs.Webhook:AddParagraph({ Title = "🔔 Discord Notifications", Content = "Get match completion stats sent directly to your Discord server" })
addToggle(Tabs.Webhook, "WebhookToggle", "Enable Webhook Notifications", getgenv().WebhookEnabled, function(v)
    getgenv().WebhookEnabled = v
    getgenv().Config.toggles.WebhookToggle = v
    saveConfig(getgenv().Config)
    if v then
        if (getgenv().WebhookURL == "" or not string.match(getgenv().WebhookURL, "^https://discord%.com/api/webhooks/")) then
            notify("Webhook", "Please enter a valid webhook URL first", 5)
            getgenv().WebhookEnabled = false
            getgenv().Config.toggles.WebhookToggle = false
            saveConfig(getgenv().Config)
        else
            notify("Webhook", "Enabled", 3)
        end
    else
        notify("Webhook", "Disabled", 3)
    end
end)

Tabs.Webhook:AddInput("WebhookURL", {
    Title = "Webhook URL",
    Default = getgenv().WebhookURL or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        getgenv().WebhookURL = Value or ""
        getgenv().Config.inputs.WebhookURL = getgenv().WebhookURL
        saveConfig(getgenv().Config)
    end
})

Tabs.SeamlessFix:AddParagraph({ Title = "🔄 Seamless Retry Fix", Content = "Prevents lag by restarting after a set number of rounds" })
addToggle(Tabs.SeamlessFix, "SeamlessToggle", "Enable Seamless Fix", getgenv().SeamlessLimiterEnabled, function(v)
    getgenv().SeamlessLimiterEnabled = v
    getgenv().Config.toggles.SeamlessToggle = v
    saveConfig(getgenv().Config)
    notify("Seamless Fix", v and "Enabled" or "Disabled", 3)
    print("[Seamless Fix] " .. (v and "Enabled" or "Disabled"))
end)

Tabs.SeamlessFix:AddInput("SeamlessRounds", {
    Title = "Max Rounds Before Restart",
    Default = getgenv().Config.inputs.SeamlessRounds or "4",
    Placeholder = "Default: 4",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            getgenv().MaxSeamlessRounds = num
            getgenv().Config.inputs.SeamlessRounds = tostring(num)
            saveConfig(getgenv().Config)
        else
            getgenv().MaxSeamlessRounds = 4
        end
    end
})

Tabs.Event:AddParagraph({ Title = "🎃 Halloween 2025 Event", Content = "Automatically join and participate in the Halloween event" })

addToggle(Tabs.Event, "AutoEventToggle", "Auto Event Join", getgenv().AutoEventEnabled, function(val)
    getgenv().AutoEventEnabled = val
    getgenv().Config.toggles.AutoEventToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Event", val and "Enabled" or "Disabled", 3)
end)

if isInLobby then
    Tabs.Event:AddParagraph({ Title = "🎲 Auto Bingo", Content = "" })
    addToggle(Tabs.Event, "BingoToggle", "Enable Auto Bingo", getgenv().BingoEnabled, function(v)
        getgenv().BingoEnabled = v
        getgenv().Config.toggles.BingoToggle = v
        saveConfig(getgenv().Config)
        notify("Auto Bingo", v and "Enabled" or "Disabled", 3)
    end)

    Tabs.Event:AddParagraph({ Title = "🎁 Auto Capsules", Content = "" })
    addToggle(Tabs.Event, "CapsuleToggle", "Enable Auto Capsules", getgenv().CapsuleEnabled, function(v)
        getgenv().CapsuleEnabled = v
        getgenv().Config.toggles.CapsuleToggle = v
        saveConfig(getgenv().Config)
        notify("Auto Capsules", v and "Enabled" or "Disabled", 3)
    end)

    Tabs.Event:AddParagraph({ Title = "ℹ️ Info", Content = "Bingo: Uses stamps (25x), claims rewards, completes board\nCapsules: Buys 100/10/1 based on candy, opens all" })
else
    Tabs.Event:AddParagraph({ Title = "ℹ️ Lobby Only", Content = "Bingo and Capsule features are only available in the lobby." })
end

Tabs.Misc:AddParagraph({ Title = "🛠️ Utility Features", Content = "Performance and quality of life improvements" })

Tabs.Misc:AddParagraph({ Title = "⚡ Performance", Content = "" })
if not isInLobby then
    addToggle(Tabs.Misc, "FPSBoostToggle", "FPS Boost", getgenv().FPSBoostEnabled, function(v)
        getgenv().FPSBoostEnabled = v
        getgenv().Config.toggles.FPSBoostToggle = v
        saveConfig(getgenv().Config)
        notify("FPS Boost", v and "Enabled" or "Disabled", 3)
    end)
else
    getgenv().FPSBoostEnabled = false
end

addToggle(Tabs.Misc, "RemoveEnemiesToggle", "Remove Enemies & Units", getgenv().RemoveEnemiesEnabled, function(v)
    getgenv().RemoveEnemiesEnabled = v
    getgenv().Config.toggles.RemoveEnemiesToggle = v
    saveConfig(getgenv().Config)
    notify("Remove Enemies", v and "Enabled" or "Disabled", 3)
end)

addToggle(Tabs.Misc, "BlackScreenToggle", "Black Screen Mode", getgenv().BlackScreenEnabled, function(v)
    getgenv().BlackScreenEnabled = v
    getgenv().Config.toggles.BlackScreenToggle = v
    saveConfig(getgenv().Config)
    notify("Black Screen", v and "Enabled" or "Disabled", 3)
end)

Tabs.Misc:AddParagraph({ Title = "🔒 Safety & UI", Content = "" })

addToggle(Tabs.Misc, "AutoHideUIToggle", "Auto Hide UI on Start", getgenv().Config.toggles.AutoHideUIToggle or false, function(v)
    getgenv().Config.toggles.AutoHideUIToggle = v
    saveConfig(getgenv().Config)
    notify("Auto Hide UI", v and "Enabled - Auto Hide UI" or "Disabled", 3)
end)

addToggle(Tabs.Misc, "AntiAFKToggle", "Anti-AFK", getgenv().AntiAFKEnabled, function(v)
    getgenv().AntiAFKEnabled = v
    getgenv().Config.toggles.AntiAFKToggle = v
    saveConfig(getgenv().Config)
    notify("Anti-AFK", v and "Enabled" or "Disabled", 3)
end)

Tabs.Settings:AddParagraph({ Title = "💾 Config Management", Content = "Your settings are automatically saved to: " .. CONFIG_FOLDER .. "/" .. CONFIG_FILE })

Tabs.Settings:AddButton({
    Title = "Force Save Config Now",
    Description = "Manually save all current settings",
    Callback = function()
        local success = saveConfig(getgenv().Config)
        if success then
            notify("Config", "Settings saved successfully!", 3)
        else
            notify("Config", "Failed to save settings!", 5)
        end
    end
})

Tabs.Settings:AddButton({
    Title = "Open Config Folder",
    Description = "Opens the folder where config is saved",
    Callback = function()
        notify("Config Location", CONFIG_FOLDER .. "/" .. CONFIG_FILE, 5)
        print("[Config] Full path: " .. getConfigPath())
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("ALS-Fluent")
SaveManager:SetFolder("ALS-Fluent/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

notify("ALS Halloween Event", "Script loaded successfully!", 5)

if getgenv().Config.toggles.AutoHideUIToggle then
    task.spawn(function()
        task.wait(0.2)
        if Window and not Fluent.Unloaded then
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            print("[Auto Hide] UI minimized after 3 seconds")
        end
    end)
end

for inputKey, value in pairs(getgenv().Config.inputs) do
    if inputKey:match("^Card_") then
        local cardName = inputKey:gsub("^Card_", "")
        local num = tonumber(value)
        if num and getgenv().CardPriority[cardName] then getgenv().CardPriority[cardName] = num end
    elseif inputKey:match("^BossRush_") then
        local cardName = inputKey:gsub("^BossRush_", "")
        local num = tonumber(value)
        if num and getgenv().BossRushCardPriority[cardName] then getgenv().BossRushCardPriority[cardName] = num end
    elseif inputKey:match("^BabyloniaCastle_") then
        local cardName = inputKey:gsub("^BabyloniaCastle_", "")
        local num = tonumber(value)
        if num then getgenv().BossRushCardPriority[cardName] = num end
    end
end

local isUnloaded = false
spawn(function()
    while true do
        task.wait(1)
        if Fluent.Unloaded then isUnloaded = true break end
    end
end)

task.spawn(function()
    while true do
        task.wait(20)
        collectgarbage("collect")
        collectgarbage("collect")
        if isUnloaded then break end
    end
end)

task.spawn(function()
    repeat task.wait() until game.CoreGui:FindFirstChild("RobloxPromptGui")
    local TeleportService = game:GetService("TeleportService")
    local promptOverlay = game.CoreGui.RobloxPromptGui.promptOverlay
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            print("[Auto Rejoin] Disconnect detected! Attempting to rejoin...")
            task.spawn(function()
                while true do
                    local ok = pcall(function()
                        TeleportService:Teleport(12886143095, Players.LocalPlayer)
                    end)
                    if ok then print("[Auto Rejoin] Rejoining...") break else print("[Auto Rejoin] Retry in 2s...") task.wait(2) end
                end
            end)
        end
    end)
    print("[Auto Rejoin] Auto rejoin system loaded!")
end)

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    Players.LocalPlayer.Idled:Connect(function()
        if getgenv().AntiAFKEnabled then
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
    print("[Anti-AFK] Anti-AFK system loaded!")
end)

task.spawn(function()
    local blackScreenGui, blackFrame
    local function createBlack()
        if blackScreenGui then return end
        blackScreenGui = Instance.new("ScreenGui")
        blackScreenGui.Name = "BlackScreenOverlay"
        blackScreenGui.DisplayOrder = -999999
        blackScreenGui.IgnoreGuiInset = true
        blackScreenGui.ResetOnSpawn = false
        blackFrame = Instance.new("Frame")
        blackFrame.Size = UDim2.new(1,0,1,0)
        blackFrame.BackgroundColor3 = Color3.new(0,0,0)
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = -999999
        blackFrame.Parent = blackScreenGui
        pcall(function() blackScreenGui.Parent = LocalPlayer.PlayerGui end)
        pcall(function()
            if workspace.CurrentCamera then workspace.CurrentCamera.MaxAxisFieldOfView = 0.001 end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end
    local function removeBlack()
        if blackScreenGui then blackScreenGui:Destroy() blackScreenGui=nil blackFrame=nil end
        pcall(function() if workspace.CurrentCamera then workspace.CurrentCamera.MaxAxisFieldOfView = 70 end end)
    end
    while true do
        task.wait(0.5)
        if getgenv().BlackScreenEnabled then if not blackScreenGui then createBlack() end else if blackScreenGui then removeBlack() end end
        if isUnloaded then removeBlack() break end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().RemoveEnemiesEnabled then
            pcall(function()
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    local children = enemies:GetChildren()
                    for i = 1, #children do
                        local enemy = children[i]
                        if enemy:IsA("Model") and enemy.Name ~= "Boss" then 
                            enemy:Destroy()
                        end
                    end
                    children = nil
                end
                
                local spawnedunits = workspace:FindFirstChild("SpawnedUnits")
                if spawnedunits then
                    for _, su in pairs(spawnedunits:GetChildren()) do
                        if su:IsA("Model") then 
                            su:Destroy()
                        end
                    end
                end
            end)
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        if not isInLobby and getgenv().FPSBoostEnabled then
            pcall(function()
                local lighting = game:GetService("Lighting")
                for _, child in ipairs(lighting:GetChildren()) do child:Destroy() end
                lighting.Ambient = Color3.new(1,1,1)
                lighting.Brightness = 1
                lighting.GlobalShadows = false
                lighting.FogEnd = 100000
                lighting.FogStart = 100000
                lighting.ClockTime = 12
                lighting.GeographicLatitude = 0
                for _, obj in ipairs(game.Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("WedgePart") or obj:IsA("CornerWedgePart") then
                            obj.Material = Enum.Material.SmoothPlastic
                            if obj:FindFirstChildOfClass("Texture") then
                                for _, t in ipairs(obj:GetChildren()) do if t:IsA("Texture") then t:Destroy() end end
                            end
                            if obj:IsA("MeshPart") then obj.TextureID = "" end
                        end
                        if obj:IsA("Decal") then obj:Destroy() end
                    end
                    if obj:IsA("SurfaceAppearance") then obj:Destroy() end
                end
                local mapPath = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Map")
                if mapPath then for _, ch in ipairs(mapPath:GetChildren()) do if not ch:IsA("Model") then ch:Destroy() end end end
            end)
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    local eventsFolder = RS:FindFirstChild("Events")
    local halloweenFolder = eventsFolder and eventsFolder:FindFirstChild("Hallowen2025")
    local enterEvent = halloweenFolder and halloweenFolder:FindFirstChild("Enter")
    local startEvent = halloweenFolder and halloweenFolder:FindFirstChild("Start")
    
    while true do
        task.wait(0.5)
        if getgenv().AutoEventEnabled and enterEvent and startEvent then
            pcall(function() 
                enterEvent:FireServer()
                startEvent:FireServer()
            end)
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    local function press(key)
        VIM:SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, key, false, game)
    end
    local GuiService = game:GetService("GuiService")
    local lastEndGameUICheck = 0
    local loopCount = 0
    while true do
        task.wait(2)
        loopCount = loopCount + 1
        
        if loopCount % 10 == 0 then
            collectgarbage("collect")
        end
        
        pcall(function()
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if endGameUI and endGameUI:FindFirstChild("BG") and endGameUI.BG:FindFirstChild("Buttons") then
                local buttons = endGameUI.BG.Buttons
                local nextButton = buttons:FindFirstChild("Next")
                local retryButton = buttons:FindFirstChild("Retry")
                local leaveButton = buttons:FindFirstChild("Leave")
                
                if getgenv().WebhookEnabled then
                    if tick() - lastEndGameUICheck > 5 then
                        print("[EndGameUI] Waiting for webhook to complete...")
                        lastEndGameUICheck = tick()
                        
                        local maxWait = 0
                        while isProcessing and maxWait < 10 do
                            task.wait(0.5)
                            maxWait = maxWait + 0.5
                        end
                        print("[EndGameUI] Webhook completed, proceeding...")
                    end
                else
                    print("[EndGameUI] Webhook disabled, proceeding immediately")
                end
                
                local buttonToPress = nil
                local actionName = ""
                
                if getgenv().AutoSmartEnabled then
                    if nextButton and nextButton.Visible then
                        buttonToPress = nextButton
                        actionName = "Next"
                    elseif retryButton and retryButton.Visible then
                        buttonToPress = retryButton
                        actionName = "Replay"
                    elseif leaveButton then
                        buttonToPress = leaveButton
                        actionName = "Leave"
                    end
                elseif getgenv().AutoNextEnabled and nextButton and nextButton.Visible then
                    buttonToPress = nextButton
                    actionName = "Next"
                elseif getgenv().AutoFastRetryEnabled and retryButton and retryButton.Visible then
                    buttonToPress = retryButton
                    actionName = "Replay"
                elseif getgenv().AutoLeaveEnabled and leaveButton then
                    buttonToPress = leaveButton
                    actionName = "Leave"
                end
                
                if buttonToPress then
                    GuiService.SelectedObject = buttonToPress
                    repeat 
                        press(Enum.KeyCode.Return)
                        task.wait(0.5)
                    until not LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
                    GuiService.SelectedObject = nil
                    print("[EndGameUI] Clicked " .. actionName .. " button")
                    
                    buttons = nil
                    nextButton = nil
                    retryButton = nil
                    leaveButton = nil
                    buttonToPress = nil
                end
            elseif GuiService.SelectedObject ~= nil then 
                GuiService.SelectedObject = nil 
            end
        end)
        if isUnloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().AutoReadyEnabled then
            pcall(function()
                local bottomGui = LocalPlayer.PlayerGui:FindFirstChild("Bottom")
                if bottomGui then
                    local frame = bottomGui:FindFirstChild("Frame")
                    if frame then
                        local children = frame:GetChildren()
                        if children[2] then
                            local subChildren = children[2]:GetChildren()
                            if subChildren[6] then
                                local textButton = subChildren[6]:FindFirstChild("TextButton")
                                if textButton then
                                    local textLabel = textButton:FindFirstChild("TextLabel")
                                    if textLabel and textLabel.Text == "Start" then
                                        local remotes = RS:FindFirstChild("Remotes")
                                        local playerReady = remotes and remotes:FindFirstChild("PlayerReady")
                                        if playerReady then
                                            playerReady:FireServer()
                                            print("[Auto Ready] Player ready fired")
                                            task.wait(2)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    local GAME_SPEED = 3
    local Towers = workspace:WaitForChild("Towers", 10)
    local bossSpawnTime = nil
    local bossInRangeTracker = {}
    local abilityCooldowns = {}
    local towerInfoCache = {}
    local generalBossSpawnTime = nil
    local lastWave = 0

    local function resetRoundTrackers()
        bossSpawnTime = nil
        bossInRangeTracker = {}
        generalBossSpawnTime = nil
        abilityCooldowns = {}
    end
    local function getTowerInfoCached(towerName)
        if towerInfoCache[towerName] then return towerInfoCache[towerName] end
        local t = getTowerInfo(towerName)
        if t then towerInfoCache[towerName] = t end
        return t
    end
    local function getAbilityData(towerName, abilityName)
        local info = getTowerInfoCached(towerName)
        if not info then return nil end
        for level=0,50 do
            if info[level] then
                if info[level].Ability then
                    local a = info[level].Ability
                    if a.Name == abilityName then return { cooldown=a.Cd, requiredLevel=level, isGlobal=a.IsCdGlobal } end
                end
                if info[level].Abilities then
                    for _,a in pairs(info[level].Abilities) do
                        if a.Name == abilityName then return { cooldown=a.Cd, requiredLevel=level, isGlobal=a.IsCdGlobal } end
                    end
                end
            end
        end
        return nil
    end
    local function getCurrentWave()
        local ok, result = pcall(function()
            local gui = LocalPlayer.PlayerGui:FindFirstChild("Top") if not gui then return 0 end
            local frame = gui:FindFirstChild("Frame") if not frame then return 0 end
            frame = frame:FindFirstChild("Frame") if not frame then return 0 end
            frame = frame:FindFirstChild("Frame") if not frame then return 0 end
            frame = frame:FindFirstChild("Frame") if not frame then return 0 end
            local button = frame:FindFirstChild("TextButton") if not button then return 0 end
            local children = button:GetChildren() if #children < 3 then return 0 end
            local text = children[3].Text
            return tonumber(text) or 0
        end)
        return ok and result or 0
    end
    local function getTowerInfoName(tower)
        if not tower then return nil end
        local candidates = { tower:GetAttribute("TowerType"), tower:GetAttribute("Type"), tower:GetAttribute("TowerName"), tower:GetAttribute("BaseTower"),
            tower:FindFirstChild("TowerType") and tower.TowerType:IsA("ValueBase") and tower.TowerType.Value,
            tower:FindFirstChild("Type") and tower.Type:IsA("ValueBase") and tower.Type.Value,
            tower:FindFirstChild("TowerName") and tower.TowerName:IsA("ValueBase") and tower.TowerName.Value,
            tower.Name }
        for _, c in ipairs(candidates) do if c and type(c)=="string" and c ~= "" then return c end end
        return tower.Name
    end
    local function getTower(name) return Towers:FindFirstChild(name) end
    local function getUpgradeLevel(tower)
        if not tower then return 0 end
        local u = tower:FindFirstChild("Upgrade")
        if u and u:IsA("ValueBase") then return u.Value or 0 end
        return 0
    end
    local function fixAbilityName(abilityName)
        local fixed = abilityName
        fixed = fixed:gsub("!!+", "!")
        fixed = fixed:gsub("%?%?+", "?")
        return fixed
    end
    local function useAbility(tower, abilityName)
        if tower then 
            local correctedName = fixAbilityName(abilityName)
            pcall(function() 
                RS.Remotes.Ability:InvokeServer(tower, correctedName) 
            end) 
        end
    end
    local function isOnCooldown(towerName, abilityName)
        local d = getAbilityData(towerName, abilityName) if not d or not d.cooldown then return false end
        local key = towerName .. "_" .. abilityName
        local last = abilityCooldowns[key]
        if not last then return false end
        local elapsed = tick() - last
        return elapsed < (d.cooldown / GAME_SPEED)
    end
    local function setAbilityUsed(towerName, abilityName) abilityCooldowns[towerName.."_"..abilityName] = tick() end
    local function hasAbilityBeenUnlocked(towerName, abilityName, towerLevel)
        local d = getAbilityData(towerName, abilityName)
        return d and towerLevel >= d.requiredLevel
    end
    local function bossExists()
        local ok, res = pcall(function()
            local enemies = workspace:FindFirstChild("Enemies") if not enemies then return false end
            return enemies:FindFirstChild("Boss") ~= nil
        end)
        return ok and res
    end
    local function bossReadyForAbilities()
        if bossExists() then
            if not generalBossSpawnTime then generalBossSpawnTime = tick() end
            return (tick() - generalBossSpawnTime) >= 1
        else
            generalBossSpawnTime = nil
            return false
        end
    end
    local function checkBossSpawnTime()
        if bossExists() then
            if not bossSpawnTime then bossSpawnTime = tick() end
            return (tick() - bossSpawnTime) >= 16
        else
            bossSpawnTime = nil
            return false
        end
    end
    local function getBossPosition()
        local ok,res = pcall(function()
            local enemies = workspace:FindFirstChild("Enemies") if not enemies then return nil end
            local boss = enemies:FindFirstChild("Boss") if not boss then return nil end
            local hrp = boss:FindFirstChild("HumanoidRootPart") if hrp then return hrp.Position end
            return nil
        end)
        return ok and res or nil
    end
    local function getTowerPosition(tower)
        if not tower then return nil end
        local ok,res = pcall(function() local hrp = tower:FindFirstChild("HumanoidRootPart") if hrp then return hrp.Position end return nil end)
        return ok and res or nil
    end
    local function getTowerRange(tower)
        if not tower then return 0 end
        local ok,res = pcall(function() local stats = tower:FindFirstChild("Stats") if not stats then return 0 end local range = stats:FindFirstChild("Range") if not range then return 0 end return range.Value or 0 end)
        return ok and res or 0
    end
    local function isBossInRange(tower)
        local b = getBossPosition() local t = getTowerPosition(tower)
        if not b or not t then return false end
        local r = getTowerRange(tower) if r <= 0 then return false end
        return (b - t).Magnitude <= r
    end
    local function checkBossInRangeForDuration(tower, requiredDuration)
        if not tower then return false end
        local name = tower.Name
        local currentTime = tick()
        if isBossInRange(tower) then
            if requiredDuration == 0 then return true end
            if not bossInRangeTracker[name] then bossInRangeTracker[name] = currentTime return false else return (currentTime - bossInRangeTracker[name]) >= requiredDuration end
        else
            bossInRangeTracker[name] = nil
        end
        return false
    end

    while true do
        task.wait(1)
        if getgenv().AutoAbilitiesEnabled then
            pcall(function()
                local currentWave = getCurrentWave()
                local hasBoss = bossExists()
                if currentWave < lastWave then resetRoundTrackers() end
                if getgenv().SeamlessLimiterEnabled and lastWave >= 50 and currentWave < 50 then resetRoundTrackers() end
                lastWave = currentWave
                if not Towers then return end
                for unitName, abilitiesConfig in pairs(getgenv().UnitAbilities) do
                    local tower = Towers:FindFirstChild(unitName)
                    if tower then
                    local infoName = getTowerInfoName(tower)
                    local towerLevel = getUpgradeLevel(tower)
                    for abilityName, cfg in pairs(abilitiesConfig) do
                        if cfg.enabled then
                            local shouldUse = true
                            if not hasAbilityBeenUnlocked(infoName, abilityName, towerLevel) then shouldUse=false end
                            if shouldUse and isOnCooldown(infoName, abilityName) then shouldUse=false end
                            if shouldUse and cfg.onlyOnBoss then if not hasBoss or not bossReadyForAbilities() then shouldUse=false end end
                            if shouldUse and cfg.useOnWave and cfg.specificWave then if currentWave ~= cfg.specificWave then shouldUse=false end end
                            if shouldUse and cfg.requireBossInRange then if not hasBoss or not checkBossInRangeForDuration(tower,0) then shouldUse=false end end
                            if shouldUse and cfg.delayAfterBossSpawn then if not hasBoss or not checkBossSpawnTime() then shouldUse=false end end
                            if shouldUse then useAbility(tower, abilityName) setAbilityUsed(infoName, abilityName) end
                        end
                    end
                end
                end
            end)
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    local function getAvailableCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame or not frame:FindFirstChild("Frame") then return nil end
            local cards, cardButtons = {}, {}
            local descendants = frame:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                    local text = d.Text
                    if getgenv().CardPriority[text] then
                        local button = d.Parent.Parent
                        if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then 
                            table.insert(cardButtons, {text=text, button=button}) 
                        end
                    end
                end
            end
            descendants = nil
            table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
            for i, c in ipairs(cardButtons) do cards[i] = { name=c.text, button=c.button } end
            cardButtons = nil
            return #cards > 0 and cards or nil
        end)
        return ok and result or nil
    end
    local function findBestCard(list)
        local bestIndex, bestPriority = 1, math.huge
        for i=1,#list do local nm = list[i].name local p = getgenv().CardPriority[nm] or 999 if p < bestPriority then bestPriority=p bestIndex=i end end
        return bestIndex, list[bestIndex], bestPriority
    end
    local function pressConfirm()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame then return nil end
            local inner = frame:FindFirstChild("Frame") if not inner then return nil end
            local children = inner:GetChildren() if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton") if not button then return nil end
            local label = button:FindFirstChild("TextLabel") if label and label.Text == "Confirm" then return button end
            return nil
        end)
        if ok and confirmButton then
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do pcall(function() for _, conn in ipairs(getconnections(confirmButton[ev])) do conn:Fire() end end) end
            return true
        end
        return false
    end
    local function selectCard()
        if not getgenv().CardSelectionEnabled then return false end
        local ok = pcall(function()
            local list = getAvailableCards() if not list then return false end
            local _, best = findBestCard(list)
            if not best or not best.button then return false end
            local button = best.button
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do pcall(function() for _, conn in ipairs(getconnections(button[ev])) do conn:Fire() end end) end
            task.wait(0.2)
            pressConfirm()
        end)
        return ok
    end
    local function selectCardSlower()
        if not getgenv().SlowerCardSelectionEnabled then return false end
        local ok = pcall(function()
            local list = getAvailableCards() if not list then return false end
            local _, best = findBestCard(list)
            if not best or not best.button then return false end
            local button = best.button
            
            local GuiService = game:GetService("GuiService")
            local function press(key)
                VIM:SendKeyEvent(true, key, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, key, false, game)
            end
            
            GuiService.SelectedObject = button
            task.wait(0.2)
            press(Enum.KeyCode.Return)
            task.wait(0.3)
            
            local ok2, confirmButton = pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt") if not prompt then return nil end
                local frame = prompt:FindFirstChild("Frame") if not frame then return nil end
                local inner = frame:FindFirstChild("Frame") if not inner then return nil end
                local children = inner:GetChildren() if #children < 5 then return nil end
                local button = children[5]:FindFirstChild("TextButton") if not button then return nil end
                local label = button:FindFirstChild("TextLabel") if label and label.Text == "Confirm" then return button end
                return nil
            end)
            
            if ok2 and confirmButton then
                GuiService.SelectedObject = confirmButton
                task.wait(0.2)
                press(Enum.KeyCode.Return)
                task.wait(0.3)
            end
            
            GuiService.SelectedObject = nil
        end)
        return ok
    end
    while true do 
        task.wait(1)
        if getgenv().CardSelectionEnabled then 
            selectCard() 
        elseif getgenv().SlowerCardSelectionEnabled then 
            selectCardSlower() 
        end 
        if isUnloaded then break end 
    end
end)

task.spawn(function()
    local function getBossRushCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame or not frame:FindFirstChild("Frame") then return nil end
            local cards, cardButtons = {}, {}
            local descendants = frame:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                    local text = d.Text
                    if getgenv().BossRushCardPriority[text] then
                        local button = d.Parent.Parent
                        if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then 
                            table.insert(cardButtons, {text=text, button=button}) 
                        end
                    end
                end
            end
            descendants = nil
            table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
            for i, c in ipairs(cardButtons) do cards[i] = { name=c.text, button=c.button } end
            cardButtons = nil
            return #cards > 0 and cards or nil
        end)
        return ok and result or nil
    end
    local function best(list)
        local idx, bestPriority = 1, math.huge
        for i=1,#list do local nm=list[i].name local p=getgenv().BossRushCardPriority[nm] or 999 if p<bestPriority then bestPriority=p idx=i end end
        return idx, list[idx], bestPriority
    end
    local function confirm()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame then return nil end
            local inner = frame:FindFirstChild("Frame") if not inner then return nil end
            local children = inner:GetChildren() if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton") if not button then return nil end
            local label = button:FindFirstChild("TextLabel") if label and label.Text == "Confirm" then return button end
            return nil
        end)
        if ok and confirmButton then
            local events={"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _,ev in ipairs(events) do pcall(function() for _,conn in ipairs(getconnections(confirmButton[ev])) do conn:Fire() end end) end
            return true
        end
        return false
    end
    local function select()
        if not getgenv().BossRushEnabled then return false end
        local ok = pcall(function()
            local list = getBossRushCards() if not list then return false end
            local _, bc, pri = best(list)
            if pri >= 999 then return false end
            if not bc or not bc.button then return false end
            local events={"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _,ev in ipairs(events) do pcall(function() for _,conn in ipairs(getconnections(bc.button[ev])) do conn:Fire() end end) end
            task.wait(0.2)
            confirm()
        end)
        return ok
    end
    while true do 
        task.wait(1)
        if getgenv().BossRushEnabled then 
            select() 
        end 
        if isUnloaded then break end 
    end
end)

task.spawn(function()
    local hasRun = 0
    local isProcessing = false
    local function formatNumber(num)
        if not num or num == 0 then return "0" end
        local s = tostring(num) local k
        while true do s,k = string.gsub(s, "^(-?%d+)(%d%d%d)", '%1,%2') if k==0 then break end end
        return s
    end
    local function SendMessageEMBED(url, embed)
        local headers = { ["Content-Type"] = "application/json" }
        local data = { embeds = { { title=embed.title, description=embed.description, color=embed.color, fields=embed.fields, footer=embed.footer, timestamp=os.date("!%Y-%m-%dT%H:%M:%S.000Z") } } }
        local body = HttpService:JSONEncode(data)
        request({ Url=url, Method="POST", Headers=headers, Body=body })
    end
    local function getRewards()
        local rewards = {}
        local ok, res = pcall(function()
            local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if not ui then 
                print("[Webhook] No EndGameUI found")
                return {} 
            end
            
            local holder = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Rewards") and ui.BG.Container.Rewards:FindFirstChild("Holder")
            
            if not holder then 
                print("[Webhook] Could not find Holder path")
                return {} 
            end
            
            print("[Webhook] Found Holder, waiting for reward buttons to load...")
            
            local waitTime = 0
            local lastCount = 0
            local stableCount = 0
            
            repeat
                task.wait(0.2)
                waitTime = waitTime + 0.2
                
                local children = holder:GetChildren()
                local currentCount = 0
                for i = 1, #children do
                    if children[i]:IsA("TextButton") then
                        currentCount = currentCount + 1
                    end
                end
                
                if currentCount == lastCount and currentCount > 0 then
                    stableCount = stableCount + 1
                else
                    stableCount = 0
                end
                
                lastCount = currentCount
                print("[Webhook] TextButtons found:", currentCount, "Stable for:", stableCount * 0.2, "s")
                
            until (stableCount >= 3 and currentCount > 0) or waitTime > 3
            
            print("[Webhook] Finished waiting after", waitTime, "s. Total TextButtons:", lastCount)
            
            print("[Webhook] Scanning all children...")
            
            local children = holder:GetChildren()
            print("[Webhook] Total children in Holder:", #children)
            
            for _, item in pairs(children) do
                print("[Webhook] Child:", item.Name, "Type:", item.ClassName)
                
                if item:IsA("TextButton") then
                    print("[Webhook] -> Is TextButton, checking for reward data...")
                    
                    local rewardName = nil
                    local rewardAmount = nil
                    
                    local unitName = item:FindFirstChild("UnitName")
                    if unitName then
                        print("[Webhook] -> Found UnitName, Text:", unitName.Text or "nil")
                        if unitName.Text and unitName.Text ~= "" then
                            rewardName = unitName.Text
                            print("[Webhook] -> Set rewardName to:", rewardName)
                        end
                    end
                    
                    local itemName = item:FindFirstChild("ItemName")
                    if itemName then
                        print("[Webhook] -> Found ItemName, Text:", itemName.Text or "nil")
                        if itemName.Text and itemName.Text ~= "" then
                            rewardName = itemName.Text
                            print("[Webhook] -> Set rewardName to:", rewardName)
                        end
                    end
                    
                    if rewardName then
                        local amountLabel = item:FindFirstChild("Amount")
                        if amountLabel then
                            print("[Webhook] -> Found Amount, Text:", amountLabel.Text or "nil")
                            if amountLabel.Text then
                                local amountText = amountLabel.Text
                                local clean = string.gsub(string.gsub(string.gsub(amountText, "x", ""), "+", ""), ",", "")
                                rewardAmount = tonumber(clean)
                                print("[Webhook] -> Parsed amount:", rewardAmount)
                            end
                        else
                            print("[Webhook] -> No Amount label found, defaulting to 1 (unit reward)")
                            rewardAmount = 1
                        end
                        
                        if rewardAmount then
                            table.insert(rewards, { name = rewardName, amount = rewardAmount })
                            print("[Webhook] ✓ Added reward:", rewardName, "x" .. rewardAmount)
                        else
                            print("[Webhook] ✗ Skipped (no valid amount):", rewardName)
                        end
                    else
                        print("[Webhook] -> No UnitName or ItemName found")
                    end
                end
            end
            print("[Webhook] === SCAN COMPLETE === Total rewards found:", #rewards)
            return rewards
        end)
        
        if not ok then
            warn("[Webhook] Error in getRewards:", res)
        end
        
        return ok and res or {}
    end
    local function getMatchResult()
        local ok, time, wave, result = pcall(function()
            local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if not ui then 
                print("[Webhook] getMatchResult: No EndGameUI")
                return "00:00:00","0","Unknown" 
            end
            
            local stats = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Stats")
            if not stats then
                print("[Webhook] getMatchResult: No Stats found")
                return "00:00:00", "0", "Unknown"
            end
            
            local resultText = stats:FindFirstChild("Result")
            local timeText = stats:FindFirstChild("ElapsedTime")
            local waveText = stats:FindFirstChild("EndWave")
            
            local r = resultText and resultText.Text or "Unknown"
            local t = timeText and timeText.Text or "00:00:00"
            local w = waveText and waveText.Text or "0"
            
            print("[Webhook] Raw stats - Result:", r, "Time:", t, "Wave:", w)
            
            if t:find("Total Time:") then 
                local m,s = t:match("Total Time:%s*(%d+):(%d+)") 
                if m and s then 
                    t = string.format("%02d:%02d:%02d", 0, tonumber(m) or 0, tonumber(s) or 0) 
                end 
            end
            
            if w:find("Wave Reached:") then 
                local wm = w:match("Wave Reached:%s*(%d+)") 
                if wm then w = wm end 
            end
            
            if r:lower():find("win") or r:lower():find("victory") then 
                r = "VICTORY" 
            elseif r:lower():find("defeat") or r:lower():find("lose") or r:lower():find("loss") then 
                r = "DEFEAT" 
            end
            
            print("[Webhook] Parsed stats - Result:", r, "Time:", t, "Wave:", w)
            return t, w, r
        end)
        
        if ok then 
            return time, wave, result 
        else 
            warn("[Webhook] Error in getMatchResult:", time)
            return "00:00:00","0","Unknown" 
        end
    end
    local function getMapInfo()
        local ok, name, difficulty = pcall(function()
            local map = workspace:FindFirstChild("Map") if not map then return "Unknown Map","Unknown" end
            local mapName = map:FindFirstChild("MapName")
            local mapDifficulty = map:FindFirstChild("MapDifficulty")
            return mapName and mapName.Value or "Unknown Map", mapDifficulty and mapDifficulty.Value or "Unknown"
        end)
        if ok then return name, difficulty else return "Unknown Map","Unknown" end
    end
    local lastWebhookHash = ""
    local function sendWebhook()
        pcall(function()
            if not getgenv().WebhookEnabled then 
                print("[Webhook] Webhook disabled, skipping")
                return 
            end
            
            if isProcessing then 
                print("[Webhook] Already processing, skipping duplicate")
                return 
            end
            
            if getgenv()._webhookLock and (tick() - getgenv()._webhookLock) < 10 then 
                print("[Webhook] Lock active, skipping duplicate (last sent:", tick() - getgenv()._webhookLock, "seconds ago)")
                return 
            end
            
            print("[Webhook] Starting webhook process...")
            getgenv()._webhookLock = tick()
            isProcessing = true
            hasRun = tick()
            
            print("[Webhook] Capturing rewards...")
            local rewards = getRewards()
            print("[Webhook] Rewards captured:", #rewards)
            
            local matchTime, matchWave, matchResult = getMatchResult()
            print("[Webhook] Match result:", matchTime, matchWave, matchResult)
            
            local mapName, mapDifficulty = getMapInfo()
            print("[Webhook] Map info:", mapName, mapDifficulty)
            
            local clientData = getClientData()
            if not clientData then 
                print("[Webhook] Failed to get ClientData")
                isProcessing = false
                return
            end
        local description = "**Username:** ||"..LocalPlayer.Name.."||\n**Level:** "..(clientData.Level or 0).." ["..formatNumber(clientData.EXP or 0).."/"..formatNumber(clientData.MaxEXP or 0).."]"
        local stats = "<:gold:1265957290251522089> "..formatNumber(clientData.Gold or 0)
        stats = stats .. "\n<:jewel:1217525743408648253> " .. formatNumber(clientData.Jewels or 0)
        stats = stats .. "\n<:emerald:1389165843966984192> " .. formatNumber(clientData.Emeralds or 0)
        stats = stats .. "\n<:rerollshard:1426315987019501598> " .. formatNumber(clientData.Rerolls or 0)
        stats = stats .. "\n<:candybasket:1426304615284084827> " .. formatNumber(clientData.CandyBasket or 0)
        local bingoStamps = 0
        if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then bingoStamps = clientData.ItemData.HallowenBingoStamp.Amount or 0 end
        stats = stats .. "\n<:bingostamp:1426362482141954068> " .. formatNumber(bingoStamps)
        local rewardsText = ""
        if #rewards > 0 then
            for _, r in ipairs(rewards) do
                local total = 0
                local itemName = r.name
                
                if clientData[itemName] and type(clientData[itemName]) == "number" then
                    total = clientData[itemName]
                elseif clientData.ItemData and clientData.ItemData[itemName] and clientData.ItemData[itemName].Amount then
                    total = clientData.ItemData[itemName].Amount
                elseif clientData.Items and clientData.Items[itemName] and clientData.Items[itemName].Amount then
                    total = clientData.Items[itemName].Amount
                elseif itemName == "Candy Basket" and clientData.CandyBasket then
                    total = clientData.CandyBasket
                elseif itemName:find("Bingo Stamp") and clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
                    total = clientData.ItemData.HallowenBingoStamp.Amount or 0
                else
                    total = r.amount
                end
                
                rewardsText = rewardsText .. "+"..formatNumber(r.amount).." "..itemName.." [ Total: "..formatNumber(total).." ]\n"
            end
        else 
            rewardsText = "No rewards found" 
        end
        local unitsText = ""
        if clientData.Slots then
            local slots = {"Slot1","Slot2","Slot3","Slot4","Slot5","Slot6"}
            for _,slotName in ipairs(slots) do
                local slot = clientData.Slots[slotName]
                if slot and slot.Value then
                    local level = slot.Level or 0
                    local kills = formatNumber(slot.Kills or 0)
                    local unitName = slot.Value
                    unitsText = unitsText .. "[ "..level.." ] "..unitName.." = "..kills.." ⚔️\n"
                end
            end
        end
        local embed = { title="Anime Last Stand", description=description or "N/A", color=0x00ff00, fields={
            { name="Player Stats", value=(stats ~= "" and stats or "N/A"), inline=true },
            { name="Rewards", value=(rewardsText ~= "" and rewardsText or "No rewards found"), inline=true },
            { name="Units", value=(unitsText ~= "" and unitsText or "No units"), inline=false },
            { name="Match Result", value=(matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. ((mapDifficulty and mapDifficulty ~= "Unknown") and (" ["..mapDifficulty.."]") or "") .. " - " .. (matchResult or "Unknown"), inline=false }
            }, footer={ text="Halloween Hook" } }
            
            local webhookHash = LocalPlayer.Name .. "_" .. matchTime .. "_" .. matchWave .. "_" .. rewardsText
            if webhookHash == lastWebhookHash then
                print("[Webhook] Duplicate detected (same hash), skipping send")
                isProcessing = false
                return
            end
            lastWebhookHash = webhookHash
            
            SendMessageEMBED(getgenv().WebhookURL, embed)
            print("[Webhook] Successfully sent!")
            
            rewards = nil
            clientData = nil
            embed = nil
            collectgarbage("collect")
            
            isProcessing=false
        end)
    end
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child) 
        if child.Name == "EndGameUI" and getgenv().WebhookEnabled then 
            print("[Webhook] EndGameUI detected, capturing data immediately...")
            sendWebhook() 
        end 
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child) 
        if child.Name == "EndGameUI" then 
            task.wait(1)
            isProcessing = false
            
            collectgarbage("collect")
            collectgarbage("collect")
            
            print("[Webhook] EndGameUI removed, ready for next webhook")
        end 
    end)
end)

task.spawn(function()
    if not getgenv().SeamlessLimiterEnabled then return end
    pcall(function()
        local endgameCount = 0
        local hasRun = false
        local lastEndgameTime = 0
        local DEBOUNCE_TIME = 5
        local maxWait = 0
        repeat 
            task.wait(0.5) 
            maxWait = maxWait + 0.5
        until not LocalPlayer.PlayerGui:FindFirstChild("TeleportUI") or maxWait > 30
        print("[Seamless Fix] Waiting for Settings GUI...")
        maxWait = 0
        repeat 
            task.wait(0.5)
            maxWait = maxWait + 0.5
        until LocalPlayer.PlayerGui:FindFirstChild("Settings") or maxWait > 30
        print("[Seamless Fix] Settings GUI found!")
        local function getSeamlessValue()
            local ok, result = pcall(function()
                local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
                if settings then
                    local seamless = settings:FindFirstChild("SeamlessRetry")
                    if seamless then 
                        print("[Seamless Fix] SeamlessRetry.Value =", seamless.Value)
                        return seamless.Value 
                    else
                        print("[Seamless Fix] SeamlessRetry not found in Settings")
                    end
                else
                    print("[Seamless Fix] Settings not found")
                end
                return false
            end)
            return ok and result or false
        end
        local function setSeamlessRetry()
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                if setSettings then
                    setSettings:InvokeServer("SeamlessRetry")
                end
            end)
        end
        print("[Seamless Fix] Checking initial seamless state...")
        local currentSeamless = getSeamlessValue()
        if endgameCount < (getgenv().MaxSeamlessRounds or 4) then
            if not currentSeamless then
                setSeamlessRetry()
                task.wait(0.5)
                print("[Seamless Fix] Enabled Seamless Retry")
            else
                print("[Seamless Fix] Seamless Retry already enabled")
            end
        end
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            pcall(function()
                if child.Name == "EndGameUI" and not hasRun then
                    local currentTime = tick()
                    if currentTime - lastEndgameTime < DEBOUNCE_TIME then
                        print("[Seamless Fix] Debounced duplicate EndGameUI trigger")
                        return
                    end
                    hasRun = true
                    lastEndgameTime = currentTime
                    endgameCount = endgameCount + 1
                    local maxRounds = getgenv().MaxSeamlessRounds or 4
                    print("[Seamless Fix] Endgame detected. Current seamless rounds: " .. endgameCount .. "/" .. maxRounds)
                    if endgameCount >= maxRounds then
                        if getSeamlessValue() then
                            task.wait(0.5)
                            setSeamlessRetry()
                            print("[Seamless Fix] Max rounds reached, disabling seamless retry to restart match...")
                            task.wait(0.5)
                            print("[Seamless Fix] Disabled Seamless Retry")
                        else
                            print("[Seamless Fix] Max rounds reached but seamless already disabled")
                        end
                    end
                end
            end)
        end)
        LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
            if child.Name == "EndGameUI" then
                task.wait(2)
                hasRun = false
            end
        end)
    end)
end)

task.spawn(function()
    if not isInLobby then return end
    task.wait(1)
    
    local BingoEvents = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("Bingo")
    if not BingoEvents then return end
    
    local UseStampEvent = BingoEvents:FindFirstChild("UseStamp")
    local ClaimRewardEvent = BingoEvents:FindFirstChild("ClaimReward")
    local CompleteBoardEvent = BingoEvents:FindFirstChild("CompleteBoard")
    
    print("[Auto Bingo] Bingo automation loaded!")
    
    while true do
        task.wait(0.1)
        if getgenv().BingoEnabled then
            pcall(function()
                if UseStampEvent then
                    for i=1,25 do 
                        UseStampEvent:FireServer()
                    end
                end
                
                if ClaimRewardEvent then
                    for i=1,25 do 
                        ClaimRewardEvent:InvokeServer(i)
                    end
                end
                
                if CompleteBoardEvent then 
                    CompleteBoardEvent:InvokeServer()
                end
            end)
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    if not isInLobby then return end
    task.wait()
    local PurchaseEvent = RS:WaitForChild("Events"):WaitForChild("Hallowen2025"):WaitForChild("Purchase")
    local OpenCapsuleEvent = RS:WaitForChild("Remotes"):WaitForChild("OpenCapsule")
    print("[Auto Capsules] Capsule automation loaded!")
    while true do
        task.wait(0.1)
        if getgenv().CapsuleEnabled then
            local clientData = getClientData()
            if clientData then
                local candyBasket = clientData.CandyBasket or 0
                local capsuleAmount = 0
                if clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then
                    capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0
                end
                
                if candyBasket >= 100000 then 
                    pcall(function() PurchaseEvent:InvokeServer(1, 100) end)
                elseif candyBasket >= 10000 then 
                    pcall(function() PurchaseEvent:InvokeServer(1, 10) end)
                elseif candyBasket >= 1000 then 
                    pcall(function() PurchaseEvent:InvokeServer(1, 1) end)
                end
                
                clientData = getClientData()
                if clientData and clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then 
                    capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0 
                end
                
                if capsuleAmount > 0 then 
                    pcall(function() OpenCapsuleEvent:FireServer("HalloweenCapsule2025", capsuleAmount) end)
                end
            end
        end
        if isUnloaded then break end
    end
end)

if isInLobby then
    task.spawn(function()
        print("=== [Breach Auto-Join] STARTING ===")
        print("[Breach Auto-Join] Initial isInLobby:", isInLobby)
        print("[Breach Auto-Join] Current PlaceId:", game.PlaceId)
        print("[Breach Auto-Join] Valid Lobby PlaceIds:", table.concat(LOBBY_PLACEIDS, ", "))
        print("[Breach Auto-Join] BreachEnabled:", getgenv().BreachEnabled)
        print("[Breach Auto-Join] BreachAutoJoin table:", game:GetService("HttpService"):JSONEncode(getgenv().BreachAutoJoin))
        
        print("[Breach Auto-Join] Breach automation loaded! (Will check lobby status each loop)")
        
        local function getAvailableBreaches()
            local ok, breaches = pcall(function()
                local lobby = workspace:FindFirstChild("Lobby")
                if not lobby then 
                    print("[Breach Auto-Join] ERROR: No Lobby found in workspace")
                    return {} 
                end
                
                local breachesFolder = lobby:FindFirstChild("Breaches")
                if not breachesFolder then 
                    print("[Breach Auto-Join] ERROR: No Breaches folder found in Lobby")
                    return {} 
                end
                
                print("[Breach Auto-Join] Scanning Breaches folder...")
                print("[Breach Auto-Join] Total children in Breaches:", #breachesFolder:GetChildren())
                
                local available = {}
                local scannedCount = 0
                local children = breachesFolder:GetChildren()
                
                for i = 1, #children do
                    local part = children[i]
                    scannedCount = scannedCount + 1
                    
                    local breachPart = part:FindFirstChild("Breach")
                    if breachPart then
                        print("[Breach Auto-Join] Found Breach part in:", part.Name)
                        
                        local proximityPrompt = breachPart:FindFirstChild("ProximityPrompt")
                        if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
                            print("[Breach Auto-Join]   ProximityPrompt found!")
                            print("[Breach Auto-Join]   ObjectText:", proximityPrompt.ObjectText)
                            
                            if proximityPrompt.ObjectText and proximityPrompt.ObjectText ~= "" then
                                local breachName = proximityPrompt.ObjectText
                                available[#available + 1] = { name = breachName, instance = part }
                                print("[Breach Auto-Join]   ✓ Added breach:", breachName)
                            else
                                print("[Breach Auto-Join]   ✗ ObjectText is empty")
                            end
                        else
                            print("[Breach Auto-Join]   ✗ No ProximityPrompt found in Breach part")
                        end
                    end
                end
                
                print("[Breach Auto-Join] Scanned", scannedCount, "parts, found", #available, "breaches")
                children = nil
                return available
            end)
            
            if not ok then
                warn("[Breach Auto-Join] ERROR in getAvailableBreaches:", breaches)
                return {}
            end
            
            return breaches or {}
        end
        
        local loopCount = 0
        while true do
            task.wait(1)
            loopCount = loopCount + 1
            
            local currentlyInLobby = checkIsInLobby()
            
            if getgenv().BreachEnabled then
                local availableBreaches = getAvailableBreaches()
                
                print("[Breach Auto-Join] Available breaches:", #availableBreaches)
                
                for _, breach in ipairs(availableBreaches) do
                    local shouldJoin = getgenv().BreachAutoJoin[breach.name]
                    print("[Breach Auto-Join] Breach:", breach.name)
                    print("[Breach Auto-Join]   Should join:", shouldJoin)
                    print("[Breach Auto-Join]   Instance:", breach.instance:GetFullName())
                    
                    if shouldJoin then
                        print("[Breach Auto-Join]   Attempting to join...")
                        
                        local success, err = pcall(function()
                            local remote = RS.Remotes.Breach.EnterEvent
                            print("[Breach Auto-Join]   Remote:", remote:GetFullName())
                            print("[Breach Auto-Join]   Firing with:", breach.instance)
                            
                            remote:FireServer(breach.instance)
                            print("[Breach Auto-Join]   ✓✓✓ SUCCESSFULLY FIRED REMOTE ✓✓✓")
                        end)
                        
                        if not success then
                            warn("[Breach Auto-Join]   ✗✗✗ FAILED:", err)
                        end
                        
                        task.wait(0.5)
                    else
                        print("[Breach Auto-Join]   Skipping (not enabled)")
                    end
                end
            end

        end
    end)
end

if isInLobby then
    task.spawn(function()
        print("[Auto Join] Auto Join system loaded!")
        
        while true do
            task.wait(2)
            
            if getgenv().AutoJoinConfig and getgenv().AutoJoinConfig.enabled then
                pcall(function()
                    local mode = getgenv().AutoJoinConfig.mode
                    local map = getgenv().AutoJoinConfig.map
                    local act = getgenv().AutoJoinConfig.act
                    local difficulty = getgenv().AutoJoinConfig.difficulty
                    
                    if not map or map == "" then return end
                    
                    local teleporterRemote = RS.Remotes.Teleporter.InteractEvent
                    
                    if mode == "Story" then
                        teleporterRemote:FireServer("Select", map, act, difficulty, "Story")
                        print("[Auto Join] Joined Story:", map, "Act", act, difficulty)
                        
                    elseif mode == "Infinite" then
                        teleporterRemote:FireServer("Select", map, act, difficulty, "Infinite")
                        print("[Auto Join] Joined Infinite:", map, "Act", act, difficulty)
                        
                    elseif mode == "Raids" then
                        teleporterRemote:FireServer("Select", map, act)
                        print("[Auto Join] Joined Raid:", map, "Act", act)
                        
                    elseif mode == "Dungeon" then
                        teleporterRemote:FireServer("Select", map)
                        print("[Auto Join] Joined Dungeon:", map)
                        
                    elseif mode == "Survival" then
                        teleporterRemote:FireServer("Select", map)
                        print("[Auto Join] Joined Survival:", map)
                        
                    elseif mode == "ElementalCaverns" then
                        teleporterRemote:FireServer("Select", map, difficulty)
                        print("[Auto Join] Joined Elemental Cavern:", map, difficulty)
                        
                    elseif mode == "Challenge" then
                        teleporterRemote:FireServer("Select", "Challenge", act)
                        print("[Auto Join] Joined Challenge Act", act)
                        
                    elseif mode == "LegendaryStages" then
                        teleporterRemote:FireServer("Select", map, act, difficulty, "LegendaryStages")
                        print("[Auto Join] Joined Legendary Stage:", map, "Act", act, difficulty)
                    end
                    
                    task.wait(1)
                end)
            end
            
            if getgenv().AutoJoinConfig and getgenv().AutoJoinConfig.autoStart then
                pcall(function()
                    local bottomGui = LocalPlayer.PlayerGui:FindFirstChild("Bottom")
                    if bottomGui then
                        local frame = bottomGui:FindFirstChild("Frame")
                        if frame then
                            local children = frame:GetChildren()
                            if children[2] then
                                local subChildren = children[2]:GetChildren()
                                if subChildren[6] then
                                    local textButton = subChildren[6]:FindFirstChild("TextButton")
                                    if textButton then
                                        local textLabel = textButton:FindFirstChild("TextLabel")
                                        if textLabel and textLabel.Text == "Start" then
                                            local remotes = RS:FindFirstChild("Remotes")
                                            local playerReady = remotes and remotes:FindFirstChild("PlayerReady")
                                            if playerReady then
                                                playerReady:FireServer()
                                                print("[Auto Join] Auto Start fired")
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end
SaveManager:LoadAutoloadConfig()
