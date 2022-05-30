function ax=wbPhasePlot3D(pcastructCellArrayOrPCCellArrayOrPCs,options)    
%plot one or more phase plot trajectories     

%% Prelims


flagstr=[];
WBSTRUCT_MODE=true;
if nargin<1 || isempty(pcastructCellArrayOrPCCellArrayOrPCs)
    
    try
        pcaStruct{1}=wbLoadPCA;
    catch me
        beep;
        disp('there is no pcastruct in this folder.');
    end
    if isempty(pcaStruct{1})
        return;
    end
    pcs={pcaStruct{1}.pcs};
    coeffs={pcaStruct{1}.coeffs};
    traces={pcaStruct{1}.traces};
    
    neuronIDs={pcaStruct{1}.neuronIDs};
else
    
    if iscell(pcastructCellArrayOrPCCellArrayOrPCs)

        if isstruct(pcastructCellArrayOrPCCellArrayOrPCs{1}) %pcastructs in a cell array

            for i=1:length(pcastructCellArrayOrPCCellArrayOrPCs)
                pcs{i}=pcastructCellArrayOrPCCellArrayOrPCs{i}.pcs;
                coeffs{i}=pcastructCellArrayOrPCCellArrayOrPCs{i}.coeffs;
                traces{i}=pcastructCellArrayOrPCCellArrayOrPCs{i}.traces;
            end

        else  %raw pcs in a cell array
            pcs{1}=pcastructCellArrayOrPCCellArrayOrPCs;
        end

    elseif isstruct(pcastructCellArrayOrPCCellArrayOrPCs)
        pcs{1}=pcastructCellArrayOrPCCellArrayOrPCs.pcs;
    else %raw pcs
        pcs{1}=pcastructCellArrayOrPCCellArrayOrPCs;
        WBSTRUCT_MODE=false;
    end

end


if nargin<2
    options=[];
end

if ~isfield(options,'saveManifoldMesh')
    options.saveManifoldMesh=true;
end

if ~isfield(options,'monitorAngularDivergence')
    options.monitorAngularDivergence=false;
end

if ~isfield(options,'useHints')
    options.useHints=true;
end

if ~isfield(options,'wbstruct')
    options.wbstruct=[];
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF_bc';
end

if ~isfield(options,'interactiveMode')
   options.interactiveMode=true;
end


if ~isfield(options,'refNeuron')
    options.refNeuron='AVAL';    %default if no refNeuron in hints
    if options.useHints && exist(['.' filesep 'Quant' filesep 'wbhints.mat'],'file')
        hints=load(['.' filesep 'Quant' filesep 'wbhints.mat']);
        if isfield(hints,'stateRefNeuron') && ~isempty(hints.stateRefNeuron)
            options.refNeuron=hints.stateRefNeuron;
        disp(['using wbhints.mat file:  state reference neuron=' options.refNeuron]);
        end
    end
end



if ~isfield(options,'multiTrial')
   options.multiTrial=false;
end

if ~isfield(options,'multiTrialPCAOptions')
     options.multiTrialPCAOptions.neuronSubset='InCommon';
     options.multiTrialPCAOptions.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AVFL','AVFR','ALA','IL2L','IL2VR'};
     options.multiTrialPCAOptions.dimRedType='PCA';
     options.multiTrialPCAOptions.joint=false;
     options.multiTrialPCAOptions.crossNormalizeFlag=false;
     options.multiTrialPCAOptions.derivFlag=true;
end


%movie and pdf output options
if ~isfield(options,'outputDirectory')
   options.outputDirectory=pwd;
end

if ~isfield(options,'outputMovieQuality')
    options.outputMovieQuality=100;
end

if ~isfield(options,'frameRate')
    options.frameRate=200;
end


if ~isfield(options,'convertToImage')
    options.convertToImage=false;
end


if ~isfield(options,'savePDFCopyDirectory')
    options.savePDFCopyDirectory=[];
end

if ~isfield(options,'playSpeed')
    options.playSpeed=32;
end


if ~isfield(options,'plotBoxAspectRatio')
    options.plotBoxAspectRatio=[];
end

%PCA OPTIONS

if ~isfield(options,'plotClusters')
   options.plotClusters=false;
end

if ~isfield(options,'riseClusterRange')
   options.riseClusterRange=[.375 .875];
end

if ~isfield(options,'fallClusterRange')
   options.fallClusterRange=[.375 .875]; %.25 1
end


if ~isfield(options,'preSmoothFlag')
    options.preSmoothFlag=false;
end

if ~isfield(options,'preSmoothingWindow')
   options.preSmoothingWindow=10;
end

if ~isfield(options,'smoothFlag')  %post PCA compuations
   options.smoothFlag=true;
end

if ~isfield(options,'smoothingWindow')  %post PCA computation
   options.smoothingWindow=3;
end

if ~isfield(options,'PCADerivReg')
    options.PCADerivReg=true;
end

if ~isfield(options,'projectOntoFirstSpace')   %only used for multi-plots
   options.projectOntoFirstSpace=true;
end

if ~isfield(options,'postNormalizePCs')
    options.postNormalizePCs=false;
end

%PLOT OPTIONS


if ~isfield(options,'backgroundColor')
    options.backgroundColor='w';
end

if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end

if ~isfield(options,'plotTrajectory')
    options.plotTrajectory=true;
end

if ~isfield(options,'flowArrows')
    options.flowArrows=false;
end

if ~isfield(options,'flowArrowsStep')
    options.flowArrowsStep=10;
end

if ~isfield(options,'trajType')
    options.trajType='single';
end

if ~isfield(options,'multiTrajectoryRangeMode')
    options.multiTrajectoryRangeMode='rise-to-rise';
end

if ~isfield(options,'plotTrajPlane')
    options.plotTrajPlane=false;
end

if ~isfield(options,'plotMeanTrajectory')
    options.plotMeanTrajectory=false;
end

if ~isfield(options,'plotGhostTrajectory')
    options.plotGhostTrajectory=false;
end

if ~isfield(options,'ghostTrajectoryRange')  || isempty(options.ghostTrajectoryRange) || numel(options.ghostTrajectoryRange)==0
    options.ghostTrajectoryRange=[];
else
    tgr={options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end)};  
    options=rmfield(options,'ghostTrajectoryRange');
    options.ghostTrajectoryRange=tgr;
end

if ~isfield(options,'timeColoring')
    options.timeColoring=[];
end
  
if isempty(options.timeColoring) && options.interactiveMode
        wbstruct{1}=wbload([],false);
        options.timeColoring{1}=wbFourStateTraceAnalysis(wbstruct{1},'useSaved',options.refNeuron);
end

if ~iscell(options.timeColoring)
    options.timeColoring={options.timeColoring};
end

if ~isfield(options,'lineWidth')
   options.lineWidth=1.5;
end


if ~isfield(options,'clusterLineWidth')
   options.clusterLineWidth=4;
end


if ~isfield(options,'drawTransitionPlane')
   options.drawTransitionPlane=false;
end

if ~isfield(options,'showRiseTransitionNumbers')
    options.showRiseTransitionNumbers=false;
end

if ~isfield(options,'showFallTransitionNumbers')
    options.showFallTransitionNumbers=false;
end

clusterRiseColors=[  [255 1.4*93 1.4*181]/255   ;MyColor('dr')];
clusterFallColors=[255 108 0;255 204 0]/255;
slowColor=[0 0 0.9];  %light blue [7 165 217]/255;
          
if ~isfield(options,'clusterColors')
   options.clusterColors=clusterRiseColors;
end

if ~isfield(options,'clusterFallColors')
   options.clusterColors=clusterFallColors;
end


colorByOptions={'4-state','constant','rise cluster','fall cluster','stimulus','direction','wormspeed','6-state','7-state'};
if ~isfield(options,'colorBy')
   options.colorBy='4-state';
end


if ~isfield(options,'stateColoring')
   options.stateColoring=4;   %or 6
end

if ~isfield(options,'fourColorMap')
   options.fourColorMap=[[7 165 217]/255;0.9 0 0;[120 231 0]/255;[255 204 0]/255];
end

if ~isfield(options,'timeColoringColorMap')
   options.timeColoringColorMap=options.fourColorMap;
end

if ~isfield(options,'timeColoringOverlay')
    options.timeColoringOverlay=[];
end

if ~isfield(options,'timeColoringOverlayNeurons')
    options.timeColoringOverlayNeurons=[];
end

if ~isfield(options,'timeColoringOverlayNeuronStates')
    options.timeColoringOverlayNeuronStates=[];
end


if isempty(options.timeColoringOverlay) && isempty(options.timeColoringOverlayNeurons) && ~options.interactiveMode
    options.overlayBallsFlag=false;
else
    options.overlayBallsFlag=true;
end


if ~isfield(options,'timeColoringOverlayColor') 
     options.timeColoringOverlayColor=[];
end
 
if ~isfield(options,'timeColoringOverlayLegend') 
    options.timeColoringOverlayLegend={};
end

if ~isfield(options,'overlayBallSize')
    options.overlayBallSize=4;
end



if ~isfield(options,'overlayMarker')
    options.overlayMarker={'o','o','o','o','o','o'};
end

if ~isfield(options,'timeColoringShiftBalls')
    options.timeColoringShiftBalls=true;
end

if ~isfield(options,'drawTerminalBalls')
    options.drawTerminalBalls=false;
end

if  ~isfield(options,'endBallColor')
    options.endBallColor='r';
end

if ~isfield(options,'phasePlot3DMainColors')
    for i=1:length(pcs)
        options.phasePlot3DMainColors{i} = MyColor(i,length(pcs));
    end
end

if ~isfield(options,'phasePlot3DView')
    options.phasePlot3DView=[-15 16];
end

if ~isfield(options,'phasePlot2DView')
    options.phasePlot2DView=[];
end

if ~isfield(options,'phasePlot3DFlipZ')
    options.phasePlot3DFlipZ=false;
end

if ~isfield(options,'view3D')
    options.view3D=[];
end

if ~isfield(options,'phasePlot3DLimits')
    options.phasePlot3DLimits=[];
end

if ~isfield(options,'phasePlot3DDualMode')
    options.phasePlot3DDualMode=false;
end

if ~isfield(options,'plotTimeRange')  
    options.plotTimeRange=[];
else
    flagstr=[flagstr '-show[' num2str(options.plotTimeRange(1))  '-' num2str(options.plotTimeRange(end)) ']' ];
end

if ~isfield(options,'axisLabels');
    options.axisLabels={'PC1','PC2','PC3'};
end

if ~isfield(options,'saveViewButton')
    options.saveViewButton=false;  %this is deprecated.  use the PDF button in the GUI window.
end

if ~isfield(options,'endBallSize')
    options.endBallSize=4;
end


if options.phasePlot3DDualMode
    num3DPlots=2;
else
    num3DPlots=1;
end

if ~isfield(options,'numTubeEdges')
    options.numTubeEdges=24;
end

if ~isfield(options,'clusterMixMode')
    options.clusterMixMode=true;
end

%% GLOBALS 

handles=[];

pcaStructJoint=[];

normFac=[1 1 1]';

traces_rms=[];
traces_rms_avg=[];
coeffsRef=[];  %for multitrial
neuronIDsRef=[];  %for multitrial

trajDataX={};
trajDataY={};
trajDataZ={};
trajDataC={};

mTrajDataX={};
mTrajDataY={};
mTrajDataZ={};
mTrajDataC={};

mTrajRiseDataX={};
mTrajRiseDataY={};
mTrajRiseDataZ={};
mTrajRiseDataC={};

mTrajFallDataX={};
mTrajFallDataY={};
mTrajFallDataZ={};
mTrajFallDataC={};

mTrajT2TDataX={};
mTrajT2TDataY={};
mTrajT2TDataZ={};
mTrajT2TDataC={};

meanTrajRiseDataX={};
meanTrajRiseDataY={};
meanTrajRiseDataZ={};
meanTrajRiseDataC={};

meanTrajFallDataX={};
meanTrajFallDataY={};
meanTrajFallDataZ={};
meanTrajFallDataC={};

meanTrajX_RiseCluster={};
meanTrajY_RiseCluster={};
meanTrajZ_RiseCluster={};
meanTrajC_RiseCluster={};

meanTrajX_FallCluster={};
meanTrajY_FallCluster={};
meanTrajZ_FallCluster={};
meanTrajC_FallCluster={};

videoOutObj=[];
   
trajTypes={'single','multi','timestretch','timewarp'};

PCAPreNormalizationTypes={'none','peak','peakDeriv','rms','rmsDeriv','maxsnr','maxsnrDeriv'};

neuronSubsetType=options.multiTrialPCAOptions.neuronSubset;

tv={};
traceColoring=[];

timeColoring=options.timeColoring;

%for overlay balls
activeFullRangeIndices={};

transitionListCellArray=[];
transitionPreRunLengthArray=[];
transitions=[];
transitionsRise=[];
transitionsFall=[];
TWFrames={};
TWRiseFrames={};
TWFallFrames={};
TWT2TFrames={};
transitionsMat=[];
transitionsRiseMat=[];
transitionsFallMat=[];
transitionsT2TMat=[];
maxRange=[];

startingTime=[];
endTime=[];
frame{1}=1;
frameEnd{1}=1;
FTFrame=[];
FTFrameEnd=[];
frameEnd_frac{1}=0;
numFrames=[];

thisPlotTimeRange{1}=[];
colorByDirectionFlag=false;

if ~exist('fullPlotTimeRange','var') 
    fullPlotTimeRange{1}=[]; 
end

multiTrialIsActive=logical(options.multiTrial);  

canonicalTimesReg=[0 .25 0.5 0.75 1.0]; 
canonicalTimesT2T=[0 0.125 0.375 0.625 0.875 1.0]; 
   
canonicalTimes=canonicalTimesReg;

%load wbstruct data and set folder names
activeDatasetFolders={pwd};
datasetsLoadedLogical=false(1,length(activeDatasetFolders));
datasetDiskOrder=1;

datasetFolderNames=listfolders([],false,true);
datasetFolderNamesFullPath=listfolders([],true,true);

slashes=strfind(pwd,filesep);
currentFolderFullPath=pwd;
currentFolder=currentFolderFullPath(1+slashes(end):end);

secondDataFolder=[];
secondDataFolderFullPath=[];

ellipsePts3D={};
CH2Dindices=[];

clusterRiseStruct={[]};
clusterFallStruct={[]};

clusterRiseColoring=[];  %should collect cluster data into a struct
clusterFallColoring=[];
clusterTiming=2;

yLim=[];
endBallSizes=[1 4 8 14 20 36];
overlayBallSizes=[1 4 6 8];

overlayNeuronState=[2 2 2 2 2 2];

trajVisibilityLogical=true(1,9);

currentRiseNumbersVisibility=options.showRiseTransitionNumbers;
currentFallNumbersVisibility=options.showFallTransitionNumbers;

%GUI state defaults
showTrajectoryCheckboxStartingState=options.plotTrajectory;
showMeanTrajectoryCheckboxStartingState=options.plotMeanTrajectory;
showRiseClusterTrajCheckboxStartingState=options.plotClusters;
showFallClusterTrajCheckboxStartingState=options.plotClusters;
showMergedClusterTrajCheckboxStartingState=false;
fallClusterRangeOverrideStartingState=0;
showTrajPlaneCheckboxStartingState=0;
cropTrajPlaneCheckboxStartingState=0;
showConvHullCheckboxStartingState=0;
splitConvHullCheckboxStartingState=1;
showTubesCheckboxStartingState=1;


showStartBallsState=options.drawTerminalBalls;
showEndBallsState=options.drawTerminalBalls;

%showEndBallsCheckboxStartingState

clusterTime1StartingTime=5;
clusterTime2StartingTime=5;

transitionColoringWindowStart=clusterTime1StartingTime;
transitionColoringWindowEnd=clusterTime2StartingTime;   

convHullIsActive=logical(showConvHullCheckboxStartingState);
trajectoryIsActive=logical(showTrajectoryCheckboxStartingState);
meanTrajIsActive=logical(showMeanTrajectoryCheckboxStartingState);
trajPlaneIsActive=logical(showTrajPlaneCheckboxStartingState);
cropPlaneIsActive=logical(cropTrajPlaneCheckboxStartingState);
convHullIsSplit=logical(splitConvHullCheckboxStartingState);
tubesIsActive=logical(showTubesCheckboxStartingState);

riseClusterTrajIsActive=logical(showRiseClusterTrajCheckboxStartingState);
fallClusterTrajIsActive=logical(showFallClusterTrajCheckboxStartingState);
mergedClusterTrajIsActive=logical(showMergedClusterTrajCheckboxStartingState);


fallClusterRangeOverrideIsActive=logical(fallClusterRangeOverrideStartingState);

timeColoringColorMap=options.timeColoringColorMap;
currentColor=options.phasePlot3DMainColors{1};

%% Load dataset
    
if WBSTRUCT_MODE
    LoadDatasets(); 

else  %raw traces, fill in needed data.
    fullPlotTimeRange{1}=[1 size(pcs{1},1)];
    
    tv{1}=fullPlotTimeRange{1}(1):fullPlotTimeRange{1}(end);

end

%% Interactive mode stuff   
    
if options.interactiveMode
        
    %GLOBALS
    slider1Val=1;
    slider2Val=thisPlotTimeRange{1}(end);   
    slider3Val=1;
    slider4Val=thisPlotTimeRange{1}(end);
    
    %draw secondary window stuff
    
    neuronList=['---', sort(wbListIDs)];    
    
    neuronListNum(1)=find(strcmpi(neuronList,options.refNeuron));
    neuronListNum(2:6)=2:6;
    for tco=1:6
       options.timeColoringOverlay{1}(:,tco)=(wbFourStateTraceAnalysis(wbstruct{1},'useSaved',neuronList{neuronListNum(tco)})==2);
    end
          
    playButtonLabels={'PLAY','PAUSE'};
    recordButtonLabels={'RECORD','RECORDING...'};
    genTubesButtonLabels={'GEN TUBES','GENERATING...'};
    missingCoeffOptionList={'zero out','copy','impute'};
    PCARestrictRangeOptionList={'all','rise','high','fall','low','rise1','rise2','fall1','fall2'};
    neuronSubsetTypeList={'all','labeled only','in common'};
    multiTrajectoryRangeModes={'rise-to-rise','fall-to-fall','trough-to-trough'};
    
    handles.f2=figure('Position',[800 0 800 800],'Name','wbPhasePlot3D Control Panel','KeyPressFcn',@(s,e) KeyPressedFcn);
    handles.tracePlotAxis=axes('Position',[.05 .68 .90 .2], 'ButtonDownFcn',@mouseDownCallback);
    
    handles.playButton=uicontrol('Style','togglebutton','Units','normalized','String',playButtonLabels{1},'Position',[.01 .965 .10 .03],'Callback',@(s,e) PlayButtonCallback);
    handles.recordButton=uicontrol('Style','togglebutton','Units','normalized','String',recordButtonLabels{1},'Position',[.01 .935 .10 .03],'Callback',@(s,e) RecordButtonCallback);
    handles.snapshotButton=uicontrol('Style','pushbutton','Units','normalized','String','PDF','Position',[.115 .935 .08 .03],'Callback',@(s,e) SavePDFButtonCallback);
   
    handles.playSpeedPopup=uicontrol('Style','popup','Units','normalized','String',{'1x','2x','4x','8x','16x','32x','64x','128x'},'Value',1+round(log2(options.playSpeed)),'Position',[.115 .960 .08 .03],'Callback',@(s,e) PlaySpeedPopupCallback);
    
    handles.trajectoriesPopupLabel=uicontrol('Style','text','Units','normalized','String','trajectories','Position',[.21 .97 .10 .02]);
    handles.trajectoriesPopup=uicontrol('Style','popup','Units','normalized','Position',[.2 .945 .14 .02],'String',trajTypes,'Value',find(strcmpi(trajTypes,options.trajType)),'Callback',@(s,e) TrajectoryTypeCallback);
  
    handles.rangeTypePopupLabel=uicontrol('Style','text','Units','normalized','String','range','Position',[.37 .97 .10 .02]);
    handles.rangeTypePopup=uicontrol('Style','popup','Units','normalized','Position',[.35 .945 .15 .02],'String',multiTrajectoryRangeModes,'Value',find(strcmpi(multiTrajectoryRangeModes,options.multiTrajectoryRangeMode)),'Callback',@(s,e) RangeTypesCallback);
    if strcmp(options.trajType,'single')
        set(handles.rangeTypePopup,'Enable','off');
    else
        set(handles.rangeTypePopup,'Enable','on');
    end
        
    handles.datasetPopup=uicontrol('Style','popup','Units','normalized','Position',[.55 .98 .25 .02],'String',datasetFolderNames,'Value',find(strcmpi(datasetFolderNames,currentFolder)),'Callback',@(s,e) DatasetPopupCallback);
    
    handles.refNeuronPopupLabel=uicontrol('Style','text','Units','normalized','String','refNeuron','Position',[.82 .98 .08 .02]);
    handles.refNeuronPopup=uicontrol('Style','popup','Units','normalized','Position',[.9 .98 .1 .02],'String',neuronList,'Value',find(strcmpi(neuronList,options.refNeuron)),'Callback',@(s,e) RefNeuronCallback,'ForegroundColor','k');
  
    
    handles.neuronPopup(1)=uicontrol('Style','popup','Units','normalized','Position',[.63 .945 .11 .02],'String',neuronList,'Value',neuronListNum(1),'Callback',@(s,e) NeuronCallback(1),'ForegroundColor','r');
    handles.neuronPopup(2)=uicontrol('Style','popup','Units','normalized','Position',[.76 .945 .11 .02],'String',neuronList,'Value',neuronListNum(2),'Callback',@(s,e) NeuronCallback(2),'ForegroundColor','g');
    handles.neuronPopup(3)=uicontrol('Style','popup','Units','normalized','Position',[.89 .945 .11 .02],'String',neuronList,'Value',neuronListNum(3),'Callback',@(s,e) NeuronCallback(3),'ForegroundColor','b');

    tab=.02;
    handles.neuronCheckbox(1)=uicontrol('Style','checkbox','Units','normalized','Position',[.63-tab .95 .03 .02],'Value',0,'Callback',@(s,e) NeuronCheckboxCallback(1),'ForegroundColor','r');
    handles.neuronCheckbox(2)=uicontrol('Style','checkbox','Units','normalized','Position',[.76-tab .95 .03 .02],'Value',0,'Callback',@(s,e) NeuronCheckboxCallback(2),'ForegroundColor','g');
    handles.neuronCheckbox(3)=uicontrol('Style','checkbox','Units','normalized','Position',[.89-tab .95 .03 .02],'Value',0,'Callback',@(s,e) NeuronCheckboxCallback(3),'ForegroundColor','b');

    handles.neuronStateDropdown(1)=uicontrol('Style','popup','Units','normalized','Position',[.63-tab .93 .03 .02],'String',{'LO','RISE','HI','FALL'},'Value',overlayNeuronState(1),'Callback',@(s,e) NeuronStateCallback(1),'ForegroundColor','r');
    handles.neuronStateDropdown(2)=uicontrol('Style','popup','Units','normalized','Position',[.76-tab .93 .03 .02],'String',{'LO','RISE','HI','FALL'},'Value',overlayNeuronState(2),'Callback',@(s,e) NeuronStateCallback(2),'ForegroundColor','g');
    handles.neuronStateDropdown(3)=uicontrol('Style','popup','Units','normalized','Position',[.89-tab .93 .03 .02],'String',{'LO','RISE','HI','FALL'},'Value',overlayNeuronState(3),'Callback',@(s,e) NeuronStateCallback(3),'ForegroundColor','b');

    handles.neuronPopup(4)=uicontrol('Style','popup','Units','normalized','Position',[.33 .32 .11 .02],'String',neuronList,'Value',neuronListNum(4),'Callback',@(s,e) NeuronCallback(4),'ForegroundColor','c');
    handles.neuronPopup(5)=uicontrol('Style','popup','Units','normalized','Position',[.46 .32 .11 .02],'String',neuronList,'Value',neuronListNum(5),'Callback',@(s,e) NeuronCallback(5),'ForegroundColor','m');
    handles.neuronPopup(6)=uicontrol('Style','popup','Units','normalized','Position',[.59 .32 .11 .02],'String',neuronList,'Value',neuronListNum(6),'Callback',@(s,e) NeuronCallback(6),'ForegroundColor','y');
              
    handles.neuronCheckbox(4)=uicontrol('Style','checkbox','Units','normalized','Position',[.33-tab .32 .03 .02],'Value',0,'Callback',@(s,e) NeuronCheckboxCallback(4),'ForegroundColor','c');
    handles.neuronCheckbox(5)=uicontrol('Style','checkbox','Units','normalized','Position',[.46-tab .32 .03 .02],'Value',0,'Callback',@(s,e) NeuronCheckboxCallback(5),'ForegroundColor','m');
    handles.neuronCheckbox(6)=uicontrol('Style','checkbox','Units','normalized','Position',[.59-tab .32 .03 .02],'Value',0,'Callback',@(s,e) NeuronCheckboxCallback(6),'ForegroundColor','y');
    
    handles.neuronStateDropdown(4)=uicontrol('Style','popup','Units','normalized','Position',[.33-tab .30 .03 .02],'String',{'LO','RISE','HI','FALL'},'Value',overlayNeuronState(4),'Callback',@(s,e) NeuronStateCallback(4),'ForegroundColor','c');
    handles.neuronStateDropdown(5)=uicontrol('Style','popup','Units','normalized','Position',[.46-tab .30 .03 .02],'String',{'LO','RISE','HI','FALL'},'Value',overlayNeuronState(5),'Callback',@(s,e) NeuronStateCallback(5),'ForegroundColor','m');
    handles.neuronStateDropdown(6)=uicontrol('Style','popup','Units','normalized','Position',[.59-tab .30 .03 .02],'String',{'LO','RISE','HI','FALL'},'Value',overlayNeuronState(6),'Callback',@(s,e) NeuronStateCallback(6),'ForegroundColor','y');
    
    %%SLIDERS
    
    handles.timeSlider1 = uicontrol('Style','slider','Units','normalized',...
            'Position',[.02 .90 .96 .03],'Min',1,'Max',thisPlotTimeRange{1}(end),...
            'SliderStep',[1/(thisPlotTimeRange{1}(end)-1) 10/(thisPlotTimeRange{1}(end)-1)],...
            'Value',slider1Val,'Visible','on'); %,'Callback',@(s,e) disp('mouseup')

    
    handles.timeSlider2 = uicontrol('Style','slider','Units','normalized',...
            'Position',[.02 .63 .96 .03],'Min',1,'Max',thisPlotTimeRange{1}(end),...
            'SliderStep',[1/(thisPlotTimeRange{1}(end)-1) 10/(thisPlotTimeRange{1}(end)-1)],...
            'Value',slider2Val,'Visible','on'); %,'Callback',@(s,e) disp('mouseup')

    hListener1 = addlistener(handles.timeSlider1,'Value','PostSet',@(s,e) timeSliderCallback) ;
    hListener2 = addlistener(handles.timeSlider2,'Value','PostSet',@(s,e) timeSlider2Callback) ;
    
    %BOTTOM SLIDERS fOR FALL CLUSTER RANGE CONTROL
    
    handles.fallSliderText=uicontrol('Style','text','Units','normalized','String','fall cluster time range','Position',[.4 .05 .2 .03],'Visible','off');
    handles.timeSlider3 = uicontrol('Style','slider','Units','normalized',...
            'Position',[.02 .03 .96 .03],'Min',1,'Max',thisPlotTimeRange{1}(end),...
            'SliderStep',[1/(thisPlotTimeRange{1}(end)-1) 10/(thisPlotTimeRange{1}(end)-1)],...
            'Value',slider3Val,'Visible','off'); %,'Callback',@(s,e) disp('mouseup')

    
    handles.timeSlider4 = uicontrol('Style','slider','Units','normalized',...
            'Position',[.02 .01 .96 .03],'Min',1,'Max',thisPlotTimeRange{1}(end),...
            'SliderStep',[1/(thisPlotTimeRange{1}(end)-1) 10/(thisPlotTimeRange{1}(end)-1)],...
            'Value',slider4Val,'Visible','off'); %,'Callback',@(s,e) disp('mouseup')
    
    
    
    hListener3 = addlistener(handles.timeSlider3,'Value','PostSet',@(s,e) timeSlider3Callback) ;
    hListener4 = addlistener(handles.timeSlider4,'Value','PostSet',@(s,e) timeSlider4Callback) ;

    
    handles.showTrajectoryCheckbox=uicontrol('Style','checkbox','String','trajectory','Units','normalized','Position',[.05 .61 .11 .02],'Value',showTrajectoryCheckboxStartingState,'Callback',@(s,e) ShowTrajectoryCheckboxCallback);
    handles.showMeanTrajectoryCheckbox=uicontrol('Style','checkbox','String','mean trajectory','Units','normalized','Position',[.05 .59 .11 .02],'Value',showMeanTrajectoryCheckboxStartingState,'Callback',@(s,e) ShowMeanTrajectoryCheckboxCallback);
 
    handles.showMergedClusterTrajCheckbox=uicontrol('Style','checkbox','String','merged clus. traj.','Units','normalized','Position',[.37 .61 .13 .02],'Value',showMergedClusterTrajCheckboxStartingState,'Callback',@(s,e) ShowMergedClusterTrajCheckboxCallback);
    handles.showRiseClusterTrajCheckbox=uicontrol('Style','checkbox','String','rise cluster traj.','Units','normalized','Position',[.50 .61 .13 .02],'Value',showRiseClusterTrajCheckboxStartingState,'Callback',@(s,e) ShowRiseClusterTrajCheckboxCallback);
    handles.showFallClusterTrajCheckbox=uicontrol('Style','checkbox','String','fall cluster traj.','Units','normalized','Position',[.63 .61 .13 .02],'Value',showFallClusterTrajCheckboxStartingState,'Callback',@(s,e) ShowFallClusterTrajCheckboxCallback);
    handles.fallClusterRangeOverrideCheckbox=uicontrol('Style','checkbox','String','range override','Units','normalized','Position',[.63 .58 .13 .02],'Value',fallClusterRangeOverrideStartingState,'Callback',@(s,e) FallClusterRangeOverrideCheckboxCallback);

    handles.ghostTrajectoryCheckbox=uicontrol('Style','checkbox','String','ghost traj.','Units','normalized','Position',[.63 .55 .13 .02],'Value',options.plotGhostTrajectory,'Callback',@(s,e) ShowGhostTrajectoryCheckboxCallback);

    bigtab=0.12;
    handles.colorByPopup=uicontrol('Style','popup','Units','normalized','Position',[.08+bigtab .61 .11 .02],'String',colorByOptions,'Value',1,'Callback',@(s,e) ColorByPopupCallback);   
    handles.colorByLabel=uicontrol('Style','text','Units','normalized','Position',[.03+bigtab .61 .05 .02],'String','color by');
    handles.trajColorPicker=uicontrol('Style','pushbutton','Units','normalized','Position',[.19+bigtab .605 .04 .025],'BackgroundColor',options.timeColoringColorMap(1,:),'Visible','off','Callback',@(s,e) TrajColorPickerCallback);

    handles.clusterTimeLabel1=uicontrol('Style','text','Units','normalized','Position',[.21+bigtab .605 .14 .025],'String','from -     to +','Visible','off','HorizontalAlignment','left');
    handles.clusterTimeEditbox1=uicontrol('Style','edit','Units','normalized','Position',[.25+bigtab .605 .04 .025],'String',num2str(clusterTime1StartingTime),'Visible','off','Callback',@(s,e) ClusterColorTimeCallback);
    handles.clusterTimeEditbox2=uicontrol('Style','edit','Units','normalized','Position',[.312+bigtab .605 .04 .025],'String',num2str(clusterTime2StartingTime),'Visible','off','Callback',@(s,e) ClusterColorTimeCallback);

    
    handles.drawPlaneCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.05 .57 .11 .02],'String','traj. plane','Value',showTrajPlaneCheckboxStartingState,'Callback',@(s,e) ShowPlaneCheckboxCallback);

    handles.cropPlaneCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.16 .57 .13 .02],'String','crop plane to hull','Value',cropTrajPlaneCheckboxStartingState,'Callback',@(s,e) CropPlaneCheckboxCallback);

    handles.clusterTubesCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.3 .58 .11 .02],'String','show tubes','Value',showTubesCheckboxStartingState,'Callback',@(s,e) ShowTubesCheckboxCallback);

    handles.genTubesButton=uicontrol('Style','togglebutton','Units','normalized','String',genTubesButtonLabels{1},'Position',[.42 .575 .12 .03],'Callback',@(s,e) GenTubesButtonCallback);

    handles.showConvHullCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.05 .55 .11 .02],'String','convex hull','Value',showConvHullCheckboxStartingState,'Callback',@(s,e) ShowConvHullCheckboxCallback);

    
    handles.voxelizeButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.25 .50 .11 .03],'String','Voxelize','Callback',@(s,e) VoxelizeButtonCallback);

    handles.splitConvHullCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.16 .55 .11 .02],'String','split hull','Value',splitConvHullCheckboxStartingState,'Callback',@(s,e) SplitConvHullCheckboxCallback);


    handles.clusterTimingLabel=uicontrol('Style','text','Units','normalized','Position',[.27 .55 .08 .02],'String','causality');
    handles.clusterTimingPopup=uicontrol('Style','popup','Units','normalized','Position',[.34 .55 .14 .02],'String',{'predictive','postdictive','pre/post'},'Value',2,'Callback',@(s,e) ClusterTimingPopupCallback);
 
    handles.loadClustering=uicontrol('Style','pushbutton','Units','normalized','Position',[.75 .60 .14 .035],'String','Load Clustering','Callback',@(s,e) LoadClusteringButtonCallback);
    handles.runClusteringRise=uicontrol('Style','pushbutton','Units','normalized','Position',[.75 .56 .14 .035],'String','Rise Clustering Panel','Callback',@(s,e) OpenClusteringRisePanel);
    handles.runClusteringFall=uicontrol('Style','pushbutton','Units','normalized','Position',[.75 .52 .14 .035],'String','Fall Clustering Panel','Callback',@(s,e) OpenClusteringFallPanel);
 
    handles.trajPlane2DFixLimitsCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[0.04,0.52,.2,.02],'String','fix limits','Value',1,'Visible','on','Callback',@(s,e) trajPlane2DFixLimitsCallback);

    handles.saveTrajDataButton=uicontrol('Style','pushbutton','Units','normalized','Position',[.63 .51 .11 .032],'String','Save Traj Data','Callback',@(s,e) SaveTrajDataButtonCallback);

    
    MakeGUIPCA;
  
    PlotGUITraces;

    DrawRanges;
    
    
    sT=round(get(handles.timeSlider1,'Value'));
    eT=round(get(handles.timeSlider2,'Value'));
    
    sTR=sT;
    eTR=eT;

    sTF=round(get(handles.timeSlider3,'Value'));
    eTF=round(get(handles.timeSlider4,'Value'));
    
