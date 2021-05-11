--[[
if true then return end --]]

-- luacheck: ignore 113/Info
local Info = Info or package.loaded.regscript or function(...) return ... end
local nfo = Info({
	_filename or ...,
	name		= "MacroEx",
	-- запуск макросов нетрадиционными способами
	description	= "Launching macros in unconventional ways (+@Xer0X mod)",
	id		= "35FD5420-D2A1-4A1C-AAFD-4C902231F549",
	version		= "3.2",
	version_mod	= "0.6",
	author		= "JD",
	author_mod	= "x-Team",
	url		= "http://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "https://github.com/dr-dba/far-lua-key-efficiency/",
	-- LuaMacro 501 (ConsoleInput)
	minfarversion	= { 3, 0, 0, 4430, 0 },
	options = {
		break_seq_on_mod_release= false,
		allow_seq_with_any_mod	= true,
		Delay		=  500,
		SeqDelay	= 5000,
		ext_modes 	= {
			hold	= true,
			double	= true,
		},
		Debug		= false,
	}
})
if not nfo then return end
local opts	= nfo.options
local BREAK_SEQ_ON_MOD_RELEASE	= opts.break_seq_on_mod_release
local ALLOW_SEQ_WITH_ANY_MOD	= opts.allow_seq_with_any_mod
local OPT_DEBUG			= opts.Debug
local OPT_DELAY_SEQ		= opts.SeqDelay
local OPT_DELAY			= opts.Delay
local fnc_case_title 	= Xer0X.fnc_case_title
local fnc_case_toggle	= Xer0X.fnc_case_toggle
local F	= far.Flags
local C = far.Colors

local Xer0X
	= require("Lib-Common-@Xer0X")
local req_ok, req_msg, fnc_lua_exp, tbl_lua_exp_hidden_props
	= Xer0X.fnc_safe_require("LuaExplorer-@Xer0X")
if not req_ok
then req_ok, req_msg, fnc_lua_exp
	= Xer0X.fnc_safe_require("LE")
end
local as_module, inp_args, own_file_path
	= Xer0X.fnc_file_whoami()
local	Macro = Macro
local	Event = Event
local	tbl_mcr_env, tbl_mcr_exinf
if not	Macro
then	tbl_mcr_env, tbl_mcr_exinf
		= Xer0X.fnc_macro_one_load(nil, own_file_path, false, true)
	Macro = tbl_mcr_env.Macro
	Event = tbl_mcr_env.Event
end


local function fnc_err_msg(msg, ...)
	local	msg2 = msg.."\n\2"..debug.traceback("", 2):gsub("\t", "  ")
	local	buttons = select('#', ...) > 0 and "Ok;&Lua explorer" or "Ok"
	local	a_msg_res
	repeat	a_msg_res = far.Message(msg2, "MacroEx: error in macro definition", buttons, "wl")
		if a_msg_res == 2
		then	-- to view args
			require("LuaExplorer-@Xer0X")({ ... }, msg)
		end
	until	a_msg_res ~= 2
end -- fnc_err_msg

local killAutorepeat, isHolding

do
	local no_repeat

	function killAutorepeat(vk) no_repeat = vk end

	function isHolding(vk) return no_repeat == vk end

	Event {	description = "MacroEx helper",
		group = "ConsoleInput",
		action = function(Rec)
			if	no_repeat
			and	Rec.EventType == F.KEY_EVENT
			and	Rec.VirtualKeyCode ~= 0
			then	-- KEY_NONE? Rec.VirtualKeyCode == 0
				if	Rec.VirtualKeyCode == no_repeat
				and	Rec.KeyDown
				then	-- eat repetitions
					return 1
				else	no_repeat = false
				end
			end
		end
	}
end

-- State after last mf.waitkey!!
local function isReleased(mod_state) return
	band(Mouse.LastCtrlState, mod_state) == 0,
	band(Mouse.LastCtrlState, mod_state),
	Mouse.LastCtrlState
end

-- C.COL_MENUTITLE
local Color = far.AdvControl(F.ACTL_GETCOLOR, C.COL_MENUHIGHLIGHT)

