function init()
  script.setUpdateDelta(90)
  
  self.affectMonstersPassive = config.getParameter("affectMonstersPassive", 0) == 1
  self.affectMonstersAgressive = config.getParameter("affectMonstersAgressive", 1) == 1
  self.affectNPCsPassive = config.getParameter("affectNPCsPassive", 0) == 1
  self.affectNPCsAgressive = config.getParameter("affectNPCsAgressive", 0) == 1
  self.affectPlayers = config.getParameter("affectPlayers", 0) == 1
  self.affectNPCsCrew = config.getParameter("affectNPCscrew", 0) == 1  -- Utilisation de la clé correcte

  self.statusEffectName = config.getParameter("statusEffectName", "minibossglow")
  self.statusEffectDuration = config.getParameter("statusEffectDuration", 60)
  self.detectionRange = config.getParameter("detectionRange", 50)
  self.detectionDailyCycle = config.getParameter("detectionDailyCycle", 0)
end

function update(dt)
  detectionEntities()
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
      sb.logInfo("Applying %s to entity: %s of type: %s", self.statusEffectName, entityId, entityType)
      world.sendEntityMessage(entityId, "applyStatusEffect", self.statusEffectName, self.statusEffectDuration, entity.id())
    else
      sb.logInfo("Skipping entity: %s of type: %s, shouldApplyEffect: %s, isCrew: %s, affectNPCsCrew: %s", entityId, entityType, shouldApplyEffect, isCrew, self.affectNPCsCrew)
    end
  end
end

function uninit()
  -- Nettoyage si nécessaire
end
