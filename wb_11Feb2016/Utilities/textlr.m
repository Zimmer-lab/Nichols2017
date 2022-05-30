function texthandle=textlr(txt,xl2,fontsize,color)
%textur(txt,xl2,fontsize,color)
%write text in the lower right corner of a plot
%
%Saul Kato
%100710
%
%HACK: needs xl2, right side limit of plot
%
if nargin<4
    color='k';
end

if nargin<3
    fontsize=10;
end

ax=axis;

if nargin<2 || xl2==0
    xl2=ax(2);
end
    

texthandle=text(xl2,ax(3),txt,...
            'VerticalAlignment','bottom','HorizontalAlignment','right',...
            'FontSize',fontsize,'Color',color);