local function setStatus(text, color)
	if	text == "anassigned"
	then	text = text.." ??"
	end
	if	text
	and	type(text) == "string"
	then
		far.Text(1, 0, color, " "..text.." ")
		far.Text()
	end
end

-- ?? premake help or store macros
local function getSeqHelp(seq_key)
	local tbl_help	= { }
	local area_re	= "%f[%a]"..string.lower(Area.Current).."%f[%A]"
	local key_re	= "%f[%a]"..string.lower(seq_key).."%-"
	for ii = 1, math.huge
	do
		local	ii_mcr = mf.GetMacroCopy(ii)
		if not	ii_mcr then break end
		-- ?? use GetMacro
		if	ii_mcr.key
		and not ii_mcr.keyregex
		then
			local ii_mcr_area_low = string.lower(ii_mcr.area)
			if string.match(string.lower(ii_mcr.key), key_re)
			then
				-- ?? checkFlags, CheckFileName
				if (	ii_mcr_area_low == "common"
				or	string.find(ii_mcr_area_low, area_re)
				)
				and not ii_mcr.disabled
				and (		ii_mcr.condition == nil
					or	type(ii_mcr.condition) == "function"
					and	ii_mcr.condition(seq_key)
					or	ii_mcr.condition
				)
				then -- ?? pcall
					table.insert(tbl_help, ii_mcr.description or ii_mcr.key)
				end
			end
		end
	end
	return next(tbl_help) and table.concat(tbl_help, "\n")
end -- getSeqHelp

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
	local	cmb_mod, cmb_key = combo:match(key)
--	far.Show(cmb_mod, cmb_key)
	if	cmb_mod
	then
		local	m = far.NameToInputRecord(cmb_mod.."a")
		local	k = far.NameToInputRecord(cmb_key)
		if	m and k
		then	return {
				ControlKeyState	= m.ControlKeyState,
				VirtualKeyCode	= k.VirtualKeyCode
			}
		end
	end
end

local MOD_MASK = bor(
	F.LEFT_ALT_PRESSED,
	F.RIGHT_ALT_PRESSED,
	F.LEFT_CTRL_PRESSED,
	F.RIGHT_CTRL_PRESSED,
	F.SHIFT_PRESSED
		)

local Macro, FileName = Macro, ...