else  %not interactive mode
    
    
    sT=1;
    eT=length(tv{1});
    
    sTR=1+round(options.riseClusterRange(1)*length(tv{1}));
    eTR=floor(options.riseClusterRange(2)*length(tv{1}));
        
    sTF=1+round(options.fallClusterRange(1)*length(tv{1}));
    eTF=floor(options.fallClusterRange(2)*length(tv{1}));
       
end

%% Final figure setup


Draw3DPlot;
%Draw3DPlotSecondary;

ax=gca;

%return;


for plot3D_num=1:num3DPlots
     rotationListener(plot3D_num) = addlistener(handles.plot3D(plot3D_num),'CameraPosition','PostSet',@(s,e) set3DViewsCallback(plot3D_num)) ;
end

if WBSTRUCT_MODE
    
    %if options.plotMeanTrajectory || options.plotClusters
        ComputeTrajectories;
    %end

    if options.plotClusters
        LoadClustering;
    end


    if options.plotMeanTrajectory
        DrawMeanTrajectories;
    end
    
    if options.plotClusters
        DrawClusterTrajectory(1);
        DrawClusterTrajectory(2);
    end

    UpdateRangeMode(options.multiTrajectoryRangeMode);  %set multi-traj range mode
    %UpdateMultiTrajectory
   
end

if multiTrialIsActive
    UpdateMultiTrial;
    disp('wbPhasePlot3d> multitrial.')
end



Update3DPlot;


if ~isempty(options.plotBoxAspectRatio)
    set(gca,'PlotBoxAspectRatio',options.plotBoxAspectRatio);
end

view(handles.plot3D(plot3D_num),options.phasePlot3DView);


if ~isempty(options.view3D)
          set(gca,'CameraPosition',options.view3D.CameraPosition );
          set(gca,'CameraTarget',options.view3D.CameraTarget );
          set(gca,'CameraUpVector',options.view3D.CameraUpVector );
          set(gca,'CameraViewAngle',options.view3D.CameraViewAngle );
end

if options.convertToImage

    drawnow;
    ConvertToImage;
    box off;
   
end
    


%%END MAIN

%% Subfuncs & Callbacks

    function KeyPressedFcn
        
        keyStroke=get(gcbo, 'CurrentKey');
        get(gcbo, 'CurrentCharacter');
        get(gcbo, 'CurrentModifier');
   
     
        if strcmp(keyStroke,'a')
             
            trajVisibilityLogical=~trajVisibilityLogical;            

            for d=1:length(activeDatasetFolders);
                UpdateVisibility(['plotLine' num2str(d)],trajVisibilityLogical(d));
                UpdateVisibility(['trajName' num2str(d)],trajVisibilityLogical(d));
                for b=1:6
                    if get(handles.neuronCheckbox(b),'Value')
                        UpdateVisibility(['timeColoringOverlay'],trajVisibilityLogical(d),d,b);
                    end
                end

            end
            
        elseif sum(strcmp(keyStroke,{'1','2','3','4','5','6','7','8','9'}))
            
            
            thisKeyNum=str2num(keyStroke);
            
            if thisKeyNum<=numel(activeDatasetFolders)
                trajVisibilityLogical(thisKeyNum)=~trajVisibilityLogical(thisKeyNum);            
                UpdateVisibility(['plotLine' keyStroke],trajVisibilityLogical(thisKeyNum));
                UpdateVisibility(['trajName' keyStroke],trajVisibilityLogical(thisKeyNum));
                for b=1:6
                    if get(handles.neuronCheckbox(b),'Value')
                        UpdateVisibility(['timeColoringOverlay'],trajVisibilityLogical(thisKeyNum),thisKeyNum,b);
                    end
                end
            end
            
        elseif strcmp(keyStroke,'z')
            
            view([0 0 90]);
            
        elseif strcmp(keyStroke,'x')
            
            view([0 90 0]);
            
        elseif strcmp(keyStroke,'c')
            
            view([90 0 0]);
            
        elseif strcmp(keyStroke,'v')
            
            view(options.phasePlot3DView);
            
        elseif strcmp(keyStroke,'period')
            
            currentLineWidth=get(handles.plotLine1(1),'LineWidth');
            newLineWidth=currentLineWidth+1;
            
            for d=1:length(activeDatasetFolders)
               set(handles.(['plotLine' num2str(d)]),'lineWidth',newLineWidth);         
            end 
            
        elseif strcmp(keyStroke,'comma')
            
            currentLineWidth=get(handles.plotLine1(1),'LineWidth');
            newLineWidth=max([1 currentLineWidth-1]);
            
           for d=1:length(activeDatasetFolders)
               set(handles.(['plotLine' num2str(d)]),'lineWidth',newLineWidth);         
            end 
                        
        end
        
        
    end

    function RefNeuronCallback
        
        theseOptions.refNeuron=neuronList{get(gcbo,'Value')};
        theseOptions.interactiveMode=true;
        
        wbPhasePlot3D([],theseOptions);
        
        close(handles.fig3D);
        close(handles.f2);
        
        
    end

    function UpdateVisibility(handleStr,visibility,d,b)
 disp('uv')       
        %d is a cell index not an array
        
        if nargin<2
            visibility=true;
        end
        
        if nargin<3

            if isfield(handles,handleStr)
                if visibility
                    for j=1:length(handles.(handleStr))
                        
%                        if handles.(handleStr)(j)>0
                            set(handles.(handleStr)(j),'Visible','on');
%                       end
                    end
                    
                else
                    
                    for j=1:length(handles.(handleStr))
                        
%                        if handles.(handleStr)(j)>0
                            set(handles.(handleStr)(j),'Visible','off');
%                        end
                    end
                end
            end
        
        else
            
            if nargin<4
                b=1:length(handles.(handleStr){d});
            end
            
            if isfield(handles,handleStr)
                if visibility
                    for j=b
%                        if handles.(handleStr){d}(j)>0
                            set(handles.(handleStr){d}(j),'Visible','on');
%                        end
                    end
                else
                    for j=b
                        
%                        if handles.(handleStr){d}(j)>0
                            set(handles.(handleStr){d}(j),'Visible','off');
%                        end
                    end
                end
            end
            
        end

    end

    function LoadDatasets(dataFolder)
 
        %load PCA data
        
        for i=1:length(activeDatasetFolders)
            
            if ~datasetsLoadedLogical(i)                
                
                pcaStruct{i}=wbLoadPCA(activeDatasetFolders{i},false);

                pcs{i}=pcaStruct{i}.pcs;
                coeffs{i}=pcaStruct{i}.coeffs;
                traces{i}=pcaStruct{i}.traces;
                neuronIDs{i}=pcaStruct{i}.neuronIDs;


                %load wbstruct data

                if i==1 && ~isempty(options.wbstruct)
                    wbstruct{i}=options.wbstruct;
                else
                    wbstruct{i}=wbload(activeDatasetFolders{i},false);
                end
                      
                tv{i}=wbstruct{i}.tv;

                fullPlotTimeRange{i}=[1 length(tv{i})];
                
                if isempty(options.plotTimeRange)
                    thisPlotTimeRange{i}=fullPlotTimeRange{i};
                else
                    thisPlotTimeRange{i}=options.plotTimeRange;
                end
                
                numFrames(i)=length(tv{i});
                
              
                if options.stateColoring>0
                    timeColoring{i}=wbFourStateTraceAnalysis(wbstruct{i},'useSaved',options.refNeuron);
                end
      
                
                frame{i}=1;
                frameEnd{i}=numFrames(i);
                frameEnd_frac{i}=0;
                
                %load transition data
                [traceColoring{i}, transitionListCellArray{i},transitionPreRunLengthArray{i}]=wbFourStateTraceAnalysis(wbstruct{i},'useSaved',options.refNeuron);
                [F2FMat{i},R2RMat{i},MT2MTMat{i}]=wbGetTransitionRanges(transitionListCellArray{i});
                transitionsRise{i}=(wbGetTransitions(transitionListCellArray{i},1,'SignedAllRises',[],transitionPreRunLengthArray{i}))';
                transitionsFall{i}=(wbGetTransitions(transitionListCellArray{i},1,'SignedAllFalls',[],transitionPreRunLengthArray{i}))';
                transitionsRiseMat{i}=F2FMat{i};
                transitionsFallMat{i}=R2RMat{i};
                transitionsT2TMat{i}=MT2MTMat{i};

                                              
                datasetsLoadedLogical(i)=true;        
                
                activeFullRangeIndices{i}=true(size(tv{i}));

                
                disp(['wbPhasePlot3D> loaded dataset#' num2str(i)]);

            end
            
            %if rise clusters, fall-to-fall
            transitionsMat=transitionsRiseMat;
            
            [trajDataX{i},trajDataY{i},trajDataZ{i}]=GetTrajectoriesFromPCs(i);     
    
            normFac(:,i)=[1 1 1]';
     
        end
        
        
        ComputeTrajectories;
        UpdateRangeMode(options.multiTrajectoryRangeMode); 
        
        if numel(activeDatasetFolders)==1
            coeffsRef=coeffs{1};
            neuronIDsRef=neuronIDs{1};
        end
        
        
        if options.stateColoring==6
           if isempty(clusterRiseColoring)  || isempty(clusterFallColoring)     
                LoadClustering;
           end

           timeColoring{i}=ComputeFullStateColoring(i,6);
           timeColoringColorMap=[options.fourColorMap;clusterRiseColors(1,:);clusterRiseColors(2,:);clusterFallColors(1,:);clusterFallColors(2,:)];
           colormap(gca,timeColoringColorMap);  
           
        elseif options.stateColoring==7
            
           if isempty(clusterRiseColoring)  || isempty(clusterFallColoring)     
                LoadClustering;
           end

           timeColoring{i}=ComputeFullStateColoring(i,7);
           timeColoringColorMap=[options.fourColorMap;clusterRiseColors(1,:);clusterRiseColors(2,:);clusterFallColors(1,:);clusterFallColors(2,:);slowColor];
           colormap(gca,timeColoringColorMap);
           
        end
        
    end

    function DatasetPopupCallback
        
        datasetsLoadedLogical(:)=false;
        
        currentFolder=datasetFolderNames{get(gcbo,'Value')};
        currentFolderFullPath=datasetFolderNamesFullPath{get(gcbo,'Value')};
        activeDatasetFolders={currentFolderFullPath};
    
        cd(currentFolderFullPath); 

        wbPhasePlot3D;
        
        close(handles.f2);
        close(handles.fig3D);

    end

    function Draw3DPlot
        
        if options.interactiveMode
            UpdateTimeBounds;
        end
        
        for plot3D_num=1:num3DPlots            

            if ~options.subPlotFlag
                if ~isfield(handles,'fig3D')
                    handles.fig3D=figure('Position',[0 0 800 800],'Name','wbPhasePlot3D 3D Plot','Renderer','opengl','KeyPressFcn',@(s,e) KeyPressedFcn);
                    whitebg(handles.fig3D,options.backgroundColor);

                else
                    figure(handles.fig3D);
                    clf;
                end
            else
                handles.fig3D=gcf;
            end
                     
            grid on;
            hold on;
        
             
%             if options.interactiveMode
%                 handles=KillHandle('plot3D',handles);
%             end
            
            handles.plot3D(plot3D_num)=gca;
            set(gca,'Color',options.backgroundColor);
            set(gcf,'Color',options.backgroundColor);
            lineStyle='-';
            currentColorMap=[];
            
            if isempty(options.phasePlot2DView)
                view(handles.plot3D(plot3D_num),options.phasePlot3DView);               
            end

            for d=1:length(pcs)  %number of datasets

                if isempty(options.plotTimeRange)
                    thisPlotTimeRange{d}=[1 size(pcs{d},1)];

                else

                    thisPlotTimeRange{d}=[options.plotTimeRange(1) options.plotTimeRange(end)] ;
                end
                
                if options.interactiveMode

                     UpdateRanges
                     for k=1:length(frame{d})
                         thisPlotTimeRange{d}(k,:)=[frame{d}(k) frameEnd{d}(k)];
                     end
                end
                
 
                [trajDataX{d},trajDataY{d},trajDataZ{d}]=GetTrajectoriesFromPCs(d);
                
                if ~isempty(timeColoring{d})
                    trajDataC{d}=timeColoring{d};
                else
                    trajDataC{d}=0.5*ones(size(trajDataX{d}));
                end

                DrawGhostTrajectory(trajDataX{d},trajDataY{d},trajDataZ{d},d,options.phasePlot2DView);            
           
            

                %set up convex hull
                if options.interactiveMode         
%                     CH = convhull(thisDataX(round(frameEnd)),thisDataY(round(frameEnd)),thisDataZ(round(frameEnd)));
%                     handles.convexHull3D=trisurf(CH,thisDataX(round(frameEnd)),thisDataY(round(frameEnd)),thisDataZ(round(frameEnd)), 'Facecolor','cyan','FaceAlpha',0.3,'Visible','on');                  
                      handles.convexHull3D=trisurf([1 2 3],0,0,0,'Facecolor','cyan','FaceAlpha',0.3,'Visible','off');
                end

                hold on;
                
                if options.postNormalizePCs
                    normFac(1,d)=std(trajDataX{d},1)/std(trajDataX{1},1);
                    normFac(2,d)=std(trajDataY{d},1)/std(trajDataY{1},1);
                    normFac(3,d)=std(trajDataZ{d},1)/std(trajDataZ{1},1);
                else
                    normFac(:,d)=[1 1 1]';
                end
                    
                %Plot trajectory
                
                if strcmp(options.trajType,'single')
                    kEnd=1;
                else
                    kEnd=length(frame{d});
                end
                
                handles=KillHandle(['plotLine' num2str(d)],handles);

                for k=1:kEnd
                     Plot3DTrajectory(trajDataX{d}/normFac(1,d),trajDataY{d}/normFac(2,d),trajDataZ{d}/normFac(3,d),trajDataC{d},thisPlotTimeRange{d},['plotLine' num2str(d)],options.lineWidth,k,options.phasePlot2DView);
                end               

                
                if options.interactiveMode
                   % handles.trajName1=uicontrol('Style','text','String',wbMakeShortTrialname(wbstruct{d}.trialname),'units','normalized','Position',[.02 .97 .15 .02]);
                   handles.(['trajName' num2str(d)])=uicontrol('Style','text','String',wbMakeShortTrialname(wbstruct{d}.trialname),'units','normalized','Position',[.02 .97-.02*(d-1) .15 .02]);
                end

                if ~trajectoryIsActive
                     set(handles.(['plotLine' num2str(d)]),'Visible','off');
                     if options.interactiveMode
                        set(handles.(['trajName' num2str(d)]),'Visible','off');
                     end
                end
                
                DrawOverlayBalls;
                
                if options.flowArrows  
                    DrawFlowArrows; 
                end
 
                %transition Plane  THIS IS A SEPARATRIX BASED ON PCA
                %TRACES, NOT CURRENTLY USING
                
                if options.drawTransitionPlane

                     if ~exist('pcaStruct','var')
                         disp('no pca struct so cannot get reference neuron info to plot transition plane.');
                         beep;
                     else

                         %get AVAL direction
                         AVALIndex=find(strcmpi(pcaStruct.neuronIDs,'AVAL'));

        %                AVALDirection=pcaStruct.coeffs(AVALIndex,1:3);
                         AVALTrace=pcaStruct.traces(:,AVALIndex);

                         AVALDirection= [...
                             dot(AVALTrace,pcs{d}(:,1))  ...
                             dot(AVALTrace,pcs{d}(:,2))  ...
                             dot(AVALTrace,pcs{d}(:,3))  ...        
                         ];

                         ex3d(0,0,0,14,[1 1 1]);
                         %DrawPlane3(AVALDirection,[0 0 0],[-.05 .05],[-.05 .05],0);

                     end

                end
               
                
                %normal plane and GUI plane projection
                if options.interactiveMode
                   
                    DrawPlane; 
                    DrawTrajPlane2D;
                    
                end
                
                
                %set limits
                plot3D_num=1;
                if ~isempty(options.phasePlot3DLimits)
                     xlim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(1:2));
                     ylim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(3:4));
                     zlim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(5:6));
                     
                elseif d==1
                    
                     xlim(handles.plot3D(plot3D_num),1.1*[min(trajDataX{d}) max(trajDataX{d})]);
                     ylim(handles.plot3D(plot3D_num),1.1*[min(trajDataY{d}) max(trajDataY{d})]);
                     if isempty(options.phasePlot2DView)
                        zlim(handles.plot3D(plot3D_num),1.1*[min(trajDataZ{d}) max(trajDataZ{d})]);
                     end
                    
                else

                     xLimCurr=get(handles.plot3D(plot3D_num),'XLim');
                     yLimCurr=get(handles.plot3D(plot3D_num),'YLim');
                     zLimCurr=get(handles.plot3D(plot3D_num),'ZLim');

                     xlim(handles.plot3D(plot3D_num),[min([xLimCurr(1) 1.1*min(trajDataX{d}/normFac(1,d))]) max([xLimCurr(2) 1.1*max(trajDataX{d}/normFac(1,d))])]);
                     ylim(handles.plot3D(plot3D_num),[min([yLimCurr(1) 1.1*min(trajDataY{d}/normFac(2,d))]) max([yLimCurr(2) 1.1*max(trajDataY{d}/normFac(2,d))])]);
                     zlim(handles.plot3D(plot3D_num),[min([zLimCurr(1) 1.1*min(trajDataZ{d}/normFac(3,d))]) max([zLimCurr(2) 1.1*max(trajDataZ{d}/normFac(3,d))])]);
                end      
                
                
            end %end dataset iteration    
            
            %set limits
%             if ~isempty(options.phasePlot3DLimits)
%                  xlim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(1:2));
%                  ylim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(3:4));                
%                  if isempty(options.phasePlot2DView)
%                     zlim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(5:6));
%                  end
%             else
%                  
%                  xlim(handles.plot3D(plot3D_num),1.1*[min(trajDataX{d}) max(trajDataX{d})]);
%                  ylim(handles.plot3D(plot3D_num),1.1*[min(trajDataY{d}) max(trajDataY{d})]);
%                  if isempty(options.phasePlot2DView)
%                     zlim(handles.plot3D(plot3D_num),1.1*[min(trajDataZ{d}) max(trajDataZ{d})]);
%                  end
%             end
                      

            if isfield(options,'colormap') && ~isempty(options.colormap)
                colormap(options.colormap);
            end
            

            xlabel(options.axisLabels{1});
            ylabel(options.axisLabels{2});                        
            if isempty(options.phasePlot2DView)
                zlabel(options.axisLabels{3});          
            end
            
            if isfield(options,'phasePlot3DFlipZ') && options.phasePlot3DFlipZ && isempty(options.phasePlot2DView)
                set(handles.plot3D(plot3D_num),'zdir','reverse');
            end

            if isfield(options,'timeColoringOverlay') && ~isempty(options.timeColoringOverlay) && ~isempty(options.timeColoringOverlayLegend)
                legend(handles.timeColoringOverlay{1},options.timeColoringOverlayLegend);
            end


            if options.drawTerminalBalls || options.interactiveMode
                DrawTerminalBalls(1:length(activeDatasetFolders));
            end
             
            %interactive mode additions: balls and fix range checkbox

            if options.interactiveMode

   
                handles=KillHandle('transitionNumbers',handles);    
                DrawTransitionNumbers;       
                
                handles.whitebgCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.80 .97 .4 .02],'String','white bg','Value',0,'Callback',@(s,e) WhitebgCheckboxCallback);

                handles.fixLimitsCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.90 .97 .4 .02],'String','fix limits','Value',1,'Callback',@(s,e) FixLimitsCheckboxCallback);
                handles.endBallSizeText=uicontrol('Style','text','Units','normalized','Position',[.80 .95 .11 .02],'String','start/end ball size');
                handles.endBallSizePopup=uicontrol('Style','popup','Units','normalized','Position',[.91 .95 .08 .02],'String',endBallSizes,'Value',2,'Callback',@(s,e) EndBallSizePopupCallback);

                handles.overlayBallSizeText=uicontrol('Style','text','Units','normalized','Position',[.80 .88 .11 .02],'String','overlay ball size');
                handles.overlayBallSizePopup=uicontrol('Style','popup','Units','normalized','Position',[.91 .88 .08 .02],'String',overlayBallSizes,'Value',2,'Callback',@(s,e) OverlayBallSizePopupCallback);

                handles.riseNumbersCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.80 .90 .4 .02],'String','rise #s','ForegroundColor','r','Value',currentRiseNumbersVisibility,'Callback',@(s,e) ShowRiseNumbersCheckboxCallback);
                handles.fallNumbersCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.90 .90 .4 .02],'String','fall #s','ForegroundColor','b','Value',currentFallNumbersVisibility,'Callback',@(s,e) ShowFallNumbersCheckboxCallback);

                handles.startBallsCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.80 .92 .4 .02],'String','start balls','Value',showStartBallsState,'Callback',@(s,e) ShowStartBallsCheckboxCallback);
                handles.endBallsCheckbox=uicontrol('Style','checkbox','Units','normalized','Position',[.90 .92 .4 .02],'String','end balls','Value',showEndBallsState,'Callback',@(s,e) ShowEndBallsCheckboxCallback);
                      
            end

     
            %view buttons
