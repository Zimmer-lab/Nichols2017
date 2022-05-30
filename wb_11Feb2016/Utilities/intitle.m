function textHandle=intitle(txt,fontsize,imageflag,position,colr)
%intitle.m
%draw a title just inside a plot to save space
%
%Saul Kato
%first version 100710
%mod 110302 added support for images
%mod 120301 added placement option


if nargin<4 || isempty(position)
    position='top';
end

if nargin<3 || isempty(imageflag)
    imageflag=0;
end

if nargin<5 || isempty(colr)
    if imageflag
        colr='w';
    else
        colr='k';
    end
end

if nargin<2 || isempty(fontsize)
    fontsize=10;
end


xl=xlim;
yl=ylim;

if strcmp(position,'bottom')
    tmp=yl(1);
    yl(1)=yl(2);
    yl(2)=tmp;
    justify='Bottom';
else
    justify='Top';
end

if imageflag
 
    textHandle=text(xl(2), yl(1),txt,'HorizontalAlignment','Right','FontSize',fontsize,...
    'VerticalAlignment',justify,'Color',colr);

else
    
    textHandle=text((xl(1)+xl(2))/2, yl(2),txt,'HorizontalAlignment','Center','FontSize',fontsize,...
    'VerticalAlignment',justify,'Color',colr);

end
