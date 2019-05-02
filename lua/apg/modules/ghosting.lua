--[[------------------------------------------

	============================
	GHOSTING/UNGHOSTING MODULE
	============================

	Developer informations :
	---------------------------------
	Used variables :
		ghostColor = { value = Color(34, 34, 34, 220), desc = "Color set on ghosted props" }
		badEnts = {
			value = {
				["prop_physics"] = true,
				["wire_"] = false,
				["gmod_"] = false },
			desc = "Entities to ghost/control/secure"}
		alwaysFrozen = { value = false, desc = "Set to true to auto freeze props on physgun drop" }

]]--------------------------------------------

local mod = "ghosting"

--[[------------------------------------------
		Override base functions
]]--------------------------------------------
local ENT = FindMetaTable( "Entity" )
APG._SetCollisionGroup = APG._SetCollisionGroup or ENT.SetCollisionGroup

function ENT:SetCollisionGroup( group )
	local group = group

	local isBadEnt = APG.isBadEnt( self )
	local hasValidOwner = APG.getOwner( self )
	local groupIsNone = group == COLLISION_GROUP_NONE
	local isNotFrozen = not self.APG_Frozen

	local shouldMakeInteractable = isBadEnt and hasValidOwner and groupIsNone and isNotFrozen

	if shouldMakeInteractable then
		group = COLLISION_GROUP_INTERACTIVE
	end

	APG.log("DEBUG: Collision Group set to " .. group)
	return APG._SetCollisionGroup( self, group )
end

ENT._SetColor = ENT._SetColor or ENT.SetColor

function ENT:SetColor( color, ... )
	local color = color
	local r, g, b, a

	if type(color) == "number" then
		color = Color(color, select(1, ...) or 255, select(2, ...) or 255, select(3, ...) or 255)
	elseif type(color) == "table" and not IsColor(color) then
		r = color.r or color[1] or 255
		g = color.g or color[2] or 255
		b = color.b or color[3] or 255
		a = color.a or color[4] or 255
		color = Color(r, g, b, a)
	end

	assert( IsColor(color), "Invalid color passed to SetColor! \n This error prevents stuff from turning purple/pink." )

	return self:_SetColor( color )
end

local PhysObj = FindMetaTable( "PhysObj" )
APG._EnableMotion = APG._EnableMotion or PhysObj.EnableMotion
function PhysObj:EnableMotion( bool )
	local sent = self:GetEntity()
	if APG.isBadEnt( sent ) and APG.getOwner( sent ) then
		sent.APG_Frozen = not bool
		if not sent.APG_Frozen then
			sent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE )
		end
	end
	return APG._EnableMotion( self, bool )
end

