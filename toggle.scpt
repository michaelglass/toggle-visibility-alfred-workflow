use AppleScript version "2.4" -- OS X 10.10 (Yosemite) or later
use framework "Foundation"
use scripting additions

-- Define the log file path
set logFilePath to (path to desktop folder as text) & "AppleScript_Log.txt"
set logFilePathPOSIX to POSIX path of logFilePath

-- Function to get current time in milliseconds (high precision using NSDate)
on getTimeMillis()
	set now to current application's class "NSDate"'s |date|()
	set timeSinceEpochSeconds to now's timeIntervalSince1970()
	return (timeSinceEpochSeconds * 1000) as real
end getTimeMillis

-- Global (or script-level) variable to hold the overall start time in milliseconds
-- It's best practice to initialize properties at the top, but the first logMessage will set it if it's 0.0
property scriptStartTimeMillis : 0.0
set scriptStartTimeMillis to my getTimeMillis()

-- Function to append text to the log file with elapsed time
on logMessage(messageText, filePath)
	-- Calculate elapsed time from the very start of the script
	set currentTimeMillis to my getTimeMillis()
	set elapsedTimeMillis to (currentTimeMillis - scriptStartTimeMillis)
	-- Round elapsed time to 3 decimal places for readability
	set roundedElapsedTime to (round (elapsedTimeMillis * 1000)) / 1000.0

	set logEntry to "[+" & roundedElapsedTime & " ms] " & messageText
    do shell script "echo " & quoted form of logEntry & " >> " & quoted form of filePath
end logMessage

my logMessage("Script started.", logFilePathPOSIX)

set appPath to "/Applications/WezTerm.app"
set target to POSIX file appPath as alias

-- Dynamically get the bundle ID
my logMessage("Attempting to get WezTerm's bundle ID dynamically...", logFilePathPOSIX)
set wezTermBundleID to ""
try
	-- Note: mdls still uses a shell script, but it's for metadata, not timing.
	set appBundleIDCommand to "mdls -name kMDItemCFBundleIdentifier -r " & quoted form of (POSIX path of appPath)
	set wezTermBundleID to (do shell script appBundleIDCommand)
	my logMessage("Dynamically retrieved WezTerm Bundle ID: " & wezTermBundleID, logFilePathPOSIX)
on error errMsg number errNum
	my logMessage("Failed to get WezTerm Bundle ID dynamically: " & errMsg & " (" & errNum & "). Falling back to hardcoded.", logFilePathPOSIX)
	set wezTermBundleID to "com.github.wezterm" -- Fallback to hardcoded if dynamic fails
end try

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
