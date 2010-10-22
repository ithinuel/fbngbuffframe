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
			n_by_row = 20,
			max_display = 32,
			icon_size = 20,
			status_bar_width = 6,
			count_size = 13,
			padding = 2,
			timer_size = 8,
			pos = {
				point = "TOPRIGHT",
				x = 0,
				y = 0,
			}
		}
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
			name = L["Afficher l'interface de Blizzard"],
			type = "toggle",
			order = 0,
		},
		
		buffs = {
			name = L["Buffs"],
			type = "group",
			order = 1,
			handler = mod,
			get = "BuffOptionsGet",
			set = "BuffOptionsSet",
			args = {
				show_anchor = {
					name = L["Montrer / Cacher l'ancre"],
					type = "execute",
					order = 0,
					func = "ToggleAnchor",
				},
				n_by_row = {
					name = L["Nombre de buff par ligne"],
					type = "range",
					order = 1,
					min = 1,
					max = 40,
					step = 1,
				},
				max_display = {
					name = L["Nombre maximal de buff a afficher"],
					type = "range",
					order = 2,
					min = 1,
					max = 40,
					step = 1,
				},
				buffs_display = {
					name = L["Parametre d'affichage"],
					type = "group",
					order = 3,
					inline = true,
					args = {
						icon_size = {
							name = L["Taille de l'icone"],
							type = "input",
							order = 0,
						},
						status_bar_width = {
							name = L["Largeur du sablier"],
							type = "input",
							order = 1,
						},
						count_size = {
							name = L["Taille du compteur de pile"],
							type = "input",
							order = 2,
						},
						timer_size = {
							name = L["Taille du temps restant"],
							type = "input",
							order = 3,
						},
						padding = {
							name = L["Espacement entre les elements"],
							type = "input",
							order = 4,
						},
					}
				},
			},
		},
	},
}


mod.buff_anchor = nil
mod.buffs = {}
mod.debuff_anchor = nil
mod.wench_frame = nil

