repeat task.wait() until game:IsLoaded()

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

if not MacLib then
    error("[ALS] Failed to load MacLib library")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")

local isMobile = UserInputService.TouchEnabled
local MOBILE_DELAY_MULTIPLIER = isMobile and 1.5 or 1.0

local Window = MacLib:Window({
    Title = "Byorl Last Stand",
    Subtitle = "Anime Last Stand Automation",
    Size = isMobile and UDim2.fromOffset(580, 480) or UDim2.fromOffset(868, 650),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})

if not Window then
    error("[ALS] Failed to create Window")
    return
end

task.wait(2)

local function isTeleportUIVisible()
    local tpUI = LocalPlayer.PlayerGui:FindFirstChild("TeleportUI")
    if not tpUI then return false end
    
    local ok, visible = pcall(function()
        return tpUI.Enabled
    end)
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

getgenv()._AbilityUIBuilt = false
getgenv()._AbilityUIBuilding = false

local function shouldFilterMessage(msg)
    local msgLower = msg:lower()
    
    if msgLower:find("playermodule") 
        or msgLower:find("cameramodule") 
        or msgLower:find("zoomcontroller")
        or msgLower:find("popper")
        or msgLower:find("poppercam")
        or msgLower:find("imagelabel")
        or msgLower:find("not a valid member")
        or msgLower:find("is not a valid member")
        or msgLower:find("attempt to perform arithmetic")
        or msgLower:find("playerscripts")
        or msgLower:find("byorials")
        or msgLower:find("stack begin")
        or msgLower:find("stack end")
        or msgLower:find("runservice")
        or msgLower:find("firerenderstepearlyfunctions")
        or msgLower:find("firerenderstep")
        or msgLower:find("metamethod")
        or msgLower:find("__namecall")
        or msgLower:find("unexpected error while invoking callback")
        or msgLower:find("frogionsol") then
        return true
    end
    
    return false
end

local oldLogWarn = logwarn or warn
local oldLogError = logerror or error

local function createFilteredLogger(originalLogger)
    return function(...)
        local args = {...}
        local msg = ""
        for i, v in ipairs(args) do
            msg = msg .. tostring(v)
        end
        if not shouldFilterMessage(msg) then
            originalLogger(...)
        end
    end
end

if logwarn then logwarn = createFilteredLogger(oldLogWarn) end
warn = createFilteredLogger(oldLogWarn)
if logerror then logerror = createFilteredLogger(oldLogError) end

local oldErrorHandler = geterrorhandler and geterrorhandler()
if seterrorhandler then
    seterrorhandler(function(msg)
        if not shouldFilterMessage(tostring(msg)) then
            if oldErrorHandler then
                oldErrorHandler(msg)
            else
                oldLogError(msg)
            end
        end
    end)
end

local function cleanupBeforeTeleport()    
    pcall(function()
        if Window and Window.Unload then
            Window:Unload()
        end
    end)
    
    pcall(function()
        getgenv().AutoAbilitiesEnabled = nil
        getgenv().CardSelectionEnabled = nil
        getgenv().SlowerCardSelectionEnabled = nil
    end)
    
    pcall(function()
        if getconnections then
            for _, service in pairs({RunService.Heartbeat, RunService.RenderStepped, RunService.Stepped}) do
                for _, connection in pairs(getconnections(service)) do
                    if connection.Disable then connection:Disable() end
                    if connection.Disconnect then connection:Disconnect() end
                end
            end
        end
    end)
    
    pcall(function()
        collectgarbage("collect")
    end)
    
    task.wait(0.2)
end

getgenv().CleanupBeforeTeleport = cleanupBeforeTeleport



local CONFIG_FOLDER = "ALSHalloweenEvent"
local CONFIG_FILE = "config.json"
local USER_ID = tostring(LocalPlayer.UserId)

local function getConfigPath()
    return CONFIG_FOLDER .. "/" .. USER_ID .. "/" .. CONFIG_FILE
end

local function getUserFolder()
    return CONFIG_FOLDER .. "/" .. USER_ID
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    local userFolder = getUserFolder()
    if not isfolder(userFolder) then makefolder(userFolder) end
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
            data.autoJoin = data.autoJoin or {}
            return data
        end
    end
    return { toggles = {}, inputs = {}, dropdowns = {}, abilities = {}, autoJoin = {} }
end

local function saveConfig(config)
    local userFolder = getUserFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    if not isfolder(userFolder) then makefolder(userFolder) end
    local ok, err = pcall(function()
        local json = HttpService:JSONEncode(config)
        writefile(getConfigPath(), json)
    end)
    if not ok then warn("[Config] Save failed: " .. tostring(err)) end
    return ok
end

getgenv().Config = loadConfig()
getgenv().Config.toggles = getgenv().Config.toggles or {}
getgenv().Config.inputs = getgenv().Config.inputs or {}
getgenv().Config.dropdowns = getgenv().Config.dropdowns or {}
getgenv().Config.abilities = getgenv().Config.abilities or {}
getgenv().Config.autoJoin = getgenv().Config.autoJoin or {}

getgenv().SaveConfig = saveConfig
getgenv().LoadConfig = loadConfig

MacLib:SetFolder("ALSHalloweenEvent")



local TabGroup1 = Window:TabGroup()

local TabGroup2 = Window:TabGroup()

local TabGroup3 = Window:TabGroup()

