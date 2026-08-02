-- Debug overlay

---@param ent Entity
---@return string
local function name(ent)
    if IsValid(ent) then return ent:GetClass().."["..ent:EntIndex().."]" end
    if ent == game.GetWorld() then return "worldspawn" end
    return "nothing"
end

if SERVER then
    util.AddNetworkString("SonicSD-Debug")

    ---@param self swep_sonicsd
    SWEP:AddHook("Think", "debug", function(self)
        local owner = self:GetOwner() --[[@as Player]]
        if not IsValid(owner) or not owner:IsPlayer() then return end
        if owner:GetInfoNum("sonic_debug", 0) == 0 then return end
        if RealTime() < (self._debugnext or 0) then return end
        self._debugnext = RealTime() + 0.1

        local trace = util.QuickTrace(owner:GetShootPos(), owner:GetAimVector() * self.Range, owner)
        local data = self.data

        local progress
        if data then
            progress = "fired"
        elseif self.wait then
            progress = string.format("%.2f / %.2fs", math.Clamp(self.WaitTime - (self.wait - CurTime()), 0, self.WaitTime), self.WaitTime)
        else
            progress = "idle"
        end

        local resolved = self:CallHook("ResolveTarget", trace.Entity, trace)
        local redirect = (IsValid(resolved) and resolved ~= trace.Entity) and name(resolved) or ""

        local allow = ""
        if data then
            allow = "use="..tostring(data.hooks.canuse)
                .."  move="..tostring(data.hooks.canmove)
                .."  tool="..tostring(data.hooks.cantool)
        end

        local portal = ""
        if IsValid(trace.WorldPortal) then
            portal = name(trace.WorldPortal).." -> "..name(trace.WorldPortal:GetExit())
        end

        net.Start("SonicSD-Debug")
            net.WriteString(name(trace.Entity).."  "..math.floor(trace.HitPos:Distance(trace.StartPos)).."u")
            net.WriteString(redirect)
            net.WriteString(portal)
            net.WriteString(progress)
            net.WriteString(allow)
            net.WriteBool(owner.tardis_vec ~= nil)
        net.Send(owner)
    end)
else
    CreateClientConVar("sonic_debug", "0", true, true, "Draw the sonic debug overlay")

    local sv = {}
    net.Receive("SonicSD-Debug", function()
        sv.target = net.ReadString()
        sv.redirect = net.ReadString()
        sv.portal = net.ReadString()
        sv.progress = net.ReadString()
        sv.allow = net.ReadString()
        sv.destination = net.ReadBool()
    end)

    ---@param rows table[]
    ---@param label string
    ---@param value string?
    local function row(rows, label, value)
        if value == nil or value == "" then return end
        rows[#rows+1] = {label, value}
    end

    ---@param ply Player
    ---@return string
    local function keys(ply)
        local held = {}
        if ply:KeyDown(IN_ATTACK) then held[#held+1] = "MOUSE1" end
        if ply:KeyDown(IN_ATTACK2) then held[#held+1] = "MOUSE2" end
        if ply:KeyDown(IN_RELOAD) then held[#held+1] = "RELOAD" end
        if ply:KeyDown(IN_WALK) then held[#held+1] = "WALK" end
        if ply:KeyDown(IN_SPEED) then held[#held+1] = "SPRINT" end
        return #held > 0 and table.concat(held, " + ") or "none"
    end

    local function overlay()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "swep_sonicsd" then return end

        local rows = {}
        row(rows, "sonic", wep:GetSonicID().."   mode "..(wep:GetSonicMode() and "secondary" or "primary"))
        row(rows, "holding", keys(ply))
        row(rows, "target", sv.target or "(waiting for server)")
        row(rows, "redirect", sv.redirect)
        row(rows, "portal", sv.portal)
        row(rows, "hold", sv.progress)
        row(rows, "allowed", sv.allow)
        row(rows, "tardis", IsValid(ply.linked_tardis)
            and (name(ply.linked_tardis)..(sv.destination and "   destination set" or ""))
            or nil)

        surface.SetFont("DermaDefault")
        local widest = 0
        for _, r in ipairs(rows) do
            widest = math.max(widest, select(1, surface.GetTextSize(r[2])))
        end

        local x, y, line = 24, ScrH() * 0.3, 18
        surface.SetDrawColor(0, 0, 0, 170)
        surface.DrawRect(x - 8, y - 6, widest + 90, #rows * line + 12)
        for i, r in ipairs(rows) do
            draw.SimpleText(r[1], "DermaDefault", x, y + (i-1) * line, color_white)
            draw.SimpleText(r[2], "DermaDefault", x + 70, y + (i-1) * line, color_white)
        end
    end

    -- A per-frame draw hook that errors would spam, so it retires itself.
    hook.Add("HUDPaint", "SonicSD-Debug", function()
        if not GetConVar("sonic_debug"):GetBool() then return end
        local ok, err = pcall(overlay)
        if not ok then
            hook.Remove("HUDPaint", "SonicSD-Debug")
            ErrorNoHalt("sonic debug overlay retired itself: "..tostring(err).."\n")
        end
    end)
end