function mod:OnInitialize()
	-- do init tasks here, like loading the Saved Variables, 
	-- or setting up slash commands.
	self:Print("mod:OnInitialise")
	self:RegisterChatCommand("fbf", "CommandParser")
	
	self.db = LibStub("AceDB-3.0"):New("fBFDB", defaults, true)
  	--MenuOptions.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
	
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("fBF", MenuOptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("fBF", "fbngBuffFrame")
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("fBF-Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("fBF-Profiles", "Profiles", "fBF")
end

function mod:OptionsGet(info)
	return self.db.profile[info[#info]]
end
function mod:OptionsSet(info, value)
	self.db.profile[info[#info]] = value
	self:UpdateConf()
	self:ArrangeBuffs()
end

function mod:BuffOptionsGet(info)
	return self.db.profile.buffs[info[#info]]
end
function mod:BuffOptionsSet(info, value)
	self.db.profile.buffs[info[#info]] = value
	self:ArrangeBuffs()
end

function mod:ToggleAnchor(info, value)
	if self.buff_anchor:IsShown() then
		mod.buff_anchor:Hide()
	else
		self.buff_anchor:Show()
	end
end

function mod:UpdateConf()
        if self.db.profile.showblizz then
		if not BuffFrame:IsShown() then
			BuffFrame:Show()
			BuffFrame:RegisterEvent("UNIT_AURA")
		end
	else
            BuffFrame:Hide()
            --TemporaryEnchantFrame:Hide()
            BuffFrame:UnregisterEvent("UNIT_AURA")
        end
end

function mod:CommandParser()
	LibStub("AceConfigDialog-3.0"):Open("fBF");
end

function mod:OnEnable()
	-- Do more initialization here, that really enables the use of your addon.
	-- Register Events, Hook functions, Create Frames, Get information from 
	-- the game that wasn't available in OnInitialize
	
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
	f:SetScript("OnDragStart",function(self) self:StartMoving() end)
	f:SetScript("OnDragStop",function(self)
		self:StopMovingOrSizing();
		_,_, mod.db.profile.buffs.pos.point, mod.db.profile.buffs.pos.x, mod.db.profile.buffs.pos.y = self:GetPoint(1)
	end)

	f.SetPos = function(self,point, x, y )
		 self:ClearAllPoints()
		 self:SetPoint(point, UIParent, point, x, y) 
	end
	f:SetPos(self.db.profile.buffs.pos.point, self.db.profile.buffs.pos.x, self.db.profile.buffs.pos.y )
	
	self.buff_anchor = f;
	self.buff_anchor:Hide()
	
	-- 
	local prev = self.buff_anchor
	for i=1, BUFF_MAX_DISPLAY do
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("player",i,"HELPFUL")
	
		f = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
		f:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 0,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		})
		f:SetBackdropColor(0, 0, 0, 0.7)
		
		-- buff icon
		f.icon = f:CreateTexture(nil,"ARTWORK")
		f.icon:SetTexCoord(.07, .93, .07, .93)
		f.icon:SetPoint("TOP", 0, 0)
		f.icon:SetPoint("RIGHT", 0, 0)
		f.icon:SetTexture(icon)

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
		f.bar:SetStatusBarColor(1,0,0)
		f.bar:Show()
	 
		f.bar.bg = f.bar:CreateTexture(nil,"BACKGROUND")
		f.bar.bg:SetTexture[[Interface\AddOns\fbngBuffFrame\white.tga]]
		f.bar.bg:SetAllPoints(f.bar)  
		f.bar.bg:SetVertexColor(0.4,0,0)
		f:SetFrameStrata("HIGH")
		f:SetFrameLevel(2)
		
		f:RegisterForClicks("RightButtonUp")
		
		-- Setup stuff for clicking off buffs
		f:SetAttribute("type", "cancelaura" )
		f:SetAttribute("unit", "player")
		f:SetAttribute("index", i)
		
		f.id = i
		f:SetScript("OnEnter",function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
			GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2);
			GameTooltip:SetUnitAura("player", self.id, "HELPFUL");
		end)
		
		f:SetScript("OnLeave",function(self)
			GameTooltip:Hide();
		end)
		self.buffs[i] = f
		f:Show()
		prev = f
	end
	self:ArrangeBuffs();
	
	self.lastTime = GetTime()
	self.OnUpdateStarted = self:ScheduleRepeatingTimer("OnUpdate", .2, self)
	
	self:RegisterEvent("UNIT_AURA")
	self:UNIT_AURA(nil, "player")
	
	self:UpdateConf()
end

function mod:OnUpdate()
	local curTime = GetTime()
	local elapsed = curTime - self.lastTime
	self.lastTime = curTime
	
	for i = 1, self.db.profile.buffs.max_display do
		local f = self.buffs[i]
		if f:GetAlpha() ~= 0 then
			local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("player",i,"HELPFUL")
			if duration ~= 0 then
				local left = expires-GetTime()
				if left > 0 then
					f.bar:SetValue(left)
					f.timer:SetFormattedText(SecondsToTimeAbbrev(left));
				else
					f:SetAlpha(0);
				end
			end
			
			if count > 1 then
				f.count:SetText(count)
			elseif f.count:IsShown() then
				f.count:Hide()
			end
		end
	end
end

function mod:UNIT_AURA(event, unit)
	if unit ~= "player" then return end
	local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
	for i=1, BUFF_MAX_DISPLAY do
		local f = self.buffs[i]
		
		name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("player",i,"HELPFUL")
		if name == nil then
			f:SetAlpha(0)
		else
			f:SetAlpha(1)
			
			if duration ~= 0 then
				f.bar:SetMinMaxValues(0,duration)
				f.bar:SetValue(expires-GetTime())
				f.timer:SetFormattedText(SecondsToTimeAbbrev(expires-GetTime()));
			else
				f.bar:SetMinMaxValues(0,1)
				f.bar:SetValue(0)
				f.timer:SetText("")
			end
			
			if count > 1 then
				f.count:Show()
				f.count:SetText(count)
			elseif f.count:IsShown() then
				f.count:Hide()
			end
			
			f.icon:SetTexture(icon)
		end
	end
end

function mod:ArrangeBuffs()
	local max = self.db.profile.buffs.max_display

	local prev = self.buff_anchor
	
	local n_by_row = self.db.profile.buffs.n_by_row
	local i_size = self.db.profile.buffs.icon_size
	local c_size = self.db.profile.buffs.count_size
	local t_size = self.db.profile.buffs.timer_size
	local pad = self.db.profile.buffs.padding
	local sb_width = self.db.profile.buffs.status_bar_width
	local buff_width = pad + sb_width + pad + i_size + pad
	local buff_height = pad + i_size + pad
	
	prev:SetWidth(buff_width)
	prev:SetHeight(buff_height)
		
	for i = 1, max do
		local b = self.buffs[i]
		local step_y = 0
		local step_x = -buff_width
		if (i % n_by_row) == 1 then
			prev = self.buff_anchor
			step_y = -(buff_height + pad + t_size + pad)* ((i-1) / n_by_row)
		end
		b:SetWidth(buff_width)
		b:SetHeight(buff_height)
				
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
