function plothandle=ex(x,y,size,colr,shape)
%draw an ex   ex(x,y,size,colr)
%
if nargin<5 || isempty(shape)
    shape='x';
end

if nargin<4 || isempty(colr)
    colr=[1 0 0];
end

if nargin<3 || isempty(size)
    size=8;
end

if nargin<2 || isempty(y)
    xo=x(1);
    yo=x(2);
else
    xo=x;
    yo=y;
end
   
plothandle=plot(xo,yo,'Color',colr,'MarkerSize',size,'Marker',shape,'LineWidth',2,'LineStyle','none');

end