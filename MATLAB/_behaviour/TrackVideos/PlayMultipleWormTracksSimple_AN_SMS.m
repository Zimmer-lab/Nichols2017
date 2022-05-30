%% Makes movie of worm with motionstate, eccentricity and speed
% filename = 'CX13663_O2_11long_6mShifts_20160715_Z2_full_adults_A1_201607151122_mjpeg_mp4.mp4';
% 
% load('CX13663_O2_11long_6mShifts_20160715_Z2_full_adults_A1201607151122_mjpeg_v2_tracks_als.mat');

% For plotting motionstate
load('Smotionstate.mat');

% filename = 'CX13663_O2_11long_9m_c_20160724a_Z2_full_adults_A1_201607241313_mjpeg_mp4.mp4';
% 
% load('201607241313_mjpeg_v2_tracks_als');
filename = 'CX13663_O2_11long_6mShifts_20160718_Z2_full_adults_A2201607181719_mjpeg_mp4.mp4';

load('CX13663_O2_11long_6mShifts_20160718_Z2_full_adults_A2201607181719_mjpeg_v2_tracks_als');

TracksToLookAt =[16]; %23,34,44,47,48,58 %20,21,43

useMP4 = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, StrcksSpdWght, StrcksSpd, Sbintrcknum, St] = spdalsV5_AN_noRing(Tracks,15);

%Smotionstate
SampleRate = 3;
sParam = 1;

%Get unbinned StrcksSpd, StrcksEcc.
[BinWinSec, StrcksSpd, ~, StrcksEcc, ~, ~, t]=...
spdalsV5_MSv103_AndreaNoRing(sParam, Tracks, 1, SampleRate);

%% Get binned and size speed
SBinWinSec = 1; %SBinWinSec = QBinning/SampleRate
QBinning = 3;

% calculate Qt based on SpdBinning of 3
maxFrames = size(StrcksSpd,2);
BinNum = maxFrames/QBinning; %default 1100; long: 7820
Qt = (SBinWinSec / 2 : SBinWinSec : SBinWinSec * BinNum - (SBinWinSec / 2));

NumTracks = size(Tracks,2);
NumBins = size(Qt,2);

% Bin speed
for m = 1:NumTracks
    SBinTrcksSpd(m,:) = nanmean(reshape(StrcksSpd(m,1 : NumBins * QBinning), QBinning, NumBins));
end


%%
Len = max([Tracks.Frames]);
BinWin = 3; %for SMS 5 for TEMZ
St=(BinWin/2:BinWin:16200)/SampleRate; % time(seconds)


%%
spdfigaxis=[0 t(end) 0 0.1];

[~, NumOfTrackstoLookAt] = size(TracksToLookAt);


for i = 1:NumOfTrackstoLookAt;

%PlayWormtrackSimple_AN(filename,TracksToLookAt(i),spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec,aAllMotionState,useMP4);

% Smotionstate
PlayWormtrackSimple_AN(filename,TracksToLookAt(i),spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec,aAllFinalWakeState,aAllMotionState,useMP4);

%PlayWormtrackParameters(filename,currenttrackno,spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec)

close all;

end;