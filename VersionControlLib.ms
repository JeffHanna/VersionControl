/*
	VersionControlLib.ms
	Version: 2.52
	Created On: December 01, 2002
	Created By: Jeff Hanna
	Modified On: January 03, 2018
	Modified By: Jeff Hanna
	Tested using 3ds Max 2016

	© Copyright 2003, Lodestone Games, LLC. All Rights Reserved.

	A set of scripts that interface the Perforce version control software into 3DS max R4 and R5.
	If the Version Control MaxScripts need to be ported to another versioning system, this file is where the majority of the changes
	will occur.


	v2.52 - Changed this from a collection of global variables and functions to a proper library struct/namespace with private members and public members.
	
	v2.51 - Fixed variable scope on the queryAllBox dialog. Improper scope was causing the scripts to break on Max 4.2x.	
	v2.5	- Added the bVCEnableReset and bVCEditTextures global variables. Changed the postFileOpen callback function to use those variables.
	v2.4	- Dead development tree, version number skipped.
	v2.32	- Fixed a typo bug in VCSubmit that was preventing the reopen option from working.
	v2.31	- Fixed a bug in the code initialization code.
	v2.3	- Added the VCMenuDefault function and callback mechanism. This sets the VC menu items back to their default ghost/unghost states after a Max reset.
				Removed all dependencies on the stored disk files and persistent global variables for sanity checking what was checked out. P4 fstat is now used for that.
				Added the VCGetClientInfo() function. The scripts are now cognizent of the user defined in the client spec. If no user name is found it
				is assumed that either the client spec is invalid or Perforce is not installed. In that instance the user will be alerted to the fact that no client spec exists, 
				the #PostFileOpen callback script will be disabled and	version control menu entries will be ghosted.
				Added the bEnableAddNew and bEnableView global variables so that menu ghosting can be controlled.			
	v2.2	- Depreciated VCSubmitAndReopen(). VCSubmit() now handles a reopen condition based on the bReOpen input boolean variable.
				Renamed VCSyncAndCheckOut() to VCSync(), since it is generally a sync function with the check-out being conditionally controlled.
				Made aMaxVersion a global array since so many scripts in this package are using it.
	v2.1	- Depricated VCSync(). Made VCSyncAndCheckOut() do an optional check out instead.
				The codepaths were so similar it makes it easier to maintain this way.
				Rewrote VCSyncAndOpen() to respect the user's wishes on working on a version < the lastest.
				Added the bEnableCheckIn and bEnableRevert global variables so that menu ghosting can be controlled.
				Added a section to the VCOpenFileCheck() function to switch the variables to true when the file is loaded.
				Added a check to the VCOpenFileCheck() callback function so that it would not try to check the maxstart.max file.
				This allows users to set up default max UI layouts without getting a Version Control error when they load.
				Changed code paths in VCOpenFileCheck(). Removed the seperate code paths for bitmap finding. Max 5's "usedMaps()"
				function does not operate as well as my functions (e.g. It misses some maps). I've gone back to just using
				my functions.
	v2.0	- Renamed to LSVersionControlLib.ms
				Added the VCParseCommandResults & VCWriteCommandResults functions. This allows for Perforce to report back what tasks it has accomplished.
				Added VCOpenFileCheck. This callback function checks all opened max files to see if they are in version control.
				Changed lib to load into memory at startup and made all functions global.
				Added VCCleanup function. This deletes all necessary temp files on the HD and displays the command result.
	v1.91	- Changed all global string variables to local string variables. Renamed variabled prefixes to match coding guidelines.
	v1.9	- Changed all instances of "SC" to "VC" to reflect the renaming of the package to "Version Control"
	v1.8	- SCAdd function adds binary files in exclusive mode now. Exclusive mode files can only be checked out by one person at a time.
	v1.7	- Added SCGetFileStats function to prevent file from being checked out twice.
	v1.6	- Copyright information added.
	v1.5	- Initial release.
*/

