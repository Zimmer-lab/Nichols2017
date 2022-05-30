function wbCirclePlot(Q,QThetas,QLabels,scale,sequences)

if nargin<4 || isempty(scale)
    scale=2*pi;
end
colorSequencesFlag=false;
drawArrowheadFlag=false;
drawBallsFlag=true;
savePDFFlag=true;
radius=1;

%clock coordinates, clockwise from top

points.x=cos(pi/2-sequences/scale/2*pi)*radius;
points.y=sin(pi/2-sequences/scale/2*pi)*radius;


QPoints.x=cos(pi/2-QThetas/scale/2*pi)*radius;
QPoints.y=sin(pi/2-QThetas/scale/2*pi)*radius;


rectangle('Position',[-1,-1,2,2],'Curvature',[1 1],'EdgeColor',color('gray'));
hold on;
 for i=1:length(QThetas)
     text(1.05*QPoints.x(i),1.05*QPoints.y(i),[QLabels{i}],'Rotation',90-90*QThetas(i)/scale);
     ex(QPoints.x(i),QPoints.y(i));
 end
 
 xlim([-1.5 1.5]);
 ylim([-1.5 1.5]);


%draw connections

if nargin<5 || isempty(sequences)
    
    for i=1:size(Q,1)
        for j=1:size(Q,2)
            if Q(i,j)
                line([QPoints.x(i) QPoints.x(j)],[QPoints.y(i) QPoints.y(j)]);
            end
        end
    end 

else
    numSequences=size(sequences,2);
    
    for s=1:numSequences
        thisSequence=sequences(:,s);
        theseX=points.x(:,s);
        theseY=points.y(:,s);
        theseX(isnan(thisSequence))=[];
        theseY(isnan(thisSequence))=[];
        
        for n=2:length(theseX)
            if colorSequencesFlag
                thisColor=color(s,numSequences);
            else
                thisColor='k';
            end
                
            if drawArrowheadFlag
               
            arrow([ theseX(n-1) theseY(n-1)     ],[ (theseX(n)+theseX(n-1))/2 (theseY(n)+theseY(n-1))/2  ],'EdgeColor',thisColor,'FaceColor',thisColor,'Length',9);
            
            line([(theseX(n)+theseX(n-1))/2  theseX(n)    ],[(theseY(n)+theseY(n-1))/2    theseY(n)] , 'Color',thisColor);
            %arrow([ points.x(i) points.y(i)     ],[points.x(j) points.y(j)  ],'EdgeColor',color(s,numSequences),'FaceColor',color(s,numSequences),'Length',12);
            else
               line([theseX(n) theseX(n-1)],[theseY(n) theseY(n-1)],'Color',thisColor); 
            end
        end
        
    end
    
end
    
 
text(0,1.35,'t=0 ->');
line([0 0],[1 1.3],'Color',color('gray'));


text(-1.35,0,['t=-' num2str(scale) ' s']);
line([-1.3 1],[0 0],'Color',color('gray'));

text(1.35,0,['t=+' num2str(scale) ' s']);
line([1.3 1],[0 0],'Color',color('gray'));

axis off;
if savePDFFlag
    export_fig(['CirclePlot.pdf']);
end

end