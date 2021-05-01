--[[
if true then return end --]]

-- luacheck: ignore 113/Info
local Info = Info or package.loaded.regscript or function(...) return ... end

local nfo = Info {
	_filename or ...,
	name		= "MacroEx",
	-- запуск макросов нетрадиционными способами
	description	= "Launching macros in unconventional ways",
	id		= "115C9534-8273-4F5A-94EB-E321D6DC8618",
	version		= "3.2",
	version_mod	= "0.5",
	author		= "JD",
	author_mod	= "x-Team",
	url		= "http://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	-- LuaMacro 501 (ConsoleInput)
	minfarversion = { 3, 0, 0, 4430, 0 },
	options = {
		break_sequence_on_mod_release	= false,
		allow_sequence_with_any_mod	= true,
		Delay	=  500,
		SeqDelay= 5000,
		debug	= false
	}
}

if not nfo then return end

local opts = nfo.options
local F = far.Flags

function fnc_case_title(str)
	local function fnc_title_int(first, rest) return first:upper()..rest:lower() end
	return string.gsub(str, "(%a)([%w']*)", fnc_title_int)
end

function fnc_case_toggle(str)
	local function fnc_toggle_int(first, rest) return first:lower()..rest:upper() end
	return string.gsub(str, "(%a)([%w']*)", fnc_toggle_int)
end

local function errmsg(msg, ...)
	local msg2 = msg.."\n\2"..debug.traceback("", 2):gsub("\t", "  ")
	local buttons = select('#', ...) > 0 and "Ok;&Lua explorer" or "Ok"
	local a_msg_res
	repeat
		a_msg_res = far.Message(msg2, "MacroEx: error in macro definition", buttons, "wl")
		if a_msg_res == 2
		then	-- to view args
			require("LuaExplorer-@Xer0X")({ ... }, msg)
		end
	until a_msg_res ~= 2
end

local killAutorepeat, isHolding

do
	local norepeat

	Event {	description = "MacroEx helper",
		group = "ConsoleInput",
		action = function(Rec)
			if	norepeat
			and	Rec.EventType == F.KEY_EVENT
			and	Rec.VirtualKeyCode ~= 0
			then	-- KEY_NONE? Rec.VirtualKeyCode == 0
				if	Rec.VirtualKeyCode == norepeat
				and	Rec.KeyDown
				then	-- eat repetitions
					return 1
				else	norepeat = false
				end
			end
		end
	}

	function killAutorepeat(vk) norepeat = vk end

	function isHolding(vk) return norepeat == vk end

end

-- State after last mf.waitkey!!
local function isReleased(Mod) return band(Mouse.LastCtrlState, Mod) == 0 end

local C = far.Colors
-- C.COL_MENUTITLE
local Color = far.AdvControl(F.ACTL_GETCOLOR, C.COL_MENUHIGHLIGHT)

local function setStatus(text, color)
	if	text == "anassigned"
	then	text = text.."??"
	end
	if	text and
		type(text) == "string"
	then
		far.Text(1, 0, color, " "..text.." ")
		far.Text()
	end
end

-- ?? premake help or store macros
local function getSeqHelp(key)
	local tbl_help	= { }
	local area_re	= "%f[%a]"..string.lower(Area.Current).."%f[%A]"
	local key_re	= "%f[%a]"..string.lower(key).."%-"
	for ii = 1, math.huge
	do
		local	mcr = mf.GetMacroCopy(ii)
		if not	mcr then break end
		-- ?? use GetMacro
		if	mcr.key and
		not	mcr.keyregex
		then
			if string.match(string.lower(mcr.key), key_re)
			then
				-- ?? checkFlags, CheckFileName
				if	(mcr.area == "common" or string.find(string.lower(mcr.area), area_re)) and
					not mcr.disabled and (
						mcr.condition == nil or
						type(mcr.condition) == "function" and mcr.condition(key) or
						mcr.condition
							)
				then -- ?? pcall
					table.insert(tbl_help, mcr.description or mcr.key)
				end
			end
		end
	end
	return next(tbl_help) and table.concat(tbl_help, "\n")
end

local function runMacro(key, Ex)
	local	eval_res = eval(key..Ex, 2)
	return	eval_res ~= -2
end

local function runMacroOrKey(key)
	local	eval_res = eval(key, 2)
	if	eval_res == -2
	then	Keys(key)
	end
end

local combo = regex.new("^((?:[rl]?ctrl)?(?:[rl]?alt)?(?:shift)?)((?:shift)|(?:alt))$", "i")

