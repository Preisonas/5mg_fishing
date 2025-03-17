local ESX = exports['es_extended']:getSharedObject()
local isFishing = false
local fishingRod = nil
local fishPed = nil
local fishMarketOpen = false
local fishBuyer = nil
local isPickingUp = false


function IsNearWater()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    

    return IsEntityInWater(playerPed) or Citizen.InvokeNative(0x5BA7A68A346A5A91, playerCoords.x, playerCoords.y, playerCoords.z)
end


RegisterNetEvent('fishing:useOldKey')
AddEventHandler('fishing:useOldKey', function()
    StartFishing()
end)


Citizen.CreateThread(function()
    local fishBuyerHash = GetHashKey("a_m_y_beach_01")
    RequestModel(fishBuyerHash)
    while not HasModelLoaded(fishBuyerHash) do
        Wait(1)
    end
    
    fishBuyer = CreatePed(4, fishBuyerHash, Config.FishBuyer.x, Config.FishBuyer.y, Config.FishBuyer.z, Config.FishBuyer.h, false, true)
    SetEntityHeading(fishBuyer, Config.FishBuyer.h)
    FreezeEntityPosition(fishBuyer, true)
    SetEntityInvincible(fishBuyer, true)
    SetBlockingOfNonTemporaryEvents(fishBuyer, true)
    

    exports.ox_target:addLocalEntity(fishBuyer, {
        {
            name = 'fish_market',
            icon = 'fas fa-fish',
            label = 'Open Fish Market',
            onSelect = function()
                OpenFishMarket()
            end,
            distance = 2.0
        },
    })
    
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - vector3(Config.FishBuyer.x, Config.FishBuyer.y, Config.FishBuyer.z))
        
        if distance < 10.0 then
            DrawMarker(29, Config.FishBuyer.x, Config.FishBuyer.y, Config.FishBuyer.z + 2.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, 0, 200, 150, 100, false, true, 2, false, nil, nil, false)
        end
    end
end)


function StartFishing()
 if isPickingUp then
        ESX.ShowNotification(Config.Locale.alreadyFishing)
        return
    end
    

    if not IsNearWater() then
        ESX.ShowNotification(Config.Locale.notNearWater)
        return
    end
    

    ESX.TriggerServerCallback('fishing:hasOldKey', function(hasOldKey)
        if hasOldKey then
            isFishing = true

            

            local playerPed = PlayerPedId()
            TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_STAND_FISHING', 0, true)
            

            Citizen.Wait(3000)

            SendNUIMessage({
                action = 'showMinigame',
                title = Config.Locale.fishingTitle,
                desc = Config.Locale.fishingDesc,
                duration = Config.FishingDuration,
                resourceName = GetCurrentResourceName(),
                ropeSplitChance = Config.RopeSplitChance,
                fishEscapeChance = Config.FishEscapeChance
            })
            
            SetNuiFocus(true, true)
        else
            ESX.ShowNotification(Config.Locale.noOldKey)
        end
    end)
end

