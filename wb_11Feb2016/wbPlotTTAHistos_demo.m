%wbPlotTTAHistos_demo

%analyze data
CTTAoptions.transitionTypes='SignedAllRises';
CTTAoptions.delayCutoff=10;
wbCompileTTA(pwd,CTTAoptions);

CTTAoptions.transitionTypes='SignedAllFalls';
CTTAoptions.delayCutoff=10;
wbCompileTTA(pwd,CTTAoptions);



%% plot data

%NOT CURRENTLY WORKING: 

options.subPlotFlag=true;
options.savePDF=false;
options.sortingMethod='Modality';
options.plotStairStep=true;
options.plotSpacing=10;

figure('Position',[0 0 800 1200],'Name',['TTA histograms']);
subtightplot(1,2,1,[0.05 0.1]);
wbPlotTTAHistos('GlobalTTA-SignedAllRises.mat',options)


subtightplot(1,2,2,[0.05 0.1]);
wbPlotTTAHistos('GlobalTTA-SignedAllFalls.mat',options)


export_fig(['TTAHistos-Both-SortedBy' options.sortingMethod '.pdf']);



%%plot data split into figures




%% plot all data

%WORKING:
h w;
c;
clear options;
options.maxPlotsPerPanel=22;

options.subPlotFlag=false;
options.savePDF=true;
options.sortingMethod='Modality';
options.plotStairStep=true;
options.plotSpacing=20;
options.plotGaussians=false;

wbPlotTTAHistos('GlobalTTA-SignedAllRises.mat',options)
wbPlotTTAHistos('GlobalTTA-SignedAllFalls.mat',options)









