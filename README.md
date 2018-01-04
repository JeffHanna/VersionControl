3DSMax Version Control Scripts

Version: 		2.52
Release Date:	January 03, 2018
Author:		Jeff Hanna (Art Director, Lodestone Games, LLC)

All scripts in this package are © copyright 2003, Lodestone Games, LLC. All Rights Reserved.


An interface between 3DSMax and the Perforce version control system

This package works in Max 4.x and Max 5.x


New in Version 2.52
* Updated to install and work correclty in newer versions of 3ds Max. Tested on 3ds Max 2016, 2017, and 2018.


New in Version 2.5

* The Version Control Menu is now sporting a few new commands.
	- "Launch P4Win" Will load the Perforce client for Windows.
	- "Sync Folder To Depot" will let the user pick a folder in their local depot. That folder (and all subfolders under it)
		will then be synchronized with the server depot. This is great for updating your art depot each day as new art 
	    assets are checked in.
		
* The "Always Display Last Command Results" check-menu command has now morphed into the "Options" menu command.
	This menu command will open up a new Options window that lets you configure how certain aspects of the Version Control
	package work.
	- The "Always show results of last command." check box controls whether or not the verbose output from the version control
		commands is shown or not. This defaults to off.
		
	- The "Reset Max scene after Check In or Add New" check box controls whether or not the Max workspace is reset to it's
		default state after a file is checked in or added (without the option of reopening it being set) to the depot. This defaults to on.
		
	- The "Check textures out also" check box controls whether or not Max checks out all of the texture maps 
		in a scene or just syncs them to the latest version. This defaults to off.



Command Reference
-----------------
(File Menu)
* Check In Scene
  ----------------
  This command is used to submit changes to a checked out scene when the user is done editing it.
  The user will be prompted to enter a change description and asked if they would like to re-open the file for continued
  editing. The changes will be submitted, and if necessary the scene will be re-checked out for further work.

  If the scene does not exist in the version control archive the user will be notified that they must use the
  "Add New to Version Control" command instead.


* Add New to Version Control
  ---------------------------
  New scenes are added to the version control archive with this command. The user will be prompted for a location
  and name for the max scene, a change description and whether they would like to immediately re-check out the file
  for further editing. The file will be saved to the user's hard drive and all files in the scene will be submitted
  to the version control archive. If necessary, the file will be re-checked out so that the user may continue to
  work on it.


* Revert Scene (undo checkout)
  ------------------------------
  Selecting this command will discard any changes made to the checked out file and will revert the checked out files
  to the last good versions in the version control archive.


* View Scene from Version Control
  --------------------------------
  This command functions similarly to the "Check Out From Version Control" command. The only difference is that the
  files for the 3DS Max scene are not checked out. All files are synchronized to the latest revisions in the
  version control archive. The 3DS Max scene is then loaded, but in a read-only state. This is useful for checking
  new versions of scenes without intending to make any changes to them.

  

(Version Control Menu)
* File manipulation commands are the same as the File Menu commands

* Sync Folder To Depot
  ----------------------
  Let's the user pick a folder in their local depot. That folder (and all subfolders under it) will then be synchronized with the 
  server depot. This is great for updating your art depot each day as new art assets are checked in.
  
  
* Launch P4Win
  --------------
  Loads the Perforce client for Windows.
  
  
* Results of Last Command
  -----------------------
  Displays a dialog with the results of the last executed Version Control command.


* Options
   -------
  Opens the Options dialog so various items controlling the execution of the package can be set.


* About Version Control Scripts
 ------------------------------
 This brings up an about dialog showing the version of the scripts installed and other information.