local function setHandler(mkey, AKey, modsLen, mcr)
	local	inp_rec = far.NameToInputRecord(AKey) or tryComboMod(AKey)
	if not	inp_rec
	then    if OPT_DEBUG
		then fnc_err_msg(("Unexpected AKey: %q"):format(AKey), mcr)
		end
		return
	end
	local	mod_state = band(inp_rec.ControlKeyState, MOD_MASK)
	if	mod_state == 0
	then    if OPT_DEBUG
		then fnc_err_msg(("Unexpected ControlKeyState in %q: %q"):format(AKey, inp_rec.ControlKeyState), inp_rec)
		end
		return
	end
	-- http://bugs.farmanager.com/view.php?id=2947
	if string.match(string.lower(AKey), "r?ctrlnumlock")
	then	inp_rec = far.NameToInputRecord("Pause")
	end
	local base_vk = inp_rec.VirtualKeyCode
	local handler_key = {
		double	= { },
		hold	= { },
		sequence= { },
		priority= { },
	--	mod	= { },
	}
	-- to disable handler in order to run original macro
	local locked

	Macro { description = ("MacroEx handler for %q"):format(mkey)
			:gsub("shift",	"Shift")
			:gsub("rctrl",	"RCtrl")
			:gsub("lctrl",	"LCtrl")
			:gsub("ctrl",	"Ctrl")
			:gsub("ralt",	"RAlt")
			:gsub("lalt",	"LAlt")
			:gsub("alt",	"Alt"),
		id = win.Uuid(win.Uuid()),
	--	uid = mkey,
		area = "Common",
		key = mkey,
		FileName = FileName,
		priority = 100,
		condition = function(mcr_key, mcr_src, p2, p3)
			return	not	locked
				and (   handler_key.priority[Area.Current:lower()]
				or 	handler_key.priority.common
					)
		end,
		action = function(mcr_src, p1, p2, p3)
			local is_hld_vk, is_rls_mod, is_timeout, run_normal
			is_hld_vk = isHolding(base_vk)
			-- prevent autorepeat:
			if is_hld_vk then return end
			killAutorepeat(base_vk)
			local area = Area.Current:lower()
			-- ?? inheritance (Autocompletion, Search)
			local has_dbl = handler_key.double	[area] or handler_key.double	.common
			local has_hld = handler_key.hold	[area] or handler_key.hold	.common
			local has_seq = handler_key.sequence	[area] or handler_key.sequence	.common
		--	local is_mod  = k.mod[area] or k.mod.common -- todo extramod
			local next_key= "" 
			local t_start = Far.UpTime
			local mod_state_new
			local t_hold_time
			while not (is_timeout or next_key ~= "" or is_rls_mod)
			do
				is_rls_mod, mod_state_and, mod_state_new = isReleased(mod_state)
				if is_rls_mod	then break end
				next_key = mf.waitkey(10)
				t_hold_time = Far.UpTime
				is_timeout = t_hold_time - t_start > OPT_DELAY
				if next_key~="" then break end
				if is_timeout	then break end
			end
			if	is_timeout 
			then
				if	has_hld
				and	isHolding(base_vk)
				then
					if runMacro(AKey, ":Hold")
					then return
					end
				end
			elseif
				has_dbl
			and	next_key ~= ""
			and	string.lower(next_key) == string.lower(AKey)
			then
				killAutorepeat(base_vk)
				if runMacro(AKey, ":Double")
				then return
				end
			end
			local help_msg, help_ret
			if has_seq
			then    -- ctrlaltshiftkey ==> CtrlAltShiftKey # todo (match) # DONE? @Xer0X
				AKey = mf.akey(1, 1)
				local hnd_scr = far.SaveScreen()
				setStatus(AKey, Color)
				local end_key =
					--[[ to require ending key with modifiers:
					("^%s(.+)") --]]
					("^%s(.*)") 
					:format(AKey:sub(1, modsLen))
				while	true
				do
					is_rls_mod = isReleased(mod_state)
					if	is_rls_mod
					and	BREAK_SEQ_ON_MOD_RELEASE
					then	run_normal = true
						break
					end
					if	next_key ~= ""
					then
						far.RestoreScreen(hnd_scr)
						local key2 = string.match(next_key, end_key)
						local key2_fix = key2 ~= "" and key2 or next_key
						-- false == BREAK_SEQ_ON_MOD_RELEASE
						if	runMacro(AKey, "-"..key2_fix)
						then	return
						elseif	key2_fix ~= next_key
						and	runMacro(AKey, "-"..next_key)
						then	return
						else	
							is_timeout = true
							run_normal = true
						end
						hnd_scr = nil
						break
					end
					next_key = mf.waitkey(10)
					if not	help_msg
					and	Far.UpTime - t_start > OPT_DELAY_SEQ
					then
						is_timeout = true
						help_msg = getSeqHelp(AKey)
						if	help_msg
						then	help_ret = far.Message(help_msg, AKey, "", "l")
						else	run_normal = true
							break
						end
					end
				end
				if hnd_scr then far.RestoreScreen(hnd_scr) end
			end -- if has_seq
			if not	is_timeout
			or	run_normal
			then
				locked = true
				runMacroOrKey(AKey)
				if next_key ~= ""
				then runMacroOrKey(next_key)
				end
				locked = false
				return
			end
			-- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
			setStatus("anassigned", Color)
			mf.beep()
			win.Sleep(100)
		end -- action
	}
	return handler_key
end -- setHandler

