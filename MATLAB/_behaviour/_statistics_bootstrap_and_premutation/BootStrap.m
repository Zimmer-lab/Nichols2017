%% BootStrap
% This script is used to statiscally compare data using bootstrapping to
% compare the means.

% Enter file path and name to a file (select) made from
% SleepAlsV12Quant_stats scripts. Make sure the BehaviourstateBin,
% ConditinoalBinSec and AlsBinSec are the same when comparing two datasets.
clear all

%Dataset 1, must end with .mat
%In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/npr-1-CX13663_O2_21.0_s_2.Lethargus__select.mat';


In.InputV1 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/HW_O2_21.0_s_2.Lethargus__select.mat';

%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Mix/Pgcy36npr1_AC72_T_18C_O2_21_s_2.Lethargus__select.mat';
%example: '/Volumes/groups/zimmer/Annika_Nichols/_4.Statisics/N2_18_O2_21.0_c_2.Let_select.mat';

%Dataset2 
In.InputV2 = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure1/npr-1-CX13663_O2_21.0_s_2.Lethargus__select.mat';

%Number of repeats:
nReps = 10000;



%%%%%%%%%%%%%%%%%%%%
%% Double nReps as looking at the difference between means and therefore 2 values only give 1 repeat.
nReps = nReps*2;

%% Make input vectors
inputs = {'InputV1', 'InputV2'};
inputData = {'dataset1', 'dataset2'};
DS = struct;
dataInfo = struct;

for ii = 1:2;
    
    load(In.(inputs{ii}))

    DS.(inputData{ii}) = nanmean(CollectedTrksInfo.SleepTrcks');
    
    dataInfo.(inputs{ii}).BehaviorstateBin1 = CollectedTrksInfo.BehaviorstateBin1;
    dataInfo.(inputs{ii}).ConditionalBinSec1 = CollectedTrksInfo.ConditionalBinSec1;
    dataInfo.(inputs{ii}).AlsBinSec1 = CollectedTrksInfo.AlsBinSec1;
end

%% Remove NaNs from the select data
for ii = 1:2
    if sum(isnan(DS.(inputData{ii}))) > 0
        idx = find(isnan(DS.(inputData{ii})));
        DS.(inputData{ii})(idx)=[];
    end
end

%% Read out N values
for ii = 1:2
    Nvalues(ii) = (length(DS.(inputData{ii})));
end

Nvalues

%% Make full input vector (combined)
dataset3 = [DS.dataset1,DS.dataset2];

clearvars inputs FractionActive1Sleep FractionActive1Wake FractionActive2Sleep FractionActive2Wake...
            LRresponse1Sleep LRresponse1Wake LRresponse2Sleep LRresponse2Wake Oresponse1Sleep Oresponse1Wake...
            Oresponse2Sleep Oresponse2Wake CollectedTrksInfo FractionAwake FileNameCell In inputData
        
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
[r1, c1] = size(DS.dataset1);
[r2, c2] = size(DS.dataset2);

%Make weighted vectors
weightsD1 = ones(1, c1);
weightsD2 = ones(1, c2);

scalingValue = c1/c2;

weightsD3 = [weightsD1, weightsD2*scalingValue];

clearvars r1 c1 r2 c2 weightsD1 weightsD2 scalingValue


%% Bootstrapping

% Find bootstrapped means for a combined and weighted dataset of dataset1 and dataset2
[bootstat,bootsam] = bootstrp(nReps,@mean,dataset3,'weights',weightsD3);

% Reshape so can find the difference between random means bootstrapped from
% the combined, weighted dataset.
[r,c] = size(bootstat);
bootstat4 = reshape(bootstat,2,r/2);

% Get the difference
bootstatDifs = (bootstat4(1,:)-bootstat4(2,:));

% Find the probability of the actual difference between the real means
realMean = nanmean(DS.dataset1) - nanmean(DS.dataset2);

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
title(strcat('Bootstrap Results, p-Value:', mat2str(pValue)));
% Note P value may be close to zero or 1.

clearvars r c ii bootsam bootstat bootstat4


