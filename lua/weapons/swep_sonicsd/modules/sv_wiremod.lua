-- Wiremod

SWEP:AddFunction(function(self,data)
    if data.class=="gmod_wire_keypad" and WireLib and data.hooks.cantool then
        -- bit hacky but the keypad hates everyone
        if data.keydown1 and not data.keydown2 then
            data.ent:SetDisplayText("y")
            Wire_TriggerOutput(data.ent, "Valid", 1)
            data.ent:EmitSound("buttons/button9.wav")
        elseif data.keydown2 and not data.keydown1 then
            data.ent:SetDisplayText("n")
            Wire_TriggerOutput(data.ent, "Invalid", 1)
            data.ent:EmitSound("buttons/button8.wav")
        end
        local access = data.keydown1 and not data.keydown2
        if access or (data.keydown2 and not data.keydown1) then
            data.ent.CurrentNum = -1
            timer.Create("wire_keypad_"..data.ent:EntIndex().."_"..tostring(access), 2, 1, function()
                if IsValid(data.ent) then
                    data.ent:SetDisplayText("")
                    data.ent.CurrentNum = 0
                    if access then
                        Wire_TriggerOutput(data.ent, "Valid", 0)
                    else
                        Wire_TriggerOutput(data.ent, "Invalid", 0)
                    end
                end
            end)
        end
    end
end)

SWEP:AddFunction(function(self,data)
    if data.class=="wired_door" and WireLib and data.hooks.cantool then
        if data.keydown1 and not data.keydown2 then
            data.ent:openself()
        elseif data.keydown2 and not data.keydown1 then
            data.ent:closeself()
        end
    end
end)