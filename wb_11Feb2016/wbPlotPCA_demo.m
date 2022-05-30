%%%%%%%%%%%%%%%
%wbPlotPCA demo


whitebg([1 1 1]); %set background white

wbdir=pwd;

%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140630h_N2_1mMTet';
%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140127d_N2';
%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140624b_N2_1mMTet';


cd(wbdir);
clear options;
wbstruct=load([wbdir '/Quant/wbstruct.mat']);  

options.plotSplitFigures=true;

options.plotNumComps=5;
options.lineWidth=2;
options.stimulusPlotSyle='solid';
options.VAFYLim=100;

%PLOT MULTIPLE OVERLAYS
options.timeColoringOverlay{1}=(wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2);  %2 is "rise state"
options.timeColoringOverlay{2}=(wbFourStateTraceAnalysis(wbstruct,'useSaved','RID')==2);
options.timeColoringOverlayColor{1}='r';
options.timeColoringOverlayColor{2}='b';
options.timeColoringOverlayLegend={'AVAL','RID'};
options.timeColoringShiftBalls=true;  %shift balls so overlaps can be seen.
 

%DUAL MODE (derivs plus integrated derivs)
%THIS IS OBSOLETE.  Use wbPhasePlot3D.m for dual mode phase plots.
%options.phasePlot3DDualMode=false;

%GHOST TRAJECTORY (GRAY LINE FOR WHOLE TRACE)
options.plotGhostTrajectory=false;

%PLOT FOUR STATE COLORING 
options.timeColoring=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL');  %use pre-saved thresholds

%COLOR PRE/POST STIM
% stimOnsetFrame=find(wbstruct.tv>=wbstruct.stimulus.switchtimes(1),1,'first');
% options.timeColoring=[ones(stimOnsetFrame-1,1) ; zeros(length(wbstruct.tv)-stimOnsetFrame+1 ,1) ];
% options.timeColoringColorMap=[color('b');color('gray')];

options.smoothFlag=true;  %smooth derivs after computation
options.smoothingWindow=5;

options.plotFlag=true;
options.plotPCExclusions=[]; %add PC numbers to exclude from plotting.  3D plots will use top 3 non-excluded components
options.savePDFFlag=true;

options.combinePDFFlag=true;

options.savePDFCopyDirectory=['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/Catchall'];
mkdir(options.savePDFCopyDirectory);

options.phasePlot3DMainColor=[0.5 0.5 0.5];
options.phasePlot3DView=[18 14]; %[-20 13];
options.phasePlot3DFlipZ=false;
%options.phasePlot3DLimits=[-0.1 0.15 -0.1  0.1 -0.04 0.06];

%pre-stimulus range plot
%options.plotTimeRange=360:1068;  %pre stimulus period minus first 360 frames, 1069:2132 would be post-stimulus range
wbPlotPCA(wbdir,[],options);

%% post-stimulus range plot
% options.plotTimeRange=1069:2132;
% options.timeColoring=wbgetstimcoloring(wbstruct);
% wbPlotPCA(wbdir,[],options);



%% neuronColoring

%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140127d_lite-1_punc-31_NLS3_4eggs_56um_basal21plus6stim';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140506j_inx-1_wCherry_lite-1_NLS3_66um_curved_3eggs_basalplus6stim_720s';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140411i_lite-1_punc-31_NLS3_60um_5eggs_basal21plus6stim_720s';
%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140624b_N2_1mMTet';
wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140630h_N2_1mMTet';
% 
% cd(wbdir);
% pe_options.savePDFCopyDirectory=['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/HarrisMondaySeminar'];
% wbpcaPhaseExplore([],[],pe_options);
%     




%% coloring by transition cluster



wbpcastruct=wbLoadPCA;

refNeuron='AVAL';
wbstruct=wbload([],false);
options.transitionTypes='SignedAllRises';
options.neuronSigns=[];
[traceColoring, transitionListCellArray,transitionPreRunLengthListArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved',refNeuron);
[refTrace,~, ~] = wbgettrace(refNeuron,wbstruct);
[transitions,transitionsType]=wbGetTransitions(transitionListCellArray,1,options.transitionTypes,options.neuronSigns,transitionPreRunLengthListArray);
transitionTimes=transitions/wbstruct.fps;

%reorder transitionTimes by clustering
transitionTimes_Cluster1=transitionTimes([1 2 3 6 9 10 12 14 18 20 24 25 26 ]);
transitionTimes_Cluster2=transitionTimes([4 5 7 8 11 13 15 16 17 19 21 22 23]);

options.timeWindow=1;
  
rangeLimits_C1=[floor(transitionTimes_Cluster1(:)-options.timeWindow/2),...
                          ceil(transitionTimes_Cluster1(:)+options.timeWindow/2)];
rangeLimits_C2=[floor(transitionTimes_Cluster2(:)-options.timeWindow/2),...
                          ceil(transitionTimes_Cluster2(:)+options.timeWindow/2)];

    
options.timeColoringOverlay{1}=false(3137,1);
options.timeColoringOverlay{2}=false(3137,1);
                       
for i=1:size(rangeLimits_C1,1)                   
    options.timeColoringOverlay{1}((round(rangeLimits_C1(i,1)*wbstruct.fps):round(rangeLimits_C1(i,2)*wbstruct.fps)))=true;
end

for i=1:size(rangeLimits_C2,1)                   
    options.timeColoringOverlay{2}((round(rangeLimits_C2(i,1)*wbstruct.fps):round(rangeLimits_C2(i,2)*wbstruct.fps)))=true;
end

options.timeColoringOverlayColor{1}='r';
options.timeColoringOverlayColor{2}='c';
options.timeColoringOverlayLegend={'Cluster1','Cluster2'};
options.timeColoringShiftBalls=true;  %shift balls so overlaps can be seen.
options.timeColoring=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL');  %use pre-saved thresholds

wbPhasePlot3D({wbpcastruct},options);
%wbPlotPCA(wbdir,[],options);



%% use reference coeffs from joint PCA

wbdir=pwd;
cd(wbdir);
clear options;
wbstruct=load([wbdir '/Quant/wbstruct.mat']);  


%PLOT FOUR STATE COLORING 
options.timeColoring=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL');  %use pre-saved thresholds

jointPCAstruct=load('/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/analyzedwholebraindatasets/NoStim/&fixed/wbPCAstruct');

options.neuronSubset=jointPCAstruct.neuronIDs;
options.externalCoeffs=jointPCAstruct.coeffs;

options.smoothFlag=true;  %smooth derivs after computation
options.smoothingWindow=5;


wbPlotPCA(wbdir,[],options);