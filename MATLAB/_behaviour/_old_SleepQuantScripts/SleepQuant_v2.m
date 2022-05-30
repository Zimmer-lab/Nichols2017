%include also eccentricity parameter
clear all; %close all; clc;
% Modified with Marek Suplata 2013-01-08

%Note may need to change slash direction if changing from mac vs PC

mainDir = pwd; %'/Users/nichols/Desktop/_test/npr-1-gcy-35_21.0_s_20130826_Z3_X9_23.05_s44.1h_201308262343_tracks_als_R_als';
saveDir = pwd; %'/Users/nichols/Desktop/_test/npr-1-gcy-35_21.0_s_20130826_Z3_X9_23.05_s44.1h_201308262343_tracks_als_R_als';

minTrackSize = 550; %'All' matrices include only tracks of a certain size. aAll include all. min is 541.

plotFlag = 0; %1 is on, 0 is off. For Dish Assays.

%%
%!NOTE: some parts were becoming NaNs due to the Ring distance. This scrit
%now uses a spdalsV5 which doesn't disclude based on Ring distance.
%23/6/2016

%Note! some tracks that are two short just get put as quiescent for
%motinstate. This is a bug. Make sure you use then minTrackSize, or have
%tracks above a certain size (700 is perfect).

cd(mainDir);
disp(strcat('... Current directory:', 32, pwd));
walkDir = dir(pwd);

aAllMotionState = [];
aAllWakeState = [];
aAllSpeed = [];
aAllEccen = [];
aAllrmdwlstate = [];
aAllPostureState = [];

AllMotionState = [];
AllWakeState = [];
AllSpeed = [];
AllEccen = [];
Allrmdwlstate = [];
AllPostureState = [];

