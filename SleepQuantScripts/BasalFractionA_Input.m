%% This script finds the responses of worms.
%Based off BasalFractionA
% Run on als files of one developmental stage (e.g. Lethargus)

clear all;

controlDir = pwd;%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_2.Lethargus+PostLet/_new/_figure1/HW_O2_21.0_s_2.Lethargus_';
saveDir = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/_basal_measurement';

%Get data names:
excelInputFolder = '/Users/nichols/Dropbox/_Manuscript';

cd(excelInputFolder);

%Specify excel sheet data cells.
dataNameInput = xlsread('Data_and_NPR1_ID_Controls.xlsx','Neurotransmitters','U48:U70');

%used for naming
basalMeasureFor = 'figS2_NT_npr1_18C_O2_21_s_Postlet_';

%%
MeausuredPeriodSec1 = [1140,1500]; %secs - FractionActiveBasal
MeausuredPeriodSecStim = [1560,1920]; %sec -FractionActiveStim
MeausuredPeriodSecStim2 = [1740, 1920]; %sec -FractionActiveStim2

%% Used for manuscript
% MeausuredPeriodSec1 = [1140,1500]; %secs - FractionActiveBasal
% MeausuredPeriodSecStim = [1560,1920]; %sec -FractionActiveStim
% MeausuredPeriodSecStim2 = [1740, 1920]; %sec -FractionActiveStim2

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

%% Addition for the control datasets
% Find datasets to run analysis on.

cd(controlDir);
walkDir = dir(pwd);

IncludedRecording = {};
FolderIncludedRecording = {};
DataFileName = '*als.mat';

%get files in top folder
FilesInFolder = dir(DataFileName);
for iii = 1:length(FilesInFolder);
    for jj = 1:length(dataNameInput)
        inputString = dataNameInput(jj);
        %note should take either column or row depending on which
        %way the information is organised.
        
        testPresence = strfind(FilesInFolder(iii, 1).name,mat2str(inputString));
        if ~isempty(testPresence)
            IncludedRecording = [IncludedRecording; FilesInFolder(iii, 1).name];
            FolderIncludedRecording = [FolderIncludedRecording; pwd];
            disp(['found recording:',FilesInFolder(iii, 1).name]);
        end
    end
end

for dirIdx = 1:length(walkDir);
    %gets only folders
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(controlDir, '/', walkDir(dirIdx).name)); %NOTE! / mac \ windows
        
        %Get als (analysed) files
        FilesInFolder = dir(DataFileName);
        
        for iii = 1:length(FilesInFolder);
            for jj = 1:length(dataNameInput)
                inputString = dataNameInput(jj);
                %note should take either column or row depending on which
                %way the information is organised.
                
                testPresence = strfind(FilesInFolder(iii, 1).name,mat2str(inputString));
                if ~isempty(testPresence)
                    IncludedRecording = [IncludedRecording; FilesInFolder(iii, 1).name];
                    FolderIncludedRecording = [FolderIncludedRecording; pwd];
                    disp(['found recording:',FilesInFolder(iii, 1).name]);
                end
            end
        end
    end
end

%% Find folder duplicates and disclude

if isempty(IncludedRecording)
    disp('did not find any matches')
    return
end

[~, ~, idx2] = unique(IncludedRecording(:,1));
unique_idx = accumarray(idx2(:),(1:length(idx2))',[],@(x) {(x)});

%find indices of duplicates
discludeRecordingsCA = {};
for numIncludedRecordings = 1:length(unique_idx)
    if length(unique_idx{numIncludedRecordings, 1})>1
        discludeRecordingsCA = [discludeRecordingsCA,unique_idx{numIncludedRecordings, 1}];
    end
end

%Take away first instance of a recording from the removal list:
for ii = 1:length(discludeRecordingsCA)
    discludeRecordingsCA{1, ii}(1,1) = NaN;
end

%Reshape so the index can be used to disclude the recordings.
discludeRecordings = vertcat(discludeRecordingsCA{1,:});

discludeRecordings(isnan(discludeRecordings)) = [];

%Disclude duplicate recordings
IncludedRecording(discludeRecordings) = [];
FolderIncludedRecording(discludeRecordings) = [];


%%
SaveQuantDataFilename = strcat(saveDir, '/BasalQ_',basalMeasureFor); %NOTE! / mac \ windows
disp(strcat('... save files as:', 32, ['BasalQ_',basalMeasureFor]));
FieldsToRemove = {'Path','LastCoordinates','LastSize','FilledArea','Round','RingEffect',...
    'Time','SmoothX','SmoothY','Direction','AngSpeed','SmoothEccentricity',...
    'SmoothRound'};

if size(IncludedRecording,1) > 0
    % Get all tracks specified
    [NumberOfAlsFiles, ~] = size(IncludedRecording);
    
    %AN: based off AccRevDatsV2_AN
    %flnms=dir('*_als.mat'); %create structure from filenames
    
    for CurrAlsFile = 1:NumberOfAlsFiles
        
        disp(num2str(CurrAlsFile));
        
        disp(strcat('now loading: ',32, IncludedRecording{CurrAlsFile}));
        cd(FolderIncludedRecording{CurrAlsFile});
        file = load(IncludedRecording{CurrAlsFile});
        
        disp(strcat('now analyzing: ',32, IncludedRecording{CurrAlsFile}));
        
        file.Tracks = rmfield(file.Tracks,FieldsToRemove);
        
        %to make compatable with old tracks which don't have
        %wormimage
        if isfield(file.Tracks,'WormImages');
            FieldsToRemoveNew = {'WormImages','MeanIntensity','Direction360','ApproxWormLength',...
                'polishedReversals','OmegaTransDeep','OmegaTransShallow',...
                'ReverseOmega','ReverseShallowTurn'};
            file.Tracks = rmfield(file.Tracks,FieldsToRemoveNew);
        end
        
        [~,NumTracks] = size(file.Tracks);
        %% Sleep state quantifications which now contains behavioural results extraction.
        % Call Sleep quantification script
        [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
            SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,file.Tracks,...
            NumTracks,movieFrames);
        
        %% Get FractionActive for both motionstate and wakestate for stim1 for each als file.
        
        state = {'MotionState', 'WakeState'};
        
        MeausuredPeriodBin1 = MeausuredPeriodSec1/5;
        MeausuredPeriodBinStim = MeausuredPeriodSecStim/5;
        MeausuredPeriodBinStim2 = MeausuredPeriodSecStim2/5;
        
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
        clearvars file wakestate motionstate MeasuredResultTracks MeasuredResultTracksStim MeasuredResultTracksStim2;
        
    end
    
else
    disp('No files found with the specified input')
end;

save(strcat(SaveQuantDataFilename, '_selectFA.mat'),'FractionActiveBasal','FractionActiveStim','FractionActiveStim2','MeausuredPeriodSec1','MeausuredPeriodSecStim','MeausuredPeriodSecStim2');

%Check input number to output number:
if length(IncludedRecording) ~= sum(~isnan(dataNameInput))
    disp('NOTE! the filename input number does not equal the output number!')
end
close all;