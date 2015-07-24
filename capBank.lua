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
termX, termY = term.getSize()
_G.runningProgram = shell.getRunningProgram()

session = {
	mons = {},
	cap = false,
	wrap = false
}

--term.setBackgroundColor(colors.white)
os.loadAPI("DynaGraphic")
cv = DynaGraphic.clone("capbank")

tc = cv.helpers.tc
bg = cv.helpers.bg
pos = cv.helpers.pos
shorten = cv.helpers.shorten
cls = cv.helpers.clear
gc = cv.helpers.getColor
cout = cv.drawing.drawCentre
db = cv.log.output
log = cv.log


db( "i", "Alias and APIs loaded")
db( "i", "Loading file system")
bg( "white" )
cls()
cout( "Circum Capacitor Bank", 4, "orange" )
cout( "Loading File System", 6, "gray" )

local function config()
	db( "i", "Starting setup" )
	set = {}
	function welcome()
		cls()
		primary:bufferAdd():bufferDraw()
		cout("Circum Capacitor Bank Setup", 6, "orange")
		cout("To configure the Capacitor Bank program", 10, "gray")
		cout("please click 'Next'", 11)
		db( "i", "Welcome page ready" )
	end

	function amountOfCap()
		bg("white")
		cls()
		primary:disable()
		primary.onclick = function( self )
			if #capamount.typed > 0 then
				set.amount = capamount.typed
				finish()
			end
		end
		cout("How many capacitors are in this bank?", 6, "orange")
		cout("Due to the way the EnderIO API works", 9, "gray")
		cout("I need to know how many capacitors", 10)
		cout("are in this bank.", 11)
		capamount:bufferAdd():focus()
	end

	function finish()
		term.setCursorBlink( false )
		cv.hideAll()
		cls()
		cv.textLine({
			text = "Saving settings...",
			y = 6,
			center = true,
			backgroundColor = gc("white"),
			textColor = gc("orange")
		}):bufferAdd()
		cv.textBlock({
			lines = {
				"Thanks for configuring Circum Capacitor Bank",
				"",
				"We are saving your settings"
			},
			center = true,
			y = 10,
			backgroundColor = gc("white"),
			textColor = gc("gray")
		}):bufferAdd()
	end

	capamount = cv.input({
		name = "capacitor_amount",
		visible = true,
		enabled = true,
		focusable = true,
		onkeyup = function( self, key )
			if #self.typed > 0 then
				primary:enable()
			else primary:disable() end
			cv.bufferDraw()
		end,
		onsubmit = function( self )
			if #self.typed > 0 then
				primary:onclick()
			end
		end,
		textColor = gc("orange"),
		backgroundColor = gc("gray"),
		limit = 4,
		y = 13,
		x = termX/2 - 2,
		whitelist = {
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
		}
	})

	primary = cv.button({
		name = "next_button",
		text = "Next",
		visible = true,
		y = termY-1,
		padding = 1,
		onclick = function() amountOfCap() end,
		enabled = true,
		backgroundColor = gc("orange")
	}):bufferAdd()

	primary.x = termX - primary.width/2 - primary.padding
	cv.startEventLoop(function() 
		welcome()
	end) -- Start event loop

end

--[[Create a new metatable containing functions used by self]]

