%ActiveNeuronsSlide
% modification onto awbActiveNeurons so that there is a sliding bin instead
% of static ones.

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
options.version.awbActiveNeuronsSlide = 'v1_20160418';
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

%% For each second finds neurons that are active in a sliding bin.
totalRecordingLength = 1080; %caution if different recording length.

[frameTotal, neuronNum] = size(wbstruct.simple.deltaFOverF_bc);

IndividualActiveNeurons = nan(1,totalRecordingLength);

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
    
    %Calculate if over thresholds
    DerivActive = options.DerivThreshold< wbstruct.simple.derivs.traces(frameStart:frameEnd,1:end);
    FActive = options.FThreshold< wbstruct.simple.deltaFOverF_bc(frameStart:frameEnd,1:end);

%for neuron fraction
Activesum = sum(DerivActive + FActive); 

Active = 0.9<Activesum;

IndividualActiveNeurons(1,second) = sum(Active)/neuronNum;

%for single neurons
SingleActiveNeurons (second,:)= Active (1,:);

end

% figure; 
% imagesc(SingleActiveNeurons')

clearvars frameStart frameStart Active Activesum DerivActive FActive totalRecordingLength