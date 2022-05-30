%% awbReversals
% This script measures the number of reversals through the number of AVA
% rises.

BinSize1 = 60; %(in seconds)

FullRecordingLength1 = 1080; %(in seconds)

%%
if ~exist('BinSize','var');
    BinSize =BinSize1;
end
clearvars BinSize1

if ~exist('FullRecordingLength','var');
    FullRecordingLength =FullRecordingLength1;
end
clearvars FullRecordingLength1

%% Get state values for AVA:
Neurons = {'AVAL'};

awbStateTransExtract

%% Find number of rises in each bin

%Number of bins
BinNum = FullRecordingLength/BinSize;

Rise = diff(StateTrans.StateValue' == 2); %makes t point at (start of rise - 1) =1, does this between rows, not across coloums so need to correct for this with '
Rise = Rise'; %Switch matrix back to normal configuration.
Rise(Rise<0) = 0; %This stops the next find sentence from finding -1 values (i.e. ends of rises). Therefore it only finds the start of the rise-1.
    
% Correct to frames
BinSizeFramesRounded = round(BinSize*wbstruct.fps); %may be slightly off due to rounding.
BinSizeFrames = BinSize*wbstruct.fps; %may be slightly off due to rounding.

EpochNum = 1;
for EpochNum = 1:BinNum;
    TimePoint = round(EpochNum*BinSizeFrames);
    if EpochNum ==1; %First epoch
        IndividualReversals(1,EpochNum) = sum(Rise(1,1:TimePoint));
    elseif EpochNum == BinNum; %Last epoch - corrects for rounding
        IndividualReversals(1,EpochNum) = sum(Rise(1,(TimePoint-BinSizeFramesRounded):end));
    else %in between epochs
        IndividualReversals(1,EpochNum) = sum(Rise(1,(TimePoint-BinSizeFramesRounded):TimePoint));
    end
end
clearvars EpochNum BinNum