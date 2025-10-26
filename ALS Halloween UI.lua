local SUPPORTED_PLACE_IDS = {
    12886143095,
    12900046592,
    12920470286,
    12982304554,
    14368918515,
    16270257509,
    16552796883,
    18583778121
}

local currentPlaceId = game.PlaceId

for _, placeId in ipairs(SUPPORTED_PLACE_IDS) do
    if currentPlaceId == placeId then
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        local characterLoadTimeout = 30
        local startTime = tick()
        
        while not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") do
            if tick() - startTime > characterLoadTimeout then
                warn("[ALS Loader] Character failed to load within timeout")
                return
            end
            task.wait(0.5)
        end
        
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Byorl/ALS-Scripts/refs/heads/main/ALS%20Script"))()
        
        local maxRetries = 6
        local retryDelay = 10
        local success = false
        
        for attempt = 1, maxRetries do
            local exists = pcall(function()
                return game:GetService("CoreGui").RaGCZy.ScreenGui.Base.Sidebar.Information.InformationHolder.TitleFrame.Title
            end)
            
            if exists then
                success = true
                break
            end
            
            if attempt < maxRetries then
                warn(string.format("[ALS Loader] UI not found, retrying in %d seconds... (Attempt %d/%d)", retryDelay, attempt, maxRetries))
                task.wait(retryDelay)
            end
        end
        
        if not success then
            warn("[ALS Loader] Failed to load UI after " .. maxRetries .. " attempts")
        end
        
        return
    end
end
