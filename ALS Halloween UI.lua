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
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Byorl/ALS-Scripts/refs/heads/main/ALS%20Script"))()
        return
    end
end

