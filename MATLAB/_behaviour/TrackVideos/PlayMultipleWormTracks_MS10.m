
close all;
clear all;

%-- Main folder containing movies and als files. These als files
%-- have to have the same name as the movies plus ->alsFileEnding
cd('/Volumes/zimmer/Annika/_makeVideos/AN20160511c_CX13663_O2_21_10m_10_10m_Z5_1350_');
diary(strcat(datestr(now,'yyyymmddHHMM'),'_singleTracks.log'));

sParam.spdalsRingLimit = 160;
sParam.xValuesDisplayed = 100;
sParam.samplerate = 3;
sParam.LargeReversalThreshold = 0.35;
sParam.SmallReversalThreshold = 0.15;
sParam.plotOldReversals = 1;
sParam.plotColors = 1;

%-- use this switch to use mp4 movies; 0 ... dont use mp4, 1 ... use mp4
sParam.useMP4 = 1;
sParam.getMovies = dir('*.mp4');

sParam.alsFileEnding = '_tracks_als.mat';

%-- if you want to use specific tracks from a movie set next option to 1
%-- and provide the tracknumbers below. Otherwise set option to 0
sParam.useSpecificTracks = 1;
sParam.useSpecificTracksNr = [1 2 3 4];
%-- if you dont use specific tracks, define minimal length of tracks to be
%-- analysed
sParam.singleTracksMinFrameLength = 700;
sParam.singleTracksPerMovie = 40;
%-- subfolder where the single tracks will be put into
sParam.movieSubFolder = 'singleTracks';

%-- close matlab after script is done
sParam.exitUponFinish = 0;

%-- test the movie window position first, before starting!
%-- distance from [left bottom width height]
%get(0,'ScreenSize')
%figure('Color',[1 1 1],'Position',[100 500 1000 1000])
xMovWinPos = [10 50 1000 1000];

%-- create singleTrackMovie output folder
[status, message, messageid] = mkdir(sParam.movieSubFolder);

for currMovie = 1:size(sParam.getMovies,1)
    [~, currFile, ~] = fileparts(sParam.getMovies(currMovie).name);

    disp(strcat('... load movie', 32, pwd, '\', sParam.getMovies(currMovie).name));
    absMovieName = strcat(pwd, '\', sParam.getMovies(currMovie).name);

    disp(strcat('... load als file', 32, currFile, sParam.alsFileEnding));
    load(strcat(currFile, sParam.alsFileEnding));

    tmpTracksToLookAt = find([Tracks.NumFrames] > sParam.singleTracksMinFrameLength);
    TracksToLookAt = [];

    for j = 1:size(tmpTracksToLookAt,2)
        if Tracks(tmpTracksToLookAt(j)).Frames(size(Tracks(tmpTracksToLookAt(j)).Frames,2)) > 1080
            TracksToLookAt = [TracksToLookAt tmpTracksToLookAt(j)];
        end;
    end;
    
    [SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, ...
        BinTrcksEccWght, Sbintrcknum, St] = spdalsV5_MSv103(sParam, Tracks, 15, 3);
    
    spdfigaxis = [0 St(end) 0 0.1];
    [~, NumOfTrackstoLookAt] = size(TracksToLookAt);
    
    if ~(NumOfTrackstoLookAt < sParam.singleTracksPerMovie)
        NumOfTrackstoLookAt = sParam.singleTracksPerMovie;
    end;
    
    disp('... get single tracks');
    if sParam.useSpecificTracks
        for zz = 1:size(sParam.useSpecificTracksNr,2)
            try
                PlayWormtrackParameters_MSv109(sParam, absMovieName, sParam.useSpecificTracksNr(zz), ...
                    spdfigaxis, Tracks, St, SBinTrcksSpd, SBinWinSec, xMovWinPos);
            catch err
                disp(getReport(err));
            end;
            close all;
        end;
    else
        for z = 1:NumOfTrackstoLookAt
            try
                PlayWormtrackParameters_MSv109(sParam, absMovieName, TracksToLookAt(z), ...
                    spdfigaxis, Tracks, St, SBinTrcksSpd, SBinWinSec, xMovWinPos);
            catch err
                disp(getReport(err));
            end;
            close all;
        end;
    end;
    clearvars -except sParam filename mainDir absMovieName walkDir currFile xMovWinPos;
end;
diary off;

if sParam.exitUponFinish
    exit
end;