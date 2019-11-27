#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Gets the external function list
Function/S getExternalFunctions(fileList)
	String fileList
	Variable numFiles,i
	String theFile,theList = ""
	
	numFiles = ItemsInList(fileList,";")
	
	For(i=0;i<numFiles;i+=1)
		theFile = StringFromList(i,fileList,";")
		theList += FunctionList("*", ";","WIN:" + theFile)
	EndFor	
	
	//Only matches functions with the prefix 'AT_'
	//This allow user to only include master functions, but also have many other subroutines that it uses, but
	//aren't seen by the function list.
	theList = ListMatch(theList,"AT_*",";")
	
	//Removes the AT from this list for easier viewing in the drop down menu
	theList = ReplaceString("AT_",theList,"")
	
	return theList
End

Function CheckExternalFunctionControls(currentCmd)
	String currentCmd
	
	Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	SVAR DSNames = root:Packages:analysisTools:DataSets:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")

	KillExtParams()
	SVAR currentExtCmd = root:Packages:analysisTools:currentExtCmd
	//ControlInfo/W=analysis_tools extFuncPopUp
	ResolveFunctionParameters("AT_" + currentExtCmd)
	recallExtFuncValues(currentExtCmd)
	
	Button goToProcButton win=analysis_tools,disable = 0
	
	//Toggle the channel pop up menu
	ControlInfo/W=analysis_tools extFuncDS
	If(cmpstr(S_Value,"--Scan List--") == 0)
		//Scan list selection
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=0
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=0
		EndIf
		
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
	ElseIf(cmpstr(S_Value,"--None--") == 0 || cmpstr(S_Value,"--Item List--") == 0)
		//Item List selection or no wave selection
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		EndIf
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
	Else
		//Data set selection
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		EndIf
		
		SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
		DrawText/W=analysis_tools 230,117,"Waves:"
		OpenExtFuncWaveListBox(S_Value)
	EndIf
End

//Returns the items in the index range from a string list
Function/S getListRange(index,list,separator)
	String index,list,separator
	String outList = ""
	
	Variable i,pos
	
	index = resolveListItems(index,",")
	For(i=0;i<ItemsInList(index,",");i+=1)
		pos = str2num(StringFromList(i,index,","))
		outList += StringFromlist(pos,list,separator) + ";"
	EndFor
	return outList
End

//Runs the selected commmand
Function RunCmd(cmdStr)
	String cmdStr
	Execute cmdStr
End

//Opens the file browser to select an abf2 file to browse through
//For PClamp Browser
Function browsePClamp()
	String/G root:ABFvar:ABF_folderpath
	String/G root:ABFvar:ABF_filename
	SVAR ABF_folderpath = root:ABFvar:ABF_folderpath
	SVAR ABF_filename = root:ABFvar:ABF_filename
	
	Variable refnum,i
	String message = "Select the data folder to index"
	String fileFilters = "All Files:.*;"
	Open/D/R/F=fileFilters/M=message refnum
	ABF_folderpath = ParseFilePath(1,S_fileName,":",1,1)
	ABF_filename = ParseFilePath(0,S_fileName,":",1,1)
	Close/A
	
	//index the files
	String fullPath = ABF_folderpath + ABF_filename
	NewPath/O/Q/Z ABFpath,fullpath
	String fileList = IndexedFile(ABFpath,-1,".abf")
	fileList = SortList(fileList,";",16)
	IndexABF(ABF_filename,fullpath,fileList,fromAT=1)
	
	//Hide the indexed table and show it within the GUI
	String tableName = "DTable_Browse"
	DoWindow/HIDE=1 $tableName
	
	//Change the table
	
	//Display the table for browsing
	//Edit/HOST=analysis_tools/W=(10,75,300,300)/N=abfTable
	
	//Set the lines to load everything
	String/G root:ABFvar:ABF_lines
	SVAR ABF_lines = root:ABFvar:ABF_lines
	ABF_lines = ""
	
	//Kill existing waves in the folder
	String saveDF = GetDataFolder(1)
	SetDataFolder root:Packages:analysisTools:ABF_Browser
	
	String browseWaves = DataFolderDir(2)
	browseWaves = StringByKey("WAVES",browseWaves,":",";")
	
	For(i=0;i<ItemsInList(browseWaves,",");i+=1)
		KillWaves/Z $StringFromList(i,browseWaves,",")
	EndFor
	SetDataFolder $saveDF
	
	//sweep listwave
	Wave/T ABF_SweepListWave = root:Packages:analysisTools:ABF_SweepListWave
	
	//sweep selwave
	Wave ABF_SweepSelWave = root:Packages:analysisTools:ABF_SweepSelWave
	//reset the list and selection waves
	Redimension/N=0 ABF_SweepListWave,ABF_SweepSelWave
	
	//Get the file list
	Wave/T table = listToTable(fileList,";")
	Redimension/N=(DimSize(table,0)) ABF_SweepListWave,ABF_SweepSelWave
	ABF_SweepListWave = table
	
End


Function SetExtFuncMenus(selection)
	String selection
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	
	If(cmpstr(selection,"--Scan List--") == 0)
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=0
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=0
		EndIf
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
	ElseIf(cmpstr(selection,"--None--") == 0 || cmpstr(selection,"--Item List--") == 0)
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		EndIf
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
	Else
		If(cmpstr(currentCmd,"Get Peaks") == 0)
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
		Else
			PopUpMenu extFuncChannelPop win=analysis_tools,fsize=12,title="CH",value="1;2",disable=1
			DrawAction/W=analysis_tools delete
			SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs,fstyle=2
			DrawText/W=analysis_tools 230,117,"Waves:"
		EndIf
		OpenExtFuncWaveListBox(selection)
	EndIf
End

//When a Data Set is selected in external functions, it opens a list box that
//shows the wave names that have been located. 
Function OpenExtFuncWaveListBox(dsName)
	String dsName
	Wave/T dsListWave = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
	
	If(!WaveExists(dsListWave))
		PopUpMenu extFuncDS win=analysis_tools,mode=1
		ListBox extFuncDSListBox win=analysis_tools,disable=1
		DrawAction/W=analysis_tools delete
		return 0
	EndIf
	
	Duplicate/O dsListWave,root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
	Wave/T dsListWave_NamesOnly = root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
	Variable i
	
	For(i=0;i<DimSize(dsListWave_NamesOnly,0);i+=1)
		dsListWave_NamesOnly[i] = ParseFilePath(0,dsListWave_NamesOnly[i],":",1,0)
	EndFor
	Make/O/N=(DimSize(dsListWave_NamesOnly,0)) root:Packages:analysisTools:DataSets:dsSelWave
	Wave dsSelWave = root:Packages:analysisTools:DataSets:dsSelWave
	ListBox extFuncDSListBox win=analysis_tools,listWave=dsListWave_NamesOnly,mode=4,disable=0,listwave=dsListWave_NamesOnly,selwave=dsSelWave,proc=atListBoxProc
End



//Loads a function package
//Function LoadPackage(thePackage)
//	String thePackage
//	SVAR cmdList = root:Packages:analysisTools:cmdList
//	SVAR saveCurrentCmd = root:Packages:analysisTools:currentCmd
//	Variable numPackages,i,index,load
//	Wave/T packageTable = root:Packages:analysisTools:packageTable
//	
//	numPackages = DimSize(packageTable,0)
//	//Finds which package
//	thePackage = RemoveEnding(thePackage,"...")
//	
//	//Get package contents
//	For(i=0;i<numPackages;i+=1)
//		If(cmpstr(packageTable[i][0],thePackage) == 0)
//			index = i
//			load = 1
//			break
//		ElseIf(cmpstr("Unload " + packageTable[i][0],thePackage) == 0)
//			index = i
//			load = 0
//			break
//		EndIf
//	EndFor
//	
////	String packageContents = packageTable[index][1]
////	//display package contextual pop up menu
////	GetMouse/W=analysis_tools
////	PopupContextualMenu/C=(16,36) packageContents
//	
//	
//	If(load)
//		cmdList = ReplaceString(thePackage,cmdList,"Unload " + thePackage)
//		cmdList += ";" + packageTable[index][1]
//		String firstControl = StringFromList(1,packageTable[index][1],";")
//		
//		ChangeControls(firstControl,"")
//		PopUpMenu AT_CommandPop win=analysis_tools,mode=WhichListItem(firstControl,cmdList)+1
//    	saveCurrentCmd = firstControl
//	Else
//		String unload = ReplaceString("Unload ",thePackage,"")
//		cmdList = ReplaceString(thePackage,cmdList,unload)
//		cmdList = ReplaceString(packageTable[index][1],cmdList,"")
//		ChangeControls("External Function","")
//		PopUpMenu AT_CommandPop win=analysis_tools,mode=WhichListItem("External Function",cmdList)+1
//		saveCurrentCmd = "External Function"
//		//refresh the values in the external parameter variables
//
//		ControlInfo/W=analysis_tools extFuncPopUp
//		ResolveFunctionParameters("AT_" + S_Value)
//		recallExtFuncValues(S_Value)
//		
//		ControlInfo/W=analysis_tools extFuncDS
//		SetExtFuncMenus(S_Value)
//	EndIf
//End

