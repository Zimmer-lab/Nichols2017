filename = 'AN20160511c_CX13663_O2_21_10m_10_10m_Z5_1350_201605111158_mjpeg_mp4.mp4';

load('AN20160511c_CX13663_O2_21_10m_10_10m_Z5_1350_201605111158_mjpeg_v2_tracks_als.mat');

% For plotting motionstate
load('AN20160511c_DishWakeState.mat');

%PositionOfFigure = [5 -700 1500 1200];

%TracksToLookAt =[3  13  20  22  23  27  35  39  42  47  49  51  84  86  87  93  98  102  142  147  161  163  168  172  174];

TracksToLookAt =[2:6];

useMP4 =1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, StrcksSpdWght, StrcksSpd, Sbintrcknum, St] = spdalsV5_AN_noRing(Tracks,15);
%[BinWinSec, BinTrcksSpd, BinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, bintrcknum, t]



spdfigaxis=[0 St(end) 0 0.1];



[~, NumOfTrackstoLookAt] = size(TracksToLookAt);


for i = 1:NumOfTrackstoLookAt;

PlayWormtrackSimple_MS(filename,TracksToLookAt(i),spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec,aAllMotionState,aAllEccen,aAllSpeed,useMP4);

%PlayWormtrackParameters(filename,currenttrackno,spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec)

close all;

end;