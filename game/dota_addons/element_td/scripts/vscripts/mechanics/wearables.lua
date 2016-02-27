function AdjustCosmetics( event )
    local unit = event.caster
    local ability = event.ability
    local unitName = unit:GetUnitName()

    Timers:CreateTimer(1, function()
        if unitName == "A_Dizzle" then
            Attachments:AttachProp(unit, "attach_attack1", "models/timebreaker.vmdl")
        elseif unitName == "Noya" then
            AddAnimationTranslate(unit, "abysm")
            unit:StartGesture(ACT_DOTA_IDLE)
        elseif unitName == "Quintinity" then
            AddAnimationTranslate(unit, "dualwield")
        elseif unitName == "villain" then         
            unit:AddNewModifier(unit, nil, "modifier_transparency", {})
        end
    end)
end


-- Creates full AttachWearables entries by set names
function MakeSets()
    if not GameRules.modelmap then MapWearables() end

    -- Generate all sets for each hero
    local heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
    local filePath = "../../dota_addons/element_td/scripts/AttachWearables.txt"
    local file = io.open(filePath, 'w')

    for k,v in pairs(heroes) do
        GenerateAllSetsForHero(file, k)
    end

    file:close()
end

function GenerateAllSetsForHero( file, heroName )
    local indent = "    "
    file:write(indent..string.rep("/", 60).."\n")
    file:write(indent.."// Cosmetic Sets for "..heroName.."\n")
    file:write(indent..string.rep("/", 60).."\n")
    GenerateDefaultBlock(file, heroName)

    -- Find sets that match this hero
    for key,values in pairs(GameRules.items) do
        if values.name and values.used_by_heroes and values.prefab and values.prefab == "bundle" then
            if type(values.used_by_heroes) == "table" then
                for k,v in pairs(values.used_by_heroes) do
                    if k == heroName then
                        GenerateBundleBlock(file, values.name)
                    end
                end
            end
        end
    end
    file:write("\n")
end

function MapWearables()
    GameRules.items = LoadKeyValues("scripts/items/items_game.txt")['items']
    GameRules.modelmap = {}
    for k,v in pairs(GameRules.items) do
        if v.name and v.prefab ~= "loading_screen" then
            GameRules.modelmap[v.name] = k
        end
    end
end

function GenerateDefaultBlock( file, heroName )
    file:write("    \"Creature\"\n")
    file:write("    {\n")
    file:write("        \"AttachWearables\" ".."// Default "..heroName.."\n")
    file:write("        {\n")
    local defCount = 1
    for code,values in pairs(GameRules.items) do
        if values.name and values.prefab == "default_item" and values.used_by_heroes then
            for k,v in pairs(values.used_by_heroes) do
                if k == heroName then
                    local itemID = GameRules.modelmap[values.name]
                    GenerateItemDefLine( file, defCount, itemID, values.name )
                    defCount = defCount + 1
                end
            end
        end
    end
    file:write("        }\n")
    file:write("    }\n")
end
 
function GenerateBundleBlock( file, setname )
    local bundle = {}
    for code,values in pairs(GameRules.items) do
        if values.name and values.name == setname and values.prefab and values.prefab == "bundle" then
            bundle = values.bundle
        end
    end

    file:write("    \"Creature\"\n")
    file:write("    {\n")
    file:write("        \"AttachWearables\" ".."// "..setname.."\n")
    file:write("        {\n")
    local wearableCount = 1
    for k,v in pairs(bundle) do
        local itemID = GameRules.modelmap[k]
        if itemID then
            GenerateItemDefLine(file, wearableCount, itemID, k)
            wearableCount = wearableCount+1
        end
    end
    file:write("        }\n")
    file:write("    }\n")
end
 
function GenerateItemDefLine( file, i, itemID, comment )
    file:write("            \""..tostring(i).."\" { ".."\"ItemDef\" \""..itemID.."\" } // "..comment.."\n")
end