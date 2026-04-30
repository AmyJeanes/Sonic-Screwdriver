-- Doctor Who

local function IsLegacy(ent)
    return not ent.TardisExterior
end

local function TARDIS_MSG(ply, tardis, msg, error)
    if IsLegacy(tardis) then
        ply:ChatPrint(msg)
    else
        if error then
            TARDIS:ErrorMessage(ply, msg)
        else
            TARDIS:Message(ply, msg)
        end
    end
end

if SERVER then
    util.AddNetworkString("Sonic-SetLinkedTARDIS")

    function SWEP:MoveTARDIS(ent, callback)
        if IsLegacy(ent) then
            callback(ent:Go(self:GetOwner().tardis_vec, self:GetOwner().tardis_ang))
        else
            ent:Demat(self:GetOwner().tardis_vec, self:GetOwner().tardis_ang, callback)
        end
        self:GetOwner().tardis_vec=nil
        self:GetOwner().tardis_ang=nil
    end

    local function LookAtPlayer(self, trace, ang)
        local hitNormal = trace.HitNormal
        if not hitNormal then return ang end
        if math.abs(hitNormal.z - 1) < 0.01 then
            local hitpos = trace.HitPos
            local plypos = self:GetOwner():GetPos()
            local x = plypos.x - hitpos.x
            local y = plypos.y - hitpos.y
            local fullAng = (90/(math.abs(x)+math.abs(y)))*x
            if y > 0 then
                fullAng = -(fullAng)-180
            end
            fullAng = fullAng-90
            snapAng = (math.SnapTo(fullAng, 15))
            ang:RotateAroundAxis( ang:Up(), snapAng )
            return ang
        else
            return ang
        end
    end

    SWEP:AddHook("Reload", "doctorwho", function(self)
        local tardis = self:GetOwner().linked_tardis
        if IsValid(tardis) then
            local moving = (tardis.moving or (tardis.GetData and tardis:GetData("teleport",false)))
            local vortex = (tardis.invortex or (tardis.GetData and tardis:GetData("vortex",false)))
            if (not moving) and (not vortex) and self:GetOwner().tardis_vec and self:GetOwner().tardis_ang then
                self:MoveTARDIS(self:GetOwner().linked_tardis, function(success)
                    if success then
                        TARDIS_MSG(self:GetOwner(), tardis, "TARDIS moving to set destination.")
                    else
                        TARDIS_MSG(self:GetOwner(), tardis, "Failed to move TARDIS.", true)
                    end
                end)
            elseif not moving and not vortex and not self:GetOwner().tardis_vec and not self:GetOwner().tardis_ang then
                local trace=util.QuickTrace( self:GetOwner():GetShootPos(), self:GetOwner():GetAimVector() * 99999, self:GetOwner() )
                local hitNormal = trace.HitNormal
                if not hitNormal then return end
                self:GetOwner().tardis_vec=trace.HitPos
                local ang=hitNormal:Angle()
                ang:RotateAroundAxis( ang:Right(), -90 )
                ang = LookAtPlayer(self, trace, ang)
                self:GetOwner().tardis_ang=ang
                self:MoveTARDIS(tardis, function(success)
                    if success then
                        TARDIS_MSG(self:GetOwner(), tardis, "TARDIS moving to AimPos.")
                    else
                        TARDIS_MSG(self:GetOwner(), tardis, "Failed to move TARDIS.", true)
                    end
                end)
            elseif ((IsLegacy(tardis) and tardis.longflight) or (not IsLegacy(tardis))) and vortex then
                if IsLegacy(tardis) then
                    self:GetOwner().linked_tardis:LongReappear()
                else
                    self:GetOwner().linked_tardis:Mat()
                end
                TARDIS_MSG(self:GetOwner(), tardis, "TARDIS materialising.")
            end
        end
    end)

    SWEP:AddFunction(function(self,data)
        if data.ent.TardisExterior and (not self:GetOwner():KeyDown(IN_WALK)) and data.keydown1 and (not data.keydown2) then
            if not data.ent:ToggleDoor() then
                if data.ent:GetData("locked") then
                    TARDIS_MSG(self:GetOwner(), data.ent, "Failed to toggle door, this TARDIS is locked.", true)
                else
                    TARDIS_MSG(self:GetOwner(), data.ent, "Failed to toggle door.", true)
                end
            end
        end
    end)

    SWEP:AddFunction(function(self,data)
        if (data.class=="gmod_time_distortion_generator" or data.class=="gmod_artron_inhibitor") and data.ent:GetEnabled() and (not self:GetOwner():KeyDown(IN_WALK)) and (data.keydown1 or data.keydown2) then
            data.ent:Break()
        end
    end)

    SWEP:AddFunction(function(self,data)
        if self:GetOwner():KeyDown(IN_WALK) and self:GetOwner().linked_tardis and IsValid(self:GetOwner().linked_tardis) and data.keydown2 and not data.keydown1 and data.hooks.cantool then
            local trackingent = data.ent
            if IsValid(trackingent) and trackingent == self:GetOwner().linked_tardis or (trackingent.TardisPart and trackingent.ExteriorPart and trackingent.exterior == self:GetOwner().linked_tardis) then
                trackingent = self:GetOwner()
            end
            if IsLegacy(self:GetOwner().linked_tardis) then
                self:GetOwner().linked_tardis:SetTrackingEnt(trackingent)
                trackingent = self:GetOwner().linked_tardis.trackingent
            else
                self:GetOwner().linked_tardis:SetTracking(trackingent, self:GetOwner())
                trackingent = self:GetOwner().linked_tardis:GetTracking()
            end
            if IsValid(trackingent) then
                self:GetOwner():ChatPrint("Tracking entity set.")
            else
                self:GetOwner():ChatPrint("Tracking disabled.")
            end
        end
    end)

    SWEP:AddFunction(function(self,data)
        if (data.class=="weepingangel" or data.class=="cube" or data.class=="cube2") and data.hooks.cantool then
            if data.ent.Victim == nil then
                local newvictim=self:GetOwner()
                if data.ent.OldVictim and IsValid(data.ent.OldVictim) and data.ent.OldVictim:IsPlayer() then
                    newvictim=data.ent.OldVictim
                end
                data.ent.Victim=newvictim
                data.ent.OldVictim=nil
                local name="Weeping Angel"
                if data.class=="cube" or data.class=="cube2" then name="Cube" end
                self:GetOwner():ChatPrint("The "..name.." has been un-frozen in time and is now chasing "..newvictim:Nick())
            else
                data.ent.OldVictim=data.ent.Victim
                data.ent.Victim=nil
                local name="Weeping Angel"
                if data.class=="cube" or data.class=="cube2" then name="Cube" end
                self:GetOwner():ChatPrint("The "..name.." has been frozen in time.")
            end
        end
    end)

    SWEP:AddFunction(function(self,data)
        if (data.class=="sent_tardis" or data.class=="sent_tardis_interior" or data.class=="gmod_tardis" or data.class=="gmod_tardis_interior") and data.hooks.cantool then
            local e
            if data.class=="sent_tardis_interior" then
                e=data.ent.tardis
            elseif data.class=="gmod_tardis_interior" then
                e=data.ent.exterior
            else
                e=data.ent
            end
            if self:GetOwner():KeyDown(IN_WALK) and data.keydown1 and (not data.keydown2) then
                if self:GetOwner().linked_tardis==e then
                    self:GetOwner().linked_tardis=NULL
                    net.Start("Sonic-SetLinkedTARDIS")
                        net.WriteEntity(NULL)
                    net.Send(self:GetOwner())
                    TARDIS_MSG(self:GetOwner(), e, "TARDIS unlinked.")
                elseif e.owner==self:GetOwner() or e:GetCreator()==self:GetOwner() or (self:GetOwner():IsAdmin() or self:GetOwner():IsSuperAdmin()) then
                    self:GetOwner().linked_tardis=e
                    net.Start("Sonic-SetLinkedTARDIS")
                        net.WriteEntity(e)
                    net.Send(self:GetOwner())
                    TARDIS_MSG(self:GetOwner(), e, "TARDIS linked.")
                else
                    TARDIS_MSG(self:GetOwner(), e, "You may only link a TARDIS you spawned.", true)
                end
            elseif IsLegacy(e) then
                if data.keydown1 and (not data.keydown2) then
                    local success=e:ToggleLocked()
                    if success then
                        if e.locked then
                            self:GetOwner():ChatPrint("TARDIS locked.")
                        else
                            self:GetOwner():ChatPrint("TARDIS unlocked.")
                        end
                    end
                elseif IsLegacy(e) and data.keydown2 and (not data.keydown1) then
                    local success=e:TogglePhase()
                    if success then
                        if e.visible then
                            self:GetOwner():ChatPrint("TARDIS now visible.")
                        else
                            self:GetOwner():ChatPrint("TARDIS no longer visible.")
                        end
                    end
                end
            elseif not IsLegacy(e) and (not data.keydown1) and (not self:GetOwner():KeyDown(IN_WALK)) and data.keydown2 then
                if self:GetOwner() ~= e:GetCreator() and e.interior:GetSecurity() then
                    TARDIS:ErrorMessage(self:GetOwner(), "This is not your TARDIS")
                    return
                end
                if e:DoorOpen() then
                    TARDIS:Message(self:GetOwner(), "Closing the doors...")
                end
                e:ToggleLocked(function(success)
                    if success then
                        if e:GetData("locked") then
                            TARDIS:Message(self:GetOwner(), "TARDIS locked.")
                        else
                            TARDIS:Message(self:GetOwner(), "TARDIS unlocked.")
                        end
                    end
                end, true)
            end
        end
    end)

    SWEP:AddFunction(function(self,data)
        if (data.ent.tardis_part or data.ent.TardisPart) and not data.ent.ExteriorPart then
            data.ent:Use(self:GetOwner(), self:GetOwner(), USE_ON, 1)
        end
    end)

    SWEP:AddFunction(function(self,data)
        if data.class=="worldspawn" and data.ent:IsWorld() and self:GetOwner().linked_tardis then
            local tardis=self:GetOwner().linked_tardis
            if self:GetOwner():KeyDown(IN_WALK) then
                self:GetOwner().tardis_vec=nil
                self:GetOwner().tardis_ang=nil
                if IsValid(tardis) and ((IsLegacy(tardis) and tardis.invortex) or ((not IsLegacy(tardis)) and tardis:GetData("vortex"))) then
                    tardis:SetDestination(tardis:GetPos(),tardis:GetAngles())
                end
                TARDIS_MSG(self:GetOwner(), tardis, "TARDIS destination unset.")
            else
                ---@type TraceResult
                local trace = data.trace
                local hitNormal = trace.HitNormal
                if not hitNormal then return end
                self:GetOwner().tardis_vec=trace.HitPos
                local ang=hitNormal:Angle()
                ang:RotateAroundAxis( ang:Right( ), -90 )
                ang = LookAtPlayer(self, trace, ang)
                self:GetOwner().tardis_ang=ang
                if IsValid(tardis) and ((IsLegacy(tardis) and tardis.invortex) or ((not IsLegacy(tardis)) and tardis:GetData("vortex"))) then
                    tardis:SetDestination(data.trace.HitPos,ang)
                end
                TARDIS_MSG(self:GetOwner(), tardis, "TARDIS destination set.")
            end
        end
    end)

    SWEP:AddHook("Hold", "doctorwho", function(self,data)
        if data.class=="gmod_time_distortion_generator" or data.class=="gmod_artron_inhibitor" then
            if (not self.repairtick) or CurTime() > self.repairtick then
                self.repairtick = CurTime() + 1
                data.ent:Repair(20)
            end 
        end
    end)
