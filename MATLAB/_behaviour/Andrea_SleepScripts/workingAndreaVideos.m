%%
figure;
imagesc(Tracks(1, 3).WormImages{1, 30})

%% 
for ii = 1:length(Tracks)
     maxes = max(Tracks(1, ii).Path);
     xmax(1,ii)= maxes(1,1);
     ymax(1,ii)=maxes(1,2);
     
     mins = min(Tracks(1, ii).Path);
     xmin(1,ii)= mins(1,1);
     ymin(1,ii)=mins(1,2);
end
 max(xmax)
 max(ymax)
 min(xmin)
 min(ymin)
 
 %% Find full length tracks
 
 for ii = 1:length(Tracks)
     trackL(ii) = Tracks(1, ii).NumFrames;
 end
 
findFull = trackL == 16200;

FullLTracks = find(findFull);

%% Find N of tracks

NFin = [];
%%
[~,N] = size(Tracks);

NFin = [NFin,N];

%% Plot FinalWakeState, TEMZ_MotionState, Speed
%load Smotionstate.mat then MotionState.mat for a file
for ii=17 %track number
figure;
subplot(4,1,1)
FWS = aAllFinalWakeState;
FWS(isnan(aAllFinalWakeState)) = 0.5;
imagesc(FWS(ii,:))
ylabel('FinalWakeState');
title(strcat('Track number:',num2str(ii)));

subplot(4,1,2)
MS = aAllMotionState;
MS(isnan(aAllMotionState)) = 0.5;
imagesc(MS(ii,:),[0,1])
ylabel('MotionState_TM');

subplot(4,1,3)
plot(aAllSpeed(ii,:))
ylabel('speed');
line('XData', [0 length(aAllSpeed(ii,:))], 'YData', [0.008, 0.008],'color','k','LineStyle', '-');
axis tight

subplot(4,1,4)
imagesc((aAllSpeed(ii,:))>0.008);

end

%% Plot motionState and FinalWakeState together
figure;
plot((nanmean(aAllFinalWakeState)))
hold on
plot(tLargeBin*5,(nanmean(aAllMotionState)),'r')

