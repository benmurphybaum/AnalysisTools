//Loads the analysis suite GUI

#include "atFunctions"
#include "atControls"
#include "atCommon"
#include "atDataSets"
#include "ABF_Loader"

Menu "Data", dynamic
	Submenu "Packages"
		 "Load Analysis Suite"
	End
End

//Finds any external procedure files to include
Function FindExternalModules()
	String filepath,helpPath,folders,platform
	platform = IgorInfo(2)
	
	//What folder is the analysisTools.ipf in?
	filepath = FunctionPath("FindExternalModules")
	
	filepath = ParseFilePath(1,filepath,":",1,0) + "External Procedures"

	NewPath/Q/Z/C/O IgorProcPath,filepath
	
	String/G root:Packages:analysisTools:fileList
	SVAR fileList = root:Packages:analysisTools:fileList
	
	fileList = IndexedFile(IgorProcPath,-1,".ipf")//finds ipf files
	InsertIncludes(fileList)
End


//Adds #includes the external procedure files
Function InsertIncludes(fileList)
	String fileList
	Variable numFiles,i
	String theFile
	
	numFiles = ItemsInList(fileList,";")
	
	For(i=0;i<numFiles;i+=1)
		theFile = StringFromList(i,fileList,";")
		theFile = RemoveEnding(theFile,".ipf")
		Execute/P "INSERTINCLUDE \"" + theFile + "\"" 
	EndFor
	Execute/P "COMPILEPROCEDURES ";
End

Function SetDefaults()
	SetVariable scriptFolder win=analysis_tools,value=_STR:"~/Desktop/retina-decoder-master"
	SetVariable denoiseDataFolder win=analysis_tools,value=_STR:"bmb:Users:bmb:Documents:Denoise_Data"
End

//Organizes the function list into packages
Function CreatePackages()
	
	String/G root:Packages:analysisTools:cmdList
	SVAR cmdList = root:Packages:analysisTools:cmdList
	Variable i
	
	//packageTable: rows are the package name, columns are the contents of that package
	Make/O/T/N=(1,2) root:Packages:analysisTools:packageTable
	Wave/T packageTable = root:Packages:analysisTools:packageTable
	packageTable[0][0] = "Calcium Imaging"
	packageTable[0][1] =  "-------Basic-------;Max Project;"//use ------ Section ------ to divide categories within the package 
	packageTable[0][1] += "-------ROIs--------;MultiROI;ROI Grid;Filter ROI;Display ROIs;Kill ROI;Denoise;"
	packageTable[0][1] += "-------Maps--------;df Map;Vector Sum Map;Line Profile;Apply Map Threshold;Dynamic ROI;"
	packageTable[0][1] += "-------Masks-------;Get Dendritic Mask;Mask Image;"
	packageTable[0][1] += "----Registration---;Adjust Galvo Distortion;Register Image;Rescale Scans;"
	
	//packageTable[1][0] = "Basic Functions"
	//packageTable[1][1] = "-------------------;Average;Error"
	cmdList = "Data Sets;External Function;---------------;Load PClamp;Browse PClamp;Load Stimulus Data;---------------;Run Cmd Line;Average;Error;Kill Waves;Duplicate/Rename;----Packages----;"
	
	For(i=0;i<DimSize(packageTable,0);i+=1)
		If(!strlen(packageTable[i][0]))
			break
		EndIf
		cmdList += packageTable[i][0] + ";"
	EndFor

End

