
%252:312 is the conditional 5m bin we normally use.

conditionDataNaN = sum(isnan(AllWakeState(:,252:312))');
conditionDataPrescence = find((conditionDataNaN==0));


conditionData = sum(AllWakeState(:,252:300)');
conditionTrks = find((conditionData==0));

conTrcks = intersect(conditionDataPrescence,conditionTrks);

figure; imagesc(AllMotionState(conTrcks,:))

figure; imagesc(AllWakeState(conTrcks,:))

figure; plot(nanmean(AllWakeState(conTrcks,:)))

figure; plot(nanmean(AllMotionState(conTrcks,:)))


%% Showing NaNs

NaNShowAllMotionState = double(motionstate);
NaNShowAllMotionState(isnan(motionstate))=0.5;

figure; imagesc(NaNShowAllMotionState)

figure; plot(nanmean(motionstate));

%%

tmotionstate = NaN(NumTracks,NumBins);

tmotionstate(isfinite(rmdwlstate)) = double(roam(isfinite(rmdwlstate)));

