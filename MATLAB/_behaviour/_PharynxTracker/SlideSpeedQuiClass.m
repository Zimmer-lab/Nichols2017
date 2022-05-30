%%Calculates SlideSpeed and Quiescence Classification

cutoff1 = 3; % above which speed the worm is considered to be engaged in a motion bout
%roamthresh = 0.35; 

if ~exist('cutoff','var');
    cutoff =cutoff1;
end
clearvars cutoff1

%% Sliding window for speed 
SlideBin = 1; %in seconds must be divisible by 0.2.
fps = 5;

%Remove this border amount (no sliding window there)
Border = floor((SlideBin/2)*fps); %CAREFUL FLOOR may not work well for every SlideBin size. Does for 1s

for iii = (Border+1):(length(Tracks.WormSpeed)-Border);
    SlideSpeed(1,iii-Border) = mean(Tracks.WormSpeed((iii-Border):(iii+Border)));
end
%% Quiescence Classification
%categorization parameters for speed:

Active = SlideSpeed > cutoff;
Active = double(Active);