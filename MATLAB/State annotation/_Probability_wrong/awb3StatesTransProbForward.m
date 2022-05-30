%% awb3StateTransProbForward
% This script takes forward runs and finds the 3state probabilities within
% bins of forward length
clear all

awb3States

%%
% Range where the end can be present
% note that forward runs that start in the desired range but then end
% outside of this range are also included but they have no transition.

% rangeS = [0:360,720:1080]; %in seconds
% %rangeS = 360:720;

%%% range in frames (5fps interpolated)
%range5fps = [1800:3600];
range5fps = [0:1800,3600:5400];

saveFlag = 0;
randomInput=1;

%%% linear
TimeBins = 0:20:200;
logon = 0;

%%% log in frames (edges of bins) must start with 1 (logspace(0,....)),
%%% need to make into intergers so check below if you change it.
%TimeBins = (logspace(0,3,10));

TimeBins = (logspace(0,3,6));
logon = 1;

% %%% log in seconds (edges of bins)
% TimeBins = (logspace(0,2.3010,10)); %round
% logon = 1;


% %%%%%%%
%tviSec = 0:1:1079;

% Find middle of bins
TimeBinsMiddle = interp1(1:length(TimeBins),TimeBins,1:0.5:length(TimeBins));
TimeBinsMiddle = TimeBinsMiddle(2:2:length(TimeBinsMiddle));

% get forward run lengths and positions
FtransStart = NaN(NumDataSets,50);
FtransLength = NaN(NumDataSets,50);
FtransEnd = NaN(NumDataSets,50);

for recNum = 1:NumDataSets
    clearvars stats
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
end

FtransStart = FtransStart -0.5; %correct position
allFtransLength = reshape(FtransLength,NumDataSets*50,1);
%allFtransLength(isnan(allFtransLength))=[];
%figure; hist(allFtransLength,25);

% Make matrix of only forward (+1 timepoint after) states if the start and end falls within the range
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),2000);
count= 1;

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);

