-- NPCs

SWEP:AddFunction(function(self,data)
    if data.class=="npc_combine_camera" and data.hooks.cantool then
        data.ent:Fire("Toggle", 0)
    end
end)

SWEP:AddFunction(function(self,data)
    if (data.class=="npc_turret_floor" or data.class=="npc_rollermine") and data.hooks.cantool then
        local hacked=tobool(data.ent:GetSaveTable().m_bHackedByAlyx)
        data.ent:SetSaveValue("m_bHackedByAlyx", (not hacked))
        if not hacked then -- this is because the variable is reversed after 'hacked' is set.
            self:GetOwner():ChatPrint("NPC now friendly.")
        else
            self:GetOwner():ChatPrint("NPC no longer friendly.")
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="npc_turret_ceiling" and data.hooks.cantool then
        data.ent:Fire("Toggle",0)
    end
end)

SWEP:AddFunction(function(self,data)
    if (data.class=="npc_cscanner" or data.class=="npc_clawscanner") and data.hooks.cantool then
        data.ent:Fire("Break", 0)
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="npc_manhack" and data.hooks.cantool then
        data.ent:Fire("InteractivePowerDown", 0)
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="npc_helicopter" and data.hooks.cantool then
        if data.keydown1 and not data.keydown2 then
            data.ent:Fire("MissileOff", 0)
            data.ent:Fire("GunOff", 0)
            self:GetOwner():ChatPrint("Helicopter weaponry disabled.")
        elseif data.keydown2 and not data.keydown1 then
            data.ent:Fire("GunOn", 0)
            data.ent:Fire("MissileOn", 0)
            self:GetOwner():ChatPrint("Helicopter weaponry enabled.")
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="npc_barnacle" and data.hooks.canuse then
        data.ent:Fire("LetGo", 0)
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="combine_mine" and data.hooks.cantool then
        local hacked=tobool(data.ent:GetSaveTable().m_bPlacedByPlayer)
        data.ent:SetSaveValue("m_bPlacedByPlayer", (not hacked))
        if not hacked then -- this is because the variable is reversed after 'hacked' is set.
            self:GetOwner():ChatPrint("Hopper Mine now friendly.")
        else
            self:GetOwner():ChatPrint("Hopper Mine no longer friendly.")
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="npc_turret_ground" and data.hooks.cantool then
        data.ent:SetSaveValue("m_IdealNPCState",7)
    end
end)

SWEP:AddFunction(function(self,data)
    if data.ent:IsNPC() and data.hooks.cantool then
        if data.keydown1 and not data.keydown2 then
            data.ent:AddEntityRelationship(self:GetOwner(), D_LI, 999)
            self:GetOwner():ChatPrint("NPC now friendly towards you.")
        elseif data.keydown2 and not data.keydown1 then
            data.ent:AddEntityRelationship(self:GetOwner(), D_HT, 999)
            self:GetOwner():ChatPrint("NPC no longer friendly towards you.")
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="prop_thumper" and data.hooks.cantool then
        local enabled=tobool(data.ent:GetSaveTable().m_bEnabled)
        if enabled then
            data.ent:Fire("Disable", 0)
        else
            data.ent:Fire("Enable", 0)
        end
    end
end)