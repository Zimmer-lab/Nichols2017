function [Oresponse1Wake,Oresponse1Sleep,LRresponse1Wake,LRresponse1Sleep] = ROSpdQuant(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,BinTrcksSR,wakestate,t,NumBins,NumTracks,BinWinSec,SBinWinSec,ConditionalBinSec1,AlsBinSec,OBasalBinSec1,OResponseBin1,LRBasalBinSec1,LRResponseBin1)

 %ConditionalBinSec1 = [1260 1560]; %[3180 3480];%[1560 1560+360]; time window in which to sort tracks into sleep vs wake
% 
 %AlsBinSec = [1260 2220]; %[3180 4140];% [1560 1560+360+360];%time window for plotting these data
% 
% grey=[0.5 0.5 0.5]; %color of boxes that indicate stimuli
% 
% spdxmax=5400; % axis scales ....only raw data plots
% spdymax=0.1;
% 
% Oxmax=5400;
% Oymax=0.04;

%FurtherBinning = 3;

% FurtherBinWinSec = BinWinSec * FurtherBinning;
% FurtherNumBins = floor(NumBins/FurtherBinning);
% FurtherBinTime = FurtherBinWinSec/2:FurtherBinWinSec:FurtherBinWinSec*FurtherNumBins;
% % TimeBinIdx=reshape(t(1:FurtherBinning*FurtherNumBins),FurtherBinning,FurtherNumBins);



% tickmarks=0:180:6*180; %tickmarks for subplots
% 
% stimuli = [1560,360,1560+360+1560,360]; %stim 1 start, stim 1 width, stim 2 start, stim 2 width ....

% OBasalBinSec1 = [1260 1560]; %[3180 3480];%[1560 1560+360];;
% OResponseBin1 = [1700 1800];
% 
% LRBasalBinSec1 = [1260 1560]; %[3180 3480];%[1560 1560+360];;
% LRResponseBin1 = [1700 1800];
% 
% OBasalBinSec2 = [1260 1560]; %[3180 3480];%[1560 1560+360];;
% OResponseBin2 = [1700 1800];
% 
% LRBasalBinSec2 = [1260 1560]; %[3180 3480];%[1560 1560+360];;
% LRResponseBin2 = [1700 1800];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



SpdSleep = NaN(NumTracks,NumBins);

SpdWake  = NaN(NumTracks,NumBins);

OSleep = NaN(NumTracks,NumBins);

OWake = NaN(NumTracks,NumBins);

LRSleep = NaN(NumTracks,NumBins);

LRWake = NaN(NumTracks,NumBins);

SRSleep = NaN(NumTracks,NumBins);

SRWake = NaN(NumTracks,NumBins);


% FollowingStateSleep = NaN(NumTracks,NumBins);
% 
% FollowingStateWake = NaN(NumTracks,NumBins);
% 
% OfractSleep = NaN(NumTracks,NumBins);
% 
% OfractWake = NaN(NumTracks,NumBins);
% 
% 
% LRfractWake = NaN(NumTracks,NumBins);
% 
% LRfractSleep = NaN(NumTracks,NumBins);





ConditionalBinFr = floor(ConditionalBinSec1 / SBinWinSec);


AlsBinFr = floor(AlsBinSec / SBinWinSec);


for i = 1:NumTracks
    
    if sum(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2)))==0
        
        SpdSleep(i,AlsBinFr(1):AlsBinFr(2)) = SBinTrcksSpdSize(i,AlsBinFr(1):AlsBinFr(2));
        
        OSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksO(i,AlsBinFr(1):AlsBinFr(2));
        
        LRSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksLR(i,AlsBinFr(1):AlsBinFr(2));
        
        SRSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksSR(i,AlsBinFr(1):AlsBinFr(2));
        
        
        
