function wbPlotTTAHistogrid(wbTTAstruct,options)

if nargin<2
    options=[];
end

if nargin<1
    wbTTAstruct=load(['Quant' filesep 'wbTTAStruct.mat']);
end

if ~isfield(options,'plotRefTrace')
    options.plotRefTrace=true;
end 

if ~isfield(options,'yDir')
    options.yDir='reverse';
    
end 


dims=size(wbTTAstruct.delayDistributionMatrix);

figure('Position',[0 0 1200 1000]);
whitebg('k');

set(gca,'yDir',options.yDir);

if strcmp(options.yDir,'reverse')
    ysgn=-1;
else
    ysgn=1;
end

hold on;
xlim([0.6 dims(1)+0.6]);
ylim([0 dims(2)]);

set(gca,'XTick',(1:size(wbTTAstruct.delayDistributionMatrix,1)));
set(gca,'YTick',(1:size(wbTTAstruct.delayDistributionMatrix,1))-0.5);
set(gca,'XTickLabel',PadStringCellArray(wbTTAstruct.neuronLabels,3));
set(gca,'YTickLabel',wbTTAstruct.neuronLabels);
set(gca,'XAxisLocation','top');
set(gca,'TickDir','out');
set(gca,'TickLength',[0.001 0.001]);
rotateXLabelsImage(gca(),90);
%axis square;

k=1;

for j=1:dims(2)   %row index
    for i=1:dims(1)   %column index
    
        
         
        [histo histo_ind]=hist(wbTTAstruct.delayDistributionMatrix{j,i},-12:12);
    

        maxY=max(histo);
        
        line([i-0.4 i+0.4],[j+ysgn*0.2 j+ysgn*0.2],'Color',color('gray'));
        
        if i==j
            boxCol=[0.5 0.5 0.5];
        else
            boxCol=[1 1 1];
        end
        if strcmp(options.yDir,'reverse')
            rectangle('Position',[i-0.4,j-1,0.9,0.9],'FaceColor',boxCol,'EdgeColor','none');
        else
            rectangle('Position',[i-0.4,j+0.1,0.9,0.9],'FaceColor',boxCol,'EdgeColor','none');
        end
        
        line([i i],[j+ysgn*0.2 j+ysgn*0.8],'Color','k');
        

            
        for m=2:length(histo)-1
             if histo(m)>0
                 
                %rectangle('Position', [i + (histo_ind(m)/12)*0.4 ,j+.2, (1/12)*0.4, histo(m)/40],'FaceColor','r','EdgeColor','none');
                patch([i + ((histo_ind(m)-0.5)/12)*0.4 ,i + ((histo_ind(m)-0.5)/12)*0.4,i + ((histo_ind(m)-0.5)/12)*0.4 + (1/12)*0.4,i + ((histo_ind(m)-0.5)/12)*0.4 + (1/12)*0.4],...
                   [ j+ysgn*0.2,j+ysgn*(0.2+0.7*histo(m)/maxY),j+ysgn*(.2+0.7*histo(m)/maxY),j+ysgn*0.2],'r','EdgeColor','none');

               
             end
        end
        
            
        
        %bar( (-20:20)/wbstruct.fps, histo/sum(histo), 'FaceColor','r','EdgeColor','none');
        %set(gca,'XTick',[]);
        %axis off;
        %box off;
        
        %drawnow;
        
        k=k+1;

    end
    drawnow;
end



export_fig('TTAHistogrid.pdf');