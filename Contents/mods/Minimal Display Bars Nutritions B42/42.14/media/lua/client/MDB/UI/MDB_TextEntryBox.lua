require "ISUI/ISUIElement"

MDB_TextEntryBox = ISUIElement:derive("MDB_TextEntryBox");


--************************************************************************--
--** ISPanel:initialise
--**
--************************************************************************--

function MDB_TextEntryBox:initialise()
	ISUIElement.initialise(self);
end

function MDB_TextEntryBox:validate()
    local text = self:getInternalText()
    text = text:gsub("[^%d]+", "")
    self:setText(text)

    if self.displayBar then

        local num = tonumber(text)

        local switchOnTextChange =
        {
            ["x"] = function()
                if num and num < 0 then num = 0 end
                if num == nil then num = 0 end
                self.displayBar:setX(num)
                if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.displayBar.coopNum, MDB.indicators[self.displayBar.playerIndex]) end
            end,
            ["y"] = function()
                if num and num < 0 then num = 0 end
                if num == nil then num = 0 end
                self.displayBar:setY(num)
                if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.displayBar.coopNum, MDB.indicators[self.displayBar.playerIndex]) end
            end,
            ["height"] = function()
                if num and num < 7 then num = 7 end
                if num == nil then num = 7 end
                self.displayBar:setHeight(num)
                if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.displayBar.coopNum, MDB.indicators[self.displayBar.playerIndex]) end
            end,
            ["width"] = function()
                if num and num < 7 then num = 7 end
                if num == nil then num = 7 end
                self.displayBar:setWidth(num)
                if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.displayBar.coopNum, MDB.indicators[self.displayBar.playerIndex]) end
            end,
            ["imageSize"] = function()
                if num and num < 1 then num = 1 end
                if num == nil then num = 1 end
                self.displayBar.imageSize = num
                --if MDB and MDB.indicators then MDB_MoveBarsTogether.recreatePanel(self.displayBar.coopNum, MDB.indicators[self.displayBar.playerIndex]) end
            end,
        }

        local f = switchOnTextChange[self.id]
        if f then
            f()
        end

    end
end

function MDB_TextEntryBox:onCommandEntered()

end

function MDB_TextEntryBox:onTextChange()
    --print(self:getText().."TEXTCHANGE TEXT")
    --print(self:getInternalText().."TEXTCHANGE INTERNALTEXT")

    self:validate()
end

function MDB_TextEntryBox:ignoreFirstInput()
	self.javaObject:ignoreFirstInput();
end

function MDB_TextEntryBox:setOnlyNumbers(onlyNumbers)
    self.javaObject:setOnlyNumbers(onlyNumbers);
end
--************************************************************************--
--** ISPanel:instantiate
--**
--************************************************************************--
function MDB_TextEntryBox:instantiate()
	--self:initialise();
	self.javaObject = UITextBox2.new(self.font, self.x, self.y, self.width, self.height, self.title, false);
	self.javaObject:setTable(self);
	self.javaObject:setX(self.x);
	self.javaObject:setY(self.y);
	self.javaObject:setHeight(self.height);
	self.javaObject:setWidth(self.width);
	self.javaObject:setAnchorLeft(self.anchorLeft);
	self.javaObject:setAnchorRight(self.anchorRight);
	self.javaObject:setAnchorTop(self.anchorTop);
	self.javaObject:setAnchorBottom(self.anchorBottom);
	self.javaObject:setEditable(true);
	--self.javaObject:setText(self.title);

end
function MDB_TextEntryBox:getText()
	return self.javaObject:getText();
end

function MDB_TextEntryBox:setEditable(editable)
    self.javaObject:setEditable(editable);
    if editable then
        self.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    else
        self.borderColor = {r=0.4, g=0.4, b=0.4, a=0.5}
    end
end

function MDB_TextEntryBox:setSelectable(enable)
	self.javaObject:setSelectable(enable)
end

function MDB_TextEntryBox:setMultipleLine(multiple)
    self.javaObject:setMultipleLine(multiple);
end

function MDB_TextEntryBox:setMaxLines(max)
    self.javaObject:setMaxLines(max);
end