%             if options.phasePlot3DDualMode 
%                 LRcorner=0.55;
%             else
%                 LRcorner=0.9;
%             end

            if plot3D_num==num3DPlots  
                if options.saveViewButton && options.interactiveMode
                   handles.saveViewButton = uicontrol('Style','pushbutton','Units','normalized','String','save PDF','Position',[0.88 0.85 0.1 0.02],'Callback',@(s,e) saveViewButtonCallback);
                   set(handles.fig3D,'toolbar','figure');
                end

                %mtit([wbMakeShortTrialname(wbstruct.trialname) ' ' flagstr],'fontsize',12,'color','k');

            end

            if options.interactiveMode && isempty(options.phasePlot2DView)
                cameratoolbar(handles.fig3D);
                set(handles.fig3D,'KeyPressFcn',@(s,e) KeyPressedFcn);

            end
            
            if plot3D_num==num3DPlots  && options.saveViewButton
                handles.viewText=uicontrol('Style','edit','Position',[0.9 0.8 0.05 0.02],'String',num2str(get(gca,'View')));
            end
            
            if options.interactiveMode
                set(handles.plot3D(plot3D_num),'XLimMode','manual');
                set(handles.plot3D(plot3D_num),'YLimMode','manual');
                if isempty(options.phasePlot2DView)
                    set(handles.plot3D(plot3D_num),'ZLimMode','manual');
                end
            end
                

        end  %for plot3D_num
        
        ColorBy(options.colorBy);
    
    end

    function XXXDraw3DPlotSecondary
        
        options.lineWidth2=1;
        
        if options.interactiveMode
            axes(handles.plot3D(1));
        end
        
        for d=2:length(activeDatasetFolders)       
            
            for k=1:length(frame{d})
                     Plot3DTrajectory(trajDataX{d}/normFac(1,d),trajDataY{d}/normFac(2,d),trajDataZ{d}/normFac(3,d),timeColoring{d},thisPlotTimeRange{d},['plotLine' num2str(d)],options.lineWidth2,k);
            end
          
            if options.interactiveMode
                handles.(['trajName' num2str(d)])=uicontrol('Style','text','String',wbMakeShortTrialname(wbstruct{d}.trialname),'units','normalized','Position',[.02 .97-.02*(d-1) .15 .02]);
            end
            

            %set limits
            plot3D_num=1;
            if ~isempty(options.phasePlot3DLimits)
                 xlim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(1:2));
                 ylim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(3:4));
                 zlim(handles.plot3D(plot3D_num),options.phasePlot3DLimits(5:6));
            else

                 xLimCurr=get(handles.plot3D(plot3D_num),'XLim');
                 yLimCurr=get(handles.plot3D(plot3D_num),'YLim');
                 zLimCurr=get(handles.plot3D(plot3D_num),'ZLim');

                 xlim(handles.plot3D(plot3D_num),[min([xLimCurr(1) 1.1*min(trajDataX{d}/normFac(1,d))]) max([xLimCurr(2) 1.1*max(trajDataX{d}/normFac(1,d))])]);
                 ylim(handles.plot3D(plot3D_num),[min([yLimCurr(1) 1.1*min(trajDataY{d}/normFac(2,d))]) max([yLimCurr(2) 1.1*max(trajDataY{d}/normFac(2,d))])]);
                 zlim(handles.plot3D(plot3D_num),[min([zLimCurr(1) 1.1*min(trajDataZ{d}/normFac(3,d))]) max([zLimCurr(2) 1.1*max(trajDataZ{d}/normFac(3,d))])]);
            end      
            
        end
        
        if options.drawTerminalBalls || options.interactiveMode
            DrawTerminalBalls(1:length(activeDatasetFolders));
        end

        
    end

    function DrawGhostTrajectory(thisDataX,thisDataY,thisDataZ,d,phasePlot2DView)

          %handles=KillHandle('ghostTrajectory',handles,d);
          
          if (numel(options.ghostTrajectoryRange)<d) || isempty(options.ghostTrajectoryRange{d})
              options.ghostTrajectoryRange{d}=1:length(thisDataX);
          end

          if isempty(phasePlot2DView) %this is the norm

               handles.ghostTrajectory(d)=plot3(thisDataX(options.ghostTrajectoryRange{d}),...
                  thisDataY(options.ghostTrajectoryRange{d}),...
                  thisDataZ(options.ghostTrajectoryRange{d}),...
                  'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);
              
                    
          elseif phasePlot2DView==1
              
               handles.ghostTrajectory(d)=plot(thisDataX(options.ghostTrajectoryRange{d}),...
                  thisDataY(options.ghostTrajectoryRange{d}),...
                  'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);  
              
          elseif phasePlot2DView==2
              
               handles.ghostTrajectory(d)=plot(thisDataX(options.ghostTrajectoryRange{d}),...
                  thisDataZ(options.ghostTrajectoryRange{d}),...
                  'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);         
              
              
          else
              
               handles.ghostTrajectory(d)=plot(thisDataY(options.ghostTrajectoryRange{d}),...
                  thisDataZ(options.ghostTrajectoryRange{d}),...
                  'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);         
                   
          end
              
              
              
          if options.plotGhostTrajectory
              set(handles.ghostTrajectory(d),'Visible','on');
          else
              set(handles.ghostTrajectory(d),'Visible','off');
          end
          
          RemoveFromLegend(handles.ghostTrajectory(d));


%                 
    end

    function DrawMeanTrajectories

        if options.interactiveMode
            
            sT=round(get(handles.timeSlider1,'Value'));
            eT=round(get(handles.timeSlider2,'Value'));

            sTF=round(get(handles.timeSlider3,'Value'));
            eTF=round(get(handles.timeSlider4,'Value'));
            
        else
            
            sT=round(0.25*length(tv{1}));
            eT=round(0.99*length(tv{1}));
            sTF=round(0.25*length(tv{1}));
            eTF=round(0.99*length(tv{1}));
        end
        
        
        handles=KillHandle('meanTrajPlotLine',handles);
        
        if options.interactiveMode
            figure(handles.fig3D);
        end
        
        %plot mean trajectory
        Plot3DTrajectory(meanTrajRiseDataX{1},meanTrajRiseDataY{1},meanTrajRiseDataZ{1},meanTrajRiseDataC{1},[sT eT],'meanTrajPlotLine',3*options.lineWidth,1,options.phasePlot2DView);
        if ~meanTrajIsActive
            set(handles.meanTrajPlotLine,'Visible','off');
        end
        
        
        
    end

    function DrawMergedClusterTrajectory(d)
        
        if nargin<1
            d=1;
        end
        
        if options.interactiveMode
            figure(handles.fig3D);
        end
        base('sTR')
        base('eTR')
        handles=KillHandle('mergedClusterTraj',handles);  
        Xdata={meanTrajX_RiseCluster{d}{1},meanTrajX_RiseCluster{d}{2},meanTrajRiseDataX{d},meanTrajX_FallCluster{d}{1},meanTrajX_FallCluster{d}{2},meanTrajRiseDataX{d}};
        Ydata={meanTrajY_RiseCluster{d}{1},meanTrajY_RiseCluster{d}{2},meanTrajRiseDataY{d},meanTrajY_FallCluster{d}{1},meanTrajY_FallCluster{d}{2},meanTrajRiseDataY{d}};
        Zdata={meanTrajZ_RiseCluster{d}{1},meanTrajZ_RiseCluster{d}{2},meanTrajRiseDataZ{d},meanTrajZ_FallCluster{d}{1},meanTrajZ_FallCluster{d}{2},meanTrajRiseDataZ{d}};
        Cdata={meanTrajC_RiseCluster{d}{1},meanTrajC_RiseCluster{d}{2},meanTrajRiseDataC{d},meanTrajC_FallCluster{d}{1},meanTrajC_FallCluster{d}{2},meanTrajRiseDataC{d}};
        
        ranges(1,:)=round([.5  .5  .25   .5   .5    .75]*numFrames+1);
        ranges(2,:)=round([.75 .75  .5  .75 .75  1]*numFrames);
                    
        Plot3DMultiTrajectory(Xdata,Ydata,Zdata,Cdata,ranges,'mergedClusterTraj',options.clusterLineWidth,options.phasePlot2DView);
        
    end

    function DrawClusterTrajectory(whichTraj,d)

            if nargin<2
                d=1;
            end
            
            if options.interactiveMode
                figure(handles.fig3D);
            end
        
            if whichTraj==1
                handles=KillHandle('riseClusterTraj',handles);                
                for nc=1:clusterRiseStruct{d}.options.maxClusters
                    Plot3DTrajectory(meanTrajX_RiseCluster{d}{nc},meanTrajY_RiseCluster{d}{nc},meanTrajZ_RiseCluster{d}{nc},meanTrajC_RiseCluster{d}{nc},sTR:eTR,'riseClusterTraj',options.clusterLineWidth,nc,options.phasePlot2DView);
                end

            else
                handles=KillHandle('fallClusterTraj',handles);  
                for nc=1:clusterFallStruct{d}.options.maxClusters                                 
                    Plot3DTrajectory(meanTrajX_FallCluster{d}{nc},meanTrajY_FallCluster{d}{nc},meanTrajZ_FallCluster{d}{nc},meanTrajC_FallCluster{d}{nc},sTF:eTF,'fallClusterTraj',options.clusterLineWidth,nc,options.phasePlot2DView);
                end
            
            end

    end

    function DrawTerminalBalls(dArray)

        handles=KillHandle('timeBall',handles);
        handles=KillHandle('timeBall2',handles);    
            
        for d=dArray
            for kk=1:size(thisPlotTimeRange{d},1) 
                 if ~isnan(thisPlotTimeRange{d}(kk,1))
                  handles.timeBall{d}(kk)=plot3(trajDataX{d}(thisPlotTimeRange{d}(kk,1)),trajDataY{d}(thisPlotTimeRange{d}(kk,1)),trajDataZ{d}(thisPlotTimeRange{d}(kk,1)),'Color',options.endBallColor,'MarkerSize',options.endBallSize,'Marker','o','LineWidth',2,'Visible','off');
                  
                 end
            end
            UpdateVisibility('timeBall',showStartBallsState,d);

                 
            for kk=1:size(thisPlotTimeRange{d},1) 
                if ~isnan(thisPlotTimeRange{d}(kk,end))
                  handles.timeBall2{d}(kk)=plot3(trajDataX{d}(thisPlotTimeRange{d}(kk,end)),trajDataY{d}(thisPlotTimeRange{d}(kk,end)),trajDataZ{d}(thisPlotTimeRange{d}(kk,end)),'Color',options.endBallColor,'MarkerSize',options.endBallSize,'Marker','o','LineWidth',2,'Visible','off'); 
                end
            end
            UpdateVisibility('timeBall2',showEndBallsState,d);
            
        end
        
        
    end
    
    function DrawTransitionNumbers
                        
        for kk=1:size(transitionsRiseMat{1},1) 
           if ~isnan(transitionsRiseMat{1}(kk,end))
             handles.riseTransitionNumbers(kk)=text(trajDataX{1}(transitionsRiseMat{1}(kk,end)),trajDataY{1}(transitionsRiseMat{1}(kk,end)),trajDataZ{1}(transitionsRiseMat{1}(kk,end)),num2str(kk),...
             'FontSize',14,'Color',[1 0 0],'VerticalAlignment','bottom','HorizontalAlignment','center','Visible','off');
           end
        end 
        
        
        for kk=1:size(transitionsFallMat{1},1) 
           if ~isnan(transitionsFallMat{1}(kk,end))
             handles.fallTransitionNumbers(kk)=text(trajDataX{1}(transitionsFallMat{1}(kk,end)),trajDataY{1}(transitionsFallMat{1}(kk,end)),trajDataZ{1}(transitionsFallMat{1}(kk,end)),num2str(kk),...
             'FontSize',14,'Color',[0 0 1],'VerticalAlignment','top','HorizontalAlignment','center','Visible','off');
           end
        end 
           
        UpdateVisibility('riseTransitionNumbers',currentRiseNumbersVisibility);
        UpdateVisibility('fallTransitionNumbers',currentFallNumbersVisibility);
        
        
%         if options.showRiseTransitionNumbers
% 
%             set(handles.riseTransitionNumbers,'Visible','on');
%         else
%             for i=1:length(handles.riseTransitionNumbers
%             set(handles.riseTransitionNumbers,'Visible','off');
%         end
%                        
%         if options.showFallTransitionNumbers
%             set(handles.fallTransitionNumbers,'Visible','on');
%         else
%             set(handles.fallTransitionNumbers,'Visible','off');
%         end
        
    end

    function Update3DPlot
        
          if options.interactiveMode
             UpdateTimeBounds;

              
             if strcmp(options.trajType,'single')
                 thisPlotTimeRange{1}=[FTFrame FTFrameEnd];  

             else

                 for k=1:length(frame{1})
                     thisPlotTimeRange{1}(k,:)=[frame{1}(k) frameEnd{1}(k)];
                 end

                 for d=2:length(activeDatasetFolders)
                     for k=1:length(frameEnd{d})
                         thisPlotTimeRange{d}(k,:)=[frame{d}(k) frameEnd{d}(k)];
                     end
                 end

             end              
           
          end
          
          
          %trajectories
          if trajectoryIsActive
              
              if strcmp(options.trajType,'single')
                  
                  for d=1:length(activeDatasetFolders)               
                      
                     sTc=max([1 round(sT/size(trajDataX{1},1)*size(trajDataX{d},1))]);
                     eTc=round(eT/size(trajDataX{1},1)*size(trajDataX{d},1));  
                     
                     if isfield(handles,['plotLine' num2str(d)])
                             if eT>sT  %don't draw unless there is something to draw

                                  set(handles.(['plotLine' num2str(d)]),...
                                                'XData',[trajDataX{d}(sTc:eTc) trajDataX{d}(sTc:eTc)]/normFac(1,d),...
                                                'YData',[trajDataY{d}(sTc:eTc) trajDataY{d}(sTc:eTc)]/normFac(2,d),...
                                                'ZData',[trajDataZ{d}(sTc:eTc) trajDataZ{d}(sTc:eTc)]/normFac(3,d),...
                                                'CData',[trajDataC{d}(sTc:eTc,:) trajDataC{d}(sTc:eTc,:)],...
                                                'Visible','on'); %,'EdgeColor','interp');
    %return;                                        
                  %  set(handles.(['plotLine' num2str(d)])(k),'EdgeAlpha',0.3);

%                                    set(handles.(['plotLine' num2str(d)]),...
%                                                 'XData',trajDataX{d}(sTc:eTc)/normFac(1,d),...
%                                                 'YData',trajDataY{d}(sTc:eTc)/normFac(2,d),...
%                                                 'ZData',trajDataZ{d}(sTc:eTc)/normFac(3,d),...
%                                                 'CData',trajDataC{d}(sTc:eTc,:),...
%                                                 'Visible','on'); %,'EdgeColor','interp');
%                   %  set(handles.(['plotLine' num2str(d)])(k),'EdgeAlpha',0.3);
                  
                  
                  
                  
                  
                  
                             else

                                  set(handles.(['plotLine' num2str(d)]),'Visible','off');  
                                  
                             end                  
                      end
                     
                     
                  end
                  
                  
              elseif strcmp(options.trajType,'timewarp')
            
                  for d=1:length(activeDatasetFolders)                     
                     sTc=max([1 round(sT/size(mTrajDataX{1},1)*size(mTrajDataX{d},1))]);
                     eTc=round(eT/size(mTrajDataX{1},1)*size(mTrajDataX{d},1));

if options.monitorAngularDivergence
     fr=eTc;
     for cl=1:2
        inds=clusterRiseStruct{d}.clusterIndices{cl};
        vels=[[mTrajFallDataX{d}(fr,inds)-mTrajFallDataX{d}(fr-1,inds)  ,  0]' ...
              [ mTrajFallDataY{d}(fr,inds)- mTrajFallDataY{d}(fr-1,inds)  ,  0]' ...
              [ mTrajFallDataZ{d}(fr,inds)-mTrajFallDataZ{d}(fr-1,inds)  ,  0]' ];
        numPts=size(vels,1);
        angDiv=nan(numPts);
        for p2=1:numPts
            for p1=1:p2-1
                angDiv(p1,p2) = abs(atan2(norm(cross(vels(p1,:),vels(p2,:))), dot(vels(p1,:),vels(p2,:))));
            end
        end
        angDiv=angDiv(~isnan(angDiv));
        disp(['angle' num2str(cl) '=' num2str(mean(angDiv(:))/pi*180)]);
        base('vels')
     end
        
end
                     
                     
                     
                     for k=1:size(thisPlotTimeRange{d},1)  
                         
                         
                         if isfield(handles,['plotLine' num2str(d)])
                             if eT>sT   %don't draw unless there is something to draw


                                  set(handles.(['plotLine' num2str(d)])(k),...
                                                'XData',[mTrajDataX{d}(sTc:eTc,k) mTrajDataX{d}(sTc:eTc,k)]/normFac(1,d),...
                                                'YData',[mTrajDataY{d}(sTc:eTc,k) mTrajDataY{d}(sTc:eTc,k)]/normFac(2,d),...
                                                'ZData',[mTrajDataZ{d}(sTc:eTc,k) mTrajDataZ{d}(sTc:eTc,k)]/normFac(3,d),...
                                                'CData',[mTrajDataC{d}(sTc:eTc,k,:) mTrajDataC{d}(sTc:eTc,k,:)],...
                                                'Visible','on');
                  %  set(handles.(['plotLine' num2str(d)])(k),'EdgeAlpha',0.3);

                  
                  
                  
                             else

                                  set(handles.(['plotLine' num2str(d)])(k),'Visible','off');  
                                  
                             end                  
                         end
                     end                            
                  end         
              end
              
              
              
              for d=1:length(activeDatasetFolders)
                  UpdateVisibility(['plotLine' num2str(d)],trajVisibilityLogical(d));
                  UpdateVisibility(['trajName' num2str(d)],trajVisibilityLogical(d));
              end
                        
              
          end
          

          %start/end balls
          
          if isfield(handles,'timeBall')
disp('yo')   
              if strcmp(options.trajType,'single')
disp('yo2')
                  for d=1:length(handles.timeBall)
disp('yo3')
base('handles')
                      sTc=max([1 round(sT/size(trajDataX{1},1)*size(trajDataX{d},1))]);
                      eTc=round(eT/size(trajDataX{1},1)*size(trajDataX{d},1));   

%                      if handles.timeBall{d}(1)>0
                          set(handles.timeBall{d}(1),'XData',trajDataX{d}(sTc,1)/normFac(1,d));
                          set(handles.timeBall{d}(1),'YData',trajDataY{d}(sTc,1)/normFac(2,d));
                          set(handles.timeBall{d}(1),'ZData',trajDataZ{d}(sTc,1)/normFac(3,d));
%                      end
%                      if handles.timeBall2{d}(1)>0
                          set(handles.timeBall2{d}(1),'XData',trajDataX{d}(eTc,1)/normFac(1,d));
                          set(handles.timeBall2{d}(1),'YData',trajDataY{d}(eTc,1)/normFac(2,d));
                          set(handles.timeBall2{d}(1),'ZData',trajDataZ{d}(eTc,1)/normFac(3,d));  
%                      end

                  end

              elseif strcmp(options.trajType,'timewarp')

                  for d=1:length(handles.timeBall)

                      sTc=max([1 round(sT/size(mTrajDataX{1},1)*size(mTrajDataX{d},1))]);
                      eTc=round(eT/size(mTrajDataX{1},1)*size(mTrajDataX{d},1));

                      for k=1:length(handles.timeBall{d})

                          if handles.timeBall{d}(k)>0
                              set(handles.timeBall{d}(k),'XData',mTrajDataX{d}(sTc,k)/normFac(1,d));
                              set(handles.timeBall{d}(k),'YData',mTrajDataY{d}(sTc,k)/normFac(2,d));
                              set(handles.timeBall{d}(k),'ZData',mTrajDataZ{d}(sTc,k)/normFac(3,d));
                          end
                      end

                      for k=1:length(handles.timeBall2{d})

                          if handles.timeBall2{d}(k)>0
                              set(handles.timeBall2{d}(k),'XData',mTrajDataX{d}(eTc,k)/normFac(1,d));
                              set(handles.timeBall2{d}(k),'YData',mTrajDataY{d}(eTc,k)/normFac(2,d));
                              set(handles.timeBall2{d}(k),'ZData',mTrajDataZ{d}(eTc,k)/normFac(3,d));  
                          end

                      end
                  end

              end

          end

          %transition numbers         
          
          if isfield(handles,'riseTransitionNumbers')
              
              for k=1:length(handles.riseTransitionNumbers)
                  if handles.riseTransitionNumbers(k)>0
                      set(handles.riseTransitionNumbers(k),'Position',[mTrajRiseDataX{1}(eT,k),mTrajRiseDataY{1}(eT,k),mTrajRiseDataZ{1}(eT,k)]);
                  end
              end
              
          end
          
          if isfield(handles,'fallTransitionNumbers')
              for k=1:length(handles.fallTransitionNumbers)
                  if handles.fallTransitionNumbers(k)>0
                      set(handles.fallTransitionNumbers(k),'Position',[mTrajFallDataX{1}(eT,k),mTrajFallDataY{1}(eT,k),mTrajFallDataZ{1}(eT,k)]);
                  end
              end
          end
          UpdateVisibility('riseTransitionNumbers',currentRiseNumbersVisibility);
          UpdateVisibility('fallTransitionNumbers',currentFallNumbersVisibility);
                        
              
          %mean trajectory    
          
          if meanTrajIsActive
              for d=1:length(activeDatasetFolders)

                    sTc=round(sT/size(mTrajRiseDataX{1},1)*size(mTrajRiseDataX{d},1));
                    eTc=round(eT/size(mTrajRiseDataX{1},1)*size(mTrajRiseDataX{d},1));

                     if eT>sT && meanTrajIsActive %don't draw unless there is something to draw

                         set(handles.meanTrajPlotLine,...
                                'XData',[meanTrajRiseDataX{d}(sTc:eTc) meanTrajRiseDataX{d}(sTc:eTc)]/normFac(1,d),...
                                'YData',[meanTrajRiseDataY{d}(sTc:eTc) meanTrajRiseDataY{d}(sTc:eTc)]/normFac(2,d),...
                                'ZData',[meanTrajRiseDataZ{d}(sTc:eTc) meanTrajRiseDataZ{d}(sTc:eTc)]/normFac(3,d),...
                                'CData',[meanTrajRiseDataC{d}(sTc:eTc) meanTrajRiseDataC{d}(sTc:eTc)],...
                                'Visible','on');
                     else
                         if isfield(handles,'meanTrajPlotLine')
                            set(handles.meanTrajPlotLine,'Visible','off');
                         end
                     end

              end      
          end
          
          %mean cluster trajectories
          
          if options.plotClusters
              
              for d=1:length(activeDatasetFolders)

    sTRc=round(sTR/size(mTrajRiseDataX{1},1)*size(mTrajRiseDataX{d},1));
    eTRc=round(eTR/size(mTrajRiseDataX{1},1)*size(mTrajRiseDataX{d},1));
    
                    if isfield(handles,'riseClusterTraj')
                        for nc=1:clusterRiseStruct{d}.options.maxClusters  

                             if eT>sT  && riseClusterTrajIsActive %don't draw unless there is something to draw
handles.riseClusterTraj
nc
handles.riseClusterTraj(nc)
                                set(handles.riseClusterTraj(nc),...
                                        'XData',[meanTrajX_RiseCluster{d}{nc}(sTRc:eTRc) meanTrajX_RiseCluster{d}{nc}(sTRc:eTRc)]/normFac(1,d),...
                                        'YData',[meanTrajY_RiseCluster{d}{nc}(sTRc:eTRc) meanTrajY_RiseCluster{d}{nc}(sTRc:eTRc)]/normFac(2,d),...
                                        'ZData',[meanTrajZ_RiseCluster{d}{nc}(sTRc:eTRc) meanTrajZ_RiseCluster{d}{nc}(sTRc:eTRc)]/normFac(3,d),...
                                        'CData',[meanTrajC_RiseCluster{d}{nc}(sTRc:eTRc) meanTrajC_RiseCluster{d}{nc}(sTRc:eTRc)],...
                                        'Visible','on');
                             else
                                 set(handles.riseClusterTraj,'Visible','off');
                             end
                        end
                    end
              end

              %mean fall cluster trajectories
              if fallClusterRangeOverrideIsActive              
                  thissT=1; %floor(length(tv{1})/4);
                  thiseT=floor(3*length(tv{1})/4);

              else
                  thissT=sTF;
                  thiseT=eTF;
              end

              for d=1:length(activeDatasetFolders)

    sTFc=round(thissT/size(mTrajRiseDataX{1},1)*size(mTrajRiseDataX{d},1));
    eTFc=round(thiseT/size(mTrajRiseDataX{1},1)*size(mTrajRiseDataX{d},1));

                    if isfield(handles,'fallClusterTraj')
                        for nc=1:clusterFallStruct{d}.options.maxClusters  

                             if eT>sT && fallClusterTrajIsActive %don't draw unless there is something to draw

                                 set(handles.fallClusterTraj(nc),...
                                        'XData',[meanTrajX_FallCluster{d}{nc}(sTFc:eTFc) meanTrajX_FallCluster{d}{nc}(sTFc:eTFc)]/normFac(1,d),...
                                        'YData',[meanTrajY_FallCluster{d}{nc}(sTFc:eTFc) meanTrajY_FallCluster{d}{nc}(sTFc:eTFc)]/normFac(2,d),...
                                        'ZData',[meanTrajZ_FallCluster{d}{nc}(sTFc:eTFc) meanTrajZ_FallCluster{d}{nc}(sTFc:eTFc)]/normFac(3,d),...
                                        'CData',[meanTrajC_FallCluster{d}{nc}(sTFc:eTFc) meanTrajC_FallCluster{d}{nc}(sTFc:eTFc)],...
                                        'Visible','on');
                             else
                                 set(handles.fallClusterTraj,'Visible','off');
                             end
                        end
                    end
              end
          
          end
          
          ColorBy(options.colorBy);

          %group normal / trajectory plane
          if trajPlaneIsActive && options.interactiveMode
              
              
              
              if options.clusterMixMode
                  
%                       nvc=sum(~isnan(transitionsMat{1}(:,1)));
%                       if eTc/numFrames<.35 || eTc/numFrames>.80
%                           clusterOcc={(clusterRiseStruct{1}.clusterMembership==1 & ~isnan(transitionsMat{1}(:,1)))',...
%                                              (clusterRiseStruct{1}.clusterMembership==2 & ~isnan(transitionsMat{1}(:,1)))'};                    
%                       elseif eTc/numFrames<0.5
%                           clusterOcc={true(nvc,1),false(nvc,1)};
%                       elseif eTc/numFrames<0.8
%                           clusterOcc={(clusterFallStruct{1}.clusterMembership==1 & ~isnan(transitionsMat{1}(:,1)))',...
%                                              (clusterFallStruct{1}.clusterMembership==2 & ~isnan(transitionsMat{1}(:,1)))'};                                
%                       else
%                           clusterOcc={true(nvc,1),false(nvc,1)};   
%                       end
                        

                      if eTc/numFrames<.35 || eTc/numFrames>.8
                          clusterOcc={(clusterRiseStruct{1}.clusterMembership==1 & ~isnan(transitionsMat{1}(:,1)))',...
                                             (clusterRiseStruct{1}.clusterMembership==2 & ~isnan(transitionsMat{1}(:,1)))'};  
                      else
                           clusterOcc={(clusterFallStruct{1}.clusterMembership==1 & ~isnan(transitionsMat{1}(:,1)))',...
                                             (clusterFallStruct{1}.clusterMembership==2 & ~isnan(transitionsMat{1}(:,1)))'};   
                      end

                      
                      numClusters=length(clusterOcc);
                      
                      pointsCenter=zeros(numClusters,3);  
                      meanNormal=zeros(size(pointsCenter));
                      
                      for nc=1:numClusters
                          
                         currentPts=[mTrajDataX{1}(eTc,clusterOcc{nc})' ...
                                         mTrajDataY{1}(eTc,clusterOcc{nc})' ...
                                         mTrajDataZ{1}(eTc,clusterOcc{nc})'];
                                     
                         pointsCenter=[mean(mTrajDataX{1}(eTc,clusterOcc{nc})) ...
                                       mean(mTrajDataY{1}(eTc,clusterOcc{nc})) ...
                                       mean(mTrajDataZ{1}(eTc,clusterOcc{nc}))];
                                         
                         eTcNext=1+mod(eTc,numFrames);
                         
                         pointsCenterNext=[mean(mTrajDataX{1}(eTcNext,clusterOcc{nc})) ...
                                           mean(mTrajDataY{1}(eTcNext,clusterOcc{nc})) ...
                                           mean(mTrajDataZ{1}(eTcNext,clusterOcc{nc}))];
                                                             
                         meanNormal=pointsCenterNext-pointsCenter;
                         
                         set(handles.planeCenter(nc),'XData',pointsCenter(1),'YData',pointsCenter(2),'ZData',pointsCenter(3));
  
                         set(handles.planeNormal(nc),'XData',[pointsCenter(1) pointsCenter(1)+10*meanNormal(1)],...
                                                     'YData',[pointsCenter(2) pointsCenter(2)+10*meanNormal(2)],...
                                                     'ZData',[pointsCenter(3),pointsCenter(3)+10*meanNormal(3)]);

                         UpdatePlane3(handles.trajPlane,nc,meanNormal,pointsCenter,[-.05 .05],[-.05 .05],currentPts,eTc);  

                      end

                      
                      
              else
              
                  if ~convHullIsSplit || ~options.plotClusters
                      
                      validFrameEnds=frameEnd{1}(~isnan(frameEnd{1}));  %fix nan at end of FrameEnd{1}, shouldnt be necesssary any more
                      pointsCenter=[mean(trajDataX{1}(round(validFrameEnds))) mean(trajDataY{1}(round(validFrameEnds)))  mean(trajDataZ{1}(round(validFrameEnds)))];
                      set(handles.planeCenter,'XData',pointsCenter(1),'YData',pointsCenter(2),'ZData',pointsCenter(3));

                      oneA=ones(size(validFrameEnds)); 

                      meanNormal=[mean(trajDataX{1}(round(validFrameEnds))-trajDataX{1}(round(max([oneA; validFrameEnds-1],[],1)))), ...
                          mean(trajDataY{1}(round(validFrameEnds))-trajDataY{1}(round(max([oneA; validFrameEnds-1],[],1)))), ...    
                          mean(trajDataZ{1}(round(validFrameEnds))-trajDataZ{1}(round(max([oneA; validFrameEnds-1],[],1))))];

                      set(handles.planeNormal,'XData',[pointsCenter(1) pointsCenter(1)+meanNormal(1)],...
                          'YData',[pointsCenter(2) pointsCenter(2)+meanNormal(2)],...
                          'ZData',[pointsCenter(3),pointsCenter(3)+meanNormal(3)]);

                    
                      UpdatePlane3(handles.trajPlane,meanNormal,pointsCenter,[-.05 .05],[-.05 .05],currentPts,clusterOcc,eTc);

                  else  %conv hull is split

                      pointsCenter=zeros(clusterRiseStruct{1}.options.maxClusters,3);  

                      for nc=1:clusterRiseStruct{1}.options.maxClusters
                          
                         validClusters=clusterRiseStruct{1}.clusterMembership==nc & ~isnan(transitionsMat{1}(:,1));

%                          pointsCenter(nc,:)=[mean(trajDataX{1}(round(frameEnd{1}(validClusters)))) ...
%                                              mean(trajDataY{1}(round(frameEnd{1}(validClusters)))) ...
%                                              mean(trajDataZ{1}(round(frameEnd{1}(validClusters))))];
                                         
                          pointsCenter(nc,:)=[mean(mTrajDataX{1}(eTc,validClusters)) ...
                                              mean(mTrajDataY{1}(eTc,validClusters)) ...
                                              mean(mTrajDataZ{1}(eTc,validClusters))];
                                         
                          eTcNext=1+mod(eTc,numFrames);
                          pointsCenterNext(nc,:)=[mean(mTrajDataX{1}(eTcNext,validClusters)) ...
                                              mean(mTrajDataY{1}(eTcNext,validClusters)) ...
                                              mean(mTrajDataZ{1}(eTcNext,validClusters))];
                                         

                          meanNormal(nc,:)=pointsCenterNext(nc,:)-pointsCenter(nc,:);
                          
                         set(handles.planeCenter(nc),'XData',pointsCenter(nc,1),'YData',pointsCenter(nc,2),'ZData',pointsCenter(nc,3));

%                         oneA=ones(size(frameEnd{1}(validClusters))); 
%
%                          meanNormal0(nc,:)=[mean(trajDataX{1}(round(frameEnd{1}(validClusters)))-trajDataX{1}(round(max([oneA; frameEnd{1}(validClusters)-1],[],1)))), ...
%                               mean(trajDataY{1}(round(frameEnd{1}(validClusters)))-trajDataY{1}(round(max([oneA; frameEnd{1}(validClusters)-1],[],1)))), ...    
%                               mean(trajDataZ{1}(round(frameEnd{1}(validClusters)))-trajDataZ{1}(round(max([oneA; frameEnd{1}(validClusters)-1],[],1))))];
% 
%                          meanNormal1(nc,:)=[mean(-trajDataX{1}(round(frameEnd{1}(validClusters)))+trajDataX{1}(round(min([numFrames*oneA; frameEnd{1}(validClusters)+1],[],1)))), ...
%                               mean(-trajDataY{1}(round(frameEnd{1}(validClusters)))+trajDataY{1}(round(min([numFrames*oneA; frameEnd{1}(validClusters)+1],[],1)))), ...    
%                               mean(-trajDataZ{1}(round(frameEnd{1}(validClusters)))+trajDataZ{1}(round(min([numFrames*oneA; frameEnd{1}(validClusters)+1],[],1))))];
%                          
%                          meanNormal=(meanNormal0+meanNormal1)/2;
%                           
                         set(handles.planeNormal(nc),'XData',[pointsCenter(nc,1) pointsCenter(nc,1)+10*meanNormal(nc,1)],...
                              'YData',[pointsCenter(nc,2) pointsCenter(nc,2)+10*meanNormal(nc,2)],...
                              'ZData',[pointsCenter(nc,3),pointsCenter(nc,3)+10*meanNormal(nc,3)]);


                      end

  
                      UpdatePlane3(handles.trajPlane,meanNormal,pointsCenter,[-.05 .05],[-.05 .05],currentPts,clusterOcc,eTc);
  

                  end

                  %convex hull
                  if convHullIsActive && get(handles.trajectoriesPopup,'Value') ~= 1
                      UpdateConvHull3D;   
                  end

              end
              
              
          end
          
                  
          %overlay balls
          if options.overlayBallsFlag
            UpdateOverlayBalls;
          end
          

            
    end

    function Update3DPlotLimits
        
        plot3D_num=1;
        
        currentView=get(gca,'View');
        cameratoolbar(handles.fig3D,'ResetCamera');
              
        minX=[];minY=[];minZ=[];maxX=[];maxY=[];maxZ=[];
        for d=1:length(activeDatasetFolders)
            
            minX=min([minX; min(trajDataX{d})/normFac(1,d)]);
            minY=min([minY; min(trajDataY{d})/normFac(2,d)]);
            minZ=min([minZ; min(trajDataZ{d})/normFac(3,d)]);
            
            maxX=max([maxX; max(trajDataX{d})/normFac(1,d)]);
            maxY=max([maxY; max(trajDataY{d})/normFac(2,d)]);
            maxZ=max([maxZ; max(trajDataZ{d})/normFac(3,d)]);
        end
            
        xlim(handles.plot3D(plot3D_num),1.1*[minX maxX]);
        ylim(handles.plot3D(plot3D_num),1.1*[minY maxY]);
        zlim(handles.plot3D(plot3D_num),1.1*[minZ maxZ]);
        
        
        set(handles.fig3D,'KeyPressFcn',@(s,e) KeyPressedFcn);
        set(gca,'View',currentView);
    end

    function Plot3DMultiTrajectory(thisDataX,thisDataY,thisDataZ,thisTimeColoring,ranges,handleName,lineWidth,phasePlot2DView)
        %currently only implemented for rise-to-rise range
        
        if nargin<7
            lineWidth=1;
        end
        
        if nargin<8
            phasePlot2DView=[];
        end
        
        %Main plot line
        if isnan(ranges(1)) || isnan(ranges(end))
            
            handles.(handleName)=color_line3([0 0],[0 0],[0 0],[0 0],'Visible','off');
            
        else

             if isempty(phasePlot2DView) %this is the norm  
                    
                        
                    for seg=1:length(thisDataX)
                           
                       % this_range= max([inPlotTimeRange(1) startF(seg)]): min([inPlotTimeRange(end) endF(seg)]);
                        this_range=ranges(1,seg):ranges(2,seg);
                    
                        handles.(handleName)(seg)=color_line3(thisDataX{seg}(this_range),...
                          thisDataY{seg}(this_range),...
                          thisDataZ{seg}(this_range),...
                          double(thisTimeColoring{seg}(this_range)),...    %hack around opengl trisurf bug
                          'LineStyle','-','Marker','none','LineWidth',lineWidth);

                    end
                          
            elseif phasePlot2DView==1  %TBD
                handles.(handleName)(handleIndex)=cline(thisDataX(this_range),...
                  thisDataY(this_range),...
                  double(thisTimeColoring(this_range)));    %hack around opengl trisurf bug
                set(handles.(handleName)(handleIndex),'LineStyle','-','Marker','none','LineWidth',lineWidth);
            elseif phasePlot2DView==2  %TBD
                handles.(handleName)(handleIndex)=cline(thisDataX(this_range),...
                  thisDataZ(this_range),...
                  double(thisTimeColoring(this_range)),...    %hack around opengl trisurf bug
                  'LineStyle','-','Marker','none','LineWidth',lineWidth);
            else  %TBD
                handles.(handleName)(handleIndex)=cline(...
                  thisDataY(this_range),...
                  thisDataZ(this_range),...
                  double(thisTimeColoring(this_range)),...    %hack around opengl trisurf bug
                  'LineStyle','-','Marker','none','LineWidth',lineWidth);       
            end
                    
        end
        
        %need to fix this, for now just comment out
        %RemoveFromLegend(handles.(handleName)(handleIndex));

        hold on;

        
    end %function Plot3DMultiTrajectory

    function Plot3DTrajectory(thisDataX,thisDataY,thisDataZ,thisTimeColoring,thisPlotTimeRange,handleName,lineWidth,handleIndex,phasePlot2DView)
        
        if nargin<7
            lineWidth=1;
        end
        
        if nargin<8
            handleIndex=1;
        end
        
        if nargin<9
            phasePlot2DView=[];
        end
        
        
        
        %handles=KillHandle(handleName,handles,handleIndex);
        %Main plot line
        if isnan(thisPlotTimeRange(1)) || isnan(thisPlotTimeRange(end))
            
            handles.(handleName)(handleIndex)=color_line3([0 0],[0 0],[0 0],[0 0],'Visible','off');
        else
%             if isempty(thisTimeColoring)
%                 disp('is this crap running')
%                 handles.(handleName)(handleIndex)=plot3(thisDataX(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
%                       thisDataY(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
%                       thisDataZ(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
%                 'Color',options.phasePlot3DMainColors{1},'LineStyle','-','Marker','none','LineWidth',1);
%             else 



                if isempty(phasePlot2DView) %this is the norm

                    qs=5;

                    handles.(handleName)(handleIndex)=color_line3(thisDataX(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      thisDataY(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      thisDataZ(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      double(thisTimeColoring(thisPlotTimeRange(1):thisPlotTimeRange(end))),...    %hack around opengl trisurf bug
                      'LineStyle','-','Marker','none','LineWidth',lineWidth);
                  

                 %   set(handles.(handleName)(handleIndex),'EdgeAlpha',0.4);
                 %   base('han',handles.(handleName)(handleIndex));


                 


                    
                elseif phasePlot2DView==1
                    handles.(handleName)(handleIndex)=cline(thisDataX(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      thisDataY(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      double(thisTimeColoring(thisPlotTimeRange(1):thisPlotTimeRange(end))));    %hack around opengl trisurf bug
                    set(handles.(handleName)(handleIndex),'LineStyle','-','Marker','none','LineWidth',lineWidth);
                elseif phasePlot2DView==2
                    handles.(handleName)(handleIndex)=cline(thisDataX(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      thisDataZ(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      double(thisTimeColoring(thisPlotTimeRange(1):thisPlotTimeRange(end))),...    %hack around opengl trisurf bug
                      'LineStyle','-','Marker','none','LineWidth',lineWidth);
                else
                    handles.(handleName)(handleIndex)=cline(...
                      thisDataY(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      thisDataZ(thisPlotTimeRange(1):thisPlotTimeRange(end)),...
                      double(thisTimeColoring(thisPlotTimeRange(1):thisPlotTimeRange(end))),...    %hack around opengl trisurf bug
                      'LineStyle','-','Marker','none','LineWidth',lineWidth);       
                end
                    

          %  end
        end
        
        RemoveFromLegend(handles.(handleName)(handleIndex));

        hold on;
            
    end

    function saveViewButtonCallback
        set(handles.saveViewButton,'Visible','off');
          
        thisview=get(gca,'View');
        disp(['3D view: ' num2str(thisview(1)) '  ' num2str(thisview(2))]);
        set(handles.viewText,'String',[num2str(thisview(1)) '  ' num2str(thisview(2))]);
        viewstr=['(' num2str(thisview(1)) '-' num2str(thisview(2)) ')'];
        
        export_fig([options.outputDirectory filesep 'Quant' filesep 'pca-' wbstruct{1}.trialname '-phaseplots' flagstr '-view' viewstr '.pdf']);
        disp(['saved: ' options.outputDirectory filesep 'Quant' filesep 'pca-' wbstruct{1}.trialname '-phaseplots' flagstr '-view' viewstr '.pdf']);
        if ~isempty(options.savePDFCopyDirectory)
           export_fig([options.savePDFCopyDirectory filesep 'pca-' wbstruct{1}.trialname '-phaseplots' flagstr '-view' viewstr '.pdf']);
           disp(['saved a copy to: ' options.savePDFCopyDirectory]);
        end
        
        
        set(handles.saveViewButton,'Visible','on');
    end

%% PCA GUI Panel functions

    function MakeGUIPCA
        
        handles.uipanel=uipanel('Position',[.05 .1 .90 .2],'Title','PCA options');
        handles.secondDatasetText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.035 .20 .30 .1],'String','project 2nd dataset','HorizontalAlignment','left');
        handles.secondDatasetPopup=uicontrol('Parent',handles.uipanel,'Style','popup','Units','normalized','Position',[.01 .15 .30 .03],'String',['---', datasetFolderNames],'Value',1,'Callback',@(s,e) SecondDatasetPopupCallback);
        handles.secondDatasetCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','Units','normalized','Position',[.01 .24 .3 .08],'Value',0,'Callback',@(s,e) SecondDatasetCheckboxCallback);
    
        handles.PCAJointCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','joint PCA','Units','normalized','Enable','off','Position',[.18 .24 .3 .08],'Value',options.multiTrialPCAOptions.joint,'Callback',@(s,e) PCAJointCheckboxCallback);
        
        handles.allDatasetsCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','all datasets','Units','normalized','Position',[.18 .34 .3 .08],'Value',multiTrialIsActive,'Callback',@(s,e) AllDatasetsCheckboxCallback);
        handles.postNormalizePCsCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','post-normalize PCs','Units','normalized','Position',[.32 .34 .3 .08],'Value',0,'Callback',@(s,e) PostNormalizePCsCheckboxCallback);
        handles.crossNormalizeCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','cross-normalize PCs','Units','normalized','Position',[.5 .34 .3 .08],'Value',double(options.multiTrialPCAOptions.crossNormalizeFlag),'Enable','off','Callback',@(s,e) CrossNormalizeCheckboxCallback);

        handles.missingCoeffText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.335 .20 .20 .1],'String','missing coeffs','HorizontalAlignment','left');       
        handles.missingCoeffPopup=uicontrol('Parent',handles.uipanel,'Style','popup','Units','normalized','Position',[.31 .15 .20 .03],'String',missingCoeffOptionList,'Value',1,'Callback',@(s,e) missingCoeffPopupCallback);

        
        handles.PCARestrictRangeText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.545 .20 .20 .1],'String','restrict range','HorizontalAlignment','left');       
        handles.PCARestrictRangePopup=uicontrol('Parent',handles.uipanel,'Style','popup','Units','normalized','Position',[.52 .15 .20 .03],'String',PCARestrictRangeOptionList,'Value',1,'Callback',@(s,e) PCARangeMaskPopupCallback);

        
        handles.PCAneuronSubsetText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.035 .85 .20 .1],'String','neuron subset','HorizontalAlignment','left');
        handles.PCAneuronSubsetPopup=uicontrol('Parent',handles.uipanel,'Style','popup','Units','normalized','Position',[.01 .82 .20 .03],'String',neuronSubsetTypeList,'Value',1,'Callback',@(s,e) neuronSubsetPopupCallback);
%              
%         handles.defaultExclusionsText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.245 .85 .20 .1],'String','default exclusions','HorizontalAlignment','left',...
%             'tooltip','BAGL,BAGR,AQR,URXL,URXR,AVFL,AVFR');
        handles.PCADefaultExclusionsCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','default exclusions','Units','normalized','Position',[.22 .85 .20 .1],'Value',1,'Callback',@(s,e) DefaultExclusionsCheckboxCallback,...
             'tooltip','BAGL,BAGR,AQR,URXL,URXR,AVFL,AVFR');
        handles.PCADerivsCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','derivs','Units','normalized','Position',[.22 .75 .20 .1],'Value',1,'Callback',@(s,e) PCADerivsCheckboxCallback); 
       
        handles.PCADerivRegCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','regularized deriv.','Units','normalized','Position',[.22 .65 .20 .1],'Value',options.PCADerivReg,'Callback',@(s,e) PCADerivRegCallback); 
        
        handles.PCAPreSmoothCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','pre-smooth wdw','Units','normalized','Position',[.22 .55 .20 .1],'Value',0,'Callback',@(s,e) PCAPreSmoothCheckboxCallback);
        handles.PCAPreSmoothEdit=uicontrol('Parent',handles.uipanel,'Style','edit','Units','normalized','Position',[.38 .55 .04 .14],'String',num2str(options.preSmoothingWindow),'Enable','off','Callback',@(s,e) PCAPreSmoothEditCallback);
      
        handles.PCAPreNormText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.035 .60 .15 .1],'String','normalization','HorizontalAlignment','left');
        handles.PCAPreNormPopup=uicontrol('Parent',handles.uipanel,'Style','popup','String',PCAPreNormalizationTypes,'Units','normalized','Position',[.01 .50 .20 .1],'Value',2,'Callback',@(s,e) PCAPreNormPopupCallback); 
         
         
        handles.oPCAText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.445 .85 .20 .1],'String','OPCA numShifts','HorizontalAlignment','left');
        handles.oPCACheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','Units','normalized','Position',[.42 .85 .20 .1],'Value',0,'Callback',@(s,e) OPCACheckboxCallback);
        handles.oPCAEdit=uicontrol('Parent',handles.uipanel,'Style','edit','Units','normalized','Position',[.56 .85 .04 .14],'String',num2str(25),'Enable','off','Callback',@(s,e) OPCANumShiftsEditCallback);

        handles.PCAdropBottomTracesText=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.445 .73 .20 .1],'String','drop low-rms traces','HorizontalAlignment','left');
        handles.PCAdropBottomTracesCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','Units','normalized','Position',[.42 .73 .20 .1],'Value',0,'Callback',@(s,e) PCADropBottomTracesCheckboxCallback);
        
        handles.PCAdropBottomTracesEdit=uicontrol('Parent',handles.uipanel,'Style','edit','Units','normalized','Position',[.58 .73 .04 .14],'String',num2str(0),'Enable','off','Callback',@(s,e) PCADropBottomTracesEditCallback);
        handles.PCAdropBottomTracesText2=uicontrol('Parent',handles.uipanel,'Style','text','Units','normalized','Position',[.62 .73 .20 .1],'String',['/' num2str(size(traces{1},2))],'HorizontalAlignment','left');

        handles.PCAPostSmoothCheckbox=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','post-smoothing wdw','Units','normalized','Position',[.42 .63 .20 .1],'Value',1,'Callback',@(s,e) PCAPostSmoothCheckboxCallback);
        handles.PCAPostSmoothEdit=uicontrol('Parent',handles.uipanel,'Style','edit','Units','normalized','Position',[.58 .63 .04 .14],'String',num2str(options.smoothingWindow),'Enable','on','Callback',@(s,e) PCAPostSmoothEditCallback);
        
        handles.ExcludePCCheckbox(1)=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','drop PC1','Units','normalized','Position',[.7 .86 .20 .1],'Value',0,'Callback',@(s,e) ExcludePCCheckboxCallback);
        handles.ExcludePCCheckbox(2)=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','drop PC2','Units','normalized','Position',[.7 .76 .20 .1],'Value',0,'Callback',@(s,e) ExcludePCCheckboxCallback);
        handles.ExcludePCCheckbox(3)=uicontrol('Parent',handles.uipanel,'Style','checkbox','String','drop PC3','Units','normalized','Position',[.7 .66 .20 .1],'Value',0,'Callback',@(s,e) ExcludePCCheckboxCallback);

        handles.PCASaveData=uicontrol('Parent',handles.uipanel,'Style','pushbutton','Units','normalized','Position',[.72 .03 .13 .16],'String','Save Data','Callback',@(s,e) PCASaveDataCallback);
        handles.PCAMakePDF=uicontrol('Parent',handles.uipanel,'Style','pushbutton','Units','normalized','Position',[.86 .03 .13 .16],'String','Results PDF','Callback',@(s,e) PCAMakePDFCallback);
        DrawPCAResults;
        
    end

    function CrossNormalizeCheckboxCallback
        
        if get(handles.crossNormalizeCheckbox,'Value')
            options.multiTrialPCAOptions.crossNormalizeFlag=true;
        else
            options.multiTrialPCAOptions.crossNormalizeFlag=false;
        end
        RecomputePCAs;
        Update3DPlot;
        Update3DPlotLimits; 
        
    end

    function PostNormalizePCsCheckboxCallback
        
        if get(handles.postNormalizePCsCheckbox,'Value')
            
            
            normFacBaseline=sqrt(sum(trajDataX{1}.^2+trajDataY{1}.^2+trajDataZ{1}.^2));
            
            for d=1:length(activeDatasetFolders)
                
                %rms by axis
%                normFac(1,d)=std(trajDataX{d},1)/std(trajDataX{1},1);              
%                normFac(2,d)=std(trajDataY{d},1)/std(trajDataY{1},1);
%                normFac(3,d)=std(trajDataZ{d},1)/std(trajDataZ{1},1);
%               

%               %max-abs by axis
%               normFac(1,d)=max(abs(trajDataX{d}))/max(abs(trajDataX{1}));              
%               normFac(2,d)=max(abs(trajDataY{d}))/max(abs(trajDataY{1}));
%               normFac(3,d)=max(abs(trajDataZ{d}))/max(abs(trajDataZ{1}));
%               

               %by std of radius 
               normFac(:,d)=sqrt(sum(trajDataX{d}.^2+trajDataY{d}.^2+trajDataZ{d}.^2))/normFacBaseline;              

            end
  
            
        else
            normFac=ones(3,length(activeDatasetFolders));
        end
        
%         if options.plotClusters
%             ComputeClusterMeanTrajectories;
%         end

        Update3DPlot;
        Update3DPlotLimits;
        
    end

    function ExcludePCCheckboxCallback
        
        options.plotPCExclusions=[];
        
        for i=1:3
            if get(handles.ExcludePCCheckbox(i),'Value')
                options.plotPCExclusions=[options.plotPCExclusions i];
            end
        end
        RecomputePCAs;
%ComputeMeanTrajectories;
%copmuteClusterTrajectories;
        Update3DPlot;
        Update3DPlotLimits;
        
    end

    function UpdateGUIPCA
        set(handles.PCAdropBottomTracesText2,'String',['/' num2str(str2double(get(handles.PCAdropBottomTracesEdit,'String'))+size(traces{1},2))]);
        DrawPCAResults;
    end

    function DrawPCAResults
        figure(handles.f2);
        KillHandle('PCAParetoPlotAxes',handles);
        handles.PCAParetoPlotAxes=axes('Position',[0.75,0.31,.2,.18]);
        plotPCAOptions.plotSections={'pareto'};
        plotPCAOptions.savePDFFlag=false;
        plotPCAOptions.plotNumComps=10;
        
        plotPCAOptions.subPlotFlag=true;
        plotPCAOptions.VAFYLim=100;
        
        wbPlotPCA(wbstruct{1},pcaStruct{1},plotPCAOptions);
        
        set(gca,'YTick',[0:10:100]);
        grid on;
        
    end

    function DefaultExclusionsCheckboxCallback
        RecomputePCAs;
        Update3DPlot; 
        Update3DPlotLimits;
    end

    function PCARangeMaskPopupCallback
        
        PCARangeMaskUpdate;
        Update3DPlot; 
        Update3DPlotLimits;
        
    end
        
    function PCARangeMaskUpdate
        
        options.PCARestrictRangeType=PCARestrictRangeOptionList{get(handles.PCARestrictRangePopup,'Value')};
        
        for d=1:numel(activeDatasetFolders)
            
            switch options.PCARestrictRangeType
                case 'all'
                    trajMask{d}=ones(size(tv{d}));
                case 'rise'
                    trajMask{d}=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron)==2;  
                case 'high'
                    trajMask{d}=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron)==3;  
                case 'fall'
                    trajMask{d}=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron)==4;  
                case 'low'
                    trajMask{d}=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron)==1;  
                case 'rise1'                   
                    trajMask{d}= ComputeFullStateColoring(d,6)==5;                    
                case 'rise2'                    
                    trajMask{d}= ComputeFullStateColoring(d,6)==6;
                case 'fall1'                   
                    trajMask{d}= ComputeFullStateColoring(d,6)==7;                   
                case 'fall2'                    
                    trajMask{d}= ComputeFullStateColoring(d,6)==8;
                    
                    
                    
                    
                otherwise
                    trajMask{d}=ones(size(tv{d}));
            end

        end
        
        options.PCARangeMask{d}=trajMask{d};
        
        RecomputePCAs;
        
        for d=1:numel(activeDatasetFolders)
            [trajDataX{d},trajDataY{d},trajDataZ{d}]=GetTrajectoriesFromPCs(d);   
            trajDataX{d}=trajDataX{d}.*trajMask{d};
            trajDataY{d}=trajDataY{d}.*trajMask{d};
            trajDataZ{d}=trajDataZ{d}.*trajMask{d};
            
            trajDataX{d}(trajDataX{d}==0)=nan;
            trajDataY{d}(trajDataY{d}==0)=nan;
            trajDataZ{d}(trajDataZ{d}==0)=nan;
            
            
        end
    end

    function PCADerivsCheckboxCallback
        options.PCADerivReg=get(handles.PCADerivRegCheckbox,'Value');
        RecomputePCAs;
        Update3DPlot; 
        Update3DPlotLimits;
    end

    function PCADerivRegCallback
        RecomputePCAs;
        Update3DPlot; 
        Update3DPlotLimits;
    end

    function PCAPreNormPopupCallback        
        RecomputePCAs;
        Update3DPlot;  
        Update3DPlotLimits;        
    end

    function OPCANumShiftsEditCallback       
        RecomputePCAs;
        Update3DPlot;    
    end

    function OPCACheckboxCallback
        
        if get(gcbo,'Value')
            set(handles.oPCAEdit,'Enable','on');
        else
            set(handles.oPCAEdit,'Enable','off');
        end
        
        RecomputePCAs;
        Update3DPlot; 
        Update3DPlotLimits;
    end

    function PCADropBottomTracesEditCallback
        RecomputePCAs;
        Update3DPlot;    
        Update3DPlotLimits;
    end

    function PCADropBottomTracesCheckboxCallback

        if get(gcbo,'Value')
            set(handles.PCAdropBottomTracesEdit,'Enable','on');
        else
            set(handles.PCAdropBottomTracesEdit,'Enable','off');
        end
        
        RecomputePCAs;
        Update3DPlot;  
        Update3DPlotLimits;
    end

    function PCAPreSmoothEditCallback
        
        options.preSmoothingWindow=str2double(get(handles.PCAPreSmoothEdit,'String'));

        RecomputePCAs;
        Update3DPlot;    
        Update3DPlotLimits;
    end

    function PCAPostSmoothEditCallback
        
        options.smoothingWindow=str2double(get(handles.PCAPostSmoothEdit,'String'));
        RecomputePCAs;
        Update3DPlot;    
        Update3DPlotLimits;
    end

    function PCAPreSmoothCheckboxCallback

        if get(gcbo,'Value')
            set(handles.PCAPreSmoothEdit,'Enable','on');
        else
            set(handles.PCAPreSmoothEdit,'Enable','off');
        end
        
        options.preSmoothFlag=get(handles.PCAPreSmoothCheckbox,'Value');
    
        
        RecomputePCAs;
        Update3DPlot;  
        Update3DPlotLimits;
    end

    function PCAPostSmoothCheckboxCallback

        if get(gcbo,'Value')
            set(handles.PCAPostSmoothEdit,'Enable','on');
        else
            set(handles.PCAPostSmoothEdit,'Enable','off');
        end
        

        options.smoothFlag=get(handles.PCAPostSmoothCheckbox,'Value');
    
        
        RecomputePCAs;
        Update3DPlot;  
        Update3DPlotLimits;
    end

    function neuronSubsetPopupCallback       
        disp(neuronSubsetTypeList{get(gcbo,'Value')});
        neuronSubsetType=neuronSubsetTypeList{get(gcbo,'Value')};
        
        if strcmp(neuronSubsetType,'in common')
            set(handles.crossNormalizeCheckbox,'Enable','on');
        else
            set(handles.crossNormalizeCheckbox,'Enable','off');
        end
     
        RecomputePCAs;
        Draw3DPlot;
        Update3DPlot;     
        Update3DPlotLimits;
        
    end

    function missingCoeffPopupCallback
        
        disp(missingCoeffOptionList{get(gcbo,'Value')});
        
    end

    function SecondDatasetCheckboxCallback
        
        if  get(handles.secondDatasetPopup,'Value')>1
            
            if get(gcbo,'Value')==1

                set(handles.plotLine2,'Visible','on');

            else

                set(handles.plotLine2,'Visible','off');

            end

            Update3DPlot;
            
        end
    end

    function SecondDatasetPopupCallback
        
        if get(gcbo,'Value')>1
            
            secondDataFolder=datasetFolderNames{get(gcbo,'Value')-1};
            secondDataFolderFullPath=datasetFolderNamesFullPath{get(gcbo,'Value')-1};
            activeDatasetFolders={currentFolderFullPath,secondDataFolderFullPath};

            
            LoadDatasets;
            
            DrawRanges;
            UpdateRanges;           
        
            for k=1:length(frame{2})
                thisPlotTimeRange{2}(k,:)=[frame{2}(k) frameEnd{2}(k)];
            end        
 
            RecomputePCAs;
            Draw3DPlot;
            %Draw3DPlotSecondary;
            set(handles.secondDatasetCheckbox,'Value',1);

        else
            
            if isfield(handles,'plotLine2')
                set(handles.plotLine{2},'Visible','off');
            end
            activeDatasetFolders={currentFolderFullPath};

        end

        Update3DPlot;
        
    end

    function AllDatasetsCheckboxCallback
        
        if get(gcbo,'Value')==1
            set(handles.PCAJointCheckbox,'Enable','on');
            multiTrialIsActive=true;
            UpdateMultiTrial;
            set(handles.secondDatasetCheckbox,'Value',1);
            
        else
            set(handles.PCAJointCheckbox,'Enable','off');
            multiTrialIsActive=false;
            if get(handles.secondDatasetCheckbox,'Value')>1
                secondDataFolder=datasetFolderNames{get(handles.secondDatasetPopup,'Value')-1};
                secondDataFolderFullPath=datasetFolderNamesFullPath{get(handles.secondDatasetPopup,'Value')-1};
                activeDatasetFolders={currentFolderFullPath,secondDataFolderFullPath};

            else
                
                activeDatasetFolders={currentFolderFullPath};
                
            end
            Update3DPlot;
        end
    end
           
    function PCAJointCheckboxCallback
        
         options.multiTrialPCAOptions.joint=get(gcbo,'Value');
         RecomputePCAs; 
         Update3DPlot;     
         Update3DPlotLimits;  
         
    end
           
    function RecomputePCAs(plotFlag)
        
        if nargin<1
            plotFlag=false;
        end
        
        
        
        if numel(activeDatasetFolders)>1
            computeOptions=options.multiTrialPCAOptions;
        end
        if options.interactiveMode
            
            if get(handles.PCADefaultExclusionsCheckbox,'Value')==1
                computeOptions.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AVFL','AVFR','ASKL','ASKR','ALA','IL2VR','IL2L'};
            else
                computeOptions.extraExclusionList={'AQR'};
            end
            
            if get(handles.PCADerivsCheckbox,'Value')==1
                computeOptions.derivFlag=true;
            else
                computeOptions.derivFlag=false;
            end

            computeOptions.preNormalizationType=PCAPreNormalizationTypes{get(handles.PCAPreNormPopup,'Value')};
            
            if get(handles.oPCACheckbox,'Value')==1
                computeOptions.dimRedType='OPCA';   %'PCA' or 'OPCA' or 'NMF'
            else
                computeOptions.dimRedType='PCA';   %'PCA' or 'OPCA' or 'NMF'
            end
            
            computeOptions.numOffsetSteps=str2double(get(handles.oPCAEdit,'String'));  %only used for OPCA
            computeOptions.numComponentsToDrop=str2double(get(handles.PCAdropBottomTracesEdit,'String'));  %only used when dropping low rms traces
       
        end
     
        neuronSubsetType=neuronSubsetTypeList{get(handles.PCAneuronSubsetPopup,'Value')};
                                                                
        if strcmp(neuronSubsetType,'all')
            computeOptions.neuronSubset=[];
        elseif strcmp(neuronSubsetType,'labeled only')
            computeOptions.neuronSubset=wbListIDs;
        else %3  'in common'       
            computeOptions.neuronSubset=wbListIDsInCommon(wbstruct);
        end
               
        computeOptions.fieldName=options.fieldName;
        computeOptions.preSmoothFlag=options.preSmoothFlag;         
        computeOptions.preSmoothingWindow=options.preSmoothingWindow;        
        computeOptions.derivRegFlag=options.PCADerivReg;               
        computeOptions.usePrecomputedDerivs=true;
        computeOptions.saveFlag=false;  
        computeOptions.plotFlag=plotFlag;
        computeOptions.refNeuron=options.refNeuron;
        

        if ~options.multiTrialPCAOptions.joint
                       
            for d=1:length(activeDatasetFolders)
                
                if isfield(options,'PCARangeMask')
                    computeOptions.rangeMask=options.PCARangeMask{d};
                end
                
                pcaStruct{d}=wbComputePCA(wbstruct{d},computeOptions);
                
                pcs{d}=pcaStruct{d}.pcs;
                coeffs{d}=pcaStruct{d}.coeffs;              
                traces{d}=pcaStruct{d}.traces;
                traces_rms{d}=rms(pcaStruct{d}.traces);
                neuronIDs{d}=pcaStruct{d}.neuronIDs;
            end
            base('pcRerun',pcaStruct);
            coeffsRef=coeffs{1};
            neuronIDsRef=neuronIDs{1};
            
        else  %jointPCA
            
            
            computeOptions.joint=true;
            computeOptions.derivFlag=true;  %hack
            computeOptions.plotFlag=true;
            cf=gcf;
            pcaStructJoint=wbComputePCAJoint(activeDatasetFolders,computeOptions);
            coeffsRef=pcaStructJoint.coeffs;
            neuronIDsRef=pcaStructJoint.neuronIDs;
            

            figure(cf);

        end
        
        %compute rms avg values for cross-normalization
        if strcmp(neuronSubsetType,'in common');
            
            for d=1:length(activeDatasetFolders)
        
                        
                    if d==1
                        traces_rms_avg=traces_rms{1};
                    else
                        traces_rms_avg=traces_rms_avg+traces_rms{d};
                    end
            end
            traces_rms_avg=traces_rms_avg/length(activeDatasetFolders);

        end
        
        for d=1:length(activeDatasetFolders)
            if isfield(options,'plotPCExclusions')
                
                [trajDataX{d},trajDataY{d},trajDataZ{d}]=GetTrajectoriesFromPCs(d,options.plotPCExclusions);
            else
                [trajDataX{d},trajDataY{d},trajDataZ{d}]=GetTrajectoriesFromPCs(d);

            end
            
            if ~isempty(timeColoring{d})
                trajDataC{d}=timeColoring{d};
            else
                trajDataC{d}=ones(size(trajDataX{d}));
            end

        end       
        
        ComputeTrajectories;
        
        if options.plotClusters
            ComputeClusterMeanTrajectories;
        end
        
        if options.interactiveMode
            UpdateGUIPCA;
        end
 
    end

    function PCASaveDataCallback
         
        save('PCASaveData','pcaStruct','pcaStructJoint');
        disp('wbPhasePlot3D> PCASaveData saved.');
    end

    function PCAMakePDFCallback
               
        RecomputePCAs(true);
        
    end

