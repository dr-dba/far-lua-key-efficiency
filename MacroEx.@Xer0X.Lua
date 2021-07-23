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

-- ### INFO AND OPTIONS BLOCK ###

-- luacheck: ignore 113/Info
local Info = Info or package.loaded.regscript or function(...) return ... end
local nfo = Info({
	_filename or ...,
	name		= "MacroEx",
	-- запуск макросов нетрадиционными способами
	description	= "Launching macros in unconventional ways (+@Xer0X mod)",
	id		= "35FD5420-D2A1-4A1C-AAFD-4C902231F549",
	version		= "3.2",
	version_mod	= "2.7.0",
	author		= "JD",
	author_mod	= "x-Team",
	url		= "https://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "https://forum.farmanager.com/viewtopic.php?f=15&t=12459",
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
		DbgShowBadExt	= false,
		DbgShowBadKey	= false,
		DbgShowLoadTime	= true,
	}
})
if not nfo then return end
local opts = nfo.options

-- @@@ END OF THE INFO AND OPTIONS BLOCK @@@

local BREAK_SEQ_ON_MOD_RELEASE	= opts.break_seq_on_mod_release
local ALLOW_SEQ_WITH_ANY_MOD	= opts.allow_seq_with_any_mod
local ALLOW_SEQ_IN_EXT		= opts.allow_seq_in_ext
local OPT_DELAY_SEQ		= opts.DelaySeq
local OPT_DELAY_HLP		= opts.DelayHlp
local OPT_DELAY_EXT		= opts.DelayExt

local F	= far.Flags
local C = far.Colors

local KEY_EVENT = F.KEY_EVENT

local MCODE_F_CHECKALL		= 0x80C64
local MCODE_F_GETOPTIONS	= 0x80C65 
local MCODE_F_MACROSETTINGS	= 0x80C6A

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
local	tbl_ext_mode_disp = { DBL = ":Double",	HLD = ":Hold"}

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
local tbl_sort	= table.sort
local mf_waitkey= mf.waitkey
local win_uuid	= win.Uuid

local far_Message		= far.Message
local far_ProcessName		= far.ProcessName
local far_NameToInputRecord	= far.NameToInputRecord

local obj_status	= Xer0X.obj_screen_status_line
local LoadedMacros	= Xer0X.utils.LoadedMacros
local GetAreaCode	= Xer0X.utils_shared.GetAreaCode
local MacroCallFar	= Xer0X.utils.MacroCallFar
local utils_Areas	= Xer0X.utils.Areas
local tbl_handlers = { }
Xer0X.tbl_macro_ex_handlers = tbl_handlers
local tbl_key_lev_hist = { }
Xer0X.tbl_ext_key_lev_hist = tbl_key_lev_hist
local tbl_normal_ask__load = loadfile(own_fpath..".dat")
local tbl_normal_ask = tbl_normal_ask__load and tbl_normal_ask__load() or { }
local vkc_no_repeat, flg_ext_mod_off	-- to disable handler in order to run an original macro

local function fnc_err_msg(msg, ...)
	local	msg2 = msg.."\n\2"..debug.traceback("", 2):gsub("\t", "  ")
	local	buttons = select('#', ...) > 0 and "Ok;&Lua explorer" or "Ok"
	repeat	local	msg_res = far_Message(msg2, "MacroEx: error in macro definition", buttons, "wl")
		if	msg_res == 2
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
		then	return{ ControlKeyState	= m.ControlKeyState,
				VirtualKeyCode	= k.VirtualKeyCode }
		end
	end
end -- fnc_combo_mod_try

local tbl_key_rec_cache = { } -- micro optimization
Xer0X.tbl_key_inp_rec_cache = tbl_key_rec_cache
local fnc_NameToInputRecord = function(the_key)
	local	the_key_rec = tbl_key_rec_cache[the_key]
	if	the_key_rec
	then	return the_key_rec
	end
	--[[ FarNameToInputRecord: "CtrlNumLock"-->VK_PAUSE
	http://bugs.farmanager.com/view.php?id=2947
	http://forum.farmanager.com/viewtopic.php?f=8&t=9357
	Комбинация клавиш CtrlNumLock для системы означает VK_PAUSE, но фар об этом не знает.]]
	local	key_inp_rec = str_match(the_key, "r?ctrlnumlock")
			and	far_NameToInputRecord(	"Pause")
			or	far_NameToInputRecord(	the_key)
			or	fnc_combo_mod_try(	the_key)
	if not	key_inp_rec
	then    if opts.DbgShowBadKey
		then fnc_err_msg(str_format("Unexpected AKey: %q", the_key))
		end
	else	tbl_key_rec_cache[the_key] = key_inp_rec
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
	local mouse_cas = band(Mouse.LastCtrlState,	MOD_MASK)
	local input_cas = band(key_rec.ControlKeyState,	MOD_MASK)
	return	0 == band(mouse_cas, input_cas)
		and (	0 ~= mouse_cas
		or	0 ~= input_cas
		),
		mouse_cas
end

local function fnc_macro_collect(tbl_keys) -- FIN/ALL/SCP
	local tbl_res = { }
	for ii_key_full, ii_obj_coll in pairs(tbl_keys)
	do	for jj_mcr_id, jj_mcr_obj in pairs(ii_obj_coll.scripts)
		do	local	jj_mcr_item = tbl_res[jj_mcr_id]
			if	jj_mcr_item
			then	jj_mcr_item.keys_full[ii_key_full] = ii_obj_coll.key_path
			else	jj_mcr_item = {
					keys_full = {[ii_key_full] = ii_obj_coll.key_path },
					mcr_extid = jj_mcr_id,
					obj_macro = jj_mcr_obj,
				}
				tbl_res[jj_mcr_id] = jj_mcr_item
			end
		end
	end
	return tbl_res
