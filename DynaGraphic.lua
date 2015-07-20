--[[
	DynaGrahpic is a powerful GUI framework for ComputerCraft 1.63+

	It allows developers to easily create on screen objects using external templates which are then loaded, buffered and displayed

	Templates contain a LUA object that sets the options of the object at run time, this allows you to completely restyle the page when a differnet
	template is loaded.

	The templates must be contained in the following folder relative to the program that runs DynaGraphic. The folder must be /Templates

	When the program is initialized the template that is specified will be loaded, therefore allowing you to specify defaults template.

	Copyright 2015 (c) HexCode, Harry Felton and other contributors
]]--

drawing = {
	drawArea = function() 
		-- Draw an oblong area
	end,

	drawLine = function()
		-- Draw a vertical or horizontal line
	end

}

helpers = {
	shorten = function()
		-- If text is greater than limit, shorten

	end,

	removeExtension = function()
		-- Remove file extension

	end,
}

object = {
	create = function()
		-- Return new META tag, will gather settings from current view
	end,
	
}

objects = [
	"text",
	"button",
	"image"
]