--[[
if 1 then return end --]]
local Info = Info or package.loaded.regscript or function(...) return ... end
local nfo = Info {
	_filename or ...,
	name = "Key (two) Proxy",
	description = "Обработка последовательности двух клавиатурных комбинаций",
	id = "8757843E-865B-43E8-9887-94F8FF6C942C",
	version	= "0.9.2";
	version_mod = "0.1.0",
	author = "IgorZ",
	author_mod = "Xer0X",
	minfarversion = { 3, 0, 0, 4000, 0 },
	url = "https://forum.farmanager.com/viewtopic.php?f=15&t=9712",
	url_mod = "https://github.com/dr-dba/far-lua-key-efficiency",
	options = {
		excludekeys = "",
		debug = true
	}
}
if not nfo then return end
local opts = nfo.options
if not	Xer0X then Xer0X = { } end
local GUID_MENU_MACRO_SELECT	= "165AA6E3-C89B-4F82-A0C5-C309243FD21B"
local rx = regex.new("(.*)(?<=LCtrl|.LAlt|RCtrl|.RAlt|.Ctrl|..Alt|Shift)(?!LCtrl|LAlt|RCtrl|RAlt|Ctrl|Alt|Shift)")
local F = far.Flags
local ACTL_GETWINDOWINFO= F.ACTL_GETWINDOWINFO
local DM_LISTGETTITLES	= F.DM_LISTGETTITLES
local DM_LISTSETTITLES	= F.DM_LISTSETTITLES
local DM_LISTGETCURPOS	= F.DM_LISTGETCURPOS
local DM_LISTSETCURPOS	= F.DM_LISTSETCURPOS
local DM_LISTUPDATE	= F.DM_LISTUPDATE
local DM_GETDIALOGINFO	= F.DM_GETDIALOGINFO
local DN_CLOSE		= F.DN_CLOSE
local DE_DLGPROCINIT	= F.DE_DLGPROCINIT
local DE_DLGPROCEND	= F.DE_DLGPROCEND
F = nil --[[ "F." looks ugly and cumbersome,
to save nothing about performance overhead,
so we are not to use it ]]
require("Lib-Common-@Xer0X")
require("introspection-@Xer0X")
local fnc_find_macrolist	= Xer0X.fnc_find_macrolist
local fnc_str_trim1		= Xer0X.fnc_str_trim1
local fnc_norm_menu_value	= Xer0X.fnc_norm_menu_value
local fnc_norm_guid		= Xer0X.fnc_norm_guid
local tbl_mcr_lst_upv, tbl_mcr_lst_loc, idx_mcr_items_L, tbl_mcr_items_L, tbl_ext_keys, tbl_menu_items

