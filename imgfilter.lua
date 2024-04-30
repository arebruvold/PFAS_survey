function Image (img)
	if img.attributes.style ~=nil then
		local height = img.attributes.style:match "%d+"
		img.attributes.height = tonumber(height)
	end
	--	img.attributes.height = 60
	return img
end
