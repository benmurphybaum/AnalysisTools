#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Called by the buttons
Function atButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	SVAR runCmdStr = root:Packages:analysisTools:runCmdStr
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	SVAR selectedWave = root:Packages:analysisTools:selectedWave
	SVAR whichList = root:Packages:analysisTools:whichList
	
	//Parameters
	NVAR Gnumtrials = root:Packages:analysisTools:Gnumtrials
	NVAR Gbatchsize = root:Packages:analysisTools:Gbatchsize
	NVAR GpeakSt = root:Packages:analysisTools:GpeakSt 
	NVAR GpeakEnd = root:Packages:analysisTools:GpeakEnd 
	NVAR GbslnSt = root:Packages:analysisTools:GbslnSt
	NVAR GbslnEnd = root:Packages:analysisTools:GbslnEnd
	NVAR Gred = root:Packages:analysisTools:Gred
	NVAR Ggreen = root:Packages:analysisTools:Ggreen
	NVAR Gblue = root:Packages:analysisTools:Gblue
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	Variable i

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlName)
				case "AT_RunCmd":
					ControlInfo/W=analysis_tools AT_CommandPop
					
					strswitch(S_Value)
						case "Line Profile":
							ControlInfo/W=analysis_tools SR_WaveList
							runCmdStr = ""
							runCmdStr = "DoWindow/F " + S_Value + ";getLineProfile()"
							RunCmd(runCmdStr)
							break
						case "Run Cmd Line":
							SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
							NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
							NVAR wsn = root:Packages:analysisTools:DataSets:wsn
							wsDims = ""
							numWaveSets = 0
							ControlInfo/W=analysis_tools cmdLineStr
							String cmdLineStr = S_Value
							
							Variable pos1 = 0,pos2 = 0,j,numWaves
							String dsRefList = "",dsName = ""
							
							//Find the data set references in the command string
							Do
								pos1 = strsearch(S_Value,"<",0)
								pos2 = strsearch(S_Value,">",pos1)
								If(pos1 != -1 && pos2 != -1)
									dsName = S_Value[pos1+1,pos2-1]
									dsRefList += dsName + ";"
									S_Value = S_Value[pos2+1,strlen(S_Value)-1]
								Else
									break
								EndIf
							While(pos1 != -1)
							
							//Test whether they have the same number of waveset dimensions
							String dims = GetWaveSetDims(StringFromList(0,dsRefList,";"))
							Make/FREE/N=(ItemsInList(dsRefList,";")) wsDimSize //holds number of waves in each waveset
							
							If(ItemsInList(dsRefList,";") > 0)	//if there are data set references, otherwise continue
								For(i=1;i<ItemsInList(dsRefList,";");i+=1)
									String testDims = GetWaveSetDims(StringFromList(i,dsRefList,";"))
									wsDimSize[i] = str2num(testDims)
									If(cmpstr(testDims,dims))
									//	Abort "Data sets must have the same dimensions"
									EndIf
								EndFor		
								
								dsName = StringFromList(0,dsRefList,";") //name of first data set found		
								numWaveSets = GetNumWaveSets(dsName)	//number wave sets
							Else
								numWaveSets = 1
							EndIf
							
							For(i=0;i<numWaveSets;i+=1)
								If(strlen(dsName))
									String theWaveSet = GetWaveSet(dsName,wsn=i)
									numWaves = ItemsInList(theWaveSet,";")
									numWaves = WaveMax(wsDimSize)

								Else
									numWaves = 1
								EndIf
								
								For(j=0;j<numWaves;j+=1)
									runCmdStr = resolveCmdLine(cmdLineStr,i,j)
									RunCmd(runCmdStr)
									print runCmdStr
								EndFor
							EndFor

							break
						case "Denoise":
							Variable denoise = 1
						case "External Function":
						case "Duplicate/Rename":
						case "Average":
						case "Error":
						case "Denoise":
						case "Mask Image":
						case "Max Project":
						case "Apply Map Threshold":
						case "Kill Waves":
							SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
							NVAR numWaveSets = root:Packages:analysisTools:DataSets:numWaveSets
							NVAR wsn = root:Packages:analysisTools:DataSets:wsn
							wsDims = ""
							numWaveSets = 0
							
							//Command string
							If(cmpstr(S_Value,"External Function") == 0)
								runCmdStr = SetExtFuncCmd()
							EndIf
						
							//WaveSet data
							ControlInfo/W=analysis_tools extFuncDS
							numWaveSets = GetNumWaveSets(S_Value)
							wsDims = GetWaveSetDims(S_Value)
							
							//If denoise function, only use one waveset
							If(denoise)
								numWaveSets = 1
							EndIf
							
							//Run the command for the designated number of wavesets
							Variable ref = StartMSTimer
							For(wsn=0;wsn<numWaveSets;wsn+=1)		
								RunCmd(runCmdStr)
							EndFor
							Variable dur = StopMSTimer(ref)/1000000
							print runCmdStr + "..." + num2str(numWaveSets) + " wavesets..." + num2str(dur) + " s"
							break
						default:
							RunCmd(runCmdStr)
							break
					endswitch

					break
				case "atBrowseBackButton":
					String parentDF = ParseFilePath(1,cdf,":",1,0)
					String childDF = ParseFilePath(0,cdf,":",1,0)
					
					
					SetDataFolder parentDF
					cdf = parentDF
					GetFolderListItems()
					GetFolderItems()
					
					Wave/T folderTable = root:Packages:analysisTools:folderTable
					Variable index = tableMatch(childDF,folderTable)
					
					Wave selFolderWave = root:Packages:analysisTools:selFolderWave
					selFolderWave = 0
					If(index != -1)
						selFolderWave[index] = 1
					EndIf
					ControlUpdate AT_cdf
					break
				case "nudgeAll":
					ControlInfo/W=analysis_tools nudgeAll	
									
					strswitch(S_title)
						case "Nudge All":
							//switch to show 'Done' 
							Button nudgeAll win=analysis_tools,title="Done"
							NudgeROI()
							break
						case "Done":
							//switch to show 'Nudge All' 
							Button nudgeAll win=analysis_tools,title="Nudge All"
							//shut down the hook function
							//have to get the top graph this way, since the top window is technically the toolbox itself
							String windows = WinList("*",";","WIN:1;VISIBLE:1")
							String graphStr = StringFromList(0,windows,";")
							String traceList = TraceNameList(graphStr,";",1)
							SetWindow $graphStr hook(myHook) = $""
							ModifyGraph/W=$graphStr quickDrag = 0
							
							//set the waves with new offsets
							For(i=0;i<ItemsInList(traceList,";");i+=1)
								String theTrace = StringFromList(i,traceList,";")
								String info = TraceInfo(graphStr,theTrace,0)
								String offsets = StringByKey("offset(x)",info,"=",";")
								
								Variable dx,dy
								sscanf offsets,"{%g,%g}",dx,dy
							
								Wave roiX = $("root:twoP_ROIS:" + RemoveEnding(theTrace,"y") + "x")
								Wave roiY = $("root:twoP_ROIS:" + theTrace)
								
								roiX += dx
								roiY += dy
								ModifyGraph/W=$graphStr offset($theTrace)={0,0}
							EndFor
							break
					endswitch
				
					break
				case "dispROI":
					roiToImage()
					break
							
				case "selectAll_Left":
					//select all scans,ROIs,folders, or wave items
					selectALL(ba.ctrlName,whichList)
					break
				case "selectAll_Right":
					Wave selWave = root:Packages:analysisTools:itemListSelWave
					Wave/T listWave = root:Packages:analysisTools:itemListTable
					SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
					//select all scans,ROIs,folders, or wave items
					selectALL(ba.ctrlName,whichList)
				
					String selWaveList = tableToList(listWave,";")
					AppendToViewer(selWaveList)
										
					//Set to null if a selection has changed.
					viewerRecall = ""
					
					break
				case "saveLineProfile":
					saveLineProfile()
					break
				case "applyLineProfile":
					applyLineProfile()
					break
				case "AT_Help":
					//ControlInfo/W=analysis_tools AT_CommandPop
					//AT_DisplayHelpMessage(S_Value)
					ControlInfo/W=analysis_tools AT_CommandPop
					If(!cmpstr(S_Value,"Data Sets"))
						DisplayHelpTopic "Data Sets"
					EndIf
					break
				case "extFuncHelp":
					ControlInfo/W=analysis_tools extFuncPopUp
					displayExtFuncHelp(S_Value)
					break
				case "ROISegmentButton":
					ControlInfo/W=analysis_tools maskListPopUp
					Wave theMask = $S_Value
					OpenMask(theMask)
					break
				case "applyImageRegistration":
					applyImageRegTemplate()
					break
				case "equalizeDimensions":
					EqualizeDimensions()
					break
				case "addPresetAngle":
					SVAR presetAngleLists = root:Packages:analysisTools:presetAngleLists
					Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
					
					String theAngles,theName
					
					Prompt theAngles,"Enter the angles: "
					Prompt theName,"Enter name of angle list: "
					DoPrompt "Add preset angle list",theName,theAngles
					If(V_Flag)
						return -1
					EndIf
					
					presetAngleLists += theName + ";"
					Variable size = DimSize(presetAngleWave,0)
					Redimension/N=(size+1,-1) presetAngleWave
					presetAngleWave[size][0] = theName
					presetAngleWave[size][1] = theAngles
					break
				case "deletePresetAngle":
					SVAR presetAngleLists = root:Packages:analysisTools:presetAngleLists
					Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
					
					ControlInfo/W=analysis_tools presetAngleListPop
					presetAngleLists = RemoveListItem(V_Value-1,presetAngleLists,";")
					DeletePoints V_Value-1,1,presetAngleWave
					break
				case "atBrowseButton":
					SVAR whichList = root:Packages:analysisTools:whichList
					
					If(cmpstr(whichList,"AT") == 0)
						whichList = "Browser"
					ElseIf(cmpstr(whichList,"Browser") == 0)
						whichList = "AT"
					EndIf
					
					flipLists(whichList)
					break
				case "addDataSet":
					Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
					ControlInfo/W=analysis_tools dataSetName
					addDataSet(S_Value)
					fillFilterTable()
					
					Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
					index = tableMatch(S_Value,dsFilters)
					dsFilters[index][1] = getListRange("0-2",dsFilters[index][1],";") + ";;;;;;;"
					
					break
				case "addDataSetFromSelection":
					Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
					ControlInfo/W=analysis_tools dataSetName	
					addDataSet(S_Value,selection=1)
					ListBox dataSetListBox win=analysis_tools,selRow=DimSize(dataSetNames,0)-1
					fillFilterTable()
					
					Wave/T dsFilters = root:Packages:analysisTools:DataSets:dsFilters
					index = tableMatch(S_Value,dsFilters)
					dsFilters[index][1] = getListRange("0-2",dsFilters[index][1],";") + ";;;;;;;"
					break
				case "delDataSet":
					Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetNames
					ControlInfo/W=analysis_tools dataSetListBox
					delDataSet(V_Value)
					
					If(V_Value == 0)
						ListBox dataSetListBox win=analysis_tools,selRow=V_Value
						index = V_Value						
					Else
						ListBox dataSetListBox win=analysis_tools,selRow=V_Value-1
						index = V_Value - 1
						Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + listWave[index])
						checkMissingWaves(listWave[index])
					EndIf
					
					
					//update the list box to show the newly selected data set
					UpdateDSListBox(dataSetWave)
					
					updateWSDimText()
					updateWSFilters()
					break
				case "reloadATButton":
					GetWindow/Z analysis_tools wsize
					KillWindow/Z analysis_tools
					
					LoadAnalysisSuite(left=V_left,top=V_top-50)
					//-50 accounts for the initial 50 pixel offset it gets upon first loading.
					break
				case "atViewerButton":
					If(viewerOpen)
						closeViewer()
					Else
						openViewer()
					EndIf
					break
				case "atViewerAutoScaleButton":
					SetAxis/W=analysis_tools#atViewerGraph/A
					break
				case "atViewerSeparateVertButton":
					SeparateTraces("vert")
					break
				case "atViewerSeparateHorizButton":
					SeparateTraces("horiz")
					break
				case "atViewerDisplayTracesButton":
					String theTraces = TraceNameList("analysis_tools#atViewerGraph",";",1)
	
					GetWindow/Z analysis_tools wsize
					//Duplicates the Viewer graph outside of the viewer
					String winRec = WinRecreation("analysis_tools#atViewerGraph",0)
					
					pos1 = strsearch(winRec,"/W",0)
					pos2 = strsearch(winRec,"/FG",0) - 1
					
					String matchStr = winRec[pos1,pos2]
					winRec = ReplaceString(matchStr,winRec,"/W=(" + num2str(V_right+10) + "," + num2str(V_top) + "," + num2str(V_right+360) + "," + num2str(V_top+200) + ")")
					winRec = ReplaceString("/FG=(FL,VT,FR,VB)/HOST=#",winRec,"")
					Execute/Q/Z winRec
					break
				case "atViewerClearTracesButton":
					clearTraces()
					break
				case "matchStraddOR":
					ControlInfo/W=analysis_tools waveMatch
					SetVariable waveMatch win=analysis_tools,value=_STR:S_Value + "||"
					break
				case "notMatchStraddOR":
					ControlInfo/W=analysis_tools waveNotMatch
					SetVariable waveNotMatch win=analysis_tools,value=_STR:S_Value + "||"
					break
				case "OpenABF2Loader":
					InitializeABFPanel()
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function atListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	SVAR scanListStr = root:Packages:twoP:examine:scanListStr
	SVAR ROIListStr = root:Packages:twoP:examine:ROIListStr
	SVAR selWaveList = root:Packages:analysisTools:selWaveList
	
	SVAR viewerRecall = root:Packages:analysisTools:viewerRecall
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	Variable i,scanNum
	
	selWaveList = ""
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
		
			break
		case 2: // mouse up
			strswitch(lba.ctrlName)
				case "AT_ItemListBox":
					selWaveList = ""

					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						EndIf
					EndFor

					//Add the traces to viewer if its in the analysis tab
					AppendToViewer(selWaveList)
					
					break
				default:
					break
			endswitch
			break
		case 3: // double click
			strswitch(lba.ctrlName)
				case "AT_FolderListBox":
					//ControlInfo/W=analysis_tools folderDepth
					Variable depth = 0
					
					If(row > DimSize(listWave,0)-1)
						break
					EndIf
					cdf = cdf + listWave[row] + ":"
					SetDataFolder cdf
					GetFolderListItems()
					GetFolderItems(depth=depth)
					ControlUpdate AT_cdf
					break
				case "WaveListBox":
					//populate scanListStr
					scanListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						scanListStr += listWave[i] + ";"
						scanNum = str2num(StringFromList(ItemsInList(listWave[i],"_")-1,listWave[i]	,"_"))
						Endif
					EndFor
					
					//if no scans were selected
					If(cmpstr(scanListStr,";") == 0)
						break
					EndIf
					
					//Adjust current scan on 2PLSM GUI
					SVAR curScan = root:Packages:twoP:examine:CurScan
					curScan = StringFromList(0,scanListStr,";")
					
					// Get some variables from scan note
					if (cmpStr (curScan, "LiveWave") == 0)
						SVAR ScanNote  = root:packages:twoP:Acquire:LiveModeScanStr
					else
						SVAR ScanNote = $"root:twoP_Scans:" + curScan + ":" + curScan+  "_info"
					endif
					variable mode = NumberByKey("mode",ScanNote, ":", "\r")
					variable doephys = NumberByKey("ephys",ScanNote, ":", "\r")
					
					//Append the new scan to scanGraph
					if (mode == kePhysOnly)
						DoWindow/K twoPscanGraph
						NQ_NewTracesGraph (curScan)
					else
						NQ_NewScanGraph (curScan)
						variable nTraces = 0//doEphys + GUIPCountObjs ("root:twoP_Scans:" + CurScan, 1, "*avg*", 0) + GUIPCountObjs ("root:twoP_Scans:" + CurScan, 1, "*ratio*", 0)
						if (nTraces == 0) 
							DoWindow/K twoP_TracesGraph
						else
							NQ_NewTracesGraph (curScan)
						endif
					endif
					// adjust the movie controls and visibility and change display
					NQ_Adjust_Examine_Controls (curScan)
					
					NVAR curScanNum = root:Packages:twoP:examine:curScanNum
					curScanNum = scanNum
					
					break
				case "ROIListBox":
				//populate ROIListStr
					ROIListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						ROIListStr += listWave[i] + ";"
						Endif
					EndFor
					
				//Jamie's code for adding an ROI to the scanGraph if it exists
					// If shift key was held down, then we are just plotting
					//variable justPlot = ((ba.EventMod & 2) == 2)
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
							appendtograph /W=$onWindow/C=(red, green, blue) RoiYWave vs RoiXwave
						endif
	
						// set quickDrag for selected rois
					//	if (!(justPlot))
					//		modifyGraph/W=$onWindow quickDrag ($roiStr + "_y")=1
					//		String/G root:packages:twoP:examine:NudgeOnWindow = onWindow
					//	endif
					endfor
				// if not just plotting, set nudge button to new title and new procedure
				//	if (!(justPlot))
				//		Button ROINudgeButton win=twoP_Controls, title = "Done", proc = NQ_RoiNudgeDoneButtonProc, fColor=(65535,0,0)
				//	endif
					break
					
					case "dataSetListBox":
						//Displays the data set in the Viewer if double clicked
						If(!viewerOpen)
							openViewer()
						EndIf
							
						Variable selection = lba.row
						Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_"+listWave[selection])
						Variable numWaves = DimSize(theDataSet,0)
						selWaveList = ""
						
						traceList = TraceNameList("analysis_tools#atViewerGraph",";",1)
						If(strlen(traceList))
							KillWindow/Z analysis_tools#atViewerGraph
							Display/HOST=analysis_tools/FG=(FL,VT,FR,VB)/N=atViewerGraph
						EndIf
						
						For(i=0;i<numWaves;i+=1)
							Wave/Z theWave = $theDataSet[i]
							Variable type = WaveType(theWave,1)
							If(type == 1)
								AppendToGraph/W=analysis_tools#atViewerGraph theWave
							EndIf
						EndFor
						
						//select all
						Wave/Z selWave = root:Packages:analysisTools:AT_SelWave
						selWave = 1
					break
			endswitch
			break
		case 4: // cell selection
			strswitch(lba.ctrlName)
				case "dataSetListBox":
					Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetNames
					Wave selWave = root:Packages:analysisTools:DataSets:dataSetSelWave
					Wave/T waveListTable = root:Packages:analysisTools:AT_waveListTable
					Wave/T AT_WaveListTable_FullPath = root:Packages:analysisTools:AT_WaveListTable_FullPath
					Wave/T ogAT_WaveListTable_UnGroup = root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
					Wave matchListselWave = root:Packages:analysisTools:AT_selWave
					
					selection = lba.row
					
					//If selection is past the item list
					If(selection > DimSize(listWave,0) - 1)
						break
					EndIf
					
					Wave/T dataSetWave = $("root:Packages:analysisTools:DataSets:DS_" + listWave[selection])
					Wave/T ogDataSetWave = $("root:Packages:analysisTools:DataSets:ogDS_" + listWave[selection])
					
					UpdateDSListBox(dataSetWave)
					
					checkMissingWaves(listWave[selection])
					updateWSDimText()
					updateWSFilters()
					
					//Set full path text wave to match the wave name text wave
					Redimension/N=(DimSize(ogDataSetWave,0)) ogAT_WaveListTable_UnGroup
					ogAT_WaveListTable_UnGroup = ogDataSetWave
					Redimension/N=(DimSize(dataSetWave,0)) AT_waveListTable_FullPath
					AT_waveListTable_FullPath = dataSetWave
					break
				case "extFuncDSListBox":
						Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
						Wave selWave = root:Packages:analysisTools:DataSets:dsSelWave
						selWaveList = ""
						For(i=0;i<DimSize(listWave,0);i+=1)
							If(selWave[i] == 1)
								selWaveList += listWave[i] + ";"
							EndIf
						EndFor
						
						ControlInfo/W=analysis_tools extFuncDS
						Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_" + S_Value)
						
						AppendDSWaveToViewer(selWave,selWaveList,theDataSet)
						break
				case "AT_ItemListBox":	
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						EndIf
					EndFor
					
					AppendToViewer(selWaveList)
										
					//Set to null if a selection has changed.
					viewerRecall = ""
					break
				endswitch
		case 5: // cell selection plus shift key
			strswitch(lba.ctrlName)
				case "WaveListBox":
					//populate scanListStr
					scanListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						scanListStr += listWave[i] + ";"
						Endif
					EndFor
					break
				case "ROIListBox":
					//populate ROIListStr
					ROIListStr = ""
					For(i=0;i<DimSize(selWave,0);i+=1)
						If(selWave[i] == 1)
						ROIListStr += listWave[i] + ";"
						Endif
					EndFor
					break
				case "extFuncDSListBox":
					Wave/T listWave = root:Packages:analysisTools:DataSets:dataSetListWave_NamesOnly
					Wave selWave = root:Packages:analysisTools:DataSets:dsSelWave
					
					ControlInfo/W=analysis_tools extFuncDS
					String dsName = S_Value
					Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_" + dsName)				
					Variable fullPathList = 0
					
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
							
							//If we hit a waveset label
							If(stringmatch(listWave[i],"*WSN*"))
								Variable index = tableMatch(listWave[i],theDataSet)
								selWaveList = ReplaceString(listWave[i] + ";",selWaveList,"")	//remove the wsLabel from the list
								selWaveList += getWaveSet(dsName,wsLabel=listWave[i])	//add in the entire waveset to the list
								fullPathList = 1
							EndIf
						EndIf
					EndFor	
			
					AppendDSWaveToViewer(selWave,selWaveList,theDataSet,fullPathList=fullPathList)
					break
				case "matchListBox":
					Wave/T listWave = root:Packages:analysisTools:AT_WaveListTable
					Wave selWave = root:Packages:analysisTools:AT_selWave
					
					dsName = whichDataSet()
					Wave/T theDataSet = $("root:Packages:analysisTools:DataSets:DS_" + dsName)
					
					If(!WaveExists(theDataSet))
						Wave/T theDataSet = root:Packages:analysisTools:AT_WaveListTable_FullPath
					EndIf
					
					fullPathList = 0
					
					selWaveList = ""
					For(i=0;i<DimSize(theDataSet,0);i+=1)
						If(i > DimSize(selWave,0) - 1)
							break
						EndIf
						
						If(selWave[i] == 1)
							selWaveList += theDataSet[i] + ";"
						
							//If we hit a waveset label
							If(stringmatch(theDataSet[i],"*WSN*"))
								selWaveList = ReplaceString(theDataSet[i] + ";",selWaveList,"")	//remove the wsLabel from the list
								selWaveList += getWaveSet(dsName,wsLabel=theDataSet[i])	//add in the entire waveset to the list
								fullPathList = 1
							EndIf
						EndIf
					EndFor			
					
					AppendDSWaveToViewer(selWave,selWaveList,theDataSet,fullPathList=fullPathList)
					break
				case "AT_ItemListBox":	
					selWaveList = ""
					For(i=0;i<DimSize(listWave,0);i+=1)
						If(selWave[i] == 1)
							selWaveList += listWave[i] + ";"
						EndIf
					EndFor
					
					AppendToViewer(selWaveList)
										
					//Set to null if a selection has changed.
					viewerRecall = ""
					break
				case "fileListBox":
					//PClamp Browser file selection
					//Loads the sweeps into memory and displays their names it the sweep list box
					LoadABF(fromAT=1)
					break
			endswitch
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End


