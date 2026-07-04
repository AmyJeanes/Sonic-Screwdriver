---@diagnostic disable-next-line: undefined-global, undefined-global-assignment
SWEP.Category = DEBUG_SONICSD_SPAWNMENU_CATEGORY_OVERRIDE or "Doctor Who - Sonic Tools"

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.UseHands = true

function SWEP:GetSonicID()
    return self.sonicid
end

function SWEP:SetSonicID(id)
    self.sonicid = id
    local sonic = self:GetSonic()
    if SERVER then
        self.ViewModel=sonic.ViewModel
        self.WorldModel=sonic.WorldModel
        self:SetModel(self.WorldModel)
        if IsValid(self:GetOwner()) then
            net.Start("SonicSD-Update")
                net.WriteString(id)
            net.Send(self:GetOwner())
        end
    else
        if file.Exists("materials/vgui/weapons/sonic/"..sonic.ID.."_wepselect.png","GAME") then
            self.WepSelectIcon = Material("vgui/weapons/sonic/"..sonic.ID.."_wepselect.png")
        else
            self.WepSelectIcon = Material("vgui/weapons/sonic/default_wepselect.png")
        end
    end
    self:CallHook("SonicChanged")
end

---@api
function SWEP:GetSonicMode()
    return self.mode
end

function SWEP:SetSonicMode(mode)
    self.mode = mode
    self:CallHook("ModeChanged", mode)
    if SERVER then
        net.Start("SonicSD-ModeChanged")
            net.WriteEntity(self)
            net.WriteBool(self.mode)
        net.Broadcast()
    end
end

---@api
---@return table # always falls back to the `default` entry, never nil
function SWEP:GetSonic()
    return SonicSD.sonics[self:GetSonicID()] or SonicSD.sonics.default
end

net.Receive("SonicSD-Update",function(len,ply)
    local selected = net.ReadString()
    if CLIENT then ply = LocalPlayer() end
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    local weapon = ply:GetWeapon("swep_sonicsd")
    if IsValid(weapon) and weapon._ready then
        weapon:SetSonicID(selected)
    end
end)

net.Receive("SonicSD-ModeChanged",function(len,ply)
    local weapon = net.ReadEntity()
    local mode = net.ReadBool()
    if IsValid(weapon) then
        weapon:SetSonicMode(mode)
    end
end)

-- Weapon Details
SWEP.Primary.Clipsize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Clipsize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "pistol"

SWEP.functions={}

function SWEP:AddFunction(func)
    table.insert(self.functions,func)
end

SWEP.hooks={}

-- Hook system for modules
function SWEP:AddHook(name,id,func)
    if not (self.hooks[name]) then self.hooks[name]={} end
    self.hooks[name][id]=func
end

function SWEP:RemoveHook(name,id)
    if self.hooks[name] and self.hooks[name][id] then
        self.hooks[name][id]=nil
    end
end

function SWEP:CallHook(name,...)
    if not self.hooks[name] then return end
    local a,b,c,d,e,f
    for _,v in pairs(self.hooks[name]) do
        a,b,c,d,e,f = v(self,...)
        if ( a ~= nil ) then
            return a,b,c,d,e,f
        end
    end
end

function SWEP:LoadFolder(folder,addonly,noprefix)
    folder="weapons/swep_sonicsd/"..folder.."/"
    local modules = file.Find(folder.."*.lua","LUA")
    for _, plugin in ipairs(modules) do
        if noprefix then
            if SERVER then
                AddCSLuaFile(folder..plugin)
            end
            if not addonly then
                include(folder..plugin)
            end
        else
            local prefix = string.Left( plugin, string.find( plugin, "_" ) - 1 )
            if (CLIENT and (prefix=="sh" or prefix=="cl")) then
                if not addonly then
                    include(folder..plugin)
                end
            elseif (SERVER) then
                if (prefix=="sv" or prefix=="sh") and (not addonly) then
                    include(folder..plugin)
                end
                if (prefix=="sh" or prefix=="cl") then
                    AddCSLuaFile(folder..plugin)
                end
            end
        end
    end
end
SWEP:LoadFolder("modules")

function SWEP:OnRestore()
    self:Initialize()
end 
 
----------------------------------------------
-- Called when the player Shoots
----------------------------------------------
function SWEP:PrimaryAttack()
end
 
----------------------------------------------
-- Called when the player Uses secondary attack
----------------------------------------------
function SWEP:SecondaryAttack() 
end