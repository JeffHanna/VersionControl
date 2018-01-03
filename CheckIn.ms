/*
	CheckIn.ms
	Version: 2.52
	Created On: November 23, 2002
	Created By: Jeff Hanna
	Modified On: January 03, 2018
	Modified By: Jeff Hanna
	tested using 3ds Max 2016

	© Copyright 2003, Lodestone Games, LLC. All Rights Reserved.

	Checks a previously checked out Max scene back into the version control archive.


	v2.52 - Updated so the VC* calls to global functions are now VersionControlLib.VC* calls 
				as that library has properly been made a struct with local functions.
	
	v2.51 - Fixed variable scope on the rltGetDescription dialog. Improper scope was causing the scripts to break on Max 4.2x.	
	v2.5	- Added checking the bVCEnableReset to control whether max is reset after a check in.
	v2.4	- Dead development tree, version number skipped.
	v2.31 - Fixed the submit and reopen code so that files were reopened properly and any file that was "revert unchanged" was re-checked out if the user
				selects the re-open option.
	v2.3  - Changed from using the persistent global variables to using P4 fstat to check if the file exists.
				Now ghosts any menu commands that are not proper after this script has finished. 
	v2.2	- Changed all VCSubmitAndReOpen() function calls to VCSubmit() function calls.
				Removed the local aMaxVersion array. The script now uses the global version of that array.
	v2.1 	- Added a section to switch the menu ghost variables to false when the file is added.
				Removed the Max4/Max5 codepaths for bitmap discovery. Max 5's function doesn't work as well as my code.
	v2.0	- Utilized the VCParseCommandResults & VCWriteCommandResults functions in VersionControlLib.ms to display results of the CheckIn to the user.
				Removed the two included library files. All functions are now made global when those two files are loaded at startup.
				(Max 5 only) Changes the title bar to show the status of the file in Version Control after it has been checked in.
				(Max 5 only) Uses the new usedMaps() command to find all bitmaps. This replaces the node-tree walking code I wrote to
				do the same thing. That code is still used if the scripts are run on Max 4.
	v1.91	- Changed variable names to follow the programming guidelines.
	v1.9	- Changed name from "SaveToSourceControl" to "CheckIn". All "Source Control" and "SC" references changed to "Version Control
				and "VC".  Changed function call "ConvertArray" to "LSUtilLib.ConvertArrayDOS2Unix" to reflect the change made in LSUtilLib
	v1.8	- Copyright information added.
	v1.7	- Changed from reading strStartMapsFile and strMaxFileToEdit from FileProperties to using the persistent global variables,
				"pg_strMaxFilepath" and, "pg_strMapsFilePath". Moved, "bExit" and, "aNewPathnames" from global to local variables.
	v1.6	- Changed the function call "ConvertArrays" to "ConvertArray" to reflect the change made in LSUtilLb.
	v1.5	- Fixed a bug that prevented the script from completing if the user answered "yes" to, the "Would you like to reopen..." dialog.
	v1.4	- Initial release.
*/

