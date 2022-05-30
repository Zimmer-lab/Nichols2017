%% This script finds the responses of worms.
% Run on als files of one developmental stage (e.g. Lethargus)

clear; close all; clc;

%Input:
mainDir = pwd;%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_2.Lethargus+PostLet/_new/_12m/_new'; %'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_2.Lethargus+PostLet/_new/_figure2/_new';%'/Volumes/groups/zimmer/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_2.Lethargus+PostLet/_new/_figure1/new'; %'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_2.Lethargus+PostLet/_new/_figure2/_new'; %'Z:\Annika_Nichols\_5_ALS_ToAverage\_2.Lethargus+PostLet\_new\_new';
%saveDir = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Homeostasis/Stats_8-10m_postStim';%'/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/Figure2';%'T:\Annika_Nichols\_Let_Assays\_5_ALS_ToAverage\_4.Statisics\_20160630_AN_collectedtracksTest'; %'Z:\Annika_Nichols\_5_ALS_ToAverage\_4.Statisics\_20160530_J310_12m';
saveDir ='V:\Annika_Nichols\_Let_Assays\_5_ALS_ToAverage\_5.Figures\revisions\Stats_npr1_CO2_TA_FT_20170330';

%% INPUT!!!: Set analysis time windows
% INPUT! Period for which the track is picked to be either "lethargic" or "awake"
% Normally 5m prior to stim ([1260 1560]).
ConditionalBinSec1 = [1260 1500];
% start and end of period [s] in which animals are evaluated for being active or quiescent,
% used for quantifications with ROSpdQuantV2.m
%Note because of affects of the sliding bin, this was changed from 1260 1560, to 1260 1500

%INPUT! This is important to change if using a longer stimulus than 6m.
AlsBinSec1 = [1260 1560+363];

%12m
%AlsBinSec1 = [1260 1560+1083];

%homeostatic measure 
%AlsBinSec1 = [1260 1560+1500];

% start and end of period [s] in which animals are analysed based on criterium above,
% used for quantifications with ROSpdQuantV2.m

% For Quiescent/Active (QA) prior to stim split:
ConditionalBinQASec1 = [1550 1560];

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
%BehaviorstateBin1 = [1740 1920];  %% Annika: 1620 1920, old 1740 1920 this is the whole period.

%12m
BehaviorstateBin1 = [1560 1920];

%12m
%BehaviorstateBin1 = [2040 2280];

% %peak [1590 1740]
%BehaviorstateBin1 = [1590 1620];

%homeostatic measure %8-9min [2040 2100] %-1-0min [1500 1560] %14-15min [2400 2460]
%BehaviorstateBin1 = [2040 2160];

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
% Modified by Annika 2017-03-09 to time adjust
% Modified by Annika 2017-03-21 to look at first turn and to introduce
% InstantQA to determine Quiescence vs Active within a 5sec bin without
% sliding windows. This is used for the QA split for looking at the first
% turn.

%% Second stimulus
%as above, but the second stimulus comes at a fixed time
%interval StimShift. Calculated automatically.

ConditionalBinSec2 = ConditionalBinSec1+StimShift;

ConditionalBinQASec2 = ConditionalBinQASec1+StimShift;

AlsBinSec2 = AlsBinSec1+StimShift;

OBasalBinSec2 = ConditionalBinSec2 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
OResponseBin2 = OResponseBin1+StimShift;

LRBasalBinSec2 = ConditionalBinSec2 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
LRResponseBin2 = LRResponseBin1+StimShift;

