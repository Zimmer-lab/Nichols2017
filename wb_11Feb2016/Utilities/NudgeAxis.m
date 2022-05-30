function NudgeAxis(axis,nudgeX,nudgeY,nudgeW,nudgeH)

if nargin<2 || isempty(nudgeX)
    nudgeX=0;
end
    
if nargin<3 || isempty(nudgeY)
    nudgeY=0;
end
   
if nargin<4 || isempty(nudgeW)
    nudgeW=0;
end
if nargin<5 || isempty(nudgeH)
    nudgeH=0;
end

pos=get(axis,'Position');
nudgedPosition=[pos(1)+nudgeX pos(2)+nudgeY pos(3)+nudgeW pos(4)+nudgeH];
set(axis,'Position',nudgedPosition);


end