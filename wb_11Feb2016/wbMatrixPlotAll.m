function wbMatrixPlotAll

    loadDir=[pwd filesep 'Quant'];
    fileName='wbmatrixstruct.mat';
    
    Q=load([loadDir filesep fileName]);
    
    Qfields=fieldnames(Q);
    numMatrices=length(Qfields);
    
    nr=ceil(sqrt(numMatrices));
    nc=nr;
    
    figure;
    for q=1:numMatrices
       
       subtightplot(nr,nc,q,[.08 .06]);
       imagesc(Q.(Qfields{q}));
       colorbar;
       title(Qfields{q});
       
    end

end