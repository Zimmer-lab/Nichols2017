function [runLengths,runStarts]=RunLengths(trace)
%[runLengths,runStarts]=RunLengths(trace)
%get vector of lengths of non-zero stretches
%
%ignores initial up run, perhaps should change that?
%
%
tracediff=diff(logical(trace));
ups=find(tracediff==1);
downs=find(tracediff==-1);

if isempty(downs)
    downs(1)=length(trace);
end

if isempty(ups)
    ups(1)=1;
end

    
if downs(1)<ups(1)
    downs(1)=[];
end

if length(downs)<length(ups)
    downs=[downs(:) ; length(trace)];
end

runLengths=(downs-ups(:))';

runStarts=ups+1;

end