%         FollowingStateSleep(i,AlsBinFr(1):AlsBinFr(2)) = wakestate(i,AlsBinFr(1):AlsBinFr(2));
%         
%         OfractSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksOstate(i,AlsBinFr(1):AlsBinFr(2));
%         
%         LRfractSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksLRstate(i,AlsBinFr(1):AlsBinFr(2));

        
    end

    
    if sum(~(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2))==1))==0
        
        SpdWake(i,AlsBinFr(1):AlsBinFr(2)) = SBinTrcksSpdSize(i,AlsBinFr(1):AlsBinFr(2));
        
        OWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksO(i,AlsBinFr(1):AlsBinFr(2));
        
        LRWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksLR(i,AlsBinFr(1):AlsBinFr(2));
        
        SRWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksSR(i,AlsBinFr(1):AlsBinFr(2));
        
%         FollowingStateWake(i,AlsBinFr(1):AlsBinFr(2)) = wakestate(i,AlsBinFr(1):AlsBinFr(2));
%         
%         OfractWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksOstate(i,AlsBinFr(1):AlsBinFr(2));
%         
%         LRfractWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksLRstate(i,AlsBinFr(1):AlsBinFr(2));
% 


    end
        
        
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FractionAwake = nanmean(wakestate(:,SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2));
% FractAwakeFig=DataFig(0,spdxmax,0,1,stimuli); 
% plot(St(SlidingWinSizeBins/2:NumBins-SlidingWinSizeBins/2),FractionAwake,'k','linewidth',1.5);
% 
% ylabel('Fraction active');
% xlabel('time [s]');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% if  strcmp(StateToPlot,'sleep')
% 
% 
% SpeedToPlot = SpdSleep;
% Oplot=OSleep;
% LRplot=LRSleep;
% SRplot=SRSleep;
% 
% end
% 
% 
% if  strcmp(StateToPlot,'wake')
% 
% 
% SpeedToPlot = SpdWake;
% Oplot=OWake;
% LRplot=LRWake;
% SRplot=SRWake;
% 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



mnspdWake=nanmean(SpdWake);
%strspdWake=nansterr(SpdWake);

mnOWake=nanmean(OWake)/BinWinSec;
%strOWake=nansterr(OWake)/BinWinSec;

mnLRWake=nanmean(LRWake)/BinWinSec;
%strLRWake=nansterr(LRWake)/BinWinSec;

mnSRWake=nanmean(SRWake)/BinWinSec;
%strSRWake=nansterr(SRWake)/BinWinSec;



mnspdSleep=nanmean(SpdSleep);
%strspdSleep=nansterr(SpdSleep);

mnOSleep=nanmean(OSleep)/BinWinSec;
%strOSleep=nansterr(OSleep)/BinWinSec;

mnLRSleep=nanmean(LRSleep)/BinWinSec;
%strSleep=nansterr(LRSleep)/BinWinSec;

mnSRSleep=nanmean(SRSleep)/BinWinSec;
%strSRSleep=nansterr(SRSleep)/BinWinSec;

