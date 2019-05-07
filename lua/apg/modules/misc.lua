--[[------------------------------------------

	============================
		MISCELLANEOUS MODULE
	============================

	Developer informations :
	---------------------------------
	Used variables :
		vehDamage = { value = true, desc = "True to enable vehicles damages, false to disable." }
		vehNoCollide = { value = false, desc = "True to disable collisions between vehicles and players"}
		autoFreeze = { value = false, desc = "Freeze every unfrozen prop each X seconds" }
		autoFreezeTime = { value = 120, desc = "Auto freeze timer (seconds)"}

]]--------------------------------------------
local mod = "misc"

--[[--------------------
	Helper functions
]]----------------------
local function isVehDamage( dmg, atk, ent )
	if not IsValid( ent ) then return false end
	if dmg:GetDamageType() == DMG_VEHICLE or APG.IsVehicle( atk ) or APG.IsVehicle( ent ) then
		return true
	end
	return false
end

local function getPhys(ent)
	local phys = IsValid(ent) and ent.GetPhysicsObject and ent:GetPhysicsObject() or false
	return ( phys and IsValid(phys) ) and phys or false
end

--[[--------------------
	No Collide vehicles on spawn
]]----------------------
APG.hookAdd( mod,"OnEntityCreated", "APG_noCollideVeh", function( ent )
	timer.Simple(0.03, function()
		if APG.cfg[ "vehNoCollide" ].value and APG.IsVehicle( ent ) then
			ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		end
	end)
end)

--[[--------------------
	Disable prop damage
]]----------------------
APG.hookAdd( mod, "EntityTakeDamage","APG_noPropDmg", function( target, dmg )
	if ( not APG.cfg[ "allowPK" ].value ) then -- Check if prop kill is allowed, before checking anything else.
		local atk, ent = dmg:GetAttacker(), dmg:GetInflictor()
		if APG.isBadEnt( ent ) or dmg:GetDamageType() == DMG_CRUSH or ( APG.cfg[ "vehDamage" ].value and isVehDamage( dmg, atk, ent ) ) then
			dmg:SetDamage(0)
			return true
			-- ^ Returning true overrides and blocks all related damage, it also prevents the hook from running any further preventing unintentional damage from other addons.
		end
	end
end)

--[[--------------------
	Block Physgun Reload
]]----------------------
APG.hookAdd( mod, "OnPhysgunReload", "APG_blockPhysgunReload", function( _, ply )
	if APG.cfg[ "blockPhysgunReload" ].value then
		--APG.notification("Physgun Reloading is Currently Disabled", ply, 1)
		return false
	end
end)

--[[--------------------
	Block Gravitygun Throwing
]]----------------------
APG.hookAdd( mod, "GravGunOnDropped", "APG_blockGravGunThrow", function(ply, ent)
	if ( not APG.cfg["blockGravGunThrow"].value ) then return end
	APG.killVelocity(ent, false, false, true)
end)

--[[--------------------
	Auto prop freeze
]]----------------------
APG.timerAdd( mod, "APG_autoFreeze", APG.cfg[ "autoFreezeTime" ].value, 0, function()
	if APG.cfg[ "autoFreeze" ].value then
		APG.freezeProps()
	end
end)

--[[--------------------
	Fading door management
]]----------------------

APG.hookAdd(mod, "CanTool", "APG_fadingDoorTool", function(ply, tr, tool)
	if IsValid(tr.Entity) and tr.Entity.APG_Ghosted then
		APG.notification("Cannot use tool on ghosted entity!", ply, 1)
		return false
	end

	if APG.cfg["fadingDoorHook"].value and tool == "fading_door" then
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

APG.hookAdd(mod, "APG.FadingDoorToggle", "init", function(ent, state, ply)
	if ent.APG_Ghosted then
		APG.entUnGhost(ent, ply, "Your fading door is ghosted! (" .. ( ent.GetModel and ent:GetModel() or "???" ) .. ")")
		return true
	end

	ent:ForcePlayerDrop()

	local phys = getPhys(ent)
	if phys then
		phys:EnableMotion(false)
	end
end)

--[[ Flashlight Spam ]]--
local spammers = {}
APG.hookAdd(mod, "PlayerSwitchFlashlight", "APG_flashlightSpam", function(ply, enabled)
	if not APG.cfg[ "blockFlashlightSpam" ].value then return end

	if ply:CanUseFlashlight() and enabled then
		spammers[tostring(ply:UserID())] = spammers[tostring(ply:UserID())] or {}
		local key = spammers[tostring(ply:UserID())]

		key.times = key.times and key.times + 1 or 1
		key.when = key.when or CurTime()

		if key.times > 4 then
			local can = ply:CanUseFlashlight()
			ply:AllowFlashlight(false)
			ply:EmitSound('buttons/button10.wav')

			timer.Simple(4, function()
				if IsValid(ply) then
					ply:AllowFlashlight(can)
					spammers[tostring(ply:UserID())] = nil
				end
			end)
		end

		if key.when+1 < CurTime() then
			spammers[tostring(ply:UserID())] = nil
		end
	end
end)

--[[ FRZR9K ]]--

local zero = Vector(0,0,0)
local pstop = FrameTime() * 3

APG.timerAdd(mod, "frzr9k", pstop, 0, function()
	if APG.cfg["sleepyPhys"].value then
		for _,v in next, ents.GetAll() do
			local phys = getPhys( v )
			local isBadEnt = APG.isBadEnt( v )
			if isBadEnt and phys and ( phys:IsMotionEnabled() and not v:IsPlayerHolding() ) then
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

APG.hookAdd(mod, "OnEntityCreated", "frzr9k", function(ent)
	if APG.cfg["sleepyPhys"].value and APG.cfg["sleepyPhysHook"].value then
		timer.Simple(0.05, function()
			if APG.isBadEnt( ent ) and getPhys( ent ) then
				ent:AddCallback("PhysicsCollide", collcall)
			end
		end)
	end
end)

--[[------------------------------------------
		Load hooks and timers
]]--------------------------------------------

APG.updateHooks(mod)
APG.updateTimers(mod)
