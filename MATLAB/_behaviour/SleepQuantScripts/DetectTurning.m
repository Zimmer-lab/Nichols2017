
function  [AllTurnStarts,AllTurnStartsBinned] = DetectTurning(SampleRate,binning,Tracks,movieFrames)
% DetectTurning
% This script is used to detect turning based off absolute eccentricity

% Get all track eccentricity and speed
[~,NumTracks] = size(Tracks);

allEccen =nan(NumTracks,movieFrames);

for TrckN = 1: length(Tracks)
    allEccen(TrckN,Tracks(TrckN).Frames) = Tracks(TrckN).Eccentricity;
end

%% Find all turning periods
TurningEccThreshold = 0.08;

TurnStart = cell(1,NumTracks);
TurnLength = cell(1,NumTracks);
for TrackN =1:NumTracks;
    
    %Find time points where turning threshold is satisfied
    EccHigh = (abs(allEccen(TrackN,:)-1))>TurningEccThreshold;
    
    TurningVector = zeros(sum(~isnan(allEccen(TrackN,:))),1);
    TurningVector(EccHigh,1) = 1;
    %figure; imagesc(TurningVector')
    
    % Find turning bouts
    L = logical(TurningVector);
    stats= regionprops(L);
    TurnNum = length(stats);
    
    for TurnN =1:TurnNum;
        %add turn start and length
        TurnStart{TrackN}(1,TurnN) = stats(TurnN, 1).BoundingBox(1,2)+0.5;
        TurnLength{TrackN}(1,TurnN) = stats(TurnN, 1).BoundingBox(1,4);
    end
end

AllTurnStarts = nan(NumTracks,movieFrames);
AllTurnStarts(~isnan(allEccen)) = 0;

AllTurnStartsBinned = nan(NumTracks,movieFrames/binning);

for TrackN =1:NumTracks;  
    
    %unbinned events/frame
    AllTurnStarts(TrackN,TurnStart{TrackN}) = 1;

    %Binned events/second
    AllTurnStartsBinned(TrackN,:) = sum(reshape(AllTurnStarts(TrackN,:),[binning,(movieFrames/binning)]))/(binning/SampleRate);
    
end
end
