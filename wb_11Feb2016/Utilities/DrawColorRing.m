%function DrawColorRing(position,palette);
figure('Color','w');

startingAngle=pi;

theta=linspace(startingAngle,startingAngle+2*pi,64);
thetaSt=theta(1:end-1);
thetaEnd=theta(2:end);

outerRad=1;
innerRad=0.7;

pal=colormap('hsv');


hold on;
line([0 0],.9*[-1 1],'LineWidth',2,'Color','k');
line(.9*[-1 1],[0 0],'LineWidth',2,'Color','k');

for i=1:length(thetaSt)
    
    x(1)=cos(thetaEnd(i))*innerRad;
    x(2)=cos(thetaSt(i))*innerRad;
    x(3)=cos(thetaSt(i))*outerRad;
    x(4)=cos(thetaEnd(i))*outerRad;
    
    
    y(1)= sin(thetaEnd(i))*innerRad;
    y(2)= sin(thetaSt(i))*innerRad;
    y(3)= sin(thetaSt(i))*outerRad;
    y(4)= sin(thetaEnd(i))*outerRad;
    
    
    
    c=pal(i,:);
    
    patch(x,y,c,'EdgeColor','none');


end

axis off;
axis square;

export_fig('HSVColorRing.pdf','-painters')