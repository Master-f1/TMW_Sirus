-- -------------
-- ADDON GLOBALS
-- -------------

TellMeWhen = {};
TELLMEWHEN_VERSION = GetAddOnMetadata("TellMeWhen","Version");
TELLMEWHEN_MAXGROUPS = 8;
TELLMEWHEN_MAXROWS = 7;
TELLMEWHEN_ICONSPACING = 0;
TELLMEWHEN_UPDATE_INTERVAL = 0.05;

TellMeWhen_Icon_Defaults = {
	BuffOrDebuff		= "HELPFUL",
	BuffShowWhen		= "present",
	CooldownShowWhen	= "usable",
	CooldownType		= "spell",
	Enabled				= false,
	Name				= "",
	OnlyMine			= false,
	ShowTimer			= "OFF",
	Font				= "Fonts\\FRIZQT__.TTF",
	Type				= "",
	Unit				= "player",
	WpnEnchantType		= "mainhand",
};

TellMeWhen_Group_Defaults = {
	Enabled			= false,
	Scale			= 1.5,
	Rows			= 1,
	Columns			= 4,
	OnlyInCombat	= false,
	Icons			= {
		Specs1={},
		Specs2={},
		Specs3={},
		Specs4={},
		Specs5={},
		Specs6={},
		Specs7={},
		Specs8={},
		Specs9={},
		Specs10={},
	},
};

TellMeWhen_Defaults = {
	Version 		= TELLMEWHEN_VERSION,
	Locked 			= false,
	Groups 			= {},
};

for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
	for specID = 1, 10 do
		TellMeWhen_Group_Defaults["Icons"]["Specs"..specID][iconID] = TellMeWhen_Icon_Defaults;
	end;
end;

for groupID = 1, TELLMEWHEN_MAXGROUPS do
	TellMeWhen_Defaults["Groups"][groupID] = TellMeWhen_Group_Defaults;
	if (groupID == 1) then
		TellMeWhen_Defaults["Groups"][groupID].Enabled = true;
	end
end

TellMeWhen_BuffEquivalencies = {};
TellMeWhen_BuffEquivalencies["Bleeding"] = "Pounce Bleed;Rake;Rip;Lacerate;Rupture;Garrote;Savage Rend;Rend;Deep Wound";
TellMeWhen_BuffEquivalencies["VulnerableToBleed"] = "Mangle (Cat);Mangle (Bear);Trauma";
--todo: include engineering bomb debuffs in Incapacitated and StunnedOrIncapacitated
TellMeWhen_BuffEquivalencies["Incapacitated"] ="Gouge;Maim;Repentance;Reckless Charge;Hungering Cold";
TellMeWhen_BuffEquivalencies["StunnedOrIncapacitated"] ="Gouge;Maim;Repentance;Reckless Charge;Hungering Cold;Bash;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp";
TellMeWhen_BuffEquivalencies["Stunned"] ="Reckless Charge;Bash;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp";
TellMeWhen_BuffEquivalencies["DontMelee"] ="Berserk;Evasion;Shield Wall;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish";
TellMeWhen_BuffEquivalencies["ImmuneToStun"] ="Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Icebound Fortitude;Hand of Protection;Cyclone;Banish";
TellMeWhen_BuffEquivalencies["ImmuneToMagicCC"] ="Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Cyclone;Banish";
TellMeWhen_BuffEquivalencies["FaerieFires"] ="Faerie Fire;Faerie Fire (Feral)";
TellMeWhen_BuffEquivalencies["MovementSlowed"] = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Frost Trap Aura;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion";
TellMeWhen_BuffEquivalencies["MeleeSlowed"] = "Rocket Burst;Infected Wounds;Judgements of the Just;Earth Shock;Thunder Clap;Icy Touch";



-- ---------------
-- EXECUTIVE FRAME
-- ---------------

function TellMeWhen_SafeUpgrade(Old)
	if (Old) then
		local specID = TellmeWhen_GetActiveTalentGroup()
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			TellMeWhen_Settings["Groups"][groupID] = CopyTable(TellMeWhen_Group_Defaults);
			TellMeWhen_Settings["Groups"][groupID]["Icons"]["Specs"..specID] = Old["Groups"][groupID]["Icons"];
		end
	end
end

