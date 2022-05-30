%% Plotting Speed Histograms for Dish
TimePeriod = 1:100;

toPlot = aAllSpeed(:,TimePeriod); %AllPreCOrmdwlstate(:,1:100);
toPlotEc = aAllEccen(:,TimePeriod); %AllPreCOrmdwlstate(:,1:100);

%%
[L,T] =size(toPlot);
TimePointsPerTrack = sum(~isnan(toPlot'));
TimePointN = sum(sum(~isnan(toPlot)));
HistX = 0:0.0025:0.5;
HistXedges=logspace(-3.2,-0.2,100); %(-0.6990,1.9031,100) %(-4,-0.6,100), -3.2,-0.2,100
HistXEccen = 0:0.001:0.02;
HistXedgesEccen = logspace(-7,-1.5,100);

BinnedSpeed =[];
BinnedSpeedLogEd = [];
BinnedEccen = [];

for ii = 1:L
    BinnedSpeed(ii,:) = hist(toPlot(ii,:),HistX); %used 100 before instead of HistX ->wrong
    BinnedSpeedLogEd(ii,:) = histc(toPlot(ii,:),HistXedges);
    BinnedEccen(ii,:) = hist(toPlotEc(ii,:),HistXEccen);
    BinnedEccenLogEd(ii,:) = histc(toPlotEc(ii,:),HistXedgesEccen);

end


for ii = 1:L
    %Divide by time points to get fraction
    BinnedSpeed(ii,:)=BinnedSpeed(ii,:)/TimePointsPerTrack(1,ii); 
    BinnedSpeedLogEd(ii,:) = BinnedSpeedLogEd(ii,:)/TimePointsPerTrack(1,ii);

    BinnedEccen(ii,:) = BinnedEccen(ii,:)/TimePointsPerTrack(1,ii);
    BinnedEccenLogEd(ii,:) = BinnedEccenLogEd(ii,:)/TimePointsPerTrack(1,ii);
end


if min(sum(BinnedSpeedLogEd')) <0.999999
    display('normalisation not working properly, check the bounds for Log Speed');
    MaxSpeed  = max(max(toPlot));
    disp(['MaxSpeed = ' num2str(MaxSpeed)]);
    MinSpeed = min(min(toPlot));
    disp(['MinSpeed = ' num2str(MinSpeed)]);
end

if min(sum(BinnedEccenLogEd')) <0.999999
    display('normalisation not working properly, check the bounds for Log Eccentricity');
    MaxEccen  = max(max(toPlotEc));
    disp(['MaxEccen = ' num2str(MaxEccen)]);
    MinEccen = min(min(toPlotEc));
    disp(['MinEccen = ' num2str(MinEccen)]);
end

figure;plot(HistXEccen,nanmean(BinnedEccen))
line('XData', [0.0009 0.0009], 'YData', [0, 0.8],'color','k','LineStyle', '-');
title('Eccentricity')

figure;
hold on
plot(HistX,nanmean(BinnedSpeed),'r','LineWidth',1);
line('XData', [0.008 0.008], 'YData', [0, 0.16],'color','k','LineStyle', '-');
title('Speed')
xlabel('Speed (pixel/sec)','Color','k','FontSize',12);
ylabel('Fraction','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);
%line('XData', [cutoff cutoff], 'YData', [0 0.3],'color','k','LineStyle', '-')

figure; plot(HistXedges,nanmean(BinnedSpeedLogEd)) %mean
line('XData', [0.008 0.008], 'YData', [0, 0.04],'color','k','LineStyle', '-');
set(gca,'XScale','log')


figure; plot(HistXedgesEccen,nanmean(BinnedEccenLogEd)) %mean
line('XData', [0.0009 0.0009], 'YData', [0, 0.035],'color','k','LineStyle', '-');
set(gca,'XScale','log')

SpeedhistLogMean = nanmean(BinnedSpeedLogEd);
SpeedhistMean = mean(BinnedSpeed);
SpeedtheMean = mean(mean(toPlot));

%% Plotting against each other.

timeP = 1:120; 
figure;
subplot(5,1,1)
plot1 = (aAllSpeed(8,timeP)); %AllPreCOrmdwlstate(:,1:100);
plot(plot1)
line('XData', [0,sum(~isnan(plot1))], 'YData', [0.008, 0.008],'color','k','LineStyle', '-');

subplot(5,1,2)
plot(aAllEccen(8,timeP)); %AllPreCOrmdwlstate(:,1:100);
line('XData', [0,sum(~isnan(plot1))], 'YData', [0.0009, 0.0009],'color','k','LineStyle', '-');

subplot(5,1,3)
stem(aAllMotionState(8,timeP))

subplot(5,1,4)
plot2 = (aAllPreCOrmdwlstate (8,timeP)); %AllPreCOrmdwlstate(:,1:100);
plot(plot2)
line('XData', [0,sum(~isnan(plot1))], 'YData', [0.008, 0.008],'color','k','LineStyle', '-');

subplot(5,1,5)
plot(aAllPreCOPostureState(8,timeP)); %AllPreCOrmdwlstate(:,1:100);
line('XData', [0,sum(~isnan(plot1))], 'YData', [0.0009, 0.0009],'color','k','LineStyle', '-');
