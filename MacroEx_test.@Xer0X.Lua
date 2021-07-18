--[[
if true then return end --]]

--[[
PARTIALLY (PROBABLY?) DEPENDS ON:
xKeys — скрипт для замены одноимённого плагина
https://forum.farmanager.com/viewtopic.php?t=8481#p116428
]]
local Info = Info or package.loaded.regscript or function(...) return ... end -- luacheck: ignore 113/Info
local nfo = Info {
	_filename or ...,
	name		= "MacroEx test",
	description	= "Sample macros to test MacroEx",
	id		= "931E8931-11D0-4FD9-B493-657898578F1B",
	parent_id	= "115C9534-8273-4F5A-94EB-E321D6DC8618",
	version		= "3", 
	version_mod	= "0.7.7",
	author		= "JD",
	author_mod	= "Xer0X",
	url		= "http://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "https://forum.farmanager.com/viewtopic.php?f=15&t=12459",
	url_git		= "https://github.com/dr-dba/far-lua-key-efficiency",
--	disabled	= true;
}

if not nfo then return end


Macro { description = "test 123",
	id = win.Uuid(win.Uuid()),
	area = "Editor",
--	key = "LCtrlF9 RCtrlF9",
--	key = "CtrlF9",
--	key = "LCtrlF9",
--	key = "RCtrlF9",
	priority = 100,
	condition = function(key_rec_str, mcr_data)
		mcr_data.a_cnt = (mcr_data.a_cnt or 0) + 1
		return true
	end,
	action = function() far.Message("plain macro", akey(1, 0).." / "..akey(1, 1)) end
}

Macro { description = "test ABC",
	id = win.Uuid(win.Uuid()),
	area = "Editor",
--	key = "LCtrlF9 RCtrlF9",
--	key = "CtrlF9",
--	key = "LCtrlF9",
--	key = "RCtrlF9",
--	priority = 100,
	condition = function(key_rec_str, mcr_data)
		mcr_data.a_cnt = (mcr_data.a_cnt or 0) + 1
		return true
	end,
	action = function() far.Message("plain macro", akey(1, 0).." / "..akey(1, 1)) end
}

for ii, ii_key in ipairs({
--	"LCtrl--x",			-- LCtrl-,then X
	"LCtrlMinus-X",			-- LCtrl-,then X
--	"LCtrl---",			-- LCtrl-,then -
	"LCtrlMinus-Minus",		-- LCtrl-,then -
--	"LCtrl--",			-- LCtrl, then -
	"LCtrl-Minus",			-- LCtrl, then -
	"RCtrl-Minus-F2",		-- RCtrl, then -, then F2
--	"RCtrl----F1",			-- RCtrl-,then -, then F1
	"RCtrlMinus-Minus-F1",		-- RCtrl-,then -, then F1
	"RCtrlMinus-Minus-Minus-Minus", -- RCtrl-,then -, then -, then -
	"RCtrl-minus-minus-minus",	-- RCtrl, then -, then -, then -
	"RCtrlQ-RCtrlA-RCtrl-",		-- here final "-" is treated the conventional way
	"RCtrlQ-CtrlA-Ctrl- RCtrlQ-CtrlA-LCtrl- RCtrlQ-CtrlA-RCtrl- CtrlAltA",
	"ShiftF8-F8",
	"CtrlF8-F9",
	"CtrlF9-1-2-3-4-5",
	"CtrlK-J",
	"RAltF1:Hold",
	"CtrlAltF1:Hold",
	"CtrlAltF2:Hold",
	"RCtrlRAltF2:Hold",
	"LCtrlLAltF2:Hold",
	"ShiftF1:Hold",
	"^:Hold",
	"::Double",
	-- error
--	"qwerty-0",
--	"CtrlAltS:Hold",
--	"CtrlAltS:Double",
	"CtrlAltX-Y-Z",
	"RCtrlRAltS:Double",
	"LCtrlLAltS-RCtrlRAltO-CtrlAltX",
	"LCtrlAlt-RCtrlAlt",
	"CtrlAlt-CtrlAlt",
	"CtrlRAlt-LCtrlRAlt-F8",
	"CtrlLAlt:Hold",
	"CtrlAlt:Hold",
	"CtrlRAlt:Hold-F3-F2-F1",
	"RCtrlRAlt:Double",
	"CtrlAlt:Double",
	"RCtrlAlt-Alt",
	"CtrlAlt-Alt",
	"LCtrlRAlt-Alt",
	"LCtrlRAlt-F7-F6-F5",
	"CtrlAlt-F3-F3-F3 LCtrlLAlt:Double-F4-F4-F4-F4",
	"X-Y-Z", 
	"X:Double-Y-Z", 
	"X:Hold-Y-Z", 
	"CtrlS:Double-F3-F2-F1",
	"CtrlS:Hold-F3-F2:Double-F1",
	"CtrlS:Hold-F3-F2:Hold-F1",
	"CtrlS-F1-F2-F3:Hold",
	"CtrlF8-Alt"
})
do	Macro { description = "Example MacroEx: "..ii_key.." (Editor+Shell)",
		id = win.Uuid(win.Uuid()),
		area = "Editor Shell",
		disabled = true,
		key = ii_key,
		sortpriority = ii % 5;
	--	condition = function(the_key, mcr_dat) return false end, -- dynamic conditioning test
		action = function() far.Message(ii_key, string.format("%s / %s / %s", mf.akey(1, 0), mf.akey(1, 1), AKey)) end
	}
end

local test_mcr_key = "CtrlAltF9"
for ii, ii_key in ipairs({
	test_mcr_key..":Double",
	test_mcr_key..":Hold",
	test_mcr_key.."-"..test_mcr_key
		})
do	Macro {	description = ii_key.." (Common+Editor) MacroEx example",
		id	= win.Uuid(win.Uuid()),
		area	= "Common Editor",
		key	= ii_key,
		priority= 100,
--		condition = function(the_key, mcr_dat) return false end, -- dynamic conditioning test
		action	= function(mcr_src)
			far.Message(
				"You pressed "..(AKey or string.format("%s / %s", mf.akey(1, 0), mf.akey(1, 1))),
				mcr_src.description
					)
		end
	}
end

Macro {	description = "CtrlF9-AltF9 (Viewer+Editor+Common) MacroEx example",
	id = win.Uuid(win.Uuid()),
	area = "Viewer Editor Common",
--	key = "CtrlF9-AltF9",
	priority = 100,
--	condition = function(the_key, mcr_dat) return false end, -- dynamic conditioning test
	action = function(mcr_src) far.Message("You pressed "..(AKey or string.format("%s / %s", mf.akey(1, 0), mf.akey(1, 1))), mcr_src.description.." ("..Area.Current..")") end
}

-- @@@@@
