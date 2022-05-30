%% This script averages the responses of worms.
% Run on als files of one developmental stage (e.g. Lethargus)
% Plots out average trace of controls who's dates are specified in an excel
% file. i.e. 20140205 would be in a cell then this script will find any
% npr-1 recording from that date.

clear all;

%-- requires subfolder in main directory
controlDir = 'T:\Annika_Nichols\_Let_Assays\_5_ALS_ToAverage\_2.Lethargus+PostLet\_new\_controlDatasets';
saveDir = 'T:\Annika_Nichols\_Let_Assays\_5_ALS_ToAverage\_5.Figures\Rescues';

%Get data names:
excelInputFolder = 'V:\Annika';

cd(excelInputFolder);

%Specify excel sheet data cells.
dataNameInput = xlsread('Data_and_NPR1_ID_Controls.xlsx','npr-1 rescues','I90:I128');

%used for naming
controlfor = 'figure2bRescues_18C_O2_21_s_2.Let_';

%% NOTES:
% Based off: SleepAlsV7_plotIndivCurves_20150213

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

for dirIdx = 1:length(walkDir);
    %gets only folders
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(controlDir, '\', walkDir(dirIdx).name)); %NOTE! / mac \ windows
        
        %Get als (analysed) files
        DataFileName = '*als.mat';
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
                end
            end
        end
    end
end

%% Find folder duplicates and disclude

[~, ~, idx2] = unique(IncludedRecording(:,1));
unique_idx = accumarray(idx2(:),(1:length(idx2))',[],@(x) {(x)});

%find indices of duplicates
discludeRecordingsCA = {};
for numIncludedRecordings = 1:length(unique_idx)
    if length(unique_idx{numIncludedRecordings, 1})>1
        discludeRecordingsCA = [discludeRecordingsCA,unique_idx{numIncludedRecordings, 1}];
    end
end

%Reshape so the index can be used to disclude the recordings.
discludeRecordings = vertcat(discludeRecordingsCA{1,:});

%Disclude duplicate recordings
IncludedRecording(discludeRecordings) = [];
FolderIncludedRecording(discludeRecordings) = [];

%%
SaveQuantDataFilename = strcat(saveDir, '\controlNPR1_',controlfor); %NOTE! / mac \ windows
disp(strcat('... save files as:', 32, ['controlNPR1_',controlfor]));
FieldsToRemove = {'Path','LastCoordinates','LastSize','FilledArea','Round','RingEffect',...
    'Time','SmoothX','SmoothY','Direction','AngSpeed','SmoothEccentricity',...
    'SmoothRound'};
%%
if size(IncludedRecording,1) > 0
    % Get all tracks specified
    [NumberOfAlsFiles, ~] = size(IncludedRecording);
    
    %AN: based off AccRevDatsV2_AN
    %flnms=dir('*_als.mat'); %create structure from filenames
    
    TrcksAcc =[]; %structure that accumulates all tracks data
    
    DatasetPointer(1,1) = 1;
    DatasetPointer(1,2) = 0;
    SelectData = [];
    
    
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
        
        if CurrAlsFile>1
            DatasetPointer(CurrAlsFile,1) = DatasetPointer(CurrAlsFile-1,2)+1;
            DatasetPointer(CurrAlsFile,2) =  DatasetPointer(CurrAlsFile-1,2) + NumTracks;
            
        else
            DatasetPointer(CurrAlsFile,2) = NumTracks;
        end
        
        TrcksAcc = [TrcksAcc file.Tracks];
        
        %Find select data
        currName = IncludedRecording{CurrAlsFile};
        if findstr('1st',currName)
            %disp(strcat(currFiles(i).name,32,'1st'));
            SelectData = [SelectData; 1, 0];
        elseif findstr('2nd',currName)
            %disp(strcat(currFiles(i).name,32,'2nd'));
            SelectData = [SelectData; 0, 1];
        else
            %disp(strcat(currFiles(i).name,32,'otherwise'));
            SelectData = [SelectData; 1, 1];
        end;
    end
    
    %Make Tracks all the tracks
    clearvars Tracks
    Tracks = TrcksAcc;
    clearvars TrcksAcc
    
    %% Call Sleep quantification script
    [~, NumTracks] = size(Tracks);
    % Call SleepQuantFun
    [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
        SBinWinSec,~,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
        NumTracks,movieFrames);
    
    %%
    disp('... running ROalsV3');
    [BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, BinTrcksLRstate, BinTrcksSRstate, BinTrcksOstate, t] = ROalsV3(Tracks,binning);
    
    stimuli = [1560,360,1560+1920,360]; %stim 1 start, stim 1 width, stim 2 start, stim 2 width ....
    spdxmax = 5400;
    
    %Plot Fraction Wakestate Active
    FractionAwake = nanmean(wakestate(:, SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2));
    FractAwakeFig = DataFig(0,spdxmax,0,1,stimuli);
    
    plot(St(SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2), FractionAwake, 'k', 'linewidth',1.5);
    title (sprintf('%s-FractionActive_WS'),'Interpreter','none','FontSize',12);
    ylabel('Fraction active');
    xlabel('time [s]');
    
    %%saveas(gcf, sprintf('%s_FractionActive_WS.fig',OutputFileName), 'fig')
    
    %Plot Fraction MotionState Active
    FractionMotionStateAwake = nanmean(motionstate(:, SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2));
    FractMotionStateAwakeFig = DataFig(0,spdxmax,0,1,stimuli);
    
    plot(St(SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2), FractionMotionStateAwake, 'k', 'linewidth',1.5);
    title (sprintf('%s-FractionActive_MS'),'Interpreter','none','FontSize',12);
    ylabel('Fraction active');
    xlabel('time [s]');
    
    % print(gcf,'-dpdf',sprintf('%s_fractionActive.pdf',DataFileName));
    %%saveas(gcf, sprintf('%s_FractionActive_MS.fig',OutputFileName), 'fig')
    
    PlotAvgSelect_MassiveP_speed_plotIndivCurves_20160628_AN_Input(SaveQuantDataFilename,...
        controlDir, 'sleep', BinWinSec, DatasetPointer, SBinTrcksSpdSize, BinTrcksO, BinTrcksLR,...
        BinTrcksSR, wakestate, motionstate, BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate,...
        SBinWinSec,SelectData);
    % PlotAvgSelect_MassiveP_speed_plotIndivCurves_20160628_AN_Input(SaveQuantDataFilename, controlDir,...
    % 'wake', BinWinSec, DatasetPointer, SBinTrcksSpdSize, BinTrcksO, BinTrcksLR, ...
    % BinTrcksSR, wakestate, motionstate, BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate, SBinWinSec,SelectData);
    
    close all;
end;
