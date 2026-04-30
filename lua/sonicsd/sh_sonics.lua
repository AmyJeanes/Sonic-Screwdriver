-- Sonics

SonicSD_OVERRIDES = SonicSD_OVERRIDES or {}

local favorites

local filename = "sonicsd_favorites.txt"
if file.Exists(filename, "DATA") then
    favorites = SonicSD.von.deserialize(file.Read(filename, "DATA"))
else
    favorites = {}
end

function SonicSD:UpdateFavoritesFile()
    file.Write(filename, SonicSD.von.serialize(favorites))
end

function SonicSD:AddFavorite(id)
    favorites[id] = true
    self:UpdateFavoritesFile()
end

function SonicSD:IsFavorite(id)
    return favorites[id]
end

function SonicSD:RemoveFavorite(id)
    favorites[id] = nil
    self:UpdateFavoritesFile()
end

function SonicSD:ToggleFavorite(id)
    if favorites[id] then
        self:RemoveFavorite(id)
    else
        self:AddFavorite(id)
    end
end


SonicSD.sonics={}
function SonicSD:AddSonic(t)
    local base = table.Copy(self.sonics[t.Base] or self.sonics.base)
    if base then
        base.IsBase = nil -- not to be inherited
        table.Merge(base,t)
        self.sonics[t.ID]=base
    else
        self.sonics[t.ID]=t
    end

    if t.IsBase then return end

    local wep = {}
    wep.Category = SonicSD_OVERRIDES.MainCategory or "Doctor Who - Sonic Tools"

    wep.PrintName = t.Name

    if CLIENT and SonicSD:IsFavorite(t.ID) then
        wep.PrintName = "  " .. wep.PrintName .. "  "-- move to the top
    end

    wep.ClassName = t.ID
    if file.Exists("materials/vgui/weapons/sonic/"..t.ID..".vtf", "GAME") then
        wep.IconOverride="vgui/weapons/sonic/"..t.ID..".vtf"
    elseif file.Exists("materials/vgui/weapons/sonic/"..t.ID..".png", "GAME") then
        wep.IconOverride="vgui/weapons/sonic/"..t.ID..".png"
    else
        wep.IconOverride="vgui/weapons/sonic/default/"..t.ID..".png"
    end
    wep.ScriptedEntityType = "sonicsd"
    wep.Spawnable = true
    list.Set("Weapon", "sonicsd-"..t.ID, wep)
end

list.Set( "ContentCategoryIcons", "Doctor Who - Sonic Tools", "vgui/sonic_icon.png" )

hook.Add("PostGamemodeLoaded", "sonicsd", function()
    if not spawnmenu then return end
    spawnmenu.AddContentType("sonicsd", function(container, obj)
        if not obj.material then return end
        if not obj.nicename then return end
        if not obj.spawnname then return end

        local icon = vgui.Create("ContentIcon", container)
        icon:SetContentType("weapon")
        icon:SetSpawnName(obj.spawnname)
        icon:SetName(obj.nicename)
        icon:SetMaterial(obj.material)
        icon:SetAdminOnly(obj.admin)
        icon:SetColor(Color(205, 92, 92, 255))
        icon.DoClick = function()
            RunConsoleCommand("sonic_model", obj.spawnname)
            RunConsoleCommand("sonicsd_give", obj.spawnname)
            surface.PlaySound("ui/buttonclickrelease.wav")
        end

        icon.OpenMenu = function(self)
            local dmenu = DermaMenu()

            local favorite = dmenu:AddOption("Add to favorites (reload required)", function(self)
                SonicSD:ToggleFavorite(obj.spawnname)
            end)
            favorite:SetIcon("icon16/heart_add.png")
            function favorite:Think()
                local fav = SonicSD:IsFavorite(obj.spawnname)
                local fav_icon = fav and "heart_delete.png" or "heart_add.png"
                local fav_text = fav and "Remove from" or "Add to"
                self:SetIcon("icon16/" .. fav_icon)
                self:SetText(fav_text .. " favorites (reload required)")
            end

            dmenu:Open()
        end

        if IsValid(container) then
            container:Add(icon)
        end

        return icon
    end)
end)

if SERVER then
    function SonicSD:GiveSonic(ply, command, args)
        local sonicID = args[1]
        if not IsValid(ply) then return end
        if sonicID == nil then return end
        if not ply:Alive() then return end

        local weaponName = "swep_sonicsd"

        local swep = list.Get("Weapon")[weaponName]
        if ( swep == nil ) then return end

        if not gamemode.Call("PlayerGiveSWEP", ply, weaponName, swep) then return end

        if not ply:HasWeapon(weaponName) then
            MsgAll("Giving " .. ply:Nick() .. " a " .. weaponName .. " (" .. sonicID .. ")\n")
            ply:Give(weaponName)
        end

        local sonic = ply:GetWeapon(weaponName)
        sonic:SetSonicID(sonicID)
        ply:SelectWeapon(weaponName)
    end
    concommand.Add("sonicsd_give", function(ply, command, args)
        SonicSD:GiveSonic(ply, command, args)
    end)

    hook.Add("PlayerLoadout", "sonicsd", function(ply)
        if tobool(ply:GetInfoNum("sonic_give_on_spawn",0)) then
            local id=ply:GetInfo("sonic_model")
            SonicSD:GiveSonic(ply, nil, {id})
        end
    end)
end

SonicSD:LoadFolder("sonics",false,true)
