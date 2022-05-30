
%plot averages from different experiments and multiple dataranges
%Modified and cleaned from PlotAvgSelect_MassiveP_speed_plotIndivCurves_20160628_AN

function PlotAverageMotionState(FilePrefix, PlotTitle, StateToPlot, BinWinSec, DatasetPointer, ...
                                                SBinTrcksSpdSize, BinTrcksO, BinTrcksLR, BinTrcksSR, wakestate, motionstate, ...
                                                BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate, SBinWinSec,SelectData,DataRange)
%%
    SelectData = []; %tag the blocks which you are interested in

    StimDist = 1920; % distance between blocks (or stimuli) in seconds

    %DataRange = [1000 2100];   %define in sec the range that spans the first block you wish to be plotted
                                % first element has to be >= BinWinSec!; second element is the width

    FirstStimulus = [1560 720]; %start and width of first stimulus

    SampleRate = 3; %framerate at which movie has been recorded

    pixelsize=0.0276; %pixelsize in mm
    
    
    ConditionalBinSec = [1260 1500]; %[3180 3480];%[1560 1560+360]; time window in which to sort tracks into sleep vs wake
    % Was [1260 1560] but this gives artefact due to sliding window. Use
    % [1260 1500].
    
    grey=[0.5 0.5 0.5]; %color of boxes that indicate stimuli
