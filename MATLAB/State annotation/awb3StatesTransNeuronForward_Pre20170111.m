%% awb3StateTransNeuronForward
% This script takes forward runs and finds the Neuron activity over those
% periods
clear all

awb3States

%% Get neuron traces (interpolated)
Neurons = {'RIS','RMED','RMEV','RIBL','RIBR','AVBL','AVBR','VB02'};
Neurons = {'RIS'};

% 'RMEL','RMER'

%time vector intrapolated
tvi = ((0:5399)/5)';
tviF = ((0:5399))';

FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);
MainDir = pwd;

%Preallocate
for neuNum =1:length(Neurons);
    iNeurons.(Neurons{neuNum}) = NaN(NumDataSets,length(tvi));
end

for recNum = 1:NumDataSets %Folder loop
    cd(FolderList{recNum});
    wbload;
    tvo =wbstruct.tv; %time vector original
    
    for neuNum =1:length(Neurons);
        Trace = wbgettrace(Neurons{neuNum})';
        if ~isnan(Trace)
            iNeurons.(Neurons{neuNum})(recNum,:) = interp1(tvo,Trace,tvi);
        end
    end
    cd(MainDir)
end

%%
% only takes time points where the start was within the range and NaNs time points
% outside of the range. Adds a 0 for reversal exits and 2 for quiescent
% exits.

% range in frames (5fps interpolated) %start at 2 if you don't want to
% include foward periods that started before the recording.
range5fps = 1800:3600;
range5fps = [2:1800,3600:5400];
%range5fps = 2:1800;
%range5fps = 3600:5400;
%range5fps = 2:5400;

saveFlag = 0;

%%% linear
% TimeBins = 0:100:1000;
% logon = 0;

%%% log in frames (edges of bins) must start with 1 (logspace(0,....)),
%%% need to make into intergers so check below if you change it.
TimeBins = [1,15,150,1500];

logon = 1;
IncludeRQTransitions = 1;

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

% FtransStart(FtransStart == 0) =-1; %correct position of Fowards starting
%at 0 (as this is not a real start!), use frame =>2 instead.

allFtransLength = reshape(FtransLength,NumDataSets*50,1);
allFtransLength(isnan(allFtransLength))=[];
%figure; hist(allFtransLength,50); %all forward periods

% Make matrix of only forward  periods
% (+1 timepoint after) states if the start falls within the range and they started from a Reversal
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),2000);
count= 1;

%%

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);
[~,nRQtrans] = size(transitionData.RQ);

gatheredQRend = NaN(NumDataSets,20);
gatheredStart = [];
gatheredEnd =[];
gatheredQRend = [];

for recNum = 1:NumDataSets
    countG =1;
    for FtransNum = 1:sum(isfinite(FtransEnd(recNum,:)));
        
        % adds points where the start point is within the range
        if sum(range5fps == FtransStart(recNum,FtransNum))
            %and
            % transitioned from a prior reversal state
            %Took out prior reversal: && sum(RtransEnd(recNum,:) == FtransStart(recNum,FtransNum))
            
            %gather the transition lengths if they are of the correct
            %transition type
            if sum(range5fps == FtransEnd(recNum,FtransNum))
                for FXtransNum = 1:nFQtrans;
                    if (transitionData.FQ{recNum, FXtransNum} == FtransEnd(recNum,FtransNum))
                        %gather the forward runs ending in a Q
                        ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),2]; %add end as either R or Q
                        
                        gatheredStart(recNum,countG) =FtransStart(recNum,FtransNum);
                        gatheredEnd(recNum,countG) =FtransEnd(recNum,FtransNum);
                        gatheredQRend(recNum,countG) = 2;
                        count=count+1;
                        countG = countG+1;
                    end
                end
                
                for FXtransNum = 1:nFRtrans;
                    if ceil(transitionData.FR{recNum, FXtransNum}) == FtransEnd(recNum,FtransNum);
                        %gather the forward runs ending in a R
                        ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),0]; %add end as either R or Q
                        
                        gatheredStart(recNum,countG) =FtransStart(recNum,FtransNum);
                        gatheredEnd(recNum,countG) =FtransEnd(recNum,FtransNum);
                        gatheredQRend(recNum,countG) = 0;
                        count=count+1;
                        countG = countG+1;
                    end
                end
            end
        end
    end
    if IncludeRQTransitions
        disp('Using RQ transitions, check Forward calling');
        for FXtransNum = 1:nRQtrans;
            if isfinite(transitionData.RQ{recNum, FXtransNum})
                if sum(transitionData.RQ{recNum, FXtransNum} == range5fps) == 1;
                    %gather the forward runs ending in a R
                    ForwardPeriods(count,1) = 2; %add end as Q (no forward prior as it comes stright from a reversal
                    
                    gatheredStart(recNum,countG) =transitionData.RQ{recNum, FXtransNum};
                    gatheredEnd(recNum,countG) =transitionData.RQ{recNum, FXtransNum};
                    gatheredQRend(recNum,countG) = 3; %indicates that it came from a revresal stright to Q
                    count=count+1;
                    countG = countG+1;
                end
            end
        end
    end
end

%for viewing forward periods
vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);

