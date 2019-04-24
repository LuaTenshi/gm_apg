--[[------------------------------------------

	A.P.G. - a lightweight Anti Prop Griefing solution (v{{ script_version_name }})
	Made by :
	- While True (http://steamcommunity.com/id/76561197972967270)
	- LuaTenshi (http://steamcommunity.com/id/76561198096713277)

	Licensed to : http://steamcommunity.com/id/{{ user_id }}

	============================
	        MISC2 MODULE
	============================

]]--------------------------------------------
local mod = "misc2"

local function hookAdd(call, key, func)
	APG.hookRegister(mod, call, key, func)
end

local function timerMake(id, delay, times, func)
	APG.timerRegister(mod, id, delay, times, func)
end

local function getphys(ent)
	local phys = IsValid(ent) and ent.GetPhysicsObject and ent:GetPhysicsObject() or false
	return IsValid(phys) and phys or false
end

hookAdd("CanTool", "APG_canTool", function(ply, tr, tool)
	if IsValid(tr.Entity) and tr.Entity.APG_Ghosted then
		APG.userNotification("Cannot use tool on ghosted entity!", ply, 1)
		return false
	end
	if APG.cfg["thFadingDoors"].value and tool == "fading_door" then
		timer.Simple(0, function()
			if IsValid(tr.Entity) and not tr.Entity:IsPlayer() then
				local ent = tr.Entity

				if not IsValid(ent) then return end
				if not ent.isFadingDoor then return end

				local state = ent.fadeActive

				if state then
					ent:fadeDeactivate()
				end

				ent.oldFadeActivate = ent.oldFadeActivate or ent.fadeActivate
				ent.oldFadeDeactivate = ent.oldFadeDeactivate or ent.fadeDeactivate

				function ent:fadeActivate()
					if hook.Run("APG.FadingDoorToggle", self, true, ply) then return end
					ent:oldFadeActivate()
				end

				function ent:fadeDeactivate()
					if hook.Run("APG.FadingDoorToggle", self, false, ply) then return end
					ent:oldFadeDeactivate()
					ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
				end

				if state then
					ent:fadeActivate()
				end
			end
		end)
	end
end)

hookAdd("APG.FadingDoorToggle", "init", function(ent, state, ply)
	if ent.APG_Ghosted then
		APG.entUnGhost(ent, ply, "Your fading door is ghosted! (" .. ( ent.GetModel and ent:GetModel() or "???" ) .. ")")
		return true
	end

	ent:ForcePlayerDrop()

	local phys = getphys(ent)
	if phys then
		phys:EnableMotion(false)
	end
end)

--[[ FRZR9K ]]--

local zero = Vector(0,0,0)
local pstop = FrameTime() * 3

timerMake("frzr9k", pstop, 0, function()
	if APG.cfg["sleepyPhys"].value then
		for _,v in next, ents.GetAll() do
			local phys = getphys(v)
			if IsValid(phys) and phys:IsMotionEnabled() and not v:IsPlayerHolding() then
				local vel = v:GetVelocity()
				if vel:Distance(zero) <= 23 then
					phys:Sleep()
				end
			end
		end
	end
end)

-- Collision Monitoring --
local function collcall(ent, data)
	local hit = data.HitObject
	local mep = data.PhysObject

	if IsValid(ent) and IsValid(hit) and IsValid(mep) then
		ent["frzr9k"] = ent["frzr9k"] or {}
		local obj = ent["frzr9k"]

		obj.Collisions = (obj.Collisions or 0) + 1

		obj.CollisionTime = obj.CollisionTime or (CurTime() + 5)
		obj.LastCollision = CurTime()

		if obj.Collisions > 23 then
			obj.Collisions = 0
			for _,e in next, {mep, hit} do
				e:SetVelocityInstantaneous(Vector(0,0,0))
				e:Sleep()
			end
		end

		if obj.CollisionTime < obj.LastCollision then
			local subtract = 1
			local mem = obj.CollisionTime

			while true do
				mem = mem + 5
				subtract = subtract + 1
				if mem >= obj.LastCollision then
					break
				end
			end

			obj.Collisions = (obj.Collisions - subtract)
			obj.Collisions = (obj.Collisions > 1) and obj.Collisions or 1

			obj.CollisionTime = (CurTime() + 5)
		end

		ent["frzr9k"] = obj
	end
end

hookAdd("OnEntityCreated", "frzr9k", function(ent)
	if APG.cfg["sleepyPhys"].value and APG.cfg["hookSP"].value then
		timer.Simple(0.1, function()
			if IsValid(ent) and ent.GetPhysicsObject and IsValid(ent:GetPhysicsObject()) then
				ent:AddCallback("PhysicsCollide", collcall)
			end
		end)
	end
end)

-- Requires Fading Door Hooks --
hookAdd("APG.FadingDoorToggle", "frzr9k", function(ent, faded)
	if APG.cfg["sleepyPhys"].value and IsValid(ent) and faded then
    local ply = APG.getOwner(ent)
    local pos = ent:GetPos()
    local notification = false
    local doors = {}
    local count = 0

    for _,v in next, ents.FindInSphere(pos, 3) do
      if v ~= ent and IsValid(v) and v.isFadingDoor and APG.getOwner(v) == o then
        table.insert(doors, v)
        count = count + 1
      end
    end

    if count > 2 then
      for _,v in next, doors do
        v:Remove()
      end
      notification = true
    end

    if notification then
      APG.userNotification("[APG] Some of your fading doors were removed.", ply)
    end
  end
end)

--[[------------------------------------------
        Load hooks and timers
]]--------------------------------------------
for k, v in next, APG[mod]["hooks"] do
    hook.Add( v.event, v.identifier, v.func )
end

for k, v in next, APG[mod]["timers"] do
    timer.Create( v.identifier, v.delay, v.repetitions, v.func )
end
