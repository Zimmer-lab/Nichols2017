function plothandle=ex3d(x,y,z,size,colr)
%draw an ex in 3D  ex3D(x,y,z,size,colr)
%
if nargin<5
    colr=[1 0 0];
end

if nargin<4 || isempty(size)
    size=8;
end

if nargin<2 || isempty(y)
    xo=x(1);
    yo=x(2);
    zo=x(3);
else
    xo=x;
    yo=y;
    zo=z;
end
   
plothandle=plot3(xo,yo,zo,'Color',colr,'MarkerSize',size,'Marker','x','LineWidth',2);

end