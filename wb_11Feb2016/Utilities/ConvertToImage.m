function ConvertToImage(axesHandle,resolution,backgroundColor,axisSquareFlag)
%convert an axis object to an image then copy it back into the figure
%good for rasterizing high complexity vector figures
%Saul Kato
%
%


        
        if nargin<4 || isempty(axisSquareFlag)
            axisSquareFlag=false;
        end
        
        if nargin<3 || isempty(backgroundColor)
            backgroundColor='w';
        end

        if nargin<2 || isempty(resolution)
            resolution=[300 300];
        end
        
        if nargin<1 || isempty(axesHandle)
            axesHandle=gca;
        end
        
        set(axesHandle,'XTickMode','manual');
        set(axesHandle,'YTickMode','manual');
        set(axesHandle,'ZTickMode','manual');
        figureHandle=gcf;
        fAux=figure('Position',[0 0 resolution(1) resolution(2)],'Colormap',get(figureHandle,'Colormap'),'Color',backgroundColor);
        %whitebg(fAux,backgroundColor);
        axisCopy=copyobj(axesHandle,gcf);
        
        set(axisCopy,'Position',[0 0 1 1]);
        set(axisCopy,'Color',backgroundColor);
        drawnow;
        
        f=getframe(gca);
        close(fAux);
        axes(axesHandle);
        cla(gca,'reset');
        image(f.cdata);
        
        if axisSquareFlag
            axis square;
        end
        axis off;
end