Function ChangeTabs(currentTab,prevTab)
	String currentTab,prevTab
	String cmdStr
	Variable i
	SVAR runCmdStr =  root:Packages:analysisTools:runCmdStr
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	
	strswitch(prevTab)
		case "Analysis":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_analysisTab
			break
		//case "Mapping":
		//	SVAR ctrlList = root:Packages:analysisTools:ctrlList_mappingTab
		//	break
	endswitch
	
	//Hide controls from previous tab)
	For(i=0;i<ItemsInList(ctrlList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
		cmdStr = TrimString(StringFromList(0,S_Recreation,","))
		cmdStr += ",disable = 1"
		Execute cmdStr
	EndFor
	
	strswitch(currentTab)
		case "Analysis":
			//ControlInfo/W=analysis_tools AT_CommandPop
			strswitch(currentCmd)
				case "MultiROI":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_multiROI
					runCmdStr = "NMultiROI()"
					break
				case "dF Map":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_dfMap
					runCmdStr = "dFMaps()"
					break
				case "Average":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_average
					runCmdStr = "averagewaves()"
					break
				case "Space-Time dF":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_spacetimeDF
					runCmdStr = "SpaceTimeDF()"
					break
				case "ROI Tuning Curve":
					SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiTuningCurve
					runCmdStr = "roiTuningCurve()"
					break
			endswitch
			break
		//case "Mapping":
		//	SVAR ctrlList = root:Packages:analysisTools:ctrlList_mappingTab
		//	runCmdStr = "qkSpot()"
		//	break
	endswitch
	
	For(i=0;i<ItemsInList(ctrlList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
		cmdStr = TrimString(StringFromList(0,S_Recreation,","))
		cmdStr += ",disable = 0"
		Execute cmdStr
	EndFor
End

Function checkMissingWaves(dsName)
	String dsName
	Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
	Wave/T ogds = $("root:Packages:analysisTools:DataSets:ogDS_" + dsName)
	Variable i
	
	For(i=0;i<DimSize(ds,0);i+=1)
		If(!stringmatch(ds[i],"*WSN*"))	//skip the wave set labels
			If(!WaveExists($ds[i]))
				DeletePoints i,1,ds
				i-=1
			EndIf
		EndIf
	EndFor
	
	For(i=0;i<DimSize(ogds,0);i+=1)
		If(!stringmatch(ogds[i],"*WSN*")	)//skip the wave set labels
			If(!WaveExists($ogds[i]))
				DeletePoints i,1,ogds
				i-=1
			EndIf
		EndIf
	EndFor

End

//Animates resizing of group box in the control panel
Function AT_animateControlDrop(ctrlName,ctrlWin,controlHeight,tab,duration)
	String ctrlName,ctrlWin
	Wave controlHeight
	Variable tab,duration
	Variable i,pauseTime,currentSize,steps,startTime,currentTime,elapsedTime
	
	ControlInfo/W=$ctrlWin $ctrlName
	steps = ceil(0.2*(controlHeight[tab] - V_height))	//for step size of 4
	pauseTime = abs(duration/steps)
	currentSize = V_height
	
	For(i=0;i<abs(steps);i+=1)
		If(steps > 0)
			currentSize +=5
		Else
			currentSize -=5
		EndIf
		GroupBox $ctrlName win=$ctrlWin,pos={V_left,V_top},size={V_width,currentSize}
		startTime = ticks
		Do
			currentTime = ticks
			elapsedTime = currentTime - startTime
		While(elapsedTime < pauseTime)
		ControlUpdate/W=$ctrlWin $ctrlName 
	EndFor	
End

//Allows user to nudge all of the ROIs on the top graph at once
Function NudgeROI()
	String graphStr,windows 
	Variable i,j
	
	//make globals for drag and drop functionality
	Variable/G root:Packages:analysisTools:mouseDown
	NVAR mouseDown = root:Packages:analysisTools:mouseDown
	mouseDown = 0
	
	String/G root:Packages:analysisTools:dragROI
	SVAR dragROI = root:Packages:analysisTools:dragROI
	dragROI = ""
	
	Make/O/N=4 root:Packages:analysisTools:mousePos
	Wave mousePos = root:Packages:analysisTools:mousePos
	mousePos = 0
	
	//have to get the top graph this way, since the top window is technically the toolbox itself
	windows = WinList("*",";","WIN:1;VISIBLE:1")
	graphStr = StringFromList(0,windows,";")

	SetWindow $graphStr hook(myHook) = nudgeHook
	
End

Function roiToImage()
	WAVE/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	WAVE ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i
	
	Wave selWave = ROIListSelWave
	Wave/T listWave = ROIListWave
	
	//populate ROIListStr
	ROIListStr = ""
	For(i=0;i<DimSize(selWave,0);i+=1)
		If(selWave[i] == 1)
			ROIListStr += listWave[i] + ";"
		Endif
	EndFor
					
//Jamie's code for adding an ROI to the scanGraph if it exists
	// If shift key was held down, then we are just plotting
	//variable justPlot = ((ba.EventMod && 2) == 2)
	SVAR curScan = root:packages:twoP:examine:curScan
	if (cmpStr (curScan, "LiveWave") == 0)
		SVAR scanStr = root:packages:twoP:Acquire:LiveModeScanStr
	else
		SVAR scanStr = $"root:twoP_Scans:" + curScan + ":" + curScan + "_info"
		endif
	// window to plot on
	controlinfo/w=twoP_Controls ROIonWindowPopup

	string onWindow = S_Value
	
	doWindow/F $S_Value
	if (!(V_Flag))
		print "The selected graph no longer exists."
		return 1
	endif
// check subwin for twoPScanGraph
	if (cmpStr (onWindow, "twoPScanGraph") ==0)
		NVAR ROIChan = root:packages:twoP:examine:roiChan
		switch (ROIChan)
			case 1:
				onWindow = "twoPScanGraph#Gch1"
				break
			case 2:
				onWindow = "twoPScanGraph#Gch2"
				break
			case 3:
				onWindow = "twoPScanGraph#Gmrg"
				break
		endSwitch
		// if selected channel is not displayed, just use first subwindow
		if (WhichListItem(stringfromlist (1, onWindow, "#"), childWindowList (stringfromlist (0, onWindow, "#")), ";") == -1) // subwin not present
			onWindow = "twoPScanGraph#" + stringFromList  (0, childWindowList (stringfromlist (0, onWindow, "#")))
		endif
	endif
	// get a list of traces already on the graph, so they are not added 2x
	string tracelist = tracenamelist (onWIndow, ";", 1)
	// find selected ROIs, append them (if not already appended) and set the "drag" option
	// also copy list of drag traces into a global string
	WAVE/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	WAVE ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	variable ii, numroi = numpnts (ROIListWave), red, green, blue
	string roiStr
	string/G root:packages:twoP:examine:ROInudgeList =""
	SVAR ROInudgeList = root:packages:twoP:examine:ROInudgeList 
	for (ii =0; ii < numRoi; ii += 1)
		if (ROIListSelWave [ii] == 0)
			continue
		endif
		roiStr = ROIListWave [ii]
		ROInudgeList += roiStr + ";"
		// display ROI if it is not already displayed
		if (WhichListItem(roiStr + "_y", tracelist, ";") == -1)
			WAVE roiXWave = $ "Root:twoP_ROIs:" + roiStr + "_x"
			WAVE roiYWave = $ "Root:twoP_ROIs:" + roiStr + "_y"
			if (!((WaveExists (roiXWave)) && (WaveExists (roiYWave))))
				continue
			endif
			red = numberbykey ("Red", note (roiXWave))
			green = numberbykey ("Green", note (roiXWave))
			blue = numberbykey ("Blue", note (roiXWave))
			
			//Automatically make cyan
			If(numtype(red) == 2)
				red = 0
				green = 65535
				blue = 65535
			EndIf
			
			//Find which axes are being used
			String xAxisName,yAxisName,flags,info
			info = TraceInfo(onWindow,StringFromList(0,tracelist,";"),0)
			xAxisName = StringByKey("XAXIS",info,":",";")
			yAxisName = StringByKey("YAXIS",info,":",";")
			flags = StringByKey("AXISFLAGS",info,":",";")
			If(StringMatch(flags,"*/T*") && StringMatch(flags,"*/R*"))
				appendtograph /W=$onWindow/C=(red, green, blue)/T=$xAxisName/R=$yAxisName RoiYWave vs RoiXwave
			ElseIf(StringMatch(flags,"*/T*"))
				appendtograph /W=$onWindow/C=(red, green, blue)/T=$xAxisName RoiYWave vs RoiXwave
			ElseIf(StringMatch(flags,"*/R*"))
				appendtograph /W=$onWindow/C=(red, green, blue)/R=$yAxisName RoiYWave vs RoiXwave
			Else
				appendtograph /W=$onWindow/C=(red, green, blue) RoiYWave vs RoiXwave
			EndIf
			
			//appendtograph /W=$onWindow/C=(red, green, blue) RoiYWave vs RoiXwave
		endif
	
					
		// set quickDrag for selected rois
					
		//	if (!(justPlot))
		//		modifyGraph/W=$onWindow quickDrag ($roiStr + "_y")=1
		//		String/G root:packages:twoP:examine:NudgeOnWindow = onWindow
		//	endif
	endfor
	//if not just plotting, set nudge button to new title and new procedure
	//	if (!(justPlot))
	//			Button ROINudgeButton win=twoP_Controls, title = "Done", proc = NQ_RoiNudgeDoneButtonProc, fColor=(65535,0,0)
	//	endif
End


End

Function nudgeHook(s)
	STRUCT WMWinHookStruct &s
	
	NVAR mouseDown = root:Packages:analysisTools:mouseDown
	SVAR dragROI = root:Packages:analysisTools:dragROI
	Variable hookResult = 0
	Variable dx,dy,newX,newY
	Wave mousePos = root:Packages:analysisTools:mousePos
	String graphStr = "",windows="",theROI = "",info = ""
	
	//have to get the top graph this way, since the top window is technically the toolbox itself
	windows = WinList("*",";","WIN:1;VISIBLE:1")
	graphStr = StringFromList(0,windows,";")
	
	switch(s.eventCode)
		case 0: //activate
			break
		case 1: //deactivate
			break
		case 3: //mouse down
			//first two rows are for the start position
		//	mousePos[0] = AxisValFromPixel(graphStr,"bottom",s.mouseLoc.h)
			//mousePos[1] = AxisValFromPixel(graphStr,"left",s.mouseLoc.v)
			
			String imageStr = StringFromList(0,ImageNameList(graphStr,";"),";")
			Wave theImage = ImageNameToWaveRef(graphStr,imageStr)
			
			//axis position in pixels
			Variable xPix = ScaleToIndex(theImage,mousePos[0],0)
			Variable yPix = ScaleToIndex(theImage,mousePos[1],1)
			
			//what ROI did the mouse click on?
			info = TraceFromPixel(s.mouseLoc.h,s.mouseLoc.v,"DELTAX:3;DELTAY:3")
			If(strlen(info))
				mouseDown = 1
				dragROI = StringByKey("TRACE",info,":",";")
				//set to quick drag
				ModifyGraph/W=$graphStr quickDrag($dragROI) = 1
				If(!strlen(dragROI))
					//reset everything if ROI was not clicked
					mouseDown = 0
					dragROI = ""
				EndIf
			Else
				//reset everything if ROI was not clicked
				mouseDown = 0
				dragROI = ""
			EndIf
			break
	endswitch	
		
End

Function SetWaveNote(theWave,paramListStr)
	Wave theWave
	String paramListStr
	Variable numParams,i
	String theParam
	
	numParams = ItemsInList(paramListStr,";")
	
	ControlInfo/W=analysis_tools bslnStVar
	Variable bslnStart = V_Value
	ControlInfo/W=analysis_tools bslnEndVar
	Variable bslnEnd = V_Value
	ControlInfo/W=analysis_tools peakStVar
	Variable pkStart = V_Value
	ControlInfo/W=analysis_tools peakEndVar
	Variable pkEnd = V_Value
	ControlInfo/W=analysis_tools pkWindow
	Variable pkWindow = V_Value
	ControlInfo/W=analysis_tools SmoothBox
	Variable TempFilter = V_Value
	ControlInfo/W=analysis_tools SmoothFilterVar
	Variable smoothSize = V_Value
	
	For(i=0;i<numParams;i+=1)
		theParam = StringFromList(i,paramListStr,";")
		
		strswitch(theParam)
			case "baseline":
				Note theWave,"BSL_START:" + num2str(bslnStart)
				Note theWave,"BSL_END:" + num2str(bslnEnd)
				break
			case "peak":
				Note theWave,"PK_START:" + num2str(pkStart)
				Note theWave,"PK_END:" + num2str(pkEnd)
				break
			case "smooth":
				If(TempFilter)
					Note theWave,"SMOOTH:" + num2str(smoothSize)
				Else
					Note theWave,"SMOOTH:0"
				EndIf
				break
			case "channel":
				If(stringmatch(NameOfWave(theWave),"*ch1*"))
					Note theWave,"CHANNEL:1"
				ElseIf(stringmatch(NameOfWave(theWave),"*ch2*"))
					Note theWave,"CHANNEL:2"				
				Else
					Note theWave,"CHANNEL:-1"
				EndIf
				break
			case "peakWidth":
				Note theWave,"PK_WIDTH:" + num2str(pkWindow)
				break
			endswitch
	EndFor
	
End

Function/WAVE GetOrderFromAngleList(angleList,orderWave[,useBatch])
	String angleList
	Wave orderWave
	Variable useBatch
	Variable batchSize
	
	ControlInfo/W=analysis_tools BatchsizeVar
	batchSize = V_Value
	
	If(batchSize == 0 || batchSize < 0 || batchSize == 1)
		batchSize = ItemsInList(angleList,",")
	EndIf	
	
	If(ParamIsDefault(useBatch))
		useBatch = 0
	EndIf
	
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable i
	
	//Get the angle order based on the angle list
	If(useBatch)
		If(strlen(angleList))
			Make/FREE/N=(batchSize) angleListWave
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				angleListWave[i] = str2num(StringFromList(i,angleList,","))
			EndFor
	
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				FindValue/V=(WaveMin(angleListWave)) angleListWave
				angleListWave[V_Value] = 1000
				orderWave[i] = V_Value
			EndFor
		EndIf
	Else
		If(strlen(angleList))
			Make/FREE/N=(ItemsInList(scanListStr,";")) angleListWave
	
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				angleListWave[i] = str2num(StringFromList(i,angleList,","))
			EndFor
	
			For(i=0;i<ItemsInList(angleList,",");i+=1)
				FindValue/V=(WaveMin(angleListWave)) angleListWave
				angleListWave[V_Value] = 1000
				orderWave[i] = V_Value
			EndFor
		EndIf
	EndIf
	return orderWave
End

Function similarityIndex()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	If(ItemsInList(scanListStr,";") != 3)
		DoAlert 0,"Need 3 wave: entry, exit, and turn."
		return -1
	EndIf
	
	Wave entry = $("root:ROI_analysis:" + StringFromList(0,scanListStr,";") + "_gridROI_peak")
	Wave exit = $("root:ROI_analysis:" + StringFromList(1,scanListStr,";") + "_gridROI_peak")
	Wave turn = $("root:ROI_analysis:" + StringFromList(2,scanListStr,";") + "_gridROI_peak")
	
	SetDataFolder GetWavesDataFolder(entry,1)
	
	Variable xSize = DimSize(entry,0)
	Variable ySize = DimSize(entry,1)
	
	Make/O/N=(xSize,ySize) sIndex
	Wave sIndex = sIndex
	
	sIndex = ( (entry - turn) - (exit - turn) ) / ( (entry - turn) + (exit - turn) )
	//sIndex = (1 - (abs(entry - turn)/turn)) - (1-(abs(exit - turn)/turn))
End

Function stimPosPanel()
	NewPanel /K=1 /W=(1978,133,2178,843)/N=stimPos as "Stimulus Position"
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv xcoord= rel,ycoord= abs,fsize= 10,textxjust= 1
	DrawText 0.5,20,"DIC"
	SetDrawEnv xcoord= rel,ycoord= abs,fsize= 10,textxjust= 1
	DrawText 0.5,220,"twoP"
	SetDrawEnv xcoord= rel,ycoord= abs,fsize= 10,textxjust= 1
	DrawText 0.5,420,"Projector/StimGen"
	CheckBox horizontalFlip,pos={10.00,620.00},size={60.00,16.00},proc=stimPosCheckProc,title=" Horizontal"
	CheckBox horizontalFlip,font="Arial",value= 0
	
	Make/O/N=4 root:Packages:analysisTools:markerX,root:Packages:analysisTools:markerY
	Wave markerX = root:Packages:analysisTools:markerX
	Wave markerY = root:Packages:analysisTools:markerY
	markerX = {150,0,-150,0}
	markerY = {0,150,0,-150}
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Packages:analysisTools

	Display/W=(10,20,190,200)/HOST=# /L=VertCrossing/B=HorizCrossing markerX vs markerY

	ModifyGraph margin(left)=7,margin(bottom)=7,margin(top)=7,margin(right)=7,gfSize=8
	ModifyGraph mode=3,marker=19,rgb=(0,0,0),msize=5,standoff=0,axThick=0.5,btLen=2
	ModifyGraph freePos(VertCrossing)={0,HorizCrossing},freePos(HorizCrossing)={0,VertCrossing}
	ModifyGraph rgb(markerX[0])=(52428,52425,1),rgb(markerX[1])=(16385,28398,65535)
	ModifyGraph rgb(markerX[2])=(65535,0,0),rgb(markerX[3])=(2,39321,1)
	
	SetAxis VertCrossing 250,-250
	SetAxis HorizCrossing 250,-250
	SetDrawLayer UserFront
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,linethick= 0.5,fillpat= 0
	DrawOval -250,250,250,-250
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText 220,0,"90°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,-220,"180°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText -220,0,"270°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,220,"0°"
	RenameWindow #,DIC
	SetActiveSubwindow ##
	
	Display/W=(10,220,190,400)/HOST=# /L=VertCrossing/B=HorizCrossing markerX vs markerY

	ModifyGraph margin(left)=7,margin(bottom)=7,margin(top)=7,margin(right)=7,gfSize=8
	ModifyGraph mode=3,marker=19,rgb=(0,0,0),msize=5,standoff=0,axThick=0.5,btLen=2
	ModifyGraph freePos(VertCrossing)={0,HorizCrossing},freePos(HorizCrossing)={0,VertCrossing}
	ModifyGraph rgb(markerX[0])=(52428,52425,1),rgb(markerX[1])=(16385,28398,65535)
	ModifyGraph rgb(markerX[2])=(65535,0,0),rgb(markerX[3])=(2,39321,1)
	
	SetAxis VertCrossing 250,-250
	SetAxis HorizCrossing -250,250
	SetDrawLayer UserFront
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,linethick= 0.5,fillpat= 0
	DrawOval -250,250,250,-250
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText 220,0,"90°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,-220,"180°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText -220,0,"270°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,220,"0°"
	RenameWindow #,twoP
	SetActiveSubwindow ##
	
	Display/W=(10,420,190,600)/HOST=# /L=VertCrossing/B=HorizCrossing markerY vs markerX

	ModifyGraph margin(left)=7,margin(bottom)=7,margin(top)=7,margin(right)=7,gfSize=8
	ModifyGraph mode=3,marker=19,rgb=(0,0,0),msize=5,standoff=0,axThick=0.5,btLen=2
	ModifyGraph freePos(VertCrossing)={0,HorizCrossing},freePos(HorizCrossing)={0,VertCrossing}
	ModifyGraph rgb(markerY[0])=(52428,52425,1),rgb(markerY[1])=(16385,28398,65535)
	ModifyGraph rgb(markerY[2])=(65535,0,0),rgb(markerY[3])=(2,39321,1)
	SetAxis VertCrossing 250,-250
	SetAxis HorizCrossing -250,250
	SetDrawLayer UserFront
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,linethick= 0.5,fillpat= 0
	DrawOval -250,250,250,-250
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText 220,0,"0°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,-220,"270°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textxjust= 1
	DrawText -220,0,"180°"
	SetDrawEnv xcoord= HorizCrossing,ycoord= VertCrossing,fsize= 10,textyjust= 1
	DrawText 0,220,"90°"
	RenameWindow #,Projector
	SetActiveSubwindow ##
End

Function stimPosCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
		switch( cba.eventCode )
			case 2: // mouse up
				Variable checked = cba.checked
				If(checked)
					SetAxis/W=stimPos#twoP HorizCrossing 250,-250
				Else
					SetAxis/W=stimPos#twoP HorizCrossing -250,250
				EndIf
				break
			case -1: // control being killed
				break
		endswitch
End

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
//SCAN REGISTER:

//This series of functions allows you to correct images that are out of register (image shearing)
//during bidirectional scanning with 2PLSM. 

//STEP 1: Select image

//Open a new image of the scan you want to correct, and select that graph window from the drop down menu.
//Set the initial parameters for the correction to use:

//Phase (slider): 40-50 degrees
//pixels: 10 or 15 is a good starting point
//divergence: set to 1. If its not working well, set to -1 and try again.
//frequency: 0.5 or 0.6 is good
//Offset: -8 works well

//STEP 2: Select ROIs

//Click 'Auto' allows you to add ROIs (make a marquee box on the image, click the '+' button to add ROI).
//These ROIs will be used for making sure the image is registered correctly. 

//STEP 3: Auto-register image

//Once ROIs are selected, click 'Done'. This will attempt to auto-register the image.

//STEP 4: Optimize correction

//The result probably won't be perfect. An max intensity projection of the uncorrected image will pop up, along with the corrected version. 
//Change the drop down to the uncorrected max intensity projection, then move around the parameters manually to optimize it.
//The corrected image will live update itself as the parameters as adjusted. 

//STEP 5: Save the correction template

//After you're happy with the correction, you can click 'Save' to save the correction template.
//The template now appears in a drop down menu for repeated use on other scans. 

//STEP 6: Apply template to other scans

//To apply the template to other scans, click the 'Use Scan List' check box, allowing you to select scans without opening an image plot.
//Select the channels (1, 2, or both) that you want to correct. 
//Select the template to use.
//Click 'Apply', and the correction will applied to all the scans that you selected in the scan list box.

//IMPORTANT: Applying the correction with the 'Apply' button will overwrite the original scan wave. Only do this if you're absolutely sure about the correction.

Function AT_InitializeScanRegister()
	//NewPanel/K=2/W=(100,100,300,330)/N=ScanRegistry as "Register Scan"
	PopUpMenu SR_waveList win=analysis_tools,pos={35,60},bodywidth=200,size={200,20},title = " ",value=WinList("*",";","WIN:1"),proc=AT_ScanRegistryPopUpProc,disable=0 //WaveList("*",";","DIMS:2")
	//SetVariable SR_phase win=ScanRegistry,live=1,pos={20,25},size={60,20},title="Phase",value=_NUM:0,proc=ScanRegistryVarProc
	Slider SR_phase win=analysis_tools,live=1,pos={50,80},size={150,20},value=50,limits={0,360,1},title="Phase",vert=0,proc=AT_ScanRegistrySliderProc
	CheckBox SR_phaseLock win=analysis_tools,pos={34,78},title="",value=0
	SetVariable SR_phaseVal win=analysis_tools,pos={210,80},size={40,20},title=" ",live=1,frame=0,value=_NUM:AT_GetSliderValue()
	CheckBox SR_pixelDeltaLock win=analysis_tools,pos={34,127},title="",value=0
	SetVariable SR_pixelDelta win=analysis_tools,pos={50,129},size={60,20},limits={-inf,inf,0.5},title="Pixels",value=_NUM:10,proc=AT_ScanRegistryVarProc
	CheckBox SR_divergenceLock win=analysis_tools,pos={34,150},title="",value=1
	SetVariable SR_divergence win=analysis_tools,pos={50,152},size={90,20},limits={-1,1,2},title="Divergence",value=_NUM:1,proc=AT_ScanRegistryVarProc
	CheckBox SR_frequencyLock win=analysis_tools,pos={34,173},title="",value=0
	SetVariable SR_frequency win=analysis_tools,pos={50,175},size={90,20},limits={0,inf,0.01},title="Frequency",value=_NUM:0.6,proc=AT_ScanRegistryVarProc
	CheckBox SR_pixelOffsetLock win=analysis_tools,pos={34,197},title="",value=0
	SetVariable SR_pixelOffset win=analysis_tools,pos={50,199},size={90,20},limits={-inf,inf,1},title="Offset",value=_NUM:-8,proc=AT_ScanRegistryVarProc
	Button SR_autoRegisterButton win=analysis_tools,pos={145,180},size={60,20},title="Auto",proc=AT_ScanRegistryButtonProc
	Button SR_addROIButton win=analysis_tools,pos={204,287},size={20,20},title="+",fColor=(3,52428,1),disable=1,proc=AT_ScanRegistryButtonProc
	Button SR_reset win=analysis_tools,pos={145,160},size={60,20},title="Reset",proc=AT_ScanRegistryButtonProc
	Button SR_showROIButton win=analysis_tools,pos={145,140},size={60,20},title="ROIs",proc=AT_ScanRegistryButtonProc
	//Button SR_quitButton win=analysis_tools,pos={145,60},size={60,20},title="Quit", fColor=(65535,0,0),proc=ScanRegistryButtonProc
	Button SR_saveTemplateButton win=analysis_tools,pos={145,200},size={60,20},title="Save",proc=AT_ScanRegistryButtonProc
	Button SR_applyTemplate win=analysis_tools,pos={176,224},size={50,20},title="Apply",proc=AT_ScanRegistryButtonProc
	
	String/G root:var:templateList
	SVAR templateList = root:var:templateList
	templateList = GetTemplateList()
	PopUpMenu SR_templatePopUp win=analysis_tools,pos={34,225},size={100,20},title="Templates",value=#"root:var:templateList",proc=AT_ScanRegistryPopUpProc
	CheckBox SR_UseAnalysisToolsCheck win=analysis_tools,pos={34,245},size={40,20},title="Use Scan List"
	
	//Wave to hold ROI coordinates for automatic registry
	If(!DataFolderExists("root:var"))
		NewDataFolder root:var
	EndIf
	Make/O/N=(4,1) root:var:roiCoord = 0
	String/G root:var:roiXlist,root:var:roiYlist
	SVAR roiXlist = root:var:roiXlist
	SVAR roiYlist = root:var:roiYlist
	roiXlist = ""
	roiYlist = ""
	Variable/G root:var:hidden = 0
End

Function/S GetTemplateList()
	String cdf
	
	cdf = GetDataFolder(1)
	If(!DataFolderExists("root:Packages:twoP:Scan_Register_Templates"))
		NewDataFolder root:Packages:twoP:Scan_Register_Templates
	EndIf
	SetDataFolder root:Packages:twoP:Scan_Register_Templates
	
	String templateList = WaveList("template*",";","DIMS:2")
	If(!strlen(templateList))
		templateList = "None"
	EndIf
	
	SetDataFolder cdf
	return templateList
	
End

Function/WAVE CorrectScanRegister(scanWave,pixelOffset,pixelDelta,phase,frequency,divergence)
	Wave scanWave
	Variable pixelOffset,pixelDelta,phase,frequency,divergence
	//divergence is 1 if even columns shift positively and odd columns shift negatively
	//divergence is -1 if even columns shift negatively and odd columns shift positively
	
	Variable xDelta,yDelta,xOffset,yOffset,xSize,ySize,i
	
	xDelta = DimDelta(scanWave,0)
	xOffset = DimOffset(scanWave,0)
	xSize = DimSize(scanWave,0)
	yDelta = DimDelta(scanWave,1)
	yOffset = DimOffset(scanWave,1)
	ySize = DimSize(scanWave,1)
	
	//abort if no scanwave is found
	If(numtype(xDelta) == 2)
		abort
	EndIf
	
	//Make template wave for register adjustment
	If(!DataFolderExists("root:var"))
		NewDataFolder root:var
	EndIf
	Make/O/N=(xSize,ySize) root:var:template
	Wave template = root:var:template
	template = 0
	
	//Creates the sine wave for the image correction. The second equation works much better when the constant pixel offset
	For(i=0;i<ySize;i+=1)
		If(mod(i,2) == 0)
			//template = 0.5*pixelDelta + 0.5*pixelDelta*sin((1/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
	//		template[][i] =  divergence*0.5*pixelDelta*sin((frequency/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
			template[][i] = pixelOffset + divergence*0.5*pixelDelta*sin((frequency/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
		Else
			//template[][i] = pixelOffset - divergence*0.5*pixelDelta*sin((frequency/xSize)*(2*pi)*(x-(phase)*xSize/(2*pi)))
		EndIf
	EndFor
	
	
	//Make source grid with the images original scaling
	Make/O/D/N=(xSize,ySize) root:var:xs
	Make/O/D/N=(xSize,ySize) root:var:ys
	Wave xs = root:var:xs
	Wave ys = root:var:ys
	
	xs = p*xSize/(xSize)
	ys = q*ySize/(ySize)
	
	//Make destination grid, which is warped according to template sine wave
	Make/O/D/N=(xSize,ySize) root:var:xd
	Make/O/D/N=(xSize,ySize) root:var:yd
	Wave xd =  root:var:xd
	Wave yd =  root:var:yd
	
	xd = xs + template
	yd = ys //+ template
	
	//xs=p*imagerows/(gridRows-1)
	//ys=q*imageCols/(gridCols-1)
	//ImageInterpolate/RESL={4500,4500}/TRNS={radialPoly,1,0,0,0} Resample scanWave
	ImageInterpolate/wm=1/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp scanWave
	
	Wave correctedImage = M_InterpolatedImage	
	return correctedImage
End

Function AT_AutoRegister(imageWave,windowName)
	Wave imageWave
	String windowName

	
	Variable error,rows,cols,left,right,top,bottom,i,j,k,m,numROIs,count,endPt
	
	Wave coordinates = root:var:roiCoord
	
	Variable timeRef = StartMSTimer
	
	numROIs = DimSize(coordinates,1)
	
	//errorWave keeps track of error minimization
	Make/O/N=1000 root:var:errorWave
	Wave errorWave = root:var:errorWave
	errorWave = 0
	
	//Original values for the image correction
	Variable pixelOffset,pixelDelta,phase,frequency,divergence
	Variable finalPixelOffset,finalPixelDelta,finalPhase,finalFrequency,finalDivergence
	
	//Some defaults initial values that are probably close to the right answer
	ControlInfo/W=analysis_tools SR_pixelDelta
	pixelDelta = V_Value
	
	ControlInfo/W=analysis_tools SR_pixelOffset
	pixelOffset = V_Value
				
	ControlInfo/W=analysis_tools SR_frequency
	frequency = V_Value
	
	ControlInfo/W=analysis_tools SR_phase
	phase = V_Value*pi/180
		
	ControlInfo/W=analysis_tools SR_divergence
	divergence = V_Value	
	//pixelOffset = -8
	//pixelDelta = 0
	//phase = 45*pi/180
	//frequency = 0.6
	//divergence = -1
	
	//Is this an image stack?
	If(DimSize(imageWave,2) > 0)
		MatrixOP/O/S maxProj = sumBeams(imageWave)
		Wave maxProj = maxProj
		SetScale/P x,DimOffset(imageWave,0),DimDelta(imageWave,0),maxProj
		SetScale/P y,DimOffset(imageWave,1),DimDelta(imageWave,1),maxProj
		Wave imagewave = maxProj
		NewImage imageWave
	EndIf
	
	Wave correctedImage = imageWave	
	
	//Get ROI coordinates in index
	Duplicate/O coordinates,root:var:roiCoordScale
	Wave coordinates_Scale = root:var:roiCoordScale
	Redimension/N=(6,-1) coordinates_Scale
	
	For(i=0;i<numROIs;i+=1)
		coordinates_Scale[0][i] = ScaleToIndex(imageWave,coordinates_Scale[0][i],0)//left
		coordinates_Scale[1][i] = ScaleToIndex(imageWave,coordinates_Scale[1][i],1)//top
		coordinates_Scale[2][i] = ScaleToIndex(imageWave,coordinates_Scale[2][i],0)//right
		coordinates_Scale[3][i] = ScaleToIndex(imageWave,coordinates_Scale[3][i],1)//bottom
		coordinates_Scale[4][i] = 	abs(coordinates_Scale[2][i] - coordinates_Scale[0][i])//rows
		
		If(stringmatch(windowName,"twoPscanGraph*"))
			coordinates_Scale[5][i] = 	abs(coordinates_Scale[1][i] - coordinates_Scale[3][i]) //cols
		Else
			coordinates_Scale[5][i] = 	abs(coordinates_Scale[3][i] - coordinates_Scale[1][i])//cols
		EndIf
		
		String dataName,peakName
		dataName = "data_" + num2str(i)
		peakName = "peaks_" + num2str(i)
	
		If(stringmatch(windowName,"twoPscanGraph*"))
			Make/O/N=(coordinates_Scale[4][i],coordinates_Scale[5][i]) $dataName = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[3][i]]
		Else
			Make/O/N=(coordinates_Scale[4][i],coordinates_Scale[5][i]) $dataName = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[1][i]]
		EndIf
		
		Make/O/N=(coordinates_Scale[5][i]) $peakName
	EndFor
	
	For(m=0;m<4;m+=1)
		count = 0
		
		If(m == 0)
			//pixel delta
			Redimension/N=50 errorWave
			endPt = 50
			ControlInfo/W=analysis_tools SR_pixelDeltaLock
			If(V_Value)
				continue
			Else
				pixelDelta = 0
			EndIf
		ElseIf(m == 1)
			//frequency
			Redimension/N=50 errorWave
			endPt = 50
		
			ControlInfo/W=analysis_tools SR_frequencyLock
			If(V_Value)
				continue
			Else
				frequency = 0.3	
			EndIf
		ElseIf(m == 2)	
			//pixel offset
			Redimension/N=60 errorWave
			endpt = 60
			ControlInfo/W=analysis_tools SR_pixelOffsetLock
			If(V_Value)
				continue
			Else
				pixelOffset = -15
			EndIf
		ElseIf(m == 3)
			//phase
			Redimension/N=100 errorWave
			endPt = 100
			ControlInfo/W=analysis_tools SR_phaseLock
			If(V_Value)
				continue
			Else
				phase = 0
			EndIf
		EndIf
		
		For(k=0;k<endPt;k+=1)
			//error will accumulate over each ROI, then the program will adjust parameters
			//in an attempt to find the parameters that minimize error. 
			error = 0
			For(i=0;i<numROIs;i+=1)
				//Get the updated ROI data
				dataName = "data_" + num2str(i)
				peakName = "peaks_" + num2str(i)
				Wave data = $dataName
				Wave peaks = $peakName
				
				If(stringmatch(windowName,"twoPscanGraph*"))
					data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[3][i]]
				Else
					data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[1][i]]
				EndIf
				//We'll be registering left/right shifts, so stepping through columns
				
				//Find peak intensity in each row of each ROI, calculate positional differences in peaks across rows.
				For(j=0;j<coordinates_Scale[5][i];j+=1)
					MatrixOP/O/FREE colData = col(data,j)
					WaveStats/Q colData
					peaks[j] = V_maxloc
					
					If(j > 0)
						error += abs(peaks[j-1] - peaks[j])
					EndIf
				EndFor
	
			EndFor
		
			errorWave[count] = error
			count += 1
		
	
			//update variables to new values
			If(m == 0)
				pixelDelta += 1
			ElseIf(m == 1)
				frequency += 0.01
			ElseIf(m == 2)
				pixelOffset += 0.5
			ElseIf(m == 3)
				phase += 1*pi/180
			EndIf
			
			Wave correctedImage = CorrectScanRegister(imageWave,pixelOffset,pixelDelta,phase,frequency,divergence)
		
		EndFor
		
		//Set the parameter to its minimum error value
		If(m == 0)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			pixelDelta = V_minloc
		ElseIf(m == 1)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			frequency = 0.3 + V_minloc*0.01
		ElseIf(m == 2)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			pixelOffset = -15 + V_minloc*0.5
		ElseIf(m == 3)
			WaveStats/Q/R=[1,DimSize(errorWave,0)] errorWave
			phase = (V_minloc)*pi/180
		EndIf
		//Reset errorWave
		errorWave = 0
	EndFor	
	
	//Final correction with minimum parameter error values
	Wave correctedImage = CorrectScanRegister(imageWave,pixelOffset,pixelDelta,phase,frequency,divergence)
	
	error = 0
	//Kill ROI data waves
	For(i=0;i<numROIs;i+=1)
		dataName = "data_" + num2str(i)
		peakName = "peaks_" + num2str(i)
		Wave data = $dataName
		Wave peaks = $peakName
		
		If(stringmatch(windowName,"twoPscanGraph*"))
			data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[3][i]]
		Else
			data = correctedImage[p + coordinates_Scale[0][i]][q + coordinates_Scale[1][i]]
		EndIf	
		//We'll be registering left/right shifts, so stepping through columns
				
		//Get final error value from optimized parameters
		For(j=0;j<coordinates_Scale[5][i];j+=1)
			MatrixOP/O/FREE colData = col(data,j)
			WaveStats/Q colData
			peaks[j] = V_maxloc
					
			If(j > 0)
				error += abs(peaks[j-1] - peaks[j])
			EndIf
		EndFor
		
		KillWaves/Z data,peaks
	EndFor
	
	print "------------"
	print "Image registration: " + NameOfWave(imageWave)
	SetVariable SR_pixelOffset win=analysis_tools,value=_NUM:pixelOffset
	print "Pixel Offset = ",pixelOffset
	SetVariable SR_pixelDelta win=analysis_tools,value=_NUM:pixelDelta
	print "Pixel Delta = ",pixelDelta
	SetVariable SR_frequency win=analysis_tools,value=_NUM:frequency
	print "Frequency = ",frequency
	Slider SR_phase win=analysis_tools,value=phase*180/pi
	SetVariable SR_phaseVal win=analysis_tools,value=_NUM:AT_GetSliderValue()
	print "Phase = ",phase*180/pi
	print "Error = ",error
	AT_SR_Message(5)
	Variable totalTime = StopMSTimer(timeRef)
	print "Time = ", totalTime/1000000," s"
	NewImage correctedImage
End



Function AT_GetSliderValue()
	Variable sliderVal
	ControlInfo/W=analysis_tools SR_phase
	sliderVal = V_Value
	return sliderVal
End





Function AT_SR_Message(code)
	Variable code
	String message
	
	DrawAction/W=analysis_tools delete
	
	switch(code)
		case 1:
			message = "Select ROIs using the marquee tool"
			break
		case 2:
			message = "Registering image"
			DrawAction/W=analysis_tools delete
			break
		case 3:
			message = "More than 1 image on the graph"
			break
		case 4:
			message = "Image wave cannot be found"
			break
		case 5:
			message = ""
			break
	endswitch
	
	SetDrawEnv/W=analysis_tools fsize=10,fstyle=(2^1),textxjust=0
	DrawText/W=analysis_tools 33,304,message
	
End



Function/S SR_addROI(theWindow)
	String theWindow

	SVAR roiXlist = root:var:roiXlist
	SVAR roiYlist = root:var:roiYlist
	
	If(!WaveExists(root:var:roiCoord))
		Make/N=(4,1) root:var:roiCoord
	EndIf
	
	Wave coordinates = root:var:roiCoord
	Variable numROIs = DimSize(coordinates,1) - 1
	
	String channel = RemoveEnding(getChannel(1),";")
	
	//Get coordinates of the marquee
	If(cmpstr(theWindow,"twoPscanGraph") == 0)
		Variable isScanGraph = 1
		If(cmpstr(channel,"ch1") == 0)
			theWindow += "#GCH1"
		ElseIf(cmpstr(channel,"ch2") == 0)
			theWindow += "#GCH2"
		EndIf
		GetMarquee/K/W=$theWindow/Z left,bottom
	Else
		GetMarquee/K/W=$theWindow/Z left,top
	EndIf
	
	coordinates[0][numROIs - 1] = V_left
	coordinates[1][numROIs - 1] = V_top
	coordinates[2][numROIs - 1] = V_right
	coordinates[3][numROIs - 1] = V_bottom
	
	String roiNameX = "ROIx_" + num2str(ItemsInList(roiXlist,";") + 1)
	roiXlist += roiNameX + ";"
	String roiNameY = "ROIy_" + num2str(ItemsInList(roiYlist,";") + 1)
	roiYlist += roiNameY + ";"
	
	Make/O/N=5 $("root:var:" + roiNameX) = {V_left,V_right,V_right,V_left,V_left}
	Wave roiXwave = $("root:var:" + roiNameX)
	Make/O/N=5 $("root:var:" + roiNameY) = {V_bottom,V_bottom,V_top,V_top,V_bottom}
	Wave roiYwave = $("root:var:" + roiNameY)
	
	If(isScanGraph)
		AppendToGraph/W=$theWindow/L/B roiYwave vs roiXwave
	Else
		AppendToGraph/W=$theWindow/L/T roiYwave vs roiXwave
	EndIf
	ModifyGraph/W=$theWindow rgb=(0,65535,65535)
End

Function/S AT_SetupROICapture()
	String imageName
	String errStr
	
	//Get the image window
	ControlInfo/W=analysis_tools SR_waveList
	DoWindow/F $S_Value
	
	String channel = RemoveEnding(getChannel(1),";")
	
	//If its the twoP Scan Graph
	If(cmpstr("twoPscanGraph",S_Value) == 0)
		If(cmpstr(channel,"ch1") == 0)
			S_Value = S_Value + "#GCH1"
		ElseIf(cmpstr(channel,"ch2") == 0)	
			S_Value = S_Value + "#GCH2"
		EndIf
		
		SVAR curScan = root:Packages:twoP:examine:curScan
		imageName = "root:twoP_Scans:" + curScan + ":" + curScan + "_" + channel
		Wave theImage = $imageName
	Else			
				
		//More than one image in graph?
		imageName = ImageNameList(S_Value,";")
		If(ItemsInList(imageName,";") > 1)
			AT_SR_Message(3)
			errStr = "-1"
		EndIf
		
		imageName = StringFromList(0,imageName,";")
		Wave theImage = ImageNameToWaveRef(S_Value,imageName)	
	EndIf
				
	//Image wave exists?
	If(!WaveExists(theImage))
		AT_SR_Message(4)
		errStr = "-1"
		return errStr	
	EndIf
				
	//Does image graph window exist?
	If(!V_flag)
		NewImage theImage
	EndIf	

	return imageName
End

//Checks string length is less than 32 characters
Function CheckLongName(theString)
	String theString
	Variable length = strlen(theString)
	
	If(length > 31)
		return 1
	Else
		return 0
	EndIf
End

//Gets full path of the selected items in the ItemListBox
Function/S getSelectedItems()
	SVAR selWaveList = root:Packages:analysisTools:selWaveList
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	WAVE/T/Z listWave = root:Packages:analysisTools:itemListTable
	WAVE/Z selWave = root:Packages:analysisTools:itemListSelWave
	Variable i
	
	selWaveList = ""

	For(i=0;i<DimSize(listWave,0);i+=1)
		If(selWave[i] == 1)
			selWaveList += cdf + listWave[i] + ";"
		EndIf
	EndFor
	
	return selWaveList
End

//Routes to using scan list or item list or data sets for wave selection.
Function/S getWaveNames([ignoreWaveGrouping,dataset,waveset])
	Variable ignoreWaveGrouping
	String dataset
	Variable waveset
	
	//To override wave grouping for some specific functions that can't use them
	If(ParamIsDefault(ignoreWaveGrouping))
		ignoreWaveGrouping = 0
	EndIf
	
	//To specify which data set to pull from as opposed to using the drop down menu to figure it out
	//This is used in cases where multiple data sets are inputs to the function
	If(ParamIsDefault(dataset))
		dataset = ""
	EndIf	
	
	//If a specific waveset needs to be extracted
	If(ParamIsDefault(waveset))
		waveset = -1
	EndIf
	
	SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
	NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
	
	If(strlen(dataset))
		wsDims = getWaveSetDims(dataset)
		numWaveSets = ItemsInList(wsDims,";")
	EndIf

	NVAR wsn = root:Packages:analysisTools:DataSets:wsn
	Variable i
	
	ControlInfo/W=analysis_tools extFuncDS
	String theWaveList = ""
	
	//If data set is specified already
	If(strlen(dataset))
		If(ignoreWaveGrouping)
			Wave/T ds = GetDataSetWave(dsName=dataset)
			theWaveList = tableToList(ds,";")
			//Remove the wave set divisions
			String matches = ListMatch(theWaveList,"*WSN*",";")
			theWaveList = RemoveFromList(matches,theWaveList)
	
		Else
			Wave/T ds = GetDataSetWave(dsName=dataset)
			If(waveset != -1)
				wsn = waveset
			EndIf
			
			Variable pos = tableMatch("*WSN " + num2str(wsn) + "*",ds) + 1//first wave of the waveset
			If(pos == 0) //no wavesets defined, take all the waves at once
				Variable endpos = DimSize(ds,0)
			Else
				endpos = pos + str2num(StringFromList(wsn,wsDims,";")) //Last wave of the waveset
			EndIf
			
			If(numtype(endpos) == 2) //only wave of the waveset
				endpos = pos + 1
			EndIf
			
			For(i=pos;i<endpos;i+=1)
				theWaveList += ds[i] + ";"
			EndFor
		EndIf
		return theWaveList
	EndIf
	
	
	//if data set is not specified, find the waves from the drop down menu
	strswitch(S_Value)
		case "--None--":
			break
		case "--Scan List--":
			ControlInfo/W=analysis_tools extFuncChannelPop
			theWaveList = getScanListItems(V_Value)
			break
		case "--Item List--":
			theWaveList = getSelectedItems()
			break
		default:
			If(ignoreWaveGrouping)
				Wave/T ds = GetDataSetWave(dsName=S_Value)
				theWaveList = tableToList(ds,";")
				//Remove the wave set divisions
				matches = ListMatch(theWaveList,"*WSN*",";")
				theWaveList = RemoveFromList(matches,theWaveList)
		
			Else
				Wave/T ds = GetDataSetWave(dsName=S_Value)
				wsDims = getWaveSetDims(S_Value)
				numWaveSets = ItemsInList(wsDims,";")
				
				pos = tableMatch("*WSN " + num2str(wsn) + "*",ds) + 1//first wave of the waveset
				If(pos == 0) //no wavesets defined, take all the waves at once
					endpos = DimSize(ds,0)
				Else
					endpos = pos + str2num(StringFromList(wsn,wsDims,";")) //Last wave of the waveset
				EndIf
				
				If(numtype(endpos) == 2) //only wave of the waveset
					endpos = pos + 1
				EndIf
				
				For(i=pos;i<endpos;i+=1)
					theWaveList += ds[i] + ";"
				EndFor
			EndIf
			
			break
	endswitch
	return theWaveList
End

//Gets the full path wave list of the selected scans from scanList
Function/S getScanListItems(channel)
	Variable channel
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	Variable i,size
	String dataFolder,chStr,theWaveList=""
	
	dataFolder = "root:twoP_Scans:"
	size = ItemsInList(scanListStr,";")
	
	If(channel == 1)
		chStr = "ch1"
	Else
		chStr = "ch2"
	EndIf
	
	For(i=0;i<size;i+=1)
		theWaveList += dataFolder + StringFromList(i,scanListStr,";") + ":" + StringFromList(i,scanListStr,";") + "_" + chStr + ";"
	EndFor
	theWaveList = RemoveEnding(theWaveList,";")
	return theWaveList
End

//Appends selected traces from a data set to the Viewer graph
Function AppendDSWaveToViewer(selWave,itemList,dsWave,[fullPathList])
	Wave selWave
	String itemList
	Wave/T dsWave
	Variable fullPathList
	Variable i,j,k,type
	String dsWaveList = ""
	
	If(ParamIsDefault(fullPathList))
		fullPathList = 0
	EndIf
	
	
	Wave/Z/T folderTable = root:Packages:analysisTools:folderTable
	Wave selFolderWave = root:Packages:analysisTools:selFolderWave
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	String fullPath = ""
	Variable count = 0
	
	//If length of dsWave and selWave don't match, assume it need
	//to use the matchList from selected folders
	If(DimSize(selWave,0) != DimSize(dsWave,0))
		If(DimSize(folderTable,0) > 0)
			For(i=0;i<DimSize(folderTable,0);i+=1)
				String previousPath = ""
				
				If(i > DimSize(selFolderWave,0)-1)
					return -1
				EndIf
				
				If(selFolderWave[i] == 1)
					For(j=count;j<ItemsInList(itemList,";");j+=1)
						//Is the name of the next possible wave the same as the previously selected wave?
						If(cmpstr(StringFromList(j,itemList,";"),previousPath) == 0)
							continue
						EndIf
						String possiblePath = cdf + folderTable[i] + ":" + StringFromList(j,itemList,";")
						If(WaveExists($possiblePath))	//is the wave in this folder?
							fullPath += possiblePath + ";"
							previousPath = StringFromList(j,itemList,";")
							count+=1
						EndIf
					EndFor
				//fullPath +=  cdf + folderTable[i] + ":" + listWave[count] + ";"
				//count += 1
				EndIf
			EndFor
		Else
			previousPath = ""
			For(j=0;j<ItemsInList(itemList,";");j+=1)
				fullPath += cdf + StringFromList(j,itemList,";") + ";"
			EndFor
		EndIf
		
		dsWaveList = fullPath
		ElseIf(fullPathList)
			dsWaveList = itemList
		Else
			//Get the full path of the selected waves
			For(j=0;j<DimSize(selWave,0);j+=1)
				If(selWave[j] == 1)
					dsWaveList += dsWave[j] + ";"
				EndIf
			EndFor
	EndIf
	
	DoWindow/W=analysis_tools#atViewerGraph atViewerGraph
	
	//Does the window exist?
	
	If(V_flag)
		String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
		//Remove all traces
		For(i=ItemsInList(traceList)-1;i>-1;i-=1)
			RemoveFromGraph/Z/W=analysis_tools#atViewerGraph $StringFromList(i,traceList,";")
		EndFor	
		//Append selected traces
		For(i=0;i<ItemsInList(dsWaveList,";");i+=1)
			If(WaveType($StringFromList(i,dsWaveList,";"),1) == 2)
				continue //text wave
			Else
				If(WaveExists($StringFromList(i,dsWaveList,";")))
					AppendToGraph/W=analysis_tools#atViewerGraph $StringFromList(i,dsWaveList,";")
				EndIf
			EndIf
		EndFor
	EndIf
End

//If str matches an entry in the tableWave, returns the row, otherwise return -1
Function tableMatch(str,tableWave,[startp,endp,returnCol])
	String str
	Wave/T tableWave
	Variable startp,endp,returnCol//for range
	Variable i,j,size = DimSize(tableWave,0)
	Variable cols = DimSize(tableWave,1)
	
	If(cols == 0)
		cols = 1
	EndIf
	
	If(ParamIsDefault(startp))
		startp = 0
	EndIf
	
	If(ParamIsDefault(endp))
		endp = size - 1
	EndIf
	
	If(ParamIsDefault(returnCol))
		returnCol = 0
	EndIf
	
	If(startp > DimSize(tableWave,0) - 1)
		return -1
	EndIf
	
	If(endp < DimSize(tableWave,0) - 1)
		return -1
	EndIf
	
	For(j=0;j<cols;j+=1)
		For(i=startp;i<endp+1;i+=1)
			If(stringmatch(tableWave[i][j],str))
				If(returnCol)
					return j
				Else
					return i
				EndIf
			EndIf
		EndFor
	EndFor
	
	return -1
End

//Takes table, creates string list with its contents
Function/S tableToList(table,separator)
	Wave/T table
	String separator
	String list = ""
	Variable i

	For(i=0;i<DimSize(table,0);i+=1)
		list += table[i] + separator
	EndFor
	return list
End

//Takes table, creates string list with its contents
Function/WAVE listToTable(list,separator)
	String list,separator
	Make/T/FREE/N=(ItemsInList(list,separator)) table
	
	Variable i

	For(i=0;i<ItemsInList(list,separator);i+=1)
		table[i] = StringFromList(i,list,separator)
	EndFor
	return table
End

Function/S ResolveErrorCode(cmdStr)
	String cmdStr
	
	String errorCode = StringByKey("error",cmdStr,":")
	//Possible error codes
	strswitch(errorCode)
		case "dim2":
			beep
			print "Expected at least a 2D wave"
			break
		case "dim3":
			beep
			print "Expected a 3D wave"
			break
		default:
			print "Unhandled error. Check code."
			break
	endswitch
	
End

Function/S ResolveCtabStr(ctabStr,theWave)
	String ctabStr
	Wave theWave
	String leftCstr,rightCstr
	Variable leftC,rightC
	
	If(!strlen(ctabStr))
		ctabStr = "error:ctab"
		return ctabStr
	EndIf
	
	ctabStr = ReplaceString("{",ctabStr,"")
	ctabStr = ReplaceString("}",ctabStr,"")
	
	leftCstr = StringFromList(0,ctabStr,",")
	rightCstr = StringFromList(1,ctabStr,",")
	
	//autoscale tests
	If(cmpstr(leftCstr,"*") == 0)
		leftC = WaveMin(theWave)
	Else
		leftC = str2num(leftCstr)
	EndIf
	
	If(cmpstr(rightCstr,"*") == 0)
		rightC = WaveMax(theWave)
	Else
		rightC = str2num(rightCStr)
	EndIf
	
	ctabStr = ReplaceString(leftCstr,ctabStr,num2str(leftC),0,1)
	ctabStr = ReplaceString(rightCstr,ctabStr,num2str(rightC),0,1)
	return ctabStr
End

Function/S GetMaskWaveList()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	String maskList,folderPath,masksInCurrentFolder
	Variable numFolders,i,checkAllFolders,j
	Make/T/O/N=0 root:Packages:analysisTools:maskTable
	Wave/T maskTable = root:Packages:analysisTools:maskTable
	
	//Find mask waves in all scan folders?
	ControlInfo/W=analysis_tools maskAllFoldersCheck
	checkAllFolders = V_Value
	
	If(checkAllFolders)
		If(DataFolderExists("root:twoP_Scans"))
			DFREF scanPath = root:twoP_Scans
			numFolders = CountObjects("root:twoP_Scans",4)
		Else
			numFolders = 1
		EndIf
	Else
		numFolders = 1
	EndIf
	
	maskList = ""
	masksInCurrentFolder = ""
	
	For(i=0;i<numFolders;i+=1)
		If(checkAllFolders)
			folderPath = "root:twoP_Scans:" + GetIndexedObjNameDFR(scanPath,4,i)
		Else
			folderPath = "root:twoP_Scans:" + StringFromList(i,scanListStr,";")
		EndIf
		
		If(DataFolderExists(folderPath))
			SetDataFolder $folderPath
			maskList += WaveList("*mask*",";","")
			masksInCurrentFolder = WaveList("*mask*",";","")
			For(j=0;j<ItemsInList(masksInCurrentFolder,";");j+=1)
				Redimension/N=(DimSize(maskTable,0) + 1) maskTable	//add a row for new entry
				maskTable[DimSize(maskTable,0)-1] += folderPath + ":" + StringFromList(j,masksInCurrentFolder,";")
			EndFor
		Else
			maskList += ""
		EndIf
	EndFor
	
	//Add the option for none to the front of the list
	maskList = "None;" + maskList
	
	return maskList
End

Function addSelectedWaves(selWaveList)
	String selWaveList
	Variable i,xSize,ySize,zSize
	String outWaveName,suffix
	
	ControlInfo/W=analysis_tools outputSuffix
	suffix = S_Value
	
	If(!strlen(suffix))
		suffix = "sum"
	EndIf
	
	outWaveName = StringFromList(0,selWaveList,";") + "_" + suffix
	
	xSize = DimSize($StringFromList(0,selWaveList,";"),0)
	ySize = DimSize($StringFromList(0,selWaveList,";"),1)
	zSize = DimSize($StringFromList(0,selWaveList,";"),2)
	
	Make/O/N=(xSize,ySize,zSize) $outWaveName
	
	Wave outWave = $outWaveName
	outWave = 0
	
	For(i=0;i<ItemsInList(selWaveList,";");i+=1)
		Wave theWave = $StringFromList(i,selWaveList,";")
		outWave += theWave
	EndFor
	
	//Set scales
	If(xSize)
		SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),outWave
	EndIf
	If(ySize)
		SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),outWave
	EndIf
	If(zSize)
		SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),outWave
	EndIf
