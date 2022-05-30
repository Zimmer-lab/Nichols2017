function hline(height,colr,zlayer,fighandle)
%hline(height,colr,zlayer)
%draw horizontal line at a height and color
%
%Saul Kato
%created 4/5/10
%added height default=0   111011
%added zlayer drawing order, by default 'bottom'  010113

if nargin==4
    axes(fighandle);
end

if nargin<3
    zlayer='bottom';
end

if nargin<2
    colr=[0.5 0.5 0.5];
end

if nargin<1
    height=0;
end

xl=xlim;


line([xl(1) xl(2)],[height height],'Color',colr)

% %move line to the bottom of the drawing layers
% if strcmp(zlayer,'bottom')
%     g=get(gca,'Children');
%     set(gca,'Children',circshift(g,1));
% end

