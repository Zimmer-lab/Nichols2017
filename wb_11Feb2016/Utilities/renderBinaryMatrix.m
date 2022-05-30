function renderBinaryMatrix(M,ylabels,col)
    if nargin<2
        ylabels=[];
    end
    if nargin<3
        col='b';
    end
    
    for j=1:size(M,2)
        
        
        if M(1,j)
            leftX=1;
            currentState=1;
        else
            currentState=0;
        end
        
        for i=2:size(M,1)
        
            
%             if M(i,j)
%                 h=patch([i-.5 i+.5 i+.5 i-.5],[j-0.5  j-0.5 j+0.5 j+0.5  ],col);
%                 set(h,'EdgeColor','none');
%             end
                if ~M(i,j) && M(i-1,j) %end box

                    rightX=i;
                    drawPatch(leftX,rightX,j,col);
                    currentState=0;

                elseif M(i,j) && ~M(i-1,j) 

                    leftX=i;
                    currentState=1;

                end
            
        end
        
        %last pixel
        if currentState==1
            rightX=i;
            drawPatch(leftX,rightX+1,j,col);
           
        end
        
    end
    
    if ~isempty(ylabels);
        set(gca,'YTick',1:size(M,2));
        set(gca,'YTickLabel',ylabels);
    end
    
    set(gca,'YDir','reverse');
   
end


function drawPatch(leftX,rightX,j,col)

   h=patch([-0.5+leftX -0.5+rightX -0.5+rightX -0.5+leftX],[j-.5 j-.5 j+.5 j+.5 ],col);
   set(h,'EdgeColor','none');

end
