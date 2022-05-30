function handles=vline(x,colr,pattern,yl,thickness)
%vline(x,colr,pattern,yl,thickness))
%draw vertical line at each value of x and color
%
%Saul Kato
%created 4/13/10
%modified 4/22/10 to support vector input, a list of vertical positions

if nargin<5
    thickness=1;
end

if nargin<4
    yl=ylim;
end

if nargin<3 || isempty(pattern)
     pattern='-';
end

if nargin<2
    colr=[0.5 0.5 0.5];
end

if nargin<1
    x=0;
end


handles=[];

for i=1:length(x)
    
    handles(i)=line([x(i) x(i)],[yl(1) yl(2)],'Color',colr,'LineStyle',pattern,'LineWidth',thickness);

end
