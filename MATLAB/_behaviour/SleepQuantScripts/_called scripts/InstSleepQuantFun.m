%% InstSleepQuantFun
% This script uses binned speed and eccentricity to determine the
% instantaneous motionstate for that bin. SleepQuantFun uses sliding
% windows and smoothing. Optimised for binning of 5sec. Uses input from
% SleepQuantFun.

function [InstMotionState] = InstSleepQuantFun(binning,Tracks,NumTracks,SBinTrcksSpdSize)
%% categorization parameters for speed:
SpeedCutoff = 0.008; % 0.008  above which speed (wormlenghts / s) the worm is considered to be engaged in a motion bout

%categorization parameters for eccentricity:
DEccentrThresh = 0.0009; % above which eccentricity change (D/Dt) the worm is considered to be engaged in a motion bout

[~, ~, ~, BinTrcksEcc, ~, Sbintrcknum, St] = spdalsV5_AN(Tracks,binning);
%note if using spdalsV5 (new) st is 721 long. ned to shorten to 720....,
%it is the correct size when using  spdalsV5_noRing.
%St(end) = [];
%Note: have made a slightly modfied version of spdalsV5 to include
%Ingridsupdate for the RingD.

%% Work around, sometimes St is 1 bin longer than it should be.
[~,BNumCheckSt]=size(St);
[~,BNumCheckReal]=size(Sbintrcknum);

if BNumCheckSt ~= BNumCheckReal;
    St(end) = [];
    disp('Corrected St length');
end

clearvars BNumCheckSt BNumCheckReal

dSt = diff(St); %time derivative

DBinEccentricityDSt = nan(NumTracks,length(Sbintrcknum));
%analyse each track at a time
for idx = 1:NumTracks;
    %calculate time derivative of eccentricity and fill missing first value with NaN
    DBinEccentricityDSt(idx,:) = [NaN abs(diff(BinTrcksEcc(idx,:))./dSt)];
end

% test = DBinSmoothedEccentricityDSt > DEccentrThresh;

%% create a logical indicating when animal is in high-locomotion 
% (both or either of the speed and eccentricity derivative are over their thresholds
InstSpeed = SBinTrcksSpdSize > SpeedCutoff;

%Find where binned eccentricity is over the threshold.
instPosture = DBinEccentricityDSt > DEccentrThresh;

% either one of the conditions have to be met to classify an animal to be in motion
InstMotionState = single(InstSpeed | instPosture);

InstMotionState(isnan(SBinTrcksSpdSize)) = NaN;

end

% IMS = InstMotionState;
% IMS(isnan(IMS)) = -1;
% 
% MS = motionstate;
% MS(isnan(MS)) = -1;
% 
% figure; imagesc(IMS(1:100,:))
% figure; imagesc(MS(1:100,:))