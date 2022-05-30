%% Mean and details
% This script is used to get out information from a stats file.

% Enter file path and name to a file (select) made from
% SleepAlsV12Quant_stats scripts. Make sure the BehaviourstateBin,
% ConditionalBinSec and AlsBinSec are the same when comparing two datasets.
clear

%Dataset 1, must end with .mat
Input = '/Volumes/zimmer/Annika/_Reversal_Omega_Checking/Stats-FT/_npr-1-CX13663_18C_O2_21_s6m_2.Lethargus__select.mat';
%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2/BAG-npr-1-ZIM465_18C_O2_21.0_s_2.Lethargus__select.mat';

%%%%%%%%%%%%%%%%%%%%
load(Input)

%% Make input vectors
% Makes an input vector for each experiment
DataSets = struct;
dataInfo = struct;

%Find the different recording names
[AlsNumber,~] = size(CollectedTrksInfo.alsName);

datePosition = strfind(CollectedTrksInfo.alsName,'201');
RecordNames = {};

for iii = 1:AlsNumber;
    CurrDatePosition = datePosition{iii,1}(1,1);
    RecordNames{iii,1} = CollectedTrksInfo.alsName{iii}(CurrDatePosition:(CurrDatePosition+11));
end

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

expStats=regionprops(L,'BoundingBox'); %create structure that contains duration and start / end of connected periods

[nExperiments, ~] = size(expStats);

dataInfo.nExperiments = nExperiments;

%Find number of alsStim per recording (2 stim per als file but
%sometimes only 1 is counted)
nAlsStim = [];
for iii = 1:nExperiments;
    nAlsStim(iii,1) = expStats(iii, 1).BoundingBox(1,4);
end
clear expStats L strMat strB strA RecordNames CurrDatePosition datePosition rr

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
clear beginStimN 

dataInfo.nTracksPerExp = nTracksPerExp;

cumnTracksPerStim = cumsum(nTracksPerStim);
cumNTracksPerExp = cumsum(nTracksPerExp);

%Get the real means for each experiment
startingTrack = 1;
for jj = 1:nExperiments;
    RealMeans(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
    startingTrack = cumNTracksPerExp(jj)+1;
end
clear startingTrack cumNTracksPerExp

% First Turn Binned sleep tracks
disp('assumes CollectedTrksInfo.BehaviorstateBin1 starts at stimulus onset');

[NumLetTracks,~] = size(CollectedTrksInfo.SleepAllTurnStartsBinned);
FirstResponseBin = NaN(NumLetTracks,1);

for TrackN =1:NumLetTracks
    turnIndexBin = find(CollectedTrksInfo.SleepAllTurnStartsBinned(TrackN,:)>0);
    if ~isempty(turnIndexBin);
        FirstResponseBin(TrackN,1) = turnIndexBin(1,1);
    else
        FirstResponseBin(TrackN,1) = NaN;
    end
end
        
% Get out lethargus track numbers
AllSleepTracksQuiescent = [];
AllSleepTracksActive = [];
SleepTracksQuiescentPerEx = cell(nExperiments,1);
SleepTracksActivePerEx = cell(nExperiments,1);

countAls =0;
for expN = 1:nExperiments
    for alsN =1:nAlsStim(expN);
        if (expN + alsN) >2
            previousTrackN = cumnTracksPerStim(countAls);
        else
            previousTrackN =0;
        end
        countAls = countAls+1;
        AllSleepTracksQuiescent = [AllSleepTracksQuiescent;((CollectedTrksInfo.SleepTrcksQuiescent{countAls,1} + previousTrackN))];
        AllSleepTracksActive = [AllSleepTracksActive;((CollectedTrksInfo.SleepTrcksActive{countAls,1} + previousTrackN))];
        
        SleepTracksQuiescentPerEx{expN} = [SleepTracksQuiescentPerEx{expN};((CollectedTrksInfo.SleepTrcksQuiescent{countAls,1} + previousTrackN))];
        SleepTracksActivePerEx{expN} = [SleepTracksActivePerEx{expN};((CollectedTrksInfo.SleepTrcksActive{countAls,1} + previousTrackN))];
    
    end
end

SBinWinSec =5;
disp('...using SBinWinSec = 5')
xcenters = 0:1:85;
xcenters = 1:2:85;
%xcenters = 2.5:5:85;
xcentersSec = xcenters*SBinWinSec;

HistFTRQ = (hist(FirstResponseBin(AllSleepTracksQuiescent,1),xcenters))/length(AllSleepTracksQuiescent);
HistFTRA = (hist(FirstResponseBin(AllSleepTracksActive,1),xcenters))/length(AllSleepTracksActive);
figure; plot(xcentersSec,HistFTRQ); hold on; plot(xcentersSec,HistFTRA,'r')
ylabel('fraction');
xlabel('time from stimulus (s)');

AllFractionTurningInFirstPeriod = [HistFTRQ(1,1); HistFTRA(1,1)];

for expN = 1:nExperiments
%     HistFTRQ = (hist(FirstResponseBin(SleepTracksQuiescentPerEx{expN},1),xcenters))/length(SleepTracksQuiescentPerEx{expN});
%     HistFTRA = (hist(FirstResponseBin(SleepTracksActivePerEx{expN},1),xcenters))/length(SleepTracksActivePerEx{expN});
%     figure; plot(xcentersSec,HistFTRQ); hold on; plot(xcentersSec,HistFTRA,'r')
%     ylabel('fraction');
%     xlabel('time from stimulus (s)');

    FractionTurningInFirstPeriodPerEx(expN,1:2) = [HistFTRQ(1,1), HistFTRA(1,1)];    
end


%Get the full data sets
DataSets.dataset = nanmean(CollectedTrksInfo.SleepTrcks');


% Read out N values
numTrack = (length(DataSets.dataset));

%Note this is the number of tracks which were included, some tracks in the
%CollectedTrksInfo are only NaNs and are therefore discluded.

%clearvars -except RealMeans numTrack dataInfo FractionTurningInFirstPeriodPerEx