End

Function/S ResolveOperation(opStr,suffix[,DSwave])
	String opStr,suffix
	String DSwave
	NVAR opCounter = root:Packages:analysisTools:opCounter
	
	Variable char,op,i,numPhrases,type,index
	String theChar,newOpStr,theCommand,phrase,theWaveName
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	Variable RunCmdLine = 0
	
	//remove whitespace
	opStr = ReplaceString(" ",opStr,"")
	//number of characters
	char = strlen(opStr)
	
	strswitch(opStr)
		case "avg":
			//Averaging
			return "1"
			break
		case "sum":
			//Sum
			return "2"
			break
		case "sem":
			return "3"
			break
		case "delete":
			//kill the waves
			return "6"
			break
		case "display":
			return "7"
			break
		case "edit":
			return "8"
			break
		case "differentiate":
			return "9"
			break
		default:
			ControlInfo/W=analysis_tools useDataSetCheck
			Variable useDS = V_Value
			ControlInfo/W=analysis_tools operationOptionsPop
			If(cmpstr(S_Value,"Cmd Line") == 0)
				Variable doCmdLine = 1
			EndIf
			
			String/G root:Packages:analysisTools:opFolder
			SVAR opFolder = root:Packages:analysisTools:opFolder
			
			String DSList = GetDSInList(opStr)
			Variable numDS = ItemsInList(DSList,";")
			
			If(useDS)
				newOpStr = ""
				For(i=0;i<char;i+=1)
					theChar = opStr[i]
					
					If(doCmdLine)
						//Get the result
						Variable isResult = ItemsInList(opStr,"=")
						If(isResult == 2) //object is receiving the result of the function
							String theResult = StringFromList(0,opStr,"=")	
						
							//Get the function argument
							String theArgument = StringFromList(1,opStr,"(") //Gets the string between the parentheses of the function call
							theArgument = RemoveEnding(theArgument,")")
					
							//Get the function 
							String theFunction = StringFromList(0,opStr,"(") //Gets the function 
							theFunction = StringFromList(1,theFunction,"=") //gets rid of the result string
						Else
							theArgument = opStr	
							theResult = ""
							theFunction = ""			
						EndIf	
						
						//Resolve the result
						If(isResult == 2)
							strswitch(theResult)
								case "rw":
									//wave result
									If(opCounter == 0)//get the folder of the first wave in the data set for the output
										If(numDS == 0)
											opFolder = GetWavesDataFolder($DSwave,1)
										EndIf
									EndIf
									
									If(numDS > 0)
										String theWaveList = GetDSWaveList(dsName=StringFromList(0,DSList,";"))
										Wave/Z theWave = $StringFromList(0,theWaveList,",")
										opFolder = GetWavesDataFolder($StringFromList(0,theWaveList,","),1)
									EndIf
									
									
									If(!strlen(suffix))
										theResult = opFolder + "result"
									Else
										theResult = opFolder + suffix
									EndIf
									
									//ensure unique name for the output wave
									If(WaveExists($theResult))
										theResult = ReplaceString(suffix,theResult,UniqueName(suffix,1,0))
									EndIf
									
									
									If(numDS == 0)
										Make/O/N=(DimSize(waveListTable,0)) $theResult
										Wave outWave = $theResult
										theResult += "[" + num2str(opCounter) + "]"
									Else
										If(opCounter != -1)
											Make/O/N=(DimSize(theWave,0)) $theResult
											Wave outWave = $theResult
											SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0), outWave
											SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1), outWave
										EndIf
									EndIf
									
									break
								case "rv":
									//variable result
									break
								case "rs":
									//string result
									break
							endswitch
						EndIf
						
						//Resolve the argument
						If(cmpstr(theArgument,"w") != 0)
							If(numDS == 0)
								Variable stringPos = WhichListItem("w",theArgument,",")
								If(stringPos == -1)
									theCommand = opStr + "(" + DSwave + ")"
									Abort "Couldn't resolve the operation"
								Else
									If(stringPos == 0)
										theArgument = ReplaceString("w,",theArgument,DSwave + ",")
									ElseIf(stringPos == strlen(theArgument) - 1)
										theArgument = ReplaceString(",w",theArgument,"," + DSwave)
									Else
										theArgument = ReplaceString(",w,",theArgument,"," + DSwave + ",")
									EndIf
								EndIf
							
								If(isResult == 2)
									theCommand = theResult + "=" + theFunction + "(" + theArgument + ")"
								Else
									theCommand = theFunction + "(" + theArgument + ")"
								EndIf
							Else
								If(!strlen(theArgument))
									theArgument = theFunction//if it mistakenly was put into the function string
								EndIf
								
								If(isResult == 2)
									theCommand = theResult + "=" + InsertDSWaveNames(theArgument,opCounter)

								Else
									theCommand = InsertDSWaveNames(theArgument,opCounter)
								EndIf
							EndIf
						Else
							If(isResult == 2)
								theCommand = theResult + "=" + opStr + "(" + DSwave + ")"
							Else
								theCommand = opStr + "(" + DSwave + ")"
							EndIf
						EndIf
						return theCommand
					EndIf
					
					
					//Separate the phrases of the operation by ;
					If(cmpstr(theChar,"=") == 0 || cmpstr(theChar,"+") == 0 || cmpstr(theChar,"-") == 0 || cmpstr(theChar,"*") == 0 || cmpstr(theChar,"/") == 0 || cmpstr(theChar,"^") == 0)
						theChar = ReplaceString(theChar,theChar,";" + theChar + ";")
					EndIf
					newOpStr += theChar
				EndFor
				numPhrases = ItemsInList(newOpStr,";")
				theCommand = ""
				
				For(i=0;i<numPhrases;i+=1)
					type = mod(i,2)
					phrase = StringFromList(i,newOpStr,";")
					
					If(type == 0)
						//wave definition
						theChar = phrase[0]
						If(cmpstr(theChar,"(") == 0)
							theCommand += theChar
							phrase = phrase[1,strlen(phrase)-1]
						EndIf
						
						Variable theNum = str2num(theChar)
						//If its a number not a wave
						If(numType(theNum) != 2)
							theCommand += theChar
							continue
						EndIf
						//index = str2num(phrase[1]) - 1 //Not zero offset, starts at 1 for indexing
						
						//specific data set reference
						If(cmpstr(theChar,"<") == 0)
							theCommand += theChar
							//take out the brackets
							phrase = ReplaceString("<",phrase,"")
							phrase = ReplaceString(">",phrase,"")
							Wave/Z theWave = getDataSetWave(dsName=phrase)
							If(WaveExists(theWave))
								theCommand += NameOfWave(theWave)
							EndIf
						Else
						
						EndIf
						
						theCommand += DSwave
						
						If(cmpstr(phrase[strlen(phrase)-1],")") == 0)
							theCommand += phrase[strlen(phrase)-1]
						EndIf
					ElseIf(type == 1)
						//operator
						theCommand += phrase
					EndIf
				EndFor
				
				
				return theCommand
			Else
				//make output wave
				theWaveName = "root:twoP_Scans:" + StringFromList(index,scanListStr,";") + ":" + waveListTable[0]
				String outputWaveName = theWaveName + "_" + suffix
				Duplicate/O $theWaveName,$outputWaveName
		
				theCommand = outputWaveName + "="
				newOpStr = ""
	
				For(i=0;i<char;i+=1)
					theChar = opStr[i]
			
					//Separate the phrases of the operation by ;
					If(cmpstr(theChar,"+") == 0 || cmpstr(theChar,"-") == 0 || cmpstr(theChar,"*") == 0 || cmpstr(theChar,"/") == 0 || cmpstr(theChar,"^") == 0)
						theChar = ReplaceString(theChar,theChar,";" + theChar + ";")
					EndIf
					newOpStr += theChar
				EndFor
	
				numPhrases = ItemsInList(newOpStr,";")
				For(i=0;i<numPhrases;i+=1)
					type = mod(i,2)
					phrase = StringFromList(i,newOpStr,";")
			
					If(type == 0)
						//wave definition
						theChar = phrase[0]
						If(cmpstr(theChar,"(") == 0)
							theCommand += theChar
							phrase = phrase[1,strlen(phrase)-1]
						EndIf
						index = str2num(phrase[1]) - 1 //Not zero offset, starts at 1 for indexing
						theWaveName = "root:twoP_Scans:" + StringFromList(index,scanListStr,";") + ":" + waveListTable[index]
						theCommand += theWaveName
						If(cmpstr(phrase[strlen(phrase)-1],")") == 0)
							theCommand += phrase[strlen(phrase)-1]
						EndIf
					ElseIf(type == 1)
						//operator
						theCommand += phrase
					EndIf
				EndFor
	
				return theCommand
			EndIf
			break
	endswitch
