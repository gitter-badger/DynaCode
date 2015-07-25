--[[
	This program updates both the terminal and all connected monitors every 0.5 secs.

	The program utilises methods exposed by openP:
	 - getEnergyStored()
	 - getMaxEnergyStored()

	Every 0.5secs (10 ticks) the program will use the wrapped peripheral to gather information about the energy cell. This information will then be
	multiplied by the amount of capacitors in the multi block.

]]
termX, termY = term.getSize()
_G.runningProgram = shell.getRunningProgram()

session = {
	wrap = false
}

--term.setBackgroundColor(colors.white)
os.loadAPI("DynaGraphic")
cv = DynaGraphic.clone("capbank")
cv.log.Initialise()

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

	function amountOfCap()
		bg("white")
		cls()
		primary:disable()
		primary.onclick = function( self )
			if #capamount.typed > 0 then
				set.amount = capamount.typed
				monitorDisplay()
			end
		end
		title.text = "How many capacitors are in this bank?"
		body.lines = {
			"Due to the way the EnderIO API works",
			"I need to know how many capacitors",
			"are in this bank."
		}
		capamount:bufferAdd():bufferDraw():focus()
	end

	function monitorDisplay()
		bg("white")
		primary:enable()
		primary.backgroundColor = gc("lime")
		primary.text = "Enable"
		primary.onclick = function() set.monitors = true finish() end
		primary:draw()
		secondary.onclick = function() set.monitors = false finish() end
		secondary:show()
		capamount:hide()
		cls()
		title.text = "Should we display information to monitors"
		body.lines = {
			"If this is enabled, any monitors",
			"attached directly or through wired modems",
			"will reflect the status of the capacitors",
			"like the terminal"
		}
		term.setCursorBlink( false )
	end

	function finish()
		term.setCursorBlink( false )
		cv.hideAll()
		cls()
		cv.file.write("capBank.cfg", textutils.serialize(set), "w")
		title.text = "Settings Saved"
		body.lines = {
			"Click 'Continue' to get started!"
		}
		title:show()
		body:show()
		primary.text = "Continue"
		primary.onclick = function() os.reboot() end
		primary:show()
		cv:bufferDraw()
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
		y = 15,
		x = termX/2 - 2,
		whitelist = {
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
		}
	})

	title = cv.textLine({
		text = "Circum Capacitor Bank Setup",
		center = true,
		visible = true,
		y = 6,
		backgroundColor = gc("white"),
		textColor = gc("orange")
	}):bufferAdd()

	body = cv.textBlock({
		lines = {
			"To start setting up this program",
			"click \"Next\""
		},
		center = true,
		visible = true,
		y = 10,
		backgroundColor = gc("white"),
		textColor = gc("gray")
	}):bufferAdd()

	primary = cv.button({
		name = "next_button",
		text = "Next",
		visible = true,
		y = termY-1,
		padding = 1,
		onclick = function() amountOfCap() end,
		enabled = true,
		backgroundColor = gc("orange"),
		beforeRedraw = function( self )
			self.x = termX - primary.width
		end
	}):bufferAdd()

	secondary = cv.button({
		name = "back_button",
		text = "Disable",
		visible = false,
		y = termY-1,
		padding = 1,
		onclick = function() amountOfCap() end,
		enabled = true,
		backgroundColor = gc("red"),
		x = 3
	}):bufferAdd()

	cv.startEventLoop(function()
		cls()
		cv:bufferDraw()
	end) -- Start event loop

end

--[[Create a new metatable containing functions used by self]]


