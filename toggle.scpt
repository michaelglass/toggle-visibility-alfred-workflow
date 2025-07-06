use AppleScript version "2.4" -- OS X 10.10 (Yosemite) or later
use framework "Foundation"
use scripting additions

-- Define the log file path
set logFilePath to POSIX path of (path to desktop folder as text) & "AppleScript_Log.txt"

-- Function to get current time in milliseconds (high precision using NSDate)
on getTimeMillis()
	set now to current application's class "NSDate"'s |date|()
	set timeSinceEpochSeconds to now's timeIntervalSince1970()
	return (timeSinceEpochSeconds * 1000) as real
end getTimeMillis


-- Global (or script-level) variable to hold the overall start time in milliseconds
-- It's best practice to initialize properties at the top, but the first logMessage will set it if it's 0.0

property DEBUG : true -- Set to 'true' for logging, 'false' to disable all log messages.
property scriptStartTimeMillis : 0.0
if DEBUG then
    set scriptStartTimeMillis to my getTimeMillis()
end if

on privateLogToFile(entryText, filePath)
	set fm to current application's NSFileManager's defaultManager()
	set fileHandle to current application's NSFileHandle
	set nsStringClass to current application's NSString

	set fileExists to fm's fileExistsAtPath:filePath
	set logEntryNSString to (nsStringClass's stringWithString:(entryText & (ASCII character 10)))
	set logEntryData to logEntryNSString's dataUsingEncoding:(current application's NSUTF8StringEncoding)

	if fileExists then
		-- Open file for appending
		set fh to fileHandle's fileHandleForWritingAtPath:filePath
		if fh is not missing value then
			fh's seekToEndOfFile() -- Move to the end of the file
			fh's writeData:logEntryData -- Write the new data
			fh's closeFile() -- Close the file handle
		else
			-- This means fileHandleForWritingAtPath returned nil (missing value), indicating it couldn't open for writing
			-- This error will now propagate out of the try block
			error "Could not get file handle for writing to log file at path: " & filePath
		end if
	else
		-- If file doesn't exist, create it and write the first line
		logEntryData's writeToFile:filePath atomically:false
	end if
end privateLogToFile

-- Function to append text to the log file with elapsed time
on logMessage(messageText, filePath)
    if DEBUG is false then
        return
    end if
	-- Calculate elapsed time from the very start of the script
	set currentTimeMillis to my getTimeMillis()
	set elapsedTimeMillis to (currentTimeMillis - scriptStartTimeMillis)
	-- Round elapsed time to 3 decimal places for readability
	set roundedElapsedTime to (round (elapsedTimeMillis * 1000)) / 1000.0

	set logEntry to "[+" & roundedElapsedTime & " ms] " & messageText
    -- do shell script "echo " & quoted form of logEntry & " >> " & quoted form of filePath
    privateLogToFile(logEntry, filePath)
end logMessage

my logMessage("Script started.", logFilePath)

set appPath to "/Applications/WezTerm.app"
set target to POSIX file appPath as alias

my logMessage("Attempting to get application's short name dynamically (Foundation method)...", logFilePath)
set appShortName to ""
set nsBundleClass to current application's NSBundle
set appURL to current application's NSURL's fileURLWithPath:appPath

set appBundle to nsBundleClass's bundleWithURL:appURL

if appBundle is not missing value then
	-- Prefer CFBundleDisplayName if available, otherwise fall back to CFBundleName
	set displayName to appBundle's objectForInfoDictionaryKey:("CFBundleDisplayName")
	if displayName is not missing value then
		set appShortName to displayName as text
	else
		set appShortName to (appBundle's objectForInfoDictionaryKey:("CFBundleName")) as text
	end if
	my logMessage("Dynamically retrieved App Short Name: " & appShortName & " (Foundation)", logFilePath)
else
	error "Could not get NSBundle for application path: " & appPath
end if

set appIsRunning to false -- Flag to track if the app is found running by System Events

my logMessage("Attempting direct System Events check for WezTerm process...", logFilePath)

tell application "System Events"
	-- Try block to handle cases where the process doesn't exist
	try
		set wezTermProcess to process appShortName
		-- If no error, the process exists
		set appIsRunning to true
		my logMessage("System Events: WezTerm process found directly.", logFilePath)

		if visible of wezTermProcess is true then
			my logMessage("System Events: WezTerm process visible. Hiding it.", logFilePath)
			set visible of wezTermProcess to false -- Set visible to false via System Events
		else
			my logMessage("System Events: WezTerm process running but not visible. Activating it.", logFilePath)
			-- Using the System Events process object's frontmost property is usually reliable here
			set frontmost of wezTermProcess to true
		end if
	on error
		-- Process not found
		set appIsRunning to false
		my logMessage("System Events: WezTerm process not found (not running).", logFilePath)
	end try
end tell -- End of System Events tell block

-- Now, perform actions based on the flag set by System Events
if appIsRunning is false then
	my logMessage("WezTerm not found running. Attempting to launch.", logFilePath)
	tell application appPath to activate -- Launch using appPath, activate brings to front
	my logMessage("WezTerm launched via direct 'activate'.", logFilePath)
end if

my logMessage("Script finished.", logFilePath)
