%%%%%%%%%%%%%%%%%%
%wbComputePCA demo AN modifications 2015-09-23

clear options;

%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140630h_N2_1mMTet';
wbdir=pwd;
wbload;
options.fieldName='deltaFOverF_bc';
range1=ceil(wbstruct.fps*360);
range2=floor(wbstruct.fps*720);
options.range=range1:range2;
%options.extraExclusionList={'4','74','BAGL','AQR','URXL','URXR','AWBL','AWBR'};

options.extraExclusionList={'5','80','81','83','BAGL','BAGR','AQR','URXL','URXR', 'IL2DL','IL2DR','AUAL','AUAR','ASKL', 'ASKR', 'AWBL', 'AWBR','AWCL', 'AWCR', 'AVFL', 'AVFR'};
options.dimRedType='PCA';   %'PCA' or 'OPCA' or 'NMF'
options.numOffsetSteps=25;  %only used for OPCA
%options.useCorrelationsFlag=true; %i.e. use covariance instead, don't use
%this anymore, although it still works by setting preNormalizationType to
%'rms'

options.preNormalizationType='peak'; %or 'peak' or 'RMSDeriv' or 'peakDeriv' or 'none', 'D' indicates working on derivative
options.preSmoothFlag=false;
options.preSmoothingWindow=10;
%
options.derivFlag=true; %CHECK
options.derivRegFlag=true;
options.usePrecomputedDerivs=true;
%
options.saveFlag=true;  %save wbpcastruct.mat and wbpcastruct-<details>.mat
options.plotFlag=true;  %launch wbPlotPCA afterward

wbpcastruct=wbComputePCA(wbdir,options);



%after this use wbPlotPCA or wbPlotPCA_demo to plot
