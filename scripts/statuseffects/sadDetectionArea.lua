function init()
  script.setUpdateDelta(60)
  
  self.affectMonsters = config.getParameter("affectMonsters", 0) == 1
  self.affectNPCs = config.getParameter("affectNPCs", 0)  == 1
  self.affectPlayers = config.getParameter("affectPlayers", 0) == 1
  self.statusEffectName = config.getParameter("statusEffectName")
  self.statusEffectDuration = config.getParameter("statusEffectDuration", 60)
  self.detectionArea = config.getParameter("detectionArea", 50)
end

function update(dt)
  local position = mcontroller.position()
  local nearbyEntities = world.entityQuery(position, self.detectionArea, {
    includedTypes = {"monster", "npc", "player"},
    boundMode = "CollisionArea"
  })

  for _, entityId in ipairs(nearbyEntities) do
    local entityType = world.entityType(entityId)
    if (self.affectMonsters and entityType == "monster") or 
       (self.affectNPCs and entityType == "npc") or 
       (self.affectPlayers and entityType == "player") then
      world.sendEntityMessage(entityId, "applyStatusEffect", self.statusEffectName, self.statusEffectDuration, entity.id())
      sb.logInfo("-------- Applying " .. self.statusEffectName .. " to entity: " .. entityId .. " of type: " .. entityType)
    end
  end
end

function uninit()
  -- Nettoyage, si nécessaire
end
