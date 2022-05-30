%reorganise top!

mainDir = pwd;

disp(strcat('... Current directory:', 32, pwd));


clearvars -except S E mainDir currFolder direct condition allnormSpeed allnormEccen nnn CurrCond tRange;

DataFileName = '*_als.mat';
Files = dir(DataFileName);
%-- check for folders not containing proper als.mat files
if size(Files,1) > 0

    lengthOfRecording = 20; % [minutes]

    %-- framerate at which movie has been recorded
    SampleRate = 3;
    pixelsize  = 0.0276; %pixelsize in mm

    movieFrames = lengthOfRecording*60*SampleRate;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    binning = 15; %binning in frames: speed is averaged over the bins, turns are summed up.

    SmoothEccentWin = 5 ; %smooth eccentricity over how many bins

    SlidingWinSizeSecs=30; %size of the sliding window from which to count the ratio of fast/slow states as well as high/low eccentricity states. It has to be any multiple of 2 (...for now). 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%

    [NumberOfAlsFiles, ~] = size(Files);

    for CurrAlsFile = 1:NumberOfAlsFiles

        disp(num2str(CurrAlsFile));

        disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
        load(Files(CurrAlsFile).name);

        disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));

        [SBinWinSec, SBinTrcksSpd, ~, BinTrcksEcc, ~, ~, St] = spdalsV5(Tracks,binning);

        [~, NumTracks] = size(Tracks);

        currWormSize = NaN(NumTracks, movieFrames);

        SBinTrcksSpdSize = NaN(size(SBinTrcksSpd));

        DBinSmoothedEccentricityDSt = NaN(size(BinTrcksEcc));
        EccSmoothWindow = ones(1,SmoothEccentWin)/SmoothEccentWin;
        dSt = diff(St);

        SlidingWinSizeBins = SlidingWinSizeSecs / SBinWinSec;

        [~, NumBins] = size(St);

        wormlength = [];

        for idx = 1:NumTracks;

            wormlength(idx) = mode(Tracks(idx).MajorAxes);

            SBinTrcksSpdSize(idx,:) = SBinTrcksSpd(idx,:)/(wormlength(idx)*pixelsize);

            BinSmoothedEccentricity = nanmoving_average(BinTrcksEcc(idx,:),SmoothEccentWin/2);

            DBinSmoothedEccentricityDSt(idx,:) = [NaN abs(diff(BinSmoothedEccentricity)./dSt)];

        end;
    end
end

clearvars -except S E DBinSmoothedEccentricityDSt SBinTrcksSpdSize mainDir  condition...
                  nnn direct CurrCond allnormSpeed allnormEccen tRange...
