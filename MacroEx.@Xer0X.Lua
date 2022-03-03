--[[
do return end --]]

--[[
GitHub file:
https://github.com/dr-dba/far-lua-key-efficiency/edit/main/MacroEx.@Xer0X.Lua

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
	version_mod	= "3.1.0.1",
	author		= "JD",
	author_mod	= "x-Team",
	url		= "https://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "https://forum.farmanager.com/viewtopic.php?f=15&t=12459",
	url_git		= "https://github.com/dr-dba/far-lua-key-efficiency",
	-- LuaMacro 501 (ConsoleInput)
	minfarversion	= { 3, 0, 0, 4430, 0 },
	options		= {
		BreakSeqOnModRelease
				= false,
		AllowSeqWithAnyMod
				= true,
		AllowSeqInExt	= true,
		DelayExt	=  400, -- 500 is ok
		DelaySeq	= 2000,
		DelayHlp	= 3000,
		LimitHld	=  400,
		LimitDbl	=  600,
		ExtModes	= {
			HLD = true, -- holding
			DBL = true, -- double
			STT = true, -- state
			MNY = true, -- many of the key expr
		},
		DbgShowBadExt	= false,
		DbgShowBadKey	= false,
		DbgShowLoadTime	= true,
	}
})
if not nfo then return end
local opts = nfo.options
local BREAK_SEQ_ON_MOD_RELEASE	= opts.BreakSeqOnModRelease
local ALLOW_SEQ_WITH_ANY_MOD	= opts.AllowSeqWithAnyMod
local ALLOW_SEQ_IN_EXT		= opts.AllowSeqInExt
local OPT_DELAY_SEQ		= opts.DelaySeq
local OPT_DELAY_HLP		= opts.DelayHlp
local OPT_DELAY_EXT		= opts.DelayExt
local OPT_LIMIT_HLD		= opts.LimitHld
local OPT_LIMIT_DBL		= opts.LimitDbl

-- @@@ END OF THE INFO AND OPTIONS BLOCK @@@

local F	= far.Flags
local C = far.Colors

local KEY_EVENT		= F.KEY_EVENT			
local MOUSE_EVENT	= F.MOUSE_EVENT			
local WND_BUF_SIZE_EVT	= F.WINDOW_BUFFER_SIZE_EVENT 	
local MENU_EVENT	= F.MENU_EVENT			
local FOCUS_EVENT	= F.FOCUS_EVENT			
local ACTL_GETFARRECT	= F.ACTL_GETFARRECT
local ACTL_GETCURSORPOS = F.ACTL_GETCURSORPOS
local ACTL_SETCURSORPOS	= F.ACTL_SETCURSORPOS
local ACTL_REDRAWALL	= F.ACTL_REDRAWALL
local EOPT_SHOWTITLEBAR = F.EOPT_SHOWTITLEBAR
local EOPT_SHOWKEYBAR	= F.EOPT_SHOWKEYBAR
local EOPT_SHOWSCROLLBAR= F.EOPT_SHOWSCROLLBAR
local DI_SINGLEBOX	= F.DI_SINGLEBOX
local DI_TEXT		= F.DI_TEXT
local FDLG_NONMODAL	= F.FDLG_NONMODAL
local DN_CLOSE		= F.DN_CLOSE

local str_lower = utf8.Utf8_lower	or utf8.lower
local str_upper = utf8.Utf8_upper	or utf8.upper
local str_gmatch= utf8.Utf8_gmatch	or utf8.gmatch
local str_match = utf8.Utf8_match	or utf8.match
local str_find	= utf8.Utf8_find	or utf8.find
local str_gsub	= utf8.Utf8_gsub	or utf8.gsub
local str_len	= utf8.Utf8_len		or utf8.len
local str_rev	= utf8.reverse		or utf8.reverse
local str_sub	= utf8.sub
local str_cfind = utf8.cfind
local str_format= utf8.format
local str_fmt	= utf8.format
local str_fmt_u	= utf8.format
local str_fmt_s	= string.format
local str_low_s = string.lower
local str_low_a = string.lower
local str_low	= string.lower
local math_min	= math.min
local math_max	= math.max
local tbl_concat= table.concat
local tbl_insert= table.insert
local tbl_ins	= table.insert
local tbl_remove= table.remove
local tbl_sort	= table.sort
local tostr	= tostring
local tostring	= tostring
local io_open	= io.open
local bit64_band= bit64.band
local dbg_getinf= debug.getinfo

local far_Message		= far.Message
local far_ProcessName		= far.ProcessName
local far_NameToInputRecord	= far.NameToInputRecord
local far_InputRecordToName	= far.InputRecordToName
local far_AdvControl		= far.AdvControl
local far_Timer			= far.Timer
local far_Text			= far.Text
local mf_postmacro		= mf.postmacro
local mf_waitkey		= mf.waitkey
local win_uuid			= win.Uuid
local win_GetKeyState		= win.GetKeyState
local editor_GetInfo		= editor.GetInfo
local panel_GetCmdLineSelection = panel.GetCmdLineSelection
local panel_SetCmdLineSelection = panel.SetCmdLineSelection
local panel_GetCmdLinePos	= panel.GetCmdLinePos
local panel_SetCmdLinePos	= panel.SetCmdLinePos
local panel_GetCmdLine		= panel.GetCmdLine

local MCODE_F_CHECKALL		= 0x80C64
local MCODE_F_GETOPTIONS	= 0x80C65 
local MCODE_F_MACROSETTINGS	= 0x80C6A