End

Function/WAVE getWaveMatchList()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	//Full path wave list table
	Wave/T AT_WaveListTable_FullPath = root:Packages:analysisTools:AT_WaveListTable_FullPath
	
	//Relative folder path that will be added on to the current data folder
	ControlInfo/W=analysis_tools relativeFolderMatch
	String relFolder = S_Value
//	If(strlen(relFolder) > 0)
//		relFolder = ":" + relFolder
//	EndIf
	
	Variable items = ItemsInList(scanListStr,";")
	Variable i,j
	SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
	SVAR notMatchStr = root:Packages:analysisTools:waveNotMatchStr
	String itemList = ""
	String masterItemList = ""
	String currentFolder,folder
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave selWave = root:Packages:analysisTools:AT_selWave
	
	currentFolder = GetDataFolder(1)
	
	//Checks if match string has value
	If(!strlen(waveMatchStr))
		waveMatchStr = "*"
	EndIf
	
	//If we're in browser mode
	SVAR whichList = root:Packages:analysisTools:whichList
	Wave/T folderTable = root:Packages:analysisTools:folderTable
	Wave selFolderWave = root:Packages:analysisTools:selFolderWave
	
	
	//Find out the selected folders if we're in Browser mode
	If(cmpstr(whichList,"Browser") == 0)
		Variable browsing = 1
		String folderList = ""
		For(i=0;i<DimSize(folderTable,0);i+=1)
		
			//reset the subfolder and matched folder lists for each parent folder
			String subFolderList = ""	//all subfolders
			String relFolderList = "" //matched subfolders
			
			If(selFolderWave[i] == 1)
				//get list of all subfolders within the parent folder
				Variable numSubFolders = CountObjects(cdf + folderTable[i],4)
				For(j=0;j<numSubFolders;j+=1)
					subFolderList += GetIndexedObjName(cdf + folderTable[i],4,j) + ";"
				EndFor
				
				//match all subfolders
				relFolderList = ListMatch(subFolderList,relFolder,";")
				
				//append each subfolder that has matched to the folderList
				If(ItemsInList(relFolderList,";") > 0)
					For(j=0;j<ItemsInList(relFolderList,";");j+=1)
						String matchedSubFolder = ":" + StringFromList(j,relFolderList,";")
						folderList +=  cdf + folderTable[i] + matchedSubFolder + ";"
					EndFor
				Else
					folderList +=  cdf + folderTable[i] + ";"
				EndIf
			EndIf
		EndFor
		items = ItemsInList(folderList,";")
	Else
		browsing = 0
	EndIf	
	
	//Fill out the wave match list box for each scan folder
	If(items == 0)
		items = 1
	EndIf
	
	Variable count = 0
	
	For(i=0;i<items;i+=1)
		If(browsing)
			If(!strlen(folderList))
				folder = cdf
			Else
				folder = StringFromList(i,folderList,";") + ":"
			EndIf
		Else
			folder = "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":"
		EndIf
	
		If(DataFolderExists(folder))
			SetDataFolder $folder
		Else
			continue
		EndIf
		
		//Are there any OR statements in the match string?
		Variable numORs
		numORs = ItemsInList(waveMatchStr,"||")
		
		//Match list
		itemList = ReplaceString(";",StringFromList(1,DataFolderDir(2),":"),"")
		itemList = TrimString(itemList)
		String item,fullPathItemList
		
		String tempList = ""
		//Match each OR element in the match string separately 
		For(j=0;j<numORs;j+=1)
			String matchStr = StringFromList(j,waveMatchStr,"||")
			tempList += ListMatch(itemList,matchStr,",")
		EndFor
		itemList = SortList(tempList,",",16)
		
		itemList = RemoveDuplicateList(itemList,";")
		
		//Not match list
		numORs = ItemsInList(notMatchStr,"||")
		For(j=0;j<numORs;j+=1)
			If(strlen(notMatchStr))
				matchStr = StringFromList(j,notMatchStr,"||")
				itemList = ListMatch(itemList,"!*" + matchStr,",")
			EndIf
		EndFor
		masterItemList += itemList
		
		Redimension/N=(ItemsInList(masterItemList,",")) AT_WaveListTable_FullPath
		For(j=0;j<ItemsInList(itemList,",");j+=1)
			item = StringFromList(j,itemList,",")
			AT_WaveListTable_FullPath[count] = folder + item
			count += 1
		EndFor
	EndFor
	
	Redimension/N=(ItemsInList(masterItemList,",")) waveListTable,selWave
	
	For(i=0;i<ItemsInList(masterItemList,",");i+=1)
		waveListTable[i] = StringFromList(i,masterItemList,",")		
	EndFor
	
	return waveListTable