end


local tbl_parsed_keys_val_cache = { }
Xer0X.tbl_parsed_keys_val_cache = tbl_parsed_keys_val_cache
local tbl_parsed_keys_bad_cache = { }
Xer0X.tbl_parsed_keys_bad_cache = tbl_parsed_keys_bad_cache
local rgx_key_parse_v2 = regex.new("/^(l?ctrl)?(rctrl)?(l?alt)?(ralt)?(shift)?(.+)?$/i")
local function fnc_key_parse(the_key)
	local	obj_parsed = tbl_parsed_keys_val_cache[the_key]
	if	obj_parsed
	then	return obj_parsed
	end
	if	tbl_parsed_keys_bad_cache[the_key]
	then	return false
	end	
	local the_key_low = string.lower(the_key)
	local t_rec_1 = { }
	t_rec_1.ctl_l, t_rec_1.ctl_r, t_rec_1.alt_l, t_rec_1.alt_r, t_rec_1.shift, t_rec_1.plain = rgx_key_parse_v2:match(the_key_low)
	local t_rec_2 = { }
	if not t_rec_1.plain then goto after_validity_check end
	t_rec_2.ctl_l, t_rec_2.ctl_r, t_rec_2.alt_l, t_rec_2.alt_r, t_rec_2.shift, t_rec_2.plain = rgx_key_parse_v2:match(t_rec_1.plain)
	if	t_rec_2.ctl_l
	or	t_rec_2.ctl_r
	or	t_rec_2.alt_l
	or	t_rec_2.alt_r
	or	t_rec_2.shift
	then	tbl_parsed_keys_bad_cache[the_key] = { t_rec_1, t_rec_2 }
		return false
	end
	::after_validity_check::
	t_rec_1.ctl_x = not t_rec_1.ctl_r and t_rec_1.ctl_l and str_lower(t_rec_1.ctl_l) == "ctrl"
	t_rec_1.alt_x = not t_rec_1.alt_r and t_rec_1.alt_l and str_lower(t_rec_1.alt_l) == "alt"
	t_rec_1.ctl_e = t_rec_1.ctl_r or t_rec_1.ctl_l
	t_rec_1.alt_e = t_rec_1.alt_r or t_rec_1.alt_l
	tbl_parsed_keys_val_cache[the_key] = t_rec_1
	return t_rec_1
end -- fnc_key_parse

local tbl_key_expanded_cache = { }
Xer0X.tbl_key_expanded_cache = tbl_key_expanded_cache 
local function fnc_key_expand(the_key, in_lower, as_single )
	if not the_key then return end
	local key_cache = str_format("%s|%s|%s", the_key, tostring(in_lower), tostring(as_single))
	local obj_cache = tbl_key_expanded_cache[key_cache]
	if obj_cache then return unpack(tbl_key_expanded_cache[key_cache]) end
--	assert(key:match("^%l+$"))
	local R =	in_lower and "r"	or "R"
	local L	=	in_lower and "l"	or "L"
	local ALT =	in_lower and "alt"	or "Alt"
	local CTL =	in_lower and "ctrl"	or "Ctrl"
	local NONE=	in_lower and "<none>"	or "<NONE>"
	local obj_key = fnc_key_parse(in_lower and str_lower(the_key) or the_key) 
	local tbl_exp = { }
	ctl = obj_key.ctl_x and L
	repeat
	alt = obj_key.alt_x and L
	repeat
	local tbl_key = { 
		ctl_l = not ctl and not not obj_key.ctl_l or ctl == L,
		ctl_r = not ctl and not not obj_key.ctl_r or ctl == R,
		alt_l = not alt and not not obj_key.alt_l or alt == L,
		alt_r = not alt and not not obj_key.alt_r or alt == R,
		shift = obj_key.shift, 
		plain = obj_key.plain
	}
	tbl_key.cas =	(ctl and ctl..CTL or (obj_key.ctl_l and L..CTL or "")..(obj_key.ctl_r and R..CTL or ""))..
			(alt and alt..ALT or (obj_key.alt_l and L..ALT or "")..(obj_key.alt_r and R..ALT or ""))..
			(obj_key.shift or "")
	tbl_key.rec_cas=(ctl and (ctl == R and R or "")..CTL or (obj_key.ctl_l and L..CTL or "")..(obj_key.ctl_r and R..CTL or ""))..
			(alt and (alt == R and R or "")..ALT or (obj_key.alt_l and L..ALT or "")..(obj_key.alt_r and R..ALT or ""))..
			(obj_key.shift or "")
	tbl_key.str = tbl_key.cas	..(obj_key.plain or "")
	tbl_key.rec = tbl_key.rec_cas	..(obj_key.plain or "")
	tbl_exp[tbl_key.str] = tbl_key
	alt = not as_single and alt == L and R
	until not alt
	ctl = not as_single and ctl == L and R
	until not ctl
	tbl_key_expanded_cache[key_cache] = { tbl_exp, obj_key }
	return tbl_exp, obj_key
end -- fnc_key_expand

local function fnc_key_equal(key_base, key_comp)
	if not	key_base
	or not	key_comp
	or	key_base == ""
	or	key_comp == ""
	then	return
	end
	local tbl_base = type(key_base) == "table" and key_base or fnc_key_expand(key_base, true, false)
	local tbl_comp = type(key_comp) == "table" and key_comp or fnc_key_expand(key_comp, true, false)
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
	then	if not	tbl_dest_loc[copy_key_idx]
		then	tbl_dest_loc[copy_key_idx] = copy_key_val
		end
		return true
	end
