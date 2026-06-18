-- Wiremod

SWEP:AddFunction(function(self,data)
    if data.class=="gmod_wire_keypad" and WireLib and data.hooks.cantool then
        local keypad = data.ent --[[@as gmod_wire_keypad]]
        -- bit hacky but the keypad hates everyone
        if data.keydown1 and not data.keydown2 then
            keypad:SetDisplayText("y")
            Wire_TriggerOutput(keypad, "Valid", 1)
            keypad:EmitSound("buttons/button9.wav")
        elseif data.keydown2 and not data.keydown1 then
            keypad:SetDisplayText("n")
            Wire_TriggerOutput(keypad, "Invalid", 1)
            keypad:EmitSound("buttons/button8.wav")
        end
        local access = data.keydown1 and not data.keydown2
        if access or (data.keydown2 and not data.keydown1) then
            keypad.CurrentNum = -1
            timer.Create("wire_keypad_"..keypad:EntIndex().."_"..tostring(access), 2, 1, function()
                if IsValid(keypad) then
                    keypad:SetDisplayText("")
                    keypad.CurrentNum = 0
                    if access then
                        Wire_TriggerOutput(keypad, "Valid", 0)
                    else
                        Wire_TriggerOutput(keypad, "Invalid", 0)
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