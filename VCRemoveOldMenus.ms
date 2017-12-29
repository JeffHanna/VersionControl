(
	MainMenu = menuMan.getMainMenuBar()
	FileMenu = menuMan.findMenu "&File"
	iMainMenuCount = mainMenu.numItems()
	iFileMenuCount = FileMenu.numItems()
	
	-- Save current Menu file for backup purposes
	menuMan.saveMenuFile "VCBackup.mnu"
	
	-- Delete the "Version Control" menu
	bExit = false
	while bExit == false do
	(
		for i = iMainMenuCount to 1 by -1 do
		(
			TestMenu = mainMenu.getItem i
			strMenuName = testMenu.getTitle()
			
			if strMenuName == "Version Control" then 
			(
				try (menuMan.unRegisterMenu TestMenu) catch()
				mainMenu.removeItemByPosition i
				
				bExit = true
				exit
			) -- end of "if StrMenuName..." loop
		) -- end of "for i = ..." loop
		bExit = true
		exit
	) -- end of do/while loop

			
	-- Delete the old Version Control menu entries on the "File" menu.
	for i = iFileMenuCount to 1 by -1 do
	(
		MenuItem = FileMenu.getItem i
		strItemName = MenuItem.getTitle()
		
		case of
		(
			(strItemName == "Check In Scene"): 
				(
					FileMenu.removeItemByPosition i
					FileMenu.removeItembyPosition (i - 1)
				)
			(strItemName == "Add Scene to Version Control"): FileMenu.removeItemByPosition i
			(strItemName == "Revert Scene (Undo Check Out)"): FileMenu.removeItemByPosition i
			(strItemName == "View Scene from Version Control"): FileMenu.removeItemByPosition i
			(strItemName == "Check Out Opened Scene"): FileMenu.removeItemByPosition i
		)		
	)
	
	menuMan.updateMenuBar()
)