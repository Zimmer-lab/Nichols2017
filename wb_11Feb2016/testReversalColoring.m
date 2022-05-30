% function stateColoringTest

neuronString='AIBL';
d1Thresh=.02;
d1NegThresh=-.02;
d2Thresh=.004;
bCountMax=50;



trace=wbstruct.deltaFOverF(:,91);

trace=wbgettrace(neuronString,wbstruct);

smoothingWindow=8;
trace_sm=fastsmooth(trace,smoothingWindow,3,1);


d1=deriv(fastsmooth(trace,smoothingWindow,3,1));
d2=-deriv(deriv(fastsmooth(trace,smoothingWindow,3,1)));


[peaks, valleys]=peakfind(d2, .005, 1);

peakInd=peaks(:,1);
d2peaks=zeros(size(trace));
d2peaks(peakInd)=1;


recordedState=nan(size(trace));

state=NaN;

bCount=0;

for i=1:length(trace)
    
    if d1(i)>d1Thresh 
        state=1;
    elseif  d1(i)<-d1Thresh 
    state=0;
    else
        state=nan;
    end


%     

%     
%     
%     if bCount>0
%         bCount=bCount+1;
%     end
%     
%     if bCount==bCountMax
%         bCount=0;
%     end
%         
    recordedState(i)=state;
    
end
    
    
    continuedState=fixnan(recordedState);

    
    continuedStateNan=continuedState;
    continuedStateNan(continuedState==0)=NaN;
    
    
figure;
nr=7;
subplot(nr,1,1);
plot(wbstruct.tv,trace);
hold on;
%plot(wbstruct.tv,recordedState,'r','LineWidth',2);
title(neuronString);

subplot(nr,1,2);
plot(wbstruct.tv,d1);
hline(d1Thresh);
hline(d1NegThresh);
ylim([2*d1NegThresh 2*d1Thresh]);
ylabel('d/dt');

subplot(nr,1,3);
plot(wbstruct.tv,trace_sm);
hold on;
plot(wbstruct.tv,zero2nan(traceDerivIsPositive(trace,d1Thresh)).*trace_sm,'r','LineWidth',2);
ylabel('rising');

subplot(nr,1,4);
plot(wbstruct.tv,trace_sm);
hold on;
plot(wbstruct.tv,zero2nan(traceDerivIsNegative(trace,d1NegThresh)).*trace_sm,'b','LineWidth',2);
ylabel('plateau');

subplot(nr,1,5);
plot(wbstruct.tv,trace_sm);
hold on;
plot(wbstruct.tv,zero2nan(tracePlateau(trace,d1Thresh,d1NegThresh)).*trace_sm,'g','LineWidth',2);
ylabel('falling');

subplot(nr,1,6);
plot(wbstruct.tv,trace_sm);
hold on;
plot(wbstruct.tv,zero2nan(traceTrough(trace,d1Thresh,d1NegThresh)).*trace_sm,'c','LineWidth',2);
ylabel('trough');

subplot(nr,1,7);
plot(wbstruct.tv,trace_sm);
hold on;
transitionIndices=wbFindTransitions(wbstruct,[],[],[],d1Thresh);
for i=1:length(transitionIndices)
    vline(wbstruct.tv(transitionIndices(i)));
    text(wbstruct.tv(transitionIndices(i)),0,num2str(i));
end
ylabel('onsets');
