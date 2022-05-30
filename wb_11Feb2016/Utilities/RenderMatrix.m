function RenderMatrix(M,cLim,ylabels,myColormap,Xpos,Ypos,axesHandle,nullColor)
%RenderMatrix(M,cLim,ylabels,myColormap,Xpos,Ypos)

if nargin<8
    nullColor=[1 1 1];
end

if nargin<7 || isempty(axesHandle)
    axesHandle=gca;
end

if nargin<5 || isempty(Xpos)
    Xpos=1:size(M,2);
end

Xpos=linspace(Xpos(1),Xpos(end),size(M,2));

if nargin<6 || isempty(Ypos)
    Ypos=1:size(M,1);
end

Ypos=linspace(Ypos(1),Ypos(end),size(M,1));

if length(Xpos)>1
    XPixWidth=Xpos(2)-Xpos(1);
else
    XPixWidth=1;
end

if length(Ypos)>1
    YPixWidth=Ypos(2)-Ypos(1);
else
    YPixWidth=1;
end

    if nargin<4 || isempty(myColormap)
        myColormap=colormap;
    end
    
    %colormap(cMap);
    
    if nargin<2 || isempty(cLim)
        cLim=[min(M(:)) max(M(:))];
    end
 
    if nargin<3
        ylabels=[];
    end
    
    M_min=min(M(:));
    M_max=max(M(:));
    
    for j=1:size(M,1)

        for i=1:size(M,2)       


            thisM=max([cLim(1) M(j,i) ]);
            thisM=min([cLim(2) thisM ]);
            if cLim(2)>cLim(1)
                colorIndex=1+round((size(myColormap,1)-1)*(thisM-cLim(1))/(cLim(2)-cLim(1)));  %scaling to colormap
            else
                colorIndex=1;
            end
            %colorIndex=thisM;
            
            if isnan(M(j,i))
                drawPatch(Xpos(i),Ypos(j),XPixWidth,YPixWidth,nullColor);
            else
                drawPatch(Xpos(i),Ypos(j),XPixWidth,YPixWidth,myColormap(colorIndex,:));
            end
        end

    end
    
    
    %set(gca,'XTick',1:size(M,2));
    set(axesHandle,'YTick',1:size(M,1));
    
    if isempty(ylabels)
        set(axesHandle,'YTickLabel',[]);
    else
        set(axesHandle,'YTickLabel',ylabels);
    end
    
    set(axesHandle,'YDir','reverse');

    
    xlim([Xpos(1)- XPixWidth/2 Xpos(end)+XPixWidth/2]);
    ylim([Ypos(1)- YPixWidth/2 Ypos(end)+YPixWidth/2]);
end



function drawPatch(i,j,XPixWidth,YPixWidth,colr)

   h=patch([-XPixWidth/2+i XPixWidth/2+i (XPixWidth*1.0000001)/2+i -(XPixWidth*1.0000001)/2+i],[j-YPixWidth/2 j-YPixWidth/2 j+YPixWidth/2 j+YPixWidth/2 ],colr);
   set(h,'EdgeColor','none');

end