End

//Takes a list of items, and removes all the duplicate items
Function/S RemoveDuplicateList(theList,separator)
	String theList,separator
	Variable i,j,size,checkpt
	String item
	
	checkpt = -1
	size = ItemsInList(theList,separator)
	For(i=0;i<size;i+=1)
		item = StringFromList(i,theList,separator)
		For(j=0;j<size;j+=1)
			//Skip the item being tested so it isn't flagged as a duplicate
			If(j == i)
				continue
			EndIf
			//Duplicate found
			If(cmpstr(item,StringFromList(j,theList,separator)) == 0)
				theList = RemoveListItem(j,theList,separator)
				size = ItemsInList(theList,separator)
				//restarts the loop
				i = checkpt	
				break
			ElseIf(j == size - 1) //no duplicates found for that item
				checkpt += 1
			EndIf
		EndFor
	EndFor
	return theList
End

Function updateWaveListBox()
	//Refresh the wave list box for the new wave grouping
	Wave/T ds = GetDataSetWave()
	
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave matchListselWave = root:Packages:analysisTools:AT_selWave
	Redimension/N=(DimSize(ds,0)) waveListTable,matchListselWave
	Variable i
	For(i=0;i<DimSize(ds,0);i+=1)
		waveListTable[i] = ParseFilePath(0,ds[i],":",1,0)
	EndFor
	ControlUpdate/W=analysis_tools	 matchListBox

End

Function applyFilters(theWave)
	Wave theWave
	theWave = (theWave == inf) ? nan : theWave
	theWave = (theWave == 0) ? nan : theWave
	theWave = (theWave > 10 || theWave < -10) ? nan : theWave
	//theWave = (theWave < 0) ? 
//	MatrixFilter/N=7 median theWave
End


Function FillDMatrix(distanceWave,startROI)
	Wave/T distanceWave//,filterTable
	String startROI
	
	Wave/T roiTable = root:roiTable
	Wave dMatrix = root:ROI_dist_matrix
		
	Variable numROIs = DimSize(roiTable,0)
	Variable i,j,length,row,col
	String ROIList = ""
	
	//Make list for the ROI table
	For(i=0;i<numROIs;i+=1)
		ROIList += roiTable[i] + ";"
	EndFor
	
	//waves holding the actual center point for all ROIs
	Wave ROIx = root:twoP_ROIS:ROIx
	Wave ROIy = root:twoP_ROIS:ROIy
	
	ROIList = RemoveEnding(ROIList,";")
		
	length = DimSize(distanceWave,0)
	
	For(i=0;i<length;i+=1)
		
		For(j=0;j<length;j+=1)
		
			row = WhichListItem(distanceWave[i][0],ROIList,";")	//start ROI
			col = WhichListItem(distanceWave[j][0],ROIList,";")	//end ROI

			If(row == -1 || col == -1)
				continue
			Else
				dMatrix[row][col] = abs(str2num(distanceWave[j][1]) - str2num(distanceWave[i][1])) //Fill out matrix
				dMatrix[col][row] = abs(str2num(distanceWave[j][1]) - str2num(distanceWave[i][1])) //and reciprocal matrix cell
			EndIf
		EndFor
	EndFor
	
End

Function fillROITable(roiTable)
	Wave/Z/T roiTable
	SetDataFolder root:
		
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	Variable size = ItemsInList(ROIListStr,";")
	
	If(!WaveExists(roiTable))
		Make/O/T/N=(size) roiTable
		Wave/T roiTable = roiTable
	Else
		Redimension/N=(size) roiTable
	EndIf
	
	Variable i
	For(i=0;i<size;i+=1)
		roiTable[i] = StringFromList(i,ROIListStr,";")
	EndFor
End

//Get the name of the nearest ROI from the mouse position
Function/S getMouseROI(theWindow,scanWave,roiTable,ROIx,ROIy)
	String theWindow
	Wave scanWave
	Wave/T roiTable
	Wave ROIx,ROIy
	Variable xPos,yPos,distance,i,minDist
	String theROI
	
	minDist = 0
	
	If(cmpstr(theWindow,"twoPscanGraph") == 0)
		theWindow += "#GCH2"
	EndIf
	
	getCenter(roiTable,"root:twoP_ROIS")
	
	GetMouse/W=$theWindow
	xPos = AxisValFromPixel(theWindow,"Bottom",V_left)
	yPos = AxisValFromPixel(theWindow,"Left",V_top)
	
	//Index values for the mouse position
	Variable xIndex = ScaleToIndex(scanWave,xPos,0)
	Variable yIndex = ScaleToIndex(scanWave,yPos,1)
	
	For(i=0;i<NumPnts(roiTable);i+=1)
		//ROI mask wave
		Wave roiXboundary = $("root:twoP_ROIS:" + roiTable[i] + "_x")
		Wave roiYboundary = $("root:twoP_ROIS:" + roiTable[i] + "_y")
		ImageBoundaryToMask ywave=roiYboundary,xwave=roiXboundary,width=(dimSize(scanWave,0)),height=(dimSize(scanWave,1)),scalingwave=scanWave,seedx=dimOffset(scanWave,0),seedy=dimOffset(scanWave,1)
		String foldername = GetDataFolder(1)
		WAVE ROIMask = $(foldername + "M_ROIMask")	

		If(ROIMask[xIndex][yIndex] == 0)
			theROI = roiTable[i]
		EndIf
	EndFor
	
//	For(i=0;i<NumPnts(roiTable);i+=1)
//		distance = sqrt((ROIy[i] - yPos)^2 + (ROIx[i] - xPos)^2)
//		If(minDist == 0)
//			minDist = distance
//		ElseIf(distance < minDist)
//			minDist = distance
//			theROI = roiTable[i]  
//		EndIf
//	EndFor
	If(strlen(theROI))
		return theROI
	Else
		return ""
	EndIf
End

//Gets list of line profile waves
Function/S getSavedLineProfileList()	
	String folder = "root:var:LineProfiles"
	String profileList
	String saveDF = GetDataFolder(1)
	
	
	If(!varFolderExists())
		NewDataFolder root:var
	EndIf
	
	If(!DataFolderExists(folder))
		NewDataFolder $folder
	EndIf
	SetDatafolder $folder 
	
	If(!DataFolderExists(folder))
		profileList = "None"
	Else
		profileList = WaveList("LineProfileY*",";","")
	EndIf
	
	If(!strlen(profileList))
		profileList = "None"
	EndIf
	SetDataFolder $saveDF
	return profileList
End

Function varFolderExists()
	If(DataFolderExists("root:var"))
		return 1
	Else
		return 0
	EndIf
End

//Saves line profile waves as template
Function saveLineProfile()

	String saveDF = GetDataFolder(1)
	String folder = "root:var:LineProfiles"
	If(!DataFolderExists(folder))
		NewDataFolder $folder
	EndIf
	SetDatafolder $folder
	
	Wave xProfile = root:var:xWave
	Wave yProfile = root:var:yWave
	Wave dProfile = root:var:W_LineProfileDisplacement
	
	If(WaveExists(root:var:xWave))
		Wave xProfile = root:var:xWave
	Else
		Abort "Profile wave does not exist"
	EndIf
	
	If(WaveExists(root:var:yWave))
		Wave yProfile = root:var:yWave
	Else
		Abort "Profile wave does not exist"
	EndIf
	
	//Get output names for the saved line profiles
	String xName,yName,dName
	ControlInfo/W=analysis_tools saveLineProfileSuffix
	If(!strlen(S_Value))
		xName = UniqueName("LineProfileX_",1,0)
		yName = ReplaceString("LineProfileX",xName,"LineProfileY")
		dName = ReplaceString("LineProfileD",xName,"LineProfileD")
	Else
		xName = "LineProfileX_" + S_Value
		yName = "LineProfileY_" + S_Value
		dName = "LineProfileD_" + S_Value
	EndIf
	
	//Move and rename the profile waves
	If(WaveExists($(folder + ":" + xName)))
		KillWaves/Z $(folder + ":" + xName)
		KillWaves/Z $(folder + ":" + yName)
		KillWaves/Z $(folder + ":" + dName)
	EndIf
	
	MoveWave xProfile,$(folder + ":" + xName)
	MoveWave yProfile,$(folder + ":" + yName)
	MoveWave dProfile,$(folder + ":" + dName)
	
	SetDataFolder $saveDF
//	String profileList = getSavedProfileList()
	PopUpMenu lineProfileTemplatePopUp win=analysis_tools,value=getSavedLineProfileList()
	ControlUpdate/W=analysis_tools lineProfileTemplatePopUp
	
	ControlInfo/W=analysis_tools SR_waveList
	AppendToGraph/W=$S_Value $(folder + ":" + yName) vs $(folder + ":" + xName)
End

Function applyLineProfile()
	String saveDF = GetDataFolder(1)
	Variable i,j,version,ch1,ch2,numChannels,frames
	String lineProfileName,displacementProfileName,channel,outputProfileName
	
	//Get Igor version
	version = floor(IgorVersion())
	
	//Get channels
	ControlInfo/W=analysis_tools ch1Check
	ch1 = V_Value
	ControlInfo/W=analysis_tools ch2Check
	ch2 = V_Value
	
	If(ch1 && ch2)
		numChannels = 2
	ElseIf(ch1 || ch2)
		numChannels = 1
	EndIf
	
	//Get line profile width
	ControlInfo/W=analysis_tools lineProfileWidth
	Variable width = V_Value
	
	//Get line profile waves
	ControlInfo/W=analysis_tools lineProfileTemplatePopUp
	String profileSuffix = StringFromList(1,S_Value,"_")
	String yProfileName = S_Value
	String xProfileName = ReplaceString("LineProfileY",yProfileName,"LineProfileX")
	Wave xProfile = $("root:var:LineProfiles:" + xProfileName)
	Wave yProfile = $("root:var:LineProfiles:" + yProfileName)
	
	ControlInfo/W=analysis_tools useScanListCheck
	If(V_Value)
	//Use Scan List
		SVAR scanListStr = root:Packages:twoP:examine:scanListStr
		For(i=0;i<ItemsInList(scanListStr,";");i+=1)
			For(j=0;j<numChannels;j+=1)
				If(numChannels == 1 && ch1)
					channel = "ch1"
				ElseIf(numChannels == 1 && ch2)
					channel = "ch2"
				ElseIf(numChannels == 2)
					channel = "ch" + num2str(j + 1)
				EndIf
				
				Wave theWave = $("root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + StringFromList(i,scanListStr,";") + "_" + channel)
				SetDataFolder GetWavesDataFolder(theWave,1)
				
				//Get baseline profile for ∆F/F
				ControlInfo/W=analysis_tools dFLineProfileCheck
				Variable doDF = V_Value
				
				If(doDF)
					Variable baselineStart,baselineEnd,baselineStartPt,baselineEndPt

					ControlInfo/W=analysis_tools bslnStVar
					baselineStartPt = V_Value
					baselineStart = ScaleToIndex(theWave,V_Value,2)
					ControlInfo/W=analysis_tools bslnEndVar
					baselineEndPt = V_Value
					baselineEnd = ScaleToIndex(theWave,V_Value,2)
					
					//Get the baseline portion of the scan
					Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1),baselineEnd-baselineStart) baselineScan
					baselineScan = theWave[p][q][baselineStart + r]
					//Set Scales
					SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),baselineScan
					SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),baselineScan
					SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),baselineScan
					
					//Set data folder to the waves folder
					SetDataFolder GetWavesDataFolder(theWave,1)
					
					//line profile the baseline scan
					ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=baselineScan,width=width
					frames = DimSize(theWave,2)
					If(frames)
						Wave baselineProfile = M_ImageLineProfile
						Duplicate/O baselineProfile,M_ImageBaselineProfile
						KillWaves/Z baselineProfile
						Wave baselineProfile = M_ImageBaselineProfile
					Else
						Wave baselineProfile = W_ImageLineProfile
						Duplicate/O baselineProfile,W_ImageBaselineProfile
						KillWaves/Z baselineProfile
						Wave baselineProfile = W_ImageBaselineProfile
					EndIf
					
					//Collapse if selected to mean baseline
					SetScale/I y,baselineStartPt,baselineEndPt,baselineProfile
					collapseLineProfile(baselineProfile,theWave,"avg")
					
					
				EndIf
				
				
				ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=theWave,width=width
				
				//Rename the displacement wave for Igor 8
				If(version > 7)
					displacementProfileName = NameOfWave(theWave) + "_LP" + profileSuffix + "_disp"
					
					//Wave lineProfileDisp = $("root:var:LineProfiles:LineProfileD_" + StringFromList(1,profileSuffix,"_"))
					
					//Rename displacement profile wave for Igor 8
					If(WaveExists($(GetDataFolder(1) + "W_LineProfileDisplacement")))
						Wave lineProfileDisp = $(GetDataFolder(1) + "W_LineProfileDisplacement")
						Duplicate/O lineProfileDisp,$displacementProfileName
						KillWaves/Z lineProfileDisp
					EndIf
				EndIf
			
				//Different output wave names depending on 2D or 3D profile
				frames = DimSize(theWave,2)
				If(frames)
					outputProfileName = GetDataFolder(1) + "M_ImageLineProfile"
				Else
					outputProfileName = GetDataFolder(1) + "W_ImageLineProfile"
				EndIf
				
				String suffix = StringFromList(ItemsInList(yProfileName,"_")-1,yProfileName,"_")
				//Rename line profile wave
				lineProfileName = NameOfWave(theWave) + "_LP" + suffix
				
				
				
				String type = "pk" //"pk"
				
				If(doDF)
					lineProfileName += "_dF_" + type
				EndIf
				
				If(WaveExists($outputProfileName))
					Wave lineProfile = $outputProfileName
					Duplicate/O lineProfile,$lineProfileName
					KillWaves/Z lineProfile
				EndIf	
				
				wave theProfile = $lineProfileName
				
				//Smooth the profile before collapsing
				ControlInfo/W=analysis_tools SmoothBox
				If(V_Value)
					ControlInfo/W=analysis_tools SmoothFilterVar
					If(DimSize(theProfile,1) > 0 && V_Value != 0)
					//	Smooth/S=2/DIM=0 5,theProfile
						Smooth/S=2/DIM=1 V_Value,theProfile
					Else
					//	Smooth/S=2 V_Value,theProfile
					EndIf
				EndIf
				
				//Collapse 2D profile to 1D max projection
				ControlInfo/W=analysis_tools collapseLineProfileCheck
				If(V_Value && frames)
					ControlInfo/W=analysis_tools peakStVar
					Variable start = V_Value
					ControlInfo/W=analysis_tools peakEndVar
					Variable stop = V_Value
					SetScale/P y,DimOffset(theWave,2),DimDelta(theWave,2),theProfile
					collapseLineProfile(theProfile,theWave,"max",start=start,stop=stop)
				EndIf
				
				//∆F/F profile
				If(doDF)
					theProfile = (theProfile - baselineProfile)/baselineProfile
					//String dFProfileName = NameOfWave(theProfile) + "_dF"
					//Duplicate/O theProfile,$dFProfileName
					//KillWaves/Z theProfile,baselineProfile
				//	Wave theProfile = $dFProfileName
				EndIf
				
			EndFor
		EndFor
	Else
	//Use top graph
		//Bring selected graph to the front
		ControlInfo/W=analysis_tools SR_WaveList
		DoWindow/F $S_Value
		
		//If 2P Scan Graph, get the actual scan wave instead of the layer projection
		
		If(cmpstr(S_Value,"twoPscanGraph") == 0)
			NVAR curScanNum = root:Packages:twoP:examine:curScanNum
			String scanNumStr
			If(curScanNum < 10)
				scanNumStr = "00" + num2str(curScanNum)
			ElseIf(curScanNum < 100)
				scanNumStr = "0" + num2str(curScanNum)
			Else
				scanNumStr = num2str(curScanNum)
			EndIf
		
		
			ControlInfo/W=analysis_tools ch1Check
			ch1 = V_Value
			If(ch1)
				channel = "ch1"
			EndIf
		
			ControlInfo/W=analysis_tools ch2Check
			ch2 = V_Value
			If(ch2)
				channel = "ch2"
			EndIf
		
			If(!ch1 && !ch2)
				Abort "Since this is from twoPscanGraph, you have to select a channel."
			EndIf
		
			If(ch1 && ch2)
				Abort "Since this is from twoPscanGraph, you can only select a single channel at a time."
			EndIf
		
			String scanName = "root:twoP_Scans:Scan_" + scanNumStr + ":Scan_" + scanNumStr + "_" + channel
			If(WaveExists($scanName))
				Wave theWave = $scanName
			EndIf
		Else
			//Get wave name from selected graph
			GetWindow/Z kwTopWin wavelist
			Wave/T WavesOnGraph = W_WaveList
			Wave theWave = $WavesOnGraph[0][1]
		EndIf
		
		SetDataFolder GetWavesDataFolder(theWave,1)
		
		//Get baseline profile for ∆F/F
		ControlInfo/W=analysis_tools dFLineProfileCheck
		doDF = V_Value
		If(doDF)

			ControlInfo/W=analysis_tools bslnStVar
			baselineStart = ScaleToIndex(theWave,V_Value,2)
			ControlInfo/W=analysis_tools bslnEndVar
			baselineEnd = ScaleToIndex(theWave,V_Value,2)
					
			//Get the baseline portion of the scan
			Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1),baselineEnd-baselineStart) baselineScan
			baselineScan = theWave[p][q][baselineStart + r]
			
			//Set Scales
			SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),baselineScan
			SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),baselineScan
			SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),baselineScan
			
			//Set data folder to the waves folder
			SetDataFolder GetWavesDataFolder(theWave,1)
					
			//line profile the baseline scan
			ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=baselineScan,width=width
			
			frames = DimSize(theWave,2)		
			If(frames)
				Wave baselineProfile = M_ImageLineProfile
				Duplicate/O baselineProfile,M_ImageBaselineProfile
				KillWaves/Z baselineProfile
				Wave baselineProfile = M_ImageBaselineProfile
			Else
				Wave baselineProfile = W_ImageLineProfile
				Duplicate/O baselineProfile,W_ImageBaselineProfile
				KillWaves/Z baselineProfile
				Wave baselineProfile = W_ImageBaselineProfile
			EndIf
			
			//Smooth/S=2/DIM=1 13,baselineProfile
					
			//Collapse to mean baseline
			collapseLineProfile(baselineProfile,theWave,"avg")
		EndIf

		ImageLineProfile/SC/P=-2 xWave=xProfile,yWave=yProfile,srcWave=theWave,width=width
		
		//Rename line profile
		lineProfileName = NameOfWave(theWave) + "_LP"
			
		If(version > 7)
			displacementProfileName = NameOfWave(theWave) + "_LD"
			
			If(doDF)
				displacementProfileName += "_dF"
			EndIf	
			
			//Rename displacement profile wave for Igor 8
			If(WaveExists($(GetDataFolder(1) + "W_LineProfileDisplacement")))
				Wave lineProfileDisp = $(GetDataFolder(1) + "W_LineProfileDisplacement")
				Duplicate/O lineProfileDisp,$displacementProfileName
				KillWaves/Z lineProfileDisp
			EndIf
		EndIf
			
		//Different output wave names depending on 2D or 3D profile
		frames = DimSize(theWave,2)
		If(frames)
			outputProfileName = GetDataFolder(1) + "M_ImageLineProfile"
		Else
			outputProfileName = GetDataFolder(1) + "W_ImageLineProfile"
		EndIf
				
		//Rename line profile wave
		lineProfileName = NameOfWave(theWave) + "_LP"
				
		type = "pk"
				
		If(doDF)
			lineProfileName += "_dF_" + type 
		EndIf
				
		If(WaveExists($outputProfileName))
			Wave lineProfile = $outputProfileName
			Duplicate/O lineProfile,$lineProfileName
			KillWaves/Z lineProfile
		EndIf	
		
		wave theProfile = $lineProfileName
		
		
		//Smooth the profile before collapsing
		ControlInfo/W=analysis_tools SmoothBox
		If(V_Value)
			ControlInfo/W=analysis_tools SmoothFilterVar
			If(DimSize(theProfile,1) > 0 && V_Value != 0)
				Smooth/S=2/DIM=1 V_Value,theProfile
			ElseIf(V_Value != 0)
				//Smooth/S=2 V_Value,theProfile
			EndIf
		EndIf
		
		//Collapse 2D profile to 1D max projection
		ControlInfo/W=analysis_tools collapseLineProfileCheck
		If(V_Value && frames)
			ControlInfo/W=analysis_tools peakStVar
			start = V_Value
			ControlInfo/W=analysis_tools peakEndVar
			stop = V_Value
			collapseLineProfile(theProfile,theWave,"max",start=start,stop=stop)
		EndIf
				
		//∆F/F profile
		If(doDF)
			theProfile = (theProfile - baselineProfile[p][0])/baselineProfile[p][0]
			//String dFProfileName = NameOfWave(theProfile) + "_dF"
			//Duplicate/O theProfile,$dFProfileName
			//KillWaves/Z theProfile,baselineProfile
			//	Wave theProfile = $dFProfileName
		EndIf
		
		KillWaves/Z WavesOnGraph	
		
	EndIf
