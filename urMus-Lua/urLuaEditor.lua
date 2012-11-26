-- Load utility and library functions here
dofile(SystemPath("FAIAP.lua"))
dofile(SystemPath("urKeyboard.lua"))
dofile(SystemPath("urTopBar.lua"))
dofile(SystemPath("urStringEditBox.lua"))

local codefilename
local edited

local currentcode

local cursor

local cursorpos = 0
colorcode = true

function CreateCursor(self,x,y,h)
	cursor = Region()
	cursor:SetAnchor("BOTTOMLEFT",self,"BOTTOMLEFT", x, y)
	cursor:SetWidth(3)
	cursor:SetHeight(h)
	cursor.t = cursor:Texture(0,0,255,128)
	cursor:Show()
end

function RefreshCursor(self)
    local x,y = self.tl:LabelBounds(cursorpos,cursorpos)
    cursor:SetAnchor("BOTTOMLEFT",self,"BOTTOMLEFT",x ,y )
    local code = self.tl:Label()
    DPrint(cursorpos.." : "..code:sub(cursorpos,cursorpos+3))
end

function OnTouchDownCursor(self,x,y)
	local pos = self.tl:CharPosition(x,y)
    if pos >= 0 then 
        cursorpos = pos
        RefreshCursor(self)
    end
end

local function ColorCode(t)
    local code = t
    if colorcode then
        colorTable = colorhighlightlib.defaultColorTable
        colorTable[0] = "|r"

        --code = colorhighlightlib.colorCodeCode(t, colorTable, 0)
        code = colorhighlightlib.indentCode(t, 2, colorTable, 0)
    end
    return code
end

local function ClearCode(self)
    EditRegion.tl:SetLabel("")
    currentcode = ""
    cursporpos = 0
    ShowNotification("Cleared")
end

local function NewCode(self)
--    EnterName()
    if codefilename and edited then
-- WarnSave
    end
    local function Done(str)
        codefilename = str..".lua"
    end
    OpenStringEditBox("ur","New Filename:",Done)
    EditRegion.tl:SetLabel("")
    currentcode = ""
    cursorpos = 0

    ShowNotification("New")
end

local function LoadLuaFile(file,path)

	local filename
	if not path then
		filename = 	SystemPath(file)
	else
		filename = path.."/"..file
	end
    local f = assert(io.open(filename, "r"))
    local t = f:read("*all")
    f:close()

    currentcode = t
    cursorpos = 0
    local code = ColorCode(t)

	EditRegion.tl:SetLabel(code)
	codefilename = file
    ShowNotification(file.." Loaded")
end


local function LoadCode(self)
    if codefilename and edited then
    -- WarnSave
    end
   	local scrollentries = {}

	for k,v in pairs(pagefile) do
		local entry = { v, nil, nil, LoadLuaFile, {84,84,84,255}}
		table.insert(scrollentries, entry)
	end
	for v in lfs.dir(DocumentPath("")) do
		if v ~= "." and v ~= ".." and string.find(v,"%.lua$") then
			local entry = { v, nil, nil, LoadLuaFile, {84,84,84,255}, DocumentPath("")}
			table.insert(scrollentries, entry)			
		end
	end
	
	urScrollList:OpenScrollListPage(scrollpage, "Load Lua File", nil, nil, scrollentries)
end

local function WriteCodeToFile(filename)
    local f = assert(io.open(DocumentPath(filename), "w"))
    local t = f:write(colorhighlightlib.stripWowColors(EditRegion.tl:Label()))
    f:close()
end

local function SaveCode(self)
    if not codefilename then
	    local function Done(str)
            local filename = str..".lua"
            WriteCodeToFile(filename)
            ShowNotification(filename.." Saved")
		end
	    OpenStringEditBox("ur","Filename:",Done)
    else
        WriteCodeToFile(codefilename)
    end
end

local function RunCode(self)
    local code = EditRegion.tl:Label()
    RunScript(code)
    local code = ColorCode(code)
    ShowNotification("Ran Code")
end

CreateTopBar(6,"Clear",ClearCode,"New",NewCode,"Load",LoadCode,"Save",SaveCode,"Run",RunCode,"Face",FlipPage)

local mykb = Keyboard.Create()

EditRegion = Region()
EditRegion:SetWidth(ScreenWidth())
EditRegion:SetHeight(ScreenHeight()-mykb:Height()-28)
EditRegion:SetAnchor("BOTTOMLEFT",0,mykb:Height())
EditRegion.tl = EditRegion:TextLabel()
EditRegion.tl:SetVerticalAlign("TOP")
EditRegion.tl:SetHorizontalAlign("LEFT")
EditRegion.tl:SetFontHeight(ScreenHeight()/30)
EditRegion.tl:SetLabel("")
EditRegion:Show()

EditRegion:Handle("OnTouchDown", OnTouchDownCursor)
EditRegion:EnableInput(true)
CreateCursor(self,0,EditRegion:Height()-EditRegion.tl:FontHeight(),EditRegion.tl:FontHeight())

--[[
function hookedSetLabel(self, label)
    local code = ColorCode(label)
    EditRegion.tl:SetLabel(code)
end

function hookedLabel(self)
    return EditRegion.tl:Label()
end

HookedEditRegion = {}
HookedEditRegion.tl = {}
HookedEditRegion.tl.SetLabel = hookedSetLabel
HookedEditRegion.tl.Label = hookedLabel

mykb.typingarea = HookedEditRegion --]]

function KeyInput(c)
    local code = EditRegion.tl:Label()
    local pos, numLines
    if colorcode then
        code, pos = colorhighlightlib.stripWowColorsWithPos(code, cursorpos)
        pos = pos - 1
    else
        pos = cursorpos
    end
    
    code = code:sub(1,pos)..c..code:sub(pos+1)
    if colorcode then
        code, pos, numLines = colorhighlightlib.colorCodeCode(code, colorTable, pos+2)
    else
        pos = pos + 1
    end

    cursorpos = pos

    EditRegion.tl:SetLabel(code)

    RefreshCursor(EditRegion)

end

function KeyBackspace()
    if cursorpos > 0 then
        local code = EditRegion.tl:Label()
        local pos, numLines
        if colorcode then
        DPrint(code:sub(cursorpos-2,cursorpos+2))
            code, pos = colorhighlightlib.stripWowColorsWithPos(code, cursorpos)
            pos = pos - 1
        else
            pos = cursorpos
        end
        code = code:sub(1,pos-1) .. code:sub(pos+1)
        if colorcode then
            code, pos, numLines = colorhighlightlib.colorCodeCode(code, colorTable, pos)
        else
            pos = pos - 1
        end
        cursorpos = pos

        EditRegion.tl:SetLabel(code)

        RefreshCursor(EditRegion)
    end
end

function KeyEnter()
    KeyInput('\n')
end

EditRegion.tl:SetLabel("")
RefreshCursor(EditRegion)

mykb.keyfunc = KeyInput
mykb.backfunc = KeyBackspace
mykb.enterfunc = KeyEnter
mykb:Show(1)

