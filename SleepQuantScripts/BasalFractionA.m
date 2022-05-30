%% This script finds the responses of worms.
% Run on als files of one developmental stage (e.g. Lethargus)

clear all;

%Input:
mainDir = '/Volumes/zimmer/Zimuser_AnTom/test_data'; %pwd; %'Z:\Annika_Nichols\_5_ALS_ToAverage\_2.Lethargus+PostLet\_new\_new';
saveDir = '/Volumes/zimmer/Zimuser_AnTom/test_results_'; %'T:\Annika_Nichols\_Let_Assays\_5_ALS_ToAverage\_5.Figures\_new';%'T:\Annika_Nichols\_Let_Assays\_5_ALS_ToAverage\_4.Statisics\_20160630_AN_collectedtracksTest'; %'Z:\Annika_Nichols\_5_ALS_ToAverage\_4.Statisics\_20160530_J310_12m';


%%
MeausuredPeriodSec1 = [1140,1500]; %secs - FractionActiveBasal
MeausuredPeriodSecStim = [1560,1920]; %sec -FractionActiveStim
MeausuredPeriodSecStim2 = [1740, 1920]; %sec -FractionActiveStim2

%% Input into sleepQuantFun

lengthOfRecording = 90; % [minutes]

%-- framerate at which movie has been recorded
SampleRate = 3;
pixelsize  = 0.0276; %pixelsize in mm

%-- required for plotting wormsize median and mode
sizeBinFrames = 2700;
%-- choose only sizeBinFrames which result in an integer sizeBin
%-- otherise reshape command will later on throw an error
movieFrames = lengthOfRecording*60*SampleRate;


%%
cd(mainDir);
disp(strcat('... Current directory:', 32, pwd));
walkDir = dir(pwd);
for dirIdx = 1 : size(walkDir,1)
    DataFileName = '*_als.mat';
    
    %gets only folders
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(mainDir, '/', walkDir(dirIdx).name)); %NOTE! / mac \ windows
        disp(strcat('... Current directory:', 32, pwd));
        
        SaveQuantDataFilename = strcat(saveDir, '/', walkDir(dirIdx).name); %NOTE! / mac \ windows
        currFolder = walkDir(dirIdx).name;
        disp(strcat('... save files as:', 32, walkDir(dirIdx).name));
        
        %Get als (analysed) files
        DataFileName = '*als.mat';
        Files = dir(DataFileName);
        
        %-- check for folders not containing proper als.mat files
        if size(Files,1) > 0
            
            %% Annika 2016/06/28 improvement to get single tracks out.

            stimNumber  = {'_stim1','_stim2'};
            
            
            %% Sleep state quantifcations which now contains behavioural results extraction.
            
            [NumberOfAlsFiles, ~] = size(Files);
            
            for CurrAlsFile = 1:NumberOfAlsFiles
                
                disp(num2str(CurrAlsFile));
                
                disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
                load(Files(CurrAlsFile).name);
                
                disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));
                
                %% Call Sleep quantification script
                [~, NumTracks] = size(Tracks);
                % Call SleepQuantFun
                [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
                    SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
                    NumTracks,movieFrames);
                
                %% Get FractionActive for both motionstate and wakestate for stim1 for each als file.
                
                state = {'MotionState', 'WakeState'};
                
                % StimShift = 1920;
                % MeausuredPeriodSecStim = MeausuredPeriodSec1 + StimShift %secs
                
                MeausuredPeriodBin1 = MeausuredPeriodSec1/5;
                MeausuredPeriodBinStim = MeausuredPeriodSecStim/5;
                MeausuredPeriodBinStim2 = MeausuredPeriodSecStim2/5;

                
                % MeausuredPeriodBin2 = MeausuredPeriodSec2/5;
                
                for jj =1:2; %for wakestate and motionstate
                    
                    if jj == 1; %calculate motionstate
                    MeasuredResultTracks = nanmean(motionstate(:,MeausuredPeriodBin1(1,1):MeausuredPeriodBin1(1,2))');
                    MeasuredResultTracksStim = nanmean(motionstate(:,MeausuredPeriodBinStim(1,1):MeausuredPeriodBinStim(1,2))');
                    MeasuredResultTracksStim2 = nanmean(motionstate(:,MeausuredPeriodBinStim2(1,1):MeausuredPeriodBinStim2(1,2))');


                    else %second is Wakestate
                    MeasuredResultTracks = nanmean(wakestate(:,MeausuredPeriodBin1(1,1):MeausuredPeriodBin1(1,2))');
                    MeasuredResultTracksStim = nanmean(wakestate(:,MeausuredPeriodBinStim(1,1):MeausuredPeriodBinStim(1,2))');
                    MeasuredResultTracksStim2 = nanmean(wakestate(:,MeausuredPeriodBinStim2(1,1):MeausuredPeriodBinStim2(1,2))');

                    end
                    
                    FractionActiveBasal.(state{1,jj})(CurrAlsFile,1) = nanmean(MeasuredResultTracks);
                    FractionActiveStim.(state{1,jj})(CurrAlsFile,1) = nanmean(MeasuredResultTracksStim);
                    FractionActiveStim2.(state{1,jj})(CurrAlsFile,1) = nanmean(MeasuredResultTracksStim2);

                end
                
                
                
                clear Tracks;
            end;

            save(strcat(SaveQuantDataFilename, '_selectFA.mat'),'FractionActiveBasal','FractionActiveStim','FractionActiveStim2','MeausuredPeriodSec1','MeausuredPeriodSecStim','MeausuredPeriodSecStim2');

            
        else
            disp(strcat('... WARNING: no files found matching search pattern ', 32, DataFileName));
        end;
        
        close all;
        cd(mainDir);
        currFiles = dir(pwd);
end;
end

close all;
    
    
    
