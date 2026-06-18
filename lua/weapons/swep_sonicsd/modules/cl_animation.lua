-- Animation

---@class SonicSDAnim
---@field speed number
---@field param string
---@field pos number
---@field target number
---@field enabled boolean

function SWEP:SetupAnimation(name, data)
    self.anims[name] = {}
    self.anims[name].speed = data.Speed or 1
    self.anims[name].param = data.Param or "switch"
    self.anims[name].pos = 0
    self.anims[name].target = 0
    self.anims[name].enabled = true
    return self.anims[name]
end

function SWEP:SetupAnimations()
    local sonic=self:GetSonic()
    if not sonic.Animations then return end
    local anims = sonic.Animations
    ---@type table<string, SonicSDAnim>
    self.anims = {}
    if anims.Mode then
        self:SetupAnimation("mode", anims.Mode)
        self:SetModeAnimation(self:GetSonicMode())
    end
    if anims.Toggle then
        self:SetupAnimation("toggle", anims.Toggle)
    end
    if anims.Active then
        self:SetupAnimation("active", anims.Active)
    end
end

function SWEP:HandleAnimation(anim, viewModel)
    if anim.enabled and anim.pos ~= anim.target then
        anim.pos = math.Approach(anim.pos, anim.target, FrameTime() * 5 * anim.speed)
    end
    if self:GetOwner() == LocalPlayer() then
        viewModel:SetPoseParameter(anim.param, anim.pos)
    end
    self:SetPoseParameter(anim.param, anim.pos)
end

function SWEP:SetModeAnimation(mode)
    if not self.anims or not self.anims.mode then return end
    if mode then
        self.anims.mode.target = 1
    else
        self.anims.mode.target = 0
    end
end

SWEP:AddHook("Initialize", "animation", function(self)
    self:SetupAnimations()
end)

SWEP:AddHook("SonicChanged", "animation", function(self)
    self:SetupAnimations()
end)

SWEP:AddHook("ModeChanged", "animation", function(self, mode)
    self:SetModeAnimation(mode)
end)

SWEP:AddHook("Think", "animation", function(self)
    if not self.anims then return end

    local viewModel = self:GetOwner()==LocalPlayer() and self:GetOwner():GetViewModel()
    if not IsValid(viewModel) then viewModel = nil end

    if self.anims.active then
        local keydown1=self:GetOwner():KeyDown(IN_ATTACK)
        local keydown2=self:GetOwner():KeyDown(IN_ATTACK2)
        if keydown1 or keydown2 then
            if keydown1 then
                if self.anims.active.pos == 1 then
                    self.anims.active.pos = 0
                end
            else
                if self.anims.active.pos == 0 then
                    self.anims.active.pos = 1
                end
            end
            if not self.anims.active.enabled then
                self.anims.active.enabled = true
            end
            self.anims.active.target = keydown2 and 0 or 1
        elseif self.anims.active.enabled then
            self.anims.active.enabled = false
        end
    end

    if self.anims.toggle then
        local keydown1=self:GetOwner():KeyDown(IN_ATTACK)
        local keydown2=self:GetOwner():KeyDown(IN_ATTACK2)
        if keydown1 or keydown2 then
            self.anims.toggle.target = 1
        else
            self.anims.toggle.target = 0
        end
    end

    for _,v in pairs(self.anims) do
        self:HandleAnimation(v, viewModel)
    end
end)