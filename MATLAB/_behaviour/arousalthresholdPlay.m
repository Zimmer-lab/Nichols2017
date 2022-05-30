QSpdDif = diff(SBinTrcksSpdSizeResh(SleepTracksQuiescent,:));

ASpdDif = diff(SBinTrcksSpdSizeResh(SleepTracksActive,:));
%%
figure; imagesc(QSpdDif)
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100])
figure; imagesc(ASpdDif)
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100])

%% speed
figure; plot(nanmean(SBinTrcksSpdSizeResh(SleepTracksQuiescent,:)))
hold on; plot(nanmean(SBinTrcksSpdSizeResh(SleepTracksActive,:)),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,0.1])

figure; imagesc(SBinTrcksSpdSizeResh(SleepTracksQuiescent,:))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100],'Color', 'k')
figure; imagesc(SBinTrcksSpdSizeResh(SleepTracksActive,:))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100],'Color', 'k')

meanSpdQ = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,112:118),2);
meanSpdA = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,112:118),2);

meanPrestimSpdQ = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,106:112),2);
meanPrestimSpdA = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,106:112),2);

meanIncreaseSpdQ = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,112:118),2)-nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,106:112),2);
meanIncreaseSpdA = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,112:118),2)-nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,106:112),2);


figure; plot(cumsum(nanmean(SBinTrcksSpdSizeResh(SleepTracksQuiescent,112:end))))
hold on; plot(cumsum(nanmean(SBinTrcksSpdSizeResh(SleepTracksActive,112:end))),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,2])
%%

figure; plot(nanmean(QSpdDif))
hold on; plot(nanmean(ASpdDif),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[-0.03,0.03])

%%
figure; plot(QSpdDif(1,:))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[-0.2,0.25])

%%
figure; plot(ASpdDif(2,:))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[-0.2,0.25])

%%

figure; plot(SBinTrcksSpdSizeResh(SleepTracksActive(2,1),:))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,0.18],'Color','k')
%% turning
figure; plot(nanmean(BinTrcksOstateResh(SleepTracksQuiescent,:)))
hold on; plot(nanmean(BinTrcksOstateResh(SleepTracksActive,:)),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,0.1])

%cumsum
figure; plot(cumsum(nanmean(BinTrcksOstateResh(SleepTracksQuiescent,112:end))))
hold on; plot(cumsum(nanmean(BinTrcksOstateResh(SleepTracksActive,112:end))),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,14])

figure; imagesc(BinTrcksOstateResh(SleepTracksQuiescent,100:200))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100])
figure; imagesc(BinTrcksOstateResh(SleepTracksActive,100:200))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100])

%% reversals
figure; plot(nanmean(BinTrcksLRstateResh(SleepTracksQuiescent,:)))
hold on; plot(nanmean(BinTrcksLRstateResh(SleepTracksActive,:)),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,0.1])

figure; imagesc(BinTrcksLRstateResh(SleepTracksQuiescent,100:200))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100])
figure; imagesc(BinTrcksLRstateResh(SleepTracksActive,100:200))
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,100])

%cumsum
figure; plot(cumsum(nanmean(BinTrcksLRstateResh(SleepTracksQuiescent,112:end))))
hold on; plot(cumsum(nanmean(BinTrcksLRstateResh(SleepTracksActive,112:end))),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,2])

%% speed
figure; plot(nanmean(SBinTrcksSpdSize(SleepTracksQuiescent,:)))
hold on; plot(nanmean(SBinTrcksSpdSize(SleepTracksActive,:)),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,0.1])

meanSpdQ = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,112:118),2);
meanSpdA = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,112:118),2);

meanPrestimSpdQ = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,106:112),2);
meanPrestimSpdA = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,106:112),2);

meanIncreaseSpdQ = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,112:118),2)-nanmeanD(SBinTrcksSpdSizeResh(SleepTracksQuiescent,106:112),2);
meanIncreaseSpdA = nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,112:118),2)-nanmeanD(SBinTrcksSpdSizeResh(SleepTracksActive,106:112),2);


figure; plot(cumsum(nanmean(SBinTrcksSpdSizeResh(SleepTracksQuiescent,112:end))))
hold on; plot(cumsum(nanmean(SBinTrcksSpdSizeResh(SleepTracksActive,112:end))),'r')
line([ConditionalBinQAFr(2),ConditionalBinQAFr(2)],[0,2])