//Called by the check boxes
Function atCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			strswitch(cba.ctrlName)
				case "SmoothBox":
				//// Temporal filter check box/////////////

					break
				case "SpaceFilterBox":
				//// Spatial filter check box/////////////

					break
				case "DarkSubtBox":
				//// Dark subtraction/////////////

					break
				case "NotSeqBox":
					string curFolder = getdatafolder(1)
					setdatafolder "root:"
					variable/G NotInSequence = checked
					setdatafolder curFolder 
					
					break
			endswitch
			
			
		case -1: // control being killed
			break
	endswitch
	return 0
End


//Called by the pop up menus
Function atPopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	SVAR prevCmd = root:Packages:analysisTools:prevCmd
	SVAR runCmdStr = root:Packages:analysisTools:runCmdStr
	
	
	
	switch( pa.eventCode )

		case 2: // mouse up
		
			strswitch(pa.ctrlName)
				case "AT_CommandPop":
					Variable popNum = pa.popNum
					String popStr = pa.popStr
			
					If(cmpstr(popStr[0],"-") == 0)
						return 0
					EndIf
			
					prevCmd = currentCmd
					currentCmd = popStr
					ChangeControls(currentCmd,prevCmd)
					
					//Refresh external function page when it opens
					If(cmpstr(pa.popStr,"External Function") == 0)
						Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
						SVAR DSNames = root:Packages:analysisTools:DSNames
						DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
					
						KillExtParams()
						ControlInfo/W=analysis_tools extFuncPopUp
						ResolveFunctionParameters("AT_" + S_Value)
						recallExtFuncValues(S_Value)
						//Toggle the channel pop up menu
						ControlInfo/W=analysis_tools extFuncDS
						If(cmpstr(S_Value,"--Scan List--") == 0)
							//Scan list selection
							If(cmpstr(currentCmd,"Get Peaks") == 0)
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=0
							Else
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=0
							EndIf
							ListBox extFuncDSListBox win=analysis_tools,disable=1
							DrawAction/W=analysis_tools delete
						ElseIf(cmpstr(S_Value,"--None--") == 0 || cmpstr(S_Value,"--Item List--") == 0)
							//Item List selection or no wave selection
							If(cmpstr(currentCmd,"Get Peaks") == 0)
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							Else
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							EndIf
							ListBox extFuncDSListBox win=analysis_tools,disable=1
							DrawAction/W=analysis_tools delete
						Else
							//Data set selection
							If(cmpstr(currentCmd,"Get Peaks") == 0)
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							Else
								PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
							EndIf
							
							SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
							DrawText/W=analysis_tools 230,117,"Waves:"
							OpenExtFuncWaveListBox(S_Value)
						EndIf
					Else
						strswitch(pa.popStr)
							case "Denoise":
							case "Average":
							case "Mask Image":
							case "Dynamic ROI":
							case "Error":
							case "Kill Waves":
							case "Run Cmd Line":
							case "Duplicate/Rename":
								Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
								SVAR DSNames = root:Packages:analysisTools:DSNames
								DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")		
								break
						endswitch
					EndIf
					
					break
				case "presetAngleListPop":
					popNum = pa.popNum
					popStr = pa.popStr
					Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
					SetVariable angleList win=analysis_tools,value=_STR:presetAngleWave[popNum-1][1]
					SetVariable scanOrderROIdisplay win=analysis_tools,value=_STR:presetAngleWave[popNum-1][1]
					ControlUpdate/W=analysis_tools angleList
					ControlUpdate/W=analysis_tools scanOrderROIdisplay
					break
				case "operationOptionsPop":
					popStr = pa.popStr
					SetVariable operation win=analysis_tools,value=_STR:popStr	
					break
				case "extFuncPopUp":
					KillExtParams()
					ResolveFunctionParameters("AT_" + pa.popStr)
					recallExtFuncValues(pa.popStr)
					break
				case "extFuncDS":
					SetExtFuncMenus(pa.popStr)
					SVAR wsDims = root:Packages:analysisTools:DataSets:wsDims
					wsDims = GetWaveSetDims(pa.popStr)
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function atSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	Wave/T WaveListDS = root:Packages:analysisTools:DataSets:WaveListDS
	Wave/T ogWaveListDS = root:Packages:analysisTools:DataSets:ogWaveListDS	
		
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
				//Get wave match string
			strswitch(sva.ctrlName)
				case "waveMatch":
					SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
					waveMatchStr = sval
					
					String df = GetDataFolder(1)
					
					//Remove selection from the data set box
					ListBox dataSetListBox win=analysis_tools,selRow=-1
					String dataSetName= whichDataSet()
					
					clearFilterSet()
					
					getWaveMatchList()
					fillFilterTable()
					updateWSDimText()
					SetDataFolder $df
					
					If(!strlen(dataSetName))
						//Save the wave list table prior to grouping again, ensures its correct
						Wave/T/Z ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
						Duplicate/T/O ds,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_FullPath,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
					EndIf
					
					SetDataFolder $df
					
					break
				case "waveNotMatch":
					SVAR waveNotMatchStr = root:Packages:analysisTools:waveNotMatchStr
					waveNotMatchStr = sval
					
					df = GetDataFolder(1)
					//Remove selection from the data set box
					ListBox dataSetListBox win=analysis_tools,selRow=-1
					dataSetName= whichDataSet()
					
					clearFilterSet()
					
					getWaveMatchList()
					fillFilterTable()
					updateWSDimText()
					SetDataFolder $df
					
					If(!strlen(dataSetName))
						//Save the wave list table prior to grouping again, ensures its correct
						Wave/T/Z ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
						Duplicate/T/O ds,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_FullPath,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
					EndIf
					
					SetDataFolder $df
					
					break	
				case "relativeFolderMatch":
					df = GetDataFolder(1)
					//Remove selection from the data set box
					ListBox dataSetListBox win=analysis_tools,selRow=-1
					clearFilterSet()
					getWaveMatchList()
					fillFilterTable()
					updateWSDimText()	
					SetDataFolder $df
					
					If(!strlen(dataSetName))
						//Save the wave list table prior to grouping again, ensures its correct
						Wave/T/Z ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
						Duplicate/T/O ds,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_FullPath,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
					EndIf

					SetDataFolder $df
					break
				case "prefixGroup":
				case "groupGroup":
				case "seriesGroup":
				case "sweepGroup":
				case "traceGroup":		
				case "waveGrouping":			
					dataSetName= whichDataSet()
					
					//If no data set is selected, use the wave present in the match list box
					If(!strlen(dataSetName))
						Wave/T/Z waveListTable = getWaveMatchList() //also gets the full path
						Wave/T/Z ds = root:Packages:analysisTools:AT_WaveListTable_FullPath
						
						//original ungrouped list
						Wave/T/Z original = root:Packages:analysisTools:DataSets:ogAT_WaveListTable_FullPath
						
						Duplicate/O original,root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
						Wave/T/Z unGrouped = root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
						
						//filter the waves
						filterByGroup(ds)
						filterByGroup(unGrouped)
								
						//group the waves
						setWaveGrouping(unGrouped,ds)
						
						//make sure wave sets are all valid dimensions	
						checkWaveSets(ds)
						
						//update the list box and wave counters
						updateWaveListBox()
						updateWSDimText()
						
					Else
						//data set
						Wave/T/Z ds = GetDataSetWave(dsName = dataSetName)
						
						//original ungrouped list
						Wave/T/Z original = $("root:Packages:analysisTools:DataSets:ogDS_" + dataSetName)
						
						//group the waves
						setWaveGrouping(original,ds)
						
						//filter the waves
						filterByGroup(ds)
						
						//make sure wave sets are all valid dimensions	
						checkWaveSets(ds)
						
						//fill out the filter table
						fillFilterTable()
						
						//update the list box and wave counters
						updateWaveListBox()
						updateWSDimText()
					EndIf
	
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

