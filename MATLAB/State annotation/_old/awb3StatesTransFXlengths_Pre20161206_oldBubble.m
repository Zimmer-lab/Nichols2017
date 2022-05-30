%% awb3StatesTransFXlengths
% This script looks at the prior forward bout length

% run this section then go below to change parameters.

% This script finds the state transitions for the 3 states
% (reversal, forward and quiescent phases)
clear all
awb3States

%% forward run length
%Range allows you to determine which range the end of a forward bout must
%be.
%range = [1:1800,3600:5399]; %in frames with 5fps.
%range = 1:1800;
%range = 1:5399;
range = 1800:3600;

plotlog =0; %1 is yes
x1edges = -50:100:1000;

SaveDir = '/Users/nichols/Documents/Imaging/State transitions/priorFlength_RQprob_plots';
saveFlag =1;
savename = '21pc_npr1_let_';


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
%figure; hist(allFtransLength,25);

%Find forward lengths if the F run ends in a Q or R bout
FQforwardLength = NaN(NumDataSets,50);
FRforwardLength = NaN(NumDataSets,50);

for recNum = 1:NumDataSets
    for FtransNum = 1:sum(isfinite(FtransEnd(recNum,:)));
        
        % find runs which end in a R or Q state
        [~,nFQtrans] = size(transitionData.FQ);
        [~,nFRtrans] = size(transitionData.FR);
        
        %only add points where the end point is within the range
        if sum(range == FtransEnd(recNum,FtransNum))
            %gather the transition lengths if they are of the correct
            %transition type
            for FXtransNum = 1:nFQtrans;
                if transitionData.FQ{recNum, FXtransNum} == FtransEnd(recNum,FtransNum);
                    FQforwardLength(recNum,FtransNum) = FtransLength(recNum,FtransNum);
                end
            end
            
            for FXtransNum = 1:nFRtrans;
                if transitionData.FR{recNum, FXtransNum} == FtransEnd(recNum,FtransNum);
                    FRforwardLength(recNum,FtransNum) = FtransLength(recNum,FtransNum);
                end
            end
        end
    end
end

% allFQforwardLength = reshape(FQforwardLength,NumDataSets*50,1);
% figure; hist(allFQforwardLength,25);
%
% allFRforwardLength = reshape(FRforwardLength,NumDataSets*50,1);
% figure; hist(allFRforwardLength,25);

if plotlog
    x1edges = logspace(0.001,6,30);
end

allFQforwardLength = reshape(FQforwardLength,NumDataSets*50,1);
hist1FQ = histc(allFQforwardLength,x1edges);

allFRforwardLength = reshape(FRforwardLength,NumDataSets*50,1);
hist2FR = histc(allFRforwardLength,x1edges);

allFRQforwardLength = [allFQforwardLength;allFRforwardLength];
hist4 = histc(allFRQforwardLength,x1edges);

if plotlog
    figure; semilogx(x1edges,hist1FQ); hold on; semilogx(x1edges,hist2FR,'r')
    
    hist3 = hist1FQ + hist2FR;
    
    figure; semilogx(x1edges,hist4)
    figure; semilogx(x1edges,hist1FQ./hist3); hold on; semilogx(x1edges,hist2FR./hist3,'r')
    
else
    figure; plot(x1edges,hist1FQ); hold on; plot(x1edges,hist2FR,'r')
    figure; plot(x1edges,hist4)
    
    hist3 = hist1FQ + hist2FR;
    fracHistFQ = hist1FQ./hist3;
    fracHistFR = hist2FR./hist3;
    
    figure; plot(x1edges,fracHistFQ); hold on; plot(x1edges,fracHistFR,'r')
end
x1edgesSec= x1edges/5;

% Plot Bubble of FX prob

figure; plot(x1edgesSec(2:7),fracHistFQ(1:6)); hold on; plot(x1edgesSec(2:7),fracHistFR(1:6),'r')
for xpoint =1:6
    hold on;
    scatter(x1edgesSec(xpoint+1),fracHistFQ(xpoint),hist1FQ(xpoint)*60,'b','filled')
    hold on;
    scatter(x1edgesSec(xpoint+1),fracHistFR(xpoint),hist2FR(xpoint)*60,'r','filled')
end
xlim([-10,80])
ylim([-0.1,1.25])

hold on;
x0=10;
y0=10;
width=300; %600, legend 700
height=300;
set(gcf,'units','points','position',[x0,y0,width,height])
set(gca,'TickDir','out')
xlabel('Prior forward bout length (s)');
ylabel('Fraction');

currDir = pwd;
if saveFlag;
    set(gcf,'PaperPositionMode','auto')
    cd(SaveDir);
    print (gcf,'-depsc', '-r300', sprintf([savename,'bubble_priorFlength_RQprob_thin.ai']));
    cd(currDir);
end

%% size legend

sizes = ([1,10,50,100])*60;
figure
scatter([20,20,20,20],[0.2,0.34,0.6,1],sizes,'k','filled')
set(gca,'TickDir','out')
xlabel('Prior forward bout length (s)');
ylabel('Fraction')
xlim([-10,80])
ylim([0,1.25])

hold on;
x0=10;
y0=10;
width=300; %600, legend 700
height=300;
set(gcf,'units','points','position',[x0,y0,width,height])
set(gca,'TickDir','out')
xlabel('Prior forward bout length (s)');
ylabel('Fraction');

currDir = pwd;
if saveFlag;
    set(gcf,'PaperPositionMode','auto')
    cd(SaveDir);
    print (gcf,'-depsc', '-r300', sprintf('bubble_priorFlength_RQprob_size_legend_thin.ai'));
    cd(currDir);
end

%%
clearvars -except fracHistFQ fracHistFR hist1FQ hist2FR iThreeStates ThreeStates...
    transition transType transitions transitionData tv tvi NumDataSets x1edgesSec...
    x1edges range

