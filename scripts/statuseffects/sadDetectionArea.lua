require "/scripts/status.lua"

function init()
  script.setUpdateDelta(90)
  
  self.affectMonstersPassive = config.getParameter("affectMonstersPassive", 0) == 1
  self.affectMonstersAgressive = config.getParameter("affectMonstersAgressive", 1) == 1
  self.affectNPCsPassive = config.getParameter("affectNPCsPassive", 0) == 1
  self.affectNPCsAgressive = config.getParameter("affectNPCsAgressive", 0) == 1
  self.affectPlayers = config.getParameter("affectPlayers", 0) == 1
  self.affectNPCsCrew = config.getParameter("affectNPCscrew", 0) == 1

  -- Gestion de plusieurs effets de statut
  self.statusEffectNames = config.getParameter("statusEffectName", {"minibossglow"})
  if type(self.statusEffectNames) ~= "table" then
    self.statusEffectNames = {self.statusEffectNames}
  end

  self.statusEffectDuration = config.getParameter("statusEffectDuration", 60)
  self.detectionRange = config.getParameter("detectionRange", 50)
  self.detectionDailyCycle = config.getParameter("detectionDailyCycle", 0)
  
  self.dpsActivation = config.getParameter("dpsActivation", 0) == 1

  -- Configure le listener de dégâts si dpsActivation est activé
  if self.dpsActivation then
    self.listener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        local targetEntityId = notification.targetEntityId

        -- Vérifier si l'entité cible est dans la bulle de détection
        if self.entitiesInRange and self.entitiesInRange[targetEntityId] then
          applyEffectToEntity(targetEntityId)
        end
      end
    end)
  end
end

function update(dt)
  detectionEntities()
  
  if self.dpsActivation and self.listener then
    self.listener:update()
  end
end

function detectionEntities()
  -- Vérifier le cycle du jour
  local cyclePhase = world.timeOfDay() < 0.5 and 1 or 2

  -- Déterminer si la détection doit se produire en fonction du cycle quotidien
  if (self.detectionDailyCycle == 1 and cyclePhase ~= 1) or 
     (self.detectionDailyCycle == 2 and cyclePhase ~= 2) then
    return
  end

  -- Détecter les entités à proximité
  local position = mcontroller.position()
  local nearbyEntities = world.entityQuery(position, self.detectionRange, {
    includedTypes = {"monster", "npc", "player"},
    boundMode = "CollisionArea"
  })

  -- Réinitialise la liste des entités
  self.entitiesInRange = {}

  -- Appliquer l'effet de statut aux entités appropriées
  for _, entityId in ipairs(nearbyEntities) do
    local entityType = world.entityType(entityId)
    local aggressive = world.entityAggressive(entityId)
    
    -- Identification des membres d'équipage
    local isCrew = false
    if entityType == "npc" then
      local npcType = world.npcType(entityId)
      if npcType and (npcType:find("crewmember") or npcType:find("crew")) then
        isCrew = true
      end
    end

    local shouldApplyEffect = ((entityType == "monster" and ((self.affectMonstersPassive and not aggressive) or (self.affectMonstersAgressive and aggressive))) or
        (entityType == "npc" and ((self.affectNPCsPassive and not aggressive and not isCrew) or (self.affectNPCsAgressive and aggressive and not isCrew) or (self.affectNPCsCrew and isCrew))) or
        (entityType == "player" and self.affectPlayers))

    if shouldApplyEffect then
      self.entitiesInRange[entityId] = true -- Ajouter l'entité à la liste pour le traitement des dégâts
      if not self.dpsActivation then
        -- Appliquer l'effet immédiatement si dpsActivation est désactivé
        applyEffectToEntity(entityId)
      end
    end
  end
end

function applyEffectToEntity(entityId)
  for _, effectName in ipairs(self.statusEffectNames) do
    world.sendEntityMessage(entityId, "applyStatusEffect", effectName, self.statusEffectDuration, entity.id())
  end
end

function uninit()
  -- Nettoyage si nécessaire
end
