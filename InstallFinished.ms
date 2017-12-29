/*
	InstallFinished.ms
	Version: 0.1
	Created On: February 18, 2003
	Created By: Jeff Hanna
	Modified On: April 02, 2003
	Modified By: Jeff Hanna
	Tested using Max 4.26

	© Copyright 2003 Lodestone Games, LLC. All Rights Reserved.


	Cleans up left over install files and then informs the user that the install is finished.

	v0.1 - First version.
*/


(
	--LOCAL VARIABLES
	-----------------


	--MAIN LOOP
	-----------
	rollout rltFinished "Version Control" width:312 height:112
	(
		label lblInstallFinished "Installation of the Version Control scripts is complete." pos:[8,8] width:256 height:16
		label lblQuery "Would you like to see the readme file or view the changelog?" pos:[8,32] width:296 height:16
		checkbox chkReadme "View readme" pos:[8,48] width:88 height:16 checked:true
		checkbox chkChangelog "View changelog" pos:[8,64] width:104 height:15
		button btnFinishedOK "OK" pos:[240,80] width:64 height:24

		on btnFinishedOK pressed  do
		(
			if rltFinished.chkReadme.state == true then
			(
				DOSCommand "c:\\windows\\notepad.exe %temp%\\VCReadme.txt"
			)

			if rltFinished.chkChangelog.state == true then
			(
				DOSCommand "c:\\windows\\notepad.exe %temp%\\VCChangelog.txt"
			)

			deleteFile "$temp\\VCReadme.txt"
			deleteFile "$temp\\VCChangelog.txt"

			destroyDialog rltFinished
		)
	)

	createDialog rltFinished 312 112 modal:true
)