%%%%%%%%%%%%%%%%%%
%wbComputePCA demo AN modifications 2016-10-05
clear all
%clear options;

%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140630h_N2_1mMTet';
wbdir=pwd;
wbload;
options.fieldName='deltaFOverF_bc';

%If running on 21% period:
% range1=ceil(wbstruct.fps*360);
% range2=floor(wbstruct.fps*720);
% options.range=range1:range2;

%If running on active brain states:
% awbQuiLoad
% calculateQuiescentRange
% options.range=rangeA;

%options.extraExclusionList={'4','74','BAGL','AQR','URXL','URXR','AWBL','AWBR'};
%options.extraExclusionList={'5','80','81','83','BAGL','BAGR','AQR','URXL','URXR', 'IL2DL','IL2DR','AUAL','AUAR','ASKL', 'ASKR', 'AWBL', 'AWBR','AWCL', 'AWCR', 'AVFL', 'AVFR'};
%options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AUAL','AUAR','RMGL','RMGR','IL2DL','IL2DR','AVFL', 'AVFR'};

options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AUAL','AUAR',...
    'RMGL','RMGR','IL2DL','IL2DR','AVFL','AVFR','ASKL','ASKR','AWBL','AWBR','AWCL','AWCR'};%

%N2 Pre
%8a 3,51,52,78
%8b 3,64,65
%8j 5,106
%2b 
%2d 7, 75
%2e
%2h 102,36
%2i 
%8c 8
%8e 5
%8f

%N2 Let
%26k 4,80, 81,86,87
%12a 7
%12d 6,73,74, 81,82
%12g 5,80,81,83,116
%12i 51,77,80,84
%...
%7f 4,41,51
%7h 9,75,77
%7j none

%npr-1 Pre
%30a 5
%30b 4,9,74 AVFL, AVFR 
%30c 2,6,8,64,95
%30e 52, 84,108
%30g 5,62,85, AVFR, 'AVFR',
%30i 4,89
%7b 85,97 AVFL 
%7d 62
%10a 57,58 
%17a 51,78,79

%npr-1 Let
%31a 67,69,73
%31b 6,93,94
%31d 6,69,70,74,
%31e 5
%31f 3,78
%31g 4,77 
%31i  73,74,77
%31j 4 and take out 'AVFR'
%31k 3,41,72,75
%12a 5, 82,83,87,88
%12b 54, 63

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
