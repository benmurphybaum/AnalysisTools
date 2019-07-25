#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <New Polar Graphs>

//Finds any help message within an external function, prints the help message
Function displayExtFuncHelp(theFunction)
	String theFunction
	Variable i
	String char = ""
	theFunction = "AT_" + theFunction
	
	String functionStr = ProcedureText(theFunction,0)
	Variable pos1 = strsearch(functionStr,"//HELP",0) + 7
	Variable pos2 = strsearch(functionStr,"//ENDHELP",0)
	
	String helpStr = theFunction + ": " + functionStr[pos1,pos2-1]
	
	//Inserts a line break every 50 characters, rounded to the next space
	If(strlen(helpStr) > 100)
		i=100
		Do
			char = helpStr[i]
			If(!cmpstr(char," "))
				helpStr[i] = char + "\r\t\t"
			Else
				i = strsearch(helpStr," ",i)
				helpStr[i] = "\r\t\t"
			EndIf
			i+=100
		While(i<strlen(helpStr))
	EndIf
	print "-----------HELP-------------"
	print helpStr
	print "----------------------------"
End

Function/WAVE GetFolderListItems([folderPath])
	//if folderPath is provided, the folder list within folderPath is provided instead of the cdf
	String folderPath
	
	Wave/Z/T folderTable = root:Packages:analysisTools:folderTable


	Wave/T selFolderWave = root:Packages:analysisTools:selFolderWave
	If(!WaveExists(folderTable))
		Make/O/T/N=(DimSize(selFolderWave,0)) root:Packages:analysisTools:folderTable
	EndIf
	Wave/T folderTable = root:Packages:analysisTools:folderTable
	
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	Variable i
	
	//Indexes waves in current data folder, applies match string
	
	cdf = GetDataFolder(1)
	
	If(!ParamIsDefault(folderPath))
		SetDataFolder $folderPath
	EndIf

	String folderList = ReplaceString(";",StringFromList(1,DataFolderDir(1),":"),"")
	folderList = TrimString(folderList)

	Redimension/N=(ItemsInList(folderList,",")) folderTable,selFolderWave
	
	//Fills out folder table for the list box
	For(i=0;i<ItemsInList(folderList,",");i+=1)
		folderTable[i] = StringFromList(i,folderList,",")
	EndFor
	SetDataFolder $cdf
	
	return folderTable
End

Function/WAVE GetFolderItems([depth])
	Variable depth //folder depth
	
	Wave/T waveListTable = root:Packages:analysisTools:itemListTable
	Wave selWave = root:Packages:analysisTools:itemListSelWave
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
	SVAR waveNotMatchStr = root:Packages:analysisTools:waveNotMatchStr
	String itemList
	Variable i
	
	//Checks if match string has value
	If(!strlen(waveMatchStr))
		waveMatchStr = "*"
	EndIf
	
	//Match list
	itemList = ReplaceString(";",StringFromList(1,DataFolderDir(2),":"),"")
	itemList = TrimString(itemList)
	//itemList = ListMatch(itemList,waveMatchStr,",")
	
	//Not match list
	//If(strlen(waveNotMatchStr))
	//	itemList = ListMatch(itemList,"!*" + waveNotMatchStr,",")
	//EndIf
	
	Redimension/N=(ItemsInList(itemList,",")) waveListTable,selWave
	
	For(i=0;i<ItemsInList(itemList,",");i+=1)
		waveListTable[i] = StringFromList(i,itemList,",")
	EndFor
	return waveListTable
End

//Flips the list boxes between showing scanlistbox and ROI listbox to the full data browser folder/item list boxes
Function flipLists(whichList)
	String whichList

	//current data folder string
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	
	//Waves for the scan and ROI tables
	wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	wave/T scanListWave = root:Packages:twoP:examine:scanListWave
	Wave selWave = root:Packages:twoP:examine:selWave
	
	//Waves for the folder and item tables
	Wave/T folderTable = GetFolderListItems()
	
	If(!WaveExists(root:Packages:analysisTools:selFolderWave))
		Make/O/N=(DimSize(folderTable,0)) root:Packages:analysisTools:selFolderWave
	EndIf
	Wave/T selFolderWave = root:Packages:analysisTools:selFolderWave
	
	NVAR selFolder= root:Packages:analysisTools:selFolder
	selFolder = 0
	

	Wave/T waveListTable = GetFolderItems()
	If(!WaveExists(root:Packages:analysisTools:itemListSelWave))
		Make/O/N=(DimSize(waveListTable,0)) root:Packages:analysisTools:itemListSelWave
	EndIf
	Wave itemListSelWave = root:Packages:analysisTools:itemListSelWave

	//Change between the scan list box and the folder list box
	strswitch(whichList)
		case "AT":
			//shrink the window
			GetWindow analysis_tools wsize
			MoveWindow/W=analysis_tools V_left,V_top,V_right-100,V_bottom
			//change the subwindow guides
			DefineGuide/W=analysis_tools listboxLeft={FR,-235},listboxBottom={FB,-10}
			//text box labels
			SetDrawEnv/W=analysis_tools#scanListPanel textxjust=1
			DrawText/W=analysis_tools#scanListPanel 75,25,"Scans"
			DrawText/W=analysis_tools#scanListPanel 180,25,"ROIs"
			
			//Hide some controls
			Button atBrowseBackButton win=analysis_tools#scanListPanel,disable=1
			SetVariable AT_cdf win=analysis_tools#scanListPanel,disable=1
			ListBox AT_FolderListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=4,listWave=folderTable,selWave=selFolderWave,proc=atListBoxProc,disable=1
			ListBox AT_ItemListBox win=analysis_tools#scanListPanel,listWave=waveListTable,selWave=itemListSelWave,mode=4,size={80+75,500-65},proc=atListBoxProc,disable = 1
			//SetVariable folderDepth win=analysis_tools#scanListPanel,disable=1
			
			//Move the ROI list box back
			ListBox ROIListBox win=analysis_tools#scanListPanel,pos={150,30}
			
			//Show the ROI list box
			ListBox ROIListBox win=analysis_tools#scanListPanel,disable=0
			
			//Show some controls
			Button dispROI win=analysis_tools#scanListPanel,disable = 0
			Button atBrowseButton win=analysis_tools#scanListPanel,title="Browse"
			
			//in case of different sizes for list wave and selection wave
			//this can happen from the time series, line scan, and z stack labels within the list
			If(DimSize(selWave,0) != DimSize(scanListWave,0))
				Redimension/N=(DimSize(selWave,0)) scanListWave
			EndIf
			
			//Change some control assignments
			ListBox/Z WaveListBox win=analysis_tools#scanListPanel,selWave=selWave,listWave=scanListWave,proc=atListBoxProc,disable=0

			break
		case "Browser":
			//expand the window
			GetWindow analysis_tools wsize
			MoveWindow/W=analysis_tools V_left,V_top,V_right+100,V_bottom
			//change the subwindow guides
			DefineGuide/W=analysis_tools listboxLeft={FR,-235-100},listboxBottom={FB,-10}
			
			//kill text box labels
			DrawAction/W=analysis_tools#scanListPanel delete	
			
			//Move the ROI list box over
			ListBox ROIListBox win=analysis_tools#scanListPanel,disable=1
			
			//Hide some controls
			ListBox/Z WaveListBox win=analysis_tools#scanListPanel,selWave=selWave,listWave=scanListWave,proc=atListBoxProc,disable=1
			Button dispROI win=analysis_tools#scanListPanel,disable = 1			
			
			//Show some controls
			Button atBrowseButton win=analysis_tools#scanListPanel,title="Scans"
			SetVariable AT_cdf win=analysis_tools#scanListPanel,disable=2
			Button atBrowseBackButton win=analysis_tools#scanListPanel,disable=0
			//SetVariable folderDepth win=analysis_tools#scanListPanel,disable=0
			
			//Change some control assignments
			ListBox AT_FolderListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=4,listWave=folderTable,selWave=selFolderWave,proc=atListBoxProc,disable=0
			ListBox AT_ItemListBox win=analysis_tools#scanListPanel,listWave=waveListTable,selWave=itemListSelWave,mode=4,size={80+100,500-65},pos={150,30},proc=atListBoxProc,disable = 0

			break
	endswitch

End

//Displays the help message for the given command
Function AT_DisplayHelpMessage(topic)
	String topic
	String message,message1,message2
	
	Variable left,top,width,height,result
	
	String osInfo = IgorInfo(2)
	
	If(cmpstr(osInfo,"Macintosh") == 0)
		String font = "Helvetica Neue Light"
	ElseIf(cmpstr(osInfo,"Windows") == 0)
		font = "Arial"
	EndIf
	
	strswitch(topic)
		case "None":
			GroupBox AT_HelpBox win=analysis_tools,disable=1
			DrawAction/L=ProgBack/W=analysis_tools delete
			break
		case "Line Profile":
			left = 7
			top = 269
			width = 326
			height = 203
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Gets a line profile from a 2D image, or a time series.\r"
			message += "Initiate the line profile by clicking once on the image.\r"
			message += "The mouse position is tracked until the user clicks again to disengage \rthe line profile.\r"
			message += "The path can be saved for repeated use, and can be selected in the \r'Paths' drop down menu.\r\r"
			message2 = "Use Scan List: applies the selected path to a scan from the scan list on \rthe right.\r"
			message2 += "Collapse: for time series images (3D), it finds the max value of the line \rprofile over the indicated Peak time window\r"
			message2 += "∆F/F: measures ∆F/F line profile instead of the raw fluorescence value. Set \rbaseline and peak ranges appropriately.\r"
			message2 += "Dist. Only: does the line profile, but also detects if the profile started and \rended in pre-"
			message2 += "made ROIs, and measures the cable distance between them."	
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+93,message2
			SetDrawLayer/W=analysis_tools UserBack
			break
		case "ROI From Map":
			left = 7
			top = 100
			width = 326
			height = 140
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Gets the ∆F/F or ∆G/R signal from a time-varying ∆F/F or ∆G/R image\r"
			message += "instead of from the raw fluorescence trace.\r\r"
			message += "To make a map, use 'Get Dendritic Mask' first, then run 'dFMap' with that\r mask.\r\r"
			message += "• Select Scan and ROI from lists.\r"
			message += "• Select channel for ∆F/F or ratio for ∆G/R\r"
			message += "• Smooth applies a temporal filter (Savitzky-Golay; 13 works well).\r"
			message += "• Select whether to average the resulting ROI traces from the scan set."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Get Dendritic Mask":
			left = 7
			top = 88
			width = 326
			height = 100
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Creates a mask image of the neuron.\r\r"
			message += "These masks can be used for creating ∆F/F maps.\r\r"
			message += "• Select Scan from list. Multiple scans can be selected at once.\r"
			message += "• Select channel to use for the mask.\r"
			message += "• Set the threshold. Higher values are more stringent (0.05 works well)."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "dF Map":
			left = 7
			top = 200
			width = 326
			height = 190
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Creates a ∆F/F or ∆G/R map from a time-varying scan.\r\r"
			message += "Outputs peak ∆F/F or peak ∆G/R map, time-varying ∆F/F or ∆G/R map,\r"
			message += "and a peak time map.\r\r"
			message += "• Select Scan from list.\r"
			message += "• Select channel.\r"
			message += "• Select the mask wave to use. Create a mask using 'Get Dendritic Mask'.\r"
			message += "• Set the time windows for baseline and peak selection. These are\r"
			message += "    important if 'Remove Laser Response' is selected.\r"
			message1 = "Make Histogram: makes histogram of fluorescence values.\r"
			message1 += "CleanUp Noise: removes extremely high intensity values.\r"
			message1 += "Remove Laser Response: flattens the laser response for better baselining."
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+145,message1
			break
		case "Display ROIs":
			left = 7
			top = 130
			width = 326
			height = 78
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Displays the selected ROI traces from the selected scans.\r\r"
			message += "Arrange the ROIs and Scans either horizontally or vertically in a grid.\r\r"
			message += "• Averages: check to display the average ROI traces (must already exist).\r"
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Data Sets":
			left = 7
			top = 360
			width = 326
			height = 128
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Define data sets by selecting folders in the scan list, and using the\r"
			message += "match/not match inputs.\r\r"
			message += "• Click the 'Browse' Button to access the rest of the data folders outside\r"
			message += "   of twoP_Scans.\r\r"
			message += "• Once you've matched the waves, set the data set name and click 'Add'.\r\r"
			message += "• Data sets can then be operated on using the 'Operation' function."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Get Peaks":
			left = 7
			top = 105
			width = 326
			height = 113
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Gets the peaks of the selected ROIs and Scans\r\r"
			message += "• Select the scans and ROIs\r\r"
			message += "• Select the channels. Choose 'ratio' if the ROIs are ∆G/R format\r\r"
			message += "• A different peak wave will be made for each ROI, with one data point\r"
			message += "   per scan."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Operation":
			left = 7
			top = 350
			width = 326
			height = 143
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Perform a custom operation on matched waves or data sets.\r"
			message += "• Select multiple folders and use the match/not match inputs to find the\r"
			message += "  waves of interest.\r"
			message += "• Alternatively, select a data set defined using the 'Data Sets' function.\r"
			message += " Operation will only use a data set if 'Use Data Set' is checked.\r"
			message += "• Choose a function from the drop down menu, or manually write it in.\r"
			message += "  Enter a custom suffix for naming the output wave, leaving it blank auto-\r"
			message1 = "  matically creates a name.\r"
			message1 += "• Operation can be a custom equation using the w0,w1,w2,etc. notation\r"
			message1 += "  to indicate the waves in the list."
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+94,message1
			break
		case "MultiROI":
			left = 7
			top = 220
			width = 326
			height = 165
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Extracts Z data from ROI regions in a time series image.\r\r"
			message += "•  Select folders from the Scan List and check the desired channels.\r"
			message += "•  Select the ROIs to extract from the ROI list\r\r"
			message += "•  Select time windows for baselining and peaks in seconds (not points)\r"
			message += "•  'Get Peaks' gets the peak ∆F/F or ∆G/R from the extracted data.\r"
			message += "•  Width (seconds) averages around the peak, or takes a single data\r"
			message += "   point if set to zero.\r\r"
			message1 = "•  'Angles' will reorder the peak data according to the angles. Preset\r"
			message1 += "  angles can be used and added to."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+135,message1
			break
		case "Vector Sum Map":
			left = 7
			top = 145
			width = 326
			height = 80
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Uses ∆F/F maps from the selected scans to build an angle maps via\r"
			message += "vector summation. Also outputs DSI and Resultant maps.\r\r"
			message += "• Not setting the 'Angles' input results in linear angles in 45° increments\r"
			message += "• 'Make Histogram' makes a histogram of the output angles in the map."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Rescale Scans":
			left = 7
			top = 80
			width = 326
			height = 50
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Rescales the selected scans according to the indicated scale factor\r\r"
			message += "• 60µm/V was recently measured for the Ca imaging rig."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			break
		case "Adjust Galvo Distortion":
			left = 7
			top = 285
			width = 326
			height = 210
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Adjusts scan image to compensate for shearing artifacts.\r\r"
			message += "• Select an open image (can be twoPScanGraph) and click 'Auto' to begin.\r"
			message += "• Select several marquee ROIs across the image that have good\r" 
			message += "   vertical dendrites. Add each ROI by clicking the '+' button.\r"
			message += "• Click 'Done' when you're finished with the ROI selection, and a max\r"
			message1 = "   projection and the adjusted image will pop up.\r\r"
			message1 += "• Select the max projection image in the drop down menu, and fine\r"
			message1 += "  tune the parameters manually to optimize the correction.\r\r"
			message1 += "When done, 'Save' the correction, which now will be in the 'Templates' list.\r"
			message1 += "'Use Scan List' or select an open image, then 'Apply Template' to actually\r"
			message1 += "perform the correction. The correction can be performed on multiple scans.\r"
			message2 = "APPLYING A TEMPLATE OVERWRITES THE ORIGINAL DATA!"
			
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+82,message1
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+190,message2
			break
		case "Register Image":
			left = 7
			top = 215
			width = 326
			height = 150
			result = ShowGroupBox(left,top,width,height)
			If(result == -1)
				return 0
			EndIf
			message = "Aligns images in the case of drift across trials.\r\r"
			message += "• Select a reference image that all others will be aligned to.\r"
			message += "• Select an image to be aligned (test image) or use the scan list.\r"
			message += "  Multiple images can be aligned at once.\r\r"
			message += "• Click 'Run' to get the alignment data, now available in the 'Templates' list\r"
			message += "• Apply template will correct the alignment between the reference and test\r"
			message += "   image. THIS WILL OVERWRITE THE ORIGINAL DATA.\r\r"
			message1 = "'Use Scan List' will automatically select the scan's corresponding template."
			SetDrawLayer/W=analysis_tools/K ProgBack
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+5,message
			SetDrawEnv/W=analysis_tools fsize = 10,textyjust=2,fname=font
			DrawText/W=analysis_tools 10,top+130,message1
			break
	endswitch
End

Function ShowGroupBox(left,top,width,height)
	Variable left,top,width,height
	
	//For animated group box
	
	Variable pixelsPerStep = 10
	Variable numSteps = floor(height/pixelsPerStep)
	Variable remainder = mod(height,pixelsPerStep)
	Variable i,currentHeight,pause,startTime,elapsedTime
	
	pause = 1
	
	//show/hide the group box
	ControlInfo/W=analysis_tools AT_HelpBox
	If(V_disable == 1)
		For(i=0;i<numSteps;i+=1)
			currentHeight = i*pixelsPerStep
			GroupBox AT_HelpBox win=analysis_tools,pos={left,top},size={width,currentHeight},disable=0
			
			startTime = ticks
			Do
				//empty loop
			While(ticks - startTime	 < pause)
			ControlUpdate/W=analysis_tools AT_HelpBox
		EndFor
			
		
		GroupBox AT_HelpBox win=analysis_tools,pos={left,top},size={width,height},disable=0
	
		
		return 1
	Else
		GroupBox AT_HelpBox win=analysis_tools,disable=1
		DrawAction/L=ProgBack/W=analysis_tools delete
		return -1
	EndIf
End



//---------------------------------FUNCTIONS---------------------------------

