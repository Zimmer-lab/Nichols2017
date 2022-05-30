%% Script for extracting and averaging the RMS values of WBI data

clear all;

ResultsStructFilename = 'CompareRMS.mat';

MasterFolder = '/Users/nichols/Documents/Imaging/MasterFolder';

TopFolder = pwd;

folders= dir;
directoryNames = {folders([folders.isdir]).name};
directoryNames = directoryNames(~ismember(directoryNames,{'.','..'}));

Final = (length(dir));
for runthrough = 1:Final

    cd (directoryNames{runthrough})
    
    WorkingFolder = cd;
    
    newPath = fullfile(cd, 'Quant');
    
    cd(newPath);
    
    load('wbstruct.mat');
    
    cd(WorkingFolder)
    
    tvi = ((0:5399)/5)';
    
    wbstruct.deltaFOverF = interp1(tv,deltaFOverF,tvi);
    
    run wbPlotEvalTimeSeriesAx
    
    CompareRMS.setID{runthrough} = trialname
    
    load('/Users/nichols/Documents/Imaging/MasterFolder/evalTimeSeries');
    
    %CompareRMS.RMS(runthrough,:) = mean(evalTimeSeries,2);
    meanevalTimeSeries = mean(evalTimeSeries,2);
    
    %RMStv = (10.2:19.9962:1059.8); % The bin# vector that the RMS values will be put onto, made as a 5fps struct.
    %NumBins = round((length(tv))/100);
    %RMStvorig = (1:NumBins);
    %for keeper=1:NumBins; 
    %    RMStvorig(keeper) = ((100*keeper)-50)/fps; 
    %end
    CompareRMS.RMS(runthrough,:) = meanevalTimeSeries;
    
    %clear('meanevalTimeSeries');
    
    clear('wbstruct2');
    
    cd(TopFolder);
    
    %need to put RMS values onto same x axis.
    %export_fig([options.saveDir '/TimeseriesPlot-' options.evalType  '-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-transparent');
end