End

Function collapseLineProfile(theProfile,theWave,type,[start,stop])
	wave theProfile
	wave theWave
	String type
	Variable start,stop
	Variable i
	
	Make/FREE/N=(DimSize(theProfile,1)) theCol
	
	If(ParamIsDefault(start))
		start = 0
	EndIf
	
	If(ParamIsDefault(stop))
		stop = DimSize(theProfile,0)
	EndIf
	
	For(i=0;i<DimSize(theProfile,0);i+=1)
		theCol[] = theProfile[i][p]
		SetScale/P x,DimOffset(theProfile,1),DimDelta(theProfile,1),theCol
		If(cmpstr(type,"max") == 0)
			WaveStats/Q/R=(start,stop) theCol
			//theProfile[i] = mean(theCol,V_maxLoc - 0.05,V_maxLoc + 0.05)
			theProfile[i] = V_max
		ElseIf(cmpstr(type,"avg") == 0)
			theProfile[i] = median(theCol)
		ElseIf(cmpstr(type,"area") == 0)
			theProfile[i] = area(theCol,start,stop)
		
		EndIf
	EndFor
	
	//MatrixOP/FREE maxProj = maxRows(theProfile) 
	Redimension/N=(0-1,0) theProfile
	//theProfile = maxProj
End

//Segments an ROI mask into specified sized sub-ROIs
Function OpenMask(theMask)
	Wave theMask
	NewImage/N=ROI_Image theMask
End

//
Function SegmentROIMap()
	
	//size of each ROI segment
	Variable pixelsPerSegment = 30
	
	Variable xPoint = hcsr(A,"ROI_Image")
	Variable yPoint = vcsr(A,"ROI_Image")

End


//Actually this just acquires the parameters needed to register an image.
//Use this function to register a max projection of the channel of interest.
//Then select the created parameter wave in the tempate list, and apply the template to...
//other test images or scans from the scan list box.

Function GetRegistrationParameters()
	Variable offsetX,offsetY,dX,dY,useScanList,i,j
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	//Get the channel
	//String channel = RemoveEnding(getChannel(1),";")
	
	//Reference channel
	ControlInfo/W=analysis_tools refImageChMenu
	String refCh = S_Value
	
	//Test channel
	ControlInfo/W=analysis_tools testImageChMenu
	String testCh = S_Value
	
	//Get the reference image	
	ControlInfo/W=analysis_tools refImagePopUp
	Wave refImage = $("root:twoP_Scans:" + S_Value + ":" + S_Value + "_" + refCh)
		
	//Get the reference image offsets and deltas
	offsetX = DimOffset(refImage,0)
	offsetY = DimOffset(refImage,1)
	dX = DimDelta(refImage,0)
	dY = DimDelta(refImage,1)
	
	If(!DataFolderExists("root:Packages:analysisTools:Registration"))
		NewDataFolder root:Packages:analysisTools:Registration
	EndIf
	
	//Kill all waves in the Registration data folder
	SetDataFolder root:Packages:analysisTools:Registration
	String theList = WaveList("*",";","")
	Variable numWaves = ItemsInList(theList,";")
	
	For(i=0;i<numWaves;i+=1)
		String item = StringFromList(i,theList,";")
		Wave theWave = $item
		KillWaves/Z theWave
	EndFor
	
	
	//Max project the reference wave. This will be the wave actually operated on
	//to get the regstration parameters.
	MatrixOP/O/FREE refMaxProj = sumBeams(refImage)
	SetScale/P x,offsetX,dX,refMaxProj
	SetScale/P y,offsetY,dY,refMaxProj
	Redimension/S refMaxProj

	ControlInfo/W=analysis_tools useScanListCheck
	useScanList = V_Value
	
	//If(useScanList)
		String testImageList = scanListStr
//	Else
//		ControlInfo/W=analysis_tools testImagePopUp
//		testImageList = S_Value
//	EndIf
	
	//Get marquee for potential mask ROI
	String graphList = StringFromList(0,WinList("*",";","WIN:1"),";")
	If(!cmpstr(graphList,"twoPscanGraph"))
		String children = ChildWindowList(graphList)
		graphList += "#" + StringFromList(0,children,";")
	EndIf
	
	String axis = AxisList(graphList)
	GetMarquee/Z/W=$StringFromList(0,graphList,";") $StringFromList(0,axis,";"),$StringFromList(1,axis,";")
	
	Make/FREE/O/N=5 roiWaveX,roiWaveY
	roiWaveX[0] = V_right
	roiWaveX[1] = V_right
	roiWaveX[2] = V_left
	roiWaveX[3] = V_left
	roiWaveX[4] = V_right
	
	roiWaveY[0] = V_top
	roiWaveY[1] = V_bottom
	roiWaveY[2] = V_bottom
	roiWaveY[3] = V_top
	roiWaveY[4] = V_top
	
	SetDataFolder root:
	
	//ROI mask seed values
	Variable maskMax,maskMin,xSeed,ySeed
	WaveStats/Q refImage
	
	maskMin = WaveMin(roiWaveX)
	maskMax = WaveMax(roiWaveX)
	
	xSeed = maskMax + DimDelta(refImage,0)
	If(xSeed > IndexToScale(refImage,DimSize(refImage,0)-1,0))
		xSeed = IndexToScale(refImage,0,0)
	EndIf
	
	maskMin = WaveMin(roiWaveY)
	maskMax = WaveMax(roiWaveY)
	
	ySeed = maskMax + DimDelta(refImage,1)
	If(ySeed > IndexToScale(refImage,DimSize(refImage,1)-1,1))
		ySeed = IndexToScale(refImage,0,1)
	EndIf
	
	ImageBoundaryToMask width=DimSize(refImage,0),height=DimSize(refImage,1),xwave=roiWaveX,ywave=roiWaveY,scalingwave=refImage,seedx=xSeed,seedy=ySeed
	Wave refMask = root:M_ROIMask	
	Duplicate/FREE refMask,testMask
	
	//Register the images
	strswitch(testCh)
		case "ch1":
		case "ch2":
			break
		case "Both":
			//make sure first channel of test wave is the same as the reference wave
			If(!cmpstr(refCh,"ch1"))
				testCh = "ch1;ch2"
			ElseIf(!cmpstr(refCh,"ch2"))
				testCh = "ch2;ch1"
			EndIf
			break
	endswitch
	
	String channel = StringFromList(0,testCh,";") //only do registration on the first channel in list, apply those parameters to the second channel in list.
		
	//loop through the selection in the scan list
	For(i=0;i<ItemsInList(testImageList,";");i+=1)
		
		//Get the registration parameters
		String theWaveName = StringFromList(i,testImageList,";")
		Wave testImage = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + channel)
		
		Duplicate/O testImage,$("root:Packages:analysisTools:Registration:" + NameOfWave(testImage))
		
		//Max project the test wave
		MatrixOP/O/FREE testMaxProj = sumBeams(testImage)
		SetScale/P x,offsetX,dX,testMaxProj
		SetScale/P y,offsetY,dY,testMaxProj
		Redimension/S testMaxProj,testMask,refMask
		
		SetDataFolder GetWavesDataFolder(testImage,1)
		ImageRegistration/REFM=0/TSTM=0/TRNS={1,1,0}/CONV=1/Q testMask=testMask,refMask=refMask,testWave=testMaxProj,refWave=refMaxProj
		Wave param = W_RegParams
		If(!WaveExists(param))
			Abort "Cannot find the registration parameter wave."
		Else
			Redimension/N=7 param
			param[3] = offsetX;SetDimLabel 0,3,'X Offset',param
			param[4] = offsetY;SetDimLabel 0,4,'Y Offset',param
			param[5] = dX;SetDimLabel 0,5,dX,param
			param[6] = dY;SetDimLabel 0,6,dY,param
		EndIf
		
		Variable xDelta,yDelta,applyOffsetX,applyOffsetY
		//Apply the registration parameters
		xDelta = round(param[0])
		yDelta = round(param[1])
		
		KillWaves/Z param //clean up
		
		Variable theMean = mean(testImage) //this value will be added with noise to blank pixels that are added from registration.
		
		//loop through all the test channels to be registered using these the calculated registration parameters
		For(j=0;j<ItemsInList(testCh,";");j+=1)
			Wave testImage = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + StringFromList(j,testCh,";"))
			
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
		
		EndFor
	EndFor
	
	Wave regWave = M_RegMaskOut
	KillWaves/Z regWave
	Wave regWave = M_RegOut
	KillWaves/Z regWave
End


//Undo for image registration. This only works for the most recent registration command.
//Originals are held in root:Packages:analysisTools:Registration
Function undoRegistration()
	SetDataFolder root:Packages:analysisTools:Registration
	String theList = WaveList("*",";","")
	Variable i,numWaves = ItemsInList(theList,";")
	
	For(i=0;i<numWaves;i+=1)
		String item = StringFromList(i,theList,";")
		Wave theWave = $item
		
		String folder = RemoveEnding(ParseFilePath(1,item,"_",1,0),"_")
		String fullPath = "root:twoP_Scans:" + folder + ":" + item
		Duplicate/O theWave,$fullPath	//overwrite wave in the scan folder
		KillWaves/Z theWave
	EndFor
End

//Returns the name of the checked channel
//Only allows a single channel to be checked at once.
Function/S getChannel(onlyOne)
	Variable onlyOne
	
	ControlInfo/W=analysis_tools ch1check
	If(V_Value)
		String channel="ch1;"
	Else
		channel = ""
	EndIf
	
	ControlInfo/W=analysis_tools ch2check

	If(cmpstr(channel,"ch1;") == 0 && V_Value == 1)
		If(onlyOne)
			Abort "Only select a single channel"
		Else
			channel += "ch2;"
		EndIf
	ElseIf(V_Value)
		channel = "ch2;"
	EndIf
	
	ControlInfo/W=analysis_tools ratioCheck
	If(V_Value)
		If(stringmatch(channel,"*ch1*") || stringmatch(channel,"*ch2*"))
			If(onlyOne)
				Abort "Only select a single channel"
			Else
				channel += "ratio"
			EndIf
		Else
			channel = "ratio"
		EndIf
	EndIf
	
	If(!strlen(channel))
		Abort "Must select a channel"
	EndIf

	return channel
End

//Gets a list of waves inside the twoP_Scans folder and all of its subfolders
Function/S getWaveList(matchStr)
	String matchStr
	String theList,theFolder,saveDF,listItem
	theList = ""
	
	saveDF = GetDataFolder(1)
	
	Variable numFolders = CountObjects("root:twoP_Scans",4)
	Variable i
	
	For(i=0;i<numFolders;i+=1)
		theFolder = GetIndexedObjName("root:twoP_Scans",4,i)
		SetDataFolder $("root:twoP_Scans:" + theFolder)
		listItem = WaveList(matchStr,";","")
		If(strlen(listItem))
			theList += theFolder + ":" + listItem + ";"
		EndIf
	EndFor
	
	return theList
End

//Puts a defined value onto an image wave in the specified location.
//This will allow me to check whether the wave has been tagged or not
//during analysis.
Function TagWave(theWave,startRow,startCol,numRows,tagValue)
	Wave theWave
	Variable startRow,startCol,numRows,tagValue
	Variable i
	
	For(i=0;i<numRows;i+=1)
		theWave[startRow + i][startCol] = tagValue
	EndFor
End

//Checks if a wave has been tagged in the specified location with..
//the tagValue
Function CheckTag(theWave,startRow,startCol,numRows,tagValue)
	Wave theWave
	Variable startRow,startCol,numRows,tagValue
	Variable i,tagPresent
	
	For(i=0;i<numRows;i+=1)
		If(theWave[startRow + i][startCol] == tagValue)
			tagPresent = 1
		Else
			tagPresent = 0
		EndIf
	EndFor
	return tagPresent
End

