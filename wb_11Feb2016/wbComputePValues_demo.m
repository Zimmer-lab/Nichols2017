%wbComputePValues_demo

%% ONE CYCLE HIGH TIME RESOLUTION

options.transitionType='both';
options.phaseRange=[-0.5 1.75];
options.includeDerivsFlag=true;
options.derivsOnlyFlag=false;

options.usePCAStruct=true;
options.pcSelection={1:3}; %{1,2,3,1:2,1:3};

%soptions.neuronSelection={'AVA','SMDV'};

options.timeWarpRangePerPoint=.001;
options.timeWarpStepSize=.05;
options.phaseOffset=options.timeWarpStepSize/2;
options.derivStrength=50;
options.plotFlag=false;
options.bootstrapNumIterations=10000;


rootfolder='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/NoStim/&fixed/';
wbDir=listfolders(rootfolder,true);
pValueStructFine=wbComputePValues(wbDir,options);

%% plot 
plotOptions.binningFactor=1;
plotOptions.subPlotFlag=true;
plotOptions.plotLogScale=true;
plotOptions.showIndividualTraces=false;
plotOptions.showMeanTrace=true;
plotOptions.showSEMBand=false;
plotOptions.showSEMBars=true;
plotOptions.showPhaseColorRects=true;
plotOptions.savePDFFlag=false;
plotOptions.showTitle=false;

figure('Position',[0 0 400 400],'Color','w');

subtightplot(2,1,1,[.05 .05],[.1 .1],[.1 .025]);
plotOptions.transitionType='rise';
wbPlotPValues(pValueStructFine,plotOptions);
set(gca,'XTickLabel',{'-p','','-p/2','','0','','p/2','','p',''},'fontname','symbol');
set(gca,'YTick',[.00001 .0001 .001 .01 .1 1]);

subtightplot(2,1,2,[.05 .05],[.1 .1],[.1 .025]);
plotOptions.transitionType='fall';
wbPlotPValues(pValueStructFine,plotOptions);
set(gca,'XTickLabel',{'-p/2','','0','','p/2','','p','','3p/2',''},'fontname','symbol');
set(gca,'YTick',[.00001 .0001 .001 .01 .1 1]);


export_fig('PValueVsTime-ONECYCLE-BOTH-PaperDraft.pdf');
%options.transitionType='Fall';
%wbComputePValues(pwd,options);


%% NON DERIV  VS DERIV
    

wbDir=pwd;

clear options;
options.transitionType='Rise';
options.phaseRange=[-0.5 1.5];
options.includeDerivsFlag=false;
options.derivsOnlyFlag=false;
options.usePCAStruct=true;
options.pcSelection={1:3}; %{1,2,3,1:2,1:3};


options.timeWarpFramesPerPoint=10;
options.timeWarpFrameStepSize=200;
options.bootstrapNumIterations=10000;

computeOptions.extraExclusionList={'BAGL','BAGR','AQR','URXL','URXR','AVFL','AVFR'};    
computeOptions.preNormalizationType='peak';
computeOptions.dimRedType='PCA';   %'PCA' or 'OPCA' or 'NMF'
           
%computeOptions.numOffsetSteps
%computeOptions.numComponentsToDrop
        
computeOptions.neuronSubset=[];
computeOptions.fieldName='deltaFOverF';
computeOptions.preSmoothFlag=false;         
computeOptions.preSmoothingWindow=[];        
computeOptions.derivRegFlag=true;               
computeOptions.usePrecomputedDerivs=true;
%computeOptions.refNeuron=options.refNeuron;




options.recomputePCA=true;
computeOptions.derivFlag=false;
options.recomputePCAOptions=computeOptions;




pValueStructNONDERIV=wbComputePValues(wbDir,options);

options.recomputePCA=true;
computeOptions.derivFlag=true;
options.includeDerivsFlag=false;
options.recomputePCAOptions=computeOptions;

pValueStructDERIV=wbComputePValues(wbDir,options);


%% plot

plotOptions.binningFactor=4;


plotOptions.subPlotFlag=false;
plotOptions.meanTraceColor='b';
plotOptions.plotLogScale=true;
plotOptions.showIndividualTraces=false;
plotOptions.showMeanTrace=true;
plotOptions.showSEM=true;
wbPlotPValues(pValueStructNONDERIV,plotOptions);

plotOptions.subPlotFlag=true;
plotOptions.meanTraceColor='r';
wbPlotPValues(pValueStructDERIV,plotOptions);

%export_fig('ClusterPValueVsTime-RISE-RAWPCA123VsDerivPCA123-0715e.pdf')




%% MULTICYCLE DYNAMICS

clear options;

options.transitionType='both';
options.phaseRange=[-12 12];
options.includeDerivsFlag=true;
options.derivsOnlyFlag=false;
options.phaseOffset=0.625; %0.125;
options.usePCAStruct=true;
options.pcSelection={1:3}; %{1,2,3,1:2,1:3};

%soptions.neuronSelection={'AVA','SMDV'};

options.timeWarpRangePerPoint=0.25;
options.timeWarpStepSize=1;
options.derivStrength=50;
options.plotFlag=false;
options.bootstrapNumIterations=10000;


rootfolder='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/NoStim/&fixed/';
wbDir=listfolders(rootfolder,true);
pValueStructLONG=wbComputePValues(wbDir,options);

%%

plotOptions.showPhaseLines=false;
plotOptions.subPlotFlag=false;
plotOptions.plotLogScale=true;
plotOptions.showIndividualTraces=false;
plotOptions.showMeanTrace=true;
plotOptions.showSEMBand=false;
plotOptions.meanTraceColor='k';
wbPlotPValues(pValueStructLONG,plotOptions);

%options.transitionType='Fall';
%wbComputePValues(pwd,options);