Function LoadAnalysisSuite([left,top])
	//So the window stays in position upon reload
	Variable left,top
	Variable width,height,i
	
	If(ParamIsDefault(left))
		left = 0
	EndIf
	If(ParamIsDefault(top))
		top = 0
	EndIf
		
	// Make the panel//////////
	DoWindow analysis_tools
	if(V_flag !=0)
	DoWindow/K analysis_tools
	else
	endif
	
	left += 0
	top += 50
	width = 575
	height = 510
	
	NewPanel /K=1 /W=(left,top,left + width,top + height) as "Analysis Tools"
	DoWindow/C analysis_tools
	ModifyPanel /W=analysis_tools, fixedSize= 1
	
	//Make analysisTools package folder
	If(!DataFolderExists("root:Packages:analysisTools"))
		NewDataFolder root:Packages:analysisTools
	EndIf
	
	//external procedures loaded
 	FindExternalModules()
	
	//Wave for remembering the most recent values for any given external function
	If(!WaveExists(root:Packages:analysisTools:extFuncValues))
		Make/T/N=(0,0) root:Packages:analysisTools:extFuncValues
	EndIf
	
	//Housekeeping variables and strings
	String/G root:Packages:analysisTools:tabList
	String/G root:Packages:analysisTools:currentTab
	String/G root:Packages:analysisTools:prevTab
	
	Variable/G root:Packages:analysisTools:viewerOpen
	NVAR viewerOpen = root:Packages:analysisTools:viewerOpen
	viewerOpen = 0
	
	Variable/G root:Packages:analysisTools:areSeparated
	NVAR areSeparated = root:Packages:analysisTools:areSeparated
	areSeparated = 0
	
	//Fill out the scan list wave
	If(!WaveExists(root:Packages:analysisTools:scanListWave))
		Make/T root:Packages:analysisTools:scanListWave
	EndIf
	wave/T scanListWave = root:Packages:analysisTools:scanListWave
	
	If(Exists("root:Packages:twoP:examine:scanListStr") !=2)
		String/G root:Packages:twoP:examine:scanListStr
	EndIf
	
	String scanList = NQ_ListScans("1,2,3,4,5")	//all scans
	//Time Series
	Variable tsStart = WhichListItem("\M1(Time Series",scanList,";") + 1
	Variable tsEnd = WhichListItem("\M1(-",scanList,";") - 1
	String timeSeries = StringsFromList(num2str(tsStart) + "-" + num2str(tsEnd),scanList,";")
	
	//Z Stacks
	Variable zsStart = WhichListItem("\u005cM1(Z Stacks",scanList,";",tsEnd + 1) + 1
	Variable zsEnd = WhichListItem("\M1(-",scanList,";",zsStart + 1) - 1
	String zStacks = StringsFromList(num2str(zsStart) + "-" + num2str(zsEnd),scanList,";")
	
	timeSeries = timeSeries + zStacks
	
	Wave/T tempWave = ListToTextWave(timeSeries,";")
	Redimension/N=(DimSize(tempWave,0)) scanListWave
	scanListWave = tempWave
	
	String/G root:Packages:analysisTools:scanFolderList
	SVAR scanFolderList = root:Packages:analysisTools:scanFolderList
	scanFolderList = ""
	For(i=0;i<DimSize(scanListWave,0);i+=1)
		scanFolderList += scanListWave[i] + ";"
	EndFor
	
	If(!WaveExists(root:Packages:twoP:examine:selWave))
		Make/O/N=(DimSize(scanListWave,0)) root:Packages:twoP:examine:selWave
	EndIf
	Wave selWave = root:Packages:twoP:examine:selWave
	Redimension/N=(DimSize(scanListWave,0)) selWave

	If(!WaveExists(root:Packages:analysisTools:selFolderWave))
		Make/O/N=(1) root:Packages:analysisTools:selFolderWave
	EndIf
	Wave/T selFolderWave = root:Packages:analysisTools:selFolderWave
		
	//Check size of selWave
	If(DimSize(selWave,0) != DimSize(scanListWave,0))
		Redimension/N=(DimSize(scanListWave,0)) selWave
	EndIf
	
	If(!WaveExists(root:packages:twoP:examine:ROIListWave))
		Make/T root:packages:twoP:examine:ROIListWave
	EndIf
	wave/T ROIListWave = root:packages:twoP:examine:ROIListWave
	
	If(!WaveExists(root:Packages:twoP:examine:ROIListSelWave))
		Make/O/N=(DimSize(ROIListWave,0)) root:Packages:twoP:examine:ROIListSelWave
	EndIf
	wave ROIListSelWave = root:packages:twoP:examine:ROIListSelWave
	
	//for the list box switcher
	String/G root:Packages:analysisTools:whichList
	SVAR whichList = root:Packages:analysisTools:whichList
	whichList = "AT"

	String/G root:Packages:twoP:examine:scanListStr
	String/G root:Packages:twoP:examine:ROIListStr
	
	String/G root:Packages:analysisTools:currentCmd
	String/G root:Packages:analysisTools:prevCmd
	SVAR prevCmd = root:Packages:analysisTools:prevCmd
	prevCmd = ""
	
	CreatePackages()
	SVAR cmdList = root:Packages:analysisTools:cmdList
	SVAR currentCmd = root:Packages:analysisTools:currentCmd
	currentCmd = StringFromList(0,cmdList,";")
	
	//For the Operation command and wave matching
	String/G root:Packages:analysisTools:waveMatchStr
	SVAR waveMatchStr = root:Packages:analysisTools:waveMatchStr
	waveMatchStr = ""
	
	String/G root:Packages:analysisTools:waveNotMatchStr
	SVAR waveNotMatchStr = root:Packages:analysisTools:waveNotMatchStr
	waveNotMatchStr = ""
	
	String/G root:Packages:analysisTools:opList
	SVAR opList = root:Packages:analysisTools:opList
	opList = "Cmd Line;avg;sem;sum;delete;edit;display;differentiate"
	
	
	
	Make/O/N=1 root:Packages:analysisTools:AT_selWave
	Wave AT_selWave = root:Packages:analysisTools:AT_selWave
	AT_selWave = 0
	
	String/G root:Packages:analysisTools:runCmdStr
	SVAR runCmdStr = root:Packages:analysisTools:runCmdStr
	runCmdStr = ""
	
	//For external functions
	String/G root:Packages:analysisTools:extFuncList
	SVAR extFuncList = root:Packages:analysisTools:extFuncList
	SVAR fileList = root:Packages:analysisTools:fileList
	extFuncList = getExternalFunctions(fileList)
	Variable/G root:Packages:analysisTools:numExtParams
	NVAR numExtParams = root:Packages:analysisTools:numExtParams
	String/G root:Packages:analysisTools:extParamNames
	SVAR extParamNames = root:Packages:analysisTools:extParamNames
	extParamNames = ""
	String/G root:Packages:analysisTools:extParamTypes
	SVAR extParamTypes = root:Packages:analysisTools:extParamTypes
	extParamTypes = ""
	String/G root:Packages:analysisTools:isOptional
	SVAR isOptional = root:Packages:analysisTools:isOptional
	isOptional = ""
	
	
	//For Data Sets////////////////////
	If(!DataFolderExists("root:Packages:analysisTools:DataSets"))
		NewDataFolder root:Packages:analysisTools:DataSets
	EndIf
	
	Make/O/T/N=1 root:Packages:analysisTools:AT_waveListTable
	Wave/T AT_waveListTable = root:Packages:analysisTools:AT_waveListTable
	Make/O/T/N=1 root:Packages:analysisTools:AT_WaveListTable_FullPath
	Wave/T AT_WaveListTable_FullPath = root:Packages:analysisTools:AT_WaveListTable_FullPath
	Make/O/T root:Packages:analysisTools:DataSets:ogAT_WaveListTable_UnGroup
	
	String/G root:Packages:analysisTools:DataSets:wsDims
	Variable/G root:Packages:analysisTools:DataSets:numWaveSets
	Variable/G root:Packages:analysisTools:DataSets:wsn
	
	//These will be the dummy data set for the wave list box until
	//the data set is actually saved. 
	Make/N=0/T/O root:Packages:analysisTools:DataSets:WaveListDS
	Make/N=0/T/O root:Packages:analysisTools:DataSets:ogWaveListDS
	
	
	
	Wave/Z/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	If(!WaveExists(dataSetNames))
		Make/T/N=1 root:Packages:analysisTools:DataSets:dataSetNames
		Wave/T dataSetNames = root:Packages:analysisTools:DataSets:dataSetNames
	EndIf
	
	GetDataSetNames()
	
	Make/O/N=(DimSize(dataSetNames,0)) root:Packages:analysisTools:DataSets:dataSetSelWave
	Wave dataSetSelWave = root:Packages:analysisTools:DataSets:dataSetSelWave
	
	//Data set filters, only overwrite if it doesn't exist yet.
	If(!WaveExists(root:Packages:analysisTools:DataSets:dsFilters))
		Make/O/T/N=(DimSize(dataSetNames,0),2) root:Packages:analysisTools:DataSets:dsFilters
	EndIf
	
	
		
	//Create Variables////////////////////

	variable/G root:Packages:analysisTools:smthMode = 0	
	variable/G root:Packages:analysisTools:Gred 
	variable/G root:Packages:analysisTools:Ggreen 
	variable/G root:Packages:analysisTools:Gblue
	variable/G root:Packages:analysisTools:Gnumtrials
	variable/G root:Packages:analysisTools:Gbatchsize
	variable/G root:Packages:analysisTools:GpeakSt = 3
	variable/G root:Packages:analysisTools:GpeakEnd  = 5
	variable/G root:Packages:analysisTools:GbslnSt = 1
	variable/G root:Packages:analysisTools:GbslnEnd = 3
	variable/G root:Packages:analysisTools:GdarkValue
	variable/G root:Packages:analysisTools:GSpaceFilter = 3
	variable/G root:Packages:analysisTools:GSmoothFilter
	variable/G root:Packages:analysisTools:TempFilter = 0	
	variable/G root:Packages:analysisTools:able = 0
	NVAR able = root:Packages:analysisTools:able
	
	//ROI display variables
	String/G root:Packages:analysisTools:arrangementOptions
	SVAR arrangementOptions = root:Packages:analysisTools:arrangementOptions
	arrangementOptions = "None;Index;ROI"
	
	//Add the names of your controls to the appropriate list to assign controls to that tab.
	//Assignment allows the tab to automatically hide or show controls assigned to that tab when it gets clicked. 
	//Make sure the name of a new control list is with format: 'ctrlList_' + 'name of control'
	
	CreateControlLists(cmdList)
	
	String/G root:Packages:analysisTools:selWaveList
	SVAR selWaveList = root:Packages:analysisTools:selWaveList
	selWaveList = ""
	
	Make/O/T/N=1 root:Packages:analysisTools:folderTable
	Variable/G root:Packages:analysisTools:selFolder
	NVAR selFolder= root:Packages:analysisTools:selFolder
	selFolder = 0
	
	Make/O/N=1 root:Packages:analysisTools:itemListSelWave
	Make/O/T/N=1 root:Packages:analysisTools:itemListTable
	// ADD functions..
	
	//Scan list panel
	DefineGuide/W=analysis_tools listboxLeft={FR,-235},listboxBottom={FB,-10}
	NewPanel/HOST=analysis_tools/FG=(listboxLeft,FT,FR,listboxBottom)/N=scanListPanel
	ModifyPanel/W=analysis_tools#scanListPanel frameStyle=0
	ListBox/Z WaveListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=4,selWave=selWave,listWave=scanListWave,proc=atListBoxProc
	Button selectAll_Left win=analysis_tools#scanListPanel,size={30,20},pos={0,height-40},title="ALL",proc=atButtonProc 
	//SetVariable folderDepth win=analysis_tools#scanListPanel,size={80,20},pos={40,height-38},fsize=12,limits={0,inf,1},value=_NUM:0,disable=1,title="Depth",proc=atSetVarProc
	
	//ROI list Panel
	ListBox/Z ROIListBox win=analysis_tools#scanListPanel,size={80,height-75},pos={150,30},mode=4,selWave=ROIListSelWave,listWave=ROIListWave,proc=atListBoxProc
	Button dispROI win=analysis_tools#scanListPanel,size={40,20},pos={190,height-40},title="DISP",proc=atButtonProc
	Button selectAll_Right win=analysis_tools#scanListPanel,size={30,20},pos={150,height-40},title="ALL",proc=atButtonProc
	
	//Extra list box for folders, so I can switch between browsing and scan list
	ListBox AT_FolderListBox win=analysis_tools#scanListPanel,size={140,500-65},pos={0,30},mode=2,disable=1,proc=atListBoxProc
	Button atBrowseButton win=analysis_tools#scanListPanel,size={40,20},pos={5,5},fsize=8,title="Browse",proc=atButtonProc
	Button atBrowseBackButton win=analysis_tools#scanListPanel,size={40,20},pos={50,5},fsize=8,title="Back",proc=atButtonProc,disable=1
	
	SetDrawEnv/W=analysis_tools#scanListPanel textxjust=1
	DrawText/W=analysis_tools#scanListPanel 75,25,"Scans"
	DrawText/W=analysis_tools#scanListPanel 180,25,"ROIs"
	
	//Reload analysis tools button
	Button reloadATButton win=analysis_tools,size={50,20},pos={3,468},title="Reload",proc=atButtonProc
	
	//Viewer Button
	Button atViewerButton win=analysis_tools,size={50,20},pos={3,448},title="Viewer",proc=atButtonProc
	String/G root:Packages:analysisTools:viewerRecall = ""
	
	//current data folder text
	String/G root:Packages:analysisTools:currentDataFolder
	SVAR cdf = root:Packages:analysisTools:currentDataFolder
	cdf = GetDataFolder(1)
	SetVariable AT_cdf win=analysis_tools#scanListPanel,pos={100,8},size={200,20},fsize=10,value=cdf,title=" ",disable=1,frame=0
	
	PopUpMenu AT_CommandPop win=analysis_tools,pos={80,6},size={125,20},fsize=12, title="Command:",bodywidth=125,value=#"root:Packages:analysisTools:cmdList",mode=1,proc=atPopProc
	Button AT_RunCmd win=analysis_tools,pos={260,5},size={50,20},title="Run",proc=atButtonProc
	Button AT_Help win=analysis_tools,pos={210,5},size={20,20},title="?",proc=atButtonProc
	GroupBox AT_HelpBox win=analysis_tools,pos={7,269},size={326,200},disable=1
	
	//Variables
	SetDrawEnv/W=analysis_tools#scanListPanel textxjust=1
	Variable yPos = 60
