-- Note:Temp add it here,because ISUIElement miss this part,will be deleted when Tis update ISUIElement
-- copy the code to your mod and use it ,dont use it directly

NeatTool = NeatTool or {}

-- ----------------------------------------------------------------------------------------------------- --
-- drawTexturePercentage (left -> right)
-- ----------------------------------------------------------------------------------------------------- --

function NeatTool.drawTexturePercentage(self,texture,Percentage, x, y, width, height, a, r, g, b)
    -- copy from here
	if self.javaObject ~= nil then
		self.javaObject:DrawTexturePercentage(texture, Percentage, x, y, width, height, r, g, b, a)
	end
    -- end
end

-- ----------------------------------------------------------------------------------------------------- --
-- drawTexturePercentageBottomUp (bottom -> top)
-- ----------------------------------------------------------------------------------------------------- --

function NeatTool.drawTexturePercentageBottomUp(self,texture,Percentage, x, y, width, height, a, r, g, b)
    -- copy from here
	if self.javaObject ~= nil then
		self.javaObject:DrawTexturePercentageBottomUp(texture, Percentage, x, y, width, height, r, g, b, a)
	end
    -- end
end