function regMonitor( side )
	-- Monitor found, create the meta table and return it.
	new = {}
	setmetatable( new, {__index = self} )
	new.side = side
	new.label = "monitor"
	new.wrap = peripheral.wrap( side )
	new.draw = function( self, text, y, x )
		if peripheral.isPresent(self.side) and peripheral.getType(self.side) == "monitor" and self.wrap then
			local mX, mY = self:getDim()
			-- we have the dimensions of a monitor, write text to this on y if not out of range. if text too long then shorten
			if mY < y then
				log.output("w", "Monitor "..self.side.."s X dimension is not big enough")
				-- Output an error message to the monitor
				self.cout("Too Small", true, 1, 1)
			elseif mX < x or (x+#text) > mX then
				log.output("w", "Monitor "..self.side.."s Y dimension is not big enough")
				self:cout("Too Small", true, 1, 1)
			else
				self:cout( text, true, x, y )
			end
		end
	end
	new.cout = function( self, text, clear, x, y )
		x = x or 1
		y = y or 1
		text = text or ""
		clear = clear or false
		if clear then
			self.wrap.clear()
		end
		self.wrap.setCursorPos( x, y )
		self.wrap.write( text )
	end
	new.getDim = function(self)
		return self.wrap.getSize()
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
	updateMon()
	cv.redrawAll()
	eventLoop()
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
			if peripheral.getType(side) == "monitor" then
				r = true
				table.insert( session.mons, regMonitor( side ) )
			end
		end
	end
	return r
end

function settings()
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
		config()
	else
		error"Ready"
	end
end

function saveSettings()

end

function updateMon( stats )
	-- Update monitor screens with capacitor bank information
	for i, v in ipairs( session.mons ) do
		local msg = "Monitor Connected ("..i..")"
		v:draw(msg, 2, 1)
	end
end

function updateTerm( stats )
	-- Update the terminal window with information if page is "main"
end

local nativeError = _G.error

function formalError( trace )
	term.setCursorBlink(false)
	-- First, get the first line of the trace
	_err = trace[1]
	--nativeError( _err )
	log.output("e", textutils.serialize(trace))
	_err = _err:match("%s.*")
	bg("blue")
	tc("white")
	cls()
	cout("Circum Capacitor Bank", 4)
	cout("Error Caught", 5)
	cout(_err, 8, "lightGray")
	cout("To view system log press [s], press any", termY-5)
	cout("other key to reboot", termY-4)
	rebootCountdown = 10
	cout(string.format("Rebooting automatically in %d seconds", rebootCountdown), termY, "white")
	rebootTimer = os.startTimer(1)
	while true do
		-- Create event listener
		local e, p1, p2, p3 = os.pullEventRaw()
		if e == "timer" then
			if p1 == rebootTimer then 
				if rebootCountdown <= 1 then
					os.reboot()
				else
					rebootCountdown = rebootCountdown - 1
					rebootTimer = os.startTimer(1)
				end
				if rebootCountdown > 1 then
					cout(string.format("Rebooting automatically in %d seconds", rebootCountdown), termY, "white")
				else
					cout(string.format("Rebooting automatically in %d second", rebootCountdown), termY, "white")
				end
			end
		elseif e == "key" then
			if p1 == keys.s then
				-- Open stacktrace
				sleep(0)
				shell.run("edit systemLog.log")
				os.reboot()
			else
				os.reboot()
			end
		end
	end
end

function _G.error(_msg, _level)
	_level = _level or 3
	if _msg == "terminated" or _level == 0 then
		trace = {
			"ERR: "..tostring(_msg)
		}
		formalError( trace )
	end
	local trace = {}
	function addToTrace( content )
		table.insert( trace, content )
	end

	local atc = addToTrace

	atc("ERR: "..tostring(_msg))
	local ok, err, last = nil, "", os.clock()
	while true do
		ok, err = pcall(nativeError, _msg, _level) -- Call the error function repeatedly, each time increasing the level to get the next program in line
		if err:find("^bios") or err:find("^shell") then
			-- If BIOS or SHELL then stop the stack trace
			atc("Stacktrace End")
			break
		end
		local name, line = err:match("(%a+)%.?.-:(%d+).-")
		atc( string.format("at %s :%d", name or "?", line or 0) )
		_level = _level + 1
	end
	formalError( trace )
end

cv.peripheral.setGroup( cv.peripheral.getAllWraps("monitor"), "test_group")

cv.monitor.drawToGroupCentered( cv.peripheral.getGroup("test_group"), "Monitor test", 5)

local _, err = pcall(loadSettings)
error( err, 4)
