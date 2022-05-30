
ScaleHtmp = [-1 3];

figure('Position',[0 0 800 600]);

    imf=imagesc(wbstruct.tv,1:size(wbstruct.deltaFOverF,2),(wbstruct.deltaFOverF)',ScaleHtmp); 
    xlabel('time (s)'); ylabel('neuron');

    set(gca,'XTick',0:60:wbstruct.tv(end));

    wbplotstimulus(wbstruct);

    %title([wbstruct.displayname '   sorted by ' options.sortMethod ' ']);