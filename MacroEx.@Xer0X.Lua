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

https://github.com/dr-dba/lua-serialize
dmp-tbl-alt-@Xer0X.Lua
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
	version_mod	= "1.10.1.2",
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
		DelayExt	=  400, -- 500 is ok
		DelaySeq	= 2000,
		DelayHlp	= 2000,
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
local OPT_DELAY_HLP		= opts.DelayHlp
local OPT_DELAY_EXT		= opts.DelayExt

local F	= far.Flags
local C = far.Colors

local KEY_EVENT = F.KEY_EVENT

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
local	Xer0X	= require("Lib-Common-@Xer0X")
local	dmp_srlz= require("dmp-tbl-alt-@Xer0X")
local	req_ok, req_msg, fnc_lua_exp= Xer0X.fnc_safe_require("LuaExplorer-@Xer0X")
if not	req_ok
then	req_ok, req_msg, fnc_lua_exp= Xer0X.fnc_safe_require("LE")
end
local	as_mdl, inp_args, own_fpath = Xer0X.fnc_file_whoami({ ... })
local	FileName = ... or own_fpath


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
local win_uuid	= win.Uuid

local far_Message = far.Message

local KEY_VIS_FMT	= "c:%s/a:%s/s:%s/p:%s"
local KEY_STR_FMT	= "%s%s%s%s"
local KEY_CAS_FMT	= "%s%s%s"
local obj_status	= Xer0X.obj_screen_status_line
local tbl_handlers	= { }
Xer0X.tbl_macro_ex_handlers = tbl_handlers
Xer0X.tbl_ext_key_lev_hist = { }
local tbl_key_lev_hist = Xer0X.tbl_ext_key_lev_hist
local tbl_normal_ask__load = loadfile(own_fpath..".dat")
local tbl_normal_ask = tbl_normal_ask__load and tbl_normal_ask__load() or { }
local flg_ext_mod_off	-- to disable handler in order to run an original macro
local vkc_no_repeat
local tbl_key_lev

local function fnc_err_msg(msg, ...)
	local	msg2 = msg.."\n\2"..debug.traceback("", 2):gsub("\t", "  ")
	local	buttons = select('#', ...) > 0 and "Ok;&Lua explorer" or "Ok"
	repeat	local	a_msg_res = far_Message(msg2, "MacroEx: error in macro definition", buttons, "wl")
		if	a_msg_res == 2
		then	-- to view args
			fnc_lua_exp({ ... }, msg)
		else	break
		end
	until	false
end -- fnc_err_msg

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
				VirtualKeyCode	= k.VirtualKeyCode }
		end
	end
end -- fnc_combo_mod_try

local far_NameToInputRecord = function(the_key)
	--[[ FarNameToInputRecord: "CtrlNumLock"-->VK_PAUSE
	http://bugs.farmanager.com/view.php?id=2947
	http://forum.farmanager.com/viewtopic.php?f=8&t=9357
	Комбинация клавиш CtrlNumLock для системы означает VK_PAUSE, но фар об этом не знает.]]
	local	key_inp_rec = str_match(the_key, "r?ctrlnumlock")
			and	far.NameToInputRecord(	"Pause")
			or	far.NameToInputRecord(	the_key)
			or	fnc_combo_mod_try(	the_key)
	if not	key_inp_rec
	then    if OPT_DEBUG
		then fnc_err_msg(str_format("Unexpected AKey: %q", the_key))
		end
	end
	return key_inp_rec
end

local function fnc_is_holding(key_inp_rec) return vkc_no_repeat == key_inp_rec.VirtualKeyCode end

Event {	description = "MacroEx helper",
	group = "ConsoleInput",
	action = function(key_inp_rec)
		if	vkc_no_repeat
		and	key_inp_rec.EventType == KEY_EVENT
		and	key_inp_rec.VirtualKeyCode ~= 0
		then	-- KEY_NONE? inp_rec.VirtualKeyCode == 0
			-- prevent senseless repeating the same key
			if	key_inp_rec.VirtualKeyCode == vkc_no_repeat
			and	key_inp_rec.KeyDown
			then	-- eat repetitions
				return 1
			else
				vkc_no_repeat = false
			end
		end
	end
}

-- State after last mf.waitkey!!
local function fnc_is_cas_mod_rls(key_rec)
	return	0 == band(
		band(Mouse.LastCtrlState,	MOD_MASK), 
		band(key_rec.ControlKeyState,	MOD_MASK)
			)
