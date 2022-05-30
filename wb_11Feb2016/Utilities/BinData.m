function [binnedTrace, binnedTV]=BinData(trace,tv,binFrames)
%binnedTrace=BinData(trace,binFrames)

binnedTrace=zeros(length(1:binFrames:length(trace)-binFrames),1);
binnedTV=zeros(length(1:binFrames:length(trace)-binFrames),1);
j=1;
for i=1:binFrames:length(trace)-binFrames
    
    binnedTrace(j)=nanmean(trace(i:i+binFrames-1));
    binnedTV(j)=tv( i+floor(binFrames/2));
    j=j+1;
end

end