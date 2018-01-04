/*
	VersionControl_Menus.ms
	Version: 2.5
	Created On: February 10, 2003
	Created By: Jeff Hanna
	Modified On: August 06, 2003 
	Modified By: Jeff Hanna
	tested using Max 5.1 (SP1)

	© Copyright 2003 Lodestone Games, LLC. All Rights Reserved.

	Adds the proper Version Control File menu and Help menu commands to the user's Max script interface.


	v2.5 - Added the LaunchP4Win menu command, menu command, and SyncFolder menu command.
	
	v2.4 - Dead development tree, version number skipped.
	v2.2 - Removed the seperator between LastCommand and Options
	v2.1 - Removed "Check Out". The check out script has been depricated. The max #filePostOpen callback script handles
			all Check Out commands now.
	v2.0 - Added new Version Control menu to Max's main menu bar.
	v1.41 - Changed the variable names to follow the programming guidelines.
	v1.4 - Changed name from "SCIO_Menus" to "VersionControl_Menus". All "Source Control" and "SC" references changed to "Version Control and "VC"
	v1.3 - Copyright information added.
	v1.2 - Initial release.
*/

(
	-- Variable to store the discovered menu entry index
	local iIndex = 0 as integer

	--Check to see if this menu context has a stored class ID. If not, then create the ID and the menu entries
	if menuMan.registerMenuContext 0xaa67b048 then
	(
		-- Get the main menu bar
		local mainMenuBar = menuMan.getMainMenuBar()


		-- Find the File menu and the Help menu
		local fileMenuItem = mainMenuBar.getItem 1

		local helpMenuIndex = mainMenuBar.numItems()
		local helpMenuItem = mainMenuBar.getItem(helpMenuIndex)

		-- Get the File menu and the help menu from the fileMenuItem and helpMenuItem variables
		local fileMenu = fileMenuItem.getSubMenu()

		local helpMenu = helpMenuItem.getSubMenu()


		-- Get the number of entries in the File and Help menus
		local fileMenuCount = fileMenu.numItems()

		local helpMenuCount = helpMenu.numItems()


		-- Create a menu Seperatorarator item
		local SeperatorItem = menuMan.createSeparatorItem()


		-- Create menu items that call the source control integration scripts and the about Script
		local CheckInItem = menuMan.createActionItem "CheckIn" "Lodestone Tools"
		local AddNewItem = menuMan.createActionItem "AddNew" "Lodestone Tools"
		local RevertItem = menuMan.createActionItem "Revert" "Lodestone Tools"
		local ViewItem = menuMan.createActionItem "View" "Lodestone Tools"		

		local SyncFolderItem = menuMan.createActionItem "SyncFolder" "Lodestone Tools"
		local LaunchP4WinItem = menuMan.createActionItem "LaunchP4Win" "Lodestone Tools"
		
		local LastCommandItem = menuMan.createActionItem "LastCommand" "Lodestone Tools"
		local OptionsItem = menuMan.createActionItem "VersionControl_Options" "Lodestone Tools"

		local AboutItem = menuMan.createActionItem "VersionControl_About" "Lodestone Tools"


		-- Find the "Xref O$bjects..." menu entry so we can get the menu entry for it.
		for i = 1 to fileMenuCount do
		(
			-- convert each &File menu entry to a string for comparison
			local menuItem = fileMenu.getItem i
			local strCompareString = menuItem.getTitle()

			-- Once found, get its index #.
			if strCompareString == "XRef O&bjects..." then
			(
				iIndex = i
			)
		)


		-- Add the new File menu entries at the proper menu index
		fileMenu.addItem SeperatorItem iIndex
		fileMenu.addItem ViewItem iIndex
		fileMenu.addItem RevertItem iIndex
		fileMenu.addItem AddNewItem iIndex
		fileMenu.addItem CheckInItem iIndex


		-- Create the Version Control menu
		local subMenu = menuMan.createMenu "Version Control"

		-- Add entries to the Version Control menu
		subMenu.addItem CheckInItem -1
		subMenu.addItem AddNewItem -1
		subMenu.addItem RevertItem -1
		subMenu.addItem ViewItem -1
		subMenu.addItem SeperatorItem -1

		subMenu.addItem SyncFolderItem -1
		subMenu.addItem LaunchP4WinItem -1
		subMenu.addItem SeperatorItem -1

		subMenu.addItem LastCommandItem -1
		subMenu.addItem OptionsItem -1
		subMenu.addItem SeperatorItem -1

		subMenu.addItem AboutItem -1

		-- Create a new menu item with the VC menu as it's sub-menu
		local subMenuItem = menuMan.createSubMenuItem "Version Control" subMenu

		-- Find the index of the next-to-last menu item in the main bar
		local subMenuIndex = mainMenuBar.numItems() - 1

		-- Add the sub-menu at the second to last index
		mainMenuBar.addItem subMenuItem subMenuIndex

		-- Redraw the menu bar with the new items
		menuMan.updateMenuBar()
	)
)