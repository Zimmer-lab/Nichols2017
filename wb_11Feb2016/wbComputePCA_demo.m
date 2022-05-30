%%%%%%%%%%%%%%%%%%
%wbComputePCA demo

clear options;

%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140630h_N2_1mMTet';
wbdir=pwd;
options.fieldName='deltaFOverF';
options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AVFL','AVFR'};
options.dimRedType='PCA';   %'PCA' or 'OPCA' or 'NMF'
options.numOffsetSteps=25;  %only used for OPCA
%options.useCorrelationsFlag=true; %i.e. use covariance instead, don't use
%this anymore, although it still works by setting preNormalizationType to
%'rms'

options.preNormalizationType='peak'; %or 'peak' or 'RMSDeriv' or 'peakDeriv' or 'none', 'D' indicates working on derivative
options.preSmoothFlag=false;
options.preSmoothingWindow=10;
%
options.derivFlag=true;
options.derivRegFlag=true;
options.usePrecomputedDerivs=true;
%
options.saveFlag=true;  %save wbpcastruct.mat and wbpcastruct-<details>.mat
options.plotFlag=false;  %launch wbPlotPCA afterward

wbpcastruct=wbComputePCA(wbdir,options);



%after this use wbPlotPCA or wbPlotPCA_demo to plot
