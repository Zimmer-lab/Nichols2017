%include also eccentricity parameter
% clear all; close all; clc;
% Modified with Marek Suplata 2013-01-08

%mainDir = 'T:/EichlerTomas_isilon/_ALS_STIMULATED/_All_others';
%saveDir = 'T:/EichlerTomas_isilon/_ALS_averaging/Results_Sizes_2';

%Note may need to change slash direction if changing from mac vs PC

mainDir = pwd; %'/Users/nichols/Desktop/_Dish/Single_Let';
saveDir = pwd; %'/Users/nichols/Desktop/_Dish/Single_Let';

cd(mainDir);
disp(strcat('... Current directory:', 32, pwd));
walkDir = dir(pwd);

aAllMotionState = [];
aAllWakeState = [];
aAllSpeed = [];
aAllEccen = [];
aAllrmdwlstate = [];
aAllPostureState = [];
aAllPreCOrmdwlstate = [];
AllPreCOrmdwlstate = [];
aAllPreCOPostureState =[];
AllPreCOPostureState =[];

AllMotionState = [];
AllWakeState = [];
AllSpeed = [];
AllEccen = [];
AllSpeedState = [];
AllPostureStateLog = [];
Allrmdwlstate = [];
AllPostureState = [];


for dirIdx = 1 : size(walkDir,1)
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(mainDir, '/', walkDir(dirIdx).name));
        disp(strcat('... Current directory:', 32, pwd));
        
        SaveQuantDataFilename = strcat(saveDir, '/', walkDir(dirIdx).name);
        currFolder = walkDir(dirIdx).name;
        disp(strcat('... save files as:', 32, walkDir(dirIdx).name));
        
        clearvars -except tRange direct condition nnn CurrCond AllSpeed AllEccen...
            AllSpeedState AllPostureStateLog Allrmdwlstate AllPostureState...
            aAllMotionState aAllWakeState mainDir saveDir walkDir dirIdx...
            SaveQuantDataFilename currFolder AllWakeState AllMotionState...
            aAllSpeed aAllEccen aAllrmdwlstate aAllPostureState DataT...
            aAllPreCOrmdwlstate AllPreCOrmdwlstate aAllPreCOPostureState AllPreCOPostureState...
            topdir;
        %close all;
        
        DataFileName = '*_als.mat';
        Files = dir(DataFileName);
        %-- check for folders not containing proper als.mat files
        if size(Files,1) > 0
            
            numberOfVideos = 1;
            %numberOfVideos = size(Files,1);
            
            lengthOfRecording = 20; % [minutes]
            stimuli = 10;
            
            %-- tickmarks for subplots
            tickmarks  = 0:lengthOfRecording:numberOfVideos*lengthOfRecording;
            %-- framerate at which movie has been recorded
            SampleRate = 3;
            pixelsize  = 0.0276; %pixelsize in mm
            
            movieFrames = lengthOfRecording*60*SampleRate;
            totalMovieFrames = numberOfVideos*movieFrames;
            
            [NumberOfAlsFiles, ~] = size(Files);
            
            for CurrAlsFile = 1:NumberOfAlsFiles
                
                disp(num2str(CurrAlsFile));
                
                disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
                load(Files(CurrAlsFile).name);
                
                disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));
                
                [~, NumTracks] = size(Tracks);
                
                [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins...
                    ,SBinTrcksSpdSize,SBinWinSec,currWormSize,St,SBinTrcksSpd,DBinSmoothedEccentricityDSt...
                    ,rmdwlstate,PostureState,Speed,Posture,PreCOrmdwlstate,PreCOPostureState]=SleepQuantFunNoRingDish(SampleRate,pixelsize,Tracks,NumTracks,movieFrames);
                
                
                %% For averaging
                
                for ii = 1:NumTracks;
                    aAllMotionState = cat(1,aAllMotionState,motionstate(ii,:));
                    aAllWakeState = cat(1,aAllWakeState,wakestate(ii,:));
                    aAllSpeed = cat(1,aAllSpeed,SBinTrcksSpdSize(ii,:));
                    aAllEccen = cat(1,aAllEccen,DBinSmoothedEccentricityDSt(ii,:));
                    aAllrmdwlstate = cat(1,aAllrmdwlstate,rmdwlstate(ii,:));
                    aAllPostureState = cat(1,aAllPostureState,PostureState(ii,:));
                    aAllPreCOrmdwlstate = cat(1,aAllPreCOrmdwlstate,PreCOrmdwlstate(ii,:));
                    aAllPreCOPostureState = cat(1,aAllPreCOPostureState,PreCOPostureState(ii,:));
                    
                    % only take full length tracks
                    if Tracks(1, ii).NumFrames == 3600;
                        AllMotionState = cat(1,AllMotionState,motionstate(ii,:));
                        AllWakeState = cat(1,AllWakeState,wakestate(ii,:));
                        AllSpeed = cat(1,AllSpeed,SBinTrcksSpdSize(ii,:));
                        AllEccen = cat(1,AllEccen,DBinSmoothedEccentricityDSt(ii,:));
                        AllSpeedState = cat(1,AllSpeedState,Speed(ii,:));
                        AllPostureStateLog = cat(1,AllPostureStateLog, Posture(ii,:));
                        Allrmdwlstate = cat(1,Allrmdwlstate,rmdwlstate(ii,:));
                        AllPostureState = cat(1,AllPostureState, PostureState(ii,:));
                        AllPreCOrmdwlstate = cat(1,AllPreCOrmdwlstate,PreCOrmdwlstate(ii,:));
                        AllPreCOPostureState = cat(1,AllPreCOPostureState,PreCOPostureState(ii,:));

                    end
                end

            end;
            cd(mainDir);
            currFiles = dir(pwd);
        end;
        
    end
end
close all;

%%
figure;imagesc(AllWakeState)
title('WakeState')

figure;imagesc(AllMotionState)
title('MotionState')

figure;imagesc(Allrmdwlstate)
title('Allrmdwlstate')

figure;imagesc(AllPostureState)
title('AllPostureState')

figure;imagesc(AllSpeedState)
title('AllSpeedState')

figure;imagesc(AllPostureStateLog)
title('AllPostureStateLog')


%clims = [0 0.02];
figure;imagesc(AllSpeed)
title('Speed')


%figure;plot(mean(AllWakeState))

save (([strcat(mainDir,'/DishWakeState_new') '.mat']), 'aAllMotionState',...
    'AllMotionState','aAllEccen','aAllSpeed','AllSpeed','AllWakeState',...
    'AllEccen','AllSpeedState','AllPostureState', 'aAllPreCOrmdwlstate',...
    'aAllPreCOPostureState');
