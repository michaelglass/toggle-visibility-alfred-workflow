-- Define the log file path
set logFilePath to (path to desktop folder as text) & "AppleScript_Log.txt"
set logFilePathPOSIX to POSIX path of logFilePath

-- Function to append text to the log file
on logMessage(messageText, filePath)
	set dateStamp to (current date) as string
	set logEntry to "-- " & dateStamp & ": " & messageText & return
	do shell script "echo " & quoted form of logEntry & " >> " & quoted form of filePath
end logMessage

-- Function to get current time in nanoseconds (high precision)
on getNanoseconds()
	-- %s = seconds since epoch
	-- %N = nanoseconds (000000000-999999999)
	return (do shell script "date +%s%N") as real
end getNanoseconds

-- Start timing (high precision)
set startTimeNano to my getNanoseconds()
my logMessage("Script started. at " & startTimeNano, logFilePathPOSIX)

set appPath to "/Applications/WezTerm.app"
set target to POSIX file appPath as alias

set appIsRunning to false -- Flag to track if the app is found running by System Events
set appWasVisible to false -- Flag to track if the app was visible when found

-- First, check running processes with System Events
tell application "System Events"
	set ps to (every process whose background only is false)

	repeat with i in ps
		set p to POSIX path of file of i
		set p to POSIX file p as alias
		if p is target then
			set appIsRunning to true
			if visible of i is true then
				set appWasVisible to true
				my logMessage("WezTerm is visible, setting to hide.", logFilePathPOSIX)
				set visible of i to false -- Set visible to false via System Events
			else
				my logMessage("WezTerm is running but not visible, setting to bring to front.", logFilePathPOSIX)
				set frontmost of i to true -- Set visible to false via System Events
				-- We'll handle activation outside this block for robustness
			end if
			exit repeat -- Found it, so no need to check other processes
		end if
	end repeat
end tell -- End of System Events tell block

-- Now, perform actions based on the flags set by System Events
if appIsRunning is false then
	-- If the application was not found in the running processes, launch it
	my logMessage("WezTerm not found in running processes. Attempting to launch.", logFilePathPOSIX)
	-- Simplified launch using only direct 'activate'
	try
		tell application appPath to activate
		my logMessage("WezTerm launched via direct 'activate'.", logFilePathPOSIX)
	on error errMsg number errNum
		my logMessage("Failed to launch WezTerm via direct 'activate': " & errMsg & " (" & errNum & ").", logFilePathPOSIX)
	end try
end if

my logMessage("Script finished", logFilePathPOSIX)
-- End timing and log duration in milliseconds (high precision)
set endTimeNano to my getNanoseconds()
set durationSeconds to (endTimeNano - startTimeNano) / 1000000000

my logMessage("Duration: " & durationSeconds & " seconds.", logFilePathPOSIX)
