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
    local weapon = LocalPlayer():GetWeapon("swep_sonicsd")
    if IsValid(weapon) then
        weapon:SetSonicID(selected)
        weapon:CallHook("SonicChanged")
    end
end)

hook.Add("PopulateToolMenu", "SonicSD-PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption("Options", "Doctor Who", "Sonic_Options", "Sonic Screwdriver", "", "", function(panel)
        panel:ClearControls()

        local DLabel1 = vgui.Create( "DLabel" )
        DLabel1:SetText( "Sonic Screwdriver" )
        panel:AddItem(DLabel1)

        local comboBox = vgui.Create("DComboBox")
        comboBox:SetText("Model")
        for _,v in pairs(SonicSD.sonics) do
            ---@cast v sonicsd_sonic_complete
            if not v.IsBase then
                v.OptionID=comboBox:AddChoice(v.Name,v.ID)
            end
        end
        local selectedmodel=GetConVarString("sonic_model")
        for _,v in pairs(SonicSD.sonics) do
            ---@cast v sonicsd_sonic_complete
            if not v.IsBase and selectedmodel==v.ID then
                comboBox:ChooseOptionID(v.OptionID)
            end
        end
        comboBox.OnSelect = function(_box,index,value,data)
            RunConsoleCommand("sonic_model", data)
        end
        panel:AddItem(comboBox)

        local DLabel2 = vgui.Create( "DLabel" )
        DLabel2:SetText( "Primary color" )
        panel:AddItem(DLabel2)

        local Mixer1 = vgui.Create( "DColorMixer" )
        Mixer1:SetPalette( true )       --Show/hide the palette         DEF:true
        Mixer1:SetAlphaBar( false )         --Show/hide the alpha bar       DEF:true
        Mixer1:SetWangs( true )         --Show/hide the R G B A indicators  DEF:true
        Mixer1:SetColor( Color(GetConVarNumber("sonic_light_r"), GetConVarNumber("sonic_light_g"), GetConVarNumber("sonic_light_b")) )  --Set the default color
        Mixer1.ValueChanged = function(self,col)
            RunConsoleCommand("sonic_light_r", col.r)
            RunConsoleCommand("sonic_light_g", col.g)
            RunConsoleCommand("sonic_light_b", col.b)
        end
        panel:AddItem(Mixer1)

        local DLabel3 = vgui.Create( "DLabel" )
        DLabel3:SetText( "Secondary color" )
        panel:AddItem(DLabel3)

        local Mixer2 = vgui.Create( "DColorMixer" )
        Mixer2:SetPalette( true )       --Show/hide the palette         DEF:true
        Mixer2:SetAlphaBar( false )         --Show/hide the alpha bar       DEF:true
        Mixer2:SetWangs( true )         --Show/hide the R G B A indicators  DEF:true
        Mixer2:SetColor( Color(GetConVarNumber("sonic_light2_r"), GetConVarNumber("sonic_light2_g"), GetConVarNumber("sonic_light2_b")) )  --Set the default color
        Mixer2.ValueChanged = function(self,col)
            RunConsoleCommand("sonic_light2_r", col.r)
            RunConsoleCommand("sonic_light2_g", col.g)
            RunConsoleCommand("sonic_light2_b", col.b)
        end
        panel:AddItem(Mixer2)

        local DLabel4 = vgui.Create( "DLabel" )
        DLabel4:SetText( "Off color" )
        panel:AddItem(DLabel4)

        local Mixer3 = vgui.Create( "DColorMixer" )
        Mixer3:SetPalette( true )       --Show/hide the palette         DEF:true
        Mixer3:SetAlphaBar( false )         --Show/hide the alpha bar       DEF:true
        Mixer3:SetWangs( true )         --Show/hide the R G B A indicators  DEF:true
        Mixer3:SetColor( Color(GetConVarNumber("sonic_lightoff_r"), GetConVarNumber("sonic_lightoff_g"), GetConVarNumber("sonic_lightoff_b")) )  --Set the default color
        Mixer3.ValueChanged = function(self,col)
            RunConsoleCommand("sonic_lightoff_r", col.r)
            RunConsoleCommand("sonic_lightoff_g", col.g)
            RunConsoleCommand("sonic_lightoff_b", col.b)
        end
        panel:AddItem(Mixer3)

        local checkboxes={}
        for _,v in pairs(checkbox_options) do
            local checkBox = vgui.Create( "DCheckBoxLabel" )
            checkBox:SetText( v[1] )
            checkBox:SetValue( GetConVar(v[2]):GetBool() )
            checkBox:SetConVar( v[2] )
            panel:AddItem(checkBox)
            table.insert(checkboxes, checkBox)
        end
    end)
end)