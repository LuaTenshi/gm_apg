--[[------------------------------------------
			INITIALIZE APG
]]--------------------------------------------
APG = {}
APG.modules =  APG.modules or {}
--[[------------------------------------------
			CLIENT related
]]--------------------------------------------
AddCSLuaFile("apg/sh_config.lua")
AddCSLuaFile("apg/cl_utils.lua")
AddCSLuaFile("apg/cl_menu.lua")

--[[------------------------------------------
			REGISTER Modules
]]--------------------------------------------
local modules, _ = file.Find("apg/modules/*.lua","LUA")
for _,v in next, modules do
	if v then
		niceName = string.gsub(tostring(v),"%.lua","")
		APG.modules[ niceName ] = false
		APG[ niceName ] = { hooks = {}, timers = {}}
	end
end

function APG.hookRegister( module, event, identifier, func )
	table.insert( APG[ module ][ "hooks"], { event = event, identifier = identifier, func = func })
end

function APG.timerRegister( module, identifier, delay, repetitions, func )
	table.insert( APG[ module ][ "timers"], { identifier = identifier, delay = delay, repetitions = repetitions, func = func } )
end

function APG.load( module )
	APG.unLoad( module )
	APG.modules[ module ] = true
	include( "apg/modules/" .. module .. ".lua" )
	print("[APG] " .. module .. " loaded.")
end

function APG.unLoad( module )
	APG.modules[module] = false

	if not (istable(APG[module]) and next(APG[module])) then return end

	local hooks = APG[ module ]["hooks"]
	for k, v in next, hooks do
		hook.Remove(v.event, v.identifier)
	end

	local timers = APG[ module ]["timers"]
	for k, v in next, timers do
		timer.Remove(v.identifier)
	end

	print("[APG] " .. module .. " unloaded.")

end

function APG.reload( )
	for k, v in next, APG.modules do
		if APG.modules[k] == true then
			APG.load( k )
		else
			APG.unLoad( k )
		end
	end
end
--[[------------------------------------------
			LOADING
]]--------------------------------------------
-- Loading config first
include( "apg/sh_config.lua" )
-- Loading APG main functions
include( "apg/sv_apg.lua") -- Modules loaded at the bottom
-- Loading APG menu
include( "apg/sv_menu.lua" )

--[[------------------------------------------
			CVars INIT
]]--------------------------------------------

concommand.Add("apg_set", function( ply, cmd, args, argStr )
	if not ply:IsSuperAdmin() then return end

	if args[1] == "module" then
		local _module = APG.modules[ args[2] ]
		if _module != nil then
			if _module == true then
				APG.unLoad( args[2] )
				APG.log( "[APG] Module " .. args[2] .. " disabled.", ply)
			else
				APG.load( args[2] )
				APG.log( "[APG] Module " .. args[2] .. " enabled.", ply)
			end
		else
			APG.log( "[APG] This module does not exist", ply)
		end

	elseif args[1] == "help" then
		local cfg = APG.cfg[ args[2] ]
		if cfg then
			APG.log( cfg.desc, ply)
		else
			APG.log( "[APG] Help: This setting does not exist", ply)
		end
	else
		APG.log( ply, "Error: unknown setting")
	end
end)