function TellMeWhen_OnEvent(self, event)
	if ( event == 'VARIABLES_LOADED' ) then
		SlashCmdList["TELLMEWHEN"] = TellMeWhen_SlashCommand;
		SLASH_TELLMEWHEN1 = "/tellmewhen";
		SLASH_TELLMEWHEN2 = "/tmw";
		if ( not TellMeWhen_Settings ) then
			TellMeWhen_Settings = CopyTable(TellMeWhen_Defaults);
			TellMeWhen_Settings["Groups"][1]["Enabled"] = true;
			local specID = TellmeWhen_GetActiveTalentGroup();
			TellMeWhen_Settings["Groups"][1]["Spec"..specID] = true;
		end
		if (TellMeWhen_Settings["Groups"][1]["Icons"]["Specs1"] == nil) then
			Old = {}
			Old = CopyTable(TellMeWhen_Settings)
			TellMeWhen_SafeUpgrade(Old);
		end
		if (TellMeWhen_Settings["Version"] < TELLMEWHEN_VERSION) then
			TellMeWhen_Settings["Version"] = TELLMEWHEN_VERSION;
		end
	elseif ( event == "PLAYER_LOGIN" ) or ( event == "PLAYER_ENTERING_WORLD" ) then
		-- initialization needs to be late enough that the icons can find their textures
		self:RegisterEvent("PLAYER_TALENT_UPDATE");
		TellMeWhen_Update();
	elseif ( event == "PLAYER_TALENT_UPDATE") then
		TellmeWhen_TalentUpdate();
		TellMeWhen_Update();
	end
end

function TellMeWhen_Update()
	for groupID = 1, TELLMEWHEN_MAXGROUPS do
		TellMeWhen_Group_Update(groupID);
	end
end

do
	local executiveFrame = CreateFrame("Frame", "TellMeWhen_ExecutiveFrame");
	executiveFrame:SetScript("OnEvent", TellMeWhen_OnEvent);
	executiveFrame:RegisterEvent("VARIABLES_LOADED");
	executiveFrame:RegisterEvent("PLAYER_LOGIN");
	executiveFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
end



-- -----------
-- GROUP FRAME
-- -----------

function TellMeWhen_Group_OnEvent(self, event)
	-- called if OnlyInCombat true for this group
	if ( event == "PLAYER_REGEN_DISABLED" ) then
		self:Show();
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		self:Hide();
	end
end

-- Called when the configuration of the group has changed, when the addon
-- is loaded or when tmw is locked or unlocked
function TellMeWhen_Group_Update(groupID)
	local specID = TellmeWhen_GetActiveTalentGroup();
	local groupName = "TellMeWhen_Group"..groupID;
	local group = getglobal(groupName);
	local resizeButton = getglobal(groupName.."_ResizeButton");

	local locked = TellMeWhen_Settings["Locked"];
	local genabled = TellMeWhen_Settings["Groups"][groupID]["Enabled"];
	local scale = TellMeWhen_Settings["Groups"][groupID]["Scale"];
	local rows = TellMeWhen_Settings["Groups"][groupID]["Rows"];
	local columns = TellMeWhen_Settings["Groups"][groupID]["Columns"];
	local onlyInCombat = TellMeWhen_Settings["Groups"][groupID]["OnlyInCombat"];

	genabled = TellMeWhen_Settings["Groups"][groupID]["Spec"..specID]
	if (genabled) then
		for row = 1, rows do
			for column = 1, columns do
				local iconID = (row-1)*columns + column;
				local iconName = groupName.."_Icon"..iconID;
				local icon = getglobal(iconName) or CreateFrame("Frame", iconName, group, "TellMeWhen_IconTemplate");
				icon:SetID(iconID);
				icon:Show();
				if ( column > 1 ) then
					icon:SetPoint("TOPLEFT", getglobal(groupName.."_Icon"..(iconID-1)), "TOPRIGHT", TELLMEWHEN_ICONSPACING, 0);
				elseif ( row > 1 ) and ( column == 1 ) then
					icon:SetPoint("TOPLEFT", getglobal(groupName.."_Icon"..(iconID-columns)), "BOTTOMLEFT", 0, -TELLMEWHEN_ICONSPACING);
				elseif ( iconID == 1 ) then
					icon:SetPoint("TOPLEFT", group, "TOPLEFT");
				end
				TellMeWhen_Icon_Update(icon, groupID, iconID);
				if ( not genabled ) then
					TellMeWhen_Icon_ClearScripts(icon);
				end
			end
		end
		for iconID = rows*columns+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
			local icon = getglobal(groupName.."_Icon"..iconID);
			if icon then
				icon:Hide();
				TellMeWhen_Icon_ClearScripts(icon);
			end
		end

		group:SetScale(scale);
		local lastIcon = groupName.."_Icon"..(rows*columns);
		resizeButton:SetPoint("BOTTOMRIGHT", lastIcon, "BOTTOMRIGHT", 3, -3);
		if ( locked ) then
			resizeButton:Hide();
		else
			resizeButton:Show();
		end
	end

	if ( onlyInCombat and genabled and locked ) then
		group:RegisterEvent("PLAYER_REGEN_ENABLED");
		group:RegisterEvent("PLAYER_REGEN_DISABLED");
		group:SetScript("OnEvent", TellMeWhen_Group_OnEvent);
		group:Hide();
	else
		group:UnregisterEvent("PLAYER_REGEN_ENABLED");
		group:UnregisterEvent("PLAYER_REGEN_DISABLED");
		group:SetScript("OnEvent", nil);
		if ( genabled ) then
			group:Show();
		else
			group:Hide();
		end
	end

	if ( not TellMeWhen_Settings["Groups"][groupID]["Spec"..specID] ) then
		TellMeWhen_Settings["Groups"][groupID]["Spec"..specID] = false
	end