%% Collect infomation:
CollectedTrksInfo.BehaviorstateBin1 = BehaviorstateBin1;
CollectedTrksInfo.ConditionalBinSec1 = ConditionalBinSec1;
CollectedTrksInfo.ConditionalBinQASec1 = ConditionalBinQASec1;
CollectedTrksInfo.AlsBinSec1 = AlsBinSec1;

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
            
            CollectedTrksInfo.alsName = {};
            CollectedTrksInfo.SleepTrcksNum = {};
            CollectedTrksInfo.WakeTrcksNum = {};
            CollectedTrksInfo.SleepTrcksQuiescent = {};
            CollectedTrksInfo.SleepTrcksActive = {};
            CollectedTrksInfo.SleepTrcks = [];
            CollectedTrksInfo.WakeTrcks = [];
            CollectedTrksInfo.SleepAllTurnStarts = [];
            CollectedTrksInfo.SleepAllTurnStartsBinned = [];
            CollectedTrksInfo.WakeAllTurnStarts = [];
            CollectedTrksInfo.WakeAllTurnStartsBinned = [];
            countingAls =1;
            
            stimNumber  = {'_stim1','_stim2'};
            
            
            %% Sleep state quantifications which now contains behavioural results extraction.
            
            [NumberOfAlsFiles, ~] = size(Files);
            FractionAwake = NaN(NumberOfAlsFiles,movieFrames/SampleRate/5); %binning =5;
            
            for CurrAlsFile = 1:NumberOfAlsFiles
                
                disp(num2str(CurrAlsFile));
                
                disp(strcat('now loading: ',32, Files(CurrAlsFile).name));
                %load(Files(CurrAlsFile).name);
                %Use this to load files so that the timing issue is taken
                %care of. Should only load the CurrAlsFile
                [Tracks, ~, ~] = AccRevDatsV2_AN_TA(Files(CurrAlsFile, 1).name);

                
                disp(strcat('now analyzing: ',32, Files(CurrAlsFile).name));
                
                %% Call Sleep quantification script
                [~, NumTracks] = size(Tracks);
                % Call SleepQuantFun
                [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
                    SBinWinSec,currWormSize,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
                    NumTracks,movieFrames);
                
                %Call InstSleepQuantFun
                [InstMotionState] = InstSleepQuantFun(binning,Tracks,NumTracks,SBinTrcksSpdSize);
                
                %REMIMNDER: still have to fix problem with RingDistance here:
                %%[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5_old(Tracks,binning,SampleRate); % create matrices that contain speed and eccentricity (rows = Tracks, columns = frames);
                
                %%Extra analysis for the reversals and omega turns
                % create matrices that contain reversal initiation events (rows = Tracks, columns = frames);
                [BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, ~, ~, ~, t] = ROalsV4(Tracks,binning,SampleRate);
                
                %  create matrices that contain turn initiation events (rows = Tracks, columns = frames);
                [AllTurnStarts,AllTurnStartsBinned] = DetectTurning(SampleRate,binning,Tracks,movieFrames);
        
                %%
                [~,BinLength]=size(motionstate); %added in as lengths now differ due to TA (time adjustment) cropping start.
                %take away NaNs at start and finish due to sliding window
                FractionAwake(CurrAlsFile,1:(BinLength-(SlidingWinSizeBins-1))) = nanmean(wakestate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
                
                FileNameCell{CurrAlsFile} = Files(CurrAlsFile).name;

                
                %This gives the responses of the first stimulus
                [Oresponse1Wake(CurrAlsFile),Oresponse1Sleep(CurrAlsFile),LRresponse1Wake(CurrAlsFile),...
                    LRresponse1Sleep(CurrAlsFile),FractionActive1Sleep(CurrAlsFile),FractionActive1Wake(CurrAlsFile),...
                    FractionMotion1Sleep,FractionMotion1Wake,SpeedBasalRate1Wake(CurrAlsFile),...
                    SpeedResponseRate1Wake(CurrAlsFile),SpeedResponseRate1Sleep(CurrAlsFile),...
                    TurnResponseRate1Wake(CurrAlsFile),TurnResponseRate1Sleep(CurrAlsFile),...
                    FractionTurn1Sleep,FractionTurn1Wake] = ... %AN 2016/06/22, added FractionMotion1Sleep/Wake, 2016/8/8 added SpeedResponse1Wake,SpeedResponse1Sleep, Removed SpeedResponse1Wake(CurrAlsFile),SpeedResponse1Sleep(CurrAlsFile) and replaced with SpeedBasalRate1Wake(CurrAlsFile), SpeedResponseRate1Wake(CurrAlsFile),SpeedResponseRate1Sleep(CurrAlsFile)
                    ROSpdQuantV3_ANSpdFT(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,motionstate,AllTurnStartsBinned,t,NumBins,NumTracks,BinWinSec,...
                    SBinWinSec,ConditionalBinSec1,AlsBinSec1,OBasalBinSec1,OResponseBin1,LRBasalBinSec1,LRResponseBin1,...
                    BehaviorstateBin1);
                
                %This gives the responses of the second stimulus
                [Oresponse2Wake(CurrAlsFile),Oresponse2Sleep(CurrAlsFile),LRresponse2Wake(CurrAlsFile),...
                    LRresponse2Sleep(CurrAlsFile),FractionActive2Sleep(CurrAlsFile),FractionActive2Wake(CurrAlsFile),...
                    FractionMotion2Sleep,FractionMotion2Wake,SpeedBasalRate2Wake(CurrAlsFile),...
                    SpeedResponseRate2Wake(CurrAlsFile),SpeedResponseRate2Sleep(CurrAlsFile),...
                    TurnResponseRate2Wake(CurrAlsFile),TurnResponseRate2Sleep(CurrAlsFile),...
                    FractionTurn2Sleep,FractionTurn2Wake] = ... %AN 2016/06/22, added FractionMotion2Sleep/Wake, 2016/8/8 added SpeedResponse1Wake,SpeedResponse1Sleep
                    ROSpdQuantV3_ANSpdFT(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,motionstate,AllTurnStartsBinned,t,NumBins,NumTracks,BinWinSec,...
                    SBinWinSec,ConditionalBinSec2,AlsBinSec2,OBasalBinSec2,OResponseBin2,LRBasalBinSec2,LRResponseBin2,...
                    BehaviorstateBin2);
                
                %% Making struct with detailed info of the track, stim# and als name for both Sleep and Wake.
                %Note return was causing problems, had to rewrite for 1st
                %and 2nd
                
                %Selects based on als files which only 1st or 2nd stim should
                %be included.
                currName = Files(CurrAlsFile).name;
                beginP = 1;
                endP = 2;
                
                if ~isempty(findstr('1st',currName));
                    endP = 1;
                end
                
                if ~isempty(findstr('2nd',currName));
                    beginP = 2;
                end
                
                for stim = beginP:endP; %to cover both stimuli
                    
                    %Sets up the conditional window values for either stim.
                    if stim == 1;
                        ConditionalBinFr = floor(ConditionalBinSec1 / SBinWinSec);
                        %corrects for taking one extra bin
                        ConditionalBinQASecA = [ConditionalBinQASec1(1)+SBinWinSec,ConditionalBinQASec1(2)]; 
                        ConditionalBinQASec = floor(ConditionalBinQASecA / SBinWinSec);
                        

                    else
                        ConditionalBinFr = floor(ConditionalBinSec2 / SBinWinSec);
                        %corrects for taking one extra bin
                        ConditionalBinQASecA = [ConditionalBinQASec2(1)+SBinWinSec,ConditionalBinQASec2(2)];
                        ConditionalBinQASec = floor(ConditionalBinQASecA / SBinWinSec);
                    end
                    
                    %Find the track numbers that satisfies the conditional bin.
                    [r, c]=size(FractionMotion1Sleep);
                    count = 0;
                    Selectwakestate =[];
                    trackidxSleep =[];
                    trackidxWake =[];
                    
                    %QA split: Find only tracks that satisfy the prior state (lethargic or
                    %non-lethargic behaviour) and within lethargic, the
                    %ones that satisfy the QA split. This index refers to
                    %the 
                    SleepTracksQuiescent = NaN(NumTracks,1);
                    SleepTracksActive = NaN(NumTracks,1);
                    countSleepTracks=1;
    
                    for i=1:r;
                        %for sleep
                        if sum(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2)))==0;
                            count = count+1;
                            Selectwakestate(count,:) = wakestate(i,:);
                            trackidxSleep = [trackidxSleep, i];
                            
                            %find the track numbers of sleep that satisfy
                            %QA criteria
                            
                            if sum(InstMotionState(i,ConditionalBinQASec(1):ConditionalBinQASec(2)))==0
                                SleepTracksQuiescent(i,1) = countSleepTracks;
                                
                            elseif sum(InstMotionState(i,ConditionalBinQASec(1):ConditionalBinQASec(2)))==(1+ConditionalBinQASec(2)-ConditionalBinQASec(1));
                                SleepTracksActive(i,1) = countSleepTracks;
                            end
                            %QA split
                            countSleepTracks = countSleepTracks +1;
                            
                        end
                        %for wake
                        if mean(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2)))==1;
                            count = count+1;
                            Selectwakestate(count,:) = wakestate(i,:);
                            trackidxWake = [trackidxWake, i];
                        end

                    end
                    
                    %QA split: remove nans
                    SleepTracksQuiescent(isnan(SleepTracksQuiescent))=[];
                    SleepTracksActive(isnan(SleepTracksActive))=[];
    
                    
                    CollectedTrksInfo.alsName{countingAls,1} = strcat(Files(CurrAlsFile).name,stimNumber{stim});
                    
                    %Collect track numbers
                    CollectedTrksInfo.SleepTrcksNum{countingAls,1} = trackidxSleep;
                    CollectedTrksInfo.WakeTrcksNum{countingAls,1} = trackidxWake;
                    % Note that the index refers to the track within the
                    % SleepTrcks matrix.
                    CollectedTrksInfo.SleepTrcksQuiescent{countingAls,1} = SleepTracksQuiescent;
                    CollectedTrksInfo.SleepTrcksActive{countingAls,1} = SleepTracksActive;
                    
                    if stim == 2;
                        stim1 = 3;
                    else
                        stim1 = stim;
                    end
                    
                    stimNumberFraction = {FractionMotion1Sleep,FractionMotion1Wake,FractionMotion2Sleep,FractionMotion2Wake};
                    stimNumberFractionTurns = {FractionTurn1Sleep,FractionTurn1Wake,FractionTurn2Sleep,FractionTurn2Wake};

                    %Make large matrix with all responses as single tracks
                    CollectedTrksInfo.SleepTrcks = [CollectedTrksInfo.SleepTrcks; stimNumberFraction{stim1}(trackidxSleep,:)];
                    CollectedTrksInfo.WakeTrcks = [CollectedTrksInfo.WakeTrcks; stimNumberFraction{stim1+1}(trackidxWake,:)];
                    
                    CollectedTrksInfo.SleepAllTurnStartsBinned = [CollectedTrksInfo.SleepAllTurnStartsBinned; stimNumberFractionTurns{stim1}(trackidxSleep,:)];
                    CollectedTrksInfo.WakeAllTurnStartsBinned = [CollectedTrksInfo.WakeAllTurnStartsBinned; stimNumberFractionTurns{stim1+1}(trackidxWake,:)];
                    
                    countingAls = countingAls + 1;
                end
                
                clear Tracks;
            end;
            
            %% Average responses

            FractionAwakeTotal = reshape(FractionAwake',1,numel(FractionAwake));
            
            FractionAwakeTotalTime = BinWinSec/2:BinWinSec:BinWinSec*numel(FractionAwake)-BinWinSec/2;
            
            close all;
            
            %%
            %Selects based on als files which only 1st or 2nd stim should
            %be included.
            SelectData = [];
            
            currFiles = dir('*_als.mat');
            for i = 1 : size(currFiles,1)
                currName =currFiles(i).name;
                if findstr('1st',currName)
                    disp(strcat(currFiles(i).name,32,'1st'));
                    SelectData = [SelectData; 1, 0];
                    
                elseif findstr('2nd',currName)
                    disp(strcat(currFiles(i).name,32,'2nd'));
                    SelectData = [SelectData; 0, 1];
                    
                else
                    disp(strcat(currFiles(i).name,32,'otherwise'));
                    SelectData = [SelectData; 1, 1];
                    
                end;
            end;
            
            set1 = logical(SelectData(:,1))';
            set2 = logical(SelectData(:,2))';
            
            
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
            
            
            %             FractionActive1WakeSelect = FractionActive1Wake(set1);
            %             FractionActive1SleepSelect = FractionActive1Sleep(set1);
            %
            %             FractionActive2WakeSelect = FractionActive2Wake(set2);
            %             FractionActive2SleepSelect = FractionActive2Sleep(set2);
            
            save(strcat(SaveQuantDataFilename, '_select.mat'),'FractionAwake',...
                'FileNameCell','Oresponse1WakeSelect','Oresponse1SleepSelect',...
                'LRresponse1WakeSelect','LRresponse1SleepSelect',...
                'Oresponse2WakeSelect','Oresponse2SleepSelect',...
                'LRresponse2WakeSelect','LRresponse2SleepSelect',...
                'CollectedTrksInfo','SpeedResponse1WakeSelect','SpeedResponse2WakeSelect');
            %'FractionActive1WakeSelect', 'FractionActive1SleepSelect',...
            %'FractionActive2WakeSelect','FractionActive2SleepSelect',...
            %'FractionActive1BSleepSelect','FractionActive2BSleepSelect',...
            %'FractionActive1BWakeSelect','FractionActive2BWakeSelect',...
            %'FractionActive1CSleepSelect','FractionActive2CSleepSelect',...
            %'FractionActive1CWakeSelect','FractionActive2CWakeSelect',...
            %'FractionActive1PreMidSleepSelect','FractionActive2MidSleepSelect',...
            %'FractionActive1PreMidWakeSelect','FractionActive2MidWakeSelect');
            
            FractionAwakeTotal = reshape(FractionAwake',1,numel(FractionAwake));
            
            FractionAwakeTotalTime = BinWinSec/2:BinWinSec:BinWinSec*numel(FractionAwake)-BinWinSec/2;
            % added 20130511:
            
        else
            disp(strcat('... WARNING: no files found matching search pattern ', 32, DataFileName));
        end;
        
        close all;
        cd(mainDir);
        currFiles = dir(pwd);
    end;
end;
close all;