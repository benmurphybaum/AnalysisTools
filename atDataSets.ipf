#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Gets the data set names that already exist
Function/S GetDataSetNames()
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	String dataSets,cdf
	Variable numDataSets,i
	
	cdf = GetDataFolder(1)
	SetDataFolder root:Packages:analysisTools:DataSets:
	
	dataSets = WaveList("DS_*",";","TEXT:1")
	numDataSets = ItemsInList(dataSets,";")
	Redimension/N=(numDataSets) dataSetNames
	
	For(i=0;i<numDataSets;i+=1)
		dataSetNames[i] = RemoveListItem(0,StringFromList(i,dataSets,";"),"_")	//also removes the DS from the front for display purposes
	EndFor
	
	SetDataFolder $cdf
End

//Removes a dataset from the list
Function delDataSet(selectedRow)
	Variable selectedRow
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	
	//Don't allow the last data set to be deleted
	If(DimSize(dataSetNames,0) == 0)
		return -1
	EndIf
	
	//returns if no data set is selected
	If(selectedRow == -1)
		return 0
	EndIf
	
	String dataSetName = datasetNames[selectedRow]
	Wave theDataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
	Wave ogDataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	DeletePoints/M=0 selectedRow,1,dataSetNames,dataSetSelWave,ogDataSetWave,dsFilters
	KillWaves/Z theDataSetWave,ogDataSetWave
End

//Adds the wave to a new dataset for quick result viewing
Function outputDS(outWave)
	Wave outWave
	SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
	NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
	NVAR wsn = root:Packages:analysisTools:DataSets:wsn
	
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	
	//Input data set in use
	ControlInfo/W=analysis_tools extFuncDS
	Wave/T/Z ds = GetDataSetWave(dsName=S_Value)
	
	//Resize data set definition waves
	If(wsn == 0)
		//only make new data set if it doesn't exist
		If(!WaveExists(root:Packages:analysisTools:DataSets:DS_output))
			Redimension/N=(DimSize(dataSetNames,0)+1) dataSetNames,dataSetSelWave
			dataSetNames[DimSize(dataSetNames,0)-1] = "output"
		EndIf
		
		//New output ds waves
		Make/O/T/N=0 root:Packages:analysisTools:DataSets:DS_output,root:Packages:analysisTools:DataSets:ogDS_output
		Make/O/T/N=0 root:Packages:analysisTools:DataSets:DS_output,root:Packages:analysisTools:DataSets:DS_output		
	EndIf
	
	Wave/T ogdsOut = root:Packages:analysisTools:DataSets:ogDS_output
	Wave/T dsOut = root:Packages:analysisTools:DataSets:DS_output
	
	Redimension/N=(wsn*2+2) dsOut
	dsOut[wsn*2] = "----WSN " + num2str(wsn)  + "----"
	dsOut[wsn*2+1] = GetWavesDataFolder(outWave,2)//full path of the wave gets put into the data set table
	
	Redimension/N=(wsn+1) ogdsOut
	ogdsOut[wsn] = GetWavesDataFolder(outWave,2)
	
	//Set the data set list for use in external functions
	SVAR DSNames = root:Packages:analysisTools:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
	
	Variable i
	For(i=0;i<DimSize(dsFilters,0);i+=1)
		If(!cmpstr(dsFilters[i],"output"))
			//make fresh filter set for the output wave
			dsFilters[i][1] = ";;;;;;;;"
			return 0
		EndIf
	EndFor
	
	//If there was no output filter set
	Variable size = DimSize(dsFilters,0)
	Redimension/N=(size+1,2) dsFilters
	dsFilters[size][0] = "output"
	dsFilters[size][1] = ";;;;;;;;"
End

