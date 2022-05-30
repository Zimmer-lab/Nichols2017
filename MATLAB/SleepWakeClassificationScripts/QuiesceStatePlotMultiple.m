%%% Plots Quiescent or Active state as shaded rectange on traces.
% VB2, AVA, SMDD, SMDV, RIV
clear all
saveFlag = 1;

% NeuronInput = {'SMDDL','SMDDR','SMDVL','SMDVR','RIVL','RIVR','AVAL','AVAR','VB02','AQR',...
%     'URXL','URXR','RMGL','RMGR','IL2L','IL2R','RIS','ASKL','ASKR',...
%     'AIBL','AIBR','RIML','RIMR','VA01'}; %'AUAL','AUAR','IL2DL','IL2DR'
NeuronInput = {'AVAL','VB02','RIS','RMED','RMEV','RMEL','RMER','SMDDL','SMDDR','AIBL','AIBR','RIML','RIMR'};
NeuronInput = {'URXL','URXR','AQR','AVAL','VB02','RIVR','SMDDR','SMDVL','SMDVR','RIS','RMED','RMEV'};
NeuronInput = {'SIBVL','SIBVR','SIBDL','SIBDR','SMDDL','SMDDR','SMDVL','SMDVR','RIS','RMED','RMEV','AVAL','VB02'};
NeuronInput = {'SMDDL','SMDDR','SMDVL','SMDVR','RIS','RMED','RMEV','AVAL','AVAR','VB02','RIVL','RIVR','VB01','AVBL','AVBR','RIBL','RIBR'};

SaveDir = pwd;%'/Users/nichols/Dropbox/_Analysing sets/';

%%
wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));

NeuronIdx = nan(1,length(NeuronInput));
for Neuron = 1:length(NeuronInput)
    NeuronName = NeuronInput{Neuron};
    %Get simple neuron ID number
    [~, rw] = size(wbstruct.simple.ID);
    for ii = 1: rw;
        idx = strcmp(wbstruct.simple.ID{1,ii}, NeuronName);
        if idx == 1;
            NeuronIdx(1,Neuron) = ii;
            disp(['found neuron: ',NeuronName]);
        end
    end
end
%% Identify found neurons
foundNeuIndex=find(isfinite(NeuronIdx));
foundNeu = NeuronInput(1,(foundNeuIndex));

%get bc traces
NeuronF_bc = wbstruct.simple.deltaFOverF_bc(:,NeuronIdx(foundNeuIndex));
%% Get wake and quiescent states
WakeToQu = ~[true;diff(QuiesceBout(:))~=1 ];
QuToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

QuRunStart=find(WakeToQu==1);
QuRunEnd=find(QuToWake==1);

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
y1=-0.399;
h1=length(foundNeu);

figure;
for n1= 1:numBouts;
    x1=(QuRunStart(n1))/wbstruct.fps;
    w1=(QuRunEnd(n1)-QuRunStart(n1))/wbstruct.fps;
    rectangle('Position',[x1,y1,w1,h1+3],'FaceColor', paleblue,'EdgeColor', paleblue);
end

for NeuronNum = 1:length(foundNeu)
    hold on;
    plot(wbstruct.tv,(NeuronF_bc(:,NeuronNum)+(h1 -NeuronNum)),'Color',colors{NeuronNum});
end


set(gca,'FontSize',12)
xlabel('Time (s)', 'FontSize',12);
ylabel('DeltaF/F_0', 'FontSize',12);
box on;
%uistack(axes);
line('XData', [360 360], 'YData', [-1 h1+3], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
line('XData', [720 720], 'YData', [-1 h1+3], 'color', [0.6 0.6 0.6], 'LineStyle', '-','LineWidth',1)
set(gca,'TickDir', 'out');
xlim([0 1080]);
ylim([-0.4 h1+1.2]);

hold on;
x0=10;
y0=10;
width=700; %600, legend 700
height=220;
set(gcf,'units','points','position',[x0,y0,width,height])

h_legend = legend(foundNeu,'Location','eastoutside');
set(h_legend,'FontSize',12);
title(wbstruct.trialname,'FontSize',12)

currDir= pwd;
if saveFlag == 1;
    set(gcf,'PaperPositionMode','auto')
    cd(SaveDir);
    print (gcf,'-depsc', '-r300', sprintf([wbstruct.trialname,'selectedNeurons_v2.ai']));
    cd(currDir);
end

