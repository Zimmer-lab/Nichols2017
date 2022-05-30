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
%tv = (0:0.2:1079.8);

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
% Range where the end can be present 
% note that forward runs that start in the desired range but then end
% outside of this range are also included but they have no transition.

% rangeS = [0:360,720:1080]; %in seconds
% rangeS = 360:720;
rangeS =0:1080;

tviSec = 0:1:1079;

%%% linear
% startS = 0:20:200;
% logon = 0;

%%% log
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

% Make matrix of only forward (+1 timepoint after) states if the start falls within the range
ForwardPeriods = NaN(sum(~isnan(allFtransLength)),700);
count= 1;

% find runs which end in a R or Q state
[~,nFQtrans] = size(transitionData.FQ);
[~,nFRtrans] = size(transitionData.FR);
gatheredQRend = NaN(NumDataSets,20);

for recNum = 1:NumDataSets
    countG =1;
    for FtransNum = 1:sum(isfinite(FtransEnd(recNum,:)));
        
        % adds points where the end point is within the range
        if sum(rangeS == FtransEnd(recNum,FtransNum))
            %gather the transition lengths if they are of the correct
            %transition type
            for FXtransNum = 1:nFQtrans;
                if ceil(transitionData.FQ{recNum, FXtransNum}/5) == FtransEnd(recNum,FtransNum)
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
                if ceil(transitionData.FR{recNum, FXtransNum}/5) == FtransEnd(recNum,FtransNum);
                    %gather the forward runs ending in a R
                    ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),0]; %add end as either R or Q
                    
                    gatheredStart(recNum,countG) =FtransStart(recNum,FtransNum);
                    gatheredEnd(recNum,countG) =FtransEnd(recNum,FtransNum);
                    gatheredQRend(recNum,countG) = 0;
                    count=count+1;
                    countG = countG+1;
                end
            end
            
            if 1080 == FtransEnd(recNum,FtransNum)
                disp([num2str(recNum),' ',num2str(FtransNum)])
                %gather the forward runs ending outside of the
                %recording
                ForwardPeriods(count,1:(FtransLength(recNum,FtransNum)+1)) = [ones(1,FtransLength(recNum,FtransNum)),3];
                %use 3 so that these forward runs won't be contatenated to
                %others
                
                gatheredStart(recNum,countG) =FtransStart(recNum,FtransNum);
                gatheredEnd(recNum,countG) =FtransEnd(recNum,FtransNum);
                gatheredQRend(recNum,countG) = 3;
                count=count+1;
                countG = countG+1;
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
            
            gatheredStart(recNum,countG) =FtransStart(recNum,FtransNum);
            gatheredEnd(recNum,countG) =FtransEnd(recNum,FtransNum);
            gatheredQRend(recNum,countG) = 3;
            count=count+1;
            countG = countG+1;
        end
    end
end

%for viewing forward periods
vis =single(ForwardPeriods);
vis(isnan(ForwardPeriods))=-1;
figure; imagesc(vis);

%% for each neuron take the data and plot the neuron average.

[~,c]=size(gatheredStart);
tviDummy = 0:1:500;
set(0,'DefaultAxesFontSize',10)

for neuNum = 1:length(Neurons);
    gatheredData.(Neurons{neuNum}) = NaN(200,1500); %in frames at 5fps
    gatheredDatai.(Neurons{neuNum}) = NaN(200,100);
    count=1;
    countR = 1;
    countQ = 1;
    for recNum = 1:NumDataSets
        for transNum = 1:c;
            %identify if end is in desired range.
            if sum(rangeS == gatheredEnd(recNum,transNum)) && gatheredStart(recNum,transNum) > 0;
                disp([num2str(recNum),',',num2str(transNum)])
                rangeES = round((gatheredStart(recNum,transNum)*5:gatheredEnd(recNum,transNum)*5));
                %adjusts for end
                if max(rangeES) ==5400;
                    rangeES(end) = [];
                end
                gatheredData.(Neurons{neuNum})(count,1:length(rangeES)) = iNeurons.(Neurons{neuNum})(recNum,rangeES);
                gatheredDatai.(Neurons{neuNum})(count,1:100) = interp1(tviF(rangeES+1),iNeurons.(Neurons{neuNum})(recNum,rangeES),linspace(min(rangeES),max(rangeES)));
                %identify index of end types
                if gatheredQRend(recNum,transNum) == 0;
                    gatheredDataRend(countR,1) = count;
                    countR = countR+1;
                elseif gatheredQRend(recNum,transNum) == 2;
                    gatheredDataQend(countQ,1) = count;
                    countQ = countQ+1;
                end
                count=count+1;
            end
        end
    end
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
    set(gca,'color','k')
    caxis([0,1.5])
%     if sum(~isnan(FXdata(outperm,1))) < length(FXdata(outperm,1))
%         ylim([1, sum(~isnan(FXdata(outperm,1)))+1])
%     end
    shading flat
    title('R end')
    ylabel('Event number')
    
%     pcolor(gatheredData.(Neurons{neuNum})(gatheredDataRend,:))
%     set(gca,'color','k')
%     shading flat
%     title('R end')
    subplot(3,2,4); plot(nanmean(gatheredData.(Neurons{neuNum})(gatheredDataRend,:)))
    title('R end')
    
    subplot(3,2,5); 
    %sort
    [~,~,outperm]=dendrogram(linkage(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:)),length(gatheredDataRend));
    FXdata = (gatheredData.(Neurons{neuNum})(gatheredDataQend,:));
    pcolor(FXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5])
%     if sum(~isnan(FXdata(outperm,1))) < length(FXdata(outperm,1))
%         ylim([1, sum(~isnan(FXdata(outperm,1)))+1])
%     end
    shading flat
    title('R end')
    ylabel('Event number')
    
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
