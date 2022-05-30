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

%%% Find number of lethargic tracks per stimulus.
nTracksPerStim = [];
for iii = 1:length(CollectedTrksInfo.SleepTrcksNum)
    nTracksPerStim(iii,1) = length(CollectedTrksInfo.SleepTrcksNum{iii, 1});
end

%Find number of lethargic tracks per experiment
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
%%%

%%% Find number of non-lethargic tracks per stimulus.
nNonLetTracksPerStim = [];
for iii = 1:length(CollectedTrksInfo.WakeTrcksNum)
    nNonLetTracksPerStim(iii,1) = length(CollectedTrksInfo.WakeTrcksNum{iii, 1});
end

%Find number of non-lethargic tracks per experiment
beginStimN = 1;
nNonLetTracksPerExp = [];
for jj = 1:nExperiments;
    nNonLetTracksPerExp(jj,1) = sum(nNonLetTracksPerStim(beginStimN:(nAlsStim(jj)+beginStimN-1)));
    beginStimN = nAlsStim(jj)+beginStimN;
end
clear beginStimN 

dataInfo.nNonLetTracksPerExp = nNonLetTracksPerExp;

cumnNonLetTracksPerStim = cumsum(nNonLetTracksPerStim);
cumNNonLetTracksPerExp = cumsum(nNonLetTracksPerExp);
%%%



