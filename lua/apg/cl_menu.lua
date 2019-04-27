--[[------------------------------------------

	A.P.G. - a lightweight Anti Prop Griefing solution (v{{ script_version_name }})
	Made by :
	- While True (http://steamcommunity.com/id/76561197972967270)
	- LuaTenshi (http://steamcommunity.com/id/76561198096713277)

	Licensed to : http://steamcommunity.com/id/{{ user_id }}

]]--------------------------------------------
APG_panels = APG_panels or {}

local utils = include( "cl_utils.lua" ) or { }

local function showNotice(notificationLevel, notificationMessage)
	if string.Trim(notificationMessage) == "" then return end
	icon = notificationLevel == 0 and NOTIFY_GENERIC or notificationLevel == 1 and NOTIFY_CLEANUP or notificationLevel == 2 and NOTIFY_ERROR

	notification.AddLegacy(notificationMessage, icon, 3 + (notificationLevel * 3))

	if APG.cfg[ "notificationSounds" ].value then
		surface.PlaySound(notificationLevel == 1 and "buttons/button10.wav" or notificationLevel == 2 and "ambient/alarms/klaxon1.wav" or "buttons/lightswitch2.wav") -- Maybe let the player choose the sound?
	end

	MsgC( notificationLevel == 0 and Color( 0, 255, 0 ) or Color( 255, 191, 0 ), "[APG] ", Color( 255, 255, 255 ), notificationMessage,"\n")
end

net.Receive( "apg_notice_s2c", function()
  local notificationLevel = net.ReadUInt( 3 )
  local notificationMessage = net.ReadString()
  showNotice(notificationLevel, notificationMessage)
end)

local function APGBuildStackPanel()
	local panel = APG_panels[ "stack_detection" ]
	panel.Paint = function( i, w, h ) end

	utils.numSlider( panel, 0, 40, 500, 20, "Maximum stacked ents", "stackMax", 3, 50, 0 )
	utils.numSlider( panel, 0, 75, 500, 20, "Stack distance (gmod units)", "stackArea", 5, 50, 0 )
end

local function APGBuildMiscPanel()
	local panel = APG_panels[ "misc" ]
	panel.Paint = function( i, w, h ) end

	utils.switch( panel, 0, 40, 395, 20, "Auto freeze over time", "autoFreeze" )
	utils.numSlider( panel, 0, 70, 500, 20, "Auto freeze delay(seconds)", "autoFreezeTime", 5, 600, 0 )
	utils.switch( panel, 0, 100, 395, 20, "Disable vehicle damages", "vehDamage" )
	utils.switch( panel, 0, 130, 395, 20, "Disable vehicle collisions (with players)", "vehNoCollide" )
	utils.switch( panel, 0, 160, 395, 20, "Block Physgun Reload", "blockPhysgunReload" )
	utils.switch( panel, 0, 190, 395, 20, "Block players from moving contraptions", "blockContraptionMove" )
end

local function APGBuildLagPanel()
	local panel = APG_panels[ "lag_detection" ]
	panel.Paint = function( i, w, h ) end

	utils.numSlider( panel, 0, 40, 500, 20, "Lag threshold (%)", "lagTrigger", 5, 200, 0 )
	utils.numSlider( panel, 0, 75, 500, 20, "Frames lost", "lagsCount", 1, 20, 0 )
	utils.numSlider( panel, 0, 110, 500, 20, "Heavy lag trigger (seconds)", "bigLag", 1, 5, 1 )
	utils.comboBox( panel, 0, 145, 500, 20, "Lag fix function", "lagFunc", APG_lagFuncs )
	utils.numSlider( panel, 0, 180, 500, 20, "Lag func. delay (seconds)", "lagFuncTime", 1, 300, 0 )
end

local function APGBuildNotificationPanel()
	local panel = APG_panels[ "notification" ]
	panel.Paint = function( i, w, h ) end

	utils.switch( panel, 0, 40, 395, 20, "Notification Sounds", "notificationSounds" )
	utils.numSlider( panel, 0, 75, 500, 20, "Notification Level", "notificationLevel", 1, 3, 0 )
	utils.switch( panel, 0, 110, 395, 20, "Do you want to show which lag function ran?", "notificationLagFunc" )
end

local function APGBuildToolHackPanel()
	local panel = APG_panels[ "misc2" ]
	panel.Paint = function( i, w, h ) end

	utils.switch( panel, 0, 40, 395, 20, "Inject custom hooks into Fading Doors", "thFadingDoors" )
	utils.switch( panel, 0, 75, 395, 20, "Activate FRZR9K (Sleepy Physics)", "sleepyPhys" )
	utils.switch( panel, 0, 110, 395, 20, "Hook FRZR9K into collision (Experimental)", "hookSP" )
	utils.switch( panel, 0, 145, 395, 20, "Allow prop killing", "allowPK" )
end

local function APGBuildGhostPanel()
	local panel = APG_panels[ "ghosting" ]
	panel.Paint = function( i, w, h)
		draw.RoundedBox( 0, 0, 37, 170, 135, Color( 38, 38, 38, 255 ) )
		draw.DrawText( "Ghosting color:", "APG_element_font", 5, 37, Color( 189, 189, 189 ), 3 )

		draw.RoundedBox( 0, 175, 37, 250, 250, Color( 38, 38, 38, 255) )
		draw.DrawText( "Bad entities:", "APG_element_font", 180, 37, Color( 189, 189, 189), 3 )
		draw.DrawText( "(Right-Click to Toggle)", "APG_title2_font", 280, 38, Color( 189, 189, 189), 3 )
	end
	utils.switch( panel, 0, 180, 170, 20, "Always frozen", "alwaysFrozen" )
	utils.switch( panel, 0, 215, 170, 20, "Apply to doors", "fadingDoorGhosting" )
	utils.switch( panel, 0, 250, 170, 20, "Ignore Vehicles", "dontGhostVehicles" )

	local Mixer = vgui.Create( "CtrlColor", panel )
	Mixer:SetPos( 5, 55 )
	Mixer:SetSize( 160, 110 )
	Mixer.Mixer.ValueChanged = function( self, color )
		APG.cfg[ "ghost_color" ].value = Color( color.r, color.g, color.b, color.a)
	end

	local dList = vgui.Create( "DListView", panel )
	dList:Clear()
	dList:SetPos( 180, 55 )
	dList:SetSize( panel:GetWide() - 185, panel:GetTall() - 5 - 55 )
	dList:SetMultiSelect( false )
	dList:SetHideHeaders( false )
	dList:AddColumn( "Class" )
	dList:AddColumn( "Exact" )

	function dList:OnRowRightClick( id, line )
		local key = line:GetColumnText(1)
		local value = not tobool(line:GetColumnText(2))
		line:SetColumnText( 2, value )
		APG.cfg[ "bad_ents" ].value[key] = value
	end

	local function updateTab()
		dList:Clear()
		for class,complete in pairs(APG.cfg[ "bad_ents" ].value) do
			dList:AddLine(class, complete)
		end
	end
	updateTab()

	dList.Paint = function(i,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 150, 150, 150, 255 ) )
	end
	dList.VBar.Paint = function(i,w,h)
		surface.SetDrawColor( 88, 110, 110, 240 )
		surface.DrawRect( 0, 0, w, h )
	end
	dList.VBar.btnGrip.Paint = function(i,w,h)
		surface.SetDrawColor( 255, 83, 13, 50 )
		surface.DrawRect( 0, 0, w, h )
		draw.RoundedBox( 0, 1, 1, w - 2, h - 2, Color( 72, 89, 89, 255 ) )
	end
	dList.VBar.btnUp.Paint = function(i,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 72, 89, 89, 240 ) )
	end
	dList.VBar.btnDown.Paint = function(i,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 72, 89, 89, 240 ) )
	end

	local TextEntry = vgui.Create( "DTextEntry", panel )
	TextEntry:SetPos( 180, 240 )
	TextEntry:SetSize( 150,20 )
	TextEntry:SetText( "Entity class" )
	TextEntry.OnEnter = function( self )
		chat.AddText( self:GetValue() )
	end

	local Add = vgui.Create( "DButton" , panel)
	Add:SetPos( 320, 240 )
	Add:SetSize( 75,20 )
	Add:SetText( "Add" )
	Add.DoClick = function()
		if TextEntry:GetValue() == "Entity class" then return end
		utils.addBadEntity( TextEntry:GetValue() )
		updateTab()
	end

	Add:SetTextColor( Color(255, 255, 255) )
	Add.Paint = function( i, w, h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 44, 55, 55, 240 ) )
		draw.RoundedBox( 0, 1, 1, w-2, h-2, Color( 58, 58, 58, 255 ) )
	end

	local Remove = vgui.Create( "DButton" , panel)
	Remove:SetPos( 180, 260 )
	Remove:SetSize( 215, 20 )
	Remove:SetText( "Remove selected" )
	Remove.DoClick = function()
		for k,v in pairs(dList:GetSelected()) do
			local key = v:GetValue(1)
			APG.cfg[ "bad_ents" ].value[key] = nil
			updateTab()
		end
	end

	Remove:SetTextColor( Color( 255, 255, 255 ) )
	Remove.Paint = function( i, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 58, 58, 58, 255 ) )
		draw.RoundedBox( 0, 0, 0, w, 1, Color( 30, 30, 30, 125 ) )
	end
