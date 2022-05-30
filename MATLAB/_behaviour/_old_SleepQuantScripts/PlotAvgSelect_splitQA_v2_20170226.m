
%plot averages from different experiments and multiple dataranges
%Modified and cleaned- Annika 20160628
function PlotAvgSelect_splitQA(FilePrefix, PlotTitle, StateToPlot, BinWinSec, DatasetPointer, ...
                                                SBinTrcksSpdSize, BinTrcksO, BinTrcksLR, BinTrcksSR, wakestate, motionstate, ...
                                                BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate, SBinWinSec,DataRange,FirstStimulus)
    %%
    StimDist = 1920; % distance between blocks (or stimuli) in seconds
    
    ConditionalBinSec = [1260 1500]; %[3180 3480];%[1560 1560+360]; time window in which to sort tracks into sleep vs wake
    % Was [1260 1560] but this gives artefact due to sliding window. Use
    % [1260 1500].
    ConditionalBinQASec = [1525 1560]; %[3180 3480];%[1560 1560+360]; time window in which to sort tracks into sleep vs wake

    grey=[0.5 0.5 0.5]; %color of boxes that indicate stimuli

    spdymax=0.22;
    spdymin = 0;
    Oymax=0.05; %AN normal is 0.04
    % spdxmax spdxmin and Oxmax Oxmin are calculated below

    TickDist = 180;
    FurtherBinning = 3;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    SelectData = []; %tag the blocks which you are interested in

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

    %AlsBinSec = DataRange; %time window for plotting these data
    FurtherBinWinSec = BinWinSec * FurtherBinning;
    %FurtherNumBinsResh = floor(NumBinsResh/FurtherBinning);
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
    ConditionalBinQAFr = floor((ConditionalBinQASec-DataRange(1)) / SBinWinSec);

    %Find only tracks that satisfy the prior state (lethargic or
    %non-lethargic behaviour)
    SleepTracksQuiescent = NaN(NumTracksResh,1);
    SleepTracksActive = NaN(NumTracksResh,1);
    countSleepTracks=1;
    
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
            
            %Added 20170215: Find tracks that are Active or Quiescent prior to
            %stimului
            
            if sum(WakeMotionStateResh(i,ConditionalBinQAFr(1):ConditionalBinQAFr(2)))==0
                SleepTracksQuiescent(i,1) = countSleepTracks;
                
            elseif sum(WakeMotionStateResh(i,ConditionalBinQAFr(1):ConditionalBinQAFr(2)))==(1+ConditionalBinQAFr(2)-ConditionalBinQAFr(1));
                SleepTracksActive(i,1) = countSleepTracks;
            end
            
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
        countSleepTracks = countSleepTracks +1;
    end
    
    %remove nans
    SleepTracksQuiescent(isnan(SleepTracksQuiescent))=[];
    SleepTracksActive(isnan(SleepTracksActive))=[];
    
    viewingFollowingMS=FollowingMotionStateSleep;
    viewingFollowingMS(isnan(viewingFollowingMS))=3;
    figure; imagesc(viewingFollowingMS(SleepTracksQuiescent,:))
    line([ConditionalBinQAFr(1),ConditionalBinQAFr(1)],[0,800])
    line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,800])
    figure; imagesc(viewingFollowingMS(SleepTracksActive,:))
    line([ConditionalBinQAFr(1),ConditionalBinQAFr(1)],[0,800])
    line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,800])
    
	spdxmax=StResh(end); % axis scales ....only raw data plots
    spdxmin = StResh(1);
	Oxmax= spdxmax;

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
        
        
        %------------------------------------------------------------------
        %------------------------------------------------------------------
        %-- add individual all curves to mean plot
        FollowStateIndivFig = DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));

        indivCurves = [];
        curveNames = {'meanCurve'};
        for currCurve = 1:size(DatasetPointer,1)
            currCurveName = currFiles(currCurve).name;
            %-- check if applicable and plot first and second stimulus
            for currStim = 1:2
                disp(strcat('... Curve:', int2str(currCurve), 32, 'Stim:', int2str(currStim)));
                if SelectData(currCurve,currStim) == 1
                    disp('... activeStim');
                    curveNames{end+1} = strcat(currCurveName,'-',int2str(currStim));
                    CurrSBinTrcksSpdSizeResh = SBinTrcksSpdSize(DatasetPointer(currCurve,1):DatasetPointer(currCurve,2), ...
                                                DataRange1(currStim,1):DataRange1(currStim,1)+DataRange1(currStim,2));

                    [CurrNumTracksResh, CurrNumBinsResh] = size(CurrSBinTrcksSpdSizeResh);
                    CurrFollowingStateSleep = NaN(CurrNumTracksResh, CurrNumBinsResh);
                    for ij = 1:CurrNumTracksResh
                        CurrWakeState = wakestate(DatasetPointer(currCurve,1):DatasetPointer(currCurve,2), ...
                                            DataRange1(currStim,1):DataRange1(currStim,1)+DataRange1(currStim,2));
                        if sum(CurrWakeState(ij,ConditionalBinFr(1):ConditionalBinFr(2)))==0
                            CurrFollowingStateSleep(ij,:) = CurrWakeState(ij,:);
                        end;
                    end;
                    mnCurrFollowingStateSleep = nanmean(CurrFollowingStateSleep);
                    indivCurves = [indivCurves; mnCurrFollowingStateSleep];
                end;
            end;
        end;

        plot(StResh, mnFollowingStateSleep, 'b', 'linewidth', 5);
        %-- hold all uses a new color for each line
        hold all;
        for getCol = 1:size(indivCurves,1)
            plot(StResh, indivCurves(getCol,:), 'linewidth', 1);
        end;
        ylabel('fraction exiting from quiescence');
        xlabel('time [s]');
        titleStr = sprintf('%s_%s_Fraction exiting quiescence',PlotTitle,StateToPlot);
        title(titleStr, 'Interpreter', 'none');
        legend(curveNames,'Location','SouthOutside','FontSize',6);
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence_indCurv_legend.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence_indCurv_legend.pdf',FilePrefix,StateToPlot));
        %saveas(gcf, sprintf('%s_%s_1-Fraction exiting quiescence_indCurv.fig',FilePrefix,StateToPlot), 'fig')
        hold off;

        %-- plot again w/o legend
        FollowStateIndivFig = DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh, mnFollowingStateSleep, 'b', 'linewidth', 5);
        %-- hold all uses a new color for each line
        hold all;
        for getCol = 1:size(indivCurves,1)
            plot(StResh, indivCurves(getCol,:), 'linewidth', 1);
        end;
        ylabel('fraction exiting from quiescence');
        xlabel('time [s]');
        titleStr = sprintf('%s_%s_Fraction exiting quiescence',PlotTitle,StateToPlot);
        title(titleStr, 'Interpreter', 'none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence_indCurv.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence_indCurv.pdf',FilePrefix,StateToPlot));
        %saveas(gcf, sprintf('%s_%s_1-Fraction exiting quiescence_indCurv.fig',FilePrefix,StateToPlot), 'fig')
        hold off;        
        %------------------------------------------------------------------
        %------------------------------------------------------------------
        
        mnOfractSleep = nanmean(OfractSleep);
        OfractSleepFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnOfractSleep,'b','linewidth',2.5);
        ylabel('fraction turning after quiescence');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Turning Quiescence',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_2-Fraction Turning Quiescence.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_2-Fraction Turning Quiescence.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_2-Fraction Turning Quiescence.fig',FilePrefix,StateToPlot), 'fig')

        mnLRfractSleep = nanmean(LRfractSleep);
        LRfractSleepFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnLRfractSleep,'b','linewidth',2.5);
        ylabel('fraction reversing after quiescence');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Reversing Quiescence',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_3-Fraction Reversing Quiescence.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_3-Fraction Reversing Quiescence.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_3-Fraction Reversing Quiescence.fig',FilePrefix,StateToPlot), 'fig')


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        mnspd = nanmean(SpdSleep);
        strspd = nansterr(SpdSleep);

        SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));
        jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);
        hold on;

        plot(StResh,mnspd,'b','linewidth',2.5);
        ylabel('speed [worm-lengths / s]');
        titleStr = sprintf('%s_%s_SpeedOfQuiescentAnimals',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_6-SpeedOfQuiescentAnimals.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_6-SpeedOfQuiescentAnimals.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_6-SpeedOfQuiescentAnimals.fig',FilePrefix,StateToPlot), 'fig')

        % Speed of QA split
        mnspd = nanmean(SpdSleep(SleepTracksQuiescent,:));
        strspd = nansterr(SpdSleep(SleepTracksQuiescent,:));
        
        SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));
        jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);