local EVAL_SHIFT_X		= 1000
local EVAL_SUCCESS		=  0
local EVAL_SUCCESS_X		=  0 + EVAL_SHIFT_X
local EVAL_SYNTAXERROR		= 11
local EVAL_BADARGS		= -1
local EVAL_MACRONOTFOUND	= -2
local EVAL_MACRONOTFOUND_X	= -2 - EVAL_SHIFT_X
local EVAL_MACROCANCELED	= -3
local EVAL_RUNTIMEERROR		= -4
local EVAL_RES = {
	 [EVAL_SUCCESS]		= "EVAL_SUCCESS"	--  0
	,[EVAL_SYNTAXERROR]	= "EVAL_SYNTAXERROR"	-- 11
	,[EVAL_BADARGS]		= "EVAL_BADARGS"	-- -1
	,[EVAL_MACRONOTFOUND]	= "EVAL_MACRONOTFOUND"	-- -2 макрос не найден среди загруженных макросов
	,[EVAL_MACROCANCELED]	= "EVAL_MACROCANCELED"	-- -3 было выведено меню выбора макроса, и пользователь его отменил
	,[EVAL_RUNTIMEERROR]	= "EVAL_RUNTIMEERROR"	-- -4 макрос был прерван в результате ошибки времени исполнения
	,[EVAL_SUCCESS_X]	= "EVAL_SUCCESS_X"
	,[EVAL_MACRONOTFOUND_X]	= "EVAL_MACRONOTFOUND_X"
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
local fnc_extr_file_name= Xer0X.fnc_str_extract_file_name
local fnc_tbl_copy	= Xer0X.fnc_tbl_copy
local fnc_str_split	= Xer0X.fnc_str_split
local fnc_tbl_copy_to	= Xer0X.fnc_tbl_copy_to
local fnc_tbl_count	= Xer0X.fnc_tbl_count
local fnc_case_title 	= Xer0X.fnc_case_title
local fnc_case_toggle	= Xer0X.fnc_case_toggle
local fnc_key_prettify	= Xer0X.fnc_key_prettify
local obj_status	= Xer0X.obj_screen_status_line
local LoadedMacros	= Xer0X.utils.LoadedMacros
local GetAreaCode	= Xer0X.utils_shared.GetAreaCode
local MacroCallFar	= Xer0X.utils.MacroCallFar
local utils_Areas	= Xer0X.utils.Areas

local RLSD_KEYS_CHCK_TICK = 100
local rlsd_keys_chck_last = Far.UpTime

local	tbl_ext_mode_code = { double = "DBL",	hold = "HLD",	state = "STT"	, many = "MNY"	}
local	tbl_ext_mode_disp = { DBL = ":Double",	HLD = ":Hold",	STT = ":State"	, MNY = ":Many" }

local	Xer0X	= require("Lib-Common-@Xer0X")
local	dmp_srlz= require("dmp-tbl-alt-@Xer0X")
local	req_ok, req_msg, fnc_lua_exp= Xer0X.fnc_safe_require("LuaExplorer-@Xer0X")
if not	req_ok
then	req_ok, req_msg, fnc_lua_exp= Xer0X.fnc_safe_require("LE")
end
local	as_mdl, inp_args, own_fpath = Xer0X.fnc_file_whoami({ ... })
local	FileName = ... or own_fpath
local	MACRO_HELP_FOOTER = "\n\1\nPress AltEscape to cancel the sequence\nPress ShiftSpace to run as normal keys"

local tbl_hld_keys = { }
Xer0X.tbl_hld_keys = tbl_hld_keys
local tbl_key_states = { }
Xer0X.tbl_key_states = tbl_key_states
local tbl_macro_ex_handlers = { }
Xer0X.tbl_macro_ex_handlers = tbl_macro_ex_handlers
local tbl_ext_key_lev_hist = { }
Xer0X.tbl_ext_key_lev_hist = tbl_ext_key_lev_hist
local tbl_key_inp_rec_cache = { } -- micro optimization
Xer0X.tbl_key_inp_rec_cache = tbl_key_inp_rec_cache
local tbl_key_evt_journal = { [KEY_EVENT] = { }, [MOUSE_EVENT] = { }, [MENU_EVENT] = { }, [FOCUS_EVENT] = { }, [WND_BUF_SIZE_EVT] = { }, [0] = { }, ALL = { } }
Xer0X.tbl_key_evt_journal = tbl_key_evt_journal
local tbl_parsed_keys_val_cache = { }
Xer0X.tbl_parsed_keys_val_cache = tbl_parsed_keys_val_cache
local tbl_parsed_keys_bad_cache = { }
Xer0X.tbl_parsed_keys_bad_cache = tbl_parsed_keys_bad_cache
local tbl_key_mcr_journal = { }
Xer0X.tbl_key_mcr_journal = tbl_key_mcr_journal
local tbl_ext_seq_key_reg = { }
Xer0X.tbl_ext_seq_key_reg = tbl_ext_seq_key_reg
local tbl_key_expanded_cache = { }
Xer0X.tbl_key_expanded_cache = tbl_key_expanded_cache

local tbl_normal_ask__load = loadfile(own_fpath..".dat")
local tbl_normal_ask = tbl_normal_ask__load and tbl_normal_ask__load() or { }
local vkc_no_repeat, flg_ext_mod_off -- to disable handler in order to run an original macro

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

local fnc_NameToInputRecord = function(the_key)
	local	the_key_rec = tbl_key_inp_rec_cache[the_key]
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
	if not	key_inp_rec
	then    if opts.DbgShowBadKey
		then fnc_err_msg(str_format("Unexpected AKey: %q", the_key))
		end
	else	tbl_key_inp_rec_cache[the_key] = key_inp_rec
	end
	return key_inp_rec
end

Xer0X.fnc_NameToInputRecord = fnc_NameToInputRecord

local function fnc_jrnl_inp_key_vis(j_rec)
	return str_format("[%s] %s %s c:%s vkc:%s down:%s cks:%s", 
		tostring(j_rec.key_rec.EventType), 
		j_rec.area, j_rec.InpRecName or "<?>", 
		tostring(j_rec.key_rec.UnicodeChar), 
		tostring(j_rec.key_rec.VirtualKeyCode), 
		tostring(j_rec.key_rec.KeyDown), 
		tostring(j_rec.key_rec.ControlKeyState) 
	)
end

local function fnc_con_inp_journal(key_inp_rec)
	if Area.Menu and Menu.Id == "7646F761-8954-42CA-9CFC-E3F98A1C54D3" then return { } end
	local rec_j, tbl_j
	rec_j = { area = Area.Current, key_rec = key_inp_rec, key_time = Far.UpTime, p1 = p1, p2 = p2, _LEX_DISPLAY_STR = fnc_jrnl_inp_key_vis }
	tbl_j = tbl_key_evt_journal.ALL
	tbl_j[#tbl_j + 1] = rec_j
	if #tbl_j > 1000 then tbl_remove(tbl_j, 1) end
	tbl_j = tbl_key_evt_journal[key_inp_rec.EventType]
	tbl_j[#tbl_j + 1] = rec_j
	if #tbl_j > 1000 then tbl_remove(tbl_j, 1) end
	return rec_j
end

local function fnc_key_state_run_remove(key_state, dt_now)
	local	key_state_id = type(key_state) == "table" and key_state.key_state_id or key_state
	local	key_state_obj= type(key_state) == "table" and key_state or tbl_key_states[key_state]
	if	key_state_obj.fnc_state_final
	then	key_state_obj:fnc_state_final(dt_now)
	end
	local	keys_run_normal	=  
			key_state_obj.key_run_normal_if_state_was_not_used and 
			key_state_obj.cnt_other_pressed == 0
	for ii_key_name, ii_key_obj in pairs(key_state_obj.keys)
	-- clean the state from all keys
	do	ii_key_obj.states[key_state_id] = nil
		if	keys_run_normal 
		then	tbl_ext_key_lev_hist[#tbl_ext_key_lev_hist].reset_hld_stt = ii_key_name
			mf_postmacro(Keys, ii_key_obj.key_name)
		end
	end
	key_state_obj.is_closed = dt_now
	key_state_obj.is_open = false
	tbl_key_states[key_state_id] = nil
	return key_state_obj, key_state_id
end

local function fnc_is_holding(key_inp_rec) return vkc_no_repeat == key_inp_rec.VirtualKeyCode end

Event {	description = "MacroEx helper",
	group = "ConsoleInput",
	action = function(key_inp_rec, p1, p2)
		local	j_rec	= fnc_con_inp_journal(key_inp_rec)
		local	dt_now	= Far.UpTime
		local	vkc, KeyDown, tbl_key_off
		local	evt_type = key_inp_rec.EventType
		if	evt_type == KEY_EVENT
		then
			vkc	= key_inp_rec.VirtualKeyCode
			KeyDown = key_inp_rec.KeyDown
			if	KeyDown
			then	Xer0X.cnt_inp_key_press = (Xer0X.cnt_inp_key_press or 0) + 1
			end
			local	InpRecName = far_InputRecordToName(fnc_tbl_copy(key_inp_rec, { KeyDown = true }, true))
			if	InpRecName
			then	j_rec.InpRecName = InpRecName
				local InpRecName_low = str_lower(InpRecName)
				local key_is_on, key_toggle = win_GetKeyState(vkc)
				for ii_key_name, ii_key_obj in pairs(tbl_hld_keys)
				do	if	ii_key_obj.key_vcd == vkc
					then 	ii_key_obj.key_is_on =	key_is_on
						ii_key_obj.key_toggle =	key_toggle
						if	KeyDown
						then
							ii_key_obj.cnt_state_pressed = (ii_key_obj.cnt_state_pressed or 0) + 1
							ii_key_obj.dt_state_pressed = dt_now
							if	ii_key_obj.eat_press_repeat
							then	j_rec.suppress = true
							end
						else	-- KeyUp!
							tbl_key_off = { [ii_key_obj.key_name_low] = ii_key_obj }
							if	ii_key_obj.key_name_low ~= InpRecName_low
							then	ii_key_obj.key_name_off  = InpRecName
							end
						end
					else
						if	KeyDown
						then	ii_key_obj.cnt_other_pressed = (ii_key_obj.cnt_other_pressed or 0) + 1
							ii_key_obj.dt_other_pressed = dt_now
						end
					end
				end
				for ii_stt_id, ii_stt_obj in pairs(tbl_key_states)
				do	for jj_stt_key_name, jj_stt_key_obj in pairs(ii_stt_obj.keys)
					do	local	key_belongs_to_state
						if	jj_stt_key_obj.key_vcd == vkc
						then	key_belongs_to_state = true
							ii_stt_obj.cnt_state_pressed = (ii_stt_obj.cnt_state_pressed or 0) + 1
							break
						end
						if not	key_belongs_to_state
						then	ii_stt_obj.cnt_other_pressed = (ii_stt_obj.cnt_other_pressed or 0) + 1
						end
					end
				end
			end
			local	last_hist = tbl_ext_key_lev_hist[#tbl_ext_key_lev_hist]
			local	last_hist_key = last_hist and last_hist[#last_hist]
			if	vkc
			and	last_hist_key
			and not last_hist.reset_hld_stt
			and (	last_hist_key.ext_type == "HLD"
			or	last_hist_key.ext_type == "STT")
			and	last_hist.run_mode == "ext-seq-run"
			then	if last_hist_key.key_rec.VirtualKeyCode == vkc
				then	j_rec.suppress = true
				else	key_inp_rec.KeyTime = Far.UpTime 
					key_inp_rec.KeyExitDeltaTime = last_hist.exit_time and key_inp_rec.KeyTime - last_hist.exit_time
					key_inp_rec.KeyExecDeltaTime = last_hist.exec_time and key_inp_rec.KeyTime - last_hist.exec_time
					last_hist.reset_hld_stt = key_inp_rec
				end
			end
			if	vkc_no_repeat
			and	vkc ~= 0
			then	-- KEY_NONE? inp_rec.VirtualKeyCode == 0
				-- prevent senseless repeating the same key
				if	vkc == vkc_no_repeat
				and	key_inp_rec.KeyDown
				then	return 1 -- eat repetitions
				else	vkc_no_repeat = false
				end
			end
		end
		if	dt_now - rlsd_keys_chck_last > RLSD_KEYS_CHCK_TICK
		or	tbl_key_off -- due to KeyUp event above
		then	rlsd_keys_chck_last = dt_now
			if not next(tbl_hld_keys) then goto after_key_off_chk end
			for ii_key_name, ii_key_obj in pairs(tbl_hld_keys)
			do	if not (tbl_key_off -- again, due to KeyUp event above
				and	tbl_key_off[ii_key_name])
				and	ii_key_obj.key_vcd
				then	ii_key_obj.key_is_on, ii_key_obj.key_toggle = win_GetKeyState(ii_key_obj.key_vcd)
					if not 	ii_key_obj.key_is_on
					then	if not tbl_key_off then tbl_key_off = { } end
						tbl_key_off[ii_key_name] = ii_key_obj
					else	-- same as for "if KeyDown"
						ii_key_obj.cnt_state_checked = (ii_key_obj.cnt_state_checked or 0) + 1
					        ii_key_obj.dt_state_checked = dt_now
						if	ii_key_obj.states
						then	for jj_stt_id, jj_stt_obj in pairs(ii_key_obj.states)
							do	jj_stt_obj.dt_state_checked = dt_now
								jj_stt_obj.cnt_state_checked = (jj_stt_obj.cnt_state_checked or 0) + 1
								if	jj_stt_obj.fnc_state_repeat
								and(not	jj_stt_obj.tick_state_repeat
								or	jj_stt_obj.tick_state_repeat < dt_now - (ii_key_obj.dt_state_repeat or 0))
								then	jj_stt_obj:fnc_state_repeat(dt_now)
									jj_stt_obj.dt_state_repeat = dt_now
								end
							end
						end
					end
				else
				end
			end			
			if not tbl_key_off then goto after_key_off_chk end
			local tbl_stt_off = { }
			for ii_key_name, ii_key_obj in pairs(tbl_key_off)
			do	ii_key_obj.is_closed = dt_now
				ii_key_obj.is_open = false
				tbl_hld_keys[ii_key_name] = nil
				if	ii_key_obj.states
				then	for ii_state_id, ii_state_obj in pairs(ii_key_obj.states)
					do tbl_stt_off[ii_state_id] = ii_state_obj
					end
				end
			end
			for ii_state_id, ii_state_obj in pairs(tbl_stt_off)
			do fnc_key_state_run_remove(ii_state_id, dt_now)
			end			
			::after_key_off_chk::
		end
		return j_rec.suppress
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


local rgx_key_parse_v2 = regex.new("/^(l?ctrl)?(rctrl)?(l?alt)?(ralt)?(shift)?(.+)?$/i")
local function fnc_key_parse(the_key, case_sens)
	if not	the_key then return end
	local	key_cache = str_format("%s|%s", the_key, tostring(case_sens))
	local	obj_parsed = tbl_parsed_keys_val_cache[key_cache]
	if	obj_parsed
	then	return obj_parsed
	end
	if	tbl_parsed_keys_bad_cache[key_cache]
	then	return false
	end
	local the_key_low = case_sens and the_key or str_lower(the_key)
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
	then	tbl_parsed_keys_bad_cache[key_cache] = { t_rec_1, t_rec_2 }
		return false
	end
	::after_validity_check::
	t_rec_1.ctl_x = not t_rec_1.ctl_r and t_rec_1.ctl_l and str_lower(t_rec_1.ctl_l) == "ctrl"
	t_rec_1.alt_x = not t_rec_1.alt_r and t_rec_1.alt_l and str_lower(t_rec_1.alt_l) == "alt"
	t_rec_1.ctl_e = t_rec_1.ctl_r or t_rec_1.ctl_l
	t_rec_1.alt_e = t_rec_1.alt_r or t_rec_1.alt_l
	tbl_parsed_keys_val_cache[key_cache] = t_rec_1
	return t_rec_1
end -- fnc_key_parse

local function fnc_key_expand(the_key, in_lower, as_single , obj_rgx)
--	assert(key:match("^%l+$")) is_regex
	if not	the_key then return end
	local	key_cache = str_format("%s|%s|%s", the_key, tostring(in_lower), tostring(as_single))
	local	obj_cache = tbl_key_expanded_cache[key_cache]
	if	obj_cache then return unpack(tbl_key_expanded_cache[key_cache]) end
	local R =	in_lower and "r"	or "R"
	local L	=	in_lower and "l"	or "L"
	local ALT =	in_lower and "alt"	or "Alt"
	local CTL =	in_lower and "ctrl"	or "Ctrl"
	local obj_key = obj_rgx 
		and { regex = the_key, reobj = obj_rgx }
		or fnc_key_parse(the_key, not in_lower)
	local tbl_exp = { }
	local ctl, alt
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
		plain = obj_key.plain,
		regex = obj_key.regex,
		reobj = obj_key.reobj,
	}
	tbl_key.cas =	(ctl and ctl..CTL or (obj_key.ctl_l and L..CTL or "")..(obj_key.ctl_r and R..CTL or ""))..
			(alt and alt..ALT or (obj_key.alt_l and L..ALT or "")..(obj_key.alt_r and R..ALT or ""))..
			(obj_key.shift or "")
	tbl_key.rec_cas=(ctl and (ctl == R and R or "")..CTL or (obj_key.ctl_l and L..CTL or "")..(obj_key.ctl_r and R..CTL or ""))..
			(alt and (alt == R and R or "")..ALT or (obj_key.alt_l and L..ALT or "")..(obj_key.alt_r and R..ALT or ""))..
			(obj_key.shift or "")
	tbl_key.str = tbl_key.cas	..(obj_key.plain or obj_key.regex or "")
	tbl_key.rec = tbl_key.rec_cas	..(obj_key.plain or "")
	tbl_exp[tbl_key.str] = tbl_key
	alt = not as_single and alt == L and R
	until not alt
	ctl = not as_single and ctl == L and R
	until not ctl
	tbl_key_expanded_cache[key_cache] = { tbl_exp, obj_key }
	return tbl_exp, obj_key
end -- fnc_key_expand

local function fnc_key_equal(key_base, key_comp, case_sens)
	if not	key_base
	or not	key_comp
	or	key_base == ""
	or	key_comp == ""
	then	return
	end
	local tbl_base = type(key_base) == "table" and key_base or fnc_key_expand(key_base, not case_sens, false)
	local tbl_comp = type(key_comp) == "table" and key_comp or fnc_key_expand(key_comp, not case_sens, false)
	for ii_base, ii_base_val in pairs(tbl_base) do
	for ii_comp, ii_comp_val in pairs(tbl_comp) do
	if	str_lower(ii_base)
	==	str_lower(ii_comp)
	then	return ii_comp:lower(), ii_comp_val
	elseif	ii_comp_val.reobj
	and	ii_comp_val.reobj:match(ii_base) ~= ""
	then	return ii_comp, ii_comp_val
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

local function fnc_get_ext_chk(obj_key_lev, key_str_new, t_wait_key)
	local tbl_ext_allowed = {
		-- holding is considered only after exceeding OPT_DELAY_EXT time frame
		["HLD"] = not obj_key_lev.ext_type and key_str_new == "" and fnc_is_holding(obj_key_lev.key_rec) and ((t_wait_key - obj_key_lev.key_time) > OPT_LIMIT_HLD and 2 or 1) or 0,
		["DBL"] = not obj_key_lev.ext_type and (t_wait_key - obj_key_lev.key_time) < OPT_LIMIT_DBL and (key_str_new ~= "" and (fnc_key_equal(key_str_new, obj_key_lev.key_str_bas) and 2 or 0) or 1) or 0,
		["STT"] = not obj_key_lev.ext_type and key_str_new == "" and vkc_no_repeat and win_GetKeyState(vkc_no_repeat) and 2 or 0,
		["MNY"] = (obj_key_lev.ext_type or "MNY") == "MNY" and (key_str_new ~= "" and 2 or 1) or 0,
		["NON"] = key_str_new == "" and 2 or 0,
		["SEQ"] = key_str_new ~= "" and 2 or 1,
	}
	local tbl_ext = { }
	local cur_ext_type = obj_key_lev.ext_type or "NON"
	for ii_mcr_key_cur_full, ii_mcr_key_cur_coll in pairs(obj_key_lev.mcr_key_cur)
	do	for ii_mcr_key_cur_idx, ii_mcr_key_cur_obj in ipairs(ii_mcr_key_cur_coll)
		do
			local	ii_mcr_key_cur_ext = ii_mcr_key_cur_obj.key_path_cur.ext or "NON"
			if	ii_mcr_key_cur_ext == cur_ext_type
			and	ii_mcr_key_cur_ext ~= "MNY"
			and	ii_mcr_key_cur_obj.key_path_len >
				ii_mcr_key_cur_obj.key_path_pos
			then	ii_mcr_key_cur_ext = "SEQ"
			end
			if	tbl_ext_allowed[ii_mcr_key_cur_ext] == 0
			then	goto loop_end
			elseif	tbl_ext_allowed[ii_mcr_key_cur_ext] == 1
			then	ii_mcr_key_cur_ext = "PRE"
			elseif	tbl_ext_allowed[ii_mcr_key_cur_ext] == 2
			then	-- is eligible
			else	-- just can not be
			end
			::again_for_seq_after_many::
			if not	tbl_ext[ii_mcr_key_cur_ext]
			then	tbl_ext[ii_mcr_key_cur_ext] = { count = 1 }
			else	tbl_ext[ii_mcr_key_cur_ext].count = 
				tbl_ext[ii_mcr_key_cur_ext].count + 1
			end
			if not	tbl_ext[ii_mcr_key_cur_ext][ii_mcr_key_cur_obj.key_full]
			then	tbl_ext[ii_mcr_key_cur_ext][ii_mcr_key_cur_obj.key_full] = { count = 1 }
			else	tbl_ext[ii_mcr_key_cur_ext][ii_mcr_key_cur_obj.key_full].count = 
				tbl_ext[ii_mcr_key_cur_ext][ii_mcr_key_cur_obj.key_full].count + 1
			end
			tbl_ins(tbl_ext[ii_mcr_key_cur_ext][ii_mcr_key_cur_obj.key_full], ii_mcr_key_cur_obj)
			if	ii_mcr_key_cur_ext == "MNY"
			and	ii_mcr_key_cur_obj.key_path_len >
				ii_mcr_key_cur_obj.key_path_pos
			then	ii_mcr_key_cur_ext = "SEQ"
				goto again_for_seq_after_many
			end
			::loop_end::
		end
	end
	local str_ext = tbl_ext.STT and "STT" -- potentially every keys can be a state key, highest priority
		or	tbl_ext.HLD and "HLD"
		or	tbl_ext.DBL and "DBL"
		or	tbl_ext.MNY and "MNY"
		or	tbl_ext.SEQ and "SEQ"
	return	str_ext, tbl_ext, tbl_ext_allowed
end -- fnc_get_ext_chk

local function fnc_get_fin_scp(key_scr, prio_cond, tbl_key_lev, final_only)
	local	tbl_mcr_coll = fnc_macro_collect(key_scr or { })
	local	tbl_mcr_help = { }
	local	tbl_res_equal = { }
	local	tbl_res_final = { }
	local	tbl_mcr_key_cur = { }
	for ii_mcr_id, ii_mcr_item in pairs(tbl_mcr_coll)
	do	for jj_key_full, jj_key_path in pairs(ii_mcr_item.keys_full)
		do	if	prio_cond[ii_mcr_id]
			and	prio_cond[ii_mcr_id][jj_key_full]
			then    if not	final_only
				then	local is_equal, is_final, in_many
					local jj_key_pos = 1
					for kk_seq_pos, kk_seq_key in ipairs(tbl_key_lev)
					do	::loop_code_start::
						is_many = jj_key_path[jj_key_pos].ext == "MNY" and (kk_seq_key.ext_type or "MNY") == "MNY"
						is_equal = fnc_key_equal(
							is_many and kk_seq_key.key_str_bas or kk_seq_key.key_exp,
							jj_key_path[jj_key_pos].exp,
							is_many -- lets suppose MNY is always regexp-based and thus case-sensitive
								) and (
							is_many -- multiple expected, allow it
							or	kk_seq_pos == #tbl_key_lev  -- the last key in the sequence, 
							and not kk_seq_key.ext_type -- .. and still no extension determined in the last.
							or	kk_seq_key.ext_type == jj_key_path[jj_key_pos].ext -- good obviously
								)
						if	is_equal
						then	if	jj_key_pos == #jj_key_path
							and	kk_seq_pos == #tbl_key_lev
							then	is_final = kk_seq_key.ext_type == jj_key_path[jj_key_pos].ext
							elseif	kk_seq_pos < #tbl_key_lev
							and not	is_many
							then	jj_key_pos = jj_key_pos + 1
							end
						else	-- is not equal, exit keys path
							if not	is_many
							or	jj_key_pos == #jj_key_path
							then	break
							elseif	is_many 
							then	jj_key_pos = jj_key_pos + 1
								goto loop_code_start
							end
						end
					end
					if	is_equal
					then	tbl_res_equal[#tbl_res_equal + 1] = ii_mcr_item
						if not	is_final
						or	jj_key_path[jj_key_pos].ext == "MNY"
						then	tbl_mcr_help[#tbl_mcr_help + 1] = fnc_key_prettify(jj_key_full).." - "..ii_mcr_item.obj_macro.description
						end
						if not	tbl_mcr_key_cur[jj_key_full]
						then	tbl_mcr_key_cur[jj_key_full] = { count = 1 }
						else	tbl_mcr_key_cur[jj_key_full].count = tbl_mcr_key_cur[jj_key_full].count + 1
						end
						tbl_ins(tbl_mcr_key_cur[jj_key_full], {
							is_final	= is_final,
							key_path_pos	= jj_key_pos,
							key_path_cur	= jj_key_path[jj_key_pos],
							key_path_len	=#jj_key_path,
							key_full	= jj_key_full,
							mcr_item	= ii_mcr_item,
							mcr_extid	= ii_mcr_item.mcr_extid,
						})
					end
					if	is_final -- the logic means that it is also equal automatically
					then	tbl_res_final[#tbl_res_final + 1] = ii_mcr_item
					end
				end
			end
		end
	end
	local	hlp_str = next(tbl_mcr_help) and tbl_concat(tbl_mcr_help, "\n")..MACRO_HELP_FOOTER or false
	return	tbl_res_equal, tbl_res_final, tbl_mcr_key_cur, hlp_str
end -- fnc_get_fin_scp

local function GetMacro(argKey, argUseCommon)
	local area_name = str_low_a(Area.Current)
	local Area_Names = { area_name, argUseCommon and area_name ~= "common" and "common" or nil }
	local key = str_low_a(argKey) 
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
				do	
					if	jj_m.data.key_state_active_prevents_new
					and	jj_m.data.key_states
					then	for ii_key_stt_id, ii_key_stt_obj in pairs(jj_m.data.key_states)
						do	if ii_key_stt_obj.is_open
							then goto loop_cycle_end
							end
						end
					end
					if not	jj_m.disabled
					and	jj_m.data.areas_dict[ii_areaname]
					and not(ii_areaname == "common"		
					and	jj_m.data.areas_dict[area_name])
					then	ExamineMacro(jj_m, ii_areaname) 
					end
					::loop_cycle_end::
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

local function fnc_mcr_key_check(key_scr)
	local tbl_mcr_coll = fnc_macro_collect(key_scr)
	local tbl_mcr_key_ok = { }
	local macrolist = { }
	for ii_mcr_idx, ii_mcr_item in pairs(tbl_mcr_coll)
	do	for jj_key_full, jj_key_path in pairs(ii_mcr_item.keys_full)
		do	
			local jj_mcr_list, mcr_hi_idx = GetMacro(jj_key_full, true)
			for jj_mcr_idx, jj_mcr_obj in pairs(jj_mcr_list)
			do
				local	jj_mcr_itm = tbl_mcr_key_ok[jj_mcr_obj.macro.data.id_ext]
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
end -- fnc_mcr_key_check


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

local function runMacroOrKey(the_key)
	local	eval_res = eval(the_key, 2)
	if	eval_res == EVAL_MACRONOTFOUND
	then	Keys(the_key)
	end
	return	eval_res
end

local function fnc_eat_hld_stt_rep_outer(rec_key)
	local	last_hist = tbl_ext_key_lev_hist[#tbl_ext_key_lev_hist]
	local	last_hist_key = last_hist and last_hist[#last_hist]
	if	last_hist_key
	and not last_hist.reset_hld_stt
	and	last_hist.run_mode == "ext-seq-run"
	and (	last_hist_key.ext_type == "HLD"
	or	last_hist_key.ext_type == "STT" )
	and	last_hist_key.key_str_act == rec_key
	then	return true
	end
end

Xer0X.fnc_eat_hld_stt_rep_outer = fnc_eat_hld_stt_rep_outer

local function fnc_key_state_add(state_key, key_state_id, eat_press_repeat, tick_state_repeat, fnc_state_init, fnc_state_repeat, fnc_state_final, key_run_normal_if_state_was_not_used)
	local	dt_now = Far.UpTime
	local	state_key_low = state_key:lower()
	if not	key_state_id
	then	key_state_id = win_uuid(win_uuid())
	end
	local	obj_hld_key =	tbl_hld_keys[state_key_low]
	local	obj_key_state = tbl_key_states[key_state_id]
	if not	obj_key_state
	then	obj_key_state = {
			key_state_id = key_state_id, 
			is_open = dt_now,
			keys = { },
			obj_self = obj_hld_key,
			fnc_state_init = fnc_state_init,
			eat_press_repeat = eat_press_repeat,
			tick_state_repeat = tick_state_repeat,
			fnc_state_repeat = fnc_state_repeat,
			fnc_state_final = fnc_state_final,
			key_run_normal_if_state_was_not_used = key_run_normal_if_state_was_not_used,
			cnt_inp_key_press_start = Xer0X.cnt_inp_key_press,
			cnt_other_pressed = 0,
		}
		tbl_key_states[key_state_id] = obj_key_state
	end
	if	obj_hld_key
	then	
		obj_hld_key.cnt_state_pressed = obj_hld_key.cnt_state_pressed + 1
		obj_hld_key.dt_pressed = dt_now
		for ii_key in pairs(obj_hld_key.states)
		do	if ii_key ~= key_state_id
			then obj_hld_key.states[ii_key] = nil
			end
		end
		if not	obj_hld_key.states[key_state_id]
		then	obj_hld_key.states[key_state_id] = obj_key_state
		end
	else	
		local key_rec = fnc_NameToInputRecord(state_key_low) 
		obj_hld_key = {
			dt_state_created = dt_now,
			dt_state_pressed = dt_now,
			cnt_state_pressed= 1,
			cnt_state_checked= 0,
			cnt_inp_key_press_start = Xer0X.cnt_inp_key_press,
			area_init	= Area.Current,
			key_name	= state_key,
			key_name_low	= state_key_low,
			key_rec		= key_rec,
			key_vcd		= key_rec.VirtualKeyCode,
			obj_self	= obj_hld_key,
			states		= { [key_state_id] = obj_key_state }
		}
		tbl_hld_keys[state_key_low] = obj_hld_key
	end
	if not	obj_key_state.keys[state_key_low]
	then	obj_key_state.keys[state_key_low] = obj_hld_key
	end
	return key_state_id, obj_key_state, obj_hld_key
end -- fnc_key_state_add

local function fnc_hnd_mcr_condition(obj_handler, rec_key, mcr_src)
	if	flg_ext_mod_off
	or	fnc_eat_hld_stt_rep_outer(rec_key)
	then	return false
	end
	obj_handler.prio_cond,
	obj_handler.macrolist
		= fnc_mcr_key_check(obj_handler.key_ext.SCP, false)
	if next(obj_handler.prio_cond) then return 0 end
end -- fnc_hnd_mcr_condition

local MULTI_KEY_EXT = {
	["MNY"] = true,
	["SEQ"] = true,
}

local function fnc_hnd_mcr_action(obj_handler, mcr_src)
	local	key_str_bas = akey(1, 0) 
	if	key_str_bas == ""
	then -- somehow got it when debugger attached and "state" keys tested
		local	key_str_ass = akey(1, 1)
		if	key_str_ass:lower() == obj_handler.key_ext.KXP.rec
		then	key_str_bas = key_str_ass
		end
	end
	local obj_scr = far.SaveScreen()
	local key_stt_id, obj_key_stt, obj_hld_key
	local key_str_seq_new_pretty = key_str_bas:gsub("-", "Minus"):gsub("+", "Plus")
	local is_rgx = obj_handler.key_ext.KXP.reobj
	local obj_key_lev = {
		key_str_act	= key_str_bas,				
		key_str_bas	= key_str_bas,				
		key_str_bas_ext = key_str_bas,				
		key_str_seq	= key_str_seq_new_pretty,
		key_str_seq_rgx	= is_rgx and obj_handler.key_ext.KXP.str or key_str_seq_new_pretty,
		key_reg_exp_obj	= is_rgx and obj_handler.key_ext.KXP.reobj or nil,
		key_reg_exp_str	= is_rgx and obj_handler.key_ext.KXP.regex or nil,
		key_reg_exp_cnt	= is_rgx and 1 or nil,
		key_str_cas	= obj_handler.key_ext.KXP.cas,
		key_str_cas_rec = obj_handler.key_ext.KXP.rec_cas,
		key_ext		= obj_handler.key_ext,			
		key_rec		= fnc_NameToInputRecord(key_str_bas),	
		key_rec_act	= fnc_NameToInputRecord(key_str_bas),	
		key_exp		= { [obj_handler.key_ext.KXP.str] = obj_handler.key_ext.KXP },
		key_time	= Far.UpTime,				
	}
	local tbl_key_lev = { obj_key_lev, run_mode = "ask-normal" } -- init
	tbl_ext_key_lev_hist[#tbl_ext_key_lev_hist + 1] = tbl_key_lev
	obj_key_lev.mcr_all, 
	obj_key_lev.mcr_fin, 
	obj_key_lev.mcr_key_cur,
	obj_key_lev.hlp_str 
		= fnc_get_fin_scp(obj_key_lev.key_ext.SCP, obj_handler.prio_cond, tbl_key_lev, false)
	obj_status:set(obj_key_lev.key_str_seq.."-... ?", nil, 10000000)
	obj_waitkeys:init(obj_key_lev.key_str_bas)
	vkc_no_repeat = obj_key_lev.key_rec.VirtualKeyCode -- global var, prevent autorepeat
	repeat
		local key_str_new, t_wait_key = obj_waitkeys:save(50)
		if key_str_new ~= ""
		then
		end
		if (	key_str_new ==  "AltEsc"
		or	key_str_new == "RAltEsc" )
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
		local	str_ext, tbl_ext, tbl_ext_allowed = fnc_get_ext_chk(obj_key_lev, key_str_new, t_wait_key)
		-- prevent futile trying to determine sequences
		if not	str_ext
		and not	tbl_ext.NON
		and not	tbl_ext.PRE
		then
			if	#tbl_key_lev == 1
			then	-- just run normal
				tbl_key_lev.stop_cause	= "no-ext-one"
				tbl_key_lev.run_mode	= "run-normal"
			else	-- lost sequence
				tbl_key_lev.stop_cause	= "no-ext-seq"
				tbl_key_lev.run_mode	= "ask-normal"
			end
			break
		end --]]
		if	str_ext
		and not MULTI_KEY_EXT[str_ext]
		then
			key_str_bas = false 
			obj_key_lev.key_str_bas_ext	= obj_key_lev.key_str_bas..	tbl_ext_mode_disp[str_ext]
			obj_key_lev.key_str_seq 	= obj_key_lev.key_str_seq..	tbl_ext_mode_disp[str_ext]
			obj_key_lev.key_str_seq_rgx	= obj_key_lev.key_str_seq_rgx..	tbl_ext_mode_disp[str_ext]
			obj_key_lev.key_bas		= obj_key_lev.key_ext 
			obj_key_lev.key_ext		= obj_key_lev.key_ext[str_ext]
			obj_key_lev.ext_type		= str_ext
			if str_ext == "STT"
			then key_stt_id, obj_key_stt, obj_hld_key = fnc_key_state_add(
				key_str_new ~= "" and key_str_new or obj_key_lev.key_str_act, 
				key_stt_id, 
				true,	-- suppress repeated
				20,	-- tick's ms time, check released
				nil,	-- fnc_state_init,	not needed
				nil,	-- fnc_state_repeat,	not needed
				nil	-- fnc_state_final,	not needed
					)
			end
		elseif
			MULTI_KEY_EXT[str_ext]
		then
			local	plain_tried, same_cas_tried, is_many,
				key_obj_seq, key_str_seq, 
				key_obj_try, key_exp_try, key_str_try, 
				key_obj_new, key_exp_new
			local	key_rec_new = fnc_NameToInputRecord(key_str_new) -- real
			local	cas_mod_is_same =
					-- for keys like Ctrl, CtrlAlt, etc. we do not need same CAS state
					({next(obj_key_lev.key_exp)})[2].key == "" or
					band(key_rec_new	.ControlKeyState, MOD_MASK) ==
					band(obj_key_lev.key_rec.ControlKeyState, MOD_MASK)			
			if not	cas_mod_is_same
			and	BREAK_SEQ_ON_MOD_RELEASE
			then	tbl_key_lev.cas_mod_expect = band(obj_key_lev.key_rec	.ControlKeyState, MOD_MASK)
				tbl_key_lev.cas_mod_actual = band(key_rec_new		.ControlKeyState, MOD_MASK)
				tbl_key_lev.stop_cause	= "cas-mod-not-same"
				tbl_key_lev.run_mode	= "ask-normal"
				break
			end
			is_many = str_ext == "MNY"
			key_str_try = key_str_new
			key_exp_new, key_obj_new = fnc_key_expand(key_str_new, not is_many, true)
			::seq_key_try::
			key_exp_try, key_obj_try = fnc_key_expand(key_str_try, not is_many, true)
			key_str_seq, key_obj_seq = fnc_key_equal( key_exp_try, is_many and obj_key_lev.key_exp or obj_key_lev.key_ext.SEQ)
			if not	key_str_seq
			and not plain_tried
			--[[ --[=[TODO: to think about, probably we need flag "TRY PLAIN" here?
				also, probably use +(Plus) as unbreakable CAS mod ]=]
			and	cas_mod_is_same --]]
			-- KXP.key as "plain" key cant be used here, since it is NEW key
			and	key_obj_try.plain -- false in the kind of RCtrlAlt
			and	key_str_try:lower() ~= key_obj_try.plain:lower()
			then	key_str_try = key_obj_try.plain
				plain_tried = true
				goto seq_key_try
			end
			if not	key_str_seq	-- self explaining
			and not same_cas_tried	-- self explaining, isn't it?
			-- same as above musing, should we invent flag for "TRY NEXT SEQ WITH THE SAME AS PREV CAS" ?
			and	obj_key_lev.key_str_cas ~= ""		-- current key CAS need to be
			and (	plain_tried				-- means plain already tried unsuccessfully
			or	({next(key_exp_try)})[2].cas == "" )	-- .. or is a plain key anyway
		--	and	({next(key_exp_new)})[2].cas == "" --[[ do it only if the original new key without CAS,
			and (	band(key_rec_new.ControlKeyState, obj_key_lev.key_rec.ControlKeyState, MOD_MASK) > 0
			-- says CAS keys can be released, but not with new CAS keys pressed:
			and	band(key_rec_new	.ControlKeyState, MOD_MASK)
			<	band(obj_key_lev.key_rec.ControlKeyState, MOD_MASK)
			or	({next(key_exp_new)})[2].cas == "" )
			then	-- try with the same CAS mods as the previous key:
				key_str_try = fnc_key_prettify(obj_key_lev.key_str_cas_rec..key_str_try)
				same_cas_tried = true
				goto seq_key_try
			end
			::end_of_seq_determine::
			if	key_str_seq -- ? registered sequence or regexp(=MNY) key
			then
				str_ext		= is_many and "MNY" or "SEQ"
				key_str_bas	= key_str_try 
				vkc_no_repeat	= key_rec_new.VirtualKeyCode -- prevent autorepeat
				if not	obj_key_lev.ext_type
				and	str_ext == "MNY"
				then	obj_key_lev.ext_type = "MNY"
					obj_key_lev.key_str_seq_rgx = obj_key_lev.key_str_seq_rgx..":Many"
				end				
				local 	regex_many_cnt = is_many and ((obj_key_lev.key_reg_exp_cnt or 0) + 1) or nil
				local 	regex_many_str = is_many and ({next(obj_key_lev.key_exp)})[1] or nil
				local 	regex_many_obj = is_many and ({next(obj_key_lev.key_exp)})[2] or nil
				if	regex_many_obj
				then	regex_many_obj = regex_many_obj.reobj
				end
				local key_str_try_disp = regex_many_obj and key_str_try or fnc_key_prettify(key_str_try):gsub("-", "Minus"):gsub("+", "Plus")
				local key_str_seq_rgx = not is_many 
					and	obj_key_lev.key_str_seq_rgx.."-"..key_str_try_disp
					or	regex_many_cnt == 1 and obj_key_lev.key_reg_exp_str ~= regex_many_str
					and	obj_key_lev.key_str_seq_rgx.."-"..regex_many_str
					or	regex_many_cnt == 1 and obj_key_lev.key_reg_exp_str == regex_many_str
					and	obj_key_lev.key_str_seq_rgx
					or	regex_many_cnt > 1
					and	obj_key_lev.key_str_seq_rgx
					or	"?????????????????"
				obj_key_lev.next_type = str_ext
				obj_key_lev.next_key_str = key_str_try
				obj_key_lev.next_key_lev = {
					ext_type	= str_ext,
					key_str_act	= key_str_new,
					key_rec_act	= key_rec_new,
					key_str_bas	= key_str_bas,
					key_str_cas	= ({next(key_exp_try)})[2].cas,
					key_str_cas_rec	= ({next(key_exp_try)})[2].rec_cas,
					key_ext_pre	= obj_key_lev.key_ext,
					ext_type	= is_many and "MNY" or nil, -- SEQ/MNY
					key_exp		= is_many and obj_key_lev.key_exp or key_exp_try,
					key_ext		= is_many and obj_key_lev.key_ext or key_obj_seq,
					key_str_seq	= obj_key_lev.key_str_seq.."-"..key_str_try_disp,
					key_str_seq_rgx = key_str_seq_rgx,
					key_rec_pre	= obj_key_lev.key_rec,
					key_rec		= fnc_NameToInputRecord(key_str_try),
					key_time	= t_wait_key,
					key_reg_exp_cnt	= regex_many_cnt,
					key_reg_exp_obj	= regex_many_obj,
					key_reg_exp_str	= regex_many_str,
					prev_key_lev	= obj_key_lev,
				}
				obj_key_lev = obj_key_lev.next_key_lev
				tbl_key_lev[#tbl_key_lev + 1] = obj_key_lev
			else
				if	is_many
				and	tbl_ext.SEQ
				then
					is_many = false
					plain_tried = false
					same_cas_tried = false
					obj_key_lev.key_ext = obj_key_lev.key_ext.MNY
					goto seq_key_try
				else
					if	#tbl_key_lev == 1
					then -- run normal if single
						tbl_key_lev.stop_cause	= "no-ext-one"
						tbl_key_lev.run_mode	= "run-normal"
					else -- the sequence went wrong, ask what to do
						tbl_key_lev.stop_cause	= "wrong-seq"
						tbl_key_lev.run_mode	= "ask-normal"
					end
					break
				end			
			end
		end
		if	str_ext
		and	str_ext ~= "NON"
		then -- some keyboard event happened
			obj_key_lev.mcr_all,
			obj_key_lev.mcr_fin,
			obj_key_lev.mcr_key_cur,
			obj_key_lev.hlp_str
				= fnc_get_fin_scp(obj_key_lev.key_ext.SCP, obj_handler.prio_cond, tbl_key_lev, false)
			if #obj_key_lev.mcr_fin > 0 
			and obj_key_lev.ext_type ~= "MNY" -- meanwhile we want to chain MANY as long as it satisfies criteria
			then	tbl_key_lev.stop_cause	= "ext-seq-exists"
				tbl_key_lev.run_mode	= "ext-seq-run"
				break
			else	obj_status:set(obj_key_lev.key_str_seq.."-... ?", nil, 10000000)
			end
		elseif -- nothing happened (no SEQ/MNY/HLD/DBL/STT) so probably we should show help message
			(t_wait_key - obj_key_lev.key_time) > OPT_DELAY_HLP
		then	
			far_Message(obj_key_lev.hlp_str, obj_key_lev.key_str_seq.."-... ?", "", "l")
		end
		local	is_cas_mod_rls, cas_int_new = fnc_is_cas_mod_rls(obj_key_lev.key_rec_act)
		if	is_cas_mod_rls 
		and	BREAK_SEQ_ON_MOD_RELEASE -- CAS changed when should not
		and (	obj_key_lev.key_bas -- need to be a plain key to break on wrong CasModChg
		or	obj_key_lev.key_ext ).KXP.key ~= ""
		then	tbl_key_lev.is_cas_mod_rls = is_cas_mod_rls
			tbl_key_lev.cas_mod_int_rls = cas_int_new
			tbl_key_lev.stop_cause	= "cas-mod-rls"
			tbl_key_lev.run_mode	= "ask-normal"
			break
		end
	until false
	vkc_no_repeat = false
	tbl_key_lev.stop_time = Far.UpTime
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
				or tbl_key_lev.is_cas_mod_rls and str_format("[cas-mod-chg:] %s  ==>> %s",
					fnc_cas_int_to_str(obj_key_lev.key_rec.ControlKeyState, "<none>"), 
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
				nil, 
				2500
			)
			flg_ext_mod_off = true
			for ii = 1, #obj_waitkeys.keys
			do runMacroOrKey(obj_waitkeys.keys[ii])
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
		-- just take the first macro object:
		local scr_num, scr_obj = next(obj_key_lev.mcr_fin)
		if	obj_key_stt
		and	obj_key_stt.is_open
		then	obj_key_stt.fnc_state_init	= scr_obj.obj_macro.data.act_state_init
			obj_key_stt.fnc_state_repeat	= scr_obj.obj_macro.data.act_state_repeat
			obj_key_stt.fnc_state_final	= scr_obj.obj_macro.data.act_state_final
			obj_key_stt.eat_press_repeat	= scr_obj.obj_macro.data.eat_press_repeat
			obj_key_stt.tick_state_repeat	= scr_obj.obj_macro.data.tick_state_repeat
			obj_key_stt.key_run_normal_if_state_was_not_used
							= scr_obj.obj_macro.data.key_run_normal_if_state_was_not_used
			if	scr_obj.obj_macro.data.key_states
			then	scr_obj.obj_macro.data.key_states[key_stt_id] = obj_key_stt
			else	scr_obj.obj_macro.data.key_states = { [key_stt_id] = obj_key_stt }
			end
		end
		tbl_key_lev.exec_time = Far.UpTime
		tbl_key_lev.eval_res = eval(obj_key_lev.key_str_seq_rgx, 2)
		if	tbl_key_lev.eval_res== EVAL_MACRONOTFOUND
		then	tbl_key_lev.eval_res = EVAL_MACRONOTFOUND_X
			local obj_macro = obj_key_lev.mcr_fin[1].obj_macro
			obj_macro.action(obj_macro.data, --[[!reserved:]]nil, --[[!reserved:]]nil, tbl_key_lev, obj_waitkeys.keys)
			tbl_key_lev.eval_res = EVAL_SUCCESS_X
		end
		obj_status:set(str_format("%s Res %s/%s", obj_key_lev.key_str_seq_rgx, tbl_key_lev.eval_res, EVAL_RES[tbl_key_lev.eval_res]), nil, 3000)
	elseif
		tbl_key_lev.run_mode == "run-cancel"
	then
		obj_status:set(str_format("%s sequence cancelled", obj_key_lev.key_str_seq), nil, 3000)
	end
	tbl_key_lev.exit_time = Far.UpTime
end -- fnc_hnd_mcr_action

-- register hotkey's handler, here keys and areas should be already normalized to lower case
local function fnc_key_handler_set(key_area, obj_key_ext, obj_mcr)
	if not	tbl_macro_ex_handlers[key_area]
	then	tbl_macro_ex_handlers[key_area] = { }
	end
	local	m_key = obj_key_ext.KXP.str
	local	obj_handler = tbl_macro_ex_handlers[key_area][m_key]
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
		tbl_macro_ex_handlers[key_area][m_key] = obj_handler
	end
	fnc_tbl_copy_to(obj_key_ext, obj_handler.key_ext, fnc_copy_key_ext_tbl, fnc_copy_key_ext_val)
	if	key_area == "common"
	then	for ii_area_name, ii_area_handlers in pairs(tbl_macro_ex_handlers)
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
		local	exH_priority = 1
		local	tbl_conflict_areas = ii_area == "common" and utils_Areas or { [ii_area] = utils_Areas[ii_area] }
		for area_conflict_name, area_conflict_keys in pairs(tbl_conflict_areas)
		do	local	mcr_key_coll = area_conflict_keys[ii_area_key]
			if	mcr_key_coll and #mcr_key_coll > 0
			then 	for mcr_idx, mcr_obj in pairs(mcr_key_coll)
				do	if	mcr_obj.priority
					and	mcr_obj.priority <= exH_priority
					then	exH_priority = mcr_obj.priority - 1
					end
				end
			end
		end
		Macro { area		= ii_area,
			key		= fnc_key_prettify(ii_area_key)..(exH_priority < 0 and "__CONFLICT" or ""),
			ext_key_hnd	= ii_area_key_handler,
			description	= ii_area_key_handler.description,
			condition	= ii_area_key_handler.fnc_condition,
			action		= ii_area_key_handler.fnc_action,
			priority	= exH_priority,	-- extended keys must NOT override plain keys
			sortpriority	= 1,		-- extended keys must NOT override plain keys
			FileName	= own_fpath,
		}
	end end
end -- fnc_macro_ex_create

local fnc_split_key do
local EXPR_KEY_SEP_PLAIN = "([^-+]*)([-+]?)"
local EXPR_KEY_SEP_REGEX = "(/.+/:?%w*)([-+]?)"
local function fnc_split_key_simple(ii_key, to_be_continued, is_rgx, tbl_key_ii, ii_has_ext)
	for jj_key_seq, jj_key_sep in str_gmatch(ii_key, is_rgx and EXPR_KEY_SEP_REGEX or EXPR_KEY_SEP_PLAIN) 
	do	if jj_key_seq == ""
		then	if	#tbl_key_ii == 0
			then	--[[ this phenomena happened to me on "-",
				this is plain key, so just skip it]]
				break -- ii_has_ext remains nil here
			else	if not	to_be_continued
				then	--[[ this phenomena happens onto such plain keys,
					as "Alt-" for example, should be on finalizing key ]]
					tbl_key_ii[#tbl_key_ii].key = tbl_key_ii[#tbl_key_ii].key..tbl_key_ii[#tbl_key_ii].sep
					tbl_key_ii[#tbl_key_ii].sep = jj_key_sep
				end
				goto seq_keys_loop_end
			end
		end
		-- try to save load time:
		if not	ii_has_ext
		and (	#tbl_key_ii > 0
		or	str_find(jj_key_seq, "%S[:]%S") )
		then	ii_has_ext = true
		end
		tbl_key_ii[#tbl_key_ii + 1] = { key = is_rgx and jj_key_seq or str_lower(jj_key_seq), sep = jj_key_sep, rgx = is_rgx }
		::seq_keys_loop_end::
	end
	return ii_has_ext
end -- fnc_split_key_simple

fnc_split_key = function(ii_key, tbl_key_ii, ii_has_ext)
	local	first_simple, first_slash 
	if	str_match(ii_key, "^/.+/")
	then	first_simple, first_slash = "", ii_key
	else	first_simple, first_slash = str_gmatch(ii_key, "([^/]+)(/.-/.+)")()
	end
	if not  first_simple
	then	ii_has_ext = fnc_split_key_simple(ii_key, false, nil, tbl_key_ii, ii_has_ext)
	else	if	first_simple ~= ""
		then	ii_has_ext = fnc_split_key_simple(first_simple		, true, nil, tbl_key_ii, ii_has_ext)
		end
		for	jj_key_rgx_seq_sep, jj_key_plain_sep in str_gmatch(first_slash, "(/.-/:?%w*[-+]?)([^/]*)")
		do	ii_has_ext = fnc_split_key_simple(jj_key_rgx_seq_sep	, true, true,tbl_key_ii, ii_has_ext)
			ii_has_ext = fnc_split_key_simple(jj_key_plain_sep	, true, nil, tbl_key_ii, ii_has_ext)
		end
	end
	return ii_has_ext
end

end -- scope for fnc_split_key

local function fnc_macro_ex_check_one(obj_mcr, create_handlers)
	local tbl_handlers_loc = { }
	local mcr_id_ext = str_upper(win_uuid(win_uuid()))
	for ii, ii_key in pairs(fnc_str_split(obj_mcr.key, "%s", true))
	do	local ii_key_low = ii_key 
		local tbl_key_ii = { }
		local tbl_ext_ii = { }
		local tbl_ext_jj = tbl_ext_ii
		local	ii_has_ext = fnc_split_key(ii_key, tbl_key_ii, ii_has_ext)
		if not	ii_has_ext
		then	goto enum_full_keys_loop_end
		end
		local tbl_scr_key_ii = { [ii_key_low] = {
			key_full = ii_key_low,
			key_path = tbl_key_ii,
			scripts = { [mcr_id_ext] = obj_mcr }
		} }
		for jj, jj_key_seq in pairs(tbl_key_ii)
		do	local tbl_seq_stub_jj = { }
			local tbl_ext_stub_jj
			local	jj_key_base, jj_ext_mode = str_match(jj_key_seq.key, "^(.+):(.+)$")
			if not	jj_key_base
			then	jj_key_base = jj_key_seq.key
			end
			if	jj_key_seq.rgx
			then	jj_key_seq.rgx = regex.new(jj_key_base)
			else	jj_key_base = jj_key_base:lower():gsub("minus", "-"):gsub("plus", "+") -- normalize orig key string
			end
			jj_key_seq.bas = jj_key_base
			if	jj_ext_mode
			then	-- here ext_mode supposed to be HLD, DBL, STT, MNY
				jj_ext_mode = str_lower(jj_ext_mode)
				local	jj_ext_code = tbl_ext_mode_code[jj_ext_mode]
				if	jj_ext_code
				then	jj_key_seq.ext = jj_ext_code
					tbl_ext_stub_jj = { EXT = jj_ext_code, SCP = tbl_scr_key_ii, SEQ = ALLOW_SEQ_IN_EXT and tbl_seq_stub_jj }
				else	if opts.DbgShowBadExt
					then fnc_err_msg(str_format("wrong extension %s in sequence %s", jj_ext_mode, ii_key))
					end
					goto enum_full_keys_loop_end -- cancel sequences with an unacceptable extension
				end
			end
			jj_key_seq.exp = fnc_key_expand(jj_key_seq.bas, true, false, jj_key_seq.rgx) -- unified complex key in lower case
			for kk_str, kk_val in pairs(jj_key_seq.exp)
			do 	tbl_ext_jj[kk_str] = { EXT = jj_key_seq.ext and true, KXP = kk_val, SCP = tbl_scr_key_ii }
				if	jj_key_seq.ext
				then	tbl_ext_jj[kk_str][jj_key_seq.ext] = tbl_ext_stub_jj
				else	tbl_ext_jj[kk_str].SEQ = tbl_seq_stub_jj
				end
			end
			tbl_ext_jj = jj_key_seq.ext and ALLOW_SEQ_IN_EXT and tbl_ext_stub_jj.SEQ or tbl_seq_stub_jj
		end -- end of the sequence keys processing loop
		if not	tbl_ext_seq_key_reg[ii_key_low]
		then	tbl_ext_seq_key_reg[ii_key_low] = { key_path = tbl_key_ii, scripts = { [mcr_id_ext] = obj_mcr } }
		else	tbl_ext_seq_key_reg[ii_key_low].scripts[mcr_id_ext] = obj_mcr
		end
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
		obj_mcr.data.key_seq_all[ii_key_low] = tbl_key_ii -- should be only once
		for mm_ext_key, mm_ext_obj in pairs(tbl_ext_ii)
		do	local areas_work =
				tbl_macro_ex_handlers.common and tbl_macro_ex_handlers.common[mm_ext_key] and { "common" }
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

local tbl_mcr_exc_run = { }
local tbl_mcr_exc_ask = { }
Xer0X.mcr_scr_excepts = tbl_mcr_exc_run
Xer0X.mcr_scr_exc_dlg = tbl_mcr_exc_ask
local FMT_FNC_ID = "%s:%s-%s"
local FUNC_META_INFO = "Sl"

local function fnc_make_wrap(fnc_orig, str_mark, str_dscr, str_file)
	local tbl_dbginf = dbg_getinf(fnc_orig, FUNC_META_INFO)
	local id_func = str_fmt_s(FMT_FNC_ID, tbl_dbginf.source, tbl_dbginf.linedefined, tbl_dbginf.lastlinedefined)

	return function(...)
		local p1, p2, p3, p4, p5 = ...
		local p1_type = type(p1)
		local p2_type = type(p2)
		local inp_val =
			p1_type ~= "nil" and p1_type ~= "table" and p1 or
			p2_type ~= "nil" and p2_type ~= "table" and p2 or
			p1_type ~= "nil" and p1_type or
			p2_type ~= "nil" and p2_type or
			p1_type
		local	is_exc = tbl_mcr_exc_run[id_func]
		local	is_ask = tbl_mcr_exc_ask[id_func]
		if	is_exc
		and	is_ask
		then	-- in ask dialog, do not run
		elseif	is_exc
		and not is_ask
		then	-- here we should ask what to do
			tbl_mcr_exc_ask[id_func] = true
			tbl_mcr_exc_ask[id_func] = false
		else 
			tbl_mcr_exc_run[id_func] = true
			local tbl_ret_val = { fnc_orig(...) }
			tbl_mcr_exc_run[id_func] = false
			return unpack(tbl_ret_val)
		end
	end
end

local function fnc_macro_ex_build_all()
	local t1 = Far.UpTime
	for ii = 1, #LoadedMacros 
	do	local	ii_mcr = LoadedMacros[ii] 
		if	ii_mcr.key
		and not ii_mcr.keyregex
		and	str_find(ii_mcr.key, "%S[:%-%+]%S") -- %S(s) - any (non-)whitespace character
		then	fnc_macro_ex_check_one(ii_mcr)
		end
		local	ii_mcr_dat = ii_mcr.data and ii_mcr.data or ii_mcr
		if (	Xer0X.DBG_WRAP_MACRO and ii_mcr_dat.area
		or	Xer0X.DBG_WRAP_EVENT and ii_mcr_dat.group )
		and	ii_mcr.FileName ~= FileName
		and not	ii_mcr_dat.DBG_WRAP
		then
			local mcr_file = ii_mcr.FileName and fnc_extr_file_name(ii_mcr.FileName) or "<UNKNOWN>"
			local mcr_dscr = ii_mcr.description or "<NO-DESCR>"
			local mcr_cond = ii_mcr.condition
			local mcr_acts = ii_mcr.action
			if type(mcr_cond) == "function" then ii_mcr.condition	= fnc_make_wrap(mcr_cond, "COND.", mcr_dscr or "?", mcr_file) end
			if type(mcr_acts) == "function" then ii_mcr.action	= fnc_make_wrap(mcr_acts, "ACTS.", mcr_dscr or "?", mcr_file) end
			ii_mcr_dat.DBG_WRAP = true
		end
	end
	fnc_macro_ex_create(tbl_macro_ex_handlers)
	if opts.DbgShowLoadTime
	then far_Message(Far.UpTime - t1, "extended keys load time")
	end
	if not	Xer0X.fnc_macro_ex_build_all
	then	Xer0X.fnc_macro_ex_build_all = fnc_macro_ex_build_all
	end
	return tbl_macro_ex_handlers
end -- fnc_macro_ex_build_all

Macro {	description = "Save all keys for the further analysis",
	area = "Common", 
	key = "/.+/", 
	condition = function(inp_key)
		if Area.Menu and Menu.Id == "7646F761-8954-42CA-9CFC-E3F98A1C54D3"
		or not inp_key
		then return -- not in LuaExplorer
		end
		tbl_key_mcr_journal[#tbl_key_mcr_journal + 1] = { inp_key = inp_key, area = Area.Current, key_rec = fnc_NameToInputRecord(inp_key), key_time = Far.UpTime }
		if #tbl_key_mcr_journal > 1000
		then tbl_remove(tbl_key_mcr_journal, 1)
		end
	end,
	action = function() end
}

Event { group = "ExitFAR",
	description = "Save MacroEx data and statistics on FAR exit",
	action = function() fnc_sett_data_store() end
}

if	as_mdl
then
else
--[=[ need to be the last call,
so that all other macros loaded already: ]=]
mf_postmacro(fnc_macro_ex_build_all)
end

-- @@@@@
