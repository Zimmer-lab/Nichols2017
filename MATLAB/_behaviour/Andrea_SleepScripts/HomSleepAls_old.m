%% HomSleepAls
%This script is used to measure motionstate and plot it

minTrackSize = 550;%550; %in frames
%'All' matrices include only tracks of a certain size. aAll include all.

saveFlag = 0; %1 is on, 0 is off

stimulus = [1800, 2340]; %in seconds

multishift =1; %1 is yes, 0 is no.

lengthShift = 30; %in seconds


%%
%version = 'AN20160714';

%% Make info for stimulus
% stimulusLength = stimulus(2)-stimulus(1);
% 
% if multishift ==1
%     numShifts = stimulusLength/lengthShift;
%     for ii = 1:numShifts;
%         stimulusMS(ii) = 
%     end
% end

%% Input into sleepQuantFun

lengthOfRecording = 90; % [minutes]

%-- framerate at which movie has been recorded
SampleRate = 3;
pixelsize  = 0.0276; %pixelsize in mm

movieFrames = lengthOfRecording*60*SampleRate;
%totalMovieFrames = numberOfVideos*movieFrames;

%% Save matrices
AllMotionState = [];
AllWakeState = [];
AllSpeed = [];
AllEccen = [];
Allrmdwlstate = [];
AllPostureState = [];

%% Find and load als files

DataFileName = '*als.mat';
Files = dir(DataFileName);

[NumberOfAlsFiles, ~] = size(Files);

for CurrAlsFile = 1:NumberOfAlsFiles
    
    disp(num2str(CurrAlsFile));
    
    disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
    load(Files(CurrAlsFile).name);
    
    disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));
    
    [~, NumTracks] = size(Tracks);
    
    
    %% Call SleepQuantFun
    [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
        SBinWinSec,currWormSize,St,SBinTrcksSpd,DBinSmoothedEccentricityDSt,rmdwlstate,PostureState] = ...
        SleepQuantFunNoRing(SampleRate,pixelsize,Tracks,NumTracks,movieFrames);
    
    %% For averaging across multiple als files within a folder.
    
    for ii = 1:NumTracks; %all tracks
        
        % only take tracks above a certain length
        if Tracks(1, ii).NumFrames > minTrackSize;
            AllMotionState = cat(1,AllMotionState,motionstate(ii,1:1080)); 
            %NOTE! Some of Andrea's movies are couple of frames shorter
            %leading to 1080 or 1081 bins. This corrects for that.
            
%             AllWakeState = cat(1,AllWakeState,wakestate(ii,:));
            AllSpeed = cat(1,AllSpeed,SBinTrcksSpd(ii,1:1080));
%             AllEccen = cat(1,AllEccen,DBinSmoothedEccentricityDSt(ii,:));
%             Allrmdwlstate = cat(1,Allrmdwlstate,rmdwlstate(ii,:));
%             AllPostureState = cat(1,AllPostureState,PostureState(ii,:));
        end
    end
    
end

%% Saving
mainDir = pwd;

if saveFlag == 1;
    save (([strcat(mainDir,'/MotionState') '.mat']), 'AllMotionState','AllSpeed','minTrackSize');
end

clearvars CurrAlsFile DataFileName Files St currWormSize pixelsize AllWakeState...
            Allrmdwlstate AllPostureState AllEccen


%% Plotting
% Showing NaNs
NaNShowAllMotionState = double(AllMotionState);
NaNShowAllMotionState(isnan(AllMotionState))=0.5;

%Time vector
TimeV = 1:(lengthOfRecording*60/NumBins):(lengthOfRecording*60);
TimeV(end) = [];


%heatmap
figure; imagesc(NaNShowAllMotionState)


figure; 
plot(TimeV,nanmean(AllMotionState),'linewidth',2);
xlabel('Time (s)');

hold on;
xpoints = stimulus(1):stimulus(2);
jbfill(xpoints,ones(length(xpoints)),zeros(length(xpoints)),[0.8,0.8,0.8],'k',0,0.05);


%to plot as fraction Q
%figure; plot(TimeV,nanmean(abs(AllMotionState-1)));


