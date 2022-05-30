function  wbPlotPCACorrelations(cc,flagstr)

if nargin<2
    flagstr='';
end


    figure('Position',[0 0 1000 1000]);
    for pc=1:min([16 size(cc,3)]);

        subtightplot(4,4,pc,[0.08 0.05],0.05,0.05);
        RenderMatrix(abs(squeeze(cc(:,:,pc))),[0 1]);
        title(['pc#' num2str(pc)]);
        BlackOutUpperRight(size(cc,1),size(cc,2));
    end


    mtit(['pairwise abs(correlations) between datasets ' flagstr],'yoff',.05);

    pdfFileName=['PCCorrelations-PairwiseTrials' flagstr '-' num2str(size(cc,3)) 'pcs.pdf'];

    export_fig(pdfFileName);


end