//adds a dataset defined by the matched waves in the list box
Function addDataSet(dataSetName,[selection])
	String dataSetName
	Variable selection
	Variable numWaves,currentNumSets,i,j,numScans
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	
	//Relative folder path that will be added on to the current data folder
	ControlInfo/W=analysis_tools relativeFolderMatch
	String relFolder = S_Value
	If(strlen(relFolder) > 0)
		relFolder = ":" + relFolder
	EndIf
	
	//Make the ds filter wave if it doesn't exist
	If(!WaveExists(root:Packages:analysisTools:DataSets:dsFilters))
		Make/O/T/N=(1,2) root:Packages:analysisTools:DataSets:dsFilters
	EndIf
	
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	String possiblePath
	
	//Does the data set name already exist?
	//If so, return
	If(tableMatch(dataSetName,dataSetNames) != -1)
		
	EndIf
	
		
	If(selection)
		//Get the wave paths from the item list box
		String fullPath = getSelectedItems()
		If(!strlen(fullPath))
			return 0
		EndIf
		numWaves = ItemsInList(fullPath,";")
		
		//Does the data set name already exist?
		If(tableMatch(dataSetName,dataSetNames) != -1)
			currentNumSets = DimSize(dataSetNames,0)			
			Variable index = tableMatch(dataSetName,dataSetNames)
			ListBox dataSetListBox win=analysis_tools,selrow=index
			
			Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
			Wave/T ogdataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
			Redimension/N=(ItemsInList(fullPath,";")) dataSetWave,ogdataSetWave
			
			//Fill the data set wave
			For(i=0;i<numWaves;i+=1)
				If(strlen(StringFromList(i,fullPath,";")) == 0)
					continue
				EndIf	
				dataSetWave[i] = StringFromList(i,fullPath,";")
			EndFor
			ogdataSetWave = dataSetWave
			
			//clear filters and matchlist
			Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
			dsFilters[index][1] = ";;;;;;;;;;"
			clearFilterSet()
			
			fillFilterTable()
		
			//Reload the data set names
			GetDataSetNames()
			
			SVAR DSNames = root:Packages:analysisTools:DataSets:DSNames
			DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
				
			return 0
		EndIf
		
	Else
		//Get the wave paths from the match list box
		ControlInfo/W=analysis_tools matchListBox
		Wave/T listWave = $("root:Packages:analysisTools:" + S_Value)
		
		If(!WaveExists(listWave))
			return -1
		EndIf
		
		
		//Full paths of the waves in the match list box, ungrouped
		If(!WaveExists(root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup))
			Make/T/O/N=1 root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
		EndIf
		Wave/T fullPathTable = root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
		
		//Make new text wave to hold the data set wave names
		Make/O/T/N=(DimSize(fullPathTable,0)) $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
		Make/O/T/N=(DimSize(fullPathTable,0)) $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
		Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
		Wave/T ogdataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)

		//Set the data set tables
		ogdataSetWave = fullPathTable
		dataSetWave = fullPathTable
		
		
		//Add the DS name to the list wave
	
		//Does the data set name already exist?
		If(tableMatch(dataSetName,dataSetNames) != -1)
			currentNumSets = DimSize(dataSetNames,0)			
		   index = tableMatch(dataSetName,dataSetNames)
			ListBox dataSetListBox win=analysis_tools,selrow=index
		Else
			currentNumSets = DimSize(dataSetNames,0)
			Redimension/N=(currentNumSets+1) dataSetNames,dataSetSelWave
			
			dataSetNames[currentNumSets] = dataSetName
			ListBox dataSetListBox win=analysis_tools,selrow=currentNumSets
		EndIf
		
		fillFilterTable()
		
		//Reload the data set names
		GetDataSetNames()
		
		SVAR DSNames = root:Packages:analysisTools:DataSets:DSNames
		DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
			
		return 0
		
		
		
		//Get the full paths of the waves in listwave
		SVAR whichList = root:Packages:analysisTools:whichList
		SVAR scanListStr = root:Packages:twoP:examine:scanListStr
		Wave/T folderTable = root:Packages:analysisTools:folderTable
		
		Wave selFolderWave = root:Packages:analysisTools:selFolderWave
		Variable count = 0 
		
		fullPath = ""
		If(cmpstr(whichList,"AT") == 0)
		   numScans = ItemsInList(scanListStr,";")
			For(i=0;i<numScans;i+=1)
				fullPath += "root:twoP_Scans:" + StringFromList(i,scanListStr,";") + ":" + listWave[count] + ";"
				count += 1
			EndFor
			
			//If we're just trying to duplicate a currently displayed data set
			//Just take what's sitting in the matchList box.
			If(numScans == 0) 
			
				If(DimSize(listWave,0) == 0)
					return -1
				EndIf
			
				//ds to be copied
				ControlInfo/W=analysis_tools dataSetListBox
				
				Wave/T copyDS = GetDataSetWave(dsName = dataSetNames[V_Value])
				Wave/T ogcopyDS = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetNames[V_Value])
				
				//Make new text wave to hold the data set wave names
				Make/O/T/N=(DimSize(copyDS,0)) $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
				Make/O/T/N=(DimSize(ogcopyDS,0)) $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
				Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
				Wave/T ogdataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
				
				dataSetWave = copyDS
				ogdataSetWave = ogcopyDS
				
				//Add the DS name to the list wave
				currentNumSets = DimSize(dataSetNames,0)
				Redimension/N=(currentNumSets+1) dataSetNames,dataSetSelWave
				
				fillFilterTable()
				
				dataSetNames[currentNumSets] = dataSetName
				return 0
			EndIf
		ElseIf(cmpstr(whichList,"Browser") == 0)
			If(DimSize(folderTable,0) > 0)
				For(i=0;i<DimSize(folderTable,0);i+=1)
					String previousPath = ""
					If(selFolderWave[i] == 1)
						For(j=count;j<DimSize(listWave,0);j+=1)
							//Is the name of the next possible wave the same as the previously selected wave?
							If(cmpstr(listWave[j],previousPath) == 0)
								continue
							EndIf
							possiblePath = cdf + folderTable[i] + relFolder + ":" + listWave[j]
							If(WaveExists($possiblePath))	//is the wave in this folder?
								fullPath += possiblePath + ";"
								previousPath = listWave[j]
								count+=1
							EndIf
						EndFor
					//fullPath +=  cdf + folderTable[i] + ":" + listWave[count] + ";"
					//count += 1
					EndIf
				EndFor
			Else
				previousPath = ""
				For(j=0;j<DimSize(listWave,0);j+=1)
					fullPath += cdf + listWave[j] + ";"
				EndFor
			EndIf
			Variable items = ItemsInList(fullPath,";")
		EndIf
		
		numWaves = DimSize(listWave,0)
	EndIf
	
	//Add the DS name to the list wave
	currentNumSets = DimSize(dataSetNames,0)
	Redimension/N=(currentNumSets+1) dataSetNames,dataSetSelWave
	dataSetNames[currentNumSets] = dataSetName

	//Make new text wave to hold the data set wave names
	Make/O/T/N=(numWaves) $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
	Make/O/T/N=(numWaves) $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + dataSetName)
	Wave/T ogdataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	
	//Fill the data set wave
	For(i=0;i<numWaves;i+=1)
		If(strlen(StringFromList(i,fullPath,";")) == 0)
			continue
		EndIf	
		dataSetWave[i] = StringFromList(i,fullPath,";")
	EndFor
	ogdataSetWave = dataSetWave

	Make/N=(DimSize(dataSetWave,0))/T/O root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping
	Wave/T ogDS_saveDSGrouping = root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping
	ogDS_saveDSGrouping = ogdataSetWave
	
	//Reload the data set names
	GetDataSetNames()
	
	SVAR DSNames = root:Packages:analysisTools:DataSets:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
