%%% Plots Quiescent or Active state as shaded rectange on traces.
% VB2, AVA, SMDD, SMDV, RIV
saveFlag = 0;

Neuron1 = 'VB02';
Neuron2 = 'RIBL';
Neuron3 = 'RIBR';
Neuron4 = 'URXR';
Neuron5 = 'AVAL';

% Neuron1 = 'VB02';
% Neuron2 = 'AVAL';
% Neuron3 = 'RIVR';
% Neuron4 = 'SMDDL';
% Neuron5 = 'SMDVR';

%%
wbload;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);

vb02=(wbgettrace(Neuron1,wbstruct))+1.5;
if isnan(vb02);
    disp(['No ',Neuron1, ' neuron in this datatset'])
end

aval=(wbgettrace(Neuron2,wbstruct))-0.3; 
if isnan(aval);
    disp(['No ', Neuron2, ' neuron in this datatset'])
end

rivl=(wbgettrace(Neuron3,wbstruct))+2.5;
if isnan(rivl);
    disp(['No ',Neuron3,' neuron in this datatset'])
end

rmed=(wbgettrace(Neuron4,wbstruct))+3.5;
if isnan(rmed);
    disp(['No ',Neuron4,' neuron in this datatset'])
end

ris=(wbgettrace(Neuron5,wbstruct))+4.5;
if isnan(ris);
    disp(['No ',Neuron5, ' neuron in this datatset'])
end
%%
WakeToQu = ~[true;diff(QuiesceBout(:))~=1 ];
QuToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

QuRunStart=find(WakeToQu,'1');
QuRunEnd=find(QuToWake,'1');

if QuiesceBout(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
    QuRunStart(2:end+1)=QuRunStart;
    QuRunStart(1)=1;
end

if QuiesceBout(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
    QuRunEnd(length(QuRunEnd)+1,1)=length(instQuiesce);
end


%% Figure plotting

paleblue = [0.8  0.93  1]; %255
forestgreen = [0 153 0]/255;
burntorange = [225 115 0]/255;
yellow = [255 240 102]/255;
purple = [76 0 103]/255;

numBouts = length(QuRunStart);
y1=-0.399;
h1=6.38;

figure;
for n1= 1:numBouts;
    x1=(QuRunStart(n1))/wbstruct.fps;
    w1=(QuRunEnd(n1)-QuRunStart(n1))/wbstruct.fps;
    rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
end
hold on;
plot(wbstruct.tv,ris,'Color',purple);
hold on;
plot(wbstruct.tv,rmed, 'Color', forestgreen);
hold on;
plot(wbstruct.tv,rivl,'Color', burntorange);
hold on;
hold on;
plot(wbstruct.tv,aval, 'r');
hold on;
plot(wbstruct.tv,vb02, 'b');
hold on;

xlim([0 1080]);
ylim([-0.4 6]);
set(gca,'FontSize',12)
xlabel('Time (s)', 'FontSize',12);
ylabel('DeltaF/F_0', 'FontSize',12);
width=800;
height=400;
box on;
%uistack(axes);
line('XData', [360 360], 'YData', [-1 8], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
line('XData', [720 720], 'YData', [-1 8], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
set(gca,'TickDir', 'out');

%h2= plot((QuiesceBout), 'k');
%set(h2, 'LineWidth', 3); 

hold on;
x0=10;
y0=10;
width=700; %600, legend 700
height=150;
set(gcf,'units','points','position',[x0,y0,width,height])

h_legend = legend(Neuron5,Neuron4,Neuron3,Neuron2,Neuron1,'Location','eastoutside');
set(h_legend,'FontSize',12);

if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    print (gcf,'-depsc', '-r300', sprintf('QuiesceNeurons2.ai'));
end

