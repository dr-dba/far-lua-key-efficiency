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
	version_mod	= "1.0.1",
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
		DelaySeq	= 5000,
		ext_modes 	= {
			HLD	= true, -- holding
			DBL	= true, -- double
		},
		Debug		= false,
	}
})
if not nfo then return end
local opts	= nfo.options
local BREAK_SEQ_ON_MOD_RELEASE	= opts.break_seq_on_mod_release
local ALLOW_SEQ_WITH_ANY_MOD	= opts.allow_seq_with_any_mod
local OPT_DEBUG			= opts.Debug
local OPT_DELAY_SEQ		= opts.DelaySeq
local OPT_DELAY			= opts.Delay
local fnc_case_title 	= Xer0X.fnc_case_title
local fnc_case_toggle	= Xer0X.fnc_case_toggle
local F	= far.Flags
local C = far.Colors
local LEFT_ALT_PRESSED	= F.LEFT_ALT_PRESSED
local RIGHT_ALT_PRESSED	= F.RIGHT_ALT_PRESSED
local LEFT_CTRL_PRESSED	= F.LEFT_CTRL_PRESSED
local RIGHT_CTRL_PRESSED= F.RIGHT_CTRL_PRESSED
local SHIFT_PRESSED	= F.SHIFT_PRESSED

local MOD_MASK = bor(
	LEFT_ALT_PRESSED,
	RIGHT_ALT_PRESSED,
	LEFT_CTRL_PRESSED,
	RIGHT_CTRL_PRESSED,
	SHIFT_PRESSED
	)
local tbl_ext_mode_code = { double = "DBL", hold = "HLD" }
local Xer0X
	= require("Lib-Common-@Xer0X")
local req_ok, req_msg, fnc_lua_exp
	= Xer0X.fnc_safe_require("LuaExplorer-@Xer0X")
if not req_ok
then req_ok, req_msg, fnc_lua_exp
	= Xer0X.fnc_safe_require("LE")
end
local as_module, inp_args, own_file_path
	= Xer0X.fnc_file_whoami()
local	FileName = ... or own_file_path
local	Macro = Macro
local	Event = Event
local	tbl_mcr_env, tbl_mcr_exinf
if not	Macro
then	tbl_mcr_env, tbl_mcr_exinf
		= Xer0X.fnc_macro_one_load(nil, own_file_path, false, true)
	Macro = tbl_mcr_env.Macro
	Event = tbl_mcr_env.Event
end
local fnc_str_split = Xer0X.fnc_str_split

local str_lower = utf8.Utf8_lower	or utf8.lower
local str_upper = utf8.Utf8_upper	or utf8.upper
local str_gmatch= utf8.Utf8_gmatch	or utf8.gmatch
local str_match = utf8.Utf8_match	or utf8.match
local str_find	= utf8.Utf8_find	or utf8.find
local str_gsub	= utf8.Utf8_gsub	or utf8.gsub
local str_len	= utf8.Utf8_len		or utf8.len
local str_sub	= utf8.sub
local str_cfind = utf8.cfind
local str_format= utf8.format
local math_max	= math.max
local tbl_concat= table.concat

local KEY_VIS_FMT = "c:%s/a:%s/s:%s/e:%s/p:%s"
-- C.COL_MENUTITLE
local CLR_STATUS_TEXT = far.AdvControl(F.ACTL_GETCOLOR, C.COL_MENUHIGHLIGHT)

local	tbl_handlers = Xer0X.tbl_macro_ex_handlers
if not	tbl_handlers
then	tbl_handlers = { }
	Xer0X.tbl_macro_ex_handlers = tbl_handlers
end
local is_locked -- to disable handler in order to run original macro
local no_repeat -- prevent senseless repeating the same key

local function fnc_err_msg(msg, ...)
	local	msg2 = msg.."\n\2"..debug.traceback("", 2):gsub("\t", "  ")
	local	buttons = select('#', ...) > 0 and "Ok;&Lua explorer" or "Ok"
	repeat	local	a_msg_res = far.Message(msg2, "MacroEx: error in macro definition", buttons, "wl")
		if	a_msg_res == 2
		then	-- to view args
			fnc_lua_exp({ ... }, msg)
		else	break
		end
	until	false
end -- fnc_err_msg

local function fnc_eat_autorep(vk) no_repeat = vk end

local function fnc_is_holding(vk) return no_repeat == vk end

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