%% for each neuron take the data and plot the neuron average.

[~,NumEvents]=size(gatheredStart);
tviDummy = 0:1:500;
set(0,'DefaultAxesFontSize',10)

for neuNum = 1:length(Neurons);
    gatheredData.(Neurons{neuNum}) = NaN(200,1500); %in frames at 5fps
    %gatheredDatai.(Neurons{neuNum}) = NaN(200,100);
    count=1;
    countR = 1;
    countQ = 1;
    countRQ = 1;
    
    for recNum = 1:NumDataSets
        for transNum = 1:NumEvents;
            %identify if end is in desired range (that is ends and starts within the range).
            if sum(range5fps == gatheredEnd(recNum,transNum)) && sum(range5fps == gatheredStart(recNum,transNum));
                %disp([num2str(recNum),',',num2str(transNum)])
                rangeEvent5fps = (gatheredStart(recNum,transNum):gatheredEnd(recNum,transNum));
                
                %adjusts for end
                if max(rangeEvent5fps) ==5400;
                    rangeEvent5fps(end) = [];
                end
                
                gatheredData.(Neurons{neuNum})(count,1:length(rangeEvent5fps)) = iNeurons.(Neurons{neuNum})(recNum,rangeEvent5fps);
                %gatheredDatai.(Neurons{neuNum})(count,1:100) = interp1(tviF(rangeES+1),iNeurons.(Neurons{neuNum})(recNum,rangeES),linspace(min(rangeES),max(rangeES)));
                
                %get length (in 5fps)
                gatheredDataLengths.(Neurons{neuNum})(count,1) = length(rangeEvent5fps);
                %identify index of end types
                if gatheredQRend(recNum,transNum) == 0;
                    gatheredDataRend(countR,1) = count;
                    countR = countR+1;
                elseif gatheredQRend(recNum,transNum) == 2;
                    gatheredDataQend(countQ,1) = count;
                    countQ = countQ+1;
                elseif gatheredQRend(recNum,transNum) == 3;
                    gatheredDataQend(countRQ,1) = count;
                    countRQ = countRQ+1;
                end
                count=count+1;
            end
        end
    end
    
    %% Bin neuron lentghs and find neuron means in those bins
    % get transitions within the bins
binStartEdge = 1; %CHECK! Needs to be below
NumNeuronEvents = nansum(isfinite(gatheredData.(Neurons{neuNum})(:,1)));

for binNum = 1:(length(TimeBins)-1);
    BinID{binNum} = ['Bin',num2str(binNum)];
end

clearvars gatheredDataMeansEvents gatheredDataMeans
%bin and extract the events per bin
for binNum = 1:(length(TimeBins)-1)
    count =1;
    %have to floor in order to get the binned edge integers
    binEndEdge = floor(TimeBins(binNum+1));
    %currPeriod = ForwardPeriods(:,binStartEdge:binEndEdge);
    
    %Get IDs of events in each bin
    for eventN = 1:NumNeuronEvents;
        if (gatheredDataLengths.(Neurons{neuNum})(eventN,1) >=binStartEdge) && (gatheredDataLengths.(Neurons{neuNum})(eventN,1) < binEndEdge)
            gatheredDataMeansEvents.(Neurons{neuNum}).(BinID{binNum})(count,1) = eventN;            
            count=count+1;
        end
    end
    
    %Get means
    gatheredDataMeans.(Neurons{neuNum}).(BinID{binNum}) = nanmean(gatheredData.(Neurons{neuNum})((gatheredDataMeansEvents.(Neurons{neuNum}).(BinID{binNum})),:)');
    
    binStartEdge = binEndEdge+1;
end

%%
    
    
    figure; subplot(3,2,1); 
    pcolor(gatheredData.(Neurons{neuNum}))
    set(gca,'color','k')
    shading flat
    title(Neurons{neuNum})
    subplot(3,2,2); plot(nanmean(gatheredData.(Neurons{neuNum})))
    
    subplot(3,2,3); 
    %sort
    [~,~,outperm]=dendrogram(linkage(gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:)),length(gatheredDataRend));
    FXdata = (gatheredData.(Neurons{neuNum})(gatheredDataRend,:));
    pcolor(FXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k'); caxis([0,1.5])
    shading flat; title('R end'); ylabel('Event number')
    
%     pcolor(gatheredData.(Neurons{neuNum})(gatheredDataRend,:))
%     set(gca,'color','k')
%     shading flat
%     title('R end')
    subplot(3,2,4); plot(nanmean(gatheredData.(Neurons{neuNum})(gatheredDataRend,:)))
    title('R end')
    
    subplot(3,2,5); 
    %sort
    [~,~,outperm]=dendrogram(linkage(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:)),length(gatheredDataQend));
    FXdata = (gatheredData.(Neurons{neuNum})(gatheredDataQend,:));
    pcolor(FXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5]); shading flat; title('R end'); ylabel('Event number')
    
