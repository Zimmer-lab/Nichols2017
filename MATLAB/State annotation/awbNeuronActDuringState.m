%% awb3StateTransNeuronForward
% This script takes forward runs and finds the Neuron activity over those
% periods
clear all

awb3States

%% Get neuron traces (interpolated)
Neurons = {'RIS','RMED','RMEV'}%,'RIBL','RIBR','AVBL','AVBR','VB02'};
% 'RMEL','RMER'

state = 'Q'; % F or Q.
saveFlag = 0;
saveName = 'npr1_Let_first10pc';

% Range where the end can be present 
% note that state runs that start in the desired range but then end
% outside of this range are also included but they have no transition.

% in seconds
 rangeS = [0:360,720:1080]; 
% rangeS = 360:720;
rangeS =0:1080;
%rangeS = 0:360;

%%
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

% Get neuron data on interpolated time.
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

tviSec = 0:1:1079;

% %%%%%%%
for recNum = 1:NumDataSets
    iThreeStatesSec(recNum,:) = interp1(tvi,iThreeStates(recNum,:),tviSec,'nearest');
end

% get state (e.g. Forward) run lengths and positions
StateTransStart = NaN(NumDataSets,50);
StateTransLength = NaN(NumDataSets,50);
StateTransEnd = NaN(NumDataSets,50);

for recNum = 1:NumDataSets
    clearvars stats
    
    currentState = iThreeStatesSec(recNum,:);
    if state == 'F'
        currentState(currentState == 2) = 0;
    elseif state == 'Q'
        currentState(currentState == 1) = 0;
        currentState(currentState == 2) = 1;
    else
        disp('confused about input state')
    end
        
    BW= bwlabel(currentState);
    stats = regionprops(BW, 'BoundingBox');
    
    for transNum = 1:length(stats);
        StateTransStart(recNum,transNum) = stats(transNum, 1).BoundingBox(1,1);
        StateTransLength(recNum,transNum) = stats(transNum, 1).BoundingBox(1,3);
        
        % find run end
        StateTransEnd(recNum,transNum) = StateTransStart(recNum,transNum)+StateTransLength(recNum,transNum)-0.5;
        % -0.5 adjusts for the position end compared to the values in transitionData
    end
end
StateTransStart = StateTransStart -0.5; %correct position
allStateTransLength = reshape(StateTransLength,NumDataSets*50,1);

% Make matrix of only forward (+1 timepoint after) states if the start falls within the range
StatePeriods = NaN(sum(~isnan(allStateTransLength)),700);
count= 1;

% find runs which end in a R, F or Q state
if state == 'F'
    [~,nXQtrans] = size(transitionData.FQ);
    [~,nXRtrans] = size(transitionData.FR);
    transTypesAnalysed = {'FQ','FR'};
elseif state == 'Q'
    [~,nXQtrans] = size(transitionData.QF);
    [~,nXRtrans] = size(transitionData.QR);
    transTypesAnalysed = {'QF','QR'};
else
    disp('confused about input state')
end

gatheredEndType = NaN(NumDataSets,20);

