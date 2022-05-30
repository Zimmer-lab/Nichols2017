%% awb3StateTransFrequency
% This script takes forward runs and finds the 3state probabilities within
% bins of forward length
clear all

awb3States

%%
% only takes time points where the start was within the range and NaNs time points
% outside of the range. Adds a 0 for reversal exits and 2 for quiescent
% exits.

% range in frames (5fps interpolated) %start at 2 if you don't want to
% include foward periods that started before the recording.
range5fps = 1800:3600;
%range5fps = [2:1800,3600:5400];
%range5fps = 2:1800;
%range5fps = 3600:5400;
%range5fps = 2:5400;

% resampling
resampleN =1000000;
resampleN =10000;
resampleOn =0;

randomInput=0;

saveFlag = 0;

%%% linear
% TimeBins = 0:100:1000;
% logon = 0;

%%% log in frames (edges of bins) must start with 1 (logspace(0,....)),
%%% need to make into intergers so check below if you change it.

%TimeBins = (logspace(0,3,6));
TimeBins = [1,15,150,1500];
TimeBins = [1,50,500,2000];
TimeBins = [1,50,250,2000];
TimeBins = [1,25,250,2000];

logon = 1;


% get forward run lengths and positions
FtransStart = NaN(NumDataSets,50);
FtransLength = NaN(NumDataSets,50);
FtransEnd = NaN(NumDataSets,50);

% get reverse run lengths and positions
RtransStart = NaN(NumDataSets,50);
RtransLength = NaN(NumDataSets,50);
RtransEnd = NaN(NumDataSets,50);

for recNum = 1:NumDataSets
    forwardState = iThreeStates(recNum,1:(end-1)); %NaN at end
    forwardState(forwardState == 2) = 0;
    BW= bwlabel(forwardState);
    stats = regionprops(BW, 'BoundingBox');
    
    for FtransNum = 1:length(stats);
        FtransStart(recNum,FtransNum) = stats(FtransNum, 1).BoundingBox(1,1);
        FtransLength(recNum,FtransNum) = stats(FtransNum, 1).BoundingBox(1,3);
        
        %find run end
        FtransEnd(recNum,FtransNum) = FtransStart(recNum,FtransNum)+FtransLength(recNum,FtransNum)-0.5;
        %-0.5 adjusts for the position end compared to the values in transitionData
    end
    
    %get reversal to X transitions (so that we can find the Reversal to
    %Forward start sites.
    reverseState = iThreeStates(recNum,1:(end-1)); %NaN at end
    reverseState(reverseState == 2) = 1;
    reverseState = abs(reverseState-1);

    BW= bwlabel(reverseState);
    stats = regionprops(BW, 'BoundingBox');
    
    for RtransNum = 1:length(stats);
        RtransStart(recNum,RtransNum) = stats(RtransNum, 1).BoundingBox(1,1);
        RtransLength(recNum,RtransNum) = stats(RtransNum, 1).BoundingBox(1,3);
        
        %find run end
        RtransEnd(recNum,RtransNum) = RtransStart(recNum,RtransNum)+RtransLength(recNum,RtransNum)-0.5;
        %-0.5 adjusts for the position end compared to the values in transitionData
    end
end

clearvars recNum FtransNum stats BW forwardState RtransNum
FtransStart = FtransStart -0.5; %correct position

%FtransStart(FtransStart == 0) =-1; %correct position of Fowards starting
%at 0 (as this is not a real start!), use frame =>2 instead.

allFtransLength = reshape(FtransLength,NumDataSets*50,1);
allFtransLength(isnan(allFtransLength))=[];
%figure; hist(allFtransLength,50); %all forward periods

% Make matrix of only forward  periods
% (+1 timepoint after) states if the start falls within the range and they started from a Reversal
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),2000);
count= 1;

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);

