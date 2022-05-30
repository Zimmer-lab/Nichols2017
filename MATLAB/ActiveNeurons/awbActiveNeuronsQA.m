% addon to Batch version of ActiveNeurons

% This script finds bins which are all Q or A and

%%
options.version.awbActiveNeuronsQA = 'v1_20160323';

load(strcat(pwd,'/Quant/QuiescentState.mat'));

totalRecordingLength = 1080;

BinNum = totalRecordingLength/options.BinSize;

QuiescentBin = nan(1,BinNum);
ActiveBin = nan(1,BinNum);

[~, idx2] = size(wbstruct.simple.deltaFOverF_bc);

for bin = 1:BinNum

if isnan(QuiescentBin(1,1))
    %Calculate if fully Q or A - first bin
    RangeEnd = floor(bin*options.BinSize*wbstruct.fps);
    QuiescentBin(1,bin) = 1 == mean(QuiesceBout(1:RangeEnd,1));
    ActiveBin(1,bin) = 0 == mean(QuiesceBout(1:RangeEnd,1));
else
    %Calculate if fully Q or A - rest of the bins
    RangeEnd = floor(bin*options.BinSize*wbstruct.fps);
    QuiescentBin(1,bin) = 1 == mean(QuiesceBout(RangeStart:RangeEnd,1));
    ActiveBin(1,bin) = 0 == mean(QuiesceBout(RangeStart:RangeEnd,1));
end
RangeStart = RangeEnd +1;
end

RecordingFractionActiveQuiBins = nan(1,BinNum);
RecordingFractionActiveActBins = nan(1,BinNum);

for bin = 1:BinNum
    if QuiescentBin(1,bin) ==1;
        RecordingFractionActiveQuiBins(1,bin) = IndividualActiveNeurons(1,bin);
    end
    if ActiveBin(1,bin) ==1;
        RecordingFractionActiveActBins(1,bin) = IndividualActiveNeurons(1,bin);
    end
end
% nanmean(RecordingFractionActiveQuiBins)
% nanmean(RecordingFractionActiveActBins)

clearvars ActiveBin QuiescentBin RangeEnd RangeStart Qoptions QuiesceBout instQuiesce