function start()
	--Start the program, first connect to monitors and store them in a table
	cls()
	function displayTerm()
		line = "0"
		if session.stats.last > 0 and session.stats.last ~= session.stats.current then
			line = tostring( session.stats.last - session.stats.current )
		end
		cls()
		title.text = "Capacitor information"
		body.lines = {
			"",
			tostring( session.stats["current"].."/"..session.stats["cap"] ),
			"",
			"",
			line
		}
	end

	function displayMon()
		mon = cv.monitor
		mons = cv.peripheral.getGroup("monitors")
		mon.backgroundColorGroup( mons, gc("white"))
		mon.textColorGroup( mons, gc("orange") )
		mon.clearGroup( mons )
		mon.drawToGroupCentered( mons, "TEST", 3 )
	end

	function update()
		-- Loop through each wrap, accumulating a total
		if not powerTitle then
			powerTitle = cv.textLine({
				textColor = gc("orange"),
				backgroundColor = gc("white"),
				text = "Power Stored / Maximum Power",
				center = true,
				y = 13
			}):bufferAdd()
			outputTitle = cv.textLine({
				textColor = gc("orange"),
				backgroundColor = gc("white"),
				text = "RF Output Over 10 Ticks",
				center = true,
				y=16
			}):bufferAdd()
			title.y = 4
			body.y = body.y + 3
			subTitle = cv.textBlock({
				lines = {
					"Every 10 ticks we are collecting",
					"data about your capacitors",
					"",
					"The information is displayed below;"
				},
				center = true,
				backgroundColor = gc("white"),
				textColor = gc("lightGray"),
				y = 6
			}):bufferAdd()
		end
		if not session.stats then
			session.stats = {}
		end
		if session.stats["current"] then
			session.stats["last"] = session.stats["current"]
		else
			session.stats["last"] = 0
		end
		session.stats["cap"] = session.wrap[1].getMaxEnergyStored() * session.amount
		session.stats["current"] = session.wrap[1].getEnergyStored() * session.amount
		displayTerm()
		if session.monitors and #cv.peripheral.getGroup("monitors") > 0 then displayMon() end
	end

	function bankConnect()
		session.wrap = cv.peripheral.getAllWraps("tile_blockcapacitorbank_name")
		if #session.wrap < 1 then
			body.lines = {
				"No Capacitors Can Be Found",
				"",
				"I cannot find any capacitor banks!"
			}
		elseif #session.wrap > 1 then
			body.lines = {
				"Multiple Capacitors Found",
				"",
				"I don't support multiple capacitors yet",
				"",
				"Please remove all but one bank"
			}
		else
			-- Get information about the capacitors.
			title.text = "Connected To Bank"
			body.lines = {
				"Retrieving information from capacitors"
			}
			cv.setTimer("updatetimer", 0.5, function( self )
				-- Update monitors and terminal
				update()
				cv:bufferDraw()
			end, true)
		end
	end
	cv.startEventLoop(function()
		cv.eventRegister("peripheral", function()
			cv.peripheral.setGroup( cv.peripheral.getAllWraps("monitor"), "monitors")
		end)
		cv.setTimer("updatetimer", 0, function( self )
			-- Update monitors and terminal
			cv:bufferDraw()
		end, true)
		cv.addToBufferOnCreation = true
		-- Program started. Create onscreen text/buttons
		title = cv.textLine({
			text="Circum Capacitor Bank",
			textColor = gc("orange"),
			backgroundColor = gc("white"),
			center = true,
			y = 6
		})
		body = cv.textBlock({
			lines={
				"Connecting to peripherals",
				"",
				"Please Wait..."
			},
			center = true,
			y = 10,
			textColor = gc("gray"),
			backgroundColor = gc("white")
		})
		cv.addToBufferOnCreation = false
		bankConnect()
		cv:bufferDraw()
		cv.peripheral.setGroup(cv.peripheral.getAllWraps("monitor"), "monitors")
	end)
end

function loadSettings()
	if not fs.exists( "capbank.cfg" ) then
		-- No config, launch setup
		config()
	else
		session = textutils.unserialize(cv.file.read("capBank.cfg"))
		start()
	end
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
		if not err then nativeError("Unknown Error") end
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

local _, err = pcall(loadSettings)
error( err, 4)