Function AT_ScanRegistryButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	String windowName,errStr
	Wave coordinates = root:var:roiCoord
	SVAR roiXlist = root:var:roiXlist
	SVAR roiYlist = root:var:roiYlist
	NVAR hidden = root:var:hidden
	Variable i,j,k
	String roiNameY,roiNameX
	
	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlName)
				case "SR_autoRegisterButton":
					ControlInfo/W=analysis_tools SR_autoRegisterButton
					String info = StringByKey("title",S_recreation,"=",",")
			
					If(strlen(info) > 10)
						info = info[0,10]
					EndIf
			
					If(StringMatch(info,"*Auto*"))
						errStr = AT_SetupROICapture()
						If(cmpstr(errStr,"-1") == 0)
							return -1
						Else
							ControlInfo/W=analysis_tools SR_waveList
							windowName = S_Value 
						EndIf
				
						Button SR_autoRegisterButton win=analysis_tools,title="Done",fColor=(65535,32764,16385)
						Button SR_addROIButton win=analysis_tools,disable=0
					//	Button SR_saveWaveformButton win=ScanRegistry,disable = 1
					//	Button SR_applyTemplate win=ScanRegistry, disable = 1
						AT_SR_Message(1)
						//Make text message to select ROIs for registry alignment. 
						//
					ElseIf(StringMatch(info,"*Done*"))
						Button SR_autoRegisterButton win=analysis_tools,title="Auto",fColor=(0,0,0)
						Button SR_addROIButton win=analysis_tools,disable=1
						//Trim ROI coordinates wave of its extra column
						Wave coordinates = root:var:roiCoord
						Variable size = DimSize(coordinates,1)
						
						MatrixOP/O/FREE result = sum(col(coordinates,size-1))
						
						If(result[0] == 0)
							Redimension/N=(-1,size - 1) coordinates
						EndIf
						AT_SR_Message(2)
						
						ControlInfo/W=analysis_tools SR_waveList
						windowName = S_Value
					
						
						String imageWaveName = AT_SetupROICapture()
						String channel = RemoveEnding(getChannel(1),";")
							
						If(cmpstr(windowName,"twoPscanGraph") == 0)
							
							If(cmpstr(channel,"ch1") == 0)
								windowName += "#GCH1"	
							ElseIf(cmpstr(channel,"ch2") == 0)
								windowName += "#GCH2"	
							EndIf
							
							Wave imageWave = $imageWaveName
						Else
							Wave imageWave = ImageNameToWaveRef(windowName,imageWaveName)
						EndIf
						
						//Register image
						AT_AutoRegister(imageWave,windowName)
					//	Button SR_saveWaveformButton win=ScanRegistry,disable = 0
					//	Button SR_applyTemplate win=ScanRegistry, disable = 0
					EndIf
					
					break
				case "SR_addROIButton":
					errStr = AT_SetupROICapture()
					If(cmpstr(errStr,"-1") == 0)
						return -1
					Else
						ControlInfo/W=analysis_tools SR_waveList
						windowName = S_Value 
					EndIf
					Wave coordinates = root:var:roiCoord
					//Add column to coordinate wave to hold next ROI
					Redimension/N=(-1,DimSize(coordinates,1) + 1) coordinates
					SR_addROI(windowName)
					break
				case "SR_reset":
					//Erases ROI lists
					For(i=0;i<ItemsInList(roiYlist,";");i+=1)
						roiNameY = StringFromList(i,roiYlist,";")
						roiNameX = StringFromList(i,roiXlist,";")
						RemoveFromGraph/Z $roiNameY
						KillWaves/Z $("root:var:" + roiNameY)
						KillWaves/Z $("root:var:" + roiNameX)
					EndFor
					
					roiXlist = ""
					roiYlist = ""
					
					//Resets to zero selected ROIs
					Redimension/N=(4,1) coordinates
					coordinates = 0
					
					//Resets button titles
					Button SR_autoRegisterButton win=analysis_tools,title="Auto",fColor=(0,0,0)
					Button SR_addROIButton win=analysis_tools,disable=1
				//	Button SR_saveWaveformButton win=ScanRegistry,disable = 0
				//	Button SR_applyTemplate win=ScanRegistry, disable = 0
					AT_SR_Message(5)
					break
				case "SR_showROIButton":
		
					errStr = AT_SetupROICapture()
					If(cmpstr(errStr,"-1") == 0)
						return -1
					Else
						ControlInfo/W=analysis_tools SR_waveList
						windowName = S_Value 
					EndIf
					
					If(hidden)
						ModifyGraph/W=$windowName hideTrace = 0
						hidden = 0
					Else	
						ModifyGraph/W=$windowName hideTrace = 1
						hidden = 1
					EndIf
					break
				case "SR_saveTemplateButton":
					//Saves the template waveform so it can be reapplied to other images

					If(!DataFolderExists("root:Packages:twoP:Scan_Register_Templates"))
						NewDataFolder root:Packages:twoP:Scan_Register_Templates
					EndIf
					SetDataFolder root:Packages:twoP:Scan_Register_Templates
					String templateName = UniqueName("template",1,0)
					Wave template = root:var:template
					Duplicate/O template,$templateName
					
										
					SVAR templateList = root:var:templateList
					templateList = GetTemplateList()
					PopUpMenu SR_templatePopUp win=analysis_tools,value=#"root:var:templateList"
					break
				case "SR_applyTemplate":
					
					ControlInfo/W=analysis_tools SR_templatePopUp
					wave template = $("root:Packages:twoP:Scan_Register_Templates:" + S_Value)
					
					ControlInfo/W=analysis_tools SR_UseAnalysisToolsCheck
					Variable useAnalysisTools = V_Value
					Variable loops,numChannels
					numChannels = 0
					If(UseAnalysisTools)
						SVAR scanListStr = root:Packages:twoP:examine:scanListStr
						loops = ItemsInList(scanListStr,";")
						ControlInfo/W=analysis_tools ch1Check
						numChannels = V_Value
						Variable theChannel = 1
						ControlInfo/W=analysis_tools ch2Check
						numChannels += V_Value
						If(V_Value)
							theChannel = 2 
						EndIf
					Else
						loops = 1
						numChannels = 1
					EndIf
					
					
					For(k=0;k<numChannels;k+=1)
						For(j=0;j<loops;j+=1)
							If(UseAnalysisTools)
								If(numChannels == 1)
									imageWaveName = StringFromList(j,scanListStr,";") + "_ch" + num2str(theChannel)
								Else
									imageWaveName = StringFromList(j,scanListStr,";") + "_ch" + num2str(k+1)
								EndIf
								
								SetDataFolder $("root:twoP_Scans:" + StringFromList(j,scanListStr,";"))
								Wave imageWave = $imageWaveName
							Else
								errStr = AT_SetupROICapture()
								If(cmpstr(errStr,"-1") == 0)
									return -1
								Else
									ControlInfo/W=analysis_tools SR_waveList
									windowName = S_Value 
								EndIf
					
								imageWaveName = AT_SetupROICapture()
								Wave imageWave = ImageNameToWaveRef(windowName,imageWaveName)						
							EndIf
							
							//If(DimSize(imageWave,2) > 0)
							//	Variable wholeStack
							//	DoAlert/T="Scan Register" 2,"Register entire stack?"
							//EndIf
							V_flag = 1
					
							Variable xDelta,yDelta,xOffset,yOffset,xSize,ySize
	
							xDelta = DimDelta(imageWave,0)
							xOffset = DimOffset(imageWave,0)
							xSize = DimSize(imageWave,0)
							yDelta = DimDelta(imageWave,1)
							yOffset = DimOffset(imageWave,1)
							ySize = DimSize(imageWave,1)
	
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
					
							If(V_flag == 1)//whole stack registry
								//Makes wave to hold each layer of the stack
								Duplicate/O/FREE imageWave,theLayer
								Redimension/N=(-1,-1,0) theLayer
						
								//New name for the output wave; 'reg' stands for registered.
								//Duplicate/O imageWave,$(NameOfWave(imageWave) + "_reg")
								Wave correctedImage = imageWave //$(NameOfWave(imageWave) + "_reg")
						
								For(i=0;i<DimSize(imageWave,2);i+=1)
									theLayer[][] = imageWave[p][q][i]
									ImageInterpolate/wm=1/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp theLayer
									Wave correctedLayer = M_InterpolatedImage
									correctedImage[][][i] = correctedLayer[p][q]
								EndFor
						
							ElseIf(V_flag == 2)//top layer registry
								ImageInterpolate/wm=1/sgrx=xs/sgry=ys/dgrx=xd/dgry=yd warp theLayer
								Wave correctedImage = M_InterpolatedImage	
							Else
								return -1
							EndIf
							
						EndFor
					EndFor
	
					break
			
			endswitch
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AT_ScanRegistryPopUpProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			strswitch(pa.ctrlName)
				case "SR_waveList":
					Variable popNum = pa.popNum
					String popStr = pa.popStr
					DoWindow/F $popStr
					String imageList = ImageNameList(popStr,";")
					
					If(strlen(imageList) != 0)
						Wave theImage = ImageNameToWaveRef(popStr,StringFromList(0,ImageNameList(popStr,";")))
					Else
						print "No images on graph"
						return -1
					EndIf
					
					SetDataFolder GetWavesDataFolder(theImage,1)
					break
				case "SR_templatePopUp":	
			
					SVAR templateList = root:var:templateList
					templateList = GetTemplateList()
					PopUpMenu SR_templatePopUp win=analysis_tools,value=#"root:var:templateList"
			
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function AT_ScanRegistrySliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				SetVariable SR_phaseVal win=analysis_tools,value=_NUM:curval
				
				ControlInfo/W=analysis_tools SR_waveList
				String imageName = ImageNameList(S_Value,";")
				imageName = StringFromList(0,imageName,";")
				Wave scanWave = ImageNameToWaveRef(S_Value,imageName)
		
			
				Variable phase,pixelOffset,pixelDelta,divergence,frequency
				phase = curval*pi/180
				ControlInfo/W=analysis_tools SR_pixelDelta
				pixelDelta = V_Value
				ControlInfo/W=analysis_tools SR_divergence
				divergence = V_Value
				ControlInfo/W=analysis_tools SR_frequency
				frequency = V_Value
				Controlinfo/W=analysis_tools SR_pixelOffset
				pixelOffset = V_Value
				CorrectScanRegister(scanWave,pixelOffset,pixelDelta,phase,frequency,divergence)
			endif
			break
	endswitch

	return 0
