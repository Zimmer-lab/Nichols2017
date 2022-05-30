function wbPlotNeuron(neuronString,wbstruct,color)


if nargin<3 || isempty(color)
    color='r';
end

if nargin<2 || isempty(wbstruct)
    wbstruct=wbload([],'false');
end


    [trace, neuronNumber] = wbgettrace(upper(neuronString),wbstruct);

    %coloring=wbgettimecoloring(wbstruct,neuronString,@traceDerivIsPositive);
    
    %area(wbstruct.tv,coloring,'FaceColor',color('gray'));
    
    hold on;
    
    plot(wbstruct.tv,trace,color);
    title(neuronString);
    
end
