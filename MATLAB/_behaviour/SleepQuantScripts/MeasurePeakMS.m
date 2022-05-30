clear

%% Input into sleepQuantFun
numberOfVideos = 14;

lengthOfRecording = 90; % [minutes]

%-- tickmarks for subplots
tickmarks  = 0:lengthOfRecording:numberOfVideos*lengthOfRecording;

%-- framerate at which movie has been recorded
SampleRate = 3;
pixelsize  = 0.0276; %pixelsize in mm

%-- required for plotting wormsize median and mode
sizeBinFrames = 2700;
%-- choose only sizeBinFrames which result in an integer sizeBin
%-- otherise reshape command will later on throw an error
movieFrames = lengthOfRecording*60*SampleRate;
totalMovieFrames = numberOfVideos*movieFrames;

sizeBins = movieFrames/sizeBinFrames;
totalSizeBins = totalMovieFrames/sizeBinFrames;

%%
FractionInMotionState = [];

DataFileName = '*_als.mat';
Files = dir(DataFileName);

[NumberOfAlsFiles, ~] = size(Files);
for CurrAlsFile = 1:NumberOfAlsFiles
    disp(num2str(CurrAlsFile));
    
    disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
    load(Files(CurrAlsFile).name);
    
    disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));
    
    [~, NumTracks] = size(Tracks);
    
    % Call SleepQuantFun
    [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
        SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
        NumTracks,movieFrames);
    
    
    FractionInMotionState(CurrAlsFile,:) = nanmean(motionstate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
    
    FractionAwake(CurrAlsFile,:) = nanmean(wakestate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
    
    FileNameCell{CurrAlsFile} = Files(CurrAlsFile).name;
    
    
end;

FractionInMotionStateTotal = reshape(FractionInMotionState',1,numel(FractionInMotionState));


PCval = 5;

ValsBelowPC = FractionInMotionStateTotal(FractionInMotionStateTotal<(prctile(FractionInMotionStateTotal,PCval)));

MeanXpc = mean(ValsBelowPC)

% Manually chosen
T1 = 6000;
TimePeriod = T1:(T1+120);

MeanMCpeak = mean(FractionInMotionStateTotal(TimePeriod));
