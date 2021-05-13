-- [[
if true then return end --]]

local Info = Info or package.loaded.regscript or function(...) return ... end -- luacheck: ignore 113/Info
local nfo = Info {
	_filename or ...,
	name		= "MacroEx test",
	description	= "sample macros to test MacroEx",
	id		= "931E8931-11D0-4FD9-B493-657898578F1B",
	parent_id	= "115C9534-8273-4F5A-94EB-E321D6DC8618",
	version		= "3", 
	version_mod	= "0.3", 
	author		= "JD",
	author_mod	= "Xer0X",
	url		= "http://forum.farmanager.com/viewtopic.php?f=15&t=8764",
	url_mod		= "https://github.com/dr-dba/far-lua-key-efficiency",
--	disabled	= true;
}

if not nfo then return end

Macro { description = "test",
	id = win.Uuid(win.Uuid()),
	area = "Editor",
	key = "CtrlF9",
--	priority = 100,
	action = function() far.Message("plain macro") end
}

for ii, ii_key in ipairs({
	"CtrlF9:Hold",
	"CtrlF9:Double",
	"ShiftF8-F8",
	"CtrlF8-F9",
	"CtrlK-J",
	"AltF1:Hold",
	"CtrlAltF1:Hold",
	"RCtrlRAltF2:Hold",
	"LCtrlLAltF2:Hold",
	"ShiftF1:Hold",
	"^:Hold",
	"::Double",
	-- error
--	"qwerty-0",
	"CtrlAltS:Hold",
	"CtrlAltS:Double",
	"CtrlAltS-CtrlAltS",
	"CtrlAlt-CtrlAlt",
	"CtrlAlt-Alt",
	"CtrlAlt:Double",
	"CtrlAlt:Hold",
	"CtrlAlt-F8",
	"CtrlF8-Alt"
})
do
	Macro { description = "Example MacroEx: "..ii_key,
		id = win.Uuid(win.Uuid()),
		area = "Editor",
		key = ii_key,
		action = function() far.Message(ii_key, "Pressed") end
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

Macro {	description = "CtrlF9-AltF9 (Viewer) MacroEx example",
	id = win.Uuid(win.Uuid()),
	area = "Viewer",
	key = "CtrlF9-AltF9",
	priority = 100,
	action = function(mcr_src) far.Message("You pressed "..(AKey or string.format("%s / %s", mf.akey(1, 0), mf.akey(1, 1))), mcr_src.description) end
}

Macro {	description = "CtrlF9-AltF9 (Editor) MacroEx example",
	id = win.Uuid(win.Uuid()),
	area = "Editor",
	key = "CtrlF9-AltF9",
	priority = 100,
	action = function(mcr_src) far.Message("You pressed "..string.format("%s; %s / %s", AKey, mf.akey(1, 0), mf.akey(1, 1)), mcr_src.description) end
}

-- @@@@@