end



-- -------------
-- ICON FUNCTION
-- -------------

local function time_split(t)
	local hour = math.floor(t / 3600)
	local min = math.floor((t % 3600) / 60)
	local sec = (t % 3600) % 60
	return tonumber(string.format("%.f",hour)), tonumber(string.format("%.f",min)), tonumber(string.format("%.f",sec))
end

local function CreateFS(frame, endT, font)
	if not frame.fs then
		frame.fs = frame:CreateFontString(frame:GetName()..'CDTimer', 'OVERLAY')
		frame.fs:SetPoint('CENTER', frame)
		frame.fs:SetVertexColor(255, 255, 0, 1)
		frame.endTime = endT
		frame.font = font
		frame:HookScript('OnUpdate', function(self)
			if self.font == nil then
				self.fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
			else
				self.fs:SetFont(self.font, 11, "OUTLINE")
			end
			local now = GetTime()-0.5
			local hour, min, sec = time_split(self.endTime-now)
			if hour > 0 then
				self.fs:SetText(hour.."ч")
			elseif min > 0 and min < 60 then
				self.fs:SetText(min.."м")
			elseif sec < 60 then
				self.fs:SetText(sec)
			end
		end)
	end
end

function TellMeWhen_Icon_Update(icon, groupID, iconID)
	local specID = TellmeWhen_GetActiveTalentGroup();
	local iconSettings = TellMeWhen_Settings["Groups"][groupID]["Icons"]["Specs"..specID][iconID];
	local Enabled = iconSettings.Enabled;
	local iconType = iconSettings.Type;
	local CooldownType = iconSettings.CooldownType;
	local CooldownShowWhen = iconSettings.CooldownShowWhen;
	local BuffShowWhen = iconSettings.BuffShowWhen;
	icon.font = iconSettings.Font;
	icon.Name = iconSettings.Name;
	icon.Unit = iconSettings.Unit;
	icon.ShowTimer = iconSettings.ShowTimer;
	icon.OnlyMine = iconSettings.OnlyMine;
	icon.BuffOrDebuff = iconSettings.BuffOrDebuff;
	icon.WpnEnchantType = iconSettings.WpnEnchantType;

	icon.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;

	icon.texture = getglobal(icon:GetName().."Texture");
	icon.countText = getglobal(icon:GetName().."Count");
	icon.Cooldown = getglobal(icon:GetName().."Cooldown");

	icon:UnregisterEvent("ACTIONBAR_UPDATE_STATE");
	icon:UnregisterEvent("ACTIONBAR_UPDATE_USABLE");
	icon:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
	--icon:UnregisterEvent("SPELL_UPDATE_USABLE");
	icon:UnregisterEvent("PLAYER_TARGET_CHANGED");
	icon:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	icon:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	icon:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	icon:UnregisterEvent("BAG_UPDATE_COOLDOWN");
	icon:UnregisterEvent("UNIT_AURA");
	icon:UnregisterEvent("PLAYER_TOTEM_UPDATE");

	if ( TellMeWhen_Settings["Locked"] and not Enabled) then
		-- DO NOTHING
	else

		-- used by both cooldown and reactive icons
		if ( CooldownShowWhen == "usable" ) then
			icon.usableAlpha = 1;
			icon.unusableAlpha = 0;
		elseif ( CooldownShowWhen == "unusable" ) then
			icon.usableAlpha = 0;
			icon.unusableAlpha = 1;
		elseif ( CooldownShowWhen == "always") then
			icon.usableAlpha = 1;
			icon.unusableAlpha = 1;
		else
			error("Alpha not assigned: "..icon.Name);
			icon.usableAlpha = 1;
			icon.unusableAlpha = 1;
		end
		-- used by both buff/debuff and wpnenchant icons
		if ( BuffShowWhen == "present" ) then
			icon.presentAlpha = 1;
			icon.absentAlpha = 0;
		elseif ( BuffShowWhen == "absent" ) then
			icon.presentAlpha = 0;
			icon.absentAlpha = 1;
		elseif ( BuffShowWhen == "always") then
			icon.presentAlpha = 1;
			icon.absentAlpha = 1;
			--SendChatMessage("Alpha always assigned to: "..icon.Name);
		else
			error("Alpha not assigned: "..icon.Name);
			icon.presentAlpha = 1;
			icon.absentAlpha = 1;
		end

		if ( iconType == "cooldown" ) then
			if ( CooldownType == "spell" ) then
				if ( GetSpellCooldown(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
					icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));
					icon:SetScript("OnUpdate", TellMeWhen_Icon_SpellCooldown_OnUpdate);
					if (icon.ShowTimer == "CC" or icon.ShowTimer == "TMW") then
						icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
						icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
						icon:SetScript("OnEvent", TellMeWhen_Icon_SpellCooldown_OnEvent);
					else
						icon:SetScript("OnEvent", nil);
					end
				else
					TellMeWhen_Icon_ClearScripts(icon);
					icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				end
			elseif ( CooldownType == "item" ) then
				local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(TellMeWhen_GetItemNames(icon.Name,1));
				if ( itemName ) then
					icon.texture:SetTexture(itemTexture);
					icon:SetScript("OnUpdate", TellMeWhen_Icon_ItemCooldown_OnUpdate);
					if (icon.ShowTimer == "CC" or icon.ShowTimer == "TMW") then
						icon:RegisterEvent("BAG_UPDATE_COOLDOWN");
						icon:SetScript("OnEvent", TellMeWhen_Icon_ItemCooldown_OnEvent);
					else
						icon:SetScript("OnEvent", nil);
					end
				else
					TellMeWhen_Icon_ClearScripts(icon);
					icon.learnedTexture = false;
					icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				end
			end
			icon.Cooldown:SetReverse(false);

		elseif ( iconType == "buff" ) then
			icon:RegisterEvent("PLAYER_TARGET_CHANGED");
			icon:RegisterEvent("PLAYER_FOCUS_CHANGED");
			icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			icon:RegisterEvent("UNIT_AURA");
			icon:SetScript("OnEvent", TellMeWhen_Icon_Buff_OnEvent);
			icon:SetScript("OnUpdate", nil);

			if ( icon.Name == "" ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			elseif ( GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
				icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));
			elseif ( not icon.learnedTexture ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01");
			end
			icon.Cooldown:SetReverse(true);

		elseif ( iconType == "reactive" ) then
			if ( GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
				icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));
				icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
				icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
				icon:SetScript("OnEvent", TellMeWhen_Icon_Reactive_OnEvent);
				icon:SetScript("OnUpdate", TellMeWhen_Icon_Reactive_OnEvent);
			else
				TellMeWhen_Icon_ClearScripts(icon);
				icon.learnedTexture = false;
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end

		elseif ( iconType == "wpnenchant" ) then
			icon:RegisterEvent("UNIT_INVENTORY_CHANGED");
			local slotID;
			if ( icon.WpnEnchantType == "mainhand" ) then
				slotID, _ = GetInventorySlotInfo("MainHandSlot");
			elseif ( icon.WpnEnchantType == "offhand" ) then
				slotID, _ = GetInventorySlotInfo("SecondaryHandSlot");
			end
			local wpnTexture = GetInventoryItemTexture("player", slotID);
			if ( wpnTexture ) then
				icon.texture:SetTexture(wpnTexture);
				icon:SetScript("OnEvent", TellMeWhen_Icon_WpnEnchant_OnEvent);
				icon:SetScript("OnUpdate", TellMeWhen_Icon_WpnEnchant_OnUpdate);
			else
				TellMeWhen_Icon_ClearScripts(icon);
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end
		elseif ( iconType == "totem" ) then
			icon:RegisterEvent("PLAYER_TOTEM_UPDATE");
			icon:SetScript("OnEvent", TellMeWhen_Icon_Totem_OnEvent);
			icon:SetScript("OnUpdate", TellMeWhen_Icon_Totem_OnEvent);
			TellMeWhen_Icon_Totem_OnEvent(icon);
			if ( icon.Name == "" ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				icon.learnedTexture = false;
			elseif ( GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
				icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));
			elseif ( not icon.learnedTexture ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01");
			end

		else
			TellMeWhen_Icon_ClearScripts(icon);
			if ( icon.Name ~= "" ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			else
				icon.texture:SetTexture(nil);
			end
		end
	end -- Enabled CHECK

	icon.countText:Hide();
	icon.Cooldown:Hide();

	if ( Enabled ) then
		icon:SetAlpha(1.0);
	else
		icon:SetAlpha(0.4);
		TellMeWhen_Icon_ClearScripts(icon);
	end

	icon:Show();
	if ( TellMeWhen_Settings["Locked"] ) then
		icon:EnableMouse(0);
		if ( not Enabled ) then
			icon:Hide();
		elseif (icon.Name == "") and ( iconType ~= "wpnenchant" ) then
			icon:Hide();
		end
		TellMeWhen_Icon_StatusCheck(icon, iconType);
	else
		icon:EnableMouse(1);
		icon.texture:SetVertexColor(1, 1, 1, 1);
		TellMeWhen_Icon_ClearScripts(icon);
	end
	if (not icon.Cooldown.fs) and (icon.ShowTimer == "TMW") then
		CreateFS(icon.Cooldown, 0, icon.font)
	end
end

function TellMeWhen_Icon_ClearScripts(icon)
	icon:SetScript("OnEvent", nil);
	icon:SetScript("OnUpdate", nil);
end

function TellMeWhen_GetGCD()
	--To test if GCD, look at an instant cast spell without a CD that player's
	--class starts with with. If that spell is on CD, GCD is up.
	--only look for DK if player has BC expansion
	local ver = select(4, GetBuildInfo());
		if (ver >= 30000) then
		defaultSpells = {
			ROGUE=GetSpellInfo(1752), -- sinister strike
			PRIEST=GetSpellInfo(139), -- renew
			DRUID=GetSpellInfo(774), -- rejuvenation
			WARRIOR=GetSpellInfo(6673), -- battle shout
			MAGE=GetSpellInfo(168), -- frost armor
			WARLOCK=GetSpellInfo(1454), -- life tap
			PALADIN=GetSpellInfo(1152), -- purify
			SHAMAN=GetSpellInfo(324), -- lightning shield
			HUNTER=GetSpellInfo(1978), -- serpent sting
			DEATHKNIGHT=GetSpellInfo(45462) -- plague strike
		}
	else
		defaultSpells = {
			ROGUE=GetSpellInfo(1752), -- sinister strike
			PRIEST=GetSpellInfo(139), -- renew
			DRUID=GetSpellInfo(774), -- rejuvenation
			WARRIOR=GetSpellInfo(6673), -- battle shout
			MAGE=GetSpellInfo(168), -- frost armor
			WARLOCK=GetSpellInfo(1454), -- life tap
			PALADIN=GetSpellInfo(1152), -- purify
			SHAMAN=GetSpellInfo(324), -- lightning shield
			HUNTER=GetSpellInfo(1978) -- serpent sting
		}
	end
	local _, unitClass = UnitClass("player");
	return select(2,GetSpellCooldown(TellMeWhen_GetSpellNames(defaultSpells[unitClass],1)));
end

function TellMeWhen_Icon_SpellCooldown_OnEvent(self, ...)
	local startTime, timeLeft, _ = GetSpellCooldown(TellMeWhen_GetSpellNames(self.Name,1));
	if ( timeLeft ) then
		CooldownFrame_SetTimer(self.Cooldown, startTime, timeLeft, 1);
		if timeLeft > 5 then
			startTime = startTime + timeLeft
			self.Cooldown.endTime = startTime
			self.Cooldown.font = self.font
		end
	end
end

function TellMeWhen_Icon_StatusCheck(icon, iconType)
	-- this function is so OnEvent-based icons can do a check when the addon is locked
	if ( iconType == "reactive" ) then
		TellMeWhen_Icon_ReactiveCheck(icon);
	elseif ( iconType == "buff" ) then
		TellMeWhen_Icon_BuffCheck(icon);
	elseif ( iconType == "cooldown" ) then
		TellMeWhen_Icon_SpellCooldown_OnEvent(icon);
	end
end

function TellMeWhen_Icon_SpellCooldown_OnUpdate(self, elapsed)
	self.updateTimer = self.updateTimer - elapsed;
	if ( self.updateTimer <= 0 ) then
		self.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;
		local _, timeLeft, _ = GetSpellCooldown(TellMeWhen_GetSpellNames(self.Name,1));
		local inrange = IsSpellInRange(TellMeWhen_GetSpellNames(self.Name,1), self.Unit);
		local _, nomana = IsUsableSpell(TellMeWhen_GetSpellNames(self.Name,1));
		local OnGCD = TellMeWhen_GetGCD() == timeLeft and timeLeft > 0;
		--name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange
		local _,_,_,_,_,_,_,minRange,maxRange = GetSpellInfo(self.Name);
		if ( not maxRange or inrange == nil) then
			inrange = 1;
		end
		--Check that name was valid first
		if ( timeLeft ) then
			if ( (timeLeft == 0 or OnGCD) and inrange == 1 and not nomana) then
				self.texture:SetVertexColor(1, 1, 1, 1);
				self:SetAlpha(self.usableAlpha);
			elseif ( self.usableAlpha == 1 and  (timeLeft == 0 or OnGCD)) then
				--gray if not inrange or if nomana
				self.texture:SetVertexColor(0.5, 0.5, 0.5, 1);
				self:SetAlpha(self.usableAlpha);
			else
				self.texture:SetVertexColor(1, 1, 1, 1);
				self:SetAlpha(self.unusableAlpha);
			end
		end
	end
end

function TellMeWhen_Icon_ItemCooldown_OnEvent(self)
	local startTime, timeLeft, enable = GetItemCooldown(TellMeWhen_GetItemNames(self.Name,1));
	if ( timeLeft ) then
		CooldownFrame_SetTimer(self.Cooldown, startTime, timeLeft, 1);
		startTime = startTime + timeLeft
		self.Cooldown.endTime = startTime
		self.Cooldown.font = self.font
	end
end

function TellMeWhen_Icon_ItemCooldown_OnUpdate(self, elapsed)
	self.updateTimer = self.updateTimer - elapsed;
	if ( self.updateTimer <= 0 ) then
		self.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;
		local _, timeLeft, _ = GetItemCooldown(TellMeWhen_GetItemNames(self.Name,1));
		local Count = GetItemCount(TellMeWhen_GetItemNames(self.Name,1));
		if ( Count > 1 ) then
			if self.font == nil then
				self.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
			else
				self.countText:SetFont(self.font, 10, "OUTLINE")
			end
		self.countText:SetText(Count);
			self.countText:Show();
		else
			self.countText:Hide();
		end
		--Check that name was valid first
		if ( timeLeft ) then
			if ( timeLeft == 0 or TellMeWhen_GetGCD() == timeLeft ) then
				self:SetAlpha(self.usableAlpha);
			elseif ( timeLeft > 0 and TellMeWhen_GetGCD() ~= timeLeft ) then
				self:SetAlpha(self.unusableAlpha);
			end
		end
	end
end

function TellMeWhen_Icon_Buff_OnEvent(self, event, ...)
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) and ( select(2, ...) == "UNIT_DIED" ) then
		if ( select(6, ...) == UnitGUID(self.Unit) ) then
			TellMeWhen_Icon_BuffCheck(self);
		end
	elseif ( event == "UNIT_AURA" ) and ( select(1, ...) == self.Unit ) then
		TellMeWhen_Icon_BuffCheck(self);
	elseif ( event == "PLAYER_TARGET_CHANGED" and self.Unit == "target" ) or ( event == "PLAYER_FOCUS_CHANGED"  and self.Unit == "focus" ) then
		TellMeWhen_Icon_BuffCheck(self);
	end
end

function TellMeWhen_Icon_BuffCheck(icon)
	if ( UnitExists(icon.Unit) ) then
		local auraNames = TellMeWhen_GetSpellNames(icon.Name);
		local maxExpirationTime = 0;
		local processedBuffInAuraNames = false;
		local i, iName;

		local filter = icon.BuffOrDebuff;
		if icon.OnlyMine then filter = filter.."|PLAYER" end

		for i, iName in ipairs(auraNames) do
			local buffName, _, iconTexture, count, _, duration, expirationTime, unitCaster = UnitAura(icon.Unit, iName, nil, filter);
			if ( buffName ) then --and expirationTime > maxExpirationTime and ((( unitCaster == "player" ) or ( unitCaster == "pet" ) or ( unitCaster == "vehicle" )) or not icon.OnlyMine) ) then
				if ( icon.texture:GetTexture() ~= iconTexture) then
					icon.texture:SetTexture(iconTexture);
					icon.learnedTexture = true;
				end
				if (icon.presentAlpha) then
					icon:SetAlpha(icon.presentAlpha);
				end
				icon.texture:SetVertexColor(1, 1, 1, 1);
				if ( count > 1 ) then
					if icon.font == nil then
						icon.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
					else
						icon.countText:SetFont(icon.font, 10, "OUTLINE")
					end
					icon.countText:SetText(count);
					icon.countText:Show();
				else
					icon.countText:Hide();
				end
				if (icon.ShowTimer == "CC" or icon.ShowTimer == "TMW") and not UnitIsDead(icon.Unit) then
					CooldownFrame_SetTimer(icon.Cooldown, expirationTime - duration, duration, 1);
					icon.Cooldown.endTime = expirationTime
					icon.Cooldown.font = icon.font
				end
				processedBuffInAuraNames = true;
			end
		end
		if (processedBuffInAuraNames) then
			 return;
		end

		if (icon.absentAlpha) then
			icon:SetAlpha(icon.absentAlpha);
		end
		if ( icon.presentAlpha == 1 ) and ( icon.absentAlpha == 1) then
			icon.texture:SetVertexColor(1, 0.35, 0.35, 1);
		end

		icon.countText:Hide();
		if (icon.ShowTimer == "CC" or icon.ShowTimer == "TMW") then
			CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
		end
	else
		icon:SetAlpha(0);
		CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
	end