//Goes through a wave set and finds the offsets incurred from image registration.
//Then it redimensions all the waves to eliminate rows/cols that have been created as buffers during image registration. 
Function EqualizeDimensions()
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	
	Variable minX,maxX,minY,maxY,i,j,buffer,row,col,sizeX,sizeY
	
	String channel = getChannel(0)
	
	For(j=0;j<ItemsInList(channel,";");j+=1)
		//Set the initial dimensions of the images using the first wave in the wave set
		String currentChannel = StringFromList(j,channel,";")
		String theWaveName = StringFromList(0,scanListStr,";") 
		Wave theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + currentChannel)
		
		minX = 0
		minY = 0
		sizeX = DimSize(theWave,0) - 1
		sizeY = DimSize(theWave,1) - 1
		maxX = sizeX
		maxY = sizeY
			
		For(i=0;i<ItemsInList(scanListStr,";");i+=1)
			//Get the channel and the image wave
			currentChannel = StringFromList(j,channel,";")
			theWaveName = StringFromList(i,scanListStr,";") 
			Wave theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + currentChannel)
		
			//check if wave exists
			If(!WaveExists(theWave))
				Abort "Couldn't find the wave: " + NameOfWave(theWave)
			EndIf
	
			//check row buffers at beginning of image
			row = 0
			col = 0
			Do
				//checks the value at each row 15 columns in, to prevent false positives from buffered columns 
				buffer = theWave[row][15]
				row += 1
			While(buffer == 0)
			
			If(row > minX)
				minX = row - 1
			EndIf
			
			//check row buffers at end of image
			row = DimSize(theWave,0) - 1
			Do
				buffer = theWave[row][15]
				row -= 1
			While(buffer == 0)
			
			If(row < maxX)
				maxX = row + 1
			EndIf
			
			//check row buffers at beginning of image
			row = 0
			col = 0
			Do
				buffer = theWave[15][col]
				col += 1
			While(buffer == 0)
			
			If(col > minY)
				minY = col - 1
			EndIf
			
			//check row buffers at end of image
			col = DimSize(theWave,1) - 1
			Do
				buffer = theWave[15][col]
				col -= 1
			While(buffer == 0)
			
			If(col < maxY)
				maxY = col + 1
			EndIf
		EndFor
		
		//Perform redimensioning
		For(i=0;i<ItemsInList(scanListStr,";");i+=1)
		
			//Get the channel and the image wave
			currentChannel = StringFromList(j,channel,";")
			theWaveName = StringFromList(i,scanListStr,";") 
			Wave theWave = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_" + currentChannel)
			
			Variable deleteMin,deleteMax
			
			//Redimension in X
			deleteMin = minX
			deleteMax = sizeX - maxX
			DeletePoints/M=0 0,deleteMin,theWave
			DeletePoints/M=0 maxX+1,deleteMax,theWave
		
			//Redimension in Y
			deleteMin = minY
			deleteMax = sizeY - maxY
			DeletePoints/M=1 0,deleteMin,theWave
			DeletePoints/M=1 maxY+1,deleteMax,theWave
			
			//Edit the scan info note to avoid scanGraph errors.
			SVAR info = $("root:twoP_Scans:" + theWaveName + ":" + theWaveName + "_info")
			info = ReplaceStringByKey("PixWidth",info,num2str(DimSize(theWave,0)),":","\r")
			info = ReplaceStringByKey("PixHeight",info,num2str(DimSize(theWave,1)),":","\r")
		EndFor
	EndFor
	
End

//Gets the middle point of an ROI defined by an x wave and a y wave
Function getCenter(ROItable,ROIFolder)
	Wave/T ROItable
	String ROIFolder
	Variable i,size
	String ROIStr
	size = DimSize(ROItable,0)
	
	If(numtype(size) == 2)
		return -1
	EndIf
	
	Make/O/N=(size) $(ROIFolder + ":ROIx"),$(ROIFolder + ":ROIy")
	Wave ROIx = $(ROIFolder + ":ROIx")
	Wave ROIy = $(ROIFolder + ":ROIy")
	
	For(i=0;i<size;i+=1)
		ROIStr = ROItable[i]
		Wave xWave = $(ROIfolder + ":" + ROIStr + "_x")
		Wave yWave = $(ROIfolder + ":" + ROIStr + "_y")
		
		If(DimSize(xWave,0) == 5) //square ROI
			ROIx[i] = 0.5*(xWave[0] + xWave[2])
			ROIy[i] = 0.5*(yWave[0] + yWave[2])
		Else
			ROIx[i] = median(xWave)
			ROIy[i] = median(yWave)
		EndIf
	EndFor	
End

Function/S  getScanInfo(theScan)
	Wave theScan
	String scanName,folder,errorStr
	
	folder = GetWavesDataFolder(theScan,1)
	scanName = ParseFilePath(1,NameOfWave(theScan),"_",1,0)
	SVAR scanInfo = $(folder + scanName + "info")
	
	If(!SVAR_Exists(scanInfo))
		errorStr = "-1"
		return errorStr
	Else
		return scanInfo
	EndIf
End

//averages a wave that contains NaNs
Function avgNaNWave(theWave)
	Wave theWave
	Variable xDim,yDim,i,j,value
	
	xDim = DimSize(theWave,0)
	yDim = DimSize(theWave,1)
	Make/FREE/N=(xDim) theCol
	Make/O/N=0 root:concat
	Wave concat = root:concat
	
	For(i=0;i<yDim;i+=1)
		theCol = theWave[p][i]
		Concatenate/NP {theCol},concat
	EndFor
	WaveTransform zapNaNs concat
	WaveStats/Q concat
	KillWaves/Z concat
	return V_avg
End

Function/S GetDistributedColorIndex(index,numGroups)
	Variable index,numGroups
	
	Variable delta = 65535/numGroups
	String colorIndex =  num2str(round(enoise(32767) + 32767)) + "," + num2str(round(enoise(32767) + 32767)) + "," + num2str(delta*index)
	return colorIndex
End

//Deletes ROIs that match grid*
Function deleteGridROI(ROIListWave,ROIListSelWave)
	Wave/T ROIListWave
	Wave ROIListSelWave
	
	Variable i,size
	size = DimSize(ROIListWave,0)
	
	SetDataFolder root:twoP_ROIS
	String objectList = StringByKey("WAVES",DataFolderDir(2),":")
	String roiList = ""
	roiList = ListMatch(objectList,"grid*_x",",")
	roiList += ListMatch(objectList,"grid*_y",",")
	
	For(i=size-1;i>-1;i-=1)	//count down
		If(StringMatch(ROIListWave[i],"grid*"))
			DeletePoints/M=0 i,1,ROIListWave,ROIListSelWave
		EndIf
	EndFor
	
	For(i=0;i<ItemsInList(objectList,",");i+=1)
		Wave theROI = $("root:twoP_ROIS:" + StringFromList(i,roiList,","))
		If(WaveExists(theROI))
			ReallyKillWaves(theROI)
		EndIf
	EndFor
	
End

//input a list of ROIs to delete
Function deleteROI([list])
	String list
	
	If(ParamIsDefault(list))
		SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
		list = ROIListStr
		list = switchSeparator(list,";",",")
	EndIf
	
	Wave/T ROIListWave = root:Packages:twoP:examine:ROIListWave
	Wave ROIListSelWave = root:Packages:twoP:examine:ROIListSelWave
	
	Variable size,i,index
	
	size = ItemsInList(list,",")
	
	SetDataFolder root:twoP_ROIS
	
	For(i=size-1;i>-1;i-=1)//count down
		Wave/Z theROI = $("root:twoP_ROIS:" + StringFromList(i,list,",") + "_y")
		If(WaveExists(theROI))
			ReallyKillWaves(theROI)
		EndIf
		Wave/Z theROI = $("root:twoP_ROIS:" + StringFromList(i,list,",") + "_x")
		If(WaveExists(theROI))
			ReallyKillWaves(theROI)
		EndIf
		index = tableMatch(StringFromList(i,list,","),ROIListWave)
		If(index != -1)
			DeletePoints/M=0 index,1,ROIListWave,ROIListSelWave
		EndIf
	EndFor
	
End

//Changes the separator string in a list
Function/S switchSeparator(list,inSeparator,outSeparator)
	String list,inSeparator,outSeparator
	String outList
	
	outList = ReplaceString(inSeparator,list,outSeparator)
	return outList

End

Function ReallyKillWaves(w)
  Wave w

  string name=nameofwave(w)
  string graphs=WinList("*",";","WIN:1") // A list of all graphs
  variable i,j
  for(i=0;i<itemsinlist(graphs);i+=1)
    string graph=stringfromlist(i,graphs)
    string traces=TraceNameList(graph,";",3)
    
    //check all the twoP graph subwindows
    If(!cmpstr(graph,"twoPScanGraph"))
    	graph = "twoPscanGraph#GCH1"
    	traces=TraceNameList(graph,";",3)
    	if(whichlistitem(name,traces) != -1) // Assumes that each wave is plotted at most once on a graph.  
      	RemoveFromGraph/Z /W=$graph $name
    	endif
    	graph = "twoPscanGraph#GCH2"
    	traces=TraceNameList(graph,";",3)
    	if(whichlistitem(name,traces) != -1) // Assumes that each wave is plotted at most once on a graph.  
      	RemoveFromGraph/Z /W=$graph $name
    	endif
    	graph = "twoPscanGraph#GMRG"
    	traces=TraceNameList(graph,";",3)
    	if(whichlistitem(name,traces) != -1) // Assumes that each wave is plotted at most once on a graph.  
      	RemoveFromGraph/Z /W=$graph $name
    	endif	
    Else
    	traces=TraceNameList(graph,";",3)
    
	    if(whichlistitem(name,traces) != -1) // Assumes that each wave is plotted at most once on a graph.  
	      RemoveFromGraph/Z /W=$graph $name
	    endif
	 EndIf 
  endfor

  string tables=WinList("*",";","WIN:2") // A list of all tables
  for(i=0;i<itemsinlist(tables);i+=1)
    string table=stringfromlist(i,tables)
    j=0
    do
      string column=StringFromList(j,table)
      if(!strlen(column))
      	break
      endif
      if(cmpstr(column,name) == 0)
        RemoveFromTable/Z/W=$table $column
        break
      else
      	j+=1
      endif
    while(1)
  endfor 

  killwaves /z w
End  

Function FilterROI_Table(roiTable,threshold,matchStr)
	Wave/T roiTable
	Variable threshold
	String matchStr
	Variable i
	
	For(i=0;i<DimSize(roiTable,0);i+=1)
		//Get the matched wave for thresholding the ROIs
		String theROI = "ROI" + roiTable[i]
		String folder = "root:ROI_analysis:" + theROI
		SetDataFolder $folder
		String theWaveList = DataFolderDir(2)
		theWaveList = StringByKey("WAVES",theWaveList,":",";")
		String matchWaveName = ListMatch(theWaveList,matchStr,",")
		matchWaveName = StringFromList(0,matchWaveName,",")
		
		Wave theWave = $matchWaveName
		
		If(WaveMax(theWave,3,5) < threshold)
			DeletePoints/M=0 i,1,roiTable
		EndIf
		
	EndFor
	

End


Function ResolveFunctionParameters(theFunction)
	String theFunction
	String info = FunctionInfo(theFunction)
	
	//control list will need updating when controls are added
	SVAR ctrlList_extFunc = root:Packages:analysisTools:ctrlList_extFunc
	ctrlList_extFunc = "extFuncPopUp;extFuncDS;extFuncChannelPop;extFuncDSListBox;extFuncHelp;goToProcButton;"
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	
	Variable numParams,i,pos
	String paramType,functionStr

	numParams = str2num(StringByKey("N_PARAMS",info,":",";"))
	
	//Function has no extra parameters declared
	If(numParams == 0)
		numExtParams = 0
		KillExtParams()
		return -1
	EndIf
	
	
	numExtParams = numParams
	paramType = ""

	//gets the type for each input parameter
	Variable numOptionals = str2num(StringByKey("N_OPT_PARAMS",info,":",";"))
	SVAR isOptional = root:Packages:analysisTools:isOptional
	isOptional = ""
	
	For(i=0;i<numParams;i+=1)
		paramType += StringByKey("PARAM_" + num2str(i) + "_TYPE",info,":",";") + ";"
		If(i < numParams - numOptionals)
			isOptional += "0" + ";"
		Else
			isOptional += "1" + ";"
		EndIf
	EndFor
	extParamTypes = paramType
	
	//Gets the names of each inputs in the selected function
	functionStr = ProcedureText(theFunction,0)
	pos = strsearch(functionStr,")",0)
	functionStr = functionStr[0,pos]
	functionStr = RemoveEnding(StringFromList(1,functionStr,"("),")")
	
	extParamNames = functionStr
	Variable type,left=10,top=145
	String name,paramName
	
	For(i=0;i<numParams;i+=1)
		name = StringFromList(i,functionStr,",")
		paramName = "param" + num2str(i)
		type = str2num(StringFromList(i,paramType,";"))
		switch(type)
			case 4://variable
				SetVariable/Z $paramName win=analysis_tools,pos={left,top},size={125,20},title=name,value=_NUM:0,disable=0,proc=atExtParamPopProc
				ctrlList_extFunc += paramName + ";"
				break
			case 8192://string
				SetVariable/Z $paramName win=analysis_tools,pos={left,top},size={150,20},title=name,value=_STR:"",disable=0,proc=atExtParamPopProc
				ctrlList_extFunc += paramName + ";"
				break
			case 16386://wave
				SetVariable/Z $paramName win=analysis_tools,pos={left,top},size={150,20},title=name,value=_STR:"",disable=0,proc=atExtParamPopProc
				ctrlList_extFunc += paramName + ";"
				break
		endswitch
		top += 25
	EndFor
	
End

Function/S SetExtFuncCmd()
	Variable option//is this from external command, or is it from a built in command
	
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	SVAR isOptional = root:Packages:analysisTools:isOptional
	Variable i,type
	String runCmdStr = ""
	String name 
	
	SVAR builtInCmdStr = root:Packages:analysisTools:runCmdStr
	
	//External function
	//ControlInfo/W=analysis_tools extFuncPopUp
	SVAR currentExtCmd = root:Packages:analysisTools:currentExtCmd
	String theFunction = currentExtCmd
	runCmdStr = "AT_" + theFunction + "("

	For(i=0;i<numExtParams;i+=1)
		ControlInfo/W=analysis_tools $("param" + num2str(i))
		type = str2num(StringFromList(i,extParamTypes,";"))
		name = StringFromList(i,extParamNames,",")
		
		switch(type)
			case 4://variable
				If(str2num(StringFromList(i,isOptional,";")) == 0)
					runCmdStr += num2str(V_Value) + ","
				Else
					//optional parameter
					If(V_Value)
						runCmdStr += name + "=" + num2str(V_Value) + ","
					EndIf
				EndIf
				break
			case 8192://string
				If(str2num(StringFromList(i,isOptional,";")) == 0)
					runCmdStr += "\"" + S_Value + "\","
				Else
					//optional parameter
					If(strlen(S_Value))
						runCmdStr += name + "=" + "\"" + S_Value + "\","
					EndIf
				EndIf
				break
			case 16386://wave
				If(str2num(StringFromList(i,isOptional,";")) == 0)
					runCmdStr += S_Value + ","
				Else
					//optional parameter
					If(strlen(S_Value))
						runCmdStr += name + "=" + S_Value + ","
					EndIf
				EndIf
				break
		endswitch
	EndFor
	runCmdStr = RemoveEnding(runCmdStr,",")
	runCmdStr += ")"

	return runCmdStr
End

Function KillExtParams()
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	Variable i
	For(i=0;i<numExtParams;i+=1)
		KillControl/W=analysis_tools $("param" + num2str(i))
	EndFor
End

Function updateExtFuncValues(theFunction)
	String theFunction
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	Wave/T extFuncValues = root:Packages:analysisTools:extFuncValues
	
	Variable cols,i,numParams,whichCol = -1
	
	cols = DimSize(extFuncValues,1)
	numParams = ItemsInList(extParamNames,",")
	
	If(cols == 0)
		whichCol = 0
		cols +=1
		Redimension/N=(1,cols) extFuncValues
		If(numParams + 2 > DimSize(extFuncValues,0))
			Redimension/N=(numParams + 2,-1) extFuncValues
		EndIf
	Else
	
		For(i=0;i<cols;i+=1)
			If(stringmatch(extFuncValues[0][i],theFunction))
				whichCol = i
				break
			EndIf
		EndFor
		
		If(whichCol == -1)
			whichCol = cols
			cols += 1
			Redimension/N=(-1,cols) extFuncValues
			If(numParams + 2 > DimSize(extFuncValues,0))
				Redimension/N=(numParams + 2,-1) extFuncValues
			EndIf
		EndIf
	EndIf
	
	///Fill out the table
	extFuncValues[0][whichCol] = theFunction
	extFuncValues[1][whichCol] = num2str(numParams)
	For(i=0;i<numParams;i+=1)
		ControlInfo/W=analysis_tools $("param" + num2str(i))
		If(numtype(V_Value) == 2 || strlen(S_Value))
			//string or wave input
			extFuncValues[i+2][whichCol] = S_Value
		Else
			//variable input
			extFuncValues[i+2][whichCol] = num2str(V_Value)
		EndIf
	EndFor

End

Function recallExtFuncValues(theFunction)
	String theFunction
	Wave/T extFuncValues = root:Packages:analysisTools:extFuncValues
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	Variable i,whichCol,cols
	
	cols = DimSize(extFuncValues,1)
	whichCol = -1
	
	For(i=0;i<cols;i+=1)
		If(stringmatch(extFuncValues[0][i],theFunction))
			whichCol = i
			break
		EndIf
	EndFor
	
	If(whichCol != -1)
		For(i=0;i<numExtParams;i+=1)
			ControlInfo/W=analysis_tools $("param" + num2str(i))
			If(numtype(V_Value) ==2)
				//string or wave input
				SetVariable $("param" + num2str(i)) win=analysis_tools,value=_STR:extFuncValues[i+2][whichCol]
			Else
				SetVariable $("param" + num2str(i)) win=analysis_tools,value=_NUM:str2num(extFuncValues[i+2][whichCol])
			EndIf
			
		EndFor
	EndIf

End

Function openViewer()
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
	
	//Define guides
	DefineGuide/W=analysis_tools VT = {FT,0.63,FB}
	DefineGuide/W=analysis_tools VB = {FT,0.97,FB}
	
	//Add an additional 200 pixels to the toolbox on the bottom
	GetWindow analysis_tools wsize
	MoveWindow/W=analysis_tools V_left,V_top,V_right,V_bottom + 300
	
	//Open the display window only if it wasn't already open
	If(viewerOpen == 0)
		Display/HOST=analysis_tools/FG=(FL,VT,FR,VB)/N=atViewerGraph
	EndIf	
	
	//adjust guide for scanListPanel so it doesn't get in the viewer's way
	DefineGuide/W=analysis_tools listboxBottom={FT,0.61,FB}
	
	//Display the window controls
	Button atViewerAutoScaleButton win=analysis_tools,size={50,20},pos={3,788},title="AUTO",proc=atButtonProc
	Button atViewerSeparateVertButton win=analysis_tools,size={50,20},pos={60,788},title="VSEP",proc=atButtonProc
	Button atViewerSeparateHorizButton win=analysis_tools,size={50,20},pos={117,788},title="HSEP",proc=atButtonProc
	Button atViewerDisplayTracesButton win=analysis_tools,size={50,20},pos={174,788},title="DISP",proc=atButtonProc
	Button atViewerClearTracesButton win=analysis_tools,size={50,20},pos={231,788},title="CLEAR",proc=atButtonProc
	
	//Recall previous display
	If(strlen(viewerRecall))
		Execute/Z viewerRecall
	EndIf
	
	viewerOpen = 1
End

Function closeViewer()
	SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	
	viewerRecall = WinRecreation("analysis_tools#atViewerGraph",0)
	//viewerRecall = ReplaceString("Display/W=(162,200,488,600)/FG=(FL,VT,FR,VB)/HOST=#",viewerRecall,"AppendToGraph/W=analysis_tools#atViewerGraph")
	
	Variable pos1 = strsearch(viewerRecall,"Display",0)
	Variable pos2 = strsearch(viewerRecall,"#",0)
	String matchStr = viewerRecall[pos1,pos2]
	viewerRecall = ReplaceString(matchStr,viewerRecall,"AppendToGraph/W=analysis_tools#atViewerGraph")
	
	KillWindow/Z analysis_tools#atViewerGraph
	//Remove 200 pixels to the toolbox on the bottom
	GetWindow analysis_tools wsize
	MoveWindow/W=analysis_tools V_left,V_top,V_right,V_bottom - 300
	
	//adjust guide for scanListPanel so it doesn't get in the viewer's way
	DefineGuide/W=analysis_tools listboxBottom={FB,-10}
	
	viewerOpen = 0