-- State after last mf.waitkey!!
local function fnc_is_released(mod_state)
	local mod_last = Mouse.LastCtrlState
	return  band(mod_last, mod_state) == 0,
		band(mod_last, mod_state),
		mod_last,
		Mouse.CtrlState
end

local function fnc_status_set(text_str, txt_color)
	if type(text_str) ~= "string" then return end
	far.Text(1, 0, txt_color or CLR_STATUS_TEXT, " "..text_str.." ")
	far.Text()
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
				and (	ii_mcr.condition == nil
				or	type(ii_mcr.condition) == "function"
				and	ii_mcr.condition(seq_key)
				or	ii_mcr.condition
				)
				then	-- ?? pcall
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

local rgx_combo = regex.new("^((?:[rl]?ctrl)?(?:[rl]?alt)?(?:shift)?)((?:shift)|(?:alt))$", "i")
local function fnc_combo_mod_try(key)
	local	combo_mod, combo_key = rgx_combo:match(key)
	if	combo_mod
	then	local	m = far.NameToInputRecord(combo_mod.."a")
		local	k = far.NameToInputRecord(combo_key)
		if	m and k
		then	return {
				ControlKeyState	= m.ControlKeyState,
				VirtualKeyCode	= k.VirtualKeyCode
			}
		end
	end
end -- fnc_combo_mod_try

local function fnc_key_prettify(str_key)
	return str_key
		:gsub("shift",	"Shift"	)
		:gsub("rctrl",	"RCtrl"	)
		:gsub("lctrl",	"LCtrl"	)
		:gsub("ctrl",	"Ctrl"	)
		:gsub("ralt",	"RAlt"	)
		:gsub("lalt",	"LAlt"	)
		:gsub("alt",	"Alt"	)
end -- fnc_key_prettify

local function fnc_key_build(RLctl, RLalt, shift, plain_key)
	return	(
	(RLctl and str_upper(RLctl).."Ctrl"	 or "")..
	(RLalt and str_upper(RLalt).."Alt"	 or "")..
	(shift and str_gsub (shift, "sh", "Sh")	 or "")..
	(plain_key and fnc_case_title(plain_key) or "")
		)
end -- fnc_key_build

local function fnc_hnd_mcr_condition(obj_handler, rec_key, mcr_src)
	local a1 = 1
	local b1 = 2
	local c1 = a1 + b1
	return not is_locked and (obj_handler.priority or true)
end -- fnc_hnd_mcr_condition

local function fnc_hnd_mcr_action(obj_handler, mcr_src)
	local a1 = 1
	local b1 = 2
	local c1 = a1 + b1
	local base_inp	= obj_handler.base_inp
	local base_vkc	= obj_handler.base_vkc 
	local mod_state = obj_handler.mod_state
	local state_key = obj_handler.state_key
	local a_key	= obj_handler.a_key
	local m_key	= obj_handler.m_key
	local is_hld_vk, is_rls_mod, is_timeout, run_normal
	is_hld_vk = fnc_is_holding(base_vkc)
	-- prevent autorepeat:
	fnc_eat_autorep(base_vkc)
	local area = str_lower(Area.Current)
	-- ?? inheritance (Autocompletion, Search)
	local has_dbl = obj_handler.key_ext.DBL 
	local has_hld = obj_handler.key_ext.HLD 
	local has_seq = obj_handler.key_ext.SEQ 