end

function TellMeWhen_Icon_Reactive_OnEvent(self, event)
	if ( event == "ACTIONBAR_UPDATE_USABLE") then
		TellMeWhen_Icon_ReactiveCheck(self);
	elseif ( event == "ACTIONBAR_UPDATE_COOLDOWN" ) then
		if (self.ShowTimer == "CC" or self.ShowTimer == "TMW") then
			TellMeWhen_Icon_SpellCooldown_OnEvent(self, event);
		end
		TellMeWhen_Icon_ReactiveCheck(self);
	end
end

function TellMeWhen_Icon_ReactiveCheck(icon)
	local usable, nomana = IsUsableSpell(TellMeWhen_GetSpellNames(icon.Name,1));
	local _, timeLeft, _ = GetSpellCooldown(icon.Name);
	local inrange = IsSpellInRange(TellMeWhen_GetSpellNames(icon.Name,1), icon.Unit);
	local OnGCD = TellMeWhen_GetGCD() == timeLeft and timeLeft > 0;
	--if range is invalid don't test for it
	if ( inrange == nil ) then
		inrange = 1
	end
	if ( usable ) then --and TellMeWhen_GetGCD() < timeLeft ) then
		if( inrange and not nomana  ) then --and timeLeft == 0) then
			icon.texture:SetVertexColor(1,1,1,1)
			icon:SetAlpha(icon.usableAlpha)
		elseif ( not inrange or nomana ) then
			icon.texture:SetVertexColor(.35,.35,.35,1)
			icon:SetAlpha(icon.usableAlpha)
		else
			icon.texture:SetVertexColor(1,1,1,1)
			icon:SetAlpha(icon.unusableAlpha)
		end
	else -- ( not usable and not nomana) then --or ( timeLeft > 1.5 ) then
		--icon.texture:SetVertexColor(1,1,1,1)
		icon:SetAlpha(icon.unusableAlpha)
	end
