function [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins...
    ,SBinTrcksSpdSize,SBinWinSec,currWormSize,St,SBinTrcksSpd,DBinSmoothedEccentricityDSt...
    ,rmdwlstate,PostureState]=SleepQuantFun(SampleRate,pixelsize,Tracks,NumTracks,movieFrames)

% In brief, a worm is considered to be in a high-locomotory state  when
% it continously engages in fast motion events (peaks in speed-profile)
% or continously keeps changing it's posture (derivative
% of eccentricity).

% At any instantaneous moment these
% parameters are calculated within a sliding window of size
% 'SlidingWinSizeSecs' as follows:

% Since the worms change speed and eccentricity very rapidly at
% second timescales, these parameters are not sufficient to determine
% behavioral state at instantaneous time points. Therefore, the fractions
% in each sliding window are calculated at
% which each animal is above a threshold ('cutoff' for speed
% and 'DEccentrThresh' for the time-derivative of eccentricity).
%
% An animal is in high-locomotion state when the fraction is
% above a threshold ('roamthresh' for speed and 'posturethresh'
% for the time-derivative of eccentricity.

%The script identifes motion bouts, which are continous periods
%in high-locomotory state. If the time spend in high locomotion is above a
%threshold ('boutsizethreshold') the animal is considered
%"active", otherwise it is considered "quiescent".

%%
% Modified with Marek Suplata 2013-01-08

%!NOTE: some parts were becoming NaNs due to the Ring distance.

%23/6/2016
%%%% NEED TO WORK OUT spdalsV5_noRing -> changed to spdalsV5_AN, has
%%%% updates.

%NOTE! there was a small bug where active bouts were made to be 1 bin
%longer than they actually were. This also relates to the bug that
%tracks need to be about 540 frames, that has been fixed.

%% Set thresholds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
binning = 15; %binning in frames: speed is averaged over the bins, turns are summed up.

%categorization parameters for speed:
cutoff = 0.008; % 0.008  above which speed (wormlenghts / s) the worm is considered to be engaged in a motion bout
roamthresh = 0.35;

%categorization parameters for eccentricity:
posturethresh = 0.2;
SmoothEccentWin = 5 ; %smooth eccentricity over how many bins
DEccentrThresh = 0.0009; % above which eccentricity change (D/Dt) the worm is considered to be engaged in a motion bout

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

boutsizethreshold = 30; %in bins

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SlidingWinSizeSecs=30; %size of the sliding window from which to count the ratio of fast/slow states as well as high/low eccentricity states. It has to be any multiple of 2 (...for now).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

%Gets the binned speed and eccentricity !!!!!!!!!FIX SPDSALS!!!!!!!
%[SBinWinSec, SBinTrcksSpd, ~, BinTrcksEcc, ~, ~, St] = spdalsV5_noRing(Tracks,binning,SampleRate);

%vs:
%ActivityPlot!!!!
[SBinWinSec, SBinTrcksSpd, ~, BinTrcksEcc, ~, Sbintrcknum, St] = spdalsV5_AN(Tracks,binning);
%note if using spdalsV5 (new) st is 721 long. ned to shorten to 720....,
%it is the correct size when using  spdalsV5_noRing.
%St(end) = [];
%Note: have made a slightly modfied version of spdalsV5 to include
%Ingridsupdate for the RingD.

%% WATCH OUT!!!!!!!Work around, sometimes St is 1 bin longer than it should be.
[~,BNumCheckSt]=size(St);
[~,BNumCheckReal]=size(Sbintrcknum);

if BNumCheckSt ~= BNumCheckReal;
    St(end) = [];
    disp('Corrected St length');
end

clearvars BNumCheckSt BNumCheckReal
%%

currWormSize = NaN(NumTracks, movieFrames); %matrix for instantaneous sizes of worms

SBinTrcksSpdSize = NaN(size(SBinTrcksSpd)); %matrix for speed in wormlengths

DBinSmoothedEccentricityDSt = NaN(size(BinTrcksEcc)); %matrix for eccentricity changes
dSt = diff(St); %time derivative

SlidingWinSizeBins = SlidingWinSizeSecs / SBinWinSec; %convert sliding window size into bins

[~, NumBins] = size(St); %get the number of bins

%matrix that contains the roaming state (the fraction of time where speed is above 'cutoff')
rmdwlstate = NaN(NumTracks,NumBins); %speed fraction above cutoff

%matrix that contains the posture state (the fraction of time where any movement is above 'DEccentrThresh')
PostureState = NaN(NumTracks,NumBins);%eccent fraction above DEccentrThresh

BinSizeFrames = SBinWinSec * SampleRate;

%temporal variables for loop below
wormsizes = [];
wormlength = [];

%analyse each track at a time
for idx = 1:NumTracks;
    
    wormsizes(idx) = mean(Tracks(idx).Size); %get the size of worm in each track
    wormlength(idx) = mode(Tracks(idx).MajorAxes); %get the length of worm in each track
    
    %Get speed normalised by worm length.
    SBinTrcksSpdSize(idx,:) = SBinTrcksSpd(idx,:)/(wormlength(idx)*pixelsize);
    
    %Gets binned Eccentricity and smoothes.
    BinSmoothedEccentricity = nanmoving_average(BinTrcksEcc(idx,:),SmoothEccentWin/2);
    
    %calculate time derivative of eccentricity and fill missing first value with NaN
    DBinSmoothedEccentricityDSt(idx,:) = [NaN abs(diff(BinSmoothedEccentricity)./dSt)];
    
    %calculate rmdwlstate and PostureState. The edges of
    %each track are truncated. Tracks which are smaller
    %than the sliding window are excluded and entries
    %remain all Nan
    
    %Sliding window for speed state (rmdwlstate) or
    %eccentricity state (PostureState).
    for sldidx = 1+SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2
        
        %Check if NumFrames is at least 1 bin big.
        if Tracks(idx).NumFrames > (SlidingWinSizeBins*BinSizeFrames)
            
            rmdwlstate(idx,sldidx) = numel(find(SBinTrcksSpdSize(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2) > cutoff))/sum(isfinite(SBinTrcksSpdSize(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2)));
            
            PostureState(idx,sldidx) = numel(find(DBinSmoothedEccentricityDSt(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2) > DEccentrThresh))/sum(isfinite(DBinSmoothedEccentricityDSt(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2)));
            
        end;
    end;
end;

%Finds where sliding binned speed is over the fraction of bins active threshold.
%for example out of the 7 bins used to calculate the value
%of the rmdwlstate if 2 are "Active" then that whole bin is
%considered wake (non-lethargic). This allows for small
%motion bouts during the lethargic behaviour.

% create a logical indicating when animal is in high-locomotion
Speed = rmdwlstate > roamthresh;

% create a logical indicating when animal is changing posture
%Find where binned and smoothed eccentricity is over the threshold.
Posture = PostureState > posturethresh;

% either one of the conditions have to be met to classify an animal to be in motionh
roam = Speed | Posture; %if bin is either above speed threshold or above eccen threshold then is considered active. | is an 'or'

% find periods of continous motion:
L=[];
roamstats=[];
BoutlengthsBins=[];
MotionBoutsBins=[]; %temporal variables for loop below

for i = 1:NumTracks
    
    L(i,:)=bwlabel(roam(i,:)); %label connected periods of motion = motion bouts
    
    roamstats(i).roamstats=regionprops(L(i,:),'Area','BoundingBox','Centroid'); %create structure that contains duration and start / end of connected periods
    
    %Lenght of active bouts in bins
    BoutlengthsBins{i} = [roamstats(i).roamstats.Area]; %get cell array containing the duration of all motion bouts in a Track
    
    
    currenttrackbouts = [roamstats(i).roamstats.BoundingBox];
    
    %Start of motion bout in bins
    MotionBoutsBins{i} = ceil(currenttrackbouts(1:4:end)); %get cell array containing the starts of all motion bouts in a Track
    
end;

wakestate = NaN(NumTracks,NumBins);
%matrix which will contain 1 (loop below) when animal is active, 0 when quiescent and NaN, when no Track
wakestate(isfinite(rmdwlstate))=0;

motionstate = NaN(NumTracks,NumBins);
%matrix which will contain  1 (loop below) when animal is within a locomotion period , 0 when not and NaN, when no Track
motionstate(isfinite(rmdwlstate))=0;

counter = 0;
%allboutlengths =[];

%EDIT: this replaces the faulty way of calling motionstate
%before which 1.only allocated quiescnence to bouts below
%540frames.
motionstate(isfinite(rmdwlstate)) = double(roam(isfinite(rmdwlstate)));

for i = 1:NumTracks
    %evaluate only tracks that are longer than the boutsizethreshold
    if Tracks(i).NumFrames > (boutsizethreshold + SlidingWinSizeBins) * BinSizeFrames
        
        counter = counter +1;
        bouts = (MotionBoutsBins{i});
        [~, numbouts] = size (bouts);
        
        boutlengths = BoutlengthsBins{i};
        
        for ii = 1:numbouts
            
            %Make active motion bout into wakestate bout
            %if the boutlength is long enough.
            if boutlengths(ii) > boutsizethreshold
                %AN20160714: added -1 to correct the track length.
                wakestate(i,bouts(ii):(bouts(ii)+boutlengths(ii))-1)=1;  %set to 1 when active
                
            else %remove data that cannot be evaluated because the motion period started/ended close to the beginning/end of the Track outside the frames within first/last sliding window
                if bouts(ii) <= 1+SlidingWinSizeBins/2 + Tracks(i).Frames(1)/BinSizeFrames
                    wakestate(i,bouts(ii):(bouts(ii)+boutlengths(ii))-1)=NaN;
                end;
                if (bouts(ii)+boutlengths(ii)-1) >= Tracks(i).Frames(end)/BinSizeFrames - SlidingWinSizeBins/2 %!
                    wakestate(i,bouts(ii):(bouts(ii)+boutlengths(ii))-1)=NaN;
                end;
            end;
        end;
    else
        wakestate(i,:) = NaN;
    end;
    
    %-- get wormsizes
    %currWormSize(i,Tracks(i).Frames(1):Tracks(i).Frames(end)) = Tracks(i).Size;
end;

end
