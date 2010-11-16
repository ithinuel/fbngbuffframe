-- A small (but complete) addon, that doesn't do anything.
local mod = LibStub("AceAddon-3.0"):NewAddon("fbngBuffFrame", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("fbngBuffFrame");

fbngBuffFrame = mod

-- creer 3 frames :
-- 1 pour les buffs
-- 1 pour les debuffs
-- 1 pour les enchant d'armes (à voir pe dans les buffs)

-- 1 frame : y lignes de x éléments
-- 1 élément : cadre
--	barre verticale "jauge" du temps
--	icon du buff/debuff
--	text : nb stack
-- 	text : timer restant

local defaults = {
	profile = {
		showblizz = false,
		buffs = {
			n_by_row = 10,
			max_display = BUFF_MAX_DISPLAY,
			
			status_bar_width = 3,
			icon_size = 20,
			count_size = 13,
			timer_size = 10,
			padding = 3,
			
			colors = {
				high = { r = 0, g = 1, b = 0, a = 1 },
				med  = { r = 1, g = 1, b = 0, a = 1 },
				low  = { r = 1, g = 0, b = 0, a = 1 },
				none = { r = .5, g = 0, b = .5, a = 1 },
			},
			pos_x = UIParent:GetWidth()/2,
			pos_y = UIParent:GetHeight()/2,
			
			show_anchor = false,
		},
		debuffs = {
			n_by_row = 10,
			max_display = DEBUFF_MAX_DISPLAY,
			
			status_bar_width = 3,
			icon_size = 20,
			count_size = 13,
			timer_size = 10,
			padding = 3,
			
			colors = {
				high = { r = 1, g = 0, b = 0, a = 1 },
				med  = { r = 1, g = 1, b = 0, a = 1 },
				low  = { r = 0, g = 1, b = 0, a = 1 },
				none = { r = .5, g = 0, b = .5, a = 1 },
			},
			pos_x = UIParent:GetWidth()/2,
			pos_y = UIParent:GetHeight()/2,
			
			show_anchor = false,
		},
		wench = {
			--n_by_row = 10,
			--max_display = 3,
			
			status_bar_width = 3,
			icon_size = 20,
			count_size = 13,
			timer_size = 10,
			padding = 3,
			
			colors = {
				high = { r = 0, g = 1, b = 0, a = 1 },
				med  = { r = 1, g = 1, b = 0, a = 1 },
				low  = { r = 1, g = 0, b = 0, a = 1 },
				none = { r = .5, g = 0, b = .5, a = 1 },
			},
			pos_x = UIParent:GetWidth()/2,
			pos_y = UIParent:GetHeight()/2,
			
			show_anchor = false,
		},
	}
}

local MenuOptions = {
	name = "fbngBuffFrame",
	type = "group",
	handler = mod,
	get = "OptionsGet",
	set = "OptionsSet",
	args = {
		showblizz = {
			name = L["Show Blizzard Frame"],
			type = "toggle",
			order = 0,
		},
	},
}

local DebuffTypeColor = { };
DebuffTypeColor["none"]		= { r = 0, g = 0, b = 0, a = 0.7 };
DebuffTypeColor["Magic"]	= { r = 0.20, g = 0.60, b = 1.00, a = 1 };
DebuffTypeColor["Curse"]	= { r = 0.60, g = 0.00, b = 1.00, a = 1 };
DebuffTypeColor["Disease"]	= { r = 0.60, g = 0.40, b = 0, a = 1 };
DebuffTypeColor["Poison"]	= { r = 0.00, g = 0.60, b = 0, a = 1 };
DebuffTypeColor[""]		= DebuffTypeColor["none"];

mod.buffs_anchor = nil
mod.buffs = {}
mod.debuffs_anchor = nil
mod.debuffs = {}
mod.wench = {}
mod.wench_anchor = nil

function mod:OnInitialize()
	-- do init tasks here, like loading the Saved Variables, 
	-- or setting up slash commands.
	self:RegisterChatCommand("fbf", "CommandParser")
	
	MenuOptions.args["buffs"] = self:GetBarOptions(L["Buffs"], BUFF_MAX_DISPLAY)
	MenuOptions.args["debuffs"] = self:GetBarOptions(L["Debuffs"], DEBUFF_MAX_DISPLAY)
	MenuOptions.args["wench"] = self:GetBarOptions(L["Wench"], NUM_TEMP_ENCHANT_FRAMES, true)
	
	self.db = LibStub("AceDB-3.0"):New("fBFDB", defaults, true)
  	MenuOptions.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
	
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("fBF", MenuOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("fBF", "fbngBuffFrame")
	
	--LibStub("AceConfig-3.0"):RegisterOptionsTable("fBF-Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	--self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("fBF-Profiles", "Profiles", "fBF")
end

function mod:OptionsGet(info)
	return self.db.profile[info[#info]] or defaults.profile[info[#info]]
end
function mod:OptionsSet(info, value)
	self.db.profile[info[#info]] = value or defaults.profile[info[#info]]
	self:UpdateConf()
end

function mod:ColorGetter (info)
	local bar = self.db.profile[info[1]]
	local r = bar.colors[info[#info]].r
	local g = bar.colors[info[#info]].g
	local b = bar.colors[info[#info]].b
	local a = bar.colors[info[#info]].a
	return r, g, b, a
end
function mod:ColorSetter (info, r, g, b, a) 
	local bar = self.db.profile[info[1]]
	bar.colors[info[#info]].r = r
	bar.colors[info[#info]].g = g
	bar.colors[info[#info]].b = b
	bar.colors[info[#info]].a = a
end

function mod:BuffOptionsGet(info)
	local v
	if info[#info] == "max_display" or info[#info] == "n_by_row" then
		v = self.db.profile[info[1]][info[#info]] or defaults.profile[info[1]][info[#info]]
	else
		v = string.format( "%i", self.db.profile[info[1]][info[#info]] or defaults.profile[info[1]][info[#info]])
	end
	return v
end
function mod:BuffOptionsSet(info, value)
	local v = math.floor( tonumber( value ) or 0 )
	if v <= 0 then v = defaults.profile[info[1]][info[#info]] end
	if self.db.profile[info[1]][info[#info]] ~= v then
		self.db.profile[info[1]][info[#info]] = v
		self:ArrangeBuffs(info[1])
	end
end

function mod:GetBarOptions(bar_name, bar_max, iswench)
	local barOpts = {
		name = bar_name,
		type = "group",
		order = 1,
		get = "BuffOptionsGet",
		set = "BuffOptionsSet",
		args = {
			show_anchor = {
				name = L["Show / Hide anchor"],
				type = "execute",
				order = 0,
				func = "ToggleAnchor",
			},
			buffs_display = {
				name = L["Display parameters"],
				type = "group",
				order = 3,
				inline = true,
				args = {
					icon_size = {
						name = L["Icon size"],
						type = "input",
						order = 0,
					},
					status_bar_width = {
						name = L["Status bar width"],
						type = "input",
						order = 1,
					},
					count_size = {
						name = L["Stack counter size"],
						type = "input",
						order = 2,
					},
					timer_size = {
						name = L["Left time font size"],
						type = "input",
						order = 3,
					},
					padding = {
						name = L["Padding between elements"],
						type = "input",
						order = 4,
					},
					colors = {
						type = 'group',
						name = L["Left time"],
						order = 5,
						get = "ColorGetter",
						set = "ColorSetter",
						guiInline  = true,
						args = {
							high = {
								type = 'color',
								name = L["High"],
								order = 1,
								hasAlpha = true,
							},
							med = {
								type = 'color',
								name = L["Med"],
								order = 2,
								hasAlpha = true,
							},
							low = {
								type = 'color',
								name = L["Low"],
								order = 3,
								hasAlpha = true,
							},
							none = {
								type = 'color',
								name = L["None"],
								order = 3,
								hasAlpha = true,
							},
						},
					},
				},
			},
		},
	}
	if iswench ~= true then
		barOpts.args.n_by_row = {
			name = L["Elements by line"],
			type = "range",
			order = 1,
			min = 1,
			max = bar_max,
			step = 1,
		}
		barOpts.args.max_display = {
			name = L["Maximum number of elements to show"],
			type = "range",
			order = 2,
			min = 1,
			max = bar_max,
			step = 1,
		}
	end
	return barOpts
end

function mod:ToggleAnchor(info, value)
	self.db.profile[info[1]].show_anchor = not self.db.profile[info[1]].show_anchor;
	if self.db.profile[info[1]].show_anchor then
		self[info[1] .. "_anchor"]:Show()
	else
		self[info[1] .. "_anchor"]:Hide()
	end
end

function mod:UpdateConf()
        if self.db.profile.showblizz then
		BuffFrame:RegisterEvent("UNIT_AURA")
		BuffFrame:Show()
		ConsolidatedBuffs:Show()
		TemporaryEnchantFrame:Show()
		BuffFrame_Update()
	else
            BuffFrame:Hide()
	    ConsolidatedBuffs:Hide()
            BuffFrame:UnregisterEvent("UNIT_AURA")
            TemporaryEnchantFrame:Hide()
        end
end

function mod:CommandParser()
	LibStub("AceConfigDialog-3.0"):Open("fBF");
end

function mod:OnEnable()
	-- Do more initialization here, that really enables the use of your addon.
	-- Register Events, Hook functions, Create Frames, Get information from 
	-- the game that wasn't available in OnInitialize
	self.buffs_anchor = self:CreateAnchor(self.db.profile.buffs)
	self.buffs_anchor:Hide()
	--
	self.debuffs_anchor = self:CreateAnchor(self.db.profile.debuffs)
	self.debuffs_anchor:Hide()
	--
	self.wench_anchor = self:CreateAnchor(self.db.profile.wench)
	self.wench_anchor:Hide()
	
	-- 
	for i=1, BUFF_MAX_DISPLAY do
		self.buffs[i] = self:CreateIcon("HELPFUL", i)
		self.buffs[i]:Show()
	end
	--
	for i=1, DEBUFF_MAX_DISPLAY do
		self.debuffs[i] = self:CreateIcon("HARMFUL", i)
		self.debuffs[i]:Show()
	end
	--
	for i=1, NUM_TEMP_ENCHANT_FRAMES do
		self.wench[i] = self:CreateIcon("Wench", i + 15)
	end
	
	self:ArrangeBuffs("buffs");
	self:ArrangeBuffs("debuffs");
	self:ArrangeBuffs("wench");
	
	self.lastTime = GetTime()
	self.OnUpdateStarted = self:ScheduleRepeatingTimer("OnUpdate", .125, self)
	
	self:RegisterEvent("UNIT_AURA")
	self:UNIT_AURA(nil, "player")
	
	self:UpdateConf()
end

function mod:CreateAnchor(pos_storage)
	local f = CreateFrame("Button",nil,UIParent)
	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	f:SetBackdropColor(0, 1, 0, 1)
	
	f:RegisterForDrag("LeftButton")
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(2)
	f:SetScript("OnMouseDown",function(self) self:StartMoving() end)
	f:SetScript("OnMouseUp",function(self)
		self:StopMovingOrSizing();
		local pos_x, pos_y = self:GetLeft(), self:GetTop()
		local s = self:GetEffectiveScale()
		pos_storage.pos_x = pos_x * s
		pos_storage.pos_y = pos_y * s
	end)

	f.SetPos = function(self, x, y )
		local s = self:GetEffectiveScale()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s , y / s) 
	end
	f:SetPos( pos_storage.pos_x, pos_storage.pos_y )
	return f
end
function mod:CreateIcon(filter, index)
	local f
	--if filter == "wench" then
	--	f = CreateFrame("Button", nil, UIParent)
	--else
		f = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
	--end
	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	local color = DebuffTypeColor["none"]
	f:SetBackdropColor(color.r, color.g, color.b, color.a)
	
	-- buff icon
	f.icon = f:CreateTexture(nil,"ARTWORK")
	f.icon:SetTexCoord(.07, .93, .07, .93)
	f.icon:SetPoint("TOP", 0, 0)
	f.icon:SetPoint("RIGHT", 0, 0)
	--f.icon:SetTexture(icon)

	-- stack count
	f.count  =  f:CreateFontString(nil, "OVERLAY")
	f.count:SetJustifyH("RIGHT")
	f.count:SetVertexColor(1,1,1)
	
	f.timer  =  f:CreateFontString(nil, "OVERLAY")
	f.timer:SetJustifyH("RIGHT")
	f.timer:SetJustifyV("BOTTOM")
	f.timer:SetVertexColor(1,1,1)
	f.timer:Show()
	
	f.bar = CreateFrame("StatusBar", nil, f)
	f.bar:SetStatusBarTexture[[Interface\AddOns\fbngBuffFrame\white.tga]]
	f.bar:SetOrientation("VERTICAL")
	--f.bar:SetStatusBarColor(1,0,0)
	f.bar:Show()
 
	f.bar.bg = f.bar:CreateTexture(nil,"BACKGROUND")
	f.bar.bg:SetTexture[[Interface\AddOns\fbngBuffFrame\white.tga]]
	f.bar.bg:SetAllPoints(f.bar)  
	--f.bar.bg:SetVertexColor(0.4,0,0)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel(2)
	
	f:EnableMouse(true)
	if filter == "HELPFUL" then
		f:RegisterForClicks("RightButtonUp")
		-- Setup stuff for clicking off buffs
		f:SetAttribute("type", "cancelaura" )
		f:SetAttribute("unit", "player")
		f:SetAttribute("index", index)
	elseif filter == "wench" then
		f:RegisterForClicks("RightButtonUp")
		-- Setup stuff for clicking off buffs
		f:SetAttribute("type", "click" )
		f:SetAttribute("clickbutton", "TempEnchant".. (index-15))	
	end
	
	f.id = index
	if filter == "Wench" then
		
		--f:RegisterForClicks("RightButtonUp")
		-- Setup stuff for clicking off buffs
		--f:SetScript("OnClick",function(self)
			--CancelItemTempEnchantment(self.id);   -- should be 1 for mh
		--end)
		--f:SetAttribute("unit", "player")
		--f:SetAttribute("index", index)
	
		f:SetScript("OnEnter",function(self)
			if self:GetAlpha() ~= 0 then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				GameTooltip:SetInventoryItem("player", self.id)
			end
		end)
	else
		f.filter = filter
		f:SetScript("OnEnter",function(self)
			--mod:Print(self.filter, " : " , self.id);
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
			GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2);
			GameTooltip:SetUnitAura("player", self.id, self.filter);
		end)
	end
	
	f:SetScript("OnLeave",function(self)
		GameTooltip:Hide();
	end)
	return f
end

function mod:OnUpdate()
	local curTime = GetTime()
	local elapsed = curTime - self.lastTime
	self.lastTime = curTime
	
	local buf_high = self.db.profile.buffs.colors.high
	local buf_med = self.db.profile.buffs.colors.med
	local buf_low = self.db.profile.buffs.colors.low
	local buf_none = self.db.profile.buffs.colors.none
	
	local debuf_high = self.db.profile.debuffs.colors.high
	local debuf_med = self.db.profile.debuffs.colors.med
	local debuf_low = self.db.profile.debuffs.colors.low
	local debuf_none = self.db.profile.debuffs.colors.none
	
	local wench_high = self.db.profile.wench.colors.high
	local wench_med = self.db.profile.wench.colors.med
	local wench_low = self.db.profile.wench.colors.low
	local wench_none = self.db.profile.wench.colors.none
	
	for i = 1, self.db.profile.buffs.max_display do
		local f = self.buffs[i]
		if f:GetAlpha() ~= 0 then
			local name, rank, icon, count, dispelType, duration, expires = UnitAura("player",i,"HELPFUL")
			self:UpdateButton(f, count, expires, duration, buf_high, buf_med, buf_low, buf_none)
		end
	end
	for i = 1, self.db.profile.debuffs.max_display do
		local f = self.debuffs[i]
		if f:GetAlpha() ~= 0 then
			local name, rank, icon, count, dispelType, duration, expires = UnitAura("player",i,"HARMFUL")
			self:UpdateButton(f, count, expires, duration, debuf_high, debuf_med, debuf_low, debuf_none)
		end
	end
	
	local	hasMainHandEnchant, mainHandExpiration, mainHandCharges, 
		hasOffHandEnchant, offHandExpiration, offHandCharges,
		hasThrownEnchant, thrownExpiration, thrownCharges = GetWeaponEnchantInfo();

	self:UpdateWench(self.wench[1], hasMainHandEnchant, mainHandExpiration, mainHandCharges, wench_high, wench_med, wench_low, wench_none);
	self:UpdateWench(self.wench[2], hasOffHandEnchant, offHandExpiration, offHandCharges, wench_high, wench_med, wench_low, wench_none);
	self:UpdateWench(self.wench[3], hasThrownEnchant, thrownExpiration, thrownCharges, wench_high, wench_med, wench_low, wench_none);

end
function mod:UpdateWench(f, hasEnchant, expiration, charges, color_high, color_med, color_low, color_none)

	if f.max == nil then f.max = 0 end
	if f.prev == nil then f.prev = 0 end

	if not hasEnchant then
		if f.max ~= 0 then f.max = 0 end
		if f.prev ~= 0 then f.prev = 0 end
		if f:GetAlpha() ~= 0 then
			f:SetAlpha(0)
			f:EnableMouse(false)
		end
		return
	end
	
	-- do stuff for wench
	if f.prev == expiration then
		return
	elseif f.prev < expiration then
		f.max = expiration
		f.prev = expiration
		f.bar:SetMinMaxValues(0,expiration)
	end
	
	if f:GetAlpha() == 0 then
		f:SetAlpha(1)
		f:EnableMouse(true)
	end
	
	f.prev = expiration
	f.bar:SetValue(expiration)
	
	f.icon:SetTexture(GetInventoryItemTexture("player", f.id))
	
	f.timer:SetFormattedText(SecondsToTimeAbbrev(f.prev/1000));
	
	local percent = (f.prev/f.max)
	if percent > .5 then
		local percent_scaled = (percent - .5) / .5
		r = (color_high.r * (percent_scaled)) + (color_med.r * (1-percent_scaled))
		g = (color_high.g * (percent_scaled)) + (color_med.g * (1-percent_scaled))
		b = (color_high.b * (percent_scaled)) + (color_med.b * (1-percent_scaled))
		a = (color_high.a * (percent_scaled)) + (color_med.a * (1-percent_scaled))
	else
		local percent_scaled = percent / .5
		r = (color_med.r * (percent_scaled)) + (color_low.r * (1-percent_scaled))
		g = (color_med.g * (percent_scaled)) + (color_low.g * (1-percent_scaled))
		b = (color_med.b * (percent_scaled)) + (color_low.b * (1-percent_scaled))
		a = (color_med.a * (percent_scaled)) + (color_low.a * (1-percent_scaled))
	end
	f.bar:SetStatusBarColor(r,g,b, a)
	f.bar.bg:SetVertexColor(r/2,g/2,b/2, a)
	
	if charges and charges > 1 then
		if not f.count:IsShown() then f.count:Show() end
		f.count:SetText(charges)
	elseif f.count:IsShown() then
		f.count:Hide()
	end
end
function mod:UpdateButton(f, count, expires, duration, color_high, color_med, color_low, color_none)
	local r, g, b, a
	if expires and expires ~= 0 then
		local left = expires-GetTime()
		if left > 0 then
			if not f.timer:IsShown() then f.timer:Show() end
			f.bar:SetValue(left)
			f.timer:SetFormattedText(SecondsToTimeAbbrev(left));
			
			--[[
			if left > duration/2 => high -> med
			high * 1-((duration-left)/(duration/2)) + 
			else med -> low
			--]]
			local percent = (left/duration)
			if percent > .5 then
				local percent_scaled = (percent - .5) / .5
				r = (color_high.r * (percent_scaled)) + (color_med.r * (1-percent_scaled))
				g = (color_high.g * (percent_scaled)) + (color_med.g * (1-percent_scaled))
				b = (color_high.b * (percent_scaled)) + (color_med.b * (1-percent_scaled))
				a = (color_high.a * (percent_scaled)) + (color_med.a * (1-percent_scaled))
			else
				local percent_scaled = percent / .5
				r = (color_med.r * (percent_scaled)) + (color_low.r * (1-percent_scaled))
				g = (color_med.g * (percent_scaled)) + (color_low.g * (1-percent_scaled))
				b = (color_med.b * (percent_scaled)) + (color_low.b * (1-percent_scaled))
				a = (color_med.a * (percent_scaled)) + (color_low.a * (1-percent_scaled))
			end
			
			f.bar:SetStatusBarColor(r,g,b, a)
			f.bar.bg:SetVertexColor(r/2,g/2,b/2, a)
		end
	else
		r = color_none.r
		g = color_none.g
		b = color_none.b
		a = color_none.a
		f.bar:SetValue(0)
		f.bar:SetMinMaxValues(0,1)
		f.bar:SetStatusBarColor(r,g,b, a)
		f.bar.bg:SetVertexColor(r/2,g/2,b/2, a)
		f.timer:Hide()
	end
	
	if count and count > 1 then
		if not f.count:IsShown() then f.count:Show() end
		f.count:SetText(count)
	elseif f.count:IsShown() then
		f.count:Hide()
	end
end

function mod:UNIT_AURA(event, unit)
	if unit ~= "player" then return end
	
	local name, rank, icon, count, debuffType, duration, expires
	for i=1, BUFF_MAX_DISPLAY do
		local f = self.buffs[i]
		
		name, rank, icon, count, debuffType, duration = UnitAura("player",i,"HELPFUL")
		self:OnUnitAura(f, name, duration, count, icon);
	end
	for i=1, DEBUFF_MAX_DISPLAY do
		local f = self.debuffs[i]
		
		name, rank, icon, count, debuffType, duration = UnitAura("player",i,"HARMFUL")
		
		self:OnUnitAura(f, name, duration, count, icon);
	
		local color
		if ( debuffType ) then
			color = DebuffTypeColor[debuffType];
		else
			color = DebuffTypeColor["none"];
		end
		f:SetBackdropColor(color.r, color.g, color.b, color.a)
	end
	self:OnUpdate()
end

function mod:OnUnitAura(f, name, duration, count, icon)
	if name == nil then
		if f:GetAlpha() == 1 then
			f:SetAlpha(0)
			--f:EnableMouse(false)
		end
	else
		if f:GetAlpha() ~= 1 then
			f:SetAlpha(1)
			--f:EnableMouse(true)
		end
		
		if duration and duration ~= 0 then
			f.bar:SetMinMaxValues(0,duration)
		else
			f.bar:SetValue(0)
			f.bar:SetMinMaxValues(0,1)
		end
		
		if count and count > 1 then
			f.count:Show()
		end
		f.icon:SetTexture(icon)
	end
end

function mod:ArrangeBuffs(bar)
	local max;
	local n_by_row;
	if bar == "wench" then
		max = NUM_TEMP_ENCHANT_FRAMES
		n_by_row = NUM_TEMP_ENCHANT_FRAMES
	else
		max = self.db.profile[bar].max_display
		n_by_row = self.db.profile[bar].n_by_row 
	end

	local prev = self[bar .. "_anchor"]
	
	local i_size = self.db.profile[bar].icon_size
	local c_size = self.db.profile[bar].count_size
	local t_size = self.db.profile[bar].timer_size
	local pad = self.db.profile[bar].padding
	local sb_width = self.db.profile[bar].status_bar_width
	local bar_width = pad + sb_width + pad + i_size + pad
	local bar_height = pad + i_size + pad
	
	prev:SetWidth(bar_width)
	prev:SetHeight(bar_height)
		
	for i = 1, max do
		local b = self[bar][i]
		local step_y = 0
		local step_x = -bar_width
		if (i % n_by_row) == 1 then
			prev = self[bar .. "_anchor"]
			step_y = -(bar_height + pad + t_size + pad)* ((i-1) / n_by_row)
		end
		b:SetWidth(bar_width)
		b:SetHeight(bar_height)
				
		b.icon:SetWidth(i_size)
		b.icon:SetHeight(i_size)
		b.icon:ClearAllPoints()
		b.icon:SetPoint("TOP", b, "TOP", 0, -pad)
		b.icon:SetPoint("RIGHT", b, "RIGHT", -pad, 0)
		
		b.count:SetPoint("BOTTOMRIGHT",b.icon,"BOTTOMRIGHT",pad,pad)
		b.count:SetFont("Fonts\\FRIZQT__.TTF", c_size ,"OUTLINE")
		
		b.timer:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",pad,-(pad+t_size))
		b.timer:SetFont("Fonts\\FRIZQT__.TTF", t_size ,"OUTLINE")
		
		b.bar:SetWidth(sb_width)
		b.bar:SetHeight(i_size)
		b.bar:SetPoint("TOPLEFT",b,"TOPLEFT", pad, -pad)

		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", prev, "TOPLEFT", step_x, step_y)
		prev = b
	end
end

function mod:OnDisable()
	-- Unhook, Unregister Events, Hide frames that you created.
	-- You would probably only use an OnDisable if you want to 
	-- build a "standby" mode, or be able to toggle modules on/off.
end