End

//Reads the match, prefix, group, series, etc. inputs to save the filter sets for the selected data set
Function/S GetDSFilters()
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	ControlInfo/W=analysis_tools dataSetListBox
	String dsName = dataSetNames[V_Value]
	String dsFilters = ""
	
	ControlInfo/W=analysis_tools waveMatch
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools waveNotMatch
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools relativeFolderMatch
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools waveGrouping
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools prefixGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools groupGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools seriesGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools sweepGroup
	dsFilters += S_Value + ";"
	ControlInfo/W=analysis_tools traceGroup
	dsFilters += S_Value + ";"
	
	return dsFilters
End

//Reads the filter settings for the selected data set, puts it into the variable boxes
Function updateWSFilters()
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	String groupList = "prefixGroup;groupGroup;seriesGroup;sweepGroup;traceGroup"
	Variable i,size
	String filters,dsName
	
	ControlInfo/W=analysis_tools dataSetListBox
	If(DimSize(dataSetNames,0) == 0)
		return -1
	EndIf
	dsName = dataSetNames[V_Value]
	
	size = DimSize(dsFilters,0)
	For(i=0;i<size;i+=1)
		//If no filter assignment is there, back compatability
		If(strlen(dsFilters[i][0]) == 0)
			dsFilters[i][0] = dataSetNames[i]
			dsFilters[i][1] = ";;;;;;;;"
		EndIf
		
		If(!cmpstr(dsFilters[i][0],dsName))
			filters = dsFilters[i][1]
			break
		EndIf
	EndFor
	
	
	
	//wave grouping variable
	SetVariable waveGrouping win=analysis_tools,value=_STR:StringFromList(3,filters,";")
	//prefix,group,series,etc. variables
	For(i=0;i<ItemsInList(groupList,";");i+=1)
		SetVariable $StringFromList(i,groupList,";") win=analysis_tools,value=_STR:StringFromList(i+4,filters,";")
	EndFor	
	//match box strings
	SetVariable waveMatch win=analysis_tools,value=_STR:StringFromList(0,filters,";")
	SetVariable waveNotMatch win=analysis_tools,value=_STR:StringFromList(1,filters,";")
	SetVariable relativeFolderMatch win=analysis_tools,value=_STR:StringFromList(2,filters,";")
End

Function updateWSDimText()
	Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetNames
	Wave selWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave matchListselWave = root:Packages:analysisTools:AT_selWave
	
	ControlInfo/W=analysis_tools dataSetListBox
	Variable selection = V_Value
	Variable i,numWaves
	
	//No data set available
	If(DimSize(listWave,0) == 0)
		numWaves = DimSize(waveListTable,0)
		String dims = "1"
		DrawAction/W=analysis_tools delete		
		DrawText/W=analysis_tools 142,117,num2str(ItemsInList(dims)) + "/" + num2str(numWaves)
		return 0
	EndIf
	
	If(selection == -1)
		dims = GetWaveSetDims("")
	Else
		dims = GetWaveSetDims(listWave[selection])
	EndIf
	
	numWaves = 0
	For(i=0;i<ItemsInList(dims,";");i+=1)
		numWaves += str2num(StringFromList(i,dims,";"))
	EndFor
	
	DrawAction/W=analysis_tools delete		
	DrawText/W=analysis_tools 142,117,num2str(ItemsInList(dims)) + "/" + num2str(numWaves)
End


//Inputs data set name, and either wsn or wsLabel. Returns string list of waves in that wave set
Function/S getWaveSet(dsName,[wsn,wsLabel])
	String dsName
	Variable wsn
	String wsLabel
	String item,wsList = ""
	Variable pos1,pos2,index,i
	
	//Find the selected dataset
	If(isDataSet(dsName))
		Wave/T ds = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
	Else
		Wave/T ds = root:Packages:analysisTools:AT_waveListTable_FullPath
	EndIf
	
	//Defaults
	If(ParamIsDefault(wsn))
		wsn = -1
	EndIf
	
	If(ParamIsDefault(wsLabel))
		wsLabel = ""
	Else
		pos1 = strsearch(wsLabel,"WSN ",0)
		pos2 = strsearch(wsLabel,"--",pos1)
		String ws = wsLabel[pos1+4,pos2-1]
		wsn = str2num(wsLabel[pos1+4,pos2])
	EndIf
	
	//If nothing was input, return empty string
	If(wsn == -1 && strlen(wsLabel) == 0)
		return ""
	EndIf
	
	index = tableMatch("*WSN " + num2str(wsn) + "*",ds)
	i = 1
	Do
		If(index + i > DimSize(ds,0) - 1)
			return wsList
		EndIf
		item = ds[index+i]
		
		If(stringmatch(item,"*WSN*"))
			return wsList
		EndIf
		
		wsList += item + ";"
		i+=1
	While(index+i < DimSize(ds,0))
	
	return wsList
