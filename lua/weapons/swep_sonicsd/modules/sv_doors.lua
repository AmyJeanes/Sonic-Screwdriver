-- Doors

---@param class string
local function isdoor(class)
    local t={"func_door", "func_door_rotating", "prop_door_rotating"}
    for _,v in pairs(t) do
        if class==v then
            return true
        end
    end
    return false
end

SWEP:AddFunction(function(self,data)
    if isdoor(data.class) then
        local savetable = data.ent:GetSaveTable()
        local locked=tobool(savetable.m_bLocked)
        if locked and data.keydown2 and data.hooks.cantool then
            data.ent:Fire("Unlock", 0)
            data.ent:EmitSound("doors/door_latch3.wav")
            self:GetOwner():ChatPrint("Door unlocked.")
        elseif not locked and data.keydown2 and data.hooks.cantool then
            data.ent:Fire("Lock", 0)
            data.ent:EmitSound("doors/door_latch3.wav")
            self:GetOwner():ChatPrint("Door locked.")
        end
        if data.keydown1 and not data.keydown2 and data.hooks.canuse then
            if locked then
                self:GetOwner():ChatPrint("Door locked, right click to open")
            else
                data.ent:Fire("Toggle", 0)
            end
        end
        return true,data.msg
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="prop_dynamic" and data.hooks.cantool then
        if data.keydown1 and not data.keydown2 then
            data.ent:Fire("setanimation", "open", 0)
        elseif data.keydown2 and not data.keydown1 then
            data.ent:Fire("setanimation", "close", 0)
        end
    end
end)