//Recoded version of NMultiROI to keep style consistent
Function GetROI()
	//The ROIs and the scans
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	
	//scan or browser mode?
	SVAR whichList = root:Packages:analysisTools:whichList
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	
	Variable numROIs,numScans,numFrames,doRatio,darkVal,darkVal2,bslnStart,bslnEnd,bsln,bsln2
	Variable TempFilter,smoothSize,getPeaks,pkStart,pkEnd,pkWindow,i,j,k,m,activePixels,activePixelThresh,darkSubtract
	String theROI,theScanName,ROIFolder,dFname,saveDF
	
	String errStr = ""
	String report = ""
	
	//Get the baseline parameters
	ControlInfo/W=analysis_tools bslnStVar
	bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	bslnEnd = V_Value
	ControlInfo/W=analysis_tools peakStVar
	pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	pkEnd = V_Value
	ControlInfo/W=analysis_tools pkWindow
	pkWindow = V_Value
	
	ControlInfo/W=analysis_tools doDarkSubtract
	darkSubtract = V_Value
	
	ControlInfo/W=analysis_tools activePixelsOnly
	activePixels = V_Value
	ControlInfo/W=analysis_tools activePixelThreshSize
	activePixelThresh = V_Value
	
	//Get the peak values?
	ControlInfo/W=analysis_tools getPeaksCheck
	getPeaks = V_Value
	
	//Get the average over the time window?
	ControlInfo/W=analysis_tools doAvgCheck
	Variable doAvg = V_Value
	
	//Average the ROIs that have been selected?
	ControlInfo/W=analysis_tools doAvgROIsCheck
	Variable avgROIs = V_Value

	
	//Get channel - only allows one at a time
	
	If(cmpstr(whichList,"AT") == 0)
		String channel = RemoveEnding(getChannel(1),";")
		If(cmpstr(channel,"ratio") == 0)
			doRatio = 1
		Else
		 	doRatio = 0
		EndIf
	Else
		channel = "ch1"
	EndIf
	
	//Make ROI_analysis folder
	If(!DataFolderExists("root:ROI_analysis"))
		NewDataFolder root:ROI_analysis
	EndIf
	SetDataFolder root:ROI_analysis	
	
	numROIs = ItemsInList(ROIListStr,";")
	
	numScans = ItemsInList(scanListStr,";")

		
	//Divided up by batch?
	ControlInfo/W=analysis_tools BatchsizeVar
	Variable batchSize = V_Value
	If(batchSize == 0 || batchSize < 0 || batchSize == 1)
		batchSize = numScans
	EndIf	
		
	Variable batchCount,counter,nextBatch
	batchCount = 1
	counter = 0
	nextBatch = 0
		
	//LOOP THROUGH SCANS
		For(j=0;j<numScans;j+=1)
			

			//Get the scan
			theScanName = StringFromList(j,scanListStr,";")
			
			If(doRatio)
				//ratio
				Wave/Z theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ch1")
				Wave/Z theScan2 = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ch2")
			
				//does channel 2 scan exist?
				If(!WaveExists(theScan2))
					DoAlert 0,"Couldn't find the scan: " + NameOfWave(theScan2)
					continue
				EndIf
			Else
				//single channel
				Wave/Z theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_" + channel)
			EndIf

			//Does the scan exist?
			If(!WaveExists(theScan))
				DoAlert 0,"Couldn't find the scan: " + NameOfWave(theScan)
				continue
			EndIf
			
			numFrames = DimSize(theScan,2)
			
			//Make the waves to get raw fluorescence data from ROI
			If(doRatio)
				Make/FREE/N=(numFrames) RawROI,RawROI2
				//Set the scale for the raw ROI waves
				SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),RawROI,RawROI2
			Else
				Make/FREE/N=(numFrames) RawROI
				SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),RawROI
			EndIf
			
			//Get the dark values for each channel using a mask
			saveDF = GetDataFolder(1)
				
			Wave darkMask = getDendriticMask(theWave=theScan,noBuffer=0)
			Wave/Z maxProj = maxProj //created by getDendriticMask
			KillWaves/Z maxProj
			
			Redimension/B/U darkMask
			
			ImageStats/R=darkMask theScan
			darkVal = 0.9*V_avg
			
			//create some buffer room so the dark never accidentally gets higher than...
			//...the dendrite background in the case of a dim dendrite
			//darkVal -= 0.1*darkVal
			
			If(doRatio)
				ImageStats/R=darkMask theScan2
				darkVal2 = 0.9*V_avg
			EndIf
			
			KillWaves/Z darkMask
			
			SetDataFolder $saveDF
			 
			//Temporal smoothing
			ControlInfo/W=analysis_tools SmoothBox
			TempFilter = V_Value
			If(V_Value)
				ControlInfo/W=analysis_tools SmoothFilterVar
				smoothSize = V_Value
			EndIf

			
			//LOOP THROUGH ROIs	/////////////////////////////
			For(i=0;i<numROIs;i+=1)
				
				//set the counters
				If(j == batchSize * batchCount && i == 0)
					nextBatch = 1
					counter = 0
				ElseIf(j == batchSize * batchCount + 1) 	//only change batch after all ROIs have been completed
					batchCount += 1
					nextBatch = 0
				EndIf
			
				//Get the ROI
				theROI = StringFromList(i,ROIListStr,";")
				ROIFolder = "root:ROI_analysis:ROI" + theROI
		
				If(!DataFolderExists(ROIFolder))
					NewDataFolder $ROIFolder
				EndIf
				SetDataFolder $ROIFolder
		
				//X and Y waves that define the ROI area
				Wave/Z roiX = $("root:twoP_ROIS:" + theROI + "_x")
				Wave/Z roiY  = $("root:twoP_ROIS:" + theROI + "_y")
		
				//Do the ROI waves exist?
				If(!WaveExists(roiX))
					DoAlert 0,"Couldn't find the ROI X wave: " + NameOfWave(roiX)
					continue
				ElseIf(!WaveExists(roiY))
					DoAlert 0,"Couldn't find the ROI Y wave: " + NameOfWave(roiY)
					continue
				EndIf
				
				//Seed values for filling out the ROI mask
				Variable maskMax,maskMin,xSeed,ySeed
				WaveStats/Q theScan
				
				maskMin = WaveMin(roiX)
				maskMax = WaveMax(roiX)
				
				xSeed = maskMax + DimDelta(theScan,0)
				If(xSeed > IndexToScale(theScan,DimSize(theScan,0)-1,0))
					xSeed = IndexToScale(theScan,0,0)
				EndIf
				
				maskMin = WaveMin(roiY)
				maskMax = WaveMax(roiY)
				
				ySeed = maskMax + DimDelta(theScan,1)
				If(ySeed > IndexToScale(theScan,DimSize(theScan,1)-1,1))
					ySeed = IndexToScale(theScan,0,1)
				EndIf
				
				//ROI mask wave				
				ImageBoundaryToMask ywave=roiY,xwave=roiX,width=(DimSize(theScan,0)),height=(DimSize(theScan,1)),scalingwave=theScan,seedx=xSeed,seedy=ySeed			
			
				Wave ROIMask = $(ROIFolder + ":M_ROIMask")	
				
				//Did the ROI mask actually get created?
				If(!WaveExists(ROIMask))
					DoAlert 0, "Couldn't find the ROI mask wave for: " + NameOfWave(theScan)
					continue
				EndIf
				
				//For using only active pixels within an ROI, trim the ROI around the dendrite here.
				If(activePixels)
					
					Wave ROImaskTrim = $(ROIFolder + ":M_ROIMaskTrim")	
					Duplicate/O ROImask,ROImaskTrim
					
					ImageTransform averageImage theScan
					Wave avgImage = M_AveImage
					Wave stdImage = M_StdvImage
					
					ROImaskTrim = (avgImage > activePixelThresh*darkVal && ROImask == 0) ? ROImaskTrim : 1	
					
					Variable ROIpnts,trimROIpnts
					ImageStats/R=ROImask theScan 
					ROIpnts = V_npnts
					ImageStats/R=ROImaskTrim theScan 
					trimROIpnts = V_npnts
					
					If(trimROIpnts/ROIpnts < 0.1)
					//	DoAlert 0,"Less than 10% of " + theROI + " contains active pixels"
					EndIf
					
					Wave ROImask = ROImaskTrim
				EndIf

				//Average values over the ROI region
				For(k=0;k<numFrames;k+=1)
					ImageStats/M=1/P=(k)/R=ROImask theScan
					RawROI[k] = V_avg

					If(doRatio)
						ImageStats/M=1/P=(k)/R=ROImask theScan2
						RawROI2[k] = V_avg
					EndIf
				EndFor			
				
				//Searches for single frame large values that are more likely instrument noise.
				//Discovered values are set to the local mean
				Variable value,localAvg,sdev
				Wavestats/Q RawROI
				sdev = V_sdev
				For(m=1;m<numFrames-1;m+=1) //avoids end points
					value = RawROI[m]
					localAvg = mean(RawROI,pnt2x(RawROI,m-1),pnt2x(RawROI,m+1))
					If(value > localAvg + 3*sdev)
						RawROI[m] = localAvg
					EndIf
				EndFor

				If(TempFilter)
					Smooth/S=2 (smoothSize), RawROI //Savitzky-Golay smoothing
					SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),RawROI
					
					If(doRatio)
						Smooth/S=2 (smoothSize), RawROI2
						SetScale/P x,DimOffset(theScan2,2),DimDelta(theScan2,2),RawROI2
					EndIf
				EndIf
				
				//Remove the laser response, if any to assist the baseline estimation.
				
				ControlInfo/W=analysis_tools RemoveLaserResponseCheck
				If(V_Value)
					FlattenLaserResponse(RawROI,0,bslnEnd,1,pkStart)
				EndIf			
				
				//Get the baseline value of the trace
				//Use median for the baseline, so it doesn't get pulled up or down from noisy values
				bsln = median(RawROI,bslnStart,bslnEnd)
				
				//Get the red baseline for ratio
				If(doRatio)
					bsln2 = median(RawROI2,bslnStart,bslnEnd)
				EndIf			
				
				//Absolute fluorescence or delta fluorescence?
				ControlInfo/W=analysis_tools dFAbsMenu
				Variable dFAbs = V_Value - 1 //0 = ∆; 1 = Abs; 2 = FFT
				
				
				//Make ∆F/F or ∆G/R waves
				If(cmpstr(whichList,"AT") == 0)
					If(doRatio)
						If(dFAbs == 1)
							dFname = theScanName + "_1_ROI" + theROI + "_absGR"
						Else
							dFname = theScanName + "_1_ROI" + theROI + "_dGR"
						EndIf
					Else
						If(dFAbs == 1)
							dFname = theScanName + "_" + channel + "_ROI" + theROI + "_absF"
						Else
							dFname = theScanName + "_" + channel + "_ROI" + theROI + "_dF"
						EndIf
					EndIf
				ElseIf(cmpstr(whichList,"Browser") == 0)
					//different naming scheme for non-scan list waves that might have different name structures
					dFname = theScanName + "_ROI" + theROI + "_dF"
				EndIF
				
				//Make the dF or dG wave
				Make/O/N=(numFrames) $dFName
				Wave dF = $dFName
				
			
				//Calculate ∆F/F or ∆G/R
				If(doRatio)
					//∆G/R
					
					If(darkSubtract)
						If(dFAbs == 1)
							//absolute fluorescence
							dF = RawROI/(bsln2 - darkVal2)
						Else
							//change fluorescence for both ∆ and FFT modes
							dF = (RawROI - bsln)/(bsln2 - darkVal2)
						EndIf
						
						//calculate FFT if needed (0-10Hz range; 200 points; Hann windowing)
						If(dFAbs == 2)
							//Set scale
							SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),dF
							
							SetDataFolder GetWavesDataFolder(dF,1)
							//execute the DFT macro
							Execute/Q/Z "DFTMagPhase(\"" + NameOfWave(dF) + "\",2,0,10,200,1,1,1)" //(waveName,windowing (2=Hann),low Freq,high Freq,output points,linear/dB,getPhase,unwrap phase)
							GetWindow kwTopWin activeSW
							KillWindow/Z $S_Value
						EndIf
					Else
						If(dFAbs == 1)
							//absolute fluorescence
							dF = RawROI/bsln2						
						Else
							//change fluorescence for both ∆ and FFT modes
							dF = (RawROI - bsln)/bsln2
							
							//calculate FFT if needed (0-10Hz range; 200 points; Hann windowing)
							If(dFAbs == 2)
								//Set scale
								SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),dF
				
								SetDataFolder GetWavesDataFolder(dF,1)
								//execute the DFT macro
								Execute "DFTMagPhase(\"" + NameOfWave(dF) + "\",2,0,10,200,1,1,1)" //(waveName,windowing (2=Hann),low Freq,high Freq,output points,linear/dB,getPhase,unwrap phase)
								GetWindow kwTopWin activeSW
								KillWindow/Z $S_Value
							EndIf
							
						EndIF
					EndIf
				Else
					//∆F/F
					If(darkSubtract)
						If(dFAbs == 1)
							//absolute fluorescence
							dF = RawROI - darkVal
						Else
							//change fluorescence
							dF = (RawROI - bsln)/(bsln - darkVal) 
						EndIf
						
						//calculate FFT if needed (0-10Hz range; 200 points; Hann windowing)
						If(dFAbs == 2)
							//Set scale
							SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),dF
				
							SetDataFolder GetWavesDataFolder(dF,1)
							//execute the DFT macro
							Execute "DFTMagPhase(" + NameOfWave(dF) + ",2,0,10,200,1,1,1)" //(waveName,windowing (2=Hann),low Freq,high Freq,output points,linear/dB,getPhase,unwrap phase)
							GetWindow kwTopWin activeSW
							KillWindow $S_Value
						EndIf
						
					Else
						If(dFAbs == 1)
							//absolute fluorescence
							dF = RawROI
						Else
							//change fluorescence
							dF = (RawROI - bsln)/bsln 
						EndIf
						
						//calculate FFT if needed (0-10Hz range; 200 points; Hann windowing)
						If(dFAbs == 2)
							//Set scale
							SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),dF
				
							SetDataFolder GetWavesDataFolder(dF,1)
							//execute the DFT macro
							Execute "DFTMagPhase(" + NameOfWave(dF) + ",2,0,10,200,1,1,1)" //(waveName,windowing (2=Hann),low Freq,high Freq,output points,linear/dB,getPhase,unwrap phase)
							GetWindow kwTopWin activeSW
							KillWindow $S_Value
						EndIf
					EndIf
				EndIf
				
				//Set scale
				SetScale/P x,DimOffset(theScan,2),DimDelta(theScan,2),dF
				
				
				////////////////////////////////////////////////////
				//Gets the peak ∆F values for the list for the scan list
				If(getPeaks)
					
					//Start a new peak ∆F wave?
					If(j == 0 || nextBatch == 1)
						String baseName = theScanName
						
						If(doRatio)
							String peakDFname = baseName + "_1_ROI" + theROI + "_dGR_pk"
						Else
							peakDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_pk"
						EndIf
						
						Make/O/N=(batchSize) $peakDFname			
					Else
						If(doRatio)
							peakDFname = baseName + "_1_ROI" + theROI + "_dGR_pk"
						Else
							peakDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_pk"
						EndIf
					EndIf
					
					Wave/Z peakDF = $peakDFname
			
					If(!WaveExists(peakDF))
						DoAlert 0,"Couldn't find the peak ∆F wave."
						continue
					EndIf
			
					peakDF[counter] = getPeakVals(dF,pkStart,pkEnd,pkWindow)
				EndIf
				
				/////////////////SS edit 30 Dec 2018////////////////////
				Note/K $dFname // kill existing note
				WaveStats/Q/R=(bslnStart,bslnEnd) DF
				
				Note $dFname,"peak:"+num2str(getPeakVals(dF,pkStart,pkEnd,pkWindow))+";"+"PeakTime:"+num2str(getPeakVals(dF,pkStart,pkEnd,pkWindow,getPkTm = 1))+";"+"bslnSD:"+num2str(V_sdev)+";"+"WindowAVG:"+num2str(V_avg)+";"
				
				/////////////////SS edit 30 Dec 2018////////////////////
				
				If(doAvg)
					If(j == 0 || nextBatch == 1)
						baseName = theScanName
						If(doRatio)
							String tavgDFname = baseName + "_1_ROI" + theROI + "_dGR_tavg"
						Else
							tavgDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_tavg"
						EndIf
						Make/O/N=(batchSize) $tavgDFname	
					Else
						If(doRatio)
							tavgDFname = baseName + "_1_ROI" + theROI + "_dGR_tavg"
						Else
							tavgDFname = baseName + "_" + channel + "_ROI" + theROI + "_dF_tavg"
						EndIf
					EndIf
				
					Wave/Z tavgDF = $tavgDFname
			
					If(!WaveExists(tavgDF))
						DoAlert 0,"Couldn't find the time average ∆F wave."
						continue
					EndIf
				
					tavgDF[counter] = mean(dF,pkStart,pkEnd)
				EndIf
					
					////REORDER THE PEAK DATA///////////////////////////////
					If(counter == batchSize - 1) //If we're at the end of a batch				
						//rearrange the peak data points according to the angle list
						If(getPeaks)
							If(batchSize > 1)
								Redimension/N=(batchSize) peakDF	
								Variable theSize = batchSize
							Else
								Redimension/N=(numScans) peakDF		
								theSize = numScans
							EndIf
							
							Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
							ControlInfo/W=analysis_tools presetAngleListPop
		
							If(V_Value != 1)
								String angleList = presetAngleWave[V_Value-1][1]
								Make/FREE/N=(theSize) order
								
								If(batchSize > 1)
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=1)
								Else
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=0)
								EndIf
															
								Make/FREE/N=(theSize) tempPeak

								For(m=0;m<theSize;m+=1)
									tempPeak[m] = peakDF[theOrderWave[m]]
								EndFor
								peakDF = tempPeak
							EndIf
						EndIf
						
						//rearrange the time average data points according to the angle list
						If(doAvg)
							If(batchSize > 1)
								Redimension/N=(batchSize) tavgDF	
								theSize = batchSize
							Else
								Redimension/N=(numScans) tavgDF		
								theSize = numScans
							EndIf
						
							Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
							ControlInfo/W=analysis_tools presetAngleListPop
	
							If(V_Value != 1)
								angleList = presetAngleWave[V_Value-1][1]
								Make/FREE/N=(theSize) order
								
 								If(batchSize > 1)
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=1)
								Else
									Wave theOrderWave = GetOrderFromAngleList(angleList,order,useBatch=0)
								EndIf
								
								Make/FREE/N=(theSize) tempPeak

								For(m=0;m<theSize;m+=1)
									tempPeak[m] = tavgDF[theOrderWave[m]]
								EndFor
								tavgDF = tempPeak
								
							EndIf
						EndIf
						//////////////	
					EndIf	
					
					//Set the wave notes
					If(getPeaks)
						Note/K peakDF//kill existing note
						SetWaveNote(peakDF,"baseline;peak;smooth;channel;peakWidth")
					EndIf
					
					If(doAvg)
						Note/K tavgDF//kill existing note
						SetWaveNote(tavgDF,"baseline;peak;smooth;channel;peakWidth")
					EndIf
					
					//clean up
					KillWaves/Z avgImage,stdImage//,ROImaskTrim
			EndFor	
			counter += 1
	EndFor	


	If(avgROIs)
		avgROIWaves(ROIListStr,scanListStr,channel,DimSize(theScan,2))
	EndIf
End

//Takes multiROI waves and averages them for each ROI separately
Function avgROIWaves(ROIListStr,scanListStr,channel,scanSize)
	String ROIListStr,scanListStr,channel
	Variable scanSize
	
	Variable i,j,numROIs,numScans
	String theROI,theScan,baseName,avgDFName,theROIName
	
	numROIs = ItemsInList(ROIListStr,";")
	numScans = ItemsInList(ScanListStr,";")
	
	baseName = StringFromList(0,ScanListStr,";")
	
	For(i=0;i<numROIs;i+=1)
		theROI = StringFromList(i,ROIListStr,";")
		
		If(cmpstr(channel,"ratio") == 0)
			//dGR
			avgDFName = "root:ROI_analysis:ROI" + theROI + ":" + baseName + "_1" + "_ROI" + theROI + "_dGR_avg"
		Else
			//dF
			avgDFName = "root:ROI_analysis:ROI" + theROI + ":" + baseName + "_" + channel + "_ROI" + theROI + "_dF_avg"
		EndIf
		Make/O/N=(scanSize) $avgDFName
		Wave/Z avgDF = $avgDFName
		avgDF = 0
		
		For(j=0;j<numScans;j+=1)
			theScan = StringFromList(j,ScanListStr,";")
			If(cmpstr(channel,"ratio") == 0)
				theROIName = "root:ROI_analysis:ROI" + theROI + ":" + theScan + "_1" + "_ROI" + theROI + "_dGR"
			Else
				//dF
				theROIName = "root:ROI_analysis:ROI" + theROI + ":" + theScan + "_" + channel + "_ROI" + theROI + "_dF"
			EndIf
			
			Wave/Z theROIWave = $theROIName
			avgDF += theROIWave
		
			//sets the wave notes
			If(j == 0)
				Note/K avgDF,"Averaged Waves: " + num2str(numScans)
				Note avgDF,NameOfWave(theROIWave)
			Else
				Note avgDF,NameOfWave(theROIWave)
			EndIf
		EndFor
		//does average
		avgDF /= numScans
		//sets scale
		SetScale/P x,DimOffset(theROIWave,0),DimDelta(theROIWave,0),avgDF
	EndFor
End


//Called by getROI() to get the peak values of the ROIs
Function getPeakVals(inWave,pkStart,pkEnd,pkWindow[,getPkTm])
	Wave inWave
	Variable pkStart,pkEnd,pkWindow,getPkTm
	Variable pkLoc,peakVal
	
	WaveStats/Q/R=(pkStart,pkEnd) inWave
	pkLoc = V_maxLoc
	
	//if pkWindow is 0, it just takes the absolute peak instead of averaging over a range around the peak location.
	If(pkWindow != 0)
		peakVal = mean(inWave,pkLoc - 0.5*pkWindow,pkLoc + 0.5*pkWindow)
	Else
		peakVal = V_max
	EndIf
	
	If(ParamIsDefault(getPkTm))
		return peakVal
	Else
		return pkLoc
	EndIf
End

//Take ROIs, and finds their pk times for corresponding dF waves, puts values into a 2D matrix wave for mapping
Function ROIgrid_pktm(gridMask,startTm,endTm,threshold,fit,leftExclude)
	Wave gridMask
	Variable startTm,endTm,threshold
	String fit
	Variable leftExclude
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable numROIs = ItemsInList(ROIListStr,";")
	Variable numScans =ItemsInList(scanListStr,";")
	Variable i,j,m,n,xDim,yDim,thePkTm
	String theROIName,theScanName,theWaveName
	
	Duplicate/FREE gridMask,testMask
	
	If(!DataFOlderExists("root:ROI_analysis:grid"))
		NewDataFolder root:ROI_analysis:grid	
	EndIf
	SetDataFolder root:ROI_analysis:grid
	
	xDim = DimSize(gridMask,0)
	yDim = DimSize(gridMask,1)
	
	For(i=0;i<numScans;i+=1)
		theScanName = StringFromList(i,scanListStr,";")
		//Make the grid wave for the scan to hold the peak times
		Make/O/N=(xDim,yDim) $(theScanName + "_grid_pktm")
		Wave grid = $(theScanName + "_grid_pktm")
		grid = 0
		
		For(j=0;j<numROIs;j+=1)
			//Get the dF wave for the selected scan and ROI
			theROIName = StringFromList(j,ROIListStr,";")

			theWaveName = "root:ROI_analysis:" + "ROI" + theROIName + ":" + theScanName + "_ch1_ROI" + theROIName + "_dF"
			Wave/Z theWave = $theWaveName
			If(!WaveExists(theWave))
				Abort "Cannot find the wave: " + theWaveName
			EndIf
			
			thePkTm = getPeakVals(theWave,startTm,endTm,0,getPkTm=1)	//gets the x location of the peak dF
			
			Variable	done = 0
			For(m=0;m<xDim;m+=1)
				For(n=0;n<yDim;n+=1)
					If(testMask[m][n] == 1)
						WaveStats/Q/R=(startTm,endTm) theWave
						Variable maxVal = V_max
						WaveStats/Q theWave
						Variable sdev = V_sdev
						If(maxVal < threshold*sdev)
							grid[m][n] = 0
						Else
							//find rise time using sigmoidal fit
							strswitch(fit)
								case "":
								case "none":
									break
								case "sigmoid":
									Variable peakIndex = ScaleToIndex(theWave,thePkTm,0)
									Make/O/N=(DimSize(theWave,0)) root:ROI_analysis:grid:theFit
									//attempt a fit up to the peak time to get the rise time
									try
										//Takes the fit 30% between 0 and the start tm all the way to the peak time.
										CurveFit/Q/M=2/W=2/X Sigmoid, theWave[ScaleToIndex(theWave,startTm/3,0),peakIndex]/D=root:ROI_analysis:grid:theFit
										AbortOnRTE
									catch
										done = 1
										break
									endtry
																		
									Wave theFit = $("root:ROI_analysis:grid:theFit")
									SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theFit
									FindLevel/Q theFit,0.5*WaveMax(theFit)
									thePkTm = V_LevelX
									KillWaves/Z theFit
									break
							endswitch
						
							If(thePkTm < leftExclude)
								grid[m][n] = 0
							Else					
								grid[m][n] = thePkTm
							EndIf
						EndIf
						testMask[m][n] = 0
						done = 1
					EndIf
					If(done)
						break
					EndIf
				EndFor
				If(done)
					break
				EndIf
			EndFor
			
		EndFor
	EndFor

	grid = (grid == 0) ? nan : grid
	SetScale/P x,DimOffset(gridMask,0),DimDelta(gridMask,0),grid
	SetScale/P y,DimOffset(gridMask,1),DimDelta(gridMask,1),grid
End



//Generates tuning curve for selected scans in the selected ROI
Function roiTuningCurve()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd
	
	Variable i,j,k,theArea
	String ROI,dataFolder,scanName,angleList,tuningCurveName
	
	CONTROLINFO/W=analysis_tools angleList
	angleList = S_Value
	
	ControlInfo/W=analysis_tools BatchsizeVar
	Variable batchSize = V_Value
	
	For (i=0;i<ItemsInList(ROIListStr,";");i+=1)
		ROI = "ROI" + StringFromList(i,ROIListStr,";")
		dataFolder = "root:NEW_ROI_analysis:" + ROI
		
		//Check ROI analysis folder exists
		If(!DataFolderExists(dataFolder))
			print "ROI data folder",dataFolder,"does not exist"
			return -1
		Else
			SetDataFolder $dataFolder
		EndIf
		
		//Check that ROI scan wave exists
		For(j=0;j<ItemsInList(scanListStr,";");j+=1)
				
			//Get the angle ordering
			Make/O/N=(ItemsInList(scanListStr,";")) $(dataFolder + "order")
			Wave order = $(dataFolder + "order")
			If(strlen(angleList))
				If(batchSize > 1)
					GetOrderFromAngleList(angleList,order,useBatch=1)
				Else
					GetOrderFromAngleList(angleList,order,useBatch=0)
				EndIf
			Else
				order = x
			EndIf
			
			//Get scan name according to the specified angle order
			scanName = StringFromList(order[j],scanListStr,";") + ROI
			
			If(WaveExists($scanName))
				Wave scanWave = $scanName
			Else
				print "Scan wave",scanName,"in folder",dataFolder,"does not exist"
				return -1
			EndIf
			
			//Make output tuning curve wave on first pass
			If(j == 0)
				tuningCurveName = "DStuning_" + scanName
				Make/O/N=(ItemsInList(scanListStr,";")) $tuningCurveName
				Wave tuningCurve = $tuningCurveName
			EndIf

			//Valid range checks
			If(GpeakEnd > DimSize(scanWave,0))
				GpeakEnd = DimSize(scanWave,0) - 1
			EndIf
			
			If(GpeakSt >  DimSize(scanWave,0))
				print "Start point is out of scan wave range"
				return -1
			ElseIf(GpeakSt < 0)
				GpeakSt = 0
			EndIf
			
			//Find integral of the indicated range of the ROI scan wave
			tuningCurve[j] = area(scanWave,pnt2x(scanWave,GpeakSt),pnt2x(scanWave,GpeakEnd))
		EndFor
		
		//Get dimensions for the tuning curve
		Make/FREE/N=(ItemsInList(angleList,",")) angleListWave
		For(k=0;k<ItemsInList(angleList,",");k+=1)
			angleListWave[k] = str2num(StringFromList(k,angleList,","))
		EndFor
		SetScale/I x,WaveMin(angleListWave),WaveMax(angleListWave),tuningCurve
	EndFor
	
End

//Takes input waves and finds the peak, puts results in a single output wave
Function getPeaks()
	//Get wave paths for analysis
	String theWaveList = getWaveNames()
	
	//Variables
	String outWaveName
	Variable xStart,xEnd,baseLineStart,baseLineEnd,numWaves,i

	ControlInfo/W=analysis_tools peakStVar
	xStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	xEnd = V_Value
	ControlInfo/W=analysis_tools bslnStVar
	baseLineStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	baseLineEnd = V_Value
	
	numWaves = ItemsInList(theWaveList,";")
	
	//make output wave
	outWaveName = ParseFilePath(0,StringFromList(0,theWaveList,";"),":",1,0)
	outWaveName = ReplaceString(StringFromList(0,outWaveName,"_"),outWaveName,"Pk")
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	Make/O/N=(numWaves) $outWaveName
	Wave outWave = $outWaveName
	
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		outWave[i] = WaveMax(theWave,xStart,xEnd) - mean(theWave,baseLineStart,baseLineEnd)
	EndFor
End

Function getPeakValues()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd
	
	Variable i,j,k,theArea
	String ROI,dataFolder,scanName,angleList,outputWaveName
	
	CONTROLINFO/W=analysis_tools angleList
	angleList = S_Value
	
	For (i=0;i<ItemsInList(ROIListStr,";");i+=1)
		ROI = "ROI" + StringFromList(i,ROIListStr,";")
		dataFolder = "root:ROI_analysis:" + ROI
		
		//Check ROI analysis folder exists
		If(!DataFolderExists(dataFolder))
			print "ROI data folder",dataFolder,"does not exist"
			return -1
		Else
			SetDataFolder $dataFolder
		EndIf
		
		//Check that ROI scan wave exists
		For(j=0;j<ItemsInList(scanListStr,";");j+=1)
			
			//Get scan name for the selected channel
			String suffix
			ControlInfo/W=analysis_tools ratioCheck
			If(V_Value)
				suffix = "_dGR"
			Else
				ControlInfo/W=analysis_tools ch1Check
				If(V_Value)
					suffix = "_dF"
				Else
					ControlInfo/W=analysis_tools ch2Check
					If(V_Value)
						suffix = "_dF"
					EndIf
				EndIf
			EndIf
			string channel = RemoveEnding(getChannel(1),";")
			
			scanName = StringFromList(j,scanListStr,";") + "_" + channel + suffix + "_" + ROI
			
			//Scan exists?
			If(WaveExists($scanName))
				Wave scanWave = $scanName
			Else
				print "Scan wave",scanName,"in folder",dataFolder,"does not exist"
				return -1
			EndIf
			
			//Make output wave on first pass
			If(j == 0)
				outputWaveName = scanName + "_peak"
				Make/O/N=(ItemsInList(scanListStr,";")) $outputWaveName
				Make/O/N=1 $(outputWaveName + "AVG"),$(outputWaveName + "SEM")
				Wave outWave = $outputWaveName
				Wave avgWave = $(outputWaveName + "AVG")
				Wave semWave = $(outputWaveName + "SEM")
			EndIf

			//Valid range checks
			If(GpeakEnd > DimSize(scanWave,0))
				GpeakEnd = DimSize(scanWave,0) - 1
			EndIf
			
			If(GpeakSt >  DimSize(scanWave,0))
				print "Start point is out of scan wave range"
				return -1
			ElseIf(GpeakSt < 0)
				GpeakSt = 0
			EndIf
			
			//Find peak of the indicated range of the ROI scan wave
			outWave[j] = WaveMax(scanWave,GpeakSt,GpeakEnd)
		EndFor
	EndFor
	WaveStats/Q outWave
	avgWave[0] = V_avg
	semWave[0] = V_sem
End



////////////////////////////////////////////////
Function DarkROI(darkValue)
	Variable darkValue

SVAR FirstScanName = root:packages:twoP:examine:curScan
wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
string channel = "ch1"
string ROIname
variable ROIList, run = 0

for (ROIList = 0; ROIList < numpnts(ROIListWave); ROIList+=1)
	ROIname = ROIListWave[ROIList]

	if(cmpstr(ROIname, "Dark")==0)

		wave roiY = root:twoP_ROIS:Dark_y
		wave roiX = root:twoP_ROIS:Dark_x
		wave Matrix = $("root:twoP_Scans:" +FirstScanName + ":" + FirstScanName + "_" + channel)  	

		ImageBoundaryToMask ywave=roiY,xwave=roiX,width=(dimSize(Matrix,0)),height=(dimSize(Matrix,1)),scalingwave=Matrix,seedx=(dimOffset(Matrix,0)+dimDelta(Matrix,0)),seedy=(dimOffset(Matrix,1)+dimDelta(Matrix,1))
		WAVE M_ROIMask	

		ImageStats/R=M_ROIMask Matrix

		darkValue = V_avg
		print darkValue
		run+=1
	else
	endif
endfor

if (run != 1)
	print 	"Dark ROI not found"
endif

end



Function circleROI(diameter,xInd,yInd)
	Variable diameter,xInd,yInd
	Wave/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	SetDataFolder root:twoP_ROIS
	
	//make into an ROI
	String ROIName = "circle" + num2str(diameter) + "_x"
	Make/O/N=50 $ROIName
	Wave ROIx = $ROIName
	ROIName = "circle" + num2str(diameter) + "_y"
	Make/O/N=50 $ROIName
	Wave ROIy = $ROIName
	String theScanName = StringFromList(0,scanListStr,";")
	Wave theScan = $("root:twoP_Scans:" + theScanName + ":" + theScanName + "_ch1")
	
	//Scale the ROIs correctly
	Variable yPos,xPos,left,right,bottom,top
	xPos = IndexToScale(theScan,xInd,0)
	yPos = IndexToScale(theScan,yInd,1)
	left = xPos - 0.5*diameter*DimDelta(theScan,0)
	right = xPos + 0.5*diameter*DimDelta(theScan,0)
	bottom = yPos - 0.5*diameter*DimDelta(theScan,1)
	top = yPos + 0.5*diameter*DimDelta(theScan,1)
	
	//make the circle
	ROIx = left +  0.5*(right-left) + 0.5*(right-left)*cos(2*pi*x/50)
	ROIy = bottom + 0.5*(top-bottom) + 0.5*(top-bottom)*sin(2*pi*x/50)
	
	Redimension/N=(DimSize(ROIListWave,0) + 1) ROIListWave,ROIListSelWave
	ROIListWave[DimSize(ROIListWave,0) - 1] = "circle" + num2str(diameter)
End


