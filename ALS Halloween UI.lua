repeat task.wait() until game:IsLoaded()

if not getgenv()._GlobalConnections then
    getgenv()._GlobalConnections = {}
end

task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            local cleaned = 0
            for i = #getgenv()._GlobalConnections, 1, -1 do
                local conn = getgenv()._GlobalConnections[i]
                if conn and conn.Connected == false then
                    table.remove(getgenv()._GlobalConnections, i)
                    cleaned = cleaned + 1
                end
            end
            
            if getgenv().MacroCashHistory and #getgenv().MacroCashHistory > 10 then
                local temp = {}
                for i = 1, 10 do
                    temp[i] = getgenv().MacroCashHistory[i]
                end
                getgenv().MacroCashHistory = temp
                print("[Memory] Trimmed MacroCashHistory")
            end
            
            if getgenv().SmartCardPicked and #getgenv().SmartCardPicked > 5 then
                getgenv().SmartCardPicked = {}
                print("[Memory] Cleared SmartCardPicked")
            end
            
            if getgenv().SlowerCardPicked and #getgenv().SlowerCardPicked > 5 then
                getgenv().SlowerCardPicked = {}
                print("[Memory] Cleared SlowerCardPicked")
            end
            
            if getgenv().MacroDataV2 and #getgenv().MacroDataV2 > 1000 and not getgenv().MacroRecordingV2 then
                local temp = {}
                for i = 1, 500 do
                    temp[i] = getgenv().MacroDataV2[i]
                end
                getgenv().MacroDataV2 = temp
                print("[Memory] Trimmed MacroDataV2")
            end
            
            local heartbeatConns = 0
            for _, conn in pairs(getconnections(game:GetService("RunService").Heartbeat)) do
                if conn.Function then
                    heartbeatConns = heartbeatConns + 1
                end
            end
            
            if heartbeatConns > 50 then
                print("[Memory] WARNING: " .. heartbeatConns .. " Heartbeat connections detected!")
                local disconnected = 0
                for _, conn in pairs(getconnections(game:GetService("RunService").Heartbeat)) do
                    if disconnected >= 20 then break end
                    pcall(function()
                        if conn.Function and not conn.Disabled then
                            conn:Disable()
                            disconnected = disconnected + 1
                        end
                    end)
                end
                print("[Memory] Disabled " .. disconnected .. " old Heartbeat connections")
            end
            
            if cleaned > 0 then
                print("[Memory] Cleaned up " .. cleaned .. " dead connections")
            end
            
            local workspace = game:GetService("Workspace")
            local debrisFolder = workspace:FindFirstChild("Debris")
            if debrisFolder then
                local debrisCount = #debrisFolder:GetChildren()
                if debrisCount > 50 then
                    for _, item in pairs(debrisFolder:GetChildren()) do
                        pcall(function() item:Destroy() end)
                    end
                    print("[Memory] Cleared " .. debrisCount .. " debris items")
                end
            end
            
            local effectsCleared = 0
            for _, obj in pairs(workspace:GetChildren()) do
                pcall(function()
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or 
                       obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                        obj:Destroy()
                        effectsCleared = effectsCleared + 1
                    end
                end)
            end
            if effectsCleared > 0 then
                print("[Memory] Cleared " .. effectsCleared .. " loose effects")
            end
            
            collectgarbage("collect")
            collectgarbage("collect")
            
            print("[Memory] Cleanup complete - Heartbeat: " .. heartbeatConns)
        end)
    end
end)

if not getgenv()._AutoRejoinSetup then
    getgenv()._AutoRejoinSetup = true
    
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local GuiService = game:GetService("GuiService")
    
    local function autoRejoin()
        print("[Auto Rejoin] Attempting to rejoin game...")
        
        if queueteleport then
            queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/Byorl/ALS-Scripts/refs/heads/main/Maclib.lua"))()')
        end
        
        task.wait(0.5)
        
        local GAME_PLACE_ID = 12886143095
        
        local success, err = pcall(function()
            TeleportService:Teleport(GAME_PLACE_ID, LocalPlayer)
        end)
        
        if not success then
            print("[Auto Rejoin] First attempt failed, retrying in 3s...")
            task.wait(3)
            
            pcall(function()
                TeleportService:Teleport(GAME_PLACE_ID, LocalPlayer)
            end)
        end
    end
    
    game:GetService("CoreGui").ChildAdded:Connect(function(child)
        if child.Name == "RobloxPromptGui" then
            task.wait(0.5)
            
            local found = child:FindFirstChild("promptOverlay", true)
            if found then
                for _, descendant in pairs(found:GetDescendants()) do
                    if descendant:IsA("TextLabel") then
                        local text = descendant.Text:lower()
                        
                        if text:find("disconnect") or 
                           text:find("error") or 
                           text:find("kick") or 
                           text:find("lost connection") or
                           text:find("failed to connect") or
                           text:find("connection attempt failed") or
                           text:find("error code") then
                            
                            print("[Auto Rejoin] Disconnect detected: " .. descendant.Text)
                            task.wait(1)
                            autoRejoin()
                            break
                        end
                    end
                end
            end
        end
    end)
    
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        print("[Auto Rejoin] Error message detected, rejoining...")
        task.wait(1)
        autoRejoin()
    end)
    
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Failed then
            print("[Auto Rejoin] Teleport failed, rejoining...")
            task.wait(2)
            autoRejoin()
        end
    end)
    
    print("[Auto Rejoin] System active - will auto-rejoin on any disconnect")
end

if getgenv().ALSScriptLoaded then
    warn("[ALS] Script already running! Please rejoin the game to reload.")
    return
end
getgenv().ALSScriptLoaded = true

local httpGet = game.HttpGet or game.httpGet or syn and syn.request or http and http.request or request
if not httpGet then
    return
end

local MacLib
local loadSuccess, loadError = pcall(function()
    local url = "https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"
    
    local response
    local httpSuccess = pcall(function()
        if game.HttpGet then
            response = game:HttpGet(url)
        elseif httpGet then
            local result = httpGet({
                Url = url,
                Method = "GET"
            })
            response = result.Body or result
        end
    end)
    
    if not httpSuccess or not response or response == "" then
        error("Failed to download MacLib. Your executor may not support HttpGet or GitHub is blocked.")
    end
    
    local loadFunc, loadErr = loadstring(response)
    if not loadFunc then
        error("Failed to compile MacLib: " .. tostring(loadErr))
    end
    
    MacLib = loadFunc()
end)


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

local function safeGarbageCollect()
    pcall(function()
        gcinfo()
    end)
end

if not getgenv()._ConnectionManager then
    getgenv()._ConnectionManager = {
        connections = {},
        add = function(self, name, connection)
            if self.connections[name] then
                pcall(function() self.connections[name]:Disconnect() end)
            end
            self.connections[name] = connection
        end,
        remove = function(self, name)
            if self.connections[name] then
                pcall(function() self.connections[name]:Disconnect() end)
                self.connections[name] = nil
            end
        end,
        cleanup = function(self)
            for name, conn in pairs(self.connections) do
                pcall(function() conn:Disconnect() end)
            end
            self.connections = {}
        end
    }
end

local ConnectionManager = getgenv()._ConnectionManager

local defaultWidth = 720
local defaultHeight = 480
local customWidth = tonumber(getgenv().Config.inputs.UIWidth) or defaultWidth
local customHeight = tonumber(getgenv().Config.inputs.UIHeight) or defaultHeight

if customWidth < 400 or customWidth > 1920 then customWidth = defaultWidth end
if customHeight < 300 or customHeight > 1080 then customHeight = defaultHeight end

local Window = MacLib:Window({
    Title = "Byorl Last Stand",
    Subtitle = "Anime Last Stand Automation",
    Size = UDim2.fromOffset(customWidth, customHeight),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = false,
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = false,
})

if not Window then
    error("[ALS] Failed to create Window")
    return
end

local globalSettings = {
    UIBlurToggle = Window:GlobalSetting({
        Name = "UI Blur",
        Default = Window:GetAcrylicBlurState(),
        Callback = function(bool)
            Window:SetAcrylicBlurState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " UI Blur",
                Lifetime = 5
            })
        end,
    }),
    NotificationToggler = Window:GlobalSetting({
        Name = "Notifications",
        Default = Window:GetNotificationsState(),
        Callback = function(bool)
            Window:SetNotificationsState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Enabled" or "Disabled") .. " Notifications",
                Lifetime = 5
            })
        end,
    }),
    ShowUserInfo = Window:GlobalSetting({
        Name = "Show User Info",
        Default = Window:GetUserInfoState(),
        Callback = function(bool)
            Window:SetUserInfoState(bool)
            Window:Notify({
                Title = Window.Settings.Title,
                Description = (bool and "Showing" or "Redacted") .. " User Info",
                Lifetime = 5
            })
        end,
    })
}

Window.onUnloaded(function()
    print("[Cleanup] Unloading script and cleaning up resources...")
    
    getgenv().ALSScriptLoaded = false
    getgenv().MacroPlayEnabled = false
    getgenv().MacroRecordingV2 = false
    getgenv().AutoAbilitiesEnabled = false
    
    pcall(function()
        if cashConnection then cashConnection:Disconnect() end
        if cashTrackingConnection then cashTrackingConnection:Disconnect() end
        for tower, conn in pairs(towerTracker.upgradeConnections or {}) do
            if conn then conn:Disconnect() end
        end
    end)
    
    if ConnectionManager then
        ConnectionManager:cleanup()
    end
    
    getgenv().MacroTowerInfoCache = nil
    getgenv().MacroRemoteCache = nil
    getgenv().MacroCashHistory = nil
    getgenv().WukongTrackedClones = nil
    getgenv().SmartCardPicked = nil
    getgenv().SlowerCardPicked = nil
    
    for i = 1, 3 do
        safeGarbageCollect()
    end
    
    print("[Cleanup] Complete")
end)

task.spawn(function()
    local lastPing = 0
    local highPingCount = 0
    local connectionCheckCount = 0
    local startTime = tick()
    
    while task.wait(5) do
        pcall(function()
            connectionCheckCount = connectionCheckCount + 1
            local uptime = (tick() - startTime) / 3600
            
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            
            if ping > 1000 then
                highPingCount = highPingCount + 1
                warn("[Network] High ping: " .. math.floor(ping) .. "ms (" .. highPingCount .. "/3)")
                
                if highPingCount >= 3 then
                    warn("[Network] Persistent high ping - cleaning memory")
                    safeGarbageCollect()
                    highPingCount = 0
                end
            else
                highPingCount = 0
            end
            
            if connectionCheckCount % 360 == 0 then
                print(string.format("[Network] Uptime: %.1fh | Ping: %dms", uptime, math.floor(ping)))
            end
            
            if uptime > 5.5 then
                print("[Network] 5.5h uptime - preemptive memory cleanup")
                safeGarbageCollect()
            end
            
            lastPing = ping
        end)
    end
end)

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

if not getgenv().Config.hasJoinedDiscord then
    Window:Dialog({
        Title = "Join Our Discord!",
        Description = "Have you joined the Byorl Last Stand Discord server? Get updates, support, and connect with the community!",
        Buttons = {
            {
                Name = "Yes, I'm in!",
                Callback = function()
                    getgenv().Config.hasJoinedDiscord = true
                    saveConfig(getgenv().Config)
                    Window:Notify({
                        Title = "Byorl Last Stand",
                        Description = "Awesome! Thanks for being part of the community!",
                        Lifetime = 3
                    })
                end,
            },
            {
                Name = "Not yet",
                Callback = function()
                    getgenv().Config.hasJoinedDiscord = true
                    saveConfig(getgenv().Config)
                    
                    if setclipboard then
                        setclipboard("https://discord.gg/V3WcdHpd3J")
                    end
                    
                    Window:Notify({
                        Title = "Byorl Last Stand",
                        Description = "Discord link copied! Opening in browser...",
                        Lifetime = 5
                    })
                    
                    task.wait(0.5)
                    
                    local success = pcall(function()
                        if request then
                            request({
                                Url = "https://discord.gg/V3WcdHpd3J",
                                Method = "GET"
                            })
                        end
                    end)
                    
                    if not success then
                        Window:Notify({
                            Title = "Byorl Last Stand",
                            Description = "Link copied to clipboard: discord.gg/V3WcdHpd3J",
                            Lifetime = 5
                        })
                    end
                end,
            }
        }
    })
end

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
        if cashConnection then cashConnection:Disconnect() end
        if cashTrackingConnection then cashTrackingConnection:Disconnect() end
        for tower, conn in pairs(towerTracker.upgradeConnections or {}) do
            if conn then conn:Disconnect() end
        end
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
        getgenv().MacroTowerInfoCache = nil
        getgenv().MacroRemoteCache = nil
        getgenv().MacroCashHistory = nil
        getgenv().MacroDataV2 = nil
        towerTracker = {
            placeCounts = {},
            upgradeLevels = {},
            lastPlaceTime = {},
            lastUpgradeTime = {},
            pendingActions = {},
            upgradeConnections = {}
        }
    end)

    
    task.wait(0.2)
end

getgenv().CleanupBeforeTeleport = cleanupBeforeTeleport


MacLib:SetFolder("ALSHalloweenEvent")



local TabGroup1 = Window:TabGroup()

local TabGroup2 = Window:TabGroup()

local TabGroup3 = Window:TabGroup()

