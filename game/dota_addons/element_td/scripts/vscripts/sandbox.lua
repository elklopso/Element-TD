if not Sandbox then
    Sandbox = class({})
end

function Sandbox:Init()
    DEVELOPERS = {[66998815]="A_Dizzle",[86718505]="Noya",[8035838]="Karawasa",[34961594]="WindStrike",[84998953]="Quintinity",[59573794]="Azarak"}
    
    -- Enable Sandbox mode, single player or dev only, after a confirmation message
    CustomGameEventManager:RegisterListener("sandbox_enable", Dynamic_Wrap(Sandbox, "Enable"))

    -- Resources section
    CustomGameEventManager:RegisterListener("sandbox_toggle_free_towers", Dynamic_Wrap(Sandbox, "FreeTowers"))
    CustomGameEventManager:RegisterListener("sandbox_toggle_god_mode", Dynamic_Wrap(Sandbox, "GodMode"))
    CustomGameEventManager:RegisterListener("sandbox_max_elements", Dynamic_Wrap(Sandbox, "MaxElements"))
    CustomGameEventManager:RegisterListener("sandbox_full_life", Dynamic_Wrap(Sandbox, "FullLife"))
    CustomGameEventManager:RegisterListener("sandbox_set_resources", Dynamic_Wrap(Sandbox, "SetResources")) -- Gold/Lumber/Essence
    CustomGameEventManager:RegisterListener("sandbox_set_element", Dynamic_Wrap(Sandbox, "SetElement")) -- 6 elements

    -- Spawn section
    CustomGameEventManager:RegisterListener("sandbox_set_wave", Dynamic_Wrap(Sandbox, "SetWave"))
    CustomGameEventManager:RegisterListener("sandbox_spawn_wave", Dynamic_Wrap(Sandbox, "SpawnWave"))
    CustomGameEventManager:RegisterListener("sandbox_spawn_boss_wave", Dynamic_Wrap(Sandbox, "SpawnBossWave"))
    CustomGameEventManager:RegisterListener("sandbox_clear_wave", Dynamic_Wrap(Sandbox, "ClearWave"))
    CustomGameEventManager:RegisterListener("sandbox_stop_wave", Dynamic_Wrap(Sandbox, "StopWave"))

    -- Game
    CustomGameEventManager:RegisterListener("sandbox_speed_up", Dynamic_Wrap(Sandbox, "SpeedUp"))
    CustomGameEventManager:RegisterListener("sandbox_pause", Dynamic_Wrap(Sandbox, "Pause"))
    CustomGameEventManager:RegisterListener("sandbox_end", Dynamic_Wrap(Sandbox, "End"))
end

-- The sandbox enable button will only be visible in the test version, or on single player/developer presence.
function Sandbox:CheckPlayer(playerID)
    if Convars:GetBool("developer") or PlayerResource:GetPlayerCount() == 1 then
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "sandbox_mode_visible", {})
    end
end

function Sandbox:Enable(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)

    if not playerData.sandBoxEnabled then
        playerData.sandBoxEnabled = true
        ElementTD:CheatsEnabled()
    else
        return
    end

    ElementTD:PrecacheAll()
    Notifications:ClearTop(playerID)
    Notifications:Top(playerID, {
        text = {text = "#sandbox_enable"}, 
        class = "SandboxEnable", 
        duration = 10
    })

    Notifications:Top(playerID, {
        text = {text = "#sandbox_wait"}, 
        class = "SandboxEnableWait", 
        duration = 10
    })
end

function Sandbox:IsDeveloper(playerID)
    return DEVELOPERS[PlayerResource:GetSteamAccountID(playerID)] ~= nil
end

function Sandbox:FreeTowers(event)
    local playerID = event.PlayerID
    local state = event.state == 1
    local playerData = GetPlayerData(playerID)
    playerData.cheated = true

    ShowSandboxToggleCommand(playerID, "#sandbox_free_towers", state)

    -- Set to 10k gold
    if state == true then
        SetCustomGold(playerID, math.max(11000, PlayerResource:GetGold(playerID)))
    end

    playerData.freeTowers = state
    UpdatePlayerSpells(playerID)
end

