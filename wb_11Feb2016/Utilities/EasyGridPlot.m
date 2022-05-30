function EasyGridPlot(traces)


nr=max(cellfun(@(x) size(x,2),traces));
nd=length(traces);

figure('Position',[0 0 800 1200]);

    
for n=1:nd     
    for tr=1:size(traces{n},2)
  
        subtightplot(nd,nr, nr*(n-1) + tr,[0.05 0.05],[0.05 0.05],[0.05 0.05])
        plot(traces{n}(:,tr));
        %SmartTimeAxis([0 max(traces]);
    end
    
end