--[[
if true then return end --]]

--[[
PARTIALLY (PROBABLY?) DEPENDS ON:
XKeys — скрипт для замены одноимённого плагина
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
	version_mod	= "0.6.12",
	author		= "JD",
	author_mod	= "Xer0X",
	url		= "http://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "https://forum.farmanager.com/viewtopic.php?f=15&t=12459",
	url_git		= "https://github.com/dr-dba/far-lua-key-efficiency",
--	disabled	= true;
}

if not nfo then return end

Macro { description = "test",
	id = win.Uuid(win.Uuid()),
	area = "Editor",
	key = "LCtrlF9 RCtrlF9",
--	priority = 100,
	action = function() far.Message("plain macro", akey(1, 0).." / "..akey(1, 1)) end
}

for ii, ii_key in ipairs({
--	"LCtrl--x",			-- LCtrl-,then X
	"LCtrlMinus-X",			-- LCtrl-,then X
--	"LCtrl---",			-- LCtrl-,then -
	"LCtrlMinus-Minus",		-- LCtrl-,then -
--	"LCtrl--",			-- LCtrl, then -
	"LCtrl-Minus",			-- LCtrl, then -
--	"RCtrl---F2",			-- RCtrl, then -, then F2
	"RCtrl-Minus-F2",		-- RCtrl, then -, then F2
--	"RCtrl----F1",			-- RCtrl-,then -, then F1
	"RCtrlMinus-Minus-F1",		-- RCtrl-,then -, then F1
	"RCtrlMinus-Minus-Minus-Minus", -- RCtrl-,then -, then -, then -
	"RCtrl-minus-minus-minus",	-- RCtrl, then -, then -, then -
	"RCtrlQ-RCtrlA-RCtrl-",		-- here final "-" is treated the conventional way
	"ShiftF8-F8",
	"CtrlF8-F9",
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
	"CtrlAltS:Hold",
	"CtrlAltS:Double",
	"RCtrlRAltS:Double",
	"LCtrlLAltS-RCtrlRAltO-CtrlAltX",
	"LCtrlAlt-RCtrlAlt",
	"CtrlRAlt-LCtrlRAlt-F8",
	"CtrlLAlt:Hold",
	"CtrlRAlt:Hold-F3-F2-F1",
	"RCtrlRAlt:Double",
	"RCtrlAlt-Alt",
	"LCtrlRAlt-Alt",
	"LCtrlRAlt-F7-F6-F5",
	"LCtrlLAlt-F3-F3-F3 LCtrlLAlt:Double-F4-F4-F4-F4",
	"X-Y-Z",
	"CtrlS:Double-F3-F2-F1",
	"CtrlS:Hold-F3-F2:Double-F1",
	"CtrlS:Hold-F3-F2:Hold-F1",
	"CtrlF8-Alt"
})
do	Macro { description = "Example MacroEx: "..ii_key,
		id = win.Uuid(win.Uuid()),
		area = "Editor Shell",
		key = ii_key,
		action = function() far.Message(ii_key, string.format("%s / %s / %s", mf.akey(1, 0), mf.akey(1, 1), AKey)) end
	}
end

local test_mcr_key = "CtrlF9"
for ii, ii_key in ipairs({
	test_mcr_key..":Double",
	test_mcr_key..":Hold",
	test_mcr_key.."-"..test_mcr_key
		})
do	Macro {	description = ii_key.." (Common) MacroEx example",
		id	= win.Uuid(win.Uuid()),
		area	= "Common",
		key	= ii_key,
		priority= 100,
		action	= function(mcr_src)
			far.Message(
				"You pressed "..(AKey or string.format("%s / %s", mf.akey(1, 0), mf.akey(1, 1))),
				mcr_src.description
					)
		end
	}
end

Macro {	description = "CtrlF9-AltF9 (Viewer+Editor) MacroEx example",
	id = win.Uuid(win.Uuid()),
	area = "Viewer Editor",
	key = "CtrlF9-AltF9",
	priority = 100,
	action = function(mcr_src) far.Message("You pressed "..(AKey or string.format("%s / %s", mf.akey(1, 0), mf.akey(1, 1))), mcr_src.description) end
}

-- @@@@@