end

function TellMeWhen_Icon_WpnEnchant_OnEvent(self, event, ...)
	if ( event == "UNIT_INVENTORY_CHANGED" ) and ( select(1, ...) == "player" ) then
		local slotID;
		if ( self.WpnEnchantType == "mainhand" ) then
			slotID, _ = GetInventorySlotInfo("MainHandSlot");
		elseif ( self.WpnEnchantType == "offhand" ) then
			slotID, _ = GetInventorySlotInfo("SecondaryHandSlot");
		end
		local wpnTexture = GetInventoryItemTexture("player", slotID);
		if ( wpnTexture ) then
			self.texture:SetTexture(wpnTexture);
		else
			self.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end
		self.startTime = GetTime();
	end
end

function TellMeWhen_Icon_WpnEnchant_OnUpdate(self, elapsed)
	self.updateTimer = self.updateTimer - elapsed;
	if ( self.updateTimer <= 0 ) then
		self.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
		if ( self.WpnEnchantType == "mainhand" ) and ( hasMainHandEnchant ) then
			self:SetAlpha(self.presentAlpha);
			if ( mainHandCharges > 1 ) then
				if self.font == nil then
					self.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
				else
					self.countText:SetFont(self.font, 10, "OUTLINE")
				end
				self.countText:SetText(mainHandCharges);
				self.countText:Show();
			else
				self.countText:Hide();
			end
			if (self.ShowTimer == "CC" or self.ShowTimer == "TMW") then
				if ( self.startTime ~= nil ) then
					CooldownFrame_SetTimer(self.Cooldown, GetTime(), mainHandExpiration/1000, 1);
					mainHandExpiration = GetTime() + mainHandExpiration/1000
					self.Cooldown.endTime = mainHandExpiration
					self.Cooldown.font = self.font
				else
					self.startTime = GetTime();
				end
			end
		elseif ( self.WpnEnchantType == "offhand" ) and ( hasOffHandEnchant ) then
			self:SetAlpha(self.presentAlpha);
			if ( offHandCharges > 1 ) then
				if self.font == nil then
					self.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
				else
					self.countText:SetFont(self.font, 10, "OUTLINE")
				end
				self.countText:SetText(offHandCharges);
				self.countText:Show();
			else
				self.countText:Hide();
			end
			if (self.ShowTimer == "CC" or self.ShowTimer == "TMW") then
				if ( self.startTime ~= nil ) then
					CooldownFrame_SetTimer(self.Cooldown, GetTime(), offHandExpiration/1000, 1);
					offHandExpiration = GetTime() + offHandExpiration/1000
					self.Cooldown.endTime = offHandExpiration
					self.Cooldown.font = self.font
				else
					self.startTime = GetTime();
				end
			end
		else
			self:SetAlpha(self.absentAlpha);
			CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0);
		end
	end