local Tabs = {
    Main = TabGroup1:Tab({ 
        Name = "Main", 
        Image = "rbxassetid://10734950309" 
    }),
    Macro = TabGroup1:Tab({ 
        Name = "Macro", 
        Image = "rbxassetid://10734923549" 
    }),
    Abilities = TabGroup1:Tab({ 
        Name = "Abilities", 
        Image = "rbxassetid://10747373176" 
    }),
    Portals = TabGroup1:Tab({ 
        Name = "Portals", 
        Image = "rbxassetid://10723407389" 
    }),
    
    Event = TabGroup2:Tab({ 
        Name = "Event", 
        Image = "rbxassetid://10734952273" 
    }),
    BossRush = TabGroup2:Tab({ 
        Name = "Boss Rush", 
        Image = "rbxassetid://10734923549" 
    }),
    Breach = TabGroup2:Tab({ 
        Name = "Breach", 
        Image = "rbxassetid://10747374131" 
    }),
    FinalExpedition = TabGroup2:Tab({ 
        Name = "Final Expedition", 
        Image = "rbxassetid://10723407389" 
    }),
    
    Webhook = TabGroup3:Tab({ 
        Name = "Webhook", 
        Image = "rbxassetid://10734952273" 
    }),
    SeamlessFix = TabGroup3:Tab({ 
        Name = "Seamless Fix", 
        Image = "rbxassetid://10734923549" 
    }),
    Misc = TabGroup3:Tab({ 
        Name = "Misc", 
        Image = "rbxassetid://10734949856" 
    }),
    Settings = TabGroup3:Tab({ 
        Name = "Settings", 
        Image = "rbxassetid://10734949856" 
    })
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

local Sections = {
    MainLeft = Tabs.Main:Section({ Side = "Left" }),
    MainRight = Tabs.Main:Section({ Side = "Right" }),
    
    MacroLeft = Tabs.Macro:Section({ Side = "Left" }),
    MacroRight = Tabs.Macro:Section({ Side = "Right" }),
    
    PortalsLeft = Tabs.Portals:Section({ Side = "Left" }),
    PortalsRight = Tabs.Portals:Section({ Side = "Right" }),
    
    BossRushLeft = Tabs.BossRush:Section({ Side = "Left" }),
    BossRushRight = Tabs.BossRush:Section({ Side = "Right" }),
    
    BreachLeft = Tabs.Breach:Section({ Side = "Left" }),
    BreachRight = Tabs.Breach:Section({ Side = "Right" }),
    
    FinalExpeditionLeft = Tabs.FinalExpedition:Section({ Side = "Left" }),
    FinalExpeditionRight = Tabs.FinalExpedition:Section({ Side = "Right" }),
    
    EventLeft = Tabs.Event:Section({ Side = "Left" }),
    EventRight = Tabs.Event:Section({ Side = "Right" }),
    
    WebhookLeft = Tabs.Webhook:Section({ Side = "Left" }),
    
    SeamlessFixLeft = Tabs.SeamlessFix:Section({ Side = "Left" }),
    
    MiscLeft = Tabs.Misc:Section({ Side = "Left" }),
    MiscRight = Tabs.Misc:Section({ Side = "Right" }),
    
    SettingsLeft = Tabs.Settings:Section({ Side = "Left" }),
    SettingsRight = Tabs.Settings:Section({ Side = "Right" })
}

Tabs.Main:Select()


local function createToggle(section, name, flag, callback, default)
    name = tostring(name or "Toggle")
    default = default or false
    local savedValue = getgenv().Config.toggles[flag]
    if savedValue == nil then
        savedValue = default
    end
    
    return section:Toggle({
        Name = name,
        Default = savedValue,
        Callback = function(value)
            getgenv().Config.toggles[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createInput(section, name, flag, placeholder, charType, callback, default)
    name = tostring(name or "Input")
    placeholder = placeholder or ""
    charType = charType or "All"
    default = default or ""
    
    local savedValue = getgenv().Config.inputs[flag]
    if savedValue == nil then
        savedValue = default
    end
    
    local inputElement = section:Input({
        Name = name,
        Placeholder = placeholder,
        AcceptedCharacters = charType,
        Callback = function(value)
            getgenv().Config.inputs[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
    
    if savedValue and savedValue ~= "" then
        pcall(function()
            inputElement:UpdateText(tostring(savedValue))
        end)
    end
    
    return inputElement
end

local function createDropdown(section, name, flag, options, multi, callback, default)
    name = tostring(name or "Dropdown")
    options = options or {}
    multi = multi or false
    default = default or (multi and {} or 1)
    
    local savedValue = getgenv().Config.dropdowns[flag]
    if savedValue == nil then
        savedValue = default
    end
    
    
    local defaultValue = savedValue
    if multi and type(savedValue) == "table" then
        local isDictionary = false
        for k, v in pairs(savedValue) do
            if type(v) == "boolean" then
                isDictionary = true
                break
            end
        end
        
        if isDictionary then
            defaultValue = {}
            for optionName, isSelected in pairs(savedValue) do
                if isSelected == true then
                    table.insert(defaultValue, optionName)
                end
            end
        end
    elseif not multi and type(savedValue) == "string" then
        defaultValue = 1
        for i, option in ipairs(options) do
            if option == savedValue then
                defaultValue = i
                break
            end
        end
    elseif not multi and type(savedValue) == "number" then
        defaultValue = savedValue
    end
    
    
    return section:Dropdown({
        Name = name,
        Options = options,
        Multi = multi,
        Required = false,
        Default = defaultValue,
        Callback = function(value)
            getgenv().Config.dropdowns[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createSlider(section, name, flag, minimum, maximum, default, callback, displayMethod)
    name = tostring(name or "Slider")
    minimum = minimum or 0
    maximum = maximum or 100
    default = default or minimum
    displayMethod = displayMethod or "Default"
    
    local savedValue = getgenv().Config.inputs[flag]
    if savedValue ~= nil then
        savedValue = tonumber(savedValue)
        if savedValue then
            default = savedValue
        end
    end
    
    return section:Slider({
        Name = name,
        Minimum = minimum,
        Maximum = maximum,
        Default = default,
        DisplayMethod = displayMethod,
        Callback = function(value)
            getgenv().Config.inputs[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createMutuallyExclusiveToggle(section, name, flag, otherToggle, otherFlag, callback, default)
    local toggle = createToggle(
        section,
        name,
        flag,
        function(value)
            if callback then callback(value) end
            
            if value and otherToggle then
                getgenv().Config.toggles[otherFlag] = false
                saveConfig(getgenv().Config)
                pcall(function()
                    otherToggle:UpdateState(false)
                end)
            end
        end,
        default
    )
    return toggle
end

local function createCardPriorityInputs(section, cardTable, targetPriorityTable, keyPrefix)
    if not cardTable or type(cardTable) ~= "table" then return end
    keyPrefix = keyPrefix or "Card_"
    
    local cardNames = {}
    for name in pairs(cardTable) do
        if name and name ~= "" then
            table.insert(cardNames, name)
        end
    end
    table.sort(cardNames, function(a, b)
        return (cardTable[a] or 999) < (cardTable[b] or 999)
    end)
    
    for _, cardName in ipairs(cardNames) do
        if cardName and cardName ~= "" then
            local configKey = keyPrefix .. tostring(cardName)
            local defaultValue = getgenv().Config.inputs[configKey] or tostring(cardTable[cardName] or 999)
            
            createInput(
                section,
                tostring(cardName),
                configKey,
                "Priority (1-999)",
                "Numeric",
                function(value)
                    local num = tonumber(value)
                    if num then
                        targetPriorityTable[cardName] = num
                    end
                end,
                tostring(defaultValue)
            )
            
            targetPriorityTable[cardName] = tonumber(defaultValue) or cardTable[cardName] or 999
        end
    end
end

getgenv().CreateToggle = createToggle
getgenv().CreateInput = createInput
getgenv().CreateDropdown = createDropdown
getgenv().CreateSlider = createSlider
getgenv().CreateMutuallyExclusiveToggle = createMutuallyExclusiveToggle


local MACRO_FOLDER = CONFIG_FOLDER .. "/macros"
local SETTINGS_FILE = MACRO_FOLDER .. "/settings.json"

if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

getgenv().Macros = {}
getgenv().MacroMaps = {}

local function loadMacroSettings()
    local settings = {
        playMacroEnabled = false,
        selectedMacro = nil,
        macroMaps = {},
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

local function saveMacroSettings()
    pcall(function()
        local settings = {
            playMacroEnabled = getgenv().MacroPlayEnabled or false,
            selectedMacro = getgenv().CurrentMacro,
            macroMaps = getgenv().MacroMaps or {},
            stepDelay = getgenv().MacroStepDelay or 0
        }
        writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
    end)
end

local function loadMacros()
    getgenv().Macros = {}
    if not isfolder(MACRO_FOLDER) then return end
    local files = listfiles(MACRO_FOLDER)
    if not files then return end
    for _, file in pairs(files) do
        if file:sub(-5) == ".json" then
            local fileName = file:match("([^/\\]+)%.json$")
            
            if fileName ~= "settings" and fileName ~= "playback_state" then
                local ok, data = pcall(function() 
                    return HttpService:JSONDecode(readfile(file)) 
                end)
                if ok and type(data) == "table" then
                    local isSettings = (data.playMacroEnabled ~= nil or data.selectedMacro ~= nil or data.macroMaps ~= nil)
                    if not isSettings then
                        getgenv().Macros[fileName] = data
                    end
                end
            end
        end
    end
end

local function saveMacro(name, data)
    local success, err = pcall(function()
        writefile(MACRO_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        getgenv().Macros[name] = data
    end)
    if not success then
        warn("[Macro] Failed to save:", err)
    end
    return success
end

local function getMacroNames()
    local names = {}
    for name in pairs(getgenv().Macros) do 
        table.insert(names, name) 
    end
    table.sort(names)
    return names
end

local savedMacroSettings = loadMacroSettings()
getgenv().MacroMaps = savedMacroSettings.macroMaps or {}
getgenv().MacroStepDelay = savedMacroSettings.stepDelay or 0
getgenv().CurrentMacro = savedMacroSettings.selectedMacro

getgenv().MacroPlayEnabled = getgenv().Config.toggles.MacroPlayToggle or false

loadMacros()

getgenv().LoadMacroSettings = loadMacroSettings
getgenv().SaveMacroSettings = saveMacroSettings
getgenv().LoadMacros = loadMacros
getgenv().SaveMacro = saveMacro
getgenv().GetMacroNames = getMacroNames

getgenv().MacroStatusText = "Idle"
getgenv().MacroActionText = ""
getgenv().MacroUnitText = ""
getgenv().MacroWaitingText = ""
getgenv().MacroCurrentStep = 0
getgenv().MacroTotalSteps = 0
getgenv().MacroLastStatusUpdate = 0

getgenv().UpdateMacroStatus = function()
    local now = tick()
    if now - getgenv().MacroLastStatusUpdate < 0.033 then 
        return 
    end
    getgenv().MacroLastStatusUpdate = now
    
    pcall(function()
        if getgenv().MacroStatusLabel and getgenv().MacroStatusLabel.UpdateName then
            local statusText = tostring(getgenv().MacroStatusText or "Idle")
            getgenv().MacroStatusLabel:UpdateName("Status: " .. statusText)
        end
        
        if getgenv().MacroStepLabel and getgenv().MacroStepLabel.UpdateName then
            local currentStep = tonumber(getgenv().MacroCurrentStep) or 0
            local totalSteps = tonumber(getgenv().MacroTotalSteps) or 0
            getgenv().MacroStepLabel:UpdateName("📝 Step: " .. currentStep .. "/" .. totalSteps)
        end
        
        if getgenv().MacroActionLabel and getgenv().MacroActionLabel.UpdateName then
            local actionText = (getgenv().MacroActionText and tostring(getgenv().MacroActionText) ~= "") and tostring(getgenv().MacroActionText) or "None"
            getgenv().MacroActionLabel:UpdateName("⚡ Action: " .. actionText)
        end
        
        if getgenv().MacroUnitLabel and getgenv().MacroUnitLabel.UpdateName then
            local unitText = (getgenv().MacroUnitText and tostring(getgenv().MacroUnitText) ~= "") and tostring(getgenv().MacroUnitText) or "None"
            getgenv().MacroUnitLabel:UpdateName("🗼 Unit: " .. unitText)
        end
        
        if getgenv().MacroWaitingLabel and getgenv().MacroWaitingLabel.UpdateName then
            local waitingText = (getgenv().MacroWaitingText and tostring(getgenv().MacroWaitingText) ~= "") and tostring(getgenv().MacroWaitingText) or "None"
            getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: " .. waitingText)
        end
    end)
end


getgenv().MacroCurrentCash = 0
getgenv().MacroLastCash = 0
getgenv().MacroCashHistory = {}
local MAX_CASH_HISTORY = 30

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        pcall(function()
            getgenv().MacroCurrentCash = LocalPlayer.Cash.Value
        end)
    end
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
                currentCash = tonumber(LocalPlayer.Cash.Value) or 0
            end)
            
            local lastCash = tonumber(getgenv().MacroLastCash) or 0
            if lastCash > 0 and currentCash < lastCash then
                local decrease = lastCash - currentCash
                table.insert(getgenv().MacroCashHistory, 1, {
                    time = tick(),
                    decrease = decrease,
                    before = lastCash,
                    after = currentCash
                })
                
                if #getgenv().MacroCashHistory > MAX_CASH_HISTORY then
                    table.remove(getgenv().MacroCashHistory, #getgenv().MacroCashHistory)
                end
            end
            
            getgenv().MacroLastCash = currentCash
        end
    end)
end

getgenv().GetRecentCashDecrease = function(withinSeconds)
    withinSeconds = withinSeconds or 1
    local now = tick()
    for _, entry in ipairs(getgenv().MacroCashHistory) do
        if (now - entry.time) <= withinSeconds then
            return entry.decrease
        end
    end
    return 0
end

getgenv().GetPlaceCost = function(towerName)
    if not getgenv().MacroTowerInfoCache then
        return 0
    end
    
    if not getgenv().MacroTowerInfoCache[towerName] then 
        return 0 
    end
    
    if getgenv().MacroTowerInfoCache[towerName][0] then
        return getgenv().MacroTowerInfoCache[towerName][0].Cost or 0
    end
    
    return 0
end

trackCash()


local function isKilled()
    return getgenv().MacroSystemKillSwitch == true
end

getgenv().IsKilled = isKilled

getgenv().MacroTowerInfoCache = {}
getgenv().MacroRemoteCache = {}

local function cacheTowerInfo()
    if next(getgenv().MacroTowerInfoCache) then return end
    
    pcall(function()
        local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
        for _, mod in pairs(towerInfoPath:GetChildren()) do
            if mod:IsA("ModuleScript") then
                local ok, data = pcall(function() 
                    return require(mod) 
                end)
                if ok then 
                    getgenv().MacroTowerInfoCache[mod.Name] = data 
                end
            end
        end
    end)
end


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
    
    for level = 0, 50 do
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
                    abilities[nm] = {
                        name = nm,
                        cooldown = a.Cd,
                        requiredLevel = level,
                        isGlobal = a.IsCdGlobal or false,
                        isAttribute = hasRealAttribute
                    }
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
                        abilities[nm] = {
                            name = nm,
                            cooldown = a.Cd,
                            requiredLevel = level,
                            isGlobal = a.IsCdGlobal or false,
                            isAttribute = hasRealAttribute
                        }
                    end
                end
            end
        end
    end
    
    return abilities
end

getgenv().AutoAbilitiesEnabled = getgenv().Config.toggles.AutoAbilityToggle or false
getgenv().UnitAbilities = getgenv().UnitAbilities or {}

getgenv().AutoReadyEnabled = getgenv().Config.toggles.AutoReady or false
getgenv().AutoNextEnabled = getgenv().Config.toggles.AutoNext or false
getgenv().AutoLeaveEnabled = getgenv().Config.toggles.AutoLeave or false
getgenv().AutoFastRetryEnabled = getgenv().Config.toggles.AutoRetry or false
getgenv().AutoSmartEnabled = getgenv().Config.toggles.AutoSmart or false

getgenv().AutoEventEnabled = getgenv().Config.toggles.AutoEventToggle or false
getgenv().BingoEnabled = getgenv().Config.toggles.BingoToggle or false
getgenv().CapsuleEnabled = getgenv().Config.toggles.CapsuleToggle or false

getgenv().SeamlessFixEnabled = getgenv().Config.toggles.SeamlessFixToggle or false
getgenv().SeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4
getgenv().AutoExecuteTeleportEnabled = getgenv().Config.toggles.AutoExecuteTeleport or false

getgenv().WebhookEnabled = getgenv().Config.toggles.WebhookToggle or false
getgenv().WebhookProcessing = false

getgenv().GetClientData = getClientData
getgenv().GetTowerInfo = getTowerInfo
getgenv().GetAllAbilities = getAllAbilities

local function cacheRemotes()
    if next(getgenv().MacroRemoteCache) then return true end
    
    pcall(function()
        for _, v in pairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                getgenv().MacroRemoteCache[v.Name:lower()] = v
            end
        end
    end)
    
    local count = 0
    for _ in pairs(getgenv().MacroRemoteCache) do 
        count = count + 1 
    end
    
    return count > 0
end

local function ensureCachesReady()
    cacheTowerInfo()
    
    local attempts = 0
    while not cacheRemotes() and attempts < 10 do
        task.wait(0.5)
        attempts = attempts + 1
    end
    
    if attempts >= 10 then
        warn("[Macro] Warning: Remote cache may be incomplete")
    end
end

getgenv().CacheTowerInfo = cacheTowerInfo
getgenv().CacheRemotes = cacheRemotes
getgenv().EnsureCachesReady = ensureCachesReady

task.spawn(function()
    task.wait(2)
    ensureCachesReady()
end)


getgenv().MacroGameState = {
    currentWave = 0,
    isInGame = false,
    hasStartButton = false,
    hasEndGameUI = false,
    lastWaveChange = 0,
    matchStartTime = 0
}

local function updateGameState()
    pcall(function()
        local wave = RS:FindFirstChild("Wave")
        if wave and wave.Value then
            local newWave = wave.Value
            if newWave ~= getgenv().MacroGameState.currentWave then
                getgenv().MacroGameState.lastWaveChange = tick()
                getgenv().MacroGameState.currentWave = newWave
            end
        end
        
        local startUI = LocalPlayer.PlayerGui:FindFirstChild("StartUI")
        getgenv().MacroGameState.hasStartButton = startUI and startUI.Enabled or false
        
        local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        getgenv().MacroGameState.hasEndGameUI = endGameUI and endGameUI.Enabled or false
        
        getgenv().MacroGameState.isInGame = not getgenv().MacroGameState.hasStartButton and not getgenv().MacroGameState.hasEndGameUI
    end)
end

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        updateGameState()
    end
end)

getgenv().MacroRecordingV2 = false
getgenv().MacroDataV2 = {}
getgenv().MacroRecordingStartTime = 0

local towerTracker = {
    placeCounts = {},
    upgradeLevels = {},
    lastPlaceTime = {},
    lastUpgradeTime = {},
    pendingActions = {}
}

local originalNamecall
local namecallHook

local function processRemoteCall(remoteName, method, args)
    local now = tick()
    local remoteNameLower = remoteName:lower()
    
    if remoteNameLower:find("place") or remoteNameLower:find("tower") then
        if args[1] and type(args[1]) == "string" then
            local towerName = args[1]
            
            if towerTracker.lastPlaceTime[towerName] and (now - towerTracker.lastPlaceTime[towerName]) < 0.5 then
                return
            end
            
            towerTracker.lastPlaceTime[towerName] = now
            task.wait(0.7)
            
            local countBefore = towerTracker.placeCounts[towerName] or 0
            local countAfter = 0
            
            for _, tower in pairs(workspace.Towers:GetChildren()) do
                if tower.Name == towerName and tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
                    countAfter = countAfter + 1
                end
            end
            
            if countAfter > countBefore then
                local cost = getgenv().GetRecentCashDecrease and getgenv().GetRecentCashDecrease(2) or 0
                if cost == 0 and getgenv().GetPlaceCost then
                    cost = getgenv().GetPlaceCost(towerName)
                end
                
                local savedArgs = {args[1]}
                if args[2] and typeof(args[2]) == "CFrame" then
                    savedArgs[2] = {args[2]:GetComponents()}
                end
                
                table.insert(getgenv().MacroDataV2, {
                    RemoteName = remoteName,
                    Args = savedArgs,
                    Time = now - getgenv().MacroRecordingStartTime,
                    IsInvoke = (method == "InvokeServer"),
                    Cost = cost,
                    TowerName = towerName,
                    ActionType = "Place",
                    Wave = getgenv().MacroGameState.currentWave
                })
                
                towerTracker.placeCounts[towerName] = countAfter
                
                getgenv().MacroStatusText = "Recording"
                getgenv().MacroCurrentStep = #getgenv().MacroDataV2
                getgenv().MacroTotalSteps = #getgenv().MacroDataV2
                getgenv().MacroActionText = "Place"
                getgenv().MacroUnitText = towerName
                
                if getgenv().UpdateMacroStatus then
                    getgenv().UpdateMacroStatus()
                end
                
            end
        end
    end
    
    if remoteNameLower:find("sell") then
        if args[1] and typeof(args[1]) == "Instance" then
            local tower = args[1]
            local towerName = tower.Name
            
            table.insert(getgenv().MacroDataV2, {
                RemoteName = remoteName,
                Args = {nil},
                Time = now - getgenv().MacroRecordingStartTime,
                IsInvoke = (method == "InvokeServer"),
                Cost = 0,
                TowerName = towerName,
                ActionType = "Sell",
                Wave = getgenv().MacroGameState.currentWave
            })
            
            if towerTracker.placeCounts[towerName] then
                towerTracker.placeCounts[towerName] = math.max(0, towerTracker.placeCounts[towerName] - 1)
            end
            
            getgenv().MacroStatusText = "Recording"
            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
            getgenv().MacroActionText = "Sell"
            getgenv().MacroUnitText = towerName
            getgenv().UpdateMacroStatus()
        end
    end
end

local function setupRecordingHook()
    if namecallHook then return end
    
    local mt = getrawmetatable(game)
    originalNamecall = mt.__namecall
    setreadonly(mt, false)
    
    namecallHook = function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        local result = originalNamecall(self, ...)
        
        if not getgenv().MacroRecordingV2 then
            return result
        end
        
        if method ~= "FireServer" and method ~= "InvokeServer" then
            return result
        end
        
        local remoteName = tostring(self.Name or "")
        if remoteName:lower():find("camera") or 
           remoteName:lower():find("zoom") or
           remoteName:lower():find("popper") or
           self:IsDescendantOf(LocalPlayer.PlayerScripts or game:GetService("StarterPlayer").StarterPlayerScripts) then
            return result
        end
        
        task.spawn(function()
            pcall(function()
                processRemoteCall(remoteName, method, args)
            end)
        end)
        
        return result
    end
    
    mt.__namecall = namecallHook
    setreadonly(mt, true)
end

local function startUpgradeMonitoring()
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            
            if not getgenv().MacroRecordingV2 then
                task.wait(1)
                continue
            end
            
            pcall(function()
                for _, tower in pairs(workspace.Towers:GetChildren()) do
                    if tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
                        local towerName = tower.Name
                        local currentLevel = tower:FindFirstChild("Upgrade") and tower.Upgrade.Value or 0
                        
                        if not towerTracker.upgradeLevels[tower] then
                            towerTracker.upgradeLevels[tower] = currentLevel
                        end
                        
                        if currentLevel > towerTracker.upgradeLevels[tower] then
                            local now = tick()
                            
                            if towerName == "NarutoBaryonClone" or towerName == "WukongClone" then
                                towerTracker.upgradeLevels[tower] = currentLevel
                                continue
                            end
                            
                            if towerTracker.lastUpgradeTime[tower] and (now - towerTracker.lastUpgradeTime[tower]) < 0.3 then
                                towerTracker.upgradeLevels[tower] = currentLevel
                                continue
                            end
                            
                            towerTracker.lastUpgradeTime[tower] = now
                            
                            task.wait(0.1)
                            local cost = getgenv().GetRecentCashDecrease and getgenv().GetRecentCashDecrease(2) or 0
                            
                            table.insert(getgenv().MacroDataV2, {
                                RemoteName = "Upgrade",
                                Args = {nil},
                                Time = now - getgenv().MacroRecordingStartTime,
                                IsInvoke = true,
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Upgrade",
                                Wave = getgenv().MacroGameState.currentWave
                            })
                            
                            towerTracker.upgradeLevels[tower] = currentLevel
                            
                            getgenv().MacroStatusText = "Recording"
                            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
                            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
                            getgenv().MacroActionText = "Upgrade"
                            getgenv().MacroUnitText = towerName
                            
                            if getgenv().UpdateMacroStatus then
                                getgenv().UpdateMacroStatus()
                            end
                            
                        end
                    end
                end
            end)
        end
    end)
end

local function monitorEndGameUI()
    task.spawn(function()
        while true do
            task.wait(0.5)
            
            if getgenv().MacroRecordingV2 and getgenv().MacroGameState.hasEndGameUI then
                getgenv().MacroRecordingV2 = false
                
                if #getgenv().MacroDataV2 > 0 and getgenv().CurrentMacro then
                    local success = getgenv().SaveMacro(getgenv().CurrentMacro, getgenv().MacroDataV2)
                    
                    if success then
                        getgenv().MacroPlayEnabled = true
                        getgenv().Config.toggles.MacroPlayToggle = true
                        getgenv().SaveConfig(getgenv().Config)
                        
                        pcall(function()
                            if getgenv().MacroPlayToggle then
                                getgenv().MacroPlayToggle:UpdateState(true)
                            end
                        end)
                        
                        if Window and Window.Notify then
                            Window:Notify({
                                Title = "Macro Recording",
                                Description = "Saved " .. #getgenv().MacroDataV2 .. " steps. Playback enabled.",
                                Lifetime = 5
                            })
                        end
                    end
                end
                
                getgenv().MacroStatusText = "Idle"
                getgenv().MacroCurrentStep = 0
                getgenv().MacroTotalSteps = 0
                getgenv().MacroActionText = ""
                getgenv().MacroUnitText = ""
                getgenv().UpdateMacroStatus()
                
                towerTracker = {
                    placeCounts = {},
                    upgradeLevels = {},
                    lastPlaceTime = {},
                    lastUpgradeTime = {},
                    pendingActions = {}
                }
            end
        end
    end)
end

getgenv().MacroPlaybackActive = false

local function executeAction(action)
    if not action.RemoteName then 
        return false, "No remote name"
    end
    
    local remote = getgenv().MacroRemoteCache[action.RemoteName:lower()]
    if not remote then 
        return false, "Remote not found: " .. action.RemoteName
    end
    
    if action.ActionType == "Upgrade" then
        local tower = nil
        for _, t in pairs(workspace.Towers:GetChildren()) do
            if t.Name == action.TowerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                tower = t
                break
            end
        end
        
        if tower then
            local currentLevel = tower:FindFirstChild("Upgrade") and tower.Upgrade.Value or 0
            local maxLevel = tower:FindFirstChild("MaxUpgrade") and tower.MaxUpgrade.Value or 999
            
            if currentLevel < maxLevel then
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(tower)
                else
                    remote:FireServer(tower)
                end
                task.wait(0.3)
                return true, "Upgraded"
            else
                return true, "Already max level"
            end
        else
            return false, "Tower not found: " .. action.TowerName
        end
        
    elseif action.ActionType == "Sell" then
        local tower = nil
        for _, t in pairs(workspace.Towers:GetChildren()) do
            if t.Name == action.TowerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                tower = t
                break
            end
        end
        
        if tower and remote then
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer(tower)
            else
                remote:FireServer(tower)
            end
            task.wait(0.3)
            return true, "Sold"
        else
            return false, "Tower not found for sell"
        end
        
    elseif action.ActionType == "Place" then
        local args = {action.Args[1]}
        if action.Args[2] and type(action.Args[2]) == "table" then
            args[2] = CFrame.new(unpack(action.Args[2]))
        end
        
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack(args))
        else
            remote:FireServer(unpack(args))
        end
        task.wait(0.3)
        return true, "Placed"
    end
    
    return false, "Unknown action type"
end

local function playMacroV2()
    if getgenv().MacroPlaybackActive then return end
    if not getgenv().CurrentMacro or not getgenv().Macros[getgenv().CurrentMacro] then
        return
    end
    
    getgenv().MacroPlaybackActive = true
    
    task.spawn(function()
        local macroData = getgenv().Macros[getgenv().CurrentMacro]
        local step = 1
        
        while getgenv().MacroGameState.hasStartButton and getgenv().MacroPlayEnabled do
            getgenv().MacroStatusText = "Waiting for Start"
            getgenv().MacroWaitingText = "Press Start..."
            getgenv().UpdateMacroStatus()
            task.wait(0.5)
        end
        
        if not getgenv().MacroPlayEnabled then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        task.wait(2)
        
        while getgenv().MacroGameState.currentWave == 0 and getgenv().MacroPlayEnabled do
            getgenv().MacroStatusText = "Waiting for Round Start"
            getgenv().MacroWaitingText = "Wave 0..."
            getgenv().UpdateMacroStatus()
            task.wait(0.5)
        end
        
        if not getgenv().MacroPlayEnabled then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        getgenv().MacroStatusText = "Playing"
        getgenv().MacroWaitingText = ""
        getgenv().UpdateMacroStatus()
        
        while getgenv().MacroPlayEnabled and step <= #macroData do
            if getgenv().IsKilled and getgenv().IsKilled() then
                break
            end
            
            if getgenv().MacroGameState.hasStartButton then
                getgenv().MacroStatusText = "Restart Detected"
                getgenv().MacroWaitingText = "Waiting for game start..."
                getgenv().UpdateMacroStatus()
                
                while getgenv().MacroGameState.hasStartButton and getgenv().MacroPlayEnabled do
                    task.wait(0.5)
                end
                
                task.wait(2)
                
                step = 1
                continue
            end
            
            local action = macroData[step]
            if not action then
                step = step + 1
                continue
            end
            
            getgenv().MacroCurrentStep = step
            getgenv().MacroTotalSteps = #macroData
            getgenv().MacroActionText = action.ActionType or "Action"
            getgenv().MacroUnitText = action.TowerName or "?"
            getgenv().UpdateMacroStatus()
            
            local cash = tonumber(getgenv().MacroCurrentCash) or 0
            local cost = tonumber(action.Cost) or 0
            
            if cost > 0 and cash < cost then
                getgenv().MacroStatusText = "Waiting Cash"
                getgenv().MacroWaitingText = "$" .. cost
                getgenv().UpdateMacroStatus()
                
                local cashWaitStart = tick()
                local maxCashWait = 1200
                
                while getgenv().MacroPlayEnabled do
                    cash = tonumber(getgenv().MacroCurrentCash) or 0
                    if cash >= cost then break end
                    
                    local waitTime = tick() - cashWaitStart
                    if waitTime > maxCashWait then
                        getgenv().MacroStatusText = "Timeout - Skipping Step"
                        getgenv().MacroWaitingText = "Waited " .. math.floor(waitTime) .. "s"
                        getgenv().UpdateMacroStatus()
                        task.wait(2)
                        step = step + 1
                        continue
                    end
                    
                    RunService.Heartbeat:Wait()
                end
                
                if not getgenv().MacroPlayEnabled then break end
            end
            
            getgenv().MacroStatusText = "Playing"
            getgenv().MacroWaitingText = ""
            getgenv().UpdateMacroStatus()
            
            local actionSuccess = false
            local actionMessage = ""
            local actionAttempts = 0
            local maxAttempts = 3
            
            while actionAttempts < maxAttempts and not actionSuccess do
                actionAttempts = actionAttempts + 1
                
                local pcallSuccess, result, msg = pcall(function()
                    return executeAction(action)
                end)
                
                if pcallSuccess and result then
                    actionSuccess = true
                    actionMessage = msg or "Success"
                elseif actionAttempts < maxAttempts then
                    task.wait(0.5)
                else
                    actionMessage = msg or "Failed after " .. maxAttempts .. " attempts"
                end
            end
            
            if not actionSuccess then
                getgenv().MacroStatusText = "Step Failed - Skipping"
                getgenv().MacroWaitingText = actionMessage
                getgenv().UpdateMacroStatus()
                task.wait(1)
            end
            
            step = step + 1
            
            local stepDelay = getgenv().MacroStepDelay or 0
            if stepDelay > 0 then
                task.wait(stepDelay)
            else
                task.wait(0.15)
            end
        end
        
        getgenv().MacroStatusText = "Idle"
        getgenv().MacroCurrentStep = 0
        getgenv().MacroActionText = ""
        getgenv().MacroUnitText = ""
        getgenv().MacroWaitingText = ""
        getgenv().UpdateMacroStatus()
        
        getgenv().MacroPlaybackActive = false
    end)
end

setupRecordingHook()
startUpgradeMonitoring()
monitorEndGameUI()

task.spawn(function()
    while true do
        task.wait(0.5)
        
        if getgenv().MacroPlayEnabled and not getgenv().MacroPlaybackActive then
            playMacroV2()
        end
    end
end)



local MapData = nil
pcall(function()
    local mapDataModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
    if mapDataModule and mapDataModule:IsA("ModuleScript") then
        MapData = require(mapDataModule)
    end
end)

local function getMapsByMode(mode)
    if not MapData then return {} end
    if mode == "ElementalCaverns" then return {"Light","Nature","Fire","Dark","Water"} end
    local maps = {}
    for mapName, mapInfo in pairs(MapData) do
        if mapInfo.Type and type(mapInfo.Type) == "table" then
            for _, mapType in ipairs(mapInfo.Type) do
                if mapType == mode then table.insert(maps, mapName) break end
            end
        end
    end
    table.sort(maps)
    return maps
end

local savedAutoJoin = getgenv().Config.autoJoin or {}
getgenv().AutoJoinConfig = {
    enabled = savedAutoJoin.enabled or false,
    autoStart = savedAutoJoin.autoStart or false,
    friendsOnly = savedAutoJoin.friendsOnly or false,
    mode = savedAutoJoin.mode or "Story",
    map = savedAutoJoin.map or "",
    act = savedAutoJoin.act or 1,
    difficulty = savedAutoJoin.difficulty or "Normal"
}




local success, err = pcall(function()
    Sections.MainLeft:Header({ Text = "🎮 Game Selection" })
    Sections.MainLeft:SubLabel({ Text = "Choose your game mode and map" })
end)
if not success then
    warn("[UI ERROR] Main tab header failed:", err)
    error("[FATAL] Cannot continue - Main tab header failed: " .. tostring(err))
end

local autoJoinModeList = {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "Event", "MidnightHunt", "BossRush", "Siege", "Breach"}

local autoJoinMapDropdown = nil

local modeDefault = 1
if getgenv().AutoJoinConfig.mode then
    for i, modeName in ipairs(autoJoinModeList) do
        if modeName == getgenv().AutoJoinConfig.mode then
            modeDefault = i
            break
        end
    end
end


local autoJoinModeDropdown
local modeSuccess, modeErr = pcall(function()
    autoJoinModeDropdown = createDropdown(
        Sections.MainLeft,
        "Mode",
        "AutoJoinMode",
        autoJoinModeList,
        false,
        function(value)
            getgenv().AutoJoinConfig.mode = value
            getgenv().Config.autoJoin.mode = value
            saveConfig(getgenv().Config)
            
            local maps = getMapsByMode(value)
            if #maps == 0 then
                maps = {"No Maps Available"}
            end
            if autoJoinMapDropdown then
                pcall(function()
                    autoJoinMapDropdown:ClearOptions()
                    autoJoinMapDropdown:InsertOptions(maps)
                    if #maps > 0 then
                        autoJoinMapDropdown:UpdateSelection(1)
                        getgenv().AutoJoinConfig.map = maps[1]
                        getgenv().Config.autoJoin.map = maps[1]
                        saveConfig(getgenv().Config)
                    end
                end)
            end
        end,
        modeDefault
    )
end)
if not modeSuccess then
    warn("[UI ERROR] Mode dropdown failed:", modeErr)
    error("[FATAL] Cannot continue - Mode dropdown failed: " .. tostring(modeErr))
end

local initialMaps = getMapsByMode(getgenv().AutoJoinConfig.mode)
if #initialMaps == 0 then
    initialMaps = {"No Maps Available"}
end

local mapDefault = 1
if getgenv().AutoJoinConfig.map and getgenv().AutoJoinConfig.map ~= "" then
    for i, mapName in ipairs(initialMaps) do
        if mapName == getgenv().AutoJoinConfig.map then
            mapDefault = i
            break
        end
    end
end


local mapSuccess, mapErr = pcall(function()
    autoJoinMapDropdown = createDropdown(
        Sections.MainLeft,
        "Map",
        "AutoJoinMap",
        initialMaps,
        false,
        function(value)
            getgenv().AutoJoinConfig.map = value
            getgenv().Config.autoJoin.map = value
            saveConfig(getgenv().Config)
        end,
        mapDefault
    )
end)
if not mapSuccess then
    warn("[UI ERROR] Map dropdown failed:", mapErr)
    error("[FATAL] Cannot continue - Map dropdown failed: " .. tostring(mapErr))
end

local actDefault = getgenv().AutoJoinConfig.act or 1

local actSuccess, actErr = pcall(function()
    createDropdown(
        Sections.MainLeft,
        "Act",
        "AutoJoinAct",
        {"1", "2", "3", "4", "5", "6"},
        false,
        function(value)
            getgenv().AutoJoinConfig.act = tonumber(value) or 1
            getgenv().Config.autoJoin.act = tonumber(value) or 1
            saveConfig(getgenv().Config)
        end,
        actDefault
    )
end)
if not actSuccess then
    warn("[UI ERROR] Act dropdown failed:", actErr)
    error("[FATAL] Cannot continue - Act dropdown failed: " .. tostring(actErr))
end

local difficultyList = {"Normal", "Nightmare", "Purgatory", "Insanity"}
local difficultyDefault = 1
if getgenv().AutoJoinConfig.difficulty then
    for i, diff in ipairs(difficultyList) do
        if diff == getgenv().AutoJoinConfig.difficulty then
            difficultyDefault = i
            break
        end
    end
end


local diffSuccess, diffErr = pcall(function()
    createDropdown(
        Sections.MainLeft,
        "Difficulty",
        "AutoJoinDifficulty",
        difficultyList,
        false,
        function(value)
            getgenv().AutoJoinConfig.difficulty = value
            getgenv().Config.autoJoin.difficulty = value
            saveConfig(getgenv().Config)
        end,
        difficultyDefault
    )
end)
if not diffSuccess then
    warn("[UI ERROR] Difficulty dropdown failed:", diffErr)
    error("[FATAL] Cannot continue - Difficulty dropdown failed: " .. tostring(diffErr))
end

local divSuccess, divErr = pcall(function()
    Sections.MainLeft:Divider()
    Sections.MainLeft:Header({ Text = "⚙️ Join Settings" })
    Sections.MainLeft:SubLabel({ Text = "Configure auto-join behavior" })
end)
if not divSuccess then
    warn("[UI ERROR] Join Settings section failed:", divErr)
    error("[FATAL] Cannot continue - Join Settings section failed: " .. tostring(divErr))
end

local enableToggleSuccess, enableToggleErr = pcall(function()
    createToggle(
        Sections.MainLeft,
        "Enable Auto Join",
        "AutoJoinEnabled",
        function(value)
            getgenv().AutoJoinConfig.enabled = value
            getgenv().Config.autoJoin.enabled = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Join",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoJoinConfig.enabled
    )
end)
if not enableToggleSuccess then
    warn("[UI ERROR] Enable Auto Join toggle failed:", enableToggleErr)
end

local joinDelaySuccess, joinDelayErr = pcall(function()
    createInput(
        Sections.MainLeft,
        "Join Delay (seconds)",
        "AutoJoinDelay",
        "Delay before joining map (0 = instant)",
        "Number",
        function(value)
            local delay = tonumber(value) or 0
            getgenv().AutoJoinDelay = delay
            Window:Notify({
                Title = "Auto Join Delay",
                Description = "Set to " .. delay .. " seconds",
                Lifetime = 2
            })
        end,
        tostring(getgenv().Config.inputs.AutoJoinDelay or 0)
    )
end)
if not joinDelaySuccess then
    warn("[UI ERROR] Auto Join Delay input failed:", joinDelayErr)
end

local friendsSuccess, friendsErr = pcall(function()
    createToggle(
        Sections.MainLeft,
        "Friends Only",
        "AutoJoinFriendsOnly",
        function(value)
            getgenv().AutoJoinConfig.friendsOnly = value
            getgenv().Config.autoJoin.friendsOnly = value
            saveConfig(getgenv().Config)
            
            pcall(function()
                RS.Remotes.Teleporter.InteractEvent:FireServer("FriendsOnly")
            end)
            
            Window:Notify({
                Title = "Friends Only",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoJoinConfig.friendsOnly
    )
end)
if not friendsSuccess then
    warn("[UI ERROR] Friends Only toggle failed:", friendsErr)
    error("[FATAL] Cannot continue - Friends Only toggle failed: " .. tostring(friendsErr))
end

local autoStartSuccess, autoStartErr = pcall(function()
    createToggle(
        Sections.MainLeft,
        "Auto Start",
        "AutoJoinAutoStart",
        function(value)
            getgenv().AutoJoinConfig.autoStart = value
            getgenv().Config.autoJoin.autoStart = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Start",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoJoinConfig.autoStart
    )
end)
if not autoStartSuccess then
    warn("[UI ERROR] Auto Start toggle failed:", autoStartErr)
    error("[FATAL] Cannot continue - Auto Start toggle failed: " .. tostring(autoStartErr))
end


local gameActionsSuccess, gameActionsErr = pcall(function()
    Sections.MainRight:Header({ Text = "📊 Quick Actions" })
    Sections.MainRight:SubLabel({ Text = "Fast toggles for common actions" })
end)
if not gameActionsSuccess then
    warn("[UI ERROR] Quick Actions header failed:", gameActionsErr)
    error("[FATAL] Cannot continue - Quick Actions header failed: " .. tostring(gameActionsErr))
end

local autoNextSuccess, autoNextErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Next",
        "AutoNext",
        function(value)
            getgenv().AutoNextEnabled = value
            Window:Notify({
                Title = "Auto Next",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoNextEnabled
    )
end)
if not autoNextSuccess then
    warn("[UI ERROR] Auto Next toggle failed:", autoNextErr)
    error("[FATAL] Cannot continue - Auto Next toggle failed: " .. tostring(autoNextErr))
end

local autoRetrySuccess, autoRetryErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Retry",
        "AutoRetry",
        function(value)
            getgenv().AutoFastRetryEnabled = value
            Window:Notify({
                Title = "Auto Retry",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoFastRetryEnabled
    )
end)
if not autoRetrySuccess then
    warn("[UI ERROR] Auto Retry toggle failed:", autoRetryErr)
    error("[FATAL] Cannot continue - Auto Retry toggle failed: " .. tostring(autoRetryErr))
end

local autoLeaveSuccess, autoLeaveErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Leave",
        "AutoLeave",
        function(value)
            getgenv().AutoLeaveEnabled = value
            Window:Notify({
                Title = "Auto Leave",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoLeaveEnabled
    )
end)
if not autoLeaveSuccess then
    warn("[UI ERROR] Auto Leave toggle failed:", autoLeaveErr)
    error("[FATAL] Cannot continue - Auto Leave toggle failed: " .. tostring(autoLeaveErr))
end

local autoSmartSuccess, autoSmartErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Next/Replay/Leave",
        "AutoSmart",
        function(value)
            getgenv().AutoSmartEnabled = value
            Window:Notify({
                Title = "Auto Next/Replay/Leave",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoSmartEnabled
    )
end)
if not autoSmartSuccess then
    warn("[UI ERROR] Auto Next/Replay/Leave toggle failed:", autoSmartErr)
    error("[FATAL] Cannot continue - Auto Next/Replay/Leave toggle failed: " .. tostring(autoSmartErr))
end

local autoReadySuccess, autoReadyErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Ready",
        "AutoReady",
        function(value)
            getgenv().AutoReadyEnabled = value
            Window:Notify({
                Title = "Auto Ready",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoReadyEnabled
    )
end)
if not autoReadySuccess then
    warn("[UI ERROR] Auto Ready toggle failed:", autoReadyErr)
    error("[FATAL] Cannot continue - Auto Ready toggle failed: " .. tostring(autoReadyErr))
end




getgenv().CandyCards = {
    ["Weakened Resolve I"] = 13,
    ["Weakened Resolve II"] = 11,
    ["Weakened Resolve III"] = 4,
    ["Fog of War I"] = 12,
    ["Fog of War II"] = 10,
    ["Fog of War III"] = 5,
    ["Lingering Fear I"] = 6,
    ["Lingering Fear II"] = 2,
    ["Power Reversal I"] = 14,
    ["Power Reversal II"] = 9,
    ["Greedy Vampire's"] = 8,
    ["Hellish Gravity"] = 3,
    ["Deadly Striker"] = 7,
    ["Critical Denial"] = 1,
    ["Trick or Treat Coin Flip"] = 15
}

getgenv().DevilSacrifice = { ["Devil's Sacrifice"] = 999 }

getgenv().OtherCards = {
    ["Bullet Breaker I"] = 999, ["Bullet Breaker II"] = 999, ["Bullet Breaker III"] = 999,
    ["Hell Merchant I"] = 999, ["Hell Merchant II"] = 999, ["Hell Merchant III"] = 999,
    ["Hellish Warp I"] = 999, ["Hellish Warp II"] = 999,
    ["Fiery Surge I"] = 999, ["Fiery Surge II"] = 999,
    ["Grevious Wounds I"] = 999, ["Grevious Wounds II"] = 999,
    ["Scorching Hell I"] = 999, ["Scorching Hell II"] = 999,
    ["Fortune Flow"] = 999, ["Soul Link"] = 999,
    ["Seeting Bloodlust"] = 999
}

getgenv().BossRushGeneral = {
    ["Metal Skin"] = 0, ["Raging Power"] = 0, ["Demon Takeover"] = 0, ["Fortune"] = 0,
    ["Chaos Eater"] = 0, ["Godspeed"] = 0, ["Insanity"] = 0, ["Feeding Madness"] = 0, ["Emotional Damage"] = 0
}

getgenv().BabyloniaCastle = {}

local function initializeCardPriorities(sourceTable, targetTable, keyPrefix)
    if not sourceTable then return end
    keyPrefix = keyPrefix or "Card_"
    
    for cardName, defaultPriority in pairs(sourceTable) do
        local configKey = keyPrefix .. cardName
        local savedValue = getgenv().Config.inputs[configKey]
        targetTable[cardName] = savedValue and tonumber(savedValue) or defaultPriority
    end
end

getgenv().CardPriority = getgenv().CardPriority or {}
initializeCardPriorities(getgenv().CandyCards, getgenv().CardPriority)
initializeCardPriorities(getgenv().DevilSacrifice, getgenv().CardPriority)
initializeCardPriorities(getgenv().OtherCards, getgenv().CardPriority)

getgenv().BossRushCardPriority = getgenv().BossRushCardPriority or {}
initializeCardPriorities(getgenv().BossRushGeneral, getgenv().BossRushCardPriority, "BossRush_")
initializeCardPriorities(getgenv().BabyloniaCastle, getgenv().BossRushCardPriority, "BabyloniaCastle_")

getgenv().CardSelectionEnabled = getgenv().Config.toggles.CardSelectionToggle or false
getgenv().SlowerCardSelectionEnabled = getgenv().Config.toggles.SlowerCardSelectionToggle or false

local savedPortalConfig = getgenv().Config.portals or {}
getgenv().PortalConfig = {
    selectedMap = savedPortalConfig.selectedMap or "",
    tier = savedPortalConfig.tier or 1,
    useBestPortal = savedPortalConfig.useBestPortal or false,
    pickPortal = savedPortalConfig.pickPortal or false,
    priorities = savedPortalConfig.priorities or {
        ["Tower Limit"] = 0,
        ["Immunity"] = 0,
        ["Speedy"] = 0,
        ["No Hit"] = 0,
        ["Flight"] = 0,
        ["Short Range"] = 0
    }
}
getgenv().Config.portals = getgenv().PortalConfig

Sections.PortalsRight:Header({ Text = "🌀 Portal Selection" })
Sections.PortalsRight:SubLabel({ Text = "Configure automatic portal selection" })

local function getPortalMaps()
    local maps = {}
    pcall(function()
        local mapData = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
        if mapData and mapData:IsA("ModuleScript") then
            local data = require(mapData)
            for mapName, mapInfo in pairs(data) do
                if mapInfo.Type and type(mapInfo.Type) == "table" then
                    for _, mapType in ipairs(mapInfo.Type) do
                        if mapType == "Portal" then
                            table.insert(maps, mapName)
                            break
                        end
                    end
                end
            end
        end
    end)
    table.sort(maps)
    return #maps > 0 and maps or {"No Portal Maps Found"}
end

local portalMaps = getPortalMaps()
local portalMapDefault = 1
if getgenv().PortalConfig.selectedMap and getgenv().PortalConfig.selectedMap ~= "" then
    for i, mapName in ipairs(portalMaps) do
        if mapName == getgenv().PortalConfig.selectedMap then
            portalMapDefault = i
            break
        end
    end
end

createDropdown(
    Sections.PortalsRight,
    "Select Map",
    "PortalMap",
    portalMaps,
    false,
    function(value)
        getgenv().PortalConfig.selectedMap = value
        getgenv().Config.portals.selectedMap = value
        saveConfig(getgenv().Config)
    end,
    portalMapDefault
)

Sections.PortalsRight:Divider()

Sections.PortalsRight:Header({ Text = "⚙️ Portal Options" })
Sections.PortalsRight:SubLabel({ Text = "Additional portal settings" })

local tierOptions = {}
for i = 1, 10 do
    table.insert(tierOptions, tostring(i))
end

createDropdown(
    Sections.PortalsRight,
    "Portal Tier",
    "PortalTier",
    tierOptions,
    false,
    function(value)
        getgenv().PortalConfig.tier = tonumber(value) or 1
        getgenv().Config.portals.tier = tonumber(value) or 1
        saveConfig(getgenv().Config)
    end,
    getgenv().PortalConfig.tier
)

createToggle(
    Sections.PortalsRight,
    "Use Best Portal (Highest Tier)",
    "UseBestPortal",
    function(value)
        getgenv().PortalConfig.useBestPortal = value
        getgenv().Config.portals.useBestPortal = value
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Will use highest tier portal available" or "Will use selected tier",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.useBestPortal
)

createToggle(
    Sections.PortalsRight,
    "Pick Portal (Manual Selection)",
    "PickPortal",
    function(value)
        getgenv().PortalConfig.pickPortal = value
        getgenv().Config.portals.pickPortal = value
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Manual portal selection enabled" or "Automatic selection enabled",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.pickPortal
)

Sections.PortalsLeft:Header({ Text = "🎯 Challenge Priority" })
Sections.PortalsLeft:SubLabel({ Text = "Assign priority (1-6) to each challenge. 1 = highest priority, 0 = ignore" })

createInput(
    Sections.PortalsLeft,
    "Tower Limit",
    "PortalPriority_TowerLimit",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Tower Limit"] = num
        getgenv().Config.portals.priorities["Tower Limit"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Tower Limit"])
)

createInput(
    Sections.PortalsLeft,
    "Immunity",
    "PortalPriority_Immunity",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Immunity"] = num
        getgenv().Config.portals.priorities["Immunity"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Immunity"])
)

createInput(
    Sections.PortalsLeft,
    "Speedy",
    "PortalPriority_Speedy",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Speedy"] = num
        getgenv().Config.portals.priorities["Speedy"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Speedy"])
)

createInput(
    Sections.PortalsLeft,
    "No Hit",
    "PortalPriority_NoHit",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["No Hit"] = num
        getgenv().Config.portals.priorities["No Hit"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["No Hit"])
)

createInput(
    Sections.PortalsLeft,
    "Flight",
    "PortalPriority_Flight",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Flight"] = num
        getgenv().Config.portals.priorities["Flight"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Flight"])
)

createInput(
    Sections.PortalsLeft,
    "Short Range",
    "PortalPriority_ShortRange",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Short Range"] = num
        getgenv().Config.portals.priorities["Short Range"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Short Range"])
)


Sections.EventLeft:Header({ Text = "🎃 Event Automation" })
Sections.EventLeft:SubLabel({ Text = "Automatically join and start events" })

createToggle(
    Sections.EventLeft,
    "Auto Event Join",
    "AutoEventToggle",
    function(value)
        getgenv().AutoEventEnabled = value
        Window:Notify({
            Title = "Auto Event",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().Config.toggles.AutoEventToggle or false
)

createInput(
    Sections.EventLeft,
    "Join Delay (seconds)",
    "EventJoinDelay",
    "Delay before joining event (0 = instant)",
    "Number",
    function(value)
        local delay = tonumber(value) or 0
        getgenv().EventJoinDelay = delay
        Window:Notify({
            Title = "Event Join Delay",
            Description = "Set to " .. delay .. " seconds",
            Lifetime = 2
        })
    end,
    tostring(getgenv().Config.inputs.EventJoinDelay or 0)
)

local isInLobby = not RS:FindFirstChild("GameEnded")

if isInLobby then
    Sections.EventLeft:Divider()
    
    Sections.EventLeft:Header({ Text = "🎲 Auto Bingo" })
    Sections.EventLeft:SubLabel({ Text = "Complete bingo cards automatically" })
    
    createToggle(
        Sections.EventLeft,
        "Enable Auto Bingo",
        "BingoToggle",
        function(value)
            getgenv().BingoEnabled = value
            Window:Notify({
                Title = "Auto Bingo",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().Config.toggles.BingoToggle or false
    )
    
    Sections.EventLeft:Divider()
    
    Sections.EventLeft:Header({ Text = "🎁 Auto Capsules" })
    Sections.EventLeft:SubLabel({ Text = "Open event capsules automatically" })
    
    createToggle(
        Sections.EventLeft,
        "Enable Auto Capsules",
        "CapsuleToggle",
        function(value)
            getgenv().CapsuleEnabled = value
            Window:Notify({
                Title = "Auto Capsules",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().Config.toggles.CapsuleToggle or false
    )
    
    Sections.EventLeft:Divider()
end

local eventHeaderSuccess, eventHeaderErr = pcall(function()
    Sections.EventLeft:Header({ Text = "⚙️ Card Selection Mode" })
    Sections.EventLeft:SubLabel({ Text = "Choose between fast or reliable selection" })
end)
if not eventHeaderSuccess then
    warn("[UI ERROR] Event tab header failed:", eventHeaderErr)
    error("[FATAL] Cannot continue - Event tab header failed: " .. tostring(eventHeaderErr))
end

local fastModeToggle, slowerModeToggle

local fastSuccess, fastErr = pcall(function()
    fastModeToggle = createToggle(
        Sections.EventLeft,
        "⚡ Fast Mode",
        "CardSelectionToggle",
        function(value)
            getgenv().CardSelectionEnabled = value
            if value and slowerModeToggle then
                getgenv().SlowerCardSelectionEnabled = false
                getgenv().Config.toggles.SlowerCardSelectionToggle = false
                getgenv().SaveConfig(getgenv().Config)
                pcall(function()
                    slowerModeToggle:UpdateState(false)
                end)
            end
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Fast Mode Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        false
    )
end)
if not fastSuccess then
    warn("[UI ERROR] Fast Mode toggle failed:", fastErr)
    error("[FATAL] Cannot continue - Fast Mode toggle failed: " .. tostring(fastErr))
end

local slowerSuccess, slowerErr = pcall(function()
    slowerModeToggle = createToggle(
        Sections.EventLeft,
        "🐢 Slower Mode (More Reliable)",
        "SlowerCardSelectionToggle",
        function(value)
            getgenv().SlowerCardSelectionEnabled = value
            if value and fastModeToggle then
                getgenv().CardSelectionEnabled = false
                getgenv().Config.toggles.CardSelectionToggle = false
                getgenv().SaveConfig(getgenv().Config)
                pcall(function()
                    fastModeToggle:UpdateState(false)
                end)
            end
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Slower Mode Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        false
    )
end)
if not slowerSuccess then
    warn("[UI ERROR] Slower Mode toggle failed:", slowerErr)
    error("[FATAL] Cannot continue - Slower Mode toggle failed: " .. tostring(slowerErr))
end

local paraSuccess, paraErr = pcall(function()
    Sections.EventLeft:SubLabel({ 
        Text = "Lower number = higher priority (1 is best, 999 to skip)"
    })
end)
if not paraSuccess then
    warn("[UI ERROR] Event instructions failed:", paraErr)
end


local candyHeaderSuccess, candyHeaderErr = pcall(function()
    Sections.EventRight:Header({ Text = "🃏 Card Priorities" })
    Sections.EventRight:SubLabel({ Text = "Lower number = higher priority (1 is best, 999 to skip)" })
    Sections.EventRight:Divider()
    Sections.EventRight:Header({ Text = "🍬 Candy Cards" })
end)
if not candyHeaderSuccess then
    warn("[UI ERROR] Candy Cards header failed:", candyHeaderErr)
    error("[FATAL] Cannot continue - Candy Cards header failed: " .. tostring(candyHeaderErr))
end

local candyInputsSuccess, candyInputsErr = pcall(function()
    createCardPriorityInputs(Sections.EventRight, getgenv().CandyCards, getgenv().CardPriority)
end)
if not candyInputsSuccess then
    warn("[UI ERROR] Candy Cards inputs failed:", candyInputsErr)
    error("[FATAL] Cannot continue - Candy Cards inputs failed: " .. tostring(candyInputsErr))
end

Sections.EventRight:Divider()

Sections.EventRight:Header({ Text = "😈 Devil's Sacrifice" })
createCardPriorityInputs(Sections.EventRight, getgenv().DevilSacrifice, getgenv().CardPriority)

Sections.EventRight:Divider()

Sections.EventRight:Header({ Text = "📋 Other Cards" })
createCardPriorityInputs(Sections.EventRight, getgenv().OtherCards, getgenv().CardPriority)



Sections.BossRushLeft:Header({ Text = "⚔️ Boss Rush Settings" })
Sections.BossRushLeft:SubLabel({ Text = "Automatic card selection for Boss Rush" })

createToggle(
    Sections.BossRushLeft,
    "Enable Boss Rush",
    "BossRushToggle",
    function(value)
        getgenv().BossRushEnabled = value
        Window:Notify({
            Title = "Boss Rush",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().BossRushEnabled or false
)

Sections.BossRushLeft:Divider()

Sections.BossRushLeft:Header({ Text = "💡 How It Works" })
Sections.BossRushLeft:SubLabel({ 
    Text = "The script automatically selects cards by priority (1-999). Cards set to 999 are skipped. Adjust priorities on the right." 
})

Sections.BossRushLeft:SubLabel({ 
    Text = "Lower number = higher priority • Set to 999 to avoid" 
})


Sections.BossRushRight:Header({ Text = "🃏 Card Priorities" })
Sections.BossRushRight:SubLabel({ Text = "Set priority for each card (1 = highest, 999 = skip)" })
Sections.BossRushRight:Divider()

Sections.BossRushRight:Header({ Text = "🎯 General Cards" })

createCardPriorityInputs(Sections.BossRushRight, getgenv().BossRushGeneral, getgenv().BossRushCardPriority, "BossRush_")

Sections.BossRushRight:Divider()

Sections.BossRushRight:Header({ Text = "🏰 Babylonia Castle Cards" })

pcall(function()
    local babyloniaModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards"):FindFirstChild("Babylonia Castle")
    if babyloniaModule then
        local cards = require(babyloniaModule)
        for _, card in pairs(cards) do
            local cardName = card.CardName
            local cardType = card.CardType or "Buff"
            local inputKey = "BabyloniaCastle_" .. cardName
            
            if not getgenv().BossRushCardPriority then 
                getgenv().BossRushCardPriority = {} 
            end
            if not getgenv().BossRushCardPriority[cardName] then 
                getgenv().BossRushCardPriority[cardName] = 999 
            end
            
            local defaultValue = getgenv().Config.inputs[inputKey] or "999"
            
            createInput(
                Sections.BossRushRight,
                cardName .. " (" .. cardType .. ")",
                inputKey,
                "Priority (1-999)",
                "Numeric",
                function(value)
                    local num = tonumber(value)
                    if num then
                        getgenv().BossRushCardPriority[cardName] = num
                    end
                end,
                defaultValue
            )
            
            getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue) or 999
        end
    end
end)



local UnitNames = nil
pcall(function()
    local unitNamesModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("UnitNames")
    if unitNamesModule and unitNamesModule:IsA("ModuleScript") then
        UnitNames = require(unitNamesModule)
    end
end)

local function getUnitDisplayName(unitName)
    if UnitNames and UnitNames[unitName] then
        return UnitNames[unitName]
    end
    return unitName
end


getgenv().BulmaEnabled = getgenv().Config.toggles.BulmaToggle or false
getgenv().BulmaWishType = getgenv().Config.dropdowns.BulmaWishType or "Power"
getgenv().BulmaWishUsedThisRound = false

getgenv().WukongEnabled = getgenv().Config.toggles.WukongToggle or false
getgenv().WukongTrackedClones = {}

getgenv().EventJoinDelay = tonumber(getgenv().Config.inputs.EventJoinDelay) or 0
getgenv().AutoJoinDelay = tonumber(getgenv().Config.inputs.AutoJoinDelay) or 0

getgenv().FinalExpAutoJoinEasyEnabled = getgenv().Config.toggles.FinalExpAutoJoinEasyToggle or false
getgenv().FinalExpAutoJoinHardEnabled = getgenv().Config.toggles.FinalExpAutoJoinHardToggle or false
getgenv().FinalExpAutoSkipShopEnabled = getgenv().Config.toggles.FinalExpAutoSkipShopToggle or false

local BLACKLISTED_UNITS = {
    "NarutoBaryonClone"
}

local function isBlacklisted(unitName)
    for _, blacklisted in ipairs(BLACKLISTED_UNITS) do
        if unitName == blacklisted or unitName:find(blacklisted) then
            return true
        end
    end
    return false
end

if not getgenv()._AbilityUIElements then
    getgenv()._AbilityUIElements = {Left = {}, Right = {}}
end

local function clearAbilityUI()
    for side, elements in pairs(getgenv()._AbilityUIElements) do
        for _, element in ipairs(elements) do
            pcall(function()
                if element and element.Remove then
                    element:Remove()
                elseif element and element.SetVisibility then
                    element:SetVisibility(false)
                end
            end)
        end
    end
    getgenv()._AbilityUIElements = {Left = {}, Right = {}}
end


local function buildAutoAbilityUI()
    if getgenv()._AbilityUIBuilding then return end
    if getgenv()._AbilityUIBuilt then return end
    getgenv()._AbilityUIBuilding = true
    
    clearAbilityUI()
    
    local clientData = getClientData()
    if not clientData or not clientData.Slots then
        Window:Notify({
            Title = "Auto Ability",
            Description = "ClientData not available yet, retrying...",
            Lifetime = 3
        })
        getgenv()._AbilityUIBuilt = false
        getgenv()._AbilityUIBuilding = false
        return
    end
    
    local anyBuilt = false
    local success, err = pcall(function()
        local unitsToShow = {}
        
        local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
        for slotIndex, slotName in ipairs(sortedSlots) do
            local slotData = clientData.Slots[slotName]
            if slotData and slotData.Value then
                table.insert(unitsToShow, {
                    name = slotData.Value,
                    slot = slotName,
                    level = slotData.Level or 0,
                    slotIndex = slotIndex,
                    isSpawned = false
                })
            end
        end
        
        for _, unitInfo in ipairs(unitsToShow) do
            local unitName = unitInfo.name
            
            if isBlacklisted(unitName) then
                continue
            end
            
            if unitName == "Bulma" then
                continue
            end
            
            local abilities = getAllAbilities(unitName)
            
            if next(abilities) then
                local tabSide = (unitInfo.slotIndex <= 3) and "Left" or "Right"
                local sideKey = tabSide
                
                local displayName = getUnitDisplayName(unitName)
                
                local unitSection = Tabs.Abilities:Section({ Side = tabSide })
                table.insert(getgenv()._AbilityUIElements[sideKey], unitSection)
                
                local headerText = "📦 " .. displayName
                local sublabelText = unitInfo.slot .. " • Level " .. tostring(unitInfo.level)
                
                unitSection:Header({ Text = headerText })
                unitSection:SubLabel({ Text = sublabelText })
                unitSection:Divider()
                
                anyBuilt = true
                
                local targetSection = unitSection
                
                if not getgenv().UnitAbilities then getgenv().UnitAbilities = {} end
                if not getgenv().UnitAbilities[unitName] then getgenv().UnitAbilities[unitName] = {} end
                if not getgenv().Config.abilities then getgenv().Config.abilities = {} end
                if not getgenv().Config.abilities[unitName] then getgenv().Config.abilities[unitName] = {} end
                    
                    local sortedAbilities = {}
                    for abilityName, data in pairs(abilities) do
                        table.insert(sortedAbilities, { name = abilityName, data = data })
                    end
                    table.sort(sortedAbilities, function(a, b)
                        local aLevel = (a.data and a.data.requiredLevel) or 0
                        local bLevel = (b.data and b.data.requiredLevel) or 0
                        return aLevel < bLevel
                    end)
                    
                    for _, ab in ipairs(sortedAbilities) do
                        local abilityName = ab.name
                        local abilityData = ab.data
                        
                        if unitName == "JinMoriGodly" and abilityName == "Clone Synthesis" then
                            continue
                        end
                        
                        local saved = getgenv().Config.abilities and 
                                     getgenv().Config.abilities[unitName] and 
                                     getgenv().Config.abilities[unitName][abilityName]
                        
                        local waveInputFlag = unitName .. "_" .. abilityName .. "_Wave"
                        local savedWave = getgenv().Config.inputs[waveInputFlag]
                        if savedWave and savedWave ~= "" then
                            savedWave = tonumber(savedWave)
                        else
                            savedWave = nil
                        end
                        
                        if not getgenv().UnitAbilities[unitName][abilityName] then
                            getgenv().UnitAbilities[unitName][abilityName] = {
                                enabled = (saved and saved.enabled) or false,
                                onlyOnBoss = (saved and saved.onlyOnBoss) or false,
                                specificWave = savedWave or (saved and saved.specificWave) or nil,
                                requireBossInRange = (saved and saved.requireBossInRange) or false,
                                useOnWave = (saved and saved.useOnWave) or false
                            }
                        end
                        
                        local cfg = getgenv().UnitAbilities[unitName][abilityName]
                        local defaultToggle = cfg.enabled
                        
                        local abilityIcon = abilityData.isAttribute and "🔒" or "⚡"
                        local abilityInfo = abilityIcon .. " " .. abilityName .. " (CD: " .. tostring(abilityData.cooldown) .. "s)"
                        
                        createToggle(
                            targetSection,
                            abilityInfo,
                            unitName .. "_" .. abilityName .. "_Toggle",
                            function(v)
                                cfg.enabled = v
                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                                getgenv().Config.abilities[unitName][abilityName].enabled = v
                                getgenv().SaveConfig(getgenv().Config)
                                
                                Window:Notify({
                                    Title = "Auto Ability",
                                    Description = abilityName .. " " .. (v and "Enabled" or "Disabled"),
                                    Lifetime = 2
                                })
                            end,
                            defaultToggle
                        )
                        
                        local modifierKey = unitName .. "_" .. abilityName .. "_Modifiers"
                        
                        local savedDropdown = getgenv().Config.dropdowns[modifierKey]
                        local defaultValue
                        
                        if savedDropdown and type(savedDropdown) == "table" then
                            defaultValue = {}
                            for optionName, isSelected in pairs(savedDropdown) do
                                if isSelected == true then
                                    table.insert(defaultValue, optionName)
                                end
                            end
                        else
                            defaultValue = {}
                            if cfg.onlyOnBoss then table.insert(defaultValue, "Only On Boss") end
                            if cfg.requireBossInRange then table.insert(defaultValue, "Boss In Range") end
                            if cfg.useOnWave then table.insert(defaultValue, "On Wave") end
                        end
                        
                        createDropdown(
                            targetSection,
                            "  > Conditions",
                            modifierKey,
                            {"Only On Boss", "Boss In Range", "On Wave"},
                            true,
                            function(Value)
                                local selectedSet = {}
                                if type(Value) == "table" then
                                    for k, v in pairs(Value) do
                                        if v == true then
                                            selectedSet[k] = true
                                        end
                                    end
                                end
                                
                                cfg.onlyOnBoss = selectedSet["Only On Boss"] == true
                                cfg.requireBossInRange = selectedSet["Boss In Range"] == true
                                cfg.useOnWave = selectedSet["On Wave"] == true
                                
                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                local store = getgenv().Config.abilities[unitName]
                                store[abilityName] = store[abilityName] or {}
                                store[abilityName].onlyOnBoss = cfg.onlyOnBoss
                                store[abilityName].requireBossInRange = cfg.requireBossInRange
                                store[abilityName].useOnWave = cfg.useOnWave
                                
                                getgenv().SaveConfig(getgenv().Config)
                            end,
                            defaultValue
                        )
                        
                        local waveFlag = unitName .. "_" .. abilityName .. "_Wave"
                        local waveDefault = ""
                        if cfg.specificWave then
                            waveDefault = tostring(cfg.specificWave)
                        elseif getgenv().Config.inputs[waveFlag] and getgenv().Config.inputs[waveFlag] ~= "" then
                            waveDefault = tostring(getgenv().Config.inputs[waveFlag])
                        end
                        
                        createInput(
                            targetSection,
                            "  > Wave Number",
                            waveFlag,
                            "Required if 'On Wave' selected",
                            "Numeric",
                            function(text)
                                local num = tonumber(text)
                                cfg.specificWave = num
                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                                getgenv().Config.abilities[unitName][abilityName].specificWave = num
                                getgenv().SaveConfig(getgenv().Config)
                            end,
                            waveDefault
                        )
                    end
                end
            end
    end)
    
    if not success then
        warn("[Auto Ability UI] build failed: " .. tostring(err))
    end
    
    pcall(function()
        local clientData = getClientData()
        if clientData and clientData.Slots then
            local hasBulma = false
            for _, slotName in ipairs({"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}) do
                local slotData = clientData.Slots[slotName]
                if slotData and slotData.Value == "Bulma" then
                    hasBulma = true
                    break
                end
            end
            
            local hasBulma = false
            local hasWukong = false
            
            for _, slotName in ipairs({"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}) do
                local slotData = clientData.Slots[slotName]
                if slotData and slotData.Value then
                    if slotData.Value == "Bulma" then
                        hasBulma = true
                    elseif slotData.Value == "JinMoriGodly" then
                        hasWukong = true
                    end
                end
            end
            
            if hasBulma or hasWukong then
                local specialSection = Tabs.Abilities:Section({ Side = "Left" })
                table.insert(getgenv()._AbilityUIElements["Left"], specialSection)
                
                specialSection:Header({ Text = "🔮 Auto Units" })
                specialSection:Divider()
                
                if hasBulma then
                    createToggle(
                        specialSection,
                        "Bulma Auto-Wish",
                        "BulmaToggle",
                        function(value)
                            getgenv().BulmaEnabled = value
                            Window:Notify({
                                Title = "Bulma Auto-Wish",
                                Description = value and "Enabled" or "Disabled",
                                Lifetime = 2
                            })
                        end,
                        getgenv().BulmaEnabled
                    )
                    
                    
                    createDropdown(
                        specialSection,
                        "  > Wish Type",
                        "BulmaWishType",
                        {"Power", "Wealth", "Time"},
                        false,
                        function(value)
                            getgenv().BulmaWishType = value
                            Window:Notify({
                                Title = "Bulma Auto-Wish",
                                Description = "Wish type set to: " .. value,
                                Lifetime = 2
                            })
                        end,
                        getgenv().BulmaWishType or "Power"
                    )
                end
                
                if hasWukong then
                    if hasBulma then
                        specialSection:Divider()
                    end
                    
                    createToggle(
                        specialSection,
                        "Auto Wukong (Jin Mori)",
                        "WukongToggle",
                        function(value)
                            getgenv().WukongEnabled = value
                            Window:Notify({
                                Title = "Auto Wukong",
                                Description = value and "Enabled" or "Disabled",
                                Lifetime = 2
                            })
                        end,
                        getgenv().WukongEnabled
                    )
                end
            end
        end
    end)
    
    getgenv()._AbilityUIBuilt = anyBuilt
    getgenv()._AbilityUIBuilding = false
end

task.spawn(function()
    task.wait(2 * MOBILE_DELAY_MULTIPLIER)
    local maxRetries, retryDelay = 10, 3 * MOBILE_DELAY_MULTIPLIER
    
    for i = 1, maxRetries do
        pcall(function()
            local cd = getClientData()
            if cd and cd.Slots then
                buildAutoAbilityUI()
            else
                if i <= 3 then
                    Window:Notify({
                        Title = "Auto Ability",
                        Description = "Loading units... (" .. i .. "/" .. maxRetries .. ")",
                        Lifetime = 2
                    })
                end
            end
        end)
        
        if getgenv()._AbilityUIBuilt then break end
        task.wait(retryDelay)
    end
end)



Sections.MacroLeft:Header({ Text = "📁 Macro Management" })
Sections.MacroLeft:SubLabel({ Text = "Create, select, and manage your macros" })

local macroDropdown = createDropdown(
    Sections.MacroLeft,
    "Select Macro",
    "MacroSelect",
    getMacroNames(),
    false,
    function(value)
        getgenv().CurrentMacro = value
        if value and getgenv().Macros[value] then
            getgenv().MacroData = getgenv().Macros[value]
            getgenv().MacroTotalSteps = #getgenv().MacroData
            Window:Notify({
                Title = "Macro System",
                Description = "Selected: " .. value,
                Lifetime = 2
            })
        end
        saveMacroSettings()
        getgenv().UpdateMacroStatus()
    end,
    getgenv().CurrentMacro
)

local macroCreateInput = createInput(
    Sections.MacroLeft,
    "Create New Macro",
    "MacroCreateNew",
    "Enter macro name and press Enter",
    "All",
    function(value)
        if not value or value == "" then
            Window:Notify({
                Title = "Macro System",
                Description = "Please enter a macro name",
                Lifetime = 3
            })
            return
        end
        
        if getgenv().Macros[value] then
            Window:Notify({
                Title = "Macro System",
                Description = "Macro '" .. value .. "' already exists",
                Lifetime = 3
            })
            return
        end
        
        local success = saveMacro(value, {})
        if success then
            loadMacros()
            local macroNames = getMacroNames()
            if macroDropdown then
                pcall(function()
                    macroDropdown:ClearOptions()
                    macroDropdown:InsertOptions(macroNames)
                    macroDropdown:UpdateSelection(value)
                end)
            end
            getgenv().CurrentMacro = value
            getgenv().MacroData = {}
            getgenv().MacroTotalSteps = 0
            
            if macroCreateInput and macroCreateInput.UpdateText then
                pcall(function()
                    macroCreateInput:UpdateText("")
                end)
                task.wait(0.1)
                pcall(function()
                    macroCreateInput:UpdateText("")
                end)
            end
            
            Window:Notify({
                Title = "Macro System",
                Description = "Created: " .. value,
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "Macro System",
                Description = "Failed to create macro",
                Lifetime = 3
            })
        end
    end,
    ""
)

Sections.MacroLeft:Button({
    Name = "🔄 Refresh Macro List",
    Callback = function()
        loadMacros()
        local macroNames = getMacroNames()
        if macroDropdown then
            pcall(function()
                macroDropdown:ClearOptions()
                macroDropdown:InsertOptions(macroNames)
            end)
        end
        Window:Notify({
            Title = "Macro System",
            Description = "Loaded " .. #macroNames .. " macro(s)",
            Lifetime = 2
        })
    end,
})

Sections.MacroLeft:Divider()

Sections.MacroLeft:Header({ Text = "🎬 Recording & Playback" })
Sections.MacroLeft:SubLabel({ Text = "Record new macros or play existing ones" })

local macroRecordToggle = createToggle(
    Sections.MacroLeft,
    "Record Macro",
    "MacroRecordToggle",
    function(value)
        if value then
            if not getgenv().CurrentMacro or getgenv().CurrentMacro == "" then
                Window:Notify({
                    Title = "Macro System",
                    Description = "Please select or create a macro first",
                    Lifetime = 3
                })
                pcall(function()
                    macroRecordToggle:UpdateState(false)
                end)
                return
            end
            
            getgenv().MacroRecordingV2 = true
            getgenv().MacroDataV2 = {}
            getgenv().MacroRecordingStartTime = tick()
            getgenv().MacroStatusText = "Recording"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroTotalSteps = 0
            
            Window:Notify({
                Title = "Macro Recording",
                Description = "Recording started for: " .. getgenv().CurrentMacro,
                Lifetime = 3
            })
        else
            getgenv().MacroRecordingV2 = false
            
            if #getgenv().MacroDataV2 > 0 and getgenv().CurrentMacro then
                local success = saveMacro(getgenv().CurrentMacro, getgenv().MacroDataV2)
                if success then
                    Window:Notify({
                        Title = "Macro Recording",
                        Description = "Saved " .. #getgenv().MacroDataV2 .. " steps to " .. getgenv().CurrentMacro,
                        Lifetime = 5
                    })
                else
                    Window:Notify({
                        Title = "Macro Recording",
                        Description = "Failed to save macro",
                        Lifetime = 3
                    })
                end
            else
                Window:Notify({
                    Title = "Macro Recording",
                    Description = "Recording stopped (no actions recorded)",
                    Lifetime = 3
                })
            end
            
            getgenv().MacroStatusText = "Idle"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroTotalSteps = 0
        end
        getgenv().UpdateMacroStatus()
    end,
    false
)

getgenv().MacroPlayToggle = createToggle(
    Sections.MacroLeft,
    "Play Macro",
    "MacroPlayToggle",
    function(value)
        
        if value then
            if not getgenv().CurrentMacro or getgenv().CurrentMacro == "" then
                Window:Notify({
                    Title = "Macro System",
                    Description = "Please select a macro first",
                    Lifetime = 3
                })
                getgenv().MacroPlayEnabled = false
                pcall(function()
                    getgenv().MacroPlayToggle:UpdateState(false)
                end)
                return
            end
            
            if not getgenv().Macros[getgenv().CurrentMacro] or #getgenv().Macros[getgenv().CurrentMacro] == 0 then
                Window:Notify({
                    Title = "Macro System",
                    Description = "Selected macro is empty",
                    Lifetime = 3
                })
                getgenv().MacroPlayEnabled = false
                pcall(function()
                    getgenv().MacroPlayToggle:UpdateState(false)
                end)
                return
            end
            
            getgenv().MacroPlayEnabled = true
            getgenv().MacroStatusText = "Playing"
            Window:Notify({
                Title = "Macro Playback",
                Description = "Started: " .. getgenv().CurrentMacro .. " (" .. #getgenv().Macros[getgenv().CurrentMacro] .. " steps)",
                Lifetime = 3
            })
        else
            getgenv().MacroPlayEnabled = false
            getgenv().MacroStatusText = "Idle"
            Window:Notify({
                Title = "Macro Playback",
                Description = "Stopped",
                Lifetime = 3
            })
        end
        saveMacroSettings()
        getgenv().UpdateMacroStatus()
    end,
    getgenv().MacroPlayEnabled or false
)

createInput(
    Sections.MacroLeft,
    "Step Delay (seconds)",
    "MacroStepDelay",
    "Additional delay between steps",
    "Numeric",
    function(value)
        local delay = tonumber(value) or 0
        getgenv().MacroStepDelay = delay
        saveMacroSettings()
    end,
    tostring(getgenv().MacroStepDelay or 0)
)

Sections.MacroLeft:Divider()

Sections.MacroLeft:Header({ Text = "📊 Macro Status" })
Sections.MacroLeft:SubLabel({ Text = "Real-time playback information" })

getgenv().MacroStatusLabel = Sections.MacroLeft:Label({ Text = "Status: Idle" })
getgenv().MacroStepLabel = Sections.MacroLeft:Label({ Text = "📝 Step: 0/0" })
getgenv().MacroActionLabel = Sections.MacroLeft:Label({ Text = "⚡ Action: None" })
getgenv().MacroUnitLabel = Sections.MacroLeft:Label({ Text = "🗼 Unit: None" })
getgenv().MacroWaitingLabel = Sections.MacroLeft:Label({ Text = "⏳ Waiting: None" })


Sections.MacroRight:Header({ Text = "🗺️ Macro Maps" })
Sections.MacroRight:SubLabel({
    Text = "Assign macros to specific maps. When you join a game, the assigned macro will auto-load."
})

local selectedGamemode = "Story"
local mapElementsByGamemode = {}

local function updateMacroMapDisplay()
    for gamemode, elements in pairs(mapElementsByGamemode) do
        for _, element in pairs(elements) do
            pcall(function()
                if element and element.SetVisibility then
                    element:SetVisibility(false)
                end
            end)
        end
    end
    
    if mapElementsByGamemode[selectedGamemode] then
        for _, element in pairs(mapElementsByGamemode[selectedGamemode]) do
            pcall(function()
                if element and element.SetVisibility then
                    element:SetVisibility(true)
                end
            end)
        end
        return
    end
    
    mapElementsByGamemode[selectedGamemode] = {}
    local elements = mapElementsByGamemode[selectedGamemode]
    
    local maps = getMapsByMode(selectedGamemode)
    
    if #maps == 0 then
        local label = Sections.MacroRight:SubLabel({
            Text = "No maps available for " .. selectedGamemode
        })
        table.insert(elements, label)
        return
    end
    
    local divider = Sections.MacroRight:Divider()
    local header = Sections.MacroRight:SubLabel({ Text = "📍 " .. selectedGamemode .. " Maps" })
    table.insert(elements, divider)
    table.insert(elements, header)
    
    for _, mapName in ipairs(maps) do
        local key = selectedGamemode .. "_" .. mapName
        local currentMacro = getgenv().MacroMaps[key] or "None"
        
        local macroNames = getMacroNames()
        table.insert(macroNames, 1, "None")
        
        local dropdown = createDropdown(
            Sections.MacroRight,
            mapName,
            "MacroMap_" .. key,
            macroNames,
            false,
            function(value)
                if value ~= "None" then
                    getgenv().MacroMaps[key] = value
                    Window:Notify({
                        Title = "Macro Maps",
                        Description = mapName .. " → " .. value,
                        Lifetime = 2
                    })
                else
                    getgenv().MacroMaps[key] = nil
                    Window:Notify({
                        Title = "Macro Maps",
                        Description = mapName .. " cleared",
                        Lifetime = 2
                    })
                end
                saveMacroSettings()
            end,
            currentMacro
        )
        
        table.insert(elements, dropdown)
    end
end

local savedGamemode = getgenv().Config.dropdowns.MacroMapsGamemode or "Story"
selectedGamemode = savedGamemode

local gamemodeDropdown = createDropdown(
    Sections.MacroRight,
    "Select Gamemode",
    "MacroMapsGamemode",
    {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "Event", "MidnightHunt", "BossRush", "Siege", "Breach"},
    false,
    function(value)
        selectedGamemode = value
        task.spawn(function()
            updateMacroMapDisplay()
        end)
    end,
    savedGamemode
)

task.spawn(function()
    task.wait(0.2)
    updateMacroMapDisplay()
end)




local function getMapsByGamemode(mode)
    if not MapData then return {} end
    if mode == "ElementalCaverns" then return {"Light","Nature","Fire","Dark","Water"} end
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


Sections.WebhookLeft:Header({ Text = "🔔 Discord Integration" })
Sections.WebhookLeft:SubLabel({ Text = "Send game notifications to Discord" })

getgenv().WebhookEnabled = getgenv().Config.toggles.WebhookToggle or false
getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL or ""
getgenv().DiscordUserID = getgenv().Config.inputs.DiscordUserID or ""
getgenv().PingOnSecretDrop = getgenv().Config.toggles.PingOnSecretToggle or false

createToggle(
    Sections.WebhookLeft,
    "Enable Webhook Notifications",
    "WebhookToggle",
    function(value)
        getgenv().WebhookEnabled = value
        if value then
            if (getgenv().WebhookURL == "" or not string.match(getgenv().WebhookURL, "^https://discord%.com/api/webhooks/")) then
                Window:Notify({
                    Title = "Webhook",
                    Description = "Please enter a valid webhook URL first",
                    Lifetime = 5
                })
                getgenv().WebhookEnabled = false
                getgenv().Config.toggles.WebhookToggle = false
                getgenv().SaveConfig(getgenv().Config)
            else
                Window:Notify({
                    Title = "Webhook",
                    Description = "Enabled",
                    Lifetime = 3
                })
            end
        else
            Window:Notify({
                Title = "Webhook",
                Description = "Disabled",
                Lifetime = 3
            })
        end
    end,
    getgenv().WebhookEnabled
)

Sections.WebhookLeft:Divider()

Sections.WebhookLeft:Header({ Text = "⚙️ Configuration" })
Sections.WebhookLeft:SubLabel({ Text = "Enter your Discord webhook details" })

createInput(
    Sections.WebhookLeft,
    "Webhook URL",
    "WebhookURL",
    "https://discord.com/api/webhooks/...",
    "All",
    function(value)
        getgenv().WebhookURL = value or ""
    end,
    getgenv().WebhookURL
)

createInput(
    Sections.WebhookLeft,
    "Discord User ID",
    "DiscordUserID",
    "123456789012345678",
    "Numeric",
    function(value)
        getgenv().DiscordUserID = value or ""
    end,
    getgenv().DiscordUserID
)

Sections.WebhookLeft:Divider()

Sections.WebhookLeft:Header({ Text = "🔔 Notification Preferences" })
Sections.WebhookLeft:SubLabel({ Text = "Customize when you get pinged" })

createToggle(
    Sections.WebhookLeft,
    "Ping on Secret Drop",
    "PingOnSecretToggle",
    function(value)
        getgenv().PingOnSecretDrop = value
        Window:Notify({
            Title = "Ping on Secret",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().PingOnSecretDrop
)


Sections.MiscLeft:Header({ Text = "⚡ Performance" })
Sections.MiscLeft:SubLabel({ Text = "Boost FPS and reduce lag" })

local isInLobby = false
pcall(function()
    local lobbyCheck = workspace:FindFirstChild("Lobby") or game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:find("Lobby")
    isInLobby = lobbyCheck ~= nil
end)

if not isInLobby then
    createToggle(
        Sections.MiscLeft,
        "FPS Boost",
        "FPSBoost",
        function(value)
            getgenv().FPSBoostEnabled = value
            Window:Notify({
                Title = "FPS Boost",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        false
    )
else
    getgenv().FPSBoostEnabled = false
end

createToggle(
    Sections.MiscLeft,
    "Remove Enemies & Units",
    "RemoveEnemies",
    function(value)
        getgenv().RemoveEnemiesEnabled = value
        Window:Notify({
            Title = "Remove Enemies",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    false
)

createToggle(
    Sections.MiscLeft,
    "Black Screen Mode",
    "BlackScreen",
    function(value)
        getgenv().BlackScreenEnabled = value
        Window:Notify({
            Title = "Black Screen",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
        pcall(function()
            local Lighting = game:GetService("Lighting")
            if value then
                Lighting.Brightness = 0
                Lighting.ClockTime = 0
                Lighting.FogEnd = 0
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
            else
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = true
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end
        end)
    end,
    false
)

Sections.MiscLeft:Divider()

Sections.MiscLeft:Header({ Text = "🛡️ Safety" })
Sections.MiscLeft:SubLabel({ Text = "Stay safe and avoid detection" })

createToggle(
    Sections.MiscLeft,
    "Anti-AFK",
    "AntiAFK",
    function(value)
        getgenv().AntiAFKEnabled = value
        Window:Notify({
            Title = "Anti-AFK",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    false
)

createToggle(
    Sections.MiscLeft,
    "Auto Hide UI on Load",
    "AutoHideUI",
    function(value)
        getgenv().AutoHideUIEnabled = value
        Window:Notify({
            Title = "Auto Hide UI",
            Description = value and "Enabled - UI will minimize on next load" or "Disabled",
            Lifetime = 3
        })
    end,
    false
)

createToggle(
    Sections.MiscLeft,
    "Auto Execute on Teleport",
    "AutoExecute",
    function(value)
        getgenv().AutoExecuteEnabled = value
        Window:Notify({
            Title = "Auto Execute",
            Description = value and "Enabled - Script will auto-load on teleport" or "Disabled",
            Lifetime = 3
        })
    end,
    false
)


Sections.MiscRight:Header({ Text = "ℹ️ Information" })
Sections.MiscRight:SubLabel({ Text = "Important notes and warnings" })

Sections.MiscRight:Divider()

Sections.MiscRight:SubLabel({
    Text = "⚠️ Do NOT enable Auto Execute if you already have this script in your executor's auto-execute folder!"
})

Sections.MiscRight:SubLabel({
    Text = "💡 FPS Boost is only available in-game. Remove Enemies and Black Screen Mode provide performance boosts."
})


Sections.SettingsLeft:Header({ Text = "⚙️ UI Settings" })

local menuKeybind = Sections.SettingsLeft:Keybind({
    Name = "Menu Toggle",
    Default = Enum.KeyCode[getgenv().Config.inputs["MenuKeybind"] or "LeftControl"],
    Callback = function(key)
        Window:SetKeybind(key)
        getgenv().Config.inputs["MenuKeybind"] = key.Name
        getgenv().SaveConfig(getgenv().Config)
        Window:Notify({
            Title = "Keybind Updated",
            Description = "Menu toggle set to " .. key.Name,
            Lifetime = 3
        })
    end,
}, "MenuKeybind")

if getgenv().Config.inputs["MenuKeybind"] then
    pcall(function()
        Window:SetKeybind(Enum.KeyCode[getgenv().Config.inputs["MenuKeybind"]])
    end)
end

Sections.SettingsLeft:Divider()

Sections.SettingsLeft:Header({ Text = "💾 Configuration" })

Sections.SettingsLeft:Button({
    Name = "💾 Save Config",
    Callback = function()
        local success = saveConfig(getgenv().Config)
        if success then
            Window:Notify({
                Title = "Config",
                Description = "Settings saved successfully!",
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "Config",
                Description = "Failed to save settings!",
                Lifetime = 5
            })
        end
    end
})

Sections.SettingsLeft:Button({
    Name = "📁 Load Config",
    Callback = function()
        getgenv().Config = loadConfig()
        Window:Notify({
            Title = "Config",
            Description = "Config loaded! Restart script to apply.",
            Lifetime = 5
        })
    end
})

Sections.SettingsRight:Header({ Text = "🔧 Utility Actions" })

Sections.SettingsRight:Button({
    Name = "🌐 Server Hop (Safe)",
    Callback = function()
        Window:Notify({
            Title = "Server Hop",
            Description = "Cleaning up and hopping to new server...",
            Lifetime = 3
        })
        task.spawn(function()
            task.wait(1)
            pcall(function()
                if getgenv().MacroEnabled then
                    getgenv().MacroEnabled = false
                end
                if getgenv().AutoJoinEnabled then
                    getgenv().AutoJoinEnabled = false
                end
            end)
            local ok, err = pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            if not ok then
                warn("[Server Hop] Failed:", err)
                Window:Notify({
                    Title = "Server Hop",
                    Description = "Failed to hop servers!",
                    Lifetime = 5
                })
            end
        end)
    end
})



getgenv().BreachAutoJoin = getgenv().BreachAutoJoin or {}
getgenv().BreachEnabled = getgenv().Config.toggles.BreachToggle or false

Sections.BreachLeft:Header({ Text = "🛡️ Breach Auto-Join" })
Sections.BreachLeft:SubLabel({ Text = "Automatically join specific Breach modes" })

createToggle(
    Sections.BreachLeft,
    "Enable Breach Auto-Join",
    "BreachToggle",
    function(value)
        getgenv().BreachEnabled = value
        Window:Notify({
            Title = "Breach Auto-Join",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().BreachEnabled
)

Sections.BreachLeft:Divider()

Sections.BreachLeft:Header({ Text = "📋 Available Breaches" })
Sections.BreachLeft:SubLabel({ Text = "Select which breaches to auto-join" })

local breachesLoaded = false
pcall(function()
    local mapParamsModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Breach") and RS.Modules.Breach:FindFirstChild("MapParameters")
    if mapParamsModule and mapParamsModule:IsA("ModuleScript") then
        local mapParams = require(mapParamsModule)
        if mapParams and next(mapParams) then
            local breachList = {}
            for breachName, breachInfo in pairs(mapParams) do
                table.insert(breachList, { name = breachName, disabled = breachInfo.Disabled or false })
            end
            table.sort(breachList, function(a,b) return a.name < b.name end)
            
            for _, breach in ipairs(breachList) do
                local breachKey = "Breach_" .. breach.name
                local savedState = getgenv().Config.toggles[breachKey] or false
                
                if not getgenv().BreachAutoJoin[breach.name] then
                    getgenv().BreachAutoJoin[breach.name] = savedState
                end
                
                local statusText = breach.disabled and " [DISABLED]" or ""
                createToggle(
                    Sections.BreachLeft,
                    breach.name .. statusText,
                    breachKey,
                    function(value)
                        getgenv().BreachAutoJoin[breach.name] = value
                    end,
                    savedState
                )
            end
            breachesLoaded = true
        end
    end
end)

if not breachesLoaded then
    Sections.BreachLeft:SubLabel({
        Text = "⚠️ Could not load breach data. The module may not be available."
    })
end


Sections.BreachRight:Header({ Text = "👹 Sukuna's Fingers" })
Sections.BreachRight:SubLabel({ Text = "Automatically unleash Sukuna's fingers" })

getgenv().AutoUnleashSukunaEnabled = getgenv().Config.toggles.AutoUnleashSukunaToggle or false

createToggle(
    Sections.BreachRight,
    "Auto Unleash Sukuna's Fingers",
    "AutoUnleashSukunaToggle",
    function(value)
        getgenv().AutoUnleashSukunaEnabled = value
        Window:Notify({
            Title = "Sukuna's Fingers",
            Description = value and "Auto-unleash enabled" or "Auto-unleash disabled",
            Lifetime = 3
        })
    end,
    getgenv().AutoUnleashSukunaEnabled
)

Sections.BreachRight:Divider()

Sections.BreachRight:SubLabel({
    Text = "When enabled, the script will automatically teleport to and interact with the shrine to unleash Sukuna's fingers."
})


Sections.FinalExpeditionLeft:Header({ Text = "🏔️ Auto Join" })
Sections.FinalExpeditionLeft:SubLabel({ Text = "Automatically join Final Expedition with your preferred difficulty" })

createToggle(
    Sections.FinalExpeditionLeft,
    "Auto Join Easy",
    "FinalExpAutoJoinEasyToggle",
    function(value)
        getgenv().FinalExpAutoJoinEasyEnabled = value
        if value and getgenv().FinalExpAutoJoinHardEnabled then
            getgenv().FinalExpAutoJoinHardEnabled = false
            getgenv().Config.toggles.FinalExpAutoJoinHardToggle = false
            saveConfig(getgenv().Config)
            pcall(function()
                if getgenv().FinalExpAutoJoinHardToggle then
                    getgenv().FinalExpAutoJoinHardToggle:UpdateState(false)
                end
            end)
        end
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Join Easy Enabled" or "Auto Join Easy Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoJoinEasyEnabled
)

local finalExpHardToggle = createToggle(
    Sections.FinalExpeditionLeft,
    "Auto Join Hard",
    "FinalExpAutoJoinHardToggle",
    function(value)
        getgenv().FinalExpAutoJoinHardEnabled = value
        if value and getgenv().FinalExpAutoJoinEasyEnabled then
            getgenv().FinalExpAutoJoinEasyEnabled = false
            getgenv().Config.toggles.FinalExpAutoJoinEasyToggle = false
            saveConfig(getgenv().Config)
            pcall(function()
                if getgenv().FinalExpAutoJoinEasyToggle then
                    getgenv().FinalExpAutoJoinEasyToggle:UpdateState(false)
                end
            end)
        end
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Join Hard Enabled" or "Auto Join Hard Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoJoinHardEnabled
)

getgenv().FinalExpAutoJoinHardToggle = finalExpHardToggle

Sections.FinalExpeditionLeft:SubLabel({
    Text = "⚠️ Only enable ONE auto join option at a time"
})

Sections.FinalExpeditionRight:Header({ Text = "⚙️ Automation" })
Sections.FinalExpeditionRight:SubLabel({ Text = "Additional automation options" })

createToggle(
    Sections.FinalExpeditionRight,
    "Auto Skip Shop",
    "FinalExpAutoSkipShopToggle",
    function(value)
        getgenv().FinalExpAutoSkipShopEnabled = value
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Skip Shop Enabled" or "Auto Skip Shop Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoSkipShopEnabled
)

Sections.FinalExpeditionRight:SubLabel({
    Text = "Automatically skips the shop selection when available"
})


Sections.SeamlessFixLeft:Header({ Text = "🔄 Seamless Fix" })
Sections.SeamlessFixLeft:SubLabel({ Text = "Keep script running across teleports" })

Sections.SeamlessFixLeft:Divider()

Sections.SeamlessFixLeft:Header({ Text = "💡 What is Seamless Fix?" })
Sections.SeamlessFixLeft:SubLabel({
    Text = "Seamless Fix ensures the script continues running smoothly when you teleport between game instances. No need to manually re-execute!"
})

Sections.SeamlessFixLeft:Divider()

Sections.SeamlessFixLeft:Header({ Text = "⚙️ Settings" })

createToggle(
    Sections.SeamlessFixLeft,
    "Enable Seamless Fix",
    "SeamlessFixToggle",
    function(value)
        getgenv().SeamlessFixEnabled = value
        Window:Notify({
            Title = "Seamless Fix",
            Description = value and "Enabled - Script will persist through teleports" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().Config.toggles.SeamlessFixToggle or false
)

createInput(
    Sections.SeamlessFixLeft,
    "Rounds Before Restart",
    "SeamlessRounds",
    "Enter number of rounds (e.g., 4)",
    "Numeric",
    function(value)
        getgenv().SeamlessRounds = tonumber(value) or 4
        Window:Notify({
            Title = "Seamless Fix",
            Description = "Will restart after " .. (tonumber(value) or 4) .. " rounds",
            Lifetime = 3
        })
    end,
    tostring(getgenv().Config.inputs.SeamlessRounds or "4")
)

Sections.SeamlessFixLeft:SubLabel({
    Text = "Script will automatically restart after this many rounds to prevent issues"
})


task.spawn(function()
    task.wait(2)
    
    pcall(function()
        
        local toggleCount = 0
        for flag, value in pairs(getgenv().Config.toggles) do
            local element = MacLib.Flags[flag]
            if element and element.UpdateState then
                pcall(function()
                    element:UpdateState(value)
                    toggleCount = toggleCount + 1
                end)
            end
        end
        
        local inputCount = 0
        for flag, value in pairs(getgenv().Config.inputs) do
            local element = MacLib.Flags[flag]
            if element and element.UpdateText then
                pcall(function()
                    if value ~= nil and value ~= "" then
                        element:UpdateText(tostring(value))
                        inputCount = inputCount + 1
                    end
                end)
            end
        end
        
        local dropdownCount = 0
        for flag, value in pairs(getgenv().Config.dropdowns) do
            local element = MacLib.Flags[flag]
            if element and element.UpdateSelection then
                pcall(function()
                    if value then
                        element:UpdateSelection(value)
                        dropdownCount = dropdownCount + 1
                    end
                end)
            end
        end
        
        
        if getgenv().CurrentMacro and MacLib.Flags["MacroSelect"] then
            pcall(function()
                MacLib.Flags["MacroSelect"]:UpdateSelection(getgenv().CurrentMacro)
            end)
        end
        
        if getgenv().AutoJoinConfig then
            if getgenv().AutoJoinConfig.mode and MacLib.Flags["AutoJoinMode"] then
                pcall(function()
                    MacLib.Flags["AutoJoinMode"]:UpdateSelection(getgenv().AutoJoinConfig.mode)
                end)
            end
            
            if getgenv().AutoJoinConfig.map and MacLib.Flags["AutoJoinMap"] then
                pcall(function()
                    MacLib.Flags["AutoJoinMap"]:UpdateSelection(getgenv().AutoJoinConfig.map)
                end)
            end
            
            if getgenv().AutoJoinConfig.difficulty and MacLib.Flags["AutoJoinDifficulty"] then
                pcall(function()
                    MacLib.Flags["AutoJoinDifficulty"]:UpdateSelection(getgenv().AutoJoinConfig.difficulty)
                end)
            end
        end
        
    end)
end)


local GuiService = game:GetService("GuiService")

local function press(key)
    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)
    end)
end

task.spawn(function()
    local lastEndGameUIInstance = nil
    local hasProcessedCurrentUI = false
    local endGameUIDetectedTime = 0
    
    while true do
        task.wait(0.5)
        local success, errorMsg = pcall(function()
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if endGameUI and endGameUI:FindFirstChild("BG") and endGameUI.BG:FindFirstChild("Buttons") then
                if lastEndGameUIInstance and endGameUI ~= lastEndGameUIInstance then
                    hasProcessedCurrentUI = false
                    lastEndGameUIInstance = endGameUI
                    endGameUIDetectedTime = tick()
                end
                
                if hasProcessedCurrentUI then
                    return
                end
                
                local buttons = endGameUI.BG.Buttons
                local nextButton = buttons:FindFirstChild("Next")
                local retryButton = buttons:FindFirstChild("Retry")
                local leaveButton = buttons:FindFirstChild("Leave")
                
                local buttonToPress, actionName = nil, ""
                
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
                    
                    if getgenv().WebhookEnabled then
                        task.wait(4)
                        local maxWait = 0
                        while getgenv().WebhookProcessing and maxWait < 15 do
                            task.wait(0.5)
                            maxWait = maxWait + 0.5
                        end
                        task.wait(2)
                    end
                    
                    hasProcessedCurrentUI = true
                    
                    local clickAttempts = 0
                    local maxAttempts = 5
                    local clicked = false
                    
                    while clickAttempts < maxAttempts and not clicked do
                        clickAttempts = clickAttempts + 1
                        
                        pcall(function()
                            local isValidDescendant = buttonToPress:IsDescendantOf(LocalPlayer.PlayerGui)
                            if isValidDescendant then
                                GuiService.SelectedObject = buttonToPress
                                task.wait(0.2)
                                press(Enum.KeyCode.Return)
                                task.wait(0.3)
                            end
                            
                            if buttonToPress:IsDescendantOf(LocalPlayer.PlayerGui) then
                                for _, connection in pairs(getconnections(buttonToPress.Activated)) do
                                    connection:Fire()
                                end
                                for _, connection in pairs(getconnections(buttonToPress.MouseButton1Click)) do
                                    connection:Fire()
                                end
                            end
                        end)
                        
                        task.wait(0.5)
                        
                        if not LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") then
                            clicked = true
                        end
                    end
                    
                    if not clicked then
                        warn("[Auto Retry] Failed to click button after " .. maxAttempts .. " attempts")
                    end
                    
                    pcall(function() GuiService.SelectedObject = nil end)
                end
                
                pcall(function()
                    if GuiService.SelectedObject ~= nil then
                        GuiService.SelectedObject = nil
                    end
                end)
            end
        end)
        
        if not success then
            warn("[Auto Leave/Replay] Error in loop: " .. tostring(errorMsg))
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().AutoReadyEnabled then
            local success, err = pcall(function()
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
                                            task.wait(2)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not success then
                warn("[Auto Ready] Error: " .. tostring(err))
            end
        end
    end
end)



local abilityCooldowns = {}
local bossSpawnTime = nil
local generalBossSpawnTime = nil
local bossInRangeTracker = {}
local lastWave = 0
local Towers = workspace:WaitForChild("Towers", 10)

local function getCurrentWave()
    local ok, res = pcall(function()
        local waveValue = RS:FindFirstChild("Wave")
        if waveValue and waveValue:IsA("IntValue") then
            return waveValue.Value
        end
        return 0
    end)
    
    if ok and res > 0 then
        return res
    end
    
    local ok2, res2 = pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if not gui then return 0 end
        local frame = gui:FindFirstChild("Frame")
        if not frame then return 0 end
        local wave = frame:FindFirstChild("Wave")
        if not wave then return 0 end
        local label = wave:FindFirstChild("TextLabel")
        if not label then return 0 end
        local text = label.Text
        local num = tonumber(text:match("%d+"))
        return num or 0
    end)
    return ok2 and res2 or 0
end

local function getCurrentTimeScale()
    local ok, res = pcall(function()
        local timeScale = RS:FindFirstChild("TimeScale")
        if timeScale and timeScale:IsA("NumberValue") then
            return timeScale.Value or 1
        end
        return 1
    end)
    return ok and res or 1
end

local function getUpgradeLevel(tower)
    if not tower then return 0 end
    local ok, res = pcall(function()
        local u = tower:FindFirstChild("Upgrade")
        if u and u:IsA("ValueBase") then return u.Value or 0 end
        return 0
    end)
    return ok and res or 0
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
        pcall(function() RS.Remotes.Ability:InvokeServer(tower, correctedName) end)
    end
end

local function getAbilityData(towerName, abilityName)
    local abilities = getAllAbilities(towerName)
    return abilities[abilityName]
end

local function isOnCooldown(towerName, abilityName)
    local d = getAbilityData(towerName, abilityName)
    if not d or not d.cooldown then return false end
    local key = towerName .. "_" .. abilityName
    local last = abilityCooldowns[key]
    if not last then return false end
    local scale = getCurrentTimeScale()
    local effectiveCd = d.cooldown / scale
    local timeSinceUse = tick() - last
    local cooldownRemaining = effectiveCd - timeSinceUse
    return cooldownRemaining > 0.5
end

local function setAbilityUsed(towerName, abilityName)
    abilityCooldowns[towerName.."_"..abilityName] = tick()
end

local function hasAbilityBeenUnlocked(towerName, abilityName, towerLevel)
    local d = getAbilityData(towerName, abilityName)
    return d and towerLevel >= d.requiredLevel
end

local function bossExists()
    local ok, res = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return false end
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

local function getBossCFrame()
    local ok, res = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        local boss = enemies:FindFirstChild("Boss")
        if not boss then return nil end
        local hrp = boss:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.CFrame end
        return nil
    end)
    return ok and res or nil
end

local function getTowerCFrame(tower)
    if not tower then return nil end
    local ok, res = pcall(function()
        local hrp = tower:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.CFrame end
        return nil
    end)
    return ok and res or nil
end

local function getTowerRange(tower)
    if not tower then return 0 end
    local ok, res = pcall(function()
        local stats = tower:FindFirstChild("Stats")
        if not stats then return 0 end
        local range = stats:FindFirstChild("Range")
        if not range then return 0 end
        return range.Value or 0
    end)
    return ok and res or 0
end

local function isBossInRange(tower)
    local bossCF = getBossCFrame()
    local towerCF = getTowerCFrame(tower)
    if not bossCF or not towerCF then return false end
    local range = getTowerRange(tower)
    if range <= 0 then return false end
    local distance = (bossCF.Position - towerCF.Position).Magnitude
    return distance <= range
end

local function checkBossInRangeForDuration(tower, requiredDuration)
    if not tower then return false end
    local name = tower.Name
    local currentTime = tick()
    if isBossInRange(tower) then
        if requiredDuration == 0 then return true end
        if not bossInRangeTracker[name] then
            bossInRangeTracker[name] = currentTime
            return false
        else
            return (currentTime - bossInRangeTracker[name]) >= requiredDuration
        end
    else
        bossInRangeTracker[name] = nil
    end
    return false
end

local function getTowerInfoName(tower)
    if not tower then return nil end
    return tower.Name
end

local function resetRoundTrackers()
    bossSpawnTime = nil
    generalBossSpawnTime = nil
    bossInRangeTracker = {}
end

local function checkGameEndedReset()
    local ok = pcall(function()
        local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if endGameUI and endGameUI:FindFirstChild("Frame") then
            resetRoundTrackers()
        end
    end)
end



task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            checkGameEndedReset()
            local currentWave = getCurrentWave()
            local hasBoss = bossExists()
            
            if currentWave < lastWave then
                resetRoundTrackers()
            end
            if getgenv().SeamlessFixEnabled and lastWave >= 50 and currentWave < 50 then
                resetRoundTrackers()
            end
            lastWave = currentWave
            
            if not Towers then return end
            if not getgenv().UnitAbilities or type(getgenv().UnitAbilities) ~= "table" then return end
            
            for unitName, abilitiesConfig in pairs(getgenv().UnitAbilities) do
                local tower = Towers:FindFirstChild(unitName)
                if tower then
                    local infoName = getTowerInfoName(tower)
                    local towerLevel = getUpgradeLevel(tower)
                    
                    for abilityName, cfg in pairs(abilitiesConfig) do
                        local savedCfg = getgenv().Config.abilities[unitName] and getgenv().Config.abilities[unitName][abilityName]
                        if savedCfg then
                            cfg.enabled = savedCfg.enabled
                            cfg.onlyOnBoss = savedCfg.onlyOnBoss or false
                            cfg.useOnWave = savedCfg.useOnWave or false
                            cfg.specificWave = savedCfg.specificWave
                            cfg.requireBossInRange = savedCfg.requireBossInRange or false
                        end
                        
                        if cfg.enabled then
                            local shouldUse = true
                            local debugInfo = {}
                            
                            if not hasAbilityBeenUnlocked(infoName, abilityName, towerLevel) then
                                shouldUse = false
                                table.insert(debugInfo, "not unlocked")
                            end
                            
                            if shouldUse and isOnCooldown(infoName, abilityName) then
                                shouldUse = false
                                table.insert(debugInfo, "on cooldown")
                            end
                            
                            if shouldUse and cfg.useOnWave and cfg.specificWave then
                                if currentWave ~= cfg.specificWave then
                                    shouldUse = false
                                    table.insert(debugInfo, "wrong wave (current: " .. currentWave .. ", need: " .. cfg.specificWave .. ")")
                                else
                                    table.insert(debugInfo, "wave OK (" .. currentWave .. ")")
                                end
                            end
                            
                            if shouldUse and cfg.onlyOnBoss then
                                if not hasBoss then
                                    shouldUse = false
                                    table.insert(debugInfo, "no boss")
                                elseif not bossReadyForAbilities() then
                                    shouldUse = false
                                    table.insert(debugInfo, "boss not ready")
                                else
                                    table.insert(debugInfo, "boss OK")
                                end
                            end
                            
                            if shouldUse and cfg.requireBossInRange then
                                if not hasBoss or not checkBossInRangeForDuration(tower, 0) then
                                    shouldUse = false
                                    table.insert(debugInfo, "boss not in range")
                                else
                                    table.insert(debugInfo, "boss in range")
                                end
                            end
                            
                            if shouldUse then
                                if not isOnCooldown(infoName, abilityName) then
                                    useAbility(tower, abilityName)
                                    setAbilityUsed(infoName, abilityName)
                                    
                                    if unitName == "AsuraEvo" and abilityName == "Lines of Sanzu" then
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)



task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().BulmaEnabled then
            local success, err = pcall(function()
                local towers = workspace:FindFirstChild("Towers")
                if not towers then return end
                
                local bulma = towers:FindFirstChild("Bulma")
                if not bulma then return end
                
                local meters = bulma:FindFirstChild("Meters")
                if not meters then return end
                
                local wishBalls = meters:FindFirstChild("Wish Balls")
                if not wishBalls then return end
                
                local attributes = wishBalls:GetAttributes()
                local ballCount = 0
                
                if attributes.Value then
                    ballCount = attributes.Value
                end
                
                if ballCount == 7 and not getgenv().BulmaWishUsedThisRound then
                    getgenv().BulmaWishUsedThisRound = true
                    
                    pcall(function()
                        RS.Remotes.Ability:InvokeServer(bulma, "Summon Wish Dragon")
                    end)
                    task.wait(0.5)
                    
                    local wishType = getgenv().BulmaWishType or "Power"
                    pcall(function()
                        RS.Remotes.Ability:InvokeServer(bulma, "Wish: " .. wishType)
                    end)
                    
                    Window:Notify({
                        Title = "Bulma Auto-Wish",
                        Description = "Used Wish: " .. wishType .. " (1x per round)",
                        Lifetime = 3
                    })
                end
            end)
            
            if not success then
                warn("[Bulma] Error: " .. tostring(err))
            end
        end
    end
end)



task.spawn(function()
    
    local CLONE_UPGRADE_COSTS = {
        [1] = 1750,
        [2] = 3500,
        [3] = 7000,
        [4] = 12500,
        [5] = 25000,
        [6] = 27500,
        [7] = 30250,
        [8] = 55000
    }
    
    local function getPlayerCash()
        local clientData = getClientData()
        if clientData and clientData.Cash then
            return clientData.Cash
        end
        return 0
    end
    
    local function getJinMoriTower()
        local Towers = workspace:FindFirstChild("Towers")
        if not Towers then return nil end
        
        for _, tower in ipairs(Towers:GetChildren()) do
            if tower.Name == "JinMoriGodly" and tower:IsA("Model") then
                return tower
            end
        end
        return nil
    end
    
    local function getJinMoriClones()
        local Towers = workspace:FindFirstChild("Towers")
        if not Towers then return {} end
        
        local clones = {}
        for _, tower in ipairs(Towers:GetChildren()) do
            if tower.Name == "JinMoriGodlyClone" and tower:IsA("Model") then
                table.insert(clones, tower)
            end
        end
        return clones
    end
    
    local function useCloneSynthesis(jinMoriTower)
        if not jinMoriTower then return false end
        
        local success, err = pcall(function()
            local AbilityEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilityEvent")
            if AbilityEvent then
                AbilityEvent:InvokeServer(jinMoriTower, "Clone Synthesis")
                return true
            end
        end)
        
        return success
    end
    
    local function upgradeClone(cloneTower)
        if not cloneTower then return false end
        
        local upgradeValue = cloneTower:FindFirstChild("Upgrade")
        if not upgradeValue then return false end
        
        local currentUpgrade = upgradeValue.Value
        if currentUpgrade >= 8 then return false end 
        
        local nextUpgradeCost = CLONE_UPGRADE_COSTS[currentUpgrade + 1]
        if not nextUpgradeCost then return false end
        
        local cash = tonumber(getPlayerCash()) or 0
        if cash < (tonumber(nextUpgradeCost) or 0) then return false end
        
        local success, err = pcall(function()
            local UpgradeEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("UpgradeEvent")
            if UpgradeEvent then
                UpgradeEvent:InvokeServer(cloneTower)
                return true
            end
        end)
        
        return success
    end
    
    local function useCloneDiffusion(cloneTower)
        if not cloneTower then return false end
        
        local success, err = pcall(function()
            local AbilityEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilityEvent")
            if AbilityEvent then
                AbilityEvent:InvokeServer(cloneTower, "Clone Diffusion")
                return true
            end
        end)
        
        return success
    end
    
    while true do
        task.wait(1)
        
        if not getgenv().WukongEnabled then continue end
        
        local jinMori = getJinMoriTower()
        if not jinMori then continue end
        
        local jinMoriUpgrade = jinMori:FindFirstChild("Upgrade")
        if not jinMoriUpgrade or jinMoriUpgrade.Value < 8 then continue end
        
        local reachingNirvana = jinMori:FindFirstChild("Meters") and jinMori.Meters:FindFirstChild("ReachingNirvana")
        if not reachingNirvana then continue end
        
        local currentNirvana = reachingNirvana:GetAttribute("Value") or 0
        local maxNirvana = reachingNirvana:GetAttribute("MaxValue") or 4
        
        if currentNirvana < maxNirvana then
            local lastSynthesisTime = getgenv()._WukongLastSynthesisTime or 0
            local currentTime = tick()
            
            if currentTime - lastSynthesisTime >= 10 then
                if useCloneSynthesis(jinMori) then
                    getgenv()._WukongLastSynthesisTime = currentTime
                    
                    Window:Notify({
                        Title = "Auto Wukong",
                        Description = "Clone Synthesis used (" .. (currentNirvana + 1) .. "/" .. maxNirvana .. ")",
                        Lifetime = 3
                    })
                    
                    task.wait(1)
                end
            end
        end
        
        local clones = getJinMoriClones()
        for _, clone in ipairs(clones) do
            local cloneUpgrade = clone:FindFirstChild("Upgrade")
            if cloneUpgrade and cloneUpgrade.Value < 8 then
                upgradeClone(clone)
                task.wait(0.5)
            end
        end
        
        for _, clone in ipairs(clones) do
            local cloneUpgrade = clone:FindFirstChild("Upgrade")
            if cloneUpgrade and cloneUpgrade.Value == 8 then
                local cloneId = clone:GetDebugId()
                if not getgenv().WukongTrackedClones[cloneId] then
                    if useCloneDiffusion(clone) then
                        getgenv().WukongTrackedClones[cloneId] = true
                        
                        Window:Notify({
                            Title = "Auto Wukong",
                            Description = "Clone Diffusion used! Nirvana state increased",
                            Lifetime = 3
                        })
                        
                        task.wait(1)
                    end
                end
            end
        end
    end
end)


task.spawn(function()
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" then
            getgenv().BulmaWishUsedThisRound = false
            getgenv().WukongTrackedClones = {}
            getgenv()._WukongLastSynthesisTime = 0
        end
    end)
end)

task.spawn(function()
    local lastWave = 0
    while true do
        task.wait(1)
        pcall(function()
            local wave = RS:FindFirstChild("Wave")
            if wave and wave:IsA("NumberValue") then
                local currentWave = wave.Value
                
                if currentWave < lastWave and currentWave <= 5 then
                    getgenv().BulmaWishUsedThisRound = false
                    getgenv().WukongTrackedClones = {}
                    getgenv()._WukongLastSynthesisTime = 0
                end
                
                lastWave = currentWave
            end
        end)
    end
end)


local function isInLobby()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local lobbyUI = playerGui:FindFirstChild("LobbyUI")
    return lobbyUI ~= nil
end

if isInLobby() then
    task.spawn(function()
        local finalExpRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("FinalExpeditionStart")
        if not finalExpRemote then
            return
        end
        while true do
            task.wait(2)
            if getgenv().FinalExpAutoJoinEasyEnabled then
                pcall(function()
                    finalExpRemote:FireServer("Easy")
                end)
            elseif getgenv().FinalExpAutoJoinHardEnabled then
                pcall(function()
                    finalExpRemote:FireServer("Hard")
                end)
            end
        end
    end)
end

if not isInLobby() then
    task.spawn(function()
        local abilitySelection = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilitySelection")
        if not abilitySelection then
            return
        end
        task.spawn(function()
            while true do
                task.wait(5)
                if getgenv().FinalExpAutoSkipShopEnabled then
                    pcall(function()
                        abilitySelection:FireServer("FinalExpeditionSelection", "Double_Dungeon")
                    end)
                end
            end
        end)
        task.spawn(function()
            while true do
                task.wait(5)
                if getgenv().FinalExpAutoSkipShopEnabled then
                    pcall(function()
                        abilitySelection:FireServer("FinalExpeditionSelection", "Dungeon")
                    end)
                end
            end
        end)
    end)
end


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

local function findBestPortal()
    local clientData = getClientData()
    if not clientData then return nil end
    
    local selectedMap = getgenv().PortalConfig.selectedMap
    local targetTier = getgenv().PortalConfig.tier
    local useBestPortal = getgenv().PortalConfig.useBestPortal
    local priorities = getgenv().PortalConfig.priorities
    
    local matchingPortals = {}
    
    for portalID, portalInfo in pairs(clientData) do
        if type(portalInfo) == "table" and portalInfo.PortalData then
            local portalData = portalInfo.PortalData
            local mapMatch = (selectedMap == "" or portalData.Map == selectedMap)
            
            if mapMatch then
                table.insert(matchingPortals, {
                    id = portalID,
                    tier = portalData.Tier or 0,
                    challenge = portalData.Challenges or "",
                    map = portalData.Map or ""
                })
            end
        end
    end
    
    if #matchingPortals == 0 then return nil end
    
    if useBestPortal then
        table.sort(matchingPortals, function(a, b)
            return a.tier > b.tier
        end)
        return matchingPortals[1].id
    end
    
    local tierFiltered = {}
    for _, portal in ipairs(matchingPortals) do
        if portal.tier == targetTier then
            table.insert(tierFiltered, portal)
        end
    end
    
    if #tierFiltered == 0 then
        return matchingPortals[1].id
    end
    
    local challengePriorityMap = {}
    for challengeName, priorityNum in pairs(priorities) do
        if priorityNum > 0 and priorityNum <= 6 then
            challengePriorityMap[challengeName] = priorityNum
        end
    end
    
    for priority = 1, 6 do
        for challengeName, priorityNum in pairs(challengePriorityMap) do
            if priorityNum == priority then
                for _, portal in ipairs(tierFiltered) do
                    if portal.challenge:lower():find(challengeName:lower()) then
                        return portal.id
                    end
                end
            end
        end
    end
    
    return tierFiltered[1].id
end

local function activatePortal(portalID)
    if not portalID then return false end
    
    local success = pcall(function()
        local portalRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Portals") and RS.Remotes.Portals:FindFirstChild("ActivateEvent")
        if portalRemote then
            portalRemote:InvokeServer(portalID)
            return true
        end
    end)
    
    return success
end

if isInLobby() then
    task.spawn(function()
        while true do
            task.wait(2)
            
            if getgenv().PortalConfig.pickPortal then
                pcall(function()
                    local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                    if promptUI and promptUI:FindFirstChild("Frame") then
                        local frame = promptUI.Frame:FindFirstChild("Frame")
                        if frame then
                            local children = frame:GetChildren()
                            for _, child in ipairs(children) do
                                if child:IsA("Frame") or child:IsA("GuiObject") then
                                    local textButton = child:FindFirstChildOfClass("TextButton", true)
                                    if textButton then
                                        for i, v in pairs(getconnections(textButton.MouseButton1Click)) do
                                            v:Fire()
                                        end
                                        task.wait(0.2)
                                        
                                        local confirmButton = promptUI:FindFirstChild("Confirm", true)
                                        if confirmButton and confirmButton:IsA("TextButton") then
                                            for i, v in pairs(getconnections(confirmButton.MouseButton1Click)) do
                                                v:Fire()
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                local portalID = findBestPortal()
                if portalID then
                    activatePortal(portalID)
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(1)
        
        pcall(function()
            local gamemode = RS:FindFirstChild("Gamemode")
            if gamemode and gamemode.Value == "Portal" then
                if getgenv().AutoNextEnabled or getgenv().AutoSmartEnabled then
                    local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
                    if endGameUI and endGameUI:FindFirstChild("BG") then
                        local buttons = endGameUI.BG:FindFirstChild("Buttons")
                        if buttons then
                            local nextButton = buttons:FindFirstChild("Next")
                            if nextButton and nextButton:FindFirstChild("Styling") then
                                local label = nextButton.Styling:FindFirstChild("Label")
                                if label and label.Text == "View Portals" then
                                    for i, v in pairs(getconnections(nextButton.MouseButton1Click)) do
                                        v:Fire()
                                    end
                                    
                                    task.wait(1)
                                    
                                    if getgenv().PortalConfig.pickPortal then
                                        pcall(function()
                                            local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                                            if promptUI and promptUI:FindFirstChild("Frame") then
                                                local frame = promptUI.Frame:FindFirstChild("Frame")
                                                if frame then
                                                    local children = frame:GetChildren()
                                                    for _, child in ipairs(children) do
                                                        if child:IsA("Frame") or child:IsA("GuiObject") then
                                                            local textButton = child:FindFirstChildOfClass("TextButton", true)
                                                            if textButton then
                                                                for i, v in pairs(getconnections(textButton.MouseButton1Click)) do
                                                                    v:Fire()
                                                                end
                                                                task.wait(0.2)
                                                                
                                                                local confirmButton = promptUI:FindFirstChild("Confirm", true)
                                                                if confirmButton and confirmButton:IsA("TextButton") then
                                                                    for i, v in pairs(getconnections(confirmButton.MouseButton1Click)) do
                                                                        v:Fire()
                                                                    end
                                                                end
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end)
                                    else
                                        local portalID = findBestPortal()
                                        if portalID then
                                            activatePortal(portalID)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)


local function formatNumber(num)
    if not num then return "0" end
    local s = tostring(num)
    s = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if s:sub(1,1) == "," then s = s:sub(2) end
    return s
end

local function SendMessageEMBED(url, embed, content)
    if not url or url == "" then
        warn("[Webhook] Invalid URL provided")
        return false
    end
    
    local success, result = pcall(function()
        local headers = { ["Content-Type"] = "application/json" }
        local data = { 
            embeds = { { 
                title = embed.title, 
                description = embed.description, 
                color = embed.color, 
                fields = embed.fields, 
                footer = embed.footer, 
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z") 
            } } 
        }
        
        if content and content ~= "" then
            data.content = content
        end
        
        local body = HttpService:JSONEncode(data)
        
        local requestFunc = syn and syn.request or http_request or request
        if not requestFunc then
            warn("[Webhook] No request function available")
            return false
        end
        
        local response = requestFunc({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = body
        })
        
        if response and response.StatusCode then
            if response.StatusCode == 204 or response.StatusCode == 200 then
                return true
            else
                warn("[Webhook] Failed with status: " .. response.StatusCode)
                if response.Body then
                    warn("[Webhook] Response: " .. response.Body)
                end
                return false
            end
        end
        
        return true
    end)
    
    if not success then
        warn("[Webhook] Error sending: " .. tostring(result))
        return false
    end
    
    return result
end

local function getRewards()
    local rewards = {}
    local ok, res = pcall(function()
        local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if not ui then return {} end
        local holder = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Rewards") and ui.BG.Container.Rewards:FindFirstChild("Holder")
        if not holder then return {} end
        
        local waitTime = 0
        local lastCount = 0
        local stableCount = 0
        repeat
            task.wait(0.3)
            waitTime = waitTime + 0.3
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
        until (stableCount >= 5 and currentCount > 0) or waitTime > 4
        
        for _, item in pairs(holder:GetChildren()) do
            if item:IsA("TextButton") then
                local rewardName, rewardAmount
                local unitName = item:FindFirstChild("UnitName")
                if unitName and unitName.Text and unitName.Text ~= "" then
                    rewardName = unitName.Text
                end
                local itemName = item:FindFirstChild("ItemName")
                if itemName and itemName.Text and itemName.Text ~= "" then
                    rewardName = itemName.Text
                end
                if rewardName then
                    local amountLabel = item:FindFirstChild("Amount")
                    if amountLabel and amountLabel.Text then
                        local amountText = amountLabel.Text
                        local clean = string.gsub(string.gsub(string.gsub(amountText, "x", ""), "+", ""), ",", "")
                        rewardAmount = tonumber(clean)
                    else
                        rewardAmount = 1
                    end
                    if rewardAmount then
                        table.insert(rewards, { name = rewardName, amount = rewardAmount })
                    end
                end
            end
        end
        return rewards
    end)
    return ok and res or {}
end

local function getMatchResult()
    local ok, time, wave, result = pcall(function()
        local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if not ui then return "00:00:00", "0", "Unknown" end
        local stats = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Stats")
        if not stats then return "00:00:00", "0", "Unknown" end
        
        local r = (stats:FindFirstChild("Result") and stats.Result.Text) or "Unknown"
        local t = (stats:FindFirstChild("ElapsedTime") and stats.ElapsedTime.Text) or "00:00:00"
        local w = (stats:FindFirstChild("EndWave") and stats.EndWave.Text) or "0"
        
        if t:find("Total Time:") then
            local m, s = t:match("Total Time:%s*(%d+):(%d+)")
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
        
        return t, w, r
    end)
    if ok then return time, wave, result else return "00:00:00", "0", "Unknown" end
end

local function getMapInfo()
    local ok, name, difficulty = pcall(function()
        local map = workspace:FindFirstChild("Map")
        if not map then return "Unknown Map", "Unknown" end
        local mapName = map:FindFirstChild("MapName")
        local mapDifficulty = map:FindFirstChild("MapDifficulty")
        return mapName and mapName.Value or "Unknown Map", mapDifficulty and mapDifficulty.Value or "Unknown"
    end)
    if ok then return name, difficulty else return "Unknown Map", "Unknown" end
end


task.spawn(function()
    local lastWebhookHash = ""
    local lastWebhookTime = 0
    local WEBHOOK_COOLDOWN = 10
    local isProcessing = false
    
    local function sendWebhook()
        local success, err = pcall(function()
            if not getgenv().WebhookEnabled then 
                return 
            end
            
            if isProcessing then 
                return 
            end
            
            local currentTime = tick()
            if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then 
                return 
            end
            
            if getgenv()._webhookLock and (currentTime - getgenv()._webhookLock) < 8 then 
                return 
            end
            
            getgenv()._webhookLock = currentTime
            lastWebhookTime = currentTime
            isProcessing = true
            getgenv().WebhookProcessing = true
            
            
            local rewards = getRewards()
            local matchTime, matchWave, matchResult = getMatchResult()
            local mapName, mapDifficulty = getMapInfo()
            local clientData = getClientData()
            
            if not clientData then
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchWave or matchWave == "0" or matchWave == "" then
                warn("[Webhook] Invalid wave data, skipping send")
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchResult or matchResult == "Unknown" or matchResult == "" then
                warn("[Webhook] Invalid match result, skipping send")
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchTime or matchTime == "00:00:00" or matchTime == "" then
                warn("[Webhook] Invalid match time, skipping send")
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            
            local function formatStats()
                local stats = "<:jewel:1217525743408648253> " .. formatNumber(clientData.Gold or 0)
                stats = stats .. "\n<:gold:1265957290251522089> " .. formatNumber(clientData.Jewels or 0)
                stats = stats .. "\n<:emerald:1389165843966984192> " .. formatNumber(clientData.Emeralds or 0)
                stats = stats .. "\n<:rerollshard:1426315987019501598> " .. formatNumber(clientData.Rerolls or 0)
                stats = stats .. "\n<:candybasket:1426304615284084827> " .. formatNumber(clientData.CandyBasket or 0)
                
                local bingoStamps = 0
                if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
                    bingoStamps = clientData.ItemData.HallowenBingoStamp.Amount or 0
                end
                stats = stats .. "\n<:bingostamp:1426362482141954068> " .. formatNumber(bingoStamps)
                
                return stats
            end
            
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
                    
                    rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                end
            else
                rewardsText = "No rewards found"
            end
            
            local unitsText = ""
            if clientData.Slots then
                local slots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
                for _, slotName in ipairs(slots) do
                    local slot = clientData.Slots[slotName]
                    if slot and slot.Value then
                        local level = slot.Level or 0
                        local kills = formatNumber(slot.Kills or 0)
                        local unitName = slot.Value
                        unitsText = unitsText .. "[ " .. level .. " ] " .. unitName .. " = " .. kills .. " ⚔️\n"
                    end
                end
            end
            
            local hasUnitDrop = false
            local unitDropName = ""
            for _, r in ipairs(rewards) do
                if r.name then
                    local isUnit = not (
                        r.name:find("Jewel") or 
                        r.name:find("Gold") or 
                        r.name:find("Emerald") or 
                        r.name:find("Candy") or 
                        r.name:find("Stamp") or
                        r.name:find("Shard") or
                        r.name:find("EXP") or
                        r.name:find("Reroll")
                    )
                    
                    if r.type == "Unit" or isUnit then
                        hasUnitDrop = true
                        unitDropName = r.name
                        break
                    end
                end
            end
            
            local description = "**Username:** ||" .. LocalPlayer.Name .. "||\n**Level:** " .. (clientData.Level or 0) .. " [" .. formatNumber(clientData.EXP or 0) .. "/" .. formatNumber(clientData.MaxEXP or 0) .. "]"
            
            local embed = {
                title = "Anime Last Stand",
                description = description or "N/A",
                color = 0x00ff00,
                fields = {
                    { name = "Player Stats", value = (formatStats() ~= "" and formatStats() or "N/A"), inline = true },
                    { name = "Rewards", value = (rewardsText ~= "" and rewardsText or "No rewards found"), inline = true },
                    { name = "Units", value = (unitsText ~= "" and unitsText or "No units"), inline = false },
                    { name = "Match Result", value = (matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. ((mapDifficulty and mapDifficulty ~= "Unknown") and (" [" .. mapDifficulty .. "]") or "") .. " - " .. (matchResult or "Unknown"), inline = false }
                },
                footer = { text = "ALS Macro System | <https://discord.gg/V3WcdHpd3J>" }
            }
            
            local webhookContent = ""
            if hasUnitDrop then
                
                if getgenv().PingOnSecretDrop and getgenv().DiscordUserID and getgenv().DiscordUserID ~= "" then
                    webhookContent = "<@" .. getgenv().DiscordUserID .. "> 🎉 **SECRET UNIT DROP: " .. unitDropName .. "**"
                else
                end
            end
            
            local webhookHash = LocalPlayer.Name .. "_" .. matchTime .. "_" .. matchWave .. "_" .. rewardsText
            if webhookHash == lastWebhookHash then
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            lastWebhookHash = webhookHash
            
            local sendSuccess = false
            local sendAttempts = 0
            local maxAttempts = 3 
            
            while not sendSuccess and sendAttempts < maxAttempts do
                sendAttempts = sendAttempts + 1
                
                local ok, result = pcall(function()
                    if webhookContent ~= "" then
                        return SendMessageEMBED(getgenv().WebhookURL, embed, webhookContent)
                    else
                        return SendMessageEMBED(getgenv().WebhookURL, embed)
                    end
                end)
                
                if ok and result then
                    sendSuccess = true
                    
                    Window:Notify({
                        Title = "Webhook Sent",
                        Description = hasUnitDrop and "Unit drop detected!" or "Match results sent",
                        Lifetime = 3
                    })
                else
                    warn("[Webhook] ❌ Send failed (Attempt " .. sendAttempts .. "/" .. maxAttempts .. ")")
                    if not ok then
                        warn("[Webhook] Error: " .. tostring(result))
                    end
                    
                    if sendAttempts < maxAttempts then
                        task.wait(1)
                    end
                end
            end
            
            if not sendSuccess then
                warn("[Webhook] Failed to send after " .. maxAttempts .. " attempts")
                Window:Notify({
                    Title = "Webhook Failed",
                    Description = "Failed to send webhook. Check URL and try again.",
                    Lifetime = 5
                })
            end
            
            task.wait(0.5)
            isProcessing = false
            getgenv().WebhookProcessing = false
        end)
        
        if not success then
            warn("[Webhook] Error in sendWebhook: " .. tostring(err))
            isProcessing = false
            getgenv().WebhookProcessing = false
        end
    end
    
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" and getgenv().WebhookEnabled then
            task.wait(2)
            sendWebhook()
        end
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            task.wait(2)
            getgenv().WebhookProcessing = false
        end
    end)
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
                local delay = getgenv().EventJoinDelay or 0
                if delay > 0 then
                    task.wait(delay)
                end
                
                enterEvent:FireServer()
                startEvent:FireServer()
            end)
        end
    end
end)

if isInLobby then
    task.spawn(function()
        local BingoEvents = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("Bingo")
        if not BingoEvents then return end
        
        local UseStampEvent = BingoEvents:FindFirstChild("UseStamp")
        local ClaimRewardEvent = BingoEvents:FindFirstChild("ClaimReward")
        local CompleteBoardEvent = BingoEvents:FindFirstChild("CompleteBoard")
        
        
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
        end
    end)
    
    task.spawn(function()
        task.wait(1)
        local PurchaseEvent = RS:WaitForChild("Events"):WaitForChild("Hallowen2025"):WaitForChild("Purchase")
        local OpenCapsuleEvent = RS:WaitForChild("Remotes"):WaitForChild("OpenCapsule")
        
        local function clickButton(button)
            if not button then return false end
            local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
            for _, ev in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(button[ev])) do
                        conn:Fire()
                    end
                end)
            end
            return true
        end
        
        local function clickAllPromptButtons()
            local success = false
            pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not prompt then return end
                
                local frame = prompt:FindFirstChild("Frame")
                if not frame then return end
                
                local textButton = frame:FindFirstChild("TextButton")
                if textButton then
                    clickButton(textButton)
                    success = true
                end
                
                local folder = frame:FindFirstChild("Folder")
                if folder then
                    local folderButton = folder:FindFirstChild("TextButton")
                    if folderButton then
                        clickButton(folderButton)
                        success = true
                    end
                end
            end)
            return success
        end
        
        while true do
            task.wait(0.1)
            if getgenv().CapsuleEnabled then
                local clientData = getClientData()
                if clientData then
                    local candyBasket = clientData.CandyBasket or 0
                    
                    if candyBasket >= 100000 then
                        pcall(function() PurchaseEvent:InvokeServer(1, 100) end)
                    elseif candyBasket >= 10000 then
                        pcall(function() PurchaseEvent:InvokeServer(1, 10) end)
                    elseif candyBasket >= 1000 then
                        pcall(function() PurchaseEvent:InvokeServer(1, 1) end)
                    end
                    
                    if candyBasket < 1000 then
                        clientData = getClientData()
                        local capsuleAmount = 0
                        if clientData and clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then
                            capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0
                        end
                        
                        if capsuleAmount > 0 then
                            pcall(function()
                                OpenCapsuleEvent:FireServer("HalloweenCapsule2025", capsuleAmount)
                            end)
                            task.wait(0.5)
                            clickAllPromptButtons()
                        end
                    end
                end
            end
        end
    end)
end



local LOBBY_PLACEIDS = {12886143095, 18583778121}
local function checkIsInLobby()
    for _, placeId in ipairs(LOBBY_PLACEIDS) do
        if game.PlaceId == placeId then return true end
    end
    return false
end

if checkIsInLobby() then
    task.spawn(function()
        
        local function getAvailableBreaches()
            local ok, breaches = pcall(function()
                local lobby = workspace:FindFirstChild("Lobby")
                if not lobby then return {} end
                local breachesFolder = lobby:FindFirstChild("Breaches")
                if not breachesFolder then return {} end
                local available = {}
                local children = breachesFolder:GetChildren()
                for i = 1, #children do
                    local part = children[i]
                    local breachPart = part:FindFirstChild("Breach")
                    if breachPart then
                        local proximityPrompt = breachPart:FindFirstChild("ProximityPrompt")
                        if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
                            if proximityPrompt.ObjectText and proximityPrompt.ObjectText ~= "" then
                                local breachName = proximityPrompt.ObjectText
                                available[#available + 1] = { name = breachName, instance = part }
                            end
                        end
                    end
                end
                return available
            end)
            if not ok then return {} end
            return breaches or {}
        end
        
        while true do
            task.wait(1)
            if getgenv().BreachEnabled then
                local availableBreaches = getAvailableBreaches()
                for _, breach in ipairs(availableBreaches) do
                    local shouldJoin = getgenv().BreachAutoJoin[breach.name]
                    if shouldJoin then
                        pcall(function()
                            local remote = RS.Remotes.Breach.EnterEvent
                            remote:FireServer(breach.instance)
                        end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end)
end



task.spawn(function()
    
    local VIM = game:GetService("VirtualInputManager")
    local TweenService = game:GetService("TweenService")
    
    local function teleportToShrine()
        local ok, err = pcall(function()
            local shrine = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shrine")
            if not shrine then return false end
            
            local model = shrine:FindFirstChild("Model")
            if not model then return false end
            
            local proximityPrompt = model:FindFirstChild("ProximityPrompt")
            if not proximityPrompt then return false end
            
            local character = LocalPlayer.Character
            if not character then return false end
            
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return false end
            
            local shrinePosition = model:GetPivot().Position
            humanoidRootPart.CFrame = CFrame.new(shrinePosition + Vector3.new(0, 3, 0))
            
            task.wait(0.3)
            
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            return true
        end)
        
        return ok
    end
    
    local lastAttempt = 0
    
    while true do
        task.wait(1)
        
        if getgenv().AutoUnleashSukunaEnabled then
            local now = tick()
            
            if (now - lastAttempt) >= 5 then
                lastAttempt = now
                
                pcall(function()
                    local shrine = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shrine")
                    if shrine then
                        local model = shrine:FindFirstChild("Model")
                        if model then
                            local proximityPrompt = model:FindFirstChild("ProximityPrompt")
                            if proximityPrompt then
                                teleportToShrine()
                            end
                        end
                    end
                end)
            end
        end
    end
end)



task.spawn(function()
    local VIM = game:GetService("VirtualInputManager")
    
    local function getAvailableCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt")
            if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame")
            if not frame or not frame:FindFirstChild("Frame") then return nil end
            local cards, cardButtons = {}, {}
            local descendants = frame:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                    local text = d.Text
                    if getgenv().CardPriority and getgenv().CardPriority[text] then
                        local button = d.Parent.Parent
                        if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
                            table.insert(cardButtons, {text=text, button=button})
                        end
                    end
                end
            end
            table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
            for i, c in ipairs(cardButtons) do
                cards[i] = { name=c.text, button=c.button }
            end
            return #cards > 0 and cards or nil
        end)
        return ok and result or nil
    end
    
    local function findBestCard(list)
        local bestIndex, bestPriority = nil, math.huge
        for i=1,#list do
            local nm = list[i].name
            local p = (getgenv().CardPriority and getgenv().CardPriority[nm]) or 999
            if p < bestPriority and p < 999 then
                bestPriority = p
                bestIndex = i
            end
        end
        if bestIndex then
            return bestIndex, list[bestIndex], bestPriority
        end
        return nil, nil, nil
    end
    
    local function pressConfirm()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
            if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame")
            if not frame then return nil end
            local inner = frame:FindFirstChild("Frame")
            if not inner then return nil end
            local children = inner:GetChildren()
            if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton")
            if not button then return nil end
            local label = button:FindFirstChild("TextLabel")
            if label and label.Text == "Confirm" then return button end
            return nil
        end)
        if ok and confirmButton then
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(confirmButton[ev])) do
                        conn:Fire()
                    end
                end)
            end
            return true
        end
        return false
    end
    
    local function selectCard()
        if not getgenv().CardSelectionEnabled then return false end
        local ok = pcall(function()
            local list = getAvailableCards()
            if not list then return false end
            local _, best, priority = findBestCard(list)
            if not best or not best.button or not priority then return false end
            if priority >= 999 then return false end
            local button = best.button
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(button[ev])) do
                        conn:Fire()
                    end
                end)
                task.wait(0.05)
            end
            task.wait(0.3)
            pressConfirm()
            task.wait(0.2)
        end)
        return ok
    end
    
    local function selectCardSlower()
        if not getgenv().SlowerCardSelectionEnabled then return false end
        local ok = pcall(function()
            local list = getAvailableCards()
            if not list then return false end
            local _, best, priority = findBestCard(list)
            if not best or not best.button or not priority then return false end
            if priority >= 999 then return false end
            local GuiService = game:GetService("GuiService")
            local function press(key)
                VIM:SendKeyEvent(true, key, false, game)
                task.wait(0.15)
                VIM:SendKeyEvent(false, key, false, game)
            end
            GuiService.SelectedObject = best.button
            task.wait(0.4)
            press(Enum.KeyCode.Return)
            task.wait(0.5)
            local ok2, confirmButton = pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not prompt then return nil end
                local frame = prompt:FindFirstChild("Frame")
                if not frame or not frame:FindFirstChild("Frame") then return nil end
                local inner = frame.Frame
                local children = inner:GetChildren()
                if #children < 5 then return nil end
                local btn = children[5]:FindFirstChild("TextButton")
                if btn and btn:FindFirstChild("TextLabel") and btn.TextLabel.Text == "Confirm" then
                    return btn
                end
                return nil
            end)
            if ok2 and confirmButton then
                GuiService.SelectedObject = confirmButton
                task.wait(0.4)
                press(Enum.KeyCode.Return)
                task.wait(0.5)
            end
            GuiService.SelectedObject = nil
        end)
        return ok
    end
    
    while true do
        task.wait(1.5)
        if getgenv().CardSelectionEnabled then
            selectCard()
        elseif getgenv().SlowerCardSelectionEnabled then
            selectCardSlower()
        end
    end
end)



if not isInLobby then
    task.spawn(function()
        local endgameCount = 0
        local maxRoundsReached = false
        local hasRun = false
        local lastEndgameTime = 0
        local DEBOUNCE_TIME = 3
        
        local maxWait = 0
        repeat 
            task.wait(0.5) 
            maxWait = maxWait + 0.5 
        until LocalPlayer.PlayerGui:FindFirstChild("Settings") or maxWait > 30
        
        
        local function getSeamlessValue()
            local ok, result = pcall(function()
                local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
                if settings then
                    local seamless = settings:FindFirstChild("SeamlessRetry")
                    if seamless then 
                        return seamless.Value 
                    else
                    end
                else
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
        
        local function enableSeamlessIfNeeded()
            if not getgenv().SeamlessFixEnabled then return end
            local maxRounds = getgenv().SeamlessRounds or 4
            
            if endgameCount < maxRounds then
                if not getSeamlessValue() then
                    setSeamlessRetry()
                    task.wait(1)
                end
            elseif endgameCount >= maxRounds then
                if getSeamlessValue() then
                    setSeamlessRetry()
                    task.wait(1)
                end
            end
        end
        
        task.wait(2)
        enableSeamlessIfNeeded()
        
        task.spawn(function()
            while true do
                task.wait(5)
                if getgenv().SeamlessFixEnabled then
                    enableSeamlessIfNeeded()
                end
            end
        end)
        
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            pcall(function()
                if child.Name == "EndGameUI" and not hasRun then
                    local currentTime = tick()
                    if currentTime - lastEndgameTime < DEBOUNCE_TIME then
                        return
                    end
                    hasRun = true
                    lastEndgameTime = currentTime
                    endgameCount = endgameCount + 1
                    local maxRounds = getgenv().SeamlessRounds or 4
                    
                    if endgameCount >= maxRounds and getgenv().SeamlessFixEnabled then
                        maxRoundsReached = true
                        task.wait(1)
                        if getSeamlessValue() then
                            setSeamlessRetry()
                            task.wait(2)
                        end
                        
                        task.spawn(function()
                            local maxWait = 0
                            while LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") and maxWait < 30 do
                                task.wait(0.5)
                                maxWait = maxWait + 0.5
                            end
                            
                            if not LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") then
                                task.wait(2) 
                                local success, err = pcall(function()
                                    local remotes = RS:FindFirstChild("Remotes")
                                    local restartEvent = remotes and remotes:FindFirstChild("RestartMatch")
                                    if restartEvent then
                                        restartEvent:FireServer()
                                        task.wait(3)
                                        endgameCount = 0
                                        maxRoundsReached = false
                                        hasRun = false
                                    end
                                end)
                            end
                        end)
                    else
                        hasRun = false
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
        
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            if child.Name == "TeleportUI" and maxRoundsReached then
                endgameCount = 0
                maxRoundsReached = false
                task.wait(2)
                enableSeamlessIfNeeded()
            end
        end)
    end)
    
end


getgenv().MacroRecording = false
getgenv().MacroData = getgenv().MacroData or {}
getgenv().TowerPlaceCounts = {}
getgenv().MacroCurrentStep = 0
getgenv().MacroTotalSteps = 0
local placementMonitor = {}

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method, args = getnamecallmethod(), {...}
    local remoteName = tostring(self.Name or "")
    
    local result = old(self, ...)
    
    if getgenv().MacroRecording and (method == "FireServer" or method == "InvokeServer") then
        if remoteName:lower():find("place") or remoteName:lower():find("tower") then
            if args[1] then
                task.spawn(function()
                    pcall(function()
                        local towerName = tostring(args[1])
                        local now = tick()
                        local actionKey = towerName .. "_" .. now
                        
                        if placementMonitor[actionKey] then return end
                        placementMonitor[actionKey] = true
                        
                        getgenv().TowerPlaceCounts = getgenv().TowerPlaceCounts or {}
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
                            
                            local cost = 0
                            if getgenv().GetRecentCashDecrease then
                                cost = getgenv().GetRecentCashDecrease(2.5)
                            end
                            
                            local savedArgs = {}
                            savedArgs[1] = args[1]
                            if args[2] and typeof(args[2]) == "CFrame" then
                                savedArgs[2] = {args[2]:GetComponents()}
                            end
                            
                            getgenv().TowerPlaceCounts[towerName] = countAfter
                            
                            table.insert(getgenv().MacroData, {
                                RemoteName = remoteName,
                                Args = savedArgs,
                                Time = now,
                                IsInvoke = (method == "InvokeServer"),
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Place"
                            })
                            
                            getgenv().MacroCurrentStep = #getgenv().MacroData
                            getgenv().MacroTotalSteps = #getgenv().MacroData
                            
                            if getgenv().UpdateMacroStatus then
                                getgenv().UpdateMacroStatus()
                            end
                        end
                        
                        placementMonitor[actionKey] = nil
                    end)
                end)
            end
        end
        
        if remoteName:lower():find("upgrade") then
            task.spawn(function()
                pcall(function()
                    local towerModel = args[1]
                    if not towerModel or not towerModel:IsA("Model") then return end
                    
                    local towerName = towerModel.Name
                    local now = tick()
                    
                    task.wait(0.3)
                    
                    local cost = 0
                    if getgenv().GetRecentCashDecrease then
                        cost = getgenv().GetRecentCashDecrease(1.5)
                    end
                    
                    table.insert(getgenv().MacroData, {
                        RemoteName = "Upgrade",
                        Args = {nil},
                        Time = now,
                        IsInvoke = false,
                        Cost = cost,
                        TowerName = towerName,
                        ActionType = "Upgrade"
                    })
                    
                    getgenv().MacroCurrentStep = #getgenv().MacroData
                    getgenv().MacroTotalSteps = #getgenv().MacroData
                    
                    if getgenv().UpdateMacroStatus then
                        getgenv().UpdateMacroStatus()
                    end
                end)
            end)
        end
    end
    
    return result
end

setreadonly(mt, true)



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

local function isKilled()
    return getgenv().MacroSystemKillSwitch == true
end

local function detectMacroProgress()
    local lastCompletedStep = 0
    
    pcall(function()
        if not getgenv().CurrentMacro or not getgenv().Macros[getgenv().CurrentMacro] then
            return
        end
        
        local macroData = getgenv().Macros[getgenv().CurrentMacro]
        if not macroData or #macroData == 0 then return end
        
        local towerStates = {}
        local playerTowers = workspace:FindFirstChild("Towers")
        if not playerTowers then return end
        
        for _, tower in pairs(playerTowers:GetChildren()) do
            pcall(function()
                local ownerValue = tower:FindFirstChild("Owner")
                if ownerValue and ownerValue.Value == LocalPlayer then
                    local towerName = tower.Name
                    
                    if not towerStates[towerName] then
                        towerStates[towerName] = {
                            count = 0,
                            levels = {}
                        }
                    end
                    
                    towerStates[towerName].count = towerStates[towerName].count + 1
                    
                    local levelValue = tower:FindFirstChild("Level")
                    if levelValue then
                        table.insert(towerStates[towerName].levels, levelValue.Value)
                    end
                end
            end)
        end
        
        local expectedCounts = {}
        local expectedLevels = {}
        
        for i, action in ipairs(macroData) do
            local towerName = action.TowerName
            if towerName then
                if action.ActionType == "Place" then
                    expectedCounts[towerName] = (expectedCounts[towerName] or 0) + 1
                    
                    local actualCount = (towerStates[towerName] and towerStates[towerName].count) or 0
                    if actualCount < expectedCounts[towerName] then
                        lastCompletedStep = i - 1
                        return
                    end
                    
                    if not expectedLevels[towerName] then
                        expectedLevels[towerName] = {}
                    end
                    table.insert(expectedLevels[towerName], 0)
                    
                    lastCompletedStep = i
                    
                elseif action.ActionType == "Upgrade" then
                    if not expectedLevels[towerName] then
                        expectedLevels[towerName] = {}
                    end
                    
                    local instanceIndex = #expectedLevels[towerName]
                    if instanceIndex > 0 then
                        local currentExpectedLevel = expectedLevels[towerName][instanceIndex]
                        local newExpectedLevel = currentExpectedLevel + 1
                        expectedLevels[towerName][instanceIndex] = newExpectedLevel
                        
                        local actualLevels = (towerStates[towerName] and towerStates[towerName].levels) or {}
                        local actualLevel = actualLevels[instanceIndex] or 0
                        
                        if actualLevel < newExpectedLevel then
                            lastCompletedStep = i - 1
                            return
                        end
                        
                        lastCompletedStep = i
                    end
                end
            end
        end
    end)
    
    return lastCompletedStep
end

getgenv().HasStartButton = hasStartButton
getgenv().DetectMacroProgress = detectMacroProgress

task.spawn(function()
    while true do
        task.wait(0.1)
        
        if getgenv().MacroPlayEnabled and not isKilled() then
            pcall(function()
                if not getgenv().CurrentMacro or getgenv().CurrentMacro == "" then
                    getgenv().MacroPlayEnabled = false
                    getgenv().MacroStatusText = "Idle"
                    getgenv().UpdateMacroStatus()
                    return
                end
                
                if not getgenv().Macros[getgenv().CurrentMacro] then
                    getgenv().MacroPlayEnabled = false
                    getgenv().MacroStatusText = "Idle"
                    getgenv().UpdateMacroStatus()
                    return
                end
                
                getgenv().MacroStatusText = "Initializing"
                getgenv().MacroCurrentStep = 0
                getgenv().MacroTotalSteps = #getgenv().Macros[getgenv().CurrentMacro]
                getgenv().UpdateMacroStatus()
                
                ensureCachesReady()
                
                getgenv().MacroStatusText = "Waiting for Start"
                getgenv().UpdateMacroStatus()
                
                local waitStartTime = tick()
                while hasStartButton() and getgenv().MacroPlayEnabled and not isKilled() do
                    task.wait(0.1)
                    local elapsed = math.floor(tick() - waitStartTime)
                    if getgenv().MacroWaitingLabel then
                        getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: " .. elapsed .. "s")
                    end
                end
                
                if isKilled() or not getgenv().MacroPlayEnabled then
                    getgenv().MacroStatusText = "Idle"
                    getgenv().UpdateMacroStatus()
                    return
                end
                
                getgenv().MacroStatusText = "Detecting Progress"
                getgenv().UpdateMacroStatus()
                
                local resumeStep = detectMacroProgress()
                
                if resumeStep > 0 then
                    getgenv().MacroCurrentStep = resumeStep + 1
                    Window:Notify({
                        Title = "Auto-Resume",
                        Description = "Resuming from step " .. (resumeStep + 1),
                        Lifetime = 5
                    })
                else
                    getgenv().MacroCurrentStep = 1
                end
                
                getgenv().MacroStatusText = "Playing"
                getgenv().UpdateMacroStatus()
                
                local step = getgenv().MacroCurrentStep or 1
                local macroData = getgenv().Macros[getgenv().CurrentMacro]
                local shouldRestart = false
                local lastWave = 0
                
                pcall(function()
                    lastWave = RS.Wave.Value
                end)
                
                task.spawn(function()
                    while getgenv().MacroPlayEnabled and not isKilled() do
                        if hasStartButton() then
                            shouldRestart = true
                        end
                        task.wait()
                    end
                    if isKilled() then
                        getgenv().MacroPlayEnabled = false
                    end
                end)
                
                while getgenv().MacroPlayEnabled and not isKilled() do
                    if isKilled() then
                        getgenv().MacroPlayEnabled = false
                        break
                    end
                    
                    if shouldRestart then
                        getgenv().MacroStatusText = "Restart Detected"
                        if getgenv().MacroStatusLabel then
                            getgenv().MacroStatusLabel:UpdateName("Status: Restart Detected")
                        end
                        if getgenv().MacroWaitingLabel then
                            getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: For start...")
                        end
                        
                        repeat 
                            task.wait() 
                        until not hasStartButton() or not getgenv().MacroPlayEnabled or isKilled()
                        
                        if not getgenv().MacroPlayEnabled or isKilled() then break end
                        
                        shouldRestart = false
                        step = 1
                        task.wait(0.5)
                        Window:Notify({
                            Title = "Game Restarted",
                            Description = "Macro restarting from step 1",
                            Lifetime = 3
                        })
                        continue
                    end
                    
                    if step > #macroData then
                        getgenv().MacroStatusText = "Waiting Next Round"
                        if getgenv().MacroStatusLabel then
                            getgenv().MacroStatusLabel:UpdateName("Status: Waiting Next Round")
                        end
                        
                        local currentWave = 0
                        repeat
                            task.wait(0.1)
                            
                            if isKilled() then
                                getgenv().MacroPlayEnabled = false
                                break
                            end
                            
                            pcall(function() 
                                currentWave = RS.Wave.Value 
                            end)
                            
                            if currentWave < lastWave and not hasStartButton() then
                                lastWave = currentWave
                                step = 1
                                task.wait(0.5)
                                Window:Notify({
                                    Title = "Seamless Retry",
                                    Description = "Restarting macro...",
                                    Lifetime = 2
                                })
                                break
                            end
                            
                            lastWave = currentWave
                        until not getgenv().MacroPlayEnabled or isKilled()
                        
                        if not getgenv().MacroPlayEnabled or isKilled() then break end
                        continue
                    end
                    
                    local action = macroData[step]
                    
                    if not action then
                        step = step + 1
                        continue
                    end
                    
                    getgenv().MacroCurrentStep = step
                    getgenv().MacroTotalSteps = #macroData
                    
                    if getgenv().MacroStepLabel then
                        getgenv().MacroStepLabel:UpdateName("📝 Step: " .. step .. "/" .. #macroData)
                    end
                    
                    local cash = tonumber(getgenv().MacroCurrentCash) or 0
                    local actionCost = tonumber(action.Cost) or 0
                    
                    if actionCost > 0 and cash < actionCost then
                        if isKilled() then
                            getgenv().MacroPlayEnabled = false
                            break
                        end
                        
                        if not action.waitStartTime then
                            action.waitStartTime = tick()
                        end
                        
                        local waitTime = tick() - action.waitStartTime
                        
                        getgenv().MacroStatusText = "Waiting Cash"
                        if getgenv().MacroStatusLabel then
                            getgenv().MacroStatusLabel:UpdateName("Status: Waiting Cash")
                        end
                        if getgenv().MacroWaitingLabel then
                            getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: $" .. actionCost .. " (" .. math.floor(waitTime) .. "s)")
                        end
                        if getgenv().MacroActionLabel then
                            getgenv().MacroActionLabel:UpdateName("⚡ Action: " .. (action.ActionType or "Action"))
                        end
                        if getgenv().MacroUnitLabel then
                            getgenv().MacroUnitLabel:UpdateName("🗼 Unit: " .. (action.TowerName or "?"))
                        end
                        
                        RunService.Heartbeat:Wait()
                        continue
                    end
                    
                    action.waitStartTime = nil
                    
                    getgenv().MacroStatusText = "Playing"
                    if getgenv().MacroStatusLabel then
                        getgenv().MacroStatusLabel:UpdateName("Status: Playing")
                    end
                    if getgenv().MacroWaitingLabel then
                        getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: None")
                    end
                    if getgenv().MacroActionLabel then
                        getgenv().MacroActionLabel:UpdateName("⚡ Action: " .. (action.ActionType or "Action"))
                    end
                    if getgenv().MacroUnitLabel then
                        getgenv().MacroUnitLabel:UpdateName("🗼 Unit: " .. (action.TowerName or "?"))
                    end
                    
                    local function isAutoUpgradeClone(towerName)
                        return towerName == "NarutoBaryonClone" or towerName == "WukongClone"
                    end
                    
                    if action.TowerName and action.ActionType == "Upgrade" and isAutoUpgradeClone(action.TowerName) then
                        step = step + 1
                        continue
                    end
                    
                    pcall(function()
                        if not action.RemoteName then
                            return
                        end
                        
                        local remote = getgenv().MacroRemoteCache[action.RemoteName:lower()]
                        if not remote then 
                            return 
                        end
                        
                        if action.RemoteName:lower():find("upgrade") then
                            local towerToUpgrade = nil
                            
                            for _, t in pairs(workspace.Towers:GetChildren()) do
                                if t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer and t.Name == action.TowerName then
                                    towerToUpgrade = t
                                    break
                                end
                            end
                            
                            if not towerToUpgrade then
                                return
                            end
                            
                            local beforeLevel = towerToUpgrade:FindFirstChild("Upgrade") and towerToUpgrade.Upgrade.Value or 0
                            local maxLevel = towerToUpgrade:FindFirstChild("MaxUpgrade") and towerToUpgrade.MaxUpgrade.Value or 999
                            
                            if beforeLevel >= maxLevel then
                                return
                            end
                            
                            if remote:IsA("RemoteFunction") then
                                remote:InvokeServer(towerToUpgrade)
                            else
                                remote:FireServer(towerToUpgrade)
                            end
                            
                            task.wait(0.3)
                            
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
                            
                            task.wait(0.3)
                        end
                    end)
                    
                    step = step + 1
                    
                    local stepDelay = getgenv().MacroStepDelay or 0
                    if stepDelay > 0 then
                        task.wait(stepDelay)
                    else
                        task.wait(0.15)
                    end
                end
                
                getgenv().MacroCurrentStep = 0
                getgenv().MacroStatusText = "Idle"
                if getgenv().MacroStatusLabel then
                    getgenv().MacroStatusLabel:UpdateName("Status: Idle")
                end
                if getgenv().MacroActionLabel then
                    getgenv().MacroActionLabel:UpdateName("⚡ Action: None")
                end
                if getgenv().MacroUnitLabel then
                    getgenv().MacroUnitLabel:UpdateName("🗼 Unit: None")
                end
                if getgenv().MacroWaitingLabel then
                    getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: None")
                end
                if getgenv().MacroStepLabel then
                    getgenv().MacroStepLabel:UpdateName("📝 Step: 0/0")
                end
            end)
        end
    end
end)



task.spawn(function()
    local lastMapKey = nil
    
    while true do
        task.wait(2)
        
        pcall(function()
            local mapNameValue = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MapName")
            local gamemodeValue = RS:FindFirstChild("Gamemode")
            
            if not mapNameValue or not gamemodeValue then return end
            
            local mapName = mapNameValue.Value
            local gamemode = gamemodeValue.Value
            
            if not mapName or not gamemode then return end
            
            local key = gamemode .. "_" .. mapName
            
            if key ~= lastMapKey then
                lastMapKey = key
                
                if getgenv().MacroMaps[key] and getgenv().MacroMaps[key] ~= "None" and getgenv().Macros[getgenv().MacroMaps[key]] then
                    getgenv().CurrentMacro = getgenv().MacroMaps[key]
                    getgenv().MacroData = getgenv().Macros[getgenv().CurrentMacro]
                    getgenv().MacroTotalSteps = #getgenv().MacroData
                    
                    if macroDropdown and macroDropdown.UpdateSelection then
                        pcall(function()
                            macroDropdown:UpdateSelection(getgenv().CurrentMacro)
                        end)
                    end
                    
                    getgenv().UpdateMacroStatus()
                    saveMacroSettings()
                    
                    Window:Notify({
                        Title = "Macro Auto-Load",
                        Description = "Loaded: " .. getgenv().CurrentMacro .. " for " .. mapName,
                        Lifetime = 5
                    })
                end
            end
        end)
    end
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
        blackFrame.Size = UDim2.new(1, 0, 1, 0)
        blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = -999999
        blackFrame.Parent = blackScreenGui
        
        pcall(function()
            blackScreenGui.Parent = LocalPlayer.PlayerGui
        end)
        
        pcall(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.MaxAxisFieldOfView = 0.001
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        
    end
    
    local function removeBlack()
        if blackScreenGui then
            blackScreenGui:Destroy()
            blackScreenGui = nil
            blackFrame = nil
        end
        
        pcall(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.MaxAxisFieldOfView = 70
            end
        end)
        
    end
    
    while true do
        task.wait(0.5)
        if getgenv().BlackScreenEnabled then
            if not blackScreenGui then
                createBlack()
            end
        else
            if blackScreenGui then
                removeBlack()
            end
        end
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
    end
end)

if getgenv().Config.toggles.AutoHideUI then
    task.spawn(function()
        task.wait(2)
        
        if Window and Window.SetState then
            local hideAttempts = 0
            local hideSuccess = false
            
            while hideAttempts < 3 and not hideSuccess do
                hideAttempts = hideAttempts + 1
                local ok = pcall(function()
                    Window:SetState(false)
                    hideSuccess = true
                end)
                
                if ok and hideSuccess then
                    break
                else
                    warn("[Auto Hide] Attempt " .. hideAttempts .. " failed, retrying...")
                    task.wait(0.5)
                end
            end
            
            if not hideSuccess then
                warn("[Auto Hide] Failed to minimize UI after 3 attempts - UI will remain visible")
            end
        else
            warn("[Auto Hide] Window not ready, skipping auto-hide")
        end
    end)
end


if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(10)
            if getgenv().FPSBoostEnabled then
                pcall(function()
                    local lighting = game:GetService("Lighting")
                    for _, child in ipairs(lighting:GetChildren()) do
                        child:Destroy()
                    end
                    lighting.Ambient = Color3.new(1, 1, 1)
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
                                obj.CastShadow = false
                                if obj:FindFirstChildOfClass("Texture") then
                                    for _, t in ipairs(obj:GetChildren()) do
                                        if t:IsA("Texture") then
                                            t:Destroy()
                                        end
                                    end
                                end
                                if obj:IsA("MeshPart") then
                                    obj.TextureID = ""
                                end
                            end
                            if obj:IsA("Decal") then
                                obj:Destroy()
                            end
                        end
                        if obj:IsA("SurfaceAppearance") then
                            obj:Destroy()
                        end
                        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                            obj.Enabled = false
                        end
                        if obj:IsA("Sound") then
                            obj.Volume = 0
                            obj:Stop()
                        end
                    end
                    
                    local mapPath = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Map")
                    if mapPath then
                        for _, ch in ipairs(mapPath:GetChildren()) do
                            if not ch:IsA("Model") then
                                ch:Destroy()
                            end
                        end
                    end
                    
                    collectgarbage("collect")
                end)
            end
        end
    end)
end