End

//Returns the selected data set name
Function/S whichDataSet()
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	ControlInfo/W=analysis_tools dataSetListBox
	If(DimSize(dataSetNames,0) == 0)
		return ""
	EndIf
	
	If(V_Value == -1)
		return ""
	EndIf
	
	return dataSetNames[V_Value]
End

//Returns the wave reference for the selected or named data set
Function/WAVE getDataSetWave([dsName,original])
	String dsName
	Variable original//if you want the ungrouped version of the data set
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	
	If(ParamIsDefault(dsName))
		ControlInfo/W=analysis_tools dataSetListBox
		
		If(V_Value > DimSize(dataSetNames,0) - 1)
			return $""
		EndIf
		
		If(V_Value == -1)
			Wave/T theWave = root:Packages:analysisTools:AT_waveListTable_FullPath
		Else
			If(original)
				dsName = "root:Packages:analysisTools:DataSets:ogDS_" + dataSetNames[V_Value]
			Else
				dsName = "root:Packages:analysisTools:DataSets:DS_" + dataSetNames[V_Value]
			EndIf
			If(WaveExists($dsName))
				Wave/T theWave = $dsName
			EndIf
		EndIf
		return theWave
	Else
		If(original)
			dsName = "root:Packages:analysisTools:DataSets:ogDS_" + dsName
		Else
			dsName = "root:Packages:analysisTools:DataSets:DS_" + dsName
		EndIf
		
		If(WaveExists($dsName))
			Wave/T theWave = $dsName
			return theWave
		EndIf
	EndIf
End

Function DSEqualLength(DSList)
	String DSList
	Variable numDS = ItemsInList(DSList,";")
	Variable length,lastLength,i
	
	If(numDS == 0)
		return -1
	EndIf
	
	For(i=0;i<numDS;i+=1)
		Wave/T dataSetWave = getDataSetWave(dsName=StringFromList(i,DSList,";"))
		length = DimSize(dataSetWave,0)
		If(i == 0)
			lastLength = length
		Else
			If(length != lastLength)
				return 0
			EndIf
		EndIf
	EndFor
	
	return 1 //equal length data sets
End

//Takes the input string, and parses to see if there are data set references present. Lists all DS references
Function/S GetDSinList(theOp)
	String theOp
	String DSList = ""
	Variable startPos,endPos
	
	//Find start position of a DS reference
	endPos = 0
	Do
		startPos = strsearch(theOp,"<",endPos)
		If(startPos != -1)
			//Find end position of a DS reference
			endPos = strsearch(theOp,">",startPos)
			If(endPos == -1)
				Abort "Need ending bracket for data set reference"
			EndIf
			DSList += theOp[startPos+1,endPos-1] + ";"
		EndIf
	While(startPos != -1)
			
	return DSList
End

//Finds the selected data set name, outputs the list of waves defined by that data set
//If wavesets are defined, loops through them and produces separate output waves for each wsn

Function/S GetDSWaveList([dsName,separator])
	String dsName,separator
	If(ParamIsDefault(separator))
		separator = ","
	EndIf
	
	If(ParamIsDefault(dsName))
		String dataSetName = whichDataSet()
		
		If(strlen(dataSetName))
			//valid data set selected
			Wave/T ds = getDataSetWave()
		Else
			//no selection or invalid data set
			
			Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
		EndIf
	Else
		If(!cmpstr(dsName,"saveDSgrouping"))
			Wave/T ds = $("root:Packages:analysisTools:DataSets:ogDS_saveDSGrouping")
		Else
			Wave/T ds = getDataSetWave(dsName=dsName)
		EndIf
	EndIf
	
	If(!WaveExists(ds))
		Wave/T ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
	EndIf
	
	//Find if there are wavesets, and what are their dimensions?
	Variable i,j,pos,size = DimSize(ds,0)
	Variable numWaveSets = 0
	
	String theWaveList = ""
	
	For(i=0;i<size;i+=1)
		theWaveList += ds[i] + separator
	EndFor
	theWaveList = RemoveEnding(theWaveList,separator)
	return theWaveList

End

//Return number wavesets in dataset
Function GetNumWaveSets(dsName)
	String dsName
	
	If(isDataSet(dsName))
		Wave/T ds = getDataSetWave(dsName=dsName)
	Else
		//If there is no valid wave set selected, just use the waves listed in the wave list table
		Wave/T ds = root:Packages:analysisTools:AT_waveListTable_FullPath
	EndIf
	
	Variable i,pos,size,numWaveSets
	
	size = DimSize(ds,0)
	numWaveSets = 0
	pos = 0
	For(i=0;i<size;i+=1)
		pos = tableMatch("*WSN*",ds,startp=pos,endp=size-1)
		If(pos == -1)
			break
		Else
			pos += 1
			numWaveSets += 1
		EndIf
	EndFor
	
	//If none were found, make it 1 waveset
	If(numWaveSets == 0)
		numWaveSets = 1
	EndIf
	
	return numWaveSets
