%% HomSleepAls_title_SMS
%This script is used to measure motionstate and plot it. This on uses
%Susanne's modified TrackQuietWormsSS_V12cNoSParam script to define
%quiescence (SMS= Susanne motionstate).

%NOTE!: bin size is 1 second for this type of sleep quantification

minTrackSize = 550;%550; %in frames
%'All' matrices include only tracks of a certain size. aAll include all.

saveFlag = 1; %1 is on, 0 is off

stimulus = [1800, 2340]; %in seconds

multishift =1; %1 is yes, 0 is no.

lengthShift = 30; %in seconds

savePlotFlag = 1;


%% get folder name
currFolder = pwd;
[upperPath, deepestFolder, ~] = fileparts(currFolder) 

%%
%version = 'AN20160812';
%fixing repeats

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
tAllFinalWakeState = [];
aAllMotionState = [];
atAllFinalWakeState = [];
aAllSpeed = [];

%% Find and load als files

DataFileName = '*als.mat';
Files = dir(DataFileName);

[NumberOfAlsFiles, ~] = size(Files);
Experiments = cell(NumberOfAlsFiles,1);
tracksPerFile = [];



for CurrAlsFile = 1:NumberOfAlsFiles
    
    disp(num2str(CurrAlsFile));
    
    disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
    load(Files(CurrAlsFile).name);
    
    disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));
    
    [~, NumTracks] = size(Tracks);
    
    Experiments{CurrAlsFile,1} = Files(CurrAlsFile).name;
    
 
    %% Run TrackQuietWormsSS_V12cNoSParam_AN
    
    TrackQuietWormsSS_V12cNoSParam_AN
    
%     [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
%         SBinWinSec,currWormSize,St,SBinTrcksSpd,DBinSmoothedEccentricityDSt,rmdwlstate,PostureState] = ...
%         
    
    %% For averaging across multiple als files within a folder.
    prevAllMotionStateSize = size(AllMotionState,1);
    
    for ii = 1:NumTracks; %all tracks
        aAllMotionState = cat(1,aAllMotionState,motionstate(ii,1:5400));
        atAllFinalWakeState = cat(1,atAllFinalWakeState,wakestateFinal(ii,1:5400));
        aAllSpeed = cat(1,aAllSpeed,SBinTrcksSpd(ii,1:5400));
        
        % only take tracks above a certain length
        if Tracks(1, ii).NumFrames > minTrackSize;
            AllMotionState = cat(1,AllMotionState,motionstate(ii,1:5400)); %5400
            %NOTE! Some of Andrea's movies are couple of frames shorter
            %leading to 1080 or 1081 bins. This corrects for that.
            
            tAllFinalWakeState = cat(1,tAllFinalWakeState,wakestateFinal(ii,1:5400));
%             AllWakeState = cat(1,AllWakeState,wakestate(ii,:));
            AllSpeed = cat(1,AllSpeed,SBinTrcksSpd(ii,1:5400)); %5400
%             AllEccen = cat(1,AllEccen,DBinSmoothedEccentricityDSt(ii,:));
%             Allrmdwlstate = cat(1,Allrmdwlstate,rmdwlstate(ii,:));
%             AllPostureState = cat(1,AllPostureState,PostureState(ii,:));
        end
    end
    postAllMotionStateSize = size(AllMotionState,1);
    tracksPerFile(CurrAlsFile,1) = postAllMotionStateSize - prevAllMotionStateSize;
end

%Invert AllFinalWakeState
AllFinalWakeState = abs(tAllFinalWakeState - 1);
aAllFinalWakeState = abs(atAllFinalWakeState - 1);


%% Saving
mainDir = pwd;

if saveFlag == 1;
    save (([strcat(mainDir,'/Smotionstate') '.mat']), 'AllMotionState','AllFinalWakeState',...
        'AllSpeed','minTrackSize','aAllMotionState', 'aAllFinalWakeState', 'aAllSpeed');
end

clearvars CurrAlsFile DataFileName Files St currWormSize pixelsize AllWakeState...
            Allrmdwlstate AllPostureState AllEccen


%% Plotting
NumBins = 5400;

% Showing NaNs
NaNShowAllMotionState = double(AllMotionState);
NaNShowAllMotionState(isnan(AllMotionState))=0.5;

%Time vector
TimeV = 1:(lengthOfRecording*60/NumBins):(lengthOfRecording*60);
%TimeV(end) = [];


%heatmap
%figure; imagesc(NaNShowAllMotionState)

cc = [0 1.1];
figure; 
plot(TimeV,nanmean(AllMotionState),'linewidth',2);
xlabel('Time (s)');
ylim(cc)

hold on;

x = [1800 1800 2340 2340];
y = [0 1.002 1.002 0];
b = patch(x,y,'k','facecolor','b','edgecolor','b');
alpha(b,0.15);
set(b, 'edgecolor','none');
uistack(b,'bottom');

title([strcat(deepestFolder),' number files: ' num2str( NumberOfAlsFiles ) ' number tracks: ' num2str(NumTracks)]);
 
%to plot as fraction Q
%figure; plot(TimeV,nanmean(abs(AllMotionState-1)));

if savePlotFlag == 0;
    print(gcf,'-dpdf',sprintf('%s_fractionActive.pdf',deepestFolder));
end