%% Assorted

    function [thisDataX,thisDataY,thisDataZ]=GetTrajectoriesFromPCs(pcSetNum,pcExclusions)
        %called by RecomputePCAs and Draw3DPlot
        
        if nargin<2
            pcExclusions=[];
        end
        
        PCsToUse=1:6;
        PCsToUse(pcExclusions)=[];
        PCsToUse=PCsToUse(1:3);
        
        if nargin<1
            pcSetNum=1;
        end
            
        if options.projectOntoFirstSpace
            
            thesePCs=zeros(size(pcs{pcSetNum},1),3);

            for nc=1:3
                for cc=1:size(coeffs{pcSetNum},1);

                    origIndex=find(strcmpi(neuronIDsRef,neuronIDs{pcSetNum}{cc}),1);

                    %this is a relaxation class
                    if isempty(origIndex) && length(neuronIDs{pcSetNum}{cc})>3
                        origIndex=find(strncmpi(neuronIDsRef,neuronIDs{pcSetNum}{cc},3),1);
                        if isscalar(origIndex)
                            
                            disp(['map ' neuronIDsRef{origIndex} '-> ' neuronIDs{pcSetNum}{cc}]);
                        end
                    end
                    

                    
                    if ~isempty(origIndex)                
                        
                        if options.multiTrialPCAOptions.crossNormalizeFlag && strcmp(neuronSubsetType,'in common')
                            
                           thesePCs(:,nc)=thesePCs(:,nc)+coeffsRef(origIndex,PCsToUse(nc))*traces{pcSetNum}(:,cc)/traces_rms{pcSetNum}(cc)*traces_rms_avg(origIndex);
                        else
                           thesePCs(:,nc)=thesePCs(:,nc)+coeffsRef(origIndex,PCsToUse(nc))*traces{pcSetNum}(:,cc);

                        end

                    end
                    
                end

            end
    

            %debug plots