for recNum = 1:NumDataSets
    
    for FtransNum = 1:sum(isfinite(FtransStart(recNum,:)));
        
        % adds points where the end point is within the range
        if sum(range5fps == FtransStart(recNum,FtransNum))
            %disp(['started ',num2str(recNum),' ',num2str(FtransNum)])
            
            %gather the transition lengths and Q or R end if they end
            %within the range
            if sum(range5fps == FtransEnd(recNum,FtransNum))
                %disp(['ended ',num2str(recNum),' ',num2str(FtransNum)])
                
                lengthCurrTransSec = ceil(FtransLength(recNum,FtransNum)/5);
                
                for FXtransNum = 1:nFQtrans;
                    if ceil(transitionData.FQ{recNum, FXtransNum}) == FtransEnd(recNum,FtransNum)
                        %gather the forward runs ending in a Q
                        ForwardPeriods(count,1:(lengthCurrTransSec+1)) = [ones(1,lengthCurrTransSec),2]; %add end as either R or Q
                        count=count+1;
                    end
                end
                
                for FXtransNum = 1:nFRtrans;
                    if ceil(transitionData.FR{recNum, FXtransNum}) == FtransEnd(recNum,FtransNum);
                        %gather the forward runs ending in a R
                        ForwardPeriods(count,1:(lengthCurrTransSec+1)) = [ones(1,lengthCurrTransSec),0]; %add end as either R or Q
                        count=count+1;
                    end
                end
                
                %                 if 5399 == FtransEnd(recNum,FtransNum)
                %                     disp([num2str(recNum),' ',num2str(FtransNum)])
                %                     %gather the forward runs ending outside of the
                %                     %recording
                %                     ForwardPeriods(count,1:(lengthCurrTransSec+1)) = [ones(1,lengthCurrTransSec),3];
                %                     %use 3 so that these forward runs won't be contatenated to
                %                     %others
                %                     count=count+1;
                %                 end
            end
        end
        
        %         % add points where the end point is outside the range but start
        %         % is inside. Cut off non-range end and end with 3.
        %         if max(range5fps == FtransEnd(recNum,FtransNum)) == 0 && sum(range5fps ==FtransStart(recNum,FtransNum)) ==1; %5fps
        %             disp(['ATN:',num2str(recNum),',',num2str(FtransNum)]);
        %             %gather the forward runs ending in outside of range and
        %             %cut off part outside range (end with a 3 to break up
        %             %the Foward states
        %
        %             %%%!!!! CORRECT INTO SECONDS!!!!!!!!!!
        %             ForwardPeriods(count,1:((sum(range5fps(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))+1)) = ...
        %                 [ones(1,(sum(range5fps(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))),3]; %add end as neither R or Q
        %             %use 3 so that these forward runs won't be contatenated to
        %             %others
        %             count=count+1;
        %         end
        
        
    end
end

%for viewing
vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);

% Testing: generating a random input:
if randomInput
    ForwardPeriods = NaN(100000,2000);
    maxLegth = 500; %frames
    for ii =1:100000; %number of random events generated
        randomLength = randperm(maxLegth,1);
        randEndType = randperm(3,1);
        if randEndType == 1
            ForwardPeriods(ii,1:(randomLength+1)) = [ones(1,randomLength),0];
        elseif randEndType ==2
            ForwardPeriods(ii,1:(randomLength+1)) = [ones(1,randomLength),NaN];
        elseif randEndType ==3
            ForwardPeriods(ii,1:(randomLength+1)) = [ones(1,randomLength),2];
        end
        
    end
    disp('Turn off random ForwardPeriods generator!')
    %for viewing
    vis =single(ForwardPeriods);
    vis(isnan(ForwardPeriods))=-1;
    figure; imagesc(vis);
end


%% get transitions within the bins
binStartEdge = 1; %has to start with 1sec as that is the minimum bout length
eventsNumPerBin= []; 

for binNum = 1:(length(TimeBins)-1)
    clearvars trans transDummy dummyBase
    binEndEdge = floor(TimeBins(binNum+1));
    
    eventsNumPerBin(binNum) =sum(~isnan(ForwardPeriods(:,binStartEdge)));
    
    x = [[0,1,2,0],reshape(ForwardPeriods(:,binStartEdge:binEndEdge),1,[])];
    if sum(isnan(x))>0
        x(isnan(x)) = []; %takes away Nans which means that each F event during that period is
        % concatenated. This is not a problem as I ignore R or Q into F
        % frequencies here!
    end
    
    %had to add the the 0,1,2,0 dummy at the start so all transitions within FQR would
    %be looked at.
    if length(x)>4
        % make transition matrix
        transDummy = full(sparse(x(1:end-1)+1, x(2:end)+1, 1));
        
        % take away dummy transitions
        if x(5) == 0
            dummyBase = [1,1,0;0,0,1;1,0,0];
        elseif x(5) == 1
            dummyBase = [0,2,0;0,0,1;1,0,0];
        elseif x(5) == 2
            dummyBase = [0,1,1;0,0,1;1,0,0];
        end
        %this only takes 0,1,2 transitions (takes out the 3 used to include
        %the forward runs that finish after the recording
        trans = transDummy(1:3,1:3) - dummyBase;
        TransProbData{binNum} = bsxfun(@rdivide, trans, sum(trans,2));
    else
        TransProbData{binNum} = nan(3,3);
    end
    %checking
    AllbinEndEdge(binNum)= binEndEdge;
    AllbinStartEdge(binNum)= binStartEdge;
    
    binStartEdge = binEndEdge+1;
end

% Getting out data across recordings for Prism.
clearvars FRprob FQprob FFprob
for binNum =1:(length(TimeBins)-1)
    FRprob(binNum) = TransProbData{binNum}(2,1,:);
    FQprob(binNum) = TransProbData{binNum}(2,3,:);
    FFprob(binNum) = TransProbData{binNum}(2,2,:);
end

%replace NaNs with zeros
FRprob(isnan(FRprob)) = 0;
FQprob(isnan(FQprob)) = 0;
FFprob(isnan(FFprob)) = 0;

%find the number of events ending in each bin.
nPerBin = abs(diff(eventsNumPerBin));

% Plot
%Let
yLmax = 0.12;
yyAxisLabels = [0,0.05,0.1,0.15,0.2];

% %Prelet
% yLmax = 0.33;
% yyAxisLabels = [0,0.1,0.2,0.3,0.4,];

yLmax = 0.05


fig = figure;

fakeVector = [];
for ii =1:length(eventsNumPerBin)
    fakeVector((length(fakeVector)+1):((length(fakeVector)+1)+eventsNumPerBin(ii)),1) = TimeBins(ii);
end

hold on
[nelements,xcenters] = hist(fakeVector,TimeBins);
bar(xcenters,nelements*(yLmax/(max(eventsNumPerBin)+6)),'histc') %should be +5 but +6 fits better... weird axes
hold on
plot(TimeBinsMiddle,FRprob,'r')
hold on;
scatter(TimeBinsMiddle,FQprob,12,'filled','b')
hold on;
scatter(TimeBinsMiddle,FRprob,12,'filled','r')

if logon
    hold on;
    %     % Plot function.
    % % Create second Y axes1 on the right.
    axes1 = plotyy(TimeBinsMiddle,FQprob,TimeBins(1,1:(end-1)),eventsNumPerBin,'semilogx');
    
    ax = get(gcf,'CurrentAxes');
    set(ax,'XScale','log')
    
    hold on
    set(axes1(1),'ylim',[0 yLmax],'ytick',yyAxisLabels,'FontSize',14, 'YColor', 'k');
    set(axes1(2),'ylim',[0 (max(eventsNumPerBin)+5)],'ytick',[0,25,50,75,100],'FontSize',14);
    ylabel('Probability/s','FontSize',14)
    set(get(axes1(2), 'Ylabel'), 'String', 'Number of events','FontSize',14);
    xlabel('Time in Forward (s)')
    set(axes1(1),'xlim',[1,10000],'xtick',[10^0,10^1,10^2,10^3],'FontSize',14);
    set(axes1(2),'xlim',[1,10000],'xtick',[10^0,10^1,10^2,10^3],'FontSize',14);
else
    hold on
    
    axes1 = plotyy(TimeBinsMiddle,FQprob,TimeBins(1,1:(end-1)),eventsNumPerBin);
    
    hold on
    set(axes1(1),'ylim',[0 yLmax])
    set(axes1(2),'ylim',[0 (max(eventsNumPerBin)+5)],'ytick',[0,25,50,75,100,125],'FontSize',14);
    ylabel('Probability/s','FontSize',14)
    set(get(axes1(2), 'Ylabel'), 'String', 'Number of events','FontSize',14);
    xlabel('Time in Forward (s)')
    
    set(axes1(1),'FontSize',14);
    %set(axes1(2),'xlim',[-10,700]);
end


title('FR and FQ probabilities 10%','FontSize',14);


if saveFlag
    set(gca,'Position',[0.2 0.2 0.18 0.3])

    set(fig,'PaperPositionMode','auto')
    print(fig,'ForwardTransProb10pc_hist.ai','-r300','-depsc')
end


% figure; plot(FFprob,'g')
% xlim([1,4])
% title('FF probabilities 21%');


