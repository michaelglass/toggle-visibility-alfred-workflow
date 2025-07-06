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

tell application "System Events"
	set ps to (every process whose background only is false)

	set appFound to false
	repeat with i in ps
		set p to POSIX path of file of i
		set p to POSIX file p as alias
		if p is target then
			set appFound to true
			if frontmost of i then
				my logMessage("WezTerm is frontmost, hiding it.", logFilePathPOSIX)
				set visible of i to false
			else
				my logMessage("WezTerm is not frontmost, bringing it to front.", logFilePathPOSIX)
				set frontmost of i to true
                tell application appPath to activate
			end if
			exit repeat -- Exit the loop once found
		end if
	end repeat

	if not appFound then
		my logMessage("WezTerm not found in running processes.", logFilePathPOSIX)
	end if
end tell

my logMessage("Script finished", logFilePathPOSIX)
-- End timing and log duration in milliseconds (high precision)
set endTimeNano to my getNanoseconds()
set durationSeconds to (endTimeNano - startTimeNano) / 1000000000

my logMessage("Duration: " & durationSeconds & " seconds.", logFilePathPOSIX)
