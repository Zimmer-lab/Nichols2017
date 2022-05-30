%wbPlotTTA_demo.m
wbload;
clear options;
whitebg('k');
% 
% numNeurons=15; %105
% options.useOnlyIDedNeurons=true;  %will use less than 20 if some aren't IDed
% sortType='pcaloading1';
% options.neuronSubset=wbGetTopNeurons(sortType,numNeurons,[],options);
% 

%options.neuronSubset={'AIBL','RIBL','RIML','AVAL','OLQVR'}; %,'AVAL','RMER','VB02','VB01','DB02'};
%options.neuronSigns=[1 -1 1 1 1]; % 1 -1 -1 -1 -1];

% options.neuronSubset={'OLQVR','OLQVL'};
% options.neuronSigns=[1 1];

% options.neuronSubset={'AIBL','RIBL','RIML','AVAL','RMER','VB02','VB01','DB02'};
% options.neuronSigns=[1 -1 1 1 -1 -1 -1 -1];




options.neuronSubset={'rmev','rmer','rmed','AIBR','AIBL','AVAL','AVAR','RIMR','RIML','OLQVL','OLQDL','OLQVR','OLQDR'};
options.neuronSigns=[-1 -1 -1 1 1 1 1 1 1 1 1 1 1];
options.neuronNumGaussians=[1 1 1 2 2 1 1 1 1 1 1 1 1];
options.refNeuron='AVAL';
options.transitionTypes='SignedAllFalls';

options.useValueNotRank=true;
options.savePDFFlag=true;
% options.savePDFDirectory='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/Catchall';
% options.savePDFCopyName='TTA-AllNoStim.pdf';
options.appendToPDFCopy=true;
options.plotTextLabels=false;
options.mixedLineStyles=true;
options.delayCutoff=15;

values=wbPlotTTA(wbstruct,options);