%ActiveNeurons
% This is a script that calculates what neuron fraction is active based on
% two indicators of activity:
% 1. that the neuron has changes over a certain threshold (derivative)
% 2. that the neuron is above a baseline threshold

%Bin size in seconds
options.BinSize1 = 60; 

%Thresholds:
options.DerivThreshold1 = 0.007;

options.FThreshold1 = 0.5;

%% Batch compatable
options.version.awbActiveNeurons = 'v1_20160323';
wbload;

if ~isfield(options,'BinSize');
    options.BinSize =options.BinSize1;
end
options = rmfield(options, 'BinSize1');

if ~isfield(options,'DerivThreshold');
    options.DerivThreshold =options.DerivThreshold1;
end
options = rmfield(options, 'DerivThreshold1');

if ~isfield(options,'FThreshold');
    options.FThreshold =options.FThreshold1;
end
options = rmfield(options, 'FThreshold1');

%% For each bin find neurons that are active.
totalRecordingLength = 1080; %caution

BinNum = totalRecordingLength/options.BinSize;

IndividualActiveNeurons = nan(1,BinNum);

[~, idx2] = size(wbstruct.simple.deltaFOverF_bc);

for bin = 1:BinNum

if isnan(IndividualActiveNeurons(1,1))
    %Calculate if over thresholds
    RangeEnd = floor(bin*options.BinSize*wbstruct.fps);
    DerivActive = options.DerivThreshold< wbstruct.simple.derivs.traces(1:RangeEnd,1:end);
    FActive = options.FThreshold< wbstruct.simple.deltaFOverF_bc(1:RangeEnd,1:end);
else
    %Calculate if over thresholds
    RangeEnd = floor(bin*options.BinSize*wbstruct.fps);
    DerivActive = options.DerivThreshold< wbstruct.simple.derivs.traces(RangeStart:RangeEnd,1:end);
    FActive = options.FThreshold< wbstruct.simple.deltaFOverF_bc(RangeStart:RangeEnd,1:end);
end

%for neuron fraction
Activesum = sum(DerivActive + FActive); 

Active = 0.9<Activesum;

IndividualActiveNeurons(1,bin) = sum(Active)/idx2;

RangeStart = RangeEnd +1;

%for single neurons

SingleActiveNeurons (bin,:)= Active (1,:);

end

% figure; 
% imagesc(SingleActiveNeurons')

clearvars RangeStart RangeEnd Active Activesum BinNum DerivActive FActive totalRecordingLength