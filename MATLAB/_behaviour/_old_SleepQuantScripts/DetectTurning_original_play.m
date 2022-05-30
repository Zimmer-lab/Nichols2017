%% DetectTurning
% This script is used to simply detect turning based off eccentricity
% peaks, and a decent speed (to prevent curly but still worms from being in
% a long turn).

Stim = [1560,360]; %Time of start, length (sec)
DataRange = [1 5399];   %define in sec the range that spans the first block you wish to be plotted
                           % first element has to be >= BinWinSec!; second element is the width
                           
MinSpeedThreshold = 0.025;

BinSizeFrames = 15;
fps = 3;
StimStartBin = round(((Stim(1,1)*fps)/BinSizeFrames));
StimLengthBin = round(((Stim(1,2)*fps)/BinSizeFrames));

StimEndBin = round(StimStartBin+((Stim(1,2)*fps)/BinSizeFrames));

grey=[0.5 0.5 0.5]; %color of boxes that indicate stimuli


%% Get all track eccentricity and speed
[~,numTracks] = size(Tracks);

allEccen =nan(numTracks,16200);
Speed =nan(numTracks,16200);
allStartingFrames =nan(numTracks,1);

for TrckN = 1: length(Tracks)
        allEccen(TrckN,Tracks(TrckN).Frames) = Tracks(TrckN).Eccentricity;
        allSpeed(TrckN,Tracks(TrckN).Frames) = Tracks(TrckN).Speed;
        allStartingFrames(TrckN,1) = Tracks(TrckN).Frames(1,1);        
end

%% Get track eccentricity and speed

Eccen =[];
Speed =[];

for TrckN = 14%1: length(Tracks)
    if Tracks(TrckN).Frames(1) == 1
        Eccen(1,:) = Tracks(TrckN).Eccentricity;
        Speed(1,:) = Tracks(TrckN).Speed;
    end
end


%% Show all peaks in the first plot
TurningEccThreshold = 0.08;

TurnStart = {};
TurnLength = {};
for TrackN =1:numTracks;

    %Find time points where turning threshold is satisfied
    EccPeaks = (abs(allEccen(TrackN,:)-1))>TurningEccThreshold;
    EccPeaksIndx = find(EccPeaks);
    %DifEccen = diff(Eccen);
    
    TurningVector = zeros(sum(~isnan(allEccen(TrackN,:))),1);
    TurningVector(EccPeaks,1) = 1;
    %figure; imagesc(TurningVector')
    
    % Find turning bouts
    L = bwlabel(TurningVector);
    stats= regionprops(L);
    TurnNum = length(stats);

    for TurnN =1:TurnNum;
        %add turn start and length
        TurnStart{TrackN}(1,TurnN) = stats(TurnN, 1).BoundingBox(1,2)+0.5;
        TurnLength{TrackN}(1,TurnN) = stats(TurnN, 1).BoundingBox(1,4);
    end
end

AllTurnStarts = nan(numTracks,16200);
AllTurnStartsBinned = nan(numTracks,16200/BinSizeFrames);

TrackPresent = nan(numTracks,16200);
TrackPresentBinned = nan(numTracks,16200/BinSizeFrames);
for TrackN =1:numTracks;
    %unbinned
    AllTurnStarts(TrackN,TurnStart{TrackN}) = 1;
    
    %Binned
    AllTurnStartsBinned(TrackN,:) = nanmean(reshape(AllTurnStarts(TrackN,:),[BinSizeFrames,(16200/BinSizeFrames)]));

    allEccenBinned(TrackN,:) = nanmean(reshape(allEccen(TrackN,:),[BinSizeFrames,(16200/BinSizeFrames)]));
    %Track present?
    TrackPresent = ~isnan(allEccen);
    
    TrackPresentBinned = ~isnan(allEccenBinned);
end
%%
%Bin data
% B = reshape(nansum(AllTurnStarts),[BinSizeFrames,(length(sum(AllTurnStarts))/BinSizeFrames)]);
% BinnedAllTurnStarts = nansum(B);
spdxmin = -200;
spdxmax = 1000;
spdymin = 0;
spdymax = 0.4;
stimuli = [0,Stim(2)];
BinWinSec = BinSizeFrames/fps;
StResh = (DataRange(1):BinWinSec:DataRange(1)+DataRange(2))-Stim(1);

% TurnBinSe = (ones(numTracks,16200/BinSizeFrames))-2;
% TurnBinSe(TrackPresentBinned)=0;
% TurnBinSe((AllTurnStartsBinned==1))=1;
% figure; imagesc(TurnBinSe)

TurnBinSe = nan(numTracks,16200/BinSizeFrames);
TurnBinSe(TrackPresentBinned)=0;
TurnBinSe((AllTurnStartsBinned==1))=1;
%figure; imagesc(TurnBinSe)

mnTurning = ((nansum(AllTurnStartsBinned))./sum(TrackPresentBinned));
%strTurning = nansterr(((AllTurnStartsBinned))./sum(TrackPresentBinned));

SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));
%hold on;
%jbfill(StResh,mnTurning+strTurning,mnTurning-strTurning,grey,grey,0,1);
hold on;
plot(StResh,(nansum(AllTurnStartsBinned))./sum(TrackPresentBinned));

%%
figure; plot(BinnedAllTurnStarts)
hold on; line([StimStartBin,StimStartBin],[0,70],'Color','r')
hold on; line([StimEndBin,StimEndBin],[0,70],'Color','r')
%need to normalise by trackN at the timepoint 

%%
figure; plot(abs(Eccen-1)); hold on; scatter(EccPeaksIndx, ones(length(EccPeaksIndx),1));
hold on; plot(DifEccen,'g'); hold on; plot(Speed,'r');
hold on; line([0,length(Eccen)],[TurningEccThreshold,TurningEccThreshold])
hold on; line([0,length(Eccen)],[0.07,0.07],'Color','g')
hold on; line([0,length(Eccen)],[-0.07,-0.07],'Color','g')

%% Looking at eccen

%figure; hist(DifEccen,50)
% figure; hist(Eccen,100)
% figure; hist(Speed,1000)

figure; plot(abs(Eccen-1)); hold on; scatter(EccPeaksIndx, ones(length(EccPeaksIndx),1));
%hold on; plot(DifEccen,'g'); hold on; plot(Speed,'r');
hold on; line([0,length(Eccen)],[0.08,0.08],'Color','g')
hold on; line([0,length(Eccen)],[-0.03,-0.03],'Color','g')

OverMovingSpeed = Speed > MinSpeedThreshold;
OverMovingSpeedIndx = find(OverMovingSpeed);

SpeedVector = zeros(length(Eccen),1);
SpeedVector(OverMovingSpeedIndx,1) = 1;
figure; imagesc(SpeedVector');


%% diffEccen based turn finding
TurningDifEccThreshold = 0.15;

difEccPeakStart = DifEccen>TurningDifEccThreshold;
difEccPeakEnd = DifEccen< -TurningDifEccThreshold;
difEccPeakStartIndx = find(difEccPeakStart);
difEccPeakEndIndx = find(difEccPeakEnd);

difTurningVector = zeros(length(Eccen),1);
difTurningVector(difEccPeakStart,1) = 1;
difTurningVector(difEccPeakEndIndx,1) = 2;

figure; imagesc(difTurningVector');

%%

AllSleepTrcksQuiescent = CollectedTrksInfo.SleepTrcksQuiescent{:, 1};