end


local main_color = Color( 32, 255, 0, 255 )
local function openMenu( len )
	len = net.ReadUInt( 32 )
	if len == 0 then return end
	local settings = net.ReadData( len )
	settings = util.Decompress( settings )
	settings = util.JSONToTable( settings )

	APG.cfg = settings.cfg
	table.Merge(APG, settings)

	local APG_Main = vgui.Create( "DFrame" )
		APG_Main:SetSize( 550 , 320)
		APG_Main:SetPos( ScrW() / 2 - APG_Main:GetWide() / 2, ScrH() / 2 - APG_Main:GetTall() / 2)
		APG_Main:SetTitle( "" )
		APG_Main:SetVisible( true )
		APG_Main:SetDraggable( true )
		APG_Main:MakePopup()
		APG_Main:ShowCloseButton( false )
		APG_Main.Paint = function( i, w, h )
			draw.RoundedBox( 4, 0, 0, w, h, Color( 34, 34, 34, 255 ) )
			draw.RoundedBox( 0, 0, 23, w, 1, main_color)
			draw.DrawText( "A.P.G. - Anti Prop Griefing Solution", "APG_title_font", 8, 5, Color( 189, 189, 189), 3 )
		end
	local closeButton = vgui.Create( "DButton",APG_Main )
		closeButton:SetPos( APG_Main:GetWide() - 20, 4 )
		closeButton:SetSize( 16, 16 )
		closeButton:SetText('')
		closeButton.DoClick = function()
			APG_Main:Remove()
		end
		closeButton.Paint = function(i,w,h)
			draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255,3 ) )
			draw.DrawText( "✕", "APG_sideBar_font", 0, -2, Color( 189, 189, 189 ), 3 )
		end
	local saveButton = vgui.Create( "DButton", APG_Main )
	saveButton:SetPos( APG_Main:GetWide() - 96,4)
	saveButton:SetSize( 72, 16 )
	saveButton:SetText('')
	saveButton.DoClick = function()
		local settings = APG
		settings = util.TableToJSON( settings )
		settings = util.Compress( settings )
		net.Start( "apg_settings_c2s")
			net.WriteUInt( settings:len(), 32 ) -- Write the length of the data (up to {{ user_id | 76561197972967270 }})
			net.WriteData( settings, settings:len() ) -- Write the data
		net.SendToServer()
		showNotice(1, "APG Settings saved!")

	end
	saveButton.Paint = function( i, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 3) )
		draw.DrawText( "Save settings", "APG_title2_font", w / 2, 1, Color( 189, 189, 189 ), 1 )
	end

	-- Side bar
	local sidebar = vgui.Create( "DPanel", APG_Main )
	sidebar:SetSize( APG_Main:GetWide() / 4 , APG_Main:GetTall() - 35)
	sidebar:SetPos( 0, 30 )
	sidebar.Paint = function( i, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 33, 33, 33,255 ) )
		draw.RoundedBox( 0, w-1, 0, 1, h, main_color)
	end

	local x, y = APG_Main:GetWide() - 150, APG_Main:GetTall() - 35
	local px, py = 145, 30
	local first = true
	for k, v in next, APG.modules do
		local panel = vgui.Create( "DPanel", APG_Main )
		panel:SetSize( x, y )
		panel:SetPos( px, py )
		panel:SetVisible( first )
		panel.Paint = function() end
		APG_panels[k] = panel
		first = false

		local button = vgui.Create( "DButton", panel )
		button:SetPos( 0, 0 )
		button:SetSize( panel:GetWide(), 35 )
		button:SetText("")
		button.UpdateColours = function( label, skin )
			label:SetTextStyleColor( Color( 189, 189, 189 ) )
		end
		button.Paint = function( slf, w, h )
			local enabled = APG.modules[k]

			draw.RoundedBox( 0, 0, h * 0.85, w-5, 1, Color(0, 96, 0, 255) )
			local text = utils.getNiceName(k) .. " module "
			draw.DrawText( text, "APG_mainPanel_font", 5, 8, Color( 189, 189, 189 ), 3 )
			utils.mainSwitch( w - 48, 7.5, enabled )
		end
		button.DoClick = function()
			APG.modules[k] = not APG.modules[k]
		end
	end

	local i = 0
	local height = ( sidebar:GetTall() - 20 ) / table.Count( APG.modules )
	for k,v in next , APG.modules do
		local button = vgui.Create( "DButton", sidebar )
		button:SetPos( 5, (height + 5) * i)
		button:SetSize( sidebar:GetWide() - 10 , height )
		button:SetText("")
		button.DoClick = function()
			for l,m in next, APG_panels do
				if k ~= l then
					APG_panels[l]:SetVisible( false )
				else
					APG_panels[l]:SetVisible( true )
				end
			end
		end
		local size = sidebar:GetWide()
		button.Paint = function( _, w, h )
			local name = utils.getNiceName( k )
			if button.Hovered then
				draw.RoundedBox( 5, 0, 0, w, h, Color( 46, 46, 46,255 ) )
				draw.RoundedBox( 0, 2, 2, w - 4, h - 4, Color( 36, 36,36, 255 ) )
			end
			if APG_panels[k]:IsVisible()  then
				draw.RoundedBox( 0, 0, 0, w, h, Color( 36, 36,36, 255 ) )
				draw.RoundedBox( 0, w * 0.15, h * 0.72, w * 0.7, 1, Color(0, 96, 0, 255 ) )
			end

			draw.DrawText( name, "APG_sideBar_font", ( size - name:len() ) / 2, h * 0.35, Color( 189, 189, 189 ), 1)
		end
		i = i + 1
	end
	APGBuildMiscPanel()
	APGBuildGhostPanel()
	APGBuildLagPanel()
	APGBuildStackPanel()
	APGBuildNotificationPanel()
	APGBuildToolHackPanel()
