--[[------------------------------------------

	============================
			NOTIFICATION MODULE
	============================

]]--------------------------------------------

local mod = "notification"

function APG.notification(msg, targets, notificationLevel, log) -- The most advanced notification function in the world.
	if not APG.modules["notification"] then return end
	if log then
		if type(targets) ~= "string" and IsValid(targets) then
			targets:PrintMessage(3, msg .. "\n")
		else
			print(msg)
		end
	end

	msg = string.Trim(tostring(msg))
	if type(notificationLevel) == "string" then
		notificationLevel = string.lower(notificationLevel)
		notificationLevel = notificationLevel == "notice" and 0 or notificationLevel == "warning" and 1 or notificationLevel == "alert" and 2
	end

	notificationLevel = notificationLevel or 0 -- Just incase there isn't a notification level.

	if IsEntity(targets) and IsValid(targets) and targets:IsPlayer() then
		targets = { targets }
	elseif type(targets) ~= "table" then -- Convert to a table.
		targets = string.lower(tostring(targets))
		if targets == "0" then
			targets = "disabled"
		elseif targets == "3" or targets == "superadmins" then
			local new_targets = {}
			for _, ply in next, player.GetHumans() do
				if not IsValid(ply) then continue end
				if not (ply:IsSuperAdmin()) then continue end
				table.insert(new_targets, ply)
			end
			targets = new_targets
		elseif targets == "2" or targets == "staff" then
			local new_targets = {}
			for _, ply in next, player.GetHumans() do
				if APG.cfg["notificationULibInheritance"].value and ulx then
					for k, y in pairs (APG.cfg["notificationRanks"].value) do
						if ply:CheckGroup(y) then
							table.insert(new_targets, ply)
						end
					end
				elseif ulx then
					if not IsValid(ply) then continue end
					for x, y in pairs (APG.cfg["notificationRanks"].value) do
						if ply:IsUserGroup(y) then
							table.insert(new_targets, ply)
						end
					end
				else
					if not IsValid(ply) then continue end
					if not ply:IsAdmin() then continue end
				end
			end
			targets = new_targets
		end
	elseif (targets == "1" or targets == "all" or targets == "everyone") then
		targets = player.GetHumans()
	end

	msg = (string.Trim(msg or "") ~= "") and msg or nil

	if msg and (notificationLevel >= 2) then
		ServerLog("[APG] " .. msg .. "\n")
	end

	if type(targets) ~= "table" then return false end

	for _,v in next, targets do
		if not IsValid(v) then continue end
		net.Start("apg_notice_s2c")
			net.WriteUInt(notificationLevel, 3)
			net.WriteString(msg)
		net.Send(v)
	end

	return true
end

-- really basic, just so I don't have to constantly look back at the gmod server console
function APG.log(msg)
	if not APG.cfg["developerLog"].value then return end
	MsgAll(msg .. "\n")
end