end

local function fnc_get_seq_hlp(key_scr, prio_cond, tbl_key_seq)
	local	tbl_mcr_coll = fnc_macro_collect(key_scr)
	local	tbl_hlp = { }
	for	ii_mcr_idx, ii_mcr_item in pairs(tbl_mcr_coll)
	do	for	jj_key_full, jj_key_path in pairs(ii_mcr_item.keys_full)
		do	if	prio_cond[ii_mcr_idx]
			and	prio_cond[ii_mcr_idx][jj_key_full]
			then	--[[ to get rid of wrong keys in the help,
				like in "CtrlAlt-F3-F3-F3 LCtrlLAlt:Double-F4-F4-F4-F4",
				need to make comparing sequences and use it in help ]]
				local	is_equal = true -- lets be optimic
				for ii_seq_pos, ii_seq_key in pairs(tbl_key_seq)
				do	if not	fnc_key_equal(ii_seq_key.exp, jj_key_path[ii_seq_pos].exp)
					or	ii_seq_key.ext ~= jj_key_path[ii_seq_pos].ext
					then	is_equal = false
						break
					end
				end
				if	is_equal
				then	tbl_insert(tbl_hlp, fnc_key_prettify(jj_key_full).." - "..ii_mcr_item.obj_macro.description)
				end
			end
		end
	end
	return next(tbl_hlp) and tbl_concat(tbl_hlp, "\n").."\n\1\nPress AltEscape to cancel the sequence\nPress ShiftSpace to run as normal keys" or false
end -- fnc_get_seq_hlp

