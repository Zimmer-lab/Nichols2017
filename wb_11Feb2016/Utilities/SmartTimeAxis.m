function SmartTimeAxis(xLim)
%SmartTimeAxis(xLim)
%xLim is a two-element vector, same as what you would use
%for the built-in MATLAB function xlim(xLim)

if nargin<1 || isempty(xLim)
    xLim=get(gca,'XLim');
else
    xlim(xLim);
end

    if xLim(2)-xLim(1)  > 540       
        set(gca,'XTick',[60*ceil(xLim(1)/60):60:-60  0:60:xLim(2)]);
        
    elseif xLim(2)-xLim(1)  > 180       
        set(gca,'XTick',[xLim(1):30:-30 0:30:xLim(2)]);
        
    elseif xLim(2)-xLim(1)  > 30       
        set(gca,'XTick',[10*ceil(xLim(1)/10):10:-10 0:10:xLim(2)]);

    elseif xLim(2)-xLim(1)  > 10       
        set(gca,'XTick',[5*ceil(xLim(1)/5):5:-5 0:5:xLim(2)]);
        
    elseif xLim(2)-xLim(1)  > 1       
        set(gca,'XTick',[xLim(1):1:-1 0:1:xLim(2)]);
    end
    

end