//Makes a grid of square ROIs across an image, only at locations within a defined mask
//or where there is high enough baseline fluorescence (dendrite).
Function gridROI()//theMask,size)
	//Get parameters from the analysis tools window
	ControlInfo/W=analysis_tools gridSizeX
	Variable sizeX = V_Value
	
	ControlInfo/W=analysis_tools gridSizeY
	Variable sizeY = V_Value

	ControlInfo/W=analysis_tools overwriteGrid
	Variable overwrite = V_Value
	
	//Optimize the position of each ROI to maximize pixels with activity.
	ControlInfo/W=analysis_tools optimizePosition
	Variable optimizePos = V_Value
	
	ControlInfo/W=analysis_tools pctOverlap
	Variable overlapPct = V_Value/100
	
	ControlInfo/W=analysis_tools pixelThresholdPct
	Variable thresholdPct = V_Value/100//0% means there is no threshold
	
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	String selectedScanStr = "root:twoP_Scans:" + StringFromList(0,scanListStr,";") + ":" + StringFromList(0,scanListStr,";") + "_ch1"
	
	
	ControlInfo/W=analysis_tools maskListPopUp
	Variable scanPosition = WhichListItem("Scan",S_Value,"_")
	
	If(scanPosition != -1)
		String theScanStr = RemoveEnding(ParseFilePath(1,S_Value,"_",0,scanPosition+2),"_")
		SetDataFolder root:twoP_Scans:$theScanStr
	EndIf
	
	//If there is no mask, make one
	Wave/Z theMask = $S_Value
	If(!WaveExists(theMask))
		Wave theScan = $selectedScanStr
		If(!WaveExists(theScan))
			Abort "Couldn't find the scan wave " + NameOfWave(theScan) + " for masking"
		EndIf
		Checkbox ratioCheck win=analysis_tools,value=0
		Wave theMask =	getDendriticMask(theWave=theScan)
	EndIf
	

	Variable xDim,yDim,remainderX,remainderY,xSteps,ySteps,i,j,avg,count,seedX,seedY,areaAvg
	String ROIName

	Wave/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	
	//Overwrite previous ROI grid?
	If(overwrite)
		deleteGridROI(ROIListWave,ROIListSelWave)
	EndIf
	
	
	Variable endX,endY,startX,startY
	
	xDim = DimSize(theMask,0)
	yDim = DimSize(theMask,1)
	
	xSteps = floor(xDim/sizeX)
	ySteps = floor(yDim/sizeY)
	remainderX = mod(xDim,sizeX)
	remainderY = mod(yDim,sizeY)
	
	Make/FREE/N=(sizeX,sizeY) buffer
	If(!DataFolderExists("root:ROI_analysis"))
		NewDataFolder root:ROI_analysis
	EndIf
	
	If(!DataFolderExists("root:ROI_analysis:grid"))
		NewDataFolder root:ROI_analysis:grid
	EndIf
	
	If(overwrite)	
		Make/O/N=(xSteps,ySteps) root:ROI_analysis:grid:grid_ROIMask
		Wave grid_ROIMask = root:ROI_analysis:grid:grid_ROIMask
	Else
		If(WaveExists(root:ROI_analysis:grid:grid_ROIMask))
			String gridName = "root:ROI_analysis:grid:" + UniqueName("grid_ROIMask",1,0)
			Make/O/N=(xSteps,ySteps) $gridName
			Wave grid_ROIMask = $gridName
		Else
			Make/O/N=(xSteps,ySteps) root:ROI_analysis:grid:grid_ROIMask
			Wave grid_ROIMask = root:ROI_analysis:grid:grid_ROIMask
		EndIf
	EndIf
	
	
	
	Variable gridX,gridY
	
	SetDataFolder root:twoP_ROIS
	
	//If not overwriting, find pre-existing grid ROIs and get the largest grid index
	Variable maxIndex = 0
	If(!overwrite)
		For(i=0;i<DimSize(ROIListWave,0);i+=1)
			String theROI = ROIListWave[i]
			If(stringmatch(theROI,"grid*"))
				Variable gridIndex = str2num(theROI[4,strlen(theROI)-1])
				If(gridIndex > maxIndex)
					maxIndex = gridIndex
				EndIf
			EndIf
		EndFor
		
		count = maxIndex + 1
	Else
		count = 0
	EndIf
	
	gridX = 0
	
	If(optimizePos)
		Make/FREE/N=(xDim,yDim) usedPixels
		Make/FREE/N=(sizeX,sizeY) theArea
		usedPixels = 0
		theArea = 0
	EndIf
	
	i = 0
	j = 0
	
	Variable initROI = count
	Variable numROIs = 0
	String gridROIList = ""
	
	Do
		gridY = 0
		j = 0
		Do	
			buffer = theMask[p + i][q + j]	//extract the square of data points
			avg = mean(buffer)	//avg is greater than 0 if it contains a non-masked point
		
			If(avg >= thresholdPct)	//% of pixels have values
				grid_ROIMask[gridX][gridY] = 1
				
				Redimension/N=(DimSize(ROIListWave,0) + 1) ROIListWave,ROIListSelWave
				ROIListWave[DimSize(ROIListWave,0) - 1] = "grid" + num2str(count)
				
				//make into an ROI
				ROIName = "grid" + num2str(count) + "_x"
				gridROIList += "root:twoP_ROIS:" + ROIName + ";" //for making different colors
				Make/O/N=5 $ROIName
				Wave ROIx = $ROIName
				ROIName = "grid" + num2str(count) + "_y"
				Make/O/N=5 $ROIName
				Wave ROIy = $ROIName
				
				ROIx[0] = IndexToScale(theMask,i,0)
				ROIx[1] = IndexToScale(theMask,i,0)
				ROIx[2] = IndexToScale(theMask,i + sizeX,0)
				ROIx[3] = IndexToScale(theMask,i + sizeX,0)
				ROIx[4] = IndexToScale(theMask,i,0)
				ROIy[0] = IndexToScale(theMask,j,1)
				ROIy[1] = IndexToScale(theMask,j + sizeY,1)
				ROIy[2] = IndexToScale(theMask,j + sizeY,1)
				ROIy[3] = IndexToScale(theMask,j,1)
				ROIy[4] = IndexToScale(theMask,j,1)
					
				count += 1
				numROIs += 1
			Else
				grid_ROIMask[gridX][gridY] = 0
			EndIf
	
			gridY += 1
		
			j += sizeY
		While(j + sizeY < yDim - 1)
		
		gridX += 1
				
		i += sizeX
	While(i + sizeX < xDim - 1)
	
	//Scale the ROI grid mask
	Variable stepScaleX = DimDelta(theMask,0) * sizeX
	Variable stepScaleY = DimDelta(theMask,1) * sizeY
	
	startX = DimOffset(theMask,0) + 0.5*sizeX*DimDelta(theMask,0) 
	endX = startX + (xSteps-1)*stepScaleX
	startY =  DimOffset(theMask,1) + 0.5*sizeY*DimDelta(theMask,1) 
	endY = startY + (ySteps-1)*stepScaleY

	SetScale/I x,startX,endX,grid_ROIMask
	SetScale/I y,startY,endY,grid_ROIMask
	
	//Set color of every grid ROI in existence
	ControlInfo/W=analysis_tools colorROIs
	SetDataFolder root:
	ColorTab2Wave rainbow
	Wave rainbowWave = root:M_Colors
		
	String r,g,b
	Variable size = DimSize(rainbowWave,0)
	For(i=0;i<numROIs;i+=1)
		Variable index = round(i * (size-1)/numROIs)
		r = num2str(rainbowWave[index][0])
		g = num2str(rainbowWave[index][1])
		b = num2str(rainbowWave[index][2])
		Note/K/NOCR $StringFromList(i,gridROIList,";"),"WaveType:ROIsquare;Red:" + r + ";green:" + g + ";Blue:" + b + ";"
	EndFor
	//Cleanup 
	KillWaves/Z theMask
End

//Takes the time-varying ROI data from GetROI(), and identifies ROIs that have no signal
//Use the Scan List and ROI List to define the waves to use for filtering
Function filterROI()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	
	Variable numScans,numROIs,i,j,noise,signal,snr,passed = 0
	String theScanName,theROI,channel,theName,list=""
	
	numScans = ItemsInList(scanListStr,";")
	numROIs = ItemsInList(ROIListStr,";")
	channel = RemoveEnding(getChannel(1),";") //what channel are we using?
	
	ControlInfo/W=analysis_tools bslnStVar
	Variable bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	Variable bslnEnd = V_Value
	ControlInfo/W=analysis_tools peakStVar
	Variable pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	Variable pkEnd = V_Value
	ControlInfo/W=analysis_tools roiThreshold
	Variable roiThreshold = V_Value
	ControlInfo/W=analysis_tools thresholdType
	String thresholdType = S_Value
	
	
	
	For(i=0;i<numROIs;i+=1)
		//get the ROI name
		theROI = StringFromList(i,ROIListStr,";")
		passed = 0
		For(j=0;j<numScans;j+=1)
			//get the scan name
			theScanName = StringFromList(j,scanListStr,";")
				
			strswitch(channel)
				case "ch1":
				case "ch2":
					String suffix = "dF"
					break
				case "ratio":
					suffix = "dGR"
					channel = "1" //avoids putting 'ratio' as part of the name, since its dG/R
					break
			endswitch
			
			//determine the GetROI wave name
			theName = "root:ROI_analysis:" + "ROI" + theROI + ":" + theScanName + "_" + channel + "_" + "ROI" + theROI + "_"
			theName += suffix
			
			//Does the wave exist?
			Wave/Z theWave = $theName
			If(!WaveExists(theWave))
				//try unbuffering scan list zeros to get the correct name
				String str = StringFromList(1,theScanName,"_")
				str = num2str(str2num(str))
				theScanName = RemoveListItem(1,theScanName,"_")
				theScanName = AddListItem(str,theScanName,"_",1)
				theScanName = RemoveEnding(theScanName,"_")
				theName = "root:ROI_analysis:" + "ROI" + theROI + ":" + theScanName + "_" + channel + "_" + "ROI" + theROI + "_" + suffix
				Wave/Z theWave = $theName
				If(!WaveExists(theWave))
					print "ERROR: Couldn't find the wave: " + theName
					continue
				EndIf
			EndIf
			
			strswitch(thresholdType)
				case "∆F/F":
					Variable theMax = WaveMax(theWave,pkStart,pkEnd)
					//Doesn't reach threshold
					If(theMax > roiThreshold)
						passed = 1
					EndIf
					break
				case "SNR":
					//Get stdev of the baseline noise section
					WaveStats/Q/R=(bslnStart,bslnEnd) theWave
					noise = V_sdev
					
					//Get mean of the signal section
					WaveStats/Q/R=(pkStart,pkEnd) theWave
					signal = V_max // incorporates both peak and average over the time interval
					
					snr = (signal^2)/(noise^2)
					
					//Doesn't reach threshold
					If(snr > roiThreshold)
						passed = 1	
					EndIf
					
					break
			endswitch
		EndFor
		
		//If the ROI passed threshold for any one of the scans, then it passes the test. 
		If(!passed)
			list += theROI + ","
		EndIf
	EndFor
	
	list = RemoveEnding(list,",")
	
	If(strlen(list))
		String promptStr = list + "\nThese ROIs didn't reach threshold. Discard them?"
		DoAlert/T="Discard ROIs?" 1,promptStr
	Else
		print "All ROIs passed the threshold"
	EndIf
	
	print "\nThe following ROIs didn't reach threshold:\n" + list
	
	If(V_flag == 1)
	//yes clicked
		deleteROI(list=list)
		//Remove deleted ROIs from ROIListStr automatically
		For(i=ItemsInList(list,",");i>-1;i-=1)//count down
			theROI = StringFromList(i,list,",")
			ROIListStr = RemoveFromList(theROI,ROIListStr,";")
		EndFor
	ElseIf(V_flag == 2)
	//no clicked, mark the ROIs as a different color on twoPScanGraph. Yellow.
		
		//Try the different channels for ROI traces
		String traceList = TraceNameList("twoPscanGraph#GCH1",";",3)
		If(!strlen(traceList))
			traceList = TraceNameList("twoPscanGraph#GCH2",";",3)
			String theGraph = "twoPscanGraph#GCH2"
		Else
			theGraph = "twoPscanGraph#GCH1"
		EndIf
		
		If(!strlen(traceList))
			traceList = TraceNameList("twoPscanGraph#GMRG",";",3)
			theGraph = "twoPscanGraph#GMRG"
		EndIf
		
		//Set all colors to cyan
		ModifyGraph/W=$theGraph rgb=(0,65535,65535)
		
		//set marked ROIs to yellow
		For(i=0;i<ItemsInList(list,",");i+=1)
			theROI = StringFromList(i,list,",") + "_y"
			ModifyGraph/W=$theGraph rgb($theROI)=(65535,65535,0)
		EndFor
		
	EndIf
End

//Displays ROI scans and arranges them for easy viewing and comparison
Function displayROIs()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	
	String horArrange,vertArrange,ROI,Scan,Path,leftAxis,bottomAxis
	String scanOrderStr,roiOrderStr, WindowName //SS edit NOV5 2018
	Variable numScans,numROIs,numTraces,horDim,vertDim,horDelta,vertDelta,i,j,count
	Variable maxValue,minValue,startLeft,endLeft,startBottom,endBottom,numHorAxes,numVertAxes
	Variable doAverages
	
	ControlInfo/W=analysis_tools horDisplayArrangementPopUp
	horArrange = S_Value
	ControlInfo/W=analysis_tools vertDisplayArrangementPopUp
	vertArrange = S_Value
	ControlInfo/W=analysis_tools dispAveragesCheck
	doAverages = V_Value
	
	numScans = ItemsInList(scanListStr,";")
	numROIs = ItemsInList(ROIListStr,";")
	numTraces = numScans * numROIs
	
	//Handle the wave ordering
	Variable k
	
	ControlInfo/W=analysis_tools scanOrderROIdisplay
	scanOrderStr = S_Value
	
	//////////SS edit NOV5 2018////////////////////////
	ControlInfo/W=analysis_tools graphName
	WindowName = S_Value
	//////////SS edit NOV5 2018////////////////////////
	
	Make/FREE/N=(ItemsInList(scanOrderStr,",")) scanOrderWave
	Make/FREE/N=(ItemsInList(scanOrderStr,",")) scanOrderIndex = x
	Make/FREE/N=(ItemsInList(scanOrderStr,",")) scanOrderIndex2 = x
	
	For(k=0;k<ItemsInList(scanOrderStr,",");k+=1)
		scanOrderWave[k] = str2num(StringFromList(k,scanOrderStr,","))
	EndFor
	
	
	If(DimSize(scanOrderWave,0) == 0 || cmpstr(scanOrderStr,"presetAngleWave[0][1]") == 0)
		Redimension/N=(numScans) scanOrderWave,scanOrderIndex
		scanOrderWave = x
		scanOrderIndex = x
	EndIf
	
	//ControlInfo/W=analysis_tools roiOrderROIdisplay
	//roiOrderStr = S_Value
	
	//Make/FREE/N=(ItemsInList(roiOrderStr,",")) roiOrderIndex = x
	//Make/FREE/N=(ItemsInList(roiOrderStr,",")) roiOrderWave

	//For(k=0;k<ItemsInList(roiOrderStr,",");k+=1)
	//	roiOrderWave[k] = str2num(StringFromList(k,roiOrderStr,","))
	//EndFor
	
	SortColumns keyWaves={scanOrderWave},sortWaves={scanOrderIndex}
	//SortColumns keyWaves={roiOrderWave},sortWaves={roiOrderIndex}
	
	//Figure out which dimension is ROI and which is Scan
	strswitch(horArrange)
		case "None":
			numHorAxes = 1
			If(cmpstr(vertArrange,"ROI") == 0)	
				horDim = numScans
			Else
				horDim = numROIs
			EndIf
			break
		case "ROI":
			horDim = numROIs
			numHorAxes = numROIs
			break
		case "Index":
			horDim = numScans
			numHorAxes = numScans
			break
	endswitch
	
	strswitch(vertArrange)
		case "None":
			numVertAxes = 1
			If(cmpstr(horArrange,"Index") == 0)
				vertDim = numROIs
			Else
				vertDim = numScans
			EndIf
			break
		case "ROI":
			vertDim = numROIs
			numVertAxes = numROIs
			break
		case "Index":
			vertDim = numScans
			numVertAxes = numScans
			break
	endswitch
	
	If(cmpstr(horArrange,vertArrange) == 0 && cmpstr(horArrange,"None") != 0)
		DoAlert 0, "Can't use '" + horArrange + "' for both horizontal and vertical dimensions"
		return -1
	EndIf
	
	horDelta = 1/horDim
	vertDelta = 1/vertDim
	
	maxValue = -10
	minValue = 10
	
	count = 0
	
	//Build ROI display
	///////////////SS edit NOv6 2018/////////////////
	If(strlen(WindowName))
		Dowindow/F $WindowName
		If(!V_Flag) 	
			Display/N = $windowname 
		EndIf
	Else
		WindowName = UniqueName("dispROI_",6,0)
		Display/N=$WindowName as WindowName
	EndIf	
	
	string ROINote
	variable Gred, Ggreen, Gblue
	string tracename
	///////////////SS edit NOv6 2018/////////////////
	
	For(i=0;i<vertDim;i+=1)
		For(j=0;j<horDim;j+=1)
			
			//Get wave names
			If(cmpstr(horArrange,"ROI") == 0)
				ROI = StringFromList(j,ROIListStr,";")
			ElseIf(cmpstr(vertArrange,"ROI") == 0)
				ROI = StringFromList(i,ROIListStr,";")
			Else
				If(cmpstr(horArrange,"Index") == 0)
					ROI = StringFromList(i,ROIListStr,";")
				Else
					//defaults so that ROI is stepped by the horizontal dimension
					ROI = StringFromList(j,ROIListStr,";")
				EndIf
				
			EndIf
			
			If(cmpstr(horArrange,"Index") == 0)
				print pnt2x(scanOrderIndex,j)
				Scan = StringFromList(scanOrderIndex[j],scanListStr,";")
			ElseIf(cmpstr(vertArrange,"Index") == 0)
				Scan = StringFromList(scanOrderIndex[i],scanListStr,";")
			Else
				If(cmpstr(vertArrange,"ROI") == 0)
					Scan = StringFromList(scanOrderIndex[j],scanListStr,";")
				Else
					//defaults so that Scan is stepped by the vertical dimension
					Scan = StringFromList(scanOrderIndex[i],scanListStr,";")
				EndIf
			EndIf
			
			String channel = getChannel(1)
			channel = RemoveEnding(channel,";")
			strswitch(channel)
				case "ch1":
				case "ch2":
					String suffix = "dF"
					break
				case "ratio":
					suffix = "dGR"
					channel = "1"
					break
			endswitch
			
			Path = "root:ROI_analysis:ROI" + ROI + ":" + Scan + "_" + channel + "_ROI" + ROI + "_" + suffix
			
			/////////SS edit Nov6 2018/////////////////////////
			tracename = Path
			ROINote = note ($("root:twoP_ROIS:"+ROI+"_x"))
			Gred = NumberByKey("Red",ROINote)
			Ggreen = NumberByKey("green",ROINote)
			Gblue = NumberByKey("Blue",ROINote)
			/////////SS edit Nov6 2018/////////////////////////
			
			
			If(doAverages)
				Path += "_avg"
			EndIf
			
			Wave theWave = $Path
			
			//If can't find the wave, check if zeros have been buffered or not
			If(!WaveExists(theWave))
				//try wave name without buffered zeros, in case they have been removed
				String str = StringFromList(1,Scan,"_")
				str = num2str(str2num(str)) // unbuffer zeros
				Scan = RemoveListItem(1,Scan,"_")
				Scan = AddListItem(str,Scan,"_",1)
				Scan = RemoveEnding(Scan,"_")
				
				//New name without buffered zeros in the Scan name
				Path = "root:ROI_analysis:ROI" + ROI + ":" + Scan + "_" + channel + "_ROI" + ROI + "_" + suffix
				Wave theWave = $Path
				
				If(!WaveExists(theWave))
					continue
				EndIf
			EndIf
			
			//Get axes names
			If(cmpstr(vertArrange,"None") == 0)
				leftAxis = "left_0"
				startLeft = 0
				endLeft = 1
			Else
				leftAxis = "left_" + num2str(i)
				startLeft = 1-vertDelta*i - 0.9*vertDelta
				endLeft = 1-vertDelta*i
			EndIf
			
			If(cmpstr(horArrange,"None") == 0)
				bottomAxis = "bottom_0"
				startBottom = 0
				endBottom = 1
			Else
				bottomAxis = "bottom_" + num2str(j)
				startBottom = horDelta*j
				endBottom = horDelta*j + 0.9*horDelta
			EndIf
			
			//Append trace to the graph
			AppendToGraph/W=$WindowName/L=$leftAxis/B=$bottomAxis theWave
			ModifyGraph/W=$WindowName axisEnab($bottomAxis)={startBottom,endBottom},freePos($leftAxis)={0,bottom_0},zero($leftAxis)=3,zeroThick($leftAxis)=0.5
			ModifyGraph/W=$WindowName axisEnab($leftAxis)={startLeft,endLeft},manTick($leftAxis)={0,0.2,0,1},manMinor($leftAxis)={1,0}
			//DoUpdate
			///////SS edit Nov6 2018///////////////////////////////////
			//only modify if the color variables exist
			ControlInfo/W=analysis_tools colorROIs
			If(V_Value)
				If(numtype(Gred) != 2 && numtype(Ggreen) != 2 && numtype(Gblue) != 2)
					Modifygraph/W=$WindowName rgb($NameOfWave(theWave)) = (Gred,Ggreen,Gblue) 
				EndIf
			EndIf
			///////SS edit Nov6 2018/////////////////////////////////// 
			
			//Max and min left axis values
			GetAxis/Q $leftAxis
			If(V_max > maxValue)
				maxValue = V_max
			EndIf
			
			If(V_min < minValue)
				minValue = V_min
			EndIf
			count += 1
		EndFor
	EndFor
	
	
	//Set all left axes to the same max and min
	For(i=0;i<numVertAxes;i+=1)
		leftAxis = "left_" + num2str(i)
		SetAxis $leftAxis,minValue,maxValue
	EndFor
	
	
	//Final modifications
	For(j=0;j<numHorAxes;j+=1)
		bottomAxis = "bottom_" + num2str(j)
		//ModifyGraph freePos($bottomAxis)={0,$("left_" + num2str(numVertAxes - 1))}
		ModifyGraph freePos($bottomAxis)={0,kwFraction}
	EndFor
	
	ModifyGraph margin(left)=28,margin(bottom)=28,margin(right)=7,margin(top)=7,gfSize=8,axThick=0.5,standoff=0,btLen=2 //rgb=(0,0,0) SS edit Nov6 2018
	SetAxis/A
End

Function/WAVE getDendriticMaskInit([theWave,noBuffer,channel])
	Wave theWave
	Variable noBuffer
	String channel
	
	String/G root:Packages:analysisTools:paramStr
	SVAR paramStr = root:Packages:analysisTools:paramStr
	paramStr = ""
	
	ControlInfo/W=analysis_tools maskThreshold
	paramStr += "maskThresh:" + num2str(V_Value) + ";"
	//maskThresh = V_Value
	
	ControlInfo/W=analysis_tools AT_CommandPop
	paramStr += "theCommand:" + S_Value + ";"
	
	paramStr += "theWave:" + GetWavesDataFolder(theWave,2) + ";"
	
	channel = getChannel(1)
	paramStr += "channel:" + channel + ";"
		
	Wave theMask = getDendriticMask()
	return theMask
End

Function/WAVE getDendriticMask([theWave,noBuffer])
	Wave theWave
	Variable noBuffer
	If(ParamIsDefault(noBuffer))
		noBuffer = 0 
	EndIf

	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	SVAR whichList = root:Packages:analysisTools:whichList
	Variable m,k,f,numScans,numChannels
	
	If(ParamIsDefault(theWave))
		If(cmpstr(whichList,"AT") == 0)
			String channel = getChannel(1)
			numChannels = ItemsInList(channel,";")
			numScans = ItemsInList(scanListStr,";")
		Else
			numChannels = 1
			numScans = ItemsInList(selWaveList,";")
		EndIf
	Else
		numScans = 1
		channel = getChannel(1)
		numChannels = ItemsInList(channel,";")
	EndIf
	
	For(k=0;k<numScans;k+=1)
		If(ParamIsDefault(theWave))
			If(cmpstr(whichList,"AT") == 0)
				String dataFolder = "root:twoP_Scans:" + StringFromList(k,scanListStr,";")
			ElseIf(cmpstr(whichList,"Browser") == 0)
				dataFolder = cdf
			EndIf
		Else
			dataFolder = GetWavesDataFolder(theWave,1)
		EndIf
		
		For(m=0;m<numChannels;m+=1)
			
			If(ParamIsDefault(theWave))
				If(cmpstr(whichList,"AT") == 0)
					String theChannel = StringFromList(m,channel,";")
					String scanPath = dataFolder + ":" + StringFromList(k,scanListStr,";") + "_" + theChannel
				Else
					scanPath = dataFolder + StringFromList(k,selWaveList,";")
				EndIf
			
				//Can we find the wave?
				If(DataFolderExists(dataFolder))
					SetDataFolder $dataFolder
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
			
				If(WaveExists($scanPath))
					Wave theWave = $scanPath
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
			
			EndIf
			
			//custom wave definition
			//Wave theWave = root:twoP_Scans:Scan_048:Scan_048_ch2
			
			
			//Variable declarations
			Variable minVal,maxVal,threshold,i,j,rows,cols,frames,maskThresh,mask3D
		
			ControlInfo/W=analysis_tools maskThreshold
			maskThresh = V_Value
			
			ControlInfo/W=analysis_tools mask3DCheck
			mask3D = V_Value
			
			rows = DimSize(theWave,0)
			cols = DimSize(theWave,1)
			
			If(mask3D)
				frames = DimSize(theWave,2)
			EndIf
			
			//Get max projection image
			MatrixOP/S/O maxProj = sumBeams(theWave)
			
			//Min value needs to be found without considering the edges, since they may have been buffered with zeros
			//for image registration purposes
			
			If(noBuffer)
				ImageStats maxProj
			Else
				ImageStats/G={20,DimSize(maxProj,0)-20,20,DimSize(maxProj,1)-20} maxProj
			EndIf
				
			minVal = V_min
			//minVal = WaveMin(maxProj)
			
			maxVal = WaveMax(maxProj)
			threshold = minVal + (maxVal - minVal)*maskThresh
		
			//Simple value thresholding
			maxProj = (maxProj < threshold) ? 0 : maxProj
	
			//Eliminate isolated points
			Make/FREE/N=(5,5) block
			block = 0
			
			If(mask3D)
			//3D masking
				Duplicate/FREE theWave,maskWave3D
				For(f=0;f<frames;f+=1)
				
					ImageStats/P=(f) maskWave3D
					threshold = V_avg + 2*V_sdev
					//make sub-threshold values zero
					maskWave3D = (maskWave3D < threshold) ? 0 : maskWave3D
					print f,"/",frames
					For(i=0;i<rows;i+=1)	
						For(j=0;j<cols;j+=1)	
							
							//check for image edges
							If(i-2 < 0 || i+2 > rows-2 || j-2 < 0 || j+2 > cols-2)
								continue
							Else
								//Get data block surrounding point
								block = maskWave3D[i-2 + p][j-2 + q][f]
								
								//Check for isolated points, set the to zero
								If(sum(block) < 3*maskWave3D[i][j][f])
									maskWave3D[i][j][f] = 0
								EndIf	
							EndIf
							
							block = 0
						EndFor
					EndFor
				EndFor
				//3D median filter 3x3
				ImageFilter/N=3 median maskWave3D
			
				//Create mask wave
				String maskName = NameOfWave(theWave) + "_mask3D"
				If(strlen(maskName) > 31)
					maskName = "Scan_mask3D"
				EndIf
			Else
			
			//2D masking
				For(i=0;i<rows;i+=1)	
					For(j=0;j<cols;j+=1)
						//skip zeros
						If(maxProj[i][j] == 0)
							continue
						EndIf			
				
						//check for image edges
						If(i-2 < 0 || i+2 > rows-2 || j-2 < 0 || j+2 > cols-2)
							continue
						Else
							//Get data block surrounding point
							block = maxProj[i-2 + p][j-2 + q]
							
							//Check for isolated point
							If(sum(block) < 3*maxProj[i][j])
								maxProj[i][j] = 0
							EndIf	
						EndIf
					
						block = 0
					EndFor
				EndFor
				//2D median filter 3x3
				MatrixFilter/N=3 median maxProj
				
				//Create mask wave
				maskName = NameOfWave(theWave) + "_mask"
				If(strlen(maskName) > 31)
					maskName = "Scan_mask"
				EndIf
			EndIf
	
		
			
			//Set non-zero values to 1
			If(mask3D)
				Make/O/N=(rows,cols,frames) $maskName
				Wave theMask = $maskName
				theMask = (maskWave3D == 0) ? 0 : 1
				//Scaling
				SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theMask
				SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),theMask
				SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),theMask
			Else
				Make/O/N=(rows,cols) $maskName
				Wave theMask = $maskName
				theMask = (maxProj == 0) ? 0 : 1
				//Scaling
				SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theMask
				SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),theMask
			EndIf
	
			ControlInfo/W=analysis_tools AT_CommandPop
			If(cmpstr(S_Value,"Get Dendritic Mask") == 0)
				print "Created dendritic mask of wave: " + scanPath
			EndIf
			
		EndFor
	EndFor
	
	return theMask
