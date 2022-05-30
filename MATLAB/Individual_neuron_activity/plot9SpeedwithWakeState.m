%This script will take the first 9 tracks which go over the defined period
%and plot the speed and stimuli for these. Works on the first als file.
close all;
%This script needs to have run a SleepWakeClassificationScript before
%starting. Below will check this and run if this hasn't been done.


%Can change these 3 parameters
PreStim=540; %Amount in frames prestimulus to include
PostStim=1620; %Amount in frames to include after stimulus
TrackN=75;


workdir=cd;
if exist('MotionBoutsBins')~=1
%run SleepWakeClassificationScript2
%runs stripped down version of SleepWakeClassification script

        DataFileName = '*_als.mat';
        Files = dir(DataFileName);
        %-- check for folders not containing proper als.mat files
        %!if size(Files,1) > 0

            numberOfVideos = 14;
            numberOfVideos = size(Files,1);

            lengthOfRecording = 90; % [minutes]
            
            %-- framerate at which movie has been recorded
            SampleRate = 3;
            pixelsize  = 0.0276; %pixelsize in mm

            %-- required for plotting wormsize median and mode
            movieFrames = lengthOfRecording*60*SampleRate;
            totalMovieFrames = numberOfVideos*movieFrames;
            sizeBinFrames = 2700;
            %!%-- choose only sizeBinFrames which result in an integer sizeBin
            %-- otherise reshape command will later on throw an error
            sizeBins = movieFrames/sizeBinFrames;
            totalSizeBins = totalMovieFrames/sizeBinFrames;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %First level classification: Quiescent or Active
            %Second level classification: Sleep bout or Wake bout

            binning = 15; %binning in frames: speed is averaged over the bins, turns are summed up.

            %categorization parameters for speed:
            cutoff = 0.008; % 0.008  above which speed (wormlenghts / s) the worm is considered to be engaged in a motion bout
            roamthresh = 0.35; % this is the value that the ratio of the first level Quiescence vs Active 
                               % that needs to be crossed for that bin to
                               % be counted as second level Wake bout or
                               % Sleep bout

            %categorization parameters for eccentricity:
            posturethresh = 0.2;
            SmoothEccentWin = 5 ; %smooth eccentricity over how many bins
            DEccentrThresh = 0.0009; % above which eccentricity change (D/Dt) the worm is considered to be engaged in a motion bout

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            boutsizethreshold = 30; %in bins

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            SlidingWinSizeSecs=30; %size of the sliding window from which to count the ratio of fast/slow states as well as high/low eccentricity states. It has to be any multiple of 2 (...for now). 

            %Recap: Bin=                15 frames 5s  1 bin
            %       SlidingWindow=      90 frames 30s 6 bins
            %       Boutsizethreshold= 450 frames 150s 30 bins
           
                disp(strcat('now loading: ',32, Files(1).name));
                load(Files(1).name);

                disp(strcat('now analyzing: ',32, Files(1).name));

                %[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5(Tracks,binning,SampleRate);
                %[BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, BinTrcksLRstate, BinTrcksSRstate, BinTrcksOstate, t] = ROalsV3(Tracks,binning,SampleRate);
                [SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5(Tracks,binning);
                [BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, BinTrcksLRstate, BinTrcksSRstate, BinTrcksOstate, t] = ROalsV3(Tracks,binning);
                %[BinWinSec, trcksLR, trcksSR, trcksO, BinTrcksLR, BinTrcksSR, BinTrcksO, bintrcknum, trcknum, t] = ROals(Tracks,binning);
                % %_______________________________________________________________________

                [~, NumTracks] = size(Tracks);

                SBinTrcksSpdSize = NaN(size(SBinTrcksSpd));

                DBinSmoothedEccentricityDSt = NaN(size(BinTrcksEcc));
                EccSmoothWindow = ones(1,SmoothEccentWin)/SmoothEccentWin;
                dSt = diff(St);

                SlidingWinSizeBins = SlidingWinSizeSecs / SBinWinSec;

                [~, NumBins] = size(St);

                rmdwlstate = NaN(NumTracks,NumBins); %speed fractions that are above cutoff
                PostureState = NaN(NumTracks,NumBins);%eccentricity fractions that are above DEccentrThresh

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

                %allareas=[];
                %allboundingboxes = [];

                L=[];
                roamstats=[];
                BoutlengthsBins=[];
                MotionBoutsBins=[];

                for i = 1:NumTracks

                    L(i,:)=bwlabel(roam(i,:));

                    roamstats(i).roamstats=regionprops(L(i,:),'Area','BoundingBox','Centroid');

                    BoutlengthsBins{i} = [roamstats(i).roamstats.Area];

                    %allareas = [allareas roamstats(i).roamstats.Area];

                    currenttrackbouts = [roamstats(i).roamstats.BoundingBox];

                    MotionBoutsBins{i} = ceil(currenttrackbouts(1:4:end));

                    %allboundingboxes = [allboundingboxes roamstats(i).roamstats.BoundingBox];
                    %motionbouts = ceil(allboundingboxes(1:2:end));

                end;

                wakestate = NaN(NumTracks,NumBins); %this matrix contains the second layer Wake and Sleep information for each bin of each track
                wakestate(isfinite(rmdwlstate))=0;

                motionstate = NaN(NumTracks,NumBins); %this matrix contains the first layer Quiescent and Active information for each bin for each track
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
                end;
close all;
end

speed=NaN((PreStim+PostStim),9);
StimStart=4680; %in frames, should be always the same
count=1;
plot9motionstate=NaN(((PreStim+PostStim)/15),9);
plot9MotionBoutsBins=cell(1,9);
plot9BoutlengthsBins=cell(1,9);
BinStart=(StimStart-PreStim)/15;
BinFinish=(StimStart+PostStim)/15;


while count<=9; 
        if ((find(Tracks(TrackN).Frames==(StimStart-PreStim)))>=1) & ((find(Tracks(TrackN).Frames==(StimStart+PostStim-1)))>=1);
            speed(:,count)=Tracks(TrackN).Speed((StimStart-PreStim):((StimStart+PostStim)-1));
            plot9motionstate(:,count)=motionstate(TrackN,((StimStart-PreStim)/15):(((StimStart+PostStim)/15))-1);
            plot9MotionBoutsBins{1,count}=MotionBoutsBins{1,TrackN};
            plot9BoutlengthsBins{1,count}=BoutlengthsBins{1,TrackN};
            TrackN=TrackN+1;
            count=count+1;
        else
            TrackN=TrackN+1;
        end
end
plot9MotionBoutsFrames=cellfun(@(x) x*15,plot9MotionBoutsBins,'un',0);
plot9BoutlengthsFrames=cellfun(@(x) x*15,plot9BoutlengthsBins,'un',0);

figure;
for wormnum = 1:9
    subplot(3,3,wormnum);
    MatrixMotionBouts=plot9MotionBoutsFrames{1,wormnum};
    MatrixBoutlengths=plot9BoutlengthsFrames{1,wormnum};
    [~,boutmax]=size(plot9MotionBoutsFrames{wormnum});
    
    for boutnum =1:boutmax
        %plots yellow for active bouts
        R=rectangle('Position',[(MatrixMotionBouts(1,boutnum)-(StimStart-PreStim)),0,(MatrixBoutlengths(1,boutnum)),0.21]);
        set(R,'FaceColor',[1 1 0.7],'edgecolor','w')
        
    end
    hold on;
    plot(speed(:,wormnum));
    axis([1 2160 0 0.2]); %Can change axis here if needed
    xlabel('Time (frames)','FontSize',13);
    ylabel('Speed','FontSize',13);
    %Stimulus start line:
    line('XData', [PreStim PreStim], 'YData', [-1 2.5], 'LineStyle', '-')
    %Stimulus end line:
    line('XData', [(PreStim+1080) (PreStim+1080)], 'YData', [-1 2.5], 'LineStyle', '-')
    
end