End

//Is the input data set name actually a data set?
Function	isDataSet(dsName)
	String dsName
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	Variable i
	
	If(strlen(dsName) == 0)
		return 0
	EndIf
	
	For(i=0;i<DimSize(dataSetNames,0);i+=1)
		If(!cmpstr(dataSetNames[i],dsName))
			return 1
		EndIf
	EndFor
	
	return 0
End

Function/S GetWaveSetDims(dsName)
	String dsName
	
	If(isDataSet(dsName))
		Wave/T ds = getDataSetWave(dsName=dsName)
	Else
		//If there is no valid wave set selected, just use the waves listed in the wave list table
		Wave/T ds = root:Packages:analysisTools:AT_waveListTable_FullPath
	EndIf	
		
	Variable i,pos,lastpos,size,dim,numWaveSets
	String wsDims = ""	
	
	size = DimSize(ds,0)
	pos = 0
	lastpos = 0
	For(i=0;i<size;i+=1)
		pos = tableMatch("*WSN*",ds,startp=pos,endp=size-1)
		
		If(pos == -1)
			//last waveset in the dataset
			dim = size- lastpos
			wsDims += num2str(dim) + ";"
			break
		Else
			If(numWaveSets > 0) //second or greater wave set label detected
				dim = pos - lastpos
				wsDims += num2str(dim) + ";"
			EndIf
			pos += 1
			numWaveSets += 1
		EndIf
		lastpos = pos
	EndFor
	
	return wsDims
End

Function/S InsertDSWaveNames(opStr,index)
	String opStr
	Variable index
	String DSList = GetDSinList(opStr)
	Variable i
	
	For(i=0;i<ItemsInList(DSList,";");i+=1)
		String theDataSet = StringFromList(i,DSList,";")
		String theWaveList = GetDSWaveList(dsName=theDataSet)
		String theItem = StringFromList(index,theWaveList,",")
		opStr = ReplaceString("<" + theDataSet + ">",opStr,theItem)
	EndFor
	
	return opStr
End

//Finds selected data set, updates it with the waves in the wave list box.
//Input the data set index to update a specific data set that isn't selected necessarily
Function updateSelectedDataSet([index])
	Variable index
	
	//get the data set wave
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	
	//Use selected data set if no index is provided
	If(ParamIsDefault(index))
		ControlInfo/W=analysis_tools dataSetListBox
		index = V_Value
	EndIf
	
	String dsName = dataSetNames[index]
	Wave/T ds = GetDataSetWave(dsName=dsName)
		
	//Wave list table
	Wave/T AT_waveListTable = root:Packages:analysisTools:AT_waveListTable
	
	Redimension/N=(DimSize(AT_waveListTable,0)) ds
	ds = AT_waveListTable
End

//Fills out the filter table for the selected data set
Function fillFilterTable()
	
	Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
	Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames

	//Fill in the data set filter table
	Variable currentNumSets = DimSize(dataSetNames,0)
	
	//Ensure correct wave dimensions
	If(currentNumSets == 0)
		return -1
	EndIf
	
	Redimension/N=(currentNumSets,2) dsFilters	
	ControlInfo/W=analysis_tools dataSetListBox
	
	If(V_Value == -1 || V_Value > currentNumSets)
		//no data set selected or invalid data set
		return -1
	EndIf
	
	
	dsFilters[V_Value][0] = dataSetNames[V_Value]
	dsFilters[V_Value][1] = GetDSFilters()

End

Function clearFilterSet()
	SetVariable prefixGroup win=analysis_tools,value=_STR:""
	SetVariable groupGroup win=analysis_tools,value=_STR:""
	SetVariable seriesGroup win=analysis_tools,value=_STR:""
	SetVariable sweepGroup win=analysis_tools,value=_STR:""
	SetVariable traceGroup win=analysis_tools,value=_STR:""
End

//If it finds any emtpy wavesets, eliminates them
Function checkWaveSets(ds)
	Wave/T/Z ds 
	
	String dataSetName = StringFromList(1,NameOfWave(ds),"_")
	Wave/T ogds = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
	
	Variable i,pos1,pos2,index,count
	
	//Remove any blank spaces
	For(i=0;i<DimSize(ds,0);i+=1)
		If(!strlen(ds[i]))
			DeletePoints i,1,ds
			i-=1
		EndIf
	EndFor
	
	For(i=0;i<DimSize(ogds,0);i+=1)
		If(!strlen(ogds[i]))
			DeletePoints i,1,ogds
			i-=1
		EndIf
	EndFor
	
	
	String dims = GetWaveSetDims(dataSetName)
	
	count = 0
	For(i=0;i<DimSize(ds,0);i+=1)
		String item = ds[i]
		If(stringmatch(item,"*WSN*"))
			pos1 = strsearch(item,"WSN ",0)
			pos2 = strsearch(item,"--",pos1)
			index = str2num(item[pos1+4,pos2-1])
			If(!cmpstr(StringFromList(index,dims,";"),"0"))
				DeletePoints i,1,ds
				i-=1
			Else
				//must number the wave sets correctly if there are empty wavesets in the beginning of the ds wave list
				ds[i] = "----WSN " + num2str(count) + "----"
				count += 1
			EndIf
		EndIf
	EndFor
