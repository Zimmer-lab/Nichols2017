%% awbRMSAverage
% This script will calculate the RMS or mean. It will do it for bins across a recording. 
% It will go across all recordings within one folder
clear all

ResultsStructFilename = 'skewness_average_1m_allNeurons'; %This structure will be saved in the top folder.

BinSize = 60; %in seconds

FullRecordingLength = 1080; %(in seconds)
Analysis = @mean; %rms

%options.extraExclusionList = {'BAGL','BAGR','AQR','URXL','URXR'}; %, 'IL2DL','IL2DR','AUAL', 'AUAR'
options.extraExclusionList = {};
%%
Analysis2 = @skewnessDim;
RMSActiveThreshold = 0.2;
%%
QuiesceBoutFlag = 0;

plotflag = 0; 

MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

%Number of bins
BinNum = FullRecordingLength/BinSize;

AnalysisAverage = struct;
AnalysisAverage.Average = NaN(BinNum,NumDataSets);
AnalysisAverage.NeuronsDiscluded = options.extraExclusionList;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');

%%
for ii = 1:NumDataSets %Folder loop
    
    load(ResultsStructFilename);

    cd(FolderList{ii})
    
    %% Find RMS/mean of each neuron in each bin
    %There will be some very small artefacts as the seconds are being converted
    %to frames. But this will be small overlaps or misses of 1-2 frames.
    
    EpochNum = 1;
    wbload;
    IndividualRMSaverage = [];%nan(BinNum,NeuronNumber);
    for EpochNum = 1:BinNum;
        TimePoint1 = EpochNum*BinSize;
        if EpochNum ==1; %First epoch
            options.rangeSeconds = 0:BinSize;
            awbPowerDist
            IndividualRMSaverage(EpochNum,:) = RangeAnalysed; 
        else %in between epochs
            options.rangeSeconds = (TimePoint2+0.3):TimePoint1; %Now takes the next bin from +0.3 second (as it is close to a 1 frame) from the end of the last bin.
            awbPowerDist
            IndividualRMSaverage(EpochNum,:) = RangeAnalysed;
        end
        TimePoint2 = TimePoint1;
        clearvars RangeAnalysed
        options = rmfield(options, 'range');
    end
    
    %AnalysisAverage.mins(1,ii) = min(mean(wbstruct.simple.deltaFOverF_bc(:,IncludedNeurons)));
    %AnalysisAverage.maxes(1,ii) = max(mean(wbstruct.simple.deltaFOverF_bc(:,IncludedNeurons)));
    
    %data = mean(wbstruct.simple.deltaFOverF_bc(:,IncludedNeurons),2);
    
    %AnalysisAverage.tenthPC(1,ii) = mean(data(prctile(data,10) < data));
    %AnalysisAverage.ninetiethPC(1,ii) = mean(data(prctile(data,90) < data));
   
    clearvars EpochNum TimePoint1 TimePoint2

    %% Batch part

    AnalysisAverage.ExpID{ii}= wbstruct.trialname;
    
    AnalysisAverage.Average(1:BinNum,ii)= Analysis(IndividualRMSaverage(1:BinNum,:)');

    AnalysisAverage.NeuronNum(1,ii)= NeuronNum(1,1);
    
    cd(MainDir)
    dateRun = datestr(now);
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'AnalysisAverage','dateRun'); 
    clearvars wbstruct IndividualRMSaverage 

    
end
clearvars -except AnalysisAverage
