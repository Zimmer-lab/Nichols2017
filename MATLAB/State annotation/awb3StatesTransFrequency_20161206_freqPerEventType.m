%% awb3StateTransProbForward
% This script takes forward runs and finds the 3state probabilities within
% bins of forward length
clear all

awb3States

%%
% only takes time points where the start was within the range and NaNs time points
% outside of the range. Adds a 0 for reversal exits and 2 for quiescent
% exits.

% range in frames (5fps interpolated)
%range5fps = [1800:3600];
range5fps = [0:1800,3600:5400];

saveFlag = 0;

%%% linear
% startS = 0:20:200;
% logon = 0;

%%% log in frames (edges of bins) must start with 1 (logspace(0,....)),
%%% need to make into intergers so check below if you change it.
%TimeBins = (logspace(0,3,10));

TimeBins = (logspace(0,3,6));

logon = 1;


% get forward run lengths and positions
FtransStart = NaN(NumDataSets,50);
FtransLength = NaN(NumDataSets,50);
FtransEnd = NaN(NumDataSets,50);

for recNum = 1:NumDataSets
    clearvars stats
    forwardState = iThreeStates(recNum,:);
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
end
FtransStart = FtransStart -0.5; %correct position
allFtransLength = reshape(FtransLength,NumDataSets*50,1);
% allFtransLength(isnan(allFtransLength))=[];
% figure; hist(allFtransLength,50);

% Make matrix of only forward (+1 timepoint after) states if the start falls within the range
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),2000);
count= 1;

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);


for recNum = 1:NumDataSets
    
    for FtransNum = 1:sum(isfinite(FtransStart(recNum,:)));
        
        % adds points where the start point is within the range
        if sum(range5fps == FtransStart(recNum,FtransNum))
            
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
                
                if 5400 == FtransEnd(recNum,FtransNum)
                    disp([num2str(recNum),' ',num2str(FtransNum)])
                    %gather the forward runs ending outside of the
                    %recording
                    ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),3];
                    %use 3 to mark these forward runs events ending outside the
                    %range
                    count=count+1;
                end
            end            
        end
        
        % add points where the end point is outside the range but start
        % is inside. Cut off non-range end and end with 3.
        if (max(range5fps == FtransEnd(recNum,FtransNum)) == 0) && (sum(range5fps ==FtransStart(recNum,FtransNum)) ==1); %5fps
            disp(['ATN:',num2str(recNum),',',num2str(FtransNum)]);
            %gather the forward runs ending in outside of range and
            %cut off part outside range (end with a 3 to break up
            %the Foward states
            ForwardPeriods(count,1:((sum(range5fps(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))+1)) = ...
                [ones(1,(sum(range5fps(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))),3]; %add end as either R or Q
            %use 3 to mark these forward runs events ending outside the
            %range
            count=count+1;
        end
    end
end

%for viewing
vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);

% get transitions within the bins
binStartEdge = 1; %CHECK! Needs to be below
FRtrans = [];
FQtrans = [];
FFevents = [];

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
        
    %checking
    AllbinEndEdge(binNum)= binEndEdge;
    AllbinStartEdge(binNum)= binStartEdge;
    %checkingBinsTaken{binNum} = testvector(binStartEdge:binEndEdge);
    currPeriodAll{binNum} = currPeriod;
    
    binStartEdge = binEndEdge+1;
end
%figure; plot(AllbinStartEdge); hold on; plot(AllbinEndEdge)

FXevents = FRtrans + FQtrans + FFevents;

FRtransFreq = FRtrans./FXevents;
FQtransFreq = FQtrans./FXevents;


% Plotting below:

yLmax = 1;

TimeBinsSec = TimeBins/5;

% Find middle of bins (!not exact as on log scale) for plotting
TimeBinsMiddleS = interp1(1:length(TimeBinsSec),TimeBinsSec,1:0.5:length(TimeBinsSec));
TimeBinsMiddleS = TimeBinsMiddleS(2:2:length(TimeBinsMiddleS));

fig = figure;

% making histograms (check against green line)
fakeVector = [];
for ii =1:length(FXevents)
    fakeVector((length(fakeVector)+1):((length(fakeVector)+1)+FXevents(ii)),1) = TimeBinsSec(ii);
end

hold on
[nelements,xcenters] = hist(fakeVector,TimeBinsSec);
bar(xcenters,nelements*(yLmax/(max(FXevents)+6)),'histc') %should be +5 but +6 fits better... weird axes

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
    axes1 = plotyy(TimeBinsMiddleS,FQtransFreq,TimeBinsSec(1,1:(end-1)),FXevents,'semilogx');   
  
    ax = get(gcf,'CurrentAxes');
    set(ax,'XScale','log')
    
    hold on 
    set(axes1(1),'ylim',[0 yLmax])
    %set(axes1(1),'ylim',[0 yLmax],'ytick',yyAxisLabels,'FontSize',14, 'YColor', 'k'); 
    set(axes1(2),'ylim',[0 (max(FXevents)+5)],'ytick',[0,25,50,75,100,125],'FontSize',14);    
    ylabel('Probability','FontSize',14)
    set(get(axes1(2), 'Ylabel'), 'String', 'Number of events','FontSize',14);
    xlabel('Time in Forward (s)')
    
end

set(axes1(1),'xlim',[-10,700],'xtick',[10^0,10^1,10^2,10^3],'FontSize',14);
set(axes1(2),'xlim',[-10,700]);
title('FR and FQ frequencies 10%','FontSize',14);

set(gca,'Position',[0.2 0.2 0.18 0.3])

if saveFlag
    set(fig,'PaperPositionMode','auto')
    print(fig,'ForwardTransProb10pc_hist.ai','-r300','-depsc')
end