function Sandbox:GodMode(event)
    local playerID = event.PlayerID
    local state = event.state == 1
    local playerData = GetPlayerData(playerID)
    playerData.cheated = true

    ShowSandboxToggleCommand(playerID, "#sandbox_god_mode", state)

    GetPlayerData(playerID).godMode = state
end

function Sandbox:MaxElements(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)
    playerData.cheated = true
    
    for k,v in pairs (playerData.elements) do
        playerData.elements[k] = 3
    end

    UpdatePlayerSpells(playerID)
    UpdateElementsHUD(playerID)
    UpdateSummonerSpells(playerID)
    for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
    end
    UpdateScoreboard(playerID)

    ShowSandboxCommand(playerID, "Max Elements")
end

function Sandbox:FullLife(event)
    local playerID = event.PlayerID
    local value = 50
    local playerData = GetPlayerData(playerID)
    playerData.health = value
    playerData.cheated = true

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero:HasModifier("modifier_bonus_life") then
        hero:AddNewModifier(hero, nil, "modifier_bonus_life", {})
    end

    hero:CalculateStatBonus()
    hero:SetHealth(value)
   
    CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )

    ShowSandboxCommand(playerID, "Full Life")
end

function Sandbox:SetResources(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)
    local gold = tonumber(event.gold) or playerData.gold
    local lumber = tonumber(event.lumber) or playerData.lumber
    local essence = tonumber(event.essence) or playerData.pureEssence
    playerData.cheated = true

    SetCustomGold(playerID, gold)
    SetCustomLumber(playerID, lumber)
    SetCustomEssence(playerID, essence)
end

function Sandbox:SetElement(event)
    local playerID = event.PlayerID
    local element = event.element
    local level = tonumber(event.level)
    local playerData = GetPlayerData(playerID)
    playerData.cheated = true

    playerData.elements[element] = level

    UpdatePlayerSpells(playerID)
    UpdateElementsHUD(playerID)
    UpdateSummonerSpells(playerID)
    for towerID,_ in pairs(playerData.towers) do
        UpdateUpgrades(EntIndexToHScript(towerID))
    end
    UpdateScoreboard(playerID)

    ShowElementLevel(playerID, element, level)
end

function Sandbox:SetWave(event)
    local playerID = event.PlayerID
    local waveNumber = event.wave
    local playerData = GetPlayerData(playerID)
    playerData.cheated = true

    if not waveNumber or waveNumber == "" then
        waveNumber = playerData.nextWave or 1
    end
    waveNumber = tonumber(waveNumber)

    if waveNumber > WAVE_COUNT then
        waveNumber = WAVE_COUNT
    end

    Sandbox:StopWave({PlayerID=playerID})

    CURRENT_WAVE = waveNumber
    playerData.nextWave = waveNumber
    playerData.completedWaves = waveNumber - 1

    StartBreakTime(playerID, GetPlayerDifficulty(playerID):GetWaveBreakTime(playerData.nextWave))

    UpdateWaveInfo(playerID, playerData.nextWave-1)
end

function Sandbox:SpawnWave(event)
    local playerID = event.PlayerID
    local waveNumber = event.wave
    local playerData = GetPlayerData(playerID)
    playerData.cheated = true

    if not waveNumber or waveNumber == "" then
        waveNumber = playerData.nextWave or 1
    end
    waveNumber = tonumber(waveNumber)

    if waveNumber > WAVE_COUNT then
        waveNumber = WAVE_COUNT
    end

    CURRENT_WAVE = waveNumber
    Sandbox:StopWave({PlayerID=playerID})

    playerData.nextWave = waveNumber
    playerData.completedWaves = waveNumber - 1

    if waveNumber == WAVE_COUNT and not EXPRESS_MODE then
        CURRENT_BOSS_WAVE = 1
        ShowBossWaveMessage(playerID, CURRENT_BOSS_WAVE)
    else
        ShowWaveSpawnMessage(playerID, waveNumber)
    end

    SpawnWaveForPlayer(playerID, waveNumber)
    ShowPortalForSector(playerData.sector+1, waveNumber, playerID)

    UpdateWaveInfo(playerID, playerData.nextWave-1)
    UpdateWaveInfo(playerID, playerData.nextWave)
