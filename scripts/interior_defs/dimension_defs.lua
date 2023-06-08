local INTERIOR_WIDTHS = {
	10,
	12,
	16,
	18,
}

local INTERIOR_HEIGHTS = {
	5,
	6,
	7,
	10,
	11,
	12,
	13,
}

local INTERIOR_TEXTURE_DIMENSIONS = {
	512,
	1024,
}


local function Initialize()
	for _, num in pairs(INTERIOR_WIDTHS) do for _, dimension in pairs(INTERIOR_TEXTURE_DIMENSIONS) do
		local scale = UnitToPixel(num) / 512
		EnvelopeManager:AddVector2Envelope(
			"interiorwidth"..num,
			{
				{ 0,    { scale, scale } },
				{ 1,    { scale, scale } },
			}
		)
	end end
	
	for _, num in pairs(INTERIOR_HEIGHTS) do
		local scale = UnitToPixel(num) / 512
		EnvelopeManager:AddVector2Envelope(
			"interiorheight"..num,
			{
				{ 0,    { -scale, -scale * 1.064 } }, --(H): why do I seemingly randomly increase height scale by this arbitrary amount? Well, Hamlet's walls are slightly taller too for some reason, I do not know the exact value
				{ 1,    { -scale, -scale * 1.064 } },
			}
		)
		EnvelopeManager:AddVector2Envelope(
			"interiorheightleftwall"..num,
			{
				{ 0,    { scale, -scale * 1.064 } },
				{ 1,    { scale, -scale * 1.064 } },
			}
		)
	end
end

return {
    --Internal use
    Initialize = Initialize,

    --Public use
    INTERIOR_WIDTHS = INTERIOR_WIDTHS,
    INTERIOR_HEIGHTS = INTERIOR_HEIGHTS,
    INTERIOR_TEXTURE_DIMENSIONS = INTERIOR_TEXTURE_DIMENSIONS,
}