else
    function SWEP:PointingAt(ent)
        if not IsValid(ent) then return end
        
        local ViewEnt = self:GetOwner():GetViewEntity()
        local fov = 20
        local Disp = ent:GetPos() - ViewEnt:GetPos()
        local Dist = Disp:Length()
        local Width = 100
        
        local MaxCos = math.abs( math.cos( math.acos( Dist / math.sqrt( Dist * Dist + Width * Width ) ) + fov * ( math.pi / 180 ) ) )
        Disp:Normalize()
        local dot=Disp:Dot( ViewEnt:EyeAngles():Forward() )
        local tr=self:GetOwner():GetEyeTraceNoCursor()
        
        if IsValid(tr.Entity) and tr.Entity==ent then
            return 0.25
        elseif dot>MaxCos then
            return math.Clamp((1-dot)*2+0.3,0.1,1)
        else
            return 1
        end
    end
    
    SWEP:AddHook("Think", "doctorwho", function(self, keydown1, keydown2)
        if (keydown1 and keydown2) and self:GetOwner().linked_tardis and IsValid(self:GetOwner().linked_tardis) and CurTime()>self.curbeep then
            local tardis=self:GetOwner().linked_tardis
            local n=self:PointingAt(tardis)
            self.curbeep=CurTime()+n
            self:EmitSound("sonicsd/beep.wav")
        end
    end)
    
    net.Receive("Sonic-SetLinkedTARDIS", function(len)
        LocalPlayer().linked_tardis=net.ReadEntity()
    end)
end