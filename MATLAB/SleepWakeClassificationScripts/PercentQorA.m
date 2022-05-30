%% Quiescent vs Active percentages
%For a dataset you can calculate the fraction quiescent (PercentQ) or
%fraction active (FractionA) for the specified time points.

BinSize1 = 60; %(in seconds)
FullRecordingLength1 = 1080; %(in seconds)

%%
wbload;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);

if ~exist('BinSize','var');
    BinSize =BinSize1;
end
clearvars BinSize1

if ~exist('FullRecordingLength','var');
    FullRecordingLength =FullRecordingLength1;
end
clearvars FullRecordingLength1

%% Find percentQ in each bin

%Number of bins
BinNum = FullRecordingLength/BinSize;

% Correct to frames
BinSizeFramesRounded = round(BinSize*wbstruct.fps); %may be slightly off due to rounding.
BinSizeFrames = BinSize*wbstruct.fps; %may be slightly off due to rounding.

EpochNum = 1;
for EpochNum = 1:BinNum;
    TimePoint1 = round(EpochNum*BinSizeFrames);
    if EpochNum ==1; %First epoch
        EpochRange = 1:TimePoint1;
        IndividualPercentQ(1,EpochNum) = sum(QuiesceBout(EpochRange))/length(QuiesceBout(EpochRange));
    elseif EpochNum == BinNum; %Last epoch - corrects for rounding
        IndividualPercentQ(1,EpochNum) = sum(QuiesceBout((TimePoint2+1):end))/length(QuiesceBout((TimePoint2+1):end));
    else %in between epochs
        EpochRange = (TimePoint2+1):TimePoint1; %Now takes the next bin from +1 frame from the end of the last bin.
        IndividualPercentQ(1,EpochNum) = sum(QuiesceBout(EpochRange))/length(QuiesceBout(EpochRange));
    end
    TimePoint2 = TimePoint1;
end
clearvars EpochNum BinNum EpochRange TimePoint1 TimePoint2 BinSizeFrames BinSizeFramesRounded


%% Quick inverse and collection of Percent Quiescent

[idx1 idx2] =size(IndividualPercentQ);
IndividualFractionA(1,1:idx2) = abs((IndividualPercentQ(1,1:end)-1)); % gives you Fraction active
clearvars idx1 idx2

%%
% figure;bar(IndividualFractionA)
% ylim([0 1]);
