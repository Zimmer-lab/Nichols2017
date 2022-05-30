%include also eccentricity parameter
clear all; close all; clc;
% Modified with Marek Suplata 2013-01-08

%mainDir = 'T:/EichlerTomas_isilon/_ALS_STIMULATED/_All_others';
%saveDir = 'T:/EichlerTomas_isilon/_ALS_averaging/Results_Sizes_2';

%Note may need to change slash direction if changing from mac vs PC

mainDir = '/Users/nichols/Desktop/_Dish/Single_Let';
saveDir = '/Users/nichols/Desktop/_Dish/Single_Let';

cd(mainDir);
disp(strcat('... Current directory:', 32, pwd));
walkDir = dir(pwd);

aAllMotionState = [];
aAllWakeState = [];

AllMotionState = [];
AllWakeState = [];
AllSpeed = [];

for dirIdx = 1 : size(walkDir,1)
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(mainDir, '/', walkDir(dirIdx).name));
        disp(strcat('... Current directory:', 32, pwd));

        SaveQuantDataFilename = strcat(saveDir, '/', walkDir(dirIdx).name);
        currFolder = walkDir(dirIdx).name;
        disp(strcat('... save files as:', 32, walkDir(dirIdx).name));

        clearvars -except AllSpeed aAllMotionState aAllWakeState mainDir saveDir walkDir dirIdx SaveQuantDataFilename currFolder AllWakeState AllMotionState;
        close all;

        DataFileName = '*_als.mat';
        Files = dir(DataFileName);
        %-- check for folders not containing proper als.mat files
        if size(Files,1) > 0

            numberOfVideos = 1;
            %numberOfVideos = size(Files,1);

            lengthOfRecording = 20; % [minutes]
            stimuli = 10;

            %-- tickmarks for subplots
            tickmarks  = 0:lengthOfRecording:numberOfVideos*lengthOfRecording;
            %-- framerate at which movie has been recorded
            SampleRate = 3;
            pixelsize  = 0.0276; %pixelsize in mm

            movieFrames = lengthOfRecording*60*SampleRate;
            totalMovieFrames = numberOfVideos*movieFrames;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            SlidingWinSizeSecs=30; %size of the sliding window from which to count the ratio of fast/slow states as well as high/low eccentricity states. It has to be any multiple of 2 (...for now). 

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%

            [NumberOfAlsFiles, ~] = size(Files);

            for CurrAlsFile = 1:NumberOfAlsFiles

                disp(num2str(CurrAlsFile));

                disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
                load(Files(CurrAlsFile).name);

                disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));

                [SBinWinSec, SBinTrcksSpd, ~, BinTrcksEcc, ~, ~, St] = spdalsV5(Tracks,binning,SampleRate);
                
                [~, NumTracks] = size(Tracks);
                
                
                [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins...
                ,SBinTrcksSpdSize,SBinWinSec,currWormSize,St,SBinTrcksSpd,DBinSmoothedEccentricityDSt...
                ,rmdwlstate,PostureState]=SleepQuantFunNoRing(SampleRate,pixelsize,Tracks,NumTracks,movieFrames)

                currWormSize = NaN(NumTracks, movieFrames);

                SBinTrcksSpdSize = NaN(size(SBinTrcksSpd));

                DBinSmoothedEccentricityDSt = NaN(size(BinTrcksEcc));
                EccSmoothWindow = ones(1,SmoothEccentWin)/SmoothEccentWin;
                dSt = diff(St);

                SlidingWinSizeBins = SlidingWinSizeSecs / SBinWinSec;

                [~, NumBins] = size(St);

                rmdwlstate = NaN(NumTracks,NumBins); %speed fraction above cutoff
                PostureState = NaN(NumTracks,NumBins);%eccent fraction above DEccentrThresh

                BinSizeFrames = SBinWinSec * SampleRate;

                wormsizes = [];
                wormlength = [];
                rmdwlratio = [];

                for idx = 1:NumTracks;

                    wormsizes(idx) = mean(Tracks(idx).Size);
                    wormlength(idx) = mode(Tracks(idx).MajorAxes);

                    SBinTrcksSpdSize(idx,:) = SBinTrcksSpd(idx,:)/(wormlength(idx)*pixelsize);

                    %rmdwlratio(idx) = numel(find(SBinTrcksSpdSize(idx,:) > cutoff))/sum(isfinite(SBinTrcksSpdSize(idx,:)));

                    BinSmoothedEccentricity = nanmoving_average(BinTrcksEcc(idx,:),SmoothEccentWin/2);

                    %BinSmoothedEccentricity = convn(BinTrcksEcc(idx,:),EccSmoothWindow,'same');

                    DBinSmoothedEccentricityDSt(idx,:) = [NaN abs(diff(BinSmoothedEccentricity)./dSt)];

                    for sldidx = 1+SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2

                        if Tracks(idx).NumFrames > (SlidingWinSizeBins*BinSizeFrames)

                            rmdwlstate(idx,sldidx) = numel(find(SBinTrcksSpdSize(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2) > cutoff))/sum(isfinite(SBinTrcksSpdSize(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2)));

                            PostureState(idx,sldidx) = numel(find(DBinSmoothedEccentricityDSt(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2) > DEccentrThresh))/sum(isfinite(DBinSmoothedEccentricityDSt(idx,sldidx-SlidingWinSizeBins/2:sldidx+SlidingWinSizeBins/2)));

                        end;
                    end;
                end;

                Speed = rmdwlstate > roamthresh;

                Posture = PostureState > posturethresh;

                roam = Speed | Posture; %if bin is either above speed threshold or above eccen threshold then is considered active. | is an 'or'

                L=[];
                roamstats=[];
                BoutlengthsBins=[];
                MotionBoutsBins=[];

                for i = 1:NumTracks

                    L(i,:)=bwlabel(roam(i,:));

                    roamstats(i).roamstats=regionprops(L(i,:),'Area','BoundingBox','Centroid');

                    BoutlengthsBins{i} = [roamstats(i).roamstats.Area];

                    
                    currenttrackbouts = [roamstats(i).roamstats.BoundingBox];

                    MotionBoutsBins{i} = ceil(currenttrackbouts(1:4:end));

                end;

                wakestate = NaN(NumTracks,NumBins);
                wakestate(isfinite(rmdwlstate))=0;

                motionstate = NaN(NumTracks,NumBins);
                motionstate(isfinite(rmdwlstate))=0;

                counter = 0;
                allboutlengths =[];

                for i = 1:NumTracks
                    if Tracks(i).NumFrames > (boutsizethreshold + SlidingWinSizeBins) * BinSizeFrames 

                        counter = counter +1;
                        bouts = (MotionBoutsBins{i});
                        [~, numbouts] = size (bouts);

                        boutlengths = BoutlengthsBins{i};
                        allboutlengths = [allboutlengths [BoutlengthsBins{i}]];

                        for ii = 1:numbouts
                            motionstate(i,bouts(ii):bouts(ii)+boutlengths(ii))=1;

                            if boutlengths(ii) > boutsizethreshold
                                wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii))=1;

                            else
                                if bouts(ii) <= 1+SlidingWinSizeBins/2 + Tracks(i).Frames(1)/BinSizeFrames
                                    wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii))=NaN;
                                end;
                                if bouts(ii)+boutlengths(ii) >= Tracks(i).Frames(end)/BinSizeFrames - SlidingWinSizeBins/2 %!
                                    wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii))=NaN;
                                end;
                            end;
                        end;
                    else
                        wakestate(i,:) = NaN;
                    end;

                    %-- get wormsizes
                    currWormSize(i,Tracks(i).Frames(1):Tracks(i).Frames(end)) = Tracks(i).Size;
                end;
            end;

%% For averaging

    for ii = 1:NumTracks;
            aAllMotionState = cat(1,aAllMotionState,motionstate(ii,:));
            aAllWakeState = cat(1,aAllWakeState,wakestate(ii,:));
        % only take full length tracks
        if Tracks(1, ii).NumFrames == 3600;
            AllMotionState = cat(1,AllMotionState,motionstate(ii,:));
            AllWakeState = cat(1,AllWakeState,wakestate(ii,:));
            AllSpeed = cat(1,AllSpeed,SBinTrcksSpd(ii,:));
            
        end
    end 
        cd(mainDir);
        currFiles = dir(pwd);
        end;
    end;
    %figure;imagesc(AllWakeState)

   
end
close all;

figure;imagesc(AllWakeState)
title('WakeState')

figure;imagesc(AllMotionState)
title('MotionState')

figure;imagesc(AllSpeed)
title('Speed')

%figure;plot(mean(AllWakeState))

save (([strcat(mainDir,'/DishWakeState_OLD') '.mat']), 'AllMotionState','AllSpeed','AllWakeState'); 
