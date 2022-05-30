%%
% This script will calculate the fraction of neurons active, as defined by
% a cutoff of RMS. It will do it for bins across a recording. It is a
% batch version in of itself.
clear all

ResultsStructFilename = 'FractionRMSactive_1m_'; %This structure will be saved in the top folder.

RMSActiveThreshold = 0.2;

BinSize = 60; %in seconds

FullRecordingLength = 1080; %(in seconds)

options.extraExclusionList = {'BAGL','BAGR','AQR','URXL','URXR'}; %, 'IL2DL','IL2DR','AUAL', 'AUAR'

%%
QuiesceBoutFlag = 0;

Analysis = @rms; 

plotflag = 0; 

MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

%Number of bins
BinNum = FullRecordingLength/BinSize;

FractionActiveRMS = struct;
FractionActiveRMS.Fractions = NaN(BinNum,NumDataSets);
FractionActiveRMS.RMSActiveThreshold =RMSActiveThreshold;
FractionActiveRMS.NeuronsDiscluded = options.extraExclusionList;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');
 
for ii = 1:NumDataSets %Folder loop
    
    load(ResultsStructFilename);

    cd(FolderList{ii})
    
    %% Find RMS of each neuron in each bin

    %There will be some very small artefacts as the seconds are being converted
    %to frames. But this will be small overlaps or misses of 1-2 frames.
    
    EpochNum = 1;
    wbload;
    for EpochNum = 1:BinNum;
        TimePoint1 = EpochNum*BinSize;
        if EpochNum ==1; %First epoch
            options.rangeSeconds = 0:BinSize;
            awbPowerDist
            IndividualRMSFraction(EpochNum,:) = RangeAnalysed; 
        else %in between epochs
            options.rangeSeconds = (TimePoint2+0.3):TimePoint1; %Now takes the next bin from +0.3 second (as it is close to a 1 frame) from the end of the last bin.
            awbPowerDist
            IndividualRMSFraction(EpochNum,:) = RangeAnalysed;
        end
        TimePoint2 = TimePoint1;
        clearvars RangeAnalysed
        options = rmfield(options, 'range');
    end
    clearvars EpochNum TimePoint1 TimePoint2

    NeuronNumber = length(IncludedNeurons);

    %Find number of values above RMSActiveThreshold
    [idx1, idx2] =size(IndividualRMSFraction);

    IndividualFractionAboveThreshold =zeros(idx1,1);
    iii =1;
    for iii = 1:idx1;
        IdxAboveThreshold = find(IndividualRMSFraction(iii,:)>RMSActiveThreshold);
        NumAboveThreshold = length(IdxAboveThreshold);
        IndividualFractionAboveThreshold(iii,1) = NumAboveThreshold/NeuronNumber;
    end
    clearvars IndividualRMSFraction 
    %% Batch part

    FractionActiveRMS.ExpID{ii}= wbstruct.trialname;
    
    FractionActiveRMS.Fractions(1:BinNum,ii)= IndividualFractionAboveThreshold(1:BinNum,1);
    
    FractionActiveRMS.NeuronNum(1,ii)= NeuronNum(1,1);
    
    cd(MainDir)
    dateRun = datestr(now);
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'FractionActiveRMS','dateRun'); 
    clearvars wbstruct
    
end
clearvars -except FractionActiveRMS
