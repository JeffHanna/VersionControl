/*
	View.ms
	Version: 2.5
	Created On: November 23, 2002
	Created By: Jeff Hanna
	Modified On: August 19, 2003 
	Modified By: Jeff Hanna
	tested using Max 5.1 (SP1)

	© Copyright 2003 Lodestone Games, LLC. All Rights Reserved.

	Synchronizes a max scene and the bitmaps in it to the latest versions located in version control,
	The file is then opened in Max without being checked out from the version control archive. This is useful for times when
	a user wants to look at the latest version of a file without making changes to it.


	v2.5 - Fixed a bug with regards to VCSync() being passed an incorrect number of parameters.
	
	v2.4 - Dead development tree, version number skipped.
	v2.3 - Reworked to use P4 fstat to check status of a file. This is much more fault tolerant than the old "temp file on hard disk" setup.
	v2.2 -Renamed all VCSyncAndCheckOut() functions to VCSync() to relfect the update in VersionControlLib.ms
			Removed the local aMaxVersion array. The script now uses the global version of that array.
	v2.1 - Changed back from seperate Max R4/R5 bitmap discovery code paths to a unified code path. Max R5's usedMaps()
			function isn't as thorough as mine.
	v2.0 - Utilized the VCParseCommandResults & VCWriteCommandResults functions in VersionControlLib.ms to display results of the View to the user.
			Removed the two included library files. All functions are now made global when those two files are loaded at startup.
			(Max 5 only) Changes the title bar to show the status of the file in Version Control after it has been loaded.
			(Max 5 only) Uses the new usedMaps() command to find all bitmaps. This replaces the node-tree walking code I wrote to
			do the same thing. That code is still used if the scripts are run on Max 4.
	v1.41 - Changed the variable names to follow the programming guidelines.
	v1.4 - Changed name from "ViewFromSourceControl" to "View". All "Source Control" and "SC" references changed to "Version Control and "VC"
	v1.3 - Copyright information added.
	v1.2 - Initial release.
*/

(
	--LOCAL VARIABLES
	-----------------
	local strViewVersion = "2.4" as string		-- Version number for display in the Max Listener window
	local strFileToOpen = "" as string			-- The max file that should be loaded
	local strStartMapsFile = "" as string		-- The text file containing the bitmap names to be sync'd in P4.

	aAllMaps = #()
	aOtherMaps = #()
	aStartMapPathnames = #()
	aMaxFile = #()


	--GLOBAL VARIABLES
	------------------
	global strCommandResults = "" as stringStream


	--INCLUDED FILES
	----------------


	--MAIN LOOP
	-----------
	-- Delete the stored last command history.
	deleteFile "$temp\\LastCommand.txt"

	-- print version information to the listener. Useful if a bug-report needs to be sent.
	print ("View, v" + strViewVersion + " loaded.")

	-- Set this boolean so the #postFileOpen callback doesn't trigger the VCOpenFileCheck function
	bPerformOpenFileCheck = false

	-- Ask the user for the name of the max scene they'd like to open.
	strFileToOpen = getMaxOpenFileName types:"3ds max(*.max)|*.max|All|*.*|"


	-- Check to make sure the scene isn't already open for edit in the source control app.
	if strFileToOpen != undefined then
	(
		-- Add the name of the max scene to that array
		append aStartMapPathnames strFileToOpen

		-- Create a string containing the full DOS path of the file to be submitted to the source control system.
		strStartMapsFile = ("$temp\\" + (getFilenameFile strFileToOpen) + "_StartMaps.txt")

		-- Ask the source control system to sync all of the files listed in that file
		-- Yes, it's empty at the moment, but the SCSync function requires two variables as input.
		-- This syncs the Max scene.
		VCSync aStartMapPathnames false

		-- load the max scene
		loadMaxFile strFileToOpen

		-- Traverse the node tree in the scene and gather all maps used.
		-- Find both maps assigned to materials and those that aren't.
		aAllMaps = GetSceneMaps()
		aOtherMaps = GetOtherMaps()
		aAllMaps = aAllMaps + aOtherMaps

		-- Get the bitmap names and file paths from the list of maps you just made.
		-- disable for max 5 version
		aStartMapPathnames = GetBitmapsFromMaps aAllMaps
	 	
		-- Remove any duplicate entries.
		RemoveDuplicates aStartMapPathnames

		-- Now sync to the latest version and check out those files files from source control
		VCSync aStartMapPathnames strStartMapsFile false

		--Force a refresh of all maps in the scene so that any that were updated by the sync become visible.
		freeSceneBitmaps()

		-- Max 5 - change the titlebar of the app to show the version control status.
		if aMaxVersion[1] >= 5000 then
		(
			cui.setAppTitle (maxFilePath + MaxFilename + " - READ ONLY.")
		)

		-- Read in the output from the version control system and add it to a stringstream so it can be displayed.
		VCParseCommandResults "VCSync.txt"

		-- Save the command results to a disk file for possible later reference.
		VCWriteCommandResults()

		-- Clean up the temporary disk file used in the synchronization process.
		deleteFile strStartMapsFile

		-- Set these boolean global variables to true so the associated menu commands un-ghost.
		bEnableCheckIn = false
		bEnableRevert = false
		bEnableView = true
		bEnableAddNew = false
			
		-- Clean up all temporary disk files that were created when the scene was checked out.
		VCCleanup()
	)

	-- Set this boolean so the #postFileOpen callback will check files opened from the normal File/Open menu.
	bPerformOpenFileCheck = true
)