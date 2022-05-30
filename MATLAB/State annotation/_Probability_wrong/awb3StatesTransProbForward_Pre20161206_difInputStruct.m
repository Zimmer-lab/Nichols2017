%% awb3StateTransProbForward
% This script takes forward runs and finds the 3state probabilities within
% bins of forward length
clear all

awb3States

%%
% Range where the end can be present 
% note that forward runs that start in the desired range but then end
% outside of this range are also included but they have no transition.

rangeS = [0:360,720:1080]; %in seconds
%rangeS = 360:720;

tviSec = 0:1:1079;

saveFlag = 1;

%%% linear
% startS = 0:20:200;
% logon = 0;

%%% log in seconds (edges of bins)
startS = (logspace(0,2.3010,10)); %round
logon = 1;


% %%%%%%%
for recNum = 1:NumDataSets
    iThreeStatesSec(recNum,:) = interp1(tvi,iThreeStates(recNum,:),tviSec,'nearest');
end

% Find middle of bins
startSMiddle = interp1(1:length(startS),startS,1:0.5:length(startS));
startSMiddle = startSMiddle(2:2:length(startSMiddle));
      
% range in frames (5fps interpolated)
range5fps = round(rangeS*5);

% get forward run lengths and positions
FtransStart = NaN(NumDataSets,50);
FtransLength = NaN(NumDataSets,50);
FtransEnd = NaN(NumDataSets,50);

for recNum = 1:NumDataSets
    clearvars stats
    forwardState = iThreeStatesSec(recNum,:);
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

% Make matrix of only forward (+1 timepoint after) states if the start falls within the range
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),2000);
count= 1;

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);

for recNum = 1:NumDataSets
    
    for FtransNum = 1:sum(isfinite(FtransEnd(recNum,:)));
        
        % adds points where the end point is within the range
        if sum(rangeS == FtransEnd(recNum,FtransNum))
            %gather the transition lengths if they are of the correct
            %transition type
            for FXtransNum = 1:nFQtrans;
                if ceil(transitionData.FQ{recNum, FXtransNum}/5) == FtransEnd(recNum,FtransNum)
                    %gather the forward runs ending in a Q
                    ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),2]; %add end as either R or Q
                    count=count+1;
                end
            end
            
            for FXtransNum = 1:nFRtrans;
                if ceil(transitionData.FR{recNum, FXtransNum}/5) == FtransEnd(recNum,FtransNum);
                    %gather the forward runs ending in a R
                    ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),0]; %add end as either R or Q
                    count=count+1;
                end
            end
            
            if 1080 == FtransEnd(recNum,FtransNum)
                disp([num2str(recNum),' ',num2str(FtransNum)])
                %gather the forward runs ending outside of the
                %recording
                ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),3];
                %use 3 so that these forward runs won't be contatenated to
                %others
                count=count+1;
            end
        end
        
        % add points where the end point is outside the range but start
        % is inside. Cut off non-range end and end with 3.
        if max(rangeS == FtransEnd(recNum,FtransNum)) == 0 && sum(rangeS ==FtransStart(recNum,FtransNum)) ==1; %5fps
            disp(['ATN:',num2str(recNum),',',num2str(FtransNum)]);
            %gather the forward runs ending in outside of range and
            %cut off part outside range (end with a 3 to break up
            %the Foward states
            ForwardPeriods(count,1:((sum(rangeS(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))+1)) = ...
                [ones(1,(sum(rangeS(end) >= FtransStart(recNum,FtransNum):FtransEnd(recNum,FtransNum)))),3]; %add end as either R or Q
            %use 3 so that these forward runs won't be contatenated to
            %others
            count=count+1;
        end
    end
end

%for viewing
vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);

% get transitions within the bins
binStartEdge = 1; %has to start with 1sec as that is the minimum bout length

for binNum = 1:(length(startS)-1)
    clearvars trans transDummy dummyBase
    binEndEdge = floor(startS(binNum+1));
    
    n(binNum) =sum(~isnan(ForwardPeriods(:,binStartEdge)));
    
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
for binNum =1:(length(startS)-1)
    FRprob(binNum) = TransProbData{binNum}(2,1,:);
    FQprob(binNum) = TransProbData{binNum}(2,3,:);
    FFprob(binNum) = TransProbData{binNum}(2,2,:);
end

%replace NaNs with zeros
FRprob(isnan(FRprob)) = 0;
FQprob(isnan(FQprob)) = 0;
FFprob(isnan(FFprob)) = 0;

%find the number of events ending in each bin.
nPerBin = abs(diff(n));

%Plot
%Let
yLmax = 0.12; 
yyAxisLabels = [0,0.05,0.1,0.15,0.2];

% %Prelet
% yLmax = 0.33;
% yyAxisLabels = [0,0.1,0.2,0.3,0.4,];

fig = figure;

fakeVector = [];
for ii =1:length(n)
    fakeVector((length(fakeVector)+1):((length(fakeVector)+1)+n(ii)),1) = startS(ii);
end

hold on
[nelements,xcenters] = hist(fakeVector,startS);
bar(xcenters,nelements*(yLmax/(max(n)+6)),'histc') %should be +5 but +6 fits better... weird axes
hold on
plot(startSMiddle,FRprob,'r')
hold on;
scatter(startSMiddle,FQprob,12,'filled','b')
hold on;
scatter(startSMiddle,FRprob,12,'filled','r')

if logon
    hold on;
    %     % Plot function.
% % Create second Y axes1 on the right.
    axes1 = plotyy(startSMiddle,FQprob,startS(1,1:(end-1)),n,'semilogx');   
  
    ax = get(gcf,'CurrentAxes');
    set(ax,'XScale','log')
    
    hold on 
    set(axes1(1),'ylim',[0 yLmax],'ytick',yyAxisLabels,'FontSize',14, 'YColor', 'k'); 
    set(axes1(2),'ylim',[0 (max(n)+5)],'ytick',[0,25,50,75,100],'FontSize',14);    
    ylabel('Probability/s','FontSize',14)
    set(get(axes1(2), 'Ylabel'), 'String', 'Number of events','FontSize',14);
    xlabel('Time in Forward (s)')
    
end

set(axes1(1),'xlim',[1,200],'xtick',[10^0,10^1,10^2,10^3],'FontSize',14);
set(axes1(2),'xlim',[1,200],'xtick',[10^0,10^1,10^2,10^3],'FontSize',14);
title('FR and FQ probabilities 10%','FontSize',14);

set(gca,'Position',[0.2 0.2 0.18 0.3])

if saveFlag
    set(fig,'PaperPositionMode','auto')
    print(fig,'ForwardTransProb10pc_hist.ai','-r300','-depsc')
end

%%
figure; plot(FFprob,'g')
xlim([1,4])
title('FF probabilities 21%');


