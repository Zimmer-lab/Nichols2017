function traceColoring=traceDerivIsPositive(trace,thresh,options)
%traceColoring=traceDerivIsPositive(trace,thresh,options)


    if nargin<3
        options=[];
    end
    
    if nargin==2 && iscell(thresh) %then thresh is a parameter cell array
        thresh=thresh{1};
        if length(thresh)>1
            options.threshType=thresh{2};
        end
        
    end
    
    if ~exist('threshType','var') || isempty(threshType)
        threshType='abs';
    end
    
    if ~exist('thresh','var') || isempty (thresh)
        thresh=0.006;
    end
    
    if strcmp(threshType,'rel');
        thisThresh=thresh*rms(trace);
    else %absolute threshold
        thisThresh=thresh; 
    end
    
    derivTrace=derivReg(trace);
    
    traceColoring=double((derivTrace-thisThresh)>0);
    

end