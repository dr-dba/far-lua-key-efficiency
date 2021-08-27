--[[
if 1 then return end --]]

--[[
DEPENDS ON MODULES:

https://github.com/dr-dba/far-lua-general-utils
Lib-Common-@Xer0X.Lua

GitHub repository:
https://github.com/dr-dba/far-lua-key-efficiency/
x-cursor.@Xer0X.lua
]]


local Xer0X = require("Lib-Common-@Xer0X")

local str_lower = utf8.Utf8_lower	or utf8.lower
local str_low	= str_lower
local str_upper = utf8.Utf8_upper	or utf8.upper
local str_gmatch= utf8.Utf8_gmatch	or utf8.gmatch
local str_match = utf8.Utf8_match	or utf8.match
local str_find	= utf8.Utf8_find	or utf8.find
local str_gsub	= utf8.Utf8_gsub	or utf8.gsub
local str_len	= utf8.Utf8_len		or utf8.len
local str_rev	= utf8.reverse		or utf8.reverse
local str_sub	= utf8.sub
local str_cfind	= utf8.cfind
local str_format= utf8.format
local str_fmt_s = string.format
local math_max	= math.max
local math_min	= math.min
local tbl_concat= table.concat
local tbl_insert= table.insert
local tostr	= tostring
local panel_GetCmdLineSelection = panel.GetCmdLineSelection
local panel_SetCmdLineSelection = panel.SetCmdLineSelection
local panel_GetCmdLinePos	= panel.GetCmdLinePos
local panel_SetCmdLinePos	= panel.SetCmdLinePos
local panel_GetCmdLine		= panel.GetCmdLine
local mf_postmacro		= mf.postmacro

local fnc_NameToInputRecord =	Xer0X.fnc_NameToInputRecord
local obj_status	=	Xer0X.obj_screen_status_line
local fnc_cfind_safe	=	Xer0X.fnc_cfind_safe
local cmd_str_cur, cmd_str_rev, cmd_str_len

local function fnc_cursor_move_intern(flg_sel, stop_expr, to_stop_end, stop_shift, cmd_str, pos_cur, has_sel, sel_beg, sel_end)
	local pos_new, has_sel_new, sel_beg_new, sel_end_new, find_res, find_msg, found_pos, found_end, found_str
	if type(stop_expr) == "number"
	then	pos_new = math_min(pos_cur + stop_expr, cmd_str_len)
	else	find_res, find_msg, found_pos, found_end, found_str = fnc_cfind_safe(cmd_str, stop_expr, pos_cur + 1)
		pos_new = find_res and found_pos and (to_stop_end and found_end or found_pos) or cmd_str_len
	end
	if 	pos_new ~= pos_cur
	then	if	flg_sel
		then
			if	has_sel
			then	if	sel_beg >= pos_cur
				and	sel_end >= pos_new
				then	sel_beg_new = pos_new + 1
					sel_end_new = sel_end
				elseif	sel_beg <= pos_cur
				and	sel_end >= pos_new
				then	sel_beg_new = pos_new
					sel_end_new = sel_end
				elseif	sel_beg <= pos_cur
				and	sel_end >= pos_cur
				then	sel_beg_new = sel_beg
					sel_end_new = pos_new
				elseif	sel_beg >= pos_cur
				and	sel_end <= pos_new
				then	sel_beg_new = pos_new
					sel_end_new = sel_end
				elseif	sel_beg <= pos_cur
				and	sel_end <= pos_new
				then	sel_beg_new = sel_beg
					sel_end_new = pos_new
				end
			else
				sel_beg_new = pos_cur
				sel_end_new = pos_new
			end
			if	sel_beg_new ==	0 -- edge case when stands at the end and move left
			and	sel_end_new >	0
			then	sel_beg_new = 	1
			end
		end
	end
	return pos_new + (stop_shift or 0), has_sel_new, sel_beg_new, sel_end_new
end

local function fnc_cursor_move(is_back, flg_sel, stop_expr, to_stop_end, stop_shift)
	local	cmd_str_new = CmdLine.Value
	if	cmd_str_new ~=cmd_str_cur
	then	cmd_str_cur = cmd_str_new
		cmd_str_rev = str_rev(cmd_str_new)
		cmd_str_len = str_len(cmd_str_new)
	end
	local	pos_cur = panel_GetCmdLinePos()
	local	has_sel = CmdLine.Selected
	local	sel_beg, sel_end
	if	has_sel
	then	sel_beg, sel_end = panel_GetCmdLineSelection()
	end
	if	has_sel
	and	sel_end == 0
	then	sel_end = cmd_str_len
	end
	local	pos_new, has_sel_new, sel_beg_new, sel_end_new
			= fnc_cursor_move_intern(flg_sel, stop_expr, to_stop_end, stop_shift,
				is_back and (cmd_str_rev)		or cmd_str_new,
				is_back and (cmd_str_len - pos_cur + 1)	or pos_cur,
				has_sel,
				has_sel and (is_back and (cmd_str_len - sel_end + 1) or sel_beg),
				has_sel and (is_back and (cmd_str_len - sel_beg + 1) or sel_end)
			)
	if	is_back
	then	pos_new	= math_max(cmd_str_len - pos_new, 1)
		sel_beg_new,
		sel_end_new =
			sel_end_new and (cmd_str_len - sel_end_new + 1),
			sel_beg_new and (cmd_str_len - sel_beg_new + 1)
		if	sel_beg_new == 0
		then	sel_beg_new = 1
		end
	end
	if	pos_new ~= pos_cur
	then	panel_SetCmdLinePos(nil, pos_new)
		if	sel_beg_new and sel_beg_new ~= sel_beg
		or	sel_end_new and sel_end_new ~= sel_end
		then	panel_SetCmdLineSelection(nil, sel_beg_new, sel_end_new)
		end
	end