local function tryComboMod(key)
	local	mod, key = combo:match(key)
--	far.Show(mod, key)
	if	mod
	then
		local	m = far.NameToInputRecord(mod.."a")
		local	k = far.NameToInputRecord(key)
		if	m and k
		then	return {
				ControlKeyState	= m.ControlKeyState,
				VirtualKeyCode	= k.VirtualKeyCode
			}
		end
	end
end

local modmask = bor(
	F.LEFT_ALT_PRESSED,
	F.RIGHT_ALT_PRESSED,
	F.LEFT_CTRL_PRESSED,
	F.RIGHT_CTRL_PRESSED,
	F.SHIFT_PRESSED
		)

local Macro, FileName = Macro, ...

local function setHandler(mkey, AKey, modslen, mcr)
	local	r = far.NameToInputRecord(AKey) or tryComboMod(AKey)
	if not	r
	then    if opts.debug then errmsg(("Unexpected AKey: %q"):format(AKey), mcr) end
		return
	end
	local	mod = band(r.ControlKeyState, modmask)
	if	mod == 0
	then    if opts.debug then errmsg(("Unexpected ControlKeyState in %q: %q"):format(AKey, r.ControlKeyState), r) end
		return
	end
	-- http://bugs.farmanager.com/view.php?id=2947
	if string.match(string.lower(AKey), "r?ctrlnumlock") then r = far.NameToInputRecord("Pause") end
	local base_vk = r.VirtualKeyCode
	local handler_key = {
		double	= { },
		hold	= { },
		sequence= { },
		priority= { },
	}
	-- to disable handler in order to run original macro
	local locked

	Macro { description = ("MacroEx handler for %q"):format(mkey)
			:gsub("shift",	"Shift")
			:gsub("rctrl",	"RCtrl")
			:gsub("lctrl",	"LCtrl")
			:gsub("ctrl",	"Ctrl"),
		id = win.Uuid(win.Uuid()),
	--	uid = mkey,
		area = "Common",
		key = mkey,
		FileName = FileName,
		priority = 100,
		condition = function(mcr_key, mcr_src, p2, p3)
			return not locked and (
				handler_key.priority[Area.Current:lower()] or 
				handler_key.priority.common
					)
		end,
		action = function(mcr_src, p1, p2, p3)
			local is_hld_vk, is_rls_mod, timeout, run_normal
			is_hld_vk = isHolding(base_vk)
			-- prevent autorepeat:
			if is_hld_vk then return end
			killAutorepeat(base_vk)
			local area = Area.Current:lower()
			-- ?? inheritance (Autocompletion, Search)
			local has_dbl = handler_key.double	[area] or handler_key.double.common
			local has_hld = handler_key.hold	[area] or handler_key.hold.common
			local has_seq = handler_key.sequence	[area] or handler_key.sequence.common
		--	local is_mod = k.mod[area] or k.mod.common -- todo extramod
			local key = ""
			local t_start = Far.UpTime
			while not (timeout or key ~= "" or is_rls_mod)
			do
				is_rls_mod = isReleased(mod)
				if is_rls_mod then break end
				key = mf.waitkey(10)
				timeout = Far.UpTime - t_start > opts.Delay
				if timeout then break end
			end
			if	timeout 
			then
				if	has_hld 
				and	isHolding(base_vk)
				then
					if runMacro(AKey, ":Hold")
					then return
					end
				end
			elseif
				has_dbl and
				key ~= "" and
				string.lower(key) == string.lower(AKey)
			then
				killAutorepeat(base_vk)
				if runMacro(AKey, ":Double")
				then return
				end
			end
			local help_msg, help_ret, endkey, try_seq_wait, key2, key2_fix
			if	has_seq 
			then    -- CtrlAltShiftKey ==> CtrlAltShiftKey -- todo (match)
				AKey = mf.akey(1, 1)
				local hnd_scr = far.SaveScreen()
				setStatus(AKey, Color)
				endkey = ("^%s(.+)"):format(AKey:sub(1, modslen))
				while	true 
				do
					is_rls_mod = isReleased(mod)
					if	is_rls_mod 
					and	opts.break_sequence_on_mod_release
					then	run_normal = true
						break
					end
					if	key ~= "" 
					then
						far.RestoreScreen(hnd_scr)
						key2 = string.match(key, endkey)
						key2_fix = key2 ~= "" and key2 or key
						-- false == break_sequence_on_mod_release
						if	runMacro(AKey, "-"..key2_fix)
						then	return
						elseif	runMacro(AKey, "-"..key)
						then	return
						else	
							timeout = true
							run_normal = true
						end
						hnd_scr = nil;
						break
					end
					try_seq_wait = true
					key = mf.waitkey(10)
					if not	help_msg 
					and	Far.UpTime - t_start > opts.SeqDelay 
					then
						timeout = true
						help_msg = getSeqHelp(AKey)
						if	help_msg
						then	help_ret = far.Message(help_msg, AKey, "", "l")
						else	run_normal = true
							break
						end
					end
				end
				if hnd_scr then far.RestoreScreen(hnd_scr) end
			end
			if not timeout or run_normal
			then
				locked = true
				runMacroOrKey(AKey)
				if key ~= "" then runMacroOrKey(key) end
				locked = false
				return
			end
			-- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
			setStatus("anassigned", Color)
			mf.beep()
			win.Sleep(100)
		end
	}
	return handler_key
