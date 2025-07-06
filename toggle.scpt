-- Define the log file path
set logFilePath to (path to desktop folder as text) & "AppleScript_Log.txt"
set logFilePathPOSIX to POSIX path of logFilePath

-- Global (or script-level) variable to hold the overall start time in nanoseconds
property scriptStartTimeNano : 0.0

-- Function to get current time in nanoseconds (high precision)
on getNanoseconds()
	-- %s = seconds since epoch
	-- %N = nanoseconds (000000000-999999999)
	return (do shell script "date +%s%N") as real
end getNanoseconds

-- Function to append text to the log file with elapsed time
on logMessage(messageText, filePath)
	-- Calculate elapsed time from the very start of the script
	set currentTimeNano to my getNanoseconds()
	set elapsedTimeMillis to (currentTimeNano - scriptStartTimeNano) / 1000000
	-- Round elapsed time to 3 decimal places for readability
	set roundedElapsedTime to (round (elapsedTimeMillis * 1000)) / 1000.0

	set logEntry to "[+" & roundedElapsedTime & " ms] " & messageText & return
	do shell script "echo " & quoted form of logEntry & " >> " & quoted form of filePath
end logMessage


-- Initialize the overall script start time
set scriptStartTimeNano to my getNanoseconds()
my logMessage("Script started.", logFilePathPOSIX)

set appPath to "/Applications/WezTerm.app"
set target to POSIX file appPath as alias

-- *** NEW: Dynamically get the bundle ID ***
my logMessage("Attempting to get WezTerm's bundle ID dynamically...", logFilePathPOSIX)
set wezTermBundleID to ""
try
	set appBundleIDCommand to "mdls -name kMDItemCFBundleIdentifier -r " & quoted form of (POSIX path of appPath)
	set wezTermBundleID to (do shell script appBundleIDCommand)
	my logMessage("Dynamically retrieved WezTerm Bundle ID: " & wezTermBundleID, logFilePathPOSIX)
on error errMsg number errNum
	my logMessage("Failed to get WezTerm Bundle ID dynamically: " & errMsg & " (" & errNum & "). Falling back to hardcoded.", logFilePathPOSIX)
	set wezTermBundleID to "com.github.wezterm" -- Fallback to hardcoded if dynamic fails
end try
-- *** END NEW ***

set appIsRunning to false -- Flag to track if the app is found running by System Events

my logMessage("Attempting direct System Events check for WezTerm process...", logFilePathPOSIX)

-- Directly check for the WezTerm process by its bundle ID
tell application "System Events"
	-- Try block to handle cases where the process doesn't exist
	try
		-- Using 'bundle identifier' property of 'process' is generally preferred
		set wezTermProcess to first process whose bundle identifier is wezTermBundleID
		-- If no error, the process exists
		set appIsRunning to true
		my logMessage("System Events: WezTerm process found directly.", logFilePathPOSIX)

		if visible of wezTermProcess is true then
			my logMessage("System Events: WezTerm process visible. Hiding it.", logFilePathPOSIX)
			set visible of wezTermProcess to false -- Set visible to false via System Events
		else
			my logMessage("System Events: WezTerm process running but not visible. Activating it.", logFilePathPOSIX)
			-- Using the System Events process object's frontmost property is usually reliable here
			set frontmost of wezTermProcess to true
		end if
	on error
		-- Process not found
		set appIsRunning to false
		my logMessage("System Events: WezTerm process not found (not running).", logFilePathPOSIX)
	end try
end tell -- End of System Events tell block

-- Now, perform actions based on the flag set by System Events
if appIsRunning is false then
	-- If the application was not found in the running processes, launch it
	my logMessage("WezTerm not found running. Attempting to launch.", logFilePathPOSIX)
	try
		tell application appPath to activate -- Launch using appPath, activate brings to front
		my logMessage("WezTerm launched via direct 'activate'.", logFilePathPOSIX)
	on error errMsg number errNum
		my logMessage("Failed to launch WezTerm via direct 'activate': " & errMsg & " (" & errNum & ").", logFilePathPOSIX)
	end try
end if

my logMessage("Script finished.", logFilePathPOSIX)
