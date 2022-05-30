%% Make lethargus curves
% This script needs to be run in a folder of the folders of interest. Best if
% tracks are at least 700frames long (use TrackReducer_V700 if need be).

clear; close all; clc;

mainDir = pwd;%'\\storage.imp.ac.at\groups\zimmer\Annika_Nichols\_3_Als_tracked_ToPlot\_20160607\_new3';
saveDir = 'V:\Annika_Nichols\_Let_Assays\_4_Als_tracked_ToPlot_Results\_20170403_revisions_P16_13pc';%'\\storage.imp.ac.at\groups\zimmer\Annika_Nichols\_4_Als_tracked_ToPlot_Results\_20160607';

%% NOTES:
%include also eccentricity parameter
%Based off: SleepAlsV13Quant_ActivityPlot_TE_MS_VBS_3_MotionStateTotal_edit

% Modified with Marek Suplata 2013-01-08
% Modified by Annika Nichols 2016-07-08 to:
% 1. include a motionstate let plot
% 2. change form -dill (illustrator files) to -depsc (coloured eps file).
% Modified by Annika Nichols 2016-07-08 to:
%Run SleepQuantFun to get sleep quantification.

%Note: there was a problem with motion state having lots of small bouts
%which were all being classed as quiescent bouts. Only bouts which are long
%enough are counted in the wakestate.

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


%% Script