%         line([ConditionalBinQAFr(1),ConditionalBinQAFr(1)],[spdymin,spdymax])
%         line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[spdymin,spdymax])
        hold on;
        
        plot(StResh,mnspd,'b','linewidth',2.5);
        ylabel('speed [worm-lengths / s]');
        titleStr = sprintf('%s_%s_SpeedOfLethargicAnimalsQuiescent',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_6-SpeedOfLethargicAnimalsQui.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_6-SpeedOfLethargicAnimalsQui.pdf',FilePrefix,StateToPlot));
        
                % Speed of QA split
        mnspd = nanmean(SpdSleep(SleepTracksActive,:));
        strspd = nansterr(SpdSleep(SleepTracksActive,:));
        
        SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));
        jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);
        %line([ConditionalBinQAFr(1),ConditionalBinQAFr(1)],[spdymin,spdymax])
        %line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[spdymin,spdymax])
        hold on;
        
        plot(StResh,mnspd,'b','linewidth',2.5);
        ylabel('speed [worm-lengths / s]');
        titleStr = sprintf('%s_%s_SpeedOfLethargicAnimalsActive',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_6-SpeedOfLethargicAnimalsAct.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_6-SpeedOfLethargicAnimalsAct.pdf',FilePrefix,StateToPlot));
        
        
        %%%

        BinOSleep = BinTurns(FurtherBinning,OSleep);
        mnBinOSleep = nanmean(BinOSleep)/FurtherBinWinSec;
        stBinOSleep = nansterr(BinOSleep)/FurtherBinWinSec;

        BinOSleepPlot=mnBinOSleep(~isnan(mnBinOSleep));
        stBinOSleepPlot=stBinOSleep(~isnan(mnBinOSleep));
        timeplot=FurtherBinTime(~isnan(mnBinOSleep));

        if size(timeplot,2) > 0
            OFigure=Ofig(Oxmax,Oymax,stimuli);
            xlim([timeplot(1) timeplot(end)]);
            title('Omega Turns After Quiescence');
            jbfill(timeplot,BinOSleepPlot+stBinOSleepPlot,BinOSleepPlot-stBinOSleepPlot,grey,grey,0,1);
            hold on;
            plot(timeplot,BinOSleepPlot,'b','linewidth',2.5);
            titleStr = sprintf('%s_%s_Omega Turns Quiescence',PlotTitle,StateToPlot);
            title(titleStr,'Interpreter','none');
            print (gcf, '-depsc', '-r300', sprintf('%s_%s_4-Omega Turns Quiescence.ai',FilePrefix,StateToPlot));
            print (gcf, '-dpdf', '-r300', sprintf('%s_%s_4-Omega Turns Quiescence.pdf',FilePrefix,StateToPlot));
            %saveas(gcf,      sprintf('%s_%s_4-Omega Turns Quiescence.fig',FilePrefix,StateToPlot), 'fig')
            
            % Speed of QA split
            BinOSleep = BinTurns(FurtherBinning,OSleep(SleepTracksQuiescent,:));
            mnBinOSleep = nanmean(BinOSleep)/FurtherBinWinSec;
            stBinOSleep = nansterr(BinOSleep)/FurtherBinWinSec;
            
            BinOSleepPlot=mnBinOSleep(~isnan(mnBinOSleep));
            stBinOSleepPlot=stBinOSleep(~isnan(mnBinOSleep));
            timeplot=FurtherBinTime(~isnan(mnBinOSleep));
            
            OFigure=Ofig(Oxmax,Oymax,stimuli);
            xlim([timeplot(1) timeplot(end)]);
            title('Omega Turns Lethargus Qui');
            jbfill(timeplot,BinOSleepPlot+stBinOSleepPlot,BinOSleepPlot-stBinOSleepPlot,grey,grey,0,1);
            hold on;
            plot(timeplot,BinOSleepPlot,'b','linewidth',2.5);
            titleStr = sprintf('%s_%s_Omega Turns Lethargus Qui',PlotTitle,StateToPlot);
            title(titleStr,'Interpreter','none');
            print (gcf, '-depsc', '-r300', sprintf('%s_%s_4-Omega Turns Lethargus Qui.ai',FilePrefix,StateToPlot));
            print (gcf, '-dpdf', '-r300', sprintf('%s_%s_4-Omega Turns Lethargus Qui.pdf',FilePrefix,StateToPlot));
            
                        BinOSleep = BinTurns(FurtherBinning,OSleep(SleepTracksActive,:));
            mnBinOSleep = nanmean(BinOSleep)/FurtherBinWinSec;
            stBinOSleep = nansterr(BinOSleep)/FurtherBinWinSec;
            
            BinOSleepPlot=mnBinOSleep(~isnan(mnBinOSleep));
            stBinOSleepPlot=stBinOSleep(~isnan(mnBinOSleep));
            timeplot=FurtherBinTime(~isnan(mnBinOSleep));
            
            OFigure=Ofig(Oxmax,Oymax,stimuli);
            xlim([timeplot(1) timeplot(end)]);
            title('Omega Turns Lethargus Act');
            jbfill(timeplot,BinOSleepPlot+stBinOSleepPlot,BinOSleepPlot-stBinOSleepPlot,grey,grey,0,1);
            hold on;
            plot(timeplot,BinOSleepPlot,'b','linewidth',2.5);
            titleStr = sprintf('%s_%s_Omega Turns Lethargus Act',PlotTitle,StateToPlot);
            title(titleStr,'Interpreter','none');
            print (gcf, '-depsc', '-r300', sprintf('%s_%s_4-Omega Turns Lethargus Act.ai',FilePrefix,StateToPlot));
            print (gcf, '-dpdf', '-r300', sprintf('%s_%s_4-Omega Turns Lethargus Act.pdf',FilePrefix,StateToPlot));
            
        end;
            
        BinLRSleep = BinTurns(FurtherBinning,LRSleep);
        mnBinLRSleep = nanmean(BinLRSleep)/FurtherBinWinSec;
        stBinLRSleep = nansterr(BinLRSleep)/FurtherBinWinSec;

        BinLRSleepPlot=mnBinLRSleep(~isnan(mnBinLRSleep));
        stBinLRSleepPlot=stBinLRSleep(~isnan(mnBinLRSleep));
        timeplot=FurtherBinTime(~isnan(mnBinLRSleep));

        if size(timeplot,2) > 0
            LRFigure=Ofig(Oxmax,Oymax,stimuli);
            xlim([timeplot(1) timeplot(end)]);
            title('Reversals After Quiescence');
            jbfill(timeplot,BinLRSleepPlot+stBinLRSleepPlot,BinLRSleepPlot-stBinLRSleepPlot,grey,grey,0,1);
            hold on;
            plot(timeplot,BinLRSleepPlot,'b','linewidth',2.5);
            titleStr = sprintf('%s_%s_Reversals Quiescence',PlotTitle,StateToPlot);
            title(titleStr,'Interpreter','none');
            print (gcf, '-depsc', '-r300', sprintf('%s_%s_5-Reversals Quiescence.ai',FilePrefix,StateToPlot));
            print (gcf, '-dpdf', '-r300', sprintf('%s_%s_5-Reversals Quiescence.pdf',FilePrefix,StateToPlot));

            % Speed of QA split
            BinLRSleep = BinTurns(FurtherBinning,LRSleep(SleepTracksQuiescent,:));
            mnBinLRSleep = nanmean(BinLRSleep)/FurtherBinWinSec;
            stBinLRSleep = nansterr(BinLRSleep)/FurtherBinWinSec;
            
            BinLRSleepPlot=mnBinLRSleep(~isnan(mnBinLRSleep));
            stBinLRSleepPlot=stBinLRSleep(~isnan(mnBinLRSleep));
            timeplot=FurtherBinTime(~isnan(mnBinLRSleep));
            
            LRFigure=Ofig(Oxmax,Oymax,stimuli);
            xlim([timeplot(1) timeplot(end)]);
            title('Reversals After Lethargus Qui');
            jbfill(timeplot,BinLRSleepPlot+stBinLRSleepPlot,BinLRSleepPlot-stBinLRSleepPlot,grey,grey,0,1);
            hold on;
            plot(timeplot,BinLRSleepPlot,'b','linewidth',2.5);
            titleStr = sprintf('%s_%s_Reversals Lethargus Qui',PlotTitle,StateToPlot);
            title(titleStr,'Interpreter','none');
            print (gcf, '-depsc', '-r300', sprintf('%s_%s_5-Reversals Lethargus Qui.ai',FilePrefix,StateToPlot));
            print (gcf, '-dpdf', '-r300', sprintf('%s_%s_5-Reversals Lethargus Qui.pdf',FilePrefix,StateToPlot));

            %active
            BinLRSleep = BinTurns(FurtherBinning,LRSleep(SleepTracksActive,:));
            mnBinLRSleep = nanmean(BinLRSleep)/FurtherBinWinSec;
            stBinLRSleep = nansterr(BinLRSleep)/FurtherBinWinSec;
            
            BinLRSleepPlot=mnBinLRSleep(~isnan(mnBinLRSleep));
            stBinLRSleepPlot=stBinLRSleep(~isnan(mnBinLRSleep));
            timeplot=FurtherBinTime(~isnan(mnBinLRSleep));
            
            LRFigure=Ofig(Oxmax,Oymax,stimuli);
            xlim([timeplot(1) timeplot(end)]);
            title('Reversals After Lethargus Act');
            jbfill(timeplot,BinLRSleepPlot+stBinLRSleepPlot,BinLRSleepPlot-stBinLRSleepPlot,grey,grey,0,1);
            hold on;
            plot(timeplot,BinLRSleepPlot,'b','linewidth',2.5);
            titleStr = sprintf('%s_%s_Reversals Lethargus Act',PlotTitle,StateToPlot);
            title(titleStr,'Interpreter','none');
            print (gcf, '-depsc', '-r300', sprintf('%s_%s_5-Reversals Lethargus Act.ai',FilePrefix,StateToPlot));
            print (gcf, '-dpdf', '-r300', sprintf('%s_%s_5-Reversals Lethargus Act.pdf',FilePrefix,StateToPlot));

        end;
    end;



    if  strcmp(StateToPlot,'wake')

        mnFollowingStateWake = nanmean(FollowingStateWake);
        FollowStateFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnFollowingStateWake,'m','linewidth',2.5);
        ylabel('fraction active');
        xlabel('time [s]');
        titleStr = sprintf('%s_%s_Fraction Active',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_1-Fraction Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_1-Fraction Active.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_1-Fraction Active.fig',FilePrefix,StateToPlot), 'fig')

        mnOfractWake = nanmean(OfractWake);
        OfractWakeFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnOfractWake,'m','linewidth',2.5);
        ylabel('fraction of active animals turning');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Active Turning',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_2-Fraction Turning Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_2-Fraction Turning Active.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_2-Fraction Turning Active.fig',FilePrefix,StateToPlot), 'fig')

        mnLRfractWake = nanmean(LRfractWake);
        LRfractWakeFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnLRfractWake,'m','linewidth',2.5);
        ylabel('fraction of active animals reversing');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Reversing Active',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_3-Fraction Reversing Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_3-Fraction Reversing Active.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_3-Fraction Reversing Active.fig',FilePrefix,StateToPlot), 'fig')


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        mnspd=nanmean(SpdWake);
        strspd=nansterr(SpdWake);

        SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));

        jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);

        hold on;

        plot(StResh,mnspd,'m','linewidth',2.5);
        ylabel('speed [worm-lengths / s]');
        titleStr = sprintf('%s_%s_Speed Of Active Animals',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_6-SpeedOfActiveAnimals.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_6-SpeedOfActiveAnimals.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_6-SpeedOfActiveAnimals.fig',FilePrefix,StateToPlot), 'fig')

        %%%

        BinOWake = BinTurns(FurtherBinning,OWake);
        mnBinOWake = nanmean(BinOWake)/FurtherBinWinSec;
        stBinOWake = nansterr(BinOWake)/FurtherBinWinSec;


        BinOWakePlot=mnBinOWake(~isnan(mnBinOWake));
        stBinOWakePlot=stBinOWake(~isnan(mnBinOWake));
        timeplot=FurtherBinTime(~isnan(mnBinOWake));


        OFigure=Ofig(Oxmax,Oymax,stimuli);
        xlim([timeplot(1) timeplot(end)]);
        title('Omega Turns After Activity');
        jbfill(timeplot,BinOWakePlot+stBinOWakePlot,BinOWakePlot-stBinOWakePlot,grey,grey,0,1);
        hold on;
        plot(timeplot,BinOWakePlot,'m','linewidth',2.5);
        titleStr = sprintf('%s_%s_Omega Turns Active',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_4-Omega Turns Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_4-Omega Turns Active.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_4-Omega Turns Active.fig',FilePrefix,StateToPlot), 'fig')



        BinLRWake = BinTurns(FurtherBinning,LRWake);
        mnBinLRWake = nanmean(BinLRWake)/FurtherBinWinSec;
        stBinLRWake = nansterr(BinLRWake)/FurtherBinWinSec;


        BinLRWakePlot=mnBinLRWake(~isnan(mnBinLRWake));
        stBinLRWakePlot=stBinLRWake(~isnan(mnBinLRWake));
        timeplot=FurtherBinTime(~isnan(mnBinLRWake));


        LRFigure=Ofig(Oxmax,Oymax,stimuli);
        xlim([timeplot(1) timeplot(end)]);
        title('Reversals After Activity');
        jbfill(timeplot,BinLRWakePlot+stBinLRWakePlot,BinLRWakePlot-stBinLRWakePlot,grey,grey,0,1);
        hold on;
        plot(timeplot,BinLRWakePlot,'m','linewidth',2.5);
        titleStr = sprintf('%s_%s_Reversals Active',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_5-Reversals Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_5-Reversals Active.pdf',FilePrefix,StateToPlot));
        %saveas(gcf,      sprintf('%s_%s_5-Reversals Active.fig',FilePrefix,StateToPlot), 'fig')

    end
end



