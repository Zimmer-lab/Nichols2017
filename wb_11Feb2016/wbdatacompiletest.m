%wbdatacompile test

dataFolders{1}='/Users/skato/Desktop/DropboxBT/WholeBrainDatasets/TS20140127d_lite-1_punc-31_NLS3_4eggs_56um_basal21plus6stim';
dataFolders{2}='/Users/skato/Desktop/DropboxBT/WholeBrainDatasets/TS20140127f_lite-1_punc-31_NLS3_AVF_0eggs_56um_basalplus6stim';

neuronNames{1}='ADAL';
neuronNames{2}='ADAR';

wbcompilation=wbdatacompile(dataFolders,neuronNames);

%%

figure;
plot(wbcompilation.tv_resampled,wbcompilation.traces_resampled);

legend(wbcompilation.neuronNames)