End

//masks an image with the specified mask wave from analysisTools
Function maskScanData()
	
	String theWaveList = getWaveNames()
	Variable i,numWaves
	
	numWaves = ItemsInList(theWaveList,";")
	
	//get the mask wave
	ControlInfo/W=analysis_tools maskListPopUp
	Wave theMask = $S_Value
	
	ControlInfo/W=analysis_tools overwrite
	Variable overwrite = V_Value
	
	//Make wave to hold the masked scan
	For(i=0;i<numWaves;i+=1)
		SetDataFolder GetWavesDataFolder($StringFromList(i,theWaveList,";"),1)
		
		//get the scan and determine overwriting
		If(overwrite)
			Wave maskedScan = $StringFromList(i,theWaveList,";")
		Else
			Wave theWave = $StringFromList(i,theWaveList,";")
			String maskedScanName = StringFromList(i,theWaveList,";") + "_msk"
			Duplicate/O theWave,$maskedScanName
			Wave maskedScan = $maskedScanName
		EndIf
		
		maskedScan = (theMask[p][q][0] == 1) ? maskedScan[p][q][r] : nan
		print StringFromList(i,theWaveList,";") + " has been masked using " + S_Value
	EndFor
		
End

Function maxLayer(theWave)
	wave theWave
	variable i,j
	
	Duplicate/O theWave,ratioPk
	wave ratioPk = ratioPk
	Redimension/N=(-1,-1,0) ratioPk
	
	For(i=0;i<DimSize(theWave,0);i+=1)	
		For(j=0;j<DimSize(theWave,1);j+=1)
			MatrixOP/FREE/O theBeam = Beam(theWave,i,j)
			Smooth/S=2 13, theBeam
			ratioPk[i][j] = WaveMax(theBeam,round(0.3*DimSize(theWave,2)),round(0.6*DimSize(theWave,2)))
		EndFor
	EndFor
End

//Creates a spatial map of either the peak Ca response, area Ca response, or area/peak ratio
//Select waves using the scan list.
//Multithreaded for speed.
Function dfMapMultiThread()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR whichList = root:Packages:analysisTools:whichList
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	SVAR selWaveList = root:Packages:MBr:selWaveList
	
	Variable numChannels,i,j,k,m,b,c,frames,rows,cols
	String scanPath = ""
	String dFWaveName
	Wave/T maskTable = root:Packages:analysisTools:maskTable
	
	SetDataFolder root:twoP_Scans
	DFREF twoPScans = GetDataFolderDFR()
	
	numChannels = 0

	//Get the range for finding the peak dF
	Variable startTm,endTm,bslnStartTm,bslnEndTm
	ControlInfo/W=analysis_tools peakStVar
	startTm = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	endTm = V_Value

	ControlInfo/W=analysis_tools bslnStVar
	bslnStartTm = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	bslnEndTm = V_Value
	
	ControlInfo/W=analysis_tools spatialFilterCheck
	Variable spatialFilter = V_Value
	
	Variable s

	
	//Loop through the scans
	For(s=0;s<ItemsInList(scanListStr,";");s+=1)
		Variable timerRef = StartMSTimer
		String dataFolder = "root:twoP_Scans:" + StringFromList(s,scanListStr,";")

		
		//Resolve the channels and get the scan name
		ControlInfo/W=analysis_tools ch1Check
		If(V_Value)
			numChannels = 1
			scanPath = dataFolder + ":" + StringFromList(s,scanListStr,";") + "_ch1"
		EndIf
		
		ControlInfo/W=analysis_tools ch2Check
		If(V_Value)
			numChannels += 1
		EndIf
		
		ControlInfo/W=analysis_tools ratioCheck
		Variable doRatio = V_Value
		
		If(cmpstr(whichList,"AT") == 0) //only need channel selection if we're in scan mode (AT)
			If(numChannels == 0 && doRatio != 1)
				Abort "Must select a channel"
			EndIf
		ElseIf(cmpstr(whichList,"Browser") == 0)
			scanPath = cdf + StringFromList(0,selWaveList,";")
			dataFolder = cdf
			numChannels = 1
		EndIf
		
		If(doRatio)
			numChannels = 1
		EndIf
		
		print "-------"
		
		//Loop through channels
		For(c=0;c<numChannels;c+=1)
		
			If(doRatio)
			
			//////// ∆G/R MAPPING //////////////////////////
			
				//Green channel scan wave
				scanPath = dataFolder + ":" + StringFromList(s,scanListStr,";") + "_ch1"
	
				//Can we find the wave?
				If(DataFolderExists(dataFolder))
					SetDataFolder $dataFolder
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
		
				If(WaveExists($scanPath))
					Wave ch1Wave = $scanPath
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
				
				//Red channel scan wave
				scanPath = dataFolder + ":" + StringFromList(s,scanListStr,";") + "_ch2"
	
				//Can we find the wave?
				If(DataFolderExists(dataFolder))
					SetDataFolder $dataFolder
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
		
				If(WaveExists($scanPath))
					Wave ch2Wave = $scanPath
					Wave ch2Wave_alternate = $scanPath
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
				
				//Wave dimensions
				rows = DimSize(ch1Wave,0)
				cols = DimSize(ch1Wave,1)
				frames = DimSize(ch1Wave,2)
						
				//Cleans up some of the instrument noise that is plaguing these dF maps. 
				ControlInfo/W=analysis_tools cleanUpNoise
				Variable cleanNoise = V_Value
				
				ControlInfo/W=analysis_tools cleanUpNoiseThresh
				Variable cleanNoiseThresh = V_Value
				
				If(cleanNoise)
					Wave theWave = CleanUpNoise(ch1Wave,cleanNoiseThresh)	//threshold is in sdevs above the mean
					Wave ch2Wave = CleanUpNoise(ch2Wave_alternate,cleanNoiseThresh)
				EndIf
				
				
				//Variance Map?
				ControlInfo/W=analysis_tools varianceMapCheck
				If(V_Value)	
					MakeVarMap(theWave)
				EndIf
				
				//Get mask wave
				ControlInfo/W=analysis_tools maskAllFoldersCheck
				Variable checkAllFolders = V_Value
				ControlInfo/W=analysis_tools maskListPopUp	
		
				If(checkAllFolders)
				//	String folderPath = "root:twoP_Scans:" + GetIndexedObjNameDFR(twoPScans,4,V_Value) + ":"
					Wave theMask = $maskTable[V_Value-2]
				Else
					Wave theMask = $S_Value
				EndIf
				
				If(!WaveExists(theMask))
					Abort "Cannot find the mask wave"
				EndIf
				
				Duplicate/FREE theMask,darkMask
				Redimension/B/U darkMask
				
				//Get red channel baseline, spatial filter and temporal smooth it.
				Duplicate/FREE/O ch2Wave,redBaselineMat
				
				//Filter the red baseline the same as the
				// green channel will be filtered
				MatrixOP/O redBaseline = sumBeams(redBaselineMat)/frames
				MatrixFilter/N=3 median redBaseline
							
				//Set scales for red baseline
				SetScale/P x,DimOffset(ch2Wave,0),DimDelta(ch2Wave,0),redBaseline
				SetScale/P y,DimOffset(ch2Wave,1),DimDelta(ch2Wave,1),redBaseline
				
				//Find average dark value for red channel
				ImageStats/R=darkMask redBaseline //gets dark value from the first frame of all non-masked pixels
				Variable darkValue = 0.9*V_avg //estimate dark value slightly low to avoid it accidentally surpassing the dendrite baseline fluorescence.
				
				//Make time-varying dG/R Map Wave
				dFWaveName = NameOfWave(ch1Wave) + "_dGR"
				Duplicate/O ch1Wave,$dFWaveName
				Wave dFWave = $dFWaveName
				
				Redimension/S/N=(rows,cols,frames) dFWave
				dFWave = 0
				
				//Operate on temporary wave so raw data is never altered.
				Duplicate/FREE/O theWave,temp
				
				//Spatial filter for each layer of the green channel.
				
				If(spatialFilter)
					If(spatialFilter < 3)
						DoAlert 0,"Spatial filter must be 3 or greater."
						break
					EndIf
	
					For(k=0;k<frames;k+=1)
						MatrixOP/O/FREE theLayer = layer(temp,k)
						MatrixFilter/N=(spatialFilter) median theLayer
						Multithread temp[][][k] = theLayer[p][q][0]
					EndFor
				EndIf
					
				//Remove laser response loop for green channel
				ControlInfo/W=analysis_tools RemoveLaserResponseCheck
				Variable RemoveLaserResponse = V_Value
	
				For(i=0;i<rows;i+=1)
					For(j=0;j<cols;j+=1)
						If(darkMask[i][j] != 1)
							continue
						EndIf
						MatrixOP/FREE/O/S theBeam = Beam(temp,i,j)
						SetScale/P x,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),theBeam
						
						//Remove laser response from dF matrix wave for better baselining
						If(RemoveLaserResponse)
							Variable estimatePeakTm = 0.5*(endTm + startTm)
							FlattenLaserResponse(theBeam,0,bslnEndTm,1,estimatePeakTm)
						EndIf
						
						Multithread temp[i][j][] = theBeam[r]
					EndFor	
				EndFor	
				
				//Get green channel baseline fluorescence map
				Make/FREE/O/N=(rows,cols) greenBaseline
				
				Variable startLayer,endLayer
				startLayer = ScaleToIndex(ch1Wave,bslnStartTm,2)
				endLayer = ScaleToIndex(ch1Wave,bslnEndTm,2)
				
				For(i=startLayer;i<endLayer;i+=1)
					MatrixOP/FREE/O theLayer = layer(temp,i)
					FastOP greenBaseline = greenBaseline + theLayer
				EndFor
				Multithread greenBaseline /= (endLayer - startLayer)
				
	
				//Eliminates the possibility of zero values in the dataset for dendrites in the mask, which all get converted to NaN at the end.
				Multithread temp = (temp[p][q][r] == greenBaseline[p][q][0]) ? temp[p][q][r] + 1 : temp[p][q][r]
				
				//Calculate ∆G/R time-varying map
				ControlInfo/W=analysis_tools doDarkSubtract
				If(V_Value)
					Multithread dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / (redBaseline[p][q][0] - darkValue)
				Else
					Multithread dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / redBaseline[p][q][0]
				EndIf
						
				//Make peak ∆G/R and peak-time map waves
				String dFPeakWaveName = dFWaveName + "_peak"
				Make/O/N=(rows,cols) $dFPeakWaveName,$(dFPeakWaveName + "Loc")
				Wave dFPeakWave = $dFPeakWaveName
				Wave dFPeakLoc = $(dFPeakWaveName + "Loc")
				
				//ZT edit - integral and area/peak index map waves
				ControlInfo/W=analysis_tools peakOrAreaMenu
				If(!cmpstr(S_Value,"Area/Peak"))
					Make/O/N=(rows,cols) $(dFPeakWaveName + "int"),$(dFPeakWaveName + "idx")
					Wave dFIntWave = $(dFPeakWaveName + "int")
					Wave dFIndexWave = $(dFPeakWaveName + "idx")
				EndIf
				
				MultiThread dFPeakWave = gnoise(0.001)	
				FastOP dFPeakLoc = 0
				
				//Temporal smoothing of the dF map prior to finding the peaks.
				ControlInfo/W=analysis_tools SmoothBox
				Variable didSmooth = V_Value
				
				If(didSmooth)
					ControlInfo/W=analysis_tools SmoothFilterVar
					Variable smoothVar = V_Value
					Smooth/S=2/DIM=2 smoothVar,dFWave
				EndIf
				
				//Getting the peak ∆G/R and its time point from a beam 
				For(i=0;i<rows;i+=1)
					For(j=0;j<cols;j+=1)
						//only operates if the data is within the mask region to save time.
						If(darkMask[i][j] != 1)
							continue
						EndIf
						
						MatrixOP/FREE/O theBeam = Beam(dFWave,i,j)
						SetScale/P x,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),theBeam
						WaveStats/Q/R=(startTm,endTm) theBeam
						
						dFPeakLoc[i][j] = V_MaxRowLoc
						//averages 50 ms before and after the peak to get the final ∆G/R peak value
						
						ControlInfo/W=analysis_tools peakOrAreaMenu
						If(!cmpstr(S_Value,"Peak"))
							MultiThread dFPeakWave[i][j] = mean(theBeam,V_maxloc - 0.05,V_maxloc + 0.05)
						ElseIf(!cmpstr(S_Value,"Area"))
							MultiThread dFPeakWave[i][j] = mean(theBeam,startTm,endTm)
						ElseIf(!cmpstr(S_Value,"Area/Peak")) //for ZT
							MultiThread dFIntWave[i][j] = area(theBeam,V_maxLoc - 0.05,V_maxLoc + 2.05) //2.1 s window for taking the area of the Ca response
							Multithread dFIndexWave[i][j] = dFIntWave[i][j] / dFPeakWave[i][j]	//Sustained/transient index (area divided by the peak)
						EndIf
					EndFor
				EndFor
				
				//Clip the edges of the image with a mask, to remove the projector artifact
				//theMask[0,10][] = 0
				//theMask[rows-11,rows-1][] = 0
				
				//Clip unreasonably high values
				//dFWave  = (dFWave > 100) ? 0 : dFWave
				//dFWave = (dFWave < 0) ? 0 : dFWave
				
				//Set scales
				SetScale/P x,DimOffset(ch1Wave,0),DimDelta(ch1Wave,0),dFPeakWave,dFPeakLoc,dFWave
				SetScale/P y,DimOffset(ch1Wave,1),DimDelta(ch1Wave,1),dFPeakWave,dFPeakLoc,dFWave
				SetScale/P z,DimOffset(ch1Wave,2),DimDelta(ch1Wave,2),dFWave
							
			Else
			
			//////// ∆F/F MAPPING //////////////////////////
			
				//If scanPath isn't assigned and we haven't aborted yet, it must be ch2
				If(!strlen(scanPath) || c > 0)
					scanPath = dataFolder + ":" + StringFromList(s,scanListStr,";") + "_ch2"
				EndIf
	
				//Can we find the wave?
				If(DataFolderExists(dataFolder))
					SetDataFolder $dataFolder
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf
		
				If(WaveExists($scanPath))
					Wave theWave = $scanPath
				Else
					Abort "Couldn't find the wave: " + scanPath
				EndIf

				
				String theWaveName = NameOfWave(theWave)
				
				//Make the input scan 32 bit float, instead of unsigned 16 bit integer
				Duplicate/FREE theWave,theWave32bit
				Wave theWave = theWave32bit
				Redimension/S theWave
				
				//Wave dimensions
				frames = DimSize(theWave,2)
				rows = DimSize(theWave,0)
				cols = DimSize(theWave,1)
			
				
				//Cleans up some of the instrument noise that is plaguing these dF maps. 
				ControlInfo/W=analysis_tools cleanUpNoise
				cleanNoise = V_Value
				
				ControlInfo/W=analysis_tools cleanUpNoiseThresh
				cleanNoiseThresh = V_Value
				
				
				If(cleanNoise)
					Wave theWave = CleanUpNoise($theWaveName,cleanNoiseThresh)	//threshold is in sdevs above the mean
					Redimension/S theWave
				EndIf
				
				//Variance Map?
				ControlInfo/W=analysis_tools varianceMapCheck
				If(V_Value)	
					MakeVarMap(theWave)
				EndIf
				
				//Get mask wave
				ControlInfo/W=analysis_tools maskAllFoldersCheck
				checkAllFolders = V_Value
				ControlInfo/W=analysis_tools maskListPopUp	
				
				Variable scanPosition = WhichListItem("Scan",S_Value,"_")
				String theScanStr = RemoveEnding(ParseFilePath(1,S_Value,"_",0,scanPosition+2),"_")
				
				DFREF theScanPath = root:twoP_Scans
				
				If(checkAllFolders)
					//folderPath = "root:twoP_Scans:" + theScanStr + ":"
					Wave theMask = $maskTable[V_Value-2]
				Else
					Wave theMask = $S_Value
				EndIf
				
				If(!WaveExists(theMask))
					Abort "Cannot find the mask wave"
				EndIf
				
				Duplicate/FREE theMask,darkMask
				Redimension/B/U darkMask
			
				//Find average dark value
				ImageStats/R=darkMask/P=1 theWave
				darkValue = 0.9*V_avg  //estimate dark value slightly low to avoid it accidentally surpassing the dendrite baseline fluorescence.
				
				//Make time-varying dF Map wave
				dFWaveName = theWaveName + "_dF"
				Duplicate/O theWave,$dFWaveName
				Wave dFWave = $dFWaveName
			
				Redimension/S/N=(rows,cols,frames) dFWave
				dFWave = 0	
				
				//Operate on temporary wave so raw data is never altered.
				Duplicate/FREE/O theWave,temp
				
				//Spatial filter for each layer of the wave.
				If(spatialFilter)
					If(spatialFilter < 3)
						DoAlert 0,"Spatial filter must be 3 or greater."
						break
					EndIf
	
					For(k=0;k<frames;k+=1)
						MatrixOP/O/FREE theLayer = layer(temp,k)
						MatrixFilter/N=(spatialFilter) median theLayer
						MultiThread temp[][][k] = theLayer[p][q][0]
					EndFor
				EndIf
				
				//Remove laser response loop
				ControlInfo/W=analysis_tools RemoveLaserResponseCheck
				RemoveLaserResponse = V_Value
	
				For(i=0;i<rows;i+=1)
					For(j=0;j<cols;j+=1)
						If(darkMask[i][j] != 1)
							continue
						EndIf
				
						MatrixOP/FREE/O/S theBeam = Beam(temp,i,j)
						SetScale/P x,DimOffset(theWave,2),DimDelta(theWave,2),theBeam
						
						//Remove laser response from dF matrix wave for better baselining
						If(RemoveLaserResponse)
							estimatePeakTm = 0.5*(endTm + startTm)
							FlattenLaserResponse(theBeam,0,bslnEndTm,1,estimatePeakTm)
						EndIf
						
						temp[i][j][] = theBeam[r]
					EndFor	
				EndFor	
				
				//Get the baseline fluorescence map
				Make/FREE/O/N=(rows,cols) greenBaseline
				startLayer = ScaleToIndex(theWave,bslnStartTm,2)
				endLayer = ScaleToIndex(theWave,bslnEndTm,2)
				
				greenBaseline = 0
				
				For(i=startLayer;i<endLayer;i+=1)
					MatrixOP/FREE/O theLayer = layer(temp,i)
					FastOP greenBaseline = greenBaseline +theLayer
				EndFor
				MultiThread greenBaseline /= (endLayer - startLayer)
				
				//Eliminates the possibility of zero values in the dataset for dendrites in the mask, which all get converted to NaN at the end.
				MultiThread temp = (temp[p][q][r] == greenBaseline[p][q][0]) ? temp[p][q][r] + 1 : temp[p][q][r]
				
				//Get the ∆F/F time series map with dark subtraction from the non-masked area
				ControlInfo/W=analysis_tools doDarkSubtract
				If(V_Value)
					MultiThread dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / (greenBaseline[p][q][0] - darkValue)
				Else
					MultiThread dFWave = (temp[p][q][r] - greenBaseline[p][q][0]) / greenBaseline[p][q][0]
				EndIf
						
				//Make waves for the peak and peak-time maps
				dFPeakWaveName = dFWaveName + "_peak"
				
				If(strlen(dFPeakWaveName) > 28)
					dFPeakWaveName = ReplaceString(StringFromList(0,dFPeakWaveName,"_"),dFPeakWaveName,"Scan")
				EndIf
								
				Make/O/N=(rows,cols) $dFPeakWaveName,$(dFPeakWaveName + "Loc")
				Wave dFPeakWave = $dFPeakWaveName
				Wave dFPeakLoc = $(dFPeakWaveName + "Loc")
				
				//ZT edit - area and area/peak map waves
				ControlInfo/W=analysis_tools peakOrAreaMenu
				If(!cmpstr(S_Value,"Area/Peak"))
					Make/O/N=(rows,cols) $(dFPeakWaveName + "int"),$(dFPeakWaveName + "idx")
					Wave dFIntWave = $(dFPeakWaveName + "int")
					Wave dFIndexWave = $(dFPeakWaveName + "idx")
				EndIf
	
				MultiThread dFPeakWave = gnoise(0.001)
				MultiThread dFPeakLoc = 0
				
				//Temporal smoothing of the dF map prior to finding the peaks.
				ControlInfo/W=analysis_tools SmoothBox
				didSmooth = V_Value
				
				If(didSmooth)
					ControlInfo/W=analysis_tools SmoothFilterVar
					smoothVar = V_Value
					Smooth/S=2/DIM=2 smoothVar,dFWave
				EndIf
					
				//Getting the peak ∆F/F and its time point from a beam 
				For(i=0;i<rows;i+=1)
					For(j=0;j<cols;j+=1)
						//only operates if the data is within the mask region to save time.
						If(darkMask[i][j] != 1)
							continue
						EndIf
						
						MatrixOP/FREE/O/S theBeam = Beam(dFWave,i,j)
						SetScale/P x,DimOffset(theWave,2),DimDelta(theWave,2),theBeam
						WaveStats/Q/R=(startTm,endTm) theBeam
						
						dFPeakLoc[i][j] = V_MaxRowLoc
						
						//averages 50ms before and after the peak to get the final ∆F/F peak value
						ControlInfo/W=analysis_tools peakOrAreaMenu
						If(!cmpstr(S_Value,"Peak"))
							dFPeakWave[i][j] = mean(theBeam,V_maxloc - 0.05,V_maxloc + 0.05)
						ElseIf(!cmpstr(S_Value,"Area"))
							dFPeakWave[i][j] = mean(theBeam,startTm,endTm)
						ElseIf(!cmpstr(S_Value,"Area/Peak")) //for ZT
							dFIntWave[i][j] = area(theBeam,V_maxLoc - 0.05,V_maxLoc + 2.05) //2.1 s window for taking the area of the Ca response
							dFIndexWave[i][j] = (dFIntWave[i][j] / dFPeakWave[i][j])	//Sustained/transient index (area divided by the peak)
						EndIf
					
					EndFor
				EndFor
				
				//Set scales
				SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),dFPeakWave,dFPeakLoc,dFWave//,dFDiff,dFDiff_pk,dF_conv
				SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),dFPeakWave,dFPeakLoc,dFWave//,dFDiff,dFDiff_pk,dF_conv
				SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),dFWave//,dFDiff
			EndIf
			
				//MASKING AND FINAL FILTERING - code common to ∆F and ∆G maps.
				
				//Additional spatial filter on the peak ∆F/F or ∆G/R map
				ControlInfo/W=analysis_tools postSpatialFilter
				Variable postSpatial = V_Value
				MatrixFilter/N=(postSpatial)/R=darkMask median dFPeakWave
				
				//Apply the mask
				MultiThread dFPeakWave *= theMask
				MultiThread dFPeakLoc *= theMask
				MultiThread dFWave *= theMask[p][q][0]
				
				//Apply mask to optional area/peak maps and the area map
				ControlInfo/W=analysis_tools peakOrAreaMenu
				String measureType = S_Value
				If(!cmpstr(measureType,"Area/Peak"))
					MultiThread dFIntWave *= theMask
					MultiThread dFIndexWave *= theMask
					MultiThread dFIntWave = (dFIntWave == 0) ? nan : dFIntWave
					MultiThread dFIndexWave = (dFIndexWave == 0) ? nan : dFIndexWave
					Variable numMaps = 5
				Else
					numMaps = 3
				EndIf
				
				MultiThread dFWave = (dFWave == 0) ? nan : dFWave
				MultiThread dFPeakLoc = (dFPeakLoc == 0) ? nan : dFPeakLoc
				MultiThread dFPeakWave = (dFPeakWave == 0) ? nan : dFPeakWave
				
				//Make image histogram of peak fluorescence values
				ControlInfo/W=analysis_tools histogramCheck
				If(V_Value)
					String histName = NameOfWave(dFWave) + "_hist"
					
				
					If(doRatio)
						Histogram/C/B={0,0.0002,150}/DEST=$histName dFPeakWave
						Wave theHist = $histName
						SetScale/P x,DimOffset(theHist,0),DimDelta(theHist,0),"∆G/R",theHist
					Else
						Histogram/C/B={0,0.002,150}/DEST=$histName dFPeakWave
						Wave theHist = $histName
						SetScale/P x,DimOffset(theHist,0),DimDelta(theHist,0),"∆F/F",theHist
					EndIf
				EndIf
				
			//Set notes for the parameters used on to create the map
				For(b=0;b<numMaps;b+=1)
					If(b == 0)
						Wave notedWave = dFWave
					ElseIf(b == 1)
						Wave notedWave = dFPeakWave
					ElseIf(b == 2)
						Wave notedWave = dFPeakLoc
					ElseIf(b == 3)
						Wave notedWave = dFIntWave
					ElseIf(b == 4)
						Wave notedWave = dFIndexWave
					EndIf 
					
					If(c==0 && numChannels == 1 && !doRatio)
						Note/K notedWave,"TYPE:∆F/F"
						Note notedWave,"CHANNEL:1"
					ElseIf(c==2 && !doRatio)
						Note/K notedWave,"TYPE:∆F/F"
						Note/K notedWave,"CHANNEL:2"
					ElseIf(doRatio)
						Note/K notedWave,"TYPE:∆G/R"
						Note/K notedWave,"CHANNEL:1/2"
					EndIf
					
					Note notedWave,"MEASURE:" + measureType
					Note notedWave,"BSL_START:" + num2str(bslnStartTm)
					Note notedWave,"BSL_END:" + num2str(bslnEndTm)
					Note notedWave,"PK_START:" + num2str(startTm)
					Note notedWave,"PK_END:" + num2str(endTm)
					If(didSmooth)
						Note notedWave,"SMOOTH:" + num2str(smoothVar)
					EndIf
					Note notedWave,"PRE-SPATIAL:" + num2str(spatialFilter)
					Note notedWave,"POST-SPATIAL:" + num2str(postSpatial)
					Note notedWave,"NOISE:" + num2str(cleanNoise)
					Note notedWave,"LASER:" + num2str(removeLaserResponse)
					Note notedWave,"MASK:" + NameOfWave(theMask)
				EndFor	
	
		EndFor
			If(doRatio)
				print "∆G/R Map for " + scanPath + " in " + num2str(StopMSTimer(timerRef)/(10^6)) + "s" 
			Else
				print "∆F/F Map for " + scanPath + " in " + num2str(StopMSTimer(timerRef)/(10^6)) + "s" 
			EndIf		
			
			KillWaves/Z redBaseline,greenBaseline
	EndFor		
