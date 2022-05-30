function axhandle=RenderMatrixColorbar(xpos,ypos,orientation,cVals,cMap,position)

if nargin<6
    position=[.05 .49 .1 .02];
end

axhandle=axes('Position',position);
RenderMatrix([cVals],[],[],cMap);
set(gca,'XTick',1:length(cVals));

set(gca,'XTickLabel',cVals);

end