--[[
	fontSelector.lua
		Displays a list of fonts registered with LibSharedMedia for the user to pick from
--]]


local LSM = LibStub('LibSharedMedia-3.0')
local LSM_FONT = LSM.MediaType.FONT
local PADDING = 2
local FONT_HEIGHT = 18
local BUTTON_HEIGHT = 24

local function getFontIDs()
	return LSM:List(LSM_FONT)
end

local function fetchFont(fontId)
	if fontId and LSM:IsValid(LSM_FONT, fontId) then
		return LSM:Fetch(LSM_FONT, fontId)
	end
	return LSM:Fetch(LSM_FONT, DEFAULT_FONT)
end

--[[
	The Font Button
--]]

local FontButton = OmniCC.Classy:New('CheckButton')

function FontButton:New(parent)
	local b = self:Bind(CreateFrame('CheckButton', nil, parent))
	b:SetHeight(48)
	b:SetScript('OnClick', b.OnClick)
	
	local bg = b:CreateTexture(nil, 'BACKGROUND')
	bg:SetTexture(0.3, 0.3, 0.3, 0.3)
	bg:SetAllPoints(b)
	
	local text = b:CreateFontString(nil, 'ARTWORK')
	text:SetPoint('BOTTOM', 0, PADDING)
	b:SetFontString(text)
	b:SetNormalFontObject('GameFontNormalSmall')
	b:SetHighlightFontObject('GameFontHighlightSmall')
	
	local fontText = b:CreateFontString(nil, 'ARTWORK')
	fontText:SetPoint('TOPLEFT', 4, -4)
	fontText:SetPoint('TOPRIGHT', -4, -4)
	fontText:SetPoint('BOTTOM', text, 'TOP', 0, 4)
	b.fontText = fontText
	
	local ht = b:CreateTexture(nil, 'OVERLAY')
	ht:SetTexture([[Interface\Buttons\UI-Listbox-Highlight]])
	ht:SetAlpha(0.1)
	ht:SetBlendMode('BLEND')
	ht:SetAllPoints(b)
	b:SetHighlightTexture(ht)
	
	local ct = b:CreateTexture(nil, 'OVERLAY')
	ct:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
	ct:SetSize(24, 24)
	ct:SetPoint('LEFT')
	b:SetCheckedTexture(ct)
	
	return b
end

function FontButton:SetFontID(fontID)
	self.fontID = fontID
	self:UpdateFont()
end

function FontButton:GetFontID()
	return self.fontID
end

function FontButton:UpdateFont()
	local fontID = self:GetFontID()
	self.fontText:SetFont(fetchFont(fontID), FONT_HEIGHT, 'OUTLINE')
	self.fontText:SetText('1234567890')
	self:SetText(fontID)
end


--[[
	The Font Selector
--]]

local FontSelector = OmniCC.Classy:New('Frame')
OmniCC.FontSelector = FontSelector

function FontSelector:New(title, parent)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. title, parent, 'OptionsBoxTemplate'))
	f:SetScript('OnShow', f.OnShow)
	f:SetBackdropBorderColor(0.4, 0.4, 0.4)
	f:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
	_G[f:GetName() .. 'Title']:SetText(title)
	
	local scrollFrame = f:CreateScrollFrame()
	scrollFrame:SetPoint('TOPLEFT', 8, -8)
	scrollFrame:SetWidth(346)
	scrollFrame:SetHeight(244)
	f.scrollFrame = scrollFrame

	local scrollChild = f:CreateScrollChild()
	scrollFrame:SetScrollChild(scrollChild)
	f.scrollChild = scrollChild
	
	local scrollBar = f:CreateScrollBar()
	scrollBar:SetPoint('TOPRIGHT', -8, -8)
	scrollBar:SetPoint('BOTTOMRIGHT', -8, 6)
	scrollBar:SetWidth(16)
	f.scrollBar = scrollBar

	return f
end