//	DrawText/W=analysis_tools 30,yPos,"Baseline"
//	DrawText/W=analysis_tools 150,yPos,"Peak"
//	DrawText/W=analysis_tools 250,yPos,"Trials"
//	DrawText/W=analysis_tools 30,yPos+60,"Filters"
	
	yPos += 5
	setvariable bslnStVar, win = analysis_tools, pos = {10,yPos}, size = {90, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GbslnSt, title = "Bsln Start"
	setvariable peakStVar, win = analysis_tools, pos = {120,yPos}, size = {90, 30}, bodywidth=35,noproc, value = root:Packages:analysisTools:GpeakSt, title = "Peak Start"
	setvariable numtrialsVar, win = analysis_tools, pos = {230,yPos}, size = {100, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:Gnumtrials, title = "No. of trials"
	
	//for ROI Display function
	PopUpMenu horDisplayArrangementPopUp win=analysis_tools,pos={10,yPos},size={75,20},title="Hor. Arrange",value=#"root:Packages:analysisTools:arrangementOptions",disable=1
	PopUpMenu vertDisplayArrangementPopUp win=analysis_tools,pos={160,yPos},size={75,20},title="Vert. Arrange",value=#"root:Packages:analysisTools:arrangementOptions",disable=1
	CheckBox dispAveragesCheck win=analysis_tools,pos={10,yPos+20},size={50,20},title="Averages",disable=1
	SetVariable scanOrderROIdisplay win=analysis_tools,pos={10,yPos+40},size={175,20},title="Scan Order",value=_STR:"",disable=1
	CheckBox colorROIs win=analysis_tools,pos={10, ypos+105},size = {75,20},title="Colors",disable=1
	
	//SetVariable roiOrderROIdisplay win=analysis_tools,pos={10,yPos+60},size={175,20},title="ROI Order",value=_STR:"",disable=1
	
	////////SS edit Nov6 2018/////////////////////
	SetVariable GraphName win = analysis_tools, pos = {10, ypos+85}, size = {175,20}, title = "Graph Name", value=_STR:"",disable=1
	////////SS edit Nov6 2018/////////////////////
	
	//for Get Dendritic Mask Function
	SetVariable maskThreshold win=analysis_tools,pos={96,62},size={100,20},title="Threshold",value=_NUM:0.05,limits={0,inf,0.005},disable=1
	CheckBox mask3DCheck win=analysis_tools,pos={10,82},size={50,20},title="3D",value=0,disable=1
	
	//For dF Map
	CheckBox varianceMapCheck win=analysis_tools,pos={140,61},size={100,20},title="Variance Map",disable=1
	CheckBox histogramCheck win=analysis_tools,pos={10,110},size={100,20},title="Make Histogram",disable=1
	CheckBox cleanUpNoise win=analysis_tools,pos={10,130},size={100,20},title="CleanUp Noise",disable=1
	SetVariable cleanUpNoiseThresh win=analysis_tools,pos={110,131},size={90,20},title="Threshold",value=_NUM:1.5,disable=1
	CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,150},size={150,20},title="Remove Laser Response",disable=1
	SetVariable spatialFilterCheck win=analysis_tools,pos={215,163},bodywidth=35,size={100,20},title="Pre Spatial Filter",value=_NUM:5,disable=1
	SetVariable postSpatialFilter win=analysis_tools,pos={215,183},bodywidth=35,size={100,20},title="Post Spatial Filter",value=_NUM:3,disable=1
	
	//For Map threshold 
	SetVariable mapThreshold win=analysis_tools,pos={20,60},size={100,20},title="Threshold",value=_NUM:0,disable=1
	
	//Average
	SetVariable outFolder win=analysis_tools,pos={20,63},size={175,20},title="Output Folder:",value=_STR:"",disable=1
	
	//Errors
	PopUpMenu errType win=analysis_tools,pos={20,120},size={50,20},title="Type",value="sem;sdev",disable=1
	
	//Duplicate/Rename
	SetVariable prefixName win=analysis_tools,pos={20,50},size={50,20},title="P",value=_STR:"",disable=1
	SetVariable groupName win=analysis_tools,pos={80,50},size={50,20},title="G",value=_STR:"",disable=1
	SetVariable seriesName win=analysis_tools,pos={140,50},size={50,20},title="Se",value=_STR:"",disable=1
	SetVariable sweepName win=analysis_tools,pos={200,50},size={50,20},title="Sw",value=_STR:"",disable=1
	SetVariable traceName win=analysis_tools,pos={260,50},size={50,20},title="T",value=_STR:"",disable=1
	Checkbox killOriginals win=analysis_tools,pos={20,70},size={100,20},title="Kill Originals",value=0,disable=1
	
	//Load PClamp
	Button OpenABF2Loader win=analysis_tools,pos={71,66},size={150,20},title="Open PClamp Loader",disable=1,proc=atButtonProc
	
	//Browse PClamp
	String/G root:Packages:analysisTools:alreadyLoaded
	SVAR alreadyLoaded = root:Packages:analysisTools:alreadyLoaded
	alreadyLoaded = ""
	
	//Make folder to hold the browser waves
	String browserPath = "root:Packages:analysisTools:ABF_Browser"
	If(!DataFolderExists(browserPath))
		NewDataFolder $browserPath
	EndIf
	
	//If there are waves in the browser folder, populate the pclamp browser list box
	SetDataFolder $browserPath
	String browseWaves = DataFolderDir(2,browserPath)
	browseWaves = StringByKey("WAVES",browseWaves,":",";")
	
	//ABF Browser file listwave
	Make/O/T root:Packages:analysisTools:ABF_FileListWave
	Wave/T ABF_FileListWave = root:Packages:analysisTools:ABF_FileListWave
	//ABF Browser file selwave
	Make/O root:Packages:analysisTools:ABF_FileSelWave
	Wave ABF_FileSelWave = root:Packages:analysisTools:ABF_FileSelWave
	
	//ABF Browser file listwave
	Make/O/T root:Packages:analysisTools:ABF_SweepListWave
	Wave/T ABF_SweepListWave = root:Packages:analysisTools:ABF_SweepListWave
	//ABF Browser file selwave
	Make/O root:Packages:analysisTools:ABF_SweepSelWave
	Wave ABF_SweepSelWave = root:Packages:analysisTools:ABF_SweepSelWave
	
	Redimension/N=(ItemsInList(browseWaves,",")) ABF_SweepListWave,ABF_SweepSelWave
	Wave/T table = listToTable(browseWaves,",")
	ABF_SweepListWave = table
	
	ListBox fileListBox win=analysis_tools,pos={10,75},size={150,300},mode=4,listWave=ABF_FileListWave,selWave=ABF_FileSelWave,disable=1,proc=atListBoxProc
	ListBox sweepListBox win=analysis_tools,pos={180,75},size={150,300},mode=4,listWave=ABF_SweepListWave,selWave=ABF_SweepSelWave,disable=1,proc=atListBoxProc
	
	
	//For ROI From Map
	CheckBox avgResultsCheck win=analysis_tools,pos={10,81},size={50,20},title="Avg Results",disable=1
	
	//For Mask Image
	CheckBox maskAllFoldersCheck win=analysis_tools,pos={192,85},size={20,20},title="ALL",disable=1
	PopUpMenu maskListPopUp win=analysis_tools,pos={10,85},size={150,20},title="Masks",value=GetMaskWaveList(),disable=1
	
	//For Dynamic ROI
	SetVariable dynamicROI_size win=analysis_tools,pos={10,40},size={80,20},title="Diameter",value=_NUM:6,disable=1
	//For Operation
	
	SetVariable waveMatch win=analysis_tools,pos={40,40},size={162,20},fsize=10,title="Match",value=_STR:"*",help={"Matches waves in the selected folder.\rLogical 'OR' can be used via '||'"},disable=1,proc=atSetVarProc
	SetVariable waveNotMatch win=analysis_tools,pos={52,60},size={150,20},fsize=10,title="Not",value=_STR:"",help={"Excludes matched waves in the selected folder.\rLogical 'OR' can be used via '||'"},disable=1,proc=atSetVarProc
	String helpNote = "Target subfolder for wave matching.\r Useful if matching in multiple parent folders that each have a common subfolder structure"
	SetVariable relativeFolderMatch win=analysis_tools,pos={35,80},size={167,20},fsize=10,title=":Folder",value=_STR:"",help={helpNote},disable=1,proc=atSetVarProc
	getWaveMatchList()
	
	ListBox matchListBox win=analysis_tools,pos={5,120},size={225,320},mode=4,listWave=AT_waveListTable,selWave=AT_selWave,disable=1,proc=atListBoxProc
	SetVariable operation win=analysis_tools,pos={80,469},size={255,20},title="Operation",value=_STR:"",disable=1
	SetVariable outputSuffix win=analysis_tools,pos={80,450},size={150,20},title="Output Suffix",value=_STR:"",disable=1
	PopUpMenu operationOptionsPop win=analysis_tools,pos={233,447},size={100,20},bodywidth=100,title="",value=#"root:Packages:analysisTools:opList",disable=1,proc=atPopProc
	CheckBox useDataSetCheck win=analysis_tools,pos={238,102},title="",disable=1
	
	//For Line Profile
	SetVariable lineProfileWidth win=analysis_tools,pos={242,62},size={75,20},title="Width",value=_NUM:5,disable=1
	PopUpMenu SR_waveList win=analysis_tools,pos={35,60},bodywidth=200,size={200,20},title = " ",value=WinList("*",";","WIN:1"),proc=AT_ScanRegistryPopUpProc,disable=1 //also for scan register
	Button saveLineProfile win=analysis_tools,pos={35,98},size={75,20},title="Save Path",disable=1,proc=atButtonProc
	SetVariable saveLineProfileSuffix win=analysis_tools,pos={115,100},size={75,20},title="Suffix",disable=1,value=_STR:""
	Button applyLineProfile win=analysis_tools,pos={35,140},size={75,20},title="Apply Path",disable=1,proc=atButtonProc
	CheckBox useScanListCheck win=analysis_tools,pos={115,142},size={75,20},title="Use Scan List",disable=1
	PopUpMenu lineProfileTemplatePopUp win=analysis_tools,pos={62,120},bodywidth=130,size={130,20},disable=1,title="Paths",value=getSavedLineProfileList()
	CheckBox collapseLineProfileCheck win=analysis_tools,pos={115,162},size={75,20},title="Collapse",disable=1
	CheckBox dFLineProfileCheck win=analysis_tools,pos={248,142},size={75,20},title="∆F/F",disable=1
	CheckBox distanceOnlyCheck win=analysis_tools,pos={295,142},size={75,20},title="Dist.\rOnly",disable=1
	
	//For ROI segmenter
	Button OpenMaskButton win=analysis_tools,size={125,20},pos={197,85},title="Open Mask",disable=1,proc=atButtonProc
	Button GetSeedPosition win=analysis_tools,size={125,20},pos={197,110},title="Get Seed Position",disable=1,proc=atButtonProc

	//For image registration (translation)
	
	Button applyImageRegistration win=analysis_tools,size={150,20},pos={125,160},title="Apply Template",disable=1,proc=atButtonProc
	Button equalizeDimensions win=analysis_tools,size={150,20},pos={125,185},title="Equalize Dimensions",disable=1,proc=atButtonProc
	PopUpMenu refImagePopUp win=analysis_tools,bodywidth=175,pos={220,85},title="Reference Image",disable=1,value=#"root:Packages:analysisTools:scanFolderList"
	PopUpMenu testImagePopUp win=analysis_tools,bodywidth=175,pos={220,110},title="Test Image",disable=1,value=#"root:Packages:analysisTools:scanFolderList"
	PopUpMenu registrationTemplatePopUp win=analysis_tools,bodywidth=175,pos={220,135},title="Templates",disable=1,value=getWaveList("W_RegParams")
	//WaveList("W_RegParams",";","")
	
	//For Data Sets
	ListBox dataSetListBox win=analysis_tools,pos={235,120},size={100,320},mode=1,listWave=dataSetNames,selWave=dataSetSelWave,disable=1,proc=atListBoxProc
	Button addDataSet win=analysis_tools,pos={234,440},size={100,20},title="Add/Update",disable=1,help={"Adds a new data set.\rUpdates it if it already exists"},proc=atButtonProc
	Button addDataSetFromSelection win=analysis_tools,pos={234,460},size={100,20},title="From Selection",help={"Adds a new data set from the wave list in Browse mode"},disable=1,proc=atButtonProc
	Button delDataSet win=analysis_tools,pos={234,480},size={100,20},title="Delete",help={"Delete the data set"},disable=1,proc=atButtonProc
	SetVariable dataSetName win=analysis_tools,pos={80,451},size={130,20},title="DS Name",disable=1,value=_STR:"NewDS"
	Button matchStraddOR win=analysis_tools,pos={202,38},size={22,20},title="OR",fsize=8,disable=1,proc=atButtonProc
	Button notMatchStraddOR win=analysis_tools,pos={202,58},size={22,20},title="OR",fsize=8,disable=1,proc=atButtonProc
	helpNote = "Organize the wave list into wave sets by the indicated underscore position.\rUses zero offset; -2 concatenates into a single wave set"
	SetVariable waveGrouping win=analysis_tools,pos={80,471},size={130,20},title="Grouping",disable=1,value=_STR:"",help={helpNote},proc=atSetVarProc
	
	SetVariable prefixGroup win=analysis_tools,pos={10,491},size={40,20},title="P",disable=1,value=_STR:"",help={"Filter the wave list by the 1st underscore position"},proc=atSetVarProc
	SetVariable groupGroup win=analysis_tools,pos={50,491},size={40,20},title="G",disable=1,value=_STR:"",help={"Filter the wave list by the 2nd underscore position"},proc=atSetVarProc
	SetVariable seriesGroup win=analysis_tools,pos={90,491},size={40,20},title="Se",disable=1,value=_STR:"",help={"Filter the wave list by the 3rd underscore position"},proc=atSetVarProc
	SetVariable sweepGroup win=analysis_tools,pos={130,491},size={40,20},title="Sw",disable=1,value=_STR:"",help={"Filter the wave list by the 4th underscore position"},proc=atSetVarProc
	SetVariable traceGroup win=analysis_tools,pos={170,491},size={40,20},title="T",disable=1,value=_STR:"",help={"Filter the wave list by the 5th underscore position"},proc=atSetVarProc
	
	//For Rescale Scans
	SetVariable scaleFactor win=analysis_tools,pos={125,62},size={125,20},bodywidth=40,title="Scale Factor (µm/volt)",disable=1,value=_NUM:60
	
	//For ROI Grid
	SetVariable gridSizeX win=analysis_tools,pos={10,108},size={60,20},title="X Size",value=_NUM:10,limits={1,inf,1},disable=1
	SetVariable gridSizeY win=analysis_tools,pos={80,108},size={60,20},title="Y Size",value=_NUM:10,limits={1,inf,1},disable=1
	CheckBox overwriteGrid win=analysis_tools,pos={10,60},size={60,20},title="Overwrite",disable=1
	CheckBox optimizePosition win=analysis_tools,pos={84,60},size={60,20},title="Optimize Positions",disable=1
	SetVariable pctOverlap win=analysis_tools,pos={196,61},size={80,20},title="% Overlap",value=_NUM:0,disable=1
	SetVariable pixelThresholdPct win=analysis_tools,pos={196,87},size={95,20},title="% Threshold",value=_NUM:0,limits={0,100,1},disable=1
	Button nudgeAll win=analysis_tools,pos={10,145},size={75,20},title="Nudge All",disable=1,proc=atButtonProc
	
	//For Filter ROI
	PopUpMenu thresholdType win=analysis_tools,pos={10,156},size={140,20},title="Threshold Type",value="∆F/F;SNR",disable=1
	SetVariable roiThreshold win=analysis_tools,pos={145,158},size={40,20},title="",limits={0,inf,0.05},value=_NUM:1,disable=1
	
	//For External Functions
	PopUpMenu extFuncPopUp win=analysis_tools,pos={21,67},size={150,200},title="Functions:",fSize=12,disable=1,value=#"root:Packages:analysisTools:extFuncList",proc=atPopProc
	
	String/G root:Packages:analysisTools:DSNames
	SVAR DSNames = root:Packages:analysisTools:DSNames
	DSNames = "--None--;--Scan List--;--Item List--;" + textWaveToStringList(dataSetNames,";")
	
	PopUpMenu extFuncDS win=analysis_tools,pos={21,90},size={150,20},title="Waves",fSize=12,disable=1,value=#"root:Packages:analysisTools:DSNames",proc=atPopProc
	PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,90},size={100,20},fsize=12,title="CH",value="1;2",disable=1
	Button extFuncHelp win=analysis_tools,pos={2,66},size={15,20},title="?",disable=1,proc=atButtonProc
	
	Make/N=0/T/O root:Packages:analysisTools:emptyWave
	Wave/T emptyWave = root:Packages:analysisTools:emptyWave
	ListBox extFuncDSListBox win=analysis_tools,size={155,344},pos={180,121},mode=0,listWave=emptyWave,disable=1
	
	//For Run Cmd Line
	SetVariable cmdLineStr win=analysis_tools,size={300,20},pos={21,65},fsize=12,title="Cmd:",value=_STR:"",disable=1
	
	//For Denoise
	Checkbox overwriteCheck win=analysis_tools,size={60,20},pos={20,29},title="Overwrite",disable=1
	SetVariable outputFolder win=analysis_tools,size={150,20},pos={90,30},title="Output Folder",value=_STR:"",disable=1
	SetVariable scriptFolder win=analysis_tools,size={300,20},pos={20,50},title="Python Script Folder",value=_STR:"",disable=1
	SetVariable denoiseDataFolder win=analysis_tools,size={300,20},pos={20,70},title="Denoise Data Folder",value=_STR:"",disable=1
	
	//For MultiROI
	CheckBox doDarkSubtract win=analysis_tools,pos={10,250},size={150,20},title="Dark Subtraction",disable=1
	CheckBox activePixelsOnly win=analysis_tools,pos={10,270},size={150,20},title="Active Pixels Only",disable=1
	SetVariable activePixelThreshSize win=analysis_tools,pos={110,272},size={40,20},limits={0,inf,0.05},title="",value=_NUM:1.25,disable=1
	
	
	yPos += 20
	setvariable bslnEndVar, win = analysis_tools, pos = {10,yPos}, size = {90, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GbslnEnd, title = "Bsln End"
	setvariable peakEndVar, win = analysis_tools, pos = {120,yPos}, size = {90, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GpeakEnd, title = "Peak End"
	setvariable BatchsizeVar, win = analysis_tools, pos = {230,yPos}, size = {100, 30},bodywidth=35, noproc, value = root:Packages:analysisTools:GBatchSize, title = "Batch Size"
	
	//setvariable SpaceFilterVar, win = analysis_tools, pos = {30,yPos}, size = {130, 30}, disable = able, noproc, value = root:Packages:analysisTools:GSpaceFilter, title = "Space Filter (pix)"
	//CheckBox SpaceFilterBox,win = analysis_tools,pos={10,yPos},title = "", proc = atCheckProc
	//setvariable DarkValueVar, win = analysis_tools, pos = {190,yPos}, size = {100, 30}, disable = able, noproc, value = root:Packages:analysisTools:GdarkValue, title = "Dark Subt."
	//CheckBox DarkSubtBox,win = analysis_tools,pos={170,yPos}, title = "", proc = atCheckProc
	
	yPos += 20
	SetVariable SmoothFilterVar win=analysis_tools, pos={20,yPos},size={80,30},bodywidth=35,disable =0,value=root:Packages:analysisTools:GSmoothFilter, title = "Smooth"
	CheckBox SmoothBox,win = analysis_tools,pos={10,yPos}, title = "", proc = atCheckProc

	//CheckBox NotSeqBox,win = analysis_tools,pos={170,yPos},title="Not in sequence?",proc = atCheckProc
	
	yPos+=20
	CheckBox ch1Check,win=analysis_tools,pos={60,yPos},title="Ch1"
	CheckBox ch2Check,win=analysis_tools,pos={100,yPos},title="Ch2"
	CheckBox ratioCheck,win=analysis_tools,pos={140,yPos},title="Ratio"
	PopUpMenu dFAbsMenu,win=analysis_tools,pos={10,yPos},value="∆;Abs",title="",disable=1
		
	yPos += 20
	CheckBox getPeaksCheck,win=analysis_tools,pos={10,yPos},title="Get Peaks"
	SetVariable pkWindow win=analysis_tools,title="Width",pos={68,yPos+1},bodywidth=35,value=_NUM:0,limits={0,inf,0.05},size={80,20},disable=0
	
	yPos +=20
	CheckBox doAvgCheck,win=analysis_tools,pos={10,yPos},title="Get tAvg"
	CheckBox doAvgROIsCheck,win=analysis_tools,pos={90,yPos},title="Avg ROIs"
	
	yPos += 20
	SetVariable angleList win=analysis_tools,title="Angles",pos={10,yPos-1},value=_STR:"",size={175,20},disable=0
	
	yPos += 20
	Wave/T/Z presetAngleWave = root:Packages:analysisTools:presetAngleWave
	If(!WaveExists(presetAngleWave))
		Make/O/T/N=(3,3) root:Packages:analysisTools:presetAngleWave
		Wave/T presetAngleWave = root:Packages:analysisTools:presetAngleWave
		presetAngleWave[0][0] = "-----"
		presetAngleWave[0][1] = ""
		presetAngleWave[1][0] = "Linear"
		presetAngleWave[1][1] = "0,45,90,135,180,225,270,315"
		presetAngleWave[2][0] = "Alternating"
		presetAngleWave[2][1] = "0,180,45,225,90,270,135,315"
	EndIf
	
	String/G root:Packages:analysisTools:presetAngleLists
	SVAR presetAngleLists = root:Packages:analysisTools:presetAngleLists
	presetAngleLists = ""
	
	For(i=0;i<DimSize(presetAngleWave,0);i+=1)
		presetAngleLists += presetAngleWave[i][0] + ";"
	EndFor

	PopUpMenu presetAngleListPop win=analysis_tools,title="Presets",pos={10,yPos-1},size={80,20},value=#"root:Packages:analysisTools:presetAngleLists",disable=0,proc=atPopProc
	Button addPresetAngle win=analysis_tools,title="+",pos={100,yPos-1},size={20,20},disable=1,proc=atButtonProc
	Button deletePresetAngle win=analysis_tools,title="-",pos={125,yPos-1},size={20,20},disable=1,proc=atButtonProc
	
	DrawAction/W=analysis_tools delete
	ChangeControls("Data Sets","MultiROI")
	
	DoWindow/F analysis_tools
	cdf = GetDataFolder(1)
	
	//any default settings for system personalization can be changed here
	SetDefaults()
End

//Assigns control variables to functions from the 'Command' pop up menu
Function CreateControlLists(cmdList)
	String cmdList
	Make/O/N=(ItemsInList(cmdList,";")) root:Packages:analysisTools:controlHeight
	Wave controlHeight = root:Packages:analysisTools:controlHeight
	//Add the names of your controls to the appropriate list to assign controls to that tab.
	//Assignment allows the tab to automatically hide or show controls assigned to that tab when it gets clicked. 
	//Make sure the name of a new control list is with format: 'ctrlList_' + 'name of control'
	
	//MultiROI
	String/G root:Packages:analysisTools:ctrlList_multiROI
	SVAR ctrlList_MultiROI = root:Packages:analysisTools:ctrlList_multiROI
	ctrlList_MultiROI = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;DarkValueVar;SmoothBox;SpaceFilterVar;SmoothFilterVar;angleList;BatchsizeVar;numtrialsVar;"
	ctrlList_MultiROI += "ch1Check;ch2Check;ratioCheck;getPeaksCheck;pkWindow;doAvgCheck;presetAngleListPop;addPresetAngle;deletePresetAngle;RemoveLaserResponseCheck;"
	ctrlList_MultiROI += "doDarkSubtract;activePixelsOnly;activePixelThreshSize;doAvgROIsCheck;dFAbsMenu"

	
	//ROI From Map
	String/G root:Packages:analysisTools:ctrlList_roiFromMap
	SVAR ctrlList_roiFromMap = root:Packages:analysisTools:ctrlList_roiFromMap
	ctrlList_roiFromMap = "SmoothFilterVar;ch1Check;ch2Check;ratioCheck;SmoothBox;avgResultsCheck"

		
	//df Map
	String/G root:Packages:analysisTools:ctrlList_dfMap
	SVAR ctrlList_dfMap = root:Packages:analysisTools:ctrlList_dfMap
	//ctrlList_dfMap = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;BatchsizeVar;numtrialsVar;DarkValueVar;SmoothBox;SpaceFilterVar;SmoothFilterVar;"
	//ctrlList_dfMap += "SpaceFilterBox;DarkSubtBox;NotSeqBox;ch1Check;ch2Check;ratioCheck"
	ctrlList_dfMap = "ch1Check;ch2Check;ratioCheck;maskListPopUp;varianceMapCheck;peakStVar;peakEndVar;bslnStVar;bslnEndVar;histogramCheck;cleanUpNoise;"
	ctrlList_dfMap += "RemoveLaserResponseCheck;SmoothFilterVar;SmoothBox;spatialFilterCheck;maskAllFoldersCheck;postSpatialFilter;cleanUpNoiseThresh;doDarkSubtract"

	//Apply Map Threshold
	String/G root:Packages:analysisTools:ctrlList_applyMapThreshold
	SVAR ctrlList_applyMapThreshold = root:Packages:analysisTools:ctrlList_applyMapThreshold
	ctrlList_applyMapThreshold = "extFuncDS;extFuncChannelPop;extFuncDSListBox;mapThreshold;"
	
	//Average
	String/G root:Packages:analysisTools:ctrlList_average
	SVAR ctrlList_average = root:Packages:analysisTools:ctrlList_average
	ctrlList_average = "extFuncDS;extFuncChannelPop;extFuncDSListBox;outFolder"
	
	//Error
	String/G root:Packages:analysisTools:ctrlList_error
	SVAR ctrlList_error = root:Packages:analysisTools:ctrlList_error
	ctrlList_error = "extFuncDS;extFuncChannelPop;extFuncDSListBox;errType;outFolder"
	
	//Kill Waves
	String/G root:Packages:analysisTools:ctrlList_killwaves
	SVAR ctrlList_killwaves = root:Packages:analysisTools:ctrlList_killwaves
	ctrlList_killwaves = "extFuncDS;extFuncChannelPop;extFuncDSListBox"
	
	//Duplicate/Rename
	String/G root:Packages:analysisTools:ctrlList_duplicateRename
	SVAR ctrlList_duplicateRename = root:Packages:analysisTools:ctrlList_duplicateRename
	ctrlList_duplicateRename = "extFuncDS;extFuncChannelPop;extFuncDSListBox;prefixName;groupName;SeriesName;SweepName;TraceName;killOriginals;"
	
	//Space-Time dF
	String/G root:Packages:analysisTools:ctrlList_spacetimeDF
	SVAR ctrlList_spacetimeDF = root:Packages:analysisTools:ctrlList_spacetimeDF
	ctrlList_spacetimeDF = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;BatchsizeVar;numtrialsVar;SmoothBox;SmoothFilterVar"

	
	//ROI Tuning Curve
	String/G root:Packages:analysisTools:ctrlList_roiTuningCurve
	SVAR ctrlList_roiTuningCurve = root:Packages:analysisTools:ctrlList_roiTuningCurve
	ctrlList_roiTuningCurve = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;BatchsizeVar;numtrialsVar;DarkValueVar;SmoothBox;SmoothFilterVar;"
	ctrlList_roiTuningCurve += "angleList;ch1Check;ch2Check;ratioCheck"
	
	//Analysis tab control group
	String/G root:Packages:analysisTools:ctrlList_analysisTab
	SVAR ctrlList_analysisTab = root:Packages:analysisTools:ctrlList_analysisTab
	ctrlList_analysisTab = ctrlList_MultiROI + ";" + ctrlList_dfMap + ";"
	
	//Mapping tab control group 
	String/G root:Packages:analysisTools:ctrlList_mappingTab
	SVAR ctrlList_mappingTab = root:Packages:analysisTools:ctrlList_mappingTab
	ctrlList_mappingTab = ""
	
	//Displaying ROI traces
	String/G root:Packages:analysisTools:ctrlList_displayROIs
	SVAR ctrlList_displayROIs = root:Packages:analysisTools:ctrlList_displayROIs
	ctrlList_displayROIs = "horDisplayArrangementPopUp;vertDisplayArrangementPopUp;dispAveragesCheck;scanOrderROIdisplay;roiOrderROIdisplay;"
	ctrlList_displayROIs += "presetAngleListPop;addPresetAngle;deletePresetAngle;ch1Check;ch2Check;ratioCheck;graphName;colorROIs" // SS edit Nov6 2018
	
	//Registering scans that are distorted during bidirectional scanning
	String/G root:Packages:analysisTools:ctrlList_adjustGalvoDistort
	SVAR ctrlList_adjustGalvoDistort = root:Packages:analysisTools:ctrlList_adjustGalvoDistort
	ctrlList_adjustGalvoDistort = "SR_waveList;SR_phase;SR_phaseLock;SR_phaseVal;SR_pixelDeltaLock;SR_pixelDelta;SR_divergenceLock;SR_divergence;"
	ctrlList_adjustGalvoDistort += "SR_frequencyLock;SR_frequency;SR_pixelOffsetLock;SR_pixelOffset;SR_autoRegisterButton;SR_addROIButton;SR_reset;"
	ctrlList_adjustGalvoDistort += "SR_showROIButton;SR_saveTemplateButton;SR_applyTemplate;SR_templatePopUp;SR_UseAnalysisToolsCheck;ch1Check;ch2Check"

	//Get Dendritic Mask
	String/G root:Packages:analysisTools:ctrlList_getDendriticMask
	SVAR ctrlList_getDendriticMask = root:Packages:analysisTools:ctrlList_getDendriticMask
	ctrlList_getDendriticMask = "ch1Check;ch2Check;maskThreshold;mask3DCheck"
	
	//Mask Image
	String/G root:Packages:analysisTools:ctrlList_maskImage
	SVAR ctrlList_maskImage = root:Packages:analysisTools:ctrlList_maskImage
	ctrlList_maskImage = "extFuncDS;extFuncChannelPop;extFuncDSListBox;maskListPopUp;overwriteCheck"
	
	//Dynamic ROI
	String/G root:Packages:analysisTools:ctrlList_dynamicROI
	SVAR ctrlList_dynamicROI = root:Packages:analysisTools:ctrlList_dynamicROI
	ctrlList_dynamicROI = "extFuncDS;extFuncChannelPop;extFuncDSListBox;dynamicROI_size"
	
	//Operation
	String/G root:Packages:analysisTools:ctrlList_operation
	SVAR ctrlList_operation = root:Packages:analysisTools:ctrlList_operation
	ctrlList_operation = "waveMatch;waveNotMatch;matchListBox;operation;outputSuffix;operationOptionsPop;dataSetListBox;useDataSetCheck;matchStraddOR;notMatchStraddOR"
	
	//Get Peaks
	String/G root:Packages:analysisTools:ctrlList_getPeaks
	SVAR ctrlList_getPeaks = root:Packages:analysisTools:ctrlList_getPeaks
	ctrlList_getPeaks = "bslnStVar;bslnEndVar;peakStVar;peakEndVar;extFuncDS;extFuncDSListBox;extFuncChannelPop"
	
	//Line Profile
	String/G root:Packages:analysisTools:ctrlList_lineProfile
	SVAR ctrlList_lineProfile = root:Packages:analysisTools:ctrlList_lineProfile
	ctrlList_lineProfile = "SR_waveList;lineProfileWidth;saveLineProfile;useScanListCheck;applyLineProfile;lineProfileTemplatePopUp;saveLineProfileSuffix;"
	ctrlList_lineProfile += "ch1Check;ch2Check;collapseLineProfileCheck;dFLineProfileCheck;bslnStVar;bslnEndVar;SmoothFilterVar;SmoothBox;peakStVar;peakEndVar;distanceOnlyCheck"

	//ROI Segmenter
	String/G root:Packages:analysisTools:ctrlList_roiSegmenter
	SVAR ctrlList_roiSegmenter = root:Packages:analysisTools:ctrlList_roiSegmenter
	ctrlList_roiSegmenter = "OpenMaskButton;GetSeedPosition;maskListPopUp"
	
	//Register image (translation)
	String/G root:Packages:analysisTools:ctrlList_registerImage
	SVAR ctrlList_registerImage = root:Packages:analysisTools:ctrlList_registerImage
	ctrlList_registerImage = "applyImageRegistration;refImagePopUp;testImagePopUp;registrationTemplatePopUp;useScanListCheck;ch1Check;ch2Check"
	
	//Vector Sum Map
	String/G root:Packages:analysisTools:ctrlList_vectorSumMap
	SVAR ctrlList_vectorSumMap = root:Packages:analysisTools:ctrlList_vectorSumMap
	ctrlList_vectorSumMap = "ch1Check;ch2Check;ratioCheck;angleList;histogramCheck;presetAngleListPop;addPresetAngle;deletePresetAngle" 
	
	//Rescale scans Rescale Scans
	String/G root:Packages:analysisTools:ctrlList_rescaleScans
	SVAR ctrlList_rescaleScans = root:Packages:analysisTools:ctrlList_rescaleScans
	ctrlList_rescaleScans = "ch1Check;ch2Check;scaleFactor" 
	
	//Data Sets
	String/G root:Packages:analysisTools:ctrlList_dataSets
	SVAR ctrlList_dataSets = root:Packages:analysisTools:ctrlList_dataSets
	ctrlList_dataSets = "waveMatch;waveNotMatch;relativeFolderMatch;matchListBox;dataSetListBox;addDataSet;dataSetName;delDataSet;"
	ctrlList_dataSets += "waveGrouping;addDataSetFromSelection;matchStraddOR;notMatchStraddOR;"
	ctrlList_dataSets += "prefixGroup;GroupGroup;SeriesGroup;SweepGroup;TraceGroup"
	
	//Get Peak Times
	String/G root:Packages:analysisTools:ctrlList_getPeakTimes
	SVAR ctrlList_getPeakTimes = root:Packages:analysisTools:ctrlList_getPeakTimes
	ctrlList_getPeakTimes = "peakStVar;peakEndVar;dataSetListBox;useDataSetCheck" 
	
	//ROI Grid
	String/G root:Packages:analysisTools:ctrlList_roiGrid
	SVAR ctrlList_roiGrid = root:Packages:analysisTools:ctrlList_roiGrid
	ctrlList_roiGrid = "maskListPopUp;gridSizeX;gridSizeY;overwriteGrid;ch1Check;ch2Check;pixelThresholdPct" 
	
	//Filter ROI
	String/G root:Packages:analysisTools:ctrlList_filterROI
	SVAR ctrlList_filterROI = root:Packages:analysisTools:ctrlList_filterROI
	ctrlList_filterROI = "roiThreshold;thresholdType;bslnStVar;bslnEndVar;peakStVar;peakEndVar;ch1Check;ch2Check;ratioCheck" 
	
	//Kill ROI
	String/G root:Packages:analysisTools:ctrlList_killROI
	SVAR ctrlList_killROI = root:Packages:analysisTools:ctrlList_killROI
	ctrlList_killROI = ""
	
	//Denoise
	String/G root:Packages:analysisTools:ctrlList_denoise
	SVAR ctrlList_denoise = root:Packages:analysisTools:ctrlList_denoise
	ctrlList_denoise = "extFuncDS;extFuncChannelPop;extFuncDSListBox;overwriteCheck;outputFolder;scriptFolder;denoiseDataFolder"
	
	//For External Functions
	String/G root:Packages:analysisTools:ctrlList_extFunc
	SVAR ctrlList_extFunc = root:Packages:analysisTools:ctrlList_extFunc
	ctrlList_extFunc = "extFuncPopUp;extFuncDS;extFuncChannelPop;extFuncDSListBox;extFuncHelp"
	
	//Load PClamp
	String/G root:Packages:analysisTools:ctrlList_loadPClamp
	SVAR ctrlList_loadPClamp = root:Packages:analysisTools:ctrlList_loadPClamp
	ctrlList_loadPClamp = "OpenABF2Loader"
	
	//Browse PClamp
	String/G root:Packages:analysisTools:ctrlList_browsePClamp
	SVAR ctrlList_browsePClamp = root:Packages:analysisTools:ctrlList_browsePClamp
	ctrlList_browsePClamp = "fileListBox;sweepListBox"
	
	//Load Stimulus Data
	String/G root:Packages:analysisTools:ctrlList_LoadStimulusData
	SVAR ctrlList_LoadStimulusData = root:Packages:analysisTools:ctrlList_LoadStimulusData
	ctrlList_LoadStimulusData = ""

	//Run Cmd Line
	String/G root:Packages:analysisTools:ctrlList_runCmdLine
	SVAR ctrlList_runCmdLine = root:Packages:analysisTools:ctrlList_runCmdLine
	ctrlList_runCmdLine = "cmdLineStr;extFuncDS;extFuncChannelPop;extFuncDSListBox"
	
	//Max Proj
	String/G root:Packages:analysisTools:ctrlList_maxProj
	SVAR ctrlList_maxProj = root:Packages:analysisTools:ctrlList_maxProj
	ctrlList_maxProj = "extFuncDS;extFuncChannelPop;extFuncDSListBox"
	
End

Function ChangeControls(currentCmd,prevCmd)
	String currentCmd,prevCmd
	Variable tab
	Wave controlHeight = root:Packages:analysisTools:controlHeight
	Variable i
	String cmdStr
	SVAR runCmdStr =  root:Packages:analysisTools:runCmdStr
	SVAR cmdList = root:Packages:analysisTools:cmdList
	
	SVAR saveCurrentCmd = root:Packages:analysisTools:currentCmd
	//Erase the help message box
	AT_DisplayHelpMessage("None")
	
//If(cmpstr(currentCmd[0],"-") == 0)
//		currentCmd = prevCmd
//		return 0
//	EndIf
	
	//Delete any draw layer items
	SetDrawLayer/K/W=analysis_tools UserBack
	
	strswitch(prevCmd)
		case "MultiROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_multiROI
			break
		case "dF Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dfMap
			break
		case "Average":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_average
			break
		case "Error":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_error
			break
		case "Space-Time dF":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_spacetimeDF
			break
		case "qkSpot":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_qkSpot
			break
		case "ROI Tuning Curve":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiTuningCurve
			break
		case "Display ROIs":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_displayROIs
			break
		case "Adjust Galvo Distortion":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_adjustGalvoDistort
			break
		case "Get Dendritic Mask":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getDendriticMask
			break
		case "Mask Image":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_maskImage
			break
		case "Operation":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_operation
			break
		case "Get Peaks":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeaks
			break
		case "Line Profile":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_lineProfile
			break
		case "ROI Segmenter":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiSegmenter
			break
		case "Register Image":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_registerImage
			break
		case "ROI From Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiFromMap
			break
		case "Vector Sum Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_vectorSumMap
			break
		case "Dynamic ROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dynamicROI
			break
		case "Rescale Scans":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_rescaleScans
			break
		case "Data Sets":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dataSets
			break
		case "Get Peak Times":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeakTimes
			break
		case "ROI Grid":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiGrid
			break
		case "Filter ROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_filterROI
			break
		case "Kill ROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_killROI
			break
		case "Denoise":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_denoise
			break
		case "Load PClamp":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_loadPClamp
			break
		case "Browse PClamp":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_browsePClamp
			break
		case "Load Stimulus Data":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_LoadStimulusData
			break
		case "Kill Waves":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_killwaves
			break
		case "Duplicate/Rename":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_duplicateRename
			break
		case "External Function":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_extFunc
			ControlInfo/W=analysis_tools extFuncPopUp
			ResolveFunctionParameters("AT_" + S_Value)
			break	
		case "Run Cmd Line":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_runCmdLine
			break
		case "Max Project":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_maxProj
			break
		case "Apply Map Threshold":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_applyMapThreshold
			break
	endswitch
	
	If(strlen(prevCmd))
		//Hide controls from previous tab)
		For(i=0;i<ItemsInList(ctrlList,";");i+=1)
			ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
			cmdStr = TrimString(StringFromList(0,S_Recreation,","))
			cmdStr += " win=analysis_tools,disable = 1"
			Execute cmdStr
		EndFor	
	EndIf	
	
	strswitch(currentCmd)
		case "MultiROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_multiROI
			runCmdStr = "GetROI()"
			break
		case "dF Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dfMap
			//runCmdStr = "dFMaps()"
			//runCmdStr = "dfMapSimple()"
			runCmdStr = "dfMapMultiThread()"
			break
		case "Average":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_average
			runCmdStr = "AverageWaves()"
			break
		case "Error":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_error
			runCmdStr = "ErrorWaves()"
			break
		case "Space-Time dF":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_spacetimeDF
			runCmdStr = "SpaceTimeDF()"
			break
		case "qkSpot":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_qkSpot
			runCmdStr = "qkSpot()"
			break
		case "ROI Tuning Curve":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiTuningCurve
			runCmdStr = "roiTuningCurve()"
			break
		case "Display ROIs":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_displayROIs
			runCmdStr = "displayROIs()"
			break
		case "Adjust Galvo Distortion":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_adjustGalvoDistort
			runCmdStr = ""
			break
		case "Get Dendritic Mask":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getDendriticMask
			runCmdStr = "getDendriticMask()"
			break
		case "Mask Image":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_maskImage
			runCmdStr = "maskScanData()"
			break
		case "Operation":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_operation
			runCmdStr = "doOperation()"
			break
		case "Get Peaks":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeaks
			runCmdStr = "getPeaks()"
			break
		case "Line Profile":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_lineProfile
			runCmdStr = "getLineProfile()"
			break
		case "ROI Segmenter":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiSegmenter
			runCmdStr = "OpenMask()"
			break
		case "Register Image":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_registerImage
			runCmdStr = "GetRegistrationParameters()"
			break
		case "ROI From Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiFromMap
			runCmdStr = "ROI_From_MapData()"
			break
		case "Vector Sum Map":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_vectorSumMap
			runCmdStr = "VectorSumMap()"
			break
		case "Dynamic ROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dynamicROI
			runCmdStr = "doDynamicROI()"
			break
		case "Rescale Scans":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_rescaleScans
			runCmdStr = "rescale2P_Scans()"
			break
		case "Data Sets":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_dataSets
			runCmdStr = "print \"Define your Data Set!\""
			break
		case "Get Peak Times":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_getPeakTimes
			runCmdStr = "GetPkTimes()"
			break
		case "ROI Grid":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_roiGrid
			runCmdStr = "gridROI()"
			break
		case "Filter ROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_filterROI
			runCmdStr = "filterROI()"
			break
		case "Kill ROI":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_killROI
			runCmdStr = "deleteROI()"
			break
		case "Denoise":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_denoise
			runCmdStr = "exportWaves()"
			break
		case "Load PClamp":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_loadPClamp
			runCmdStr = ""
			break
		case "Browse PClamp":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_browsePClamp
			runCmdStr = "browsePClamp()"
			break
		case "Load Stimulus Data":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_LoadStimulusData
			runCmdStr = "LoadStimulusData()"
			break
		case "Kill Waves":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_killwaves
			runCmdStr = "AT_KillWaves()"
			break
		case "Duplicate/Rename":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_duplicateRename
			runCmdStr = "duplicateRename()"
			break
		case "External Function":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_extFunc
			runCmdStr = "()"
			break
		case "Run Cmd Line":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_runCmdLine
			runCmdStr = ""	//will resolve at run time
			break
		case "Max Project":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_maxProj
			runCmdStr = "atMaxProj()"
			break
		case "Apply Map Threshold":
			SVAR ctrlList = root:Packages:analysisTools:ctrlList_applyMapThreshold
			runCmdStr = "mapThresh()"
			break
		default:
			//Loads a package if its not a function
			LoadPackage(currentCmd)
			return 0
	endswitch
	
	S_Recreation = ""
	
	If(cmpstr(currentCmd,"Adjust Galvo Distortion") == 0)
		AT_InitializeScanRegister()
		//Clear any text drawing layers from qkSpot build
		DrawAction/W=analysis_tools delete
	Else
		//Clear any text drawing layers from qkSpot build
		DrawAction/W=analysis_tools delete
	EndIf
		
	//Show controls from current tab
	For(i=0;i<ItemsInList(ctrlList,";");i+=1)
		ControlInfo/W=analysis_tools $StringFromList(i,ctrlList)
		cmdStr = TrimString(StringFromList(0,S_Recreation,","))
		
		String os = IgorInfo(2)
		If(!cmpstr(os,"Macintosh"))
			cmdStr += " win=analysis_tools,disable = 0"
		ElseIf(!cmpstr(os,"Windows"))
			cmdStr += " win=analysis_tools,disable = 0,fsize=10"
		EndIf
		
		If(StringMatch(cmdStr,"*ch1Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) == 0)
			CheckBox ch1Check,win=analysis_tools,pos={34,264}
		ElseIf(StringMatch(cmdStr,"*ch2Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) == 0)
			CheckBox ch2Check,win=analysis_tools,pos={74,264},title="Ch2"
		ElseIf(StringMatch(cmdStr,"*ch1Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) != 0)
			CheckBox ch1Check,win=analysis_tools,pos={10,190},title="Ch1"
		ElseIf(StringMatch(cmdStr,"*ch2Check*") && cmpstr("Adjust Galvo Distortion",currentCmd) != 0)
			CheckBox ch2Check,win=analysis_tools,pos={50,190},title="Ch2"
		EndIf
		
		Execute cmdStr
	EndFor
	
	//Change some of the control positions for certain functions
	strswitch(currentCmd)
		case "Adjust Galvo Distortion":
			CheckBox ch1Check,win=analysis_tools,pos={34,264}
			CheckBox ch2Check,win=analysis_tools,pos={74,264}
			CheckBox ratioCheck,win=analysis_tools,pos={104,264}
			AT_InitializeScanRegister()
			break
		case "Get Dendritic Mask":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61},value=0
			break
		case "df Map":
			PopUpMenu maskListPopUp win=analysis_tools,value=GetMaskWaveList()
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			SetVariable peakStVar win=analysis_tools,pos={230,103}
			SetVariable peakEndVar win=analysis_tools,pos={235,123}
			SetVariable bslnStVar win=analysis_tools,pos={232,63}
			SetVariable bslnEndVar win=analysis_tools,pos={237,83}
			CheckBox SmoothBox,win=analysis_tools,pos={225,143}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={240,143}
			CheckBox histogramCheck win=analysis_tools,pos={10,110}
			CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,151}
			CheckBox doDarkSubtract win=analysis_tools,pos={10,171}
			break
		case "Get Peaks":
			CheckBox ch1Check,win=analysis_tools,pos={26,61}
			CheckBox ch2Check,win=analysis_tools,pos={61,61}
			CheckBox ratioCheck,win=analysis_tools,pos={26,82}
			PopUpMenu extFuncDS win=analysis_tools,pos={21,110}
			ListBox extFuncDSListBox win=analysis_tools,pos={21,136}
			ControlInfo/W=analysis_tools extFuncDS
			If(cmpstr(S_Value,"--Scan List--") != 0)
				PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},disable=1
			Else
				PopUpMenu extFuncChannelPop win=analysis_tools,pos={175,110},disable=0
			EndIf
			break
		case "Line Profile":
			CheckBox ch1Check,win=analysis_tools,pos={202,142}
			CheckBox ch2Check,win=analysis_tools,pos={202,162}
			SetVariable bslnStVar win=analysis_tools,pos={248,165},bodywidth=35
			SetVariable bslnEndVar win=analysis_tools,pos={248,185},bodywidth=35
			SetVariable peakStVar win=analysis_tools,pos={248,206},bodywidth=35
			SetVariable peakEndVar win=analysis_tools,pos={248,226},bodywidth=35
			CheckBox SmoothBox,win=analysis_tools,pos={115,184}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={135,185}
			break
		case "Register Image":
			CheckBox useScanListCheck win=analysis_tools,pos={278,109},title="Scan\rList"
			CheckBox ch1Check,win=analysis_tools,pos={10,162}
			CheckBox ch2Check,win=analysis_tools,pos={50,162}
			break
		case "ROI From Map":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			CheckBox SmoothBox,win=analysis_tools,pos={142,62}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={162,62}
			break
		case "Vector Sum Map":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			CheckBox ratioCheck,win=analysis_tools,pos={90,61}
			SetVariable angleList,win=analysis_tools,pos={10,81}
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,101}
			Button addPresetAngle,win=analysis_tools,pos={140,101}
			Button deletePresetAngle,win=analysis_tools,pos={165,101}
			CheckBox histogramCheck win=analysis_tools,pos={10,125}
			break
		case "Rescale Scans":
			CheckBox ch1Check,win=analysis_tools,pos={10,61}
			CheckBox ch2Check,win=analysis_tools,pos={50,61}
			break
		case "Display ROIs":
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,124}
			Button addPresetAngle,win=analysis_tools,pos={140,124}
			Button deletePresetAngle,win=analysis_tools,pos={165,124}
			CheckBox ch1Check,win=analysis_tools,pos={10,39}
			CheckBox ch2Check,win=analysis_tools,pos={50,39}
			CheckBox ratioCheck,win=analysis_tools,pos={90,39}
			break
		case "External Function":			
			ControlInfo/W=analysisTools extFuncPopUp
			ResolveFunctionParameters("AT_" + S_Value)
			PopUpMenu extFuncDS win=analysis_tools,pos={21,90}
			ListBox extFuncDSListBox win=analysis_tools,pos={180,121}
			break
		case "Data Sets":
			SetDrawLayer/W=analysis_tools UserBack
			SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
			DrawText/W=analysis_tools 95,117,"Waves:"
			DrawText/W=analysis_tools 255,117,"Data Sets:"
			DrawLine/W=analysis_tools 220,449,220,471
			DrawLine/W=analysis_tools 220,449,230,449
			
			SetDrawEnv/W=analysis_tools arrow= 1,arrowlen= 5.00
			DrawLine/W=analysis_tools 220,471,230,471
			
			SetDrawLayer/W=analysis_tools ProgBack
			break
		case "Operation":
			SetDrawLayer/W=analysis_tools UserBack
			SetDrawEnv/W=analysis_tools fsize=12,xcoord=abs,ycoord=abs
			DrawText/W=analysis_tools 95,117,"Waves:"
			DrawText/W=analysis_tools 255,117,"Data Sets:"
			SetDrawLayer/W=analysis_tools ProgBack
			break
		case "Mask Image":
			PopUpMenu maskListPopUp win=analysis_tools,value=GetMaskWaveList(),pos={20,50}
		case "Denoise":
		case "Max Project":
		case "Dynamic ROI":
		case "Duplicate/Rename":
		case "Average":
		case "Error":
		case "Kill Waves":
		case "Run Cmd Line":
			PopUpMenu extFuncChannelPop win=analysis_tools,pos={21,90},disable=1
			ListBox extFuncDSListBox win=analysis_tools,pos={180,121},disable=1
			ControlInfo/W=analysis_tools extFuncDS
			SetExtFuncMenus(S_Value)
			break
		case "MultiROI":
			CheckBox SmoothBox,win=analysis_tools,pos={10,107}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={30,107}
			SetVariable bslnStVar win=analysis_tools,pos={10,65}
			SetVariable bslnEndVar win=analysis_tools,pos={15,85}
			SetVariable peakStVar win=analysis_tools,pos={120,65}
			SetVariable peakEndVar win=analysis_tools,pos={125,85}
			CheckBox ch1Check,win=analysis_tools,pos={60,127}
			CheckBox ch2Check,win=analysis_tools,pos={100,127}
			CheckBox ratioCheck,win=analysis_tools,pos={140,127}
			SetVariable angleList,win=analysis_tools,pos={10,186}
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,205}
			Button addPresetAngle,win=analysis_tools,pos={140,205}
			Button deletePresetAngle,win=analysis_tools,pos={165,205}
			CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,231}
			CheckBox doDarkSubtract win=analysis_tools,pos={10,250}
			break
		default:
				//return controls to default positions
			PopUpMenu maskListPopUp win=analysis_tools,pos={10,85}
			CheckBox ch1Check,win=analysis_tools,pos={10,127}
			CheckBox ch2Check,win=analysis_tools,pos={50,127}
			CheckBox ratioCheck,win=analysis_tools,pos={90,127}
			SetVariable bslnStVar win=analysis_tools,pos={10,65}
			SetVariable bslnEndVar win=analysis_tools,pos={15,85}
			SetVariable peakStVar win=analysis_tools,pos={120,65}
			SetVariable peakEndVar win=analysis_tools,pos={125,85}
			CheckBox SmoothBox,win=analysis_tools,pos={10,107}
			SetVariable SmoothFilterVar,win=analysis_tools,pos={30,107}
			CheckBox useScanListCheck win=analysis_tools,pos={115,142},title="Use Scan List"
			SetVariable angleList,win=analysis_tools,pos={10,186}
			PopUpMenu presetAngleListPop,win=analysis_tools,pos={10,205}
			Button addPresetAngle,win=analysis_tools,pos={140,205}
			Button deletePresetAngle,win=analysis_tools,pos={165,205}
			CheckBox RemoveLaserResponseCheck win=analysis_tools,pos={10,231}
			CheckBox doDarkSubtract win=analysis_tools,pos={10,250}
			PopUpMenu extFuncDS win=analysis_tools,pos={21,90}
			ListBox extFuncDSListBox win=analysis_tools,pos={180,121}
			break
	endswitch

End