end

local parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)$")

--[[ todo:
local parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)$")
return parse:match(("CtrlAlt"):lower())
--]]

local function fnc_build_key(RLctl, RLalt, shift, key)
	return (
		(RLctl and string.upper(RLctl).."Ctrl" or "")..
		(RLalt and string.upper(RLalt).."Alt"  or "")..
		(shift or "")..
		(key and fnc_case_title(key) or "")
			)
		:gsub("shift", "Shift")
end

local function fnc_expand_key(key, ext_mod, mcr, callback)
--	assert(key:match("^%l+$"))
	local RLctl, RLalt, shift, base_key = parse:match(string.lower(key))
	if not	base_key
	or	base_key == ""
	then
		if opts.debug then errmsg(("Unable to parse key %q"):format(key), Rlctl, RLalt, shift, base_key) end
		return
	end
	local ctl = RLctl == "" and "L"
	repeat
		local alt = RLalt == "" and "L"
		repeat
			callback(ctl or RLctl, alt or RLalt, shift, base_key, ext_mod, mcr)
			alt = (alt or ""):lower() == "l" and "R"
		until not alt
		ctl = (ctl or ""):lower() == "l" and "R"
	until not ctl
end

local tbl_handlers = { }
_G.tbl_macro_ex_handlers = tbl_handlers

function fnc_expand_key_callback(	ctl, alt, shift, base_key, ext_mod, mcr)
	local	mkey = fnc_build_key(	ctl, alt, shift, base_key)
	local	hnd_key = tbl_handlers[mkey]
	if not	hnd_key
	then 	-- register hotkey's handler
		local fkey = fnc_build_key(
			(ctl or ""):lower() == "l" and "" or ctl,
			(alt or ""):lower() == "l" and "" or alt,
			shift,
			base_key
				)
		hnd_key = setHandler(mkey, fkey, fkey:len() - base_key:len(), mcr)
		tbl_handlers[mkey] = hnd_key
	end
	-- calculate handler's priority by area --??use GetMacro??
	if	hnd_key
	then
		local UniqAreas = { }
		for mcr_area in mcr.area:lower():gmatch("%S+")
		do
			if not	UniqAreas[mcr_area]
			then 	-- prevent multiple inclusions
				UniqAreas[mcr_area] = true
				hnd_key[ext_mod][mcr_area] = true
				hnd_key.priority[mcr_area] = math.max(hnd_key.priority[mcr_area] or 0, (mcr.priority or 50) + 5)
				mcr[ext_mod] = true
				if opts.debug
				then	mcr.base_key = base_key
					table.insert(hnd_key, mcr)
				end
			end
		end
	end
end

mf.postmacro(function()
	local tbl_valid_ext_mod = { hold = 1, double = 1 }
	for ii = 1, math.huge
	do
		local	ii_mcr = mf.GetMacroCopy(ii)
		if not	ii_mcr then break end
		if	ii_mcr.key and
		not 	ii_mcr.keyregex
		then
			local UniqKeys = { }
			for Key in ii_mcr.key:lower():gmatch("%S+")
			do	-- prevent multiple inclusions
				if not	UniqKeys[Key]
				then
					UniqKeys[Key] = true
					local	key, ext_mod = Key:match("^(.+):(.+)$")
					if	ext_mod and not tbl_valid_ext_mod[ext_mod] then key = false	end
					if not	key then key, ext_mod = Key:match("^(.+)%-."), "sequence"	end
					-- todo extramod
					if	key
					then	fnc_expand_key(key, ext_mod, ii_mcr, fnc_expand_key_callback)
					end
				end
			end
		end
	end
	if opts.debug then le(tbl_handlers) end
end)

-- @@@@@
