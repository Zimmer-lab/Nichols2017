%% BootStrap
% This script is used to statiscally compare data using resampling to
% compare the means of the mean of each genotype/condition. It is built on
% 'BootStrap'.

% Enter file path and name to a file (select) made from
% SleepAlsV12Quant_stats scripts. Make sure the BehaviourstateBin,
% ConditinoalBinSec and AlsBinSec are the same when comparing two datasets.
clear all

%Dataset 1, must end with .mat
%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/N2_O2_21.0_s_2.Lethargus__select.mat';

%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/npr-1-CX13663_O2_21.0_s_2.Lethargus__select.mat';

%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/HW_O2_21.0_s_2.Lethargus__select.mat';
%In.InputV1 = '/Volumes/groups/zimmer/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/_new/npr-1-CX13663_18C_O2_21.0_s_2016_Feb-June_2.Lethargus__select.mat';
In.InputV1 ='/Volumes/zimmer/Annika/_test_npr1_subsets/_Sub1_select.mat';

%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Mix/Pgcy36npr1_AC72_T_18C_O2_21_s_2.Lethargus__select.mat';
%example: '/Volumes/groups/zimmer/Annika_Nichols/_4.Statisics/N2_18_O2_21.0_c_2.Let_select.mat';

%Dataset2 
%In.InputV2 = '/Volumes/groups/zimmer/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/npr-1-CX13663_O2_21.0_s_2.Lethargus__select.mat';
In.InputV2 ='/Volumes/zimmer/Annika/_test_npr1_subsets/_Sub2_select.mat';


%Number of repeats:
nReps = 1000;



%%%%%%%%%%%%%%%%%%%%
%% Make input vectors
% Makes an input vector for each experiment
inputs = {'InputV1', 'InputV2'};
inputData = {'dataset1', 'dataset2'};
DataSets = struct;
dataInfo = struct;

