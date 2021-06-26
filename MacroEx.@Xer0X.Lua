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
]]

-- ### OPTIONS BLOCK ###

-- luacheck: ignore 113/Info
local Info = Info or package.loaded.regscript or function(...) return ... end
local nfo = Info({
	_filename or ...,
	name		= "MacroEx",
	-- запуск макросов нетрадиционными способами
	description	= "Launching macros in unconventional ways (+@Xer0X mod)",
	id		= "35FD5420-D2A1-4A1C-AAFD-4C902231F549",
	version		= "3.2",
	version_mod	= "1.5.9",
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

-- @@@ END OF THE OPTIONS BLOCK @@@

local BREAK_SEQ_ON_MOD_RELEASE	= opts.break_seq_on_mod_release
local ALLOW_SEQ_WITH_ANY_MOD	= opts.allow_seq_with_any_mod
local ALLOW_SEQ_IN_EXT		= opts.allow_seq_in_ext
local OPT_DEBUG			= opts.Debug
local OPT_DELAY_SEQ		= opts.DelaySeq
local OPT_DELAY			= opts.Delay
local F	= far.Flags
local C = far.Colors
local EVAL_SUCCESS       =  0
local EVAL_SYNTAXERROR   = 11
local EVAL_BADARGS       = -1
local EVAL_MACRONOTFOUND = -2
local EVAL_MACROCANCELED = -3
local EVAL_RUNTIMEERROR  = -4
local EVAL_RES = {
	 [EVAL_SUCCESS]		= "EVAL_SUCCESS"	--  0
	,[EVAL_SYNTAXERROR]	= "EVAL_SYNTAXERROR"	-- 11
	,[EVAL_BADARGS]		= "EVAL_BADARGS"	-- -1
	,[EVAL_MACRONOTFOUND]	= "EVAL_MACRONOTFOUND"	-- -2 макрос не найден среди загруженных макросов
	,[EVAL_MACROCANCELED]	= "EVAL_MACROCANCELED"	-- -3 было выведено меню выбора макроса, и пользователь его отменил
	,[EVAL_RUNTIMEERROR]	= "EVAL_RUNTIMEERROR"	-- -4 макрос был прерван в результате ошибки времени исполнения
}
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
local	tbl_ext_mode_code = { double = "DBL",	hold = "HLD" }
local	tbl_ext_mode_show = { DBL = ":Double",	HLD = ":Hold"}
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
local fnc_key_prettify	= Xer0X.fnc_key_prettify

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
local mf_akey	= mf.akey
local win_uuid	= win.Uuid

local KEY_VIS_FMT	= "c:%s/a:%s/s:%s/p:%s"
local KEY_STR_FMT	= "%s%s%s%s"
local KEY_CAS_FMT	= "%s%s%s"
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
	local area_re	= "%f[%a]"..str_lower(Area.Current).."%f[%A]"
	local key_re	= "%f[%a]"..str_lower(seq_key).."%-"
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
	return	eval_res ~= EVAL_MACRONOTFOUND, eval_res
end

local function runMacroOrKey(key)
	local	eval_res = eval(key, 2)
	if	eval_res == EVAL_MACRONOTFOUND
	then	Keys(key)
	end
	return	eval_res
end

local rgx_combo = regex.new("^((?:[rl]?ctrl)?(?:[rl]?alt)?(?:shift)?)((?:shift)|(?:alt))$", "i")
local function fnc_combo_mod_try(key)
	local	combo_mod,
		combo_key = rgx_combo:match(key)
	if	combo_mod
	then	local	m = far.NameToInputRecord(combo_mod.."a")
		local	k = far.NameToInputRecord(combo_key)
		if	m
		and	k
		then	return {ControlKeyState	= m.ControlKeyState,
				VirtualKeyCode	= k.VirtualKeyCode}
		end
	end
end -- fnc_combo_mod_try

--[[ have to be base key, as in "CtrlRAltA" is "A":
local rgx_key_parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)$")
--[=[! have NOT to be base key, as in "CtrlRAltA" is NiL:]]
local rgx_key_parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$")
--[[ todo:
local rgx_key_parse = regex.new("^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$")
return rgx_key_parse:match(("LCtrlRAlt"):lower())
--]]

local function fnc_key_expand(key_base, in_lower, str_id, as_received)
--	assert(key:match("^%l+$"))
	local R =	in_lower and "r"	or "R"
	local L	=	in_lower and "l"	or "L"
	local ALT =	in_lower and "alt"	or "Alt"
	local CTL =	in_lower and "ctrl"	or "Ctrl"
	local NONE=	in_lower and "<none>"	or "<NONE>"
	local RLctl, RLalt, shift, plain = rgx_key_parse:match(str_lower(key_base))
	local tbl_exp = { }
	local ctl, alt, sft, ctl2, alt2, key
	ctl = RLctl == "" and L -- (in_lower and "l" or "L")
	repeat
	alt = RLalt == "" and L -- (in_lower and "l" or "L")
	repeat
	ctl2 = ctl or RLctl
	alt2 = alt or RLalt
	key = plain or ""
	local tbl_key = { ctl = ctl2, alt = alt2, sft = shift, key = key }
	tbl_key.vis	= str_lower(str_format(KEY_VIS_FMT,
		ctl2 or 0,
		alt2 or 0,
		shift and 1 or 0,
		plain or NONE))
	tbl_key.str	= str_format(KEY_STR_FMT,
		ctl2 and ctl2..CTL or "",
		alt2 and alt2..ALT or "",
		shift or "", key)
	tbl_key.rec	= str_format(KEY_STR_FMT,
		ctl2 and (ctl2 == R and R or "")..CTL or "",
		alt2 and (alt2 == R and R or "")..ALT or "",
		shift or "", key)
	tbl_key.rec_cas = str_format(KEY_STR_FMT,
		ctl2 and (ctl2 == R and R or "")..CTL or "",
		alt2 and (alt2 == R and R or "")..ALT or "",
		shift or "", "")
	tbl_key.cas	= str_format(KEY_CAS_FMT,
		ctl2 and ctl2..CTL or "",
		alt2 and alt2..ALT or "",
		shift or "")
	tbl_exp[str_id and tbl_key.str or tbl_key.vis] = tbl_key
	alt = str_lower(alt or "") == L and not as_received and R 
	until not alt
	ctl = str_lower(ctl or "") == L and not as_received and R 
	until not ctl
	return tbl_exp
end -- fnc_key_expand

local function fnc_key_equal(key_base, key_comp)
	local tbl_base = type(key_base) == "table" and key_base or fnc_key_expand(key_base, true)
	local tbl_comp = type(key_comp) == "table" and key_comp or fnc_key_expand(key_comp, true)
	for ii_base, ii_base_val in pairs(tbl_base) do
	for ii_comp, ii_comp_val in pairs(tbl_comp) do
	if	str_lower(ii_base)
	==	str_lower(ii_comp)
	then return
		str_lower(ii_comp), ii_comp_val
	end
	end
	end
	return false
end -- fnc_key_equal


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
	local mod_state = obj_handler.mod_state
	local m_key	= obj_handler.m_key
	local base_vkc	= obj_handler.base_inp.VirtualKeyCode
	-- prevent autorepeat:
	fnc_eat_autorep(base_vkc)
	obj_waitkeys:init()
	local was_hld, was_dbl, obj_ext, str_ext, is_rls_mod, res_rls_mod, new_rls_mod, cur_rls_mod, is_timeout, run_normal, anassigned_msg
	local a_key_real = mf_akey(1, 0)
	local a_key_show = mf_akey(1, 1)
	local t_key_ex_start = Far.UpTime
	local area = str_lower(Area.Current)
	-- ?? inheritance (AutoCompletion, Search)
	local next_key = "" -- have to be not null
	local t_wait_key = t_key_ex_start
--	local is_mod  = k.mod[area] or k.mod.common -- todo extramod
	if	obj_handler.key_ext.EXT -- just a flag for the extended mode existence here
	then	repeat
			is_rls_mod, res_rls_mod, new_rls_mod, cur_rls_mod = fnc_is_released(mod_state)
			if is_rls_mod	then break end
			next_key, t_wait_key = obj_waitkeys:save(10)
			if next_key~="" then break end
			is_timeout = t_wait_key - t_key_ex_start > OPT_DELAY
			if is_timeout	then break end
		until false
		was_hld = is_timeout and fnc_is_holding(base_vkc)
		was_dbl = fnc_key_equal(next_key, a_key_real)
		str_ext =
			was_hld and obj_handler.key_ext.HLD and "HLD" or-- [area] or obj_handler.HLD.common
			was_dbl and obj_handler.key_ext.DBL and "DBL"	-- [area] or obj_handler.DBL.common
		obj_ext = str_ext and obj_handler.key_ext[str_ext]
		if	obj_ext
		and	obj_ext.SCR
		then    local	eval_ok, eval_res = runMacro(a_key_real, tbl_ext_mode_show[str_ext])
			if not	eval_ok
			and	eval_res == -2
			then	-- just take the first macro object:
				local scr_key, scr_mcr = next(obj_ext.SCR)
				eval_res = eval(scr_key, 2)
				eval_ok = eval_res ~= EVAL_MACRONOTFOUND
			end
			obj_status:set(a_key_real..tbl_ext_mode_show[str_ext].." "..eval_res.."/"..EVAL_RES[eval_res], nil, 1000)
			return
		end
	end
	local	has_seq
	if	ALLOW_SEQ_IN_EXT
	and	obj_ext
	and	obj_ext.SEQ
	then	has_seq = obj_ext.SEQ
		next_key = ""
	else	has_seq = obj_handler.key_ext.SEQ -- [area] or obj_handler.SEQ.common
	end
	if	has_seq
	then
		-- ctrlaltshiftkey ==> CtrlAltShiftKey # todo (match) # DONE? @Xer0X
		a_key_show = a_key_show..(str_ext and tbl_ext_mode_show[str_ext] or "")
		local obj_scr = far.SaveScreen()
		local end_key_fmt =
			--[[ to require ending key with modifiers:
			("^%s(.+)") --]]
			("^%s(.*)") 
			:format(obj_handler.key_ext.KXP.rec_cas)
		local sz_seq_chain, seq_hlp_msg
		local t_last_key = t_wait_key
		local ii_key_seq = has_seq
		repeat
			obj_status:set(a_key_show..(sz_seq_chain or "").."-..?", nil, 1000)
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
						anassigned_msg = str_format("%s%s No scripts assigned", a_key_show, sz_seq_chain or "")
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
				-- Looks like key state prefix was changed
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
				local	key2_run_exp = fnc_key_expand(key2_run, "in_lower", "real_key_str", "received")
				local	next_key_exp, key2_run_seq
				local	str_next_seq,
					obj_key2_seq = fnc_key_equal(key2_run_exp, ii_key_seq)
				if	obj_key2_seq
				then	key2_run_seq = true
				elseif	next_key ~= key2_run
				and not BREAK_SEQ_ON_MOD_RELEASE
				then 
					next_key_exp = fnc_key_expand(next_key, "in_lower", "real_key_str", "received")
					str_next_seq,
					obj_key2_seq = fnc_key_equal(next_key_exp, ii_key_seq)
				end
				if	obj_key2_seq -- ? is it registered sequence key
				then	sz_seq_chain = (sz_seq_chain or "").."-"..(key2_run_seq and key2_run or next_key)
					obj_status:set(str_format("%s%s Run ?", a_key_show, sz_seq_chain), nil, 1000000)
					if 	obj_key2_seq.SCR
					--[[ the registered sequence is finalized here:
						fnc_tbl_count(obj_key2_seq.SCR) > 0
					.. so run it:]]
					then	local	eval_ok, eval_res = runMacro(a_key_show, sz_seq_chain)
						if not	eval_ok
						and	eval_res == -2
						then	-- just take the first macro object:
							local scr_key, scr_mcr = next(obj_key2_seq.SCR)
							eval_res = eval(scr_key, 2)
							eval_ok = eval_res ~= EVAL_MACRONOTFOUND
						end
						far.RestoreScreen(obj_scr); obj_scr = nil
						obj_status:set(str_format("%s%s Run %s/%s", a_key_show, sz_seq_chain, eval_res, EVAL_RES[eval_res]), nil, 3000)
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
		do      run_res = runMacroOrKey(obj_waitkeys.keys[ii])
		end
		--[[ the old fashion, no multi-sequences:
		if next_key ~= ""
		then runMacroOrKey(next_key)
		end --]]
		is_locked = false
		obj_status:set(anassigned_msg or str_format(
			"%s anassigned, run_norm: %s, timeout: %s, next_key: %s",
			a_key_real, tostring(run_normal), tostring(is_timeout), tostring(next_key)
				), nil, 3000)
		return
	end
	-- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
	obj_status:set(anassigned_msg or a_key_real.." is anassigned", nil, 3000)
	mf.beep()
	--[[ needed?
	win.Sleep(100) --]]
end -- fnc_hnd_mcr_action

local function fnc_copy_key_ext_val(tbl_from, tbl_from_loc, tbl_dest, tbl_dest_loc, copy_key_idx, copy_key_val)
	if type(copy_key_idx) == "number"
	and	copy_key_idx <= #tbl_from_loc
	then	tbl_dest_loc[#tbl_dest_loc + 1] = copy_key_val
	else	tbl_dest_loc[copy_key_idx]	= copy_key_val
	end
	return true
end

local function fnc_copy_key_ext_tbl(tbl_from, tbl_from_loc, tbl_dest, tbl_dest_loc, copy_key_idx, copy_key_val)
	if	copy_key_val.action
	and	copy_key_val.key
	and	copy_key_val.area
	then	return fnc_copy_key_ext_val(tbl_from, tbl_from_loc, tbl_dest, tbl_dest_loc, copy_key_idx, copy_key_val)
	end
end

-- register hotkey's handler
local function fnc_key_handler_set(key_area, obj_key_ext, obj_mcr)
	local m_key = obj_key_ext.KXP.str
	local base_inp =
		far.NameToInputRecord(obj_key_ext.KXP.rec)
		or fnc_combo_mod_try(obj_key_ext.KXP.rec)
	if not	base_inp
	then    if OPT_DEBUG
		then fnc_err_msg(("Unexpected AKey: %q"):format(m_key))
		end
		return
	end
	--[[ FarNameToInputRecord: "CtrlNumLock"-->VK_PAUSE
	http://bugs.farmanager.com/view.php?id=2947
	http://forum.farmanager.com/viewtopic.php?f=8&t=9357
	Комбинация клавиш CtrlNumLock для системы означает VK_PAUSE, но фар об этом не знает.]]
	if str_match(str_lower(m_key), "r?ctrlnumlock")
	then	base_inp = far.NameToInputRecord("Pause")
	end
	if not	tbl_handlers[key_area]
	then	tbl_handlers[key_area] = { }
	end
	local	obj_handler = tbl_handlers[key_area][m_key]
	if not	obj_handler
	then	obj_handler = {
			description	= ("MacroEx handler for %s %q"):format(str_upper(key_area), fnc_key_prettify(m_key)),
			key_area	= key_area,
			m_key		= m_key,
			base_inp	= base_inp,
			mod_state	= band(base_inp.ControlKeyState, MOD_MASK),
			key_ext		= { },
			fnc_condition	= function(rec_key, mcr_src)
				return fnc_hnd_mcr_condition(obj_handler, rec_key, mcr_src)
			end,
			fnc_action	= function(mcr_src)
				return fnc_hnd_mcr_action(obj_handler, mcr_src)
			end
		}
		tbl_handlers[key_area][m_key] = obj_handler
	end
	obj_handler.priority = math_max(obj_handler.priority or 0, (obj_mcr.priority or 50) + 5)
	obj_handler.key_ext = fnc_tbl_copy_to(obj_key_ext, obj_handler.key_ext, fnc_copy_key_ext_tbl, fnc_copy_key_ext_val)
	return obj_handler
end -- fnc_key_handler_set

local function fnc_macro_ex_create(tbl_handlers)
	for ii_area,	ii_area_handlers	in pairs(tbl_handlers)		do
	for ii_area_key,ii_area_key_handler	in pairs(ii_area_handlers)	do
		Macro { area		= ii_area,
			key		= fnc_key_prettify(ii_area_key),
			description	= ii_area_key_handler.description,
			priority	= ii_area_key_handler.priority,
			action		= ii_area_key_handler.fnc_action,
			condition	= ii_area_key_handler.fnc_condition,
			ext_key_hnd	= ii_area_key_handler,
			FileName	= own_fpath,
		}
	end end
end -- fnc_macro_ex_create


local function fnc_macro_ex_check_one(obj_mcr, create_handlers)
	local tbl_handlers_loc = { }
	local id_ext = obj_mcr.id ~= "<no id>" and obj_mcr.id or str_upper(win_uuid(win_uuid()))
	for ii, ii_key in pairs(fnc_str_split(str_lower(obj_mcr.key), "%s+", true))
	do	local obj_mcr_ii = { [ii_key] = { obj_mcr } }
		local tbl_key_ii = { }
		local tbl_ext = { }
		local tbl_ext_jj = tbl_ext
		local jj_key_base, jj_ext_mode, ii_has_ext
		for jj_key_seq in str_gmatch(ii_key.."-", "([^-]*)-")
		do	-- try to save load time:
			if not	ii_has_ext
			and (	#tbl_key_ii > 0
			or	str_match(jj_key_seq, ":double")
			or	str_match(jj_key_seq, ":hold"))
			then	ii_has_ext = true
			end
			tbl_key_ii[#tbl_key_ii + 1] = str_gsub(jj_key_seq, "<minus>", "-")
		end
		if not	ii_has_ext
		then	goto keys_loop_end
		end
		for	jj, jj_key_seq in pairs(tbl_key_ii)
		do
			jj_key_base, jj_ext_mode = str_match(jj_key_seq, "^(.+):(.+)$")
			if	jj_ext_mode
			then	-- here ext_mode supposed to be HLD or DBL
				jj_ext_mode = tbl_ext_mode_code[jj_ext_mode]
				if not	jj_ext_mode
				then	jj_key_base = nil
				end
			end
			if not	jj_key_base
			then	jj_key_base = jj_key_seq
			end
			local tbl_key_exp_jj = fnc_key_expand(jj_key_base, true, true)
			local tbl_ext_stub = jj_ext_mode and { ALL = obj_mcr_ii } or nil
			local tbl_seq_stub = jj < #tbl_key_ii and { } or nil
			if	jj == #tbl_key_ii
			then	if	jj_ext_mode
				then	tbl_ext_stub.SCR = obj_mcr_ii
				end
			else	if	jj_ext_mode
				then	if	ALLOW_SEQ_IN_EXT
					then	tbl_ext_stub.SEQ = tbl_seq_stub
						tbl_seq_stub = nil
					end
				end
			end
			for kk_str, kk_val in pairs(tbl_key_exp_jj)
			do 	tbl_ext_jj[kk_str] = { }
				tbl_ext_jj[kk_str].KXP = kk_val
				tbl_ext_jj[kk_str].SEQ = tbl_seq_stub
				tbl_ext_jj[kk_str].ALL = obj_mcr_ii
				if	jj_ext_mode
				then	tbl_ext_jj[kk_str][jj_ext_mode] = tbl_ext_stub
					tbl_ext_jj[kk_str].EXT = true
				elseif	jj == #tbl_key_ii
				then	tbl_ext_jj[kk_str].SCR = obj_mcr_ii
				end
			end
			if	jj < #tbl_key_ii
			then	tbl_ext_jj = tbl_seq_stub or ALLOW_SEQ_IN_EXT and tbl_ext_stub.SEQ
			end
		end
		if	ii_has_ext              -- prebuild analized
		then	if	#tbl_key_ii > 1
			then	if not	obj_mcr.key_seq_all
				then	obj_mcr.key_seq_all = { [ii_key] = tbl_key_ii }
				elseif
				not	obj_mcr.key_seq_all[ii_key]
				then	obj_mcr.key_seq_all[ii_key] = tbl_key_ii
				end
			end
			if not	obj_mcr.id
			or	obj_mcr.id == "<no id>"
			-- have to have id, i.e. reloading or detecting
			then	obj_mcr.id = id_ext
			end
			for kk, kk_area in pairs(fnc_str_split(str_lower(obj_mcr.area), "%s+", true))
			do	if not	tbl_handlers_loc[kk_area]
				then	tbl_handlers_loc[kk_area] = { }
				end
				for ll_ext_key, ll_ext_obj in pairs(tbl_ext)
				do	tbl_handlers_loc[kk_area][ll_ext_key] = fnc_key_handler_set(kk_area, ll_ext_obj, obj_mcr)
				end
			end
		end
		::keys_loop_end::
	end
	if	create_handlers
	then	fnc_macro_ex_create(tbl_handlers_loc)
	end
	return tbl_handlers_loc
end -- fnc_macro_ex_check_one

local function fnc_macro_ex_build_all()
	local t1 = Far.UpTime
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
