%% This script finds the responses of worms.
% Run on als files of one developmental stage (e.g. Lethargus)
% This script will read data names from a file and then find any files which 
% match these in the  specified control folder(s). it will then create a 
% stats analysis for this.

clear all; close all;

%-- requires subfolder in main directory
controlDir = pwd; %'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_2.Lethargus+PostLet/_new/_controlDatasets';
saveDir = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/pdfs/_statsSpeed';

%Get data names:
excelInputFolder = '/Users/nichols/Dropbox/_Manuscript';

cd(excelInputFolder);

%Specify excel sheet data cells which have part of the als file names to search for.
dataNameInput = xlsread('Data_and_NPR1_ID_Controls.xlsx','pdfs','U25:U28');

%used for naming
controlfor = 'pdfs_pdfr1_npr1_Speed_18C_O2_21_s_Prelet';

%% INPUT!!!: Set analysis time windows
% INPUT! Period for which the track is picked to be either "lethargic" or "awake"
% Normally 5m prior to stim ([1260 1560]).
ConditionalBinSec1 = [1260 1500];
% start and end of period [s] in which animals are evaluated for being active or quiescent,
% used for quantifications with ROSpdQuantV2.m
%Note because of affects of the sliding bin, this was changed from 1260 1560, to 1260 1500

%INPUT! This is important to change if using a longer stimulus than 6m.
AlsBinSec1 = [1260 1560+363];
% start and end of period [s] in which animals are analysed based on criterium above,
% used for quantifications with ROSpdQuantV2.m

%% INPUT!!!: Set measured time periods:
%Imega turns
OBasalBinSec1 = ConditionalBinSec1 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];; % basal and response periods [s] for omega turns
OResponseBin1 = [1560 1660]; % O2  Omega: 1560 1660
% CO2 Omega: 1630 1860
% O2_21.0_s_ Annika: 1560 1660

%Long reversals
LRBasalBinSec1 = ConditionalBinSec1 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];; % basal and response periods [s] for reversals
LRResponseBin1 = [1560 1660]; % O2  Revs: 1560 1625
% CO2 Revs: 1690 1860
% O2_21.0_s_ Annika: 1560 1660

%Change if second stimulus comes at different time point.
StimShift = 1920;

% Wakestate and motionstate
BehaviorstateBin1 = [1740 1920];  %% Annika: 1620 1920, old 1740 1920 this is the whole period.
%[CO2 stimulus conditions]time periods from which to average behavioral state. Used for quantifications with ROSpdQuantV2.m
% new MS: O2_21.0_s_ Annika: 1740 1920 (last half)
BehaviorstateBin2 = BehaviorstateBin1 + StimShift;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Script, shouldn't need to change inputs below here.
% NOTES:
% Modified with Marek Suplata 2013-01-08
% Modifed by Annika 2016-6-22 based off
% SleepAlsV12Quant_CO2_SIZES_20130920_stats_MZ_3_4_ANtrue
% Modified by Annika 2016-7-14 to call on SleepQuantFun.
% Based off SleepQuantStats but edited to allow for finding excel 
% specified input in a specificed control directory. 20160801.

%% Second stimulus
%as above, but the second stimulus comes at a fixed time
%interval StimShift. Calculated automatically.

ConditionalBinSec2 = ConditionalBinSec1+StimShift;

% ConditionalBinSec2B = ConditionalBinSec1B+StimShift;
% ConditionalBinSec2C = ConditionalBinSec1C+StimShift;

AlsBinSec2 = AlsBinSec1+StimShift;

% AlsBinSec2B = AlsBinSec1B+StimShift;
% AlsBinSec2C = AlsBinSec1C+StimShift;

OBasalBinSec2 = ConditionalBinSec2 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
OResponseBin2 = OResponseBin1+StimShift;

LRBasalBinSec2 = ConditionalBinSec2 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
LRResponseBin2 = LRResponseBin1+StimShift;

%% Collect infomation:
CollectedTrksInfo.BehaviorstateBin1 = BehaviorstateBin1;
CollectedTrksInfo.ConditionalBinSec1 = ConditionalBinSec1;
CollectedTrksInfo.AlsBinSec1 = AlsBinSec1;

%% Addition for the control datasets
% Find datasets to run analysis on.

cd(controlDir);
walkDir = dir(pwd);
IncludedRecording = {};
FolderIncludedRecording = {};

for dirIdx = 1:length(walkDir);
    %gets only folders
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(controlDir, '/', walkDir(dirIdx).name)); %NOTE! / mac \ windows
        
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

SaveQuantDataFilename = strcat(saveDir, '/controlNPR1_',controlfor); %NOTE! / mac \ windows
disp(strcat('... save files as:', 32, walkDir(dirIdx).name));

