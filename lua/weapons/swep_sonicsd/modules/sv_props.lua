-- Props

SWEP:AddFunction(function(self,data)
    if data.class=="gmod_balloon" and data.hooks.cantool then
        data.ent:TakeDamage(100)
    end
end)

SWEP:AddFunction(function(self,data)
    if (data.class=="func_breakable" or data.class=="func_breakable_surf" or data.class=="func_physbox") and data.hooks.cantool then
        data.ent:Fire("Break", 0)
    end
end)

SWEP:AddFunction(function(self,data)
    if (data.class=="prop_physics" or data.class=="prop_physics_multiplayer") and data.hooks.canmove then
        local phys=data.ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:AddVelocity(self:GetOwner():GetAimVector()*200)
        end
        if (data.ent:GetSaveTable().max_health > 1) and data.hooks.cantool then
            data.ent:Fire("Break", 0)
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="item_item_crate" and data.hooks.cantool then
        data.ent:TakeDamage(100, self:GetOwner(), self) --data.ent:Fire("Break", 0) crashed the game
    end
end)