End

//Appends selected waves in the Browser item list box to the Viewer graph
Function AppendToViewer(itemList)
	String itemList
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	Variable i,j,type

	DoWindow/W=analysis_tools#atViewerGraph atViewerGraph
	
	//Does the window exist?
	If(V_flag)
		String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
		//Remove all traces
		For(i=ItemsInList(traceList)-1;i>-1;i-=1)
			RemoveFromGraph/Z/W=analysis_tools#atViewerGraph $StringFromList(i,traceList,";")
		EndFor	
		//Append selected traces
		For(i=0;i<ItemsInList(itemList,";");i+=1)
			If(WaveType($(cdf + StringFromList(i,itemList,";")),1) == 2)
				continue //text wave
			Else
				AppendToGraph/W=analysis_tools#atViewerGraph $(cdf + StringFromList(i,itemList,";"))
			EndIf
		EndFor
	EndIf	
End

Function SeparateTraces(orientation)
	String orientation
	NVAR areSeparated = root:Packages:analysisTools:areSeparated
	String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
	String theTrace,prevTrace
	Variable numTraces,i,traceMax,traceMin,traceMinPrev,traceMaxPrev,offset
	offset = 0
	numTraces = ItemsInList(traceList,";")
	
	strswitch(orientation)
		case "vert":
			If(areSeparated)
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					offset = 0
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={0,offset}
				EndFor	
				areSeparated = 0	
			Else
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					Wave theTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",theTrace)
					traceMin = WaveMin(theTraceWave)
					traceMax = WaveMax(theTraceWave)
					Wave prevTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",StringFromList(i-1,traceList,";"))
					traceMinPrev = WaveMin(prevTraceWave)
					traceMaxPrev = WaveMax(prevTraceWave)
					offset -= abs(traceMax - traceMinPrev)
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={0,offset}
				EndFor
				areSeparated = 1
			EndIf
			break
		case "horiz":
			If(areSeparated)
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					offset = 0
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={offset,0}
				EndFor	
				areSeparated = 0	
			Else
				For(i=1;i<numTraces;i+=1)
					theTrace = StringFromList(i,traceList,";")
					Wave theTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",theTrace)
					traceMin = DimOffset(theTraceWave,0)
					traceMax = IndexToScale(theTraceWave,DimSize(theTraceWave,0)-1,0)
					Wave prevTraceWave = TraceNameToWaveRef("analysis_tools#atViewerGraph",StringFromList(i-1,traceList,";"))
					traceMinPrev = DimOffset(prevTraceWave,0)
					traceMaxPrev = IndexToScale(prevTraceWave,DimSize(prevTraceWave,0)-1,0)
					offset += abs(traceMinPrev+traceMax)
					ModifyGraph/W=analysis_tools#atViewerGraph offset($theTrace)={offset,0}
				EndFor
				areSeparated = 1
			EndIf
			break
	endswitch
End

//Clears all the traces from the Viewer window
Function clearTraces()
	String traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
	Variable numTraces = ItemsInList(traceList,";")
	Variable i
	
	For(i=numTraces - 1;i>-1;i-=1)
		String theTrace = StringFromList(i,traceList,";")
		RemoveFromGraph/W=analysis_tools#atViewerGraph $theTrace
	EndFor	
End

Function/S textWaveToStringList(textWave,separator)
	Wave/T textWave
	String separator
	Variable size,i
	String strList = ""
	
	If(WaveType(textWave,1) !=2)
		Abort "Input must be a text wave"
	EndIf
	size = DimSize(textWave,0)
	For(i=0;i<size;i+=1)
		strList += textWave[i] + separator
	EndFor
	strList = RemoveEnding(strList,separator)
	
	return strList
End

Function/WAVE StringListToTextWave(strList,separator)
	String strList,separator
	Variable size,i
	
	If(!strlen(strList))
		Abort "String must be longer than 0 characters"
	EndIf
	
	size = ItemsInList(strList,separator)
	Make/FREE/T/N=(size) textWave
	For(i=0;i<size;i+=1)
		textWave[i] = StringFromList(i,strList,";")
	EndFor

	return textWave
End

//Same as StringFromList, but is capable of extracting a range from the list
Function/S StringsFromList(range,list,separator)
	String range,list,separator
	String outList = ""
	Variable i,index
	
	range = ResolveListItems(range,separator)
	
	For(i=0;i<ItemsInList(range,";");i+=1)
		index = str2num(StringFromList(i,range,";"))
		outList += StringFromList(index,list,separator) + separator
	EndFor	

	return outList
End

Function selectALL(control,mode)
	String control,mode
	//Selection wave for the scan list
	Wave scanSelWave = root:Packages:twoP:examine:selWave
	Wave/T scanListWave = root:Packages:twoP:examine:scanListWave
	
	//Selection wave for the ROI list
	Wave roiSelWave = root:Packages:twoP:examine:ROIListSelWave
	Wave/T roiListWave = root:Packages:twoP:examine:roiListWave
	
	//Selection wave for the folder list
	Wave folderSelWave = root:Packages:analysisTools:selFolderWave
	//Selection wave for the wave item list
	Wave itemSelWave = root:Packages:analysisTools:itemListSelWave
	
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr

	Variable i
	
	strswitch(mode)
		case "AT":
			strswitch(control)
				case "selectAll_Left":
					scanSelWave = 1
					scanListStr = ""
					For(i=0;i<DimSize(scanListWave,0);i+=1)
						scanListStr += scanListWave[i] + ";"
					EndFor
					break
				case "selectAll_Right":
					roiSelWave = 1
					ROIListStr = ""
					For(i=0;i<DimSize(roiListWave,0);i+=1)
						ROIListStr += roiListWave[i] + ";"
					EndFor
					break
			endswitch
		break
		case "Browser":
			strswitch(control)
				case "selectAll_Left":
					folderSelWave = 1
					break
				case "selectAll_Right":
					itemSelWave = 1
					break
			endswitch
		break
	endswitch
End

//Resolves the syntax used in the Cmd input for 'Run Cmd Line' function
//Replaces data set references <DataSet> with the name of the wave
//<DataSet>{wsn,wsi}
Function/S resolveCmdLine(cmdLineStr,wsn,wsi)
	String cmdLineStr
	Variable wsn,wsi

	//WaveSet data
	//ControlInfo/W=analysis_tools extFuncDS
	//numWaveSets = GetNumWaveSets(S_Value)
	//wsDims = GetWaveSetDims(S_Value)
	
	String left = "",right = "",dsName="",char="",outStr="",tempStr="",indexStr=""
	Variable pos1,pos2,pos3,pos4,numChars,i,index,wsnIndex,wsiIndex
	
	//Divide into left and right sides of an equals sign
	left = StringFromList(0,cmdLineStr,"=")
	right = StringFromList(1,cmdLineStr,"=")

	
	pos1 = 0;pos2 = 0
	pos3 = 0;pos4 = 0
	outStr = ""
	Do
		pos1 = strsearch(cmdLineStr,"<",0)
		pos2 = strsearch(cmdLineStr,">",pos1)
		
		
		//If a valid data set syntax was found
		If(pos1 != -1 && pos2 != -1)
			//test for wsi specifier { } directly after the dataset specifier
			If(!cmpstr(cmdLineStr[pos2+1],"{"))
				pos3 = pos2+1
				pos4 = strsearch(cmdLineStr,"}",pos3)
			Else
				pos3 = -1
				pos4 = -1
			EndIf
			
			//Get the referenced data set
			dsName = cmdLineStr[pos1+1,pos2-1]
			Wave/T/Z ds = GetDataSetWave(dsName=dsName)
				
			If(pos3 != -1 && pos2 != -1)
				//set pos2 to after the waveset specifier for proper string trimming
				pos2 = pos4
				
				//wsi specifier
				indexStr = cmdLineStr[pos3+1,pos4-1]
				
				//resolve wsn
				tempStr = StringFromList(0,indexStr,",")
				
				If(cmpstr(tempStr,"*"))
					wsnIndex = str2num(tempStr)
					If(numtype(wsnIndex) == 2)//invalid index number
						outStr = ""
						return outStr
					EndIf
					
					//Ensures that the function only runs for the indicated wave set number,
					//instead of repeating itself for every wave set.
					If(wsnIndex != wsn)
						outStr = ""
						return outStr
					EndIf
				Else
					wsnIndex = wsn
				EndIf
				
				//resolve wsi
				tempStr = StringFromList(1,indexStr,",")
				
				If(cmpstr(tempStr,"*"))
					wsiIndex = str2num(tempStr)
					If(numtype(wsnIndex) == 2)//invalid index number
						outStr = ""
						return outStr
					EndIf
				Else
					wsiIndex = wsi
				EndIf
				
				
			  String theWaveSet = GetWaveSet(dsName,wsn=wsnIndex)
			  String theWaveStr = StringFromList(wsiIndex,theWaveSet,";")
				
			Else
				//No wsi specifier
				If(cmpstr(dsName,"wsi") == 0)
					theWaveSet = ""
				   theWaveStr = num2str(wsi)
				ElseIf(cmpstr(dsName,"wsn") == 0)
				   theWaveSet = ""
				   theWaveStr = num2str(wsn)
				Else
					theWaveSet = GetWaveSet(dsName,wsn=wsn)
					theWaveStr = StringFromList(wsi,theWaveSet,";")
				EndIf
			EndIf
			
			//section of string that isn't a data set reference
			tempStr = cmdLineStr[0,pos1-1]

			//insert into wave name the output command string
			outStr += tempStr + theWaveStr
			
			//trim to the remaining section of unsearched command string
			cmdLineStr = cmdLineStr[pos2+1,strlen(cmdLineStr)-1]
		Else
			//append remaining characters to the output command string
			outStr += cmdLineStr
			break
		EndIf
	While(pos1 != -1)
	return outStr
End

//Takes the scaling of refWave, and applies it to testWave
//Waves must have the same dimensions
Function matchScale(testWave,refWave[,ignoreDims])
	Wave testWave,refWave
	Variable ignoreDims
	
	If(ParamIsDefault(ignoreDims))
		ignoreDims = 0
	EndIf
	
	//check wave existence
	If(!WaveExists(testWave))
		Abort "Couldn't find the wave " + NameOfWave(testWave)
	EndIf
		
	If(!WaveExists(refWave))
		Abort "Couldn't find the wave " + NameOfWave(refWave)
	EndIf
	
	Variable xSize,ySize,zSize,xSizeRef,ySizeRef,zSizeRef
	
	//dimensions of each wave
	xSizeRef = DimSize(refWave,0)
	ySizeRef = DimSize(refWave,1)
	zSizeRef = DimSize(refWave,2)
	
	xSize = DimSize(testWave,0)
	ySize = DimSize(testWave,1)
	zSize = DimSize(testWave,2)
	
	//set scales
	If(ignoreDims)
		SetScale/P x,DimOffset(refWave,0),DimDelta(refWave,0),testWave
		SetScale/P y,DimOffset(refWave,1),DimDelta(refWave,1),testWave
		SetScale/P z,DimOffset(refWave,2),DimDelta(refWave,2),testWave
	Else
		If(xSizeRef == xSize && ySizeRef == ySize && zSizeRef == zSize)
			SetScale/P x,DimOffset(refWave,0),DimDelta(refWave,0),testWave
			SetScale/P y,DimOffset(refWave,1),DimDelta(refWave,1),testWave
			SetScale/P z,DimOffset(refWave,2),DimDelta(refWave,2),testWave
		EndIf
	EndIf
End

//Dynamic ROI window hook function
Function dROI_Hook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0
	Variable xPix,yPix,size,left,right,top,bottom,i,j,xVal,yVal,leftAxis,rightAxis,bottomAxis,topAxis
	Wave dROI = root:Packages:analysisTools:dynamicROIWave
	
	If(!WaveExists(dROI))
		return -1
	EndIf
	
	//projection and the original 3D image
	Wave maxProj = root:Packages:analysisTools:maxProj
   Wave theImage = $note(maxProj)
   
   If(DimSize(theImage,2) == 0)
   	Variable dims = 2
   Else
   	dims = 3
   EndIf
   
   If(!WaveExists(maxProj))
   	return -1
   EndIf
    
   If(!WaveExists(theImage))
   	return -1
   EndIf
   
	//diameter of the beam
	ControlInfo/W=analysis_tools dynamicROI_size
	size = V_Value

	//check if mouse is over image
	xVal = AxisValFromPixel("maxProjection","bottom",s.mouseLoc.h)
	yVal = AxisValFromPixel("maxProjection","left",s.mouseLoc.v)
	
	//Is mouse within axis range?
	GetAxis/W=maxProjection/Q bottom
	If(xVal - DimDelta(maxProj,0)*0.5*size < V_min || xVal + DimDelta(maxProj,0)*0.5*size> V_max)
		DrawAction/L=UserFront/W=maxProjection delete
		return -1
	EndIf
	
	GetAxis/W=maxProjection/Q left
	If(yVal - DimDelta(maxProj,1)*0.5*size < V_min || yVal + DimDelta(maxProj,1)*0.5*size> V_max)
		DrawAction/L=UserFront/W=maxProjection delete
		return - 1
	EndIf
	
	//convert axis value to pixels
	xPix = ScaleToIndex(maxProj,xVal,0)
	yPix = ScaleToIndex(maxProj,yVal,0)
	
	//edges of the ROI
	left = ceil(xPix - .5*size) 
	right = left + size
	top = ceil(yPix - .5*size) 
	bottom = top + size
	
	leftAxis = IndexToScale(maxProj,left,0)
	rightAxis = IndexToScale(maxProj,right,0)
	topAxis = IndexToScale(maxProj,top,1)
	bottomAxis = IndexToScale(maxProj,bottom,1)
	
	switch(s.eventCode)
		case 0: //activate
			break
		case 1: //deactivate
			break
		case 4: //mouse moved
			//Correctly size the dynamic ROI wave to the number of frames in the image
			Redimension/N=(DimSize(theImage,2)) dROI
			
			If(DimSize(dROI,0) == 0)
				Redimension/N=1 dROI
			EndIf
			
			dROI = 0	
			
			//Draw for showing the ROI
			SetDrawLayer/W=maxProjection/K UserFront
			SetDrawEnv/W=maxProjection xCoord=bottom,yCoord=left,fillfgc=(0,35000,50000,25000),linethick=0
			//draw in window absolute coordinates
			DrawRect/W=maxProjection leftAxis,topAxis,rightAxis,bottomAxis
			Variable numPixels = 0
			
			For(i=left;i<right;i+=1)
				For(j=top;j<bottom;j+=1)
					If(dims == 3)
						MatrixOP/FREE temp = beam(theImage,i,j)
						If(numtype(temp[0]) == 2) //is nan
							continue
						EndIf
						numPixels +=1
						dROI += temp
					ElseIf(dims == 2)
						If(numtype(theImage[i][j]) == 2) //is nan
							continue
						EndIf
						numPixels +=1
						dROI += theImage[i][j]
					EndIf
				EndFor
			EndFor
			
			dROI /= numPixels
			SetScale/P x,DimOffset(theImage,2),DimDelta(theImage,2),dROI
			break
	endswitch
End

//gets the center of mass of the wave, 1D waves only.
Function CofM(theWave[,startX,endX])
	Wave theWave
	Variable startX,endX
	Variable i,mass,com,size

	If(!WaveExists(theWave))
		return -1
	EndIf
	
	mass = 0
	com = 0
	size = DimSize(theWave,0)
	
	If(ParamIsDefault(startX))
		startX = 0
	Else
		startX = ScaleToIndex(theWave,startX,0)
	EndIf
	
	If(ParamIsDefault(endX))
		endX = size-1
	Else
		endX = ScaleToIndex(theWave,endX,0)
	EndIf

	For(i=startX;i<=endX;i+=1)
		com += theWave[i] * IndexToScale(theWave,i,0)
		mass += theWave[i]
	EndFor
	com /= mass
	
	return com
End

//Writes out the different syntax that you need to use with the command line.
Function drawSyntaxInfo()
	SetDrawLayer/W=analysis_tools UserBack
	
	String text = "\\f04Syntax"
	DrawText/W=analysis_tools 20,145,text
	
	SetDrawEnv/W=analysis_tools textrgb= (34952,34952,34952)
	text = "Data Set: <myDataSet>\n\nReference WSI: <wsi>\n\nReference WSN: <wsn>"
	text += "\n\nSpecific WSN/WSI:\n <myDataSet>{wsn,wsi}"
	DrawText/W=analysis_tools 20,260,text
	SetDrawEnv/W=analysis_tools textrgb= (34952,34952,34952)
	text = "Specific WSI for all WSN:\n <myDataSet>{*,wsi}"
	DrawText/W=analysis_tools 20,300,text
	
	SetDrawEnv/W=analysis_tools textrgb= (0,0,0)
End

//Replaces the indicated list item with the replaceWith string
Function/S ReplaceListItem(index,listStr,separator,replaceWith)
	Variable index
	String listStr,separator,replaceWith
	
	listStr = RemoveListItem(index,listStr,separator)
	listStr = AddListItem(replaceWith,listStr,separator,index)
	listStr = RemoveEnding(listStr,separator)
	
	return listStr
End

//Navigates to the procedure window for the selected external function 
Function goToProc()
	SVAR fileList = root:Packages:analysisTools:fileList //list of external .ipf files
	Variable i,j,numFiles
	String theFile,theFunction,theList = ""
	
	SVAR currentExtCmd = root:Packages:analysisTools:currentExtCmd
	theFunction = "AT_" + currentExtCmd
	
	numFiles = ItemsInList(fileList,";")
	
	For(j=0;j<numFiles;j++)
		For(i=0;i<numFiles;i+=1)
			theFile = StringFromList(i,fileList,";")
			theList = FunctionList("*", ";","WIN:" + theFile)
			
			If(stringmatch(theList,"*" + theFunction + "*"))
				DisplayProcedure/W=theFile theFunction
			EndIf
		EndFor	
	EndFor	
End

Function areaOffset(inWave,offset[,startX,endX])
//returns the area under the curve above the indicated offset value
	Wave inWave
	Variable offset
	Variable startX,endX
	Variable theArea
	
	If(ParamIsDefault(startX))
		startX = DimOffset(inWave,0)
	EndIf
	
	If(ParamIsDefault(endX))
		endX = pnt2x(inWave,DimSize(inWave,0)-1)
	EndIf
	
	If(!WaveExists(inWave))
		Abort "The input wave does not exist: " + NameOfWave(inWave)
		return nan
	EndIf
	
	//remove offset
	Duplicate/FREE inWave,temp
	temp -= offset
	
	theArea = area(temp,startX,endX)
	return theArea
End