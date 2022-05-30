% filename = 'npr-1-CX13663-Singled_DOTS_18C_O2_21.0_c_20140218_Z5_X8_10.30_201402182308_mjpeg.avi';
% 
% load('npr-1-CX13663-Singled_DOTS_18C_O2_21.0_c_20140218_Z5_X8_10.30_201402182308_mjpeg_tracks_als.mat');

% filename = 'AN20160511c_CX13663_O2_21_10m_10_10m_Z5_1350_201605111158_mjpeg_mp4.mp4';
% 
% load('AN20160511c_CX13663_O2_21_10m_10_10m_Z5_1350_201605111158_mjpeg_v2_tracks_als.mat');

filename = 'CX13663_O2_11long_6mShifts_20160715_Z2_full_adults_A1_201607151122_mjpeg_mp4.mp4';

load('CX13663_O2_11long_6mShifts_20160715_Z2_full_adults_A1201607151122_mjpeg_v2_tracks_als.mat');

%PositionOfFigure = [5 -700 1500 1200];

%TracksToLookAt =[3  13  20  22  23  27  35  39  42  47  49  51  84  86  87  93  98  102  142  147  161  163  168  172  174];

TracksToLookAt =[2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, StrcksSpdWght, StrcksSpd, Sbintrcknum, Strcknum, St] = spdals(Tracks,15);




spdfigaxis=[0 St(end) 0 0.1];



[~, NumOfTrackstoLookAt] = size(TracksToLookAt);


for i = 1:NumOfTrackstoLookAt;

PlayWormtrackSimple(filename,TracksToLookAt(i),spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec);

%PlayWormtrackParameters(filename,currenttrackno,spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec)

close all;

end;