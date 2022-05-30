%% pharynxTrackerSpeed_Slide
% This script calculates the different speed types (per second= BinSpeed,
% SlideSpeed= 1s sliding window
clear all


cutoff = 1.25; % above which speed the worm is considered to be engaged in a motion bout
%3 for clump at 40x
%1.25 for border at 20x

%roamthresh = 0.35; 
% 3 for 40x

MainDir = pwd;
 
FolderList = mywbGetDataFolders; %to exclude a dataset put & symbol in front of foldername
 
NumDataSets = length(FolderList);
 
 
for ii = 1:NumDataSets
    
    cd(FolderList{ii})
    
    [~, deepestFolder, ~] = fileparts(pwd);
    
    load(strcat(deepestFolder,'_track.mat'));
    
    Speed(ii,:) = Tracks.WormSpeed;
    
    cd(MainDir)

    %% Use the reshape function for databinning
    binning = 5; %in frames
    %!!! 25 is 5 sec. Note Let assays bin for 5 seconds.... but binning = 15.

    BinWin = binning;

    Len = length(Tracks.WormSpeed);

    BinNum = floor(Len/BinWin); 

    BinSpeed(ii,:) = sum(reshape(Tracks.WormSpeed(1:BinNum*BinWin),BinWin,BinNum));

    SlideSpeedQuiClass
    
    AllSlideSpeed(ii,:) = SlideSpeed;

end


%% Plotting

toPlot = AllSlideSpeed;
[L,T] =size(toPlot);
HistX = 0:0.25:80;
HistXedges=logspace(-0.6990,1.9031,100); %(-0.6990,1.9031,100)

BinnedSpeed =[];

for ii = 1:L
    BinnedSpeed(ii,:) = hist(toPlot(ii,:),HistX); %used 100 before instead of HistX ->wrong
    BinnedSpeedLogEd(ii,:) = histc(toPlot(ii,:),HistXedges)
end

BinnedSpeed=BinnedSpeed/T; %Divide by time points to get fraction
BinnedSpeedLogEd = BinnedSpeedLogEd/T;

figure;plot(HistX,mean(BinnedSpeed))

theMean = mean(mean(toPlot));

hold on
plot(HistX,mean(BinnedSpeed),'r','LineWidth',1);

xlabel('Speed (pixel/sec)','Color','k','FontSize',12);
ylabel('Fraction','Color','k','FontSize',12);
set(gca, 'XColor', 'k');
set(gca, 'YColor', 'k');
set(gca,'Color',[1 1 1]);
line('XData', [cutoff cutoff], 'YData', [0 0.3],'color','k','LineStyle', '-')


figure;imagesc(AllSlideSpeed);
caxis([0 50]);

figure; plot(HistXedges,mean(BinnedSpeedLogEd))
%set(gca,'XScale','log')


%cumsum
 
%% Quiescence Classification All
%categorization parameters for speed:

AllActive = AllSlideSpeed > cutoff;

%Keep NaNs in tracking as NaNs
findNans = find(isnan(AllSlideSpeed)); %[row, col]

MotionState = double(AllActive);

MotionState(findNans) = NaN;

figure;imagesc(MotionState);

FractionAmeans = nanmean(MotionState');
FractionA = mean(mean(FractionAmeans))

%%
CurrentFolder = pwd;
[~, deepestFolder, ~] = fileparts(pwd);

save (([strcat(CurrentFolder,'/',deepestFolder,'_track_mmSec') '.mat']),'Speed','BinSpeed','AllSlideSpeed','binning','fps','SlideBin','MotionState');

clearvars BinNum BinWin CurrentFolder FolderList Len LevelThresh Levelbackground MainDir NumDataSets deepestFolder ii iii SlideBin ans fps Border Tracks

%%
TV = [1.2:0.2:300];
[NumTracks, ~] = size(AllSlideSpeed);
yaxis = [1:NumTracks];
figure;
subplot(2,1,1) 
imagesc(TV,yaxis,AllSlideSpeed);
colorbar
xlabel('time (s)');
ylabel('Worm');
colormap jet

freezeColors
cbfreeze(colorbar)

map = ([0, 0, 0.562; 0.5, 0, 0]);
subplot(2,1,2) 
imagesc(TV,yaxis,MotionState);
colormap(map);

xlabel('time (s)');
ylabel('Worm');
%legend('Awake','Quiescent')
colorbar
set(colorbar,'YTick',0:1:1)


% NOTE: NaNs are shown in black for speed and blue (like Q for
% motionstate).
