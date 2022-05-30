%%
% Make plot of Q state, speed, eccen of worm from Dish assay
wormNum = 3;
range = 4:237;

%%
tv = 0:0.0833:19.9087;
paleblue = [0.8  0.93  1]; %255

figure;
subplot(2,1,1)

L = bwlabel(abs(AllMotionState(wormNum,:)-1));
stats = regionprops(L,'basic');
numBouts = length(stats);
stats(1, 1).BoundingBox(3)
stats(1, 1).BoundingBox(4)
y1 =0;
h1 = max(AllSpeed(wormNum,range))+0.05;

for n1= 1:numBouts;
    x1=(stats(n1, 1).BoundingBox(1))*0.0833;
    w1=(stats(n1, 1).BoundingBox(3))*0.0833;
    rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
end
hold on
plot(tv(range),AllSpeed(wormNum,range))
axis tight
%hold on
line([0,240],[0.008 0.008],'Color','r','Linewidth',1)
xlabel('Time (min)','FontSize',12)
ylabel('Speed (wormlengths/sec)','FontSize',12)
xlim([min(range)/12,max(range)/12]);


subplot(2,1,2)
h1 = max(AllEccen(wormNum,range))+0.0005;

for n1= 1:numBouts;
    x1=(stats(n1, 1).BoundingBox(1))*0.0833;
    w1=(stats(n1, 1).BoundingBox(3))*0.0833;
    rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
end
hold on
plot(tv(range),AllEccen(wormNum,range))
axis tight
line([0,240],[0.0009 0.0009],'Color','r','Linewidth',1)
xlabel('Time (min)','FontSize',12)
ylabel('dEccentricity/dT','FontSize',12)
xlim([min(range)/12,max(range)/12]);

hold on;
x0=10;
y0=10;
width=500;
height=300;
set(gcf,'units','points','position',[x0,y0,width,height])
set(gcf,'PaperPositionMode','auto')

print (gcf,'-depsc', '-r300', sprintf('SpeedandEccenQA.ai'));
