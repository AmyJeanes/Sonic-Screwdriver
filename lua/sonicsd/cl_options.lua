-- Options

local checkbox_options={
    -- Name, ConVar, Default, Userinfo
    {"Give sonic on spawn", "sonic_give_on_spawn", false, true},
    {"Sound", "sonic_sound", true, false},
    {"Particle light", "sonic_light", true, false},
    {"Dynamic light", "sonic_dynamiclight", true, false},
    {"Enable default colors for each sonic", "sonic_should_set_default_colors", true, false},
}

for _,v in pairs(checkbox_options) do
    CreateClientConVar(v[2], v[3] and "1" or "0", true, v[4])
end

CreateClientConVar("sonic_light_r", "0", true)
CreateClientConVar("sonic_light_g", "255", true)
CreateClientConVar("sonic_light_b", "0", true)
CreateClientConVar("sonic_light2_r", "0", true)
CreateClientConVar("sonic_light2_g", "255", true)
CreateClientConVar("sonic_light2_b", "0", true)
CreateClientConVar("sonic_lightoff_r", "0", true)
CreateClientConVar("sonic_lightoff_g", "255", true)
CreateClientConVar("sonic_lightoff_b", "0", true)
CreateClientConVar("sonic_model", "0", true, true)
cvars.AddChangeCallback("sonic_model", function(convar_name, old, selected)
    net.Start("SonicSD-Update")
        net.WriteString(selected)
    net.SendToServer()
    local weapon = LocalPlayer():GetWeapon("swep_sonicsd") --[[@as swep_sonicsd]]
    if IsValid(weapon) then
        weapon:SetSonicID(selected)
        weapon:CallHook("SonicChanged")
    end
end)

hook.Add("PopulateToolMenu", "SonicSD-PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption("Options", "Doctor Who", "Sonic_Options", "Sonic Screwdriver", "", "", function(panel)
        panel:ClearControls()
        panel:Help("Sonic Screwdriver")

        local comboBox = vgui.Create("DComboBox")
        comboBox:SetText("Model")
        for _,v in pairs(SonicSD.sonics) do
            if not v.IsBase then
                v.OptionID=comboBox:AddChoice(v.Name,v.ID)
            end
        end
        local selectedmodel=GetConVarString("sonic_model")
        for _,v in pairs(SonicSD.sonics) do
            -- Use the runtime type, not the authored one.
            ---@cast v sonicsd_sonic_complete
            if not v.IsBase and selectedmodel==v.ID then
                comboBox:ChooseOptionID(v.OptionID)
            end
        end
        comboBox.OnSelect = function(_box,index,value,data)
            RunConsoleCommand("sonic_model", data)
        end
        panel:AddItem(comboBox)

        ---@param label string
        ---@param r_convar string
        ---@param g_convar string
        ---@param b_convar string
        local function addColorMixer(label, r_convar, g_convar, b_convar)
            panel:Help(label)

            local mixer = vgui.Create("DColorMixer")
            mixer:SetAlphaBar(false)
            mixer:SetColor(Color(GetConVarNumber(r_convar), GetConVarNumber(g_convar), GetConVarNumber(b_convar)))
            mixer.ValueChanged = function(_self, col)
                RunConsoleCommand(r_convar, col.r)
                RunConsoleCommand(g_convar, col.g)
                RunConsoleCommand(b_convar, col.b)
            end
            panel:AddItem(mixer)
        end

        addColorMixer("Primary color", "sonic_light_r", "sonic_light_g", "sonic_light_b")
        addColorMixer("Secondary color", "sonic_light2_r", "sonic_light2_g", "sonic_light2_b")
        addColorMixer("Off color", "sonic_lightoff_r", "sonic_lightoff_g", "sonic_lightoff_b")

        for _,v in pairs(checkbox_options) do
            panel:CheckBox(v[1], v[2])
        end
    end)
end)