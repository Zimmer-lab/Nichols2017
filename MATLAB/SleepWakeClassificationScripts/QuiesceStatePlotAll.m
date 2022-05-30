%%% Plots Quiescent or Active state as shaded rectange on traces.
clear all
saveFlag = 0;

SaveDir = pwd;%'/Users/nichols/Dropbox/_Analysing sets/';

%%
wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));

%get bc traces
NeuronF_bc = wbstruct.simple.deltaFOverF_bc;
%% Get wake and quiescent states
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

colors = {'k','r',burntorange,forestgreen,'b', purple,'k','r',burntorange,forestgreen,'b', purple,'k','r',burntorange,yellow,forestgreen,'b', purple,};

numBouts = length(QuRunStart);
NeuronNum = 1;
prePlot =1;
[~,numNeurons] = size(NeuronF_bc);

figure;
for subN =1:12;
    subplot(4,3,subN)
    for n1= 1:numBouts;
        x1=(QuRunStart(n1))/wbstruct.fps;
        w1=(QuRunEnd(n1)-QuRunStart(n1))/wbstruct.fps;
        y1 =(subN*10)-10;
        h1 = subN*10;
        rectangle('Position',[x1,y1,w1,h1+3],'FaceColor', paleblue,'EdgeColor', paleblue);
    end
    
    for NeuronNum = prePlot:(subN*10)
        if NeuronNum <= numNeurons
            hold on;
            plot(wbstruct.tv,(NeuronF_bc(:,NeuronNum)+(NeuronNum)));
        end
    end
    line('XData', [360 360], 'YData', [-1 h1+3], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
    line('XData', [720 720], 'YData', [-1 h1+3], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
    set(gca,'TickDir', 'out');
    xlim([0 1080]);
    ylim([(subN*10)-10, subN*10]);

    prePlot = (subN*10)+1;
end


set(gcf, 'Position', get(0,'Screensize'));


currDir= pwd;
if saveFlag
    set(gcf,'PaperPositionMode','auto')
    cd(SaveDir);
    print (gcf,'-depsc', '-r300', sprintf([wbstruct.trialname,'all_neurons.ai']));
    cd(currDir);
end