end

function Sandbox:StopWave(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject
    playerData.cheated = true

    ClosePortalForSector(playerID, playerData.sector+1, true)

    if wave and wave.spawnTimer then
        Timers:RemoveTimer(wave.spawnTimer)
        wave:SetOnCompletedCallback(function() end)
    end
end

function Sandbox:ClearWave(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerData = GetPlayerData(playerID)
    local wave = playerData.waveObject
    local creeps = wave.creeps
    wave.endTime = GameRules:GetGameTime()
    wave.endSpawnTime = wave.endSpawnTime or GameRules:GetGameTime()
    playerData.cheated = true

    if creeps then
        for k,v in pairs(creeps) do
            local unit = EntIndexToHScript(v)
            if IsValidEntity(unit) then
                unit:Kill(nil, hero)
            end
        end
    end

    for _,object in pairs(playerData.waveObjects) do
        object.endTime = GameRules:GetGameTime()
        object.endSpawnTime = object.endSpawnTime or GameRules:GetGameTime()
        for index,_ in pairs(object.creeps) do
            local creep = EntIndexToHScript(index)
            if IsValidEntity(creep) then
                creep:Kill(nil, hero)
            end
        end
    end

    local elemental = playerData.elementalUnit
    if elemental then elemental:Kill(nil, hero) end

    Sandbox:StopWave({PlayerID=playerID})

    -- Complete the wave
    wave.endSpawnTime = GameRules:GetGameTime()
    wave:callback()
end

function Sandbox:SpeedUp(event)
    local fast = event.state == 1
    if fast then
        SendToServerConsole("host_timescale 3")
    else
        SendToServerConsole("host_timescale 1")
    end
end

function Sandbox:Pause(event)
    local pause = event.state == 1
    PauseGame(pause)
end

function Sandbox:End(event)
    local playerID = event.PlayerID
    local playerData = GetPlayerData(playerID)

    playerData.completedWaves = WAVE_COUNT
    ElementTD:EndGameForPlayer( playerID )
    GameRules:SetGameWinner(PlayerResource:GetTeam(playerID))
end

-- Forces a fast precache of everything to be able to build anything ASAP
function ElementTD:PrecacheAll()
    if EXPRESS_MODE then
        ElementTD:ExpressPrecache(5)
        ElementTD:PrecacheWave(2)
        ElementTD:PrecacheWave(5)
        ElementTD:PrecacheWave(11)
    else
        ElementTD:PrecacheWave(4)
        ElementTD:PrecacheWave(9)
        ElementTD:PrecacheWave(14)
        ElementTD:PrecacheWave(24)
    end
end

--------------------------------------------------------------------------

function ElementTD:ToggleDebugDamage()
    GameRules.DebugDamage = not GameRules.DebugDamage
    if GameRules.DebugDamage then
        Say(nil,"Debug Damage <font color='#ff0000'>ON</font>", false)
    else
        Say(nil,"Debug Damage <font color='#ff0000'>OFF</font>", false)
    end
end

function ElementTD:WhereIsTheWave(playerID)
    local playerData = GetPlayerData(playerID)
    local waveObject = playerData.waveObject

    if waveObject and waveObject.waveNumber and waveObject.waveNumber > 0 then
        print("=====================================")
        print("PlayerID: "..playerID.." - Wave: "..waveObject.waveNumber)
        print("Wave Started At: "..waveObject.startTime.." EndTime: "..waveObject.endTime) -- endTime should be 0
        print("-------------------------------------")
        print("Remaining: "..waveObject.creepsRemaining,"Leaks: "..waveObject.leaks,"Kills: "..waveObject.kills)
        for k,v in pairs(waveObject.creeps) do
            local creep = EntIndexToHScript(v)
            if IsValidEntity(creep) then
                print("["..k.."]","Alive:"..tostring(creep:IsAlive()))
                DebugDrawCircle(creep:GetAbsOrigin(), Vector(255,0,0), 1, 16, true, 5)
            else
                print("["..k.."]","Entity Not Valid!")
            end
        end
    end
end

if not DEVELOPERS then Sandbox:Init() end