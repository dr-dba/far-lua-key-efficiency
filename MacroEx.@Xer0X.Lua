--[[
if true then return end --]]

--[[
DEPENDS ON MODULES:
https://github.com/dr-dba/far-lua-internals
introspection-@Xer0X.lua
https://github.com/dr-dba/far-lua-general-utils
Lib-Common-@Xer0X.Lua
https://github.com/dr-dba/far-lua-diagnostics
StackTracePlusPlus-@Xer0X.Lua

TODO

]]
-- luacheck: ignore 113/Info
local Info = Info or package.loaded.regscript or function(...) return ... end
local nfo = Info({
	_filename or ...,
	name		= "MacroEx",
	-- запуск макросов нетрадиционными способами
	description	= "Launching macros in unconventional ways (+@Xer0X mod)",
	id		= "35FD5420-D2A1-4A1C-AAFD-4C902231F549",
	version		= "3.2",
	version_mod	= "1.3.3",
	author		= "JD",
	author_mod	= "x-Team",
	url		= "http://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "http://forum.farmanager.com/viewtopic.php?f=15&t=12459",
	url_git		= "https://github.com/dr-dba/far-lua-key-efficiency",
	-- LuaMacro 501 (ConsoleInput)
	minfarversion	= { 3, 0, 0, 4430, 0 },
	options		= {
		break_seq_on_mod_release
				= false,
		allow_seq_with_any_mod
				= true,
		allow_seq_in_ext= true,
		Delay		=  400, 
		DelaySeq	= 5000,
		ext_modes 	= {
			HLD = true, -- holding
			DBL = true, -- double
		},
		Debug		= false,
	}
})
if not nfo then return end
local opts = nfo.options
local BREAK_SEQ_ON_MOD_RELEASE	= opts.break_seq_on_mod_release
local ALLOW_SEQ_WITH_ANY_MOD	= opts.allow_seq_with_any_mod
local ALLOW_SEQ_IN_EXT		= opts.allow_seq_in_ext
local OPT_DEBUG			= opts.Debug
local OPT_DELAY_SEQ		= opts.DelaySeq
local OPT_DELAY			= opts.Delay
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
local	tbl_ext_mode_code = { double = "DBL", hold = "HLD" }
local	Xer0X = require("Lib-Common-@Xer0X")
local	req_ok, req_msg, fnc_lua_exp	= Xer0X.fnc_safe_require("LuaExplorer-@Xer0X")
if not	req_ok
then	req_ok, req_msg, fnc_lua_exp	= Xer0X.fnc_safe_require("LE")
end
local	as_mdl, inp_args, own_fpath	= Xer0X.fnc_file_whoami({ ... })
local	FileName = ... or own_fpath
local	Macro = Macro
local	Event = Event
local	tbl_mcr_env, tbl_mcr_exinf
if not	Macro
then	tbl_mcr_env, tbl_mcr_exinf	= Xer0X.fnc_macro_one_load(nil, own_fpath, false, true)
	Macro = tbl_mcr_env.Macro
	Event = tbl_mcr_env.Event
end

local fnc_str_split	= Xer0X.fnc_str_split
local fnc_tbl_copy_to	= Xer0X.fnc_tbl_copy_to
local fnc_tbl_count	= Xer0X.fnc_tbl_count
local fnc_case_title 	= Xer0X.fnc_case_title
local fnc_case_toggle	= Xer0X.fnc_case_toggle

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
local tbl_insert= table.insert
local mf_waitkey= mf.waitkey
local win_uuid	= win.Uuid

local KEY_VIS_FMT	= "c:%s/a:%s/s:%s/p:%s"
local obj_status	= Xer0X.obj_screen_status_line
local	tbl_handlers	= Xer0X.tbl_macro_ex_handlers
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

local function fnc_eat_autorep(vkc) no_repeat = vkc end

local function fnc_is_holding(vkc) return no_repeat == vkc end