do
	local function scrollFrame_OnMouseWheel(self, delta)
		local scrollBar = self:GetParent().scrollBar
		local min, max = scrollBar:GetMinMaxValues()
		local current = scrollBar:GetValue()

		if IsShiftKeyDown() and (delta > 0) then
		   scrollBar:SetValue(0)
		elseif IsShiftKeyDown() and (delta < 0) then
		   scrollBar:SetValue(scrollMax)
		elseif (delta < 0) and (current < max) then
		   scrollBar:SetValue(current + 20)
		elseif (delta > 0) and (current > 1) then
		   scrollBar:SetValue(current - 20)
		end
	end

	function FontSelector:CreateScrollFrame()
		local scrollFrame = CreateFrame('ScrollFrame', nil, self)
		scrollFrame:EnableMouseWheel(true)
		scrollFrame:SetScript('OnMouseWheel', scrollFrame_OnMouseWheel)
	
		return scrollFrame
	end
end

do
	local function scrollBar_OnValueChanged(self, value)
		local scrollFrame = self:GetParent().scrollFrame
		scrollFrame:SetVerticalScroll(value)
	end

	function FontSelector:CreateScrollBar()
		local scrollBar = CreateFrame('Slider', nil, self)

		local bg = scrollBar:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(true)
		bg:SetTexture(0, 0, 0, 0.5)

		local thumb = scrollBar:CreateTexture(nil, 'OVERLAY')
		thumb:SetTexture([[Interface\Buttons\UI-ScrollBar-Knob]])
		thumb:SetSize(25, 25)
		scrollBar:SetThumbTexture(thumb)

		local scrollMax = self.scrollChild:GetHeight() - self.scrollFrame:GetHeight()
		scrollBar:SetMinMaxValues(0, scrollMax)
		scrollBar:SetValue(0)
		scrollBar:SetOrientation('VERTICAL')
	
		scrollBar:SetScript('OnValueChanged', scrollBar_OnValueChanged)
		return scrollBar
	end
end

function FontSelector:CreateScrollChild()
	self.buttons = {}
	
	local scrollChild = CreateFrame('Frame')
	local height = 0

	local f_OnClick = function(f) self:Select(f:GetFontID()) end

	for i, fontID in ipairs(getFontIDs()) do
		local f = FontButton:New(scrollChild)
		f:SetFontID(fontID)
		f:SetScript('OnClick', f_OnClick)
		
		if i == 1 then
			f:SetPoint('TOPLEFT')
			f:SetPoint('TOPRIGHT', scrollChild, 'TOP', -PADDING/2, 0)
			height = height + BUTTON_HEIGHT
		elseif i == 2 then
			f:SetPoint('TOPLEFT', scrollChild, 'TOP', PADDING/2, 0)
			f:SetPoint('TOPRIGHT')
		else
			f:SetPoint('TOPLEFT', self.buttons[i-2], 'BOTTOMLEFT', 0, -PADDING)
			f:SetPoint('TOPRIGHT', self.buttons[i-2], 'BOTTOMRIGHT', 0, -PADDING)
			height = height + BUTTON_HEIGHT + PADDING
		end
		
		table.insert(self.buttons, f)
	end

	scrollChild:SetWidth(self.scrollFrame:GetWidth())
	scrollChild:SetHeight(height)
	
	return scrollChild
end


function FontSelector:OnShow()
	self:UpdateSelected()
end

function FontSelector:Select(value)
	self:SetSavedValue(value)
	self:UpdateSelected()
end

function FontSelector:SetSavedValue(value)
	assert(false, 'Hey, you forgot to set SetSavedValue for ' .. self:GetName())
end

function FontSelector:GetSavedValue()
	assert(false, 'Hey, you forgot to set GetSavedValue for ' .. self:GetName())
end

function FontSelector:UpdateSelected()
	local selectedValue = self:GetSavedValue()
	for i, button in pairs(self.buttons) do
		button:SetChecked(button:GetFontID() == selectedValue)
	end
end