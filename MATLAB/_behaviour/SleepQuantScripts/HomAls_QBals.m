%%
%finding lethargic vs non-lethargic animals
%only full tracks with less than x active
MinQuiescene = 0.5;

%For finding lethargic vs non-lethargic
ConditionalBinSec = [1260 1500];

%Finds Bout lengths and number during a period of lethargic animals,
%normally a period post-stim.
MeasurePeriod =[sum(Stim1)+120, sum(Stim1)+120+120];
BaselinePeriod =[1260, 1260+120];

%
%Annika 20170306

%Gets only full length tracks over this period
MinTimeFilled = [min([ConditionalBinSec(1,1), MeasurePeriod(1,1),BaselinePeriod(1,1)]),...
    max([ConditionalBinSec(1,2), MeasurePeriod(1,2),BaselinePeriod(1,2)])];

%% Input into sleepQuantFun
lengthOfRecording = 90; % [minutes]

%-- framerate at which movie has been recorded
SampleRate = 3;
pixelsize  = 0.0276; %pixelsize in mm

% %-- required for plotting wormsize median and mode
% sizeBinFrames = 2700;
% %-- choose only sizeBinFrames which result in an integer sizeBin
% %-- otherise reshape command will later on throw an error
movieFrames = lengthOfRecording*60*SampleRate;

%% Get als (analysed) files
DataFileName = '*als.mat';
Files = dir(DataFileName);
[NumberOfAlsFiles, ~] = size(Files);

CurrAlsFile=1;
disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
[Tracks, files, DatasetPointer] = AccRevDatsV2_AN(DataFileName);

disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));

%% Call Sleep quantification script
[~, NumTracks] = size(Tracks);
% Call SleepQuantFun
[motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
    SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
    NumTracks,movieFrames);

%REMIMNDER: still have to fix problem with RingDistance here:
%%[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5_old(Tracks,binning,SampleRate); % create matrices that contain speed and eccentricity (rows = Tracks, columns = frames);

%% Find tracks covering the whole video
FullTracks=(sum(~isnan(wakestate),2))==1074;

TracksQ = nanmeanD(wakestate,2)<MinQuiescene;
FullLetTracks = FullTracks ==1 && TracksQ==1;

%%
Qstarts={};
QLength={};
QEnd={};
Astarts={};
ALength={};
AEnd={};

cnt=0;
for TrackN =1:NumTracks;
    if FullLetTracks(TrackN)==1
        cnt = cnt+1;
        % Find Quiescence bouts
        M = abs(motionstate(TrackN,:)-1);
        M(isnan(M))=0;
        L = bwlabel(M);
        stats= regionprops(L);
        BoutNum = length(stats);
        cntB=0;
        for BoutN =1:BoutNum;
            % add bout start and length, disclude bouts that start on 1
            % (i.e. start outside of measured area), and doesn't finish
            % within the measured period
            if stats(BoutN, 1).BoundingBox(1,1)>=1.5 && ...
                    (stats(BoutN, end).BoundingBox(1,1) + stats(BoutN, end).BoundingBox(1,3))<1077;
                cntB =cntB+1;
                Qstarts{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,1)+0.5;
                QLength{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,3);
                QEnd{cnt}(1,cntB) = Qstarts{cnt}(1,cntB)+QLength{cnt}(1,cntB);
                %For each Q bout included get the preceeding A bout length,
                %note that for the first Q bout it will always be a nan if
                %there wasn't a cut QB at the start.
                
                %need to take into account NaNs at the start...
                
                %in the case where the track started with activity (so the first activity bout won't be counted:
                if BoutN == 1 && cntB ==1;
                    PriorABoutLength{cnt}(1,cntB) = NaN;
                %in the case where the track started with cutoff QB (so the
                %activity bout can be counted)
                elseif BoutN == 2 && cntB ==1;
                    %find current start position and subtract the end of
                    %the first bout (end being start +length)
                    PriorABoutLength{cnt}(1,cntB) = Qstarts{cnt}(1,cntB) - (stats(1, 1).BoundingBox(1,1)+0.5 +stats(1, 1).BoundingBox(1,3));
                else
                    PriorABoutLength{cnt}(1,cntB)= Qstarts{cnt}(1,cntB) - QEnd{cnt}(1,(cntB-1));
                end
            end
        end
%         % Find Active bouts
%         M = motionstate(TrackN,:);
%         M(isnan(M))=0;
%         L = bwlabel(M);
%         stats= regionprops(L);
%         BoutNum = length(stats);
%         cntB=0;
%         for BoutN =1:BoutNum;
%             % add bout start and length, disclude bouts that start on 1
%             % (i.e. start outside of measured area), and doesn't finish
%             % within the measured period
%             if stats(BoutN, 1).BoundingBox(1,1)>=1.5 && ...
%                     (stats(BoutN, end).BoundingBox(1,1) + stats(BoutN, end).BoundingBox(1,3))<1077;
%                 cntB =cntB+1;
%                 Astarts{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,1)+0.5;
%                 ALength{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,3);
%                 AEnd{cnt}(1,cntB) = Astarts{cnt}(1,cntB)+ALength{cnt}(1,cntB);
%             end
%         end
    end
end
%%

AllQLengths = (cat(2, QLength{:}))*SBinWinSec;
figure; hist(AllQLengths,100);
AverageBoutLength = mean(AllQLengths)
%BoutNumberPerTrack = length(AllLengths)/length(LethargicTrack)

AllPriorALengths = (cat(2, PriorABoutLength{:}))*SBinWinSec;
%%

figure; imagesc(SubsetMotionstate(LethargicTrack,:));
figure; imagesc(SubsetMotionstate(NonlethargicTrack,:));

figure; plot(MinTimeVectorSec,nanmean(SubsetMotionstate(LethargicTrack,:)))
figure; plot(MinTimeVectorSec,nanmean(SubsetMotionstate(NonlethargicTrack,:)))

PoststimMean=(mean(SubsetMotionstate(LethargicTrack,SubsetMeasurePeriodBin(1,1):SubsetMeasurePeriodBin(1,2)),2));
PrestimMean=(mean(SubsetMotionstate(LethargicTrack,SubsetBaselinePeriodBin(1,1):SubsetBaselinePeriodBin(1,2)),2));
PostPrestimMeanDif=PoststimMean-PrestimMean;
%%
xcentres = -4:(SBinWinSec*2):2000;

QBHist = hist(AllQLengths,xcentres)/length(AllQLengths);
%BoutNumberPerTrackPerMin(1,1) = (length(AllQLengths)/length(LethargicTrack))/(BaselinePeriod(1,2)-BaselinePeriod(1,1))/60;
AverageBoutLength(1,1) = mean(AllQLengths);

pABHist = hist(AllPriorALengths,xcentres)/length(AllPriorALengths);


figure; plot(QBHist,'k'); hold on; plot(pABHist,'r');
xlabel('Bout duration (s)');
ylabel('Fraction of Bouts');


figure; scatter(AllPriorALengths,AllQLengths);
xlabel('Prior Active Bout duration (s)');
ylabel('Quiescent Bout duration (s)');