end

net.Receive( "apg_menu_s2c", openMenu )

properties.Add( "apgoptions", {
	MenuLabel = "APG Options", -- Name to display on the context menu
	Order = 9999, -- The order to display this property relative to other properties
	MenuIcon = "icon16/fire.png", -- The icon to display next to the property

	Filter = function( self, ent, ply ) -- A function that determines whether an entity is valid for this property
		if not ply:IsSuperAdmin() then return false end
		if not IsValid(ent) then return false end
		if not ent:GetClass() then return false end
		if not (ent:EntIndex() > 0) then return false end

		return true
	end,
	MenuOpen = function( self, option, ent, tr )
		local submenu = option:AddSubMenu()
		local function addoption( str, data )
			local menu = submenu:AddOption( str, data.callback )

			if data.icon then
				menu:SetImage( data.icon )
			end

			return menu
		end

		addoption( "Sleep entities of this Class", {
			icon = "icon16/clock.png",
			callback = function() self:APGcmd( ent, "sleepclass" ) end,
		})

		addoption( "Freeze entities of this Class", {
			icon = "icon16/bell_delete.png",
			callback = function() self:APGcmd( ent, "freezeclass" ) end,
		})

		submenu:AddSpacer()

		addoption( "Cleanup Owner - Unfrozens", {
			icon = "icon16/cog_delete.png",
			callback = function() self:APGcmd( ent, "clearunfrozen" ) end,
		})

		addoption( "Cleanup Owner", {
			icon = "icon16/bin_closed.png",
			callback = function() self:APGcmd( ent, "clearowner" ) end,
		})

		submenu:AddSpacer()

		addoption( "Get Owner SteamID", {
			icon = "icon16/user.png",
			callback = function() self:APGcmd( ent, "getownerid" ) end,
		})

		addoption( "Get Owner Entity Count", {
			icon = "icon16/brick.png",
			callback = function() self:APGcmd( ent, "getownercount" ) end,
		})

		submenu:AddSpacer()

		addoption( "Add this entity class to the Ghosting List", {
			icon = "icon16/cross.png",
			callback = function() self:APGcmd( ent, "addghost" ) end,
		})

		addoption( "Remove this entity class from the Ghosting List", {
			icon = "icon16/tick.png",
			callback = function() self:APGcmd( ent, "remghost" ) end,
		})
	end,
	Action = function( self, ent ) end,
	APGcmd = function( self, ent, cmd )
		if cmd == "getownerid" then
			local owner, _ = ent:CPPIGetOwner()
			if IsValid( owner ) and owner.SteamID() then
				local id = tostring( owner:SteamID() )
				SetClipboardText( id )
				chat.AddText( Color( 0, 255, 0 ), "\n\"" .. id .. "\" has been copied to your clipboard.\n")
			else
			   chat.AddText( Color( 255, 0, 0 ), "\nOops, that's not a Player!\n")
			end
		elseif IsValid( ent ) and ent.EntIndex() then
			net.Start( "apg_context_c2s" )
				net.WriteString( cmd )
				net.WriteEntity( ent)
			net.SendToServer()
		end
	end,
})
