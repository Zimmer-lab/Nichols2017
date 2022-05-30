%% This script works on CollectedTrksInfo to average responses.

%Need to average across stimuli from same recording.
%CollectedTrksInfo.alsName;

%Need to get idea of variation of N between stimuli and recording. Then
%average tracks from one stim.
%CollectedTrksInfo.SleepTrcksNum

% Get number of tracks for each stimulus.
[numStim,~] = size(CollectedTrksInfo.alsName);
numTracksPerStim = nan(6,1);

for ii = 1:numStim;
    numTracksPerStim(ii,1) = numel(CollectedTrksInfo.SleepTrcksNum{ii,1});
end

%average response per stimulus:
cumNumTrcksPerStim = cumsum(numTracksPerStim);

[~,responseBins] = size(CollectedTrksInfo.SleepTrcks);

responsePerStim = nan(6,responseBins);
TrackStart = 1;

for ii = 1:numStim;
    TrackEnd = cumNumTrcksPerStim(ii);
    
    responsePerStim(ii,:) = nanmean(CollectedTrksInfo.SleepTrcks(TrackStart:TrackEnd,:));
    
    TrackStart = TrackEnd +1;
end