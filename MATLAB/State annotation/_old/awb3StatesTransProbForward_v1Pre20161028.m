%% awb3StateTransProbForward
% This script takes forward runs and finds the 3state probabilities within
% bins of forward length
clear all

awb3States

%%
% Range where the end can be present (note that forward runs post recording
% are used)
%rangeS = [0:360,720:1080]; %in seconds
rangeS = 360:720;

tviSec = 0:1:1079;

% linear
% startS = 0:20:200;
% logon = 0;

%log
startS = round(logspace(0,2.3010,10));
logon = 1;

% %%%%%%%
for recNum = 1:NumDataSets
    iThreeStatesSec(recNum,:) = interp1(tvi,iThreeStates(recNum,:),tviSec,'nearest');
end

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
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),200);
count= 1;

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);

% !!! ADD IN: if start is within range but end is not, end at range end at
% a 3. (hard with 360-720gap....)

for recNum = 1:NumDataSets
    
    for FtransNum = 1:sum(isfinite(FtransEnd(recNum,:)));
        %only add points where the end point is within the range
        if sum(rangeS == round(FtransEnd(recNum,FtransNum))) %5fps
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
    end
end

vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);

for binNum = 1:(length(startS)-1)
    clearvars trans transDummy dummyBase
    endS = startS(binNum+1)-1;
    
    n(binNum) =sum(~isnan(ForwardPeriods(:,startS(binNum))));
    
    x = [[0,1,2,0],reshape(ForwardPeriods(:,startS(binNum):endS),1,[])];
    if sum(isnan(x))>0
        x(isnan(x)) = []; %takes away Nans which means that each F event during that period is
        % catenated. This is not a problem as I ignore R or Q into F
        % frequencies here!
    end
    
    %had to add the the 0,1,2,0 dummy at the start so all transitions would
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

%% Plot
fig = figure;
plot(startS(1,1:end-1),FQprob)
hold on
plot(startS(1,1:end-1),FRprob,'r')
hold on;
scatter(startS(1,1:end-1),FQprob,'filled','b')
hold on;
scatter(startS(1,1:end-1),FRprob,'filled','r')

if logon
    hold on;
    %ha = plotyy(startS(1,1:end-1),FQprob,startS(1,1:end-1),n,'semilogx')
    ha = plotyy(startS(1,1:end-1),FQprob,startS(1,1:end-1),n,@semilogx,@bar)
    %(1:100).*10,hist(x,100),1:length(x),x,@bar,@plot)

    ax = get(fig,'CurrentAxes');
    set(ax,'XScale','log')
    
    set(ha(1),'ylim',[0 0.8],'ytick',[0,0.025,0.05,0.075,0.1]);
    set(ha(2),'ylim',[0 55]);
    

end

%xlim([1,4])
title('FR and FQ probabilities 21%');
ylim([0,0.15])
%%
figure; plot(FFprob,'g')
xlim([1,4])
title('FF probabilities 21%');