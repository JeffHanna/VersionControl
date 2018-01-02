/*
	LSUtilLib.ms
	Version: 1.51
	Created On: December 05, 2002
	Created By: Jeff Hanna
	Modified On: March 12, 2003
	Modified By: Jeff Hanna
	tested using Max 4.26

	
	v1.51 - Renamed variables to match programming guidelines.
	        Removed the strStartMapsFile and strFileToOpen variables. They weren't used in this script.
	v1.5 - Added the GeometryFilter and GetSelectionBoundingBox functions. 
	       Commented out the strStartMapsFile and strFileToOpen variable declarations. They are P4Lib.ms variables. Why are they being delcared here?
	v1.4 - Reworked functions to standardized programming conventions.
		   Changed DOSTempPath function to take start and end character locations as input variables.
	v1.3 - Added CompareFileDates function
	v1.2 - Renamed the function "ConvertArrays" to "ConvertArray" since it only works on one array at a time.
	v1.1 - Initial release.
	
*/

(
--LOCAL VARIABLES
------------------
	local strLSULVersion = "1.51" as string
	
	
--GLOBAL VARIABLES
------------------
		
	
--GLOBAL FUNCTIONS
------------------
	global GetUsedMapPaths
	global GetNewMapPaths
	global ConvertArrayDOS2Unix
	global RemoveDuplicates
	global WriteFile
	global MakeRelativePath
	global DOSTempPath
	global GetSceneMaps
	global GetSceneMaterials
	global GetAllMaterials
	global GetSubMaterials
	global GetMapsFromMaterial
	global GetOtherMaps
	global GetBitmapsFromMaps
	global CompareFileDates
	global GeometryFilter
	global GetSelectionBoundingBox

		
--ARRAY MANIPULATION FUNCTIONS
-----------------------------------
	-- Checks the input array for duplicate entries. Removes any duplicates found.
	fn RemoveDuplicates aInput =
	(
		for j in aInput.count to 1 by -1 do 
		(
			local iIndex = findItem aInput aInput[j]
			if (iIndex != 0) and (iIndex != j) do 
				(
					deleteItem aInput j
				)
		)
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Performs a simple alphabetic check on two file names. Returns a value indicating which one is 
	-- closer to A in the alphabet (e.g. A_File.text is higher than File.text)
	fn NameCompare strName1 strName2 = 
	(
		if strName1.name < strName2.name then
		(
			return -1
		)
		else if strName1.name > strName2.name then
		(
			return 1
		)
		else 
		(
			return 0
		)
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	
--FILE MANIPULATION FUNCTIONS
---------------------------------
	-- Takes an array of items and a file path name.
	-- Writes the list of items in the array to the file on disk.
	fn WriteFile aInput strFilePath =
	(
		local FileOut = createFile strFilePath
		
		for i in aInput do
		(
			format "%\n" i to:FileOut
		)
		close FileOut
	)
	-------------------------------------------------------------------------------------------------------------------------		
		
	-- Takes two file paths and checks to see if they point to files of the same name.
	-- If so, it checks the modification dates to see which is newer.
	-- Returns 0 if the files aren't the same name and can't be compared.
	-- Returns 1 if the files have the same modification dates/times.
	-- Returns 2 if the first input file is newer.
	-- Returns 3 if the second input file is newer.
	fn CompareFileDates strFile1 strFile2 =
	(
		local iResult = 0
		
		-- If the file names don't match the files can't be synchronized
		if (getFilenameFile strFile1) != (getFilenameFile strFile2) then
			(
				iResult = 0
			)
			else
			(
				-- If the file mod dates are the same the files don't need to be synchronized
				if getFileModDate strFile1 == getFileModDate strFile2 then
				(
					iResult = 1
				)
				else
				(
					-- Break File 1's mod date info up and put it in an array
					-- The array items are always ordered; MM, DD, YYY, HH, MM, SS
					aFile1ModInfo = filterString (getFileModDate strFile1) "//, ,:"
					
					-- Break File 2's mod date info up and put it in an array
					aFile2ModInfo = filterstring (getFileModDate strFile2) "//, ,:"
					
					-- Pull the MM/DD/YYYY and HH:MM:SS out of the arrays and put them in integer variables for comparison.
					-- Must be done since the values in the array are strings and won't compare properly as such.
					iFile1Month = aFile1ModInfo[1] as integer
					iFile2Month = aFile2ModInfo[1] as integer
					
					iFile1Day = aFile1ModInfo[2] as integer
					iFIle2Day = aFile2ModInfo[2] as integer
					
					iFile1Year = aFile1ModInfo[3] as integer
					iFile2Year = aFile2ModInfo[3] as integer
					
					iFile1Hour = aFile1ModInfo[4] as integer
					iFile2Hour = aFile2ModInfo[4] as integer
					
					iFile1Minute = aFile1ModInfo[5] as integer
					iFile2Minute = aFile2ModInfo[5] as integer
					
					iFile1Second = aFile1ModInfo[6] as integer
					iFile2Second = aFile2ModInfo[6] as integer
					
					
					-- Check to see if File2's date is newer than File1's.
					if iFile2Month > iFile1Month and iFile2Day > iFile1Day and iFile2Year > iFile1Year then
					(
						-- If the date is newer, then check the time to see if it is newer.
						if iFile2Hour > iFile1Hour and iFile2Minute >= iFile1Minute and iFile2Second > iFile1Second then
						(
							iResult = 3
						)
					)
					-- If file 1's mod date info is newer than File 2's it must be the newer file.
					else
					(
						iResult = 2
					)
				)
			)		
			return iResult
	)
	-------------------------------------------------------------------------------------------------------------------------
		
	
--PATH MANIPULATION FUNCTIONS
----------------------------------
	-- Convert the array's elements from DOS based absolute pathing to Unix based relative pathing.
	fn ConvertArrayDOS2Unix aInput =
	(
		local aReturn = #()
		
		for i in aInput do
		(
			i = MakeRelativePath i
			aPathPieces = filterString i "\\"
			
			local UnixPath = stringStream ""
			
			format "//" to:UnixPath
			for j = 1 to aPathPieces.count do
			(
				format aPathPieces[j] to:UnixPath
				if j != aPathPieces.count then
				(
					format "/" to:UnixPath
				)
			)
			close UnixPath
			strUnixPath = UnixPath as string
			append aReturn strUnixPath
		)
		return aReturn
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Changes C:\ absolute pathing to \\ relative pathing
	fn MakeRelativePath strInputPath  =
	(
		replace strInputPath 1 2 "\\"
	)	
	-------------------------------------------------------------------------------------------------------------------------

	
	-- DOS Commands don't understand the Max-centric relative Temp path of $temp.
	-- Instead, they understand %temp%.
	fn DOSTempPath strInputPath iStartCharacter iEndCharacter =
	(
		replace strInputPath iStartCharacter iEndCharacter "%temp%"
	)
	-------------------------------------------------------------------------------------------------------------------------
		
	
--MATERIAL TREE FUNCTIONS
----------------------------
	--Scan the scene to find all Map assignments within it.
	fn GetSceneMaps =
	(
		local aSceneMaterials = #()
		local aReturn = #()
		aTempMap = #()
		
		aSceneMaterials = GetSceneMaterials()
		
		for i in aSceneMaterials do
		(
			aTempMaps = #()
			
			GetMapsFromMaterial i aTempMaps
			
			join aReturn aTempMaps
		)
		
		qSort aReturn NameCompare
		
		return aReturn
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	--Scan the scene to find all material assignments within it.
	fn GetSceneMaterials =
	(
		local aReturn = #()
		local iIndex = 0 as integer
		
		for i in $* do
		(
			if i.material != undefined then
			(
				for i in (GetAllMaterials i.material) do
				(
					iIndex = findItem aReturn i
					if iIndex == 0 then
					(
						append aReturn i
					)
				)
			)
		) 		
		
		qSort aReturn NameCompare
		
		return aReturn
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Find all materials and multi-sub materials within a given assigned scene material.
	fn GetAllMaterials InputMaterial =
	(
		aReturn = #()
		aTempMaterials = #()
		
		append aReturn InputMaterial
		
		GetSubMaterials InputMaterial aTempMaterials
		
		for i in aTempMaterials do
		(
			if findItem aReturn i == 0 then
			(
				append aReturn i
			)
		)
		
		return aReturn
	)
	-------------------------------------------------------------------------------------------------------------------------

	-- If the InputMaterial array has multi-sub materials then scan them for material entries.
	fn GetSubMaterials InputMaterial aInput =
	(
		if InputMaterial.numsubs != 0 then
		(
			for i = 1 to InputMaterial.numsubs do
			(
				if InputMaterial[i] != undefined then
				(
					if isKindOf InputMaterial[i] material == true then
					(
						if classOf InputMaterial[i] == subAnim then
						(
							if superClassOf InputMaterial[i].object == material then
							(
								if findItem aInput (InputMaterial[i].object) == 0 then
								(
									append aInput (InputMaterial[i].object)
								)
							)
						)
						
						if superClassOf InputMaterial[i] == material then
						(
							if findItem aInput InputMaterial[i] == 0 then
							(
								append aInput InputMaterial[i]
							)
						)
					)
					GetSubMaterials InputMaterial[i] aInput
				)
			)
		)
	)
	-------------------------------------------------------------------------------------------------------------------------

	-- Find all maps in the inputted materials.
	fn GetMapsFromMaterial InputMaterial aInput =
	(
		if InputMaterial.numsubs != 0 then
		(
			for i = 1 to InputMaterial.numsubs do
			(
				if InputMaterial[i] != undefined then
				(
					if classOf InputMaterial[i] == subAnim then
					(
						if superClassOf InputMaterial[i].object == textureMap then
						(
							if InputMaterial[i].object != undefined then
							(
								append aInput InputMaterial[i].object
							)
						)
					)
					GetMapsFromMaterial InputMaterial[i] aInput
				)
			)
		)
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Scan the lights in the scene for projector map bitmaps.
	fn GetOtherMaps =
	(
		local aReturn = #()
		
		for i in lights do
		(
			if superClassof i == light then
			(
				local bLightType = false
				
				if classOf i == targetSpot or classOf i == Omnilight or classOf i == TargetDirectionallight or classOf i == Directionallight or classOf i == freeSpot then
				(
					bLightType = true
				)
				
				if bLightType == true then
				(
					if i.projectorMap != undefined then
					(
						append aReturn i.projetorMap
					)
					
					if i.shadowProjectorMap != undefined then
					(
						append aReturn i.shadowProjectorMap
					)
				)
			)
		)
		return aReturn
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- From the input array of maps gather all of the bitmap filepaths.
	fn GetBitmapsFromMaps aInput =
	(
		local aReturn = #()
		
		for i in aInput do
		(
			if classOf i == Bitmaptexture then
			(
				append aReturn i.filename
			)
		)
		return aReturn
	)
	-------------------------------------------------------------------------------------------------------------------------		
	
	
--BITMAP PATH FUNCTIONS
--------------------------
	-- Enumerate all bitmaps in the scene. If the gathered bitmap isn't in the array of stored bitmaps, add it.
	-- DEPRECATED DUE TO THE FACT THAT IT DOESN'T ALWAYS GATHER ALL BITMAPS IN THE SCENE.
	fn GetUsedMapPaths strMapPathname =
	(
		local iIndex = findItem StartMapPathnames strMapPathname
		StartMapPathnames = #()
		if iIndex == 0 do
		(
			append StartMapPathnames strMapPathname
		)
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- Compare the list of current maps against the array of original maps to see if any new ones were added to the Max scene.
	-- DEPRECATED DUE TO THE FACT THAT IT DOESN'T ALWAYS GATHER ALL BITMAPS IN THE SCENE.
	fn GetNewMapPaths strNewPathname =
	(
		local iIndex = findItem StartMapPathnames strNewPathname
		if iIndex == 0 do
		(
			append NewPathnames strNewPathname
		)
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	
--GEOMETRY FUNCTIONS
------------------------
	-- Pickbutton filter that tests the potential pick object to ensure that it is valid geometry.
	fn GeometryFilter InputObject =
	(
		superClassOf InputObject == GeometryClass
	)
	-------------------------------------------------------------------------------------------------------------------------

	-- Takes the current selected objects, puts them into an array, then calculates the bounding volume for all of the objects.
	fn GetSelectionBoundingBox =
	(
		-- Put the selected items into an array.
		arraySelection = $*

		local point3Min = [0,0,0]
		local point3Max = [0,0,0]
		
		-- If the array is empty, return null bounding volume coordinates.
		if arraySelection.count == 0 then
		(
			return #(point3Min, point3Max)
		)
		else
		(
			-- Else, walk the array and compare each element's min and max values against the initial set.
			for i in arraySelection do
			(
				-- Check each element to see if it is valid geometry. Skip objects that don't have a volume associated with them.
				if superclassof i != light and superclassof i != camera and superclassof i != spacewarpObject then
				(
					-- If the element''s min coordinates are smaller than the initial set, replace the initial set with these coordinates.
					if i.min.x < point3Min.x then
					(
						point3Min.x = i.min.x
					)
					if i.min.y < point3Min.y then
					(
						point3Min.y = i.min.y
					)
					if i.min.z < point3Min.z then
					(
						point3Min.z = i.min.z
					)
					
					-- If the element's max coordinates are larger then the initial set, replace the initial set with these coordinates.
					if i.max.x > point3Max.x then
					(
						point3Max.x = i.max.x
					)
					if i.max.y > point3Max.y then
					(
						point3Max.y = i.max.y
					)
					if i.max.z > point3Max.z then
					(
						point3Max.z = i.max.z
					)					
				)
			)
			
			return #(point3Min, point3Max)
		)
	)
	-------------------------------------------------------------------------------------------------------------------------
	
	-- print version information to the listener. Useful if a bug-report needs to be sent.
	format "LSUtilLib, v% loaded.\n" strLSULVersion to:Listener
)