%             cf=gcf;
%             figure;            
%             for cc=1:size(coeffs{pcSetNum},1);
%                 origIndex=find(strcmpi(neuronIDs{1},neuronIDs{pcSetNum}{cc}));
%                 if isempty(origIndex) && length(neuronIDs{pcSetNum}{cc})>3
%                         origIndex=find(strncmpi(neuronIDs{1},neuronIDs{pcSetNum}{cc},length(neuronIDs{pcSetNum}{cc})-1),1);
%                 end
%                 subtightplot(ceil(sqrt(size(coeffs{pcSetNum},1))),ceil(sqrt(size(coeffs{pcSetNum},1))),cc)
%                 plot(traces{pcSetNum}(:,cc),'b');
%                 hold on;
%                 plot(traces{1}(:,origIndex),'r--');
%                 plot(traces{pcSetNum}(:,cc)/rms(traces{pcSetNum}(:,cc))*rms(traces{1}(:,origIndex)),'g--');
%                 if ~isempty(origIndex)
%                     textul(neuronIDs{1}{origIndex},8,'r');
%                 else
%                     textul('XXX',8,'r');
%                 end
%                 textur(neuronIDs{pcSetNum}{cc},[],8,'b');
%             end
%             figure(cf);
            
        else
             thesePCs=pcs{pcSetNum}(:,PCsToUse(1:3));
        end

        %apply smoothing
        if options.smoothFlag
            thesePCs=fastsmooth(thesePCs,options.smoothingWindow,3,1);
        end

        thisDataX=thesePCs(:,1);
        thisDataY=thesePCs(:,2);
        thisDataZ=thesePCs(:,3);                     


    end

    function UpdateMultiTrial
        
        
        %dataset 1 is always current folder.  then others are in order
        %of listfolders.

        activeDatasetFolders=[activeDatasetFolders, datasetFolderNamesFullPath];
        activeDatasetFolders=unique(activeDatasetFolders,'stable');
        datasetsLoadedLogical=[datasetsLoadedLogical false(1,numel(datasetFolderNamesFullPath))];

        
        for i=1:numel(activeDatasetFolders)
            datasetDiskOrder(i)=find(strcmp(datasetFolderNamesFullPath,activeDatasetFolders{i}));
        end

        LoadDatasets;

        if options.interactiveMode
            DrawRanges;
            UpdateRanges;
        else
            ComputeRanges;
        end     


        for d=1:length(activeDatasetFolders)
            for k=1:length(frame{d})
                thisPlotTimeRange{d}(k,:)=[frame{d}(k) frameEnd{d}(k)];
            end        
        end
   

        %compute PCARangeMasks
        PCARangeMaskUpdate;

        RecomputePCAs;  %incl. compute trajectories

        ComputeTimeColoringOverlay;
        
        
        if options.plotClusters
            ComputeClusterMeanTrajectories;
        end


%        if options.interactiveMode
            Draw3DPlot;
%            Draw3DPlotSecondary;
%        end

        


        if ~exist('sT','var')
            sT=1;
            eT=length(tv{1});
        end
        
        if options.interactiveMode
            
            Update3DPlot;
            
        end
        
    end

    function GenTubesButtonCallback
        
        disp('generating tubes.');
        
        if get(gcbo,'Value')==1
            
            set(handles.genTubesButton,'String',genTubesButtonLabels{2});
            set(handles.genTubesButton,'ForegroundColor',[1 0 0]);
            
            set(handles.playButton,'Value',1);
            set(handles.playButton,'String',playButtonLabels{2});
            set(handles.playButton,'ForegroundColor',[0 1 0]);
            
            PlayButtonCallback(true,false,true,false);
            
            set(handles.genTubesButton,'String',genTubesButtonLabels{1});
            set(handles.genTubesButton,'ForegroundColor','k');

            disp('gen tubes done.');
            %MacOSNotify('PhasePlot3D Gen Tubes done.','wbPhasePlot3D','','Submarine');
            
        end
        
    end

    function GenMeanTrajButtonCallback
        
        disp('generating mean trajectories.');
        
        if get(gcbo,'Value')==1
            
            set(handles.genMeanTrajButton,'String',genMeanTrajButtonLabels{2});
            set(handles.genMeanTrajButton,'ForegroundColor',[1 0 0]);
            
            set(handles.playButton,'Value',1);
            set(handles.playButton,'String',playButtonLabels{2});
            set(handles.playButton,'ForegroundColor',[0 1 0]);
            
            PlayButtonCallback(true,false,false,true);
            
            set(handles.genTubesButton,'String',genMeanTrajButtonLabels{1});
            set(handles.genTubesButton,'ForegroundColor','k');

            disp('gen mean trajectories done.');
            MacOSNotify('PhasePlot3D Gen Mean Trajectories done.','wbPhasePlot3D','','Submarine');
            
        end
        
    end

    function PlayButtonCallback(loopFlag,recordingFlag,genTubesFlag,genMeanTrajFlag)
        
        if nargin<1
            loopFlag=true;
        end
        
        if nargin<2
            recordingFlag=false;
        end
        
        if nargin<3
            genTubesFlag=false;
        end
        
        if nargin<4
            genMeanTrajFlag=false;
        end
        
        startingTime=get(handles.timeSlider1,'Value');
        endTime=get(handles.timeSlider2,'Value');
        
        set(handles.timeSlider2,'Value',startingTime);

        %turn off in-viewer GUI
        set(handles.whitebgCheckbox,'Visible','off');
        set(handles.fixLimitsCheckbox,'Visible','off');
        set(handles.endBallSizeText,'Visible','off');
        set(handles.endBallSizePopup,'Visible','off');
        set(handles.overlayBallSizeText,'Visible','off');
        set(handles.overlayBallSizePopup,'Visible','off');
        set(handles.riseNumbersCheckbox,'Visible','off');
        set(handles.fallNumbersCheckbox,'Visible','off');
        set(handles.startBallsCheckbox,'Visible','off');
        set(handles.endBallsCheckbox,'Visible','off');     
        
        set(handles.trajName1,'Visible','off');
        
        while get(handles.playButton,'Value')==1   %animation loop
            
            set(handles.playButton,'String',playButtonLabels{2});
            set(handles.playButton,'ForegroundColor',[0 1 0]);
            currentTime=get(handles.timeSlider2,'Value');

            Update3DPlot;
            drawnow;
            
            if currentTime+options.playSpeed <= endTime
                set(handles.timeSlider2,'Value',currentTime + options.playSpeed);              
            else
                if ~loopFlag
                   set(handles.playButton,'Value',0);
                   set(handles.timeSlider2,'Value',endTime);
                else
                    
                   if genTubesFlag || genMeanTrajFlag
                       set(handles.playButton,'Value',0);
                       set(handles.timeSlider2,'Value',endTime);    
                       if genTubesFlag
                           GenerateTriTubes('b');
                       end
                       if genMeanTrajFlag
                           GenerateMeanTraj;
                       end
                   else
                       set(handles.timeSlider2,'Value',startingTime);
                   end
                   
                   
                   
                end
            end
            
            UpdateRanges;
                        
            if recordingFlag && get(handles.playButton,'Value')==1
                
               %write out video frame              
               framestruct=im2frame(png_cdata(handles.fig3D),jet(256));
               writeVideo(videoOutObj,framestruct.cdata);

            end

            
        end
        
        %turn on in-viewer GUI
%         set(handles.whitebgCheckbox,'Visible','on');
%         set(handles.fixLimitsCheckbox,'Visible','on');
%         set(handles.endBallSizeText,'Visible','on');
%         set(handles.endBallSizePopup,'Visible','on');
%         set(handles.overlayBallSizeText,'Visible','on');
%         set(handles.overlayBallSizePopup,'Visible','on');
%         set(handles.riseNumbersCheckbox,'Visible','on');
%         set(handles.fallNumbersCheckbox,'Visible','on');
%         set(handles.startBallsCheckbox,'Visible','on');
%         set(handles.endBallsCheckbox,'Visible','on');   
%         
        set(handles.playButton,'String',playButtonLabels{1});
        set(handles.playButton,'ForegroundColor','k');
        
    end

    function RecordButtonCallback
        
        if get(gcbo,'Value')==1
            
            set(handles.recordButton,'String',recordButtonLabels{2});
            set(handles.recordButton,'ForegroundColor',[1 0 0]);

            thisview=get(gca,'View');
            viewstr=['(' num2str(thisview(1)) '-' num2str(thisview(2)) ')'];
            
            %open video file
            movieOutName=[options.outputDirectory filesep 'PhasePlot3D-' wbMakeShortTrialname(wbstruct{1}.trialname) '.mp4'];
            if options.playSpeed>1
                movieOutName=[movieOutName(1:end-4) '-' num2str(options.playSpeed) 'x-view' viewstr '.mp4'];
            end
            SetupOutputMovie(movieOutName); %local function

            set(handles.playButton,'Value',1);

            %play movie, no loop, recording on
            PlayButtonCallback(false,true);

            %close video file
            close(videoOutObj);
            
            %restore button state
            set(handles.recordButton,'String',recordButtonLabels{1});
            set(handles.recordButton,'ForegroundColor','k');

            disp('movie done.');
            MacOSNotify('PhasePlot3D movie recorded.','wbPhasePlot3D','','Submarine');
            
        else  %stop recording prematurely
            
            %close Movie
            close(videoOutObj); 

        end
        
    end

    function PlaySpeedPopupCallback
        
        options.playSpeed=2^(get(gcbo,'Value')-1);
        
    end

    function SetupOutputMovie(movieOutName)
            %create movie object for saving
            videoOutObj=VideoWriter(movieOutName,'MPEG-4');
            videoOutObj.FrameRate=options.frameRate;
            videoOutObj.Quality=options.outputMovieQuality;
            open(videoOutObj);
    end

    function cdata = png_cdata(hfig)
        % Get CDATA from hardcopy using opengl
        % Need to have PaperPositionMode be auto 
        orig_mode = get(hfig, 'PaperPositionMode');
        set(hfig, 'PaperPositionMode', 'auto');
        cdata = hardcopy(hfig, '-Dopengl', '-r0');
        % Restore figure to original state
        set(hfig, 'PaperPositionMode', orig_mode);
    end

    function SavePDFButtonCallback
        
        thisview=round(get(handles.plot3D(1),'View'));
        disp(['3D view: ' num2str(thisview(1)) '  ' num2str(thisview(2))]);
        viewstr=['(' num2str(thisview(1)) '-' num2str(thisview(2)) ')'];
        
        if multiTrialIsActive
            
            if options.multiTrialPCAOptions.joint
                outputFilename=[options.outputDirectory filesep 'pca-MultiTrial-jointEV-phaseplots' flagstr '-' colorByOptions{get(handles.colorByPopup,'Value')} '-view' viewstr '.pdf'];     
            else
                outputFilename=[options.outputDirectory filesep 'pca-MultiTrial-' wbMakeShortTrialname(wbstruct{1}.trialname) 'EV-phaseplots' flagstr '-' colorByOptions{get(handles.colorByPopup,'Value')} '-view' viewstr '.pdf'];     
            end
            
        else
            outputFilename=[options.outputDirectory filesep 'pca-' wbMakeShortTrialname(wbstruct{1}.trialname) '-phaseplots' flagstr '-' colorByOptions{get(handles.colorByPopup,'Value')} '-view' viewstr '.pdf'];     
        end
        
        
        currentBC=get(handles.fig3D,'Color');
        if get(handles.whitebgCheckbox,'Value')
            set(handles.fig3D,'Color','w');
        end
       export_fig(outputFilename,'-painters',handles.plot3D(1));

        set(handles.fig3D,'Color',currentBC);
        disp(['saved:' outputFilename]);
    end

    function TrajectoryTypeCallback
        
        options.trajType=trajTypes{get(gcbo,'Value')};
        
        if get(gcbo,'Value')==1  %single
            
            set(handles.rangeTypePopup,'Enable','off');
            
            %translucent highlight rect
            set(handles.highlightRect,'Visible','on');
            
%             set(handles.timeBall(2:end),'Visible','off');
%             set(handles.timeBall2(2:end),'Visible','off');
            
            set(handles.showConvHullCheckbox,'Enable','off');
            set(handles.splitConvHullCheckbox,'Enable','off');
            
            set(handles.convexHull3D,'Visible','off');
            
%             set(handles.plotLine1(2:end),'Visible','off'); 
            
            
            if ~isfield(handles,'FTRedline');
                DrawRanges;
            end
          
        else
            
            set(handles.rangeTypePopup,'Enable','on');

            
            set(handles.highlightRect,'Visible','off');

%             set(handles.timeBall{d}(2:end),'Visible','on');
%             set(handles.timeBall2{d}(2:end),'Visible','on');
            
            set(handles.showConvHullCheckbox,'Enable','on');

            set(handles.splitConvHullCheckbox,'Enable','on');
            
            if convHullIsActive
                set(handles.convexHull3D,'Visible','on');
            end
            
%             set(handles.plotLine1(2:end),'Visible','on'); 

        end
        ComputeTrajectories;
        
        UpdateRangeMode(options.multiTrajectoryRangeMode);
        
        DrawRanges;
        UpdateRanges;
        
        Draw3DPlot;
        Update3DPlot;
        
    end

    function RangeTypesCallback
               
        options.multiTrajectoryRangeMode=multiTrajectoryRangeModes{get(handles.rangeTypePopup,'Value')};
        
options.multiTrajectoryRangeMode
        
        UpdateRangeMode(options.multiTrajectoryRangeMode);
              
        if options.plotClusters
            ComputeClusterMeanTrajectories;
        end    
        
        DrawRanges;
        UpdateRanges;
        
        Draw3DPlot;
        Update3DPlot;

    end
    
    function UpdateRangeMode(multiTrajectoryRangeMode)
        
        if strcmpi(multiTrajectoryRangeMode,'rise-to-rise')

            transitions=transitionsRise;
            
            transitionsMat=transitionsFallMat;           
                
            TWFrames=TWRiseFrames;
            
            mTrajDataX=mTrajFallDataX;
            mTrajDataY=mTrajFallDataY;
            mTrajDataZ=mTrajFallDataZ;
            mTrajDataC=mTrajFallDataC;

            canonicalTimes=[0 .25 .5 .75 1.0];
            
%             if isfield(handles,'riseTransitionNumbers')
%                 ShowRiseNumbersCheckboxCallback(false);
%                 ShowFallNumbersCheckboxCallback(true);
%             end
            
        elseif strcmpi(multiTrajectoryRangeMode,'fall-to-fall')

            transitions=transitionsFall;
            
            transitionsMat=transitionsRiseMat;

            TWFrames=TWFallFrames;
            
            mTrajDataX=mTrajRiseDataX;
            mTrajDataY=mTrajRiseDataY;
            mTrajDataZ=mTrajRiseDataZ;
            mTrajDataC=mTrajRiseDataC;
            
            canonicalTimes=[0 .25 .5 .75 1.0];
            
            ShowRiseNumbersCheckboxCallback(true);
            ShowFallNumbersCheckboxCallback(false);
            
%             if isfield(handles,'riseTransitionNumbers')
%                 ShowRiseNumbersCheckboxCallback(false);
%                 ShowFallNumbersCheckboxCallback(true);
%             end
%             
            
            
        elseif strcmpi(multiTrajectoryRangeMode,'trough-to-trough')
            
            transitionsMat=transitionsT2TMat;
            
            TWFrames=TWT2TFrames;
            
            mTrajDataX=mTrajT2TDataX;
            mTrajDataY=mTrajT2TDataY;
            mTrajDataZ=mTrajT2TDataZ;
            mTrajDataC=mTrajT2TDataC;
            
            canonicalTimes=[0 .125 .375 .625 .875 1.0];

            
        end

        maxRange=max(transitionsMat{1}(:,end)-transitionsMat{1}(:,1));


        
    end
   
    function NeuronCallback(neuron)
        if get(gcbo,'Value')==1
            
            
            neuronListNum(neuron)=0;  %signifies blank
            set(handles.neuronCheckbox(neuron),'Value',0);
            set(handles.neuronCheckbox(neuron),'Enable','off');
        else
            set(handles.neuronCheckbox(neuron),'Enable','on');
            neuronListNum(neuron)=get(gcbo,'Value');
            for d=1:length(activeDatasetFolders)
                thisNeuron=neuronList{neuronListNum(neuron)};
                if isnan(wbgettrace(thisNeuron,wbstruct{d}))
                    thisNeuron=thisNeuron(1:end-1);
                end
                
                if isnan(wbgettrace(thisNeuron,wbstruct{d}))
                    options.timeColoringOverlay{d}(:,neuron)=zeros(size(tv{d}));
                else
                    options.timeColoringOverlay{d}(:,neuron)=(wbFourStateTraceAnalysis(wbstruct{d},'useSaved',thisNeuron)==overlayNeuronState(neuron));  %2 is "rise state"
                end
            end
        end
        UpdateTraces;
        %DrawOverlayBalls;
        UpdateOverlayBalls;
        
    end

    function NeuronCheckboxCallback(neuron)
        
        if ~isfield(handles,'timeColoringOverlay')
            DrawOverlayBalls;
        end
        %else
            if get(gcbo,'Value')
               for d=1:length(activeDatasetFolders)
                 set(handles.timeColoringOverlay{d}(neuron),'Visible','on');
               end
            else
               for d=1:length(activeDatasetFolders)
                 set(handles.timeColoringOverlay{d}(neuron),'Visible','off');
               end
            end
       % end
                
    end

    function NeuronStateCallback(neuron)
        
        overlayNeuronState(neuron)=get(gcbo,'Value');
        for d=1:length(activeDatasetFolders)
           options.timeColoringOverlay{d}(:,neuron)=(wbFourStateTraceAnalysis(wbstruct{d},'useSaved',neuronList{neuronListNum(neuron)})==overlayNeuronState(neuron));  %2 is "rise state"
        end
        %DrawOverlayBalls;
        UpdateOverlayBalls;
                
    end

%% ON-figure GUI Callbacks

    function WhitebgCheckboxCallback
        
        if get(gcbo,'Value')
            whitebg(handles.fig3D,'white');

        else

            whitebg(handles.fig3D,'black');
            
        end
        
        for k=1:length(handles.riseTransitionNumbers)
           if handles.riseTransitionNumbers(k)>0
              set(handles.riseTransitionNumbers(k),'Color','r');
           end            
        end
        for k=1:length(handles.fallTransitionNumbers)
           if handles.fallTransitionNumbers(k)>0
              set(handles.fallTransitionNumbers(k),'Color','b');
           end
        end
        
    end

    function FixLimitsCheckboxCallback
        
        if get(gcbo,'Value')==1
            set(handles.plot3D(1),'XLimMode','manual');
            set(handles.plot3D(1),'YLimMode','manual');
            set(handles.plot3D(1),'ZLimMode','manual');
        else
            set(handles.plot3D(1),'XLimMode','auto');
            set(handles.plot3D(1),'YLimMode','auto');
            set(handles.plot3D(1),'ZLimMode','auto');
        end
                   
    end

    function ShowRiseNumbersCheckboxCallback(forceValue)
        
        if nargin<1
            forceValue=get(gcbo,'Value');
        end
        currentRiseNumbersVisibility=forceValue;
        UpdateVisibility('riseTransitionNumbers',forceValue);
        
    end

    function ShowFallNumbersCheckboxCallback(forceValue)
        
        if nargin<1
            forceValue=get(gcbo,'Value');
        end
        currentFallNumbersVisibility=forceValue;
        UpdateVisibility('fallTransitionNumbers',forceValue);
        
    end

    function ShowStartBallsCheckboxCallback(forceValue)
        
        if nargin<1
            forceValue=get(gcbo,'Value');
        end
        
        showStartBallsState=forceValue;
        
        for d=1:length(activeDatasetFolders)
            UpdateVisibility('timeBall',showStartBallsState,d);
        end       

    end

    function ShowEndBallsCheckboxCallback(forceValue)
        
        if nargin<1
            forceValue=get(gcbo,'Value');
        end
        
        showEndBallsState=forceValue;
        
        for d=1:length(activeDatasetFolders)
            UpdateVisibility('timeBall2',showEndBallsState,d);
        end
       
        
    end

    function OverlayBallSizePopupCallback
        
        options.overlayBallSize=overlayBallSizes(get(gcbo,'Value'));
        for d=1:length(activeDatasetFolders)
            set(handles.timeColoringOverlay{d},'MarkerSize',options.overlayBallSize);
        end
        
    end

    function EndBallSizePopupCallback
        
        options.endBallSize=endBallSizes(get(gcbo,'Value'));

        
        for d=1:length(activeDatasetFolders)
                set(handles.timeBall{d},'MarkerSize',options.endBallSize);
                set(handles.timeBall2{d},'MarkerSize',options.endBallSize);
        end
        
    end

