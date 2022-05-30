%% Measures Quiescence at given location
clear
Stim1 = [1560, 0]; %start and length (sec)

%For finding lethargic vs non-lethargic
ConditionalBinSec = [1260 1500];

%Finds Bou lengths and number during a period of lethargic animals,
%normally a period post-stim.
%MeasurePeriod =[1590 1600+400];
%MeasurePeriod =[1740 1740+600];
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
%load(Files(CurrAlsFile).name);
%[Tracks, files, DatasetPointer] = AccRevDatsV2_AN(DataFileName);
[Tracks, files, DatasetPointer] = AccRevDatsV2_AN_TA(DataFileName);

disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));

%% Call Sleep quantification script
[~, NumTracks] = size(Tracks);
% Call SleepQuantFun
[motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
    SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
    NumTracks,movieFrames);

%REMIMNDER: still have to fix problem with RingDistance here:
%%[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5_old(Tracks,binning,SampleRate); % create matrices that contain speed and eccentricity (rows = Tracks, columns = frames);

%% Find tracks which cover the area specifed in MinTimeFilled and that are lethargic or non-lethargic animals

MinTimeFilledBin=MinTimeFilled/SBinWinSec;
MeasurePeriodBin =MeasurePeriod/SBinWinSec;
SubsetMeasurePeriodBin = MeasurePeriodBin - MinTimeFilledBin(1,1);
SubsetBaselinePeriodBin = (BaselinePeriod/SBinWinSec) - MinTimeFilledBin(1,1);
SubsetBaselinePeriodBin(SubsetBaselinePeriodBin==0)=1;

MinTimeVectorSec = ((MinTimeFilledBin(1,1):MinTimeFilledBin(1,2))*SBinWinSec) - Stim1(1,1);
ConditionalBin = ConditionalBinSec/SBinWinSec;

SubsetMotionstate=[];
SubsetWakestate=[];
LethargicTrack=[];
NonlethargicTrack=[];
QstartsPreStim = cell(1,NumTracks);
QLengthPreStim = cell(1,NumTracks);
Qstarts={};
QLength={};
cnt=0;
for TrackN =1:NumTracks;
    if sum(isnan(motionstate(TrackN,MinTimeFilledBin(1,1):MinTimeFilledBin(1,2)))) == 0;
        cnt=cnt+1;
        SubsetMotionstate(cnt,:) = motionstate(TrackN,MinTimeFilledBin(1,1):MinTimeFilledBin(1,2));
        SubsetWakestate(cnt,:) = wakestate(TrackN,MinTimeFilledBin(1,1):MinTimeFilledBin(1,2));
        if sum((wakestate(TrackN,ConditionalBin(1,1):ConditionalBin(1,2)))) == 0;
            LethargicTrack = [LethargicTrack,cnt];
        elseif mean((wakestate(TrackN,ConditionalBin(1,1):ConditionalBin(1,2)))) == 1;
            NonlethargicTrack = [NonlethargicTrack,cnt];
        end
        % Find bouts of the Prestim period
        L = bwlabel(abs(SubsetMotionstate(cnt,SubsetBaselinePeriodBin(1,1):SubsetBaselinePeriodBin(1,2))-1));
        stats= regionprops(L);
        BoutNum = length(stats);
        cntB=0;
        for BoutN =1:BoutNum;
            %add bout start and length, disclude bouts that start on 1
            %(i.e. start outside of measured area), and doesn't finish
            %within the measured period
            if stats(BoutN, 1).BoundingBox(1,1)>=1.5 && ...
                    (stats(BoutN, end).BoundingBox(1,1) + stats(BoutN, end).BoundingBox(1,3))<(MinTimeFilledBin(1,2)-MinTimeFilledBin(1,1)+1);
                cntB =cntB+1;
                QstartsPreStim{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,1)+0.5;
                QLengthPreStim{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,3);                
            end
        end
        % Find bouts of the Measured period
        L = bwlabel(abs(SubsetMotionstate(cnt,(MeasurePeriodBin(1,1)-MinTimeFilledBin(1,1)):end)-1));
        stats= regionprops(L);
        BoutNum = length(stats);
        cntB=0;
        for BoutN =1:BoutNum;
            %add bout start and length, disclude bouts that start on 1
            %(i.e. start outside of measured area), and doesn't finish
            %within the measured period
            if stats(BoutN, 1).BoundingBox(1,1)>=1.5 && ...
                    (stats(BoutN, end).BoundingBox(1,1) + stats(BoutN, end).BoundingBox(1,3))<(MinTimeFilledBin(1,2)-MinTimeFilledBin(1,1)+1);
                cntB =cntB+1;
                QstartsPostStim{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,1)+0.5;
                QLengthPostStim{cnt}(1,cntB) = stats(BoutN, 1).BoundingBox(1,3);
            end
        end
    end
end
%%
xcentres = -4:(SBinWinSec*2):500;

%AllLengths = cat(2, QLength{LethargicTrack});
%figure; hist(AllLengths,100);
%AverageBoutLength = mean(AllLengths)
%BoutNumberPerTrack = length(AllLengths)/length(LethargicTrack)

figure; imagesc(SubsetMotionstate(LethargicTrack,:));
figure; imagesc(SubsetMotionstate(NonlethargicTrack,:));

figure; plot(MinTimeVectorSec,nanmean(SubsetMotionstate(LethargicTrack,:)))
figure; plot(MinTimeVectorSec,nanmean(SubsetMotionstate(NonlethargicTrack,:)))

PoststimMean=(mean(SubsetMotionstate(LethargicTrack,SubsetMeasurePeriodBin(1,1):SubsetMeasurePeriodBin(1,2)),2));
PrestimMean=(mean(SubsetMotionstate(LethargicTrack,SubsetBaselinePeriodBin(1,1):SubsetBaselinePeriodBin(1,2)),2));
PostPrestimMeanDif=PoststimMean-PrestimMean;
%%

AllLengthsPreStim = cat(2, QLengthPreStim{LethargicTrack});
PreHist = hist(AllLengthsPreStim*SBinWinSec,xcentres)/length(AllLengthsPreStim);
BoutNumberPerTrackPerMin(1,1) = (length(AllLengthsPreStim)/length(LethargicTrack))/(BaselinePeriod(1,2)-BaselinePeriod(1,1))/60;
AverageBoutLength(1,1) = mean(AllLengthsPreStim);

AllLengthsPostStim = cat(2, QLengthPostStim{LethargicTrack});
PostHist = hist(AllLengthsPostStim*SBinWinSec,xcentres)/length(AllLengthsPostStim);
BoutNumberPerTrackPerMin(1,2) = (length(AllLengthsPostStim)/length(LethargicTrack))/(MeasurePeriod(1,2)-MeasurePeriod(1,1))/60
AverageBoutLength(1,2) = mean(AllLengthsPostStim)

figure; plot(PreHist,'k'); hold on; plot(PostHist,'r')
xlabel('Bout duration (s)');
ylabel('Fraction of Bouts');