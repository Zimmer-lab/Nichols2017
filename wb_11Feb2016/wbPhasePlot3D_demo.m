%wbPhasePlot3D_demo




%plot 3 datasets in PC-space of the first


clear options;

%%%
options.projectOntoFirstSpace=true;

options.plotGhostTrajectory=false;


options.smoothFlag=true;  %smooth derivs after computation
options.smoothingWindow=5;

options.phasePlot3DMainColor=[0.5 0.5 0.5];
options.phasePlot3DView=[18 14]; %[-20 13];
options.phasePlot3DFlipZ=false;

basedir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/NoStim/&fixed/';
ds{1}=[basedir filesep 'TS20140926d_lite-1_punc-31_NLS3_RIV_2eggs_1mMTet_basal_1080s'];
ds{2}=[basedir filesep 'TS20140905c_lite-1_punc-31_NLS3_AVHJ_0eggs_1mMTet_basal_1080s'];
ds{3}=[basedir filesep 'TS20140715e_lite-1_punc-31_NLS3_2eggs_56um_1mMTet_basal_1080s'];


%PLOT FOUR STATE COLORING 
for i=1:3
    wbstruct=wbload(ds{i},false);
    options.timeColoring{i}=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL');  %use pre-saved thresholds
end

computeOptions.neuronSubset=wbListIDsInCommon({ds{1},ds{2},ds{3}});

computeOptions.fieldName='deltaFOverF';
computeOptions.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AVFL','AVFR'};
computeOptions.dimRedType='OPCA';   %'PCA' or 'OPCA' or 'NMF'
computeOptions.numOffsetSteps=25;  %only used for OPCA
computeOptions.preNormalizationType='peak'; %or 'peak' or 'RMSDeriv' or 'peakDeriv' or 'none', 'D' indicates working on derivative
computeOptions.preSmoothFlag=false;
computeOptions.derivFlag=true;
computeOptions.derivRegFlag=true;
computeOptions.usePrecomputedDerivs=true;
computeOptions.saveFlag=false;  %save wbpcastruct.mat and wbpcastruct-<details>.mat
computeOptions.plotFlag=false;  %launch wbPlotPCA afterward

for i=1:3
    cd(ds{i});
    wbpcastructs{i}=wbComputePCA(ds{i},computeOptions);
end


wbPhasePlot3D({wbpcastructs{1},wbpcastructs{2},wbpcastructs{3}},options);





%% plot 3 neuron's activities against each other

%cd to the data directory first
clear options;
wbstruct=wbload([],false);
neurons={'AVAL','RIVL','RIBL'};
[traces,simpleIndices]=wbGetTraces(wbstruct,[],[],neurons);
derivs=wbstruct.simple.derivs.traces(:,simpleIndices);
options.smoothFlag=true;
options.smoothingWindow=5;
options.axisLabels=neurons;
options.drawTransitionPlane=false;
wbPhasePlot3D(derivs,options);   %use this line for derivs
%wbPhasePlot3D(traces,options);  %use this line for non-derivs

saveas(gcf, ['NeuronPhasePlot-' neurons{1}  '-' neurons{2} '-' neurons{3} '-'  wbMakeShortTrialname(wbstruct.trialname)  '.fig'], 'fig');