End

Function MakeVarMap(theWave)
	Wave theWave
	Variable i,rows,cols,frames
	
	//Get dimensions
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	frames = DimSize(theWave,2)
	
	String varMapName = NameOfWave(theWave) + "_var"
	Duplicate/O theWave,$varMapName
	Wave varMap = $varMapName
	Redimension/S/N=(rows,cols,0) varMap
	varMap = 0
				
	//Calculate variance across frames
	MatrixOP/FREE/O theMean = sumBeams(theWave)
	MultiThread theMean /= frames
				
	For(i=0;i<frames;i+=1)
		MultiThread varMap += (theMean - theWave[p][q][i])^2
	EndFor
				
	MultiThread varMap /= (frames - 1)	
End


//Replaces extreme fluorescence values with the mean.
Function/WAVE CleanUpNoise(theWave,threshold)
	Wave theWave
	Variable threshold
	Variable i,j,rows,cols,frames
	
	//Get dimensions
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	frames = DimSize(theWave,2)
	
	//First make a variance map
	String varMapName = NameOfWave(theWave) + "_var"
	Duplicate/O theWave,$varMapName
   Wave varMap = $varMapName
	Redimension/S/N=(rows,cols,0) varMap
	varMap = 0
				
	//Calculate variance across frames
	MatrixOP/FREE/O theMean = sumBeams(theWave)
	MultiThread theMean /= frames
				
	For(i=0;i<frames;i+=1)
		MultiThread varMap += (theWave[p][q][i] - theMean[p][q])^2
	EndFor
				
	MultiThread varMap /= (frames - 1)	
	MultiThread varMap = sqrt(varMap)
				
	//Use the variance map to identify pixels that have large outlier values
	Duplicate/FREE theWave,theWaveNoise
				
	For(j=0;j<frames;j+=1)
		MatrixOP/FREE theLayer = layer(theWave,j)
		MultiThread theWaveNoise[][][j] = (theLayer[p][q][0] > theMean[p][q][0] + threshold*varMap[p][q][0]) ? theMean[p][q][0] : theLayer[p][q][0]
	EndFor
	KillWaves/Z varMap		
	return theWaveNoise	
End
	




//Perform a user defined operation between two waves
//Function doOperation()
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR selWaveList = root:Packages:MBr:selWaveList
	SVAR whichList = root:Packages:analysisTools:whichList
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	
	Variable numWaves = DimSize(waveListTable,0)
	Variable i
	
	//Set up operation counter for running from the command line
	Variable/G root:Packages:analysisTools:opCounter
	NVAR opCounter = root:Packages:analysisTools:opCounter
	opCounter = 0
	
	//Using a data set?
	ControlInfo/W=analysis_tools useDataSetCheck
	Variable useDS = V_Value
	
	//Resolve the operation
	ControlInfo/W=analysis_tools operation
	String theOp = S_Value
	ControlInfo/W=analysis_tools outputSuffix
	String suffix = S_Value
	
	String theWaveList = ""
	
	If(useDS)
		String DSList = GetDSinList(theOp)
		//data sets must be of equal length
		If(!DSEqualLength(DSList))
			Abort "Data sets must have the same number of waves"
		EndIf
				
		Variable numDS = ItemsInList(DSList,";")
		If(numDS == 0)
			theWaveList = GetDSWaveList()
			String DSwave = StringFromList(0,theWaveList,",")
			String operation = ResolveOperation(theOp,suffix,DSwave = DSwave)
		Else
			opCounter = -1
			operation = ResolveOperation(theOp,suffix)
			opCounter = 0
		EndIf
	Else
		operation = ResolveOperation(theOp,suffix)
	EndIf
	
	strswitch(operation)
		case "1":
			//average all waves
			If(useDS)
				theWaveList = GetDSWaveList(separator=";")
			//	avgSelectedWaves(theWaveList,0)
			Else
				If(cmpstr(whichList,"AT") == 0)
					SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						theWaveList += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i] + ";"
					EndFor
					avgSelectedWaves(theWaveList,0)
				ElseIf(cmpstr(whichList,"Browser") == 0)
					SetDataFolder $cdf	 //set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						theWaveList += cdf + waveListTable[i] + ";"
					EndFor
					avgSelectedWaves(theWaveList,0)
				EndIf
			EndIf
			break
		case "2": 
			//add up all the waves
			
			If(useDS)
				theWaveList = GetDSWaveList(separator=";")
				addSelectedWaves(theWaveList)
			Else
				SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
				theWaveList = ""
				For(i=0;i<DimSize(waveListTable,0);i+=1)
					theWaveList += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i] + ";"
				EndFor
				addSelectedWaves(theWaveList)
			EndIf
			break
		case "3":
			//standard error of the waves
			If(useDS)
				theWaveList = GetDSWaveList(separator=";")
				avgSelectedWaves(theWaveList,1)
			Else
				SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
				theWaveList = ""
				For(i=0;i<DimSize(waveListTable,0);i+=1)
					theWaveList += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i] + ";"
				EndFor
				avgSelectedWaves(theWaveList,1)
			EndIf
			break
		case "5":
			SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))
			Wave w1 = $waveListTable[0]
			SetDataFolder $("root:twoP_Scans:" + StringFromList(1,scanListStr,";"))
			Wave w2 = $waveListTable[1]
		
			String outWaveName = NameOfWave(w1) + "_ratio"
			SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))
			Duplicate/O w1,$outWaveName
	
			Wave outWave = $outWaveName
			outWave = 0
	
			outWave = w2/w1
	
			outWave = (outWave == inf) ? nan : outWave
			outWave = (outWave == 0) ? nan : outWave
			outWave = (outWave > 10 || outWave < -10) ? nan : outWave
			MatrixFilter/N=7 median outWave
		case "6":
			//kill all the selected waves
			If(useDS)
			
			Else
				If(cmpstr(whichList,"AT") == 0)
					SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						Wave/Z theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i])
						KillWaves/Z theWave
					EndFor
				ElseIf(cmpstr(whichList,"Browser") == 0)
					SetDataFolder $cdf	 //set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						KillWaves/Z $(cdf + waveListTable[i])
					EndFor
				EndIf
			EndIf
			break
		case "7":
			//display the selected waves in a single graph
			If(useDS)
				theWaveList = GetDSWaveList()
				Display $StringFromList(0,theWaveList,",")
				For(i=1;i<ItemsInList(theWaveList,",");i+=1)
					AppendToGraph $StringFromList(i,theWaveList,",")
				EndFor
			Else
				print "can only display using data set function for now."
			EndIf
			break
		case "8":
			//edit the waves
			If(useDS)
				theWaveList = GetDSWaveList()
				Execute/Q/Z "Edit/K=0 " + theWaveList
			EndIf
			break
		case "9":
			//Differentiate
			If(useDS)
				theWaveList = GetDSWaveList()
				For(i=0;i<ItemsInList(theWaveList,",");i+=1)
					DifferentiateWaves($StringFromList(i,theWaveList,";"))
				EndFor
			Else
				If(cmpstr(whichList,"AT") == 0)
					SetDataFolder $("root:twoP_Scans:" + StringFromList(0,scanListStr,";"))	//set to first waves data folder
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						Wave/Z theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + waveListTable[i])
						DifferentiateWaves(theWave)
					EndFor
				ElseIf(cmpstr(whichList,"Browser") == 0)
					SetDataFolder $cdf	 //set to first waves data folder
					theWaveList = ""
					For(i=0;i<DimSize(waveListTable,0);i+=1)
						theWaveList += cdf + waveListTable[i] + ";"
						DifferentiateWaves($StringFromList(i,theWaveList,";"))
					EndFor
				EndIf
			EndIf
			break
		default:
			//free form
			opCounter = 0
			If(useDS)
				DSList = GetDSinList(theOp)
				//data sets must be of equal length
				If(!DSEqualLength(DSList))
					Abort "Data sets must have the same number of waves"
				EndIf
				
				numDS = ItemsInList(DSList,";")
				If(numDS == 0)	//if DS reference is from the selection
					theWaveList = GetDSWaveList()
					numWaves = ItemsInList(theWaveList,",")
					operation = ""
					For(i=0;i<numWaves;i+=1)
						opCounter = i
						DSwave = StringFromList(i,theWaveList,",")
						operation = ResolveOperation(theOp,suffix,DSwave = DSwave)
						Execute/Z operation
						print operation
					EndFor
				Else //if DS reference is stated in the command
					theWaveList = GetDSWaveList(dsName=StringFromList(0,DSList,";"))
					numWaves = ItemsInList(theWaveList,",")
					operation = ""
					For(i=0;i<numWaves;i+=1)
						opCounter = i
						operation = ResolveOperation(theOp,suffix)
						Execute/Z operation
						print operation
					EndFor
				EndIf
			Else
				Execute/Z operation
				print operation
				String outputWaveStr = StringFromList(0,operation,"=")
				Wave outWave = $outputWaveStr
			
				//Set scale
				String scaleWaveName = "root:twoP_Scans:" + StringFromList(0,scanListStr,";") + ":" + waveListTable[0]
				If(DimSize(outWave,2) > 0)
					SetScale/P x,DimOffset($scaleWaveName,0),DimDelta($scaleWaveName,0),outWave
					SetScale/P y,DimOffset($scaleWaveName,1),DimDelta($scaleWaveName,1),outWave
					SetScale/P z,DimOffset($scaleWaveName,2),DimDelta($scaleWaveName,2),outWave
				ElseIf(DimSize(outWave,1) > 0)
					SetScale/P x,DimOffset($scaleWaveName,0),DimDelta($scaleWaveName,0),outWave
					SetScale/P y,DimOffset($scaleWaveName,1),DimDelta($scaleWaveName,1),outWave
				Else
					SetScale/P x,DimOffset($scaleWaveName,0),DimDelta($scaleWaveName,0),outWave
				EndIf
			
			//	applyFilters(outWave)
			EndIf
	endswitch
End

//Makes histogram of a waves value distribution
Function freqHistogram(inWave,[binWidth])
	Wave inWave
	Variable binWidth
	Variable low,high,numBins
	
	low = WaveMin(inWave)
	high = WaveMax(inWave)
	
	If(ParamIsDefault(binWidth))
		binWidth = 0.05
	EndIf
	
	numBins = ceil((high - low)/binWidth)
	
	String outWaveName = NameOfWave(inWave) + "_hist"
	Make/O/N=(numBins) $outWaveName
	Wave outWave = $outWaveName
	outWave = 0
	
	Variable i,j,rows,cols,theBin,count
	
	rows = DimSize(inWave,0)
	cols = DimSize(inWave,1)
	If(cols == 0)
		cols = 1
	Endif
	count = 0
	For(i=0;i<rows;i+=1)
		For(j=0;j<cols;j+=1)
			theBin = floor((inWave[i][j] - low)/binWidth)
			If(numType(theBin) == 2)
				continue
			EndIf
			outWave[theBin] += 1
			count += 1
		EndFor
	EndFor
	
	outWave /= count
	
	SetScale/I x,low,high,outWave
	DoWindow FreqHist
	If(V_flag)
		KillWindow FreqHist
	EndIf
	Display/N=FreqHist outWave as "Frequency Histogram"
	ModifyGraph/W=FreqHist/Z mode=5,rgb=(0,0,0)
End


//Initiates line profile function
Function GetLineProfile()
	Variable/G root:var:activeProfile = 1
	
	If(!DataFolderExists("root:var"))
		NewDataFolder root:var
	EndIf
	SetDataFolder root:var
	Variable /G root:var:mouseEvent = 0
	
	GetWindow/Z kwTopWin wavelist
	Wave/T WavesOnGraph = W_WaveList
	Wave theWave = $WavesOnGraph[0][1]
	
	GetWindow/Z kwTopWin activeSW
	String/G root:var:graphName = S_Value
	SVAR graphName = root:var:graphName
	String/G root:var:windowName = graphName
	SVAR windowName = root:var:windowName
	
	If(StringMatch(windowName,"*#*"))
		windowName = StringFromList(0,windowName,"#")
	EndIf
	
	Make/O/N=0 root:var:xWave,root:var:yWave,root:var:xWaveIndex,root:var:yWaveIndex
	Wave xWave = root:var:xWave
	Wave yWave = root:var:yWave
	
	String/G root:Packages:analysisTools:startROI
	SVAR startROI = root:Packages:analysisTools:startROI
	startROI = ""
	String/G root:Packages:analysisTools:endROI
	SVAR endROI = root:Packages:analysisTools:endROI
	endROI = ""
	String/G root:Packages:analysisTools:prevROI
	SVAR prevROI = root:Packages:analysisTools:prevROI
	prevROI = ""
	
	Wave roiTable = root:roiTable
	
	//Make distance matrix wave
	Wave/Z dMatrix = root:ROI_dist_matrix
	If(!WaveExists(dMatrix))
		Make/O/N=(DimSize(roiTable,0),DimSize(roiTable,0)) root:ROI_dist_matrix
		Wave dMatrix = root:ROI_dist_matrix
		dMatrix = 0
	EndIf
	
	SetWindow $windowName, hook(getLineHook)=getLineHook
	return 0
End


//Takes the distData waves, and correlates each ROI over trials with the ROIs in its distData wave. 
//Appends that correlation value to the end of the distData wave
Function correlateDistData()
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i,j,k,m,numROI
	String startROI,startDataList
	
	numROI = ItemsInList(ROIListStr,";")
	
  //Loop through angles
  For(m=0;m<8;m+=1)
	
	//Loop through reference ROIs
	For(i=0;i<numROI;i+=1)
		//Get the distData wave for each reference ROI
		startROI = StringFromList(i,ROIListStr,";")
		Wave/T distData = $("root:ROI_analysis:distData_" + startROI)
		
		If(!WaveExists(distData))
			//go to next ROI if there is no distData
			continue
		EndIf
		
		//Get the DStuning plots for each ROI
		SetDataFolder root:ROI_analysis:Values
		startDataList = WaveList("DStuning_c100_*ROI" + startROI + "*",";","DIMS:1")
		
		Variable repeats = ItemsInList(startDataList,";")
		//this holds the trial to trial amplitudes 
		Make/FREE/N=(repeats) tempStart = 0
		Make/FREE/N=(repeats) tempEnd = 0
		
		//Loop through end ROIs
		For(k=0;k<DimSize(distData,1);k+=1)
			//Matches the end ROI wave 
			String endDataList = WaveList("DStuning_c100_*ROI" + distData[0][k] + "*",";","DIMS:1")
			
			//Loop through the number of repeats per ROI to build the trial-to-trial amplitude waves to be correlated
			For(j=0;j<repeats;j+=1)
				Wave startData = $StringFromList(j,startDataList)
				Wave endData = $StringFromList(j,endDataList)
				tempStart[j] = startData[m]	//using only 1 angle for now.
				tempEnd[j] = EndData[m]
			EndFor
			
			//Make the x and y waves to hold the distance values (X), and the correlation values (Y)
			Make/O/N=(DimSize(distData,1)) $(NameOfWave(distData) + "_corrY_" + num2str(m)),$(NameOfWave(distData) + "_corrX_" + num2str(m))
			Wave corrY = $(NameOfWave(distData) + "_corrY_" + num2str(m))
			Wave corrX = $(NameOfWave(distData) + "_corrX_" + num2str(m))
			
			StatsLinearCorrelationTest/Q/Z tempStart,tempEnd
			Wave corrWave = W_StatsLinearCorrelationTest
			
			If(!WaveExists(corrWave))
				Abort "Can't find correlation output wave"
			EndIf
			
			//Get the correlation coefficient R
			corrY[k] = corrWave[1]
			corrX[k] = str2num(distData[1][k])
			
		EndFor
	EndFor
	
	//Concatenate the correlation/distance waves into a single wave
	String theListY = WaveList("distData*corrY*" + num2str(m),";","DIMS:1")
	String theListX = WaveList("distData*corrX*" + num2str(m),";","DIMS:1")
	Concatenate/NP/O theListY,$("distData_corrY_" + num2str(m))
	Concatenate/NP/O theListX,$("distData_corrX")
  EndFor

End




//Takes image registration parameters and applies them to other images
Function applyImageRegTemplate()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable xDelta,yDelta,applyOffsetX,applyOffsetY,useScanList,i,j
	
	//Get the selected parameter wave
	ControlInfo/W=analysis_tools registrationTemplatePopUp
	Wave param = $("root:twoP_Scans:" + S_Value)
	If(!WaveExists(param))
		Abort "Couldn't find the parameter wave."
	EndIf
	
	xDelta = round(param[0])
	yDelta = round(param[1])
	
	ControlInfo/W=analysis_tools useScanListCheck
	useScanList = V_Value
	
	//Get the channel
	String channel = getChannel(0)
	For(j=0;j<ItemsInList(channel,";");j+=1)
		//if two channels are checked, it loops through both channels
		String currentChannel = StringFromList(j,channel,";")
		
		If(useScanList)
			String testImageList = scanListStr
		Else
			ControlInfo/W=analysis_tools testImagePopUp
			testImageList = "root:twoP_Scans:" + S_Value + ":" + S_Value + "_" + currentChannel
		EndIf
	
		For(i=0;i<ItemsInList(testImageList,";");i+=1)
			If(useScanList)
				Wave testImage = $("root:twoP_Scans:" + StringFromList(i,testImageList,";") + ":" + StringFromList(i,testImageList,";")) + "_" + currentChannel
			Else
				Wave testImage = $StringFromList(i,testImageList,";")
			EndIf
			
			If(useScanList)
				Wave/Z param = $("root:twoP_Scans:" + StringFromList(i,testImageList,";") + ":W_RegParams")
				If(!WaveExists(param))
					continue
				EndIf
				xDelta = round(param[0])
				yDelta = round(param[1])
			EndIf
					
			//Check if wave has been tagged, indicating that it already has been registered.
			Variable tagPresent = CheckTag(testImage,0,0,4,99)
			If(tagPresent)
			//	continue
			EndIf
			Variable theMean = mean(testImage)
			
			If(xDelta < 0)
				DeletePoints/M=0 0,-xDelta,testImage
				InsertPoints/M=0 DimSize(testImage,0),-xDelta,testImage
				//testImage[DimSize(testImage,0)+xDelta,DimSize(testImage,0)-1][] = testImage[p+xDelta][q]
				//inserted points become noise around the mean signal
				testImage[DimSize(testImage,0)+xDelta,DimSize(testImage,0)-1][] = theMean + gnoise(0.05*theMean)
			ElseIf(xDelta > 0)
				InsertPoints/M=0 0,xDelta,testImage
				DeletePoints/M=0 DimSize(testImage,0)-xDelta,xDelta,testImage
				//testImage[0,xDelta-1][] = testImage[p+xDelta][q]
				testImage[0,xDelta-1][] = theMean + gnoise(0.05*theMean)
			EndIf
		
			If(yDelta < 0)
				DeletePoints/M=1 0,-yDelta,testImage
				InsertPoints/M=1 DimSize(testImage,1),-yDelta,testImage
				//testImage[][DimSize(testImage,1)+yDelta,DimSize(testImage,1)-1] = testImage[p][q+yDelta]
				testImage[][DimSize(testImage,1)+yDelta,DimSize(testImage,1)-1] = theMean + gnoise(0.05*theMean)
			ElseIf(yDelta > 0)
				InsertPoints/M=1 0,yDelta,testImage
				DeletePoints/M=1 DimSize(testImage,1)-yDelta,yDelta,testImage
				//testImage[][0,yDelta-1] = testImage[p][q+yDelta]
				testImage[][0,yDelta-1] = theMean + gnoise(0.05*theMean)
			EndIf
			TagWave(testImage,0,0,4,99)
		EndFor
	EndFor
End



//Fits an 5-polynomial to the data before the light response and subtracts it out.
//Can use the FindPeakTrough option (set to usePkTrough to 1 and set the estimated peak time)...
//...for optimizing the range of the fit, which can distort the data a bit if it's set improperly. 

Function FlattenLaserResponse(theWave,xStart,xEnd,usePkTrough,estimatedPkTm)
	Wave theWave
	Variable xStart,xEnd,usePkTrough,estimatedPkTm
	Variable troughVal
	
	//Should we even do the flattening?
	//test average for early and late in the baseline to see if they are actually trending down.
	Variable early,late,xMiddle,total
	xMiddle = 0.5*(xStart + xEnd)
	
	early = mean(theWave,xStart,xMiddle)
	late = mean(theWave,xMiddle,xEnd)
	total = mean(theWave,xStart,xEnd)
	
	variable earlyCenterX = x2pnt(theWave,0.5*(xStart + xMiddle))
	variable lateCenterX = x2pnt(theWave,0.5*(xEnd + xMiddle))
	variable totalCenterX = x2pnt(theWave,xMiddle)

	variable startX = x2pnt(theWave,xStart)
	
	Duplicate/O theWave,temp
	SEtScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),temp
	temp = nan
	temp[earlyCenterX] = early
	temp[lateCenterX] = late
	temp[totalCenterX] = total
	
		
	If(usePkTrough)
		troughVal = FindPeakTrough(theWave,estimatedPkTm,"YVALUE")
		Variable troughX = FindPeakTrough(theWave,estimatedPkTm,"")
	EndIf
	
	
	CurveFit/X/L=(troughX - startX)/Q/M=2/W=0 line,temp[startX,troughX]/D
	Wave theFit = $("fit_" + NameOfWave(temp))
	SetScale/I x,xStart,pnt2x(theWave,troughX),theFit
	
	theWave[startX,troughX] = theWave[p] - theFit[x2pnt(theFit,pnt2x(theWave,p))]
	
	Variable minVal = WaveMin(theFit)
	
	If(troughVal == -1)
	//No trough was found
		return -1
	EndIf
	
	If(usePkTrough)
		theWave[x2pnt(theWave,xStart),troughX] += troughVal
	Else
		theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)] += minVal
	EndIf
		KillWaves/Z temp

	return 0
	
	//CurveFit/Q/M=2/W=0 poly_XOffset 3, theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)]/D
	CurveFit/Q/M=2/W=0 line, theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)]/D
	//CurveFit/Q/M=2/W=0 exp_XOffset, theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)]/D

	Wave theFit = $("fit_" + NameOfWave(theWave))
	//Redimension/N=(DimSize(theWave,0)) theFit
		
	minVal = WaveMin(theFit)
	//theFit -= minVal
	theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)] = theWave[p] - theFit[x2pnt(theFit,pnt2x(theWave,p))]
	If(usePkTrough)
		theWave[x2pnt(theWave,xStart),x2pnt(theWave,xEnd)] += troughVal
	EndIf
	//theWave[x2pnt(theWave,xEnd)+1,DimSize(theWave,0)-1] = theWave[p] - theFit[DimSize(theFit,0) - 1]
End

//Finds the start of the rising phase of the major peak in a wave
Function FindPeakTrough(theWave,estimatedPeakTime,returnValue)
	Wave theWave
	Variable estimatedPeakTime
	String returnValue
	Variable peakTm,peakIndex
	
	Duplicate/FREE theWave,smthWave	
	Smooth/S=2 13,smthWave

	If(!WaveExists(smthWave))
		return -1
	EndIf
	
	ControlInfo/W=analysis_tools peakStVar
	Variable pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	Variable pkEnd = V_Value
	
	ControlInfo/W=analysis_tools bslnStVar
	Variable bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	Variable bslnEnd = V_Value
	
	Variable pkStartIndex = x2pnt(smthWave,pkStart)
	
	WaveStats/Q/R=(pkStart,pkEnd) smthWave
	peakIndex = V_MaxRowLoc
	peakTm = V_MaxLoc
	
	
	//Is there an earlier peak that is better to use?
	Variable backCounter = 1
	Do
		WaveStats/Q/R=[pkStartIndex,peakIndex - backCounter] smthWave
		Variable peakIndex_early = V_MaxRowLoc
		Variable peakTm_early = V_MaxLoc
		Variable peakVal_early = V_Max
	
		If(peakIndex_early < peakIndex - backCounter - 1) // if it's found the peak more than 2 rows away from the right limit, that's a new peak.  
			
			//If the new peak is more than halfway down to the baseline, then it's not a peak.
			If(smthWave[peakIndex] - smthWave[peakIndex_early] > smthWave[peakIndex_early] - mean(smthWave,bslnStart,bslnEnd))
				break
			EndIf
			
			//use the earlier peak
			peakIndex = peakIndex_early
			peakTm = peakTm_early
			break
		EndIf
		
		backCounter += 1
	While(backCounter < peakIndex - pkStartIndex)
	
	//Is the last point in the window actually a peak?
	If(peakTm == pkEnd)
		WaveStats/Q/R=(pkEnd,pkEnd + 0.5) smthWave
		peakTm = V_MaxLoc
		If(peakTm != pkEnd)
			return -1
		EndIf
	EndIf
	
	//sigmoidal fit to find the trough x/y values
	CurveFit/N/Q/M=2/W=2 Sigmoid, smthWave[x2pnt(smthWave,bslnStart),peakIndex]/D
	Wave theFit = $("fit_" + NameOfWave(smthWave))
	
	//Find location where the sigmoidal fit is 5% of its maximum value - this is the trough.
	WaveStats/Q theFit
	FindLevel/EDGE=1/Q theFit,V_min + 0.05*(V_max-V_min)
	Variable trough2,troughVal2
	
	trough2 = x2pnt(smthWave,V_LevelX)
	troughVal2 = V_min + 0.05*(V_max-V_min)
	
	
	Duplicate/FREE smthWave,diffWave
	Differentiate diffWave

	Variable value,i,changeTicker,trough
	changeTicker = 0
	i = 0
	value = 0
	
	//Works backwards from the peak.
	//Identify the trough of the peak after seeing 3 points in a row that are downwards sloping
	Do
		//Break in case it never finds a trough
		If(i > peakIndex)
			return -1
		EndIf
		
		If(diffWave[peakIndex - i] < 0)
			changeTicker +=1
		Else
			changeTicker = 0
		EndIf
		i+=1
	While(changeTicker < 3)	

	trough = peakIndex - i + 3
	
	If(cmpstr(returnValue,"YVALUE") == 0)
		return smthWave[trough2]
	Else
		return trough2
	EndIf