End

Function AT_ScanRegistryVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			ControlInfo/W=analysis_tools SR_waveList
			String imageName = ImageNameList(S_Value,";")
			imageName = StringFromList(0,imageName,";")
			Wave scanWave = ImageNameToWaveRef(S_Value,imageName)
			
			Variable phase,pixelOffset,pixelDelta,divergence,frequency
			ControlInfo/W=analysis_tools SR_phase
			phase = V_Value*pi/180
			ControlInfo/W=analysis_tools SR_pixelDelta
			pixelDelta = V_Value
			ControlInfo/W=analysis_tools SR_divergence
			divergence = V_Value
			ControlInfo/W=analysis_tools SR_frequency
			frequency = V_Value
			Controlinfo/W=analysis_tools SR_pixelOffset
			pixelOffset = V_Value
			
			CorrectScanRegister(scanWave,pixelOffset,pixelDelta,phase,frequency,divergence)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function sliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				//Variable curval = sa.curval
				NVAR bkgF = root:bkgF
				CONTROLINFO/W=spot subSlider
				Variable userSubtract = V_value
				CONTROLINFO/W=spot inflSlider
				Variable inflation = V_value
				ValDisplay subDisplay value=_NUM:(-bkgF+userSubtract*bkgF)
				ValDisplay inflDisplay value=_NUM:(inflation*bkgF)
			endif
			break
	endswitch
	return 0