local tbl_handlers = { }
_G.Xer0X.tbl_macro_ex_handlers = tbl_handlers
--[[ have to be base key, as in "CtrlRAltA" is "A":
local parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)$")
--[=[! have NOT to be base key, as in "CtrlRAltA" is NiL:]]
local parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$")
--[[ todo:
local parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$")
return parse:match(("LCtrlRAlt"):lower())
--]]

local function fnc_build_key(RLctl, RLalt, shift, key) return
		(
	(RLctl and string.upper(RLctl).."Ctrl" or "")..
	(RLalt and string.upper(RLalt).."Alt"  or "")..
	(shift or "")..
	(key and fnc_case_title(key) or "")
		)
	:gsub("shift", "Shift")
end -- fnc_build_key

local function fnc_expand_key(key, ext_mod, mcr, fnc_callback)
--	assert(key:match("^%l+$"))
	local RLctl, RLalt, shift, base_key = parse:match(string.lower(key))
	if	base_key == false
	then	base_key = ""
	end
	local tbl_hnd_keys = { }
	local key_fmt = "c:%s/a:%s/s:%s/b:%s/e:%s"
	local ctl = RLctl == "" and "L"
	repeat
		local alt = RLalt == "" and "L"
		repeat
			local key_str = string.format(key_fmt, ctl or RLctl, alt or RLalt, shift, base_key, ext_mod)
			tbl_hnd_keys[key_str] = fnc_callback(ctl or RLctl, alt or RLalt, shift, base_key, ext_mod, mcr)
			alt = (alt or ""):lower() == "l" and "R"
		until not alt
		ctl = (ctl or ""):lower() == "l" and "R"
	until not ctl
	return tbl_hnd_keys
end -- fnc_expand_key

function fnc_expand_key_callback(	ctl, alt, shift, base_key, ext_mod, mcr)
	local	mkey = fnc_build_key(	ctl, alt, shift, base_key)
	local	hnd_key = tbl_handlers[mkey]
	if not	hnd_key
	then 	-- register hotkey's handler
		local fkey = fnc_build_key(
			(ctl or ""):lower() == "l" and "" or ctl,
			(alt or ""):lower() == "l" and "" or alt,
			shift,
			base_key)
		hnd_key = setHandler(mkey, fkey, fkey:len() - base_key:len(), mcr)
		tbl_handlers[mkey] = hnd_key
	end
	-- calculate handler's priority by area --??use GetMacro??
	if	hnd_key
	then
		local UniqAreas = { }
		for ii_area in mcr.area:lower():gmatch("%S+")
		do
			if not	UniqAreas[ii_area]
			then 	-- prevent multiple inclusions
				UniqAreas[ii_area] = true
				hnd_key[ext_mod][ii_area] = true
				hnd_key.priority[ii_area] = math.max(hnd_key.priority[ii_area] or 0, (mcr.priority or 50) + 5)
				mcr[ext_mod] = true
				if OPT_DEBUG
				then	mcr.base_key = base_key
					table.insert(hnd_key, mcr)
				end
			end
		end
	end
	return hnd_key
end -- fnc_expand_key_callback

local function fnc_macro_ex_build_one(mcr)
	local tbl_UniqKeys = { }
	local tbl_hnd_keys = { }
	for ii_key in mcr.key:lower():gmatch("%S+")
	do	-- prevent multiple inclusions
		if not	tbl_UniqKeys[ii_key]
		then	tbl_UniqKeys[ii_key] = true
			local	ii_key_base, ii_ext_mode = ii_key:match("^(.+):(.+)$")
			if	ii_ext_mode
			and not opts.ext_modes[ii_ext_mode]
			then	ii_key_base = false
			end
			if not	ii_key_base
			then	ii_key_base = ii_key:match("^(.+)%-.")
				ii_ext_mode = "sequence"
			end
			--[[ todo extramod
			if not	ii_key_base
			then	ii_key_base = ii_key:match("^(.+)%+.")
				ii_ext_mode = "mod"
			end --]]
			if	ii_key_base
			then	tbl_hnd_keys[ii_key] = fnc_expand_key(ii_key_base, ii_ext_mode, mcr, fnc_expand_key_callback)
			end
		end
	end
	return tbl_hnd_keys
end -- fnc_macro_ex_build_one

local function fnc_macro_ex_build_all()
	for ii = 1, math.huge
	do
		local	ii_mcr = mf.GetMacroCopy(ii)
		if not	ii_mcr then break end
		if	ii_mcr.key
		and not ii_mcr.keyregex
		then	fnc_macro_ex_build_one(ii_mcr)
		end
	end
	if OPT_DEBUG then fnc_lua_exp(tbl_handlers) end
	return tbl_handlers
end -- fnc_macro_ex_find_all

mf.postmacro(fnc_macro_ex_build_all)

-- @@@@@
