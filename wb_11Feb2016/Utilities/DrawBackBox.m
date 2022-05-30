function DrawBackBox(colr,dimensions,view3D)

if nargin<3 || isempty(view3D)
    
else
         set(gca,'CameraPosition',view3D.CameraPosition );
          set(gca,'CameraTarget',view3D.CameraTarget );
          set(gca,'CameraUpVector',view3D.CameraUpVector );
          set(gca,'CameraViewAngle',view3D.CameraViewAngle );
    
end

if nargin<2 || isempty(dimensions)
    dimensions=3;
end

if nargin<1 || isempty(colr)
    colr=[0.4 0.4 0.4];
end

xl=get(gca,'XLim');
yl=get(gca,'YLim');

if dimensions==3
    
    zl=get(gca,'ZLim');

    line([xl(2) xl(2)],[yl(1) yl(2)],[0 0],'Color',colr,'LineStyle','--')
    line([xl(2) xl(2)],[0 0],[zl(1) zl(2)],'Color',colr,'LineStyle','--')
    line([0 0],[yl(1) yl(2)],[zl(1) zl(1)],'Color',colr,'LineStyle','--')
    line([xl(1) xl(2)],[0 0],[zl(1) zl(1)],'Color',colr,'LineStyle','--')

    line([0 0],[yl(2) yl(2)],[zl(1) zl(2)],'Color',colr,'LineStyle','--')

    line([xl(1) xl(2)],[yl(2) yl(2)],[0 0],'Color',colr,'LineStyle','--')

    line([xl(1) xl(2)],[yl(2) yl(2)],[zl(1) zl(1)],'Color',colr)

    line([xl(2) xl(2)],[yl(2) yl(2)],[zl(1) zl(2)],'Color',colr)


    line([xl(2) xl(2)],[yl(1) yl(2)],[zl(1) zl(1)],'Color',colr)

    line([xl(1) xl(2)],[yl(2) yl(2)],[zl(1) zl(1)],'Color',colr)

    line([xl(2) xl(2)],[yl(2) yl(2)],[zl(1) zl(2)],'Color',colr)
else
    
    line([xl(2) xl(2)],[0 0],'Color',colr,'LineStyle','--')
    line([0 0],[yl(1) yl(2)],'Color',colr,'LineStyle','--')
    line([xl(1) xl(2)],[0 0],'Color',colr,'LineStyle','--')

    line([0 0],[yl(2) yl(2)],'Color',colr,'LineStyle','--')


    
end



end