function APG.isTrap( ent, fullscan )
	local check = false
	local center = ent:LocalToWorld( ent:OBBCenter() )
	local bRadius = ent:BoundingRadius()
	local cache = {}

	for _,v in next, ents.FindInSphere( center, bRadius ) do
		if v:IsPlayer() and v:Alive() then
			local pos = v:GetPos()
			local trace = { start = pos, endpos = pos, filter = v }
			local tr = util.TraceEntity( trace, v )

			if tr.Entity == ent then
				if fullscan then
					table.insert( cache, v )
				else
					check = v
				end
			end
		elseif APG.IsVehicle(v) then
			-- Check if the distance between the spheres centers is less than the sum of their radius.
			if v:IsPlayer() then -- Only check for players.
				local vCenter = v:LocalToWorld( v:OBBCenter() )
				if center:Distance( vCenter ) < v:BoundingRadius() then
					check = v
				end
			end
		end

		if check then break end
	end

	if fullscan and ( #cache > 0 ) then
		return cache
	else
		return check or false
	end
end

function APG.entGhost( ent, noCollide, enforce )
	if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end
	if APG.cfg["vehAntiGhost"].value and APG.IsVehicle( ent ) then return end
	if ent.jailWall then return end
	if type(noCollide) ~= "boolean" then noCollide = true end

	if not ent.APG_Ghosted then
		ent.FPPAntiSpamIsGhosted = nil -- Override FPP Ghosting.

		DropEntityIfHeld( ent )
		ent:ForcePlayerDrop()

		ent.APG_oldCollisionGroup = ent:GetCollisionGroup()

		if not enforce then
			-- If and old collision group was set get it.
			if ent.OldCollisionGroup then ent.APG_oldCollisionGroup = ent.OldCollisionGroup end -- For FPP
			if ent.DPP_oldCollision then ent.APG_oldCollisionGroup = ent.DPP_oldCollision end -- For DPP

			ent.OldCollisionGroup = nil
			ent.DPP_oldCollision = nil
		end

		ent.APG_Ghosted = true

		timer.Simple(0, function()
			if not IsValid( ent ) then return end

			if not ent.APG_oldColor then
				ent.APG_oldColor = ent:GetColor()

				if not enforce then
					if ent.OldColor then ent.APG_oldColor = ent.OldColor end -- For FPP
					if ent.__DPPColor then ent.APG_oldColor = ent.__DPPColor end -- For DPP

					ent.OldColor = nil
					ent.__DPPColor = nil
				end
			end

			ent:SetColor( APG.cfg[ "ghostColor" ].value )
		end)

		ent.APG_oldRenderMode = ent:GetRenderMode()
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		ent:DrawShadow( false )
		APG.log("DEBUG: noCollide set to " .. tostring(noCollide))
		if noCollide then
			ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
		else
			ent:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
		end

		ent:CollisionRulesChanged()
	end
end

function APG.entUnGhost( ent, ply, failmsg )
	if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end
	if ent.APG_Picked or (ent.APG_HeldBy and #ent.APG_HeldBy > 1) then return end

	if ent.APG_Ghosted == true then
		ent.APG_isTrap = APG.isTrap(ent)
		if not ent.APG_isTrap then
			ent.APG_Ghosted = false
			ent:DrawShadow( true )

			ent:SetRenderMode( ent.APG_oldRenderMode or RENDERMODE_NORMAL )
			ent:SetColor( ent.APG_oldColor or Color( 255, 255, 255, 255) )
			ent.APG_oldColor = false

			local newColGroup = COLLISION_GROUP_INTERACTIVE

			if ent.APG_oldCollisionGroup == COLLISION_GROUP_WORLD then
				newCollisionGroup = ent.APG_oldCollisionGroup
			elseif ent.APG_Frozen then
				newCollisionGroup = COLLISION_GROUP_NONE
			end

			ent:SetCollisionGroup( newCollisionGroup )

			ent:CollisionRulesChanged()
			return true
		else
			APG.notification( failmsg or "There is something in this prop!", ply, 1 )
			ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

			ent:CollisionRulesChanged()

			return false
		end
	end
end

function APG.ConstraintApply( ent, callback )
	local constrained = constraint.GetAllConstrainedEntities(ent)
	for _,v in next, constrained do
		if IsValid( v ) and v ~= ent then
			callback( v )
		end
	end
end

--[[------------------------------------------
		Hooks/Timers
]]--------------------------------------------

APG.hookAdd( mod, "PhysgunPickup", "APG_makeGhost", function(ply, ent)
	if not APG.canPhysGun( ent, ply ) then return end
	if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end

	ent.APG_Picked = true

	if not APG.cfg[ "allowPK" ].value then
		APG.entGhost( ent )
		APG.ConstraintApply( ent, function( _ent )
			if not _ent.APG_Frozen then
				_ent.APG_Picked = true
				APG.entGhost( _ent )
			end
		end) -- Apply ghost to all constrained ents
	end
end)

APG.hookAdd( mod, "PlayerUnfrozeObject", "APG_unFreezeInteract", function (ply, ent, object)
	if not APG.canPhysGun( ent, ply ) then return end
	if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end
	if APG.cfg[ "alwaysFrozen" ].value then
		APG.log("[APG-UNFREEZE]" .. ply:Nick() .. " unfroze " .. ent .. " but alwaysFrozen is enabled!")
		return false
	 end -- Do not unfreeze if Always Frozen is enabled !
	if ent:GetCollisionGroup( ) ~= COLLISION_GROUP_WORLD then
		APG.log("[APG-UNFREEZE]" .. ply:Nick() .. " unfroze " .. ent)
		ent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE )
	end
end)

APG.dJobRegister( "unghost", 0.1, 50, function( ent )
	if IsValid(ent) then
		APG.entUnGhost( ent )
	end
end)

APG.hookAdd( mod, "PhysgunDrop", "APG_pGunDropUnghost", function( ply, ent )
	if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end
	ent.APG_Picked = false

	if APG.cfg[ "alwaysFrozen" ].value then
		APG.freezeIt( ent )
	end

	APG.entUnGhost( ent, ply )

	APG.ConstraintApply( ent, function( _ent )
		_ent.APG_Picked = false
		APG.startDJob( "unghost", _ent )
	end) -- Apply unghost to all constrained ents
end)

local function SafeSetCollisionGroup( ent, colgroup, pobj )
	-- If the entity is being held by a player or is ghosted abort.
	if ent:IsPlayerHolding() then return end
	if ent.APG_Ghosted then return end

	if pobj then pobj:Sleep() end
	ent:SetCollisionGroup(colgroup)
end

APG.hookAdd( mod, "OnEntityCreated", "APG_noCollideOnCreate", function( ent )
	if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end
	if not IsValid( ent ) then return end
	if ent:GetClass() == "gmod_hands" then return end -- Fix shadow glitch

	timer.Simple( 0, function() APG.entGhost( ent ) end)
	timer.Simple( 0, function()
		local owner = APG.getOwner( ent )

		DropEntityIfHeld( ent )
		ent:ForcePlayerDrop()

		if IsValid( owner ) and owner:IsPlayer() then
			local pObj = ent:GetPhysicsObject()
			if IsValid(pObj) then
				if APG.cfg[ "alwaysFrozen" ].value then
					ent.APG_Frozen = true
					pObj:EnableMotion( false )
				elseif pObj:IsMoveable() then
					ent.APG_Frozen = false
					SafeSetCollisionGroup( ent, COLLISION_GROUP_INTERACTIVE )
				end
				pObj:RecheckCollisionFilter()

			-- Need's a whitelist to allow specific mods
			-- else
			-- 	if not APG.cfg["removeInvalidPhys"].value then return end
			-- 	timer.Simple(0, function()
			-- 		ent:Remove()
			-- 		APG.log(tostring(ent) .. " spawned by " .. owner:Nick() .. " doesn't have physics!")
			-- 	end)
			end
		end

		APG.startDJob( "unghost", ent )
	end)
end)

local BlockedProperties = { "collision", "persist", "editentity", "drive", "ignite", "statue" }
APG.hookAdd( mod, "CanProperty", "APG_canProperty", function(ply, property, ent)
	local property = tostring( property )
	if ( table.HasValue(BlockedProperties, property) and ent.APG_Ghosted ) then
		APG.notification( "Cannot set " .. property .. " properties on ghosted entities!", ply, -1, true)
		return false
	end
end)

-- Custom Hooks --
local function checkDoor(ply, ent)
	local isTrap = APG.isTrap(ent, true)

	if isTrap and istable(isTrap) then
		ent.APG_Ghosted = true
		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		for _,v in next, isTrap do
			if v:IsPlayer() then
				local push = v:GetForward()
				push = push * 1200
				push.z = 60

				v:SetVelocity(push)
			end
		end

		timer.Simple(1, function()
			if IsValid(ply) and IsValid(ent) then
				ent.APG_Ghosted = false
				ent:oldFadeDeactivate()
				ent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE )

				if IsValid(isTrap) then
					APG.log("Cant Unstuck " .. ply:GetName() .. " from " .. ent)
					APG.notification( "Unable to unstuck objects from fading door!", ply, 1 )
					APG.entGhost(ent)
				end
			end
		end)
	end
end

APG.hookAdd(mod, "APG.FadingDoorToggle", "APG_FadingDoor", function(ent, isFading)
	if APG.isBadEnt(ent) and APG.cfg["fadingDoorGhosting"].value then
		local ply = APG.getOwner( ent )

		if (IsValid(ply) and ply:IsPlayer() and not isFading) then
			-- If you make a timer small enough it will call multiple times a second
			timer.Simple(0.001, function()
				checkDoor(ply, ent)
			end)
		end
	end
end)

--[[------------------------------------------
		Load hooks and timers
]]--------------------------------------------

APG.updateHooks(mod)
APG.updateTimers(mod)