(
	--LOCAL VARIABLES
	-----------------
	local strCheckInVersion = "2.52" -- Version number for display in the Max Listener window
	local bExit = false					-- Boolean to determine if the script should be exited.
	local bReOpen = false				-- Boolean to determine if the file should be re-opened.
	local bExists = false				-- Boolean to determine if the file exists under version control

	aAllMaps = #()
	aOtherMaps = #()
	aPathnames = #()
	aFilesToSubmit = #()
	aFilesToCheckOut = #()


	--GLOBAL VARIABLES
	------------------


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
			VersionControlLib.strChangeDescription = edtUserEntry.text
			btnOK.enabled = true
		)
		on btnOK pressed do
		(
			destroyDialog rltGetDescription
		)
	) -- end of rollout


	--MAIN LOOP
	-----------
	format "CheckIn v% loaded.\n" strCheckInVersion to:Listener

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

		-- Check to make sure the file exists under version control and this person has it checked out.
		bExists = VersionControlLib.VCFstatExists (maxFilePath + maxFileName)
		
		--If the file doesn't exist under verison control then check in won't work.
		if bExists != true then
		(
			-- If the variable exits, then this file is already in source control. It can't be added a second time.
			-- Alert the user and exit the script.
			messagebox "This scene does not exists under version control.\nYou need to use the Add New command to add it" title:"Version Control" beep:false

			-- Exit the script
			bExit = true
			exit
		)
		-- If it does exist it can either be checked out by this user or a different user. Find that out and take appropriate action
		else
		(
			local strActionOwner = VersionControlLib.VCGetFileStats (maxFilePath + maxFileName)
			
			if strActionOwner == "" then
			(
				messagebox "This scene is not checked out from version control.\nIt can not be checked in unless it is checked out." title:"Version Control" beep:false
				
				-- Exit the script
				bExit = true
				exit
			)
			else
			(
				case of
				(
					-- Scene is checked out by someone else. Don't check it in. Exit.
					(strActionOwner != VersionControlLib.strUserName):
					(
						messagebox "This scene is checked out by " + strActionOwner + ".\nYou can do not have it checked out, so you can't check it in." title:"Version Control" beep:false
						
						-- Exit the script
						bExit = true
						exit
					)
					
					-- Scene is checked out by this user. Check it in.
					(strActionOwner == VersionControlLib.strUserName):
					(
						-- Save the file.
						max file save
						
						-- The user needs to enter a description of the changes and decide if they want to close the scene.
						createDialog rltGetDescription width:250 modal:true
						bReOpen = querybox "Would you like to reopen the scene and continue to work on it?" title:"Version Control" beep:false
				
						-- Get a list of all maps used in the scene
						aAllMaps = LSUtilLib.GetSceneMaps()
						aOtherMaps = LSUtilLib.GetOtherMaps()
						aAllMaps = aAllMaps + aOtherMaps
				
						-- Get the pathnames from that list. Then remove the duplicates
						aPathnames = LSUtilLib.GetBitmapsFromMaps aAllMaps
								
						--Do an add so any new textures are added to version control
						VersionControlLib.VCAdd aPathnames
				
						-- Add the max scene to the array so it is checked in also.
						append aPathnames (maxFilePath + maxFileName)			
										
						--Forcing a revert on all files will cause P4 to revert any file that is unchanged
						VersionControlLib.VCRevertUnchanged aPathnames
						
						-- Parse the results of the revert and add the reverted files to an array so they can be re-checked out if the user chooses to re-open the scene
						local fileIn = openFile "$temp\\VCRevert.txt" mode:"r"
						while not eof fileIn do
						(
							sTempString = readDelimitedString fileIn "#"
							append aFilesToCheckOut sTempString
							skipToNextLine fileIn
						)
						close fileIn
				
						-- 'Cause P4 Open and P4 Submit use Unix style relative pathing.
						aPathnames = LSUtilLib.ConvertArrayDOS2Unix aPathnames
						
						-- Remove the reverted files from the files to check in, since they don't need to go through a submit command.
	 					aFilesToSubmit = VersionControlLib.VCGetOpenedFiles aPathnames
									
						-- Check to see if the user wanted to reopen the file for editing after the save/submit.
						if bReOpen == false then
						(
							-- If not, then submit the files to source control. Pass the function an array of files to submit and a boolen
							-- indicating whether or not the files should be reopened.
							VersionControlLib.VCSubmit aFilesToSubmit false
				
							-- Parse the results of the submit command so they can be displayed.
							VersionControlLib.VCParseCommandResults "VCRevert.txt"
							VersionControlLib.VCParseCommandResults "VCSubmit.txt"
				
							-- Possibly display the results of the version control system operations in a dialog.
							if VersionControlLib.bVCShowResults == true then
							(
								messagebox VersionControlLib.strCommandResults title:"Version Control" beep:false
							)
				
							-- Save the command results to a disk file for possible later reference.
							VersionControlLib.VCWriteCommandResults()
				
							-- Clean up all temporary disk files that were created when the scene was checked out.
							VersionControlLib.VCCleanup()
				
							-- Set these VersionControlLib public boolean variables to false so the associated menu commands ghost.
							VersionControlLib.bEnableCheckIn = false
							VersionControlLibbEnableRevert = false
							VersionControlLib.bEnableView = true
				
							-- If requested, reset Max to prevent further editing of the file.
							if VersionControlLib.bVCEnableReset == true then resetMaxFile #noPrompt
							else
							(
								-- Change the titlebar of the app to show the version control status.
								cui.setAppTitle (maxFilePath + MaxFilename + " - NOT CHECKED OUT FROM VERSION CONTROL. OPENED AS READ ONLY.")
							)
				
							-- Exit the script
							bExit = true
							exit
						)
						else -- bReOpen == true
						(
							-- If yes, then submit the files and immediately check them back out of the source control archive.
							VersionControlLib.VCSubmit aFilesToSubmit true
				
							-- Re-check out the reverted files
							LSUtilLib.WriteFile aFilesToCheckOut "$temp\\TempSync.txt" --strTextFile
							strDOSEditFile = LSUtilLib.DOSTempPath "$temp\\TempSync.txt" 1 5
							HiddenDOSCommand ("p4 -x " + strDOSEditFile + " edit > %temp%\\VCEdit.txt")
							deleteFile "$Temp\\TempSync.txt"
							
							-- Parse the results of the submit command so they can be displayed.
							VersionControlLib.VCParseCommandResults "VCRevert.txt"
							VersionControlLib.VCParseCommandResults "VCSubmit.txt"
							VersionControlLib.VCParseCommandResults "VCEdit.txt"
				
							-- Possibly display the results of the version control system operations in a dialog.
							if bVCShowResults == true then
							(
								messagebox VersionControlLib.strCommandResults title:"Version Control" beep:false
							)
				
							-- Save the command results to a disk file for possible later reference.
							VersionControlLib.VCWriteCommandResults()
				
							-- Change the titlebar of the app to show the version control status.
							cui.setAppTitle (maxFilePath + MaxFilename + " - CHECKED OUT FROM VERSION CONTROL")
				
							-- Set these boolean global variables to true so the associated menu commands un-ghost.
							VersionControlLib.bEnableCheckIn = true
							VersionControlLib.bEnableRevert = true
							VersionControlLib.bEnableRevert = true
							VersionControlLib.bEnableView = true
											
							-- Clean up all temporary disk files that were created when the scene was checked out.
							VersionControlLib.VCCleanup()
				
							-- Exit the script
							bExit = true
							exit
						)	
					)
				)
			)
		)
	) 
	while bExit == false
)