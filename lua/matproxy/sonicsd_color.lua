
matproxy.Add(
{
    name    =   "SonicSDColor",

    init    =   function( self, mat, values )

        self.ResultTo = values.resultvar

    end,

    -- The engine passes the IMaterial itself, not the material-name string the annotation claims.
    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind    =   function( self, mat, ent )

        if not IsValid( ent ) then return end

        local owner = ent:GetOwner();
        if not (IsValid(owner) and owner:IsPlayer()) then return end

        local col1 = Vector(GetConVarNumber("sonic_light_r")/255, GetConVarNumber("sonic_light_g")/255, GetConVarNumber("sonic_light_b")/255)
        local col2 = Vector(GetConVarNumber("sonic_light2_r")/255, GetConVarNumber("sonic_light2_g")/255, GetConVarNumber("sonic_light2_b")/255)
        local cold = Vector(GetConVarNumber("sonic_lightoff_r")/255, GetConVarNumber("sonic_lightoff_g")/255, GetConVarNumber("sonic_lightoff_b")/255)
        if not isvector(col1 and col2) then return end

        local keydown1=owner:KeyDown(IN_ATTACK)
        local keydown2=owner:KeyDown(IN_ATTACK2)

        local mul
        local col
        if keydown1 or keydown2 then
            mul = 4.0 + math.sin( CurTime() * 5 ) * 0.25
        elseif cold == col1 then
            mul = 0.6
        else
            mul = 1
        end

        if keydown2 then
            col=col2
        elseif keydown1 then
            col=col1
        else
            col=cold
        end

        mat:SetVector( self.ResultTo, col * mul );

    end
})

matproxy.Add(
{
    name    =   "SonicSDColorStatic",

    init    =   function( self, mat, values )

        self.ResultTo = values.resultvar

    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind    =   function( self, mat, ent )

        if not IsValid( ent ) then return end

        local owner = ent:GetOwner();
        if not (IsValid(owner) and owner:IsPlayer()) then return end

        local cold = Vector(GetConVarNumber("sonic_light_r")/255, GetConVarNumber("sonic_light_g")/255, GetConVarNumber("sonic_light_b")/255)

        mat:SetVector( self.ResultTo, cold );

    end
})

matproxy.Add(
{
    name    =   "SonicSDColor2Static",

    init    =   function( self, mat, values )

        self.ResultTo = values.resultvar

    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind    =   function( self, mat, ent )

        if not IsValid( ent ) then return end

        local owner = ent:GetOwner();
        if not (IsValid(owner) and owner:IsPlayer()) then return end

        local cold = Vector(GetConVarNumber("sonic_light2_r")/255, GetConVarNumber("sonic_light2_g")/255, GetConVarNumber("sonic_light2_b")/255)

        mat:SetVector( self.ResultTo, cold );

    end
})

matproxy.Add(
{
    name    =   "SonicSDColorOff",

    init    =   function( self, mat, values )

        self.ResultTo = values.resultvar

    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind    =   function( self, mat, ent )

        if not IsValid( ent ) then return end

        local owner = ent:GetOwner();
        if not (IsValid(owner) and owner:IsPlayer()) then return end

        local cold = Vector(GetConVarNumber("sonic_lightoff_r")/255, GetConVarNumber("sonic_lightoff_g")/255, GetConVarNumber("sonic_lightoff_b")/255)

        mat:SetVector( self.ResultTo, cold );

    end
})

matproxy.Add(
{
    name    =   "SonicSDLightBool",

    init    =   function( self, mat, values )

        self.ResultTo = values.resultvar

    end,

    ---@param self table
    ---@param mat IMaterial
    ---@param ent Entity?
    bind    =   function( self, mat, ent )

        if not IsValid( ent ) then return end

        local owner = ent:GetOwner();
        if not (IsValid(owner) and owner:IsPlayer()) then return end

        local keydown1=owner:KeyDown(IN_ATTACK)
        local keydown2=owner:KeyDown(IN_ATTACK2)

        local active=0
        if keydown2 or keydown1 then
            active=1
        end

        mat:SetFloat( self.ResultTo, active );

    end
})