for ii = 1:2;
    
    load(In.(inputs{ii}))
    
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
    clearvars strMat
    expGroups = max(L);
    numExpGroups = max(expGroups);
    
    expStats= {};
    expStats=regionprops(L,'BoundingBox'); %create structure that contains duration and start / end of connected periods
    
    [nExperiments, ~] = size(expStats);
    
    dataInfo.(inputs{ii}).nExperiments = nExperiments;
    
    %Find number of Stim per recording (2 stim per als file but
    %sometimes only 1 is counted)
    nAlsStim = [];
    for iii = 1:nExperiments;
        nAlsStim(iii,1) = expStats(iii, 1).BoundingBox(1,4);
    end
    
    dataInfo.(inputs{ii}).nStim = nAlsStim;
    
    %Find number of tracks per stimulus.
    nTracksPerStim = [];
    for iii = 1:length(CollectedTrksInfo.SleepTrcksNum)
        nTracksPerStim(iii,1) = length(CollectedTrksInfo.SleepTrcksNum{iii, 1});
    end
    
    dataInfo.(inputs{ii}).nTracksPerStim = nTracksPerStim;
    
    %Find number of tracks per experiment
    beginStimN = 1;
    nTracksPerExp = [];
    for jj = 1:nExperiments;
        nTracksPerExp(jj,1) = sum(nTracksPerStim(beginStimN:(nAlsStim(jj)+beginStimN-1)));
        beginStimN = nAlsStim(jj)+beginStimN;
    end
    
    dataInfo.(inputs{ii}).nTracksPerExp = nTracksPerExp;
    
    
    %%
    cumNTracksPerStim = cumsum(nTracksPerStim);
    
    %Get the real means for each experiment
    startingTrack = 1;
    for jj = 1:nExperiments;
        RealMeans.(inputData{ii})(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerStim(jj),:))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        startingTrack = cumNTracksPerStim(jj)+1;
    end
    
    %Get the full data sets
    DataSets.(inputData{ii}) = nanmean(CollectedTrksInfo.SleepTrcks');
    
    dataInfo.(inputs{ii}).BehaviorstateBin1 = CollectedTrksInfo.BehaviorstateBin1;
    dataInfo.(inputs{ii}).ConditionalBinSec1 = CollectedTrksInfo.ConditionalBinSec1;
    dataInfo.(inputs{ii}).AlsBinSec1 = CollectedTrksInfo.AlsBinSec1;
end

%% Remove NaNs from the select data
for ii = 1:2
    if sum(isnan(DataSets.(inputData{ii}))) > 0
        idx = find(isnan(DataSets.(inputData{ii})));
        DataSets.(inputData{ii})(idx)=[];
    end
end

%% Read out N values
for ii = 1:2
    TrackNumbers(ii) = (length(DataSets.(inputData{ii})));
end

TrackNumbers

%% Make full input vector (combined)
dataset3 = [DataSets.dataset1,DataSets.dataset2];

%clearvars FractionActive1Sleep FractionActive1Wake FractionActive2Sleep FractionActive2Wake...
%            LRresponse1Sleep LRresponse1Wake LRresponse2Sleep LRresponse2Wake Oresponse1Sleep Oresponse1Wake...
%            Oresponse2Sleep Oresponse2Wake CollectedTrksInfo FractionAwake FileNameCell In inputData
        
%% Checking where the data is coming from:
if sum(dataInfo.InputV1.BehaviorstateBin1 == dataInfo.InputV2.BehaviorstateBin1) ~= 2;
    disp('Note: BehaviorstateBin1 is not the same between datasets')
end
if sum(dataInfo.InputV1.ConditionalBinSec1 == dataInfo.InputV2.ConditionalBinSec1) ~= 2;
    disp('Note: ConditionalBinSec1 is not the same between datasets')
end

if sum(dataInfo.InputV1.AlsBinSec1 == dataInfo.InputV2.AlsBinSec1) ~= 2;
    disp('Note: AlsBinSec1 is not the same between datasets')
end


%% Weighting of values
% To deal with different track numbers we weight the values which
% means that an equal number of tracks from dataset1 and 2 should be selected

%Find number of worm responses
[r1, c1] = size(DataSets.dataset1);
[r2, c2] = size(DataSets.dataset2);

%Make weighted vectors
weightsD1 = ones(1, c1);
weightsD2 = ones(1, c2);

scalingValue = c1/c2;

weightsD3 = [weightsD1, weightsD2*scalingValue];

clearvars r1 c1 r2 c2 weightsD1 weightsD2 scalingValue


%% Bootstrapping
% Creates 2 matrices of the mean of responses from x stimuli for
% each input dataset. Still use weighting by track as the tracks are what
% are being choosen. Draws for each stimulus only the number that it had in
% the exepriment.

%Draw matrices
draws.(inputs{ii}) = [];

for ii = 1:2; %for each input vetcor
    for jj  = 1:sum(dataInfo.(inputs{ii}).nStim); % for each stim
        
        %Define number of tracks to randomly draw (based off track number
        %of that stim).
        CurrTrackN = dataInfo.(inputs{ii}).nTracksPerStim(jj);
        
        %Redraw nReps number of times and find the mean. This will be a repetition of the
        %mean of one stimulus. Repeat nReps times, and do it for each
        %stimulus for this input vector.
        for RepetitionN = 1:nReps;
            draws.(inputs{ii})(jj,RepetitionN) = nanmean(randsample(dataset3,CurrTrackN,true,weightsD3));
        end
    end
end

% Get the difference between the two drawn matrices
bootstatDifs = mean(draws.InputV2) - mean(draws.InputV1);

% Find the probability of the actual difference between the real means
realMean = nanmean(RealMeans.dataset1) - nanmean(RealMeans.dataset2);

%Accounts for possibility of value being at either end.
if realMean < mean(bootstatDifs)
    pValue = sum(bootstatDifs <= realMean)/length(bootstatDifs);
    display(pValue);
else
    pValue = sum(bootstatDifs >= realMean)/length(bootstatDifs);
    display(pValue);
end

[histD,xValues] = hist(bootstatDifs);
histD = histD/length(bootstatDifs);

figure; bar(xValues,histD);
hold on
plot([realMean realMean],ylim,'r')
title(strcat('Resampling Results, p-Value:', mat2str(pValue)));
% Note P value may be close to zero or 1.

clearvars r c ii bootsam bootstat


