%% Fraction Awake from SleepQuant of Dish Assays
% works on loaded 'DishWakeState.mat'
% Note that there are many graphing tools below fo replotting histgrams of
% speed and eccentricity as well as other states.

%% Range to measure to find Fraction active for each condition:
% In bins (1bin =5s)
HighO = 25:75;
LowO = 170:220;

HighO = 1:100;
LowO = 140:240;

HighOFractionA = nanmean(AllWakeState(:,HighO)');
LowOFractionA = nanmean(AllWakeState(:,LowO)');

HighOFractionA = nanmean(AllMotionState(:,HighO)');
LowOFractionA = nanmean(AllMotionState(:,LowO)');

%% Plotting histogram of speed
cutoff = 0.008; %speed cutoff

toPlot = AllSpeed(:,150:240);
[L,T] =size(toPlot);
HistX = [0:0.001:0.12];

BinnedSpeed = [];

for ii = 1:L
    BinnedSpeed(ii,:) = hist(toPlot(ii,:),HistX); 
end

BinnedSpeed=BinnedSpeed/T; %Divide by time points to get fraction

figure;plot(HistX,mean(BinnedSpeed))

theMean = mean(mean(toPlot))

hold on
plot(HistX,mean(BinnedSpeed),'r','LineWidth',1);

xlabel('Speed (wormlengths/sec)','Color','k','FontSize',12);
ylabel('Fraction','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);
line('XData', [cutoff cutoff], 'YData', [0 0.2],'color','k','LineStyle', '-')

%% Eccentricity histogram plotting
DEccentrThresh = 0.0009

toPlot = AllEccen(:,150:240);
[L,T] =size(toPlot);
HistX = [0:0.0001:0.02];

BinnedSpeed = [];

for ii = 1:L
    BinnedSpeed(ii,:) = hist(toPlot(ii,:),HistX); 
end

BinnedSpeed=BinnedSpeed/T; %Divide by time points to get fraction

figure;plot(HistX,mean(BinnedSpeed))

theMean = mean(mean(toPlot))

hold on
plot(HistX,mean(BinnedSpeed),'b','LineWidth',1);

xlabel('dEccentricity/dt','Color','k','FontSize',12);
ylabel('Fraction','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);
line('XData', [DEccentrThresh DEccentrThresh], 'YData', [0 0.2],'color','k','LineStyle', '-')

figure; 
hold on;
plot(cumsum(mean(BinnedSpeed)),'r')

%% Comparing the speed and eccen cutoffs with the motionstate.
% note there are some differences as motionstate implements a sliding
% window.

figure; imagesc(AllMotionState)

%Speed
cutoff = 0.008; %speed cutoff
[L,T] =size(AllSpeed);

AllSpeedCut = zeros(L,T);
%[idxR, idxC] 
index = find(AllSpeed > cutoff);
AllSpeedCut(index) = 1;
figure; imagesc(AllSpeedCut)

%Eccen
DEccentrThresh = 0.0009
[L,T] =size(AllEccen);

AllEccenCut = zeros(L,T);
%[idxR, idxC] 
index = find(AllEccen > DEccentrThresh);
AllEccenCut(index) = 1;

figure; imagesc(AllEccenCut)

motionstateCut = AllEccenCut + AllSpeedCut;

figure; imagesc(motionstateCut)

%% Below is plotting of 1D histograms

%%  Plot speed hist.
twentyPC = AllSpeed(:, 1:120);
tenPC = AllSpeed(:, 150:240);

figure; hist(twentyPC(:),100)
title('twentyPC')

figure; hist(tenPC(:),100)
title('tenPC')

%% Plot eccen hist.
twentyPC = AllEccen(:, 1:120);
tenPC = AllEccen(:, 150:240);

figure; hist(twentyPC(:),100)
title('twentyPC')

figure; hist(tenPC(:),100)
title('tenPC')


%% Plot rmdwlstate hist
twentyPC = rmdwlstate(:, 1:120);
tenPC = rmdwlstate(:, 150:240);

figure; hist(twentyPC(:),10)
title('twentyPC')

figure; hist(tenPC(:),10)
title('tenPC')

%% Plot PostureState hist
twentyPC = PostureState(:, 1:120);
tenPC = PostureState(:, 150:240);

figure; hist(twentyPC(:),10)
title('twentyPC')

figure; hist(tenPC(:),10)
title('tenPC')




