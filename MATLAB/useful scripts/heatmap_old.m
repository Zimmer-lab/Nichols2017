figure('Position',[0 0 800 600]);

    imf=imagesc(wbstruct.tv(options.range),1:size(traces,2),traces(options.range,:)'); 
    xlabel('time (s)'); ylabel('neuron');

    set(gca,'XTick',0:60:wbstruct.tv(end));

    wbplotstimulus(wbstruct);

    title([wbstruct.displayname '   sorted by ' options.sortMethod ' ']);