%Get the real means for each experiment for Motionstate in lethargus
startingTrack = 1;
for jj = 1:nExperiments;
    RealMeansLetSleep(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
    startingTrack = cumNTracksPerExp(jj)+1;
end
clear startingTrack 

% First Turn Binned sleep tracks
disp('assumes CollectedTrksInfo.BehaviorstateBin1 starts at stimulus onset');

[NumLetTracks,~] = size(CollectedTrksInfo.SleepAllTurnStartsBinned);
SleepFirstResponseBin = NaN(NumLetTracks,1);

for TrackN =1:NumLetTracks
    turnIndexBin = find(CollectedTrksInfo.SleepAllTurnStartsBinned(TrackN,:)>0);
    if ~isempty(turnIndexBin);
        SleepFirstResponseBin(TrackN,1) = turnIndexBin(1,1);
    else
        SleepFirstResponseBin(TrackN,1) = NaN;
    end
end

% First Turn Binned wake tracks
[NumWakeTracks,~] = size(CollectedTrksInfo.WakeAllTurnStartsBinned);
WakeFirstResponseBin = NaN(NumWakeTracks,1);

for TrackN =1:NumWakeTracks
    turnIndexBin = find(CollectedTrksInfo.WakeAllTurnStartsBinned(TrackN,:)>0);
    if ~isempty(turnIndexBin);
        WakeFirstResponseBin(TrackN,1) = turnIndexBin(1,1);
    else
        WakeFirstResponseBin(TrackN,1) = NaN;
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
xcenters = 0.5:1:85;
%xcenters = 1:2:85;
%xcenters = 2.5:5:85;
xcentersSec = xcenters*SBinWinSec;

HistFTRQ = (hist(SleepFirstResponseBin(AllSleepTracksQuiescent,1),xcenters))/length(AllSleepTracksQuiescent);
HistFTRA = (hist(SleepFirstResponseBin(AllSleepTracksActive,1),xcenters))/length(AllSleepTracksActive);
figure; plot(xcentersSec,HistFTRQ); hold on; plot(xcentersSec,HistFTRA,'r')
ylabel('fraction');
xlabel('time from stimulus (s)');

AllFractionTurningInFirstPeriod = [HistFTRQ(1,1); HistFTRA(1,1)];

startingTrack = 1;
startingTrackNonlet = 1;

FractionTurningInFirstPeriodPerEx =nan(nExperiments,1);
FractionQATurningInFirstPeriodPerEx = nan(nExperiments,1);
for expN = 1:nExperiments
    HistFTRQ = (hist(SleepFirstResponseBin(SleepTracksQuiescentPerEx{expN},1),xcenters))/length(SleepTracksQuiescentPerEx{expN});
    HistFTRA = (hist(SleepFirstResponseBin(SleepTracksActivePerEx{expN},1),xcenters))/length(SleepTracksActivePerEx{expN});
    figure; plot(xcentersSec,HistFTRQ); hold on; plot(xcentersSec,HistFTRA,'r')
    ylabel('fraction');
    xlabel('time from stimulus (s)');
    HistFTRlet = (hist(SleepFirstResponseBin(startingTrack:cumNTracksPerExp(expN),1),xcenters))/length(startingTrack:cumNTracksPerExp(expN));
    HistFTRnonlet = (hist(WakeFirstResponseBin(startingTrackNonlet:cumNNonLetTracksPerExp(expN),1),xcenters))/length(startingTrackNonlet:cumNNonLetTracksPerExp(expN));

    startingTrack = cumNTracksPerExp(expN)+1;
    startingTrackNonlet = cumNNonLetTracksPerExp(expN)+1;
%     if expN== 3;
%         return
%     end

    FractionQATurningInFirstPeriodPerEx(expN,1:2) = [HistFTRQ(1,1), HistFTRA(1,1)];    
    FractionTurningInFirstPeriodPerExLet(expN,1) = HistFTRlet(1,1);
    FractionTurningInFirstPeriodPerExNonLet(expN,1) = HistFTRnonlet(1,1);
end

% Hist for Wake vs Sleep

xcenters = 0:1:85;
%xcenters = 1:2:85;
%xcenters = 2.5:5:85;
xcentersSec = xcenters*SBinWinSec;

HistFTRsleep = (hist(SleepFirstResponseBin,xcenters))/length(SleepFirstResponseBin);
HistFTRwake = (hist(WakeFirstResponseBin,xcenters))/length(WakeFirstResponseBin);
figure; plot(xcentersSec,HistFTRsleep); hold on; plot(xcentersSec,HistFTRwake,'r')
ylabel('fraction');
xlabel('time from stimulus (s)');
nameStr = CollectedTrksInfo.alsName{1,1}(1:22);
nameStr(nameStr == '_') =' ';
title(nameStr);

%% Speed readout

MeasurementPeriodBins = (3:7);
MeasurementPeriodBins = (32:72);

%MS bin for intial fig S2
MeasurementPeriodBins = (1:12);

%MeasurementPeriodBins = (60:72);

if CollectedTrksInfo.BehaviorstateBin1(1,1) == 1560
    figure;
    %Get the real means for each experiment
    startingTrack = 1;
    startingTrackNonLet = 1;
    for jj = 1:nExperiments;
        RealMeansNonLetActive(jj,:) = nanmean(nanmean((CollectedTrksInfo.WakeTrcks(startingTrackNonLet:cumNNonLetTracksPerExp(jj),MeasurementPeriodBins))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        RealMeansLetSleep2(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),MeasurementPeriodBins))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        
        RealMeansSpdNonLet(jj,:) = nanmean(nanmean((CollectedTrksInfo.WakeAllSpdBinned(startingTrackNonLet:cumNNonLetTracksPerExp(jj),MeasurementPeriodBins))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        
        RealMeansSpdLet(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepAllSpdBinned(startingTrack:cumNTracksPerExp(jj),MeasurementPeriodBins))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        RealMeansSpdLetA(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepAllSpdBinned(SleepTracksQuiescentPerEx{jj,1},MeasurementPeriodBins))'));
        RealMeansSpdLetQ(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepAllSpdBinned(SleepTracksActivePerEx{jj,1},MeasurementPeriodBins))'));
        
        RealMeansTurnNonLet(jj,:) = nanmean(nanmean((CollectedTrksInfo.WakeAllTurnStartsBinned(startingTrackNonLet:cumNNonLetTracksPerExp(jj),MeasurementPeriodBins))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        RealMeansTurnLet(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepAllTurnStartsBinned(startingTrack:cumNTracksPerExp(jj),MeasurementPeriodBins))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        RealMeansTurnLetA(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepAllTurnStartsBinned(SleepTracksQuiescentPerEx{jj,1},MeasurementPeriodBins))'));        
        RealMeansTurnLetQ(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepAllTurnStartsBinned(SleepTracksActivePerEx{jj,1},MeasurementPeriodBins))'));  
        startingTrack = cumNTracksPerExp(jj)+1;
        startingTrackNonLet = cumNNonLetTracksPerExp(jj)+1;
        
        hold on; plot(nanmean(CollectedTrksInfo.SleepAllSpdBinned(SleepTracksActivePerEx{jj,1},:)),'r');
        hold on; plot(nanmean(CollectedTrksInfo.SleepAllSpdBinned(SleepTracksQuiescentPerEx{jj,1},:)));

    end

    
end

%% Time to max Speed readout

if CollectedTrksInfo.BehaviorstateBin1(1,1) == 1560
    startingTrack = 1;
    startingTrackNonLet = 1;
    firstBinAbovemeantwentypcLet = nan(nExperiments,1);
    firstBinAbovemeantwentypcNonLet = nan(nExperiments,1);
    figure;
    for expN = 1:nExperiments;
%         hold on; plot(nanmean(CollectedTrksInfo.SleepAllSpdBinned(startingTrack:cumNTracksPerExp(expN),:)),'r');
%         hold on; plot(nanmean(CollectedTrksInfo.WakeAllSpdBinned(startingTrackNonLet:cumNNonLetTracksPerExp(expN),:)));

        hold on; plot((nanmean(CollectedTrksInfo.SleepAllSpdBinned(startingTrack:cumNTracksPerExp(expN),:))),'r');
        hold on; plot((nanmean(CollectedTrksInfo.WakeAllSpdBinned(startingTrackNonLet:cumNNonLetTracksPerExp(expN),:))));

        %find mean of top 20% and find first bin which is over this level
        meanExpSleep =nanmean(CollectedTrksInfo.SleepAllSpdBinned(startingTrack:cumNTracksPerExp(expN),:));
        twentpc = prctile(meanExpSleep,20);
        meantwentypc = mean(meanExpSleep(twentpc < meanExpSleep));
        firstBinAbovemeantwentypcLet(expN) = find(meantwentypc < meanExpSleep, 1);

        %same for non-let
        meanExpNonLet =nanmean(CollectedTrksInfo.WakeAllSpdBinned(startingTrackNonLet:cumNNonLetTracksPerExp(expN),:));
        twentpc = prctile(meanExpNonLet,20);
        meantwentypc = mean(meanExpNonLet(twentpc < meanExpNonLet));
        firstBinAbovemeantwentypcNonLet(expN) = find(meantwentypc < meanExpNonLet, 1);
        
        startingTrack = cumNTracksPerExp(expN)+1;
        startingTrackNonLet = cumNNonLetTracksPerExp(expN)+1;
    end
    firstBinAbovemeantwentypcLet = firstBinAbovemeantwentypcLet*SBinWinSec;
    firstBinAbovemeantwentypcNonLet = firstBinAbovemeantwentypcNonLet*SBinWinSec;
end


%% Get the full data sets
DataSets.dataset = nanmean(CollectedTrksInfo.SleepTrcks');


% Read out N values
numTrack = (length(DataSets.dataset));

%Note this is the number of tracks which were included, some tracks in the
%CollectedTrksInfo are only NaNs and are therefore discluded.

%clearvars -except RealMeans numTrack dataInfo FractionTurningInFirstPeriodPerEx