struct VersionControlLib_Base
(
	private	
	-------
	strVersion = "2.52",

	strAddFile = "$temp\\AddFiles.txt",
	strRevertFile = "$temp\\RevertFiles.txt",
	strSubmitFile = "$temp\\SubmitFiles.txt",
	strOpenedFiles = "$temp\\OpenedFiles.txt",
	strStartMapsFile = "",
	bExists = false,
	aAllMaps = #(),
	aOtherMaps = #(),
	aStartMapPathnames = #(),
	aMaxFile = #(),


	public
	------
	bPerformOpenFileCheck = true,					-- Boolean to indicate if a file opened with Max's File\Open command should be checked
											 				--  to see if it is under version control
	strCommandResults = "" as stringStream,	-- StringStream to hold the results of the last executed VC command.
	bVCShowResults = false,							-- Boolean to tell if the results of the last VC command should be shown or not.
	bVCEnableReset = true,							-- Boolean to track whether the scene should be reset after a checkin or add new.
	bVCEditTextures = false,						-- Boolean to track whether textures should be opened for edit or not.
	bEnableCheckIn = false,							-- Boolean variable to tell if the Check In command should be ghosted or not.
	bEnableRevert = false,							-- Boolean variable to tell if the Revert command should be ghosted or not.
	bEnableAddNew = true,							-- Boolean variable to tell if the Add new command should be ghosted or not.
	bEnableView = true,								-- Boolean variable to tell if the View command should be ghosted or not.
	strChangeDescription = "",						-- String variable to hold change descriptions.
	strUserName = "",									-- String variable to hold the user's name.


	--TEXT FILE FUNCTIONS
	-----------------------
	-- The "Submit" function takes a specially formed text file to be read from standard input.
	fn VCWriteSubmitTemplate aInputArray strFilePath =
	(
		local FileOut = createFile strFilePath

		format "Change:\tnew\n\n" to:FileOut
		format "Status:\tnew\n\n" to:FileOut
		format "Description:\n" to:FileOut
		format "\t%\n\n" strChangeDescription to:FileOut
		format "Files:\n\n" to:FileOut

		for i in aInputArray do
		(
			format "\t%\n" i to:FileOut
		)
		close FileOut
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Read in the piped output from the VC system and store it in the global strCommandResults stringstream.
	fn VCParseCommandResults strFileName =
	(
		local ResultsFile = openFile ("$temp\\" + strFileName)

		if ResultsFile != undefined then
		(
			seek ResultsFile 0

			while not eof ResultsFile do
			(
				local strTemp = readLine ResultsFile
				format strTemp to:strCommandResults
				format "\n" to:strCommandResults
			)
			close ResultsFile
		)
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Write the value of the global stringStream strCommandResults to a disk file for possible later reference.
	fn VCWriteCommandResults =
	(
		try
		(
			local FileOut = openFile ("$temp\\LastCommand.txt")
			if FileOut != undefined then
			(
				local strOutput = strCommandResults as string
				format strOutput to:FileOut
			)
			else
			(
				local FileOut = createFile ("$temp\\LastCommand.txt")

				local strOutput = strCommandResults as string
				format strOutput to:FileOut
			)
			close FileOut
			strCommandResults = "" as stringStream
		)
		catch()
	),
	-------------------------------------------------------------------------------------------------------------------------


	--SOURCE CONTROL COMMAND FUNCTIONS
	-----------------------------------------
	-- Check a max scene file against the archive to see if someone has it checked out.
	-- Takes the path file of the max scene as input.
	-- Returns a string of the name of the person that has the file checked out.
	-- Called VCGetFileStats instead of something like VCGetCurrentUser because P4 fstat returns much more information than just
	-- the user name. That data may be necessary in the future.
	fn VCGetFileStats strMaxSceneFile =
	(
		HiddenDOSCommand ("p4 fstat " + strMaxSceneFile + " > \"" + (getDir #temp) + "\\VCFstat.txt\"")
		local f = openFile "$temp\\VCFstat.txt" mode:"r"
		
		if skipToString f "actionOwner " != undefined then
		(
			local strActionOwner = readLine f
			return strActionOwner
		)
		else
		(
			seek f 0
			if skipToString f "otherOpen0 " != undefined then
			(
				local strOtherOwner = readDelimitedString f "@"
				return strOtherOwner
			)
			else
			(
				return ""
			)
		)
		close f
	),
	-------------------------------------------------------------------------------------------------------------------------
	
	--
	fn VCFstatExists strMaxSceneFile =
	(
		HiddenDOSCommand ("p4 fstat " + strMaxSceneFile + " > \"" + (getdir #temp) + "\\VCFstat.txt\"")
		local f = openFile "$temp\\VCFstat.txt" mode:"r"
		if skipTostring f "..." != undefined then
		(
			return true
		)
		else
		(
			return false
		)
		close f
	),	
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Finds the user name of the local Perforce client.
	-- Called "GetClientInfo" instead of "GetUserName" since the Perforce "info" command returns much more information than just the user name.
	-- That extra information might be used by the Version Control scripts in the future.
	fn VCGetClientInfo =
	(
		HiddenDOSCommand ("p4 info > \"" + (getdir #temp) + "\\VCClientInfo.txt\"")
		local f = openFile "$temp\\VCClientInfo.txt" mode:"r"
		if f != undefined and skipToString f "User name: " != undefined then
		(
			local strName = readLine f
			return strName
			close f
		)
	),	
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Pass a list of requested files to the source control system so they can be sync'd to their latest versions and opened for edit.
	fn VCSync aFilesToCheck bCheckOut =
	(
		local bmpQMark = openBitmap "$usericons\\QMark.bmp"
		local bStopFileCheck = false	-- A boolean variable to control the do/while loop for texture sync'ing
		local aFilesToSync = #()		-- Local array to hold items that need to be sync'ed to the latest rev.

		global iCaseIndex = 0 as integer	-- Index for the case statements controlling the Yes/No/All requestor.
		global strLabel = "" as string		-- String variable to hold the label text for the Yes/No/All requestor.


		-- Custom dialog since MaxScript doesn't have a Yes/No/All requestor.
		rollout queryAllBox "Version Control" width:446 height:94
		(
			imgTag imgQMark bitmap:bmpQMark pos:[11,11]
			label lblString "" pos:[61,17] width:374 height:69
			button btnYes "Yes" pos:[62,60] width:75 height:23
			button btnYesAll "Yes to All" pos:[141,60] width:75 height:23
			button btnNo "No" pos:[222,60] width:75 height:23
			button btnNoAll "No to All" pos:[303,60] width:75 height:23

			on queryAllBox open do
			(
				queryAllBox.lblString.text = strLabel
			)
			
			on btnYes pressed do
			(
				iCaseIndex = 1
				destroyDialog queryAllBox
			)

			on btnYesAll pressed do
			(
				iCaseIndex = 2
				destroyDialog queryAllBox
			)

			on btnNo pressed do
			(
				iCaseIndex = 3
				destroyDialog queryAllBox
			)

			on btnNoAll pressed do
			(
				iCaseIndex = 4
				destroyDialog queryAllBox
			)
		)-- end rollout


		-- Delete the stored last command history.
		deleteFile "$temp\\LastCommand.txt"

		-- If the input array has only one element then it is checking the Max scene file.
		-- A standard query box is all that is needed.
		if aFilesToCheck.count <= 1 then
		(
			for i in aFilesToCheck do
			(
				-- Do a report only sync on the file to see if it is the latest revision. Then read the piped output in.
				HiddenDOSCommand ("p4 sync -n " + i + " > \"" + (getDir #temp) + "\\VCSyncCheck.txt\"")
				local f = openFile "$temp\\VCSyncCheck.txt" mode:"r"

				-- If the output contains the word "updating" then the file is not the latest revision.
				-- Ask the user if they would like to sync to the latest rev.
				if skipToString f "updating" != undefined then
				(
					bDoSync = querybox ("You do not have the latest version of " + (filenameFromPath i) + " on your machine.\nDo you want to sync to the latest version?") title:"Version Control"
					if bDoSync == true then
					(
						append aFilesToSync i
					)
				)

				-- If the output doesn't contain the word "updating" it is either the latest revision or isn't in
				-- the user's local depot. If the output cotains the word "added" then it is not in the local depot.
				-- Add it to the files to sync so it will be put in the user's depot and checked out.
				else
				(
					seek f 0
					if skipToString f "added" != undefined then
					(
						append aFilesToSync i
					)
				)
				close f
			)
		)
		-- If the array as > 1 elements in it, it is the array of textures.
		-- A custom Yes/No/All requestor makes things easier on the user.
		else
 		(
			while bStopFileCheck == false do
			(
				for i = 1 to aFilesToCheck.count do
				(
					-- Do a report only sync on the file to see if it is the latest revision. Then read the piped output in.
					HiddenDOSCommand ("p4 sync -n " + aFilesToCheck[i] + " > \"" + (getdir #temp) + "\\VCSyncCheck.txt\"")
					local f = openFile "$temp\\VCSyncCheck.txt" mode:"r"

					-- If the output contains the word "updating" then the file is not the latest revision.
					-- Ask the user if they would like to sync to the latest rev. for individual or textures.
					if skipToString f "updating" != undefined then
					(
						strLabel = ("You do not have the latest version of " + (filenameFromPath aFilesToCheck[i]) + "\non your machine. Do you want to sync to the latest version?")
						queryAllBox.lblString.text = strLabel
						createDialog queryAllBox 446 94 modal:true

						-- Depending on the button the user clicks, execute the correct case statements.
						case iCaseIndex of
						(
							-- User clicks "Yes"
							1:	(
									append aFilesToSync aFilesToCheck[i]
									close f
								)
							-- User clicks "Yes to All"
							2:	(
									for j = i to aFilesToCheck.count do
									(
										append aFilesToSync aFilesToCheck[j]
									)
									close f
									bStopFileCheck = true
									exit
								)
							-- User clicks "No"
							3:	(
									close f
								)
							-- User clicks "No to All"
							4:	(
									close f
									bStopFileCheck = true
									exit
								)
						)
					)

					-- If the output doesn't contain the word "updating" it is either the latest revision or isn't in
					-- the user's local depot. If the output cotains the word "added" then it is not in the local depot.
					-- Add it to the files to sync so it will be put in the user's depot and checked out.
					else
					(
						seek f 0
						if skipToString f "added" != undefined then
						(
							append aFilesToSync aFilesToCheck[i]
						)
						close f
					)

					-- Check each iteration through the loop to see if we're at the last element in the array.
					-- If we are, then exit the do/while loop automatically.
					if i >= aFilesToCheck.count then
					(
						bStopFileCheck = true
						exit
					)
				)
			)
		)

		-- If there are any files to sync, sync them.
		if aFilesToSync.count >= 1 then
		(
			LSUtilLib.WriteFile aFilesToSync "$temp\\TempSync.txt" --strTextFile
			strDOSEditFile = LSUtilLib.DOSTempPath "$temp\\TempSync.txt" 1 5
			HiddenDOSCommand ("p4 -x " + strDOSEditFile + " sync > \"" + (getDir #temp) + "\\VCSync.txt\"")
		)

		if bCheckOut == true then
		(
			LSUtilLib.WriteFile aFilesToCheck "$temp\\TempSync.txt" --strTextFile
			strDOSEditFile = LSUtilLib.DOSTempPath "$temp\\TempSync.txt" 1 5
			HiddenDOSCommand ("p4 -x " + strDOSEditFile + " edit > \"" + (getDir #temp) + "\\VCEdit.txt\"")
		)
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Pass a list of new files to the source control system so they can be added.
	fn VCAdd aFilesToAdd =
	(
		LSUtilLib.WriteFile aFilesToAdd strAddFile

		strDOSAddFile = LSUtilLib.DOSTempPath strAddFile 1 5
		HiddenDOSCommand ("P4 -x " + strDOSAddFile + " add -t binary+l > \"" + (getDir #temp) + "\\VCAdd.txt\"")
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Pass a list of unchanged files to the source control system so they can be reverted. Best used at the end of an editing
	-- session before a submit happens.
	fn VCRevertUnchanged aFilesToRevert =
	(
		LSUtilLib.WriteFile aFilesToRevert strRevertFile

		strDOSRevertFile = LSUtilLib.DOSTempPath strRevertFile 1 5
		HiddenDOSCommand ("P4 -x " + strDOSRevertFile + " revert -a > \"" + (getdir #temp) + "\\VCRevert.txt\"")
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Discard all changes and revert all opened files to their latest version.
	fn VCRevertAll aFilesToRevert =
	(
		LSUtilLib.WriteFile aFilesToRevert strRevertFile

		strDOSRevertFile = LSUtilLib.DOSTempPath strRevertFile 1 5

		HiddenDOSCommand ("P4 -x " + strDOSRevertFile + " revert > \"" + (getDir #temp) + "\\VCRevert.txt\"")
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Pass a list of opened and changed files to the source control system so the changes can be submitted.
	fn VCSubmit aFilesToSubmit bAndReOpen =
	(
		VCWriteSubmitTemplate aFilesToSubmit strSubmitFile

		strDOSSubmitFile = LSUtilLib.DOSTempPath strSubmitFile 1 5
		
		if bAndReOpen == true then
		(
			HiddenDOSCommand ("type " + strDOSSubmitFile + " | p4 submit -i -r > \"" + (getDir #temp) + "\\VCSubmit.txt\"")
		)
		else
		(
			HiddenDOSCommand ("type " + strDOSSubmitFile + " | p4 submit -i > \"" + (getDir #temp) + "\\VCSubmit.txt\"")
		)
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- A list of the remaining opened files needs to be gathered so that the program knows what to submit.
	-- Reading the .txt file into an array and comparing it against the array of all pathnames used in
	-- the scene will yield just the files that need to be submitted.
	fn VCGetOpenedFiles aInputArray =
	(
		local aReturnArray = #()

		HiddenDOSCommand ("P4 opened > \"" + (getDir #temp) + "\\OpenedFiles.txt\"")

		local f = openFile strOpenedFiles
		while not eof f do
		(
			local strTextLine = (readLine f) as string
			aOpenedFiles = filterString strTextLine "#"

			for i in aOpenedFiles do
			(
				local iIndex = findItem aInputArray i

				if iIndex != 0 then
				(
					append aReturnArray i
				)
			)
		)
		close f
		deleteFile "$temp\\OpenedFiles.txt"
		return aReturnArray
	),
	-------------------------------------------------------------------------------------------------------------------------

	fn VCCleanUp =
	(
		-- Clean up any temporary files on the HD.
		deleteFile "$temp\\AddFiles.txt"
		deleteFile "$temp\\OpenedFiles.txt"
		deleteFile "$temp\\RevertFiles.txt"
		deleteFile "$temp\\SubmitFiles.txt"
		deleteFile "$temp\\VCAdd.txt"
		deleteFile "$temp\\VCRevert.txt"
		deleteFile "$temp\\VCSubmit.txt"
		deleteFile "$temp\\VCSync.txt"
		deleteFile "$temp\\VCEdit.txt"
		deleteFile "$temp\\VCFstat.txt"
		deleteFile "$temp\\VCClientInfo.txt"
		deleteFile "$temp\\TempSync.txt"
		deleteFile "$temp\\VCSyncCheck.txt"
	),
	-------------------------------------------------------------------------------------------------------------------------


	--CALLBACK FUNCTIONS
	-----------------------
	-- Check every opened max file for version control status. Check out, open, or ignore based on fstat data.
	fn VCOpenFileCheck =
	(
		aMaxFile = #()

		disableSceneRedraw()

		if bPerformOpenFileCheck == true and maxFilename != "" then
		(
			-- Set up a stringStream for the max file path and file name. After it's populated, convert it to a string.
			strFileToOpen = "" as stringStream
			format maxFilepath to:strFileToOpen
			format maxFilename to:strFileToOpen
			strFileToOpen = strFileToOpen as string

			-- Delete the stored last command history.
			deleteFile "$temp\\LastCommand.txt"

			-- Check the properties of the file to see if it is exists under version control
			bExists = VCFstatExists (maxFilePath + maxFileName)
			
			if bExists == true then
			(		
				local strCheckedOutByName = VCGetFileStats strFileToOpen
				
				if strCheckedOutbyName == "" then
				(
					bCheckOut = querybox "This file is not checked out from version control.\nWould you like to check it out?" title:"Version Control" beep:false
	
					if bCheckOut == true then
					(
	
					    -- If it's not already open it, add the file to the request that it become open for editing.
					    append aMaxFile strFileToOpen
	
						-- Sync to the latest version and check the max scene out.
						VCSync aMaxFile true
	
						-- Read in the output from the version control system and add it to a stringstream so it can be displayed.
						VCParseCommandResults "VCSync.txt"
						VCParseCommandResults "VCEdit.txt"
	
						-- Now load it into Max
						bPerformOpenFileCheck = false
						loadMaxFile strFileToOpen
	
						-- Traverse the node tree in the scene and gather all maps used.
						-- Find both maps assigned to materials and those that aren't.
					 	aAllMaps = LSUtilLib.GetSceneMaps()
					 	aOtherMaps = LSUtilLib.GetOtherMaps()
					  	aAllMaps = aAllMaps + aOtherMaps
	
						-- Get the bitmap names and file paths from the list of maps you just made.
						aStartMapPathnames = LSUtilLib.GetBitmapsFromMaps aAllMaps
	
						-- Now sync to the latest version and check out those files files from source control
						VCSync aStartMapPathnames bVCEditTextures
	
						-- Read in the output from the version control system and add it to a stringstream so it can be displayed.
						VCParseCommandResults "VCSync.txt"
						VCParseCommandResults "VCEdit.txt"
	
						-- Possibly display the results of the version control system operations in a dialog.
						if bVCShowResults == true then
						(
							messagebox strCommandResults title:"Version Control" beep:false
						)
	
						-- Save the command results to a disk file for possible later reference.
						VCWriteCommandResults()
	
						-- Force a refresh of all maps in the scene so that any that were updated by the sync become visible.
						freeSceneBitmaps()
	
						-- Set Ghost/unghost the appropriate menu items.
						bEnableCheckIn = true
						bEnableAddNew = true
						bEnableRevert = true
						bEnableView = true
	
						-- Max 5 - change the titlebar of the app to show the version control status.
						if aMaxVersion[1] >= 5000 then
						(
							cui.setAppTitle (maxFilePath + MaxFilename + " - CHECKED OUT FROM VERSION CONTROL.")
						)
					)
					else
					(
						-- Max 5 - change the titlebar of the app to show the version control status.
						if aMaxVersion[1] >= 5000 then
						(
							cui.setAppTitle (maxFilePath + MaxFilename + " - READ ONLY. NOT CHECKED OUT FROM VERSION CONTROL.")
						)
					)
					
				)
				else
				(
					case of
					(
						-- The file is checked out by someone else
						(strUserName != strCheckedOutByName): 
						(
							messagebox ("This file is already checked out by " +  strCheckedOutByName + ".\n\nA Max scene can not be checked out by two people simultaneously.\nIf you need to work on this file please ask " + strCheckedOutByName + " to submit the changes or revert the file.") title:"Version Control" beep:false
							local bKeepOpen = querybox ("You will not be able to save any changes you make to this file.\nDo you want to continue?") title:"Version Control" beep:false
							
							if bKeepOpen == true then
							(
								-- Max 5 - change the titlebar of the app to show the version control status.
								if aMaxVersion[1] >= 5000 then
								(
									cui.setAppTitle (maxFilePath + MaxFilename + " - READ ONLY. CURRENTLY CHECKED OUT BY: " + strCheckedOutByName)
								)
								
							-- Set Ghost/unghost the appropriate menu items.
							bEnableCheckIn = false
							bEnableAddNew = true
							bEnableRevert = false
							bEnableView = true		
							)
							else
							(
								resetMaxFile #noPrompt
							)
						) -- end of 1st case
							
						-- This user already has the file checked out. Just open it.
						(strUserName == strCheckedOutByName):
						(
							-- Set the call back script controller variable to false. We don't need to check this file again.
							bPerformOpenFileCheck = false
		
							-- If the map path storage file exists, then this max scene is already checked out by this user. Just load it.
							loadMaxFile strFileToOpen
		
							-- Set these boolean global variables to true so the file can be reverted or checked in.
							bEnableCheckIn = true
							bEnableRevert = true
		
							-- Max 5 - change the titlebar of the app to show the version control status.
							if aMaxVersion[1] >= 5000 then
							(
								cui.setAppTitle (maxFilePath + MaxFilename + " - CHECKED OUT FROM VERSION CONTROL")
							)	
							
							-- Set Ghost/unghost the appropriate menu items.
							bEnableCheckIn = true
							bEnableRevert = true
							bEnableAddNew = true
							bEnableView = true
						) -- end of second case
					) -- end of case block
				)				
			)
			
			-- The file isn't in version control. Just open it and configure the menus properly
			else
			(
				-- Set Ghost/unghost the appropriate menu items.
				bEnableCheckIn = false
				bEnableRevert = false
				bEnableAddNew = true
				bEnableView = true
			)		
		)		
		
		-- Cleanup disk files, reenable the viewports, and set the boolean controlling whether this script is run or not.
		VCCleanUp()
		enableSceneRedraw()
		forceCompleteRedraw()
		bPerformOpenFileCheck = true
	),
	-------------------------------------------------------------------------------------------------------------------------

	-- Reset the global variables that control whether the version control menu items are ghosted or not.
	fn VCMenuDefault =
	(
		global bEnableCheckIn = false
		global bEnableRevert = false
		global bEnableAddNew = true
		global bEnableView = true
	),
	-------------------------------------------------------------------------------------------------------------------------
	
	
	
	--Init
	-------------
	fn init = 
	(
		-- Get the local user info and/or alert the user that this machine has no client spec.
		strUserName = VCGetClientInfo()
		
		-- If there is a user name then the machine as a valid Perforce client spec. Initialize the version control routines
		if strUserName != undefined then
		(
			-- Print version information to the listener. Useful if a bug-report needs to be sent.
			format "VersionControlLib v% loaded.\n" strVersion to:Listener
		
			-- Read the user stored setting for whether the command results should be displayed or not.
			case of
			(
				(getINIsetting "$plugcfg\\VersionControl.ini" "Options" "Show Results" == "true"): bVCShowResults = true
				(getINIsetting "$plugcfg\\VersionControl.ini" "Options" "Show Results" == "false"): bVCShowResults = false
				(getINIsetting "$plugcfg\\VersionControl.ini" "Options" "Show Results" == ""): bVCShowResults = true
			)
		
			-- Remove the LastCommand file since this is a new Max session
			deleteFile "$temp\\LastCommand.txt"	
			
			-- Register the callback functions so they will be used at every file open and reset
			callbacks.addScript #filePostOpen "VersionControlLib.VCOpenFileCheck()" id:#VersionControl
			callbacks.addScript #systemPostReset "VersionControlLib.VCMenuDefault()" id:#VersionControl
		)
		
		-- If there is no user name then assume there is no valid client spec and/or Perforce isn't installed. Alert the user and
		-- do not initialize the version control scripts.
		else
		(
			bEnableAddNew = false
			bEnableCheckIn = false
			bEnableRevert = false
			bEnableView = false
			messagebox "Either Perforce is not installed or there is no client spec defined on this machine.\n\nWork can not be stored in version control without a local client spec.\nPlease insure that you have Perforce installed properly and a client spec defined.\n\nThe version control system will not be initialized." title:"VersionControl" beep:false
		)
	)
)

VersionControlLib = VersionControlLib_Base()
VersionControlLib.init()