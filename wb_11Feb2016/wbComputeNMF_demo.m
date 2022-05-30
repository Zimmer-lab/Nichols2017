%%%%%%%%%%%%%%%%%%
%wbComputeNMF demo

clear options;

%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140630h_N2_1mMTet';
wbdir=pwd;
options.fieldName='deltaFOverF';
options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR'};
options.offsetFlag=false;   %offset PCA method
options.useCorrelationsFlag=true; %i.e. use covariance instead
options.preSmoothFlag=true;
options.preSmoothingWindow=10;
options.plotNumComps=6;

options.derivFlag=false;
options.derivRegFlag=false;
options.usePrecomputedDerivs=false;
options.integrateDerivComponents=false;
%
options.saveFlag=true;  %save wbNMFstruct.mat and wbpcastruct-<details>.mat
options.plotFlag=true;  %launch wbPlotPCA afterward

options.plotPCExclusions=[]; %add PC numbers to exclude from plotting.  3D plots will use top 3 non-excluded components

numComps=6;

wbNMFstruct=wbComputeNMF(wbdir,numComps,options);