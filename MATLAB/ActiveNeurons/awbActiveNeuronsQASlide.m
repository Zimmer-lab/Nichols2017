% addon to Batch version of ActiveNeurons

% This script finds bins which are all Q or A and
%%
options.version.awbActiveNeuronsQASlide = 'v1_20160418';

load(strcat(pwd,'/Quant/QuiescentState.mat'));

totalRecordingLength = 1080;

BinNum = totalRecordingLength/options.BinSize;

QuiescentBin = nan(1,BinNum);
ActiveBin = nan(1,BinNum);

[frameTotal, neuronNum] = size(wbstruct.simple.deltaFOverF_bc);

binHalf = ((options.BinSize*wbstruct.fps)/2);

for second = 1:totalRecordingLength
    %set up range for bin for this frame
    frameStart = ceil((second*wbstruct.fps) - binHalf);
    frameEnd = floor((second*wbstruct.fps) + binHalf);
    
    %Accounting for edged bins
    if frameStart <1
        frameStart =1;
    end
    
    if frameEnd > frameTotal
        frameEnd = frameTotal;
    end
    
    %Calculate if fully Q or A
    QuiescentBin(1,second) = 1 == mean(QuiesceBout(frameStart:frameEnd,1));
    ActiveBin(1,second) = 0 == mean(QuiesceBout(frameStart:frameEnd,1));
end

RecordingFractionActiveQuiBins = nan(1,totalRecordingLength);
RecordingFractionActiveActBins = nan(1,totalRecordingLength);

for second = 1:totalRecordingLength
    if QuiescentBin(1,second) ==1;
        RecordingFractionActiveQuiBins(1,second) = IndividualActiveNeurons(1,second);
    end
    if ActiveBin(1,second) ==1;
        RecordingFractionActiveActBins(1,second) = IndividualActiveNeurons(1,second);
    end
end
% nanmean(RecordingFractionActiveQuiBins)
% nanmean(RecordingFractionActiveActBins)

%%
clearvars ActiveBin QuiescentBin RangeEnd RangeStart Qoptions QuiesceBout instQuiesce