end

local function fnc_macro_collect(tbl_keys) -- FIN/ALL/SCP
	local tbl_res = { }
	for ii_key_full, ii_obj_coll in pairs(tbl_keys)
	do	for jj_mcr_id, jj_mcr_obj in pairs(ii_obj_coll.scripts)
		do	local	jj_mcr_item = tbl_res[jj_mcr_id]
			if	jj_mcr_item
			then	jj_mcr_item.keys_full[#jj_mcr_item.keys_full + 1] = ii_key_full
			else	jj_mcr_item = {
					keys_full = { [ii_key_full] = ii_obj_coll.key_path },
					obj_macro = jj_mcr_obj,
					key_final = ii_obj_coll.key_final,
					key_level = ii_obj_coll.key_level,
					key_base  = ii_obj_coll.key_base,
					key_extn  = ii_obj_coll.key_extn,
				}
				tbl_res[jj_mcr_id] = jj_mcr_item
			end
		end
	end
	return tbl_res
end

local function fnc_get_seq_hlp(key_scr, in_key_base)
	local	tbl_mcr_coll = fnc_macro_collect(key_scr)
	local	tbl_hlp = { }
	for	ii_mcr_idx, ii_mcr_item in pairs(tbl_mcr_coll)
	do	for	jj_key_full, jj_key_path in pairs(ii_mcr_item.keys_full)
		do	if not	ii_mcr_item.key_extn
			or not	in_key_base
			then	tbl_insert(tbl_hlp, fnc_key_prettify(jj_key_full).." - "..ii_mcr_item.obj_macro.description)
			end
		end
	end
	return next(tbl_hlp) and tbl_concat(tbl_hlp, "\n").."\n\1\nPress Escape to cancel the sequence" or false
end -- fnc_get_seq_hlp

local function fnc_get_fin_scp(key_scr)
	local	tbl_fin = { }
	if	key_scr
	then	local	tbl_mcr_coll = fnc_macro_collect(key_scr)
		for	ii_mcr_idx, ii_mcr_item in pairs(tbl_mcr_coll)
		do	for	jj_key_idx, jj_key_full in pairs(ii_mcr_item.keys_full)
			do	if	ii_mcr_item.key_final
				then	tbl_insert(tbl_fin, ii_mcr_item)
				end
			end
		end
	end
	return tbl_fin
end -- fnc_get_fin_scp


local function runMacro(key, ext)
	local	eval_res = eval(key..(ext and ext or ""), 2)
	return	eval_res ~= EVAL_MACRONOTFOUND, eval_res
end

local function runMacroOrKey(key)
	local	eval_res = eval(key, 2)
	if	eval_res == EVAL_MACRONOTFOUND
	then	Keys(key)
	end
	return	eval_res
end

local rgx_key_parse = regex.new("/^(?:([rl]?)ctrl)?(?:([rl]?)alt)?(shift)?(.+)?$/i")
local function fnc_key_parse(the_key)
	local RLctl, RLalt, shift, plain = rgx_key_parse:match(the_key)
	return {
		RLctl = RLctl,
		RLalt = RLalt,
		shift = shift,
		plain = plain,
	}
end

local function fnc_key_expand(the_key, in_lower, str_id, as_received)
	if not the_key then return end
--	assert(key:match("^%l+$"))
	local R =	in_lower and "r"	or "R"
	local L	=	in_lower and "l"	or "L"
	local ALT =	in_lower and "alt"	or "Alt"
	local CTL =	in_lower and "ctrl"	or "Ctrl"
	local NONE=	in_lower and "<none>"	or "<NONE>"
	local obj_key = fnc_key_parse(str_lower(the_key))
	local tbl_exp = { }
	local ctl, alt, sft, ctl2, alt2, key
	ctl = obj_key.RLctl == "" and L -- (in_lower and "l" or "L")
	repeat
	alt = obj_key.RLalt == "" and L -- (in_lower and "l" or "L")
	repeat
	ctl2 = ctl or obj_key.RLctl
	alt2 = alt or obj_key.RLalt
	key = obj_key.plain or ""
	local tbl_key = { ctl = ctl2, alt = alt2, sft = obj_key.shift, key = key }
	tbl_key.vis	= str_lower(str_format(KEY_VIS_FMT,
		ctl2 or 0,
		alt2 or 0,
		obj_key.shift and 1 or 0,
		obj_key.plain or NONE))
	tbl_key.str	= str_format(KEY_STR_FMT,
		ctl2 and ctl2..CTL or "",
		alt2 and alt2..ALT or "",
		obj_key.shift or "", key)
	tbl_key.rec	= str_format(KEY_STR_FMT,
		ctl2 and (ctl2 == R and R or "")..CTL or "",
		alt2 and (alt2 == R and R or "")..ALT or "",
		obj_key.shift or "", key)
	tbl_key.rec_cas = str_format(KEY_STR_FMT,
		ctl2 and (ctl2 == R and R or "")..CTL or "",
		alt2 and (alt2 == R and R or "")..ALT or "",
		obj_key.shift or "", "")
	tbl_key.cas	= str_format(KEY_CAS_FMT,
		ctl2 and ctl2..CTL or "",
		alt2 and alt2..ALT or "",
		obj_key.shift or "")
	tbl_exp[str_id and tbl_key.str or tbl_key.vis] = tbl_key
	alt = str_lower(alt or "") == L and not as_received and R 
	until not alt
	ctl = str_lower(ctl or "") == L and not as_received and R 
	until not ctl
	return tbl_exp, obj_key
end -- fnc_key_expand

local function fnc_key_equal(key_base, key_comp)
	if not	key_base
	or not	key_comp
	or	key_base == ""
	or	key_comp == ""
	then	return
	end
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
	return not flg_ext_mod_off and (obj_handler.priority or true)
end -- fnc_hnd_mcr_condition

local obj_waitkeys = {
	keys = { },
	init = function(self, keys)
		local type_keys = type(keys)
		self.keys= type_keys == "nil"	and { }
			or type_keys == "table"	and keys
			or { keys } -- should be string
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

local function fnc_sett_data_store()
	local res_val, file_hnd = dmp_srlz.fnc_file_save(tbl_normal_ask, { file_path = own_fpath..".dat", file_init = true, file_close = true })
end

local function fnc_hnd_mcr_action(obj_handler, mcr_src)
	local obj_scr = far.SaveScreen()
	local key_ext_pre, key_ext_new, key_rec_pre, key_rec_new, key_str_new, t_wait_key
	local run_mode = "ask_normal" -- default mode
	local key_str_bas = akey(1, 0) 
	local obj_key_lev = {
		key_str_bas	= key_str_bas,				
		key_str_bas_ext = key_str_bas,				
		key_str_seq	= str_gsub(key_str_bas, "-", "Minus"),  
		key_ext = obj_handler.key_ext,				
		key_rec = far_NameToInputRecord(key_str_bas),		
		key_time= Far.UpTime,					
	}
	tbl_key_lev = { obj_key_lev } -- init
	local key_ext	= obj_key_lev.key_ext
	local key_rec	= obj_key_lev.key_rec
	local t_last_key= obj_key_lev.key_time
	obj_status:set(obj_key_lev.key_str_seq.." ..?", nil, 10000000)
	obj_waitkeys:init(obj_key_lev.key_str_bas)
	vkc_no_repeat = obj_key_lev.key_rec.VirtualKeyCode -- global var, prevent autorepeat
	repeat
		key_str_new, t_wait_key = obj_waitkeys:save(50)
		if	key_str_new == "Esc"
		then	run_mode = "cancel"; break
		end
		local	is_ext_timeout = t_wait_key - obj_key_lev.key_time > OPT_DELAY_EXT
		local	was_hld = not obj_key_lev.ext_type and key_str_new == "" and is_ext_timeout and fnc_is_holding(obj_key_lev.key_rec)
		local	was_dbl = not obj_key_lev.ext_type and key_str_new ~= "" and fnc_key_equal(key_str_new, obj_key_lev.key_str_bas)
		local	str_ext =
				was_hld and key_ext.HLD and "HLD" or
				was_dbl and key_ext.DBL and "DBL"
		if	str_ext
		then
			key_str_bas = false
			obj_key_lev.ext_type		= str_ext
			obj_key_lev.key_str_bas_ext	= obj_key_lev.key_str_bas..tbl_ext_mode_show[obj_key_lev.ext_type]
			obj_key_lev.key_str_seq 	= obj_key_lev.key_str_seq..tbl_ext_mode_show[obj_key_lev.ext_type]
			obj_key_lev.key_bas		= obj_key_lev.key_ext 
			obj_key_lev.key_ext		= obj_key_lev.key_ext[obj_key_lev.ext_type]
			key_ext_new = obj_key_lev.key_ext 
		elseif
			key_str_new ~= "" -- got the next key
		then
			key_rec_new = far_NameToInputRecord(key_str_new) -- real
			local	cas_mod_is_same =
					band(key_rec_new.ControlKeyState, MOD_MASK) ==
					band(key_rec	.ControlKeyState, MOD_MASK)
			if not	cas_mod_is_same
			and	BREAK_SEQ_ON_MOD_RELEASE
			then	break
			end
			local	key_str_try = key_str_new
			::seq_key_try::
			local	key_exp_try, key_obj_try = fnc_key_expand(key_str_try, "in_lower", "real_key_str", "received")
			local	key_str_seq, key_obj_seq = fnc_key_equal( key_exp_try, key_ext.SEQ)
			if not	key_str_seq
			and	cas_mod_is_same
			-- KXP.key as "plain" key cant be used here, since it is NEW key
			and	key_obj_try.plain -- false in the kind of RCtrlAlt
			and	key_str_try ~= key_obj_try.plain
			then	key_str_try  = key_obj_try.plain
				goto seq_key_try
			end
			if not	key_str_seq -- ? is it registered sequence key
			then	break -- run normal
			end
			obj_key_lev.next_type = "SEQ"
			obj_key_lev.next_key_str = key_str_new
			obj_key_lev.next_key_lev = {
				key_str_bas =	key_str_new,
				key_ext_pre =	key_ext,
				key_ext =	key_obj_seq,
				key_rec_pre =	key_rec,
				key_rec =	key_rec_new,
				key_str_seq =	obj_key_lev.key_str_seq.."-"..str_gsub(key_str_new, "-", "Minus"),
				key_time=	t_wait_key,
			}
			obj_key_lev = obj_key_lev.next_key_lev
			tbl_key_lev[#tbl_key_lev + 1] = obj_key_lev
			str_ext		= "SEQ"
			key_ext_new	= obj_key_lev.key_ext
			key_rec_pre	= obj_key_lev.key_rec_pre
			key_rec		= obj_key_lev.key_rec
			key_str_bas	= obj_key_lev.key_str_bas 
			vkc_no_repeat	= obj_key_lev.key_rec.VirtualKeyCode -- prevent autorepeat
		else -- no SEQ/HLD/DBL
			if	OPT_DELAY_HLP < t_wait_key - obj_key_lev.key_time
			then	far_Message(
					fnc_get_seq_hlp(
						obj_key_lev.key_ext.SCP, 
						obj_key_lev.key_ext.KXP -- here KXP is the flag that we are not in an extended key
					),
					obj_key_lev.key_str_seq, 
					"", "l"
				)
			end
		end
		if	str_ext
		then -- some keyboard event happened
			t_last_key = t_wait_key 
			key_ext_pre = key_ext	
			key_ext = key_ext_new	
			obj_status:set(obj_key_lev.key_str_seq.." ..?", nil, 10000000)
			if #fnc_get_fin_scp(obj_key_lev.key_ext.SCP) > 0
			then	run_mode = "seq_ext"
				break
			end
		end
		if	fnc_is_cas_mod_rls(obj_key_lev.key_rec)
		and	BREAK_SEQ_ON_MOD_RELEASE
		or  not obj_key_lev.key_ext.SEQ
		and not obj_key_lev.key_ext.EXT
		then	break
		end
	until false
	tbl_key_lev.run_mode = run_mode -- debug purposes only
	tbl_key_lev_hist[#tbl_key_lev_hist + 1] = tbl_key_lev
	far.RestoreScreen(obj_scr)
	if	run_mode == "ask_normal"
	then
		local	bad_key_seq = str_format("%s + %s", obj_key_lev.key_str_seq, key_str_new and key_str_new ~= "" and key_str_new or "???")
		if not	tbl_normal_ask[Area.Current]
		then	tbl_normal_ask[Area.Current] = { }
		end
		local	inf_saved = tbl_normal_ask[Area.Current][bad_key_seq]
		local	cnt_use = inf_saved and (inf_saved % 1000000) or 0
		local	res_msg = inf_saved and (inf_saved - cnt_use) / 1000000
		if not  res_msg
		then	res_msg = far.Message(
				str_format(
					"%s\n\1\nDo you want to run these keys as normal in %s?\n\1\n%s\n\2",
					bad_key_seq, Area.Current, tbl_concat(obj_waitkeys.keys, ", ")
						),
				"WRONG SEQUENCE",
				"&YES;yes &Save;&NOT;not sav&E",
				"w"
					)
		end
		if	res_msg == 2
		or	res_msg == 4
		then -- to store(save) response for future use
			tbl_normal_ask[Area.Current][bad_key_seq] = res_msg * 1000000 + cnt_use + 1
			if	cnt_use == 0
			then	fnc_sett_data_store()
			end
		end
		if	res_msg == 1 -- run normal, not saved
		or	res_msg == 2 -- run normal, saved as default response
		then	obj_status:set(str_format("%s anassigned run normal%s", bad_key_seq, res_msg == 2 and " (saved)" or ""), nil, 2500)
			flg_ext_mod_off = true
			for ii = 1, #obj_waitkeys.keys
			do local run_res = runMacroOrKey(obj_waitkeys.keys[ii])
			end
			flg_ext_mod_off = false
		else	obj_status:set(str_format("%s anassigned run cancel%s", bad_key_seq, res_msg == 4 and " (saved)" or ""), nil, 2500)
			mf.beep() -- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
		end
	elseif
		run_mode == "seq_ext"
	then
		obj_status:set(str_format("%s Run ?", obj_key_lev.key_str_seq), nil, 100000)
		local	eval_ok, eval_res = runMacro(obj_key_lev.key_str_seq)
		if not	eval_ok
		and	eval_res == -2
		then -- just take the first macro object:
			local scr_num, scr_obj = next(fnc_get_fin_scp(key_ext.SCP))
			eval_res = eval(({ next(scr_obj.keys_full) })[1], 2)
			eval_ok = eval_res ~= EVAL_MACRONOTFOUND
		end
		obj_status:set(str_format("%s Run %s/%s", obj_key_lev.key_str_seq, eval_res, EVAL_RES[eval_res]), nil, 3000)
	elseif
		run_mode == "cancel"
	then
		obj_status:set(str_format("%s sequence canceled", obj_key_lev.key_str_seq), nil, 3000)
	end
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
	elseif	copy_key_idx == "KXP"
	or	copy_key_idx == "key_path"
	or	copy_key_idx == "key_pth2"
	then	if not	tbl_dest_loc[copy_key_idx]
		then	tbl_dest_loc[copy_key_idx] = copy_key_val
		end
		return true
	end
end

-- register hotkey's handler, here keys and areas should be already normalized to lower case
local function fnc_key_handler_set(key_area, obj_key_ext, obj_mcr)
	if not	tbl_handlers[key_area]
	then	tbl_handlers[key_area] = { }
	end
	local	m_key = obj_key_ext.KXP.str
	local	obj_handler = tbl_handlers[key_area][m_key]
	if not	obj_handler
	then	obj_handler = {
			description	= ("MacroEx handler for %s %q"):format(str_upper(key_area), fnc_key_prettify(m_key)),
			key_area	= key_area,
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
	for ii, ii_key in pairs(fnc_str_split(str_lower(obj_mcr.key), "%s+", true))
	do	local obj_mcr_ii = { [ii_key] = { obj_mcr } }
		local tbl_key_ii = { }
		local tbl_ext	 = { }
		local tbl_ext_jj = tbl_ext
		local jj_key_base, jj_ext_mode, ii_has_ext
		for jj_key_seq in str_gmatch(ii_key.."-", "([^-]*)-")
		do	if	jj_key_seq == ""
			then	if	#tbl_key_ii == 0
				then	--[[ this phenomena happened to me on "-",
					this is plain key, so just skip it]]
					break -- ii_has_ext remains nil here
				else	--[[ this phenomena happens onto such plain keys,
					as "Alt-" for example, should be on finalizing key ]]
					tbl_key_ii[#tbl_key_ii] = tbl_key_ii[#tbl_key_ii].."-"
					goto seq_keys_loop_end
				end
			end
			-- try to save load time:
			if not	ii_has_ext
			and (	#tbl_key_ii > 0
			or	str_find( jj_key_seq, "%S[:-]%S"))
			then	ii_has_ext = true
			end
			tbl_key_ii[#tbl_key_ii + 1] = str_gsub(jj_key_seq, "minus", "-")
			::seq_keys_loop_end::
		end
		local tbl_kxp_ii = { }
		if	ii_has_ext
		then
			if not	obj_mcr.data.id_ext -- have to have ext_id, for reloading or detecting
			then	obj_mcr.data.id_ext = str_upper(win_uuid(win_uuid()))
			end
			for	jj, jj_key_seq in pairs(tbl_key_ii)
			do
				jj_key_base, jj_ext_mode = str_match(jj_key_seq, "^(.+):(.+)$")
				if	jj_ext_mode
				then	-- here ext_mode supposed to be HLD or DBL
					jj_ext_mode = tbl_ext_mode_code[jj_ext_mode]
				else	jj_key_base = jj_key_seq
				end
				local tbl_key_exp_jj = fnc_key_expand(jj_key_base, true, true)
				tbl_kxp_ii[#tbl_kxp_ii + 1] = { exp = tbl_key_exp_jj, bas = jj_key_base, ext = jj_ext_mode, key = jj_key_seq }

				local function fnc_loc_scr_key_gen(is_fin_key) 
				-- helper func, not done with usual table, only because we need to differentiate "is_fin_key"
					return { [ii_key] = {
						key_level= jj,
						key_path = tbl_key_ii,
						key_pth2 = tbl_kxp_ii,
						key_full = ii_key,
						key_extn = jj_ext_mode,
						key_base = jj_key_base,
						key_expn = tbl_key_exp_jj,
						key_final= is_fin_key,
						scripts = { [obj_mcr.data.id_ext] = obj_mcr }
				} } end

				local tbl_seq_stub = { }
				local tbl_ext_stub = jj_ext_mode and { EXT = jj_ext_mode, SCP = fnc_loc_scr_key_gen(jj == #tbl_key_ii) }
				if	jj_ext_mode
				and	ALLOW_SEQ_IN_EXT
				then	tbl_ext_stub.SEQ = tbl_seq_stub
				end
				for kk_str, kk_val in pairs(tbl_key_exp_jj)
				do 	tbl_ext_jj[kk_str] = { EXT = jj_ext_mode and true, KXP = kk_val }
					if	jj_ext_mode
					then	tbl_ext_jj[kk_str][jj_ext_mode] = tbl_ext_stub
					else	tbl_ext_jj[kk_str].SEQ = tbl_seq_stub
					end
					tbl_ext_jj[kk_str].SCP = fnc_loc_scr_key_gen(jj == #tbl_key_ii and not jj_ext_mode)
				end
				tbl_ext_jj = jj_ext_mode and ALLOW_SEQ_IN_EXT and tbl_ext_stub.SEQ or tbl_seq_stub
			end -- end of the sequence keys processing loop
			if not	obj_mcr.data.key_seq_all
			then	obj_mcr.data.key_seq_all = { }
			end
			if not	obj_mcr.data.key_seq_all[ii_key]
			then	obj_mcr.data.key_seq_all[ii_key] = tbl_kxp_ii -- is better than tbl_key_ii
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
	end
	if	create_handlers
	then	fnc_macro_ex_create(tbl_handlers_loc)
	end
	return tbl_handlers_loc
end -- fnc_macro_ex_check_one

local function fnc_macro_ex_build_all()
	for ii = 1, #Xer0X.utils.LoadedMacros
	do	local	ii_mcr = Xer0X.utils.LoadedMacros[ii]
		local	ii_mcr_key = ii_mcr.key
		if	ii_mcr_key
		and not ii_mcr.keyregex
		and	str_find(ii_mcr_key, "%S[:-]%S") -- %S(s) - any (non-)whitespace character
		then	fnc_macro_ex_check_one(ii_mcr)
		end
	end
	fnc_macro_ex_create(tbl_handlers)
	return tbl_handlers
end -- fnc_macro_ex_build_all

Event { group = "ExitFAR",
	description = "Save MacroEx data and statistics on FAR exit",
	action = function() fnc_sett_data_store() end
}

if	as_mdl
then
else
--[=[ need to be the last call,
so that all other macros loaded already: ]=]
mf.postmacro(fnc_macro_ex_build_all)
end

-- @@@@@
