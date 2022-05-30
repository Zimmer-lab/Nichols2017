%wbMatrixPlot_demo

relationList=wbComputeRelationMatrix('?')

%%

cd(['/Users/' thisuser '/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/TS20140127d_N2']);
clear thisoptions;
thisoptions.useSavedMatrixData=true;
thisoptions.sortMethod='customcluster'; %none
thisoptions.relation='lnfit';   
thisoptions.clickable='true';
thisoptions.postProcessingFunction=@threshMat;
thisoptions.postProcessingFunctionParams=50;
thisoptions.saveFlag=false;
thisoptions.saveDir=['/Users/' thisuser '/Desktop/Dropbox/'];
wbMatrixPlot([],thisoptions);