End

//Finds the start of the rising phase of the major peak in a wave
Function FindPeakTrough3D(theWave,estimatedPeakTime,returnValue)
	Wave theWave
	Variable estimatedPeakTime
	String returnValue
	Variable peakTm,peakIndex
	
	If(DimSize(theWave,2) == 0)
		Abort "Must use 3D wave."
	EndIf
	
	Duplicate/FREE theWave,smthWave

	Smooth/S=2/DIM=2 13, smthWave

	If(!WaveExists(smthWave))
		return -1
	EndIf
	
	//Waves to hold the peak indexes
	//Make/O/FREE/N=(DimSize(theWave,0),DimSize(theWave,1)) peakTm,peakIndex
	variable i
	//transpose the matrix so its an x-z series
	MatrixOP/FREE/S xzWave = transposeVol(smthWave,2)
	
	//Trim matrix around the estimated peak time
	Variable startPt,numberPts
	startPt = ScaleToIndex(theWave,estimatedPeakTime,2) - ScaleToIndex(theWave,0.5,2)
	numberPts = (ScaleToIndex(theWave,estimatedPeakTime,2) + ScaleToIndex(theWave,0.5,2)) - startPt
	DeletePoints/M=0 0,startPt,xzWave
	Redimension/N=(numberPts,-1,-1) xzWave
	
	//Find the peak data point in the extracted region
	MatrixOP/FREE peakTmCols = maxCols(xzWave)
	MatrixOP/FREE peakTmMatrix = transposeVol(peakTmCols,3)
	MatrixOP/O peakTmMatrix = peakTmMatrix^t 
	peakTmMatrix += IndexToScale(theWave,startPt,2)
	Duplicate/FREE peakTmMatrix,peakIndexMatrix
	peakIndexMatrix = ScaleToIndex(theWave,peakTmMatrix,2)
	
	//Differentiate the smoothed matrix
	Duplicate/FREE smthWave,diffWave
	Differentiate/DIM=2 diffWave

	//Works backwards from the peak.
	//Identify the trough of the peak after seeing 3 points in a row that are downwards sloping
	Variable trough,completed,m,n
	Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1)) changeTicker,troughIndexMatrix
	changeTicker = 0
	troughIndexMatrix = 0
	i = 0
	
	//Get for trough positions
	Do
		If(i == startPt)
			//Need a break statement if noisy signals don't give a peak or trough after a certain point.
			break
		EndIf
		
		For(m=0;m<DimSize(theWave,0);m+=1)
			For(n=0;n<DimSize(theWave,1);n+=1)
				If(changeTicker[m][n] < 2)
					If(peakIndexMatrix[m][n] - i < 0)
						changeTicker[m][n] += 1
					Else
						changeTicker[m][n] = 0
					EndIf
				ElseIf(changeTicker[m][n] == 2)
					troughIndexMatrix = peakIndexMatrix[m][n] - i + 3
					troughIndexMatrix = (troughIndexMatrix[m][n] < 0) ? 0 : troughIndexMatrix[m][n]
				Else
					continue
				EndIf
			EndFor
		EndFor
		
		i+=1
		
		//stops when i is larger than the peak start point. 
	While(i < startPt)	
	
	//If(cmpstr(returnValue,"YVALUE") == 0)
	//	return smthWave[trough]
	//Else
		return trough
	//EndIf
End

//Takes multiple dF maps and associated stimulus angles, and creates a vector sum angle map
Function VectorSumMap()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable numScans,i,rows,cols,theAngle
	String scanName,channel,channelName
	
	//Get the channel
	channel = RemoveEnding(getChannel(1),";")
	If(cmpstr(channel,"ch1") == 0)
		channelName = "dF"
		channel = "ch1"
	ElseIf(cmpstr(channel,"ch2") == 0)
		channelName = "dF"
		channel = "ch2"
	ElseIf(cmpstr(channel,"ratio") == 0)
		channelName = "dGR"
		channel = "ch1"
	Else
		Abort "Must select a channel."
	EndIf
	
	numScans = ItemsInList(scanListStr,";")
	
	//Get first wave for dimensioning the output wave
	String theWaveName = StringFromList(0,scanListStr,";") 
	Wave/Z theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_peak")
	
	If(!WaveExists(theWave))
		Abort "Cannot find the wave " + NameOfWave(theWave)
	EndIf
	
	SetDataFolder GetWavesDataFolder(theWave,1)
	
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	
	//Make the operating waves for the vector sum
	Make/O/FREE/N=(rows,cols) vSumX,vSumY,totalSignal
	
	//Make output wave
	String outWaveName = "root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_vAng"
	Make/O/N=(rows,cols) $outWaveName
	Wave vAngle = $outWaveName
	
	outWaveName = "root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_vRad"
	Make/O/N=(rows,cols) $outWaveName
	Wave vRadius = $outWaveName
	
   outWaveName = "root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_DSI"
	Make/O/N=(rows,cols) $outWaveName
	Wave DSI = $outWaveName

	//Set scales
	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),vSumX,vSumY,totalSignal,vRadius,vAngle,DSI
	SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),vSumX,vSumY,totalSignal,vRadius,vAngle,DSI
		
	vAngle = 0
	vRadius = 0
	DSI = 0
	
	//Get the angles
	ControlInfo/W=analysis_tools angleList
	String angleList = S_Value
	
	If(ItemsInList(angleList,",") != numScans)
		Abort "# angles must equal # scans"
	EndIf
	
	vSumX = 0
	vSumY = 0
	totalSignal = 0
	
	//Loop through scans to make vector sum
	For(i=0;i<numScans;i+=1)
		//Get the scan wave
		theWaveName = StringFromList(i,scanListStr,";") 
		Wave/Z theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel + "_" + channelName + "_peak")
		
		If(!WaveExists(theWave))
			Abort "Cannot find the wave " + NameOfWave(theWave)
		EndIf
		
		theAngle = str2num(StringFromList(i,angleList,","))
		
		vSumX += theWave * cos(theAngle * pi/180)
		vSumY += theWave * sin(theAngle * pi/180)
		totalSignal += theWave
	EndFor
	
	vRadius = sqrt(vSumX^2 + vSumY^2)
	vAngle = -atan2(vSumY,vSumX) * 180/pi
	DSI = vRadius / totalSignal
	
	vAngle = (vAngle[p][q] < 0) ? vAngle[p][q] + 360 : vAngle[p][q]
	vAngle = 360 - vAngle
	
	ControlInfo/W=analysis_tools histogramCheck
	If(V_Value)
		String histName = NameOfWave(vAngle) + "_hist"
		Histogram/C/B={0,2,180}/DEST=$histName vAngle
		Wave theHist = $histName
		SetScale/P x,DimOffset(theHist,0),DimDelta(theHist,0),"degrees",theHist
	
		//Display histogram polar plot
		NewPolarPlot()
		GetWindow/Z kwTopWin activeSW
		WMPolarAppendTrace(S_Value,theHist,$"", 360)
		ModifyGraph rgb(polarY0)=(0,0,0),lsize=2
	EndIf
		
End

//Clone of the packages polar plot, but doesn't require the GUI to be running
Function NewPolarPlot()
	String srcGraphName = "_default_"
	String srcDF= WMPolarGraphDF(srcGraphName)
	
	if( strlen(srcDF) == 0 || DataFolderExists(srcDF) == 0 )
		NewDataFolder root:Packages:WMPolarGraphs
		NewDataFolder root:Packages:WMPolarGraphs:'_default_'
	endif
	
	srcDF= WMPolarGraphDF(srcGraphName)
	
	if( strlen(srcDF) == 0 || DataFolderExists(srcDF) == 0 )	
		DoAlert 0, "Polar settings for graph \"" + srcGraphName +"\" are missing. Expected datafolder is "+srcDF
		return 0
	endif

	WMPolarGraphDefaults("_default_")

	String newGraphName= WMPolarNewGraphName()
	String destDF= WMPolarGraphDF(newGraphName) // returns full path from dfName

	Display/W=(10,45,360,345)
	DoWindow/C $newGraphName
	WMPolarSaveSettingsName(newGraphName,newGraphName)	// initially the graph name and data folder name are the same.
	
	SetWindow $newGraphName hook=WMPolarGraphHook, hookEvents=1	// mouse button events

	// copy the settings
	if( DataFolderExists(destDF) )
		WMPolarCleanOutDF(destDF)	// should remove any dependencies that prevent folder deletion.
		KillDataFolder/Z $destDF
	endif
	DuplicateDataFolder $srcDF+":", $destDF
	WMPolarCleanOutDF(destDF)
	
	DoWindow/F WMPolarGraphPanel	// nothing interesting can be done with an empty polar graph, 
//	WMPolarPanelUpdate()				// panel activation will cause WMPolarPanelUpdate to run, anyway


End



Function rescale2P_Scans()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	ControlInfo/W=analysis_tools scaleFactor
	Variable scaleFactor = V_Value*(1e-6)//microns per volt
	Variable numScans,numChannels,i,j,XVStart,XVEnd,YVStart,YVEnd
	String folder,channel,info,theChannel
	scanListStr = "Scan_014"
	numScans = ItemsInList(scanListStr,";")
	channel = getChannel(0)
	numChannels = ItemsInList(channel,";")
	
	For(i=0;i<numScans;i+=1)
		folder = "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":"
		theChannel = StringFromList(0,channel,";")	//only one info wave for all the channels
		Wave theWave = $(folder + StringFromList(i,scanListStr,";") + "_" + theChannel)
		
		info = getScanInfo(theWave)
		
		If(cmpstr(info,"-1") == 0)
			DoAlert 0,"Couldn't find the scan info for scan: " + NameOfWave(theWave)
		EndIf
		
		//Get the galvo voltages
		XVStart = str2num(StringByKey("XSV",info,":","\r"))
		XVEnd = str2num(StringByKey("XEV",info,":","\r"))
		YVStart = str2num(StringByKey("YSV",info,":","\r"))
		YVEnd = str2num(StringByKey("YEV",info,":","\r"))
		
		//Reset the scales according to the scale factor
		For(j=0;j<numChannels;j+=1)	
			theChannel = StringFromList(j,channel,";")	
			Wave theWave = 	$(folder + StringFromList(i,scanListStr,";") + "_" + theChannel)
			SetScale/I x,XVStart*scaleFactor,XVEnd*scaleFactor,theWave
			SetScale/I y,YVStart*scaleFactor,YVEnd*scaleFactor,theWave
		EndFor
		
		//Rewrite the scan info note with the correct pixel size
		Variable xPixels,yPixels,XVrange,YVrange,newXpixSize,newYpixSize,xPos,yPos,newXPos,newYPos
		//xPixels = str2num(StringByKey("PixWidth",info,":","\r"))
		//yPixels = str2num(StringByKey("PixHeight",info,":","\r"))
		//XVrange = abs(XVEnd - XVStart)
		//YVrange = abs(YVEnd - YVStart)
		newXpixSize = DimDelta(theWave,0)	//scaled microns per pixel in X
		newYpixSize = DimDelta(theWave,1)	  //scaled microns per pixel in Y
		info = ReplaceStringByKey("XpixSize",info,num2str(newXpixSize),":","\r")
		info = ReplaceStringByKey("YpixSize",info,num2str(newYpixSize),":","\r")
		//replace the x and y offset scales
		newXPos = DimOffset(theWave,0)//XVStart * scaleFactor
		newYPos = DimOffset(theWave,1)//YVStart * scaleFactor
		info = ReplaceStringByKey("Xpos",info,num2str(newXPos),":","\r")
		info = ReplaceStringByKey("Ypos",info,num2str(newYPos),":","\r")
		
		String scanName = ParseFilePath(1,NameOfWave(theWave),"_",1,0)
		SVAR scanInfo = $(folder + scanName + "info")
		scanInfo = info
	EndFor
End



//Uses scanListStr to compute the correlation across trials for specific x and y pixel
Function spatialCov([threshold,xPix,yPix,filter])
	Variable threshold,xPix,yPix,filter//filter is 1 for 3x3 avg, or 0 for no filter
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable i,j,k,m,n,xDim,yDim,numScans,pixelNumRef,pixelNumTest
	String theScan,theFolder,theChannel
	Variable progress = 0
	
	If(ParamIsDefault(xPix) && !ParamIsDefault(filter))
		Display/N=Progress
		SetDrawEnv fsize=20,xcoord=prel,ycoord=prel
		DrawText 0.5,0.5,num2str(progress) + " %"
	EndIf
	
	If(ParamIsDefault(filter))
		filter = 0
	EndIf
	
	numScans = ItemsInList(scanListStr,";")
	//Make the stack of images for covariance analysis
	For(k=0;k<numScans;k+=1)
		theScan = StringFromList(k,scanListStr,";")
		theFolder = "root:twoP_Scans:" + theScan
		theChannel = RemoveEnding(getChannel(1),";")
		Wave theWave = $(theFolder + ":" + theScan + "_" + theChannel + "_dF_peak")
		If(!WaveExists(theWave))
			Abort "Cannot find wave: " + NameOfWave(theWave)
		EndIf
		
		If(k==0)	//first pass
			xDim = DimSize(theWave,0)
			yDim = DimSize(theWave,1)
			Make/FREE/N=(xDim,yDim,numScans) imageStack
			
			//Make wave to hold correlation values
			SetDataFolder GetWavesDataFolder(theWave,1)
			WaveStats/Q theWave			
		EndIf
		imageStack[][][k] = theWave[p][q][0]
	EndFor
	
	Variable count = 0
	If(!ParamIsDefault(threshold))	
		For(i=0;i<xDim;i+=1)
			For(j=0;j<yDim;j+=1)
				If(imageStack[i][j][0] > threshold)
					count += 1
				EndIf
			EndFor
		EndFor
	Else
		count = xDim*yDim
	EndIf
	
	Variable startIndex,endX,endY,refEndX,refEndY
	If(!ParamIsDefault(xPix))
		If(ParamIsDefault(yPix))
			Abort "Must include both x and y pixel locations"
		EndIf
		Make/O/N=(xDim,yDim) $("correlation_x" + num2str(xPix) + "_y" + num2str(yPix))
		Wave correlation = $("correlation_x" + num2str(xPix) + "_y" + num2str(yPix))
		
		If(filter)
			startIndex = 1
			endX = xDim - 1
			refEndX = 2
			endY = yDim - 1
			refEndY = 2
		Else
			endX = xDim
			refEndX = 1
			endY = yDim
			refEndY = 1
			startIndex = 0
		EndIf
	Else
		Make/O/N=(count,count) $("corr_matrix")//matrix excludes NaNs for sizing
		Wave correlation = $("corr_matrix")
		startIndex = 0
		refEndX = xDim
		refEndY = yDim
		endX = xDim
		endY = yDim
	EndIf	
	correlation = 0
	
	//Z-beams to be compared
	Make/FREE/N=(numScans) refBeam,testBeam
		
	If(filter)
		Make/FREE/N=(3,3) buffer
	EndIf
	
	If(!ParamIsDefault(xPix))
		If(filter)
			For(k=0;k<numScans;k+=1)
				buffer[][] = imageStack[xPix-1 + p][yPix-1 + q][k]
				refBeam[k] = avgNaNWave(buffer)
			EndFor
		Else
			refBeam[] = imageStack[xPix][yPix][p]
		EndIf
	EndIf

	Variable refCount,testCount
	refCount = -1
	testCount = -1
	
	//Compute pearson coefficient between two Z-beams
	For(m=startIndex;m<refEndX;m+=1)//sets the reference pixel
		For(n=startIndex;n<refEndY;n+=1)
			pixelNumRef = m + n*xDim
			
			//only for full image xcorr
			If(ParamIsDefault(xPix))
				refBeam[] = imageStack[m][n][p]
			EndIf
					
			//skip pixel if its NaN or under threshold
			If(numtype(refBeam[0]) == 2)
				If(!ParamIsDefault(xPix))
					correlation[i][j] = nan
				EndIf
				continue
			ElseIf(!ParamIsDefault(threshold))
				If(refBeam[0] < threshold)
					continue
				EndIf
			EndIf
			
			//set counters
			refCount += 1
			testCount = -1		
			
			For(i=startIndex;i<endX;i+=1)
				For(j=startIndex;j<endY;j+=1)
					pixelNumTest = i + j*xDim

					testBeam[] = imageStack[i][j][p]
					
					//skip pixel if its NaN or under threshold
					If(numtype(testBeam[0]) == 2)
						If(!ParamIsDefault(xPix))
							correlation[i][j] = nan
						EndIf
						continue
					ElseIf(!ParamIsDefault(threshold))
						If(testBeam[0] < threshold)
							continue
						EndIf
					EndIf
					
					//set counters
					testCount += 1
					
					//3x3 spatial averaging
					If(filter)
						For(k=0;k<numScans;k+=1)
							buffer[][] = imageStack[i-1 + p][j-1 + q][k]
							testBeam[k] = avgNaNWave(buffer)
						EndFor
					EndIf			
					
					//Do the two beams covary across trials?
					//reference on X axis, test on Y axis
					If(ParamIsDefault(xPix))
						correlation[refCount][testCount] = StatsCorrelation(refBeam,testBeam)
					Else
						correlation[i][j] = StatsCorrelation(refBeam,testBeam)
					EndIf
				EndFor
			EndFor
			
			//only progress % if doing entire image xcorr.
			If(ParamIsDefault(xPix) && !ParamIsDefault(filter))
				progress += 1/(count)
				DrawAction/W=Progress delete
				SetDrawEnv fsize=20,xcoord=prel,ycoord=prel
				DrawText 0.5,0.5,num2str(progress*100) + " %"
				DoUpdate/W=Progress
			EndIf
		EndFor
	EndFor	
	If(!ParamIsDefault(xPix))
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),correlation
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),correlation
	EndIf
	
End

Function clusterMatrix(corrMatrix,numGroups)
	Wave corrMatrix
	Variable numGroups
	SetDataFolder GetWavesDataFolder(corrMatrix,1)
	
	KMeans/INIT=1/NCLS=(numGroups)/OUT=2/SEED=(ticks) corrMatrix
	
	Wave W_KMMembers = W_KMMembers
	Duplicate/O corrMatrix,clustMatrix
	Wave clustMatrix = clustMatrix
	Duplicate/O W_KMMembers,Sorting_Index
	Wave Sorting_Index = Sorting_Index;Sorting_Index=p
	Sort W_KMMembers,Sorting_Index
	clustMatrix = corrMatrix[Sorting_Index[p]][Sorting_Index[q]]
	SetScale/P x,0,1,clustMatrix
	SetScale/P y,0,1,clustMatrix
	
	KillWaves /Z M_KMClasses // Cleanup.  
End

Function FPClusterMatrix(corrMatrix,numGroups)
	Wave corrMatrix
	Variable numGroups
	SetDataFolder GetWavesDataFolder(corrMatrix,1)
	FPClustering/NOR/MAXC=(numGroups)/INCD/CM corrMatrix
	Duplicate/O corrMatrix,clustMatrix_FP
	Wave clutMatrix_FP
	Wave W_FPClusterIndex = W_FPClusterIndex
	Duplicate/O W_FPClusterIndex,Sorting_Index
	Wave Sorting_Index = Sorting_Index;Sorting_Index = p
	Sort W_FPClusterIndex,Sorting_Index
	clustMatrix_FP = corrMatrix[Sorting_Index[p]][Sorting_Index[q]]
	SetScale/P x,0,1,clustMatrix_FP
	SetScale/P y,0,1,clustMatrix_FP
End

Function colorByCluster(theWave,class,[threshold])
	Wave theWave,class
	Variable threshold
	Variable xDim,yDim,xDel,yDel,i,j
	
	//dimensions
	xDim = DimSize(theWave,0)
	yDim = DimSize(theWave,1)
	xDel = DimDelta(theWave,0)
	yDel = DimDelta(theWave,1)
	
	//output wave
	Make/O/N=(xDim,yDim) $("cluster_map_FP")
	Wave clusterMap = $("cluster_map_FP")
	Variable count = -1
	
	For(i=0;i<xDim;i+=1)
		For(j=0;j<yDim;j+=1)
			If(ParamIsDefault(threshold))
				If(numtype(theWave[i][j]) == 2)
					clusterMap[i][j] = NaN
					continue
				EndIf
			Else
				If(numtype(theWave[i][j]) == 2 || theWave[i][j] < threshold)
					clusterMap[i][j] = NaN
					continue
				EndIf
			EndIf
			count += 1
			clusterMap[i][j] = class[count] //class wave ignored NaNs before, so need a separate index
		EndFor
	EndFor
	
	
End



Function doCluster()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable i,j,k,xDim,yDim,numScans
	String theScan,theFolder,theChannel
	
	numScans = ItemsInList(scanListStr,";")
	//Make the stack of images for covariance analysis
	For(k=0;k<numScans;k+=1)
		theScan = StringFromList(k,scanListStr,";")
		theFolder = "root:twoP_Scans:" + theScan
		theChannel = RemoveEnding(getChannel(1),";")
		Wave theWave = $(theFolder + ":" + theScan + "_" + theChannel + "_dF_peak")
		If(!WaveExists(theWave))
			Abort "Cannot find wave: " + NameOfWave(theWave)
		EndIf
		
		If(k==0)	//first pass
			xDim = DimSize(theWave,0)
			yDim = DimSize(theWave,1)
			//Make wave to hold correlation values
			SetDataFolder GetWavesDataFolder(theWave,1)
			Make/O/N=(xDim*yDim,numScans) theData
			Wave theData = theData
		EndIf
		
		Make/FREE/N=(xDim) theCol
		Make/O/N=0 root:concat
		Wave concat = root:concat
		concat = 0
		
		//concatenate the image into a single row
		For(i=0;i<yDim;i+=1)
			theCol = theWave[p][i]
			Concatenate/NP {theCol},concat
		EndFor
		WaveTransform zapNaNs concat
		Redimension/N=(DimSize(concat,0),-1) theData
		theData[][k] = concat[p]
	EndFor
	FPClustering/CM/CAC/MAXC=(10) theData
	
End

Function CorrMatrix2()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i,j,numScans,numROIs
	String theROI,theScan,theChannel,theFolder,theWaveName
	
	numScans = ItemsInList(scanListStr,";")
	numROIs = ItemsInList(ROIListStr,";")
	Make/FREE/N=(numScans) refTrial,testTrial
	Make/FREE/N=(numScans,numROIs) trials
	
	For(i=0;i<numROIs;i+=1)
		theROI = StringFromList(i,ROIListStr,";")
		For(j=0;j<numScans;j+=1)
			theScan = StringFromList(j,ScanListStr,";")
			theFolder = "root:ROI_analysis:"
			theChannel = RemoveEnding(getChannel(1),";")
			theWaveName = theFolder + "ROI" + theROI + ":" + theScan + "_" + theChannel + "_" + "ROI" + theROI + "_dF"
			Wave theWave = $theWaveName
			//gets the peak over time window, puts into 2D wave.
			trials[j][i] = WaveMax(theWave,3,5)
			
			If(i == 0 && j == 0)//first pass
				SetDataFolder GetWavesDataFolder(theWave,1)
				Make/O/N=(numROIs,numROIs) $("peak_correlation")
				Wave correlation = $("peak_correlation")
			EndIf
		EndFor
	EndFor

	//get cross-correlations
	For(i=0;i<numROIs;i+=1)
		//reference
		refTrial = trials[p][i]
		For(j=0;j<numROIs;j+=1)
			//test
			testTrial = trials[p][j]
			correlation[i][j] = StatsCorrelation(refTrial,testTrial) 
		EndFor
	EndFor
End

//Takes a data set input or wave list and generates a correlation matrix
Function GetCorrelationMatrix(dataSet)
	String dataSet
	String DSfolder = "root:Packages:analysisTools:DataSets:"
	String dataSetPath = DSfolder + "DS_" + dataSet
	Variable i,j
	
	Wave/T DSTable = $dataSetPath
	If(!WaveExists(DSTable))
		print "Cannot find the data set: " + dataSet
		return -1
	EndIf
	
	Variable numWaves = DimSize(DSTable,0)
	
	//Set initial wave to navigate to its data folder
	Wave refWave = $DSTable[0]
	If(!WaveExists(refWave))
		print "Cannot find the wave: " + DSTable[i]
		return -1
	EndIf
		
	SetDataFolder GetWavesDataFolder(refWave,1)
	Make/O/N=(numWaves,numWaves) xCorr
	Wave xCorr = xCorr
	
	For(i=0;i<numWaves;i+=1)
		Wave refWave = $DSTable[i]
		If(!WaveExists(refWave))
			print "Cannot find the wave: " + DSTable[i]
			return -1
		EndIf
		
		For(j=0;j<numWaves;j+=1)
			Wave testWave = $DSTable[j]
			If(!WaveExists(testWave))
				print "Cannot find the wave: " + DSTable[j]
				return -1
			EndIf
			
			//Get correlation between refWave and testWave
			xCorr[i][j] = StatsCorrelation(refWave,testWave) 
		EndFor	
	EndFor	
End

Function ColorROI_xCorr(windowName,colorGroups)
	String windowName
	Wave colorGroups
	String ROIfolder = "root:twoP_ROIS"
	String traces = TraceNameList(windowName,";",1)
	
	Variable i,j,k
	Variable numROIs = DimSize(colorGroups,0)
	Variable numGroups = WaveMax(colorGroups) + 1

	For(i=0;i<numGroups;i+=1)
		//What color will this group get?
		String colorIndex = GetDistributedColorIndex(i,numGroups)
		String theCluster = ""
		//Get ROIs from that color group
		For(j=0;j<numROIs;j+=1)
			If(colorGroups[j] == i)
				theCluster += StringFromList(j,traces,";") + ";"
			EndIf
		EndFor
		//Color the ROIs on the graph
		For(k=0;k<ItemsInList(theCluster,";");k+=1)
			Variable color1,color2,color3
			color1 = str2num(StringFromList(0,colorIndex,","))
			color2 = str2num(StringFromList(1,colorIndex,","))
			color3 = str2num(StringFromList(2,colorIndex,","))
			String theTrace = StringFromList(k,theCluster,";")
			ModifyGraph/W=$windowName rgb($theTrace) = (color1,color2,color3)
		EndFor
	EndFor

End



//Function GetWaveList

Function DifferentiateWaves(theWave)
	Wave theWave
	String outWaveName = NameOfWave(theWave) + "_diff"
	Variable dim
	
	If(!WaveExists(theWave))
		Abort "Couldn't find the wave: " + NameOfWave(theWave)
	EndIf
	
	//What dimension to differentiate over?
	If(DimSize(theWave,0) > 0 && DimSize(theWave,1) > 0)
		If(DimSize(theWave,2) > 0)
			dim = 2
		Else
			Abort "Must be either a 1D or 3D wave"
		EndIf
	Else
		dim = 0
	EndIf
	
	//Make the output wave
	SetDataFolder GetWavesDataFolder(theWave,1)
	Duplicate/O theWave,$outWaveName
	Wave outWave = $outWaveName
	outWave = 0
	
	//Differentiate
	Differentiate/DIM=(dim) theWave/D=outWave
