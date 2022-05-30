%%%%%%%%%%%%%%%%%%
%wbTreeRun_demo
%
%Make sure you use the @ sign for referencing functions!
%
%Put function parameters, if any, in a cell array and make it the third
%argument


%this is used by all the code blocks below:
rootFolder='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets';


%% Run wbMakeSimpleStruct on all dataset folders within a folder

cd(rootFolder);
wbTreeRun(@wbMakeSimpleStruct,rootFolder);

%% Run wbAddDerivs on all dataset folders within a folder

cd(rootFolder);
wbTreeRun(@wbAddDerivs,rootFolder);

%% Run PCA on all dataset folders within a folder
rootFolder=pwd;

clear options;
options.fieldName='deltaFOverF';
options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR'};  %you can add SIMPLE NUMBERS here.
options.offsetFlag=false;   %offset PCA method
options.useCorrelationsFlag=true; %i.e. use covariance instead
options.preSmoothFlag=false;
options.preSmoothingWindow=10;
%
options.derivFlag=true;
options.derivRegFlag=true;
options.usePrecomputedDerivs=true;
options.integrateDerivComponents=true;
%
options.saveFlag=true;  %save wbpcastruct.mat and wbpcastruct-<details>.mat
options.plotFlag=false;  %launch wbPlotPCA afterward

cd(rootFolder);

wbTreeRun(@wbComputePCA,rootFolder,{[],options});

%% plot and save all gridplots for all dataset folders within a folder
clear options;
options.hideExclusions=true;
options.sortMethod='power';
options.saveDir=pwd;
cd(rootFolder);
wbTreeRun(@wbGridPlot,rootFolder,{[],options});


%% create SimpleNeuronTrackingMovie for all dataset folders within a folder

clear options;
cd(rootFolder);
options.saveDir=pwd;
wbTreeRun(@wbMakeSimpleNeuronTrackingMovie,rootFolder,options);


%% Create wbPlotTTA for all dataset folders within a folder



rootFolder=pwd;
clear options;

options.neuronSubset='topNeurons50';
% options.neuronSubset={'RIBL','AVBR','rmev','rmer','rmed','AIBR','AIBL','AVAL','AVAR','RIMR','RIML','OLQVL','OLQDL','OLQVR','OLQDR'};
% options.neuronSigns=[1 1 -1 -1 -1 1 1 1 1 1 1 1 1 1 1];
% options.neuronNumGaussians=[1 1 1 1 1 2 2 1 1 1 1 1 1 1 1];

options.refNeuron='AVAL';
options.savePDFCopyName=['wbTTA-ref' options.refNeuron '-NoStim-AllN-AllSignedRises-Compilation.pdf'];
options.savePDFDirectory=pwd;
options.appendToPDFCopy=true;
options.transitionTypes='SignedAllRises';
options.useValueNotRank=true;
options.savePDFFlag=true;
options.plotTextLabels=false;
options.mixedLineStyles=true;

options.delayCutoff=15;

wbTreeRun(@wbPlotTTA,rootFolder,{[],options},1,true);



%% Same as above but Falls

rootFolder=pwd;
clear options;
options.neuronSubset='topNeurons20';
%options.neuronSubset={'RIBL','AVBR','rmev','rmer','rmed','AIBR','AIBL','AVAL','AVAR','RIMR','RIML','OLQVL','OLQDL','OLQVR','OLQDR'};
% options.neuronSigns=[1 1 -1 -1 -1 1 1 1 1 1 1 1 1 1 1];
% options.neuronNumGaussians=[1 1 1 1 1 2 2 1 1 1 1 1 1 1 1];

options.refNeuron='AVAL';
options.savePDFCopyName=['wbTTA-ref' options.refNeuron '-NoStim-AllNeurons-AllSignedRises-Compilation.pdf'];
options.savePDFDirectory=pwd;
options.appendToPDFCopy=true;
options.transitionTypes='SignedAllRises';
options.useValueNotRank=true;
options.savePDFFlag=true;
options.plotTextLabels=false;
options.mixedLineStyles=true;

options.delayCutoff=15;

wbTreeRun(@wbPlotTTA,rootFolder,{[],options},1,true);

