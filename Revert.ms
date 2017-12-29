/*
	Revert.ms
	Version: 2.5
	Created On: December 05, 2002
	Created By: Jeff Hanna
	Modified On: August 19, 2003 
	Modified By: Jeff Hanna
	tested using Max 5.1 (SP1)

	© Copyright 2003, Lodestone Games, LLC. All Rights Reserved.

	Discards all changes to the Max scene, resets Max, and synchronizes the user's machine with the most recently checked in version
	of the Max scene that is in the version control archive.
	

	v2.5 - If bVCEditTextures is enabled (e.g. textures checked out) Revert will know to revert them also.
	
	v2.4 - Dead development tree, version number skipped.
	v2.3 - Changed file check to use VCGetFileStats() instead of relying on the temp files on the harddisk.
	v2.2 - Converted back to my bitmap finding functions for all max versions. The new functions in Max5 aren't as robust.
	v2.1 - Added a section to switch the menu ghost variables to flase when the file is added.	
	v2.0 - Utilized the VCParseCommandResults & VCWriteCommandResults functions in VersionControlLib.ms to display results of the Revert to the user.
			Removed the two included library files. All functions are now made global when those two files are loaded at startup.
	v1.51 - Updated variable names to follow programming guidelines.
	v1.5 - Added confirmation dialog to the script.
	v1.4 - Changed name from "RevertScene" to "Revert". Changed function names to reflect overal package renaming from "Source Control" to "Version Control".
	v1.3 - Copyright Information added.
	v1.2 - Resetting the peristent global variables, "pg_strMaxFilepath" and, "pg_strMapsFilepath" at the end of the script.
	v1.1 - Initial release.
*/

(
	--LOCAL VARIABLES
	-----------------
	local strRevertVersion = "2.5" as string								-- Version number for display in the Max Listener window
	local bConfirm = false														-- Boolean to determine if the user really wants to revert.
	local strMaxScene = (maxFilePath + maxFileName) as string		-- String variable to hold the entire path+file name of the max scene.

	aAllMaps = #()
	aOtherMaps = #()
	aFilesToRevert = #()


	--GLOBAL VARIABLES
	------------------
	global strCommandResults = "" as stringStream


	--INCLUDED FILES
	----------------


	--MAIN LOOP
	-----------
	-- print version information to the listener. Useful if a bug-report needs to be sent.
	print ("RevertScene, v" + strRevertVersion + " loaded.")

	-- Delete the stored last command history.
	deleteFile "$temp\\LastCommand.txt"

	local strCheckedOutByName = VCGetFileStats strMaxScene
	
	if strUserName != strCheckedOutByName then
	(
		messagebox "You do not have this scene checked out from the version control archive.\nThis scene can not be reverted." title:"Version Control"
	)
	else
	(
		bConfirm = querybox "This will discard all changes and revert your local depot to the last checked in version.\nDo you want to do this?" title:"Version Control"
		
		if bConfirm == true then
		(
			-- Get the location of the max scene in the depot and add it to the array that will be passed to the revert function
			append aFilesToRevert strMaxScene
			
			if bVCEditTextures == true then
			(
				-- Traverse the node tree in the scene and gather all maps used.
				-- Find both maps assigned to materials and those that aren't.
			 	aAllMaps = GetSceneMaps()
			 	aOtherMaps = GetOtherMaps()
			  	aAllMaps = aAllMaps + aOtherMaps
	
				-- Get the bitmap names and file paths from the list of maps you just made.
				aFilesToRevert = GetBitmapsFromMaps aAllMaps
	
				-- Remove any duplicate entries.
				RemoveDuplicates aFilesToRevert
			)

			-- Forcing a revert on all files will cause P4 to revert any file that is unchanged
			VCRevertAll aFilesToRevert

			-- Parse the results of the revert command so they can be displayed.
			VCParseCommandResults "VCRevert.txt"

			-- Possibly display the results of the version control system operations in a dialog.
			if bVCShowResults == true then
			(
				messagebox strCommandResults title:"Version Control" beep:false
			)

			-- Save the command results to a disk file for possible later reference.
			VCWriteCommandResults()

			-- Clean up all temporary disk files that were created when the scene was checked out.
			VCCleanup()

			-- Set these boolean global variables to false so the associated menu commands ghost.
			bEnableAddNew = true
			bEnableCheckIn = false
			bEnableRevert = false
			bEnableView = true

			-- Reset the max file to prevent any further editing of the file.
			resetMaxFile #noPrompt
		)
	)
)