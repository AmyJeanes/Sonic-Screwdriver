AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')
 
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.WaitTime = 0.5

util.AddNetworkString("SonicSD-Initialize")
util.AddNetworkString("SonicSD-Update")
util.AddNetworkString("SonicSD-ModeChanged")

function SWEP:Initialize()
    self:SetHoldType( self.HoldType )
    self.done=nil
    self.wait=nil
    self.ent=nil
    self.reloadcur=0
    self.mode=false
    self._initqueue={}
    self.disablereload=false
end

function SWEP:Go(ent, trace, keydown1, keydown2)
    if not IsValid(ent) and not ent:IsWorld() then return end
    
    local hooks={}
    local use = self:CallHook("CanUse",self.Owner,ent)
    if use~=nil then
        hooks.canuse = use
    else
        hooks.canuse=hook.Call("PlayerUse", GAMEMODE, self.Owner, ent)
    end
    local move = self:CallHook("CanMove",self.Owner,ent)
    if move~=nil then
        hooks.canmove = move
    else
        hooks.canmove=hook.Call("PhysgunPickup", GAMEMODE, self.Owner, ent)
    end
    local tool = self:CallHook("CanTool",self.Owner,ent)
    if tool~=nil then
        hooks.cantool = tool
    else
        hooks.cantool=hook.Call("CanTool", GAMEMODE, self.Owner, self.Owner:GetEyeTraceNoCursor(), "")
    end
    local class=ent:GetClass()
    self.data = {class=class,ent=ent,hooks=hooks,keydown1=keydown1,keydown2=keydown2,trace=trace}
    for k,v in ipairs(self.functions) do
        v(self,self.data)
    end
end

function SWEP:Reload()
    if self._ready and CurTime()>self.reloadcur then
        self.reloadcur=CurTime()+1
        self.reloadstart=CurTime()
    end
end

function SWEP:InitClient(ply)
    net.Start("SonicSD-Initialize")
        net.WriteEntity(self)
        net.WriteString(self:GetSonicID())
        net.WriteBool(self:GetSonicMode())
    net.Send(ply)
end

net.Receive("SonicSD-Initialize",function(len,ply)
    local sonic = net.ReadEntity()
    if IsValid(sonic) and sonic:GetClass()=="swep_sonicsd" then
        if sonic._ready then
            sonic:InitClient(ply)
        else
            table.insert(sonic._initqueue,ply)
        end
    end
end)

function SWEP:FirstThink()
    -- Owner only exists now, not in init unfortunately
    local id=self.Owner:GetInfo("sonic_model","default")
    self:SetSonicID(id)
    
    self._ready = true
    self:CallHook("Initialize")
    
    for _,ply in pairs(self._initqueue) do
        self:InitClient(ply)
    end
    self._initqueue=nil
    
    local sonic=self:GetSonic()
    self.ViewModel=sonic.ViewModel
    self.WorldModel=sonic.WorldModel
    self:SetModel(self.WorldModel)
end

function SWEP:Think()
    if not self.firstthink then
        self:FirstThink()
        self.firstthink=true
    end
    
    if self._ready then
        local keydown1=self.Owner:KeyDown(IN_ATTACK)
        local keydown2=self.Owner:KeyDown(IN_ATTACK2)
        
        if keydown1 or keydown2 then
            if (keydown1 and keydown2) and self.Owner.linked_tardis and IsValid(self.Owner.linked_tardis) then
                self.wait=CurTime()+self.WaitTime
            else
                local trace = util.QuickTrace( self.Owner:GetShootPos(), self.Owner:GetAimVector() * 1000, { self.Owner } )
                if not self.ent and not self.wait and trace.Entity then
                    self.ent=trace.Entity
                    self.wait=CurTime()+self.WaitTime
                end
                if CurTime() > self.wait and self.ent==trace.Entity and not self.done then
                    self:Go(trace.Entity, trace, keydown1, keydown2)
                    self.done=true
                end
                if (self.done and not self.ent==trace.Entity) or not (self.ent==trace.Entity) then
                    self.done=nil
                    self.wait=nil
                    self.ent=nil
                    self.data=nil
                elseif self.done and self.data then
                    self:CallHook("Hold", self.data)
                end
            end
        else
            self.done=nil
            self.wait=nil
            self.ent=nil
            self.data=nil
        end

        if self.reloadstart then
            if CurTime()>self.reloadstart+0.5 and not self.toggled then
                self.toggled=true
                self:SetSonicMode(not self:GetSonicMode())
            elseif not self.Owner:KeyDown(IN_RELOAD) then
                self.reloadstart=nil
                if not self.toggled then
                    self:CallHook("Reload")
                end
                self.toggled=nil
            end
        end
        
        self:CallHook("Think",keydown1,keydown2)
    end
end