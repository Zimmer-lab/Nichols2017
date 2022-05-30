


whitebg([1 1 1]); %set background white
wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140127d_N2';

%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140624b_N2_1mMTet';

%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140127d_lite-1_punc-31_NLS3_4eggs_56um_basal21plus6stim';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140506j_inx-1_wCherry_lite-1_NLS3_66um_curved_3eggs_basalplus6stim_720s';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140411i_lite-1_punc-31_NLS3_60um_5eggs_basal21plus6stim_720s';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140127f_lite-1_punc-31_NLS3_AVF_0eggs_56um_basalplus6stim';
cd(wbdir);
clear options;
wbstruct=load([wbdir '/Quant/wbstruct.mat']);  
options.plotSplitFigures=false;
options.plotNumComps=5;
options.lineWidth=1.5;
options.plotGhostTrajectory=true;
options.VAFYLim=80;
options.timeColoringOverlay=wbgettimecoloring(wbstruct,'AVAL',@traceDerivIsPositive);
options.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR'};
options.preNormFlag=true;
options.saveFlag=true;
options.plotFlag=true;
options.plotExclusions=[];
options.savePDFFlag=true;

options.savePDFCopyDirectory=['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/ForWisconsin'];
mkdir(options.savePDFCopyDirectory);

options.range=360:2132;
options.derivFlag=1;
options.phasePlot3DView=[18 14]; %[-20 13];
options.phasePlot3DFlipZ=false;
%options.phasePlot3DLimits=[-0.1 0.15 -0.1  0.1 -0.04 0.06];
ptr={360:1068;1069:2132};

for i=1:2
    if i==2
        options.timeColoring=wbgetstimcoloring(wbstruct);
        
    end
    options.plotTimeRange=ptr{i};

    wbpca(wbdir,options);
end


%% neuronColoring

%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140127d_lite-1_punc-31_NLS3_4eggs_56um_basal21plus6stim';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140506j_inx-1_wCherry_lite-1_NLS3_66um_curved_3eggs_basalplus6stim_720s';
%wbdir='/Users/skato/Desktop/DropboxBTShare/WBDatasets_Completed/TS20140411i_lite-1_punc-31_NLS3_60um_5eggs_basal21plus6stim_720s';
%wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140624b_N2_1mMTet';
wbdir='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140127d_N2';

cd(wbdir);
pe_options.savePDFCopyDirectory=['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/ForWisconsin'];
wbpcaPhaseExplore([],[],pe_options);
    