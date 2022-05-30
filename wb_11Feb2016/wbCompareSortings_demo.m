%%%%%%%%%%%%%%%%%%%%
%%wbCompareSortings_demo


%% look at PC Coefficient orderings for all PCs of a single dataset

%cd('/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140715f_N2_1mMTet_nostim');
clear options;
options.sortMethod='pcaloading';
options.saveDir=pwd;
wbCompareSortings([],options);


