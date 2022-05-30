%% Resampling
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'BootStrap'.

% Enter file path and name to a file (select) made from
% SleepAlsV12Quant_stats scripts. Make sure the BehaviourstateBin,
% ConditinoalBinSec and AlsBinSec are the same when comparing two datasets.
clear all

%Dataset 1, must end with .mat
In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/N2_O2_21.0_s_2.Lethargus__select.mat';
%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/npr-1-CX13663_O2_21.0_s_2.Lethargus__select.mat';

%In.InputV1 ='/Volumes/zimmer/Annika/_test_npr1_subsets/_Sub1_select.mat';

%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/HW_O2_21.0_s_2.Lethargus__select.mat';

%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2/npr-1-gcy-35_O2_21.0_s_2.Lethargus___select.mat';%

nReps = 10000;


%%%%%%%%%%%%%%%%%%%%
%% Make input vectors
% Makes an input vector for each experiment
inputs = {'InputV1'};
inputData = {'dataset1'};
DataSets = struct;
dataInfo = struct;

load(In.(inputs{1}))

%Find the different recording names
[r,~] = size(CollectedTrksInfo.alsName);

datePosition = strfind(CollectedTrksInfo.alsName,'201');
RecordNames = {};

for iii = 1:r;
    CurrDatePosition = datePosition{iii,1}(1,1);
    RecordNames{iii,1} = CollectedTrksInfo.alsName{iii}(CurrDatePosition:(CurrDatePosition+10));
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
clear beginStimN nAlsStim

dataInfo.nTracksPerExp = nTracksPerExp;

cumNTracksPerExp = cumsum(nTracksPerExp);

%Get the real means for each experiment
startingTrack = 1;
RealMeans = [];
for jj = 1:nExperiments;
    RealMeans(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
    startingTrack = cumNTracksPerExp(jj)+1;
end
clear startingTrack cumNTracksPerExp

%Get the full data sets
DataSets = nanmean(CollectedTrksInfo.SleepTrcks');

dataInfo.BehaviorstateBin1 = CollectedTrksInfo.BehaviorstateBin1;
dataInfo.ConditionalBinSec1 = CollectedTrksInfo.ConditionalBinSec1;
dataInfo.AlsBinSec1 = CollectedTrksInfo.AlsBinSec1;


%% Remove NaNs from the select data
if sum(isnan(DataSets)) > 0
    idx = find(isnan(DataSets));
    DataSets(idx)=[];
end

%% Read out N values
numTrack(1) = (length(DataSets));

%Note this is the number of tracks which were included, some tracks in the
%CollectedTrksInfo are only NaNs and are therefore discluded.

numExperiments = [dataInfo.nExperiments];

%% Make full input vector (combined)
dataset3 = [DataSets];

clear FractionActive1Sleep FractionActive1Wake FractionActive2Sleep FractionActive2Wake...
    LRresponse1SleepSelect LRresponse1WakeSelect LRresponse2SleepSelect LRresponse2WakeSelect Oresponse1SleepSelect Oresponse1WakeSelect...
    Oresponse2SleepSelect Oresponse2WakeSelect CollectedTrksInfo FractionAwake FileNameCell In inputData


%% Resampling
% Need to create 2 vectors of the mean of repsonses from x experiments for
% each input dataset. Still use weighing by track as the tracks are what
% are being choosen.

draws = [];

for jj  = 1:dataInfo.nExperiments; % for each experiment
    
    %Define number of tracks to randomly draw
    CurrTrackN = dataInfo.nTracksPerExp(jj);
    
    %Redraw nReps number of times and find the mean. This will be a repetition of the
    %mean of one experiment. Repeat nReps, and do it for each
    %experiment for this input vector.
    for RepetitionN = 1:nReps;
        draws(jj,RepetitionN) = nanmean(randsample(dataset3,CurrTrackN));
    end
    clear RepetitionN
end

%% WORK HERE!!!! Find the 95 percentile for the data.
Means = mean(draws);

RealMean = mean(RealMeans);
[histD,xValues] = hist(Means);
histD = histD/length(Means);

%% Plot figure
figure; bar(xValues,histD);
hold on
plot([RealMean RealMean],ylim,'r')
line1 = ['Resampling Results'];
line2 = ['Num tracks: ', mat2str(numTrack)];
line3 = ['Num Exp: ', mat2str(numExperiments)];
title({line1;line2;line3});
xlabel('resampled means');
ylabel('Fraction');
% Note P value may be close to zero or 1.

clearvars r c ii bootsam jj nExperiments inputs iii idx CurrTrackN


