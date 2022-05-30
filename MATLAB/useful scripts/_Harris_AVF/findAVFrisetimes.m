function [AVFsinglerisetimes,AVFsingleriseframes] = findAVFrisetimes(thisTraceColoring,tv)
%
%AVFcyt: will run if thisTraceColoring isn't really a coloring vector, and
%instead is a wormstruct from makewormstruct containing wormstruct.AVF!
%
%WB: will run if thisTraceColoring is really a coloring vector (ie only
%1s 2s 3s and 4s)
%first you may want to verify that the output rise times from
%WBtracestateannotator are correct - to do so, if trace is your AVF trace, use
%this: risesonly = NaN(size(trace,1),1); risesonly(find(thisTraceColoring==2)) = trace(find(thisTraceColoring==2));
%figure;plot(trace); hold on; plot(risesonly,'r')
%OK, now you want to first ignore any single time points and then average
%the time points within each rise to a single time point, the resulting
%vector AVFrisetimes with each element as the average time of a single rise
%phase; to check how good your output is, you can then use this:
% figure;plot(wbstruct.tv,trace);
% hold on;for thisrise = 1:size(AVFsinglerisetimes,1)
% line([AVFsinglerisetimes(thisrise,1) AVFsinglerisetimes(thisrise,1)],[0 1],'Color','r')
% hold on
% end

originalstruct=[];
%if AVFcyt and not WB, first conver to real tracecoloring:
if isstruct(thisTraceColoring)
    tv=thisTraceColoring.t;
    originalstruct=thisTraceColoring;
    avfderiv = derivReg(thisTraceColoring.avf,1e-20,5);
    thisTraceColoring=avfderiv;
    thisTraceColoring(avfderiv>0.1)=2;
    thisTraceColoring(avfderiv<0.1)=NaN;
end

%first get rid of any non-2's
thisTraceColoring(find(thisTraceColoring == 1)) = NaN;
thisTraceColoring(find(thisTraceColoring == 3)) = NaN;
thisTraceColoring(find(thisTraceColoring == 4)) = NaN;

risestartsandends = contiguous(thisTraceColoring,2);
risestartsandends = risestartsandends{2};

%AVFcyt: stitch together rise phases that aren't stitched yet
if ~isempty(originalstruct)
    for thisrise = 1:size(risestartsandends,1)-1
        if thisrise == 1
            currentrise = 1;
            fixedrisestartsandends = [NaN NaN];
        end
        endrise=0;
        if risestartsandends(thisrise,2)+10 < risestartsandends(thisrise+1,1)
            endrise = 1;
        end
        if endrise
            fixedrisestartsandends = [fixedrisestartsandends ; risestartsandends(currentrise,1) risestartsandends(thisrise,2)];
            currentrise = thisrise+1;
        end
    end
    fixedrisestartsandends(1,:)=[];
    risestartsandends = fixedrisestartsandends;
end

%remove the 1-frame rises
riseduration = risestartsandends(:,2) - risestartsandends(:,1);
tooshort = find(riseduration < 1);
risestartsandends(tooshort,:) = [];
if ~isempty(originalstruct)
    tooshort = find(riseduration < 7);
    risestartsandends(tooshort,:) = [];
end

AVFsinglerisetimes = [];
AVFsingleriseframes = [];
for thisrise = 1:size(risestartsandends,1)
    AVFsinglerisetimes = [AVFsinglerisetimes; mean(tv(risestartsandends(thisrise,1):risestartsandends(thisrise,2)))];
    AVFsingleriseframes = [AVFsingleriseframes; floor(mean(risestartsandends(thisrise,1):risestartsandends(thisrise,2)))];
end

end