function MDB_TextEntryBox:setClearButton(hasButton)
    self.javaObject:setClearButton(hasButton);
end

function MDB_TextEntryBox:setText(str)
    if not str then
        str = "";
    end
	self.javaObject:SetText(str);
	self.title = str;
end

function MDB_TextEntryBox:onPressDown()
    self:validate()
end

function MDB_TextEntryBox:onPressUp()
    self:validate()
end

function MDB_TextEntryBox:focus()
	return self.javaObject:focus();
end

function MDB_TextEntryBox:unfocus()
	return self.javaObject:unfocus();
end

function MDB_TextEntryBox:getInternalText()
	return self.javaObject:getInternalText();
end

function MDB_TextEntryBox:setMasked(b)
	return self.javaObject:setMasked(b);
end

function MDB_TextEntryBox:setMaxTextLength(length)
	self.javaObject:setMaxTextLength(length);
end

function MDB_TextEntryBox:setForceUpperCase(forceUpperCase)
	self.javaObject:setForceUpperCase(forceUpperCase);
end

--************************************************************************--
--** ISPanel:render
--**
--************************************************************************--
function MDB_TextEntryBox:prerender()

	self.fade:setFadeIn(self:isMouseOver() or self.javaObject:isFocused())
	self.fade:update()

	self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	if self.borderColor.a == 1 then
		local rgb = math.min(self.borderColor.r + 0.2 * self.fade:fraction(), 1.0)
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, rgb, rgb, rgb);
	else -- setValid(false)
		local r = math.min(self.borderColor.r + 0.2 * self.fade:fraction(), 1.0)
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, r, self.borderColor.g, self.borderColor.b)
	end

    if self:isMouseOver() and self.tooltip then
        local text = self.tooltip;
        if not self.tooltipUI then
            self.tooltipUI = ISToolTip:new()
            self.tooltipUI:setOwner(self)
            self.tooltipUI:setVisible(false)
        end
        if not self.tooltipUI:getIsVisible() then
            if string.contains(self.tooltip, "\n") then
                self.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
            else
                self.tooltipUI.maxLineWidth = 300
            end
            self.tooltipUI:addToUIManager()
            self.tooltipUI:setVisible(true)
            self.tooltipUI:setAlwaysOnTop(true)
        end
        self.tooltipUI.description = text
        self.tooltipUI:setX(self:getMouseX() + 23)
        self.tooltipUI:setY(self:getMouseY() + 23)
    else
        if self.tooltipUI and self.tooltipUI:getIsVisible() then
            self.tooltipUI:setVisible(false)
            self.tooltipUI:removeFromUIManager()
        end
    end
end

function MDB_TextEntryBox:onMouseMove(dx, dy)
	self.mouseOver = true
end

function MDB_TextEntryBox:onMouseMoveOutside(dx, dy)
	self.mouseOver = false
end

function MDB_TextEntryBox:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - (del*40))
	return true;
end

function MDB_TextEntryBox:clear()
	self.javaObject:clearInput();
end

function MDB_TextEntryBox:setHasFrame(hasFrame)
	self.javaObject:setHasFrame(hasFrame)
end

function MDB_TextEntryBox:setFrameAlpha(alpha)
	self.javaObject:setFrameAlpha(alpha);
end

function MDB_TextEntryBox:getFrameAlpha()
	return self.javaObject:getFrameAlpha();
end

function MDB_TextEntryBox:setValid(valid)
	if valid then
		self.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
	else
		self.borderColor = {r=0.7, g=0.1, b=0.1, a=0.7}
	end
end

function MDB_TextEntryBox:setTooltip(text)
	self.tooltip = text and text:gsub("\\n", "\n") or nil
end

--************************************************************************--
--** ISPanel:new
--**
--************************************************************************--
function MDB_TextEntryBox:new(id, title, x, y, width, height, displayBar)
	local o = {}
	--o.data = {}
	o = ISUIElement:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.x = x;
	o.y = y;

    o.id = id
	o.title = title;
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.width = width;
	o.height = height;
    o.keeplog = false;
    o.logIndex = 0;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
	o.fade = UITransition.new()
	o.font = UIFont.Small
    o.currentText = title;

    o.displayBar = displayBar

	return o
end