%% Trajectory Callbacks

    function ShowTrajectoryCheckboxCallback

        if get(gcbo,'Value')
            set(handles.plotLine1,'Visible','on');
            trajectoryIsActive=true;
        else
            set(handles.plotLine1,'Visible','off');
            trajectoryIsActive=false;
        end
    end

    function ShowMeanTrajectoryCheckboxCallback
        
        if get(gcbo,'Value')
            
            if ~isfield(handles,'meantrajPlotLine')           
                 DrawMeanTrajectories;
            end
            
            set(handles.meanTrajPlotLine,'Visible','on');
            meanTrajIsActive=true;

        else
            set(handles.meanTrajPlotLine,'Visible','off');
            meanTrajIsActive=false;
        end
        
    end

    function ShowMergedClusterTrajCheckboxCallback
        
        if get(gcbo,'Value')
            
            if ~isfield(handles,'mergedClusterTraj')
                options.plotClusters=true;
                LoadClustering;
                DrawMergedClusterTrajectory;
                Update3DPlot;
            end
            set(handles.mergedClusterTraj,'Visible','on');            
            mergedClusterTrajIsActive=true;
            
        else                       
            set(handles.mergedClusterTraj,'Visible','off');
            mergedClusterTrajIsActive=false;
        end
        
    end

    function ShowRiseClusterTrajCheckboxCallback
        
        if get(gcbo,'Value')
            
            if ~isfield(handles,'riseClusterTraj')
                options.plotClusters=true;
                LoadClustering;
                DrawClusterTrajectory(1);
                DrawPlane;
                DrawTrajPlane2D;
                Update3DPlot;
            end
            set(handles.riseClusterTraj,'Visible','on');            
            riseClusterTrajIsActive=true;
            
        else
                        
            set(handles.riseClusterTraj,'Visible','off');
            riseClusterTrajIsActive=false;
        end
        
    end

    function ShowFallClusterTrajCheckboxCallback
        
        if get(gcbo,'Value')
            
            if ~isfield(handles,'fallClusterTraj')
                options.plotClusters=true;
                LoadClustering;
                DrawClusterTrajectory(2);
                DrawPlane;
                DrawTrajPlane2D;               
                Update3DPlot;
            end
                        
            set(handles.fallClusterTraj,'Visible','on');
            
            set(handles.fallSliderText,'Visible','on');
            set(handles.timeSlider3,'Visible','on');
            set(handles.timeSlider4,'Visible','on');
                      
            fallClusterTrajIsActive=true;
            
        else
            
            set(handles.fallClusterTraj,'Visible','off');
            
            set(handles.fallSliderText,'Visible','off');
            set(handles.timeSlider3,'Visible','off');
            set(handles.timeSlider4,'Visible','off');
            
            fallClusterTrajIsActive=false;
        end
        
    end

    function FallClusterRangeOverrideCheckboxCallback
        
        if get(gcbo,'Value')
            fallClusterRangeOverrideIsActive=true;
        else
            fallClusterRangeOverrideIsActive=false;
        end
        
        Update3DPlot;
        
    end

    function ShowGhostTrajectoryCheckboxCallback(forceValue)
        
        if nargin<1
            forceValue=get(gcbo,'Value');
        end
        
        if forceValue          
            set(handles.ghostTrajectory,'Visible','on');
            options.plotGhostTrajectory=true;

        else
            set(handles.ghostTrajectory,'Visible','off');
            options.plotGhostTrajectory=false;

        end
              
    end

    function ShowPlaneCheckboxCallback
        

        if get(gcbo,'Value')
            
           
            
            set(handles.trajPlane,'Visible','on');
            trajPlaneIsActive=true;
            set(handles.trajPlane2DAxis,'Visible','on');
            set(handles.trajPlane2DPlot,'Visible','on');
            set(handles.trajPlane2DPlotEx,'Visible','on');
            set(handles.trajPlane2DFixLimitsCheckbox,'Visible','on');
            set(handles.planeNormal,'Visible','on');
            set(handles.planeCenter,'Visible','on');
            set(handles.trajPlaneEllipse,'Visible','on');
            set(handles.backProjPts,'Visible','on');
            set(handles.trajPlane2DEllipse,'Visible','on');
            set(handles.projectedPts,'Visible','on');
            set(handles.currentPts,'Visible','on');



            
        else
            
            set(handles.trajPlane,'Visible','off');
            trajPlaneIsActive=false;
            set(handles.trajPlane2DAxis,'Visible','off');
            set(handles.trajPlane2DPlot,'Visible','off');
            set(handles.trajPlane2DPlotEx,'Visible','off');
            set(handles.trajPlane2DFixLimitsCheckbox,'Visible','off');
            set(handles.trajPlane2DFixLimitsCheckbox,'Visible','off');
            set(handles.planeNormal,'Visible','off');
            set(handles.planeCenter,'Visible','off');
            set(handles.trajPlaneEllipse,'Visible','off');
            set(handles.backProjPts,'Visible','off');
            set(handles.trajPlane2DEllipse,'Visible','off');         
            set(handles.projectedPts,'Visible','off');
            set(handles.currentPts,'Visible','off');
            
        end
        
        Update3DPlot;
        
    end

    function CropPlaneCheckboxCallback
        
        if get(gcbo,'Value')
            cropPlaneIsActive=true;
        else
            cropPlaneIsActive=false;
        end
        
        Update3DPlot;

    end

    function ShowTubesCheckboxCallback
        
        if get(gcbo,'Value')
           tubesIsActive=true;
        else
           tubesIsActive=false;
        end
    end

    function trajPlane2DFixLimitsCallback
        
        if get(gcbo,'Value')==1
            set(handles.trajPlane2DAxis,'XLimMode','manual');
            set(handles.trajPlane2DAxis,'YLimMode','manual');
        else
            set(handles.trajPlane2DAxis,'XLimMode','auto');
            set(handles.trajPlane2DAxis,'YLimMode','auto');
            axis(handles.trajPlane2DAxis,'equal');
        end
    end 

    function DrawTrajPlane2D
        
        handles=KillHandle('trajPlane2DPlot',handles);
        handles=KillHandle('trajPlane2DPlotEx',handles);
        handles=KillHandle('trajPlane2DPrincipalAxes1',handles);
        handles=KillHandle('trajPlane2DPrincipalAxes2',handles);
        handles=KillHandle('trajPlane2DEllipse',handles);
        handles=KillHandle('trajPlane2DAxis',handles);

        figure(handles.f2);
        handles.trajPlane2DAxis=axes('Position',[0.04,0.32,.2,.2],'Visible','on');
        xlim([-.4 .4]);ylim([-.4 .4]);
        hold on;
        handles.trajPlane2DPlotEx=ex(0,0,8,'r');
        
        if options.plotClusters
            disp('DrawTrajPlane2D> options.plotClusters true')
            if ~isempty(clusterRiseStruct{1})
                for nc=1:clusterRiseStruct{1}.options.maxClusters
                    handles.trajPlane2DPlot(nc)=scatter([.1 .2],[.1 .2],24,'o','filled','Visible','on');
                    handles.trajPlane2DPrincipalAxes1(nc)=line([0 0],[0 0],'Color','r');
                    handles.trajPlane2DPrincipalAxes2(nc)=line([0 0],[0 0],'Color','b');
                    handles.trajPlane2DEllipse(nc)=plot(0,0,'g');
                end
            end

        else
            
            handles.trajPlane2DPlot=scatter([.1 .2],[.1 .2],24,'o','filled','Visible','on');
            handles.trajPlane2DPrincipalAxes1=line([0 0],[0 0],'Color','r');
            handles.trajPlane2DPrincipalAxes2=line([0 0],[0 0],'Color','b');
            handles.trajPlane2DEllipse=plot(0,0,'g');
        end
        
        if isfield(handles,'fig3D')
            figure(handles.fig3D);
        end
        
    end

    function ShowConvHullCheckboxCallback
        if get(gcbo,'Value')
            UpdateConvHull3D;
            set(handles.convexHull3D,'Visible','on');
            convHullIsActive=true;
        else
            UpdateConvHull3D;
            set(handles.convexHull3D,'Visible','off');
            convHullIsActive=false;
        end
    end

    function SplitConvHullCheckboxCallback
        
        if get(gcbo,'Value')
            convHullIsSplit=true;
        else
            convHullIsSplit=false;
        end
        DrawPlane; %update # of planes
        DrawTrajPlane2D;  %update # of plot groups
        Update3DPlot;
    end

    function ClusterTimingPopupCallback
        
        if get(gcbo,'Value')==1
            clusterTiming=1;
        elseif get(gcbo,'Value')==2
            clusterTiming=2;
        else
            clusterTiming=3;
        end
        
        Update3DPlot;
    end

    function TrajColorPickerCallback
        
        currentColor=uisetcolor;
        if size(currentColor,2)==3
            set(handles.trajColorPicker,'BackgroundColor',currentColor);

            timeColoringColorMap=currentColor;
            colormap(handles.fig3D,timeColoringColorMap);
            Update3DPlot;
        end
    
        
    end

    function ColorByPopupCallback
        
        colorByMode=colorByOptions{get(gcbo,'Value')};
        
        options.colorBy=colorByMode;
        
        switch colorByMode
            
           case 'constant'
             set(handles.trajColorPicker,'Visible','on');                  
             set(handles.clusterTimeLabel1,'Visible','off');
             set(handles.clusterTimeEditbox1,'Visible','off');
             set(handles.clusterTimeEditbox2,'Visible','off');
                        
           case {'rise cluster','fall cluster'}
               
             set(handles.trajColorPicker,'Visible','off');
             set(handles.clusterTimeLabel1,'Visible','on');
             set(handles.clusterTimeEditbox1,'Visible','on');
             set(handles.clusterTimeEditbox2,'Visible','on');

           otherwise
               
             set(handles.trajColorPicker,'Visible','off');
             set(handles.clusterTimeLabel1,'Visible','off');
             set(handles.clusterTimeEditbox1,'Visible','off');
             set(handles.clusterTimeEditbox2,'Visible','off');
             
        end
        
        ColorBy(colorByMode);     
        Update3DPlot;
    end

    function ColorBy(colorByMode)
        
      colorByDirectionFlag=false;
      
      switch colorByMode
          
        case '4-state'
          
          if exist('wbstruct','var')
              
              for d=1:numel(activeDatasetFolders)
                  timeColoring{d}=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron);
              end
          
          else

              disp('wbPhasePlot3D>ColorBy: no wbstruct to build 4-state coloring.')
              for d=1:numel(activeDatasetFolders)
                  timeColoring{d}=ones(size(pcs{d}(:,1)));

              end
              
          end
          
          timeColoringColorMap=options.fourColorMap;
          

          colormap(handles.fig3D,timeColoringColorMap);   

          caxis(handles.plot3D,[1 4]);

          
        case 'constant' %constant color
                
          if exist('wbstruct','var')
              
              for d=1:length(activeDatasetFolders)
                  timeColoring{d}=zeros(size(wbstruct{d}.tv))+d-1;
              end
          
          else
              for d=1:length(activeDatasetFolders)
                  timeColoring{d}=zeros(size(pcs{d}(:,1)))+d-1;
              end
          end
          
          if length(activeDatasetFolders)==1
              timeColoringColorMap=currentColor;
          else
              for d=1:length(activeDatasetFolders)
                  timeColoringColorMap(d,:)=MyColor(d,length(activeDatasetFolders));
              end
          end
          colormap(handles.fig3D,timeColoringColorMap);
   
        case 'rise cluster'
          
         
          if isempty(clusterRiseColoring)          
              LoadClustering;
          end
                    
          for d=1:length(activeDatasetFolders)
              timeColoring{d}=clusterRiseColoring{d};
          end
          
          timeColoringColorMap=[0.3 0.3 0.3;clusterRiseColors(1,:);clusterRiseColors(2,:);clusterRiseColors(2,:)];
    
          colormap(handles.fig3D,timeColoringColorMap);          
            
        case 'fall cluster'          
          
          if isempty(clusterFallColoring)          
              LoadClustering;
          end
          
          for d=1:length(activeDatasetFolders)
              timeColoring{d}=clusterFallColoring{d};
          end
          
          timeColoringColorMap=[0.3 0.3 0.3;clusterFallColors(1,:);clusterFallColors(2,:);clusterFallColors(2,:)];
        
          colormap(handles.fig3D,timeColoringColorMap);                    
         
        case 'stimulus'
          
          for d=1:numel(activeDatasetFolders)
              
              if ~isempty(wbstruct{d}.stimulus.switchtimes)

                  stimOnsetFrame=find(wbstruct{d}.tv>=wbstruct{d}.stimulus.switchtimes(1),1,'first');

                  timeColoring{d}=1+[ones(stimOnsetFrame-1,1) ; zeros(length(wbstruct{d}.tv)-stimOnsetFrame+1 ,1) ]+...
                      ~wbgetstimcoloring(wbstruct{d});
              else
                  
                  %stimulus reference

                  wbstruct{d}.stimulus.switchtimes=[360 390 420 450 480 510 540 570 600 630 660 690];
                  stimOnsetFrame=find(wbstruct{d}.tv>=wbstruct{d}.stimulus.switchtimes(1),1,'first');
                  timeColoring{d}=1+[ones(stimOnsetFrame-1,1) ; zeros(length(wbstruct{d}.tv)-stimOnsetFrame+1 ,1) ]+...
                      ~wbgetstimcoloring(wbstruct{d});
                  %timeColoring{d}=ones(length(wbstruct{d}.tv),1);
                                    
              end

          end
          
          timeColoringColorMap=[MyColor('r');MyColor('gray')];

          colormap(handles.fig3D,[[0 0 1]; timeColoringColorMap]);  %hack

        case 'direction'
                       
          colorByDirectionFlag=true;

        case 'wormspeed'
          
          
          for d=1:numel(activeDatasetFolders)
             timeColoring{d}=ComputeWormSpeedColoring(d);
          end
          
          if isempty(options.timeColoringColorMap)            
             timeColoringColorMap=[0.5 0.5 0.5; flipud(jet(256))];             
          else
              timeColoringColorMap=options.timeColoringColorMap;             
          end
          
          colormap(handles.fig3D,timeColoringColorMap);  
          caxis([-1 1]);
          
        case '6-state'

          if isempty(clusterRiseColoring)  || isempty(clusterFallColoring)     
              LoadClustering;
          end
                    
          for d=1:numel(activeDatasetFolders)
              timeColoring{d}=ComputeFullStateColoring(d,6);
          end
          
          timeColoringColorMap=[options.fourColorMap;clusterRiseColors(1,:);clusterRiseColors(2,:);clusterFallColors(1,:);clusterFallColors(2,:)];
          colormap(handles.fig3D,timeColoringColorMap);    
          
          caxis(handles.plot3D,[1 9]);
          
        case '7-state'
           
          if isempty(clusterRiseColoring)  || isempty(clusterFallColoring)     
              LoadClustering;
          end
                    
          for d=1:numel(activeDatasetFolders)
              timeColoring{d}=ComputeFullStateColoring(d,7);
          end
          

          timeColoringColorMap=[options.fourColorMap;clusterRiseColors(1,:);clusterRiseColors(2,:);clusterFallColors(1,:);clusterFallColors(2,:);slowColor];
          colormap(handles.fig3D,timeColoringColorMap);     
          caxis(handles.plot3D,[1 9]);
   
      end   
      
      caxis(handles.plot3D,'manual');

      ComputeTrajectoryColor;

      cm=colormap(handles.plot3D);
      base('cm'); 
    end

    function timeColoringOut=ComputeFullStateColoring(d,numStates)  %6-state or 7-state coloring
        
            if nargin<2 || isempty(numStates)      
                numStates=7;
            end
                    
            clusterRiseColoring{d}=zeros(size(timeColoring{d}));
            clusterFallColoring{d}=zeros(size(timeColoring{d}));
            
            for k=1:size(transitionsRiseMat{d},1)
                  if ~isnan(transitionsRiseMat{d}(k,4)) && ~isnan(transitionsRiseMat{d}(k,3))
                         clusterRiseColoring{d}(max([1 transitionsRiseMat{d}(k,3)]): ...
                         min([size(timeColoring{d},1)  transitionsRiseMat{d}(k,4)]))=  ...
                         clusterRiseStruct{d}.clusterMembership(k);
                  end

            end


            for k=1:min([size(transitionsFallMat{d},1) length(clusterFallStruct{d}.clusterMembership)])
                  if ~isnan(transitionsFallMat{d}(k,4)) && ~isnan(transitionsFallMat{d}(k,3))
                         clusterFallColoring{d}(max([1 min([length(clusterFallColoring{d})  transitionsFallMat{d}(k,3)])]): ...
                          min([size(timeColoring{d},1)  transitionsFallMat{d}(k,4)]))=   ...
                          clusterFallStruct{d}.clusterMembership(k);
                  end

            end

            timeColoring4State=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron);
% base('tFM',transitionsFallMat{d})
% base('cF',clusterFallColoring);
% base('tC',timeColoring4State);

            cR=clusterRiseColoring{d} .* (timeColoring4State==2);
            cR(cR>0)=cR(cR>0)+2;

            cF=clusterFallColoring{d} .* (timeColoring4State==4);
            cF(cF>0)=cF(cF>0)+2;

            if numStates==7
                
                speedNeuron='RIB'; %'RIB';
                
                %RIB deriv < 0 during fwd runs
                RIB=wbgettrace(speedNeuron,wbstruct{d});

                RIBd=wbgettrace(speedNeuron,wbstruct{d},{'derivs','traces'});
                
                RIBd2=circshift(wbFourStateTraceAnalysis(wbstruct{d},'useSaved',speedNeuron),-1);
                
                RIBd=RIBd/max(RIBd);

                slowColoring=(RIBd2>2 | RIBd2==1).*(timeColoring4State==1);

                timeColoringOut=timeColoring4State+cR+cF+8*slowColoring;

% base('rib',RIB);
% base('ribD',RIBd);
% base('ribD2',RIBd2);                
                

            else  %numStates==6
                
                timeColoringOut=timeColoring4State+cR+cF;
                
            end
            

% base('tc',timeColoring);
 
            %force colormap
            timeColoringOut(1)=0;timeColoringOut(2)=9;
        
            

        
    end

    function timeColoringOut=ComputeWormSpeedColoring(d)  %6-state to be 7-state coloring
        
            timeColoring4State=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.refNeuron);

            %RIB
            RIB=wbgettrace('RIB',wbstruct{d});
            
            RIB=RIB/(max(RIB));
            
            fwdColoring=RIB.*(timeColoring4State==1 | timeColoring4State==4);

            %RIM deriv for reverse
            RIMd=wbgettrace('RIM',wbstruct{d},{'derivs','traces'});
            
            RIMd=RIMd/(max(RIMd));
            
            revColoring=-RIMd.* (timeColoring4State==2);
            
            timeColoringOut=fwdColoring+revColoring;
            
            %gray out plateaus
            timeColoringOut(timeColoring4State==3) = -1;