end

function TellMeWhen_Icon_Totem_OnEvent(self, event, ...)
	--Totems have changed! Do something!
	local spellName, spellRank, spellIconPath,totemNames
	totemNames = TellMeWhen_GetSpellNames(self.Name);
	local foundTotem = false
	for iSlot=1, 4 do
		local haveTotem, totemName, startTime, totemDuration, totemIcon = GetTotemInfo(iSlot)
		for i, iName in ipairs(totemNames) do
			spellName, spellRank, spellIconPath = GetSpellInfo(iName)
			if ( totemName and totemName:find(iName) ) then
				foundTotem = true;
				self.texture:SetVertexColor(1,1,1,1);
				self:SetAlpha(self.presentAlpha);

				if ( self.texture:GetTexture() ~= totemIcon ) then
					self.texture:SetTexture( totemIcon );
					self.learnedTexture = true;
				--else
					--self.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				end

				if (self.ShowTimer == "CC" or icon.ShowTimer == "TMW") then
					-- The startTime reported here is both cast to an int and off by
					-- a latency meaning it can be significantly low.  So we cache the GetTime
					-- that the totem actually appeared, so long as GetTime is reasonably close to
					-- startTime (since the totems may have been out for awhile before this runs.)
					local precise = GetTime()
					if ( precise - startTime > 1 ) then
						precise = startTime + 1
					end
					CooldownFrame_SetTimer(self.Cooldown, precise, totemDuration, 1);
					local totem = precise + totemDuration - 1
					self.Cooldown.endTime = totem
					self.Cooldown.font = self.font
				end
				self:SetScript("OnUpdate", nil);
				break
			end
		end
	end
	if (not foundTotem) then
		if ( self.absentAlpha == 1 and self.presentAlpha == 1) then
			self.texture:SetVertexColor(1,0.35,0.35,1);
		end
		self:SetAlpha(self.absentAlpha);
		CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0);
	end