local function fnc_get_fin_scp(key_scr, prio_cond, tbl_key_seq)
	local	tbl_fin = { }
	local	tbl_mcr_coll = fnc_macro_collect(key_scr or { })
	for	ii_mcr_idx, ii_mcr_item in pairs(tbl_mcr_coll)
	do	for	jj_key_full, jj_key_path in pairs(ii_mcr_item.keys_full)
		do	if	prio_cond[ii_mcr_idx]
			and	prio_cond[ii_mcr_idx][jj_key_full]
			then    if	#jj_key_path == #tbl_key_seq
				then	local	is_equal = true -- lets be optimic
					for ii_seq_pos, ii_seq_key in pairs(tbl_key_seq)
					do	if not	fnc_key_equal(ii_seq_key.exp, jj_key_path[ii_seq_pos].exp)
						or	ii_seq_key.ext ~= jj_key_path[ii_seq_pos].ext
						then	is_equal = false
							break
						end
					end
					if	is_equal
					then	tbl_fin[#tbl_fin + 1] = ii_mcr_item
					end
				end
			end
		end
	end
	return tbl_fin
end -- fnc_get_fin_scp

local function GetMacro(argKey, argUseCommon)
	local area_name = str_lower(Area.Current)
	local Area_Names = { area_name, argUseCommon and area_name ~= "common" and "common" or nil }
	local key = argKey:lower()
	do 
		local	from, to, ctrl, alt, start
		do	from, to, ctrl = str_find(key, "^(r?ctrl)")
		end
		if	ctrl == "ctrl"
		then	ctrl = "lctrl"
		elseif	ctrl ~="rctrl"
		then	from, to, ctrl = str_find(key, "^(l?ctrl)")
		end
		start = to and to + 1 or 1
		do	from, to, alt = str_find(key, "^(r?alt)", start)
		end
		if	alt == "alt"
		then	alt = "lalt"
		elseif	alt ~="ralt"
		then	from, to, alt = str_find(key, "^(l?alt)", start)
		end
		start = to and to + 1 or start
		key = (ctrl or "")..(alt or "")..str_sub(key, start)
	end
	local Collector, CInfo = { }, { }
	local filename = false
		or area_name == "editor" and editor.GetFileName()
		or area_name == "viewer" and viewer.GetFileName()
		or area_name == "shell"  and APanel.Path.."\\"..APanel.Current

	local function ExamineMacro(m, area_name_test)
		local check = not (filename and m.filemask) or far_ProcessName("PN_CMPNAMELIST", m.filemask, filename, "PN_SKIPPATH")
		if check and MacroCallFar(MCODE_F_CHECKALL, GetAreaCode(area_name_test), m.flags, m.callback, m.callbackId)
		then	if not	Collector[m]
			then	local n = #CInfo + 1
				Collector[m] = n
				CInfo[n] = m.priority or 50
				CInfo[n + 1] = area_name_test
			end
		end
	end -- ExamineMacro

	for _, ii_areaname in ipairs(Area_Names)
	do	local	ii_areatable = utils_Areas[ii_areaname]
		if	ii_areatable
		then	local	ii_macros = ii_areatable[key]
			if	ii_macros
			then	for _, jj_m in ipairs(ii_macros)
				do	if not	jj_m.disabled
					and	jj_m.data.areas_dict[ii_areaname]
					and not(ii_areaname == "common"		
					and	jj_m.data.areas_dict[area_name])
					then	ExamineMacro(jj_m, ii_areaname) 
					end
				end
			end
		end
	end
	local max_priority = -1
	local nummacros = 0
	for ii_m, ii_p in pairs(Collector)
	do	if	ii_m.condition
		then	local	ii_pr = ii_m.condition(key, ii_m.data) -- unprotected call
			if	ii_pr
			then	if type(ii_pr) == "number"
				then CInfo[ii_p] = ii_pr > 100 and 100 or ii_pr < 0 and 0 or ii_pr
				end
			else	Collector[ii_m] = nil
			end
		end
		if	Collector[ii_m]
		then	nummacros = nummacros + 1
			if	max_priority < CInfo[ii_p]
			then	max_priority = CInfo[ii_p]
			end
		end
	end
	local macrolist = { }
	local nindex = nil
	for ii_m, ii_p in pairs(Collector)
	do	macrolist[#macrolist + 1] = { macro = ii_m, priority = CInfo[ii_p], sortpriority = ii_m.sortpriority }
		if CInfo[ii_p] == max_priority then nindex = nindex and -1 or #macrolist end
	end
	return macrolist, nindex, Collector, CInfo
end -- GetMacro

local function fnc_macro_key_check(key_scr)
	local	tbl_mcr_coll = fnc_macro_collect(key_scr)
	local	tbl_mcr_key_ok = { }
	local	macrolist = { }
	for	ii_mcr_idx, ii_mcr_item in pairs(tbl_mcr_coll)
	do	for	jj_key_full, jj_key_path in pairs(ii_mcr_item.keys_full)
		do	
			local jj_mcr_list, mcr_hi_idx = GetMacro(jj_key_full, true)
			for jj_mcr_idx, jj_mcr_obj in pairs(jj_mcr_list)
			do	local	jj_mcr_itm = tbl_mcr_key_ok[jj_mcr_obj.macro.data.id_ext]
				if not	jj_mcr_itm
				then	jj_mcr_itm = { }
					macrolist[#macrolist + 1] = jj_mcr_obj
				end
				if not	jj_mcr_itm[jj_key_full]
				then    jj_mcr_itm[jj_key_full] = {
						priority = jj_mcr_obj.priority,
						is_highest = jj_mcr_idx == mcr_hi_idx
					}
				end
				jj_mcr_itm.highest = mcr_def_idx
				tbl_mcr_key_ok[jj_mcr_obj.macro.data.id_ext] = jj_mcr_itm
			end
		end
	end
	tbl_sort(macrolist, function(m1, m2)
		local m1_prio = m1.priority	or 0
		local m2_prio = m2.priority	or 0
		local m1_sort = m1.sortpriority or 0
		local m2_sort = m2.sortpriority or 0
		if	m1_prio >  m2_prio
		then	return true
		elseif	m1_prio == m2_prio
		then	return m1_sort > m2_sort
		else	return false
		end
	end)
	return tbl_mcr_key_ok, macrolist
end -- fnc_macro_key_check


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
	end,
	last_rem = function(self)
		self.keys[#self.keys] = nil
	end
}

local function fnc_sett_data_store()
	local res_val, file_hnd = dmp_srlz.fnc_file_save(tbl_normal_ask, { file_path = own_fpath..".dat", file_init = true, file_close = true })
end

local function fnc_cas_int_to_str(cas_mod, empty_str)
	local ret_val =	""
		..(band(cas_mod, LEFT_CTRL_PRESSED	) > 0 and "LCtrl" or "")
		..(band(cas_mod, RIGHT_CTRL_PRESSED	) > 0 and "RCtrl" or "")
		..(band(cas_mod, LEFT_ALT_PRESSED	) > 0 and "LAlt"  or "")
		..(band(cas_mod, RIGHT_ALT_PRESSED	) > 0 and "RAlt"  or "")
		..(band(cas_mod, SHIFT_PRESSED		) > 0 and "Shift" or "")
	if	ret_val == ""
	and	empty_str
	then	return empty_str
	else	return ret_val
	end
end -- fnc_cas_int_to_str

Xer0X.fnc_cas_int_to_str = fnc_cas_int_to_str

local function runMacro(key, ext)
	local	eval_res = eval(key..(ext and ext or ""), 2)
	return	eval_res ~= EVAL_MACRONOTFOUND, eval_res
end

local function runMacroOrKey(the_key)
	local	eval_res = eval(the_key, 2)
	if	eval_res == EVAL_MACRONOTFOUND
	then	Keys(the_key)
	end
	return	eval_res
end

local function fnc_hnd_mcr_condition(obj_handler, rec_key, mcr_src)
	if flg_ext_mod_off then return false end
	obj_handler.prio_cond,
	obj_handler.macrolist
		= fnc_macro_key_check(obj_handler.key_ext.SCP, false)
	if next(obj_handler.prio_cond) then return 0 end
end -- fnc_hnd_mcr_condition

local function fnc_hnd_mcr_action(obj_handler, mcr_src)
	local obj_scr = far.SaveScreen()
	local key_ext_pre, key_ext_new, key_rec_pre, key_str_new, t_wait_key,
		is_ext_timeout, is_doubled, is_holding, is_cas_mod_rls, cas_int_new
--	local run_mode = "ask-normal" -- default mode
	local key_str_bas = akey(1, 0) 
	local obj_key_lev = {
		key_str_act	= key_str_bas,				
		key_str_bas	= key_str_bas,				
		key_str_bas_ext = key_str_bas,				
		key_str_seq	= key_str_bas:gsub("-", "Minus"):gsub("+", "Plus"),
		key_str_cas	= obj_handler.key_ext.KXP.cas,
		key_str_cas_rec = obj_handler.key_ext.KXP.rec_cas,
		key_ext		= obj_handler.key_ext,				
		key_rec		= fnc_NameToInputRecord(key_str_bas),		
		key_rec_act	= fnc_NameToInputRecord(key_str_bas),		
		key_exp		= { [obj_handler.key_ext.KXP.str] = obj_handler.key_ext.KXP },
		key_time	= Far.UpTime,					
	}
	local tbl_key_lev = { obj_key_lev, run_mode = "ask-normal" } -- init
	local obj_key_cur = {
		exp = obj_key_lev.key_exp,
		bas = str_lower(obj_key_lev.key_str_bas),
		key = str_lower(obj_key_lev.key_str_bas),
	}
	local tbl_key_seq = { obj_key_cur } -- init
	local key_ext	= obj_key_lev.key_ext
	local key_rec	= obj_key_lev.key_rec
	local t_last_key= obj_key_lev.key_time
	obj_status:set(obj_key_lev.key_str_seq.."-... ?", nil, 10000000)
	obj_waitkeys:init(obj_key_lev.key_str_bas)
	vkc_no_repeat = obj_key_lev.key_rec.VirtualKeyCode -- global var, prevent autorepeat
	repeat
		key_str_new, t_wait_key = obj_waitkeys:save(50)
		if (	key_str_new ==  "AltEsc"
		or	key_str_new == "RAltEsc")
		and	key_str_new ~= key_str_bas
		then	tbl_key_lev.stop_cause	= "user-cancel"
			tbl_key_lev.run_mode	= "run-cancel"
			break
		elseif	key_str_new == "ShiftSpace"
		and	key_str_bas ~= "ShiftSpace" -- allow starting ShiftSpace:Double
		--[[ "ShiftSpace" is used as ability for user to run the sequence "as is" in normal mode,
		but if so, without "ShiftSpace" if so:]]
		then	obj_waitkeys:last_rem() -- remove ShiftSpace
			tbl_key_lev.stop_cause	= "user-normal"
			tbl_key_lev.run_mode	= "run-normal"
			break
		end
		is_ext_timeout = t_wait_key - obj_key_lev.key_time > OPT_DELAY_EXT
		-- holding is considered only after exceeding OPT_DELAY_EXT time frame
		is_holding = not obj_key_lev.ext_type and key_str_new == "" and	is_ext_timeout and fnc_is_holding(obj_key_lev.key_rec)
		--[[ double key need to be double pressed in the time frame lesser than OPT_DELAY_EXT,
		to differentiate it from subsequent presses of the same key,
		as for example to differentiate "CtrlF9:Double" and "CtrlF9-CtrlF9" ]]
		is_doubled = not obj_key_lev.ext_type and key_str_new ~= "" and not is_ext_timeout
			and (	fnc_key_equal(key_str_new, obj_key_lev.key_str_act)
			or	fnc_key_equal(key_str_new, obj_key_lev.key_str_bas))
		local	str_ext =
				is_holding and key_ext.HLD and "HLD" or
				is_doubled and key_ext.DBL and "DBL"
		if	str_ext
		then
			key_str_bas = false
			obj_key_lev.ext_type		= str_ext
			obj_key_lev.key_str_bas_ext	= obj_key_lev.key_str_bas..tbl_ext_mode_disp[obj_key_lev.ext_type]
			obj_key_lev.key_str_seq 	= obj_key_lev.key_str_seq..tbl_ext_mode_disp[obj_key_lev.ext_type]
			obj_key_lev.key_bas		= obj_key_lev.key_ext 
			obj_key_lev.key_ext		= obj_key_lev.key_ext[obj_key_lev.ext_type]
			obj_key_cur.ext			= str_ext 
			obj_key_cur.key			= str_lower(obj_key_cur.key..tbl_ext_mode_disp[str_ext])
			key_ext_new			= obj_key_lev.key_ext 
		elseif
			key_str_new ~= "" -- got the next key
		then
			local	key_rec_new = fnc_NameToInputRecord(key_str_new) -- real
			local	cas_mod_is_same =
					-- for keys like Ctrl, CtrlAlt, etc. we do not need same CAS state
					({next(obj_key_lev.key_exp)})[2].key == "" or
					band(key_rec_new.ControlKeyState, MOD_MASK) ==
					band(key_rec	.ControlKeyState, MOD_MASK)
			if not	cas_mod_is_same
			and	BREAK_SEQ_ON_MOD_RELEASE
			then	tbl_key_lev.cas_mod_expect = band(key_rec    .ControlKeyState, MOD_MASK)
				tbl_key_lev.cas_mod_actual = band(key_rec_new.ControlKeyState, MOD_MASK)
				tbl_key_lev.stop_cause	= "cas-mod-not-same"
				tbl_key_lev.run_mode	= "ask-normal"
				break
			end
			local	key_str_try = key_str_new
			local	plain_tried, same_cas_tried
			local	key_exp_new, key_obj_new = fnc_key_expand(key_str_new, true, true)
			::seq_key_try::
			local	key_rec_try = fnc_NameToInputRecord(key_str_try) -- real
			local	key_exp_try, key_obj_try = fnc_key_expand(key_str_try, true, true)
			local	key_str_seq, key_obj_seq = fnc_key_equal( key_exp_try, key_ext.SEQ)
			if not	key_str_seq
			and not plain_tried
			--[[ --[=[TODO: to think about, probably we need flag "TRY PLAIN" here?
				also, probably use +(Plus) as unbreakable CAS mod ]=]
			and	cas_mod_is_same --]]
			-- KXP.key as "plain" key cant be used here, since it is NEW key
			and	key_obj_try.plain -- false in the kind of RCtrlAlt
			and	str_lower(key_str_try) ~= str_lower(key_obj_try.plain)
			then	key_str_try = key_obj_try.plain
				plain_tried = true
				goto seq_key_try
			end
			if not	key_str_seq	-- self explaining
			and not same_cas_tried	-- self explaining, isn't it?
			-- same as above musing, should we invent flag for "TRY NEXT SEQ WITH THE SAME AS PREV CAS" ?
			and	obj_key_lev.key_str_cas ~= ""		-- current key CAS need to be
			and (	plain_tried				-- means plain already tried unsuccessfully
			or	({next(key_exp_try)})[2].cas == "")	-- .. or is a plain key anyway
		--	and	({next(key_exp_new)})[2].cas == "" --[[ do it only if the original new key without CAS,
			and (	band(key_rec_new.ControlKeyState, key_rec.ControlKeyState, MOD_MASK) > 0
			-- says CAS keys can be released, but not with new CAS keys pressed:
			and	band(key_rec_new.ControlKeyState, MOD_MASK) < band(key_rec.ControlKeyState, MOD_MASK)
			or	({next(key_exp_new)})[2].cas == "")
			then	-- try with the same CAS mods as the previous key:
				key_str_try = fnc_key_prettify(obj_key_lev.key_str_cas_rec..key_str_try)
				same_cas_tried = true
				goto seq_key_try
			end
			if not	key_str_seq -- ? is it registered sequence key
			then	tbl_key_lev.stop_cause	= "wrong-seq"
				tbl_key_lev.run_mode	= "ask-normal"
				break -- run normal
			end
			obj_key_lev.next_type = "SEQ"
			obj_key_lev.next_key_str = key_str_try
			obj_key_lev.next_key_lev = {
				key_str_act =	key_str_new,
				key_rec_act =	key_rec_new,
				key_str_bas =	key_str_try,
				key_str_cas =	({next(key_exp_try)})[2].cas,
				key_str_cas_rec=({next(key_exp_try)})[2].rec_cas,
				key_ext_pre =	key_ext,
				key_ext =	key_obj_seq,
				key_rec_pre =	key_rec,
				key_rec =	key_rec_try,
				key_str_seq =	obj_key_lev.key_str_seq.."-"..fnc_key_prettify(key_str_try):gsub("-", "Minus"):gsub("+", "Plus"),
				key_exp =	key_exp_try,
				key_time=	t_wait_key,
			}
			obj_key_lev = obj_key_lev.next_key_lev
			tbl_key_lev[#tbl_key_lev + 1] = obj_key_lev
			str_ext		= "SEQ"
			key_ext_new	= obj_key_lev.key_ext
			key_rec_pre	= obj_key_lev.key_rec_pre
			key_rec		= obj_key_lev.key_rec_act
			key_str_bas	= obj_key_lev.key_str_bas 
			vkc_no_repeat	= obj_key_lev.key_rec_act.VirtualKeyCode -- prevent autorepeat
			obj_key_cur = {
				exp = obj_key_lev.key_exp,
				bas = obj_key_lev.key_str_bas,
				key = obj_key_lev.key_str_bas,
			}
			tbl_key_seq[#tbl_key_seq + 1] = obj_key_cur
		else -- no SEQ/HLD/DBL
			if	OPT_DELAY_HLP < t_wait_key - obj_key_lev.key_time
			then	local	hlp_str = fnc_get_seq_hlp(obj_key_lev.key_ext.SCP, obj_handler.prio_cond, tbl_key_seq)
				if not	hlp_str
				then
					obj_status:set(obj_key_lev.key_str_seq..(is_holding and " holding for too long?" or "!?!?!?"), nil, 10000000)
					tbl_key_lev.is_holding	= is_holding
					tbl_key_lev.is_doubled	= is_doubled
					tbl_key_lev.stop_cause	= "ext-seq-none"
					tbl_key_lev.run_mode	= "ask-normal"
					break -- considering example CtrlAltS:Doubble, but just holding
				else
					far_Message(hlp_str, obj_key_lev.key_str_seq.."-... ?", "", "l")
				end
			end
		end
		if	str_ext
		then -- some keyboard event happened
			t_last_key = t_wait_key 
			key_ext_pre = key_ext	
			key_ext = key_ext_new	
			obj_status:set(obj_key_lev.key_str_seq.."-... ?", nil, 10000000)
			if #fnc_get_fin_scp(obj_key_lev.key_ext.SCP, obj_handler.prio_cond, tbl_key_seq) > 0
			then    tbl_key_lev.stop_cause	= "ext-seq-exists"
				tbl_key_lev.run_mode	= "ext-seq-run"
				break
			end
		end
		is_cas_mod_rls, cas_int_new = fnc_is_cas_mod_rls(obj_key_lev.key_rec_act)
		if	is_cas_mod_rls 
		and	BREAK_SEQ_ON_MOD_RELEASE -- CAS changed when should not
		and (	obj_key_lev.key_bas -- need to be a plain key to break on wrong CasModChg
		or	obj_key_lev.key_ext).KXP.key ~= ""
		then	tbl_key_lev.is_cas_mod_rls = is_cas_mod_rls
			tbl_key_lev.cas_mod_int_rls = cas_int_new
			tbl_key_lev.stop_cause	= "cas-mod-rls"
			tbl_key_lev.run_mode	= "ask-normal"
			break
		end
		--[[ HUGE TODO: make here conditioning, but, actually,
		this check should be immediatly in the new sequence key receive and analize block ]]
		if  not obj_key_lev.key_ext.SEQ	-- no sequences
		and not obj_key_lev.key_ext.EXT -- no extensions to wait
		then	tbl_key_lev.stop_cause	= "no-ext-seq"
			tbl_key_lev.run_mode	= "ask-normal"
			break -- run normal, is lost sequence
		end
	until false
	far.RestoreScreen(obj_scr)
	if	tbl_key_lev.run_mode == "ask-normal"
	or	tbl_key_lev.run_mode == "run-normal"
	then
		local	res_msg, bad_key_seq
		if
			tbl_key_lev.run_mode == "run-normal"
		then
			bad_key_seq = obj_key_lev.key_str_seq
			res_msg = 1
		else
			bad_key_seq = str_format("%s + %s", obj_key_lev.key_str_seq,
				key_str_new ~= "" and key_str_new
				or is_cas_mod_rls and str_format("[cas-mod-chg:] %s  ==>> %s",
					fnc_cas_int_to_str(key_rec.ControlKeyState, "<none>"), 
					fnc_cas_int_to_str(cas_int_new, "<none>"))
				or "???")
			if not	tbl_normal_ask[Area.Current]
			then	tbl_normal_ask[Area.Current] = { }
			end
			local inf_saved, cnt_use
			inf_saved = tbl_normal_ask[Area.Current][bad_key_seq]
			cnt_use	= inf_saved and (inf_saved % 1000000) or 0
			res_msg = inf_saved and (inf_saved - cnt_use) / 1000000
			if not res_msg
			then res_msg = far.Message(
				str_format(
					"%s\n\1\nDo you want to run these keys as normal for %s area?\n\1\n%s\n\2",
					bad_key_seq, str_upper(Area.Current), tbl_concat(obj_waitkeys.keys, ", ")),
				"WRONG SEQUENCE",
				"&YES;yes &Save;&NOT;not sav&E", "w")
			end
			if	res_msg == 2
			or	res_msg == 4
			then -- to store(save) response for future use
				tbl_normal_ask[Area.Current][bad_key_seq] = res_msg * 1000000 + cnt_use + 1
				if	cnt_use == 0
				then	fnc_sett_data_store()
				end
			end
		end
		if	res_msg == 1 -- run normal, not saved
		or	res_msg == 2 -- run normal, saved as default response
		then
			obj_status:set(
				str_format("%s%s (run normal)%s", str_gsub(bad_key_seq, "-", ", "),
					tbl_key_lev.run_mode == "ask-normal" and " anassigned," or "",
					res_msg == 2 and " (saved)" or ""
				),
				nil, 2500)
			flg_ext_mod_off = true
			for ii = 1, #obj_waitkeys.keys
			do local run_res = runMacroOrKey(obj_waitkeys.keys[ii])
			end
			flg_ext_mod_off = false
		else
			obj_status:set(str_format("%s anassigned run cancel%s", bad_key_seq, res_msg == 4 and " (saved)" or ""), nil, 2500)
			mf.beep() -- http://forum.farmanager.com/viewtopic.php?p=131249#p131249
		end
	elseif
		tbl_key_lev.run_mode == "ext-seq-run"
	then
		obj_status:set(str_format("%s Run ?", obj_key_lev.key_str_seq), nil, 1000000)
		local	eval_ok, eval_res = runMacro(obj_key_lev.key_str_seq)
		if not	eval_ok
		and	eval_res == -2
		then -- just take the first macro object:
			local scr_num, scr_obj = next(fnc_get_fin_scp(obj_key_lev.key_ext.SCP, obj_handler.prio_cond, tbl_key_seq))
			eval_res = eval(({ next(scr_obj.keys_full) })[1], 2)
			eval_ok = eval_res ~= EVAL_MACRONOTFOUND
			--[[ TODO: upon unsuccess when macro not found especiallly,
			probably we should suggest ask for running rormal? ]]
		end
		obj_status:set(str_format("%s Res %s/%s", obj_key_lev.key_str_seq, eval_res, EVAL_RES[eval_res]), nil, 3000)
	elseif
		tbl_key_lev.run_mode == "run-cancel"
	then
		obj_status:set(str_format("%s sequence cancelled", obj_key_lev.key_str_seq), nil, 3000)
	end
	tbl_key_lev_hist[#tbl_key_lev_hist + 1] = tbl_key_lev -- debug purposes only
end -- fnc_hnd_mcr_action

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
	fnc_tbl_copy_to(obj_key_ext, obj_handler.key_ext, fnc_copy_key_ext_tbl, fnc_copy_key_ext_val)
	if	key_area == "common"
	then	for ii_area_name, ii_area_handlers in pairs(tbl_handlers)
		do 	if	ii_area_name ~= "common"
			and	ii_area_handlers[m_key]
			then	fnc_tbl_copy_to(ii_area_handlers[m_key].key_ext, obj_handler.key_ext, fnc_copy_key_ext_tbl, fnc_copy_key_ext_val)
				ii_area_handlers[m_key] = nil
			end
		end
	end
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
			priority	= 0, -- extended keys must NOT override plain keys
			sortpriority	= 0, -- extended keys must NOT override plain keys
			ext_key_hnd	= ii_area_key_handler,
			FileName	= own_fpath,
		}
	end end
end -- fnc_macro_ex_create


local function fnc_macro_ex_check_one(obj_mcr, create_handlers)
	local tbl_handlers_loc = { }
	local mcr_id_ext = str_upper(win_uuid(win_uuid()))
	for ii, ii_key in pairs(fnc_str_split(str_lower(obj_mcr.key), "%s", true))
	do	local ii_has_ext
		local tbl_key_ii = { }
		local tbl_ext_ii = { }
		local tbl_ext_jj = tbl_ext_ii
		for jj_key_seq, jj_key_sep in str_gmatch(ii_key, "([^-+]*)([-+]?)") 
		do
			if	jj_key_seq == ""
			then	if	#tbl_key_ii == 0
				then	--[[ this phenomena happened to me on "-",
					this is plain key, so just skip it]]
					break -- ii_has_ext remains nil here
				else	--[[ this phenomena happens onto such plain keys,
					as "Alt-" for example, should be on finalizing key ]]
					tbl_key_ii[#tbl_key_ii].key = tbl_key_ii[#tbl_key_ii].key..tbl_key_ii[#tbl_key_ii].sep
					tbl_key_ii[#tbl_key_ii].sep = jj_key_sep
					goto seq_keys_loop_end
				end
			end
			-- try to save load time:
			if not	ii_has_ext
			and (	#tbl_key_ii > 0
			or	str_find( jj_key_seq, "%S[:]%S"))
			then	ii_has_ext = true
			end
			tbl_key_ii[#tbl_key_ii + 1] = { key = jj_key_seq, sep = jj_key_sep }
			::seq_keys_loop_end::
		end
		if not	ii_has_ext
		then	goto enum_full_keys_loop_end
		end
		local tbl_scr_key_ii = { [ii_key] = {
			key_full = ii_key,
			key_path = tbl_key_ii,
			scripts = { [mcr_id_ext] = obj_mcr }
		} }
		for	jj, jj_key_seq in pairs(tbl_key_ii)
		do	jj_key_seq.key = jj_key_seq.key:gsub("minus", "-"):gsub("plus", "+") -- normalize orig key string
			local tbl_seq_stub_jj = { }
			local tbl_ext_stub_jj
			local	jj_key_base, jj_ext_mode = str_match(jj_key_seq.key, "^(.+):(.+)$")
			if	jj_ext_mode
			then	-- here ext_mode supposed to be HLD or DBL
				local	jj_ext_code = tbl_ext_mode_code[jj_ext_mode]
				if	jj_ext_code
				then	jj_key_seq.ext = jj_ext_code
					jj_key_seq.bas = jj_key_base
					tbl_ext_stub_jj = { EXT = jj_ext_code, SCP = tbl_scr_key_ii, SEQ = ALLOW_SEQ_IN_EXT and tbl_seq_stub_jj }
				else	if opts.DbgShowBadExt
					then fnc_err_msg(str_format("wrong extension %s in sequence %s", jj_ext_mode, ii_key))
					end
					goto enum_full_keys_loop_end -- cancel sequences with an unacceptable extension
				end
			else	jj_key_seq.bas = jj_key_seq.key
			end
			jj_key_seq.exp = fnc_key_expand(jj_key_seq.bas, true, false) -- unified complex key in lower case
			for kk_str, kk_val in pairs(jj_key_seq.exp)
			do 	tbl_ext_jj[kk_str] = { EXT = jj_key_seq.ext and true, KXP = kk_val, SCP = tbl_scr_key_ii }
				if	jj_key_seq.ext
				then	tbl_ext_jj[kk_str][jj_key_seq.ext] = tbl_ext_stub_jj
				else	tbl_ext_jj[kk_str].SEQ = tbl_seq_stub_jj
				end
			end
			tbl_ext_jj = jj_key_seq.ext and ALLOW_SEQ_IN_EXT and tbl_ext_stub_jj.SEQ or tbl_seq_stub_jj
		end -- end of the sequence keys processing loop
		if	obj_mcr.data.id_ext ~= mcr_id_ext
		then	
			obj_mcr.data.id_ext = mcr_id_ext
			obj_mcr.data.areas_arr = fnc_str_split(str_lower(obj_mcr.area), "%s+", true)
			obj_mcr.data.areas_dict = { }
			for mm, mm_area in pairs(obj_mcr.data.areas_arr)
			do obj_mcr.data.areas_dict[mm_area] = true
			end
			obj_mcr.data.areas_work = obj_mcr.data.areas_dict.common and { "common" } or obj_mcr.data.areas_arr
			obj_mcr.data.key_seq_all = { }
		end
		obj_mcr.data.key_seq_all[ii_key] = tbl_key_ii -- should be only once
		for mm_ext_key, mm_ext_obj in pairs(tbl_ext_ii)
		do	local areas_work =
				tbl_handlers.common and tbl_handlers.common[mm_ext_key] and { "common" }
				or obj_mcr.data.areas_work
			for ll, ll_area in pairs(areas_work)
			do	if not	tbl_handlers_loc[ll_area]
				then	tbl_handlers_loc[ll_area] = { }
				end
				tbl_handlers_loc[ll_area][mm_ext_key] = fnc_key_handler_set(ll_area, mm_ext_obj, obj_mcr)
			end
		end
		::enum_full_keys_loop_end::
	end
	if	create_handlers
	then	fnc_macro_ex_create(tbl_handlers_loc)
	end
	return tbl_handlers_loc
end -- fnc_macro_ex_check_one

local function fnc_macro_ex_build_all()
	local t1 = Far.UpTime
	for ii = 1, #LoadedMacros 
	do	local	ii_mcr = LoadedMacros[ii] 
		if	ii_mcr.key
		and not ii_mcr.keyregex
		and	str_find(ii_mcr.key, "%S[:%-%+]%S") -- %S(s) - any (non-)whitespace character
		then	fnc_macro_ex_check_one(ii_mcr)
		end
	end
	fnc_macro_ex_create(tbl_handlers)
	if opts.DbgShowLoadTime
	then far_Message(Far.UpTime - t1, "extended keys load time")
	end
	if not	Xer0X.fnc_macro_ex_build_all
	then	Xer0X.fnc_macro_ex_build_all = fnc_macro_ex_build_all	 
	end	
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
