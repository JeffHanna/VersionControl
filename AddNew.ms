/*
	AddNew.ms
	Version: 2.51
	Created On: November 23, 2002
	Created By: Jeff Hanna
	Modified On: August 28, 2003 
	Modified By: Jeff Hanna
	tested using Max 5.1 (SP1)

	© Copyright 2003, Lodestone Games, LLC. All Rights Reserved.

	Adds a new Max scene and any new bitmaps used in that scene to the version control archive.
	The files are added in a locked state, to prevent the scene from being checked out of version control by more than one user
	at a time.


	v2.51 - Fixed variable scope on the rltGetDescription dialog. Improper scope was causing the scripts to break on Max 4.2x.
	
	v2.5 - Added checking for the bVCEnableReset variable to control if the scene is reset or not.
	v2.4 - Dead development tree, version number skipped.
	v2.31 - Fixed the "ReOpen" code to work properly.
	v2.3 - Changed from using the persistent global variables to using P4 fstat to check if the file exists.
			Now ghosts any menu commands that are not proper after this script has finished.
	v2.2 - Changed all VCSubmitAndReOpen() function calls to VCSubmit() function calls to reflect changes in VersionControlLib.ms
			Changed all VCSyncAndCheckOut() function calls to VCSync() function calls to reflect changes in VersionControlLib.ms
			Removed the local aMaxVersion array. The script now uses the global version of that array.
	v2.1 - Added a section to switch the menu ghost variables to false when the file is added.
			Removed the Max4/Max5 codepaths for bitmap discovery. Max 5's function doesn't work as well as my code.
	v2.0 - Utilized the VCParseCommandResults & VCWriteCommandResults functions in VersionControlLib.ms to display results of the AddNew to the user.
			Removed the two included library files. All functions are now made global when those two files are loaded at startup.
			(Max 5 only) Changes the title bar to show the status of the file in Version Control after it has been added.
			(Max 5 only) Uses the new usedMaps() command to find all bitmaps. This replaces the node-tree walking code I wrote to
			do the same thing. That code is still used if the scripts are run on Max 4.
	v1.71 - Changed variable names to follow the programming guidelines.
	v1.7 - Changed name from "SaveAsToSourceControl" to "AddNew". All "Source Control" and "SC" references changed to "Version Control
	       and "VC".  Changed function call "ConvertArray" to "ConvertArrayDOS2Unix" to reflect the change made in LSUtilLib
	v1.6 - Fixed a bug with a misnamed variable that was breaking the script.
	v1.5 - Copyright information added.
	v1.4 - Switched from storing strMaxFileToEdit and strStartMapsFile in the FileProperties page to storing them in the persistent
	       global variables, "pg_strMaxFilepath" and, "pg_strMapsFilepath".
	v1.3 - Changed the function call "ConvertArrays" to "ConvertArray" to reflect the change made in LSUtilLb.
	v1.2 - Initial release.
*/