--	local is_mod  = k.mod[area] or k.mod.common -- todo extramod
	local next_key= "" -- have to be not null
	local t_start = Far.UpTime
	repeat
		is_rls_mod = fnc_is_released(mod_state)
		if is_rls_mod	then break end
		next_key = mf.waitkey(10)
		is_timeout = Far.UpTime - t_start > OPT_DELAY
		if next_key~="" then break end
		if is_timeout	then break end
	until false
	if	is_timeout
	then
		if	has_hld
		and	fnc_is_holding(base_vkc)
		then	if runMacro(a_key, ":Hold")
			then return
			end
		end
	elseif
		has_dbl
	and	next_key ~= ""
	and	string.lower(next_key) == string.lower(a_key)
	then
		fnc_eat_autorep(base_vkc)
		if runMacro(a_key, ":Double")
		then return
		end
	end
	local help_msg, help_ret
	if	has_seq
	then    -- ctrlaltshiftkey ==> CtrlAltShiftKey # todo (match) # DONE? @Xer0X
		a_key = mf.akey(1, 1)
		local obj_scr = far.SaveScreen()
		fnc_status_set(a_key)
		local end_key =
			--[[ to require ending key with modifiers:
			("^%s(.+)") --]]
			("^%s(.*)") 
			:format(state_key)
		repeat
			is_rls_mod = fnc_is_released(mod_state)
			if	is_rls_mod
			and	BREAK_SEQ_ON_MOD_RELEASE
			then	run_normal = true
				break
			end
			if	next_key ~= ""
			then
				far.RestoreScreen(obj_scr)
				local key2 = string.match(next_key, end_key)
				local key2_fix = key2 ~= "" and key2 or next_key
				-- false == BREAK_SEQ_ON_MOD_RELEASE
				if	runMacro(a_key, "-"..key2_fix)
				then	return
				elseif	key2_fix ~= next_key
				and	runMacro(a_key, "-"..next_key)
				then	return
				else	
					is_timeout = true
					run_normal = true
				end
				obj_scr = nil
				break
			end
			next_key = mf.waitkey(10)
			if not	help_msg
			and	Far.UpTime - t_start > OPT_DELAY_SEQ
			then
				is_timeout = true
				help_msg = getSeqHelp(a_key)
				if	help_msg
				then	help_ret = far.Message(help_msg, a_key, "", "l")
				else	run_normal = true
					break
				end
			end
		until false
		if obj_scr then far.RestoreScreen(obj_scr) end
	end -- if has_seq
	if not	is_timeout
	or	run_normal
	then
		is_locked = true
		runMacroOrKey(a_key)
		if next_key ~= ""
		then runMacroOrKey(next_key)
		end
		is_locked = false
		return
	end
	-- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
	fnc_status_set("anassigned")
	mf.beep()
	win.Sleep(100)
end -- fnc_hnd_mcr_action

-- register hotkey's handler
local function fnc_key_handler_set(key_area, key_full, key_base, ctl, alt, sft, plain_key, ext_mode, mcr)
	local m_key = fnc_key_build(ctl, alt, sft, plain_key)
	local a_key = fnc_key_build(
		str_lower(ctl or "") == "l" and "" or ctl,
		str_lower(alt or "") == "l" and "" or alt,
		str_lower(sft or ""),
		plain_key
	)
	local	base_inp =
			far.NameToInputRecord(a_key)
			or fnc_combo_mod_try(a_key)
	if not	base_inp
	then    if OPT_DEBUG
		then fnc_err_msg(("Unexpected AKey: %q"):format(a_key), mcr)
		end
		return
	end
	--[[ FarNameToInputRecord: "CtrlNumLock"-->VK_PAUSE
	http://bugs.farmanager.com/view.php?id=2947
	http://forum.farmanager.com/viewtopic.php?f=8&t=9357
        Комбинация клавиш CtrlNumLock для системы означает VK_PAUSE, но фар об этом не знает.]]
	if string.match(string.lower(a_key), "r?ctrlnumlock")
	then	base_inp = far.NameToInputRecord("Pause")
	end
	local	obj_handler = tbl_handlers[m_key]
	if not	obj_handler
	then	obj_handler = {
			description	= ("MacroEx handler for %s %q"):format(str_upper(key_area), m_key),
			id		= win.Uuid(win.Uuid()),
			key_area	= key_area,
			key_full	= key_full,
			m_key		= m_key,
			a_key		= a_key,
			state_key_tbl	= { ctl = ctl, alt = alt, sft = sft },
			state_key	= str_sub(a_key, 1, str_len(a_key) - str_len(plain_key)),
			plain_key	= plain_key,
			base_inp	= base_inp,
			base_vkc	= base_inp.VirtualKeyCode,
			has_plain	= base_inp.UnicodeChar ~= "\0",
			mod_state	= band(base_inp.ControlKeyState, MOD_MASK),
			key_ext		= { },
			macros		= { },
			fnc_condition	= function(rec_key, mcr_src)
				return fnc_hnd_mcr_condition(obj_handler, rec_key, mcr_src)
			end,
			fnc_action	= function(mcr_src)
				return fnc_hnd_mcr_action(obj_handler, mcr_src)
			end
		}
		tbl_handlers[m_key] = obj_handler
	end
	obj_handler.priority = math_max(obj_handler.priority or 0, (mcr.priority or 50) + 5)
	obj_handler.key_ext[ext_mode] = true
	if not	obj_handler.macros[key_full]
	then	obj_handler.macros[key_full] = { mcr }
	else	table.insert(obj_handler.macros[key_full], mcr)
        end
	return obj_handler
