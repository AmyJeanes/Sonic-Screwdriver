-- Sound

function SWEP:UpdateSounds()
    local sonic = self:GetSonic()
    self.sound1=CreateSound(self,sonic.SoundLoop)
    self.sound2=CreateSound(self,sonic.SoundLoop2 or sonic.SoundLoop)
    self.buttonsound=sonic.ButtonSound
    self.buttonsoundon=sonic.ButtonSoundOn
    self.buttonsoundoff=sonic.ButtonSoundOff
    self.holstersound=sonic.HolsterSound
    self.buttondelay=sonic.ButtonDelay
    self.modesoundon=sonic.ModeSoundOn
    self.modesoundoff=sonic.ModeSoundOff
end

SWEP:AddHook("Initialize", "sound", function(self)
    self.curbeep=0
    self.eyeangles=Angle(0,0,0)
    self.mutesonic=false
    self:UpdateSounds()
end)

SWEP:AddHook("SonicChanged", "sound", function(self)
    self:UpdateSounds()
end)

SWEP:AddHook("ModeChanged", "sound", function(self, mode)
    if mode and self.modesoundon then
        self:EmitSound(self.modesoundon)
    elseif not mode and self.modesoundoff then
        self:EmitSound(self.modesoundoff)
    end 
end)

SWEP:AddHook("OnRemove", "sound", function(self)
    if self.sound1 then self.sound1:Stop() self:EmitSound(self.buttonsoundoff) end
    if self.sound2 then self.sound2:Stop() self:EmitSound(self.buttonsoundoff) end
end)

SWEP:AddHook("Holster", "sound", function(self)
    if self.sound1 then self.sound1:Stop() self:EmitSound(self.holstersound) end
    if self.sound2 then self.sound2:Stop() self:EmitSound(self.holstersound) end
end)

SWEP:AddHook("Think", "sound", function(self,keydown1,keydown2)

    local function StopSound(sound)
        if sound and sound:IsPlaying() then
            sound:Stop()
        end
    end

    if tobool(GetConVarNumber("sonic_sound"))~=true or (not keydown1 and not keydown2) or self.mutesonic then
        StopSound(self.sound1)
        StopSound(self.sound2)
        self.sound_start = nil
        self.sound_playing = nil
        if self.soundon then
            if CurTime() > (self.soundoff_last or 0) + 0.5 and self.buttonsound then
                self:EmitSound(self.buttonsoundoff)
                self.soundoff_last = CurTime()
            end
            self.soundon = false
        end
        return
    end

    self.soundon = true

    local diff=self.Owner:EyeAngles()-self.eyeangles
    if diff.p < 0 then diff.p=-diff.p end
    if diff.y < 0 then diff.y=-diff.y end
    local pitch=diff.p+diff.y*15

    local function ProcessSound(sound, other_sound)
        sound:ChangePitch(math.Clamp(pitch+100,100,150),0.1)
        self.eyeangles=self.Owner:EyeAngles()
        if not self.sound_start and not self.sound_playing then
            if CurTime() > (self.soundon_last or 0) + (self.buttondelay or 0) + 0.5 and not other_sound:IsPlaying() and self.buttonsound then
                self:EmitSound(self.buttonsoundon)
                self.soundon_last = CurTime()
            end
            self.sound_start = CurTime() + (self.buttondelay or 0)
        end
        if ((self.sound_start and self.sound_start < CurTime()) or self.sound_playing) and not sound:IsPlaying() then
            sound:Play()
            self.sound_playing = true
            self.sound_start = nil
            return
        end
        StopSound(other_sound)
    end

    if not self.mutesonic then
        if keydown2 then
            ProcessSound(self.sound2, self.sound1)
        elseif keydown1 then
            ProcessSound(self.sound1, self.sound2)
        end
    end
end)