for recNum = 1:NumDataSets
    
    for FtransNum = 1:sum(isfinite(FtransStart(recNum,:)));
        
        % adds points where the start point is within the range
        if sum(range5fps == FtransStart(recNum,FtransNum))
            %and
            % transitioned from a prior reversal state
            %Took out prior reversal: && sum(RtransEnd(recNum,:) == FtransStart(recNum,FtransNum))
            
            %gather the transition lengths and Q or R end if they end
            %within the range
            if sum(range5fps == FtransEnd(recNum,FtransNum))
                for FXtransNum = 1:nFQtrans;
                    if (transitionData.FQ{recNum, FXtransNum} == FtransEnd(recNum,FtransNum))
                        %gather the forward runs ending in a Q
                        ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),2]; %add end as either R or Q
                        count=count+1;
                    end
                end
                
                for FXtransNum = 1:nFRtrans;
                    if ceil(transitionData.FR{recNum, FXtransNum}) == FtransEnd(recNum,FtransNum);
                        %gather the forward runs ending in a R
                        ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),0]; %add end as either R or Q
                        count=count+1;
                    end
                end
                
                %%%Nan end
                %                 if 5399 == FtransEnd(recNum,FtransNum)
                %                     disp([num2str(recNum),' ',num2str(FtransNum)])
                %                     %gather the forward runs ending outside of the
                %                     %recording
                %                     ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),3];
                %                     %use 3 to mark these forward runs events ending outside the
                %                     %range
                %                     count=count+1;
                %                 end
            end
        end
        
        %%%Nan end
        %         % add points where the end point is outside the range but start
        %         % is inside. Cut off non-range end and end with 3.
        %         if (max(range5fps == FtransEnd(recNum,FtransNum)) == 0) && (sum(range5fps ==FtransStart(recNum,FtransNum)) ==1); %5fps
        %             disp(['ATN:',num2str(recNum),',',num2str(FtransNum)]);
        %             %gather the forward runs ending in outside of range and
        %             %cut off part outside range (end with a 3 to break up
        %             %the Foward states
        %             ForwardPeriods(count,1:((sum(range5fps(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))+1)) = ...
        %                 [ones(1,(sum(range5fps(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))),3]; %add end as either R or Q
        %             %use 3 to mark these forward runs events ending outside the
        %             %range
        %             count=count+1;
        %         end
    end
end

% for viewing
vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);


% Testing: generating a random input:
if randomInput
    nFPs =100000;
    ForwardPeriods = NaN(nFPs,2000);
    maxLegth = 500; %frames
    for ii =1:nFPs; %number of random events generated
        if max(ii == 1:(nFPs/2));
            randomLength = randperm(20,1);
        else
            randomLength = randperm(maxLegth,1);
        end
        randEndType = randperm(2,1);
        if randEndType == 1
            ForwardPeriods(ii,1:(randomLength+1)) = [ones(1,randomLength),0];
        elseif randEndType ==2
            ForwardPeriods(ii,1:(randomLength+1)) = [ones(1,randomLength),2];
            %         elseif randEndType ==3
            %             ForwardPeriods(ii,1:(randomLength+1)) = [ones(1,randomLength),NaN];
        end
        
    end
    disp('Turn off random ForwardPeriods generator!')
    %for viewing
    vis =single(ForwardPeriods);
    vis(isnan(ForwardPeriods))=-1;
    figure; imagesc(vis);
end

% get transitions within the bins
binStartEdge = 1; %CHECK! Needs to be below
FRtrans = [];
FQtrans = [];
FFevents = [];
totalForwardFrames =[];
eventsNumPerBin =[];

% for checking bin edges
checkingBinsTaken={};
testvector = 1:1000;
clearvars AllbinEndEdge AllbinStartEdge currPeriodAll

%bin and extract the events per bin
for binNum = 1:(length(TimeBins)-1)
    clearvars currPeriod
    
    %have to floor in order to get the binned edge integers
    binEndEdge = floor(TimeBins(binNum+1));
    
    currPeriod = ForwardPeriods(:,binStartEdge:binEndEdge);
    
    %Find number of FR events (end with a '0')
    FRtrans(binNum,1) = sum(sum(currPeriod == 0));
    
    %Find number of FQ events (end with a '2')
    FQtrans(binNum,1) = sum(sum(currPeriod == 2));
    
    %Find number of events ending with F in this bin
    FFevents(binNum,1) = sum(currPeriod(:,end) == 1);
    
    %Find number of events in this bin
    eventsNumPerBin(binNum,1) = sum(isfinite(currPeriod(:,1)));
    
    %Find total number of forward frames
    totalForwardFrames(binNum,1) = sum(sum(currPeriod == 1));
    
    %checking
    AllbinEndEdge(binNum)= binEndEdge;
    AllbinStartEdge(binNum)= binStartEdge;
    %checkingBinsTaken{binNum} = testvector(binStartEdge:binEndEdge);
    currPeriodAll{binNum} = currPeriod;
    
    binStartEdge = binEndEdge+1;
end
% figure; plot(AllbinStartEdge); hold on; plot(AllbinEndEdge)
% FXevents = FRtrans + FQtrans + FFevents;

totalForwardSeconds = totalForwardFrames/5;

totalNumEvents = sum(isfinite(ForwardPeriods(:,1)));

NumEventsEndingPerBin = abs(diff([eventsNumPerBin,;0])); %incorrect if not all events end within bins specificed.

%
% FRtransFreq = FRtrans./totalForwardSeconds;
% FQtransFreq = FQtrans./totalForwardSeconds;

% FRtransFreq = FRtrans./totalNumEvents;
% FQtransFreq = FQtrans./totalNumEvents;

FRtransFreq = FRtrans./NumEventsEndingPerBin;
FQtransFreq = FQtrans./NumEventsEndingPerBin;
%
% FRtransFreq = FRtrans./eventsNumPerBin;
% FQtransFreq = FQtrans./eventsNumPerBin;

% FRtransFreq = FRtrans./(AllbinEndEdge - AllbinStartEdge)';
% FQtransFreq = FQtrans./(AllbinEndEdge - AllbinStartEdge)';

% %Get lengths of selected ForwardPerios
% selectFtransLength = [];
% ForwardPeriodsN = sum(isfinite(ForwardPeriods(:,1)));
% for FPnum = 1:ForwardPeriodsN;
%     selectFtransLength(FPnum,1) = sum(isfinite(ForwardPeriods(FPnum,:)));
% end
% [nelements,xvals] = hist(selectFtransLength,5);
% 
% figure; hist(selectFtransLength,50);
% title('Histogram of selected Forward period lengths')
% ylabel('event number')

figure;
set(gca,'fontsize',18)
hist((nansum(ForwardPeriods')/5),1.25:2.5:161.25)
xlim([0,165]); ylim([0,60])
title('forward period length distributions','fontsize',18);
xlabel('Forward period duration (seconds)','fontsize',18)
ylabel('Event end number','fontsize',18)

if resampleOn
    [eventsAboveTrueDis,rasampledDistance,trueDistance,pValue] = permuteTSTransFrequency(NumEventsEndingPerBin,FRtrans,FQtrans,resampleN);
end

%%%%%%%%%%%%%%%%
% Plotting below:

yLmax = 1;
TimeBinsSec = TimeBins/5;

% Find middle of bins (!not exact as on log scale) for plotting
% TimeBinsMiddleS = TimeBinsSec+(TimeBinsSec(2)/2);

% TimeBinsMiddleS = interp1(1:length(TimeBinsSec),TimeBinsSec,1:0.5:length(TimeBinsSec));
% TimeBinsMiddleS = TimeBinsMiddleS(2:2:length(TimeBinsMiddleS));

ColorOrder2=[0.5 0.5 1;1 0.5 0.5];

figure;
set(gca,'fontsize',18)
if logon
    bar(log10(TimeBins(1:(end-1))/5),[FQtrans,FRtrans],'stacked') %should be +5 but +6 fits better... weird axes
    %set(axesB(2),'ylim',[0 max(FRtrans + FQtrans)])
    ylim([0,100]); xlim([min(log10(TimeBins(1:(end-1))/5))-0.5,max(log10(TimeBins(1:(end-1))/5))+0.5])
    set(gca,'Xtick',log10(TimeBins(1:(end-1))/5)); %// adjust manually; values in log scale
    set(gca,'Xticklabel',10.^get(gca,'Xtick')); %// use labels with linear values
    colormap(ColorOrder2)
    ylabel('Event end number','fontsize',18)
    
%     figure;
%     xdata = [0.01 0.018 0.032 0.056 0.1 0.18 0.32 0.56 1 1.8 3.2 5.6 10];
%     ydata = [1.3 1.6 1.5 1.2 1.0 3.5 0.6 3.1 1.6 1.9 1.7 0.3 0.4];
%     bar(log10(xdata),ydata);
%     set(gca,'Xtick',-3:1); %// adjust manually; values in log scale
% 	set(gca,'Xticklabel',10.^get(gca,'Xtick')); %// use labels with linear values
    set(gca,'Position',[0.2 0.2 0.18 0.3])
    ax1 = gca;
    ax2 = axes('Position',get(ax1,'Position'),...
        'XAxisLocation','top',...
        'YAxisLocation','right',...
        'Color','none',...
        'XColor','b','YColor','b');
    set(gca,'fontsize',18)
    set(gca,'Position',[0.2 0.2 0.18 0.3])
    
    %axesB = plotyy(TimeBins(1:(end-1)),FQtransFreq,1,max(FRtrans + FQtrans));
    hold on
    plot(log10(TimeBins(1:(end-1))/5),FRtransFreq,'r','LineWidth',2,'Parent',ax2); hold on;
    plot(log10(TimeBins(1:(end-1))/5),FQtransFreq,'b','LineWidth',2,'Parent',ax2); hold on;
    scatter(log10(TimeBins(1:(end-1))/5),FQtransFreq,40,'filled','b','Parent',ax2); hold on;
    scatter(log10(TimeBins(1:(end-1))/5),FRtransFreq,40,'filled','r','Parent',ax2); hold on
    set(gca,'Xtick',log10(TimeBins(1:(end-1))/5)); %// adjust manually; values in log scale
    set(gca,'Xticklabel',10.^get(gca,'Xtick')); %// use labels with linear values    
    xlim([min(log10(TimeBins(1:(end-1))/5))-0.5,max(log10(TimeBins(1:(end-1))/5))+0.5])
    ylim([0,1])
    ylabel('End type probability','fontsize',18)
    title('stacked bar plot of Reversal and quiescence events');
else
    bar(TimeBins(1:(end-1)),[FQtrans,FRtrans],'stacked')
    ylim([0,62]); xlim([-50,850])
    colormap(ColorOrder2)
    ylabel('Event end number','fontsize',18)
    
    ax1 = gca;
    ax2 = axes('Position',get(ax1,'Position'),...
        'XAxisLocation','top',...
        'YAxisLocation','right',...
        'Color','none',...
        'XColor','b','YColor','b');
    set(gca,'fontsize',18)
    hold on
    plot(TimeBins(1:(end-1)),FRtransFreq,'r','LineWidth',2,'Parent',ax2); hold on;
    plot(TimeBins(1:(end-1)),FQtransFreq,'b','LineWidth',2,'Parent',ax2); hold on;
    scatter(TimeBins(1:(end-1)),FQtransFreq,40,'filled','b','Parent',ax2); hold on;
    scatter(TimeBins(1:(end-1)),FRtransFreq,40,'filled','r','Parent',ax2); hold on
    xlim([-50,850]); ylim([0,1])
    ylabel('End type probability','fontsize',18)
    title('stacked bar plot of Reversal and quiescence events');
end

if saveFlag
    %set(gca,'Position',[0.2 0.2 0.18 0.3])
    set(gcf,'PaperPositionMode','auto')
    print(gcf,'ForwardTransProb10pc_log3bin_normal.ai','-r300','-depsc')
end

%%
fig = figure;

% making histograms (check against green line)
fakeVector = [];
for ii =1:length(eventsNumPerBin)
    fakeVector((length(fakeVector)+1):((length(fakeVector)+1)+eventsNumPerBin(ii)),1) = TimeBinsSec(ii);
end

hold on
[nelements,xcenters] = hist(fakeVector,TimeBinsSec);
bar(xcenters,nelements*(yLmax/(max(eventsNumPerBin)+6)),'histc') %should be +5 but +6 fits better... weird axes

%plot frequencies
hold on
plot(TimeBinsMiddleS,FRtransFreq,'r')
hold on;
scatter(TimeBinsMiddleS,FQtransFreq,20,'filled','g')
hold on;
scatter(TimeBinsMiddleS,FRtransFreq,20,'filled','r')


if logon
    hold on;
    %Create second Y axes1 on the right.
    axesB = plotyy(TimeBinsMiddleS,FQtransFreq,TimeBinsSec(1,1:(end-1)),eventsNumPerBin,'semilogx');
    
    ax = get(gcf,'CurrentAxes');
    set(ax,'XScale','log')
    
    hold on
    set(axesB(1),'ylim',[0 yLmax])
    %set(axes1(1),'ylim',[0 yLmax],'ytick',yyAxisLabels,'FontSize',14, 'YColor', 'k');
    set(axesB(2),'ylim',[0 (max(eventsNumPerBin)+5)],'ytick',[0,25,50,75,100,125],'FontSize',14);
    ylabel('Probability/s','FontSize',14)
    set(get(axesB(2), 'Ylabel'), 'String', 'Number of events','FontSize',14);
    xlabel('Time in Forward (s)')
    
    set(axesB(1),'xlim',[-10,700],'xtick',[10^0,10^1,10^2,10^3],'FontSize',14);
    set(axesB(2),'xlim',[-10,700]);
else
    hold on
    
    axesB = plotyy(TimeBinsMiddleS,FQtransFreq,TimeBinsSec(1,1:(end-1)),eventsNumPerBin);
    
    hold on
    set(axesB(1),'ylim',[0 yLmax])
    set(axesB(2),'ylim',[0 (max(eventsNumPerBin)+5)],'ytick',[0,25,50,75,100,125],'FontSize',14);
    ylabel('Probability/s','FontSize',14)
    set(get(axesB(2), 'Ylabel'), 'String', 'Number of events','FontSize',14);
    xlabel('Time in Forward (s)')
    
    set(axesB(1),'FontSize',14);
    %set(axes1(2),'xlim',[-10,700]);
end

title('FR and FQ frequencies 10%','FontSize',14);

if saveFlag
    set(gca,'Position',[0.2 0.2 0.18 0.3])
    set(fig,'PaperPositionMode','auto')
    %print(fig,'ForwardTransProb10pc_hist.ai','-r300','-depsc')
end

% Cumsum of events
figure;
plot(TimeBins(1:(end-1)),cumsum(FRtrans./totalNumEvents),'r')
hold on;
plot(TimeBins(1:(end-1)),cumsum(FQtrans./totalNumEvents))
ylim([0,1])
title('cumsum of Reversal and quiescence ends');

figure;
bar(TimeBins(1:(end-1)),[cumsum(FQtrans./totalNumEvents),cumsum(FRtrans./totalNumEvents)],'stacked') %should be +5 but +6 fits better... weird axes
ylim([0,1])
title('cumsum of Reversal and quiescence ends as a stacked bar plot');

% FRtransFreq = FRtrans./totalNumEvents;
% FQtransFreq = FQtrans./totalNumEvents;
