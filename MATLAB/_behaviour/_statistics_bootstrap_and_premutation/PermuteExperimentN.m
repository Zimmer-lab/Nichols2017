%% Resampling
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'BootStrap'.

% Enter file path and name to a file (select) made from
% SleepAlsV12Quant_stats scripts. Make sure the BehaviourstateBin,
% ConditinoalBinSec and AlsBinSec are the same when comparing two datasets.
clear all

%Dataset 1, must end with .mat
In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/_NPR1_controls/controlNPR1_ZIM997_AD51xJ310_GR_18C_O2_21_s_2.Let__select.mat';

%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/12m/_last4m/CX13663_18C_O2_21_s_12m_2.Lethargus__select.mat';
%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/HW_O2_21.0_s_2.Lethargus__select.mat';

%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2/npr-1-gcy-35_O2_21.0_s_2.Lethargus___select.mat';%
%N2_O2_21.0_s_2.Lethargus__select.mat';
%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Mix/Pgcy36npr1_AC72_T_18C_O2_21_s_2.Lethargus__select.mat';
%example: '/Volumes/groups/zimmer/Annika_Nichols/_4.Statisics/N2_18_O2_21.0_c_2.Let_select.mat';

%Dataset2 

%In.InputV2 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/12m/_last4m/N2_18C_O2_21_s_12m_2.Lethargus__select.mat';

In.InputV2 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Rescues/ZIM997_AD51xJ310_GR_18C_O2_21_s_2.Let__select.mat';
%In.InputV2 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2/npr-1-gcy-35_O2_21.0_s_2.Lethargus___select.mat';%npr-1-CX13663_O2_21.0_s_2.Lethargus__select.mat';
%In.InputV2 ='/Volumes/zimmer/Annika/_test_npr1_subsets/_Sub2_select.mat';
%In.InputV2 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2/npr-1-gcy-35_O2_21.0_s_2.Lethargus___select.mat';


%Number of repeats:
nReps = 100000;



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

    expStats= {}; 
    expStats=regionprops(L,'BoundingBox'); %create structure that contains duration and start / end of connected periods
    
    [nExperiments, ~] = size(expStats);
    
    dataInfo.(inputs{ii}).nExperiments = nExperiments;
    
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
    
    dataInfo.(inputs{ii}).nTracksPerExp = nTracksPerExp;
    
    cumNTracksPerExp = cumsum(nTracksPerExp);
    
    %Get the real means for each experiment
    startingTrack = 1;
    for jj = 1:nExperiments;
        RealMeans.(inputData{ii})(jj,:) = nanmean(nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        startingTrack = cumNTracksPerExp(jj)+1;
    end
    clear startingTrack cumNTracksPerExp
    
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
    numTrack(ii) = (length(DataSets.(inputData{ii})));
end
%Note this is the number of tracks which were included, some tracks in the
%CollectedTrksInfo are only NaNs and are therefore discluded.

numExperiments = [dataInfo.InputV1.nExperiments,dataInfo.InputV2.nExperiments];

%% Make full input vector (combined)
dataset3 = [DataSets.dataset1,DataSets.dataset2];

clear FractionActive1Sleep FractionActive1Wake FractionActive2Sleep FractionActive2Wake...
            LRresponse1SleepSelect LRresponse1WakeSelect LRresponse2SleepSelect LRresponse2WakeSelect Oresponse1SleepSelect Oresponse1WakeSelect...
            Oresponse2SleepSelect Oresponse2WakeSelect CollectedTrksInfo FractionAwake FileNameCell In inputData
        
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
% To deal with different N numbers we weight the values which
% means that an equal number of dataset1 and 2 should be selected
% Should work for whichever is bigger.

%Find number of worm responses
[r1, c1] = size(DataSets.dataset1);
[r2, c2] = size(DataSets.dataset2);

%Make weighted vectors
weightsD1 = ones(1, c1);
weightsD2 = ones(1, c2);

scalingValue = c1/c2;

weightsD3 = [weightsD1, weightsD2*scalingValue];

clearvars r1 c1 r2 c2 weightsD1 weightsD2 scalingValue


%% Resampling
% Need to create 2 vectors of the mean of repsonses from x experiments for
% each input dataset. Still use weighing by track as the tracks are what
% are being choosen.

draws.(inputs{ii}) = [];

for ii = 1:2; %for each input vetcor
    for jj  = 1:dataInfo.(inputs{ii}).nExperiments; % for each experiment
        
        %Define number of tracks to randomly draw
        CurrTrackN = dataInfo.(inputs{ii}).nTracksPerExp(jj);
        
        %Redraw nReps number of times and find the mean. This will be a repetition of the
        %mean of one experiment. Repeat nReps, and do it for each
        %experiment for this input vector.
        for RepetitionN = 1:nReps;
            draws.(inputs{ii})(jj,RepetitionN) = nanmean(randsample(dataset3,CurrTrackN,true,weightsD3));
        end
        clear RepetitionN
    end
end

% Get the difference
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

%% Plot figure
figure; bar(xValues,histD);
hold on
plot([realMean realMean],ylim,'r')
line1 = ['Resampling Results, p-Value:', mat2str(pValue)];
line2 = ['Num tracks: ', mat2str(numTrack)];
line3 = ['Num Exp: ', mat2str(numExperiments)];
title({line1;line2;line3});
xlabel('difference between the means');
ylabel('Fraction');
% Note P value may be close to zero or 1.

clearvars r c ii bootsam bootstat jj nExperiments inputs iii idx CurrTrackN 