local function fnc_macro_choose_helper(inp_key, win_info, dlg_info, hDlg)
	local inp_key_low = inp_key and string.lower(inp_key)
	if not Area.Menu then return end
	local max_ext_key_len = 0
	local sep_cnt, fmt_str, mcrLst_found, tbl_menu_sel_1, tbl_menu_sel_2, menu_vals_map
	if not	hDlg
	then	dlg_info = far.AdvControl(ACTL_GETWINDOWINFO)
		hDlg = dlg_info.Id;
	end
	local dlg_hnd_str = tostring(hDlg)
	local dlg_handle = Xer0X.dlg_handles and Xer0X.dlg_handles[dlg_hnd_str]
	local dlg_xuid = dlg_handle and dlg_handle.xuid
	local dlg_data = dlg_xuid and Xer0X.dlg_data[dlg_xuid]	
	mcrLst_found,
	tbl_mcr_lst_upv,
	tbl_mcr_lst_loc,
	tbl_mcr_items_L
		= fnc_find_macrolist()
	if not	tbl_mcr_lst_loc then return end
	if	tbl_mcr_items_L.MLT_MCR_SEL_HLP
	then	goto done_with_it
	else	tbl_mcr_items_L.MLT_MCR_SEL_HLP = true
	end
	menu_vals_map = { new_to_val = { } }
	if	dlg_data
	then	dlg_data.menu_vals_map = menu_vals_map
	end
	tbl_ext_keys = { }
	tbl_menu_items = { }
	sep_cnt = 0
	for ii = 1, Object.ItemCount
	do	local	ii_val = Menu.GetValue(ii)
		local	ii_flg = Menu.ItemStatus(ii)
		local	ii_id2
		local	ii_txt
		local	ii_idn
		local	ii_kxt
		local	ii_k2t
		local	ii_dsc
		local	ii_hot
		local	ii_sep = band(ii_flg, 0x00000004) > 0
		if	ii_sep
		then	sep_cnt = sep_cnt + 1
		else	ii_id2,
			ii_txt = string.match(ii_val, "(%d+)%. (.*)$")
			ii_idn = tonumber(ii_id2)
			ii_dsc = tbl_mcr_lst_loc[ii].macro.description
			ii_hot = ii_dsc and string.match(ii_dsc, "&(.)")
			ii_kxt = tbl_mcr_lst_loc[ii].macro.data.key2 or ""
			if	ii_kxt ~= ""
			then	ii_kxt = fnc_str_trim1(ii_kxt)
				if	max_ext_key_len < string.len(ii_kxt)
				then	max_ext_key_len = string.len(ii_kxt)
				end
				ii_k2t = {}
				for ii_k in string.gmatch(string.lower(ii_kxt), "%S+")
				do	ii_k2t[#ii_k2t + 1] = ii_k
					tbl_ext_keys[ii_k] = ii_idn
				end
			end
		end
		tbl_menu_items[ii] = {
			idx = ii,
			id2 = ii_id2,
			idn = ii_idn,
			val = ii_val,
			txt = ii_txt,
			dsc = ii_dsc,
			hot = ii_hot,
			flg = ii_flg,
			kxt = ii_kxt,
			sep = ii_sep
		}
	end
	if max_ext_key_len == 0 then return end
	max_ext_key_len = math.min(max_ext_key_len, 15)
	fmt_str = "%"..string.len(tostring(#tbl_menu_items)).."s.%-"..tostring(max_ext_key_len).."s|%s"
	sep_cnt = 0
	tbl_menu_sel_1 = hDlg:send("DM_LISTGETCURPOS", 1)
	for ii = 1, #tbl_menu_items
	do	local	ii_p = tbl_menu_items[ii]
		if	ii_p.sep
		then	sep_cnt = sep_cnt + 1
		else	ii_p.str = string.format(fmt_str, (ii_p.hot and "" or "&")..ii_p.id2, string.sub(ii_p.kxt, 1, 15), ii_p.dsc)
			menu_vals_map.new_to_val[fnc_norm_menu_value(ii_p.str)] = ii_p.val
			hDlg:send(DM_LISTUPDATE, 1, { Index = ii, Text = ii_p.str })
		end
	end
	tbl_menu_sel_2 = hDlg:send("DM_LISTGETCURPOS", 1)
	if	tbl_menu_sel_1.SelectPos ~=
		tbl_menu_sel_2.SelectPos
	then    hDlg:send("DM_LISTSETCURPOS", 1, tbl_menu_sel_1)
	end
	::done_with_it::
	return inp_key and tbl_ext_keys[inp_key_low], win_info, dlg_info, hDlg
end

Macro { description = "Обработка вторичной клавиатурной комбинации в меню выбора макроса",
	area = "Menu", key = "/.+/",
	priority = 100,	
	condition = function(inp_key, tbl_mcr)
		if	Menu.Id == GUID_MENU_MACRO_SELECT and not (" "..nfo.options.excludekeys.." "):cfind(" "..inp_key.." ", 1, true)
		then	local run_inf = { }
			run_inf.mcr_idx, run_inf.win_inf, run_inf.dlg_inf, run_inf.dlg_hnd = fnc_macro_choose_helper(inp_key)
			if	run_inf.mcr_idx
			and	run_inf.mcr_idx > 0
			then	tbl_mcr.run_inf = run_inf
				return true
			end
		end
	end,
	action = function(tbl_mcr)
		local	menu_pos = tbl_mcr.run_inf.dlg_hnd:send(DM_LISTSETCURPOS, 1, { SelectPos = tbl_mcr.run_inf.mcr_idx } )
		if	menu_pos > 0
		then	Keys("Enter")
		end
	end
}

Event { description = "Key2proxy helper dialog event";
	group = "DialogEvent";
	priority = 100;
	condition = function(evt, fde)
		if	evt	== DE_DLGPROCINIT
		and	fde.Msg == DN_CLOSE
		then	return false
		end
		local	dlg_info = far.SendDlgMessage(fde.hDlg, DM_GETDIALOGINFO)
		if not	dlg_info then return end
		local	dlg_guid = fnc_norm_guid(dlg_info.Id) or fnc_norm_guid(Menu.Id)
		return	dlg_guid == GUID_MENU_MACRO_SELECT
	end;
	action = function(evt, fde)
		local dlg_info = far.SendDlgMessage(fde.hDlg, DM_GETDIALOGINFO)
		fnc_macro_choose_helper(nil, dlg_info, fde.hDlg)
	end;
}

-- @@@@@
