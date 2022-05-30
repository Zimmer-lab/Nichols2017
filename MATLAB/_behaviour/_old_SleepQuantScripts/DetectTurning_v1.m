%% DetectTurning
% This script is used to simply detect turning based off eccentricity
% peaks, and a decent speed (to prevent curly but still worms from being in
% a long turn).


MinSpeedThreshold = 0.025;
%% Get all track eccentricity and speed
[~,numTracks] = size(Tracks);

allEccen =nan(numTracks,16200);
Speed =nan(numTracks,16200);

for TrckN = 1: length(Tracks)
        allEccen(TrckN,Tracks(TrckN).Frames) = Tracks(TrckN).Eccentricity;
        allSpeed(TrckN,Tracks(TrckN).Frames) = Tracks(TrckN).Speed;
end

%% Get track eccentricity and speed

Eccen =[];
Speed =[];

for TrckN = 33%1: length(Tracks)
    if Tracks(TrckN).Frames(1) == 1
        Eccen(1,:) = Tracks(TrckN).Eccentricity;
        Speed(1,:) = Tracks(TrckN).Speed;
    end
end


%% Show all peaks in the first plot
TurningEccThreshold = 0.08;

%[EccValues,EccPeaks] = findpeaks(abs(Eccen-1), 'MINPEAKHEIGHT', TurningEccThreshold);%,'MINPEAKDISTANCE',6);
EccPeaks = (abs(Eccen-1))>TurningEccThreshold;
EccPeaksIndx = find(EccPeaks);
DifEccen = diff(Eccen);

TurningVector = zeros(length(Eccen),1);
TurningVector(EccPeaks,1) = 1;
figure; imagesc(TurningVector')

cnt=0;
for TrackN =1:NumTracks;
    cnt=cnt+1;
    
    TurnStart = {};
    TurnLength = {};
    % Find bouts of the Prestim period
    L = bwlabel(TurningVector);
    stats= regionprops(L);
    TurnNum = length(stats);
    cntT=0;
    for TurnN =1:TurnNum;
        %add turn start and length, disclude bouts that start on 1
        %(i.e. start outside of measured area), and doesn't finish
        %within the measured period
        if stats(TurnN, 1).BoundingBox(1,2)>=1.5 && ...
                (stats(TurnN, end).BoundingBox(1,2) + stats(TurnN, end).BoundingBox(1,4))<(length(TurningVector));
            cntT =cntT+1;
            TurnStart{cnt}(1,cntT) = stats(TurnN, 1).BoundingBox(1,2)+0.5;
            TurnLength{cnt}(1,cntT) = stats(TurnN, 1).BoundingBox(1,4);
        end
    end
end

figure; plot(abs(Eccen-1)); hold on; scatter(EccPeaksIndx, ones(length(EccPeaksIndx),1));
hold on; plot(DifEccen,'g'); hold on; plot(Speed,'r');
hold on; line([0,length(Eccen)],[TurningEccThreshold,TurningEccThreshold])
hold on; line([0,length(Eccen)],[0.07,0.07],'Color','g')
hold on; line([0,length(Eccen)],[-0.07,-0.07],'Color','g')

%% Looking at eccen

figure; hist(DifEccen,50)
figure; hist(Eccen,100)
figure; hist(Speed,1000)

figure; plot(abs(Eccen-1)); hold on; scatter(EccPeaksIndx, ones(length(EccPeaksIndx),1));
hold on; plot(DifEccen,'g'); hold on; plot(Speed,'r');
hold on; line([0,length(Eccen)],[0.03,0.03],'Color','g')
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