End

Function GetPkTimes()
	//Using a data set?
	ControlInfo/W=analysis_tools useDataSetCheck
	Variable useDS = V_Value

	If(useDS)
		String theWaveList = GetDSWaveList(separator=";")
	Else
		Abort "Only supports data set use for now"
	EndIf
	
	SetDataFolder GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	Variable i,j,k,rows,cols,startTm,endTm

	//Get range info
	ControlInfo/W=analysis_tools peakStVar
	startTm = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	endTm = V_Value
	
	For(i=0;i<ItemsInList(theWaveList,";");i+=1)
		//Get input wave
		Wave theWave = $StringFromList(i,theWaveList,";")
		If(DimSize(theWave,2) == 0)
			Abort "Only supports 3D waves for now"
		EndIf
		
		//Get Dimensions
		rows = DimSize(theWave,0)
		cols = DimSize(theWave,1)
		
		//Make output wave
		SetDataFolder GetWavesDataFolder(theWave,1)
		String outWaveName = NameOfWave(theWave) + "_pkTm"
		Make/O/N=(rows,cols) $outWaveName
		Wave pkTm = $outWaveName
		
		//Getting the peak ∆F/F and its time point from a beam 
			For(j=0;j<rows;j+=1)
				For(k=0;k<cols;k+=1)
					MatrixOP/FREE/O/S theBeam = Beam(theWave,j,k)
					SetScale/P x,DimOffset(theWave,2),DimDelta(theWave,2),theBeam
					WaveStats/Q/R=(startTm,endTm) theBeam
					If(V_avg == 0)
						pkTm[j][k] = NaN
					Else
						pkTm[j][k] = V_MaxLoc
					EndIf
				EndFor
			EndFor
		//Set scales
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),pkTm
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),pkTm
	EndFor	
	
End

//takes image, if there is a non-NaN value, it marks the coordinate in an x and y 1D wave
Function convertImage2xy(theImage)
	Wave theImage
	ImageStats/Q theImage
	SetDataFolder GetWavesDataFolder(theImage,1)
	 
	Make/N=(V_npnts)/O $(NameOfWave(theImage) + "_x"),$(NameOfWave(theImage) + "_y"),$(NameOfWave(theImage) + "_pktm")
	Wave xwave = $(NameOfWave(theImage) + "_x")
	Wave ywave = $(NameOfWave(theImage) + "_y")
	Wave pktm = $(NameOfWave(theImage) + "_pktm")
	
	Variable xDim,yDim,i,j,count
	
	xDim = DimSize(theImage,0)
	yDim = DimSize(theImage,1)
	count = 0
	For(i=0;i<xDim;i+=1)
		For(j=0;j<yDim;j+=1)
			If(numtype(theImage[i][j]) != 2)
				xwave[count] = IndexToScale(theImage,i,0)
				ywave[count] = IndexToScale(theImage,j,1)
				pktm[count] = theImage[i][j]//will be used as an f(z) color function
				count += 1
			EndIf
		EndFor
	EndFor

End


//Takes image, gets the median pixel value for that column and puts it into a new wave dimensioned for the # image rows
Function medianCol(theImage)
	Wave/Z theImage
	
	If(!WaveExists(theImage))
		Abort "The wave: " + NameOfWave(theImage) + " does not exist"
	EndIf
	
	If(DimSize(theImage,1) == 0 || DimSize(theImage,0) == 0)
		Abort "Must be an 2D wave"
	EndIf
	
	SetDataFolder GetWavesDataFolder(theImage,1)
	
	Variable rows,cols,i,j
	rows = DimSize(theImage,0)
	cols = DimSize(theImage,1)
	
	Make/O/N=(rows) $(NameOfWave(theImage) + "_medCol")
	Wave outWave = $(NameOfWave(theImage) + "_medCol")
	
	For(i=0;i<rows;i+=1)
		MatrixOP/FREE theCol = row(theImage,i)^t
		WaveTransform zapNaNs theCol
		outWave[i] = median(theCol)
	EndFor
End

Function avgROIs()
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	Variable i,j,numROIs,numScans
	numROIs = ItemsInList(ROIListStr,";")
	numScans = ItemsInList(scanListStr,";")
	
	//initial wave
	String theROIName = StringFromList(0,ROIListStr,";")
	String origScanName = StringFromList(0,scanListStr,";")
	String theWaveName = "root:ROI_analysis:ROI" + theROIName + ":" + origScanName + "_ch1_ROI" + theROIName + "_dF"
	Wave theWave = $theWaveName
	Variable size = DimSize(theWave,0)
	
	SetDataFolder GetWavesDataFolder(theWave,1)
	
	For(i=0;i<numROIs;i+=1)
		theROIName = StringFromList(i,ROIListStr,";")
		Make/O/N=(size) $("root:ROI_analysis:ROI" + theROIName + ":" + origScanName + "_ch1_ROI" + theROIName + "_dF_avg")
		Wave theAvg = $("root:ROI_analysis:ROI" + theROIName + ":" + origScanName + "_ch1_ROI" + theROIName + "_dF_avg")
		Note/K theAvg,"Averaged " + num2str(numScans) + " waves:"
		For(j=0;j<numScans;j+=1)
			String theScanName = StringFromList(j,scanListStr,";")
			theWaveName = "root:ROI_analysis:ROI" + theROIName + ":" + theScanName + "_ch1_ROI" + theROIName + "_dF"
			Wave theWave = $theWaveName
			theAvg += theWave	
			Note theAvg,theWaveName
		EndFor
		theAvg /= numScans
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),theAvg
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),theAvg
		
	EndFor
End

Function NormalizeWaves()
	Variable i
	String theWaveList = GetDSWaveList(separator=";")
	For(i=0;i<ItemsInList(theWaveList,";");i+=1)
		String theWaveName = StringFromList(i,theWaveList,";")
		Wave theWave = $theWaveName
		
		SetDataFolder GetWavesDataFolder(theWave,1)
	//	String outWaveName = NameOfWave(theWave) + "_Nrm"
	//	Make/O/N=(DimSize(theWave,0)) $outWaveName
		//Wave outWave = $outWaveName
		
		Variable maxVal = WaveMax(theWave)
		theWave = theWave/maxVal
				
	//	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	//	SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	EndFor
End



//Makes a custom color table with the specified dimensions
//Useful for truncating a color table so the start/end colors make more sense
Function MakeCustomColorTable(colorMap,startRow,endRow)
	String colorMap
	Variable startRow,endRow
	
	If(!DataFolderExists("root:CustomColors"))
		NewDataFolder root:CustomColors
	EndIf
	SetDataFolder root:CustomColors
	
	ColorTab2Wave $colorMap
	Wave customTable = M_Colors
	
	Variable size = DimSize(customTable,0)
	DeletePoints endRow+1,size-1,customTable
	DeletePoints 0,startRow,customTable
	
End

//input wave should be a dendritic mask.
Function distanceMatrix(theWave,startX,startY)
	Wave theWave
	Variable startX,startY
	Variable xOff,yOff
	Variable left,right,up,down,keepGoing,xStep,yStep,i,j,xPos,yPos,numPts,blockDir
	
	Make/FREE/N=1 buffer
	Make/O/N=100 xPlot,yPlot
	Wave xPlot = xPlot
	Wave yPlot = yPlot
	xPlot = 0
	yPlot = 0
	SetDataFolder GetWavesDataFolder(theWave,1)
	
	Make/O/N=4 count
	Wave count = count
	
	xPlot[0] = startX
	yPlot[0] = startY
	
	
	numPts = 0
	Do
		count = 0
		//Which direction are we testing?
		For(i=0;i<4;i+=1)
			switch(i)
				case 0:
					//right
					xStep = 1
					yStep = 0
					break
				case 1:
					//left
					xStep = -1
					yStep = 0
					break
				case 2:
					//down
					yStep = 1
					xStep = 0
					break
				case 3:
					//up
					yStep = -1
					xStep = 0
					break
			endswitch
			
			//reset for each direction
			xPos = startX
			yPos = startY	
			
			Do	
				xPos += xStep
				yPos += yStep		
				
				If(theWave[xPos][yPos] == 1)
					keepGoing = 1
					count[i] += 1
				Else
					keepGoing = 0
				EndIf
			While(keepGoing)
		EndFor
		
		numPts += 1
		keepGoing = 1
		
		//Prevent it from going back in the direction it just came from
		If(numPts > 1)
			count[blockDir] = 0
		EndIf
		
		//If in dead end
		If(count[0] + count[1] + count[2] + count[3] == 3)
			keepGoing = 0
		EndIf
		
		//Which direction gave the largest run?
		WaveStats/Q count

		If(round(V_maxLoc) == 0)
			blockDir = 1
			xPlot[numPts] = xPlot[numPts - 1] + count[0]
			yPlot[numPts] = yPlot[numPts - 1]
		ElseIf(round(V_maxLoc) == 1)
			blockDir = 0
			xPlot[numPts] = xPlot[numPts - 1] - count[1]
			yPlot[numPts] = yPlot[numPts - 1]
		ElseIf(round(V_maxLoc) == 2)
			blockDir = 3
			xPlot[numPts] = xPlot[numPts - 1]
			yPlot[numPts] = yPlot[numPts - 1] + count[2]
		ElseIf(round(V_maxLoc) == 3)
			blockDir = 2
			xPlot[numPts] = xPlot[numPts - 1]
			yPlot[numPts] = yPlot[numPts - 1] - count[3]	
		EndIf
		
		//Prevents running out of space in the plot waves
		If(numPts < 100)
			startX = xPlot[numPts]
			startY = yPlot[numPts]
		Else
			keepGoing = 0
		EndIf
		
	While(keepGoing)
	
	//clean up zeros and scale
	xPlot = (xPlot == 0) ? nan : xPlot
	yPlot = (yPlot == 0) ? nan : yPlot
	
	WaveTransform zapNaNs xPlot
	WaveTransform zapNaNs yPlot
	
	xPlot = IndexToScale(theWave,xPlot[p],0)
	yPlot = IndexToScale(theWave,yPlot[p],1)

End

Function clip()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable numScans = ItemsInList(scanListStr,";")
	Variable i,val
	val = 65000
	
	For(i=0;i<numScans;i+=1)
		Wave theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + StringFromList(i,scanListStr,";") + "_ch2")
		SetDataFolder GetWavesDataFolder(theWave,1)
		Variable avg = mean(theWave)
		theWave = (theWave[p][q][r] > val) ? avg : theWave[p][q][r]

	EndFor
End


Function getLineProfileDistance(xWave,yWave)
	Wave xWave,yWave
	Variable delta = xWave[1] - xWave[0]
	Variable size = DimSize(xWave,0)
	Variable i,distance
	
	distance = 0

	For(i=1;i<size;i+=1)
		If(yWave[i] != yWave[i-1])
			distance += sqrt(abs(yWave[i] - yWave[i-1])^2 + delta^2) //a^2 + b^2 = c^2
		Else
			distance += delta
		EndIf
	EndFor
	return distance
End

//Gets an x-scaling wave for the line profile
Function getLineProfileDistanceWave(xWave,yWave,theProfile,theImage)
	Wave xWave,yWave,theProfile,theImage
	Variable xDelta,yDelta,size,i,xD,yD
	String LPname,LDname
	
	If(!WaveExists(xWave) || !WaveExists(yWave) || !WaveExists(theProfile) || !WaveExists(theImage))
		Abort "Some of the waves don't exist."
	EndIf
	
	//dimensions
	xDelta = DimDelta(theImage,0)
	yDelta = DimDelta(theImage,1)
	size = DimSize(theProfile,0)
	
	//line distance wave name
	LPname = NameOfWave(theProfile)
	If(StringMatch(LPname,"*LP"))
		LDname = ReplaceString("LP",LPname,"LD")
	Else
		LDname = LPname + "_LD"
	EndIf
	
	SetDataFolder GetWavesDataFolder(theProfile,1)
	
	Make/O/N=(size) $LDname
	Wave LD = $LDname
	
	LD[0] = 0
	
	For(i=1;i<size;i+=1)
		//Get distance from each x/y data point to the next
		xD = abs(xWave[i] - xWave[i-1]) * 5
		yD = abs(yWave[i] - yWave[i-1]) * 5
		
		//calculate the point to point distance
		LD[i] = sqrt(xD^2 + yD^2) + LD[i-1]
	EndFor
	
End

//takes 2D matrix and concatenates the rows together
Function concatenate2D(theWave,outWave)
	wave theWave,outWave
	
	If(DimSize(theWave,1) == 0)
		Abort "Must use 2D wave"
	EndIf
	Variable size = DimSize(theWave,0)
	Variable cols = DimSize(theWave,1)
	Variable i,currentSize
	
	For(i=0;i<cols;i+=1)
		If(i==0)
			Redimension/N=(size) outWave
			outWave[0,size-1] = theWave[p][i]
		Else
			currentSize = DimSize(outWave,0)
			Redimension/N=(currentSize + size) outWave
			outWave[currentSize,currentSize+size-1] = theWave[p-currentSize][i]
		EndIf
		
	EndFor	
End

Function trimCMatrix(dMatrix,cMatrix)
	Wave dMatrix,cMatrix
	
	Variable rows = DimSize(dMatrix,0)
	Variable i
	For(i=0;i<rows;i+=1)
		If(dMatrix[i] == 0)
			dMatrix[i] = nan
			cMatrix[i] = nan
		EndIf
	EndFor
	WaveTransform zapNaNs dMatrix
	WaveTransform zapNaNs cMatrix
	
End



//Takes an ROI table and eliminates columns and rows from the DMatrix wave that aren't in the filter table
//roiTable is the full length table with all the ROIs
Function filterDMatrix(filterTable,roiTable,dMatrix)
	Wave/T filterTable,roiTable
	Wave dMatrix
	Variable size = DimSize(roiTable,0)
	Variable filterSize = DimSize(filterTable,0)
	Variable i,index,isPresent
	String filterList = ""
	String ROIList = ""
	String theROI
	
	//Get the ROI lists
	For(i=0;i<filterSize;i+=1)
		filterList += filterTable[i] + ";"
	EndFor
	
	For(i=0;i<size;i+=1)
		ROIList += roiTable[i] + ";"
	EndFor
	
	For(i=0;i<size;i+=1)
		theROI = StringFromList(i,ROIList,";")
		isPresent = WhichListItem(theROI,filterList,";")
		
		If(isPresent == -1)
			index = WhichListItem(theROI,ROIList,";")
			dMatrix[index][] = 0
			dMatrix[][index] = 0
		EndIf
	EndFor
End


Function GR_map(ch1,ch2,startTm,endTm)
	Wave ch1,ch2
	Variable startTm,endTm
	Variable startR,endR,size
	String name,outWaveName
	Variable rows,cols,frames
	
	rows = DimSize(ch1,0)
	cols = DimSize(ch1,1)
	frames =DimSize(ch1,2)
	
	startR = ScaleToIndex(ch1,startTm,2)
	endR = ScaleToIndex(ch1,endTm,2)
	size = endR - startR + 1
	
	name = NameOfWave(ch1)
	outWaveName = ReplaceString("ch1",name,"GR") 
	
	SetDataFolder GetWavesDataFolder(ch1,1)
	
	Make/FREE/N=(rows,cols,size) green
	
	//Get average green map over the peak area
	green = ch1[p][q][r+startR]
	MatrixOP/FREE greenAvg = sumBeams(green)/size
	MatrixFilter/N=3 median greenAvg
	
	//Get average red map over the entire scan
	MatrixOP/FREE redAvg = sumBeams(ch2)/frames
	MatrixFilter/N=3 median redAvg
	
	//Get the ratio map
	Make/O/N=(rows,cols) $outWaveName
	Wave GR = $outWaveName
	
	GR = greenAvg/redAvg	
End

Function Normalize3D(theWave)
	Wave theWave
	Variable i,j,k,numFrames,rows,cols,maxVal
	
	numFrames = DimSize(theWave,2)
	rows = DimSize(theWave,0)
	cols = DimSize(theWave,1)
	
	For(i=0;i<rows;i+=1)
		For(j=0;j<cols;j+=1)
			MatrixOP/FREE theBeam = beam(theWave,i,j)
			maxVal = WaveMax(theBeam)
			theBeam /= maxVal
			theWave[i][j][] = theBeam[r]
		EndFor
	EndFor

End



//averages the selected waves
Function AverageWaves()
	Variable numWaves,i
	
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	If(numWaves == 0)
		print "No waves were processed"
		return 0
	EndIf
	
	String cdf = GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	ControlInfo/W=analysis_tools outFolder
	String outFolder = S_Value
	
	//Parent data folder must already exist to use the output folder option
	outFolder = RemoveEnding(outFolder,":")
	Variable isRoot = (cmpstr(StringFromList(0,outFolder,":"),"root") == 0) ? 1 : 0
	
	//If it isn't a full path, add the output folder to the current data folder
	If(!isRoot)
		outFolder = RemoveEnding(cdf + outFolder,":")
	EndIf
	
	If(!DataFolderExists(outFolder))
		NewDataFolder $outFolder
	EndIf
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder cdf
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";")
	String outWaveName = outFolder + ":" + NameOfWave(theWave) + "_avg"
	
	Variable dims = WaveDims(theWave)
	
	switch(dims)
		case 1:
			Make/O/N=(DimSize(theWave,0)) $outWaveName
			break
		case 2:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1)) $outWaveName
			break
		case 3:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1),DimSize(theWave,2)) $outWaveName
			break
	endswitch
	
	Wave outWave = $outWaveName 
	outWave = 0
	
	Note/K outWave,num2str(numWaves) + " waves averaged:"
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		outWave += theWave
		Note outWave,GetWavesDataFolder(theWave,2)
	EndFor
	outWave /= numWaves
	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),outWave
	
	outputDS(outWave)
End

//error (SEM) the selected waves
Function ErrorWaves()
	
	ControlInfo/W=analysis_tools errType
	String error = S_Value
	
	Variable numWaves,i

	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	If(numWaves == 0)
		print "No waves were processed"
		return 0
	EndIf
	
	String cdf = GetWavesDataFolder($StringFromList(0,theWaveList,";"),1)
	
	ControlInfo/W=analysis_tools outFolder
	String outFolder = S_Value
	
	//Parent data folder must already exist to use the output folder option
	outFolder = RemoveEnding(outFolder,":")
	Variable isRoot = (cmpstr(StringFromList(0,outFolder,":"),"root") == 0) ? 1 : 0
	
	//If it isn't a full path, add the output folder to the current data folder
	If(!isRoot)
		outFolder = RemoveEnding(cdf + outFolder,":")
	EndIf
	
	If(!DataFolderExists(outFolder))
		NewDataFolder $outFolder
	EndIf
	
	//Set data folder to that of the first wave on the wavelist
	SetDataFolder cdf
	
	//Make output wave
	Wave theWave = $StringFromList(0,theWaveList,";")
	
	String outWaveName = outFolder + ":" + NameOfWave(theWave) + "_" + error
	
	Variable dims = WaveDims(theWave)
	
	switch(dims)
		case 1:
			Make/O/N=(DimSize(theWave,0)) $outWaveName
			break
		case 2:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1)) $outWaveName
			break
		case 3:
			Make/O/N=(DimSize(theWave,0),DimSize(theWave,1),DimSize(theWave,2)) $outWaveName
			break
	endswitch
	
	Wave outWave = $outWaveName 
	outWave = 0
	
	//Compute average first
	Make/FREE/N=(DimSize(outWave,0)) tempAvg = 0
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,theWaveList,";")
		tempAvg += theWave
	EndFor
	tempAvg /= numWaves
	SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),outWave
	
	//SEM calculation
	strswitch(error)
		case "SEM":
			Note/K outWave,num2str(numWaves) + " SEM waves included:"

			For(i=0;i<numWaves;i+=1)
				Wave theWave = $StringFromList(i,theWaveList,";")
				outWave += (theWave - tempAvg)^2
				Note outWave,GetWavesDataFolder(theWave,2)
			EndFor
			outWave = (sqrt(outWave / (numWaves -1)))/sqrt(numWaves)
			break
		case "SDEV":
			Note/K outWave,num2str(numWaves) + " SDEV waves included:"
			For(i=0;i<numWaves;i+=1)
				Wave theWave = $StringFromList(i,theWaveList,";")
				outWave += (theWave - tempAvg)^2
				Note outWave,GetWavesDataFolder(theWave,2)
			EndFor
			outWave = sqrt(outWave / (numWaves -1))
			break
	endswitch
		
	outputDS(outWave)
	
End

//Kill all the waves in the data set
Function AT_KillWaves()
	//Finds the wave paths for analysis
	String theWaveList = getWaveNames()
	Variable numWaves = ItemsInList(theWaveList,";")
	Variable i
	String df = GetDataFolder(1)
	
	For(i=0;i<numWaves;i+=1)
		Wave/Z theWave = $StringFromList(i,theWaveList,";")
		If(!WaveExists(theWave))
			Wave/Z/T theTextWave = $StringFromList(i,theWaveList,";")
			If(!WaveExists(theTextWave))
				continue
			Else
				SetDataFolder GetWavesDataFolder(theWave,1)
				KillWaves/Z theTextWave
			EndIf
		Else
			SetDataFolder GetWavesDataFolder(theWave,1)
			KillWaves/Z theWave
		EndIf
	EndFor
	
	SetDataFolder $df
End

Function FlattenWave(inputWave)
	wave inputWave
	
//	Make/N=(DimSize(inputWave,0)) fitWave
	SetDataFolder GetWavesDataFolder(inputWave,1)
	Make/O/D/N=0 coefs
	Duplicate/O inputWave,filtered
	FilterFIR/DIM=0/HI={0.006,0.01,101}/COEF coefs, filtered
	Wave filterWave = filtered
	inputWave = filterWave
//	CurveFit/Q/M=2/W=0 poly_XOffset 10,inputWave/D=fitWave 	
	//inputWave -= fitWave
//	Note inputWave,"Trend Fitted"
	//KillWaves fitWave
	
	KillWaves filterWave
End

Function LoadStimulusData()
	
	Variable refnum
	String message = "Select the stimulus file to load"
	String fileFilters = "All Files:.*;"
	Open/D/R/F=fileFilters/M=message refnum
	String filePath = S_fileName
	Close/A
	
	String tableName = ParseFilePath(0,filePath,":",1,0)
	tableName = RemoveEnding(tableName,".txt")
	
	String line = ""
	Make/O/T/N=(1,2,1) $tableName
	Wave/T table = $tableName
	
	Open/Z=2/R/T="????" refNum as filePath
	Variable row=0,col=0,depth=0,i,numItems
	String numObjects = ""
	
	Variable objectNum,objectCount = 1
	
	//How many lines are in this file?
	
	
	Do
		FReadLine refNum, line
		
		If(!strlen(line))
			break
		EndIf
		
		line = RemoveEnding(line,"\r")
		If(!strlen(line))
			continue
		EndIf
		
		//Add another row if needed
		If(row > DimSize(table,0) - 1)
			Redimension/N=(DimSize(table,0)+1,-1,-1) table
		EndIf
			
		If(stringmatch(line,"*ID:*"))
			depth += 1
			row = 0
			Redimension/N=(-1,-1,depth) table
			
			table[row][0][depth-1] = "ID"
			table[row][1][depth-1] = StringByKey("ID",line,":")
			
		ElseIf(stringmatch(line,"*Stimulus*"))
		 	table[row][0][depth-1] = "Stimulus:"
			table[row][1][depth-1] = StringByKey("Stimulus",line,":")
		Else
			numItems = ItemsInList(line,"\t")	
			Redimension/N=(-1,numItems,-1) table
			
			For(i=0;i<numItems;i+=1)
				String theItem = StringFromList(i,line,"\t")
				table[row][i][depth-1] = theItem
			EndFor
		EndIf
		
		row += 1
	While(strlen(line))
	
	Close refnum
		
	//Sort the table by object number
	Variable rows,cols,frames,index,j,k,count = 0
	rows = DimSize(table,0)
	cols = DimSize(table,1)
	frames = DimSize(table,2)
	
	Make/FREE/T/N=(rows,cols) temp
	
	For(i=0;i<frames;i+=1)
		count = 0
		temp = table[p][q][i]
		
		//Get number of objects for this stimus
		index = tableMatch("numObjects",table,returnCol=1)
		If(index == -1)
			return -1
		EndIf
		numObjects = table[3][index][i]
		
		index = tableMatch("objectNum",table,returnCol=1)
		
		If(index == -1)
			return -1
		EndIf
		
		//Loop through all the objects
		For(k=1;k<str2num(numObjects)+1;k+=1)
			//Loop through each row for each sequential object
			For(j=3;j<rows;j+=1)//row 3 starts the stimulus data
				If(!cmpstr(table[j][index][i],num2str(k)))
					//If its the correct object number put it in the correct row of the temp table
					temp[count + 3][] = table[j][q][i]
					count += 1
				ElseIf(!strlen(table[j][index][i]))
					break
				EndIf
			EndFor
		EndFor
		table[][][i] = temp[p][q][0]
	EndFor

End

Function duplicateRename()

	Variable numWaves,i,j,pos,numAddItems
	String theWaveList,name,newName,posList,ctrlList,addItem
	
	posList = "0;1;2;3;4"
	ctrlList = "prefixName;groupName;seriesName;sweepName;traceName"
	
	ControlInfo/W=analysis_tools killOriginals
	Variable killOriginals = V_Value
	
	//Finds the wave paths for analysis
	theWaveList = getWaveNames()
	numWaves = ItemsInList(theWaveList,";")
	
	For(i=0;i<numWaves;i+=1) //for # waves in the waveset
		Wave/Z theWave = $StringFromList(i,theWaveList,";")
		If(!WaveExists(theWave))
			continue
		EndIf	
		
		SetDataFolder GetWavesDataFolder(theWave,1)
		name = NameOfWave(theWave)
		newName = name
		
		For(j=4;j>-1;j-=1)	//step backwards
			//new name and the position
			ControlInfo/W=analysis_tools $StringFromList(j,ctrlList,";")
			S_Value = resolveListItems(S_value,",")
			S_Value = RemoveEnding(S_Value,",")
			
			numAddItems = ItemsInList(S_Value,",")
			pos = str2num(StringFromList(j,posList,";"))
			
			If(strlen(S_Value))
				If(!cmpstr(S_Value,"-"))
					newName = RemoveListItem(pos,newName,"_")
				Else
					newName = RemoveListItem(pos,newName,"_")
					If(i > numAddItems - 1)
						addItem = StringFromList(numAddItems - 1,S_Value,",")
					Else
						addItem = StringFromList(i,S_Value,",")
					EndIf
					newName = AddListItem(addItem,newName,"_",pos)
					newName = RemoveEnding(newName,"_")
				EndIf
			EndIf
			
		EndFor
		
		//If no changes in name were made, make the name unique with extra 0,1,2... at the end
		If(!cmpstr(name,newName))
			newName = UniqueName(newName,1,0)
		EndIf
		
		Duplicate/O theWave,$newName
		
		If(killOriginals)
			ReallyKillWaves(theWave)
		EndIf
	EndFor

