function [RealMeans,nExperiments,nTracksPerExp,numTrack,SingleRecordNames] = SleepStats_Get_MeanReadout(Input)

%% Mean and details
% This script is used to get out information from a stats file.

% Enter file path and name to a file (select) made from
% SleepAlsV12Quant_stats scripts. Make sure the BehaviourstateBin,
% ConditinoalBinSec and AlsBinSec are the same when comparing two datasets.
%clear all

%Dataset 1, must end with .mat
%Input = '//Users/eichler/Downloads/data_TA_receptors_set/lethargus/N2-males_2.Lethargus__select.mat';
%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2/BAG-npr-1-ZIM465_18C_O2_21.0_s_2.Lethargus__select.mat';

%%%%%%%%%%%%%%%%%%%%
%% Make input vectors
% Makes an input vector for each experiment
DataSets = struct;
dataInfo = struct;
load(Input)

fprintf('   * Calling SleepStats_Get_MeanReadout %s\n',Input);

%Find the different recording names
[r,~] = size(CollectedTrksInfo.alsName);

datePosition = strfind(CollectedTrksInfo.alsName,'201');
RecordNames = {};

for iii = 1:r;
    CurrDatePosition = datePosition{iii,1}(1,1);
    RecordNames{iii,1} = CollectedTrksInfo.alsName{iii}(CurrDatePosition:(CurrDatePosition+10));
end

%Get unique names 
RecordNames2 = {};
for iii = 1:r;
    CurrDatePosition = datePosition{iii,1}(1,1);
    RecordNames2{iii,1} = CollectedTrksInfo.alsName{iii}(1:(CurrDatePosition+10));
end
SingleRecordNames = unique(RecordNames2);

[rr,~]= size(RecordNames);
strMat = [];
for jj =1:rr;
    strA = RecordNames{jj,1};
    for iii =1:rr;
        strB = RecordNames{iii,1};
        strMat(jj,iii) = strcmp(strA,strB);
    end
end

L=bwlabel(strMat,4); %label connected periods of motion = motion bouts

expStats= {};
expStats=regionprops(L,'BoundingBox'); %create structure that contains duration and start / end of connected periods

[nExperiments, ~] = size(expStats);

dataInfo.nExperiments = nExperiments;

%Find number of alsStim per recording (2 stim per als file but
%sometimes only 1 is counted)
nAlsStim = [];
for iii = 1:nExperiments;
    nAlsStim(iii,1) = expStats(iii, 1).BoundingBox(1,4);
end
clear expStats L strMat strB strA RecordNames CurrDatePosition datePosition rr RecordNames2

%Find number of tracks per stimulus.
nTracksPerStim = [];
for iii = 1:length(CollectedTrksInfo.SleepTrcksNum)
    nTracksPerStim(iii,1) = length(CollectedTrksInfo.SleepTrcksNum{iii, 1});
end

%Find number of tracks per experiment
beginStimN = 1;
nTracksPerExp = [];
for jj = 1:nExperiments;
    nTracksPerExp(jj,1) = sum(nTracksPerStim(beginStimN:(nAlsStim(jj)+beginStimN-1)));
    beginStimN = nAlsStim(jj)+beginStimN;
end
clear beginStimN nAlsStim

dataInfo.nTracksPerExp = nTracksPerExp;

cumNTracksPerExp = cumsum(nTracksPerExp);

%Get the real means for each experiment
startingTrack = 1;
for jj = 1:nExperiments;
    RealMeans(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
    startingTrack = cumNTracksPerExp(jj)+1;
end
clear startingTrack cumNTracksPerExp

%Get the full data sets
DataSets.dataset = nanmean(CollectedTrksInfo.SleepTrcks');


% Read out N values
numTrack = (length(DataSets.dataset));

%Note this is the number of tracks which were included, some tracks in the
%CollectedTrksInfo are only NaNs and are therefore discluded.

% clearvars -except RealMeans numTrack dataInfo

end