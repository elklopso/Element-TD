-- Tidal (Light + Nature + Water)
-- Every attack (this is when it fires, not when the attack lands) decreases splash by 10/20 AoE (this AoE reduction is for both tiers). 
-- It also increases damage by 30/150. Damage increase caps out when 0 splash is reached. Resets after 1 second of not attacking.
-- By the end, it should reach a maximum of 900 / 4,500 damage.

TidalTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "TidalTower"
    },
nil)

function TidalTower:ResetDamage(keys)
    if self.resetTimer then
        Timers:RemoveTimer(self.resetTimer)
    end
    self.tidalStacks = 0
    self.tower:RemoveModifierByName("modifier_tidal_splash_decay")
end

function TidalTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = ApplyAttackDamageFromModifiers(self.tower:GetAverageTrueAttackDamage(), self.tower)

    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE - (self.tidalStacks * self.aoeDecay), self.tower, damage / 2)
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE - (self.tidalStacks * (self.aoeDecay/2)), self.tower, damage / 2)

    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_tidal_splash_decay", {})

    if self.tidalStacks < 20 then
        self.tidalStacks = self.tidalStacks + 1
        self.tower:SetModifierStackCount("modifier_tidal_splash_decay", self.ability, self.tidalStacks)
    end

    if self.resetTimer ~= nil then
        Timers:RemoveTimer(self.resetTimer)
    end
    self.resetTimer = Timers:CreateTimer(self.resetTime, function()
        self:ResetDamage({})
    end)
end

function TidalTower:OnCreated()
    self.ability = AddAbility(self.tower, "tidal_tower_splash_decay", self.tower:GetLevel())
    self.aoeDecay = GetAbilitySpecialValue("tidal_tower_splash_decay", "aoe")
    self.fullAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE = tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.douseDamage = GetAbilitySpecialValue("tidal_tower_splash_decay", "damage")
    self.resetTime = GetAbilitySpecialValue("tidal_tower_splash_decay", "reset_time")
    self.tidalStacks = 0
    self.resetTimer = nil
end

RegisterTowerClass(TidalTower, TidalTower.className)