% base('rib',RIB);
% base('rimD',RIMd);
% 
% base('sc',timeColoring4State);
% 
% base('fc',fwdColoring);   
% base('rc',revColoring);            
% base('tc',timeColoringOut);

    end


    function ClusterColorTimeCallback
        
        transitionColoringWindowStart=str2num(get(handles.clusterTimeEditbox1,'String'));
        transitionColoringWindowEnd=str2num(get(handles.clusterTimeEditbox2,'String'));
       
        GenClusterColoring
        
        if get(handles.colorByPopup,'Value')==3  %rise
            
            for d=1:numel(activeDatasetFolders)         
               timeColoring{d}=clusterRiseColoring{d};
            end
            
        else
            
            for d=1:numel(activeDatasetFolders)         
                timeColoring{d}=clusterFallColoring{d};
            end

        end

        ComputeTrajectoryColor;
        Update3DPlot; 
        
    end

    function LoadClusteringButtonCallback
        
        LoadClustering;
        Update3DPlot;
        
    end

    function LoadClustering
        
        for d=1:numel(activeDatasetFolders)
            
            thisFolderFullPath=activeDatasetFolders{d};
            
            if exist([thisFolderFullPath filesep 'Quant' filesep 'wbClusterRiseStruct.mat'],'file')
                disp('wbPhasePlot3D> loading existing rise cluster struct.');
                clusterRiseStruct{d}=load([thisFolderFullPath filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);

                if ~strcmp(clusterRiseStruct{d}.options.refNeuron,options.refNeuron)  %different refNeuron so re-run
                    disp('wbPhasePlot3D> re-clustering with new reference neuron.');
                    RunClustering(d);
                end
            else
                RunClustering(d);
            end

            if exist([thisFolderFullPath filesep 'Quant' filesep 'wbClusterFallStruct.mat'],'file')
                disp('wbPhasePlot3D> loading existing fall cluster struct.');
                clusterFallStruct{d}=load([thisFolderFullPath filesep 'Quant' filesep 'wbClusterFallStruct.mat']);

                if ~strcmp(clusterFallStruct{d}.options.refNeuron,options.refNeuron)  %different refNeuron so re-run
                    disp('wbPhasePlot3D> re-clustering with new reference neuron.');
                    RunClustering(d);
                end
            else
                RunClustering(d);
            end
        end
        
        GenClusterColoring;
        ComputeClusterMeanTrajectories;

        
    end

    function GenClusterColoring
        
         for d=1:numel(activeDatasetFolders)
             
              clusterRiseColoring{d}=zeros(size(wbstruct{d}.tv));

              for k=1:length(transitionsRise{d})

                  clusterRiseColoring{d}(max([1 transitionsRise{d}(k)-transitionColoringWindowStart]): ...
                          min([size(timeColoring{d},1)  transitionsRise{d}(k)+transitionColoringWindowEnd]))=   ...
                          clusterRiseStruct{d}.clusterMembership(k);

              end
              clusterRiseColoring{d} = clusterRiseColoring{d}(:);

              clusterFallColoring{d}=zeros(size(wbstruct{d}.tv));

              for k=1:length(transitionsFall{d})

                  clusterFallColoring{d}(max([1 transitionsFall{d}(k)-transitionColoringWindowStart]): ...
                          min([size(timeColoring{d},1)  transitionsFall{d}(k)+transitionColoringWindowEnd]))=   ...
                          clusterFallStruct{d}.clusterMembership(k);

              end
              clusterFallColoring{d}= clusterFallColoring{d}(:);
         end
    end

    function RunClustering(d)
        
          clusterRiseColoring{d}=zeros(size(wbstruct{d}.tv));  %this line is suspect
          
          CPoptions.maxClusters=2;
          CPoptions.interactiveMode=false;          
          CPoptions.refNeuron=options.refNeuron;
          CPoptions.saveDirectory=[currentFolderFullPath filesep 'Quant'];
          
          clusterRiseStruct{d}=wbTTACluster([],CPoptions);

          clusterFallColoring{d}=zeros(size(wbstruct{d}.tv)); %this line is suspect
          
          CPoptions.transitionTypes='SignedAllFalls';       
          clusterFallStruct{d}=wbTTACluster([],CPoptions);
           
          
    end

    function OpenClusteringRisePanel
        
        LoadClustering;
        CPoptions=clusterRiseStruct{1}.options;
        
        if isfield(handles,'ClusteringPanelFigure') && ishghandle(handles.ClusteringPanelFigure)
            
            CPoptions.existingFigureHandle=handles.ClusteringPanelFigure;
            
        else
            CPoptions.existingFigureHandle=[];
        end
        
        CPoptions.saveFlag=false;

        CPoptions.originatingFigureHandle=handles.f2;
        CPoptions.interactiveMode=true;
        CPoptions.refNeuron=options.refNeuron;
        CPoptions.transitionTypes='SignedAllRises';
        
        
        
        if multiTrialIsActive
            CPoptions.refNeuron=[];
            CPoptions.multiTrialFlag=true;
            CPoptions.multiTrialDir='..';
            disp('multitrial cluster.')

            GTTA=['..' filesep 'wbClusterRiseStruct-multitrial.mat'];
            [~,handles.ClusteringPanelFigure]=wbTTACluster(GTTA,CPoptions);

        else
            [~,handles.ClusteringPanelFigure]=wbTTACluster([],CPoptions);
        end
    end

    function OpenClusteringFallPanel
        
        LoadClustering;
        CPoptions=clusterFallStruct{1}.options;
        
        if isfield(handles,'ClusteringFallPanelFigure') && ishghandle(handles.ClusteringFallPanelFigure)
            
            CPoptions.existingFigureHandle=handles.ClusteringFallPanelFigure;
            
        else
            CPoptions.existingFigureHandle=[];
        end
        
        CPoptions.saveFlag=false;
        
        CPoptions.originatingFigureHandle=handles.f2;
        CPoptions.interactiveMode=true;
        CPoptions.refNeuron=options.refNeuron;
        CPoptions.transitionTypes='SignedAllFalls';
        

        if multiTrialIsActive
            
            disp('multitrial cluster.')

            GTTA=load(['..' filesep 'wbClusterFallStruct-multitrial.mat']);
            [~,handles.ClusteringPanelFigure]=wbTTACluster(GTTA,CPoptions);
        else
            [~,handles.ClusteringPanelFigure]=wbTTACluster([],CPoptions);
        end

    end

    function SaveTrajDataButtonCallback
        
        trajStruct.mTrajRiseDataX=mTrajRiseDataX;
        trajStruct.mTrajRiseDataY=mTrajRiseDataY;
        trajStruct.mTrajRiseDataZ=mTrajRiseDataZ;
        trajStruct.mTrajRiseDataC=mTrajRiseDataC;
        
              
        trajStruct.mTrajFallDataX=mTrajFallDataX;
        trajStruct.mTrajFallDataY=mTrajFallDataY;
        trajStruct.mTrajFallDataZ=mTrajFallDataZ;
        trajStruct.mTrajFallDataC=mTrajFallDataC;
        
        trajStruct.trajDataX=trajDataX;
        trajStruct.trajDataY=trajDataY;
        trajStruct.trajDataZ=trajDataZ;
        trajStruct.trajDataC=trajDataC;
        
        trajStruct.TWRiseFrames=TWRiseFrames;
        trajStruct.TWFallFrames=TWFallFrames;
        
        trajStruct.transitionsRiseMat=transitionsRiseMat;
        trajStruct.transitionFallMat=transitionsFallMat;
        trajStruct.transitionT2TMat=transitionsT2TMat;
        
        trajStruct.canonicalTimesReg=canonicalTimesReg;
        trajStruct.canonicalTimesT2T=canonicalTimesT2T;
        
        
        
        for d=1:numel(activeDatasetFolders)
            st=round(0.5*length(tv{d}));
            et=round(0.75*length(tv{d}));
            trajStruct.trajRiseRange{d}=TWRiseFrames{d}(st:et,:);
            trajStruct.trajFallRange{d}=TWFallFrames{d}(st:et,:);
                     
            trajStruct.trajRiseXYZ{d}=nan(length(st:et),3,size(TWRiseFrames{d},2));
            trajStruct.trajFallXYZ{d}=nan(length(st:et),3,size(TWFallFrames{d},2));
            trajStruct.trajFullRiseXYZ{d}=nan(length(tv{d}),3,size(TWRiseFrames{d},2));
            trajStruct.trajFullFallXYZ{d}=nan(length(tv{d}),3,size(TWFallFrames{d},2));
            
            trajStruct.nanRise{d}=isnan(TWRiseFrames{d}(1,:));
            trajStruct.nanFall{d}=isnan(TWFallFrames{d}(1,:));

                        
            trajStruct.trajRiseXYZ{d}(:,1,~trajStruct.nanRise{d})=mTrajRiseDataX{d}(round(st:et),~trajStruct.nanRise{d});
            trajStruct.trajRiseXYZ{d}(:,2,~trajStruct.nanRise{d})=mTrajRiseDataY{d}(round(st:et),~trajStruct.nanRise{d});
            trajStruct.trajRiseXYZ{d}(:,3,~trajStruct.nanRise{d})=mTrajRiseDataZ{d}(round(st:et),~trajStruct.nanRise{d});
            

            trajStruct.trajFallXYZ{d}(:,1,~trajStruct.nanFall{d})=mTrajFallDataX{d}(round(st:et),~trajStruct.nanFall{d});
            trajStruct.trajFallXYZ{d}(:,2,~trajStruct.nanFall{d})=mTrajFallDataY{d}(round(st:et),~trajStruct.nanFall{d});
            trajStruct.trajFallXYZ{d}(:,3,~trajStruct.nanFall{d})=mTrajFallDataZ{d}(round(st:et),~trajStruct.nanFall{d});
            
            trajStruct.trajFullRiseXYZ{d}(:,1,~trajStruct.nanRise{d})=mTrajRiseDataX{d}(:,~trajStruct.nanRise{d});
            trajStruct.trajFullRiseXYZ{d}(:,2,~trajStruct.nanRise{d})=mTrajRiseDataY{d}(:,~trajStruct.nanRise{d});
            trajStruct.trajFullRiseXYZ{d}(:,3,~trajStruct.nanRise{d})=mTrajRiseDataZ{d}(:,~trajStruct.nanRise{d});
            
            trajStruct.trajFullFallXYZ{d}(:,1,~trajStruct.nanFall{d})=mTrajFallDataX{d}(:,~trajStruct.nanFall{d});
            trajStruct.trajFullFallXYZ{d}(:,2,~trajStruct.nanFall{d})=mTrajFallDataY{d}(:,~trajStruct.nanFall{d});
            trajStruct.trajFullFallXYZ{d}(:,3,~trajStruct.nanFall{d})=mTrajFallDataZ{d}(:,~trajStruct.nanFall{d});
            
            trajStruct.trialname{d}=wbstruct{d}.trialname;


        end
    
        trajStruct.tv=tv;
        
        if numel(activeDatasetFolders)>1
            save(['Quant' filesep 'wbTrajStructMultiDataset.mat'],'-struct','trajStruct');
        else
            save(['Quant' filesep 'wbTrajStruct.mat'],'-struct','trajStruct');
        end
        
        disp('wbPhasePlot3D> wbTrajStruct.mat saved.')
        
    end

    function PlotGUITraces
        
        axes(handles.tracePlotAxis);
        
        hold off;
        neuronTraceColor={'r','g','b'};
        
        handles=KillHandle('trace',handles);
        
        for i=1:3         
           neuronTrace(:,i)=wbgettrace(neuronList{neuronListNum(i)},wbstruct{1});
           handles.trace(i)=plot(tv{1},neuronTrace(:,i),neuronTraceColor{i});
           hold on;
        end

        xLim=[tv{1}(1)-3 tv{1}(end)+1];
        xlim(xLim);
        yLim=1.1*[min(neuronTrace(:))   max(neuronTrace(:))];
        ylim(yLim);
        SmartTimeAxis(xLim);
        
        box off;
        
        %plot top rise transition ticks
        handles=KillHandle('tracePlotAxisTop',handles);
        handles.tracePlotAxisTopRise = axes('Position',get(gca,'Position'),...
            'XAxisLocation','top',...
            'YAxisLocation','right',...
            'Color','r');

        xlim(xLim);
        ylim(yLim);
        set(handles.tracePlotAxisTopRise,'TickDir','out');
        set(handles.tracePlotAxisTopRise,'XTick',tv{1}(transitionsRise{1}));
        set(handles.tracePlotAxisTopRise,'TickLength',[.013 .025]);
        set(handles.tracePlotAxisTopRise,'XTickLabel',arrayfun(@num2str,1:length(transitionsRise{1}),'UniformOutput',0));
        set(handles.tracePlotAxisTopRise,'XColor',[1 0 0]);

        %plot top fall transition ticks
        handles.tracePlotAxisTopFall = axes('Position',get(gca,'Position'),...
            'XAxisLocation','top',...
            'YAxisLocation','right',...
            'Color','b');

        xlim(xLim);
        ylim(yLim);
        set(handles.tracePlotAxisTopFall,'TickDir','out');
        set(handles.tracePlotAxisTopFall,'XTick',tv{1}(transitionsFall{1}));
        set(handles.tracePlotAxisTopFall,'TickLength',[.005 .025]);
        set(handles.tracePlotAxisTopFall,'XTickLabel',arrayfun(@num2str,1:length(transitionsFall{1}),'UniformOutput',0));
        set(handles.tracePlotAxisTopFall,'XColor',[0 0 1]);
        
        
        
        
    end

    function UpdateTraces
        axes(handles.tracePlotAxis);
        hold off;
        for k=1:3

            if neuronListNum(k)>0          

                set(handles.trace(k),'YData',wbgettrace(neuronList{neuronListNum(k)},wbstruct{1}));
                set(handles.trace(k),'Visible','on');
            else

                set(handles.trace(k),'Visible','off');
            end
        end  
    end

    function timeSliderCallback
        
        newVal=get(handles.timeSlider1,'Value');
        
        %force slider2 to be to the right of slider 1
        if newVal<slider2Val
            slider1Val=newVal;
        else
            slider1Val=max([1 slider2Val]);
            set(handles.timeSlider1,'Value',slider1Val);
        end

        UpdateRanges;
        Update3DPlot;
        UpdateHighlightRect;
        UpdateCounter;
 
    end
       
    function timeSlider2Callback
        
        newVal=get(handles.timeSlider2,'Value');
        
        %force slider2 to be to the right of slider 1
        if newVal>slider1Val
            slider2Val=newVal;
        else
            slider2Val=min([slider1Val numFrames]);
            set(handles.timeSlider2,'Value',slider2Val);
        end

        UpdateRanges;
        Update3DPlot;
        UpdateHighlightRect;
        UpdateCounter;
 
    end

    function timeSlider3Callback
        
        newVal=get(handles.timeSlider3,'Value');
        
        %force slider2 to be to the right of slider 1
        if newVal<slider4Val
            slider3Val=newVal;
        else
            slider3Val=max([1 slider4Val]);
            set(handles.timeSlider3,'Value',slider3Val);
        end

        UpdateRanges;
        Update3DPlot;
        UpdateHighlightRect;
        UpdateCounter;
 
    end
       
    function timeSlider4Callback
        
        newVal=get(handles.timeSlider4,'Value');
        
        %force slider4 to be to the right of slider 3
        if newVal>slider1Val
            slider4Val=newVal;
        else
            slider4Val=min([slider3Val numFrames]);
            set(handles.timeSlider4,'Value',slider4Val);
        end

        UpdateRanges;
        Update3DPlot;
        UpdateHighlightRect;
        UpdateCounter;
 
    end

    function DrawRanges
        
        axes(handles.tracePlotAxis);
        
        handles=KillHandle('redline',handles);
        handles=KillHandle('blueline',handles); 
        handles=KillHandle('frametext',handles);

        %translucent highlight rect
        handles=KillHandle('highlightRect',handles);
        handles.highlightRect=fill([tv{1}(1),tv{1}(1),tv{1}(end),tv{1}(end)],...
        [yLim(1) yLim(2) yLim(2) yLim(1) ],...
        [0.5 0.5 0.5],'FaceAlpha',0.3,'EdgeColor','none','Visible','off');

        if get(handles.trajectoriesPopup,'Value')==1  %single
                     
            %redline
            FTFrame=get(handles.timeSlider1,'Value');
            handles.FTRedline=line([tv{1}(FTFrame) tv{1}(FTFrame)],yLim,'Color','r');  

            %blueline
            FTFrameEnd=get(handles.timeSlider2,'Value');
            handles.FTBlueline=line([tv{1}(round(FTFrameEnd)) tv{1}(round(FTFrameEnd))],yLim,'Color','b');

            %translucent highlight rect
            set(handles.highlightRect,'Visible','on');

            %frame counter
            handles.frametext=textur([num2str(round(FTFrame)) ' - ' num2str(round(FTFrameEnd)) '/' num2str(numFrames) ' frames'],0,14,[0 0 0]);    

        elseif get(handles.trajectoriesPopup,'Value')==2  %multi
            
            relTime=get(handles.timeSlider1,'Value')/length(tv);
            relTimeEnd=get(handles.timeSlider2,'Value')/length(tv);
            
            for d=1:length(activeDatasetFolders)

                for i=1:length(transitions{d})

                    frame{d}(i)=round(transitions{d}(i)+relTime*maxRange);
                    if d==1 && ~isnan(frame{1}(i))
                        handles.redline(i)=line([tv(frame{d}(i)) tv(frame{d}(i))],yLim,'Color','r');  
                    end
                end

                for i=1:length(transitions{d})

                    frameEnd{d}(i)=min([round(transitions{d}(i)+relTimeEnd*maxRange)  transitions{d}(i+1) ]);
                    if d==1 && ~isnan(frame{1}(i))
                       handles.blueline(i)=line([tv{1}(frameEnd{d}(i)) tv{1}(frameEnd{d}(i))],yLim,'Color','b','LineStyle','--');
                    end
                end
            end

            %frame counter
            handles.frametext=textur('multi range',0,14,[0 0 0]);    

            
        elseif get(handles.trajectoriesPopup,'Value')==3 %stretch
            
            
            relTime=get(handles.timeSlider1,'Value')/length(tv);
            relTimeEnd=get(handles.timeSlider2,'Value')/length(tv);   

            for i=1:length(transitionsRise)
                          
                frame(i)=round(transitionsRise(i)+relTime*(transitionsRise(i+1)-transitionsRise(i)));
                handles.redline(i)=line([tv(frame(i)) tv(frame(i))],yLim,'Color','r');  
            end
            
               
            for i=1:length(transitionsRise)
                
                frameEnd(i)=min([round(transitionsRise(i)+relTimeEnd*(transitionsRise(i+1)-transitionsRise(i)))  transitionsRise(i+1) ]);
                handles.blueline(i)=line([tv(frameEnd(i)) tv(frameEnd(i))],yLim,'Color','b','LineStyle','--');
       
            end
            
            %frame counter
            handles.frametext=textur(['multi range (stretched)'],0,14,[0 0 0]);    
 
            
        else  %timewarp

            relTime=get(handles.timeSlider1,'Value')/length(tv{1});
            relTimeEnd=get(handles.timeSlider2,'Value')/length(tv{1});
                
 
            for d=1:length(activeDatasetFolders)

                for i=1:size(transitionsMat{d},1)

                    frame{d}(i)=round( interp1(canonicalTimes,transitionsMat{d}(i,:)-0.5,max([relTime 0]),'linear'));

                    if d==1 && ~isnan(frame{1}(i))
                        handles.redline(i)=line([tv{1}(frame{1}(i)) tv{1}(frame{1}(i))],yLim,'Color','r');  
                    end
                end

                for i=1:size(transitionsMat{d},1)

                    frameEnd{d}(i)=round( interp1(canonicalTimes,transitionsMat{d}(i,:),min([relTimeEnd 1]),'linear'));
                    if d==1 && ~isnan(frameEnd{1}(i))
                        handles.blueline(i)=line([tv{1}(frameEnd{1}(i)) tv{1}(frameEnd{1}(i))],yLim,'Color','b','LineStyle','--');
                    end


                    
                end
                
                %hack for chopped final transition, should eventually
                %fix in wbGetTransitionRanges
                if isnan(frameEnd{d}(end))
                    frameEnd{d}(end)=numFrames;
                end

            end
                       
            %frame counter
            handles.frametext=textur(['multi range (stretched)'],0,14,[0 0 0]);    
 
            
        end

        
    end

    function UpdateRanges
                    
        if get(handles.trajectoriesPopup,'Value')==1  %single
            
              FTFrame=round(slider1Val);
              FTFrameEnd=round(slider2Val);
              
            
              set(handles.FTRedline,'XData',[tv{1}(FTFrame) tv{1}(FTFrame)]);
              set(handles.FTBlueline,'XData',[tv{1}(FTFrameEnd) tv{1}(FTFrameEnd)]);
              
              
        elseif get(handles.trajectoriesPopup,'Value')==2  %multi
                                  
              relTime=get(handles.timeSlider1,'Value')/length(tv);
              relTimeEnd=get(handles.timeSlider2,'Value')/length(tv);

              
              
              %left slider

                  for ii=1:size(transitionsMat,1)
                      
                     updateFrame=transitionsMat(ii,1)+round(relTime*maxRange);
                     %frame(ii)=max([transitions(ii) min([updateFrame transitions(ii+1) ])]) ;
                     
                     frame(ii)= max([transitionsMat(ii,1)   min([updateFrame transitionsMat(ii,end) ])]);
                     
                     set(handles.redline(ii),'XData',[tv(frame(ii)) tv(frame(ii))]);
        

                  end
              %right slider
                  for ii=1:size(transitionsMat,1)
                      updateFrameEnd=transitionsMat(ii,1)+round(relTimeEnd*maxRange);
                      frameEnd(ii)=max([transitionsMat(ii,1)  min([updateFrameEnd  transitionsMat(ii,end) ])]);

                         set(handles.blueline(ii),'XData',[tv(frameEnd(ii)) tv(frameEnd(ii))]);
                      
                  end
              
        elseif get(handles.trajectoriesPopup,'Value')==3  %stretch
            
              relTime=get(handles.timeSlider1,'Value')/length(tv);
              relTimeEnd=get(handles.timeSlider2,'Value')/length(tv);
            
              %left slider

                  for ii=1:length(transitionsRise)
                      
                     frame(ii)=max([transitionsRise(ii) min([transitionsRise(ii)+round(relTime*(transitionsRise(ii+1)-transitionsRise(ii))) transitionsRise(ii+1) ])]) ;
                    
                     if drawMode
                         set(handles.redline(ii),'XData',[tv(frame(ii)) tv(frame(ii))]);
                     end
                  end
              %right slider
                  for ii=1:length(transitionsRise)
                      frameEnd(ii)=max([transitionsRise(ii)  min([transitionsRise(ii)+round(relTimeEnd*(transitionsRise(ii+1)-transitionsRise(ii)))  transitionsRise(ii+1) ])]);
                         set(handles.blueline(ii),'XData',[tv(frameEnd(ii)) tv(frameEnd(ii))]);  
                      
                  end           
            
        else  %timewarp
            
              relTime=get(handles.timeSlider1,'Value')/length(tv{1});
              relTimeEnd=get(handles.timeSlider2,'Value')/length(tv{1});

            
              %left slider
                   
              clear frame;
              for d=1:length(activeDatasetFolders)
                  
                 %create interp1 lookup
                 for ii=1:size(transitionsMat{d},1)

                     interpFrame= round( interp1(canonicalTimes,transitionsMat{d}(ii,:),max([0 relTime]),'linear'));
                     frame{d}(ii)=max([floor(transitionsMat{d}(ii,1)) min([interpFrame floor(transitionsMat{d}(ii,end)) ])]) ;

                     if d==1 && ~isnan(frame{1}(ii)) && handles.redline(ii)>0
                        set(handles.redline(ii),'XData',[tv{1}(frame{1}(ii)) tv{1}(frame{1}(ii))]);
                     end
                   end

              end
                                                                    
              %right slider
                  
              clear frameEnd;
              for d=1:length(activeDatasetFolders)
                           
                 for ii=1:size(transitionsMat{d},1)

                          interpFrameEnd= interp1(canonicalTimes,transitionsMat{d}(ii,:),min([relTimeEnd 1]),'linear');
                          frameEnd_frac{d}(ii)=rem(interpFrameEnd,1);
                          frameEnd{d}(ii)=max([ceil(transitionsMat{d}(ii,1))  min([round(interpFrameEnd)  ceil(transitionsMat{d}(ii,end)) ])]);

                          if d==1 && ~isnan(frameEnd{1}(ii)) && handles.blueline(ii)>0
                              set(handles.blueline(ii),'XData',[tv{1}(frameEnd{1}(ii)) tv{1}(frameEnd{1}(ii))]);  
                          end
                 end
                      
               
              end 

                        
              %update thisPlotTimeRange 
              clear('thisPlotTimeRange');
              for d=1:length(activeDatasetFolders)
                for k=1:length(frame{d})
                    thisPlotTimeRange{d}(k,:)=[frame{d}(k) frameEnd{d}(k)];
                end        

              end
              
        end   
              
        caxis([1 9]);

    end
    
    function DrawPlane
                
        handles=KillHandle('planeCenter',handles);
        handles=KillHandle('planeNormal',handles);
        handles=KillHandle('trajPlane',handles);
        handles=KillHandle('projectedPts',handles);
        
        %trajectory plane
        
        
        if ~options.plotClusters || (exist('convHullIsSplit','var') && ~convHullIsSplit) 
            axes(handles.plot3D(1))
            hold on;
            handles.planeCenter=ex3d(0,0,0,20,'g');  
            
            
            disp('convHullNotSplit')

            handles.trajPlane=DrawPlane3([1 0 0],[0 0 0],[-.05 .05],[-.05 .05],[],'r');
            handles.trajPlaneEllipse=plot3([0 0],[0 0],[0 0],'Color','g','LineWidth',2);

            
            if trajPlaneIsActive
               set(handles.trajPlane,'Visible','on');
               set(handles.planeCenter,'Visible','on');
            else
               set(handles.trajPlane,'Visible','off');
               set(handles.planeCenter,'Visible','off');
            end

            handles.planeNormal=plot3([0 0],[0 0],[0 0],'Color','r','LineWidth',2);
            handles.projectedPts=plot3([0 0],[0 0],[0 0],'Color','w','LineStyle','none','MarkerSize',10,'Marker','x');

        else %convHullIsSplit

            disp('drawPlane> convHullisSPlit')
            axes(handles.plot3D(1))
            hold on;
            
            if ~isempty(clusterRiseStruct{1})
                for nc=1:clusterRiseStruct{1}.options.maxClusters
                    handles.planeCenter(nc)=ex3d(0,0,0,20,'g');   

                    %handles.trajPlane(nc)=DrawPlane3([1 0 0],[0 0 0],[-.05 .05],[-.05 .05],[],clusterRiseColors(nc,:));

                    handles.trajPlane(nc)=DrawPlane3([1 0 0],[0 0 0],[-.05 .05],[-.05 .05],[],'r');
                    handles.trajPlaneEllipse(nc)=plot3([0 0],[0 0],[0 0],'Color','g','LineWidth',2);

                    handles.planeNormal(nc)=plot3([0 0],[0 0],[0 0],'Color','r','LineWidth',2);

                    if trajPlaneIsActive
                        disp('tracePlaneIsActive')
                       set(handles.trajPlane(nc),'Visible','on');
                       set(handles.planeCenter(nc),'Visible','on');
                       set(handles.planeNormal(nc),'Visible','on');
                       set(handles.trajPlaneEllipse(nc),'Visible','on');                   

                    else
                       set(handles.trajPlane(nc),'Visible','off');
                       set(handles.planeCenter(nc),'Visible','off');
                       set(handles.planeNormal(nc),'Visible','off');
                       set(handles.trajPlaneEllipse(nc),'Visible','off');

                    end
                    handles.currentPts(nc)=plot3([0 0],[0 0],[0 0],'Color','r','LineStyle','none','MarkerSize',8,'Marker','o');  

                    handles.projectedPts(nc)=plot3([0 0],[0 0],[0 0],'Color','w','LineStyle','none','MarkerSize',10,'Marker','x');  
                    handles.backProjPts(nc)=plot3([0 0],[0 0],[0 0],'Color','b','LineStyle','none','MarkerSize',8,'Marker','+');  

                end
            end
        end
        
    end

    function DrawOverlayBalls


             if options.interactiveMode
                 figure(handles.fig3D);
             end
             
             %Overlay plots
             if isfield(options,'timeColoringOverlay') && ~isempty(options.timeColoringOverlay)

                 if ~isfield(options,'timeColoringOverlayColor') || isempty(options.timeColoringOverlayColor)  
                     
                     for d=1:length(activeDatasetFolders)
                    
                         if numel(options.timeColoringOverlay)>6
                             for cc=1:numel(options.timeColoringOverlay{d})
                                 colorList{cc}=color(cc,numel(options.timeColoringOverlay));
                             end
                         else
                            colorList={'r','g','b','c','m','y'};
                         end

                         for co=1:size(options.timeColoringOverlay{d},2)

                             %options.timeColoringOverlayColor{co}=color(length(options.timeColoringOverlay)-co+1,length(options.timeColoringOverlay));                                 
                             options.timeColoringOverlayColor{co}=colorList{co};
                         end

                     end
                 end
                 

                 KillHandle('timeColoringOverlay',handles);
                 

                 if options.timeColoringShiftBalls
                    ballOffset=[0 0.1 0.5 0.2 0.15 0.25];
                 else
                    ballOffset=zeros(1,6);
                 end    
            
                 if ~isnan(fullPlotTimeRange{1}(1)) && ~isnan(fullPlotTimeRange{1}(end))
 
                    for d=1:length(activeDatasetFolders)

                       for tco=1:size(options.timeColoringOverlay{d},2)

                           indicesLogical=logical(options.timeColoringOverlay{d}(:,tco));
                           indicesShift=circshift(indicesLogical,1);

                           XBalls=((1-ballOffset(tco))*trajDataX{d}(indicesLogical)+ ballOffset(tco)*trajDataX{d}(indicesShift))/normFac(1,d);
                           YBalls=((1-ballOffset(tco))*trajDataY{d}(indicesLogical)+ ballOffset(tco)*trajDataY{d}(indicesShift))/normFac(2,d);
                           ZBalls=((1-ballOffset(tco))*trajDataZ{d}(indicesLogical)+ ballOffset(tco)*trajDataZ{d}(indicesShift))/normFac(3,d);
                                          
%                          XBalls=trajDataX{d}(logical(options.timeColoringOverlay{d}(fullPlotTimeRange{d}(1):fullPlotTimeRange{d}(end),tco)));
%                          YBalls=trajDataY{d}(logical(options.timeColoringOverlay{d}(fullPlotTimeRange{d}(1):fullPlotTimeRange{d}(end),tco)));
%                          ZBalls=trajDataZ{d}(logical(options.timeColoringOverlay{d}(fullPlotTimeRange{d}(1):fullPlotTimeRange{d}(end),tco)));


                           if ~isempty(XBalls)
                             if options.phasePlot2DView  
                                 size(XBalls)
                                 size(YBalls)
                                 handles.timeColoringOverlay{d}(tco)=plot(XBalls,YBalls,...
                                 'Color',options.timeColoringOverlayColor{tco},'LineWidth',options.lineWidth,'LineStyle','none','Marker',options.overlayMarker{tco},'MarkerSize',options.overlayBallSize,'MarkerFaceColor',options.timeColoringOverlayColor{tco},'Visible','off');

                                 %alpha                          
%                                  if ~verLessThan('matlab','8.4.0')
%                                      
%                                      drawnow;
% 
%                                      hMarkers=handles.timeColoringOverlay{d}(tco).MarkerHandle;
%                                      hMarkers.FaceColorData=uint8(255*[options.timeColoringOverlayColor{tco} 0.3]');
%                                      hMarkers.EdgeColorData=[];
% 
%                                  end
                             else

                                 handles.timeColoringOverlay{d}(tco)=plot3(XBalls,YBalls,ZBalls,...
                                 'Color',options.timeColoringOverlayColor{tco},'LineWidth',options.lineWidth,'LineStyle','none','Marker',options.overlayMarker{tco},'MarkerSize',options.overlayBallSize,'MarkerFaceColor',options.timeColoringOverlayColor{tco},'Visible','off');
                          
                             end
                             
                           else
                               
                              if options.phasePlot2DView
                                  handles.timeColoringOverlay{d}(tco)=plot(0,0,...
                                 'Color',options.timeColoringOverlayColor{tco},'LineWidth',options.lineWidth,'LineStyle','none','Marker',options.overlayMarker{tco},'MarkerSize',options.overlayBallSize,'MarkerFaceColor',options.timeColoringOverlayColor{tco},'Visible','on');    
                                   
                                  
                              else
                                  handles.timeColoringOverlay{d}(tco)=plot3(0,0,0,...
                                 'Color',options.timeColoringOverlayColor{tco},'LineWidth',options.lineWidth,'LineStyle','none','Marker',options.overlayMarker{tco},'MarkerSize',options.overlayBallSize,'MarkerFaceColor',options.timeColoringOverlayColor{tco},'Visible','on');    
                              end
                           end
                           

                       end
                    end 
                 end

%                  if options.interactiveMode && isfield(handles,'timeColoringOverlay')
% 
%                      set(handles.timeColoringOverlay{d},'Visible','off');
% 
%                  end

             end
                     
    end
 
    function DrawFlowArrows
        
         
          ComputeTrajectories;
          
          kkk=1;
          d=1;
          
          base('mTrajRiseDataX')
          kk=1;
          nrings=length(thisPlotTimeRange{1}(1)+options.flowArrowsStep:options.flowArrowsStep:thisPlotTimeRange{1}(end));
          for fr=[thisPlotTimeRange{1}(1)+options.flowArrowsStep:options.flowArrowsStep:thisPlotTimeRange{1}(end)  thisPlotTimeRange{1}(end)-1]
              cm=jet(nrings+1);
              colr=cm(kk,:);
              for k=1:size(transitionsRiseMat{1},1) 
                      

                  handles.flowArrow(kkk)=arrowMMC([mTrajRiseDataX{d}(fr-1,k),mTrajRiseDataY{d}(fr-1,k)],...
                                                  [mTrajRiseDataX{d}(fr,k),mTrajRiseDataY{d}(fr,k)],...
                                                  [mTrajRiseDataX{d}(fr+1,k),mTrajRiseDataY{d}(fr+1,k)],4,[-.2 .4 -.15 .15],colr,colr);
                  kkk=kkk+1;
              end    
              kk=kk+1;
          end
                  
    end

    function UpdateTimeBounds   %interactive mode only function
        
        ComputeTWFrames
        
          sT=round(get(handles.timeSlider1,'Value'));
          eT=round(get(handles.timeSlider2,'Value'));
          
          sTF=round(get(handles.timeSlider3,'Value'));  %for fall cluster mean traj
          eTF=round(get(handles.timeSlider4,'Value')); 
          
          
          if strcmpi(options.trajType,'single')
              
              for d=1:length(activeDatasetFolders)

                  activeFullRangeIndices{d}=false(size(trajDataX{d},1),1);        

                     thisRange=ceil(sT/size(trajDataX{1},1)*size(trajDataX{d},1)):floor(eT/size(trajDataX{1},1)*size(trajDataX{d},1));

                     if ~isnan(thisRange)
                          activeFullRangeIndices{d}(thisRange)=true;
                     end

              end              
              
              
          else

              
              for d=1:length(activeDatasetFolders)

                  activeFullRangeIndices{d}=false(size(trajDataX{d},1),1);        

                  sTc=max([1 round(sT/size(mTrajDataX{1},1)*size(mTrajDataX{d},1))]);
                  eTc=round(eT/size(mTrajDataX{1},1)*size(mTrajDataX{d},1));
                      
                  for k=1:size(TWFrames{d},2);  

                     thisRange=ceil(TWFrames{d}(sTc,k)):floor(TWFrames{d}(eTc,k));

                     if ~isnan(thisRange)
                          activeFullRangeIndices{d}(thisRange)=true;
                      end
                  end

              end
          
          end
    end


%% Pre computations 

    function ComputeRanges
        
        %time warp only right now
        
            relTime=0;
            relTimeEnd=1;
                
            for d=1:length(activeDatasetFolders)

                for k=1:length(transitionsMat{d})

                    frame{d}(k)=round( interp1(canonicalTimes,transitionsMat{d}(k,:),max([relTime 0]),'linear'));        

                end

                for k=1:length(transitionsMat{d})

                    frameEnd{d}(k)=round( interp1(canonicalTimes,transitionsMat{d}(k,:),min([relTimeEnd 1]),'linear'));

                end

            
            end
   
    end

    function ComputeTrajectories
        
        ComputeTWFrames;

        %interpolate trajectory positions and color           
        for d=1:length(activeDatasetFolders) 
            
                 for k=1:size(transitionsRiseMat{d},1)  

                      mTrajRiseDataX{d}(:,k)=interp1(1:length(tv{d}),trajDataX{d},TWRiseFrames{d}(:,k));         
                      mTrajRiseDataY{d}(:,k)=interp1(1:length(tv{d}),trajDataY{d},TWRiseFrames{d}(:,k));   
                      mTrajRiseDataZ{d}(:,k)=interp1(1:length(tv{d}),trajDataZ{d},TWRiseFrames{d}(:,k));   
                      if isempty(timeColoring{d})
                          thisTimeColoring=ones(length(tv{d}),1);
                      else
                          thisTimeColoring=timeColoring{d};
                      end
                          
                      mTrajRiseDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWRiseFrames{d}(:,k),'nearest');
                      
                 end
                                 
                 %compute mean rise trajectory
                 meanTrajRiseDataX{d}=nanmean(mTrajRiseDataX{d},2);
                 meanTrajRiseDataY{d}=nanmean(mTrajRiseDataY{d},2);
                 meanTrajRiseDataZ{d}=nanmean(mTrajRiseDataZ{d},2);
                 meanTrajRiseDataC{d}=mode(mTrajRiseDataC{d},2); 
                                 
                 for k=1:size(transitionsFallMat{d},1)   

                      mTrajFallDataX{d}(:,k)=interp1(1:length(tv{d}),trajDataX{d},TWFallFrames{d}(:,k));         
                      mTrajFallDataY{d}(:,k)=interp1(1:length(tv{d}),trajDataY{d},TWFallFrames{d}(:,k));   
                      mTrajFallDataZ{d}(:,k)=interp1(1:length(tv{d}),trajDataZ{d},TWFallFrames{d}(:,k));   
                      mTrajFallDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWFallFrames{d}(:,k),'nearest');
                 end
                        
                 %compute mean fall trajectory
                 meanTrajFallDataX{d}=nanmean(mTrajFallDataX{d},2);
                 meanTrajFallDataY{d}=nanmean(mTrajFallDataY{d},2);
                 meanTrajFallDataZ{d}=nanmean(mTrajFallDataZ{d},2);
                 meanTrajFallDataC{d}=mode(mTrajFallDataC{d},2); 
                 
                 
                 for k=1:size(transitionsT2TMat{d},1)   

                      mTrajT2TDataX{d}(:,k)=interp1(1:length(tv{d}),trajDataX{d},TWT2TFrames{d}(:,k));         
                      mTrajT2TDataY{d}(:,k)=interp1(1:length(tv{d}),trajDataY{d},TWT2TFrames{d}(:,k));   
                      mTrajT2TDataZ{d}(:,k)=interp1(1:length(tv{d}),trajDataZ{d},TWT2TFrames{d}(:,k));   
                      mTrajT2TDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWT2TFrames{d}(:,k),'nearest');
                 end
                 
                 
        end
        
        ComputeTrajectoryColor;
        
    end

    function ComputeTWFrames
    % called by ComputeTrajectories
        
        %compute timewarped TWFrames and TWFallFrames for each transition period of each dataset
        for d=1:length(activeDatasetFolders) 
            
            TWRiseFrames{d}=zeros(length(tv{d}),size(transitionsRiseMat{d},1));
            for k=1:size(transitionsRiseMat{d},1)               
                TWRiseFrames{d}(:,k)=interp1(canonicalTimesReg*length(tv{d}),transitionsRiseMat{d}(k,:)-0.5,0:(length(tv{d})-1),'linear');
            end
            
            TWFallFrames{d}=zeros(length(tv{d}),size(transitionsFallMat{d},1));
            for k=1:size(transitionsFallMat{d},1)              
                TWFallFrames{d}(:,k)=interp1(canonicalTimesReg*length(tv{d}),transitionsFallMat{d}(k,:)-0.5,0:(length(tv{d})-1),'linear');
            end
            
            TWT2TFrames{d}=zeros(length(tv{d}),size(transitionsT2TMat{d},1));
                        
            for k=1:size(transitionsT2TMat{d},1)              
                TWT2TFrames{d}(:,k)=interp1(canonicalTimesT2T*length(tv{d}),transitionsT2TMat{d}(k,:)-0.5,0:(length(tv{d})-1),'linear');
            end
    
        end
        
    end

    function ComputeTrajectoryColor
        
        for d=1:length(activeDatasetFolders) 
            
                 if isempty(timeColoring{d})
                      thisTimeColoring=ones(length(tv{d}),1);
                 else
                      thisTimeColoring=timeColoring{d};
                 end
                 
                 if colorByDirectionFlag                     
                     
                     trajDataVX{d}=[diff(trajDataX{d}); 0];
                     trajDataVY{d}=[diff(trajDataY{d}); 0];
                     trajDataVZ{d}=[diff(trajDataZ{d}); 0];
                     
                     norm=sqrt(trajDataVX{d}.^2+trajDataVY{d}.^2+trajDataVZ{d}.^2);
                     
                     trajDataVX{d}=trajDataVX{d}./norm;
                     trajDataVY{d}=trajDataVY{d}./norm;
                     trajDataVZ{d}=trajDataVZ{d}./norm;
                                         
                     maxVX=max([trajDataVX{d}; abs(min(trajDataVX{d}))]);
                     maxVY=max([trajDataVY{d}; abs(min(trajDataVY{d}))]);
                     maxVZ=max([trajDataVZ{d}; abs(min(trajDataVZ{d}))]);
                                           
                     
                     for k=1:size(transitionsRiseMat{d},1)  

                        mTrajDataVX{d}(:,k)=interp1(1:length(tv{d}),trajDataVX{d},TWRiseFrames{d}(:,k));         
                        mTrajDataVY{d}(:,k)=interp1(1:length(tv{d}),trajDataVY{d},TWRiseFrames{d}(:,k));   
                        mTrajDataVZ{d}(:,k)=interp1(1:length(tv{d}),trajDataVZ{d},TWRiseFrames{d}(:,k)); 
                      
                     end
                     
                     for k=1:size(transitionsFallMat{d},1)   

                        mTrajFallDataVX{d}(:,k)=interp1(1:length(tv{d}),trajDataVX{d},TWFallFrames{d}(:,k));         
                        mTrajFallDataVY{d}(:,k)=interp1(1:length(tv{d}),trajDataVY{d},TWFallFrames{d}(:,k));   
                        mTrajFallDataVZ{d}(:,k)=interp1(1:length(tv{d}),trajDataVZ{d},TWFallFrames{d}(:,k)); 
                       
                     end                          
                    
                     mTrajRiseDataC{d}=zeros(length(tv{d}),size(transitionsRiseMat{d},1),3);
                     mTrajFallDataC{d}=zeros(length(tv{d}),size(transitionsFallMat{d},1),3);

                     
                     thisTimeColoringR=.0+ (trajDataVX{d}+maxVX)/(2*maxVX)*1.25;
                     thisTimeColoringG=.0+ (trajDataVY{d}+maxVY)/(2*maxVY)*1.25;
                     thisTimeColoringB=.0+ (trajDataVZ{d}+maxVZ)/(2*maxVZ)*1.25;
                         
                     colorAngle=atan2(trajDataVY{d},trajDataVX{d}); 

                     %for single trajType
                     
                   %  trajDataC{d}=[thisTimeColoringR(:),thisTimeColoringG(:),thisTimeColoringB(:)];  %RGB color
                      trajDataC{d}=colorAngle;  %RGB color

                     colormap(hsv);
                     caxis([-pi,pi]);
                     for k=1:size(transitionsRiseMat{d},1)  %-1    
                         
                          mTrajRiseDataC{d}(:,k,1)=interp1(1:length(tv{d}),thisTimeColoringR,TWRiseFrames{d}(:,k),'nearest');
                          mTrajRiseDataC{d}(:,k,2)=interp1(1:length(tv{d}),thisTimeColoringG,TWRiseFrames{d}(:,k),'nearest');
                          mTrajRiseDataC{d}(:,k,3)=interp1(1:length(tv{d}),thisTimeColoringB,TWRiseFrames{d}(:,k),'nearest');


                     end
                     
                     for k=1:size(transitionsFallMat{d},1)
                           
                          mTrajFallDataC{d}(:,k,1)=interp1(1:length(tv{d}),thisTimeColoringR,TWFallFrames{d}(:,k),'nearest');
                          mTrajFallDataC{d}(:,k,2)=interp1(1:length(tv{d}),thisTimeColoringG,TWFallFrames{d}(:,k),'nearest');
                          mTrajFallDataC{d}(:,k,3)=interp1(1:length(tv{d}),thisTimeColoringB,TWFallFrames{d}(:,k),'nearest');
                     end
                     
                     
                 else  %not colorByDirection
                     
                     trajDataC{d}=timeColoring{d};
 
                     mTrajRiseDataC{d}=[];
                     mTrajFallDataC{d}=[];
                     
                     if ~isempty(transitionsRiseMat)
                         
                         for k=1:size(transitionsRiseMat{d},1)  %-1   

                              mTrajRiseDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWRiseFrames{d}(:,k),'nearest');
                         end
                         for k=1:size(transitionsFallMat{d},1)

                              mTrajFallDataC{d}(:,k)=interp1(1:length(tv{d}),thisTimeColoring,TWFallFrames{d}(:,k),'nearest');
                         end
                     
                     end

                 end
                 
                 
                 %compute mean trajectory
                 meanTrajRiseDataC{d}=mode(mTrajRiseDataC{d},2); 
                 meanTrajFallDataC{d}=mode(mTrajFallDataC{d},2); 

        end 
        

    end

    function ComputeClusterMeanTrajectories

        for d=1:length(activeDatasetFolders) 
             
                for nc=1:clusterRiseStruct{d}.options.maxClusters

                    numC=min([length(clusterRiseStruct{d}.clusterMembership) length(~isnan(transitionsRiseMat{d}(:,1)))]);

                    validClusters=clusterRiseStruct{d}.clusterMembership(1:numC)==nc & ~isnan(transitionsRiseMat{d}(1:numC,1));

                    meanTrajX_RiseCluster{d}{nc}= nanmean( mTrajRiseDataX{d}(:,validClusters),2);
                    meanTrajY_RiseCluster{d}{nc}= nanmean( mTrajRiseDataY{d}(:,validClusters),2);
                    meanTrajZ_RiseCluster{d}{nc}= nanmean( mTrajRiseDataZ{d}(:,validClusters),2);
                    meanTrajC_RiseCluster{d}{nc}= mode( mTrajRiseDataC{d}(:,validClusters),2);
               
                end
 
                for nc=1:clusterFallStruct{d}.options.maxClusters  

                    indicesCapped=clusterFallStruct{d}.clusterIndices{nc};

                    meanTrajX_FallCluster{d}{nc}= nanmean( mTrajFallDataX{d}(:,indicesCapped),2);
                    meanTrajY_FallCluster{d}{nc}= nanmean( mTrajFallDataY{d}(:,indicesCapped),2);
                    meanTrajZ_FallCluster{d}{nc}= nanmean( mTrajFallDataZ{d}(:,indicesCapped),2);
                    meanTrajC_FallCluster{d}{nc}= mode( mTrajFallDataC{d}(:,indicesCapped),2);

                end
            end

    end

    function ComputeTimeColoringOverlay
        
        for d=1:length(activeDatasetFolders)
            
                if isempty(options.timeColoringOverlay) || (iscell(options.timeColoringOverlay) && numel(options.timeColoringOverlay)<d)
                    options.timeColoringOverlay{d}=zeros(length(tv{d}),6);
                end
 
                
                if options.interactiveMode
                        for n=1:6  

                            overlayNeuronState=get(handles.neuronStateDropdown(n),'Value');
                            if find(strcmp(wbstruct{d}.simple.ID1,neuronList{neuronListNum(n)}))           
                               options.timeColoringOverlay{d}(:,n)=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',neuronList{neuronListNum(n)})==overlayNeuronState;
                            else
                               options.timeColoringOverlay{d}(:,n)=zeros(size(tv{d})); 
                            end
                        end
                    
                elseif ~isempty(options.timeColoringOverlayNeurons)
                        for n=1:length(options.timeColoringOverlayNeurons)           
                            options.timeColoringOverlay{d}(:,n)=wbFourStateTraceAnalysis(wbstruct{d},'useSaved',options.timeColoringOverlayNeurons{n})==options.timeColoringOverlayNeuronStates(n);
                        end
                end
        end
        
    end

    function UpdateOverlayBalls
        
        if options.timeColoringShiftBalls
             ballOffset=[0 0.1 0.5 0.2 0.15 0.25];
        else
                     
             ballOffset=zeros(1,6);
        end       
                                              
        for d=1:length(activeDatasetFolders)
            
            for tco=1:size(options.timeColoringOverlay{d},2)

                indicesLogical=activeFullRangeIndices{d} & logical(options.timeColoringOverlay{d}(:,tco));

                indicesShift=circshift(indicesLogical,1);

                XBalls=((1-ballOffset(tco))*trajDataX{d}(indicesLogical)+ ballOffset(tco)*trajDataX{d}(indicesShift))/normFac(1,d);
                YBalls=((1-ballOffset(tco))*trajDataY{d}(indicesLogical)+ ballOffset(tco)*trajDataY{d}(indicesShift))/normFac(2,d);
                ZBalls=((1-ballOffset(tco))*trajDataZ{d}(indicesLogical)+ ballOffset(tco)*trajDataZ{d}(indicesShift))/normFac(3,d);

                set(handles.timeColoringOverlay{d}(tco),'XData',XBalls);
                set(handles.timeColoringOverlay{d}(tco),'YData',YBalls);
                set(handles.timeColoringOverlay{d}(tco),'ZData',ZBalls,'Visible','on');
                                          
               
