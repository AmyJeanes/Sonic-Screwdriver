-- Vehicles

SWEP:AddFunction(function(self,data)
    if data.ent.isWacAircraft and data.hooks.cantool then -- new base
        data.ent:setEngine(not data.ent.active)
    elseif (string.find(data.class, "wac_hc_") or string.find(data.class, "wac_pl_")) and not data.ent.isWacAircraft and data.hooks.cantool then -- old base
        data.ent:SwitchState()
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="func_tracktrain" and data.hooks.canuse then
        if data.keydown1 and not data.keydown2 then
            data.ent:Fire("Toggle", 0)
        elseif data.keydown2 and not data.keydown1 then
            data.ent:Fire("Reverse", 0)
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="func_movelinear" and data.hooks.canuse then
        if data.keydown1 and not data.keydown2 then
            data.ent:Fire("Open", 0)
        elseif data.keydown2 and not data.keydown1 then
            data.ent:Fire("Close", 0)
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if string.find( data.class, "sent_sakarias_car" ) and not (string.find( data.class, "sent_sakarias_carwheel" ) or string.find( data.class, "sent_sakarias_carwheel_punked" ) or data.ent.IsDestroyed == 1) then
        if data.ent:PlayerCanUseLock( self:GetOwner() ) then
            if data.ent:IsLocked() then
                data.ent:UnLock( true )
                self:GetOwner():ChatPrint("SCar unlocked.")
            else
                data.ent:Lock( true )
                self:GetOwner():ChatPrint("SCar locked.")
            end
        end
    end
end)