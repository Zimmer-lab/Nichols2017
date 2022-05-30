%% MotionBoutStats
% This script returns information about bout statistics.

% Find long tracks



% Find motion bouts

test = motionstate;

changes = diff(test(11,:));

qui2wake = find(changes == 1);
wake2qui = find(changes == -1);

    
    motionstats(ii).motiostats=regionprops(L(ii,:),'Area','BoundingBox','Centroid'); %create structure that contains duration and start / end of connected periods
    
    %Lenght of active bouts in bins
    BoutlengthsBins{ii} = [motionstats(1).motiostats.Area]; %get cell array containing the duration of all motion bouts in a Track
    
    
    currenttrackbouts = [motionstats(ii).motiostats.BoundingBox];
    
    %Start of motion bout in bins
    MotionBoutsBins{ii} = ceil(currenttrackbouts(1:4:end)); %get cell array containing the starts of all motion bouts in a Track
;
    

figure; imagesc(changes)
figure;imagesc(motionstate(11,:))