-- Spawn Fishing Rod
function SpawnFishingRod()
    if fishingRod then
        DeleteObject(fishingRod)
        fishingRod = nil
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local boneIndex = GetPedBoneIndex(playerPed, 18905)
    
    fishingRod = CreateObject(GetHashKey('prop_fishing_rod_01'), coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(fishingRod, playerPed, boneIndex, 0.1, 0.05, 0, 80.0, 120.0, 160.0, true, true, false, true, 1, true)
end


RegisterNUICallback('minigameResult', function(data, cb)
    local success = data.success
    local reason = data.reason
    
    SetNuiFocus(false, false)
    

    ClearPedTasks(PlayerPedId())
    

    if fishingRod then
        DeleteObject(fishingRod)
        fishingRod = nil
    end
    
    if success then
        PlaySuccessAnimation()
        
        SpawnFishPed()
        

        TriggerServerEvent('fishing:giveReward')
        
        ESX.ShowNotification(Config.Locale.fishCaught)
        

        if fishPed then
            exports.ox_target:addLocalEntity(fishPed, {
                {
                    name = 'pickup_fish',
                    icon = 'fas fa-hand-paper',
                    label = 'Pick Up Fish',
                    onSelect = function()
                        PickUpFish()
                    end,
                    distance = 2.0
                }
            })
        end
    else
        if reason == "rope_split" then
            PlayRopeSplitAnimation()
            ESX.ShowNotification(Config.Locale.ropeSplit)
        elseif reason == "fish_escaped" then
            PlayFishEscapedAnimation()
            ESX.ShowNotification(Config.Locale.fishEscaped)
        else
            PlayFailAnimation()
            ESX.ShowNotification(Config.Locale.fishingFailed)
        end
        isFishing = false
    end
    
    cb({})
end)

RegisterNUICallback('sellItem', function(data, cb)
    local item = data.item
    local amount = data.amount
    
    TriggerServerEvent('fishing:sellItem', item, amount)
    

    Citizen.Wait(500)
    UpdateMarketInventory()
    
    cb({})
end)

RegisterNUICallback('closeMarket', function(data, cb)
    SetNuiFocus(false, false)
    fishMarketOpen = false
    cb({})
end)


function PlaySuccessAnimation()
    local playerPed = PlayerPedId()
    

    RequestAnimDict(Config.Animations.success.dict)
    while not HasAnimDictLoaded(Config.Animations.success.dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, Config.Animations.success.dict, Config.Animations.success.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(3000)
    ClearPedTasks(playerPed)
end


function PlayFailAnimation()
    local playerPed = PlayerPedId()
    

    RequestAnimDict(Config.Animations.fail.dict)
    while not HasAnimDictLoaded(Config.Animations.fail.dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, Config.Animations.fail.dict, Config.Animations.fail.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(3000)
    ClearPedTasks(playerPed)
end


function PlayRopeSplitAnimation()
    local playerPed = PlayerPedId()
    

    RequestAnimDict(Config.Animations.ropeSplit.dict)
    while not HasAnimDictLoaded(Config.Animations.ropeSplit.dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, Config.Animations.ropeSplit.dict, Config.Animations.ropeSplit.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(3000)
    ClearPedTasks(playerPed)
end


function PlayFishEscapedAnimation()
    local playerPed = PlayerPedId()
    

    RequestAnimDict(Config.Animations.fishEscaped.dict)
    while not HasAnimDictLoaded(Config.Animations.fishEscaped.dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, Config.Animations.fishEscaped.dict, Config.Animations.fishEscaped.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    Citizen.Wait(3000)
    ClearPedTasks(playerPed)
end


function SpawnFishPed()

    if fishPed then
        DeleteEntity(fishPed)
        fishPed = nil
    end
    

    local fishModel = Config.FishModels[math.random(#Config.FishModels)]
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local x, y, z = table.unpack(coords + forward * 1.0)
    

    RequestModel(GetHashKey(fishModel))
    while not HasModelLoaded(GetHashKey(fishModel)) do
        Citizen.Wait(1)
    end
    

    fishPed = CreatePed(4, GetHashKey(fishModel), x, y, z - 1.0, 0.0, false, true)
    SetEntityHealth(fishPed, 0)
    

    Citizen.SetTimeout(Config.FishDespawnTime, function()
        if fishPed then
            DeleteEntity(fishPed)
            fishPed = nil
            isFishing = false
        end
    end)
end


function PickUpFish()
    if not fishPed or isPickingUp then return end
    
    isPickingUp = true
    

    local playerPed = PlayerPedId()
    
    RequestAnimDict(Config.Animations.pickup.dict)
    while not HasAnimDictLoaded(Config.Animations.pickup.dict) do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, Config.Animations.pickup.dict, Config.Animations.pickup.anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    

    Citizen.Wait(2000)
    

    DeleteEntity(fishPed)
    fishPed = nil
    

    ESX.ShowNotification(Config.Locale.fishPickedUp)
    

    ClearPedTasks(playerPed)
    isFishing = false
    isPickingUp = false
end


function OpenFishMarket()
    if fishMarketOpen then return end
    
    fishMarketOpen = true
    

    UpdateMarketInventory()
    

    SendNUIMessage({
        action = 'openMarket',
        resourceName = GetCurrentResourceName()
    })
    
    SetNuiFocus(true, true)
end

function UpdateMarketInventory()
    ESX.TriggerServerCallback('fishing:getMarketInventory', function(items)
        SendNUIMessage({
            action = 'updateInventory',
            items = items
        })
    end)
end