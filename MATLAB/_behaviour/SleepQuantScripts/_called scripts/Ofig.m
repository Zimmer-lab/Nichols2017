function figure1=Ofig(xmax,ymax,stim);

%CREATEFIGURE
 
%  Auto-generated by MATLAB on 07-May-2007 23:35:04
 
% Create figure

figure1 = figure('Color',[1 1 1],'Position',[1 1 700 600]);
 
boxcolor=[0.9 0.9 0.9];


% Create axes
axes1 = axes('FontSize',18,'Parent',figure1);
axis([1 xmax 0 ymax]);


for i=1:2:length(stim)-1

bx(i)=rectangle('Position',[stim(i),0,stim(i+1),ymax],'FaceColor',boxcolor,'LineStyle','none');

end


% bx1=rectangle('Position',[0,0,360,yaxsc],'FaceColor',boxcolor,'LineStyle','none');
% bx2=rectangle('Position',[720,0,360,yaxsc],'FaceColor',boxcolor,'LineStyle','none');


% bx1=rectangle('Position',[60,0,1,yaxsc],'FaceColor',boxcolor,'LineStyle','none');
% bx2=rectangle('Position',[121,0,10,yaxsc],'FaceColor',boxcolor,'LineStyle','none');
% bx3=rectangle('Position',[191,0,100,yaxsc],'FaceColor',boxcolor,'LineStyle','none');





set(axes1,'layer','top');

box('on');
hold('all');
grid('on');
 
% Create xlabel
xlabel('Time (seconds)',...
  'FontSize',24,...
  'FontWeight','bold');
 
% Create ylabel
ylabel('event frequency / s ',...
  'FontSize',24,...
  'FontWeight','bold');
 