end

function TellMeWhen_GetMatchedBuffName(checkName, buffName)
	local buffNames = TellMeWhen_SplitNames(buffName)
	if tonumber( checkName ) ~= nil then
		checkName = GetSpellInfo(checkName)
	end

	local i, iName
	for i, iName in ipairs(buffNames) do
		if ( checkName == iName ) then
			return iName
		end
	end
	return nil
end

function TellMeWhen_GetSpellNames(buffName,firstOnly)
	local buffNames;
	if (TellMeWhen_BuffEquivalencies[buffName]) then
		 buffNames = TellMeWhen_SplitNames(TellMeWhen_BuffEquivalencies[buffName],"spell");
	else
		 buffNames = TellMeWhen_SplitNames(buffName,"spell")
	end
	if ( firstOnly ) then
		return buffNames[1]
	end
	return buffNames
end

function TellMeWhen_GetItemNames(buffName,firstOnly)
	local buffNames = TellMeWhen_SplitNames(buffName,"item")
	if ( firstOnly ) then
		return buffNames[1]
	end
	return buffNames
end

function TellMeWhen_SplitNames(buffName,convertIDs)
	-- If buffName contains one or more semicolons, split the list into parts
	local buffNames = {}
	if (buffName:find(";") ~= nil) then
		buffNames = { strsplit(";", buffName) }
	else
		buffNames = { buffName }
	end

	local i, iName
	for i, iName in ipairs(buffNames) do
		if (tonumber( iName ) ~= nil) then
			if (convertIDs == "item") then
				buffNames[i] = GetItemInfo(iName)
			else
				buffNames[i] = GetSpellInfo(iName)
			end
		end
	end

	return buffNames
end

function TellmeWhen_TalentUpdate()
	specID = C_Talent.GetActiveTalentGroup()
end

function TellmeWhen_GetActiveTalentGroup()
	if ( specID == nil ) then
		TellmeWhen_TalentUpdate()
	end
	return specID
end
