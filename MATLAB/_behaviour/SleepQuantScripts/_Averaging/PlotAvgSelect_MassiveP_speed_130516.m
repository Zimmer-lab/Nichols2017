
%plot averages from different experiments and multiple dataranges
function PlotAvgSelect_MassiveP_speed_130516(FilePrefix, PlotTitle, StateToPlot, BinWinSec, DatasetPointer, SBinTrcksSpdSize, BinTrcksO, BinTrcksLR, BinTrcksSR, wakestate, BinTrcksOstate, BinTrcksLRstate, BinTrcksSRstate, SBinWinSec)
    %FilePrefix = 'N2_O2_10.0_1.PreLet_v74_'; 
                % N2--CO2-0.5-2.Let %%

    %StateToPlot ='sleep';           % wake or sleep

    SelectData = []; %tag the blocks which you are interested in


    StimDist = 1920; % distance between blocks (or stimuli) in seconds

    DataRange = [1000 1600];   %define in sec the range that spans the first block you wish to be plotted
                                % first element has to be >= BinWinSec!; second element is the width

    FirstStimulus = [1560 360]; %start and width of first stimulus

    SampleRate = 3; %framerate at which movie has been recorded

    pixelsize=0.0276; %pixelsize in mm

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';
    % StateToPlot ='wake';           % wake or sleep

    ConditionalBinSec = [1260 1560]; %[3180 3480];%[1560 1560+360]; time window in which to sort tracks into sleep vs wake


    grey=[0.5 0.5 0.5]; %color of boxes that indicate stimuli



    spdymax=0.22;

    spdymin = 0;

    Oymax=0.04;

    % spdxmax spdxmin and Oxmax Oxmin are calculated below

    TickDist = 180;

    FurtherBinning = 3;





    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    SelectData = [];

    currFiles = dir('*_als.mat');
    for i = 1 : size(currFiles,1)
        currName =currFiles(i).name;
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

    %disp(SelectData);



    StResh = (DataRange(1):BinWinSec:DataRange(1)+DataRange(2))-FirstStimulus(1);




    DataRange1 = floor([DataRange; DataRange(1)+StimDist DataRange(2)]/BinWinSec);

    SBinTrcksSpdSizeResh =[];

    BinTrcksOResh =[];

    BinTrcksLRResh =[];

    BinTrcksSRResh =[];

    WakeStateResh =[];

    BinTrcksOstateResh =[];

    BinTrcksLRstateResh =[];

    BinTrcksSRstateResh =[];


    [NumExp, NumStim] = size(SelectData);

    for i = 1:NumExp

        for ii = 1:NumStim

            if SelectData(i,ii)==1

            SBinTrcksSpdSizeResh = [SBinTrcksSpdSizeResh; SBinTrcksSpdSize(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];


            BinTrcksOResh = [BinTrcksOResh; BinTrcksO(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];

            BinTrcksLRResh = [BinTrcksLRResh; BinTrcksLR(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];

            BinTrcksSRResh = [BinTrcksSRResh; BinTrcksSR(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];

            WakeStateResh = [WakeStateResh; wakestate(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];


             BinTrcksOstateResh = [BinTrcksOstateResh; BinTrcksOstate(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];

            BinTrcksLRstateResh = [BinTrcksLRstateResh; BinTrcksLRstate(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];

            BinTrcksSRstateResh = [BinTrcksSRstateResh; BinTrcksSRstate(DatasetPointer(i,1):DatasetPointer(i,2),DataRange1(ii,1):DataRange1(ii,1)+DataRange1(ii,2))];





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
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % FractionAwake = nanmean(WakeStateResh(:,SlidingWinSizeBins/2:NumBinsResh-SlidingWinSizeBins/2));
    % FractAwakeFig=DataFig(0,spdxmax,0,1,stimuli); 
    % plot(FurtherBinTime,FractionAwake,'k','linewidth',1.5);
    % 
    % ylabel('Fraction active');
    % xlabel('time [s]');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    if  strcmp(StateToPlot,'sleep')


    SpeedToPlot = SpdSleep;
    Oplot=OSleep;
    LRplot=LRSleep;
    SRplot=SRSleep;

    end


    if  strcmp(StateToPlot,'wake')


    SpeedToPlot = SpdWake;
    Oplot=OWake;
    LRplot=LRWake;
    SRplot=SRWake;

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    % mnspd=nanmean(SpeedToPlot);
    % strspd=nansterr(SpeedToPlot);
    % 
    % mnO=nanmean(Oplot)/BinWinSec;
    % strO=nansterr(Oplot)/BinWinSec;
    % 
    % mnLR=nanmean(LRplot)/BinWinSec;
    % strLR=nansterr(LRplot)/BinWinSec;
    % 
    % mnSR=nanmean(SRplot)/BinWinSec;
    % strSR=nansterr(SRplot)/BinWinSec;
    % 



    % SpdFigure=spdfig(spdxmax,spdymax,stimuli);
    % title('Instantaneous Speed');
    % jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);
    % hold on;
    % plot(StResh,mnspd,'k','linewidth',1.5);
    % ylabel('speed [wormlengths / s]');
    % 
    % 
    % OFigure=Ofig(Oxmax,Oymax,stimuli);
    % title('Omega Turns');
    % jbfill(StResh,mnO+strO,mnO-strO,grey,grey,0,1);
    % hold on;
    % plot(StResh,mnO,'k','linewidth',1.5);
    % 
    % LRFigure=Ofig(Oxmax,Oymax,stimuli);
    % title('Large Reversals');
    % jbfill(StResh,mnLR+strLR,mnLR-strLR,grey,grey,0,1);
    % hold on;
    % plot(StResh,mnLR,'k','linewidth',1.5);
    % 
    % SRFigure=Ofig(Oxmax,Oymax,stimuli);
    % title('Small Reversals');
    % jbfill(StResh,mnSR+strSR,mnSR-strSR,grey,grey,0,1);
    % hold on;
    % plot(StResh,mnSR,'k','linewidth',1.5);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        spdxmax=StResh(end); % axis scales ....only raw data plots

        spdxmin = StResh(1);

        Oxmax= spdxmax;

        %Oxmin = spdxmin;

        tickmarks=0:TickDist:FurtherBinTime(end); %tickmarks for subplots


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    if  strcmp(StateToPlot,'sleep')

        mnFollowingStateSleep=nanmean(FollowingStateSleep);
        FollowStateFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnFollowingStateSleep,'b','linewidth',2.5);
        ylabel('fraction exiting from quiescence');
        xlabel('time [s]');
        titleStr = sprintf('%s_%s_Fraction exiting quiescence',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_1-Fraction exiting quiescence.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_1-Fraction exiting quiescence.fig',FilePrefix,StateToPlot), 'fig')

        mnOfractSleep = nanmean(OfractSleep);
        OfractSleepFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnOfractSleep,'b','linewidth',2.5);
        ylabel('fraction turning after quiescence');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Turning Quiescence',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_2-Fraction Turning Quiescence.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_2-Fraction Turning Quiescence.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_2-Fraction Turning Quiescence.fig',FilePrefix,StateToPlot), 'fig')

        mnLRfractSleep = nanmean(LRfractSleep);
        LRfractSleepFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnLRfractSleep,'b','linewidth',2.5);
        ylabel('fraction reversing after quiescence');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Reversing Quiescence',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_3-Fraction Reversing Quiescence.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_3-Fraction Reversing Quiescence.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_3-Fraction Reversing Quiescence.fig',FilePrefix,StateToPlot), 'fig')


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        mnspd = nanmean(SpeedToPlot);
        strspd = nansterr(SpeedToPlot);


        SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));

        jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);

        hold on;

        plot(StResh,mnspd,'b','linewidth',2.5);
        ylabel('speed [worm-lengths / s]');
        titleStr = sprintf('%s_%s_SpeedOfQuiescentAnimals',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_6-SpeedOfQuiescentAnimals.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_6-SpeedOfQuiescentAnimals.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_6-SpeedOfQuiescentAnimals.fig',FilePrefix,StateToPlot), 'fig')


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
            saveas(gcf,      sprintf('%s_%s_4-Omega Turns Quiescence.fig',FilePrefix,StateToPlot), 'fig')
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
            saveas(gcf,      sprintf('%s_%s_5-Reversals Quiescence.fig',FilePrefix,StateToPlot), 'fig')
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
        saveas(gcf,      sprintf('%s_%s_1-Fraction Active.fig',FilePrefix,StateToPlot), 'fig')

        mnOfractWake = nanmean(OfractWake);
        OfractWakeFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnOfractWake,'m','linewidth',2.5);
        ylabel('fraction of active animals turning');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Active Turning',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_2-Fraction Turning Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_2-Fraction Turning Active.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_2-Fraction Turning Active.fig',FilePrefix,StateToPlot), 'fig')

        mnLRfractWake = nanmean(LRfractWake);
        LRfractWakeFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), -0.05, 1.05, stimuli(1:2));
        plot(StResh,mnLRfractWake,'m','linewidth',2.5);
        ylabel('fraction of active animals reversing');
        xlabel('time [s]')
        titleStr = sprintf('%s_%s_Fraction Reversing Active',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_3-Fraction Reversing Active.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_3-Fraction Reversing Active.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_3-Fraction Reversing Active.fig',FilePrefix,StateToPlot), 'fig')


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        mnspd=nanmean(SpeedToPlot);
        strspd=nansterr(SpeedToPlot);


        %SpdFigure=spdfig(spdxmax,spdymax,stimuli);

        %SpdFig=DataFig(FurtherBinTime(1), FurtherBinTime(end), 0, 0.05, stimuli(1:2));


        SpdFig=DataFig(spdxmin, spdxmax, spdymin, spdymax, stimuli(1:2));

        jbfill(StResh,mnspd+strspd,mnspd-strspd,grey,grey,0,1);

        hold on;

        plot(StResh,mnspd,'m','linewidth',2.5);
        ylabel('speed [worm-lengths / s]');
        titleStr = sprintf('%s_%s_Speed Of Active Animals',PlotTitle,StateToPlot);
        title(titleStr,'Interpreter','none');
        print (gcf, '-depsc', '-r300', sprintf('%s_%s_6-SpeedOfActiveAnimals.ai',FilePrefix,StateToPlot));
        print (gcf, '-dpdf', '-r300', sprintf('%s_%s_6-SpeedOfActiveAnimals.pdf',FilePrefix,StateToPlot));
        saveas(gcf,      sprintf('%s_%s_6-SpeedOfActiveAnimals.fig',FilePrefix,StateToPlot), 'fig')

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
        saveas(gcf,      sprintf('%s_%s_4-Omega Turns Active.fig',FilePrefix,StateToPlot), 'fig')



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
        saveas(gcf,      sprintf('%s_%s_5-Reversals Active.fig',FilePrefix,StateToPlot), 'fig')

    end
end



