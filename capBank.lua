--[[
	This program updates both the terminal and all connected monitors every 0.5 secs.

	The program utilises methods exposed by openP:
	 - getEnergyStored()
	 - getAdvancedMethodsData()
	 - getMaxEnergyStored()
	 - doc()
	 - listMethods()

	Every 0.5secs the program will use the wrapped peripheral to gather information about the energy cell. This information will then be
	multiplied by the amount of capacitors in the multi block.

]]

_G.runningProgram = shell.getRunningProgram()

session = {
	mons = {},
	cap = false,
	capwrap = false
}

--[[color = {
	returnFilter = function( color )

	end,

	setFilter = function( filter )

	end,

	filters = {

	}
}]]

drawing = {
	termX, termY = term.getSize(),
	drawCentre = function ( text, y, bg, tc )
		-- body
		draw( text, y, math.floor(termX/2-(#text/2)), bg, tc ) -- Use draw to make text centered
	end,
	draw = function ( text, y, x, bg, tc )
		term.setCursorPos( x, y )
		term.write( text )
	end,
	color = function() 
		term.setBackgroundColor( bg )
	end
}

log = {
	config = {
		enabled = true,
		location = "systemLog.log"
	},
	Initialise = function()
		-- Start the log file
		self.output( "i", "--== Cap Bank V0.2 ==--" )
		self.output( "i", "     LOG follows:      " )
		self.newline()
	end,
	newline = function()
		self.output("i", " \n ")
	end,
	output = function( type, text )
		if config.enabled then
			local f = fs.open(config.location, "w")
			local msg = "Info"
			if not type or type == "e" then
				msg = "FATAL"
			elseif type == "w" then
				msg = "Warning"
			end
			text = "[".._G.runningProgram.."] [" ..msg.. "]" .. text
			f.write( text )
			f.close()
		end
	end
}

helpers = {
	shorten = function(text, limit)
		-- Reduce text size by replace middle of string with "..."
	end
}

--[[Create a new metatable containing functions used by self]]

function regMonitor( side )
	-- Monitor found, create the meta table and return it.
	new = {}
	setmetatable( new, {__index = self} )
	new.side = side
	new.label = "monitor"
	new.wrap = peripheral.wrap( side )
	new.draw = function( self, text, y, x )
		print( self.wrap )
		if peripheral.isPresent(self.side) and peripheral.getType(self.side) == "monitor" and self.wrap then
			self.wrap.write( side )
			local mX, mY = self.getDim()
			print( mY )
			-- we have the dimensions of a monitor, write text to this on y if not out of range. if text too long then shorten
			if mY < y then
				log.output("w", "Monitor Y is too small")
				-- Output an error message to the monitor
				wrap.write("Too Small!")
			elseif mX < x or (x+#text) > mX then
				log.output("w", "Monitor X is too small")
				wrap.write("Too Small")
			end
		end
	end
	new.getDim = function()
		return new.wrap.getSize()
	end
	new.check = function()
		-- First check if the peripheral is still there.
		if peripheral.isPresent( new.side ) and peripheral.getType( new.side ) == "monitor" then
			new.wrap = peripheral.wrap( new.side )
			-- Rewrapped, check if advanced
			if new.wrap.isColor() then
				-- has color
			else
				-- no color
			end
		else
			new.wrap = false
		end
	end
	return new
end

function start() 
	--Start the program, first connect to monitors and store them in a table
	connectMonitors()
	connectBank()
end

function connectBank()
	-- Find the capacitor bank that the computer is directly connected to
	local peripherals = peripheral.getNames()
	for per, side in ipairs( peripherals ) do
		if per and side then
			if peripheral.getType( side ) == "tile_capbank" then-- Fake name
				session.cap = side
				return true
			end
		end
	end
	return false
end

function connectMonitors()
	-- Find any and all monitors connected via rednet or directly.
	local peripherals = peripheral.getNames()
	local r = false
	-- We have got all peripherals, check each one. If its type is monitor then store it.
	for per, side in ipairs( peripherals ) do
		if per and side then
			print("found peripheral on side: " .. side )
			if peripheral.getType(side) == "monitor" then
				print( side )
				r = true
				table.insert( session.mons, regMonitor( side ) )
			end
		end
	end
	return r
end

function config()
	local function login()

	end

	local function show()

	end
end

function update()
	local stats = {
		stored = session.wrap.getEnergyStored(),
		max = session.wrap.getMaxEnergyStored()
	}
end

function loadSettings()
	if not fs.exists( "capbank.cfg" ) then
		-- No config, launch setup
	end
end

function saveSettings()

end

function updateMon( stats )
	-- Update monitor screens with capacitor bank information
	for i, v in ipairs( session.mons ) do
		local msg = "Monitor Connected ("..i..")"
		v:draw(msg, 2, 1)
		print("drawing "..msg.." on "..v.side)
	end
end

function updateTerm( stats )
	-- Update the terminal window with information if page is "main"
end

Events = {}

function eventRegister(event, functionToRun)
	if not Events[event] then
		Events[event] = {}
	end
	table.insert(Events[event], functionToRun)
end

function eventLoop()
	while true do
		local event, arg1, arg2, arg3, arg4, arg5, arg6 = os.pullEventRaw()
		if Events[event] then
			for i, e in ipairs(Events[event]) do
				e(event, arg1, arg2, arg3, arg4, arg5, arg6)
			end
		end
	end
end

start()
updateMon()