end -- fnc_key_handler_set

--[[ have to be base key, as in "CtrlRAltA" is "A":
local rgx_key_parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)$")
--[=[! have NOT to be base key, as in "CtrlRAltA" is NiL:]]
local rgx_key_parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$")
--[[ todo:
local rgx_key_parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$")
return rgx_key_parse:match(("LCtrlRAlt"):lower())
--]]

local function fnc_macro_ex_create(tbl_handlers)
	for ii, ii_handler in pairs(tbl_handlers)
	do	Macro { description	= ii_handler.description,
			id		= ii_handler.id,
			area		= ii_handler.key_area,
			key		= ii_handler.m_key,
			priority	= ii_handler.priority,
			action		= ii_handler.fnc_action,
			condition	= ii_handler.fnc_condition,
			ext_key_hnd	= ii_handler,
			FileName	= FileName,
		}
	end
end

local function fnc_expand_key(key_base, ext_mode)
--	assert(key:match("^%l+$"))
	local tbl_exp = { }
	local RLctl, RLalt, shift, plain_key = rgx_key_parse:match(str_lower(key_base))
	if	plain_key == false
	then	plain_key = ""
	end
	local ctl, alt
	ctl = RLctl == "" and "L"
	repeat
	alt = RLalt == "" and "L"
	repeat
	local tbl_key = {
		ctl = ctl or RLctl,
		alt = alt or RLalt,
		sft = shift,
		key = plain_key,
		ext = ext_mode,
	}
	tbl_key.str = str_format(KEY_VIS_FMT, tbl_key.ctl or "0", tbl_key.alt or "0", tbl_key.sft or "0", tbl_key.ext, tbl_key.key)
	tbl_exp[tbl_key.str] = tbl_key
	alt = str_lower(alt or "") == "l" and "R"
	until not alt
	ctl = str_lower(ctl or "") == "l" and "R"
	until not ctl
	return tbl_exp
end -- fnc_expand_key

local function fnc_build_key(key_area, key_full, key_base, ext_mode, mcr)
	local tbl_ret = { }
	local tbl_exp = fnc_expand_key(key_base, ext_mode)
	for ii, ii_key in pairs(tbl_exp)
	do tbl_ret[ii_key.str] = fnc_key_handler_set(key_area, key_full, key_base, ii_key.ctl, ii_key.alt, ii_key.sft, ii_key.key, ii_key.ext, mcr)
	end
	return tbl_ret
end -- fnc_build_key

local function fnc_macro_ex_check_one(mcr, create_handlers)
	local tbl_res = { }
	for ii, ii_key in pairs(fnc_str_split(str_lower(mcr.key), "%s+", true))
	do	local	ii_key_base, ii_ext_mode = str_match(ii_key, "^(.+):(.+)$")
		ii_ext_mode = ii_ext_mode and tbl_ext_mode_code[ii_ext_mode]
		if not	ii_ext_mode
		then	ii_key_base = false
		end
		if not	ii_key_base
		then	ii_key_base = ii_key:match("^(.+)%-.")
			ii_ext_mode = "SEQ"
		end
		if	ii_key_base
		then	for jj, jj_area in pairs(fnc_str_split(str_lower(mcr.area), "%s+", true))
			do	local tbl_exp = fnc_build_key(jj_area, ii_key, ii_key_base, ii_ext_mode, mcr)
				for kk, kk_val in pairs(tbl_exp)
				do tbl_res[#tbl_res + 1] = kk_val
				end
			end
		end
	end
	if	create_handlers
	then	fnc_macro_ex_create(tbl_res)
	end
	return	tbl_res
end -- fnc_macro_ex_check_one

local function fnc_macro_ex_build_all()
	for ii = 1, #Xer0X.utils.LoadedMacros
	do	local	ii_mcr = Xer0X.utils.LoadedMacros[ii]
		if	ii_mcr.key
		and not ii_mcr.keyregex
		then	fnc_macro_ex_check_one(ii_mcr)
		end
	end
	fnc_macro_ex_create(tbl_handlers)
	return	tbl_handlers
end -- fnc_macro_ex_build_all

--[=[ need to be the last call,
so that all other macros loaded already: ]=]
mf.postmacro(fnc_macro_ex_build_all)

-- @@@@@