cd(mainDir);
disp(strcat('... Current directory:', 32, pwd));
walkDir = dir(pwd);
for dirIdx = 1 : size(walkDir,1)
    DataFileName = '*_als.mat';
    
    wormSizeMedian = zeros(1, totalSizeBins);
    wormSizeMode = zeros(1, totalSizeBins);
    FractionAwake = [];
    FractionInMotionState = [];
                
    %gets only folders
    if walkDir(dirIdx).isdir == 1 && strcmp(walkDir(dirIdx).name, '.') == 0 && strcmp(walkDir(dirIdx).name, '..') == 0
        cd(strcat(mainDir, '/', walkDir(dirIdx).name)); %NOTE! / for mac \ for PC
        disp(strcat('... Current directory:', 32, pwd));
        
        SaveQuantDataFilename = strcat(saveDir, '/', walkDir(dirIdx).name); %NOTE! / for mac \ for PC
        currFolder = walkDir(dirIdx).name;
        disp(strcat('... save files as:', 32, walkDir(dirIdx).name));
        
        %clearvars -except mainDir saveDir walkDir dirIdx SaveQuantDataFilename currFolder;
        close all;
        
        
        %% Work through each als file and call SleepQuantFun to get motionstate and wakestate.
        Files = dir(DataFileName);
        
        [NumberOfAlsFiles, ~] = size(Files);
        
        %-- check for folders not containing proper als.mat files
        if size(Files,1) > 0
            
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
                
                %%
                ConditionalBinSec1 = [1440 1560];
                
                AlsBinSec1 = [1440 1560+363];
                
                % SET MEASURED PERIODS:
                OBasalBinSec1 = ConditionalBinSec1 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
                OResponseBin1 = [1630 1860]; % O2  Omega: 1560 1660
                % CO2 Omega: 1630 1860
                %
                LRBasalBinSec1 = ConditionalBinSec1 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
                LRResponseBin1 = [1690 1860]; % O2  Revs: 1560 1625
                % CO2 Revs: 1690 1860
                %%%%%%%
                
                ConditionalBinSec2 = ConditionalBinSec1+1920;
                
                AlsBinSec2 = AlsBinSec1+1920;
                
                OBasalBinSec2 = ConditionalBinSec2 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
                OResponseBin2 = OResponseBin1+1920;
                %
                LRBasalBinSec2 = ConditionalBinSec2 ; %[1260 1560]; %[3180 3480];%[1560 1560+360];;
                LRResponseBin2 = LRResponseBin1+1920;
                
                %             medSizeMat = [];
                %             modSizeMat = [];
                
                %% Extra quantification
                
                %[SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5(Tracks,binning);
                [BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, BinTrcksLRstate, BinTrcksSRstate, BinTrcksOstate, t] = ROalsV3(Tracks,binning);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                
                FractionInMotionState(CurrAlsFile,:) = nanmean(motionstate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
                
                FractionAwake(CurrAlsFile,:) = nanmean(wakestate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
                
                FileNameCell{CurrAlsFile} = Files(CurrAlsFile).name;
                
                [Oresponse1Wake(CurrAlsFile),Oresponse1Sleep(CurrAlsFile),LRresponse1Wake(CurrAlsFile),LRresponse1Sleep(CurrAlsFile)] = ROSpdQuant(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,t,NumBins,NumTracks,BinWinSec,SBinWinSec,ConditionalBinSec1,AlsBinSec1,OBasalBinSec1,OResponseBin1,LRBasalBinSec1,LRResponseBin1);
                
                [Oresponse2Wake(CurrAlsFile),Oresponse2Sleep(CurrAlsFile),LRresponse2Wake(CurrAlsFile),LRresponse2Sleep(CurrAlsFile)] = ROSpdQuant(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,t,NumBins,NumTracks,BinWinSec,SBinWinSec,ConditionalBinSec2,AlsBinSec2,OBasalBinSec2,OResponseBin2,LRBasalBinSec2,LRResponseBin2);
                
                %-- get worm size median and mode
                wormSizeMedian(CurrAlsFile*sizeBins-(sizeBins-1) : CurrAlsFile*sizeBins) ...
                    = median(reshape(nanmean(currWormSize), sizeBinFrames, sizeBins));
                wormSizeMode(CurrAlsFile*sizeBins-(sizeBins-1) : CurrAlsFile*sizeBins) ...
                    = mode(reshape(nanmean(currWormSize), sizeBinFrames, sizeBins));
                
            end;
            
            wormSizeMedianSave = [];
            wormSizeModeSave = [];
            for ii = 1 : numberOfVideos
                wormSizeMedianSave(ii,1:sizeBins) = wormSizeMedian(ii*sizeBins-(sizeBins-1) : ii*sizeBins);
                wormSizeModeSave(ii,1:sizeBins) = wormSizeMode(ii*sizeBins-(sizeBins-1) : ii*sizeBins);
            end;

            
            FractionAwakeTotal = reshape(FractionAwake',1,numel(FractionAwake));
            
            FractionInMotionStateTotal = reshape(FractionInMotionState',1,numel(FractionInMotionState));
            
            FractionAwakeTotalTime = BinWinSec/2:BinWinSec:BinWinSec*numel(FractionAwake)-BinWinSec/2;
            
            %Saves important data FIX!!! DO WE NEED ALL THIS????
            save(strcat(SaveQuantDataFilename,'.mat'),'FractionAwake','FileNameCell','Oresponse1Wake',...
                'Oresponse1Sleep','LRresponse1Wake','LRresponse1Sleep','Oresponse2Wake',...
                'Oresponse2Sleep','LRresponse2Wake','LRresponse2Sleep','wormSizeMedian','wormSizeMode','wormSizeMedianSave','wormSizeModeSave',...
                'FractionInMotionStateTotal','FractionAwakeTotal','motionstate');
            
            %% FIGURE PLOTTING:
            fractionfig = figure;
            
            hold on;
            plot(FractionAwakeTotalTime/60,FractionAwakeTotal,'b','LineWidth',2.1);
            title(sprintf('%s', currFolder),'Interpreter','none','FontSize',15)
            
            % -- set fixed y-axis limits to [0 1]
            ylim([0 1]);
            xlabel('Dev. Time [hours]','FontSize',13);
            ylabel('fraction active','FontSize',13);
            
            set(gca,'XTick',tickmarks);
            set(gca,'YTick',[0.25 0.5 0.75]);
            
            xlim([0 numberOfVideos*90]);
            grid on
            
            set(gca,'GridLineStyle','-');
            
            %saveas(fractionfig,[SaveQuantDataFilename '.fig'],'fig');
            print (gcf, '-depsc', '-r900', sprintf('%s.ai', SaveQuantDataFilename) );
            
            %-- timepoints to plot wormsize median and mode
            time = 15:15:size(wormSizeMedian,2)*15;
            
            %-- plot wormsize median
            medianfig = figure;
            hold on;
            plot(time,wormSizeMedian,'k','LineWidth',2.7);
            title(sprintf('%s', currFolder),'Interpreter','none','FontSize',15)
            
            % -- set fixed y-axis limits
            ylim([20 140]);
            xlabel('Dev. Time [hours]','FontSize',13);
            ylabel('median','FontSize',13);
            set(gca,'XTick',tickmarks);
            set(gca,'YTick',[25 50 75 100 125]);
            xlim([0 numberOfVideos*90]);
            grid on
            set(gca,'GridLineStyle','-');
            
            print (gcf, '-depsc', '-r900', sprintf('%s_median.ai', SaveQuantDataFilename));
            
            %============
            %Finding developmental time at recording start
            
            spos=find(currFolder=='s');
            charnum=currFolder(spos(end)+1:spos(end)+4);
            trec=str2num(charnum);
            
            %%============
            figure(3);
            nintervals=10; %number of divisons of axis Y
            %-- timepoints to plot wormsize median and mode
            time = (15:15:size(wormSizeMedian,2)*15)/60+trec;
            DevTime=(FractionAwakeTotalTime/3600)+trec;
            [AX,H1,H2]=plotyy(DevTime,FractionAwakeTotal,time,wormSizeMedian);
            hold on
            set(get(AX(1),'Ylabel'),'String','fraction active','FontSize',13)
            set(get(AX(2),'Ylabel'),'String','median','FontSize',13)
            set(H1,'Color','b','LineWidth',2.1)
            set(H2,'LineWidth',2.7)
            
            
            title(sprintf('%s', currFolder),'Interpreter','none','FontSize',15)
            
            % -- set fixed y-axis limits to [0 1]
            axes(AX(1))
            xlim([0 numberOfVideos*1.5]+trec);
            grid on
            set(gca,'GridLineStyle','-');
            set(gca,'FontSize',11);
            ylim([0 1]);
            xlabel('time [hours]','FontSize',13);
            ylimits1 = get(AX(1),'YLim'); yinc1 = (ylimits1(2)-ylimits1(1))/nintervals;
            set(gca,'XTick',[trec:1.5:trec+1.5*14]);
            set(gca,'TickDir','out');
            set(gca,'YTick',[ylimits1(1):yinc1:ylimits1(2)])
            
            axes(AX(2))
            xlim([0 numberOfVideos*1.5]+trec);
            set(gca,'XTick',[]);
            set(gca,'FontSize',11);
            ylim([20 140]);
            ylimits2 = get(AX(2),'YLim');
            yinc2 = (ylimits2(2)-ylimits2(1))/nintervals;
            
            set(gca,'YTick',[ylimits2(1):yinc2:ylimits2(2)])
            hold off
            
            
            print (gcf, '-painters', '-r900', sprintf('%s_medianV.ai', SaveQuantDataFilename),'-depsc');
            
            %%=========== %plot motion state over time.
            figure(4);
            nintervals=10; %number of divisons of axis Y
            %-- timepoints to plot wormsize median and mode
            time = [15:15:size(wormSizeMedian,2)*15]/60+trec;
            %Developmental time (used for motionstate).
            DevTime=(FractionAwakeTotalTime/3600)+trec;
            
            [AX,H1,H2]=plotyy(DevTime,FractionInMotionStateTotal,time,wormSizeMedian);
            hold on
            %plot(AX(1),[0 time],0.5*ones(length([0 time]),1),'r--','LineWidth',3.0)
            set(get(AX(1),'Ylabel'),'String','fraction active','FontSize',13)
            set(get(AX(2),'Ylabel'),'String','median','FontSize',13)
            set(H1,'Color','b','LineWidth',2.1)
            set(H2,'LineWidth',2.7)
            
            title(sprintf('%s', currFolder),'Interpreter','none','FontSize',15)
            
            % -- set fixed y-axis limits to [0 1]
            axes(AX(1))
            xlim([0 numberOfVideos*1.5]+trec);
            grid on
            set(gca,'GridLineStyle','-');
            set(gca,'FontSize',11);
            ylim([0 1]);
            xlabel('time [hours]','FontSize',13);
            ylimits1 = get(AX(1),'YLim'); yinc1 = (ylimits1(2)-ylimits1(1))/nintervals;
            set(gca,'XTick',[trec:1.5:trec+1.5*14]);
            set(gca,'TickDir','out');
            set(gca,'YTick',[ylimits1(1):yinc1:ylimits1(2)])
            
            axes(AX(2))
            xlim([0 numberOfVideos*1.5]+trec);
            set(gca,'XTick',[]);
            set(gca,'FontSize',11);
            ylim([20 140]);
            ylimits2 = get(AX(2),'YLim');
            yinc2 = (ylimits2(2)-ylimits2(1))/nintervals;
            
            set(gca,'YTick',[ylimits2(1):yinc2:ylimits2(2)])
            hold off
            
            print (gcf, '-painters', '-r900', sprintf('%s_MotionState_medianV.ai', SaveQuantDataFilename),'-depsc');
            %============
            
            %-- plot wormsize mode
            modefig = figure;
            hold on;
            time2=[15:15:size(wormSizeMedian,2)*15];
            plot(time2, wormSizeMode, 'm', 'LineWidth', 2.7);
            title(sprintf('%s', currFolder),'Interpreter','none','FontSize',15)
            
            % -- set fixed y-axis limits
            ylim([20 140]);
            xlabel('time [minutes]','FontSize',13);
            ylabel('mode','FontSize',13);
            set(gca,'XTick',tickmarks);
            set(gca,'YTick',[25 50 75 100 125]);
            xlim([0 numberOfVideos*90]);
            grid on
            set(gca,'GridLineStyle','-');
            
            %saveas(modefig,[SaveQuantDataFilename '_mode.fig'],'fig');
            print (gcf, '-depsc', '-r900', sprintf('%s_mode.ai', SaveQuantDataFilename));
            
            
            %             %-- plot wormsize mode and median in the same figure
            %             modMedfig = figure;
            %             hold on;
            %             plot(time2, wormSizeMode, 'm', 'LineWidth', 2.7);
            %             plot(time2, wormSizeMedian, 'k', 'LineWidth', 2.7);
            %             title(sprintf('%s', currFolder),'Interpreter','none','FontSize',15)
            %
            %             % -- set fixed y-axis limits
            %             ylim([20 140]);
            %             xlabel('time [minutes]','FontSize',13);
            %             ylabel('mode(magenta) + median(black)','FontSize',13);
            %             set(gca,'XTick',tickmarks);
            %             set(gca,'YTick',[25 50 75 100 125]);
            %             xlim([0 numberOfVideos*90]);
            %             grid on
            %             set(gca,'GridLineStyle','-');
            %
            %             %saveas(modMedfig,[SaveQuantDataFilename '_modMed.fig'],'fig');
            %             print (gcf, '-depsc', '-r900', sprintf('%s_modMed.ai', SaveQuantDataFilename));
            
            FractionAwakeTotal = reshape(FractionAwake',1,numel(FractionAwake));
            
            FractionAwakeTotalTime = BinWinSec/2:BinWinSec:BinWinSec*numel(FractionAwake)-BinWinSec/2;
        else
            disp(strcat('... WARNING: no files found matching search pattern ', 32, DataFileName));
        end
        
        %Repeat for all folders.
        close all;
        cd(mainDir);
        currFiles = dir(pwd);
    end;
    
end;
clear all