%     pcolor(gatheredData.(Neurons{neuNum})(gatheredDataQend,:))
%     set(gca,'color','k')
%     shading flat 
%     title('Q end')
    subplot(3,2,6); plot(nanmean(gatheredData.(Neurons{neuNum})(gatheredDataQend,:)))
    title('Q end')
end

%% Flip gahered data so they are aligned by FX transition
Nrow = sum(isfinite(gatheredData.(Neurons{1})(:,1)));

for neuNum = 1:length(Neurons);
    gatheredDataFlip.(Neurons{neuNum}) = NaN(200,700);
    for rowNum =1:Nrow;
        lenFBout =sum(isfinite(gatheredData.(Neurons{neuNum})(rowNum,:)));
        gatheredDataFlip.(Neurons{neuNum})(rowNum,(701-lenFBout):700) = gatheredData.(Neurons{neuNum})(rowNum,1:lenFBout);
    end
    
    figure;
    subplot(3,2,1); pcolor(gatheredDataFlip.(Neurons{neuNum}))
    set(gca,'color','k')
    shading flat
    title(Neurons{neuNum})
    subplot(3,2,2); plot(nanmean(gatheredDataFlip.(Neurons{neuNum})))
    
    subplot(3,2,3); pcolor(gatheredDataFlip.(Neurons{neuNum})(gatheredDataRend,:))
    set(gca,'color','k')
    shading flat
    title('R end')
    subplot(3,2,4); plot(nanmean(gatheredDataFlip.(Neurons{neuNum})(gatheredDataRend,:)))
    title('R end')
    
    subplot(3,2,5); pcolor(gatheredDataFlip.(Neurons{neuNum})(gatheredDataQend,:))
    set(gca,'color','k')
    shading flat 
    title('Q end')
    subplot(3,2,6); plot(nanmean(gatheredDataFlip.(Neurons{neuNum})(gatheredDataQend,:)))
    title('Q end')
end

%% Figure plots

for neuNum = 1:3%length(Neurons);
    set(0,'DefaultAxesFontSize',7)
    fig = figure;
    
    n = sum(~isnan(gatheredDatai.(Neurons{neuNum})(gatheredDataRend,1)));
    strRange1ALL = (nanstd(gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:))/sqrt(n));
    
    subplot(2,2,1); 
%     pcolor(gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:))
%     set(gca,'color','k')
%     caxis([0,1.5])
%     shading flat
%     title('R end')

    %sort
    [~,~,outperm]=dendrogram(linkage(gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:)),length(gatheredDataRend));
    FXdata = (gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:));
    pcolor(FXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5])
    if sum(~isnan(FXdata(outperm,1))) < length(FXdata(outperm,1))
        ylim([1, sum(~isnan(FXdata(outperm,1)))+1])
    end
    shading flat
    title('Reversal end')
    ylabel('Event number')
    
    subplot(2,2,2);
    errorbar(nanmean(gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:)),strRange1ALL);
    xlim([0,100])
    ylim([0.2,0.7])
    title(Neurons{neuNum})
    title('R end')
    
    n = sum(~isnan(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,1)));
    strRange1ALL = (nanstd(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:))/sqrt(n));
    
    subplot(2,2,3);
%     pcolor(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:))
%     set(gca,'color','k') 
%     caxis([0,1.5])
%     shading flat 
%     xlabel('Time (au)');
%     title('Q end') 
    
    [~,~,outperm]=dendrogram(linkage(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:)),length(gatheredDataRend));
    FXdata = (gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:));
    pcolor(FXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5])
    if sum(~isnan(FXdata(outperm,1))) < length(FXdata(outperm,1))
        ylim([1, sum(~isnan(FXdata(outperm,1)))+1])
    end
    shading flat
    title('Quiescence end')
    ylabel('Event number')
    xlabel('Time (au)');
    
    subplot(2,2,4);
    pl = errorbar(nanmean(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:)),strRange1ALL);
    xlabel('Time (au)');
    xlim([0,100])
    ylim([0.2,0.7])
    title(Neurons{neuNum})
    title('Quiescence end')
    
    hold on;
    x0=100;
    y0=100;
    width=250; %600, legend 700
    height=200;
    set(gcf,'units','points','position',[x0,y0,width,height])
    if saveflag == 1;
        set(gcf,'PaperPositionMode','auto')
        print (gcf,'-depsc', '-r300', sprintf(['intNeuronOverForward',Neurons{neuNum},'.ai']));
    end
    
end

figure; subplot(2,2,1)
pcolor(FXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
set(gca,'color','k')
caxis([0,1.5])
shading flat
colorbar
set(gcf,'units','points','position',[x0,y0,width,height])

    
if saveflag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf('intNeuronOverForward_colorbar.ai'));
end
