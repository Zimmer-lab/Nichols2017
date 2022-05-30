%% awb3StateTransFrequencyPermute
% This script takes forward runs and finds the 3state probabilities within
% bins of forward length

function [eventsAboveTrueDis,changeInQuiescence,trueDistance,pValue] = permuteTSTransFrequency(NumEventsEndingPerBin,FRtrans,FQtrans,resampleN)
% v2 looks to see how much it increases

FRtransFreq = FRtrans./NumEventsEndingPerBin;
FQtransFreq = FQtrans./NumEventsEndingPerBin;

% Use pdist or jus the abs sum betweent the two?
%trueDistance = pdist([FRtransFreq,FQtransFreq]');
%trueDistance = sum(abs(FQtransFreq-FRtransFreq));

trueDistance = (FQtransFreq(2)-FQtransFreq(1)) + (FQtransFreq(3)-FQtransFreq(2));

RevEvents = sum(FRtrans);
Qui2Events = sum(FQtrans);

totalEvents = RevEvents+Qui2Events;

possibleEnds = [zeros(1,RevEvents),ones(1,Qui2Events)];

binIndexEnds = cumsum(NumEventsEndingPerBin);
binIndexStarts = [1;binIndexEnds(1:(end-1))+1];
NumberBins = length(FRtransFreq);

OnesVector = ones(NumberBins,1);

% %testing
% figure;
% hold on; plot(FQtransFreq,'g','LineWidth',3); hold on; plot(FRtransFreq,'k','LineWidth',3)

%%
for repN = 1:resampleN;
    %randomly redistribute Q or R ends into the different bins
    
    newEndVector = randsample(possibleEnds,totalEvents,false);
%     figure; imagesc(newEndVector)
%     
%     if (sum(newEndVector) ~= sum(possibleEnds))
%         disp('check!!!')
%         return
%     end
    
    for RbinNum = 1:NumberBins;
        newFQtrans(RbinNum,1) = sum(newEndVector(1,binIndexStarts(RbinNum,1):binIndexEnds(RbinNum,1)));
    end
    
    newFQtransFreq = newFQtrans./NumEventsEndingPerBin;
    
    changeInQuiescence(repN) = (newFQtrans(2)-newFQtrans(1)) + (newFQtrans(3)-newFQtrans(2));
    
    %v1 version (changeInQuiescence replaced rasampledDistance):
    %newFRtransFreq = OnesVector-newFQtransFreq;
    %rasampledDistance(repN) = sum(abs(newFQtransFreq - newFRtransFreq));
    
    %testing
%     hold on; plot(newFQtransFreq,'b'); hold on; plot(newFRtransFreq,'r')
end

%% Caluclate pvalue Accounts for possibility of value being at either end.
if trueDistance < mean(changeInQuiescence)
    pValue = sum(changeInQuiescence <= trueDistance)/resampleN;
    display(pValue);
else
    pValue = sum(changeInQuiescence >= trueDistance)/resampleN;
    display(pValue);
end

[histD,xValues] = hist(changeInQuiescence,500);
histD = histD/resampleN;

%% Plot figure
figure; bar(xValues,histD);
hold on
plot([trueDistance trueDistance],ylim,'r')
line1 = ['Resampling Results, p-Value:', mat2str(pValue)];
title({line1});
xlabel('absolute distance');
ylabel('Fraction');
% Note P value may be close to zero or 1.

eventsAboveTrueDis = sum(changeInQuiescence >= trueDistance);
end
