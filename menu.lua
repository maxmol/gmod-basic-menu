local favourite_maps = {
	'gm_construct',
}

local btns = {
	{'PLAY', function()
		local sortedMaps = {}
		local mapFiles = file.Find('maps/*.bsp', 'GAME')
		for k, v in ipairs(mapFiles) do
			local name = string.lower(string.gsub(v, '%.bsp$', ''))
			local prefix = string.match(name, '^(.-_)')
			sortedMaps[prefix] = sortedMaps[prefix] or {}
			table.insert(sortedMaps[prefix], name)
		end
		
		local menu = DermaMenu()

		for i, map in ipairs(favourite_maps) do
			menu:AddOption(map, function()
				RunConsoleCommand('progress_enable')
				RunConsoleCommand('map', map)
			end):SetIcon('icon16/star.png')
		end

		menu:AddSpacer()

		for prefix, maps in pairs(sortedMaps) do
			local submenu = menu:AddSubMenu(prefix)
			for i, map in ipairs(maps) do
				submenu:AddOption(map, function()
					RunConsoleCommand('progress_enable')
					RunConsoleCommand('map', map)
				end)
			end
		end

		menu:AddSpacer()

		RunConsoleCommand('maxplayers', 1)
		menu:AddOption('Multiplayer', function(self)
			self.enabled = not self.enabled
			self:SetIcon(self.enabled and 'icon16/accept.png' or false)

			RunConsoleCommand('maxplayers', self.enabled and 128 or 1)

			self.m_MenuClicking = false
		end)

		menu:Open()
	end},
	{'SERVERS', 'OpenServerBrowser'},
	{'OPTIONS', 'OpenOptionsDialog'},
	{'DISCONNECT', 'engine disconnect'},
	{'QUIT', 'Quit'}
}

CreateMenu = function()
	vgui.GetWorldPanel():Clear()

	local runCommand = function(self)
		RunGameUICommand(self.cmd)
	end

	local paint = function(self, w, h)
		surface.SetDrawColor(80, 80, 80, self:IsHovered() and 220 or 192)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0)
		surface.DrawOutlinedRect(0, 0, w, h)

		local clr

		if self:IsDown() then
			clr = Color(255, 255, 255)
		elseif self:IsHovered() then
			clr = Color(128, 192, 220)
		else
			clr = Color(220, 220, 220)
		end
		
		surface.SetFont('DermaDefaultBold')
		local tw, th = surface.GetTextSize(self:GetText())

		surface.SetTextPos((w-tw)/2, (h-th)/2)
		surface.SetTextColor(clr)
		surface.DrawText(self:GetText())
		
		return true
	end

	for i, t in ipairs(btns) do
		local b = vgui.Create('DButton')
		b:SetPos(32, 50 * i)
		b:SetSize(120, 40)
		b:SetText(t[1])
		
		if isstring(t[2]) then
			b.DoClick = runCommand
			b.cmd = t[2]
		else
			b.DoClick = t[2]
		end

		b.Paint = paint
	end
end

concommand.Add('menu_recreate', CreateMenu)
CreateMenu()

do -- LUA Errors
	local errors = {}
	local lastError = 0
	hook.Add('OnLuaError', 'MenuErrorHandler', function(str, realm, stack, addontitle, addonid)
		table.insert(errors, {SysTime() + 2, 20, 8, math.Rand(1, 10), math.Rand(-0.2, 0.2)})
		lastError = SysTime() + 2
	end)

	hook.Add('DrawOverlay', 'MenuDrawLuaErrors', function()
		if #errors > 0 then
			if errors[#errors][1] < SysTime() then
				table.remove(errors)
			end
			
			surface.SetFont('DermaDefaultBold')

			local delta = FrameTime() * 150
			for i, e in ipairs(errors) do
				e[4] = e[4] * 0.995
				e[2] = e[2] + e[4] * delta
				
				e[5] = e[5] * 0.99 + 0.03
				e[3] = e[3] + e[5] * delta

				surface.SetTextColor(230, 64, 32, (e[1] - SysTime()) * 255)
				surface.SetTextPos(e[2], e[3])
				surface.DrawText('LUA ERROR')
			end
			
			local tw, th = surface.GetTextSize('LUA ERROR')
			
			local val = 200 + math.sin(SysTime() * 20) * 128
			surface.SetDrawColor(255, val, 64, 255)
			surface.DrawRect(0, 0, tw + 16, th + 16)
			
			surface.SetDrawColor(70, 80, 90, 255)
			surface.DrawRect(4, 4, tw + 8, th + 8)
			
			surface.SetTextPos(8, 8)
			surface.SetTextColor(255, 0, 0, 255)
			surface.DrawText('LUA ERROR')

			if lastError < SysTime() then
				errors = {}
			end
		end
	end)
end