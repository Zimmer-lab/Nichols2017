function traceColoring=traceTrough(trace,riseThresh,fallThresh,smoothingWindow)

    if nargin<4
        smoothingWindow=8;
    end

    if nargin<3
        fallThresh=-0.01;
    end
    
    if nargin<2
        fallThresh=0.01;
    end
    
    
    traceColoring1=traceDerivIsPositive(trace,riseThresh,smoothingWindow);
    
    traceColoring2=-traceDerivIsNegative(trace,fallThresh,smoothingWindow);

    both=traceColoring1+traceColoring2;
    
    both(both==0)=NaN;
    
    traceColoring=1-heaviside(fixnan(both))+traceColoring2;
    
   
    
end