End

//Takes input of prefix,group,series,sweep, or trace and filters the wave list accordingly
Function/S filterByGroup(ds)
	Wave/T/Z ds
	
	//List out all of the waves in the grouped data set
	String theList = TableToList(ds,",")
	
	String groupList = "prefixGroup;groupGroup;seriesGroup;sweepGroup;traceGroup"
	Variable i,j,k,numWaves,numTerms
	String waveTerm,filterTerms,theWave,theTerm,fullTermList,tempList
	
	//Get the inputs from all of the variables (prefix,group,series,etc.)
	Variable termCount = 0
	fullTermList = ""
	For(i=0;i<ItemsInList(groupList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,groupList,";")
		fullTermList += S_Value + ";"
		If(strlen(S_Value) > 0)
			termCount += 1
		EndIf
	EndFor
		
	numWaves = ItemsInList(theList,",")
	
	//Will hold the final waveset list
	Variable match = 0
	
	For(k=0;k<ItemsInList(fullTermList,";");k+=1)
		//each overall input term for prefix/group/etc.
		filterTerms = resolveListItems(StringFromList(k,fullTermList,";"),",")
		numTerms = ItemsInList(filterTerms,",")
				
		If(numTerms == 0)
			continue
		EndIf		
				
		For(i=0;i<ItemsInList(theList,",");i+=1)
			theWave = ParseFilePath(0,StringFromList(i,theList,","),":",1,0)
			
			//skip over wave set markers
			If(stringmatch(theWave,"*WSN*"))
				continue
			EndIf
		
			//Gets the term in the wave name to compare it to
			//Uses the overall term position (prefix/group/series) for this
			waveTerm = StringFromList(k,theWave,"_")	
			
			//Does the wave match any of the wave terms in this term slot? (prefix,group,series,etc.)
			match = 0
			For(j=0;j<numTerms;j+=1)
				//subterm within prefix/group/etc.
				theTerm = StringFromList(j,filterTerms,",")
				If(cmpstr(waveTerm,theTerm))
				//no match
					match = 0
				Else
				//match
					match = 1
					break
				EndIf
			EndFor
			
			//If one of the terms in the list matched the wave, keep it in the list
			If(!match)
				theList = RemoveListItem(i,theList,",")
				i -= 1
			EndIf
		EndFor
	EndFor
	
	//Input the new list into the data set wave
	Redimension/N=(ItemsInList(theList,",")) ds
	
	For(i=0;i<ItemsInList(theList,",");i+=1)
		ds[i] = StringFromList(i,theList,",")
	EndFor
	
	return theList
End

//Reorganizes the waves in the data set according to the wave grouping
Function setWaveGrouping(original,ds)
	Wave/T original
	Wave/T ds
	
	Variable numGroupings,numWaves,item,i,j,k,wsn,count
	String term,name,matchName,matchTerm,dataSetName
	
	//Get data set name
	dataSetName = StringFromList(1,NameOfWave(ds),"_")
	
	//reset the wave groupings to the original ungrouped state
	Redimension/N=(DimSize(original,0)) ds
	ds = original
	
	ControlInfo/W=analysis_tools waveGrouping
	String grouping = S_Value
	
	//extract /WG and /WSI and /WSN flags
	//if there is no flag, the entry is treated as a wave grouping
	//if there are flags, wave grouping can be placed prior to /WSI and /WSN flags and be given no flag, 
	//or it can be given the /WG flag and placed anywhere in the entry
	
	//Perform the filtering/grouping in order of appearance
	String itemStr = "",flag = "",value=""
	Variable numItems = ItemsInList(grouping,"/")
	For(i=0;i<numItems;i+=1)
		itemStr = StringFromList(i,grouping,"/")
		flag = StringFromList(0,itemStr,"=")
		value = StringFromList(1,itemStr,"=")
		
		//itemize the list ('1-5' becomes '1,2,3,4,5')
		If(strlen(value))
			value = resolveListItems(value,",")
		EndIf
		
		//filter or sort the data set, depending on the flag
		strswitch(flag)
			case "WG":
				sortByWaveGroup(original,ds,value)
				break
			case "WSI":
				filterByWaveSetIndex(ds,value)
				break
			case "WSN":
				filterByWaveSetNumber(ds,value)
				break
			case "B":
				//block flag, this separates everything into specific size blocks of waves
				//must be placed first in the order for it to work
				filterByBlockSize(original,ds,value)
				break
			case "S":
				//stride flag, this separates all waves within a waveset by every /S=x wave.
				//So for /S=8, every 8th wave will be in a waveset starting with the first wave, then every 8th starting with the second, etc.
				filterByStride(original,ds,value)
				break
			default:
				sortByWaveGroup(original,ds,itemStr)
				break
		endswitch
	EndFor
End

//orgnizes a dataset by the indicated underscore position
Function sortByWaveGroup(original,ds,value)
	Wave/T original
	Wave/T ds
	String value
	
	Variable numGroupings,numWaves,item,i,j,k,wsn,count
	String term,name,matchName,matchTerm,dataSetName
	
	//Get data set name
	dataSetName = StringFromList(1,NameOfWave(ds),"_")

	numGroupings = ItemsInList(value,",")
	numWaves = DimSize(ds,0)
	
	//make working waves
	Make/T/FREE/N=(numWaves) tempDS
	Make/FREE/N=(numWaves) matched
	
	matched = -1
	//wsn = 0
	
	For(i=0;i<numGroupings;i+=1)
		wsn = 0
		item = str2num(StringFromList(i,value,","))
		switch(item)
			case -2:
				//group all together
				For(j=DimSize(ds,0)-1;j>-1;j-=1) //go backwards
					If(stringmatch(ds[j],"*WSN*"))
						DeletePoints j,1,ds
					EndIf
				EndFor
				//Redimension/N=(DimSize(original,0)) ds
				//ds = original
				break
			default:
				//group by the index

				//If the data set is already grouped, must do next grouping within that structure
				Variable m,numWaveSets = GetNumWaveSets(dataSetName)
				String wsDims = GetWaveSetDims(dataSetName)
				numWaves = DimSize(ds,0)
				
				//make fresh working waves
				Make/T/FREE/N=(numWaves) tempDS
				Make/FREE/N=(numWaves) matched
				Make/T/FREE/N=(DimSize(ds,0)) original2
				original2 = ds
				
				matched = -1	
				count = 0
				
				For(m=0;m<numWaveSets;m+=1)
					//uses block of waves from each subsequent waveset
					numWaves = str2num(StringFromList(m,wsDims,";"))
					String theWaves = getWaveSet(dataSetName,wsn=m)
					
					For(j=0;j<numWaves;j+=1)
						
						If(matched[j + count] != -1)
							continue
						EndIf
						
						//name = ParseFilePath(0,ds[j],":",1,0)
						name = ParseFilePath(0,StringFromList(j,theWaves,";"),":",1,0)
						term = StringFromList(item,name,"_")
						
						For(k=0;k<numWaves;k+=1)
							If(matched[k + count] != -1)
								continue
							EndIf
							//matchName = ParseFilePath(0,ds[k],":",1,0)
							matchName = ParseFilePath(0,StringFromList(k,theWaves,";"),":",1,0)
							matchTerm = StringFromList(item,matchName,"_")
						
							If(!cmpstr(term,matchTerm))
								matched[k + count] = wsn
							EndIf	
							
						EndFor
						wsn += 1
					EndFor
					count += numWaves
				EndFor
				
				//Label first wave set, if there are more than 1
				count = 0

				//make copy of it without the wave set labels
				Variable size = DimSize(original2,0)
				For(j=0;j<size;j+=1)
					If(stringmatch(original2[j],"*WSN*"))
						DeletePoints j,1,original2
						j -= 1
						size -= 1
					EndIf
				EndFor
				
				If(wsn > 0)
					InsertPoints 0,1,tempDS
					tempDS[count] = "----WSN 0----"
					count += 1
				EndIf
				
				//sort data set
				numWaves = DimSize(original,0)
								
				For(j=0;j<wsn;j+=1)
					For(k=0;k<numWaves;k+=1)
						If(matched[k] == j)
							tempDS[count] = original2[k]
							count +=1
						EndIf	
					EndFor
					
					If(j<wsn-1)
						InsertPoints count,1,tempDS
						tempDS[count] = "----WSN " + num2str(j+1) + "----"
					EndIf
					count+=1
				EndFor
				
				Redimension/N=(DimSize(tempDS,0)) ds
				ds = tempDS
		endswitch
	EndFor
End

//orgnizes a dataset by the wave set index
Function filterByWaveSetIndex(ds,value)
	Wave/T ds
	String value
	Variable i,j,count,endPt,startPt,numWaveSets,waveSetSize,totalSize = DimSize(ds,0)
	String wsDims = "",waveEntry = ""
	
	//Get data set name
	String dataSetName = StringFromList(1,NameOfWave(ds),"_")
	
	value = "," + value//put in starting comma for matching purposes
	
	//dimensions of current organization
	wsDims = getWaveSetDims(dataSetName)
	numWaveSets = ItemsInList(wsDims,";")
	
	If(numWaveSets == 1)
		Variable offset = 0
	Else
		offset = 1
	EndIf
	
	For(j=numWaveSets-1;j>-1;j-=1) //go backwards
		waveSetSize = str2num(StringFromList(j,wsDims,";"))
		
		count = waveSetSize - 1
		
		//start and end indices of each waveset, start is high, end is low.
		endPt = totalSize - (numWaveSets - j)*waveSetSize -  (numWaveSets - (j + 1)) * offset //offset is only used when there is more than 1 waveset
		startPt = endPt + waveSetSize - 1
		
		For(i=startPt;i>endPt-1;i-=1) //go backwards
			//If the wsi is not in the flag value, delete from dataset
			If(!StringMatch(value,"*," + num2str(count) + ",*"))
				DeletePoints i,1,ds
			EndIf
			count -= 1
		EndFor
	EndFor

End

//orgnizes a dataset by the wave set number
Function filterByWaveSetNumber(ds,value)
	Wave/T ds
	String value
	Variable i,j,count,endPt,startPt,numWaveSets,waveSetSize,totalSize = DimSize(ds,0)
	String wsDims = "",waveEntry = ""
	
	//Get data set name
	String dataSetName = StringFromList(1,NameOfWave(ds),"_")
	
	value = "," + value//put in starting comma for matching purposes
	
	//dimensions of current organization
	wsDims = getWaveSetDims(dataSetName)
	numWaveSets = ItemsInList(wsDims,";")
	
	If(numWaveSets == 1)
		Variable offset = 0
	Else
		offset = 1
	EndIf
	
	For(j=numWaveSets-1;j>-1;j-=1) //go backwards
		waveSetSize = str2num(StringFromList(j,wsDims,";"))
		
		//start and end indices of each waveset, start is high, end is low.
		endPt = totalSize - (numWaveSets - j)*waveSetSize -  (numWaveSets - (j + 1)) * offset //offset is only used when there is more than 1 waveset
		
		If(!StringMatch(value,"*," + num2str(j) + ",*"))
			DeletePoints endPt-1,waveSetSize+1,ds
		EndIf
	EndFor
	
End

Function filterByBlockSize(original,ds,value)
	Wave/T original,ds
	String value
	
	//Get data set name
	String dataSetName = StringFromList(1,NameOfWave(ds),"_")
	
	Variable waveSetSize,numWaveSets,blockSize,nextBlock,count,i,j,numWaves,index
	
	numWaves = DimSize(original,0)
	//reset the wave groupings to the original ungrouped state
	//Redimension/N=(numWaves) ds
	//ds = original
	
	Make/T/N=(numWaves)/FREE tempDS
	
	//dimensions of current organization
	String wsDims = getWaveSetDims(dataSetName)
	numWaveSets = ItemsInList(wsDims,";")
	
	blockSize = str2num(value)
	index = 0
	
	For(j=0;j<numWaveSets;j+=1)
		waveSetSize = str2num(StringFromList(j,wsDims,";"))
		String theWaves = getWaveSet(dataSetName,wsn=j)
		
		count = 0
		nextBlock = 0
	
		For(i=0;i<waveSetSize;i+=1)
			If(i == nextBlock)
				InsertPoints index + count,1,tempDS
				tempDS[index] = "----WSN " + num2str(count) + "----"
				index += 1
				tempDS[index] = StringFromList(i,theWaves,";")
				index += 1
				count += 1
				nextBlock = blockSize * count
			Else
				tempDS[index] = StringFromList(i,theWaves,";")//ds[i-count]
				index += 1 
			EndIf
		EndFor
	EndFor
	
	//if last waveset is emtpy, delete it
	If(stringmatch(tempDS[DimSize(tempDS,0)-1],"*WSN*"))
		DeletePoints DimSize(tempDS,0)-1,1,tempDS
	EndIf
	
	Redimension/N=(DimSize(tempDS,0)) ds
	ds = tempDS
	
End

Function filterByStride(original,ds,value)
	Wave/T original,ds
	String value
	
	Variable numWaves,stride = str2num(value)
	Variable nextStride,numStrides,j,k,i,count,waveSetSize,numWaveSets,index
	
	//Get data set name
	String dataSetName = StringFromList(1,NameOfWave(ds),"_")
	
	numWaves = DimSize(original,0)
	
	Make/T/N=(numWaves)/FREE tempDS
	
	//dimensions of current organization
	String wsDims = getWaveSetDims(dataSetName)
	numWaveSets = ItemsInList(wsDims,";")
	
	For(j=0;j<numWaveSets;j+=1)
		//Get the waves in the waveset
		waveSetSize = str2num(StringFromList(j,wsDims,";"))
		String theWaves = getWaveSet(dataSetName,wsn=j)
		
		numStrides = floor(waveSetSize / stride)
		count = 0
		//cycle through each set of strides through the wave set
		For(k=0;k<stride;k+=1)
			//insert another WSN reference in the data set
			InsertPoints index + k,1,tempDS
			tempDS[index] = "----WSN " + num2str(count) + "----"
			index += 1
			
			//cycle through each wave in the waveset, by the stride length
			For(i=count;i<waveSetSize;i+=stride)
				tempDS[index] = StringFromList(i,theWaves,";")
				index += 1 
			EndFor
			
			count += 1
		EndFor
	EndFor
	
	//if last waveset is emtpy, delete it
	If(stringmatch(tempDS[DimSize(tempDS,0)-1],"*WSN*"))
		DeletePoints DimSize(tempDS,0)-1,1,tempDS
	EndIf
	
	Redimension/N=(DimSize(tempDS,0)) ds
	ds = tempDS
	
End

//updates the wave list box to show the contents of the selected data set
Function updateDSListBox(ds)
	Wave/T ds
	Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
	Wave matchListselWave = root:Packages:analysisTools:AT_selWave
	Variable i
				
	If(!WaveExists(ds))
		return -1
	EndIf		
	
	Redimension/N=(DimSize(ds,0)) waveListTable,matchListselWave
	For(i=0;i<DimSize(ds,0);i+=1)
		waveListTable[i] = ParseFilePath(0,ds[i],":",1,0)
	EndFor

End