% 
% 
% SpdFigure=spdfig(spdxmax,spdymax,stimuli);
% title('Instantaneous Speed');
% jbfill(St,mnspd+strspd,mnspd-strspd,grey,grey,0,1);
% hold on;
% plot(St,mnspd,'k','linewidth',1.5);
% ylabel('speed [wormlengths / s]');
% 
% 
% OFigure=Ofig(Oxmax,Oymax,stimuli);
% title('Omega Turns');
% jbfill(t,mnO+strO,mnO-strO,grey,grey,0,1);
% hold on;
% plot(t,mnO,'k','linewidth',1.5);
% 
% LRFigure=Ofig(Oxmax,Oymax,stimuli);
% title('Large Reversals');
% jbfill(t,mnLR+strLR,mnLR-strLR,grey,grey,0,1);
% hold on;
% plot(t,mnLR,'k','linewidth',1.5);
% 
% SRFigure=Ofig(Oxmax,Oymax,stimuli);
% title('Small Reversals');
% jbfill(t,mnSR+strSR,mnSR-strSR,grey,grey,0,1);
% hold on;
% plot(t,mnSR,'k','linewidth',1.5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tOBasalBinIdx1=zeros(1,2);

tOResponseBinIdx1=zeros(1,2);

tOBasalBinIdx1(1) = find(t<=OBasalBinSec1(1),1,'last');

tOBasalBinIdx1(2) = find(t>=OBasalBinSec1(2),1,'first');

tOResponseBinIdx1(1) = find(t<=OResponseBin1(1),1,'last');

tOResponseBinIdx1(2) = find(t>=OResponseBin1(2),1,'first');



OResponseRate1Wake = nanmean(mnOWake(tOResponseBinIdx1(1):tOResponseBinIdx1(2)));

OBasalRate1Wake = nanmean(mnOWake(tOBasalBinIdx1(1):tOBasalBinIdx1(2)));

Oresponse1Wake = OResponseRate1Wake - OBasalRate1Wake; 


OResponseRate1Sleep = nanmean(mnOSleep(tOResponseBinIdx1(1):tOResponseBinIdx1(2)));

OBasalRate1Sleep = nanmean(mnOSleep(tOBasalBinIdx1(1):tOBasalBinIdx1(2)));

Oresponse1Sleep = OResponseRate1Sleep - OBasalRate1Sleep; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%

% tOBasalBinIdx2=zeros(1,2);
% 
% tOResponseBinIdx2=zeros(1,2);
% 
% tOBasalBinIdx2(1) = find(t<=OBasalBinSec2(1),1,'last');
% 
% tOBasalBinIdx2(2) = find(t>=OBasalBinSec2(2),1,'first');
% 
% tOResponseBinIdx2(1) = find(t<=OResponseBin2(1),1,'last');
% 
% tOResponseBinIdx2(2) = find(t>=OResponseBin2(2),1,'first');
% 
% 
% OResponseRate2Wake = nanmean(mnOWake(tOResponseBinIdx2(1):tOResponseBinIdx2(2)));
% 
% OBasalRate2Wake = nanmean(mnOWake(tOBasalBinIdx2(1):tOBasalBinIdx2(2)));
% 
% Oresponse2Wake = OResponseRate2Wake - OBasalRate2Wake; 
% 
% 
% OResponseRate2Sleep = nanmean(mnOSleep(tOResponseBinIdx2(1):tOResponseBinIdx2(2)));
% 
% OBasalRate2Sleep = nanmean(mnOSleep(tOBasalBinIdx2(1):tOBasalBinIdx2(2)));
% 
% Oresponse2Sleep = OResponseRate2Sleep - OBasalRate2Sleep; 

%%%%%%%%%%%%%%%%%%%%%%%%%%

tLRBasalBinIdx1=zeros(1,2);

tLRResponseBinIdx1=zeros(1,2);

tLRBasalBinIdx1(1) = find(t<=LRBasalBinSec1(1),1,'last');

tLRBasalBinIdx1(2) = find(t>=LRBasalBinSec1(2),1,'first');

tLRResponseBinIdx1(1) = find(t<=LRResponseBin1(1),1,'last');

tLRResponseBinIdx1(2) = find(t>=LRResponseBin1(2),1,'first');



LRResponseRate1Wake = nanmean(mnLRWake(tLRResponseBinIdx1(1):tLRResponseBinIdx1(2)));

LRBasalRate1Wake = nanmean(mnLRWake(tLRBasalBinIdx1(1):tLRBasalBinIdx1(2)));

LRresponse1Wake = LRResponseRate1Wake - LRBasalRate1Wake; 


LRResponseRate1Sleep = nanmean(mnLRSleep(tLRResponseBinIdx1(1):tLRResponseBinIdx1(2)));

LRBasalRate1Sleep = nanmean(mnLRSleep(tLRBasalBinIdx1(1):tLRBasalBinIdx1(2)));

LRresponse1Sleep = LRResponseRate1Sleep - LRBasalRate1Sleep; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%

% tLRBasalBinIdx2=zeros(1,2);
% 
% tLRResponseBinIdx2=zeros(1,2);
% 
% tLRBasalBinIdx2(1) = find(t<=LRBasalBinSec2(1),1,'last');
% 
% tLRBasalBinIdx2(2) = find(t>=LRBasalBinSec2(2),1,'first');
% 
% tLRResponseBinIdx2(1) = find(t<=LRResponseBin2(1),1,'last');
% 
% tLRResponseBinIdx2(2) = find(t>=LRResponseBin2(2),1,'first');
% 
% 
% LRResponseRate2Wake = nanmean(mnLRWake(tLRResponseBinIdx2(1):tLRResponseBinIdx2(2)));
% 
% LRBasalRate2Wake = nanmean(mnLRWake(tLRBasalBinIdx2(1):tLRBasalBinIdx2(2)));
% 
% LRresponse2Wake = LRResponseRate2Wake - LRBasalRate2Wake; 
% 
% 
% LRResponseRate2Sleep = nanmean(mnLRSleep(tLRResponseBinIdx2(1):tLRResponseBinIdx2(2)));
% 
% LRBasalRate2Sleep = nanmean(mnLRSleep(tLRBasalBinIdx2(1):tLRBasalBinIdx2(2)));
% 
% LRresponse2Sleep = LRResponseRate2Sleep - LRBasalRate2Sleep; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% if  strcmp(StateToPlot,'sleep')
% 
%     mnFollowingStateSleep=nanmean(FollowingStateSleep);
%     FollowStateFig=DataFig(AlsBinSec(1), AlsBinSec(2), -0.05, 1.05, stimuli(1:2));
%     plot(t,mnFollowingStateSleep,'k','linewidth',1.5);
%     ylabel('fraction exiting from quiescence');
%     xlabel('time [s]');
% 
%     mnOfractSleep = nanmean(OfractSleep);
%     OfractSleepFig=DataFig(AlsBinSec(1), AlsBinSec(2), -0.05, 1.05, stimuli(1:2));
%     plot(t,mnOfractSleep,'k','linewidth',1.5);
%     ylabel('fraction turning after quiescence');
%     xlabel('time [s]')
% 
% 
%     mnLRfractSleep = nanmean(LRfractSleep);
%     LRfractSleepFig=DataFig(AlsBinSec(1), AlsBinSec(2), -0.05, 1.05, stimuli(1:2));
%     plot(t,mnLRfractSleep,'k','linewidth',1.5);
%     ylabel('fraction reversing after quiescence');
%     xlabel('time [s]')

    
%     BinOSleep = BinTurns(FurtherBinning,OSleep);
% 
%     mnBinOSleep = nanmean(BinOSleep)/FurtherBinWinSec;
% 
%     stBinOSleep = nansterr(BinOSleep)/FurtherBinWinSec;
% 
% 
%     BinOSleepPlot=mnBinOSleep(~isnan(mnBinOSleep));
% 
%     stBinOSleepPlot=stBinOSleep(~isnan(mnBinOSleep));
% 
%     timeplot=FurtherBinTime(~isnan(mnBinOSleep));
% 
%     OFigure=Ofig(Oxmax,Oymax,stimuli);
%     xlim([timeplot(1) timeplot(end)]);
%     title('Omega Turns After Quiescence');
%     jbfill(timeplot,BinOSleepPlot+stBinOSleepPlot,BinOSleepPlot-stBinOSleepPlot,grey,grey,0,1);
%     hold on;
%     plot(timeplot,BinOSleepPlot,'k','linewidth',1.5);
%     
%     
%     BinLRSleep = BinTurns(FurtherBinning,LRSleep);
% 
%     mnBinLRSleep = nanmean(BinLRSleep)/FurtherBinWinSec;
% 
%     stBinLRSleep = nansterr(BinLRSleep)/FurtherBinWinSec;
% 
% 
%     BinLRSleepPlot=mnBinLRSleep(~isnan(mnBinLRSleep));
% 
%     stBinLRSleepPlot=stBinLRSleep(~isnan(mnBinLRSleep));
% 
%     timeplot=FurtherBinTime(~isnan(mnBinLRSleep));
%     
%     LRFigure=Ofig(Oxmax,Oymax,stimuli);
%     xlim([timeplot(1) timeplot(end)]);
%     title('Reversals After Quiescence');
%     jbfill(timeplot,BinLRSleepPlot+stBinLRSleepPlot,BinLRSleepPlot-stBinLRSleepPlot,grey,grey,0,1);
%     hold on;
%     plot(timeplot,BinLRSleepPlot,'k','linewidth',1.5);
% 
% % end
% 
% 
% 
% if  strcmp(StateToPlot,'wake')
    
%     mnFollowingStateWake = nanmean(FollowingStateWake);
%     FollowStateFig=DataFig(AlsBinSec(1), AlsBinSec(2), -0.05, 1.05, stimuli(1:2));
%     plot(t,mnFollowingStateWake,'k','linewidth',1.5);
%     ylabel('fraction active');
%     xlabel('time [s]');
% 
%     
%     mnOfractWake = nanmean(OfractWake);
%     OfractWakeFig=DataFig(AlsBinSec(1), AlsBinSec(2), -0.05, 1.05, stimuli(1:2));
%     plot(t,mnOfractWake,'k','linewidth',1.5);
%     ylabel('fraction of active animals turning');
%     xlabel('time [s]')
%     
%     mnLRfractWake = nanmean(LRfractWake);
%     LRfractWakeFig=DataFig(AlsBinSec(1), AlsBinSec(2), -0.05, 1.05, stimuli(1:2));
%     plot(t,mnLRfractWake,'k','linewidth',1.5);
%     ylabel('fraction of active animals reversing');
%     xlabel('time [s]')


%     BinOWake = BinTurns(FurtherBinning,OWake);
% 
%     mnBinOWake = nanmean(BinOWake)/FurtherBinWinSec;
% 
%     stBinOWake = nansterr(BinOWake)/FurtherBinWinSec;
% 
% 
%     BinOWakePlot=mnBinOWake(~isnan(mnBinOWake));
% 
%     stBinOWakePlot=stBinOWake(~isnan(mnBinOWake));
% 
%     timeplot=FurtherBinTime(~isnan(mnBinOWake));
% 
% 
%     OFigure=Ofig(Oxmax,Oymax,stimuli);
%     xlim([timeplot(1) timeplot(end)]);
%     title('Omega Turns After Activity');
%     jbfill(timeplot,BinOWakePlot+stBinOWakePlot,BinOWakePlot-stBinOWakePlot,grey,grey,0,1);
%     hold on;
%     plot(timeplot,BinOWakePlot,'k','linewidth',1.5);
%     
%     
%     
%     
%     BinLRWake = BinTurns(FurtherBinning,LRWake);
% 
%     mnBinLRWake = nanmean(BinLRWake)/FurtherBinWinSec;
% 
%     stBinLRWake = nansterr(BinLRWake)/FurtherBinWinSec;
% 
% 
%     BinLRWakePlot=mnBinLRWake(~isnan(mnBinLRWake));
% 
%     stBinLRWakePlot=stBinLRWake(~isnan(mnBinLRWake));
% 
%     timeplot=FurtherBinTime(~isnan(mnBinLRWake));
% 
% 
%     LRFigure=Ofig(Oxmax,Oymax,stimuli);
%     xlim([timeplot(1) timeplot(end)]);
%     title('Reversals After Activity');
%     jbfill(timeplot,BinLRWakePlot+stBinLRWakePlot,BinLRWakePlot-stBinLRWakePlot,grey,grey,0,1);
%     hold on;
%     plot(timeplot,BinLRWakePlot,'k','linewidth',1.5);
%     
% 

 end