for dirIdx = 1 : size(walkDir,1)
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(mainDir, '/', walkDir(dirIdx).name));
        disp(strcat('... Current directory:', 32, pwd));

        SaveQuantDataFilename = strcat(saveDir, '/', walkDir(dirIdx).name);
        currFolder = walkDir(dirIdx).name;
        disp(strcat('... save files as:', 32, walkDir(dirIdx).name));

        %clearvars -except condition CurrCond tRange nnn plotFlag Allrmdwlstate AllPostureState AllSpeed AllEccen aAllMotionState aAllWakeState mainDir saveDir walkDir dirIdx SaveQuantDataFilename currFolder AllWakeState AllMotionState;
        %close all;
        
        %%
        DataFileName = '*_als.mat';
        Files = dir(DataFileName);
        %-- check for folders not containing proper als.mat files
        if size(Files,1) > 0

            numberOfVideos = 1;
            %numberOfVideos = size(Files,1);

            lengthOfRecording = 20; % [minutes]
            stimuli = 10;

            %-- tickmarks for subplots
            %tickmarks  = 0:lengthOfRecording:numberOfVideos*lengthOfRecording;
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
                
                %Gets the binned speed and eccentricity
                [SBinWinSec, SBinTrcksSpd, ~, BinTrcksEcc, ~, ~, St] = spdalsV5_noRing(Tracks,binning,SampleRate);
                
                [~, NumTracks] = size(Tracks);

                currWormSize = NaN(NumTracks, movieFrames);

                SBinTrcksSpdSize = NaN(size(SBinTrcksSpd));

                DBinSmoothedEccentricityDSt = NaN(size(BinTrcksEcc));
                %EccSmoothWindow = ones(1,SmoothEccentWin)/SmoothEccentWin;
                dSt = diff(St);

                SlidingWinSizeBins = SlidingWinSizeSecs / SBinWinSec;

                [~, NumBins] = size(St);

                rmdwlstate = NaN(NumTracks,NumBins); %speed fraction above cutoff
                PostureState = NaN(NumTracks,NumBins);%eccent fraction above DEccentrThresh

                BinSizeFrames = SBinWinSec * SampleRate;

                wormsizes = [];
                wormlength = [];
                %rmdwlratio = [];

                for idx = 1:NumTracks;

                    wormsizes(idx) = mean(Tracks(idx).Size);
                    wormlength(idx) = mode(Tracks(idx).MajorAxes);
                    
                    %Get speed normalised by worm lenght.
                    SBinTrcksSpdSize(idx,:) = SBinTrcksSpd(idx,:)/(wormlength(idx)*pixelsize);

                    %rmdwlratio(idx) = numel(find(SBinT rcksSpdSize(idx,:) > cutoff))/sum(isfinite(SBinTrcksSpdSize(idx,:)));
                    
                    %Gets binned Eccentricity and smoothes.
                    BinSmoothedEccentricity = nanmoving_average(BinTrcksEcc(idx,:),SmoothEccentWin/2);

                    %BinSmoothedEccentricity = convn(BinTrcksEcc(idx,:),EccSmoothWindow,'same');

                    DBinSmoothedEccentricityDSt(idx,:) = [NaN abs(diff(BinSmoothedEccentricity)./dSt)];
                    
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
                Speed = rmdwlstate > roamthresh;
                
                %Find where binned and smoothed eccentricity is over the threshold.
                Posture = PostureState > posturethresh;

                %roam = active/awake.
                roam = Speed | Posture; %if bin is either above speed threshold or above eccen threshold then is considered active. | is an 'or'

                % find periods of continous motion:
                L=[];
                roamstats=[];
                BoutlengthsBins=[];
                MotionBoutsBins=[]; %temporal variables for loop below

                for i = 1:NumTracks

                    L(i,:)=bwlabel(roam(i,:)); % label connected periods of motion = motion bouts

                    roamstats(i).roamstats=regionprops(L(i,:),'Area','BoundingBox','Centroid'); %create structure that contains duration and start / end of connected periods
                    
                    %Lenght of active bouts in bins
                    BoutlengthsBins{i} = [roamstats(i).roamstats.Area]; %get cell array containing the duration of all motion bouts in a Track

           
                    currenttrackbouts = [roamstats(i).roamstats.BoundingBox];
                    
                    %Start of motion bout in bins
                    MotionBoutsBins{i} = ceil(currenttrackbouts(1:4:end)); %get cell array containing the starts of all motion bouts in a Track

                end;

                wakestate = NaN(NumTracks,NumBins);
                wakestate(isfinite(rmdwlstate))=0;

                motionstate = NaN(NumTracks,NumBins);
                motionstate(isfinite(rmdwlstate))=0;

                counter = 0;
                %allboutlengths =[];

                for i = 1:NumTracks
                    if Tracks(i).NumFrames > (boutsizethreshold + SlidingWinSizeBins) * BinSizeFrames 

                        counter = counter +1;
                        bouts = (MotionBoutsBins{i});
                        [~, numbouts] = size (bouts);

                        boutlengths = BoutlengthsBins{i};
                        %allboutlengths = [allboutlengths [BoutlengthsBins{i}]];

                        for ii = 1:numbouts %NOTE: if tracks are shorter than 540frams (defined in if above) 
                            %then this doesn't happen, leaving all short motion bouts as 0.
                            
                            %Make active motion state =1
                            motionstate(i,bouts(ii):bouts(ii)+boutlengths(ii))=1;
                            
                            %Make active motion bout into wakestate bout
                            %if the boutlength is long enough.
                            if boutlengths(ii) > boutsizethreshold
                                wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii))=1;

                            else %remove data that cannot be evaluated because the motion period started/ended close to the beginning/end of the Track outside the frames within` first/last sliding window
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
                %% For averaging
                
                for ii = 1:NumTracks; %all tracks
                    aAllMotionState = cat(1,aAllMotionState,motionstate(ii,:));
                    aAllWakeState = cat(1,aAllWakeState,wakestate(ii,:));
                    aAllSpeed = cat(1,aAllSpeed,SBinTrcksSpd(ii,:));
                    aAllEccen = cat(1,aAllEccen,DBinSmoothedEccentricityDSt(ii,:));
                    aAllrmdwlstate = cat(1,aAllrmdwlstate,rmdwlstate(ii,:));
                    aAllPostureState = cat(1,aAllPostureState,PostureState(ii,:));
                    
                    % only take full length tracks
                    if Tracks(1, ii).NumFrames > minTrackSize;
                        AllMotionState = cat(1,AllMotionState,motionstate(ii,:));
                        AllWakeState = cat(1,AllWakeState,wakestate(ii,:));
                        AllSpeed = cat(1,AllSpeed,SBinTrcksSpd(ii,:));
                        AllEccen = cat(1,AllEccen,DBinSmoothedEccentricityDSt(ii,:));
                        Allrmdwlstate = cat(1,Allrmdwlstate,rmdwlstate(ii,:));
                        AllPostureState = cat(1,AllPostureState,PostureState(ii,:));
                    end
                end

            end;                
            cd(mainDir);
            currFiles = dir(pwd);
        end;
    end;
    %figure;imagesc(AllWakeState)
   
end
%close all;

%% Plotting for Dish Assays

if plotFlag ==1;
    DishAssayPlot
end

%%
save (([strcat(mainDir,'/WakeState') '.mat']), 'AllMotionState','AllSpeed','AllWakeState',...
    'Allrmdwlstate','AllPostureState','AllEccen', 'aAllMotionState','aAllWakeState',...
    'aAllSpeed','aAllrmdwlstate','aAllPostureState','aAllEccen'); 