for recNum = 1:NumDataSets
    countG =1;
    for transNum = 1:sum(isfinite(StateTransEnd(recNum,:)));
        
        % adds points where the end point is within the range
        if sum(rangeS == StateTransEnd(recNum,transNum))
            %gather the transition lengths if they are of the correct
            %transition type
            for FXtransNum = 1:nXQtrans;
                if ceil(transitionData.(transTypesAnalysed{1}){recNum, FXtransNum}/5) == StateTransEnd(recNum,transNum)
                    %gather the forward runs ending in a Q (for foward
                    %runs) or F (for quiescent runs)
                    StatePeriods(count,1:(StateTransLength(recNum,transNum)+1)) = [ones(1,StateTransLength(recNum,transNum)),2]; %add end as either R or Q
                    
                    gatheredStart(recNum,countG) =StateTransStart(recNum,transNum);
                    gatheredEnd(recNum,countG) =StateTransEnd(recNum,transNum);
                    gatheredEndType(recNum,countG) = 2; 
                    count=count+1;
                    countG = countG+1;
                end
            end
            
            for FXtransNum = 1:nXRtrans;
                if ceil(transitionData.(transTypesAnalysed{2}){recNum, FXtransNum}/5) == StateTransEnd(recNum,transNum);
                    %gather the runs ending in a R
                    StatePeriods(count,1:(StateTransLength(recNum,transNum)+1)) = [ones(1,StateTransLength(recNum,transNum)),0]; %add end as either R or Q
                    
                    gatheredStart(recNum,countG) =StateTransStart(recNum,transNum);
                    gatheredEnd(recNum,countG) =StateTransEnd(recNum,transNum);
                    gatheredEndType(recNum,countG) = 0;
                    count=count+1;
                    countG = countG+1;
                end
            end
            
            if 1080 == StateTransEnd(recNum,transNum)
                disp([num2str(recNum),' ',num2str(transNum)])
                %gather the runs ending outside of the
                %recording
                StatePeriods(count,1:(StateTransLength(recNum,transNum)+1)) = [ones(1,StateTransLength(recNum,transNum)),3];
                %use 3 so that these runs won't be contatenated to
                %others
                
                gatheredStart(recNum,countG) =StateTransStart(recNum,transNum);
                gatheredEnd(recNum,countG) =StateTransEnd(recNum,transNum);
                gatheredEndType(recNum,countG) = 3;
                count=count+1;
                countG = countG+1;
            end
        end
        
        % add points where the end point is outside the range but start
        % is inside. Cut off non-range end and end with 3.
        if max(rangeS == StateTransEnd(recNum,transNum)) == 0 && sum(rangeS ==StateTransStart(recNum,transNum)) ==1; %5fps
            disp(['ATN:',num2str(recNum),',',num2str(transNum)]);
            %gather the forward runs ending in outside of range and
            %cut off part outside range (end with a 3 to break up
            %the Foward states
            StatePeriods(count,1:((sum(rangeS(end) >= StateTransStart(recNum,transNum):StateTransEnd(recNum,transNum)))+1)) = ...
                [ones(1,(sum(rangeS(end) >= StateTransStart(recNum,transNum):StateTransEnd(recNum,transNum)))),3]; %add end as either R or Q
            %use 3 so that these forward runs won't be contatenated to
            %others
            
            gatheredStart(recNum,countG) =StateTransStart(recNum,transNum);
            gatheredEnd(recNum,countG) =StateTransEnd(recNum,transNum);
            gatheredEndType(recNum,countG) = 3;
            count=count+1;
            countG = countG+1;
        end
    end
end

%for viewing forward periods
vis =single(StatePeriods);
vis(isnan(StatePeriods))=-1;
figure; imagesc(vis);

%% for each neuron take the data and plot the neuron average.

[~,c]=size(gatheredStart);
tviDummy = 0:1:500;
set(0,'DefaultAxesFontSize',10)

for neuNum = 1:length(Neurons);
    gatheredData.(Neurons{neuNum}) = NaN(200,2000); %in frames at 5fps
    gatheredDatai.(Neurons{neuNum}) = NaN(200,100);
    count=1;
    countR = 1;
    countQF = 1;
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
                if gatheredEndType(recNum,transNum) == 0;
                    gatheredDataRend(countR,1) = count;
                    countR = countR+1;
                elseif gatheredEndType(recNum,transNum) == 2;
                    gatheredDataQend(countQF,1) = count;
                    countQF = countQF+1;
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
    StateXdata = (gatheredData.(Neurons{neuNum})(gatheredDataRend,:));
    pcolor(StateXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5])
%     if sum(~isnan(FXdata(outperm,1))) < length(FXdata(outperm,1))
%         ylim([1, sum(~isnan(FXdata(outperm,1)))+1])
%     end
    shading flat
    if state == 'F'
        title('Q end')
    else
        title('F end')
    end
    ylabel('Event number')
    
%     pcolor(gatheredData.(Neurons{neuNum})(gatheredDataRend,:))
%     set(gca,'color','k')
%     shading flat
%     title('R end')
    subplot(3,2,4); plot(nanmean(gatheredData.(Neurons{neuNum})(gatheredDataRend,:)))
    if state == 'F'
        title('Q end')
    else
        title('F end')
    end
    
    subplot(3,2,5); 
    %sort
    [~,~,outperm]=dendrogram(linkage(gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:)),length(gatheredDataRend));
    StateXdata = (gatheredData.(Neurons{neuNum})(gatheredDataQend,:));
    pcolor(StateXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
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

%% Flip gahered data so they are aligned by StateX transition
Nrow = sum(isfinite(gatheredData.(Neurons{1})(:,1)));

for neuNum = 1:3;%length(Neurons);
    gatheredDataFlip.(Neurons{neuNum}) = NaN(200,2000);
    for rowNum =1:Nrow;
        lenStateBout =sum(isfinite(gatheredData.(Neurons{neuNum})(rowNum,:)));
        gatheredDataFlip.(Neurons{neuNum})(rowNum,(2001-lenStateBout):2000) = gatheredData.(Neurons{neuNum})(rowNum,1:lenStateBout);
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
    StateXdata = (gatheredDatai.(Neurons{neuNum})(gatheredDataRend,:));
    pcolor(StateXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5])
    if sum(~isnan(StateXdata(outperm,1))) < length(StateXdata(outperm,1))
        ylim([1, sum(~isnan(StateXdata(outperm,1)))+1])
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
    StateXdata = (gatheredDatai.(Neurons{neuNum})(gatheredDataQend,:));
    pcolor(StateXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    set(gca,'color','k')
    caxis([0,1.5])
    if sum(~isnan(StateXdata(outperm,1))) < length(StateXdata(outperm,1))
        ylim([1, sum(~isnan(StateXdata(outperm,1)))+1])
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
    if saveFlag == 1;
        set(gcf,'PaperPositionMode','auto')
        print (gcf,'-depsc', '-r300', sprintf(['intNeuronOverForward',saveName,Neurons{neuNum},'.ai']));
    end
    
end

figure; subplot(2,2,1)
pcolor(StateXdata(outperm,:));%, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
set(gca,'color','k')
caxis([0,1.5])
shading flat
colorbar
set(gcf,'units','points','position',[x0,y0,width,height])

    
if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf('intNeuronOverForward_colorbar.ai'));
end