Event {	description = "MacroEx helper",
	group = "ConsoleInput",
	action = function(inp_rec)
		if	no_repeat
		and	inp_rec.EventType == F.KEY_EVENT
		and	inp_rec.VirtualKeyCode ~= 0
		then	-- KEY_NONE? inp_rec.VirtualKeyCode == 0
			if	inp_rec.VirtualKeyCode == no_repeat
			and	inp_rec.KeyDown
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

local tbl_key_hlp_cache = { }
-- ?? premake help or store macros
local function fnc_get_seq_hlp(seq_key)
	local	txt_help = tbl_key_hlp_cache[seq_key]
	if	txt_help ~= nil
	then	return txt_help
	end
	local tbl_help	= { }
	local area_re	= "%f[%a]"..string.lower(Area.Current).."%f[%A]"
	local key_re	= "%f[%a]"..string.lower(seq_key).."%-"
	for ii = 1, #Xer0X.utils.LoadedMacros
	do
		local	ii_mcr = Xer0X.utils.LoadedMacros[ii] 
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
					tbl_insert(tbl_help, ii_mcr.description or ii_mcr.key)
				end
			end
		end
	end
	txt_help = next(tbl_help) and table.concat(tbl_help, "\n") or false
	tbl_key_hlp_cache[seq_key] = txt_help
	return txt_help
end -- fnc_get_seq_hlp

local function runMacro(key, Ex)
	local	eval_res = eval(key..Ex, 2)
	return	eval_res ~= -2, eval_res
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

local function fnc_key_concat(RLctl, RLalt, shift, plain_key)
	return	(
	(RLctl and str_upper(RLctl).."Ctrl"	 or "")..
	(RLalt and str_upper(RLalt).."Alt"	 or "")..
	(shift and str_gsub (shift, "sh", "Sh")	 or "")..
	(plain_key and fnc_case_title(plain_key) or "")
		)
end -- fnc_key_concat

local function fnc_hnd_mcr_condition(obj_handler, rec_key, mcr_src)
	return not is_locked and (obj_handler.priority or true)
end -- fnc_hnd_mcr_condition

local obj_waitkeys = {
	keys = { },
	init = function(self)
		self.keys = { }
		self.no_key = nil
	end,
	save = function(self, ...)
		local	the_key = mf_waitkey(...)
		local	has_key = the_key ~= ""
		local	isNewOn = self.no_key and has_key
		self.no_key = not has_key
		if	the_key ~= ""
		then	tbl_insert(self.keys, the_key)
		end
		return	the_key, Far.UpTime
	end
}

local function fnc_hnd_mcr_action(obj_handler, mcr_src)
	local base_inp	= obj_handler.base_inp
	local mod_state = obj_handler.mod_state
	local state_key = obj_handler.state_key.str
	local a_key	= obj_handler.a_key
	local m_key	= obj_handler.m_key
	local base_vkc	= base_inp.VirtualKeyCode
	-- prevent autorepeat:
	fnc_eat_autorep(base_vkc)
	obj_waitkeys:init()
	local was_hld, was_dbl, ext_hld, ext_dbl, is_rls_mod, is_timeout, run_normal, anassigned_msg
	local a_key_real = mf.akey(1, 0)
	local a_key_show = mf.akey(1, 1)
	local t_key_ex_start = Far.UpTime
	local area = str_lower(Area.Current)
	-- ?? inheritance (AutoCompletion, Search)
	local next_key = "" -- have to be not null
	local t_wait_key = t_key_ex_start
	local has_dbl = obj_handler.key_ext.DBL 
	local has_hld = obj_handler.key_ext.HLD 
--	local is_mod  = k.mod[area] or k.mod.common -- todo extramod
	if	has_dbl
	or	has_hld
	then	repeat
			is_rls_mod = fnc_is_released(mod_state)
			if is_rls_mod	then break end
			next_key, t_wait_key = obj_waitkeys:save(10)
			is_timeout = t_wait_key - t_key_ex_start > OPT_DELAY
			if next_key~="" then break end
			if is_timeout	then break end
		until false
		was_hld = is_timeout and fnc_is_holding(base_vkc)
		was_dbl = str_lower(next_key) == str_lower(a_key)
		ext_hld = was_hld and has_hld
		ext_dbl = was_dbl and has_dbl
		if	ext_hld
		and	has_hld.scripts
		and     has_hld.scripts.exists > 0
		then    local eval_ok, eval_res = runMacro(a_key, ":Hold")
			obj_status:set(a_key..":Hold "..eval_res, nil, 1000)
			return
		end
		if	ext_dbl
		and	has_dbl.scripts
		and	has_dbl.scripts.exists > 0
		then	local eval_ok, eval_res = runMacro(a_key, ":Double")
			obj_status:set(a_key..":Double "..eval_res, nil, 1000)
			return
		end
	end
	local	has_seq
	if	ALLOW_SEQ_IN_EXT
	and	ext_hld
	and	ext_hld.SEQ
	then	has_seq = ext_hld.SEQ
		next_key = ""
	end
	if	ALLOW_SEQ_IN_EXT
	and not	has_seq
	and	ext_dbl
	and	ext_dbl.SEQ
	then	has_seq = ext_dbl.SEQ
		next_key = ""
	end
	if not	has_seq
	then	has_seq = obj_handler.key_ext.SEQ 
	end
	if	has_seq
	then
		-- ctrlaltshiftkey ==> CtrlAltShiftKey # todo (match) # DONE? @Xer0X
		a_key_show = a_key_show..(
			ext_hld and ":Hold"	or
			ext_dbl and ":Double"	or
			"")
		local obj_scr = far.SaveScreen()
		local end_key_fmt =
			--[[ to require ending key with modifiers:
			("^%s(.+)") --]]
			("^%s(.*)") 
			:format(state_key)
		local str_seq_chain, seq_hlp_msg
		local t_last_key = t_wait_key
		local ii_key_seq = has_seq
		repeat
			obj_status:set(a_key_show..(str_seq_chain or "").."-..?", nil, 1000)
			is_rls_mod = fnc_is_released(mod_state)
			if	is_rls_mod
			and	BREAK_SEQ_ON_MOD_RELEASE
			then	run_normal = true
				break
			end
			if	next_key == ""
			then	--	try_seq_wait = true -- ? @Xer0X
				if t_wait_key - t_last_key > OPT_DELAY_SEQ
				then
					is_timeout = true
					seq_hlp_msg = fnc_get_seq_hlp(a_key_show)
					if	seq_hlp_msg
					then	obj_status:stop()
						far.Message(seq_hlp_msg, a_key_show, "", "l")
					else	run_normal = true
						anassigned_msg = str_format("%s%s No scripts assigned", a_key_show, str_seq_chain or "")
						break
					end
				end
			else	-- got the next key
				t_last_key = t_wait_key
				local	key2_run -- :that will be the key to launch
				-- extract new received (next) key without modifiers:
				local	key2 = str_match(next_key, end_key_fmt)
				--[[ control state of received key is different
				from the starting input, what want we do? ]]
				if	key2 == ""
				or	key2 == nil
				-- looks like key state prefix was changed
				then	if	BREAK_SEQ_ON_MOD_RELEASE
					-- on changing CtlAlt modifiers consider it as breaking sequence:
					then	run_normal = true
						break
					--[[ release of control (ctl+alt) keys allowed,
					so we just take it as a whole:]]
					else	key2_run = next_key
					end
				--[[ contol state in sequence key was not changed,
				thus we run the read (received) key as it is:]]
				else	key2_run = key2
				end
				local	obj_key2_seq = ii_key_seq[str_lower(key2_run)]
				if	obj_key2_seq
				then	str_seq_chain = (str_seq_chain or "").."-"..key2_run
				else	obj_key2_seq = ii_key_seq[str_lower(next_key)]
					str_seq_chain = (str_seq_chain or "").."-"..next_key
				end
				if	obj_key2_seq -- ? is it registered sequence key
				then	obj_status:set(str_format("%s%s Run ?", a_key_show, str_seq_chain), nil, 1000000)
					if 	obj_key2_seq.scripts
					and	obj_key2_seq.scripts.exists > 0
					--[[ the registered sequence is finalized here:
						fnc_tbl_count(obj_key2_seq.scripts) > 0
					.. so run it:]]
					then	local eval_ok, eval_res = runMacro(a_key_show, str_seq_chain)
						far.RestoreScreen(obj_scr); obj_scr = nil
						obj_status:set(str_format("%s%s Run %s", a_key_show, str_seq_chain, eval_res), nil, 3000)
						return
					end
					--[[ have we any continue for the sequence?
					BTW, here we may go to DBL/HLD paths]]
					ii_key_seq = obj_key2_seq.SEQ
					if not	ii_key_seq
					then	-- all done, no further sequences
						return
					else	-- continue to the next sequenced key
					end
				else	--[[ the received key is not registered,
					thus the sequence is broken,
					run all previous keys as "normal" and exit:]]
					run_normal = true
					break
				end
				--[[ an alternative way to define want we state breaking:
				local key2_run = key2 ~= "" and key2 or next_key
				--! false == BREAK_SEQ_ON_MOD_RELEASE
				if	runMacro(a_key_show, "-"..key2_fix)
				then	return
				elseif	key2_fix ~= next_key
				and	runMacro(a_key_show, "-"..next_key)
				then	return
				else	-- set timeout var to prevent key post..
					is_timeout = true
					run_normal = true
				end
				break --]]
			end
			next_key, t_wait_key = obj_waitkeys:save(10)
		until false
		if obj_scr then far.RestoreScreen(obj_scr) end
	end -- "if has_seq"
	if not	is_timeout
	or	run_normal
	then
		is_locked = true
		local run_res = runMacroOrKey(a_key_real)
		for ii = 1, #obj_waitkeys.keys
		do run_res = runMacroOrKey(obj_waitkeys.keys[ii])
		end
		--[[ the old fashion, no multi-sequences:
		if next_key ~= ""
		then runMacroOrKey(next_key)
		end --]]
		is_locked = false
		obj_status:set(anassigned_msg or str_format(
			"%s anassigned, run_norm: %s, timeout: %s, next_key: %s",
			a_key, tostring(run_normal), tostring(is_timeout), tostring(next_key)
				), nil, 3000)
		return
	end
	-- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
	obj_status:set(anassigned_msg or a_key.." is anassigned", nil, 3000)
	mf.beep()
	--[[ needed?
	win.Sleep(100) --]]
end -- fnc_hnd_mcr_action

local function fnc_copy_key_ext(tbl_from, tbl_from_loc, tbl_dest, tbl_dest_loc, copy_key_idx, copy_key_val)
	if	copy_key_idx == "id"
	-- that is macro object to merge:
	and	copy_key_val == tbl_from_loc.id
	then	tbl_dest.exists = (tbl_dest.exists or 0) + 1
	end
	tbl_dest_loc[copy_key_idx] = copy_key_val
end

-- register hotkey's handler
local function fnc_key_handler_set(key_area, key_full, key_base, ctl, alt, sft, plain_key, tbl_ext, obj_mcr)
	local m_key = fnc_key_concat(ctl, alt, sft, plain_key)
	local a_key = fnc_key_concat(
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
		then fnc_err_msg(("Unexpected AKey: %q"):format(a_key))
		end
		return
	end
	--[[ FarNameToInputRecord: "CtrlNumLock"-->VK_PAUSE
	http://bugs.farmanager.com/view.php?id=2947
	http://forum.farmanager.com/viewtopic.php?f=8&t=9357
	Комбинация клавиш CtrlNumLock для системы означает VK_PAUSE, но фар об этом не знает.]]
	if str_match(str_lower(a_key), "r?ctrlnumlock")
	then	base_inp = far.NameToInputRecord("Pause")
	end
	local	obj_handler = tbl_handlers[m_key]
	if not	obj_handler
	then	obj_handler = {
			description	= ("MacroEx handler for %s %q"):format(str_upper(key_area), m_key),
			key_area	= key_area,
			key_full	= key_full,
			m_key		= m_key,
			a_key		= a_key,
			state_key	= {
				ctl = ctl, alt = alt, sft = sft,
				str = str_sub(a_key, 1, str_len(a_key) - str_len(plain_key))
			},
			plain_key	= plain_key,
			base_inp	= base_inp,
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
	obj_handler.priority = math_max(obj_handler.priority or 0, (obj_mcr.priority or 50) + 5)
	obj_handler.key_ext = fnc_tbl_copy_to(tbl_ext, obj_handler.key_ext, fnc_copy_key_ext)
	if not	obj_handler.macros[key_full]
	then	obj_handler.macros[key_full] = { [obj_mcr.id] = obj_mcr }
	else	obj_handler.macros[key_full][obj_mcr.id] = obj_mcr
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

local function fnc_key_expand(key_base, in_lower)
--	assert(key:match("^%l+$"))
	local RLctl, RLalt, shift, plain = rgx_key_parse:match(str_lower(key_base))
	local tbl_exp = { }
	local ctl, alt
	ctl = RLctl == "" and (in_lower and "l" or "L")
	repeat
	alt = RLalt == "" and (in_lower and "l" or "L")
	repeat
	local tbl_key = {
		ctl = ctl or RLctl,
		alt = alt or RLalt,
		sft = shift,
		key = plain or "",
	}
	tbl_key.str = str_lower(str_format(KEY_VIS_FMT, tbl_key.ctl or "0", tbl_key.alt or "0", tbl_key.sft or "0", tbl_key.key))
	tbl_exp[tbl_key.str] = tbl_key
	alt = str_lower(alt or "") == "l" and (in_lower and "r" or "R")
	until not alt
	ctl = str_lower(ctl or "") == "l" and (in_lower and "r" or "R")
	until not ctl
	return tbl_exp
end -- fnc_key_expand

local function fnc_key_equal(key_base, key_comp)
	local tbl_base = type(key_base) == "table" and key_base or fnc_key_expand(key_base, true)
	local tbl_comp = type(key_comp) == "table" and key_comp or fnc_key_expand(key_comp, true)
	for ii_base in pairs(tbl_base) do
	for ii_comp in pairs(tbl_comp) do
	if	str_lower(ii_base)
	==	str_lower(ii_comp)
	then return
		str_lower(ii_comp)
	end
	end
	end
	return false
end -- fnc_key_equal

local function fnc_key_build(key_area, key_full, key_base, tbl_ext, obj_mcr)
	local tbl_ret = { }
	local tbl_exp = fnc_key_expand(key_base)
	for ii, ii_key in pairs(tbl_exp)
	do tbl_ret[ii_key.str] = fnc_key_handler_set(key_area, key_full, key_base, ii_key.ctl, ii_key.alt, ii_key.sft, ii_key.key, tbl_ext, obj_mcr)
	end
	return tbl_ret
end -- fnc_key_build


local function fnc_macro_ex_check_one(obj_mcr, create_handlers)
	local tbl_res = { }
	local id_ext = obj_mcr.id ~= "<no id>" and obj_mcr.id or str_upper(win_uuid(win_uuid()))
	for ii, ii_key in pairs(fnc_str_split(str_lower(obj_mcr.key), "%s+", true))
	do	local tbl_ext = { }
		local tbl_ext_jj = tbl_ext
		local ii_key_trig, jj_key_base, jj_ext_mode
		if str_match(ii_key, "^%-") then ii_key = str_gsub(ii_key, "^%-", "<MINUS>") end
		if str_match(ii_key, "%-$") then ii_key = str_gsub(ii_key, "%-$", "<MINUS>") end
		if str_match(ii_key, "%-%-")then ii_key = str_gsub(ii_key, "%-%-","<MINUS>-")end
		local	jj = 0
		for	jj_key_seq in	str_gmatch(ii_key.."-", "([^-]*)-")
		do	jj_key_seq =	str_gsub(jj_key_seq, "<MINUS>", "-")
			jj = jj + 1
			jj_key_base, jj_ext_mode = str_match(jj_key_seq, "^(.+):(.+)$")
			if	jj_ext_mode
			then	-- here ext_mode supposed to be HLD or DBL
				jj_ext_mode = tbl_ext_mode_code[jj_ext_mode]
				if not	jj_ext_mode
				then	jj_key_base = nil
					jj_ext_mode = nil
				end
			end
			if not	jj_key_base
			then	jj_key_base = jj_key_seq
			end
			if	jj == 1
			then	ii_key_trig = jj_key_base
				if	jj_ext_mode
				then	tbl_ext_jj[jj_ext_mode] = { }
					if	ALLOW_SEQ_IN_EXT
					then	tbl_ext_jj = tbl_ext_jj[jj_ext_mode]
					end
				end
			else	if	jj_ext_mode
				then	tbl_ext_jj.SEQ = { [jj_key_base] = { [jj_ext_mode] = { } } }
				else	tbl_ext_jj.SEQ = { [jj_key_base] = { } }
				end
				if	jj_ext_mode
				and	ALLOW_SEQ_IN_EXT
				then	tbl_ext_jj = tbl_ext_jj.SEQ[jj_key_base][jj_ext_mode]
				else	tbl_ext_jj = tbl_ext_jj.SEQ[jj_key_base]
				end
			end
		end
		if	tbl_ext.SEQ
		or	tbl_ext.DBL
		or	tbl_ext.HLD
		then	-- the last part of key sequence:
			tbl_ext_jj.scripts = { [id_ext] = obj_mcr }
			if not	obj_mcr.id
			or	obj_mcr.id == "<no id>"
			-- have to have id, i.e. reloading or detecting
			then	obj_mcr.id = id_ext
			end
			for kk, kk_area in pairs(fnc_str_split(str_lower(obj_mcr.area), "%s+", true))
			do	local tbl_exp = fnc_key_build(kk_area, ii_key, ii_key_trig, tbl_ext, obj_mcr)
				for ll, ll_val in pairs(tbl_exp)
				-- just save it in the output table variable:
				do tbl_res[#tbl_res + 1] = ll_val
				end
			end
		end
	end
	if	create_handlers
	then	fnc_macro_ex_create(tbl_res)
	end
	return tbl_res
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
	return tbl_handlers
end -- fnc_macro_ex_build_all

if	as_mdl
then
else
--[=[ need to be the last call,
so that all other macros loaded already: ]=]
mf.postmacro(fnc_macro_ex_build_all)
end

-- @@@@@