%     spdymax=0.22;
%     spdymin = 0;
%     Oymax=0.05; %AN normal is 0.04
    % spdxmax spdxmin and Oxmax Oxmin are calculated below

    TickDist = 180;
    FurtherBinning = 3;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    SelectData = [];

    currFiles = dir('*_als.mat');
    for i = 1 : size(currFiles,1)
        currName = currFiles(i).name;
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
    end;

    StResh = (DataRange(1):BinWinSec:DataRange(1)+DataRange(2))-FirstStimulus(1);

    DataRange1 = floor([DataRange; DataRange(1)+StimDist DataRange(2)]/BinWinSec);

    SBinTrcksSpdSizeResh =[];

    BinTrcksOResh =[];

    BinTrcksLRResh =[];

    BinTrcksSRResh =[];

    WakeStateResh =[];

    WakeMotionStateResh =[];
    
    BinTrcksOstateResh =[];

    BinTrcksLRstateResh =[];

    BinTrcksSRstateResh =[];

    [NumExp, NumStim] = size(SelectData);

    for i = 1:NumExp

        for ii = 1:NumStim

            if SelectData(i,ii)==1
                SBinTrcksSpdSizeResh = [SBinTrcksSpdSizeResh; ...
                    SBinTrcksSpdSize(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                BinTrcksOResh = [BinTrcksOResh; ...
                    BinTrcksO(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                BinTrcksLRResh = [BinTrcksLRResh; ...
                    BinTrcksLR(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                BinTrcksSRResh = [BinTrcksSRResh; ...
                    BinTrcksSR(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                WakeStateResh = [WakeStateResh; ...
                    wakestate(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                WakeMotionStateResh = [WakeMotionStateResh; ...
                    motionstate(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))]; %AN
                BinTrcksOstateResh = [BinTrcksOstateResh; ...
                    BinTrcksOstate(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                BinTrcksLRstateResh = [BinTrcksLRstateResh; ...
                    BinTrcksLRstate(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
                BinTrcksSRstateResh = [BinTrcksSRstateResh; ...
                    BinTrcksSRstate(DatasetPointer(i,1):DatasetPointer(i,2), DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];
            end
        end
    end
    
    [NumTracksResh, NumBinsResh] = size(SBinTrcksSpdSizeResh);

    %figure; plot(StResh,nanmean(BinTrcksOResh));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    stimuli = [0,FirstStimulus(2)]; %stim 1 start, stim 1 width, stim 2 start, stim 2 width ....

    AlsBinSec = DataRange; %time window for plotting these data
    FurtherBinWinSec = BinWinSec * FurtherBinning;
    FurtherNumBinsResh = floor(NumBinsResh/FurtherBinning);
    FurtherBinTime = StResh(1):FurtherBinWinSec:StResh(end);
    % TimeBinIdx=reshape(t(1:FurtherBinning*FurtherNumBinsResh),FurtherBinning,FurtherNumBinsResh);

    SpdSleep = NaN(NumTracksResh,NumBinsResh);
    SpdWake  = NaN(NumTracksResh,NumBinsResh);
    OSleep = NaN(NumTracksResh,NumBinsResh);
    OWake = NaN(NumTracksResh,NumBinsResh);
    LRSleep = NaN(NumTracksResh,NumBinsResh);
    LRWake = NaN(NumTracksResh,NumBinsResh);
    SRSleep = NaN(NumTracksResh,NumBinsResh);
    SRWake = NaN(NumTracksResh,NumBinsResh);

    FollowingStateSleep = NaN(NumTracksResh,NumBinsResh);
    FollowingMotionStateSleep = NaN(NumTracksResh,NumBinsResh); %AN
    FollowingStateWake = NaN(NumTracksResh,NumBinsResh);
    OfractSleep = NaN(NumTracksResh,NumBinsResh);
    OfractWake = NaN(NumTracksResh,NumBinsResh);

    LRfractWake = NaN(NumTracksResh,NumBinsResh);
    LRfractSleep = NaN(NumTracksResh,NumBinsResh);

    ConditionalBinFr = floor((ConditionalBinSec-DataRange(1)) / SBinWinSec);

    for i = 1:NumTracksResh

        if sum(WakeStateResh(i,ConditionalBinFr(1):ConditionalBinFr(2)))==0
            SpdSleep(i,:) = SBinTrcksSpdSizeResh(i,:);
            OSleep(i,:) = BinTrcksOResh(i,:);
            LRSleep(i,:) = BinTrcksLRResh(i,:);
            SRSleep(i,:) = BinTrcksSRResh(i,:);

            FollowingStateSleep(i,:) = WakeStateResh(i,:);
            FollowingMotionStateSleep(i,:) = WakeMotionStateResh(i,:); %AN
            OfractSleep(i,:) = BinTrcksOstateResh(i,:);
            LRfractSleep(i,:) = BinTrcksLRstateResh(i,:);
        end

        if sum(~(WakeStateResh(i,ConditionalBinFr(1):ConditionalBinFr(2))==1))==0
            SpdWake(i,:) = SBinTrcksSpdSizeResh(i,:);
            OWake(i,:) = BinTrcksOResh(i,:);
            LRWake(i,:) = BinTrcksLRResh(i,:);
            SRWake(i,:) = BinTrcksSRResh(i,:);
            FollowingStateWake(i,:) = WakeStateResh(i,:);
            OfractWake(i,:) = BinTrcksOstateResh(i,:);
            LRfractWake(i,:) = BinTrcksLRstateResh(i,:);
        end
    end

%     if  strcmp(StateToPlot,'sleep')
%         SpeedToPlot = SpdSleep;
%         Oplot=OSleep;
%         LRplot=LRSleep;
%         SRplot=SRSleep;
%     end
%     if  strcmp(StateToPlot,'wake')
%         SpeedToPlot = SpdWake;
%         Oplot=OWake;
%         LRplot=LRWake;
%         SRplot=SRWake;
%     end

% 	spdxmax=StResh(end); % axis scales ....only raw data plots
%   spdxmin = StResh(1);
% 	Oxmax= spdxmax;
% 	tickmarks=0:TickDist:FurtherBinTime(end); %tickmarks for subplots

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if  strcmp(StateToPlot,'sleep')

        mnFollowingStateSleep = nanmean(FollowingStateSleep);
        FollowStateFig = DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh, mnFollowingStateSleep, 'b', 'linewidth', 2.5);
        ylabel('fraction active');
        xlabel('time [s]');
        titleStr = sprintf('%s_%s_Fraction active_WakeState',PlotTitle,StateToPlot);
        title(titleStr, 'Interpreter', 'none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence_WakeState.ai',FilePrefix,StateToPlot));
        %print (gcf, '-dpdf', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence.pdf',FilePrefix,StateToPlot));
        %saveas(gcf, sprintf('%s_%s_1-Fraction exiting quiescence.fig',FilePrefix,StateToPlot), 'fig')

        %AN: Plot motionstate
        mnFollowingMotionStateSleep = nanmean(FollowingMotionStateSleep);
        FollowStateFig = DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh, mnFollowingMotionStateSleep, 'b', 'linewidth', 2.5);
        ylabel('fraction active');
        xlabel('time [s]');
        titleStr = sprintf('%s_%s_Fraction active_MotionState',PlotTitle,StateToPlot);
        title(titleStr, 'Interpreter', 'none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence_MotionState.ai',FilePrefix,StateToPlot));

    end
end