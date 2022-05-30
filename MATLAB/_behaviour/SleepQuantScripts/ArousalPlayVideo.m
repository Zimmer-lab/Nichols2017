%% ArousalPlay2

%% Input into sleepQuantFun

lengthOfRecording = 89.9100;% OLD!: 90; % [minutes]

%-- framerate at which movie has been recorded
SampleRate = 1000/333;%OLD!: 3;
pixelsize  = 0.0276; %pixelsize in mm

%-- required for plotting wormsize median and mode
sizeBinFrames = 2700;
%-- choose only sizeBinFrames which result in an integer sizeBin
%-- otherise reshape command will later on throw an error
movieFrames = floor(lengthOfRecording*60*SampleRate);

%%
DataFileName = '*_als.mat';

disp('... loading data');
%[Tracks, files, DatasetPointer] = AccRevDatsV2_AN(DataFileName);

%% Call Sleep quantification script
[~, NumTracks] = size(Tracks);
% Call SleepQuantFun
[motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
    SBinWinSec,~,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
    NumTracks,movieFrames);

%%
TrackN =12;

figure;
subplot(4,1,1)
plot(Tracks(1,TrackN).Speed)

subplot(4,1,2)
plot(Tracks(1,TrackN).AngSpeed)

subplot(4,1,3)
plot(abs(diff(Tracks(1,TrackN).Eccentricity)))

BinsToPlot = floor((Tracks(1, 10).Frames(1,[1,end]))/binning);
BinsToPlot(BinsToPlot==0)=1;

subplot(4,1,4)
imagesc(~isnan(motionstate(TrackN,BinsToPlot(1,1):BinsToPlot(1,2))))