%-- check for input not containing als.mat files
if size(IncludedRecording,1) > 0
    
    %% Annika 2016/06/28 improvement to get single tracks out.
    
    CollectedTrksInfo.alsName = {};
    CollectedTrksInfo.SleepTrcksNum = {};
    CollectedTrksInfo.WakeTrcksNum = {};
    CollectedTrksInfo.SleepTrcks = [];
    CollectedTrksInfo.WakeTrcks = [];
    counting =1;
    
    stimNumber  = {'_stim1','_stim2'};
    
    
    %% Sleep state quantifications which now contains behavioural results extraction.
    
    [NumberOfAlsFiles, ~] = size(IncludedRecording);
    
    for CurrAlsFile = 1:NumberOfAlsFiles
        
        disp(num2str(CurrAlsFile));
        
        disp(strcat('now loading: ',32, IncludedRecording{CurrAlsFile}));
        cd(FolderIncludedRecording{CurrAlsFile});
        load(IncludedRecording{CurrAlsFile});
        
        disp(strcat('now analyzing: ',32, IncludedRecording{CurrAlsFile}));
        
        %% Call Sleep quantification script
        [~, NumTracks] = size(Tracks);
        % Call SleepQuantFun
        [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
            SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
            NumTracks,movieFrames);
        
        %REMIMNDER: still have to fix problem with RingDistance here:
        %%[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5_old(Tracks,binning,SampleRate); % create matrices that contain speed and eccentricity (rows = Tracks, columns = frames);
        
        %%Extra analysis for the reversals and omega turns
        % create matrices that contain reversal initiation events (rows = Tracks, columns = frames);
        [BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, ~, ~, ~, t] = ROalsV4(Tracks,binning,SampleRate);
        
        
        %%
        
        FractionAwake(CurrAlsFile,:) = nanmean(wakestate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
        
        FileNameCell{CurrAlsFile} = IncludedRecording(CurrAlsFile); %changed
        
        FractionMotion1Sleep = {};
        FractionMotion1Wake = {};
        
        %This gives the responses of the first stimulus
        [Oresponse1Wake(CurrAlsFile),Oresponse1Sleep(CurrAlsFile),LRresponse1Wake(CurrAlsFile),...
            LRresponse1Sleep(CurrAlsFile),FractionActive1Sleep(CurrAlsFile),FractionActive1Wake(CurrAlsFile),...
            FractionMotion1Sleep,FractionMotion1Wake,SpeedBasalRate1Wake(CurrAlsFile),...
            SpeedResponseRate1Wake(CurrAlsFile),SpeedResponseRate1Sleep(CurrAlsFile)] = ... %AN 2016/06/22, added FractionMotion1Sleep/Wake, 2016/8/8 added SpeedResponse1Wake,SpeedResponse1Sleep, Removed SpeedResponse1Wake(CurrAlsFile),SpeedResponse1Sleep(CurrAlsFile) and replaced with SpeedBasalRate1Wake(CurrAlsFile), SpeedResponseRate1Wake(CurrAlsFile),SpeedResponseRate1Sleep(CurrAlsFile)
            ROSpdQuantV3_ANSpd(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,motionstate,t,NumBins,NumTracks,BinWinSec,...
            SBinWinSec,ConditionalBinSec1,AlsBinSec1,OBasalBinSec1,OResponseBin1,LRBasalBinSec1,LRResponseBin1,...
            BehaviorstateBin1);
        
        FractionMotion2Sleep = {};
        FractionMotion2Wake = {};
        
        %This gives the responses of the first stimulus
        [Oresponse2Wake(CurrAlsFile),Oresponse2Sleep(CurrAlsFile),LRresponse2Wake(CurrAlsFile),...
            LRresponse2Sleep(CurrAlsFile),FractionActive2Sleep(CurrAlsFile),FractionActive2Wake(CurrAlsFile),...
            FractionMotion2Sleep,FractionMotion2Wake,SpeedBasalRate2Wake(CurrAlsFile),...
            SpeedResponseRate2Wake(CurrAlsFile),SpeedResponseRate2Sleep(CurrAlsFile)] = ... %AN 2016/06/22, added FractionMotion2Sleep/Wake, 2016/8/8 added SpeedResponse1Wake,SpeedResponse1Sleep
            ROSpdQuantV3_ANSpd(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,motionstate,t,NumBins,NumTracks,BinWinSec,...
            SBinWinSec,ConditionalBinSec2,AlsBinSec2,OBasalBinSec2,OResponseBin2,LRBasalBinSec2,LRResponseBin2,...
            BehaviorstateBin2);
        
        %% Making struct with detailed info of the track, stim# and als name for both Sleep and Wake.
        stimNumberFraction = {FractionMotion1Sleep,FractionMotion1Wake,FractionMotion2Sleep,FractionMotion2Wake};
        
        %Note return was causing problems, had to rewrite for 1st
        %and 2nd
        
        %Selects based on als files which only 1st or 2nd stim should
        %be included.
        currName = IncludedRecording(CurrAlsFile); %Changed for control datatsets.
        beginP = 1;
        endP = 2;
        
        if ~isempty(findstr('1st',char(currName)));
            endP = 1;
        end
        
        if ~isempty(findstr('2nd',char(currName)));
            beginP = 2;
        end
        
        for stim = beginP:endP; %to cover both stimuli
            
            %Sets up the conditional window values for either stim.
            if stim == 1;
                ConditionalBinFr = floor(ConditionalBinSec1 / SBinWinSec);
            else
                ConditionalBinFr = floor(ConditionalBinSec2 / SBinWinSec);
            end
            
            %Find the track numbers that statisfys the conditional bin.
            [r, c]=size(FractionMotion1Sleep);
            count = 0;
            Selectwakestate =[];
            trackidxSleep =[];
            trackidxWake =[];
            
            for i=1:r;
                %for sleep
                if sum(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2)))==0;
                    count = count+1;
                    Selectwakestate(count,:) = wakestate(i,:);
                    trackidxSleep = [trackidxSleep, i];
                end
                %for wake
                if mean(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2)))==1;
                    count = count+1;
                    Selectwakestate(count,:) = wakestate(i,:);
                    trackidxWake = [trackidxWake, i];
                end
            end
            
            CollectedTrksInfo.alsName{counting,1} = strcat(IncludedRecording{CurrAlsFile,1},stimNumber{stim});

            
            %Collect track numbers
            CollectedTrksInfo.SleepTrcksNum{counting,1} = trackidxSleep;
            CollectedTrksInfo.WakeTrcksNum{counting,1} = trackidxWake;
            
            if stim == 2;
                stim1 = 3;
            else
                stim1 = stim;
            end
            
            stimNumberFraction = {FractionMotion1Sleep,FractionMotion1Wake,FractionMotion2Sleep,FractionMotion2Wake};
            
            %Make large matrix with all responses as single tracks
            CollectedTrksInfo.SleepTrcks = [CollectedTrksInfo.SleepTrcks; stimNumberFraction{stim1}(trackidxSleep,:)];
            CollectedTrksInfo.WakeTrcks = [CollectedTrksInfo.WakeTrcks; stimNumberFraction{stim1+1}(trackidxWake,:)];
            counting = counting + 1;
        end
        
        clear Tracks;
    end;
    
    %% Average responses

    FractionAwakeTotal = reshape(FractionAwake',1,numel(FractionAwake));
    
    FractionAwakeTotalTime = BinWinSec/2:BinWinSec:BinWinSec*numel(FractionAwake)-BinWinSec/2;
    
    close all;
    
    %% Stimuls controlled data
    %Selects based on als files which only 1st or 2nd stim should
    %be included. CHANGED for control datasets.
    SelectData = [];
    
    currFiles = IncludedRecording; %dir('*_als.mat');
    for i = 1 : size(currFiles,1)
        currName =char(currFiles(i));
        if findstr('1st',currName)
            disp(strcat(currFiles(i),'1st'));
            SelectData = [SelectData; 1, 0];
            
        elseif findstr('2nd',currName)
            disp(strcat(currFiles(i),'2nd'));
            SelectData = [SelectData; 0, 1];
            
        else
            %disp(strcat(currFiles(i),'otherwise'));
            SelectData = [SelectData; 1, 1];
            
        end;
    end;
    
    set1 = logical(SelectData(:,1))';
    set2 = logical(SelectData(:,2))';
    
    SpeedBasalRate1WakeSelect  = SpeedBasalRate1Wake(set1);
    
    SpeedBasalRate2WakeSelect = SpeedBasalRate2Wake(set2);
    
    SpeedResponse1WakeSelect  = SpeedResponseRate1Wake(set1);
    SpeedResponse1SleepSelect = SpeedResponseRate1Sleep(set1);
    
    Oresponse1WakeSelect = Oresponse1Wake(set1);
    Oresponse1SleepSelect = Oresponse1Sleep(set1);
    
    LRresponse1WakeSelect = LRresponse1Wake(set1);
    LRresponse1SleepSelect = LRresponse1Sleep(set1);
    
    SpeedResponse2WakeSelect  = SpeedResponseRate2Wake(set2);
    SpeedResponse2SleepSelect = SpeedResponseRate2Sleep(set2);
    
    Oresponse2WakeSelect = Oresponse2Wake(set2);
    Oresponse2SleepSelect = Oresponse2Sleep(set2);
    
    LRresponse2WakeSelect = LRresponse2Wake(set2);
    LRresponse2SleepSelect = LRresponse2Sleep(set2);

    
    save(strcat(SaveQuantDataFilename, '_select.mat'),'FractionAwake',...
        'FileNameCell','Oresponse1WakeSelect','Oresponse1SleepSelect',...
        'LRresponse1WakeSelect','LRresponse1SleepSelect',...
        'Oresponse2WakeSelect','Oresponse2SleepSelect',...
        'LRresponse2WakeSelect','LRresponse2SleepSelect',...
        'CollectedTrksInfo','SpeedResponse1WakeSelect','SpeedResponse1SleepSelect',...
        'SpeedResponse2WakeSelect','SpeedResponse2SleepSelect', 'SpeedBasalRate1WakeSelect',...
        'SpeedBasalRate2WakeSelect');
    
    
    FractionAwakeTotal = reshape(FractionAwake',1,numel(FractionAwake));
    
    FractionAwakeTotalTime = BinWinSec/2:BinWinSec:BinWinSec*numel(FractionAwake)-BinWinSec/2;
    % added 20130511:
    
else
    disp(strcat('... WARNING: no files found matching search pattern ', 32, DataFileName));
end;

close all;