end -- fnc_cursor_move

local FAST_WORD_JUMP_MODE
local function fnc_fast_word_mode_cond() return FAST_WORD_JUMP_MODE end

Macro { description = "cmd line: FAST WORD JUMP MODE state",
	area = "Shell",
	key = "w:state",
	action = function(mcr_dat,
			p2, p3, p4, p5, -- reserved for the future far-system use
			obj_key_stt, dt_now
				)
		obj_status:set("FAST WORD JUMP MODE ACTIVATED", nil, 100000000)
		FAST_WORD_JUMP_MODE = true
	end, 
	eat_press_repeat = true,
	tick_state_repeat = 1000,
	act_state_repeat = function(obj_key_stt, dt_now)
		obj_status:set("FAST WORD JUMP MODE IS ACTIVE", nil, 100000000)
	end,
	act_state_final = function(obj_key_stt, dt_now)
		obj_status:set("FAST WORD JUMP MODE OFF", nil, 1000)
		FAST_WORD_JUMP_MODE = false
	end, 
	key_state_active_prevents_new = true,
	key_run_normal_if_state_was_not_used = true,
}

Macro {	description = "cmd line goto: to the begin",
	area = "Shell",
	key = "Home",
	flags = "NotEmptyCommandLine",
	action = function()
		panel_SetCmdLineSelection(nil, -1, -1)
		panel_SetCmdLinePos(nil, 1)
	end
}
Macro {	description = "cmd line goto: to the end",
	area = "Shell",
	key = "End",
	flags = "NotEmptyCommandLine",
	action = function()
		panel_SetCmdLineSelection(nil, -1, -1)
		panel_SetCmdLinePos(nil, panel.GetCmdLine():len() + 1)
	end
}
Macro {	description = "cmd line goto: to the begin with sel",
	area = "Shell",
	key = "ShiftHome",
	flags = "NotEmptyCommandLine",
	action = function()
		panel.SetCmdLineSelection(nil, 1, panel.GetCmdLinePos() - 1)
		panel.SetCmdLinePos(nil, 1)
	end
}
Macro {	description = "cmd line goto: to the end with sel",
	area = "Shell",
	key = "ShiftEnd",
	flags = "NotEmptyCommandLine",
	action = function()
		panel.SetCmdLineSelection(nil, panel.GetCmdLinePos(), panel.GetCmdLine():len())
		panel.SetCmdLinePos(nil, 1)
	end
}
Macro {	description = "cmd line goto: jump word left, no sel",
	area = "Shell",
	key = "CtrlLeft",
	flags = "NotEmptyCommandLine",
	condition = fnc_fast_word_mode_cond,
	action = function() fnc_cursor_move(true, false, "%s+", true, -1) end
}
Macro {	description = "cmd line goto: char left, with sel",
	area = "Shell",
	key = "ShiftLeft",
	flags = "NotEmptyCommandLine",
	action = function() fnc_cursor_move(true, true, 1, true, 0) end
}
Macro {	description = "cmd line goto: jump word left, with sel",
	area = "Shell",
	key = "CtrlShiftLeft",
	flags = "NotEmptyCommandLine",
	condition = fnc_fast_word_mode_cond,
	action = function() fnc_cursor_move(true, true, "%s+", true, -1) end
}
Macro {	description = "cmd line goto: jump word right, no sel",
	area = "Shell",
	key = "CtrlRight",
	flags = "NotEmptyCommandLine",
	condition = fnc_fast_word_mode_cond,
	action = function() fnc_cursor_move(false, false, "%s+", true, 1) end
}
Macro {	description = "cmd line goto: char right, with sel",
	area = "Shell",
	key = "ShiftRight",
	flags = "NotEmptyCommandLine",
	action = function() fnc_cursor_move(false, true, 1, true, 0) end
}
Macro {	description = "cmd line goto: jump word right, with sel",
	area = "Shell",
	key = "CtrlShiftRight",
	flags = "NotEmptyCommandLine",
	condition = fnc_fast_word_mode_cond,
	action = function() fnc_cursor_move(false, true, "%s+", true, 1) end
}


-- @@@@@
