set appPath to "/Applications/WezTerm.app"

use AppleScript version "2.4" -- OS X 10.10 (Yosemite) or later
use framework "Foundation"
use scripting additions

set target to POSIX file appPath as alias

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
else
	error "Could not get NSBundle for application path: " & appPath
end if

set appIsRunning to false -- Flag to track if the app is found running by System Events

tell application "System Events"
	-- Try block to handle cases where the process doesn't exist
	try
		set wezTermProcess to process appShortName
		-- If no error, the process exists
		set appIsRunning to true

		if visible of wezTermProcess is true then
			set visible of wezTermProcess to false -- Set visible to false via System Events
		else
			-- Using the System Events process object's frontmost property is usually reliable here
			set frontmost of wezTermProcess to true
		end if
	on error
		-- Process not found
		set appIsRunning to false
	end try
end tell -- End of System Events tell block

-- Now, perform actions based on the flag set by System Events
if appIsRunning is false then
	tell application appPath to activate -- Launch using appPath, activate brings to front
end if
