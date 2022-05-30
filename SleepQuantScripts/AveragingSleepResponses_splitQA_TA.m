%% This script averages the responses of worms.
% Run on als files of one developmental stage (e.g. Lethargus)

clear all;

%-- requires subfolder in main directory
mainDir = pwd;%'/Users/nichols/Desktop/_test/_test1';
saveDir = '/Volumes/Annika_Nichols/_Let_Assays/_5_ALS_ToAverage/_5.Figures/revisions';%'\\storage.imp.ac.at\groups\zimmer\Annika_Nichols\_5_ALS_ToAverage\_3.RESULTS\_20160531';

DataRange = [1000 2000];   %define in sec the range that spans the first block you wish to be plotted
                           % first element has to be >= BinWinSec!; second element is the width
FirstStimulus = [1560 360];%6min start and width of first stimulus in seconds
%FirstStimulus = [1560 720];%12min


%% NOTES:
% include eccentricity change as parameter as well
% Based off: SleepAlsV7_plotIndivCurves_20150213
% 20170126 made so the range plotted is accessible 
% 20170309 Added Time adjustment to counter the miscalulcation of movie
% length.

%% Input into sleepQuantFun

lengthOfRecording = 89.9100;% OLD!: 90; % [minutes]

%-- framerate at which movie has been recorded
SampleRate = 1000/333;%OLD!: 3;
pixelsize  = 0.0276; %pixelsize in mm

%-- required for plotting wormsize median and mode
sizeBinFrames = 2700;
%-- choose only sizeBinFrames which result in an integer sizeBin
%-- otherise reshape command will later on throw an error
movieFrames = floor(lengthOfRecording*60*SampleRate);

%%

cd(mainDir);
disp(strcat('... Current directory:', 32, pwd));
walkDir = dir(pwd);
for i = 1 : size(walkDir,1)
    DataFileName = '*_als.mat';
    
    %gets only folders
    if walkDir(i).isdir == 1 && strcmp(walkDir(i).name, '.') == 0 ...
            && strcmp(walkDir(i).name, '..') == 0 && strcmp(walkDir(i).name, '.snapshot') == 0
        
        cd(strcat(mainDir, '/', walkDir(i).name)); %NOTE! / mac \ windows
        disp(strcat('... Current directory:', 32, pwd));
        
        OutputFileName = strcat(saveDir,'/',walkDir(i).name); %NOTE! / mac \ windows
        currFolder = walkDir(i).name;
        disp(strcat('... here we are:',32,OutputFileName));
        
        %clearvars -except mainDir saveDir SampleRate pixelsize walkDir OutputFileName currFolder;
        close all;
        
        disp('... loading data');
        [Tracks, files, DatasetPointer] = AccRevDatsV2_AN_TA(DataFileName);
        
        %% Call Sleep quantification script
        [~, NumTracks] = size(Tracks);
        % Call SleepQuantFun
        [motionstate,wakestate,binning,SlidingWinSizeBins,NumBins,SBinTrcksSpdSize,...
            SBinWinSec,~,St,~,~,~,~] = SleepQuantFun(SampleRate,pixelsize,Tracks,...
            NumTracks,movieFrames);

        %%
        %         disp('... running spdalsv5');
        %         [SBinWinSec, SBinTrcksSpd, SBinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, Sbintrcknum, St] = spdalsV5(Tracks,binning);
        %
        disp('... running ROalsV3');
        [BinWinSec, BinTrcksLR, BinTrcksSR, BinTrcksO, BinTrcksLRstate, BinTrcksSRstate, BinTrcksOstate, t] = ROalsV3(Tracks,binning);
        
        stimuli = [1560,360,1560+1920,360]; %stim 1 start, stim 1 width, stim 2 start, stim 2 width ....
        spdxmax = 5400;
        
        %Plot Fraction Wakestate Active
        FractionAwake = nanmean(wakestate(:, SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2));
        FractAwakeFig = DataFig(0,spdxmax,0,1,stimuli);
        
        plot(St(SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2), FractionAwake, 'k', 'linewidth',1.5);
        title (sprintf('%s-FractionActive_WS',currFolder),'Interpreter','none','FontSize',12);
        ylabel('Fraction active');
        xlabel('time [s]');
        
        saveas(gcf, sprintf('%s_FractionActive_WS.fig',OutputFileName), 'fig')
        
        %Plot Fraction MotionState Active
        FractionMotionStateAwake = nanmean(motionstate(:, SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2));
        FractMotionStateAwakeFig = DataFig(0,spdxmax,0,1,stimuli);
        
        plot(St(SlidingWinSizeBins/2 : NumBins-SlidingWinSizeBins/2), FractionMotionStateAwake, 'k', 'linewidth',1.5);
        title (sprintf('%s-FractionActive_MS',currFolder),'Interpreter','none','FontSize',12);
        ylabel('Fraction active');
        xlabel('time [s]');
        
        % print(gcf,'-dpdf',sprintf('%s_fractionActive.pdf',DataFileName));
        saveas(gcf, sprintf('%s_FractionActive_MS.fig',OutputFileName), 'fig')
        
        PlotAvgSelect_splitQA(OutputFileName, currFolder, 'sleep', BinWinSec, DatasetPointer, SBinTrcksSpdSize, BinTrcksO, BinTrcksLR, BinTrcksSR, wakestate, motionstate, BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate, SBinWinSec,DataRange,FirstStimulus);
        PlotAvgSelect_splitQA(OutputFileName, currFolder, 'wake', BinWinSec, DatasetPointer, SBinTrcksSpdSize, BinTrcksO, BinTrcksLR, BinTrcksSR, wakestate, motionstate, BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate, SBinWinSec,DataRange,FirstStimulus);
        
        close all;
        cd(mainDir);
        currFiles = dir(pwd);
    end;
end;