End

//Called by external procedures parameters 
Function atExtParamPopProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo/W=analysis_tools extFuncPopUp
			UpdateExtFuncValues(S_Value)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

////// Color Picker for NMultiROI//////
Function ROIColorPopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			controlinfo/w=analysis_tools ROIColorPop
			variable/G Gred = V_red
			variable/G GBlue = V_blue
			variable/G Ggreen = V_green
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

////Smooth checkbox//////////////
//Currently not in use///
Function SmoothCheckBoxProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			NVAR smthMode = root:smthMode
			if(checked)
				smthMode = 1
			else
				smthMode = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//Mouse hook function for line profile function
Function getLineHook(s)
	STRUCT WMWinHookStruct &s
	SVAR graphName = root:var:graphName
	SVAR windowName = root:var:windowName

	NVAR mouseEvent = root:var:mouseEvent
	NVAR activeProfile = root:var:activeProfile
	Wave/T WavesOnGraph = W_WaveList
	
	SVAR startROI = root:Packages:analysisTools:startROI
	SVAR endROI = root:Packages:analysisTools:endROI
	SVAR prevROI = root:Packages:analysisTools:prevROI

	Variable/G root:Packages:analysisTools:distance 
	NVAR distance = root:Packages:analysisTools:distance 
	Wave/T/Z distanceWave = root:Packages:analysisTools:distanceWave

	Wave/T roiTable = root:roiTable
	
	//centers of the ROIs
	Wave ROIx = root:twoP_ROIS:ROIx
	Wave ROIy = root:twoP_ROIS:ROIy
	
	If(DimSize(WavesOnGraph,0))
		Wave theWave = $WavesOnGraph[0][1]
		Variable count = 0
		Do
			Wave theWave = $WavesOnGraph[count][1]
			count+=1
		While(!DimSize(theWave,1))
	EndIf
	
	Variable i
	Variable hookResult = 0
	Wave xWave = root:var:xWave
	Wave yWave = root:var:yWave
	Wave xWaveIndex = root:var:xWaveIndex
	Wave yWaveIndex = root:var:yWaveIndex
	Variable distCols
	
	//Check for cable distance measurement check box.
	ControlInfo/W=analysis_tools distanceOnlyCheck
	Variable distOnly = V_Value
	If(distOnly)
		String/G root:Packages:analysisTools:distDataName
		SVAR distDataName = root:Packages:analysisTools:distDataName
	EndIf
	
	//If 2P Scan Graph, get the actual scan wave instead of the layer projection
	If(cmpstr(windowName,"twoPscanGraph") == 0)
		NVAR curScanNum = root:Packages:twoP:examine:curScanNum
		String scanNumStr
		If(curScanNum < 10)
			scanNumStr = "00" + num2str(curScanNum)
		ElseIf(curScanNum < 100)
			scanNumStr = "0" + num2str(curScanNum)
		Else
			scanNumStr = num2str(curScanNum)
		EndIf
		
		String channel
		Variable ch1,ch2
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
	EndIf
	
	switch(s.eventCode)
		case 0:
		//handle activate
			break
		case 1:
		//handle deactivate
			break
		case 4:
			//mouse moved
			If(activeProfile)	//only starts tracing mouse path if the initial starting click has been made (sets activeProfile = 1)
				If(mouseEvent == 1 && activeProfile == 1)
					
					If(DimSize(xWave,0) == 0)
						Redimension/N=(DimSize(xWave,0)+1) xWave
						Redimension/N=(DimSize(yWave,0)+1) yWave
						xWave[DimSize(xWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"bottom",s.mouseLoc.h),0)
						yWave[DimSize(yWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"left",s.mouseLoc.v),1)
						
					Else
						If(ScaleToIndex(theWave,AxisValFromPixel(graphName,"bottom",s.mouseLoc.h),0) == xWave[DimSize(xWave,0)-1])
							If(ScaleToIndex(theWave,AxisValFromPixel(graphName,"left",s.mouseLoc.v),1) == yWave[DimSize(yWave,0)-1])
								//discards point if movement is sub-pixel
							EndIf
						Else
							
							Redimension/N=(DimSize(xWave,0)+1) xWave
							Redimension/N=(DimSize(yWave,0)+1) yWave
							xWave[DimSize(xWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"bottom",s.mouseLoc.h),0)
							yWave[DimSize(yWave,0)-1] = ScaleToIndex(theWave,AxisValFromPixel(graphName,"left",s.mouseLoc.v),1)
				
						EndIf
					EndIf
																
					//Is the line profile near enough to the center of the ROI?
					//If we take the profile right after it switches to a new ROI, the distance will be short.
					
					//What ROI is the mouse hovering over?
					String currentROI = getMouseROI(windowName,theWave,root:roiTable,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
					
					//How far away is the mouse from the center of that ROI?
					Variable index = tableMatch(currentROI,roiTable)
					If(index != -1) //-1: not over ROI, in dead zones between them
						Variable xDist,yDist
						xDist = IndexToScale(theWave,xWave[DimSize(xWave,0) - 1],0)
						yDist = IndexToScale(theWave,yWave[DimSize(yWave,0) - 1],1)
						Variable distFromROICenterX = abs(ROIx[index] - xDist) 
						Variable distFromROICenterY = abs(ROIy[index] - yDist)
					Else
						return 0
					EndIf
										
					//Is the mouse over a new ROI?
					Variable pass = 1
				   If(pass)
						//String currentROI = getMouseROI(windowName,theWave,root:roiTable,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
						
						If(strlen(currentROI) && strlen(startROI))
							If(cmpstr(currentROI,startROI) != 0)
								If(cmpstr(currentROI,prevROI) != 0)
									
										Duplicate/FREE xWave,xFree
										Duplicate/FREE yWave,yFree
										For(i=0;i<DimSize(xWave,0);i+=1)
											xFree[i] = IndexToScale(theWave,xWave[i],0)
											yFree[i] = IndexToScale(theWave,yWave[i],1)
										EndFor
										//distance = getLineProfileDistance(xFree,yFree)
										
										//fill with ROI that the mouse is over and its distance from the start
										If(DimSize(xFree,0) > 1)
											//add another row to the distance wave
											Variable distWaveSize = DimSize(distanceWave,0)
											Redimension/N=(distWaveSize+1,2) distanceWave

											//must be within 1 µm of the ROI center to register as hitting that ROI
											
											If(distFromROICenterX < 0.5e-6 && distFromROICenterY < 0.5e-6) 
												print "center: " + currentROI
												distanceWave[distWaveSize][0] = currentROI
												
												//get distance w/ line profile of the in-progress line
												ImageLineProfile/SC/P=-2 xWave=xFree,yWave=yFree,srcWave=theWave,width=1
												Wave lineProfileDist = $(GetDataFolder(1) + "W_LineProfileDisplacement")
												
												Variable dist = lineProfileDist[DimSize(lineProfileDist,0)-1]
												distanceWave[distWaveSize][1] = num2str(dist)
												
												//register the current ROI as having been hit
												prevROI = currentROI
												
											EndIf
												//distanceWave[distWaveSize][1] = num2str(getLineProfileDistance(xFree,yFree))
										EndIf					
										//FillDMatrix(distanceWave,startROI,currentROI,distance)
										
								EndIf
							EndIf
					 	EndIf
			   	EndIf
				EndIf
			EndIf
			break
		case 5:
		//mouse up
		If(activeProfile)	//Stops tracing the mouse path if the path was active (sets activeProfile = 0), otherwise activate the path (sets activeProfile = 1)
			If(mouseEvent == 1)
				SetWindow $windowName, hook(getLineHook)=$"" //remove window hook
				mouseEvent = 0
				Redimension/N=(DimSize(xWave,0)-1) xWave,xWaveIndex
				Redimension/N=(DimSize(yWave,0)-1) yWave,yWaveIndex
				activeProfile = 0
				
				xWaveIndex = xWave
				yWaveIndex = yWave
				For(i=0;i<DimSize(xWave,0);i+=1)
					xWave[i] = IndexToScale(theWave,xWave[i],0)
					yWave[i] = IndexToScale(theWave,yWave[i],1)
				EndFor
				
				//Get wave dimensions
				Variable frames = DimSize(theWave,2)
				
				//Take the line profile
				ControlInfo/W=analysis_tools lineProfileWidth
				Variable width = V_Value
				
				//Set data folder to the waves folder
				SetDataFolder GetWavesDataFolder(theWave,1)
				
				
				//Get baseline profile for ∆F/F
				ControlInfo/W=analysis_tools dFLineProfileCheck
				Variable doDF = V_Value
				
				
				
				If(doDF)
					Variable baselineStart,baselineEnd

					ControlInfo/W=analysis_tools bslnStVar
					baselineStart = ScaleToIndex(theWave,V_Value,2)
					ControlInfo/W=analysis_tools bslnEndVar
					baselineEnd = ScaleToIndex(theWave,V_Value,2)
					
					//Get the baseline portion of the scan
					Make/FREE/N=(DimSize(theWave,0),DimSize(theWave,1),baselineEnd-baselineStart) baselineScan
					//Set scales
					SetScale/P x,DimOffset(theWave,0),DimDelta(theWave,0),baselineScan
					SetScale/P y,DimOffset(theWave,1),DimDelta(theWave,1),baselineScan
					SetScale/P z,DimOffset(theWave,2),DimDelta(theWave,2),baselineScan
					
					baselineScan = theWave[p][q][baselineStart + r]
				
					//line profile the baseline scan
					ImageLineProfile/SC/P=-2 xWave=xWave,yWave=yWave,srcWave=baselineScan,width=width
									
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
					
					//collapse baseline profile, mean over time
					collapseLineProfile(baselineProfile,theWave,"avg")
					
				EndIf
				
				
				//Line profile of the scan
				ImageLineProfile/SC/P=-2 xWave=xWave,yWave=yWave,srcWave=theWave,width=width
				
				If(frames)
					Wave theProfile = $(GetWavesDataFolder(theWave,1) + "M_ImageLineProfile")
				Else
					Wave theProfile = $(GetWavesDataFolder(theWave,1) + "W_ImageLineProfile")
				EndIf
				
				//Smooth the profile before collapsing
				ControlInfo/W=analysis_tools SmoothBox
				If(V_Value)
					ControlInfo/W=analysis_tools SmoothFilterVar
					If(DimSize(theProfile,1) > 0 && V_Value != 0)
						Smooth/S=2/DIM=1 V_Value,theProfile
					Else
						//Smooth/S=2 V_Value,theProfile
					EndIf
				EndIf
				
				//Collapse if selected to peak value
				ControlInfo/W=analysis_tools collapseLineProfileCheck
				If(DimSize(theProfile,1) > 0 && V_Value)
					ControlInfo/W=analysis_tools peakStVar
					Variable start = V_Value
					ControlInfo/W=analysis_tools peakEndVar
					Variable stop = V_Value
					collapseLineProfile(theProfile,theWave,"max",start=start,stop=stop)
				EndIf
				
				//∆F/F profile
				If(doDF)
					theProfile = (theProfile - baselineProfile)/baselineProfile
					//String dFProfileName = NameOfWave(theProfile) + "_dF"
					//Duplicate/O theProfile,$dFProfileName
					//KillWaves/Z theProfile,baselineProfile
					KillWaves/Z baselineProfile
					//Wave theProfile = $dFProfileName
				EndIf
				
				Variable version = floor(IgorVersion())
			
				//Rename line profile
				String lineProfileName = NameOfWave(theWave) + "_lineProfile"
			
				If(version > 7)
					String displacementProfileName = NameOfWave(theWave) + "_lineDisp"
			
					If(doDF)
						displacementProfileName += "_dF"
					EndIf	
			
					//Rename displacement profile wave for Igor 8
					If(WaveExists($(GetDataFolder(1) + "W_LineProfileDisplacement")))
						Wave lineProfileDisp = $(GetDataFolder(1) + "W_LineProfileDisplacement")
						KillWaves/Z root:var:W_LineProfileDisplacement
						MoveWave lineProfileDisp,root:var:W_LineProfileDisplacement
						
						Duplicate/O lineProfileDisp,$displacementProfileName
						//KillWaves/Z lineProfileDisp
						Wave lineProfileDisp = $displacementProfileName
					EndIf
				EndIf
			
				//Different output wave names depending on 2D or 3D profile
				frames = DimSize(theWave,2)
				If(frames)
					String outputProfileName = GetDataFolder(1) + "M_ImageLineProfile"
				Else
					outputProfileName = GetDataFolder(1) + "W_ImageLineProfile"
				EndIf
				
				//Rename line profile wave
				lineProfileName = NameOfWave(theWave) + "_LP"
				
				If(doDF)
					lineProfileName += "_dF"
				EndIf
				
				If(WaveExists($outputProfileName))
					Wave lineProfile = $outputProfileName
					Duplicate/O lineProfile,$lineProfileName
					KillWaves/Z lineProfile
				EndIf	
		
				wave theProfile = $lineProfileName
				
				//Append the line profile path to the graph
				String xAxis,yAxis,info,flags
				info = ImageInfo(graphName,NameOfWave(theWave),0)
				xAxis = StringByKey("XAXIS",info,":",";")
				yAxis = StringByKey("YAXIS",info,":",";")
				flags = StringByKey("AXISFLAGS",info,":",";")
				
				info = TraceInfo(graphName,"W_LineProfileY",0)
				
				If(!strlen(info))	
					wave lineX = W_LineProfileX
					wave lineY = W_LineProfileY
					
					If(cmpstr(windowName,"twoPscanGraph")==0)
						ControlInfo/W=twoP_Controls CH1Check
						ch1 = V_Value
						ControlInfo/W=twoP_Controls CH2Check
						ch2 = V_Value
						
						If(ch1 && ch2)
							channel = "#GCH2"
						ElseIf(ch1)
							channel = "#GCH1"
						Else
							channel = "#GCH2"
						EndIf
						windowName = "twoPscanGraph" + channel
					EndIf
					
					If(StringMatch(flags,"*/R*") && StringMatch(flags,"*/T*"))
						AppendToGraph/W=$windowName/R=$yAxis/T=$xAxis lineY vs lineX
					ElseIf(StringMatch(flags,"*/R*"))
						AppendToGraph/W=$windowName/R=$yAxis lineY vs lineX
					ElseIf(StringMatch(flags,"*/T*"))
						AppendToGraph/W=$windowName/T=$xAxis lineY vs lineX
					Else
						AppendToGraph/W=$windowName lineY vs lineX
					EndIf
				EndIf

				//Display the line profile versus displacement
				DoWindow LineProfileGraph
				If(V_flag)
					KillWindow/Z LineProfileGraph
				EndIf
				
				If(version < 8)
					If(DimSize(theProfile,1) > 0)
					//	NewImage/N=LineProfileGraph theProfile
					Else
					//	Display/N=LineProfileGraph theProfile as "Line Profile"
					EndIf
				Else
					If(DimSize(theProfile,1) > 0)
						NewImage/N=LineProfileGraph theProfile
					Else
						Display/N=LineProfileGraph theProfile vs lineProfileDisp as "Line Profile"
					EndIf
				EndIf
		
				//SetWindow $windowName, hook(getLineHook)=$""
				
				//Sets the ending ROI name and the distance between the start/end ROIs
				If(distOnly)
					Wave/T distData = $distDataName
					String mouseROI = getMouseROI(windowName,theWave,root:roiTable,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
					endROI = mouseROI
				//	print "End: " + mouseROI
				//	distData[0][DimSize(distData,1) - 1] = mouseROI
				//	distData[1][DimSize(distData,1) - 1] = num2str(WaveMax(lineProfileDisp)*3.3) //3.3 scale factor for Varsha's recordings.
					
					If(DimSize(xFree,0) > 1)
						distance = getLineProfileDistance(xFree,yFree)
					EndIf					
					If(strlen(startROI) && strlen(endROI))
						FillDMatrix(distanceWave,startROI)
					EndIf
				//	print distance
					Wave filterTable = root:ROI_table_filter
					//FillDMatrix(distanceWave,filterTable)
				EndIf
				
				
			ElseIf(mouseEvent == 0)
				mouseEvent = 1
				
				//Make the cable distance between ROIs data wave
				ControlInfo/W=analysis_tools distanceOnlyCheck
				distOnly = V_Value
				
				Make/N=(1,2)/O/T root:Packages:analysisTools:distanceWave
				Wave/T distanceWave = root:Packages:analysisTools:distanceWave
				
				If(distOnly)
					mouseROI = getMouseROI(windowName,theWave,root:roitable,root:twoP_ROIS:ROIx,root:twoP_ROIS:ROIy)
					print "Start: " + mouseROI

					startROI = mouseROI
					If(strlen(startROI))
						distanceWave[0][0] = startROI
						
						//get distance from starting point of the line profile to the center of the ROI
						//index = tableMatch(startROI,roiTable)
						//xDist = ROIx[index] - AxisValFromPixel(graphName,"bottom",s.mouseLoc.h)
						//yDist = ROIy[index] - AxisValFromPixel(graphName,"left",s.mouseLoc.v)
						distanceWave[0][1] = "0"//num2str(sqrt(xDist^2 + yDist^2))
						//print distanceWave[0][1]
					EndIf
					
					distDataName = "root:ROI_analysis:distData" + "_" + mouseROI
					//If(!WaveExists($distDataName))
					//	Make/O/T/N=(2,1) $distDataName
						//2 rows
						//Name of Wave: start ROI name
						//R0: end ROI name
						//R1: cable distance between those ROIs
						//columns will be added for each new ending ROI for a given starting ROI
					//Else
						//add a column
					//	Wave/T distData = $distDataName
					//	Redimension/N=(2,DimSize($distDataName,1) + 1) $distDataName
					//EndIf
				EndIf
					//reset ROI strings
				prevROI = ""
				currentROI = ""
				
			EndIf
		
						
		EndIf
		break
	endswitch
	
	return hookResult

End

Function ptsOverThreshold(theWave,threshold,overUnder)
	Wave theWave
	Variable threshold,overUnder
	Variable i,numpts,count = 0
	
	Duplicate/FREE theWave,temp
	WaveTransform zapNaNs temp
	
	If(overUnder)
		//over threshold
		For(i=0;i<DimSize(temp,0);i+=1)
			If(temp[i] > threshold)
				count += 1
			EndIf
		EndFor
	Else
		//under threshold
		For(i=0;i<DimSize(temp,0);i+=1)
			If(temp[i] < threshold)
				count += 1
			EndIf
		EndFor
	EndIf

	print(count)
	print(count/DimSize(temp,0))
End