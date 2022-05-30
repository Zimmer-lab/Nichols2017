function traceColoring=traceDerivIsNegative(trace,fallThresh,smoothingWindow)

    if nargin<3
        smoothingWindow=8;
    end

    if nargin<2
        fallThresh=-0.003;
    end
    
    traceColoring=double((deriv(fastsmooth(trace,smoothingWindow,3,1))-fallThresh)<0);
    

end