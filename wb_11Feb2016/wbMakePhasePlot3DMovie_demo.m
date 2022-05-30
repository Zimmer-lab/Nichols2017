%wbMakePhasePlot3DMovie_demo
clear options;
%cd('/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140127d_N2');
wbstruct=wbload;


options.width=640;
options.height=480;
options.frameRate=40;
    
options.smoothFlag=true;  %smooth derivs after computation
options.smoothingWindow=5;

%options.timeColoringFlag=true;
%options.timeColoring=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL');  %use pre-saved thresholds
options.integrateDerivComponents=false;

options.plotWallProjectionsFlag=true;

options.lineWidth=4;
options.trajectoryCurrentTimeMarkerSize=10;  %size of the green dot
options.backgroundColor='white';
options.plotGhostTrajectory=true;
options.trajectoryColor='b';

options.ghostTrajectoryColor=[0.5 0.5 0.5];
options.outputDirectory=['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/Catchall'];


options.cameraViewParamsFile='cameraViewParams.mat';
options.wiggleCameraFlag=false;


%options.cameraView=[90 -180];%18 24
% options.xWall=[-0.8, 0.5];
% options.yWall=[-0.2, 0.6];
% options.zWall=[-0.3, 0.2];
wbMakePhasePlot3DMovie([],[],options);

