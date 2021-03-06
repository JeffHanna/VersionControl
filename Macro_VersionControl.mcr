/*
	Macro_VersionControl.mcr
	Version: 2.52
	Created On: December 01, 2002
	Created By: Jeff Hanna
	Modified On: January 03, 2018
	Modified By: Jeff Hanna
	tested using 3ds Max 2016

	� Copyright 2003, Lodestone Games, LLC. All Rights Reserved.

	A macroscript to tie all of the Version Control scripts into max's UI.
	
	v2.52	- Updated so the VC* calls to global functions are now VersionControlLib.VC* calls
				as that library has properly been made a struct with local functions.
				Brought version numbering in line with the other scripts.
	
	v2.5	- Added LaunchP4Win, SyncToFolder, and the updated options macroscripts.	
	v2.4	- Dead development tree. Version number skipped.
	v2.3	- Added conditional code around the "CheckIn", "AddNew", "Revert", and "View" macroscripts so their menu entries can be ghosted if need be.
	v2.2	- Changed VersionControl_Options to be a check-menu entry and display different menu text.
	v2.1	- Removed "Check Out". The check out script has been depricated. The max #filePostOpen callback script handles
				all Check Out commands now.
*/

macroscript AddNew
	category:"Lodestone Tools"
	buttontext:"Add Scene to Version Control"
	tooltip:"Add Scene to Version Control"

	(
		on isEnabled return VersionControlLib.bEnableAddNew
		
		on execute do
		(
			include "$userscripts\\Lodestone\\VersionControl\\AddNew.ms"
		)
	)


macroscript CheckIn
	category:"Lodestone Tools"
	buttontext:"Check In Scene"
	tooltip:"Check In Scene"

	(
		on isEnabled return VersionControlLib.bEnableCheckIn

		on execute do
		(
			include "$userscripts\\Lodestone\\VersionControl\\CheckIn.ms"
		)
	)


macroscript Revert
	category:"Lodestone Tools"
	buttontext:"Revert Scene (Undo Check Out)"
	tooltip:"Revert Scene (Undo Check Out)"

	(
		on isEnabled return VersionControlLib.bEnableRevert

		on execute do
		(
			include "$userscripts\\Lodestone\\VersionControl\\Revert.ms"
		)
	)


macroscript View
	category:"Lodestone Tools"
	buttontext:"View Scene from Version Control"
	tooltip:"View Scene from Version Control"

	(
		on isEnabled return VersionControlLib.bEnableView
		
		on execute do
		(
			include "$userscripts\\Lodestone\\VersionControl\\View.ms"
		)
	)
	

macroscript LastCommand
	category:"Lodestone Tools"
	buttontext:"Results of Last Command"
	tooltip:"Results of Last Command"

	(
		VersionControlLib.VCParseCommandResults "LastCommand.txt"

		if (VersionControlLib.strCommandResults as string) != "" then
		(
			messagebox VersionControlLib.strCommandResults title:"Version Control" beep:false
		)
	)


macroscript LaunchP4Win
	category:"Lodestone Tools"
	buttontext:"Launch P4V"
	tooltip:"Launch P4V"
	
	(
		shellLaunch "p4v" ""
	) -- end of LaunchP4Win
	
	
macroscript SyncFolder
	category:"Lodestone Tools"
	buttontext:"Sync Folder to Depot"
	tooltip:"Sync Folder to Depot"
	
	(
		local strSyncFolder = getSavePath caption:"Select the folder to sync."
		if strSyncFolder != undefined then HiddenDOSCommand("p4 sync " + strSyncFolder + "\\...")
	) -- end of SyncFolder
	
	
macroscript VersionControl_About
	category:"Lodestone Tools"
	buttontext:"About Version Control Scripts"
	tooltip:"About Version Control Scripts"

	(
		rollout rltAbout "About" width:320 height:170
		(
			bitmap bmpLodestone "" pos:[8,8] width:100 height:100 fileName:"$usericons\\Lodestone.bmp"

			label lblAboutVersion "version 2.52" pos:[120,24] width:64 height:16
			label lblAboutTitle "Version Control Scripts" pos:[120,8] width:164 height:16
			label lblAboutName "Jeff Hanna" pos:[120,64] width:56 height:16
			label lblAboutCompany "Art Director, Lodestone Games" pos:[120,80] width:152 height:16
			label lblCopyright "� Copyright 2003, Lodestone Games, LLC. All Rights Reserved." pos:[8,112] width:304 height:16

			button btnAboutOK "OK" pos:[248,136] width:64 height:24

			on btnAboutOK pressed do
			(
				destroyDialog rltAbout
			)
		)

		createDialog rltAbout 320 170 modal:true
	)


macroscript VersionControl_Options
	category:"Lodestone Tools"
	buttontext:"Options"
	tooltip:"Options"
	
	(
		rollout rltVCOptions "Version Control" width:264 height:144
		(
			groupBox grpVCOptions "Options" pos:[8,8] width:251 height:96
			checkbox chkVCShowResults "Always show results of last command." pos:[16,32] width:200 height:16
			checkbox chkVCEnableReset "Reset Max scene after Check In or Add New." pos:[16,56] width:240 height:16
			checkbox chkVCEditTextures "Check textures out also." pos:[16,80] width:240 height:16
			button btnVCOptionsOK "OK" pos:[104,112] width:75 height:23
			button btnVCOptionsCancel "Cancel" pos:[184,112] width:75 height:23	
			on rltVCOptions open  do
			(
				rltVCOptions.chkVCShowResults.state = VersionControlLib.bVCShowResults
				rltVCOptions.chkVCEnableReset.state = VersionControlLib.bVCEnableReset
				rltVCOptions.chkVCEditTextures.state = VersionControlLib.bVCEditTextures
			)
			on btnVCOptionsOK pressed  do
			(
				VersionControlLib.bVCShowResults = rltVCOptions.chkVCShowResults.state
				VersionControlLib.bVCEnableReset = rltVCOptions.chkVCEnableReset.state
				VersionControlLib.bVCEditTextures = rltVCOptions.chkVCEditTextures.state
				
				setINISetting "$plugcfg\\VersionControl.ini" "Options" "Show Results" (VersionControlLib.bVCShowResults as string)
				setINISetting "$plugcfg\\VersionControl.ini" "Options" "Enable Reset" (VersionControlLib.bVCEnableReset as string)
				setINISetting "$plugcfg\\VersionControl.ini" "Options" "Edit Textures" (VersionControlLib.bVCEditTextures as string)
				
				destroyDialog rltVCOptions
			)
			on btnVCOptionsCancel pressed  do destroyDialog rltVCOptions
		) -- end of rollout rltVCOptions
		
		createDialog rltVCOptions 264 144 modal:true
	) -- end of VersionControl_Options