local Tabs = {
    Main = TabGroup1:Tab({ 
        Name = "Main", 
        Image = "rbxassetid://10734950309" 
    }),
    AutoPlay = TabGroup1:Tab({ 
        Name = "Auto Play", 
        Image = "rbxassetid://10723407389" 
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
    InfinityCastle = TabGroup2:Tab({ 
        Name = "Infinity Castle", 
        Image = "rbxassetid://10734923549" 
    }),
    
    Webhook = TabGroup3:Tab({ 
        Name = "Webhook", 
        Image = "rbxassetid://10734952273" 
    }),
    SeamlessFix = TabGroup3:Tab({ 
        Name = "Automation", 
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

local function getCurrentMenuKey()
    local keyName = getgenv().Config.inputs["MenuKeybind"] or "LeftControl"
    local success, keyCode = pcall(function()
        return Enum.KeyCode[keyName]
    end)
    return success and keyCode or Enum.KeyCode.LeftControl
end

local function toggleUI()
    local currentKey = getCurrentMenuKey()
    VIM:SendKeyEvent(true, currentKey, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, currentKey, false, game)
end
ToggleButton.MouseButton1Click:Connect(toggleUI)

local Sections = {
    MainLeft = Tabs.Main:Section({ Side = "Left" }),
    MainRight = Tabs.Main:Section({ Side = "Right" }),
    
    AutoPlayLeft = Tabs.AutoPlay:Section({ Side = "Left" }),
    AutoPlayRight = Tabs.AutoPlay:Section({ Side = "Right" }),
    
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
    
    InfinityCastleLeft = Tabs.InfinityCastle:Section({ Side = "Left" }),
    InfinityCastleRight = Tabs.InfinityCastle:Section({ Side = "Right" }),
    
    EventLeft = Tabs.Event:Section({ Side = "Left" }),
    EventRight = Tabs.Event:Section({ Side = "Right" }),
    
    WebhookLeft = Tabs.Webhook:Section({ Side = "Left" }),
    
    SeamlessFixLeft = Tabs.SeamlessFix:Section({ Side = "Left" }),
    SeamlessFixRight = Tabs.SeamlessFix:Section({ Side = "Right" }),
    
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

local function createToggleNoSave(section, name, flag, callback, default)
    name = tostring(name or "Toggle")
    default = default or false
    
    return section:Toggle({
        Name = name,
        Default = default,
        Callback = function(value)
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
        Search = true,
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

local function createSlider(section, name, flag, minimum, maximum, default, callback, displayMethod, precision)
    name = tostring(name or "Slider")
    minimum = minimum or 0
    maximum = maximum or 100
    default = default or minimum
    displayMethod = displayMethod or "Default"
    precision = precision or nil
    
    local savedValue = getgenv().Config.inputs[flag]
    if savedValue ~= nil then
        savedValue = tonumber(savedValue)
        if savedValue then
            default = savedValue
        end
    end
    
    local sliderConfig = {
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
    }
    
    if precision then
        sliderConfig.Precision = precision
    end
    
    return section:Slider(sliderConfig, flag)
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

local cachedLabels = {}
getgenv().UpdateMacroStatus = function()
    local now = tick()
    if now - getgenv().MacroLastStatusUpdate < 0.033 then 
        return 
    end
    getgenv().MacroLastStatusUpdate = now
    
    pcall(function()
        if not cachedLabels.status then cachedLabels.status = getgenv().MacroStatusLabel end
        if not cachedLabels.step then cachedLabels.step = getgenv().MacroStepLabel end
        if not cachedLabels.action then cachedLabels.action = getgenv().MacroActionLabel end
        if not cachedLabels.unit then cachedLabels.unit = getgenv().MacroUnitLabel end
        if not cachedLabels.waiting then cachedLabels.waiting = getgenv().MacroWaitingLabel end
        
        if cachedLabels.status and cachedLabels.status.UpdateName then
            cachedLabels.status:UpdateName("Status: " .. (getgenv().MacroStatusText or "Idle"))
        end
        
        if cachedLabels.step and cachedLabels.step.UpdateName then
            cachedLabels.step:UpdateName("📝 Step: " .. (getgenv().MacroCurrentStep or 0) .. "/" .. (getgenv().MacroTotalSteps or 0))
        end
        
        if cachedLabels.action and cachedLabels.action.UpdateName then
            cachedLabels.action:UpdateName("⚡ Action: " .. (getgenv().MacroActionText ~= "" and getgenv().MacroActionText or "None"))
        end
        
        if cachedLabels.unit and cachedLabels.unit.UpdateName then
            cachedLabels.unit:UpdateName("🗼 Unit: " .. (getgenv().MacroUnitText ~= "" and getgenv().MacroUnitText or "None"))
        end
        
        if cachedLabels.waiting and cachedLabels.waiting.UpdateName then
            cachedLabels.waiting:UpdateName("⏳ Waiting: " .. (getgenv().MacroWaitingText ~= "" and getgenv().MacroWaitingText or "None"))
        end
    end)
end


getgenv().MacroCurrentCash = 0
getgenv().MacroLastCash = 0
getgenv().MacroCashHistory = {}
local MAX_CASH_HISTORY = 30

local cashConnection
pcall(function()
    if LocalPlayer:FindFirstChild("Cash") then
        getgenv().MacroCurrentCash = LocalPlayer.Cash.Value
        cashConnection = LocalPlayer.Cash:GetPropertyChangedSignal("Value"):Connect(function()
            getgenv().MacroCurrentCash = LocalPlayer.Cash.Value
        end)
    end
end)

local cashTrackingActive = false
local cashTrackingConnection
local function trackCash()
    if cashTrackingActive then return end
    cashTrackingActive = true
    
    pcall(function()
        if LocalPlayer:FindFirstChild("Cash") then
            getgenv().MacroLastCash = LocalPlayer.Cash.Value
            
            cashTrackingConnection = LocalPlayer.Cash:GetPropertyChangedSignal("Value"):Connect(function()
                local currentCash = tonumber(LocalPlayer.Cash.Value) or 0
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
                        table.remove(getgenv().MacroCashHistory)
                    end
                end
                
                getgenv().MacroLastCash = currentCash
            end)
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

getgenv().GetUpgradeCost = function(towerName, currentLevel)
    if not getgenv().MacroTowerInfoCache then
        return 0
    end
    
    if not getgenv().MacroTowerInfoCache[towerName] then 
        return 0 
    end
    
    local nextLevel = (currentLevel or 0) + 1
    if getgenv().MacroTowerInfoCache[towerName][nextLevel] then
        return getgenv().MacroTowerInfoCache[towerName][nextLevel].Cost or 0
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
        local modules = RS:FindFirstChild("Modules")
        if not modules then return end
        local towerInfoPath = modules:FindFirstChild("TowerInfo")
        if not towerInfoPath then return end
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
        local modules = RS:FindFirstChild("Modules")
        if not modules then return nil end
        local modulePath = modules:FindFirstChild("ClientData")
        if modulePath and modulePath:IsA("ModuleScript") then
            return require(modulePath)
        end
        return nil
    end)
    return ok and data or nil
end

local function getTowerInfo(unitName)
    local ok, data = pcall(function()
        local modules = RS:FindFirstChild("Modules")
        if not modules then return nil end
        local towerInfoPath = modules:FindFirstChild("TowerInfo")
        if not towerInfoPath then return nil end
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
    local seenAbilities = {}
    
    for level = 0, 50 do
        if towerInfo[level] then
            if towerInfo[level].Ability then
                local a = towerInfo[level].Ability
                local nm = a.Name
                
                if not seenAbilities[nm] then
                    seenAbilities[nm] = true
                    
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
                for idx, a in pairs(towerInfo[level].Abilities) do
                    local nm = a.Name
                    
                    if not seenAbilities[nm] then
                        seenAbilities[nm] = true
                        
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

getgenv().RemoveEnemiesEnabled = getgenv().Config.toggles.RemoveEnemiesToggle or false
getgenv().AntiAFKEnabled = getgenv().Config.toggles.AntiAFKToggle or false
getgenv().BlackScreenEnabled = getgenv().Config.toggles.BlackScreenToggle or false
getgenv().FPSBoostEnabled = getgenv().Config.toggles.FPSBoostToggle or false

getgenv().BossRushEnabled = getgenv().Config.toggles.BossRushToggle or false

getgenv().SeamlessFixEnabled = getgenv().Config.toggles.SeamlessFixToggle or false
getgenv().SeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4
getgenv().AutoExecuteTeleportEnabled = getgenv().Config.toggles.AutoExecuteTeleport or false
getgenv().AutoExecuteEnabled = getgenv().Config.toggles.AutoExecuteToggle or false

local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

if queueteleport then
    LocalPlayer.OnTeleport:Connect(function(State)
        if getgenv().AutoExecuteEnabled then
            pcall(function()
                queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/Byorl/ALS-Scripts/refs/heads/main/Maclib.lua"))()')
                print("[ALS] Auto Execute queued for next game")
            end)
        end
    end)
    
    if getgenv().AutoExecuteEnabled then
        print("[ALS] Auto Execute on Teleport is active")
    end
else
    if getgenv().AutoExecuteEnabled then
        warn("[ALS] Auto Execute enabled but queue_on_teleport not supported by your executor")
    end
end

if getgenv().SeamlessFixEnabled then
    task.spawn(function()
        task.wait(2)
        task.spawn(function()
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                if setSettings then 
                    setSettings:InvokeServer("SeamlessRetry")
                end
            end)
        end)
    end)
end

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
    gameEnded = false,
    lastWaveChange = 0,
    matchStartTime = 0,
    lastGameEndedState = false,
    lastEndGameUIState = false,
    seamlessTransition = false
}

local function updateGameState()
    pcall(function()
        local wave = RS:FindFirstChild("Wave")
        if wave and wave.Value then
            local newWave = wave.Value
            if newWave ~= getgenv().MacroGameState.currentWave then
                getgenv().MacroGameState.lastWaveChange = tick()
                
                if getgenv().MacroGameState.currentWave > 10 and newWave <= 5 then
                    print("[Game State] New game detected via wave reset (" .. getgenv().MacroGameState.currentWave .. " -> " .. newWave .. ")")
                    getgenv().MacroGameState.seamlessTransition = true
                    getgenv().MacroGameState.gameEnded = false
                    getgenv().MacroGameState.matchStartTime = tick()
                end
                
                getgenv().MacroGameState.currentWave = newWave
            end
        end
        
        local hasStart = false
        pcall(function()
            local bottom = LocalPlayer.PlayerGui:FindFirstChild("Bottom")
            if bottom and bottom:FindFirstChild("Frame") then
                for _, child in ipairs(bottom.Frame:GetChildren()) do
                    if child:IsA("Frame") then
                        for _, subChild in ipairs(child:GetChildren()) do
                            if subChild:IsA("TextButton") and subChild.Visible then
                                for _, element in ipairs(subChild:GetChildren()) do
                                    if element:IsA("TextLabel") and element.Text == "Start" then
                                        hasStart = true
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        getgenv().MacroGameState.hasStartButton = hasStart
        
        local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        local currentEndGameUIState = endGameUI and endGameUI.Enabled or false
        
        if getgenv().MacroGameState.lastEndGameUIState and not currentEndGameUIState then
            print("[Game State] EndGameUI removed - seamless transition or new game starting")
            getgenv().MacroGameState.seamlessTransition = true
            getgenv().MacroGameState.gameEnded = false
            getgenv().MacroGameState.hasEndGameUI = false
        end
        
        getgenv().MacroGameState.hasEndGameUI = currentEndGameUIState
        getgenv().MacroGameState.lastEndGameUIState = currentEndGameUIState
        
        local gameEndedValue = RS:FindFirstChild("GameEnded")
        local currentGameEnded = gameEndedValue and gameEndedValue.Value or false
        
        if currentGameEnded and not getgenv().MacroGameState.lastGameEndedState then
            print("[Game State] Game ended detected - cleaning up memory")
            getgenv().MacroGameState.gameEnded = true
            getgenv().MacroGameState.seamlessTransition = false
            
            getgenv().BulmaWishUsedThisRound = false
            getgenv().WukongTrackedClones = {}
            getgenv()._WukongLastSynthesisTime = 0
            getgenv().SmartCardPicked = {}
            getgenv().SmartCardLastPromptId = nil
            getgenv().SlowerCardPicked = {}
            getgenv().SlowerCardLastPromptId = nil
            getgenv().OneEyeDevilCurrentIndex = 0  
            
            if getgenv().MacroCashHistory and #getgenv().MacroCashHistory > 10 then
                local temp = {}
                for i = 1, 10 do
                    temp[i] = getgenv().MacroCashHistory[i]
                end
                getgenv().MacroCashHistory = temp
            end
            
            if getgenv()._EtoEvoAbilityUsed then
                getgenv()._EtoEvoAbilityUsed = {}
            end
            
            pcall(function()
                for i = 1, 3 do
                    safeGarbageCollect()
                    task.wait(0.1)
                end
            end)
            
            print("[Memory] Cleanup complete")
        end
        
        if not currentGameEnded and getgenv().MacroGameState.lastGameEndedState then
            print("[Game State] New game started (GameEnded: true -> false)")
            getgenv().MacroGameState.seamlessTransition = true
            getgenv().MacroGameState.matchStartTime = tick()
        end
        
        getgenv().MacroGameState.lastGameEndedState = currentGameEnded
        getgenv().MacroGameState.isInGame = not getgenv().MacroGameState.hasStartButton and not getgenv().MacroGameState.hasEndGameUI and not currentGameEnded
        
        if getgenv().MacroGameState.seamlessTransition and getgenv().MacroGameState.isInGame then
            task.delay(2, function()
                getgenv().MacroGameState.seamlessTransition = false
            end)
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(1) 
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
    pendingActions = {},
    upgradeConnections = {}
}

local function setupTowerUpgradeListener(tower)
    
    if not tower:FindFirstChild("Upgrade") or towerTracker.upgradeConnections[tower] then 
        return 
    end
    
    local currentLevel = tower.Upgrade.Value
    towerTracker.upgradeLevels[tower] = currentLevel
    
    local connection = tower.Upgrade:GetPropertyChangedSignal("Value"):Connect(function()
        if not getgenv().MacroRecordingV2 then return end
        
        local success, err = pcall(function()
            if not tower or not tower.Parent or not tower:FindFirstChild("Upgrade") then return end
            
            local towerName = tower.Name
            local currentLevel = tower.Upgrade.Value
            local now = tick()
            
            if towerName == "NarutoBaryonClone" or towerName == "WukongClone" then return end
            
            local oldLevel = towerTracker.upgradeLevels[tower] or 0
            if currentLevel <= oldLevel then return end
            
            local levelsGained = currentLevel - oldLevel
            
            towerTracker.upgradeLevels[tower] = currentLevel
            towerTracker.lastUpgradeTime[tower] = now
            
            for i = 1, levelsGained do
                local upgradeLevel = oldLevel + i - 1
                local cost = 0
                
                if getgenv().GetUpgradeCost then
                    cost = getgenv().GetUpgradeCost(towerName, upgradeLevel)
                end
                
                if cost == 0 and getgenv().GetRecentCashDecrease then
                    cost = getgenv().GetRecentCashDecrease(0.3)
                end
                

                
                table.insert(getgenv().MacroDataV2, {
                    RemoteName = "Upgrade",
                    Args = {},
                    Time = now - getgenv().MacroRecordingStartTime,
                    IsInvoke = true,
                    Cost = cost,
                    TowerName = towerName,
                    ActionType = "Upgrade",
                    Wave = getgenv().MacroGameState.currentWave
                })
            end
            
            getgenv().MacroStatusText = "Recording"
            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
            getgenv().MacroActionText = "Upgrade"
            getgenv().MacroUnitText = towerName
            
            if getgenv().UpdateMacroStatus then
                getgenv().UpdateMacroStatus()
            end

        end)
        
        if not success then
            warn("[Macro Debug] Error in upgrade listener:", err)
        end
    end)
    
    towerTracker.upgradeConnections[tower] = connection
    
    local ancestryConnection
    ancestryConnection = tower.AncestryChanged:Connect(function()
        if not tower:IsDescendantOf(game) then
            if towerTracker.upgradeConnections[tower] then
                towerTracker.upgradeConnections[tower]:Disconnect()
                towerTracker.upgradeConnections[tower] = nil
            end
            if towerTracker.upgradeLevels[tower] then
                towerTracker.upgradeLevels[tower] = nil
            end
            if ancestryConnection then
                ancestryConnection:Disconnect()
                ancestryConnection = nil
            end
        end
    end)
end

task.spawn(function()    
    workspace.Towers.ChildAdded:Connect(function(tower)
        task.spawn(function()
            for attempt = 1, 10 do
                task.wait(0.1)
                local owner = tower:FindFirstChild("Owner")
                if owner and owner.Value == LocalPlayer then
                    setupTowerUpgradeListener(tower)
                    return
                end
                if owner then return end
            end
        end)
    end)
    
    task.wait(0.5)
    for _, tower in pairs(workspace.Towers:GetChildren()) do
        local owner = tower:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            setupTowerUpgradeListener(tower)
        end
    end
end)

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
                local owner = tower:FindFirstChild("Owner")
                if tower.Name == towerName and owner and owner.Value == LocalPlayer then
                    countAfter = countAfter + 1
                end
            end
            
            if countAfter > countBefore then
                local cost = getgenv().GetRecentCashDecrease and getgenv().GetRecentCashDecrease(0.3) or 0
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
    
    if remoteNameLower:find("upgrade") then
        if args[1] and typeof(args[1]) == "Instance" then
            local tower = args[1]
            local towerName = tower.Name
            
            if towerName ~= "NarutoBaryonClone" and towerName ~= "WukongClone" then
                local upgradeKey = tower .. "_" .. now
                if not towerTracker.pendingActions[upgradeKey] then
                    towerTracker.pendingActions[upgradeKey] = true
                    
                    task.spawn(function()
                        if towerTracker.pendingActions[upgradeKey] then
                            local currentLevel = 0
                            pcall(function()
                                if tower and tower:FindFirstChild("Upgrade") then
                                    currentLevel = tower.Upgrade.Value
                                end
                            end)
                            
                            local cost = 0
                            if getgenv().GetUpgradeCost then
                                cost = getgenv().GetUpgradeCost(towerName, currentLevel)
                            end
                            
                            if cost == 0 and getgenv().GetRecentCashDecrease then
                                cost = getgenv().GetRecentCashDecrease(0.3)
                            end
                            
                            table.insert(getgenv().MacroDataV2, {
                                RemoteName = "Upgrade",
                                Args = {nil},
                                Time = now - getgenv().MacroRecordingStartTime,
                                IsInvoke = (method == "InvokeServer"),
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Upgrade",
                                Wave = getgenv().MacroGameState.currentWave
                            })
                            
                            getgenv().MacroStatusText = "Recording"
                            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
                            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
                            getgenv().MacroActionText = "Upgrade"
                            getgenv().MacroUnitText = towerName
                            
                            if getgenv().UpdateMacroStatus then
                                getgenv().UpdateMacroStatus()
                            end
                            
                        end
                        
                        towerTracker.pendingActions[upgradeKey] = nil
                    end)
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
    
    task.spawn(function()
        local lastTowerCount = {}
        
        while true do
            task.wait(0.5) 
            
            if not getgenv().MacroRecordingV2 then
                task.wait(1) 
                continue
            end
            
            pcall(function()
                local currentCounts = {}
                
                for _, tower in pairs(workspace.Towers:GetChildren()) do
                    local owner = tower:FindFirstChild("Owner")
                    if owner and owner.Value == LocalPlayer then
                        local towerName = tower.Name
                        currentCounts[towerName] = (currentCounts[towerName] or 0) + 1
                    end
                end
                
                for towerName, count in pairs(currentCounts) do
                    local lastCount = lastTowerCount[towerName] or 0
                    
                    if count > lastCount then
                        local now = tick()
                        
                        local newestTower = nil
                        for _, tower in pairs(workspace.Towers:GetChildren()) do
                            local owner = tower:FindFirstChild("Owner")
                            if tower.Name == towerName and owner and owner.Value == LocalPlayer then
                                local upgrade = tower:FindFirstChild("Upgrade")
                                if not newestTower or (upgrade and upgrade.Value == 0) then
                                    newestTower = tower
                                end
                            end
                        end
                        
                        if newestTower then
                            local cost = getgenv().GetRecentCashDecrease and getgenv().GetRecentCashDecrease(0.3) or 0
                            
                            if cost == 0 and getgenv().GetPlaceCost then
                                cost = getgenv().GetPlaceCost(towerName)
                            end
                            
                            
                            local cframe = newestTower:GetPivot()
                            local savedArgs = {towerName, {cframe:GetComponents()}}
                            
                            table.insert(getgenv().MacroDataV2, {
                                RemoteName = "PlaceTower",
                                Args = savedArgs,
                                Time = now - getgenv().MacroRecordingStartTime,
                                IsInvoke = false,
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Place",
                                Wave = getgenv().MacroGameState.currentWave
                            })
                            
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
                
                lastTowerCount = currentCounts
            end)
        end
    end)
    
    namecallHook = true
end


local function monitorEndGameUI()
    task.spawn(function()
        while true do
            task.wait(0.5)
            
            if getgenv().MacroRecordingV2 and getgenv().MacroGameState.hasEndGameUI then
                getgenv().MacroRecordingV2 = false
                
                pcall(function()
                    if macroRecordToggle then
                        macroRecordToggle:UpdateState(false)
                    end
                end)
                
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
        local towers = {}
        local allTowers = {}
        
        for _, t in pairs(workspace.Towers:GetChildren()) do
            local owner = t:FindFirstChild("Owner")
            if t.Name == action.TowerName and owner and owner.Value == LocalPlayer then
                table.insert(allTowers, t)
                local upgrade = t:FindFirstChild("Upgrade")
                local maxUpgrade = t:FindFirstChild("MaxUpgrade")
                local currentLevel = upgrade and upgrade.Value or 0
                local maxLevel = maxUpgrade and maxUpgrade.Value or 999
                if currentLevel < maxLevel then
                    table.insert(towers, {tower = t, level = currentLevel})
                end
            end
        end
        
        if #allTowers == 0 then
            return false, "No " .. action.TowerName .. " found"
        end
        
        if #towers == 0 then
            return true, "All " .. action.TowerName .. " already max level"
        end
        
        table.sort(towers, function(a, b)
            return a.level < b.level
        end)
        
        local towerData = towers[1]
        local tower = towerData.tower
        
        local cash = tonumber(getgenv().MacroCurrentCash) or 0
        local cost = tonumber(action.Cost) or 0
        
        if cost > 0 and cash < cost then
            return false, "Not enough cash: need $" .. cost .. ", have $" .. cash
        end
        
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(tower)
        else
            remote:FireServer(tower)
        end
        
        task.wait(0.5)
        
        local newLevel = tower:FindFirstChild("Upgrade") and tower.Upgrade.Value or towerData.level
        if newLevel > towerData.level then
            return true, "Upgraded to level " .. newLevel
        else
            return false, "Upgrade may have failed"
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
        if action.Args[2] and type(action.Args[2]) == "table" and #action.Args[2] >= 3 then
            local success, cframe = pcall(function()
                return CFrame.new(unpack(action.Args[2]))
            end)
            if success and cframe then
                args[2] = cframe
            else
                return false, "Invalid position data"
            end
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

local function detectMacroProgress(macroData)
    local towerStates = {}
    
    for _, tower in pairs(workspace.Towers:GetChildren()) do
        local owner = tower:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            local towerName = tower.Name
            local upgrade = tower:FindFirstChild("Upgrade")
            local level = upgrade and upgrade.Value or 0
            
            if not towerStates[towerName] then
                towerStates[towerName] = {count = 0, maxLevel = 0}
            end
            
            towerStates[towerName].count = towerStates[towerName].count + 1
            towerStates[towerName].maxLevel = math.max(towerStates[towerName].maxLevel, level)
        end
    end
    
    local lastCompletedStep = 0
    local expectedTowers = {}
    
    for i, action in ipairs(macroData) do
        if action.ActionType == "Place" then
            local towerName = action.TowerName
            expectedTowers[towerName] = (expectedTowers[towerName] or 0) + 1
            
            if towerStates[towerName] and towerStates[towerName].count >= expectedTowers[towerName] then
                lastCompletedStep = i
            else
                break
            end
            
        elseif action.ActionType == "Upgrade" then
            local towerName = action.TowerName
            
            local expectedLevel = 0
            for j = 1, i do
                if macroData[j].ActionType == "Upgrade" and macroData[j].TowerName == towerName then
                    expectedLevel = expectedLevel + 1
                end
            end
            
            if towerStates[towerName] and towerStates[towerName].maxLevel >= expectedLevel then
                lastCompletedStep = i
            else
                break
            end
        end
    end
    
    
    if lastCompletedStep >= #macroData then
        return -1
    end
    
    return lastCompletedStep + 1
end

local function playMacroV2()
    if getgenv().MacroPlaybackActive then return end
    if not getgenv().CurrentMacro or not getgenv().Macros[getgenv().CurrentMacro] then
        return
    end
    
    getgenv().MacroPlaybackActive = true
    
    task.spawn(function()
        local macroData = getgenv().Macros[getgenv().CurrentMacro]
        if not macroData or #macroData == 0 then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        local step = 1
        
        local elapsedTime = 0
        pcall(function()
            local elapsed = RS:FindFirstChild("ElapsedTime")
            if elapsed and elapsed.Value then
                elapsedTime = elapsed.Value
            end
        end)
        
        if not getgenv().MacroGameState.hasStartButton and getgenv().MacroGameState.currentWave > 0 and elapsedTime > 5 then
            step = detectMacroProgress(macroData)
            
            if step == -1 then
                getgenv().MacroStatusText = "Finished Macro"
                getgenv().MacroWaitingText = "All steps complete"
                getgenv().MacroCurrentStep = #macroData
                getgenv().MacroTotalSteps = #macroData
                getgenv().UpdateMacroStatus()
                getgenv().MacroPlaybackActive = false
                return
            end
            
        end
        
        local elapsedTime = 0
        local currentWave = 0
        
        pcall(function()
            local elapsed = RS:FindFirstChild("ElapsedTime")
            if elapsed and elapsed.Value then
                elapsedTime = elapsed.Value
            end
            
            local wave = RS:FindFirstChild("Wave")
            if wave and wave.Value then
                currentWave = wave.Value
            end
        end)
        
        if currentWave > 0 and elapsedTime > 0 then
        else
            local waitStartTime = tick()
            
            while getgenv().MacroPlayEnabled do
                pcall(function()
                    local elapsed = RS:FindFirstChild("ElapsedTime")
                    if elapsed and elapsed.Value then
                        elapsedTime = elapsed.Value
                    end
                    
                    local wave = RS:FindFirstChild("Wave")
                    if wave and wave.Value then
                        currentWave = wave.Value
                    end
                end)
                
                if currentWave > 0 and elapsedTime > 0 then
                    break
                end
                
                getgenv().MacroStatusText = "Waiting for Start"
                getgenv().MacroWaitingText = "Round not started..."
                getgenv().UpdateMacroStatus()
                
                local elapsed = tick() - waitStartTime
                if elapsed > 300 then
                    print("[Macro] ✗ Timeout waiting for round start (5 minutes)")
                    getgenv().MacroPlaybackActive = false
                    return
                end
                
                task.wait(0.5)
            end
        end
        
        if not getgenv().MacroPlayEnabled then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        task.wait(0.3)
        
        if not getgenv().MacroPlayEnabled then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        getgenv().MacroStatusText = "Playing"
        getgenv().MacroWaitingText = ""
        getgenv().UpdateMacroStatus()
        
        local lastCashCheck = 0
        local lastWaveCheck = getgenv().MacroGameState.currentWave
        
        while getgenv().MacroPlayEnabled and step <= #macroData do
            if getgenv().IsKilled and getgenv().IsKilled() then
                break
            end
            
            local currentWave = getgenv().MacroGameState.currentWave
            local elapsedTime = 0
            pcall(function()
                local elapsed = RS:FindFirstChild("ElapsedTime")
                if elapsed and elapsed.Value then
                    elapsedTime = elapsed.Value
                end
            end)
            
            if lastWaveCheck > 5 and currentWave == 1 and elapsedTime < 30 then
                getgenv().MacroStatusText = "Wave Reset - Restarting Macro"
                getgenv().MacroWaitingText = "Detected wave reset..."
                getgenv().UpdateMacroStatus()
                step = 1
                lastWaveCheck = currentWave
                task.wait(2)
                continue
            end
            lastWaveCheck = currentWave
            
            if getgenv().MacroGameState.gameEnded or getgenv().MacroGameState.hasEndGameUI then
                getgenv().MacroStatusText = "Game Ended"
                getgenv().MacroWaitingText = "Auto-restart will handle next round..."
                getgenv().UpdateMacroStatus()
                getgenv().MacroPlaybackActive = false
                return
            end
            
            if getgenv().MacroGameState.hasStartButton or getgenv().MacroGameState.currentWave == 0 then
                getgenv().MacroStatusText = "Restart Detected"
                getgenv().MacroWaitingText = "Waiting for game start..."
                getgenv().UpdateMacroStatus()
                
                while (getgenv().MacroGameState.hasStartButton or getgenv().MacroGameState.currentWave == 0) and getgenv().MacroPlayEnabled do
                    task.wait(0.1)
                end
                
                if not getgenv().MacroPlayEnabled then
                    break
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
            
            local shouldSkipStep = false
            
            if cost > 0 and cash < cost then
                getgenv().MacroStatusText = "Waiting Cash"
                getgenv().MacroWaitingText = "$" .. cost .. " (have $" .. cash .. ")"
                getgenv().UpdateMacroStatus()
                
                local cashWaitStart = tick()
                local maxCashWait = 300
                local lastCash = cash
                local noIncomeTime = 0
                
                while getgenv().MacroPlayEnabled do
                    task.wait(0.1)
                    cash = tonumber(getgenv().MacroCurrentCash) or 0
                    
                    if cash >= cost then 
                        break 
                    end
                    
                    if cash > lastCash then
                        noIncomeTime = 0
                    else
                        noIncomeTime = noIncomeTime + 0.1
                    end
                    lastCash = cash
                    
                    local waitTime = tick() - cashWaitStart
                    
                    if waitTime > maxCashWait then
                        shouldSkipStep = true
                        break
                    end
                    
                    if noIncomeTime > 60 and waitTime > 30 then
                        shouldSkipStep = true
                        break
                    end
                    
                    getgenv().MacroWaitingText = "$" .. cost .. " (have $" .. cash .. ") - " .. math.floor(waitTime) .. "s"
                    getgenv().UpdateMacroStatus()
                end
                
                if not getgenv().MacroPlayEnabled then break end
            end
            
            if shouldSkipStep then
                getgenv().MacroStatusText = "Skipping - Not Enough Cash"
                getgenv().MacroWaitingText = "Needed $" .. cost .. ", have $" .. cash
                getgenv().UpdateMacroStatus()
                task.wait(2)
                step = step + 1
                continue
            end
            
            getgenv().MacroStatusText = "Playing"
            getgenv().MacroWaitingText = ""
            getgenv().UpdateMacroStatus()
            
            local actionSuccess = false
            local actionMessage = ""
            
            local success, result, msg = pcall(function()
                return executeAction(action)
            end)
            
            if success and result then
                actionSuccess = true
                actionMessage = msg or "Success"
                print("[Macro] Step", step, "SUCCESS")
            else
                actionMessage = msg or "Action failed"
                print("[Macro] Step", step, "FAILED:", actionMessage)
            end
            
            if not actionSuccess then
                getgenv().MacroStatusText = "Step Failed - Continuing"
                getgenv().MacroWaitingText = actionMessage
                getgenv().UpdateMacroStatus()
                task.wait(0.5)
            end
            
            step = step + 1
            
            task.wait(0.3)
            
            local stepDelay = getgenv().MacroStepDelay or 0
            if stepDelay > 0 then
                task.wait(stepDelay)
            else
                task.wait(0.15)
            end
        end
        
        if step > #macroData then
            getgenv().MacroStatusText = "Macro Complete"
            getgenv().MacroWaitingText = "Waiting for game end..."
            getgenv().MacroCurrentStep = #macroData
            getgenv().MacroTotalSteps = #macroData
            getgenv().MacroActionText = "Complete"
            getgenv().MacroUnitText = ""
            getgenv().UpdateMacroStatus()
            
            getgenv().MacroPlaybackActive = false
            return
        else
            getgenv().MacroStatusText = "Idle"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroActionText = ""
            getgenv().MacroUnitText = ""
            getgenv().MacroWaitingText = ""
            getgenv().UpdateMacroStatus()
        end
        
        getgenv().MacroPlaybackActive = false
    end)
end

setupRecordingHook()
monitorEndGameUI()

task.spawn(function()
    local lastRestartAttempt = 0
    local lastEndGameUIState = false
    
    while true do
        task.wait(0.3)
        
        local currentEndGameUIState = false
        pcall(function()
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            currentEndGameUIState = endGameUI and endGameUI.Enabled or false
        end)
        
        if lastEndGameUIState and not currentEndGameUIState and getgenv().MacroPlayEnabled then
            task.wait(1)
            
            getgenv().MacroPlaybackActive = false
            getgenv().MacroStatusText = "Idle"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroActionText = ""
            getgenv().MacroUnitText = ""
            getgenv().MacroWaitingText = ""
            
            getgenv().MacroGameState.gameEnded = false
            getgenv().MacroGameState.hasEndGameUI = false
            getgenv().MacroGameState.lastGameEndedState = false
            
            getgenv().UpdateMacroStatus()
            
            task.wait(0.5)
            
            playMacroV2()
            lastRestartAttempt = tick()
        end
        
        lastEndGameUIState = currentEndGameUIState
        
        if getgenv().MacroPlayEnabled and not getgenv().MacroPlaybackActive then
            local now = tick()
            if now - lastRestartAttempt > 3 then                
                getgenv().MacroGameState.gameEnded = false
                getgenv().MacroGameState.hasEndGameUI = false
                getgenv().MacroGameState.lastGameEndedState = false
                
                lastRestartAttempt = now
                playMacroV2()
            end
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
    if mode == "FinalExpedition" then mode = "Story" end
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

local autoJoinModeList = {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "BossRush", "Siege"}

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
    
    if autoJoinModeDropdown and modeDefault then
        task.spawn(function()
            task.wait(0.1)
            pcall(function()
                autoJoinModeDropdown:UpdateSelection(modeDefault)
            end)
        end)
    end
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

task.spawn(function()
    while true do
        task.wait(0.5)
        
        if getgenv().AutoJoinConfig and getgenv().AutoJoinConfig.enabled then
            pcall(function()
                local mode = getgenv().AutoJoinConfig.mode
                if not mode then return end
                
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local teleporterFolder = workspace:FindFirstChild("TeleporterFolder")
                if not teleporterFolder then return end
                
                local doorFolder
                
                if mode == "Raid" then
                    doorFolder = teleporterFolder:FindFirstChild("Raids")
                elseif mode == "Siege" then
                    doorFolder = teleporterFolder:FindFirstChild("Siege")
                elseif mode == "Dungeon" then
                    doorFolder = teleporterFolder:FindFirstChild("Dungeon")
                elseif mode == "Survival" then
                    doorFolder = teleporterFolder:FindFirstChild("Survival")
                elseif mode == "Story" or mode == "Infinite" or mode == "LegendaryStages" then
                    doorFolder = teleporterFolder:FindFirstChild("Story")
                elseif mode == "Elemental Cavern" then
                    doorFolder = teleporterFolder:FindFirstChild("ElementalCaverns")
                elseif mode == "Challenge" then
                    doorFolder = teleporterFolder:FindFirstChild("Challenge")
                end
                
                if doorFolder then
                    for _, teleporter in pairs(doorFolder:GetChildren()) do
                        if teleporter:IsA("Model") and teleporter.Name == "Teleporter" then
                            local door = teleporter:FindFirstChild("Door")
                            if door and door:IsA("BasePart") then
                                hrp.CFrame = door.CFrame
                                return
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if not getgenv().AutoJoinConfig or not getgenv().AutoJoinConfig.enabled then
            continue
        end
        
        pcall(function()
            local mode = getgenv().AutoJoinConfig.mode
            local map = getgenv().AutoJoinConfig.map
            local act = getgenv().AutoJoinConfig.act or 1
            local difficulty = getgenv().AutoJoinConfig.difficulty or "Normal"
            
            if not mode or not map then return end
            
            local teleporter = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Teleporter")
            if not teleporter then return end
            
            if getgenv().AutoJoinConfig.friendsOnly then
                teleporter.Interact:FireServer("FriendsOnly")
            end
            
            if mode == "Raid" then
                teleporter.Interact:FireServer("Select", map, act)
                
            elseif mode == "Siege" then
                local siegeDiff = difficulty
                if difficulty == "Purgatory" or difficulty == "Insanity" then
                    siegeDiff = "Bounded"
                elseif difficulty == "Normal" or difficulty == "Nightmare" then
                    siegeDiff = "Normal"
                end
                teleporter.Select:FireServer(map, siegeDiff)
                
            elseif mode == "Dungeon" then
                teleporter.Interact:FireServer("Select", map)
                
            elseif mode == "Survival" then
                teleporter.Interact:FireServer("Select", map)
                
            elseif mode == "Story" then
                local storyDiff = difficulty
                if difficulty == "Purgatory" or difficulty == "Insanity" then
                    storyDiff = "Nightmare"
                end
                teleporter.Interact:FireServer("Select", map, act, storyDiff, "Story")
                
            elseif mode == "Infinite" then
                local infDiff = difficulty
                if difficulty == "Purgatory" or difficulty == "Insanity" then
                    infDiff = "Nightmare"
                end
                teleporter.Interact:FireServer("Select", map, act, infDiff, "Infinite")
                
            elseif mode == "Elemental Cavern" then
                teleporter.Interact:FireServer("Select", map, difficulty)
                
            elseif mode == "Challenge" then
                teleporter.Interact:FireServer("Select", "Challenge", act)
            end
            
            if getgenv().AutoJoinConfig.autoStart then
                task.wait(0.5)
                
                local teleporter = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Teleporter")
                if teleporter and teleporter:FindFirstChild("Interact") then
                    teleporter.Interact:FireServer("Skip")
                end
            end
        end)
    end
end)

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
            getgenv().Config.toggles.AutoNext = value
            saveConfig(getgenv().Config)
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
            getgenv().Config.toggles.AutoRetry = value
            saveConfig(getgenv().Config)
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
            getgenv().Config.toggles.AutoLeave = value
            saveConfig(getgenv().Config)
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
            getgenv().Config.toggles.AutoSmart = value
            saveConfig(getgenv().Config)
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

pcall(function()
    local babyloniaModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards"):FindFirstChild("Babylonia Castle")
    if babyloniaModule then
        local cards = require(babyloniaModule)
        for _, card in pairs(cards) do
            if card.CardName then
                getgenv().BabyloniaCastle[card.CardName] = card
            end
        end
        print("[Boss Rush] Loaded " .. #cards .. " Babylonia Castle cards")
    end
end)

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
    useSelectedTier = savedPortalConfig.useSelectedTier or false,
    pickPortal = savedPortalConfig.pickPortal or false,
    autoPickReward = savedPortalConfig.autoPickReward or false,
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
        
        if value and getgenv().PortalConfig.useSelectedTier then
            getgenv().PortalConfig.useSelectedTier = false
            getgenv().Config.portals.useSelectedTier = false
            saveConfig(getgenv().Config)
            pcall(function()
                if MacLib.Flags["UseSelectedTier"] then
                    MacLib.Flags["UseSelectedTier"]:UpdateState(false)
                end
            end)
        end
        
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Will use highest tier portal available" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.useBestPortal
)

createToggle(
    Sections.PortalsRight,
    "Use Selected Tier",
    "UseSelectedTier",
    function(value)
        getgenv().PortalConfig.useSelectedTier = value
        getgenv().Config.portals.useSelectedTier = value
        
        if value and getgenv().PortalConfig.useBestPortal then
            getgenv().PortalConfig.useBestPortal = false
            getgenv().Config.portals.useBestPortal = false
            saveConfig(getgenv().Config)
            pcall(function()
                if MacLib.Flags["UseBestPortal"] then
                    MacLib.Flags["UseBestPortal"]:UpdateState(false)
                end
            end)
        end
        
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Will use selected map and tier" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.useSelectedTier or false
)

createToggle(
    Sections.PortalsRight,
    "Auto Pick Portal Reward",
    "AutoPickPortalReward",
    function(value)
        getgenv().PortalConfig.autoPickReward = value
        getgenv().Config.portals.autoPickReward = value
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Auto pick portal reward enabled" or "Auto pick portal reward disabled",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.autoPickReward or false
)

Sections.PortalsRight:SubLabel({
    Text = "⚠️ Portal rewards are selected randomly (fast method)"
})

Sections.PortalsRight:Divider()

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


Sections.InfinityCastleLeft:Header({ Text = "🏯 Auto Join Infinity Castle" })
Sections.InfinityCastleLeft:SubLabel({ Text = "Automatically join Infinity Castle with your preferred difficulty" })

if not getgenv().InfinityCastleAutoJoinEnabled then
    getgenv().InfinityCastleAutoJoinEnabled = getgenv().Config.toggles.InfinityCastleAutoJoinToggle or false
end

if not getgenv().InfinityCastleDifficulty then
    getgenv().InfinityCastleDifficulty = getgenv().Config.inputs.InfinityCastleDifficulty or "Easy"
end

createToggle(
    Sections.InfinityCastleLeft,
    "Auto Join Infinity Castle",
    "InfinityCastleAutoJoinToggle",
    function(value)
        getgenv().InfinityCastleAutoJoinEnabled = value
        Window:Notify({
            Title = "Infinity Castle",
            Description = value and "Auto Join Enabled" or "Auto Join Disabled",
            Lifetime = 3
        })
    end,
    getgenv().InfinityCastleAutoJoinEnabled
)

createDropdown(
    Sections.InfinityCastleLeft,
    "Difficulty",
    "InfinityCastleDifficulty",
    {"Easy", "Hard"},
    false,
    function(value)
        getgenv().InfinityCastleDifficulty = value
        Window:Notify({
            Title = "Infinity Castle",
            Description = "Difficulty set to: " .. value,
            Lifetime = 3
        })
    end,
    getgenv().InfinityCastleDifficulty
)

Sections.InfinityCastleLeft:SubLabel({
    Text = "Select difficulty and enable auto join to automatically enter Infinity Castle"
})

task.spawn(function()
    while true do
        task.wait(2)
        
        if getgenv().InfinityCastleAutoJoinEnabled then
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local infinityCastleRemotes = remotes and remotes:FindFirstChild("InfinityCastle")
                local enterEvent = infinityCastleRemotes and infinityCastleRemotes:FindFirstChild("Enter")
                
                if enterEvent then
                    local isHardMode = getgenv().InfinityCastleDifficulty == "Hard"
                    enterEvent:FireServer(isHardMode)
                    print("[Infinity Castle] Joining " .. getgenv().InfinityCastleDifficulty .. " mode (Hard: " .. tostring(isHardMode) .. ")")
                    
                    Window:Notify({
                        Title = "Infinity Castle",
                        Description = "Joining " .. getgenv().InfinityCastleDifficulty .. " mode...",
                        Lifetime = 3
                    })
                    
                    task.wait(5)
                else
                    print("[Infinity Castle] EnterEvent remote not found")
                end
            end)
        end
    end
end)


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

local LOBBY_PLACEIDS = {12886143095, 18583778121}
local function checkIsInLobby()
    for _, placeId in ipairs(LOBBY_PLACEIDS) do
        if game.PlaceId == placeId then return true end
    end
    return false
end
local isInLobby = checkIsInLobby()

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

local fastModeToggle, slowerModeToggle, smartModeToggle

getgenv().SmartCardSelectionEnabled = getgenv().Config.toggles.SmartCardSelectionToggle or false

local fastSuccess, fastErr = pcall(function()
    fastModeToggle = createToggle(
        Sections.EventLeft,
        "⚡ Fast Mode",
        "CardSelectionToggle",
        function(value)
            getgenv().CardSelectionEnabled = value
            if value then
                if slowerModeToggle then
                    getgenv().SlowerCardSelectionEnabled = false
                    getgenv().Config.toggles.SlowerCardSelectionToggle = false
                    pcall(function() slowerModeToggle:UpdateState(false) end)
                end
                if smartModeToggle then
                    getgenv().SmartCardSelectionEnabled = false
                    getgenv().Config.toggles.SmartCardSelectionToggle = false
                    pcall(function() smartModeToggle:UpdateState(false) end)
                end
                getgenv().SaveConfig(getgenv().Config)
            end
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Fast Mode Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().CardSelectionEnabled
    )
end)
if not fastSuccess then
    warn("[UI ERROR] Fast Mode toggle failed:", fastErr)
end

local slowerSuccess, slowerErr = pcall(function()
    slowerModeToggle = createToggle(
        Sections.EventLeft,
        "🐢 Slower Mode (More Reliable)",
        "SlowerCardSelectionToggle",
        function(value)
            getgenv().SlowerCardSelectionEnabled = value
            if value then
                if fastModeToggle then
                    getgenv().CardSelectionEnabled = false
                    getgenv().Config.toggles.CardSelectionToggle = false
                    pcall(function() fastModeToggle:UpdateState(false) end)
                end
                if smartModeToggle then
                    getgenv().SmartCardSelectionEnabled = false
                    getgenv().Config.toggles.SmartCardSelectionToggle = false
                    pcall(function() smartModeToggle:UpdateState(false) end)
                end
                getgenv().SaveConfig(getgenv().Config)
            end
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Slower Mode Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().SlowerCardSelectionEnabled
    )
end)
if not slowerSuccess then
    warn("[UI ERROR] Slower Mode toggle failed:", slowerErr)
end

local smartSuccess, smartErr = pcall(function()
    smartModeToggle = createToggle(
        Sections.EventLeft,
        "🧠 Smart Mode (Wave-Based)",
        "SmartCardSelectionToggle",
        function(value)
            getgenv().SmartCardSelectionEnabled = value
            getgenv().Config.toggles.SmartCardSelectionToggle = value
            if value then
                if fastModeToggle then
                    getgenv().CardSelectionEnabled = false
                    getgenv().Config.toggles.CardSelectionToggle = false
                    pcall(function() fastModeToggle:UpdateState(false) end)
                end
                if slowerModeToggle then
                    getgenv().SlowerCardSelectionEnabled = false
                    getgenv().Config.toggles.SlowerCardSelectionToggle = false
                    pcall(function() slowerModeToggle:UpdateState(false) end)
                end
            end
            getgenv().SaveConfig(getgenv().Config)
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Smart Mode Enabled - Maximizes candy based on wave" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().SmartCardSelectionEnabled
    )
end)
if not smartSuccess then
    warn("[UI ERROR] Smart Mode toggle failed:", smartErr)
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
        getgenv().Config.toggles.BossRushToggle = value
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Boss Rush",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().BossRushEnabled
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

local function getUnitFileName(displayName)
    if UnitNames then
        for fileName, displayNameInModule in pairs(UnitNames) do
            if displayNameInModule == displayName then
                return fileName
            end
        end
    end
    return displayName
end


getgenv().BulmaEnabled = getgenv().Config.toggles.BulmaToggle or false
getgenv().BulmaWishType = getgenv().Config.dropdowns.BulmaWishType or "Power"
getgenv().BulmaWishUsedThisRound = false

getgenv().WukongEnabled = getgenv().Config.toggles.WukongToggle or false
getgenv().WukongTrackedClones = {}

getgenv().OneEyeDevilEnabled = getgenv().Config.toggles.OneEyeDevilToggle or false
getgenv().OneEyeDevilCurrentIndex = 0 

getgenv().EventJoinDelay = tonumber(getgenv().Config.inputs.EventJoinDelay) or 0
getgenv().AutoJoinDelay = tonumber(getgenv().Config.inputs.AutoJoinDelay) or 0

getgenv().FinalExpAutoJoinEasyEnabled = getgenv().Config.toggles.FinalExpAutoJoinEasyToggle or false
getgenv().FinalExpAutoJoinHardEnabled = getgenv().Config.toggles.FinalExpAutoJoinHardToggle or false
getgenv().FinalExpAutoSkipShopEnabled = getgenv().Config.toggles.FinalExpAutoSkipShopToggle or false
getgenv().FinalExpAutoSelectModeEnabled = getgenv().Config.toggles.FinalExpAutoSelectModeToggle or false
getgenv().FinalExpSkipRewardsEnabled = getgenv().Config.toggles.FinalExpSkipRewardsToggle or false

getgenv().FinalExpRestPriority = tonumber(getgenv().Config.inputs.FinalExpRestPriority) or 3
getgenv().FinalExpDungeonPriority = tonumber(getgenv().Config.inputs.FinalExpDungeonPriority) or 1
getgenv().FinalExpDoubleDungeonPriority = tonumber(getgenv().Config.inputs.FinalExpDoubleDungeonPriority) or 2

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
        if not Tabs or not Tabs.Abilities then
            warn("[Ability UI] Tabs.Abilities not found!")
            return
        end
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
            
            if unitName == "EtoEvo" then
                continue
            end
            
            local abilities = getAllAbilities(unitName)
            
            if next(abilities) then
                local tabSide = "Right"
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
                    
                    if unitName == "EscanorGodly" then
                        local success, err = pcall(function()
                            local clientData = getClientData()
                            
                            if clientData and clientData.UnitData and clientData.Slots then
                                local escanorUnitID = nil
                                for slotName, slotData in pairs(clientData.Slots) do
                                    if slotData.Value == "EscanorGodly" and slotData.UnitID then
                                        escanorUnitID = slotData.UnitID
                                        break
                                    end
                                end
                                
                                if escanorUnitID and clientData.UnitData[escanorUnitID] then
                                    local unitData = clientData.UnitData[escanorUnitID]
                                    
                                    if unitData.EquippedSoul == "SoulOfTheScarredSun" then
                                        local soulAbilityName = "Who Decided That?"
                                        
                                        if not getgenv().UnitAbilities[unitName][soulAbilityName] then
                                            local saved = getgenv().Config.abilities and 
                                                         getgenv().Config.abilities[unitName] and 
                                                         getgenv().Config.abilities[unitName][soulAbilityName]
                                            
                                            local waveInputFlag = unitName .. "_" .. soulAbilityName .. "_Wave"
                                            local savedWave = getgenv().Config.inputs[waveInputFlag]
                                            if savedWave and savedWave ~= "" then
                                                savedWave = tonumber(savedWave)
                                            else
                                                savedWave = nil
                                            end
                                            
                                            getgenv().UnitAbilities[unitName][soulAbilityName] = {
                                                enabled = (saved and saved.enabled) or false,
                                                onlyOnBoss = (saved and saved.onlyOnBoss) or false,
                                                specificWave = savedWave or (saved and saved.specificWave) or nil,
                                                requireBossInRange = (saved and saved.requireBossInRange) or false,
                                                useOnWave = (saved and saved.useOnWave) or false
                                            }
                                        end
                                        
                                        local cfg = getgenv().UnitAbilities[unitName][soulAbilityName]
                                        
                                        targetSection:Divider()
                                        targetSection:SubLabel({ Text = "🔥 Soul Ability (SoulOfTheScarredSun)" })
                                        
                                        createToggle(
                                            targetSection,
                                            "⚡ Who Decided That? (CD: 999999s)",
                                            unitName .. "_" .. soulAbilityName .. "_Toggle",
                                            function(v)
                                                cfg.enabled = v
                                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                                getgenv().Config.abilities[unitName][soulAbilityName] = getgenv().Config.abilities[unitName][soulAbilityName] or {}
                                                getgenv().Config.abilities[unitName][soulAbilityName].enabled = v
                                                getgenv().SaveConfig(getgenv().Config)
                                                
                                                Window:Notify({
                                                    Title = "Auto Ability",
                                                    Description = soulAbilityName .. " " .. (v and "Enabled" or "Disabled"),
                                                    Lifetime = 2
                                                })
                                            end,
                                            cfg.enabled
                                        )
                                        
                                        local modifierKey = unitName .. "_" .. soulAbilityName .. "_Modifiers"
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
                                                store[soulAbilityName] = store[soulAbilityName] or {}
                                                store[soulAbilityName].onlyOnBoss = cfg.onlyOnBoss
                                                store[soulAbilityName].requireBossInRange = cfg.requireBossInRange
                                                store[soulAbilityName].useOnWave = cfg.useOnWave
                                                
                                                getgenv().SaveConfig(getgenv().Config)
                                            end,
                                            defaultValue
                                        )
                                        
                                        local waveFlag = unitName .. "_" .. soulAbilityName .. "_Wave"
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
                                                getgenv().Config.abilities[unitName][soulAbilityName] = getgenv().Config.abilities[unitName][soulAbilityName] or {}
                                                getgenv().Config.abilities[unitName][soulAbilityName].specificWave = num
                                                getgenv().SaveConfig(getgenv().Config)
                                            end,
                                            waveDefault
                                        )
                                    else
                                        print("[Soul Check] ❌ Soul not equipped or wrong soul")
                                    end
                                else
                                    print("[Soul Check] ❌ UnitID not found or no UnitData")
                                end
                            else
                                print("[Soul Check] ❌ Missing ClientData, UnitData, or Slots")
                            end
                        end)
                        
                        if not success then
                            warn("[Soul Check] Error:", err)
                        end
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
            
            local hasEtoEvo = false
            for slotName, slotData in pairs(clientData.Slots) do
                if slotData.Value == "EtoEvo" then
                    hasEtoEvo = true
                    break
                end
            end
            
            if hasBulma or hasWukong or hasEtoEvo then
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
                
                if hasEtoEvo then
                    if hasBulma or hasWukong then
                        specialSection:Divider()
                    end
                    
                    createToggle(
                        specialSection,
                        "Auto One Eye Devil (EtoEvo)",
                        "OneEyeDevilToggle",
                        function(value)
                            getgenv().OneEyeDevilEnabled = value
                            Window:Notify({
                                Title = "Auto One Eye Devil",
                                Description = value and "Enabled - Cycling Ocular Sigils" or "Disabled",
                                Lifetime = 2
                            })
                        end,
                        getgenv().OneEyeDevilEnabled
                    )
                end
            end
        end
    end)
    
    if not success then
        warn("[Ability UI] Build failed:", err)
        Window:Notify({
            Title = "Auto Ability Error",
            Description = "Failed to build UI. Check console for details.",
            Lifetime = 5
        })
    end
    
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
    
    if not getgenv()._AbilityUIBuilt then
        pcall(function()
            local fallbackSection = Tabs.Abilities:Section({ Side = "Left" })
            fallbackSection:Header({ Text = "⚠️ No Units Found" })
            fallbackSection:SubLabel({ Text = "Make sure you have units equipped in your slots." })
            fallbackSection:Divider()
            fallbackSection:SubLabel({ Text = "If you do have units equipped, try:" })
            fallbackSection:SubLabel({ Text = "1. Rejoining the game" })
            fallbackSection:SubLabel({ Text = "2. Reloading the script" })
            fallbackSection:SubLabel({ Text = "3. Checking console for errors (F9)" })
        end)
    end
end)


getgenv().AutoPlayConfig = getgenv().AutoPlayConfig or {
    enabled = false,
    autoPlace = false,
    autoUpgrade = false,
    autoUpgradePriority = false,
    focusFarm = false,
    hologram = false,
    placeBeforeUpgrade = false,
    pathPercentage = 1,
    distanceFromPath = 0,
    placeCaps = {1, 1, 1, 1, 1, 1},
    upgradeCaps = {0, 0, 0, 0, 0, 0},
    upgradePriorities = {1, 2, 3, 4, 5, 6}
}

getgenv().AutoPlayConfig.autoPlace = getgenv().Config.toggles.AutoPlayPlace or false
getgenv().AutoPlayConfig.autoUpgrade = getgenv().Config.toggles.AutoPlayUpgrade or false
getgenv().AutoPlayConfig.autoUpgradePriority = getgenv().Config.toggles.AutoPlayUpgradePriority or false
getgenv().AutoPlayConfig.focusFarm = getgenv().Config.toggles.AutoPlayFocusFarm or false
getgenv().AutoPlayConfig.hologram = getgenv().Config.toggles.AutoPlayHologram or false
getgenv().AutoPlayConfig.placeBeforeUpgrade = getgenv().Config.toggles.AutoPlayPlaceBeforeUpgrade or false
getgenv().AutoPlayConfig.pathPercentage = tonumber(getgenv().Config.inputs.AutoPlayPathPercentage) or 1
getgenv().AutoPlayConfig.distanceFromPath = tonumber(getgenv().Config.inputs.AutoPlayDistanceFromPath) or 0

for i = 1, 6 do
    local savedCap = tonumber(getgenv().Config.inputs["AutoPlayPlaceCap" .. i])
    if savedCap then
        getgenv().AutoPlayConfig.placeCaps[i] = savedCap
    end
end

for i = 1, 6 do
    local savedCap = tonumber(getgenv().Config.inputs["AutoPlayUpgradeCap" .. i])
    if savedCap then
        getgenv().AutoPlayConfig.upgradeCaps[i] = savedCap
    end
end

for i = 1, 6 do
    local savedPriority = tonumber(getgenv().Config.inputs["AutoPlayUpgradePriority" .. i])
    if savedPriority then
        getgenv().AutoPlayConfig.upgradePriorities[i] = savedPriority
    end
end

Sections.AutoPlayLeft:Header({ Text = "🤖 Auto Play" })
Sections.AutoPlayLeft:SubLabel({ Text = "Automated tower placement and upgrades" })

createToggle(
    Sections.AutoPlayLeft,
    "Enable Auto Place",
    "AutoPlayPlace",
    function(value)
        getgenv().AutoPlayConfig.autoPlace = value
    end,
    getgenv().AutoPlayConfig.autoPlace
)

local autoUpgradeToggle, autoUpgradePriorityToggle

autoUpgradeToggle = createToggle(
    Sections.AutoPlayLeft,
    "Enable Auto Upgrade",
    "AutoPlayUpgrade",
    function(value)
        getgenv().AutoPlayConfig.autoUpgrade = value
        if value and getgenv().AutoPlayConfig.autoUpgradePriority then
            getgenv().AutoPlayConfig.autoUpgradePriority = false
            getgenv().Config.toggles.AutoPlayUpgradePriority = false
            saveConfig(getgenv().Config)
            if autoUpgradePriorityToggle then
                pcall(function() autoUpgradePriorityToggle:UpdateState(false) end)
            end
        end
    end,
    getgenv().AutoPlayConfig.autoUpgrade
)

autoUpgradePriorityToggle = createToggle(
    Sections.AutoPlayLeft,
    "Auto Upgrade Priority",
    "AutoPlayUpgradePriority",
    function(value)
        getgenv().AutoPlayConfig.autoUpgradePriority = value
        if value and getgenv().AutoPlayConfig.autoUpgrade then
            getgenv().AutoPlayConfig.autoUpgrade = false
            getgenv().Config.toggles.AutoPlayUpgrade = false
            saveConfig(getgenv().Config)
            if autoUpgradeToggle then
                pcall(function() autoUpgradeToggle:UpdateState(false) end)
            end
        end
    end,
    getgenv().AutoPlayConfig.autoUpgradePriority
)

createToggle(
    Sections.AutoPlayLeft,
    "Focus Farm Units",
    "AutoPlayFocusFarm",
    function(value)
        getgenv().AutoPlayConfig.focusFarm = value
    end,
    getgenv().AutoPlayConfig.focusFarm
)

createToggle(
    Sections.AutoPlayLeft,
    "Enable Hologram",
    "AutoPlayHologram",
    function(value)
        getgenv().AutoPlayConfig.hologram = value
    end,
    getgenv().AutoPlayConfig.hologram
)

createToggle(
    Sections.AutoPlayLeft,
    "Place Units before Upgrading",
    "AutoPlayPlaceBeforeUpgrade",
    function(value)
        getgenv().AutoPlayConfig.placeBeforeUpgrade = value
    end,
    getgenv().AutoPlayConfig.placeBeforeUpgrade
)

Sections.AutoPlayLeft:Divider()

local pathSlider
local function updatePathSliderMax()
    local waypoints = {}
    pcall(function()
        local waypointsFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Waypoints")
        if waypointsFolder then
            for _, wp in pairs(waypointsFolder:GetChildren()) do
                if wp:IsA("BasePart") then
                    local num = tonumber(wp.Name)
                    if num and num >= 1 then
                        table.insert(waypoints, num)
                    end
                end
            end
        end
    end)
    
    local maxWaypoint = #waypoints > 0 and math.max(table.unpack(waypoints)) or 50
    
    if pathSlider then
        pcall(function()
            pathSlider:UpdateValue(math.min(getgenv().AutoPlayConfig.pathPercentage or 1, maxWaypoint))
        end)
    end
end

pathSlider = createSlider(
    Sections.AutoPlayLeft,
    "Path Waypoint",
    "AutoPlayPathPercentage",
    1,
    50,
    getgenv().AutoPlayConfig.pathPercentage or 1,
    function(value)
        getgenv().AutoPlayConfig.pathPercentage = value
    end,
    "Default",
    1
)

task.spawn(function()
    task.wait(2)
    updatePathSliderMax()
end)

createSlider(
    Sections.AutoPlayLeft,
    "Distance from Path",
    "AutoPlayDistanceFromPath",
    0,
    25,
    getgenv().AutoPlayConfig.distanceFromPath,
    function(value)
        getgenv().AutoPlayConfig.distanceFromPath = math.floor(value)
    end,
    "Default",
    0
)

Sections.AutoPlayRight:Header({ Text = "⚙️ Auto Place & Upgrade Settings" })
Sections.AutoPlayRight:SubLabel({ Text = "Configure placement and upgrade caps per slot" })

getgenv().AutoPlaySliders = {
    placeCaps = {},
    upgradeCaps = {}
}


for i = 1, 6 do
    getgenv().AutoPlaySliders.placeCaps[i] = createSlider(
        Sections.AutoPlayRight,
        "Place Cap " .. i,
        "AutoPlayPlaceCap" .. i,
        0,
        5,
        getgenv().AutoPlayConfig.placeCaps[i],
        function(value)
            getgenv().AutoPlayConfig.placeCaps[i] = math.floor(value)
        end,
        "Default",
        0
    )
end

Sections.AutoPlayRight:Divider()

for i = 1, 6 do
    local savedValue = getgenv().Config.inputs["AutoPlayUpgradeCap" .. i]
    local defaultValue = savedValue and tonumber(savedValue) or 0
    
    getgenv().AutoPlaySliders.upgradeCaps[i] = createSlider(
        Sections.AutoPlayRight,
        "Upgrade Cap " .. i,
        "AutoPlayUpgradeCap" .. i,
        0,
        20,
        defaultValue,
        function(value)
            getgenv().AutoPlayConfig.upgradeCaps[i] = math.floor(value)
        end,
        "Default",
        0
    )
end

Sections.AutoPlayRight:Divider()

Sections.AutoPlayRight:SubLabel({ Text = "Priority: 1 = Highest (upgrades first), 6 = Lowest" })

for i = 1, 6 do
    if not getgenv().AutoPlayConfig.upgradePriorities then
        getgenv().AutoPlayConfig.upgradePriorities = {1, 2, 3, 4, 5, 6}
    end
    
    local savedPriority = getgenv().Config.inputs["AutoPlayUpgradePriority" .. i]
    local defaultPriority = savedPriority and tonumber(savedPriority) or i
    
    createSlider(
        Sections.AutoPlayRight,
        "Upgrade Priority " .. i,
        "AutoPlayUpgradePriority" .. i,
        1,
        6,
        defaultPriority,
        function(value)
            getgenv().AutoPlayConfig.upgradePriorities[i] = math.floor(value)
        end,
        "Default",
        0
    )
end



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

Sections.MacroLeft:Button({
    Name = "⚙️ Equip Macro Units",
    Callback = function()
        local selectedMacro = getgenv().CurrentMacro
        if not selectedMacro or selectedMacro == "" then
            Window:Notify({
                Title = "Equip Macro Units",
                Description = "Please select a macro first!",
                Lifetime = 3
            })
            return
        end
        
        local macroData = getgenv().MacroData or loadMacro(selectedMacro)
        if not macroData or #macroData == 0 then
            Window:Notify({
                Title = "Equip Macro Units",
                Description = "Failed to load macro data!",
                Lifetime = 3
            })
            return
        end
        
        local summonBlacklist = {
            ["TuskSummon_Act4"] = true,
            ["NarutoBaryonClone"] = true,
        }
        
        local macroUnits = {}
        local unitSet = {}
        for _, action in ipairs(macroData) do
            if action.ActionType == "Place" and action.TowerName then
                local towerName = action.TowerName
                
                local isSummon = summonBlacklist[towerName] or 
                                 towerName:find("Summon") or 
                                 towerName:find("Clone")
                
                if not isSummon and not unitSet[towerName] then
                    unitSet[towerName] = true
                    table.insert(macroUnits, towerName)
                end
            end
        end
        
        if #macroUnits == 0 then
            Window:Notify({
                Title = "Equip Macro Units",
                Description = "No units found in macro!",
                Lifetime = 3
            })
            return
        end
        
        local clientData = getClientData()
        if not clientData or not clientData.UnitData or not clientData.Slots then
            Window:Notify({
                Title = "Equip Macro Units",
                Description = "Failed to get client data!",
                Lifetime = 3
            })
            return
        end
        
        local unitIDs = {}
        for unitID, unitInfo in pairs(clientData.UnitData) do
            for _, macroUnit in ipairs(macroUnits) do
                if unitInfo.UnitName == macroUnit then
                    unitIDs[macroUnit] = unitID
                    break
                end
            end
        end
        
        local missingUnits = {}
        for _, macroUnit in ipairs(macroUnits) do
            if not unitIDs[macroUnit] then
                table.insert(missingUnits, macroUnit)
            end
        end
        
        if #missingUnits > 0 then
            Window:Notify({
                Title = "Equip Macro Units",
                Description = "Missing units: " .. table.concat(missingUnits, ", "),
                Lifetime = 5
            })
            return
        end
        
        local equipRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Equip")
        if not equipRemote then
            Window:Notify({
                Title = "Equip Macro Units",
                Description = "Equip remote not found!",
                Lifetime = 3
            })
            return
        end
        
        print("[Equip Macro Units] Unequipping all units...")
        local unequipped = 0
        for unitID, unitInfo in pairs(clientData.UnitData) do
            if unitInfo.Equipped then
                pcall(function()
                    equipRemote:InvokeServer(unitID)
                    unequipped = unequipped + 1
                end)
            end
        end
        
        print("[Equip Macro Units] Unequipped " .. unequipped .. " units")
        
        print("[Equip Macro Units] Equipping macro units...")
        local equipped = 0
        for i, macroUnit in ipairs(macroUnits) do
            if i <= 6 then
                local unitID = unitIDs[macroUnit]
                if unitID then
                    pcall(function()
                        equipRemote:InvokeServer(unitID)
                        equipped = equipped + 1
                    end)
                end
            end
        end
        
        Window:Notify({
            Title = "Equip Macro Units",
            Description = "Equipped " .. equipped .. " unit(s) for " .. selectedMacro,
            Lifetime = 3
        })
    end,
})

Sections.MacroLeft:Button({
    Name = "🗑️ Delete Macro",
    Callback = function()
        local selectedMacro = getgenv().CurrentMacro
        if not selectedMacro or selectedMacro == "" then
            Window:Notify({
                Title = "Delete Macro",
                Description = "Please select a macro first!",
                Lifetime = 3
            })
            return
        end
        
        local macroPath = "ALSHalloweenEvent/macros/" .. selectedMacro .. ".json"
        
        local success = pcall(function()
            if isfile(macroPath) then
                delfile(macroPath)
            end
        end)
        
        if success then
            getgenv().Macros[selectedMacro] = nil
            getgenv().CurrentMacro = nil
            
            Window:Notify({
                Title = "Delete Macro",
                Description = "Deleted macro: " .. selectedMacro,
                Lifetime = 3
            })
            
            if getgenv().MacroDropdown then
                pcall(function()
                    getgenv().MacroDropdown:UpdateOptions(getMacroNames())
                    getgenv().MacroDropdown:UpdateValue("None")
                end)
            end
        else
            Window:Notify({
                Title = "Delete Macro",
                Description = "Failed to delete macro!",
                Lifetime = 3
            })
        end
    end,
})

Sections.MacroLeft:Divider()

Sections.MacroLeft:Header({ Text = "📥 Macro Import" })
Sections.MacroLeft:SubLabel({ Text = "Import macros from Discord links" })

local macroImportInput = createInput(
    Sections.MacroLeft,
    "Import Link",
    "MacroImportLink",
    "Paste Discord link here",
    "All",
    function(value) end,
    ""
)

Sections.MacroLeft:Button({
    Name = "📥 Import Macro",
    Callback = function()
        local importLink = getgenv().Config.inputs.MacroImportLink or ""
        
        if not importLink or importLink == "" then
            Window:Notify({
                Title = "Macro Import",
                Description = "Please paste a link in the input box!",
                Lifetime = 3
            })
            return
        end
        
        if not importLink:match("cdn%.discordapp%.com") and not importLink:match("cdn%.discord%.com") then
            Window:Notify({
                Title = "Macro Import",
                Description = "Invalid Discord link!",
                Lifetime = 3
            })
            return
        end
        
        Window:Notify({
            Title = "Macro Import",
            Description = "Downloading macro...",
            Lifetime = 2
        })
        
        local success, result = pcall(function()
            return game:HttpGet(importLink)
        end)
        
        if not success or not result then
            Window:Notify({
                Title = "Macro Import",
                Description = "Failed to download macro!",
                Lifetime = 3
            })
            return
        end
        
        local macroData
        success, macroData = pcall(function()
            return HttpService:JSONDecode(result)
        end)
        
        if not success or not macroData then
            Window:Notify({
                Title = "Macro Import",
                Description = "Invalid macro file format!",
                Lifetime = 3
            })
            return
        end
        
        local macroName = importLink:match("/([^/]+)%.json") or "Imported_Macro_" .. os.time()
        macroName = macroName:gsub("%%20", " ")
        
        if getgenv().Macros[macroName] then
            macroName = macroName .. "_" .. os.time()
        end
        
        local saveSuccess = saveMacro(macroName, macroData)
        
        if saveSuccess then
            loadMacros()
            local macroNames = getMacroNames()
            if macroDropdown then
                pcall(function()
                    macroDropdown:ClearOptions()
                    macroDropdown:InsertOptions(macroNames)
                    macroDropdown:UpdateSelection(macroName)
                end)
            end
            
            getgenv().CurrentMacro = macroName
            getgenv().MacroData = macroData
            getgenv().MacroTotalSteps = #macroData
            
            if macroImportInput and macroImportInput.UpdateText then
                pcall(function()
                    macroImportInput:UpdateText("")
                end)
            end
            
            Window:Notify({
                Title = "Macro Import",
                Description = "✅ Imported: " .. macroName,
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "Macro Import",
                Description = "Failed to save imported macro!",
                Lifetime = 3
            })
        end
    end,
})

Sections.MacroLeft:Divider()

Sections.MacroLeft:Header({ Text = "🎬 Recording & Playback" })
Sections.MacroLeft:SubLabel({ Text = "Record new macros or play existing ones" })

local macroRecordToggle = createToggleNoSave(
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
            
            
            if getgenv().UpdateMacroStatus then
                getgenv().UpdateMacroStatus()
            end
            
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
    {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "Event", "MidnightHunt", "BossRush", "Siege", "Breach", "FinalExpedition"},
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
    if mode == "FinalExpedition" then mode = "Story" end
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
        "FPSBoostToggle",
        function(value)
            getgenv().FPSBoostEnabled = value
            Window:Notify({
                Title = "FPS Boost",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().FPSBoostEnabled
    )
else
    getgenv().FPSBoostEnabled = false
end

createToggle(
    Sections.MiscLeft,
    "Remove Enemies & Units",
    "RemoveEnemiesToggle",
    function(value)
        getgenv().RemoveEnemiesEnabled = value
        Window:Notify({
            Title = "Remove Enemies",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().RemoveEnemiesEnabled
)

createToggle(
    Sections.MiscLeft,
    "Black Screen Mode",
    "BlackScreenToggle",
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
    getgenv().BlackScreenEnabled
)

Sections.MiscLeft:Divider()

Sections.MiscLeft:Header({ Text = "🛡️ Safety" })
Sections.MiscLeft:SubLabel({ Text = "Stay safe and avoid detection" })

createToggle(
    Sections.MiscLeft,
    "Anti-AFK",
    "AntiAFKToggle",
    function(value)
        getgenv().AntiAFKEnabled = value
        Window:Notify({
            Title = "Anti-AFK",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AntiAFKEnabled
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
    "AutoExecuteToggle",
    function(value)
        getgenv().AutoExecuteEnabled = value
        
        local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        
        if value and queueteleport then
            print("[ALS] Auto Execute on Teleport enabled")
        elseif value and not queueteleport then
            warn("[ALS] Auto Execute enabled but queue_on_teleport not supported by your executor")
        end
        
        Window:Notify({
            Title = "Auto Execute",
            Description = value and "Enabled - Script will auto-load on teleport" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AutoExecuteEnabled
)

Sections.MiscLeft:Divider()

Sections.MiscLeft:Header({ Text = "🎯 Placement" })
Sections.MiscLeft:SubLabel({ Text = "Advanced tower placement options" })

if not getgenv().PlaceAnywhereEnabled then
    getgenv().PlaceAnywhereEnabled = getgenv().Config.toggles.PlaceAnywhereToggle or false
end

createToggle(
    Sections.MiscLeft,
    "Place Anywhere",
    "PlaceAnywhereToggle",
    function(value)
        getgenv().PlaceAnywhereEnabled = value
        Window:Notify({
            Title = "Place Anywhere",
            Description = value and "Enabled - Click on units to place them" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().PlaceAnywhereEnabled
)

Sections.MiscLeft:SubLabel({
    Text = "Click on any unit preview in workspace to place it at that location"
})

if not isInLobby then
    local Mouse = LocalPlayer:GetMouse()
    local UIS = game:GetService("UserInputService")
    
    local function getUnitAtMouse()
        local target = Mouse.Target
        if not target then return nil end
        
        local current = target
        while current and current ~= workspace do
            if current:IsA("Model") and current.Parent == workspace then
                local hrp = current:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local towerInfo = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("TowerInfo")
                    if towerInfo and towerInfo:FindFirstChild(current.Name) then
                        return current.Name, hrp.CFrame
                    end
                end
            end
            current = current.Parent
        end
        
        return nil
    end
    
    Mouse.Button1Down:Connect(function()
        if not getgenv().PlaceAnywhereEnabled then return end
        
        pcall(function()
            local unitName, unitCFrame = getUnitAtMouse()
            if unitName and unitCFrame then
                local placeRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("PlaceTower")
                if placeRemote then
                    placeRemote:FireServer(unitName, unitCFrame)
                    print("[Place Anywhere] Placed " .. unitName .. " at " .. tostring(unitCFrame.Position))
                    
                    Window:Notify({
                        Title = "Place Anywhere",
                        Description = "Placed " .. unitName,
                        Lifetime = 2
                    })
                end
            end
        end)
    end)
    
    UIS.TouchTap:Connect(function(touchPositions, gameProcessedEvent)
        if not getgenv().PlaceAnywhereEnabled or gameProcessedEvent then return end
        
        pcall(function()
            local unitName, unitCFrame = getUnitAtMouse()
            if unitName and unitCFrame then
                local placeRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("PlaceTower")
                if placeRemote then
                    placeRemote:FireServer(unitName, unitCFrame)
                    print("[Place Anywhere] Placed " .. unitName .. " at " .. tostring(unitCFrame.Position))
                    
                    Window:Notify({
                        Title = "Place Anywhere",
                        Description = "Placed " .. unitName,
                        Lifetime = 2
                    })
                end
            end
        end)
    end)
end

if not getgenv().AutoVolcanoEnabled then
    getgenv().AutoVolcanoEnabled = getgenv().Config.toggles.AutoVolcanoToggle or false
end

createToggle(
    Sections.MiscLeft,
    "Auto Volcano",
    "AutoVolcanoToggle",
    function(value)
        getgenv().AutoVolcanoEnabled = value
        Window:Notify({
            Title = "Auto Volcano",
            Description = value and "Enabled - Auto-activating volcanoes" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AutoVolcanoEnabled
)

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(2)
            
            if getgenv().AutoVolcanoEnabled then
                pcall(function()
                    local gamemode = RS:FindFirstChild("Gamemode")
                    local mapName = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MapName")
                    
                    if gamemode and gamemode.Value == "Dungeon" and mapName and mapName.Value == "Infernal Volcano" then
                        local volcano = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Volcanoes") and workspace.Map.Volcanoes:FindFirstChild("Volcano")
                        
                        if volcano then
                            local remotes = RS:FindFirstChild("Remotes")
                            local volcanoRemote = remotes and remotes:FindFirstChild("VolcanoRemote")
                            
                            if volcanoRemote then
                                volcanoRemote:FireServer(volcano)
                                print("[Auto Volcano] Activated volcano")
                            end
                        end
                    end
                end)
            end
        end
    end)
end

if not getgenv().AutoOrbEnabled then
    getgenv().AutoOrbEnabled = getgenv().Config.toggles.AutoOrbToggle or false
end

createToggle(
    Sections.MiscLeft,
    "Auto Orb",
    "AutoOrbToggle",
    function(value)
        getgenv().AutoOrbEnabled = value
        Window:Notify({
            Title = "Auto Orb",
            Description = value and "Enabled - Auto-collecting orbs" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AutoOrbEnabled
)

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(1)
            
            if getgenv().AutoOrbEnabled then
                pcall(function()
                    local gamemode = RS:FindFirstChild("Gamemode")
                    local mapName = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MapName")
                    
                    local shouldCollect = false
                    
                    if gamemode then
                        if gamemode.Value == "BossRush" then
                            shouldCollect = true
                        elseif gamemode.Value == "Dungeon" and mapName and mapName.Value == "Warehouse" then
                            shouldCollect = true
                        end
                    end
                    
                    if shouldCollect then
                        local orb = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("ActiveOrbs") and workspace.Map.ActiveOrbs:FindFirstChild("Orb")
                        
                        if orb then
                            local remotes = RS:FindFirstChild("Remotes")
                            local interactEvent = remotes and remotes:FindFirstChild("Interact")
                            
                            if interactEvent then
                                interactEvent:FireServer(orb)
                                print("[Auto Orb] Collected orb")
                            end
                        end
                    end
                end)
            end
        end
    end)
end

if not getgenv().AntiMagicZoneEnabled then
    getgenv().AntiMagicZoneEnabled = getgenv().Config.toggles.AntiMagicZoneToggle or false
end

createToggle(
    Sections.MiscLeft,
    "Anti Magic Zone",
    "AntiMagicZoneToggle",
    function(value)
        getgenv().AntiMagicZoneEnabled = value
        Window:Notify({
            Title = "Anti Magic Zone",
            Description = value and "Enabled - Teleporting away from magic zones" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AntiMagicZoneEnabled
)

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(10)
            
            if getgenv().AntiMagicZoneEnabled then
                pcall(function()
                    local gamemode = RS:FindFirstChild("Gamemode")
                    
                    if gamemode and gamemode.Value == "BossRush" then
                        local zoneHitbox = workspace:FindFirstChild("EffectZones") and workspace.EffectZones:FindFirstChild("ZoneHitbox")
                        
                        if zoneHitbox and zoneHitbox:IsA("BasePart") then
                            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            
                            if hrp then
                                hrp.CFrame = zoneHitbox.CFrame
                                print("[Anti Magic Zone] Teleported to safe zone")
                            end
                        end
                    end
                end)
            end
        end
    end)
end


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

local function getValidKeyCode(keyName, fallback)
    if not keyName or keyName == "" then return Enum.KeyCode[fallback] end
    local success, keyCode = pcall(function()
        return Enum.KeyCode[keyName]
    end)
    if success and keyCode then
        return keyCode
    else
        getgenv().Config.inputs["MenuKeybind"] = fallback
        getgenv().SaveConfig(getgenv().Config)
        return Enum.KeyCode[fallback]
    end
end

local menuKeybind = Sections.SettingsLeft:Keybind({
    Name = "Menu Toggle",
    Default = getValidKeyCode(getgenv().Config.inputs["MenuKeybind"], "LeftControl"),
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
        local validKey = getValidKeyCode(getgenv().Config.inputs["MenuKeybind"], "LeftControl")
        Window:SetKeybind(validKey)
    end)
end

Sections.SettingsLeft:Divider()

Sections.SettingsLeft:Header({ Text = "🖥️ UI Size (Restart Required)" })
Sections.SettingsLeft:SubLabel({ Text = "Custom window size - changes apply on next script load" })

createInput(
    Sections.SettingsLeft,
    "Width",
    "UIWidth",
    "Default: 580 (mobile) or 868 (desktop)",
    "Numeric",
    function(value)
        local width = tonumber(value)
        if width and width >= 400 and width <= 1920 then
            getgenv().Config.inputs.UIWidth = width
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "UI Width",
                Description = "Set to " .. width .. " (restart to apply)",
                Lifetime = 3
            })
        end
    end,
    tostring(getgenv().Config.inputs.UIWidth or (isMobile and 580 or 868))
)

createInput(
    Sections.SettingsLeft,
    "Height",
    "UIHeight",
    "Default: 480 (mobile) or 650 (desktop)",
    "Numeric",
    function(value)
        local height = tonumber(value)
        if height and height >= 300 and height <= 1080 then
            getgenv().Config.inputs.UIHeight = height
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "UI Height",
                Description = "Set to " .. height .. " (restart to apply)",
                Lifetime = 3
            })
        end
    end,
    tostring(getgenv().Config.inputs.UIHeight or (isMobile and 480 or 650))
)

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
            pcall(function()
                if getgenv().MacroEnabled then
                    getgenv().MacroEnabled = false
                end
                if getgenv().AutoJoinEnabled then
                    getgenv().AutoJoinEnabled = false
                end
            end)
            
            task.wait(1)
            cleanupBeforeTeleport()
            task.wait(1)
            
            local maxRetries = 3
            local retryDelay = 2
            
            for attempt = 1, maxRetries do
                local ok, err = pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                
                if ok then
                    print("[Server Hop] Teleport initiated (Attempt " .. attempt .. ")")
                    break
                else
                    warn("[Server Hop] Attempt " .. attempt .. "/" .. maxRetries .. " failed:", err)
                    
                    if attempt < maxRetries then
                        print("[Server Hop] Retrying in " .. retryDelay .. "s...")
                        task.wait(retryDelay)
                        retryDelay = retryDelay * 2
                    else
                        Window:Notify({
                            Title = "Server Hop",
                            Description = "Failed after " .. maxRetries .. " attempts",
                            Lifetime = 5
                        })
                    end
                end
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

Sections.FinalExpeditionRight:Divider()

createToggle(
    Sections.FinalExpeditionRight,
    "Skip Rewards",
    "FinalExpSkipRewardsToggle",
    function(value)
        getgenv().FinalExpSkipRewardsEnabled = value
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Skip Rewards Enabled" or "Skip Rewards Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpSkipRewardsEnabled
)

Sections.FinalExpeditionRight:SubLabel({
    Text = "Automatically skips reward screens"
})

Sections.FinalExpeditionRight:Divider()

Sections.FinalExpeditionRight:Header({ Text = "🎯 Auto Select Mode" })
Sections.FinalExpeditionRight:SubLabel({ Text = "Automatically select Rest/Dungeon/Double Dungeon based on priority" })

createToggle(
    Sections.FinalExpeditionRight,
    "Enable Auto Select Mode",
    "FinalExpAutoSelectModeToggle",
    function(value)
        getgenv().FinalExpAutoSelectModeEnabled = value
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Select Mode Enabled" or "Auto Select Mode Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoSelectModeEnabled
)

createInput(
    Sections.FinalExpeditionRight,
    "Rest Priority (1-3)",
    "FinalExpRestPriority",
    "3",
    "Numeric",
    function(value)
        local num = tonumber(value) or 3
        if num < 1 then num = 1 end
        if num > 3 then num = 3 end
        getgenv().FinalExpRestPriority = num
    end
)

createInput(
    Sections.FinalExpeditionRight,
    "Dungeon Priority (1-3)",
    "FinalExpDungeonPriority",
    "1",
    "Numeric",
    function(value)
        local num = tonumber(value) or 1
        if num < 1 then num = 1 end
        if num > 3 then num = 3 end
        getgenv().FinalExpDungeonPriority = num
    end
)

createInput(
    Sections.FinalExpeditionRight,
    "Double Dungeon Priority (1-3)",
    "FinalExpDoubleDungeonPriority",
    "2",
    "Numeric",
    function(value)
        local num = tonumber(value) or 2
        if num < 1 then num = 1 end
        if num > 3 then num = 3 end
        getgenv().FinalExpDoubleDungeonPriority = num
    end
)

Sections.FinalExpeditionRight:SubLabel({
    Text = "1 = Highest priority, 3 = Lowest priority"
})


Sections.SeamlessFixLeft:Header({ Text = "🔄 Automation Settings" })
Sections.SeamlessFixLeft:Divider()

Sections.SeamlessFixLeft:Header({ Text = "💡 Seamless Fix" })
Sections.SeamlessFixLeft:SubLabel({
    Text = "Ensures the script continues running smoothly when you teleport between game instances"
})

Sections.SeamlessFixLeft:Divider()

Sections.SeamlessFixLeft:Header({ Text = "⚙️ Settings" })

createToggle(
    Sections.SeamlessFixLeft,
    "Enable Seamless Fix",
    "SeamlessFixToggle",
    function(value)
        getgenv().SeamlessFixEnabled = value
        
        task.spawn(function()
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                if setSettings then 
                    setSettings:InvokeServer("SeamlessRetry")
                end
            end)
        end)
        
        Window:Notify({
            Title = "Seamless Fix",
            Description = value and "Enabled - Script will persist through teleports" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().SeamlessFixEnabled
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

Sections.SeamlessFixRight:Header({ Text = "♾️ Infinite Mode Restart" })
Sections.SeamlessFixRight:SubLabel({
    Text = "Automatically restart the match when reaching a specific wave in Infinite mode"
})

if not getgenv().InfiniteRestartEnabled then
    getgenv().InfiniteRestartEnabled = getgenv().Config.toggles.InfiniteRestartToggle or false
end

if not getgenv().InfiniteRestartWave then
    getgenv().InfiniteRestartWave = tonumber(getgenv().Config.inputs.InfiniteRestartWave) or 50
end

createToggle(
    Sections.SeamlessFixRight,
    "Enable Infinite Restart",
    "InfiniteRestartToggle",
    function(value)
        getgenv().InfiniteRestartEnabled = value
        Window:Notify({
            Title = "Infinite Restart",
            Description = value and "Enabled - Will restart at wave " .. getgenv().InfiniteRestartWave or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().InfiniteRestartEnabled
)

createInput(
    Sections.SeamlessFixRight,
    "Restart at Wave",
    "InfiniteRestartWave",
    "Enter wave number (e.g., 50)",
    "Numeric",
    function(value)
        getgenv().InfiniteRestartWave = tonumber(value) or 50
        Window:Notify({
            Title = "Infinite Restart",
            Description = "Will restart at wave " .. (tonumber(value) or 50),
            Lifetime = 3
        })
    end,
    tostring(getgenv().InfiniteRestartWave)
)

Sections.SeamlessFixRight:SubLabel({
    Text = "Match will automatically restart when the wave counter reaches this number"
})

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(2)
            
            if getgenv().InfiniteRestartEnabled then
                pcall(function()
                    local wave = RS:FindFirstChild("Wave")
                    if wave and wave.Value then
                        local currentWave = tonumber(wave.Value) or 0
                        local targetWave = tonumber(getgenv().InfiniteRestartWave) or 50
                        
                        if currentWave >= targetWave then
                            print("[Infinite Restart] Wave " .. currentWave .. " reached, restarting match...")
                            
                            local remotes = RS:FindFirstChild("Remotes")
                            local restartRemote = remotes and remotes:FindFirstChild("RestartMatch")
                            
                            if restartRemote then
                                restartRemote:FireServer()
                                print("[Infinite Restart] ✅ Restart signal sent")
                                
                                Window:Notify({
                                    Title = "Infinite Restart",
                                    Description = "Restarting at wave " .. currentWave,
                                    Lifetime = 3
                                })
                                
                                task.wait(10)
                            else
                                print("[Infinite Restart] ❌ RestartMatch remote not found")
                            end
                        end
                    end
                end)
            end
        end
    end)
end


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

getgenv()._isTeleporting = false

task.spawn(function()
    local lastEndGameUIInstance = nil
    local hasProcessedCurrentUI = false
    local endGameUIDetectedTime = 0
    local endGameUIWasPresent = false
    local lastActionTime = 0
    local ACTION_TIMEOUT = 45
    local newGameDetected = false
    local lastEndGameUIState = false
    
    while true do
        task.wait(0.2)
        
        local success, errorMsg = pcall(function()
            if not LocalPlayer or not LocalPlayer.PlayerGui then return end
            
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            local currentEndGameUIState = endGameUI and endGameUI.Enabled or false
            
            if lastEndGameUIState and not currentEndGameUIState then
                newGameDetected = true
                hasProcessedCurrentUI = false
                lastEndGameUIInstance = nil
                endGameUIWasPresent = false
                getgenv()._isTeleporting = false
                
                getgenv().MacroGameState.hasStartButton = false
                getgenv().MacroGameState.currentWave = 0
                getgenv().MacroGameState.gameEnded = false
                getgenv().MacroGameState.hasEndGameUI = false
                getgenv().MacroCurrentStep = 1
                getgenv().MacroActionText = ""
                getgenv().MacroUnitText = ""
                getgenv().MacroWaitingText = ""
                getgenv().MacroStatusText = "New Game Started"
                getgenv().MacroPlaybackActive = false
                
                getgenv().SmartCardPicked = {}
                getgenv().SmartCardLastPromptId = nil
                getgenv().SlowerCardPicked = {}
                getgenv().SlowerCardLastPromptId = nil
                
                if getgenv().UpdateMacroStatus then
                    getgenv().UpdateMacroStatus()
                end
            end
            
            lastEndGameUIState = currentEndGameUIState
            
            if endGameUI then
                endGameUIWasPresent = true
            end
            
            if not endGameUI or not endGameUI.Enabled then 
                return 
            end
            
            local bg = endGameUI:FindFirstChild("BG")
            if not bg then return end
            
            local buttons = bg:FindFirstChild("Buttons")
            if not buttons then return end
            
            if lastEndGameUIInstance and endGameUI ~= lastEndGameUIInstance then
                hasProcessedCurrentUI = false
                lastEndGameUIInstance = endGameUI
                endGameUIDetectedTime = tick()
                newGameDetected = false
            end
            
            if not lastEndGameUIInstance then
                lastEndGameUIInstance = endGameUI
                endGameUIDetectedTime = tick()
            end
            
            if hasProcessedCurrentUI then
                return
            end
            
            local nextButton = buttons:FindFirstChild("Next")
            local retryButton = buttons:FindFirstChild("Retry")
            local leaveButton = buttons:FindFirstChild("Leave")
            
            if not retryButton or not nextButton or not leaveButton then
                for _, button in pairs(buttons:GetChildren()) do
                    if button:IsA("TextButton") or button:IsA("ImageButton") then
                        local textLabel = button:FindFirstChildWhichIsA("TextLabel", true)
                        if textLabel then
                            local text = textLabel.Text:lower()
                            if text:find("retry") and not retryButton then
                                retryButton = button
                            elseif text:find("next") and not nextButton then
                                nextButton = button
                            elseif text:find("leave") and not leaveButton then
                                leaveButton = button
                            end
                        end
                    end
                end
            end
            
            local buttonToPress, actionName = nil, ""
            
            local isFinalExpedition = false
            pcall(function()
                local gamemode = RS:FindFirstChild("Gamemode")
                if gamemode and gamemode.Value == "FinalExpedition" then
                    isFinalExpedition = true
                end
            end)
            
            if isFinalExpedition then
                print("[Final Expedition] Detected - waiting for Next button...")
                local waitTime = 0
                local maxWaitTime = 10
                
                while waitTime < maxWaitTime do
                    local foundNext = false
                    pcall(function()
                        if buttons then
                            nextButton = buttons:FindFirstChild("Next")
                            if not nextButton then
                                for _, button in pairs(buttons:GetChildren()) do
                                    if button:IsA("TextButton") or button:IsA("ImageButton") then
                                        local textLabel = button:FindFirstChildWhichIsA("TextLabel", true)
                                        if textLabel and textLabel.Text:lower():find("next") then
                                            nextButton = button
                                            break
                                        end
                                    end
                                end
                            end
                            
                            if nextButton and nextButton.Visible then
                                foundNext = true
                            end
                        end
                    end)
                    
                    if foundNext then
                        print("[Final Expedition] Next button found and visible!")
                        break
                    end
                    
                    task.wait(0.5)
                    waitTime = waitTime + 0.5
                end
                
                if waitTime >= maxWaitTime then
                    print("[Final Expedition] Timeout waiting for Next button")
                end
            end
            
            if getgenv().AutoNextEnabled and nextButton and nextButton.Visible then
                buttonToPress = nextButton
                actionName = "Next"
            elseif getgenv().AutoFastRetryEnabled and retryButton and retryButton.Visible then
                buttonToPress = retryButton
                actionName = "Retry"
            elseif getgenv().AutoLeaveEnabled and leaveButton and leaveButton.Visible then
                if isFinalExpedition and nextButton and nextButton.Visible then
                    buttonToPress = nextButton
                    actionName = "Next"
                else
                    buttonToPress = leaveButton
                    actionName = "Leave"
                end
            elseif getgenv().AutoSmartEnabled then
                if nextButton and nextButton.Visible then
                    buttonToPress = nextButton
                    actionName = "Next"
                elseif retryButton and retryButton.Visible then
                    buttonToPress = retryButton
                    actionName = "Retry"
                elseif leaveButton and leaveButton.Visible then
                    if isFinalExpedition and nextButton and nextButton.Visible then
                        buttonToPress = nextButton
                        actionName = "Next"
                    else
                        buttonToPress = leaveButton
                        actionName = "Leave"
                    end
                end
            end
            
            if buttonToPress then
                if getgenv()._isTeleporting then
                    return
                end
                
                if getgenv().WebhookEnabled then
                    print("[Auto " .. actionName .. "] Waiting for webhook to start and complete...")
                    
                    local startWait = 0
                    while not getgenv().WebhookProcessing and startWait < 5 do
                        task.wait(0.5)
                        startWait = startWait + 0.5
                    end
                    
                    if getgenv().WebhookProcessing then
                        print("[Auto " .. actionName .. "] Webhook started, waiting for completion...")
                    else
                        print("[Auto " .. actionName .. "] Webhook didn't start, continuing anyway...")
                    end
                    
                    local maxWait = 0
                    local maxWaitTime = 35
                    
                    while getgenv().WebhookProcessing and maxWait < maxWaitTime do
                        task.wait(0.5)
                        maxWait = maxWait + 0.5
                        
                        if maxWait % 5 == 0 then
                            print("[Auto " .. actionName .. "] Still waiting... (" .. maxWait .. "s)")
                        end
                    end
                    
                    if getgenv().WebhookProcessing then
                        warn("[Auto " .. actionName .. "] Webhook timeout, forcing continue")
                        getgenv().WebhookProcessing = false
                    else
                        print("[Auto " .. actionName .. "] ✅ Webhook completed")
                    end
                    
                    task.wait(1)
                else
                    task.wait(0.5)
                end
                
                hasProcessedCurrentUI = true
                lastActionTime = tick()
                
                local pressSuccess = pcall(function()
                    if not buttonToPress or not buttonToPress.Parent then
                        return
                    end
                    
                    if not buttonToPress:IsDescendantOf(game) then
                        return
                    end
                    
                    if not buttonToPress:IsDescendantOf(LocalPlayer.PlayerGui) then
                        return
                    end
                    
                    local GuiService = game:GetService("GuiService")
                    
                    pcall(function()
                        GuiService.SelectedObject = nil
                    end)
                    task.wait(0.1)
                    
                    if not buttonToPress or not buttonToPress.Parent or not buttonToPress:IsDescendantOf(LocalPlayer.PlayerGui) then
                        return
                    end
                    
                    local setSuccess = pcall(function()
                        GuiService.SelectedObject = buttonToPress
                    end)
                    
                    if not setSuccess then
                        return
                    end
                    
                    local lockConnection
                    lockConnection = RunService.Heartbeat:Connect(function()
                        pcall(function()
                            if buttonToPress and buttonToPress.Parent and GuiService.SelectedObject ~= buttonToPress then
                                GuiService.SelectedObject = buttonToPress
                            end
                        end)
                    end)
                    
                    task.wait(0.3)
                    
                    if GuiService.SelectedObject == buttonToPress then
                        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.2)
                        
                        print("[Auto " .. actionName .. "] ✅ Button pressed successfully!")
                        
                        getgenv()._isTeleporting = true
                        
                        if lockConnection then
                            lockConnection:Disconnect()
                        end
                        
                        GuiService.SelectedObject = nil
                    else
                        if lockConnection then
                            lockConnection:Disconnect()
                        end
                    end
                end)
            end
        end)
    end
end)

do
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
end



do
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
        if abilityName == "Who Decided That?" then
            pcall(function() 
                RS.Remotes.Ability:InvokeServer(tower, abilityName)
                print("[Soul Ability] Used: " .. abilityName)
            end)
        else
            local correctedName = fixAbilityName(abilityName)
            pcall(function() RS.Remotes.Ability:InvokeServer(tower, correctedName) end)
        end
    end
end

local function getAbilityData(towerName, abilityName)
    if abilityName == "Who Decided That?" then
        return {
            cooldown = 999999,
            requiredLevel = 0,
            isSoulAbility = true
        }
    end
    
    local abilities = getAllAbilities(towerName)
    return abilities[abilityName]
end

local function isOnCooldown(towerName, abilityName)
    local d = getAbilityData(towerName, abilityName)
    if not d or not d.cooldown then return false end
    local key = towerName .. "_" .. abilityName
    local last = abilityCooldowns[key]
    if not last then return false end
    
    if d.isSoulAbility then
        local timeSinceUse = tick() - last
        local cooldownRemaining = d.cooldown - timeSinceUse
        return cooldownRemaining > 0.5
    end
    
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
    if d and d.isSoulAbility then
        return true
    end
    return d and towerLevel >= d.requiredLevel
end

getgenv()._AbilityHelpers1 = {
    getCurrentWave = getCurrentWave,
    getCurrentTimeScale = getCurrentTimeScale,
    getUpgradeLevel = getUpgradeLevel,
    fixAbilityName = fixAbilityName,
    useAbility = useAbility,
    getAbilityData = getAbilityData,
    isOnCooldown = isOnCooldown,
    setAbilityUsed = setAbilityUsed,
    hasAbilityBeenUnlocked = hasAbilityBeenUnlocked
}

end

do
if not getgenv()._AbilityState then
    getgenv()._AbilityState = {
        abilityCooldowns = {},
        bossSpawnTime = nil,
        generalBossSpawnTime = nil,
        bossInRangeTracker = {}
    }
end

local state = getgenv()._AbilityState
local helpers1 = getgenv()._AbilityHelpers1

local function isOnCooldown(towerUniqueId, abilityName, actualTowerName)
    local nameForData = actualTowerName or towerUniqueId:match("^([^_]+)")
    
    local d = helpers1.getAbilityData(nameForData, abilityName)
    if not d or not d.cooldown then return false end
    
    local key = towerUniqueId .. "_" .. abilityName
    local last = state.abilityCooldowns[key]
    if not last then return false end
    
    local scale = helpers1.getCurrentTimeScale()
    local effectiveCd = d.cooldown / scale
    local timeSinceUse = tick() - last
    local cooldownRemaining = effectiveCd - timeSinceUse
    return cooldownRemaining > 0.5
end

local function setAbilityUsed(towerUniqueId, abilityName)
    state.abilityCooldowns[towerUniqueId.."_"..abilityName] = tick()
end

local function bossExists()
    local ok, res = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then 
            return false 
        end
        
        for _, enemy in pairs(enemies:GetChildren()) do
            if enemy:IsA("Model") then
                local bossValue = enemy:FindFirstChild("Boss")
                if bossValue and bossValue:IsA("BoolValue") and bossValue.Value == true then
                    return true
                end
            end
        end
        
        return false
    end)
    if not ok then
        warn("[Auto Ability] Error checking boss existence:", res)
    end
    return ok and res
end

local function bossReadyForAbilities()
    if bossExists() then
        if not state.generalBossSpawnTime then state.generalBossSpawnTime = tick() end
        return (tick() - state.generalBossSpawnTime) >= 1
    else
        state.generalBossSpawnTime = nil
        return false
    end
end

getgenv()._AbilityHelpers2a = {
    isOnCooldown = isOnCooldown,
    setAbilityUsed = setAbilityUsed,
    bossExists = bossExists,
    bossReadyForAbilities = bossReadyForAbilities
}

end

do
local state = getgenv()._AbilityState
local helpers2a = getgenv()._AbilityHelpers2a

local function bossExists()
    return helpers2a.bossExists()
end

local function checkBossSpawnTime()
    if bossExists() then
        if not state.bossSpawnTime then state.bossSpawnTime = tick() end
        return (tick() - state.bossSpawnTime) >= 16
    else
        state.bossSpawnTime = nil
        return false
    end
end

local function getBossCFrame()
    local ok, res = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        
        for _, enemy in pairs(enemies:GetChildren()) do
            if enemy:IsA("Model") then
                local bossValue = enemy:FindFirstChild("Boss")
                if bossValue and bossValue:IsA("BoolValue") and bossValue.Value == true then
                    local hrp = enemy:FindFirstChild("HumanoidRootPart")
                    if hrp then 
                        return hrp.CFrame 
                    end
                end
            end
        end
        
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
        if not state.bossInRangeTracker[name] then
            state.bossInRangeTracker[name] = currentTime
            return false
        else
            return (currentTime - state.bossInRangeTracker[name]) >= requiredDuration
        end
    else
        state.bossInRangeTracker[name] = nil
    end
    return false
end

local function getTowerInfoName(tower)
    if not tower then return nil end
    local uniqueId = tostring(tower)
    return tower.Name .. "_" .. uniqueId:sub(-8)
end

local function resetRoundTrackers()
    state.bossSpawnTime = nil
    state.generalBossSpawnTime = nil
    state.bossInRangeTracker = {}
    state.abilityCooldowns = {}
end

local helpers1 = getgenv()._AbilityHelpers1
local helpers2a = getgenv()._AbilityHelpers2a
getgenv()._AbilitySystemFuncs = {
    getCurrentWave = helpers1.getCurrentWave,
    getCurrentTimeScale = helpers1.getCurrentTimeScale,
    getUpgradeLevel = helpers1.getUpgradeLevel,
    fixAbilityName = helpers1.fixAbilityName,
    useAbility = helpers1.useAbility,
    getAbilityData = helpers1.getAbilityData,
    hasAbilityBeenUnlocked = helpers1.hasAbilityBeenUnlocked,
    isOnCooldown = helpers2a.isOnCooldown,
    setAbilityUsed = helpers2a.setAbilityUsed,
    bossExists = helpers2a.bossExists,
    bossReadyForAbilities = helpers2a.bossReadyForAbilities,
    getTowerCFrame = getTowerCFrame,
    getBossCFrame = getBossCFrame,
    getTowerRange = getTowerRange,
    isBossInRange = isBossInRange,
    checkBossInRangeForDuration = checkBossInRangeForDuration,
    getTowerInfoName = getTowerInfoName,
    resetRoundTrackers = resetRoundTrackers
}

end

do
local lastWave = 0
local Towers = workspace:WaitForChild("Towers", 10)
local funcs = getgenv()._AbilitySystemFuncs

local function checkGameEndedReset()
    local ok = pcall(function()
        local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if endGameUI and endGameUI:FindFirstChild("Frame") then
            funcs.resetRoundTrackers()
        end
    end)
end

local function processAbility(tower, unitName, abilityName, cfg, currentWave, hasBoss)
    local infoName = funcs.getTowerInfoName(tower) 
    local towerLevel = funcs.getUpgradeLevel(tower)
    local savedCfg = getgenv().Config.abilities[unitName] and getgenv().Config.abilities[unitName][abilityName]
    
    if savedCfg then
        cfg.enabled = savedCfg.enabled
        cfg.onlyOnBoss = savedCfg.onlyOnBoss or false
        cfg.useOnWave = savedCfg.useOnWave or false
        cfg.specificWave = savedCfg.specificWave
        cfg.requireBossInRange = savedCfg.requireBossInRange or false
    end
    
    if not cfg.enabled then return end
    
    local shouldUse = true
    
    if not funcs.hasAbilityBeenUnlocked(unitName, abilityName, towerLevel) then
        return
    end
    
    if funcs.isOnCooldown(infoName, abilityName, unitName) then
        return
    end
    
    if cfg.useOnWave and cfg.specificWave then
        if currentWave ~= cfg.specificWave then
            return
        end
    end
    
    if cfg.onlyOnBoss then
        if not hasBoss or not funcs.bossReadyForAbilities() then
            return
        end
    end
    
    if cfg.requireBossInRange then
        if not hasBoss or not funcs.checkBossInRangeForDuration(tower, 0) then
            return
        end
    end
    
    if not funcs.isOnCooldown(infoName, abilityName, unitName) then
        funcs.useAbility(tower, abilityName)
        funcs.setAbilityUsed(infoName, abilityName)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            checkGameEndedReset()
            local currentWave = funcs.getCurrentWave()
            local hasBoss = funcs.bossExists()
            
            if currentWave < lastWave then
                funcs.resetRoundTrackers()
            end
            
            if getgenv().SeamlessFixEnabled and lastWave >= 50 and currentWave < 50 then
                funcs.resetRoundTrackers()
            end
            
            if currentWave == 1 and lastWave > 10 then
                funcs.resetRoundTrackers()
            end
            
            lastWave = currentWave
            
            if not Towers then return end
            if not getgenv().UnitAbilities or type(getgenv().UnitAbilities) ~= "table" then return end
            
            for unitName, abilitiesConfig in pairs(getgenv().UnitAbilities) do
                for _, tower in pairs(Towers:GetChildren()) do
                    local owner = tower:FindFirstChild("Owner")
                    if tower.Name == unitName and owner and owner.Value == LocalPlayer then
                        for abilityName, cfg in pairs(abilitiesConfig) do
                            processAbility(tower, unitName, abilityName, cfg, currentWave, hasBoss)
                        end
                    end
                end
            end
        end)
    end
end)

end


do
    task.spawn(function()
        while true do
            task.wait(1)
            if getgenv().BulmaEnabled then
            local success, err = pcall(function()
                local towers = workspace:FindFirstChild("Towers")
                if not towers then return end
                
                local bulma = nil
                for _, tower in pairs(towers:GetChildren()) do
                    local owner = tower:FindFirstChild("Owner")
                    if tower.Name == "Bulma" and owner and owner.Value == LocalPlayer then
                        bulma = tower
                        break
                    end
                end
                
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
end



do
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
            local owner = tower:FindFirstChild("Owner")
            if tower.Name == "JinMoriGodly" and tower:IsA("Model") and owner and owner.Value == LocalPlayer then
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
            local owner = tower:FindFirstChild("Owner")
            if tower.Name == "JinMoriGodlyClone" and tower:IsA("Model") and owner and owner.Value == LocalPlayer then
                table.insert(clones, tower)
            end
        end
        return clones
    end
    
    local function useCloneSynthesis(jinMoriTower)
        if not jinMoriTower then return false end
        
        local success, err = pcall(function()
            local Ability = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Ability")
            if Ability then
                Ability:InvokeServer(jinMoriTower, "Clone Synthesis")
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
            local UpgradeEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Upgrade")
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
            local Ability = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Ability")
            if Ability then
                Ability:InvokeServer(cloneTower, "Clone Diffusion")
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
                if currentNirvana < 4 then
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
end


do
    task.spawn(function()
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" then
            getgenv().BulmaWishUsedThisRound = false
            getgenv().WukongTrackedClones = {}
            getgenv()._WukongLastSynthesisTime = 0
            getgenv().OneEyeDevilCurrentIndex = 0 
            
            if getgenv()._EtoEvoAbilityUsed then
                getgenv()._EtoEvoAbilityUsed = {}
            end
        end
    end)
    end)
end

do
    task.spawn(function()
        local SIGIL_ORDER = {
            [0] = "Ocular Sigil: Eye",
            [1] = "Ocular Sigil: Mouth",
            [2] = "Ocular Sigil: Arm",
            [3] = "Ocular Sigil: Leg"
        }
        
        if not getgenv()._EtoEvoAbilityUsed then
            getgenv()._EtoEvoAbilityUsed = {}
        end
        
        local function getEtoEvoTower()
            local towers = workspace:FindFirstChild("Towers")
            if not towers then return nil end
            
            for _, tower in pairs(towers:GetChildren()) do
                local owner = tower:FindFirstChild("Owner")
                if tower.Name == "EtoEvo" and owner and owner.Value == LocalPlayer then
                    return tower
                end
            end
            return nil
        end
        
        local function getTowerInfoName(tower)
            if not tower then return nil end
            local config = tower:FindFirstChild("Config")
            if config then
                local infoName = config:FindFirstChild("InfoName")
                if infoName and infoName.Value then
                    return infoName.Value
                end
            end
            return tower.Name
        end
        
        local function getUpgradeLevel(tower)
            if not tower then return 0 end
            local upgrade = tower:FindFirstChild("Upgrade")
            return upgrade and upgrade.Value or 0
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
        
        local function resetEtoEvoCooldowns()
            if getgenv()._EtoEvoAbilityUsed then
                getgenv()._EtoEvoAbilityUsed = {}
            end
            print("[One Eye Devil] Cooldowns reset")
        end
        
        local function isOnCooldown(infoName, abilityName, unitName)
            if not getgenv()._EtoEvoAbilityUsed[infoName] then
                return false
            end
            
            local lastUse = getgenv()._EtoEvoAbilityUsed[infoName][abilityName]
            if not lastUse then return false end
            
            local baseCooldown = 50
            local towerInfo = getgenv().MacroTowerInfoCache
            if towerInfo and towerInfo[unitName] then
                for level, data in pairs(towerInfo[unitName]) do
                    if data.Abilities then
                        for _, abilityData in ipairs(data.Abilities) do
                            if abilityData.Name == abilityName then
                                baseCooldown = abilityData.Cd or 50
                                break
                            end
                        end
                    end
                end
            end
            
            local timeScale = getCurrentTimeScale()
            local effectiveCooldown = baseCooldown / timeScale
            
            local elapsed = tick() - lastUse
            return elapsed < effectiveCooldown
        end
        
        local function setAbilityUsed(infoName, abilityName)
            if not getgenv()._EtoEvoAbilityUsed[infoName] then
                getgenv()._EtoEvoAbilityUsed[infoName] = {}
            end
            getgenv()._EtoEvoAbilityUsed[infoName][abilityName] = tick()
        end
        
        local function getCardButtons()
            local ok, result = pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not prompt or not prompt.Enabled then return nil end
                
                local frame = prompt:FindFirstChild("Frame")
                if not frame then return nil end
                
                local frame2 = frame:FindFirstChild("Frame")
                if not frame2 then return nil end
                
                local frame3 = frame2:FindFirstChild("Frame")
                if not frame3 then return nil end
                
                local frame4 = frame3:FindFirstChild("Frame")
                if not frame4 then return nil end
                
                local buttons = {}
                for _, child in ipairs(frame4:GetChildren()) do
                    if child:IsA("TextButton") then
                        table.insert(buttons, child)
                    end
                end
                
                return #buttons > 0 and buttons or nil
            end)
            
            return ok and result or nil
        end
        
        local function getCardName(button)
            local ok, result = pcall(function()
                local function searchForTextLabel(parent, depth)
                    if depth > 10 then return nil end
                    
                    for _, child in ipairs(parent:GetChildren()) do
                        if child:IsA("TextLabel") and child.Text ~= "" and child.Text:find("Ocular Sigil") then
                            return child.Text
                        end
                        
                        if child:IsA("Frame") or child:IsA("Folder") then
                            local found = searchForTextLabel(child, depth + 1)
                            if found then return found end
                        end
                    end
                    
                    return nil
                end
                
                return searchForTextLabel(button, 0)
            end)
            
            return ok and result or nil
        end
        
        local function clickButton(button)
            if not button then return false end
            
            local success = false
            
            if getconnections then
                pcall(function()
                    local events = {"Activated", "MouseButton1Click", "MouseButton1Down"}
                    for _, eventName in ipairs(events) do
                        local connections = getconnections(button[eventName])
                        if connections then
                            for _, conn in ipairs(connections) do
                                if conn and conn.Fire then
                                    conn:Fire()
                                    success = true
                                end
                            end
                        end
                    end
                end)
            end
            
            if not success then
                pcall(function()
                    local GuiService = game:GetService("GuiService")
                    GuiService.SelectedObject = nil
                    task.wait(0.05)
                    GuiService.SelectedObject = button
                    task.wait(0.1)
                    
                    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.02)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    
                    success = true
                end)
            end
            
            return success
        end
        
        local lastWave = 0
        local isWaitingForPrompt = false
        local promptWaitStart = 0
        
        while true do
            task.wait(0.5)
            
            if not getgenv().OneEyeDevilEnabled then
                task.wait(2)
                continue
            end
            
            pcall(function()
                local currentWave = 0
                pcall(function()
                    local wave = RS:FindFirstChild("Wave")
                    if wave and wave:IsA("NumberValue") then
                        currentWave = wave.Value
                    end
                end)
                
                if currentWave < lastWave then
                    resetEtoEvoCooldowns()
                    isWaitingForPrompt = false
                end
                
                if getgenv().SeamlessFixEnabled and lastWave >= 50 and currentWave < 50 then
                    resetEtoEvoCooldowns()
                    isWaitingForPrompt = false
                end
                
                if currentWave == 1 and lastWave > 10 then
                    resetEtoEvoCooldowns()
                    isWaitingForPrompt = false
                end
                
                lastWave = currentWave
                
                local tower = getEtoEvoTower()
                if not tower then 
                    isWaitingForPrompt = false
                    return 
                end
                
                local infoName = getTowerInfoName(tower)
                local towerLevel = getUpgradeLevel(tower)
                
                if towerLevel < 3 then
                    return
                end
                
                local buttons = getCardButtons()
                
                if buttons then
                    if isWaitingForPrompt and tick() - promptWaitStart > 5 then
                        isWaitingForPrompt = false
                        return
                    end
                    
                    if not isWaitingForPrompt then
                        isWaitingForPrompt = true
                        promptWaitStart = tick()
                    end
                    
                    local targetCard = SIGIL_ORDER[getgenv().OneEyeDevilCurrentIndex]
                    
                    local foundCard = false
                    for _, button in ipairs(buttons) do
                        local cardName = getCardName(button)
                        if cardName then
                            if cardName == targetCard then
                                print("[One Eye Devil] Clicking: " .. cardName)
                                
                                if clickButton(button) then
                                    foundCard = true
                                    isWaitingForPrompt = false
                                    
                                    setAbilityUsed(infoName, "Detachment")
                                    
                                    local timeScale = getCurrentTimeScale()
                                    local baseCd = 50
                                    local effectiveCd = baseCd / timeScale
                                    
                                    getgenv().OneEyeDevilCurrentIndex = (getgenv().OneEyeDevilCurrentIndex + 1) % 4
                                    
                                    local nextCard = SIGIL_ORDER[getgenv().OneEyeDevilCurrentIndex]
                                    local cdText = string.format("%.1fs", effectiveCd)
                                    if timeScale ~= 1 then
                                        cdText = cdText .. " (x" .. timeScale .. " speed)"
                                    end
                                    
                                    print("[One Eye Devil] Next card: " .. nextCard .. " (CD: " .. cdText .. ")")
                                    
                                    Window:Notify({
                                        Title = "One Eye Devil",
                                        Description = "Selected: " .. cardName,
                                        Lifetime = 2
                                    })
                                    
                                    break
                                end
                            end
                        end
                    end

                    return
                end
                
                if not isWaitingForPrompt and not isOnCooldown(infoName, "Detachment", "EtoEvo") then
                    local abilityUsed, abilityResult = pcall(function()
                        return RS.Remotes.Ability:InvokeServer(tower, "Detachment")
                    end)
                    
                    if abilityUsed and abilityResult then
                        isWaitingForPrompt = true
                        promptWaitStart = tick()
                    end
                end
            end)
        end
    end)
end

do
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
                    getgenv().OneEyeDevilCurrentIndex = 0 
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

task.spawn(function()
    while true do
        task.wait(2)
        
        local currentlyInLobby = false
        pcall(function()
            local lobbyCheck = workspace:FindFirstChild("Lobby")
            currentlyInLobby = lobbyCheck ~= nil
        end)
        
        if currentlyInLobby and (getgenv().FinalExpAutoJoinEasyEnabled or getgenv().FinalExpAutoJoinHardEnabled) then
            pcall(function()
                local finalExpRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("FinalExpeditionStart")
                if finalExpRemote then
                    if getgenv().FinalExpAutoJoinEasyEnabled then
                        finalExpRemote:FireServer("Easy")
                        print("[Final Expedition] Auto joining Easy mode")
                    elseif getgenv().FinalExpAutoJoinHardEnabled then
                        finalExpRemote:FireServer("Hard")
                        print("[Final Expedition] Auto joining Hard mode")
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        
        local currentlyInLobby = false
        pcall(function()
            local lobbyCheck = workspace:FindFirstChild("Lobby")
            currentlyInLobby = lobbyCheck ~= nil
        end)
        
        if not currentlyInLobby then
            pcall(function()
                local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not promptUI then return end
                
                local frame = promptUI:FindFirstChild("Frame")
                if not frame then return end
                
                local function clickOptionButton(button)
                    if not button then return false end
                    print("[Final Expedition] Clicking button:", button:GetFullName())
                    local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
                    for _, ev in ipairs(events) do
                        pcall(function()
                            for _, conn in ipairs(getconnections(button[ev])) do
                                conn:Fire()
                            end
                        end)
                        task.wait(0.05)
                    end
                    return true
                end
                
                local function findOptionsWithButtons()
                    local options = {}
                    local innerFrames = frame:GetDescendants()
                    for _, obj in pairs(innerFrames) do
                        if obj:IsA("TextButton") then
                            for _, child in pairs(obj:GetDescendants()) do
                                if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                                    local text = child.Text:gsub("<[^>]+>", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
                                    if text ~= "" and #text < 100 then
                                        options[text] = obj
                                    end
                                end
                            end
                        end
                    end
                    return options
                end
                
                local availableOptions = findOptionsWithButtons()
                if next(availableOptions) == nil then return end
                
                if getgenv().FinalExpSkipRewardsEnabled then
                    if availableOptions["Click anywhere to continue"] or availableOptions["(Click anywhere to continue)"] then
                        print("[Final Expedition] Reward screen detected - clicking to skip")
                        
                        local textButton = frame:FindFirstChild("TextButton")
                        if textButton and textButton.Visible then
                            clickOptionButton(textButton)
                            task.wait(0.3)
                            return
                        end
                        
                        local folder = frame:FindFirstChild("Folder")
                        if folder then
                            local folderButton = folder:FindFirstChild("TextButton")
                            if folderButton and folderButton.Visible then
                                clickOptionButton(folderButton)
                                task.wait(0.3)
                                return
                            end
                        end
                    end
                end
                
                if getgenv().FinalExpAutoSkipShopEnabled and availableOptions["Shop"] then
                    print("[Final Expedition] Skipping Shop - clicking Shop card")
                    clickOptionButton(availableOptions["Shop"])
                    task.wait(0.5)
                    
                    print("[Final Expedition] Looking for Shop button inside shop UI...")
                    local shopButtonClicked = false
                    local maxAttempts = 10
                    for attempt = 1, maxAttempts do
                        local screenGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
                        if screenGui then
                            local shopFrame = screenGui:FindFirstChild("Frame")
                            if shopFrame then
                                local children = shopFrame:GetChildren()
                                if children[4] then
                                    local innerFrame = children[4]:FindFirstChild("Frame")
                                    if innerFrame then
                                        local folder = innerFrame:FindFirstChild("Folder")
                                        if folder then
                                            local shopButton = folder:FindFirstChild("TextButton")
                                            if shopButton then
                                                print("[Final Expedition] Found Shop button, clicking...")
                                                clickOptionButton(shopButton)
                                                shopButtonClicked = true
                                                task.wait(0.3)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(0.2)
                    end
                    
                    if not shopButtonClicked then
                        print("[Final Expedition] Shop button not found after " .. maxAttempts .. " attempts")
                    end
                    return
                end
                
                if getgenv().FinalExpAutoSelectModeEnabled then
                    local priorities = {
                        {name = "Rest Point", priority = getgenv().FinalExpRestPriority or 3},
                        {name = "Dungeon", priority = getgenv().FinalExpDungeonPriority or 1},
                        {name = "Double Dungeon", priority = getgenv().FinalExpDoubleDungeonPriority or 2}
                    }
                    
                    table.sort(priorities, function(a, b) return a.priority < b.priority end)
                    
                    for _, option in ipairs(priorities) do
                        if availableOptions[option.name] then
                            print("[Final Expedition] Auto selecting:", option.name, "(Priority:", option.priority .. ")")
                            clickOptionButton(availableOptions[option.name])
                            task.wait(0.3)
                            
                            if option.name == "Rest Point" then
                                task.wait(0.5)
                                pcall(function()
                                    local screenGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
                                    if screenGui then
                                        local restFrame = screenGui:FindFirstChild("Frame")
                                        if restFrame then
                                            local children = restFrame:GetChildren()
                                            if children[4] then
                                                local innerFrame = children[4]:FindFirstChild("Frame")
                                                if innerFrame then
                                                    local folder = innerFrame:FindFirstChild("Folder")
                                                    if folder then
                                                        local closeButton = folder:FindFirstChild("TextButton")
                                                        if closeButton then
                                                            print("[Final Expedition] Closing Rest Point UI")
                                                            clickOptionButton(closeButton)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                            
                            return
                        end
                    end
                end
            end)
        end
    end
end)


local function findBestPortalFromClientData()
    local clientData = getClientData()
    if not clientData or not clientData.PortalData then 
        print("[Portal] No portal data found in ClientData")
        return nil 
    end
    
    local selectedMap = getgenv().PortalConfig.selectedMap
    local targetTier = getgenv().PortalConfig.tier
    local useBestPortal = getgenv().PortalConfig.useBestPortal
    local priorities = getgenv().PortalConfig.priorities

    
    local matchingPortals = {}
    
    for portalID, portalInfo in pairs(clientData.PortalData) do
        pcall(function()
            if type(portalInfo) == "table" and portalInfo.PortalData then
                local portalData = portalInfo.PortalData
                if not portalData or type(portalData) ~= "table" then return end
                
                local mapMatch = (selectedMap == "" or portalData.Map == selectedMap)
                
                if mapMatch then
                    table.insert(matchingPortals, {
                        id = portalID,
                        tier = portalData.Tier or 0,
                        challenge = portalData.Challenges or "",
                        map = portalData.Map or ""
                    })
                    print("[Portal] Found: " .. (portalData.Map or "Unknown") .. " | Tier " .. (portalData.Tier or 0) .. " | " .. (portalData.Challenges or "None"))
                end
            end
        end)
    end
    
    if #matchingPortals == 0 then 
        return nil 
    end
    
    print("[Portal] Total matching portals: " .. #matchingPortals)
    
    if useBestPortal then
        table.sort(matchingPortals, function(a, b)
            return a.tier > b.tier
        end)
        
        local bestTier = matchingPortals[1].tier
        local bestTierPortals = {}
        
        for _, portal in ipairs(matchingPortals) do
            if portal.tier == bestTier then
                table.insert(bestTierPortals, portal)
            end
        end
        
        for priority = 1, 6 do
            for challengeName, priorityNum in pairs(priorities) do
                if priorityNum == priority and priorityNum > 0 then
                    for _, portal in ipairs(bestTierPortals) do
                        if portal.challenge == challengeName then
                            print("[Portal] ✓ Selected: " .. portal.map .. " | Tier " .. portal.tier .. " | " .. portal.challenge .. " (Priority: " .. priorityNum .. ")")
                            return portal.id
                        end
                    end
                end
            end
        end
        
        print("[Portal] ✓ Selected: " .. bestTierPortals[1].map .. " | Tier " .. bestTierPortals[1].tier .. " (No priority match)")
        return bestTierPortals[1].id
    end
    
    local tierFiltered = {}
    for _, portal in ipairs(matchingPortals) do
        if portal.tier == targetTier then
            table.insert(tierFiltered, portal)
        end
    end
    
    if #tierFiltered == 0 then
        print("[Portal] No portals found for tier " .. targetTier .. ", using first available")
        return matchingPortals[1].id
    end
    
    for priority = 1, 6 do
        for challengeName, priorityNum in pairs(priorities) do
            if priorityNum == priority and priorityNum > 0 then
                for _, portal in ipairs(tierFiltered) do
                    if portal.challenge == challengeName then
                        print("[Portal] ✓ Selected: " .. portal.map .. " | Tier " .. portal.tier .. " | " .. portal.challenge .. " (Priority: " .. priorityNum .. ")")
                        return portal.id
                    end
                end
            end
        end
    end
    
    print("[Portal] ✓ Selected: " .. tierFiltered[1].map .. " | Tier " .. tierFiltered[1].tier .. " (No priority match)")
    return tierFiltered[1].id
end

local function activatePortalAndStart(portalID)
    if not portalID then 
        print("[Portal] ❌ No portal ID provided")
        return false 
    end
        
    local success, err = pcall(function()
        local remotes = RS:FindFirstChild("Remotes")
        if not remotes then
            print("[Portal] ❌ Remotes not found")
            return false
        end
        
        local portalsFolder = remotes:FindFirstChild("Portals")
        if not portalsFolder then
            print("[Portal] ❌ Portals folder not found")
            print("[Portal] 🔍 Contents of Remotes:")
            for _, child in ipairs(remotes:GetChildren()) do
                print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
            end
            return false
        end
        
        local activateEvent = portalsFolder:FindFirstChild("Activate")
        if not activateEvent then
            return false
        end
        
        local result = activateEvent:InvokeServer(portalID)
        print("[Portal] ✓ ActivateEvent returned:", tostring(result))
        
        task.wait(0.5)
        
        local startEvent = portalsFolder:FindFirstChild("Start")
        if startEvent then
            print("[Portal] ✓ Calling Start:FireServer()")
            startEvent:FireServer()
            print("[Portal] ✅ Portal activated and started!")
            return true
        else
            print("[Portal] ⚠️ Start event not found, but portal activated")
            return true
        end
    end)
    
    if not success then
        print("[Portal] ❌ Error activating portal:", err)
    end
    
    return success
end

local function fastSelectPortal()    
    local ok, result = pcall(function()
        local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
        if not prompt then 
            return false 
        end
        
        local frame1 = prompt:FindFirstChild("Frame")
        if not frame1 then 
            return false 
        end
        
        local frame2 = frame1:FindFirstChild("Frame")
        if not frame2 then 
            return false 
        end
        
        local children = frame2:GetChildren()
        if #children < 4 then
            return false
        end
        
        local fourthChild = children[4]
        
        local subChildren = fourthChild:GetChildren()
        if #subChildren < 2 then
            return false
        end
        
        local secondSubChild = subChildren[2]
        
        local portalButton = secondSubChild:FindFirstChild("TextButton")
        if not portalButton then
            return false
        end
        
        local GuiService = game:GetService("GuiService")
        local VIM = game:GetService("VirtualInputManager")
        
        GuiService.SelectedObject = nil
        task.wait(0.1)
        
        GuiService.SelectedObject = portalButton
        
        local lockConnection
        lockConnection = RunService.Heartbeat:Connect(function()
            if GuiService.SelectedObject ~= portalButton then
                GuiService.SelectedObject = portalButton
            end
        end)
        
        task.wait(0.2)
        
        if GuiService.SelectedObject == portalButton then
            print("[Portal Reward] Pressing Enter to select portal...")
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.02)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            
            task.wait(0.3)
            
            if lockConnection then
                lockConnection:Disconnect()
            end
            
            GuiService.SelectedObject = nil
        else
            if lockConnection then
                lockConnection:Disconnect()
            end
            print("[Portal Reward] ❌ Failed to select portal button")
            return false
        end
        
        task.wait(0.2)
        
        local confirmButton = nil
        
        local frame1 = prompt:FindFirstChild("Frame")
        if frame1 then
            local frame2 = frame1:FindFirstChild("Frame")
            if frame2 then
                local children = frame2:GetChildren()
                if #children >= 5 then
                    local fifthChild = children[5]
                    confirmButton = fifthChild:FindFirstChild("TextButton")
                    if confirmButton then
                        print("[Portal Reward] ✓ Found confirm button")
                    end
                end
            end
        end
        
        if confirmButton then
            print("[Portal Reward] Selecting confirm button...")
            GuiService.SelectedObject = nil
            task.wait(0.05)
            
            GuiService.SelectedObject = confirmButton
            
            local confirmLock
            confirmLock = RunService.Heartbeat:Connect(function()
                if GuiService.SelectedObject ~= confirmButton then
                    GuiService.SelectedObject = confirmButton
                end
            end)
            
            task.wait(0.2)
            
            if GuiService.SelectedObject == confirmButton then
                for i = 1, 3 do
                    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.02)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    task.wait(0.02)
                end
                
                task.wait(0.1)
                
                if confirmLock then
                    confirmLock:Disconnect()
                end
                
                GuiService.SelectedObject = nil
                print("[Portal Reward] ✅ Portal selected!")
                return true
            else
                if confirmLock then
                    confirmLock:Disconnect()
                end
                print("[Portal Reward] ❌ Failed to select confirm button")
                return false
            end
        else
            print("[Portal Reward] ❌ Confirm button not found")
            return false
        end
    end)
    
    if not ok then
        warn("[Portal Reward] Error:", result)
    end
    
    return ok and result
end

task.spawn(function()
    local lastProcessedTime = 0
    local isProcessing = false
    
    while true do
        task.wait(0.5)
        
        if getgenv().PortalConfig.autoPickReward and not isProcessing then
            local success, err = pcall(function()
                local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not promptUI then return end
                
                local frame = promptUI:FindFirstChild("Frame")
                if not frame or not frame:FindFirstChild("Frame") then return end
                
                local children = frame.Frame:GetChildren()
                local hasPortalButtons = false
                
                for _, child in ipairs(children) do
                    if child:IsA("Frame") then
                        for _, descendant in ipairs(child:GetDescendants()) do
                            if descendant:IsA("TextButton") and descendant.Name == "TextButton" then
                                hasPortalButtons = true
                                break
                            end
                        end
                        if hasPortalButtons then break end
                    end
                end
                
                if hasPortalButtons then
                    local now = tick()
                    if now - lastProcessedTime > 10 then
                        isProcessing = true
                        lastProcessedTime = now
                        task.wait(1)
                        
                        local success = fastSelectPortal()
                        
                        if success then
                            task.wait(2)
                            for i = 1, 10 do
                                if not LocalPlayer.PlayerGui:FindFirstChild("Prompt") then
                                    break
                                end
                                task.wait(0.5)
                            end
                        end
                        
                        isProcessing = false
                    end
                end
            end)
            
            if not success then
                warn("[Portal Reward] Error in detection loop:", err)
                isProcessing = false
            end
        end
    end
end)

task.spawn(function()
    local lastActivationTime = 0
    
    while true do
        task.wait(2)
        
        local shouldActivate = (getgenv().PortalConfig.useBestPortal == true) or 
                               (getgenv().PortalConfig.useSelectedTier == true)
        
        if shouldActivate then
            local currentlyInLobby = false
            pcall(function()
                local lobbyCheck = workspace:FindFirstChild("Lobby")
                currentlyInLobby = lobbyCheck ~= nil
            end)
            
            local canActivate = false
            
            if currentlyInLobby then
                canActivate = true
            else
                local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
                if endGameUI then
                    local gameHasEnded = false
                    if endGameUI:FindFirstChild("Frame") then
                        gameHasEnded = endGameUI.Frame.Visible
                    elseif endGameUI:FindFirstChild("BG") then
                        gameHasEnded = endGameUI.BG.Visible
                    else
                        gameHasEnded = endGameUI.Enabled
                    end
                    canActivate = gameHasEnded
                end
            end
            
            if canActivate then
                local promptExists = LocalPlayer.PlayerGui:FindFirstChild("Prompt") ~= nil
                
                if not promptExists then
                    local now = tick()
                    
                    if now - lastActivationTime > 10 then
                        pcall(function()
                            local portalID = findBestPortalFromClientData()
                            if portalID then
                                local success = activatePortalAndStart(portalID)
                                if success then
                                    lastActivationTime = now
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end)

if isInLobby then
    task.spawn(function()
        while true do
            task.wait(2)
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
end


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
        
        local maxRetries = 3
        local retryDelay = 1
        local response = nil
        
        for attempt = 1, maxRetries do
            local requestSuccess, requestResult = pcall(function()
                return requestFunc({
                    Url = url,
                    Method = "POST",
                    Headers = headers,
                    Body = body
                })
            end)
            
            if requestSuccess and requestResult then
                response = requestResult
                break
            else
                warn("[Webhook] Attempt " .. attempt .. "/" .. maxRetries .. " failed: " .. tostring(requestResult))
                if attempt < maxRetries then
                    task.wait(retryDelay)
                    retryDelay = retryDelay * 2 
                end
            end
        end
        
        if not response then
            warn("[Webhook] All retry attempts failed")
            return false
        end
        
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


do
    if not getgenv()._WebhookInitialData then
        getgenv()._WebhookInitialData = {}
        task.spawn(function()
            task.wait(2)
            local clientData = getClientData()
            if clientData then
                getgenv()._WebhookInitialData = {
                    Jewels = clientData.Jewels or 0,
                    Gold = clientData.Gold or 0,
                    Emeralds = clientData.Emeralds or 0,
                    Rerolls = clientData.Rerolls or 0,
                    CandyBasket = clientData.CandyBasket or 0,
                    HeroTokens = clientData.HeroTokens or 0,
                    EXP = clientData.EXP or 0,
                    ItemData = {},
                    ExperienceItemsData = {}
                }
                
                if clientData.ItemData then
                    for itemName, itemInfo in pairs(clientData.ItemData) do
                        if itemInfo.Amount then
                            getgenv()._WebhookInitialData.ItemData[itemName] = itemInfo.Amount
                        end
                    end
                end
                
                if clientData.ExperienceItemsData then
                    for itemName, itemInfo in pairs(clientData.ExperienceItemsData) do
                        if itemInfo.Amount then
                            getgenv()._WebhookInitialData.ExperienceItemsData[itemName] = itemInfo.Amount
                        end
                    end
                end
                
                getgenv()._WebhookInitialData.UnitCounts = {}
                if clientData.UnitData then
                    for unitID, unitInfo in pairs(clientData.UnitData) do
                        if unitInfo.UnitName then
                            local unitName = unitInfo.UnitName
                            getgenv()._WebhookInitialData.UnitCounts[unitName] = (getgenv()._WebhookInitialData.UnitCounts[unitName] or 0) + 1
                        end
                    end
                end
                
                print("[Webhook] Initial data captured")
            end
        end)
    end
    
    task.spawn(function()
        local lastWebhookHash = ""
        local lastWebhookTime = 0
        local WEBHOOK_COOLDOWN = 10
        local isProcessing = false
    
    local function sendWebhook()
        local success, err = pcall(function()
            if not getgenv().WebhookEnabled then 
                print("[Webhook] Webhook disabled, skipping")
                getgenv().WebhookProcessing = false
                return 
            end
            
            if isProcessing and not getgenv().WebhookProcessing then 
                print("[Webhook] Already processing, skipping duplicate call")
                return 
            end
            
            local currentTime = tick()
            if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then 
                print("[Webhook] Cooldown active, skipping (" .. (WEBHOOK_COOLDOWN - (currentTime - lastWebhookTime)) .. "s remaining)")
                getgenv().WebhookProcessing = false
                return 
            end
            
            if getgenv()._webhookLock and (currentTime - getgenv()._webhookLock) < 8 then 
                print("[Webhook] Lock active, skipping")
                getgenv().WebhookProcessing = false
                return 
            end
            
            print("[Webhook] Starting webhook send process...")
            getgenv()._webhookLock = currentTime
            lastWebhookTime = currentTime
            isProcessing = true
            if not getgenv().WebhookProcessing then
                getgenv().WebhookProcessing = true
            end
            
            
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
                task.wait(0.5)
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchResult or matchResult == "Unknown" or matchResult == "" then
                warn("[Webhook] Invalid match result, skipping send")
                task.wait(0.5)
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchTime or matchTime == "00:00:00" or matchTime == "" then
                warn("[Webhook] Invalid match time, skipping send")
                task.wait(0.5)
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            print("[Webhook] Data validated - Wave: " .. matchWave .. ", Result: " .. matchResult .. ", Time: " .. matchTime)
            
            
            local function formatStats()
                local stats = "<:gold:1265957290251522089> " .. formatNumber(clientData.Jewels or 0)
                stats = stats .. "\n<:jewel:1217525743408648253> " .. formatNumber(clientData.Gold or 0)
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
                    local initialValue = 0
                    local currentValue = 0
                    local itemName = r.name
                    local itemKey = itemName:gsub(" ", "")
                    
                    if itemKey == "HeroCoins" then itemKey = "HeroTokens" end
                    if itemKey == "PlayerEXP" then itemKey = "EXP" end
                    
                    if r.type == "Unit" then
                        local unitFileName = getUnitFileName(itemName)
                        initialValue = getgenv()._WebhookInitialData.UnitCounts[unitFileName] or 0
                        
                        currentValue = 0
                        if clientData.UnitData then
                            for unitID, unitInfo in pairs(clientData.UnitData) do
                                if unitInfo.UnitName == unitFileName then
                                    currentValue = currentValue + 1
                                end
                            end
                        end
                        
                        local total = initialValue + r.amount
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    elseif clientData[itemKey] and type(clientData[itemKey]) == "number" then
                        currentValue = clientData[itemKey]
                        initialValue = getgenv()._WebhookInitialData[itemKey] or 0
                        local total = currentValue 
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    elseif clientData.ItemData and clientData.ItemData[itemKey] then
                        currentValue = clientData.ItemData[itemKey].Amount or 0
                        initialValue = getgenv()._WebhookInitialData.ItemData[itemKey] or 0
                        local total = currentValue 
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    elseif clientData.ExperienceItemsData and clientData.ExperienceItemsData[itemKey] then
                        currentValue = clientData.ExperienceItemsData[itemKey].Amount or 0
                        initialValue = getgenv()._WebhookInitialData.ExperienceItemsData[itemKey] or 0
                        local total = currentValue 
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    elseif itemName:find("Candy Basket") then
                        currentValue = clientData.CandyBasket or 0
                        initialValue = getgenv()._WebhookInitialData.CandyBasket or 0
                        local total = currentValue 
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    elseif itemName:find("Bingo Stamp") and clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
                        currentValue = clientData.ItemData.HallowenBingoStamp.Amount or 0
                        initialValue = getgenv()._WebhookInitialData.ItemData.HallowenBingoStamp or 0
                        local total = currentValue 
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    else
                        local total = r.amount
                        rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
                    end
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
                if r.name and r.type == "Unit" then
                    hasUnitDrop = true
                    unitDropName = r.name
                    break
                end
            end
            
            local description = "**Username:** ||" .. LocalPlayer.Name .. "||\n**Level:** " .. (clientData.Level or 0) .. " [" .. formatNumber(clientData.EXP or 0) .. "/" .. formatNumber(clientData.MaxEXP or 0) .. "]"
            
            local embedColor = 0x00ff00
            if matchResult and (matchResult:upper():find("DEFEAT") or matchResult:upper():find("LOSE") or matchResult:upper():find("LOSS")) then
                embedColor = 0xff0000
            end
            
            local embed = {
                title = "Anime Last Stand",
                description = description or "N/A",
                color = embedColor,
                fields = {
                    { name = "Player Stats", value = (formatStats() ~= "" and formatStats() or "N/A"), inline = true },
                    { name = "Rewards", value = (rewardsText ~= "" and rewardsText or "No rewards found"), inline = true },
                    { name = "Units", value = (unitsText ~= "" and unitsText or "No units"), inline = false },
                    { name = "Match Result", value = (matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. ((mapDifficulty and mapDifficulty ~= "Unknown") and (" [" .. mapDifficulty .. "]") or "") .. " - " .. (matchResult or "Unknown"), inline = false }
                },
                footer = { text = "Byorl Last Stand | https://discord.gg/V3WcdHpd3J" }
            }
            
            local webhookContent = ""
            if hasUnitDrop and getgenv().PingOnSecretDrop and getgenv().DiscordUserID and getgenv().DiscordUserID ~= "" then
                webhookContent = "<@" .. getgenv().DiscordUserID .. "> 🎉 **SECRET UNIT DROP: " .. unitDropName .. "**"
            end
            
            local webhookHash = LocalPlayer.Name .. "_" .. matchTime .. "_" .. matchWave .. "_" .. rewardsText .. "_" .. (hasUnitDrop and unitDropName or "")
            if webhookHash == lastWebhookHash then
                print("[Webhook] Duplicate webhook detected, skipping send")
                task.wait(0.5)
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            lastWebhookHash = webhookHash
            print("[Webhook] Sending webhook to Discord...")
            
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
                    print("[Webhook] ✅ Webhook sent successfully!")
                    
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
                        print("[Webhook] Retrying in 1 second...")
                        task.wait(1)
                    end
                end
            end
            
            if not sendSuccess then
                warn("[Webhook] ❌ Failed to send after " .. maxAttempts .. " attempts")
                Window:Notify({
                    Title = "Webhook Failed",
                    Description = "Failed to send webhook. Check URL and try again.",
                    Lifetime = 5
                })
            end
            
            print("[Webhook] Cleaning up and releasing lock...")
            task.wait(0.5)
            isProcessing = false
            getgenv().WebhookProcessing = false
            print("[Webhook] Process complete, ready for next action")
        end)
        
        if not success then
            warn("[Webhook] ❌ Critical error in sendWebhook: " .. tostring(err))
            task.wait(0.5)
            isProcessing = false
            getgenv().WebhookProcessing = false
            print("[Webhook] Error recovery complete, flags cleared")
        end
    end
    
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" and getgenv().WebhookEnabled then
            print("[Webhook] EndGameUI detected, setting processing flag...")
            getgenv().WebhookProcessing = true
            print("[Webhook] Waiting 2s before sending...")
            task.wait(2)
            sendWebhook()
        end
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            print("[Webhook] EndGameUI removed, clearing processing flag...")
            task.wait(1)
            if getgenv().WebhookProcessing then
                warn("[Webhook] Force clearing WebhookProcessing flag due to UI removal")
                getgenv().WebhookProcessing = false
            end
        end
    end)
    
    task.spawn(function()
        task.wait(1)
        if getgenv().WebhookEnabled then
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if endGameUI and endGameUI.Enabled and not getgenv().WebhookProcessing then
                print("[Webhook] EndGameUI already present on load, sending webhook...")
                task.wait(1)
                sendWebhook()
            end
        end
    end)
end)



do
    task.spawn(function()
        local eventsFolder = RS:FindFirstChild("Events")
    local halloweenFolder = eventsFolder and eventsFolder:FindFirstChild("Hallowen2025")
    local enterEvent = halloweenFolder and halloweenFolder:FindFirstChild("Enter")
    local startEvent = halloweenFolder and halloweenFolder:FindFirstChild("Start")
    
    while true do
        task.wait(1) 
        

        if not getgenv().AutoEventEnabled then
            task.wait(2)
            continue
        end
        
        if enterEvent and startEvent then
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
end

if isInLobby then
    task.spawn(function()
        local BingoEvents = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("Bingo")
        if not BingoEvents then return end
        
        local UseStampEvent = BingoEvents:FindFirstChild("UseStamp")
        local ClaimRewardEvent = BingoEvents:FindFirstChild("ClaimReward")
        local CompleteBoardEvent = BingoEvents:FindFirstChild("CompleteBoard")
        
        
        while true do
            task.wait(3)
            
            if not getgenv().BingoEnabled then
                task.wait(5)
                continue
            end
            
            pcall(function()
                if UseStampEvent then
                    for i=1,25 do 
                        UseStampEvent:FireServer()
                        task.wait(0.1)
                    end
                end
                task.wait(0.5)
                if ClaimRewardEvent then
                    for i=1,25 do 
                        ClaimRewardEvent:InvokeServer(i)
                        task.wait(0.1)
                    end
                end
                task.wait(0.5)
                if CompleteBoardEvent then 
                    CompleteBoardEvent:InvokeServer()
                end
            end)
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
                    print("[Prompt] Clicked Frame.TextButton")
                end
                
                local folder = frame:FindFirstChild("Folder")
                if folder then
                    local folderButton = folder:FindFirstChild("TextButton")
                    if folderButton then
                        clickButton(folderButton)
                        success = true
                        print("[Prompt] Clicked Frame.Folder.TextButton")
                    end
                end
            end)
            return success
        end
        
        while true do
            task.wait(1) 
            
            if not getgenv().CapsuleEnabled then
                task.wait(3)
                continue
            end
            
            if true then
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
end



do
    if isInLobby then
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
end



do
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
end



do
    task.spawn(function()
        local VIM = game:GetService("VirtualInputManager")
    
    local function getAvailableCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt")
            if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame")
            if not frame or not frame:FindFirstChild("Frame") then return nil end
            
            local frameChildren = frame:FindFirstChild("Frame"):GetChildren()
            if #frameChildren < 4 then return nil end
            
            local fourthFrame = frameChildren[4]
            local cardButtons = fourthFrame:GetChildren()
            
            local cards = {}
            for i = 1, math.min(4, #cardButtons) do
                local cardButton = cardButtons[i]
                if cardButton and cardButton:IsA("TextButton") then
                    local frameChild = cardButton:FindFirstChild("Frame")
                    if frameChild then
                        local textLabel = frameChild:FindFirstChild("TextLabel")
                        if textLabel and textLabel.Text and textLabel.Text ~= "" then
                            local cardName = textLabel.Text
                            table.insert(cards, { name = cardName, button = cardButton })
                        end
                    end
                end
            end
            
            return #cards > 0 and cards or nil
        end)
        
        return ok and result or nil
    end
    
    local function findBestCard(list)
        local bestIndex, bestPriority = nil, math.huge
        
        local blacklistedCards = {
            ["Devil's Sacrifice"] = true, 
        }
        
        local isBossRush = false
        pcall(function()
            local gamemode = RS:FindFirstChild("Gamemode")
            if gamemode and gamemode.Value == "BossRush" then
                isBossRush = true
            end
        end)
        
        local priorityTable = isBossRush and getgenv().BossRushCardPriority or getgenv().CardPriority
        
        for i=1,#list do
            local nm = list[i].name
            
            if not blacklistedCards[nm] then
                local p = (priorityTable and priorityTable[nm]) or 999
                if p < bestPriority and p < 999 then
                    bestPriority = p
                    bestIndex = i
                end
            end
        end
        if bestIndex then
            return bestIndex, list[bestIndex], bestPriority
        end
        return nil, nil, nil
    end
    
    local function pressConfirm()
        local confirmButton = nil
        
        pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
            if not prompt then return end
            local frame = prompt:FindFirstChild("Frame")
            if not frame then return end
            local inner = frame:FindFirstChild("Frame")
            if not inner then return end
            local children = inner:GetChildren()
            if #children < 5 then return end
            local button = children[5]:FindFirstChild("TextButton")
            if not button then return end
            local label = button:FindFirstChild("TextLabel")
            if label and label.Text == "Confirm" then 
                confirmButton = button 
            end
        end)
        
        if not confirmButton then
            return false
        end
        
        local anySuccess = false
        
        pcall(function()
            local GuiService = game:GetService("GuiService")
            GuiService.SelectedObject = nil
            task.wait(0.05)
            
            GuiService.SelectedObject = confirmButton
            
            local lockConnection
            lockConnection = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if confirmButton and confirmButton.Parent and GuiService.SelectedObject ~= confirmButton then
                        GuiService.SelectedObject = confirmButton
                    end
                end)
            end)
            
            task.wait(0.25)
            
            if GuiService.SelectedObject == confirmButton then
                VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                anySuccess = true
            end
            
            if lockConnection then
                lockConnection:Disconnect()
            end
            
            GuiService.SelectedObject = nil
        end)
        
        task.wait(0.1)
        
        pcall(function()
            if getconnections then
                local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
                for _, ev in ipairs(events) do
                    pcall(function()
                        local connections = getconnections(confirmButton[ev])
                        if connections then
                            for _, conn in ipairs(connections) do
                                if conn and conn.Fire then
                                    conn:Fire()
                                    anySuccess = true
                                end
                            end
                        end
                    end)
                end
            end
        end)
        
        task.wait(0.1)
        
        pcall(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            local absPos = confirmButton.AbsolutePosition
            local absSize = confirmButton.AbsoluteSize
            if absPos and absSize then
                local centerX = absPos.X + (absSize.X / 2)
                local centerY = absPos.Y + (absSize.Y / 2)
                
                VirtualInputManager:SendMouseMoveEvent(centerX, centerY, game)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
                anySuccess = true
            end
        end)
        
        return anySuccess
    end
    
    local function selectCard()
        local isBossRush = false
        pcall(function()
            local gamemode = RS:FindFirstChild("Gamemode")
            if gamemode and gamemode.Value == "BossRush" then
                isBossRush = true
            end
        end)
        
        if isBossRush then
            if not getgenv().BossRushEnabled then return false end
        else
            if not getgenv().CardSelectionEnabled then return false end
        end
        
        local ok = pcall(function()
            local list = getAvailableCards()
            if not list then return false end
            
            local _, best, priority = findBestCard(list)
            if not best or not best.button or not priority then return false end
            if priority >= 999 then return false end
            
            local button = best.button
            local GuiService = game:GetService("GuiService")
            
            if not button:IsDescendantOf(LocalPlayer.PlayerGui) then
                return false
            end
            
            GuiService.SelectedObject = nil
            task.wait(0.1)
            
            GuiService.SelectedObject = button
            task.wait(0.2)
            
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            
            task.wait(0.3)
            
            pressConfirm()
            task.wait(0.2)
        end)
        
        return ok
    end
    
    local function selectCardSlower()
        if not getgenv().SlowerCardSelectionEnabled then return false end
        local ok, result = pcall(function()
            local currentSignature = getPromptSignature()
            if not currentSignature then
                return false
            end
            
            if getgenv().SlowerCardLastPromptId == currentSignature then
                return false
            end
            
            local currentWave = 0
            pcall(function()
                local wave = RS:FindFirstChild("Wave")
                if wave and wave.Value then
                    currentWave = wave.Value
                end
            end)
            
            local list = getAvailableCards()
            if not list or #list == 0 then 
                return false 
            end
            
            local bestCard = nil
            local bestValue = -999999
            
            local alreadyPicked = {}
            for _, pickedName in ipairs(getgenv().SlowerCardPicked or {}) do
                alreadyPicked[pickedName] = true
            end
            
            for i=1,#list do
                local nm = list[i].name
                
                if not alreadyPicked[nm] then
                    local value = calculateCardValue(nm, currentWave)
                    
                    if value > bestValue then
                        bestValue = value
                        bestCard = list[i]
                    end
                end
            end
            
            if not bestCard or bestValue <= 0 or not bestCard.button then
                return false
            end
            
            local GuiService = game:GetService("GuiService")
            
            GuiService.SelectedObject = nil
            task.wait(0.25)
            
            GuiService.SelectedObject = bestCard.button
            
            local lockConnection
            lockConnection = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if bestCard.button and bestCard.button.Parent and GuiService.SelectedObject ~= bestCard.button then
                        GuiService.SelectedObject = bestCard.button
                    end
                end)
            end)
            
            task.wait(0.6)
            
            local cardSelected = false
            if GuiService.SelectedObject == bestCard.button then
                VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                cardSelected = true
                
                if lockConnection then
                    lockConnection:Disconnect()
                end
                
                GuiService.SelectedObject = nil
            else
                if lockConnection then
                    lockConnection:Disconnect()
                end
                return false
            end
            
            getgenv().SlowerCardLastPromptId = currentSignature
            
            task.wait(0.6)
            
            local confirmButton = nil
            pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if prompt and prompt:FindFirstChild("Frame") and prompt.Frame:FindFirstChild("Frame") then
                    local inner = prompt.Frame.Frame
                    local children = inner:GetChildren()
                    if #children >= 5 then
                        local btn = children[5]:FindFirstChild("TextButton")
                        if btn and btn:FindFirstChild("TextLabel") and btn.TextLabel.Text == "Confirm" then
                            confirmButton = btn
                        end
                    end
                end
            end)
            
            if confirmButton then
                GuiService.SelectedObject = nil
                task.wait(0.15)
                
                GuiService.SelectedObject = confirmButton
                
                local confirmLock
                confirmLock = RunService.Heartbeat:Connect(function()
                    pcall(function()
                        if confirmButton and confirmButton.Parent and GuiService.SelectedObject ~= confirmButton then
                            GuiService.SelectedObject = confirmButton
                        end
                    end)
                end)
                
                task.wait(0.4)
                
                if GuiService.SelectedObject == confirmButton then
                    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    
                    if confirmLock then
                        confirmLock:Disconnect()
                    end
                    
                    GuiService.SelectedObject = nil
                else
                    if confirmLock then
                        confirmLock:Disconnect()
                    end
                end
            end
            
            task.wait(0.5)
            
            local waitTime = 0
            while waitTime < 3 do
                local promptStillOpen = false
                pcall(function()
                    local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                    promptStillOpen = prompt and prompt.Enabled
                end)
                
                if not promptStillOpen then
                    break
                end
                
                task.wait(0.1)
                waitTime = waitTime + 0.1
            end
            
            if not getgenv().SlowerCardPicked then
                getgenv().SlowerCardPicked = {}
            end
            table.insert(getgenv().SlowerCardPicked, bestCard.name)
            print("[Slower Card] 📝 " .. bestCard.name .. " (Total: " .. #getgenv().SlowerCardPicked .. ")")
            
            return true
        end)
        
        if not ok then
            warn("[Slower Card] ❌ Error:", result)
        end
        
        return ok and result
    end
    
    if not getgenv().SmartCardPicked then
        getgenv().SmartCardPicked = {}
    end
    
    if not getgenv().SmartCardLastPromptId then
        getgenv().SmartCardLastPromptId = nil
    end
    
    if not getgenv().SlowerCardPicked then
        getgenv().SlowerCardPicked = {}
    end
    
    if not getgenv().SlowerCardLastPromptId then
        getgenv().SlowerCardLastPromptId = nil
    end
    
    local function getPromptSignature()
        local ok, signature = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
            if not prompt or not prompt.Enabled then
                return nil
            end
            
            local list = getAvailableCards()
            if not list or #list == 0 then
                return nil
            end
            
            local cardNames = {}
            for _, card in ipairs(list) do
                table.insert(cardNames, card.name)
            end
            table.sort(cardNames)
            
            return table.concat(cardNames, "|")
        end)
        return ok and signature or nil
    end
    
    local function calculateCardValue(cardName, currentWave)
        local blacklistedCards = {
            ["Devil's Sacrifice"] = true, 
        }
        
        if blacklistedCards[cardName] then
            return -999999999 
        end
        
        local cardDefinitions = {
            ["Critical Denial"] = {type = "wave", candyPerWave = 100},
            ["Weakened Resolve III"] = {type = "wave", candyPerWave = 50},
            ["Fog of War III"] = {type = "wave", candyPerWave = 50},
            ["Weakened Resolve II"] = {type = "wave", candyPerWave = 25},
            ["Fog of War II"] = {type = "wave", candyPerWave = 25},
            ["Power Reversal II"] = {type = "wave", candyPerWave = 25},
            ["Greedy Vampire's"] = {type = "wave", candyPerWave = 25},
            ["Weakened Resolve I"] = {type = "wave", candyPerWave = 15},
            ["Fog of War I"] = {type = "wave", candyPerWave = 15},
            ["Power Reversal I"] = {type = "wave", candyPerWave = 15},
            
            ["Lingering Fear II"] = {type = "kill", bonusCandyPerKill = 2},
            ["Hellish Gravity"] = {type = "kill", bonusCandyPerKill = 2},
            ["Lingering Fear I"] = {type = "kill", bonusCandyPerKill = 1},
            ["Deadly Striker"] = {type = "kill", bonusCandyPerKill = 1},
            
            ["Trick or Treat Coin Flip"] = {type = "special", treatValue = 5000},
        }
        
        local cardData = cardDefinitions[cardName]
        if not cardData then
            local isCandyCard = getgenv().CandyCards and getgenv().CandyCards[cardName] ~= nil
            if not isCandyCard then
                return -999999
            end
            cardData = {type = "wave", candyPerWave = 20}
        end
        
        local userPriority = (getgenv().CardPriority and getgenv().CardPriority[cardName]) or 1
        if userPriority >= 999 then
            return -999999
        end
        
        local TOTAL_WAVES = 50
        local TOTAL_ENEMIES = 1350
        
        local wavesRemaining = math.max(1, TOTAL_WAVES - currentWave + 1)
        
        local currentKills = 0
        pcall(function()
            currentKills = game:GetService("Players").LocalPlayer.leaderstats.Kills.Value
        end)
        
        local enemiesRemaining = math.max(1, TOTAL_ENEMIES - currentKills)
        
        local totalCandyValue = 0
        
        if cardData.type == "wave" then
            totalCandyValue = cardData.candyPerWave * wavesRemaining
            
        elseif cardData.type == "kill" then
            totalCandyValue = cardData.bonusCandyPerKill * enemiesRemaining
            
        elseif cardData.type == "special" and cardName == "Trick or Treat Coin Flip" then
            if wavesRemaining >= 40 then
                totalCandyValue = 2500
            elseif wavesRemaining >= 30 then
                totalCandyValue = 2000
            elseif wavesRemaining >= 20 then
                totalCandyValue = 1500
            else
                totalCandyValue = 1000
            end
        end
        
        local priorityMultiplier = 1.0 / (1.0 + (userPriority - 1) * 0.05)
        totalCandyValue = totalCandyValue * priorityMultiplier
        
        return totalCandyValue
    end
    
    local function selectCardSmart()
        if not getgenv().SmartCardSelectionEnabled then 
            return false 
        end
        
        local ok, result = pcall(function()
            local currentSignature = getPromptSignature()
            if not currentSignature then
                return false
            end
            
            if getgenv().SmartCardLastPromptId == currentSignature then
                return false
            end
            
            local currentWave = 0
            pcall(function()
                local wave = RS:FindFirstChild("Wave")
                if wave and wave.Value then
                    currentWave = wave.Value
                end
            end)
            
            local list = getAvailableCards()
            if not list or #list == 0 then 
                print("[Smart Card] ❌ No cards detected in UI")
                return false 
            end
            
            local alreadyPicked = {}
            for _, pickedName in ipairs(getgenv().SmartCardPicked) do
                alreadyPicked[pickedName] = true
            end
            
            local candyCards = {}
            local nonCandyCards = {}
            
            print("[Smart Card] Wave " .. currentWave .. " - Evaluating " .. #list .. " cards:")
            
            for i = 1, #list do
                local cardName = list[i].name
                local button = list[i].button
                
                if not alreadyPicked[cardName] then
                    local value = calculateCardValue(cardName, currentWave)
                    
                    if value > -999999 then
                        table.insert(candyCards, {
                            name = cardName,
                            button = button,
                            value = value
                        })
                        print("  ✅ " .. cardName .. " = " .. math.floor(value) .. " candy")
                    else
                        table.insert(nonCandyCards, cardName)
                        print("  ❌ " .. cardName .. " = SKIPPED")
                    end
                end
            end
            
            table.sort(candyCards, function(a, b)
                return a.value > b.value
            end)
            
            if #candyCards == 0 then
                print("[Smart Card] ⚠️ WARNING: No valid candy cards found! Available cards:")
                for _, name in ipairs(nonCandyCards) do
                    print("    - " .. name)
                end
                return false
            end
            
            local bestCard = candyCards[1]
            print("[Smart Card] 🎯 SELECTING: " .. bestCard.name .. " (" .. math.floor(bestCard.value) .. " candy)")
            
            if not bestCard.button or not bestCard.button:IsDescendantOf(LocalPlayer.PlayerGui) then
                print("[Smart Card] ❌ Button not valid or not in PlayerGui")
                return false
            end
            
            pcall(function()
                local GuiService = game:GetService("GuiService")
                GuiService.SelectedObject = nil
                task.wait(0.1)
                GuiService.SelectedObject = bestCard.button
                task.wait(0.2)
                
                VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                
                print("[Smart Card] ✓ Card clicked via GuiService")
            end)
            
            task.wait(0.3)
            
            local confirmSuccess = pressConfirm()
            if confirmSuccess then
                print("[Smart Card] ✓ Confirm button pressed")
            end
            
            task.wait(0.2)
            
            getgenv().SmartCardLastPromptId = currentSignature
            
            table.insert(getgenv().SmartCardPicked, bestCard.name)
            print("[Smart Card] 📝 Picked: " .. bestCard.name .. " (Total picked: " .. #getgenv().SmartCardPicked .. "/5)")
            
            return true
        end)
        
        if not ok then
            warn("[Smart Card] ⚠️ Error:", result)
        end
        
        return ok and result
    end
    
    while true do
        task.wait(1)
        
        local promptVisible = false
        pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
            if prompt and prompt.Enabled then
                promptVisible = true
            end
        end)
        
        if not promptVisible then
            task.wait(0.3)
            continue
        end
        
        local isBossRush = false
        pcall(function()
            local gamemode = RS:FindFirstChild("Gamemode")
            if gamemode and gamemode.Value == "BossRush" then
                isBossRush = true
            end
        end)
        
        if isBossRush and getgenv().BossRushEnabled then
            selectCard()
        elseif not isBossRush then
            if getgenv().CardSelectionEnabled then
                selectCard()
            elseif getgenv().SlowerCardSelectionEnabled then
                selectCardSlower()
            elseif getgenv().SmartCardSelectionEnabled then
                selectCardSmart()
            end
        end
    end
    end)
end



if not isInLobby then
    task.spawn(function()
        local endgameCount = 0
        local maxRoundsReached = false
        local hasRun = false
        local lastEndgameTime = 0
        local DEBOUNCE_TIME = 3
        local lastEndGameUIState = false
        local newGameStartDetected = false
        
        print("[Seamless Fix] Initializing system...")
        print("[Seamless Fix] Waiting for Settings GUI...")
        local maxWait = 0
        repeat 
            task.wait(0.5) 
            maxWait = maxWait + 0.5 
        until LocalPlayer.PlayerGui:FindFirstChild("Settings") or maxWait > 30
        
        if not LocalPlayer.PlayerGui:FindFirstChild("Settings") then
            warn("[Seamless Fix] Settings GUI not found after 30s, seamless fix may not work")
            return
        end
        
        print("[Seamless Fix] Settings GUI found!")
        
        local function getSeamlessValue()
            local ok, result = pcall(function()
                local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
                if settings then
                    local seamless = settings:FindFirstChild("SeamlessRetry")
                    if seamless then 
                        return seamless.Value 
                    end
                end
                return false
            end)
            return ok and result or false
        end
        
        local function setSeamlessRetry()
            task.spawn(function()
                pcall(function()
                    local remotes = RS:FindFirstChild("Remotes")
                    local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                    if setSettings then 
                        setSettings:InvokeServer("SeamlessRetry")
                    end
                end)
            end)
        end
        
        local function enableSeamlessIfNeeded()
            if not getgenv().SeamlessFixEnabled then return end
            local maxRounds = getgenv().SeamlessRounds or 4
            
            if endgameCount < maxRounds then
                if not getSeamlessValue() then
                    setSeamlessRetry()
                    print("[Seamless Fix] ✅ Enabled Seamless Retry (" .. endgameCount .. "/" .. maxRounds .. ")")
                    task.wait(0.5)
                end
            elseif endgameCount >= maxRounds then
                if getSeamlessValue() then
                    setSeamlessRetry()
                    print("[Seamless Fix] ⏸️ Disabled Seamless Retry - Max rounds reached (" .. endgameCount .. "/" .. maxRounds .. ")")
                    task.wait(0.5)
                end
            end
        end
        
        print("[Seamless Fix] Checking initial seamless state...")
        enableSeamlessIfNeeded()
        
        local seamlessToggleConnection
        seamlessToggleConnection = task.spawn(function()
            while true do
                task.wait(1)
                if getgenv().SeamlessFixEnabled then
                    enableSeamlessIfNeeded()
                end
            end
        end)
        
        task.spawn(function()
            while true do
                task.wait(0.5) 
                
                if not getgenv().SeamlessFixEnabled then
                    task.wait(2)
                    continue
                end
                
                pcall(function()
                    local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
                    local currentEndGameUIState = endGameUI and endGameUI.Enabled or false
                    
                    if lastEndGameUIState and not currentEndGameUIState then
                        print("[Seamless Fix] 🎮 EndGameUI removed - New game started!")
                        newGameStartDetected = true
                        hasRun = false
                        
                        if getgenv().SeamlessFixEnabled and endgameCount < (getgenv().SeamlessRounds or 4) then
                            task.wait(2)
                            enableSeamlessIfNeeded()
                        end
                    end
                    
                    lastEndGameUIState = currentEndGameUIState
                end)
            end
        end)
        
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            pcall(function()
                if child.Name == "EndGameUI" then
                    local currentTime = tick()
                    if currentTime - lastEndgameTime < DEBOUNCE_TIME then
                        print("[Seamless Fix] Debounced duplicate EndGameUI trigger")
                        return
                    end
                    
                    if hasRun then
                        print("[Seamless Fix] EndGameUI detected but hasRun is true, resetting...")
                        hasRun = false
                    end
                    
                    hasRun = true
                    lastEndgameTime = currentTime
                    endgameCount = endgameCount + 1
                    local maxRounds = getgenv().SeamlessRounds or 4
                    print("[Seamless Fix] 🏁 Endgame detected. Current seamless rounds: " .. endgameCount .. "/" .. maxRounds)
                    
                    if endgameCount >= maxRounds and getgenv().SeamlessFixEnabled then
                        maxRoundsReached = true
                        print("[Seamless Fix] 🔄 Max rounds reached, disabling seamless retry to restart match...")
                        task.wait(0.5)
                        if getSeamlessValue() then
                            setSeamlessRetry()
                            print("[Seamless Fix] ⏸️ Disabled Seamless Retry")
                            task.wait(0.5)
                        else
                            print("[Seamless Fix] Seamless already disabled")
                        end
                        
                        task.spawn(function()
                            print("[Seamless Fix] Waiting for EndGameUI to close...")
                            local maxWait = 0
                            while LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") and maxWait < 30 do
                                task.wait(0.5)
                                maxWait = maxWait + 0.5
                            end
                            
                            print("[Seamless Fix] EndGameUI closed, attempting restart...")
                            task.wait(2)
                            
                            local success, err = pcall(function()
                                local remotes = RS:FindFirstChild("Remotes")
                                local restartEvent = remotes and remotes:FindFirstChild("RestartMatch")
                                if restartEvent then
                                    restartEvent:FireServer()
                                    print("[Seamless Fix] ✅ Restart signal sent")
                                    task.wait(3)
                                    endgameCount = 0
                                    maxRoundsReached = false
                                    hasRun = false
                                    enableSeamlessIfNeeded()
                                else
                                    warn("[Seamless Fix] ❌ RestartMatch remote not found")
                                end
                            end)
                            
                            if not success then
                                warn("[Seamless Fix] ❌ Restart failed:", err)
                            end
                        end)
                    else
                        task.delay(3, function()
                            hasRun = false
                        end)
                    end
                end
            end)
        end)
        
        LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child) 
            if child.Name == "EndGameUI" then 
                print("[Seamless Fix] EndGameUI removed event triggered")
                task.wait(3) 
                hasRun = false 
            end 
        end)
        
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            if child.Name == "TeleportUI" and maxRoundsReached then
                print("[Seamless Fix] 🚀 Teleport detected after max rounds, resetting counter...")
                endgameCount = 0
                maxRoundsReached = false
                task.wait(2)
                enableSeamlessIfNeeded()
            end
        end)
    end)
    
end


do
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
end

do
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
end

do
    task.spawn(function()
        while true do
            task.wait(0.25) 
            if getgenv().RemoveEnemiesEnabled then
                pcall(function()
                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, enemy in pairs(enemies:GetChildren()) do
                            pcall(function()
                                if enemy and enemy.Parent and enemy:IsA("Model") then
                                    local isBoss = enemy:FindFirstChild("Boss")
                                    if not isBoss or not isBoss.Value then
                                        for _, desc in pairs(enemy:GetDescendants()) do
                                            pcall(function()
                                                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
                                                    desc.Enabled = false
                                                    desc:Destroy()
                                                elseif desc:IsA("Sound") then
                                                    desc:Stop()
                                                    desc:Destroy()
                                                end
                                            end)
                                        end
                                        enemy:Destroy()
                                    end
                                end
                            end)
                        end
                    end
                    
                    local spawnedunits = workspace:FindFirstChild("SpawnedUnits")
                    if spawnedunits then
                        for _, su in pairs(spawnedunits:GetChildren()) do
                            pcall(function()
                                if su and su.Parent and su:IsA("Model") then
                                    for _, desc in pairs(su:GetDescendants()) do
                                        pcall(function()
                                            if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
                                                desc.Enabled = false
                                                desc:Destroy()
                                            elseif desc:IsA("Sound") then
                                                desc:Stop()
                                                desc:Destroy()
                                            end
                                        end)
                                    end
                                    su:Destroy()
                                end
                            end)
                        end
                    end
                    
                    local debris = workspace:FindFirstChild("Debris")
                    if debris then
                        for _, item in pairs(debris:GetChildren()) do
                            pcall(function() 
                                if item then
                                    item:Destroy()
                                end
                            end)
                        end
                    end
                    
                    for _, obj in pairs(workspace:GetChildren()) do
                        pcall(function()
                            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                                obj.Enabled = false
                                obj:Destroy()
                            end
                        end)
                    end
                end)
            end
        end
    end)
end

if getgenv().AutoHideUIEnabled or getgenv().Config.toggles.AutoHideUI then
    task.spawn(function()
        task.wait(3)
        
        if Window and Window.SetState then
            pcall(function()
                Window:SetState(false)
            end)
        end
    end)
end

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("ParticleEmitter") then
                            if obj.Rate > 100 then 
                                obj.Enabled = false
                                obj:Destroy()
                            end
                        elseif obj:IsA("Trail") or obj:IsA("Beam") then
                            obj.Enabled = false
                        elseif obj:IsA("Sound") then
                            if obj.Volume > 0.5 then
                                obj.Volume = 0
                            end
                        elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                            obj.Enabled = false
                            obj:Destroy()
                        end
                    end)
                end
                
                local camera = workspace.CurrentCamera
                if camera then
                    for _, effect in pairs(camera:GetChildren()) do
                        pcall(function()
                            if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                                effect.Enabled = false
                            end
                        end)
                    end
                end
            end)
        end
    end)
end

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(15)
            
            pcall(function()
                collectgarbage("collect")
                collectgarbage("collect") 
            end)
            
            if getgenv().FPSBoostEnabled then
                pcall(function()
                    local lighting = game:GetService("Lighting")
                    for _, child in ipairs(lighting:GetChildren()) do
                        pcall(function()
                            if not child:IsA("Sky") and not child:IsA("Atmosphere") then
                                child:Destroy()
                            end
                        end)
                    end
                    lighting.Ambient = Color3.new(1, 1, 1)
                    lighting.Brightness = 1
                    lighting.GlobalShadows = false
                    lighting.FogEnd = 100000
                    lighting.FogStart = 100000
                    lighting.ClockTime = 12
                    lighting.GeographicLatitude = 0
                    
                    local descendants = game.Workspace:GetDescendants()
                    local batchSize = 100
                    for i = 1, #descendants, batchSize do
                        for j = i, math.min(i + batchSize - 1, #descendants) do
                            local obj = descendants[j]
                            pcall(function()
                                if not obj or not obj.Parent then return end
                                
                                if obj:IsA("BasePart") then
                                    if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("WedgePart") or obj:IsA("CornerWedgePart") then
                                        pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
                                        pcall(function() obj.CastShadow = false end)
                                        if obj:FindFirstChildOfClass("Texture") then
                                            for _, t in ipairs(obj:GetChildren()) do
                                                if t:IsA("Texture") then
                                                    pcall(function() t:Destroy() end)
                                                end
                                            end
                                        end
                                        if obj:IsA("MeshPart") then
                                            pcall(function() obj.TextureID = "" end)
                                        end
                                    end
                                    if obj:IsA("Decal") then
                                        pcall(function() obj:Destroy() end)
                                    end
                                end
                                if obj:IsA("SurfaceAppearance") then
                                    pcall(function() obj:Destroy() end)
                                end
                                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                                    pcall(function() obj.Enabled = false end)
                                end
                                if obj:IsA("Sound") then
                                    pcall(function() 
                                        obj.Volume = 0
                                        obj:Stop()
                                    end)
                                end
                            end)
                        end
                        task.wait()
                    end
                    
                    local mapPath = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Map")
                    if mapPath then
                        for _, ch in ipairs(mapPath:GetChildren()) do
                            if not ch:IsA("Model") then
                                pcall(function() ch:Destroy() end)
                            end
                        end
                    end
                end)
            end
        end
    end)
end

if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(30) 
            pcall(function()
                collectgarbage("collect")
                print("[Memory] Garbage collection performed")
            end)
        end
    end)
    
    task.spawn(function()
        local placedTowers = {}
        local hologramParts = {}
        
        local function getClientData()
            local ok, data = pcall(function()
                return require(RS:WaitForChild("Modules"):WaitForChild("ClientData"))
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
            end)
            return ok and data or nil
        end
        
        local function isFarmUnit(unitName)
            local towerInfo = getTowerInfo(unitName)
            if not towerInfo or not towerInfo[1] then return false end
            return towerInfo[1].Attack == "Cash"
        end
        
        local function getWaypoints()
            local waypoints = {}
            local waypointsFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Waypoints")
            if not waypointsFolder then return waypoints end
            
            for _, wp in pairs(waypointsFolder:GetChildren()) do
                if wp:IsA("BasePart") then
                    local num = tonumber(wp.Name)
                    if num and num >= 1 then
                        table.insert(waypoints, {number = num, part = wp})
                    end
                end
            end
            
            table.sort(waypoints, function(a, b) return a.number < b.number end)
            return waypoints
        end
        
        local function isValidPlacement(position)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local filterList = {}
            if workspace:FindFirstChild("Towers") then table.insert(filterList, workspace.Towers) end
            if workspace:FindFirstChild("Enemies") then table.insert(filterList, workspace.Enemies) end
            rayParams.FilterDescendantsInstances = filterList
            
            local rayOrigin = position + Vector3.new(0, 10, 0)
            local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -20, 0), rayParams)
            
            if not rayResult then return false end
            
            local hitPart = rayResult.Instance
            if not hitPart then return false end
            
            local partName = hitPart.Name:lower()
            if partName:find("waypoint") or partName:find("path") or partName:find("rock") then
                return false
            end
            
            if hitPart.Parent and (hitPart.Parent.Name == "Waypoints" or hitPart.Parent.Name:lower():find("path")) then
                return false
            end
            
            return true
        end
        
        local function getPlacementPosition(slotNum, waypointIndex, distance)
            local waypoints = getWaypoints()
            if #waypoints == 0 then return nil end
            
            local baseIndex = math.floor(waypointIndex)
            local decimal = waypointIndex - baseIndex
            
            baseIndex = math.clamp(baseIndex, 1, #waypoints)
            local waypoint1 = waypoints[baseIndex].part
            
            if not waypoint1 or not waypoint1.Position then return nil end
            
            local waypointPos = waypoint1.Position
            
            if decimal > 0 and baseIndex < #waypoints then
                local waypoint2 = waypoints[baseIndex + 1].part
                if waypoint2 and waypoint2.Position then
                    waypointPos = waypoint1.Position:Lerp(waypoint2.Position, decimal)
                end
            end
            
            if distance == 0 then distance = 10 end
            
            local baseAngle = slotNum * 60
            
            for attempt = 1, 15 do
                local angleVariation = math.random(-20, 20)
                local angle = math.rad(baseAngle + angleVariation)
                
                local distVariation = distance + math.random(-3, 5)
                
                local offset = Vector3.new(
                    math.cos(angle) * distVariation,
                    0,
                    math.sin(angle) * distVariation
                )
                
                local pos = waypointPos + offset
                local cframe = CFrame.new(pos.X, waypointPos.Y, pos.Z)
                
                if isValidPlacement(cframe.Position) then
                    return cframe
                end
            end
            
            local fallbackAngle = math.rad(baseAngle)
            local fallbackOffset = Vector3.new(
                math.cos(fallbackAngle) * (distance + 5),
                0,
                math.sin(fallbackAngle) * (distance + 5)
            )
            local fallbackPos = waypointPos + fallbackOffset
            return CFrame.new(fallbackPos.X, waypointPos.Y, fallbackPos.Z)
        end
        
        local function createHologram(unitName, cframe, slotNum)
            if not getgenv().AutoPlayConfig.hologram then return end
            
            local position = cframe.Position
            
            local part = Instance.new("Part")
            part.Size = Vector3.new(0.5, 0.5, 0.5)
            part.Position = position + Vector3.new(0, 2, 0)
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 0.5
            part.Color = Color3.fromRGB(0, 255, 100)
            part.Material = Enum.Material.Neon
            part.Shape = Enum.PartType.Ball
            part.Parent = workspace
            
            local beam = Instance.new("Part")
            beam.Size = Vector3.new(0.2, 4, 0.2)
            beam.Position = position
            beam.Anchored = true
            beam.CanCollide = false
            beam.Transparency = 0.6
            beam.Color = Color3.fromRGB(0, 255, 100)
            beam.Material = Enum.Material.Neon
            beam.Parent = workspace
            
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, 120, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = part
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 0.3
            label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            label.Text = unitName .. " (Slot " .. slotNum .. ")"
            label.TextColor3 = Color3.fromRGB(0, 255, 100)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = label
            
            table.insert(hologramParts, part)
            table.insert(hologramParts, beam)
            return part
        end
        
        local function clearHolograms()
            for _, part in pairs(hologramParts) do
                pcall(function()
                    if part and part.Parent then
                        part:Destroy()
                    end
                end)
            end
            table.clear(hologramParts)
            hologramParts = {}
        end
        
        local function getPlacedTowerCount(slotNum)
            local clientData = getClientData()
            if not clientData or not clientData.Slots then return 0 end
            
            local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
            local slotData = clientData.Slots[sortedSlots[slotNum]]
            if not slotData or not slotData.Value then return 0 end
            
            local unitName = slotData.Value
            local towersFolder = workspace:FindFirstChild("Towers")
            if not towersFolder then return 0 end
            
            local count = 0
            for _, tower in pairs(towersFolder:GetChildren()) do
                if tower.Name == unitName then
                    local owner = tower:FindFirstChild("Owner")
                    if owner and owner.Value == Players.LocalPlayer then
                        count = count + 1
                    end
                end
            end
            
            return count
        end
        
        local function placeTower(unitName, cframe, slotNum)
            if not cframe then return false end
            
            local placeEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("PlaceTower")
            if not placeEvent then return false end
            
            local countBefore = getPlacedTowerCount(slotNum)
            
            local success, result = pcall(function()
                return placeEvent:FireServer(unitName, cframe)
            end)
            
            if not success then return false end
            
            task.wait(0.5)
            
            local countAfter = getPlacedTowerCount(slotNum)
            if countAfter > countBefore then return true end
            
            return false
        end
        
        local function upgradeTower(tower)
            if not tower then return false end
            
            local upgradeEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Upgrade")
            if not upgradeEvent then return false end
            
            local success, result = pcall(function()
                return upgradeEvent:InvokeServer(tower)
            end)
            
            if not success then return false end
            
            return true
        end
        
        local function getTowerLevel(tower)
            if not tower then return 0 end
            local level = 0
            pcall(function()
                local upgradeValue = tower:FindFirstChild("Upgrade")
                if upgradeValue then
                    level = upgradeValue.Value or 0
                end
            end)
            return level
        end
        
        local function hologramLoop()
            task.wait(3)
            print("[AutoPlay] Hologram loop started")
            
            while true do
                task.wait(2)  
                
                if not getgenv().AutoPlayConfig.hologram then
                    clearHolograms()
                    task.wait(1)
                    continue
                end
                
                clearHolograms()
                
                local clientData = getClientData()
                if not clientData or not clientData.Slots then continue end
                
                local pathIndex = getgenv().AutoPlayConfig.pathPercentage or 1
                local distance = math.floor(getgenv().AutoPlayConfig.distanceFromPath or 10)
                
                local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
                local totalHolograms = 0
                local maxHolograms = 30 
                
                for slotNum = 1, 6 do
                    if totalHolograms >= maxHolograms then break end
                    
                    local slotData = clientData.Slots[sortedSlots[slotNum]]
                    if slotData and slotData.Value then
                        local unitName = slotData.Value
                        local placeCap = math.floor(getgenv().AutoPlayConfig.placeCaps[slotNum] or 1)
                        local currentCount = getPlacedTowerCount(slotNum)
                        
                        if placeCap > 0 then
                            for i = currentCount + 1, math.min(placeCap, currentCount + 10) do  
                                if totalHolograms >= maxHolograms then break end
                                
                                local position = getPlacementPosition(slotNum, pathIndex, distance)
                                if position then
                                    createHologram(unitName, position, slotNum)
                                    totalHolograms = totalHolograms + 1
                                end
                            end
                        end
                    end
                end
                
                pcall(function() collectgarbage("collect") end)
            end
        end
        
        local function autoPlaceLoop()
            task.wait(3)
            
            while true do
                task.wait(3)  
                
                if not getgenv().AutoPlayConfig.autoPlace then
                    task.wait(1)
                    continue
                end
                
                local clientData = getClientData()
                if not clientData or not clientData.Slots then continue end
                
                local currentCash = tonumber(getgenv().MacroCurrentCash) or 0
                
                local pathIndex = getgenv().AutoPlayConfig.pathPercentage or 1
                local distance = math.floor(getgenv().AutoPlayConfig.distanceFromPath or 10)
                
                local unitsToPlace = {}
                local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
                
                for slotNum = 1, 6 do
                    local slotData = clientData.Slots[sortedSlots[slotNum]]
                    if slotData and slotData.Value then
                        local unitName = slotData.Value
                        local placeCap = math.floor(getgenv().AutoPlayConfig.placeCaps[slotNum] or 1)
                        local currentCount = getPlacedTowerCount(slotNum)
                        
                        if placeCap > 0 and currentCount < placeCap then
                            local cost = getgenv().GetPlaceCost and getgenv().GetPlaceCost(unitName) or 0
                            local isFarm = isFarmUnit(unitName)
                            
                            table.insert(unitsToPlace, {
                                slotNum = slotNum,
                                unitName = unitName,
                                cost = cost,
                                isFarm = isFarm
                            })
                        end
                    end
                end
                
                if getgenv().AutoPlayConfig.focusFarm then
                    table.sort(unitsToPlace, function(a, b)
                        if a.isFarm ~= b.isFarm then
                            return a.isFarm 
                        end
                        return a.slotNum < b.slotNum
                    end)
                else
                    table.sort(unitsToPlace, function(a, b)
                        return a.slotNum < b.slotNum
                    end)
                end
                
                for _, unitData in ipairs(unitsToPlace) do
                    currentCash = tonumber(getgenv().MacroCurrentCash) or 0
                    
                    if currentCash >= unitData.cost then                        
                        local position = getPlacementPosition(unitData.slotNum, pathIndex, distance)
                        if position then
                            if placeTower(unitData.unitName, position, unitData.slotNum) then
                                task.wait(1)
                                break 
                            end
                        end
                    end
                end
            end
        end
        
        local function autoUpgradeLoop()
            task.wait(2)
            
            while true do
                task.wait(1) 
                
                if not getgenv().AutoPlayConfig.autoUpgrade and not getgenv().AutoPlayConfig.autoUpgradePriority then continue end
                
                local clientData = getClientData()
                if not clientData or not clientData.Slots then continue end
                
                if getgenv().AutoPlayConfig.placeBeforeUpgrade and getgenv().AutoPlayConfig.autoPlace then
                    local allUnitsPlaced = true
                    local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
                    
                    for slotNum = 1, 6 do
                        local slotData = clientData.Slots[sortedSlots[slotNum]]
                        if slotData and slotData.Value then
                            local placeCap = math.floor(getgenv().AutoPlayConfig.placeCaps[slotNum] or 0)
                            local currentCount = getPlacedTowerCount(slotNum)
                            
                            if placeCap > 0 and currentCount < placeCap then
                                allUnitsPlaced = false
                                break
                            end
                        end
                    end
                    
                    if not allUnitsPlaced then
                        continue
                    end
                end
                
                local towersFolder = workspace:FindFirstChild("Towers")
                if not towersFolder then continue end
                
                local farmUnits = {}
                local normalUnits = {}
                
                local slotUpgradeCaps = {}
                local slotPriorities = {}
                local unitToSlot = {}
                local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
                for slotNum = 1, 6 do
                    local slotData = clientData.Slots[sortedSlots[slotNum]]
                    if slotData and slotData.Value then
                        local unitName = slotData.Value
                        local upgradeCap = math.floor(getgenv().AutoPlayConfig.upgradeCaps[slotNum] or 0)
                        slotUpgradeCaps[unitName] = upgradeCap
                        slotPriorities[unitName] = getgenv().AutoPlayConfig.upgradePriorities[slotNum] or slotNum
                        unitToSlot[unitName] = slotNum
                    end
                end
                
                for _, tower in pairs(towersFolder:GetChildren()) do
                    local owner = tower:FindFirstChild("Owner")
                    if owner and owner.Value == Players.LocalPlayer then
                        local unitName = tower.Name
                        local level = getTowerLevel(tower)
                        local maxUpgrade = tower:FindFirstChild("MaxUpgrade")
                        local actualMaxLevel = maxUpgrade and maxUpgrade.Value or 20
                        
                        local upgradeCap = slotUpgradeCaps[unitName] or 20 
                        
                        if slotUpgradeCaps[unitName] and slotUpgradeCaps[unitName] == 0 then
                            continue
                        end
                        
                        local effectiveCap = math.min(upgradeCap, actualMaxLevel)
                        
                        if level < effectiveCap then
                            local upgradeCost = getgenv().GetUpgradeCost and getgenv().GetUpgradeCost(unitName, level) or 999999999
                            local priority = slotPriorities[unitName] or 999
                            
                            if isFarmUnit(unitName) then
                                table.insert(farmUnits, {tower = tower, level = level, cap = effectiveCap, unitName = unitName, cost = upgradeCost, priority = priority})
                            else
                                table.insert(normalUnits, {tower = tower, level = level, cap = effectiveCap, unitName = unitName, cost = upgradeCost, priority = priority})
                            end
                        end
                    end
                end
                
                if getgenv().AutoPlayConfig.autoUpgradePriority then
                    table.sort(farmUnits, function(a, b)
                        if a.priority ~= b.priority then
                            return a.priority < b.priority
                        end
                        return a.cost < b.cost
                    end)
                    table.sort(normalUnits, function(a, b)
                        if a.priority ~= b.priority then
                            return a.priority < b.priority
                        end
                        return a.cost < b.cost
                    end)
                else
                    table.sort(farmUnits, function(a, b) return a.cost < b.cost end)
                    table.sort(normalUnits, function(a, b) return a.cost < b.cost end)
                end
                
                local currentCash = tonumber(getgenv().MacroCurrentCash) or 0
                
                local upgraded = false
                
                local allUnits = {}
                for _, data in ipairs(farmUnits) do
                    data.isFarm = true
                    table.insert(allUnits, data)
                end
                for _, data in ipairs(normalUnits) do
                    data.isFarm = false
                    table.insert(allUnits, data)
                end
                
                if getgenv().AutoPlayConfig.autoUpgradePriority then
                    table.sort(allUnits, function(a, b)
                        if getgenv().AutoPlayConfig.focusFarm then
                            if a.isFarm ~= b.isFarm then
                                return a.isFarm
                            end
                        end
                        
                        if a.priority ~= b.priority then
                            return a.priority < b.priority
                        end
                        
                        return a.cost < b.cost
                    end)
                else
                    table.sort(allUnits, function(a, b) return a.cost < b.cost end)
                end
                
                if getgenv().AutoPlayConfig.autoUpgradePriority then
                    for _, data in ipairs(allUnits) do
                        if upgraded then break end
                        
                        currentCash = tonumber(getgenv().MacroCurrentCash) or 0
                        
                        if data.cost > 0 and currentCash >= data.cost then
                            local prefix = data.isFarm and "[FARM] " or ""
                            print("[AutoUpgrade] " .. prefix .. "Upgrading " .. data.unitName .. " (Priority " .. data.priority .. ") from level " .. data.level .. " (Cost: $" .. data.cost .. ")")
                            if upgradeTower(data.tower) then
                                upgraded = true
                                task.wait(0.2)
                            end
                        end
                    end
                else
                    for _, data in ipairs(allUnits) do
                        if upgraded then break end
                        currentCash = tonumber(getgenv().MacroCurrentCash) or 0
                        
                        if data.cost > 0 and currentCash >= data.cost then
                            print("[AutoUpgrade] Upgrading " .. data.unitName .. " from level " .. data.level .. " (Cost: $" .. data.cost .. ")")
                            if upgradeTower(data.tower) then
                                upgraded = true
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
        
        task.spawn(hologramLoop)
        task.spawn(autoPlaceLoop)
        task.spawn(autoUpgradeLoop)
    end)
end