(
	--LOCAL VARIABLES
	-----------------
	local strAddNewVersion = "2.51" as string	-- Version number for display in the Max Listener window
	local bExit = false							-- Boolean to control whether the script should exit or not.
	local bReOpen = false						-- Boolean to indicate whether the user wants to immediately re-open the file.
	local bExists = false							-- Boolean to indicate if the file already exists or not.

	aAllMaps = #()
	aOtherMaps = #()
	aPathnames = #()
	aAllPathnames = #()
	aFilesToSubmit = #()
	aFilesToCheckOut = #()


	--GLOBAL VARIABLES
	------------------
	global rltGetDescription
	global strCommandResults = "" as stringStream
	strChangeDescription = ""


	--INCLUDED FILES
	----------------


	--ROLLOUTS
	----------
	-- The change lists are more useful with user-entered descriptions about what was done during the edit session.
	rollout rltGetDescription "Version Control"
	(
		label lblWhatFor "Please enter a change description for this scene."
		editText edtUserEntry
		button btnOK "OK" enabled:false

		on edtUserEntry changed strEntry do
		(
			strChangeDescription = edtUserEntry.text
			btnOK.enabled = true
		)
		on btnOK pressed do
		(
			destroyDialog rltGetDescription
		)
	)


	--MAIN LOOP
	-----------
	-- print version information to the listener. Useful if a bug-report needs to be sent.
	print ("AddNew, v" + strAddNewVersion + " loaded.")

	-- Delete the stored last command history.
	deleteFile "$temp\\LastCommand.txt"

	-- This script is executed as a do-while loop so that it can be exited at any time
	do
	(
		-- Check to see if the file is empty. If so, abort the add process.
		if getSaveRequired() == false and maxFileName == "" then
		(
			bExit = true
			exit
		)

		-- Check the properties of the file to see if it is already under version control. 
		bExists = VCFstatExists (maxFilePath + maxFileName)
		
		--If it already exists, it can not be added a second time.
		if bExists == true then
		(
			-- If the variable exits, then this file is already in source control. It can't be added a second time.
			-- Alert the user and exit the script.
			messagebox "It appears that this scene already exists in the version control archive.\nThis scene cannot be added a second time." title:"Version Control" beep:false

			bExit = true
			exit
		)
		-- If it doesn't exist add it and check it in.
		else
		(
			-- If no filename exists, prompt the user for a name and location to save.
			if getSaveRequired() == true and maxFileName == "" then
			(
				-- If the user cancels the save-as then exit this script
				if getMaxSaveFilename() == undefined then
				(
					bExit = true
					exit
				)
			)
			-- If the filename does exist, save the file.
			else
			(
				if getSaveRequired() == true and maxFileName != "" then
				(
					saveMaxFile (maxFilePath + maxFileName)
				)
			)
		
			-- The user needs to enter a description of the changes and decide if they want to close the scene.
			createDialog rltGetDescription width:250 modal:true
			bReOpen = querybox "Would you like to reopen the scene and continue to work on it?" title:"Version Control" beep:false

			-- Get a list of all maps used in the scene
			aAllMaps = GetSceneMaps()
			aOtherMaps = GetOtherMaps()
			aAllMaps = aAllMaps + aOtherMaps

			-- Get the bitmap file paths from the maps and then remove any duplicate entries.
			aPathnames = GetBitmapsFromMaps aAllMaps

			-- Get rid of duplicate entries in the array
			RemoveDuplicates aPathnames

			-- The Max scene wouldn't be included in the Submit function if it's path and name weren't retrieved and added to the array.
			append aPathnames (maxFilePath + maxFileName)
			
			-- Forcing a revert on all files will cause the source control system to revert any file that is unchanged
			VCRevertUnchanged aPathnames
			
			-- Parse the results of the revert and add the reverted files to an array so they can be re-checked out if the user chooses to re-open the scene
			local fileIn = openFile "$temp\\VCRevert.txt" mode:"r"
			while not eof fileIn do
			(
				sTempString = readDelimitedString fileIn "#"
				append aFilesToCheckOut sTempString
				skipToNextLine fileIn
			)
			close fileIn
						
			-- Add all new files to the source control archive.
			VCAdd aPathnames
			
			-- Convert the path names to Unix style relative pathing.
			aPathnames = ConvertArrayDOS2UNIX aPathnames

			-- Check the changelist after the revert and build an array, "aFilesToSubmit" from what's left.
			aFilesToSubmit = VCGetOpenedFiles aPathnames

			-- Check to see if the user wanted to continue editng the file
			if bReOpen == false then
			(
				-- If not, then submit the files. Pass and array of files and a boolean indicating 
				-- whether the submitted files should be reopened or not.
				VCSubmit aFilesToSubmit false

				-- Parse the results of the submit command so they can be displayed.
				VCParseCommandResults "VCAdd.txt"
				VCParseCommandResults "VCRevert.txt"
				VCParseCommandResults "VCSubmit.txt"

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
				bVCEnableCheckIn = false
				bVCEnableAddNew = true
				bVCEnableRevert = false
				bVCEnableView = true

				-- If requested, reset Max to prevent further editing of the file.
				if bVCEnableReset == true then resetMaxFile #noPrompt
				else
				(
					-- Max 5 - change the titlebar of the app to show the version control status.
					if iVCMaxVersion >= 5000 then cui.setAppTitle (maxFilePath + MaxFilename + " - NOT CHECKED OUT FROM VERSION CONTROL. OPENED AS READ ONLY.")
				)

				-- Exit the script
				bExit = true
				exit
			)
			else -- bReOpen == true
			(
				-- If they did want to continue editing, submit the files and
				-- immediately check them out again from the source control archive.
				VCSubmit aFilesToSubmit true

				-- Re-check out the reverted files
				WriteFile aFilesToCheckOut "$temp\\TempSync.txt" --strTextFile
				strDOSEditFile = DOSTempPath "$temp\\TempSync.txt" 1 5
				DOSCommand ("p4 -x " + strDOSEditFile + " edit > %temp%\\VCEdit.txt")
				deleteFile "$Temp\\TempSync.txt"

				-- Parse the results of the submit and Sync commands so they can be displayed.
				VCParseCommandResults "VCAdd.txt"
				VCParseCommandResults "VCRevert.txt"
				VCParseCommandResults "VCSubmit.txt"
				VCParseCommandResults "VCEdit.txt"

				-- Possibly display the results of the version control system operations in a dialog.
				if bVCShowResults == true then
				(
					messagebox strCommandResults title:"Version Control" beep:false
				)

				-- Save the command results to a disk file for possible later reference.
				VCWriteCommandResults()

				-- Max 5 - change the titlebar of the app to show the version control status.
				if aMaxVersion[1] >= 5000 then
				(
					cui.setAppTitle (maxFilePath + MaxFilename + " - CHECKED OUT FROM VERSION CONTROL")
				)

				-- Clean up all temporary disk files that were created when the scene was checked out.
				VCCleanup()

				-- Set these boolean global variables to false so the associated menu commands un-ghost.
				bEnableCheckIn = true
				bEnableAddNew = false
				bEnableRevert = true
				bEnableView = true
				
				-- Exit the script
				bExit = true
				exit
			)
		)
	)
	while bExit == false
)