End

//Export single dimension waves into CSV format
//Executes a denoising algorithm via Python code
Function/S exportWaves()
	
	//Finds the wave paths for analysis
	String list = getWaveNames(ignoreWaveGrouping=1)
		
	//Overwrite?
	ControlInfo/W=analysis_tools overwriteCheck
	Variable overwrite = V_Value
	
	//Output subfolder?
	ControlInfo/W=analysis_tools outputFolder
	String outFolder = S_Value	
	
	//Path to python script
	ControlInfo/W=analysis_tools scriptFolder
	String scriptFolder = S_Value
	
	//Path to data folder that will hold the exported and denoised data
	ControlInfo/W=analysis_tools denoiseDataFolder
	String denoiseDataFolder = S_Value
	
	String fileName,errStr = ""
	Variable xSize,ySize,zSize,i
	
	String separator = ";"
	
	//How many waves are being exported?
	Variable numWaves = ItemsInList(list,separator)
	
	Wave theWave = $StringFromList(0,list,separator)
	If(!WaveExists(theWave))
		errStr = "Couldn't find the wave: " + NameOfWave(theWave)
		return errStr
	EndIf
	
	//Dimensions?
	Variable dims = WaveDims(theWave)
	xSize = DimSize(theWave,0)
	ySize = DimSize(theWave,1)
	zSize = DimSize(theWave,2)
	
	//Make the output table for making the csv
	If(dims == 3)
		Make/O/N=(zSize,xSize*ySize) root:data
	Else
		Make/O/N=(xSize,numWaves) root:data
	EndIf

	Wave data = root:data
	Variable j
	
	//Fill out the table. Each column is a different wave
	If(dims == 3)
		//single of 3D wave for denoising (image time series)
		Wave theWave = $StringFromList(0,list,separator) //only uses the first wave for now
		
		//Error handling
		If(!WaveExists(theWave))
			errStr = "Couldn't find the wave: " + NameOfWave(theWave)
			print errStr
			return errStr
		EndIf
		
		Variable col
		col = 0
		
		For(i=0;i<xSize;i+=1)
			For(j=0;j<ySize;j+=1)
				MatrixOP/O/FREE theBeam = beam(theWave,i,j)
				MultiThread data[][col] = theBeam[p]
				col += 1
			EndFor
		EndFor

	Else
		//series of 1D waves for denoising
		For(i=0;i<numWaves;i+=1)
			Wave theWave = $StringFromList(i,list,separator)
			
			//Error handling
			If(!WaveExists(theWave))
				errStr = "Couldn't find the wave: " + NameOfWave(theWave)
				print errStr
				return errStr
			EndIf
			
			data[][i] = theWave[p][0]
		EndFor
	EndIf

	
	//Show the table
	Edit/N=denoiseData data as "denoiseData"
	
	//Path to folder
	NewPath/O/Q folderPath,denoiseDataFolder
	
	//Filename
	fileName = "denoiseData.csv"
	
	//Export table to CSV
	SaveTableCopy/O/P=folderPath/T=2/W=denoiseData as fileName
	
	//Cleanup
	KillWindow/Z denoiseData
	KillWaves/Z data
		
	String os = IgorInfo(2)
	
	strswitch(os)
		case "Windows":
			//write BAT file for windows python script - denoising code
			String scriptPath = writeBAT(scriptFolder)
			
			If(strlen(errStr))
				print errStr
			Else
				importWaves(list,outFolder,overwrite)
			EndIf
			
			ExecuteScriptText scriptPath
		
			//must manually execute python code through anaconda terminal
			//DoAlert/T="Denoising" 1,"Run Python Script"
			//If(V_flag == 1)
			//	print errStr
		//	Else
			//	importWaves(list,outFolder,overwrite)
			//EndIf
			break
		case "Macintosh":
			//Uses applescript to run the python code through anaconda terminal
			String script = "activate application \"Terminal\"\r"
			script += "tell application \"System Events\" to keystroke \"conda activate base\"\r"
			script += "tell application \"System Events\" to keystroke return\r"
			script += "delay 0.1\r"
			script += "tell application \"System Events\" to keystroke \"cd " + scriptFolder + "\"\r"
			script += "tell application \"System Events\" to keystroke return\r"
			script += "delay 0.1\r"
			script += "tell application \"System Events\" to keystroke \"python denoise.py\"\r"
			script += "tell application \"System Events\" to keystroke return"
	
			ExecuteScriptText script
			
			//Wait for python to finish, then proceed
			DoAlert 0,"Wait for Python to finish, then click OK"
			
			errStr = S_Value
			
			If(strlen(errStr))
				print errStr
			Else
			   errStr = importWaves(list,outFolder,overwrite)
				print errStr
			EndIf
		break
	endswitch

End

//Imports waves that were operated on by Python script for denoising Ca signals
Function/S importWaves(list,outFolder,overwrite)
	String list,outFolder
	Variable overwrite
	Variable i,j,offset,delta
	String errStr = ""
	
	//Path to folder was created in exportWaves function
	//path = denoiseDataFolder
		
	//Set Data Folder to that of the first wave
	SetDataFolder GetWavesDataFolder($StringFromList(0,list,";"),1)
	DFREF saveDF = GetDataFolderDFR()
	
	Wave oldWave = $StringFromList(0,list,";")
	
	//Error handling
	If(!WaveExists(oldWave))
		errStr = "Couldn't find the wave: " + NameOfWave(oldWave)
		return errStr
	EndIf
	
	//Dimensions?
	Variable dims = WaveDims(oldWave)
	Variable xSize,ySize,zSize
	xSize = DimSize(oldWave,0)
	ySize = DimSize(oldWave,1)
	zSize = DimSize(oldWave,2)
	
	//Load waves
	If(dims == 3)
		//load as a matrix if it was a scan
		LoadWave/Q/P=folderPath/J/M/U={0,0,1,0} "denoiseData.csv"   
		
		//Denoised wave that was loaded
		SetDataFolder saveDF
		Wave newWave = $("wave0")
		
		//source data folder
		String df = GetWavesDataFolder(oldWave,1)
		
		//Error handling
		If(!WaveExists(newWave))
			errStr = "Couldn't find the wave: " + NameOfWave(newWave)
			return errStr
		EndIf
		
		//Make output data folder if there is one indicated and it doesn't exist
		If(!strlen(outFolder))
			SetDataFolder $df
		Else
			If(!DataFolderExists(df + outFolder))
				NewDataFolder $(df + outFolder)
			EndIf
			SetDataFolder $(df + outFolder)
		EndIf
		
		//make output 2D wave
		
		If(overwrite)
			Make/O/N=(xSize,ySize,zSize) $NameOfWave(oldWave)
			Wave outWave = $NameOfWave(oldWave)
			MultiThread outWave = 0
		Else
			Make/O/N=(xSize,ySize,zSize) $(NameOfWave(oldWave) + "_denoise")
			Wave outWave = $(NameOfWave(oldWave) + "_denoise")
			MultiThread outWave = 0
		EndIf
		
		//Reorganize the rows/cols/frames into the new wave
		Variable col = 0
		Variable count = 0
				
		For(i=0;i<DimSize(outWave,0);i+=1)
			For(j=0;j<DimSize(outWave,1);j+=1)
				col = count * ySize + j
				outWave[i][j][] = newWave[r][col]
			EndFor
			count += 1
		EndFor
		KillWaves/Z newWave
	Else
		LoadWave/Q/P=folderPath/J/A "denoiseData.csv"   
	
		For(i=0;i<ItemsInList(list,";");i+=1)
			//Original wave and folder
			Wave oldWave = $StringFromList(i,list,";")
			df = GetWavesDataFolder(oldWave,1)
			
			//Error handling
			If(!WaveExists(oldWave))
				errStr = "Couldn't find the wave: " + NameOfWave(oldWave)
				return errStr
			EndIf
			
			
			
			//Scaling details
			offset = DimOffset(oldWave,0)
			delta = DimDelta(oldWave,0)
			
			//Denoised wave that was loaded
			SetDataFolder saveDF
			Wave newWave = $("wave" + num2str(i))
			
			//Error handling
			If(!WaveExists(newWave))
				errStr = "Couldn't find the wave: " + NameOfWave(newWave)
				return errStr
			EndIf
			
			//Make output data folder if there is one indicated and it doesn't exist
			If(!strlen(outFolder))
				SetDataFolder $df
			Else
				If(!DataFolderExists(df + outFolder))
					NewDataFolder $(df + outFolder)
				EndIf
				SetDataFolder $(df + outFolder)
			EndIf
			
			//Rename/overwrite
			String newName = StringFromList(i,list,";")
			
			If(overwrite)
				Duplicate/O newWave,$NameOfWave(oldWave)
				Wave outWave = $NameOfWave(oldWave)
				DeletePoints 0,1,outWave
			Else
				Duplicate/O newWave,$(NameOfWave(oldWave) + "_denoise")
				Wave outWave = $(NameOfWave(oldWave) + "_denoise")
				DeletePoints 0,1,outWave
			EndIf
			
			//Scales,wave notes,cleanup
			SetScale/P x,offset,delta,outWave
			Note outWave,"Denoised"
			KillWaves/Z newWave
		EndFor
	EndIf
	
	return errStr
End

//Writes a .bat file to disk on Windows systems
//File contains a python script for executing a denoising algorithm
Function/S writeBAT(scriptFolder)
	String scriptFolder
	String errStr = ""
	Variable refNum
	String/G root:Packages:analysisTools:batStr
	SVAR batStr = root:Packages:analysisTools:batStr
	
	String scriptPath = scriptFolder + "\denoiseScript.bat"
	
	//contents of the BAT file
	batStr = "CLS\r"
	batStr += "call \"" + scriptFolder + "\activate.bat\"\r"
	batStr += "python denoise.py\r"
	batStr += "CLS"
	
	//Path was created in exportWaves function
	Open/Z/P=folderPath refnum as "denoiseScript.bat"
	
	If(V_flag > 0)
		errStr = "Couldn't open the file: " + scriptFolder + "\denoiseScript.bat"
		return ""
	Else
		FBinWrite refnum,batStr
		Close refnum
	EndIf
	
	return scriptPath
End

//max projection on input wave (must be 3D)
Function atMaxProj()
	//Finds the wave paths for analysis
	String list = getWaveNames(ignoreWaveGrouping=1)
	Variable i,j,size,xSize,ySize,frames
	
	size=ItemsInList(list,";")
	
	For(i=0;i<size;i+=1)
		Wave theWave = $StringFromList(i,list,";")
		
		If(!WaveExists(theWave))
			print "Couldn't find the wave: " + NameOfWave(theWave)
			continue
		EndIf
		
		SetDataFolder GetWavesDataFolder(theWave,1)
		
		//dimensions
		xSize = DimSize(theWave,0)
		ySize = DimSize(theWave,1)
		frames = DimSize(theWave,2)
		
		If(frames == 0)
			print "Wave must be 3D (" + NameOfWave(theWave) + ")"
			continue
		EndIf
		
		//output wave
		String outName = NameOfWave(theWave) + "_mproj"
		Make/O/N=(xSize,ySize) $outName
		Wave outWave = $outName
		
		//set outWave to first frame of the input wave
		outWave = theWave[p][q][0]
		
		//max project
		For(j=0;j<frames;j+=1)
			outwave = (theWave[p][q][j] > outWave[p][q]) ? theWave[p][q][j] : outWave[p][q]
		EndFor
		
		//Set scales
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	EndFor
End

//Applies a threshold value to a 2D or 3D wave
Function mapThresh()
	
	String list = getWaveNames(ignoreWaveGrouping=1)
	Variable size,i,j,k,xSize,ySize,zSize,threshold
	
	ControlInfo/W=analysis_tools mapThreshold
	threshold = V_Value
	
	size=ItemsInList(list,";")
	
	Variable timer = StartMSTimer
	
	For(i=0;i<size;i+=1)
		//get the wave
		Wave theWave = $StringFromList(i,list,";")
		If(!WaveExists(theWave))
			print "Couldn't find the wave: " + NameOfWave(theWave)
			continue
		EndIf
		
		//wave dimensions
		xSize = DimSize(theWave,0)
		ySize = DimSize(theWave,1)
		zSize = DimSize(theWave,2)
	
		SetDataFolder GetWavesDataFolder(theWave,1)
		
		//output wave
		String outName = NameOfWave(theWave) + "_thr"
		Make/O/N=(xSize,ySize,zSize) $outName
		Wave outWave = $outName
		
		//set scales
		matchScale(outWave,theWave)
		
		//so we at least register a single layer, which is always true
		If(zSize == 0)
			zSize = 1
		EndIf
		
		//apply threshold
		For(k=0;k<zSize;k+=1)
			MultiThread outWave[][][k] = (theWave[p][q][k] < threshold) ? 0 : theWave[p][q][k]
		EndFor
		
	EndFor
	
	Variable dur = StopMSTimer(timer) / (1e6)
	print "Applied threshold (" + num2str(threshold) + ") to " + NameOfWave(theWave) + "..." + num2str(dur) + " s"
End

//Opens a dynamic ROI window to use on any 3D scan instead of just designated scans (2PLSM)
Function doDynamicROI()
	
	//Get the waves
	String waveNameList = getWaveNames()
	
	//Only use the first wave in the list if multiple waves are specified
	Wave theImage = $StringFromList(0,waveNameList)
	If(!WaveExists(theImage))
		return -1
	EndIf
	
	//Make a free max projection of the wave for viewing purposes
	//set outWave to first frame of the input wave
	Make/O/N=(DimSize(theImage,0),DimSize(theImage,1)) root:Packages:analysisTools:maxProj
	Wave maxProj = root:Packages:analysisTools:maxProj
	maxProj = theImage[p][q][0]
	
	//max projection
	Variable j,frames = DimSize(theImage,2)
	For(j=0;j<frames;j+=1)
		//MultiThread maxProj = (theImage[p][q][j] > maxProj[p][q]) ? theImage[p][q][j] : maxProj[p][q]
		MultiThread maxProj += theImage[p][q][j]
	EndFor
	
	If(frames > 0)
		maxProj /= frames
	EndIf
	
//	SetScale/P x,DimOffset(theImage,0),DimDelta(theImage,0),maxProj
//	SetScale/P y,DimOffset(theImage,1),DimDelta(theImage,1),maxProj
//	SetScale/P z,DimOffset(theImage,2),DimDelta(theImage,2),maxProj
		
	//Set note in maxProj to reference the original 3D wave
	Note/K maxProj,NameOfWave(theImage)
	
	//Get dynamic ROI wave
	If(!WaveExists(root:Packages:analysisTools:dynamicROIWave))
		Make/O root:Packages:analysisTools:dynamicROIWave
	EndIf
	
	Wave dROI = root:Packages:analysisTools:dynamicROIWave
	
	//Display dynamic ROI wave outside of top right corner of analysis toolbox
	DoWindow dynamicROI
	If(!V_flag)
		GetWindow/Z analysis_tools wsize
		Display/K=1/W=(V_right,V_top,V_right + 360,V_top + 200)/N=dynamicROI dROI as "Dynamic ROI"	
	EndIf
	
	//Display max projection
	Display/K=1/W=(V_right,V_top+220,V_right + 720,V_top + 520)/N=maxProjection
	AppendImage/W=maxProjection maxProj
	
	//Set the window hook function
	SetWindow maxProjection,hook(droiHook) = dROI_Hook

End


//Projects data onto PCA eigenvectors using dot product
Function projectPCA(eigen,dataMatrix)
	Wave eigen//multidimensional wave holding eigenvalues from PCA
	Wave dataMatrix//matrix data of input parameter waves, i.e. the raw data used for PCA
	
	Variable numWaves = DimSize(dataMatrix,1)
	Variable i,j
	
	Make/O/N=(numWaves) c00,c10 //projection coordinates for each data sample
	Wave c00 = c00
	Wave c10 = c10
	
	Make/FREE/N=(DimSize(dataMatrix,0)) theWave
	
	For(i=0;i<numWaves;i+=1)
		theWave = dataMatrix[p][i] //extract each parameter wave from the data matrix
		
		//extract the eigenvectors for the first two PCA components
		Make/FREE/N=(DimSize(theWave,0)) eigen1,eigen2 
		eigen1 = eigen[p][0]
		eigen2 = eigen[p][1]
		
		//standardize the waves
		MatrixOP/O $(NameOfWave(theWave) + "_std") = normalize(subtractMean(theWave,1))
		Wave stdWave = $(NameOfWave(theWave) + "_std")
		
		//dot product of eigenvector with the parameter wave, i.e. raw data used for PCA
		//this outputs the x/y coordinates of each wave projected onto the first two PCA components
		MatrixOP/FREE coordinate = eigen1.stdWave
		c00[i] = coordinate[0]
		MatrixOP/FREE coordinate = eigen2.stdWave
		c10[i] = coordinate[0]
	EndFor
End

Function matrixSort(matrix,key)
	Wave matrix,key //key is 1D wave that is used to sort the matrix with
	Variable i
	
	Wave/T roiTable = root:roiTable
	
	If(DimSize(roiTable,0) != DimSize(matrix,0))
		Abort "ROI table must have same number of points as the square matrix X and Y dimensions"
	EndIf
	
	For(i=0;i<DimSize(matrix,0);i+=1)
		SetDimLabel 0,i,$roiTable[i],matrix
		SetDimLabel 1,i,$roiTable[i],matrix
	EndFor
	
	Duplicate/O matrix,$(NameOfWave(matrix) + "_sort")
	Wave sorted = $(NameOfWave(matrix) + "_sort")
	sorted = 0
	
	//Sort the matrix according to the key
	Duplicate /O key Sorting_Index; Sorting_Index=p
   Sort key,Sorting_Index // Create a sorting index to use to swap out rows (and columns).  
   sorted = matrix[Sorting_Index[p]][Sorting_Index[q]] // Shuffle rows (and columns).  
	
	
	//duplicate the ROI table to make a sorted version
	Duplicate/T/O roiTable,roiTable_sort
	Wave/T roiTable_sort = roiTable_sort
	roiTable_sort = roiTable[Sorting_Index[p]]
	//make wave for the location of the sorted roiTable, which is just linear
	Make/O/N=(DimSize(roiTable_sort,0)) roiTable_sort_loc = x
	
	For(i=0;i<DimSize(matrix,0);i+=1)
		SetDimLabel 0,i,$roiTable[Sorting_Index[i]],sorted
		SetDimLabel 1,i,$roiTable[Sorting_Index[i]],sorted
	EndFor
End

//extracts a column/row from the correlation matrix, and organizes it by largest to smallest correlation
//output is roi_extract, which has the name of the ROIs and their correlation values, all sorted.
Function getROI_Corr(matrix,roiTable,theRow)
	Wave matrix//sorted correlation matrix
	Wave/T roiTable//sorted ROI table to match the sorted matrix
	Variable theRow//row/col to extract and sort by the max
	
	SetDataFolder GetWavesDataFolder(matrix,1)
	
	Make/O/N=(DimSize(matrix,0),2)/T roi_extract
	Wave/T roi_extract
	
	roi_extract[][1] = num2str(matrix[p][theRow])
	roi_extract[][0] = roiTable[p]
	
	Make/FREE/N=(DimSize(matrix,0)) sortKey = str2num(roi_extract[p][1])
	SortColumns/R keyWaves={sortKey},sortWaves={roi_extract}

End

//input is a correlation matrix.
//sorts each column in the matrix from highest to lowest correlation
//makes a mirrored matrix that has the corresponding ROI names
Function sortCorrMatrix(matrix,roiTable)
	Wave matrix //correlation matrix
	Wave/T roiTable //contains sorted list of ROIs that correspond to the indices of the matrix
	Variable col,row,i,j 
	
	col = DimSize(matrix,1)
	row = DimSize(matrix,0)
	
	//make output waves
	SetDataFolder GetWavesDataFolder(matrix,1)
	String outMatrixName = NameOfWave(matrix) + "_Hi2Low"
	String ROIMatrixName = NameOfWave(matrix) + "_Hi2Low_ROIs"
	Make/O/N=(row,col) $outMatrixName
	Make/O/T/N=(row,col) $ROIMatrixName
	
	Wave outMatrix = $outMatrixName
	Wave/T roiMatrix = $ROIMatrixName
	
	//will hold the column data
	Make/FREE/N=(row) tempData
	Make/T/FREE/N=(row) tempROI
	
	//sort each column of the matrix and put in output matrices
	For(i=0;i<col;i+=1)
		tempROI = roiTable
		tempData = matrix[p][i]
		
		Sort/R tempData,tempROI//sort ROI names
		Sort/R tempData,tempData//sort correlation values
		
		//fill the matrices
		roiMatrix[][i] = tempROI[p]
		outMatrix[][i] = tempData[p]
	EndFor
	
End

//inputs spike recording, outputs histograms
Function PSTH()
	ControlInfo/W=analysis_tools binSize
	Variable binSize = V_Value
	ControlInfo/W=analysis_tools spkThreshold
	Variable threshold = V_Value
	ControlInfo/W=analysis_tools histType
	String type = S_Value
	
	Variable i,j,numWaves,numBins
	
	//Get the waves
	String waveNameList = getWaveNames()
	numWaves = ItemsInList(waveNameList,";")
	
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,waveNameList,";")
		SetDataFolder GetWavesDataFolder(theWave,1)
		
		//get spike times
		FindLevels/EDGE=1/M=0.002/D=spktm theWave,threshold
		
		strswitch(type)
			case "Binned":	
				numBins = floor((IndexToScale(theWave,DimSize(theWave,0)-1,0) - IndexToScale(theWave,0,0) )/ binSize) //number of bins in wave
				Make/O $(NameOfWave(theWave) + "_hist")
				Histogram/C/B={pnt2x(theWave,0),binSize,numBins} spktm,$(NameOfWave(theWave) + "_hist")
				Wave hist = $(NameOfWave(theWave) + "_hist")
				hist /= binSize
				
				KillWaves spktm
				break
			case "Gaussian":
				Variable dT = DimDelta(theWave,0)
				Variable sampleRate = 1000 // 1 ms time resolution
				//gaussian template for convolution
				Make/O/N=(3*(binSize*sampleRate)+1) root:var:template
				Wave template = root:var:template
				SetScale/I x,-1.5*binSize,1.5*binSize,template
				template = exp((-x^2/(0.5*binSize)^2)/2)
				
				Variable theSum = sum(template)
				template /= (1000*binSize)
				
				Variable histDelta = (DimSize(theWave,0)*dT)/sampleRate
				Make/O/FREE/N=(DimSize(theWave,0)*dT*sampleRate) raster
				
				SetScale/P x,0,1/sampleRate,raster
				raster = 0
				
				For(j=0;j<DimSize(spktm,0);j+=1)
					raster[x2pnt(raster,spktm[j])] = 1
				Endfor
	
				Duplicate/O template,$(NameOfWave(theWave) + "_hist");DelayUpdate
				Wave hist = $(NameOfWave(theWave) + "_hist")
				
				Convolve raster, hist
				hist *=1000
				
				break
		endswitch	
		
	EndFor
End

//Set a note for the waves
Function AT_setWaveNote()
	ControlInfo/W=analysis_tools waveNote
	String theNote = S_Value
	ControlInfo/W=analysis_tools overwriteNote
	Variable overwrite = V_Value
	
	//Get the waves
	String waveNameList = getWaveNames()
	Variable i,numWaves = ItemsInList(waveNameList,";")
	
	For(i=0;i<numWaves;i+=1)
		Wave theWave = $StringFromList(i,waveNameList,";")
		SetDataFolder GetWavesDataFolder(theWave,1)
		
		If(overwrite)
			Note/K theWave,theNote
		Else
			Note theWave,theNote
		EndIf
	EndFor

End

//Hides or kills all windows
Function AT_cleanDesk()
	//Hide All: hides all windows
	//Hide Layouts/Kill Rest: if it's not part of a layout, kill the window
	//Kill all: kills all windows

	ControlInfo/W=analysis_tools cleanDeskPop
	String mode = S_Value
	
	String list,info,graphList,currentGraph,layoutList,s
	variable numItems,numPages,i,j,k,graphListItems,match
	
	//list of the layouts
	layoutList = WinList("*",";","WIN:4")
	
	//gets the names of all the windows that are in the layouts
	list="" 
	For(k=0;k<ItemsInList(layoutList,";");k+=1)
		s = StringFromList(k,layoutList,";")
		
		info = LayoutInfo(s,"Layout")
		numPages = str2num(StringByKey("NUMPAGES",info,":",";"))
		
		For(j=1;j<=numPages;j+=1)
			LayoutPageAction/W=$s page=j
			info = LayoutInfo(s,"Layout")
			numItems = str2num(StringByKey("NUMOBJECTS",info,":",";"))
			For(i=0;i<numItems;i+=1)
				info = LayoutInfo(s,num2str(i))
				list += StringByKey("NAME",info,":",";") +";"
			EndFor
		EndFor
	EndFor
	
	//these are the windows that are going to be killed or hidden
	graphList = WinList("*",";","WIN:1")
	graphListItems = ItemsInList(graphList,";")
	//removes some important windows that might be around
	graphList = RemoveFromList("WBr",graphList,";")  //removes Wave Browser 
	graphList = RemoveFromList("analysis_tools",graphList,";")//removes analysis tools
	graphList = RemoveFromList("twoP_Controls",graphList,";")//removes 2PLSM control panel
	
	strswitch(mode)
		case "Hide All":
			//Hides if not included in a layout
			For(k=0;k<graphListItems;k+=1)
				currentGraph =StringFromList(k,graphList,";")
				match = StringMatch(list,"*" + currentGraph + "*")
				If(match == 0)
					DoWindow/HIDE=1 $currentGraph
				EndIf
			EndFor
			
			//Hides if included in a layout
			numItems = ItemsInList(list,";")
			For(i=0;i<numItems;i+=1)
				currentGraph = StringFromList(i,list,";")
				DoWindow/HIDE=1 $currentGraph
			EndFor
			break
		case "Hide Layouts/Kill Rest":
			//Kills if not included in a layout
			For(k=0;k<graphListItems;k+=1)
				currentGraph =StringFromList(k,graphList,";")
				match = StringMatch(list,"*" + currentGraph + "*")
				If(match == 0)
					KillWindow /Z $currentGraph
				EndIf
			EndFor
			
			//Hides if included in a layout
			numItems = ItemsInList(list,";")
			For(i=0;i<numItems;i+=1)
				currentGraph = StringFromList(i,list,";")
				DoWindow/HIDE=1 $currentGraph
			EndFor
			break
		case "Kill All":
			//Kills if not included in a layout
			For(k=0;k<graphListItems;k+=1)
				currentGraph =StringFromList(k,graphList,";")
				match = StringMatch(list,"*" + currentGraph + "*")
				If(match == 0)
					KillWindow /Z $currentGraph
				EndIf
			EndFor
			
			//Kills if included in a layout
			numItems = ItemsInList(list,";")
			For(i=0;i<numItems;i+=1)
				currentGraph = StringFromList(i,list,";")
				KillWindow/Z $currentGraph
			EndFor
			break
			
			break
	endswitch
	
	DoWindow/F WBr //Keeps Wave Browser visible
End