%                 hMarkers=handles.timeColoringOverlay{d}(tco).MarkerHandle;
%                 hMarkers.FaceColorData=uint8(255*[options.timeColoringOverlayColor{tco} 0.3]');
%                 hMarkers.EdgeColorData=[]; 
                                 
                if options.interactiveMode
                    if get(handles.neuronCheckbox(tco),'Value')
                        set(handles.timeColoringOverlay{d}(tco),'Visible','on');
                    else
                        set(handles.timeColoringOverlay{d}(tco),'Visible','off');
                    end
                end
                
                %drawnow;

            end
        end
              
    end

    function UpdateConvHull3D
        
          axes(handles.plot3D(1));
          
          validFrameEnds=frameEnd{1}(~isnan(frameEnd{1}));  %skip nans from incomplete final cycles

          if convHullIsSplit
              
              if ~exist('clusterRiseStruct','var');
                   LoadClustering;
              end
              
              delete(handles.convexHull3D);
              d=1;
              for i=1:clusterRiseStruct{d}.options.maxClusters
                  
                    if clusterTiming==1 %get(handles.rangeTypePopup,'Value')==2
                        
                       theseClusterInd=clusterRiseStruct{d}.clusterIndices{i}-1;
                       theseClusterInd(theseClusterInd==0)=[];
                       
                    else %2
                        
                       theseClusterInd=clusterRiseStruct{d}.clusterIndices{i};
                       
                    end                 
            
                   CH = convhull(trajDataX{1}(round(validFrameEnds(theseClusterInd))),trajDataY{1}(round(validFrameEnds(theseClusterInd))),trajDataZ{1}(round(validFrameEnds(theseClusterInd))));
                   handles.convexHull3D(i)=trisurf(CH,trajDataX{1}(round(validFrameEnds(theseClusterInd))),trajDataY{1}(round(validFrameEnds(theseClusterInd))),trajDataZ{1}(round(validFrameEnds(theseClusterInd))), 'Facecolor',clusterRiseColors(i,:),'FaceAlpha',0.1,'Visible','on');   

              end
              
          else  %one convex hull for all transitions
              
              
              CH = convhull(trajDataX{1}(round(validFrameEnds)),trajDataY{1}(round(validFrameEnds)),trajDataZ{1}(round(validFrameEnds)));
    % get(handles.convexHull3D,'Vertices')
    % get(handles.convexHull3D,'XData')
    % get(handles.convexHull3D,'Faces')
    %           CHlength=size(CH,1)
    %           set(handles.convexHull3D,'Faces',CH,'Vertices',[thisDataX(round(frameEnd)) thisDataY(round(frameEnd)) thisDataZ(round(frameEnd))],...
    %               'XData',reshape(thisDataX(round(frameEnd(CH(:)))),3,CHlength),...
    %               'YData',reshape(thisDataY(round(frameEnd(CH(:)))),3,CHlength),...
    %               'ZData',reshape(thisDataZ(round(frameEnd(CH(:)))),3,CHlength),...
    %               'Visible','on');
              delete(handles.convexHull3D);
              handles.convexHull3D=trisurf(CH,trajDataX{1}(round(validFrameEnds)),trajDataY{1}(round(validFrameEnds)),trajDataZ{1}(round(validFrameEnds)), 'Facecolor','cyan','FaceAlpha',0.3,'Visible','on');   


          end
          
          
    end

    function UpdatePlane3(planeHandle,planeHandleIndex,normVec,pointOnPlane,xLim,yLim,pts3D,currentFrame)
          
            %plane normal and corners in e-space
            origNorm=[0 0 1];            
            origX=[xLim(1) xLim(1) xLim(2) xLim(2)];  %in 2D plane coords
            origY=[yLim(1) yLim(2) yLim(2) yLim(1)];
            origZ=[0 0 0 0];

            costheta = dot(normVec(:),origNorm)/(norm(origNorm)*norm(normVec(:)));
            rotAxis = cross(normVec(:),origNorm);
            
            if norm(rotAxis)>0

                rotAxis = rotAxis/norm(rotAxis);

                c=costheta;
                s=-sqrt((1-costheta*costheta));     
                C=1-c;
                
                x=rotAxis(1);
                y=rotAxis(2);
                z=rotAxis(3);

                %2D to 3D
                rmat = [[ x*x*C+c    x*y*C-z*s  x*z*C+y*s ];
                        [ y*x*C+z*s  y*y*C+c    y*z*C-x*s ];
                        [ z*x*C-y*s  z*y*C+x*s  z*z*C+c   ]]; 
                    
                    
                %3D to 2D
                cInv=costheta;
                sInv=sqrt((1-costheta*costheta));
                CInv=1-cInv;
                
                rmatInv = [[ x*x*CInv+cInv    x*y*CInv-z*sInv  x*z*CInv+y*sInv];
                           [ y*x*CInv+z*sInv  y*y*CInv+cInv    y*z*CInv-x*sInv];
                           [ z*x*CInv-y*sInv  z*y*CInv+x*sInv  z*z*CInv+cInv  ]];
                
            else
                rmat=diag([1 1 1]);
            end

            %project 2d plane corners back into 3D
            if ~cropPlaneIsActive

                for k=1:4  %four corners
                    nuPoint=rmat*([origX(k) origY(k) origZ(k)])';
                    cornerX(k)=nuPoint(1)+pointOnPlane(1);
                    cornerY(k)=nuPoint(2)+pointOnPlane(2);
                    cornerZ(k)=nuPoint(3)+pointOnPlane(3);
                end  
                set(planeHandle(planeHandleIndex),'XData',cornerX,'YData',cornerY,'ZData',cornerZ);

            end
            
            %project 3D points onto 2D plane
            normVecNorm=normVec/norm(normVec);

            set(handles.currentPts(planeHandleIndex),'XData',pts3D(:,1),'YData',pts3D(:,2),'ZData',pts3D(:,3));        
                    
            projectedPts=[];

            for k=1:size(pts3D,1)
               projectedPts(k,:)=pts3D(k,:)-dot(pts3D(k,:)-pointOnPlane,normVecNorm)*normVecNorm;
            end

            if isempty(projectedPts)
               set(handles.projectedPts(planeHandleIndex),'XData',[],'YData',[],'ZData',[]);
            else
               set(handles.projectedPts(planeHandleIndex),'XData',projectedPts(:,1),'YData',projectedPts(:,2),'ZData',projectedPts(:,3));
            end
            
            
            %get intrinsic 2D coordinates of projectedPts
            projectedPts2D=zeros(size(pts3D,1),3);
            for k=1:size(pts3D,1)
                projectedPts2D(k,:)=rmatInv*(squeeze(projectedPts(k,:)) - pointOnPlane)';
            end
                        
            %move this out of loop pre-calclute
%             clear('clusterTimeColoring');
%             for kk=1:size(currentPts,1)
%                 clusterTimeColoring(kk,:)=clusterRiseColors(clusterRiseStruct{1}.clusterMembership(kk),:);
%             end

            set(handles.trajPlane2DPlot(planeHandleIndex),'XData',projectedPts2D(:,1),'YData',projectedPts2D(:,2));
            
            
            if size(projectedPts2D,1)>1
                
                %estimate principal axes     
                [coeff,latentdiag] = eig(cov(projectedPts2D(:,1:2)));
                latent(1)=latentdiag(1,1);
                latent(2)=latentdiag(2,2);                

                meanX=mean(projectedPts2D(:,1));
                meanY=mean(projectedPts2D(:,2));

                sf=1; %overall scale factor
                
                set(handles.trajPlane2DPrincipalAxes1(planeHandleIndex),'XData',[meanX meanX+sf*sqrt(latent(1))*coeff(1,1)]);
                set(handles.trajPlane2DPrincipalAxes1(planeHandleIndex),'YData',[meanY meanY+sf*sqrt(latent(1))*coeff(2,1)]);
                set(handles.trajPlane2DPrincipalAxes2(planeHandleIndex),'XData',[meanX meanX+sf*sqrt(latent(2))*coeff(1,2)]);
                set(handles.trajPlane2DPrincipalAxes2(planeHandleIndex),'YData',[meanY meanY+sf*sqrt(latent(2))*coeff(2,2)]);
                
                %Compute and plot rotated ellipse
                thetas=linspace(0,2*pi,options.numTubeEdges)';

                circlePts=[cos(thetas) , sin(thetas)];
 
                ellipsePts=sf*((diag(sqrt(latent))*coeff)'*circlePts')'; %apply affine transform
                
                set(handles.trajPlane2DEllipse(planeHandleIndex),'XData',ellipsePts(:,1)+meanX);
                set(handles.trajPlane2DEllipse(planeHandleIndex),'YData',ellipsePts(:,2)+meanY);


                %project ellipse points back into 3D

                for k=1:size(ellipsePts,1)
                    nuPoint=rmat*([ellipsePts(k,1) ellipsePts(k,2) 0])';
                    ell3DX(k)=nuPoint(1)+pointOnPlane(1);
                    ell3DY(k)=nuPoint(2)+pointOnPlane(2);
                    ell3DZ(k)=nuPoint(3)+pointOnPlane(3);
                end  
                
                
                %project 2D points back into 3D as a check
                for k=1:size(projectedPts2D,1)
                     nuPoint =rmat*([projectedPts2D(k,1) projectedPts2D(k,2)  0  ])';
                     pp3DX(k)=nuPoint(1)+pointOnPlane(1);
                     pp3DY(k)=nuPoint(2)+pointOnPlane(2);
                     pp3DZ(k)=nuPoint(3)+pointOnPlane(3);                        
                end
                
                set(handles.trajPlaneEllipse(planeHandleIndex),'XData',ell3DX,'YData',ell3DY,'ZData',ell3DZ);
            
                set(handles.backProjPts(planeHandleIndex),'XData',pp3DX,'YData',pp3DY,'ZData',pp3DZ);

                
                ellipsePts3D{planeHandleIndex}(currentFrame,:,:)=[ell3DX', ell3DY',ell3DZ'];
            
            else
                ellipsePts3D{planeHandleIndex}(currentFrame,:,:)=zeros(options.numTubeEdges,3);

            end
            
            %compute 2D convex hull
            CH2DindicesOld=CH2Dindices;

            if size(projectedPts2D,1)>2
                %% SECTION TITLE
                % DESCRIPTIVE TEXT
                CH2Dindices{planeHandleIndex}{currentFrame} = convhull(projectedPts2D(:,1),projectedPts2D(:,2));
            else
                CH2Dindices{planeHandleIndex}{currentFrame} =1;  %just refer to the first point if less than 3
            end
            

            %set(planeHandle(nc),'XData',cornerX,'YData',cornerY,'ZData',cornerZ);

            
            %draw ring

            
%            plot3(projectedPts(currentFrame,CH2Dindices{nc}{currentFrame},1),projectedPts(currentFrame,CH2Dindices{nc}{currentFrame},2),projectedPts(currentFrame,CH2Dindices{nc}{currentFrame},3),'LineWidth',1,'Color',color(nc,clusterStruct.options.maxClusters))
%             for  m=1:min([length( CH2Dindices) length( CH2DindicesOld)])
%                 line([projectedPts(CH2Dindices(m),1) projectedPtsOld(CH2DindicesOld(m),1)],...
%                     [projectedPts(CH2Dindices(m),2) projectedPtsOld(CH2DindicesOld(m),2)],...
%                     [projectedPts(CH2Dindices(m),3) projectedPtsOld(CH2DindicesOld(m),3)],    'Color',color(nc,clusterStruct.options.maxClusters))
%             end
                


            if cropPlaneIsActive

                set(planeHandle(planeHandleIndex),'XData',projectedPts{nc}(currentFrame,CH2Dindices{nc}{currentFrame},1),'YData',projectedPts{nc}(currentFrame,CH2Dindices{nc}{currentFrame},2),'ZData',projectedPts{nc}(currentFrame,CH2Dindices{nc}{currentFrame},3));

            end

        
    end

    function GenerateTriTubes(colr)
        
       tubeStep=options.playSpeed;
        
       lighterblue=[127 207 234]/255;
       tubeColor{1}=[[255 1.4*93 1.4*181]/255;[120 231 0]/255;[255 108 0;]/255;lighterblue;MyColor('dr');];
       tubeColor{2}=[MyColor('dr');[120 231 0]/255;[255 204 0]/255;lighterblue;[255 1.4*93 1.4*181]/255];
       
       startT=floor(([ 0 .25  .5 .75 .999]*numFrames)/tubeStep)*tubeStep+1+tubeStep;
       endT=   ceil(([.25 .5 .75  .999  1]*numFrames)/tubeStep)*tubeStep;
       numClus={[1 2],[1 2],[1 2],[1 2],[1 2]};
       
       
       meshCount=0;
       
       for seg=1:5
                  
           triListTube{1}=[];
           tubePoints{1}=[];
           triListTube{2}=[];
           tubePoints{2}=[];
                
           %compute tubes        
           for nc=numClus{seg}  %# of clusters

                for t=startT(seg):tubeStep:endT(seg)

                    
    %               thisRing1=squeeze(projectedPts{nc}(t-1,CH2Dindices{nc}{t-1},:)); %for convex hull
    %               thisRing2=squeeze(projectedPts{nc}(t,CH2Dindices{nc}{t},:));

                    thisRing1=squeeze(ellipsePts3D{nc}(t-tubeStep,:,:));
                    
                    
                    thisRing2=squeeze(ellipsePts3D{nc}(t,:,:));
                    
                    thisRing1(end,:)=[];
                    thisRing2(end,:)=[];

                    numQuads=min([size(thisRing1,1) size(thisRing2,1)]);

                    if numQuads>0 && sum(thisRing1(:)) ~=0 && sum(thisRing2(:)) ~=0

                        thisRing1minned=thisRing1(1:numQuads,:);

                        thisRing2minned=thisRing2(1:numQuads,:);

                        startingIndex=FindClosestPoint(thisRing1minned(1,:),thisRing2minned);

                        thisRing2minnedRot=circshift(thisRing2minned,-startingIndex+1);

                        triList=zeros(2*numQuads-2,3);

                        for i=1:2:(2*(numQuads-1))
                            triList(i:(i+1),:)=[1 2 3; 3 2 4]+i-1;
                        end
                        triList=[triList;   1 2 length(thisRing1)*2; 1 length(thisRing1)*2-1 length(thisRing1)*2 ]; %seal the cap

                        ringsMinnedInterleaved=interleave2(thisRing1minned, thisRing2minnedRot, 'row');

                        triListTube{nc}=[ triListTube{nc} ; triList+size(tubePoints{nc},1)];

                        %axes(handles.plot3D(1));
                        %trisurf(triList,ringsMinnedInterleaved(:,1),ringsMinnedInterleaved(:,2),ringsMinnedInterleaved(:,3),'EdgeColor',color(nc,clusterStruct.options.maxClusters),'FaceColor',color(nc,clusterStruct.options.maxClusters),'FaceAlpha',0.3,'EdgeAlpha',0.8);

                        tubePoints{nc}=[tubePoints{nc} ; ringsMinnedInterleaved];

                    end       

                end
           
           %draw tubes
           %handles=KillHandle('tubes',handles);
           axes(handles.plot3D(1));
           handles.tubes(nc)=trisurf(triListTube{nc},tubePoints{nc}(:,1),tubePoints{nc}(:,2),tubePoints{nc}(:,3),'EdgeColor',tubeColor{nc}(seg,:),'FaceColor',tubeColor{nc}(seg,:),'FaceAlpha',0.3,'EdgeAlpha',0.3);

           if options.saveManifoldMesh
               v=tubePoints{nc};
               vc=randn(size(v,1),3);
               f=triListTube{nc};
               meshCount=meshCount+1;
               vertface2obj(v,f,vc,['manifoldMesh' num2str(meshCount) '.obj']);
           end
            
%            shading interp;

             lightangle(90,30);
             base('handles');
    %          handles.tubes(nc).FaceLighting = 'gouraud';
%             handles.tubes(nc).AmbientStrength = 0.3;
%             handles.tubes(nc).DiffuseStrength = 0.8;
%             handles.tubes(nc).SpecularStrength = 0.9;
%             handles.tubes(nc).SpecularExponent = 25;
%             handles.tubes(nc).BackFaceLighting = 'unlit';
%             base('handles')
           end
       


       
       end
        
       
       
    end

    function GenerateMeanTraj
        
       %compute mean trajectors      
       for nc=1:clusterRiseStruct.options.maxClusters  %# of clusters
           
            meanTrajPoints{nc}=[];
            for t=2:size(projectedPts{nc},1)
                    
                thisPointGroup=squeeze(projectedPts{nc}(t,CH2Dindices{nc}{t},:));     

                meanTrajPoints{nc}=[meanTrajPoints{nc} ; mean(thisPointGroup,1)];
                    
            end
       end
       
       %draw tubes
       handles=KillHandle('meanTraj',handles);
       axes(handles.plot3D(1));
       for nc=1:clusterRiseStruct.options.maxClusters  %# of clusters
            handles.meanTraj(nc)=plot3(meanTrajPoints{nc}(:,1),meanTrajPoints{nc}(:,2),meanTrajPoints{nc}(:,3),'Color',clusterRiseColors(nc,:), 'LineStyle','-','Marker','none','LineWidth',2*options.lineWidth);
       end
        
       
        
    end

    function UpdateHighlightRect
         if get(handles.trajectoriesPopup,'Value')==1  %single
             set(handles.highlightRect,'XData',[tv{1}(FTFrame(1)),tv{1}(FTFrame(1)),tv{1}(FTFrameEnd(1)),tv{1}(FTFrameEnd(1))]);
         end
    end

    function UpdateCounter
         if get(handles.trajectoriesPopup,'Value')==1  %single
            set(handles.frametext,'String',[num2str(FTFrame) ' - ' num2str(FTFrameEnd) '/' num2str(numFrames) ' frames']);  
         end
    end

    function set3DViewsCallback(plot3D_num)
        
        if options.phasePlot3DDualMode
           
            set(handles.plot3D(3-plot3D_num),'CameraPosition',get(handles.plot3D(plot3D_num),'CameraPosition'));
            %set(handles.plot3D(3-plot3D_num),'CameraUpVector',get(handles.plot3D(plot3D_num),'CameraUpVector'));
            %set(handles.plot3D(3-plot3D_num),'CameraTarget',get(handles.plot3D(plot3D_num),'CameraTarget'));
            %set(handles.plot3D(3-plot3D_num),'CameraViewAngle',get(handles.plot3D(plot3D_num),'CameraViewAngle'));
            set(handles.plot3D(3-plot3D_num),'CameraViewAngleMode','auto');
        
        end
    end

    function VoxelizeButtonCallback
        %figure;
        voxelResolution=20;
        for co=1:4
           [V{co},A{co}]=wbPhasePlot3DVolume(trajDataX,trajDataY,trajDataZ,timeColoring{1}==co,voxelResolution,10,[0 0 0;timeColoringColorMap]);
        end
        assignin('base','V',V);
        assignin('base','A',A);
%         renderOptions.RenderType='color';
%         renderOptions.Mview=makeViewMatrix([-1 3 1],[.1 .1 .1],[0 0 0]);
%         renderOptions.AlphaTable=.1*[0 0.4 0.4 0.4 0.4];
%         renderOptions.ColorTable=[0 0 0 ; timeColoringColorMap];
%         I=render(V,renderOptions);
%         imshow(I);
        
       %figure(handles.fig3D);
       %handles=KillHandle('volume3D',handles);
       
       C=repmat(zeros(size(A)),[1 1 1 3]);
       C(:,:,:,1)=1;
       
      % cLUT=[(0:4)', [0 0 0;timeColoringColorMap]];
      %  assignin('base','cLUT',cLUT);
%       oLUT=[ 0 0; 0.25 .25; 0.5 0.5; 0.75 .75; 1 1];
      cLUT{1}=[0 0 0 1;1 0 0 1];
      cLUT{2}=[0 1 0 0;1 1 0 0];
      cLUT{3}=[0 0 1 0;1 0 1 0];
      cLUT{4}=[0 1 1 0;1 1 1 0];
      
      oLUT=[0 0;1 0.05];
       vtkinit
       for co=1:4
         volumePlot = vtkplotvolume(4*44*A{co},cLUT{co},oLUT);
       end
       %vtkcrop(volumePlot)
       %vtkgrid

       vtkwait
       vtkdestroy()

   
%            'XData',[-max(trajDataX{1}),max(trajDataX{1})], ...
%              'YData',[-max(trajDataY{1}),max(trajDataY{1})], ...
%                'ZData',[-max(trajDataZ{1}),max(trajDataZ{1})]);
%         
    end

%%Graphics Utilities

    function AlphaDiamond(handle,XData,YData,ZData,color,alpha)
    end
        
    function RemoveFromLegend(object_handle)
        hAnnotation = get(object_handle,'Annotation');
        hLegendEntry = get(hAnnotation','LegendInformation');
        set(hLegendEntry,'IconDisplayStyle','off')
    end

    function ConvertToImage
        
        disp('wbPhasePlot3D> converting to image.');
        axesHandle=gca;
        set(axesHandle,'XTickMode','manual');
        set(axesHandle,'YTickMode','manual');
        set(axesHandle,'ZTickMode','manual');
        figureHandle=gcf;
        fAux=figure('Position',[0 0 600 600],'Colormap',get(figureHandle,'Colormap'),'Color',options.backgroundColor);
        %whitebg(fAux,options.backgroundColor);
        axisCopy=copyobj(axesHandle,gcf);
        
        set(axisCopy,'Position',[0.15 0.15 0.85 0.85]);
        set(axisCopy,'Color',options.backgroundColor);
        set(axisCopy,'Visible','off');
        drawnow;
        f=getframe(gca);
        close(fAux);
        axes(axesHandle);
        cla(gca,'reset');
        image(f.cdata);
        axis off;
        

        
        
    end
        
end