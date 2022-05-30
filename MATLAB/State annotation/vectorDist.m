%% VectorDist
% uses pdist to calculate the distance between two vectors

vector1 = RISE1;
vector2 = RISE2;

% vector1 = StateTransQATriggered.ClosestTransArise_Qui2Act_evoked_AVAcorr;
% vector2 = StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr_AllRISE_butRISRME;


% Calculate distance

%only take neurons with at least an N > 3 in both conditions
NperNeuV1 = sum(~isnan(vector1),2);
NperNeuV2 = sum(~isnan(vector2),2);
NeuInc = NperNeuV1 > 3 & NperNeuV2 >3;

%calculate median
medians = nanmedian(vector1,2);
medians(:,2) = nanmedian(vector2,2);

vectorDistance = pdist(medians(NeuInc,:)');
incNeurons = Neurons(NeuInc,:);

%% Plot distances
figure;  
plot(1:length(incNeurons),medians(NeuInc,1))
hold on
plot(1:length(incNeurons),medians(NeuInc,2))
set(gca,'XTick',1:length(incNeurons),'XTickLabel',incNeurons);


%% Correlations matrixes of the distance between neurons.
for vectorN =1:2;
    vectorDistBtwnNeuV = pdist(medians(NeuInc,vectorN));
    
    figure;
    set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
    heatmap(squareform(vectorDistBtwnNeuV), incNeurons, incNeurons, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    
    [H,T,outperm]=dendrogram(linkage(vectorDistBtwnNeuV),length(incNeurons));
    svectorDistBtwnNeu = squareform(vectorDistBtwnNeuV);
    
    figure;
    set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
    heatmap(svectorDistBtwnNeu(outperm,outperm), incNeurons(outperm), incNeurons(outperm), [], 'NaNColor', [0 0 0], 'ShowAllTicks', true,'TickAngle',45);
    title('RISE1')
end


%%
%disclude these neurons:
NeuronsExclude = {'AQR','URXL','URXR','AUAL','AUAR','IL2DL','IL2DR','AVBL','AVBR','RIBL','RIBR','SIBDL','SIBDR','SIBVL','SIBVR','RIVL','RIVR','SMDDL','SMDDR',...
    'SMDVL','SMDVR','VB02','RMGL','RMGR'};

%'RMED','RMEV','RMEL','RMER'

Index =[];
% plot neurons:
for neuN = 1:length(NeuronsExclude)
    IndexC = (strfind(Neurons(NeuInc,1),NeuronsExclude{neuN}));
    if ~isempty(find(not(cellfun('isempty', IndexC))))
        Index(neuN) = find(not(cellfun('isempty', IndexC)));
    end
end

Index(Index==0)=[];

NeuronsPlot =Neurons(NeuInc,:);
NeuronsPlot(Index) = [];

mediansPlot = medians(NeuInc,:);
mediansPlot(Index,:) = [];

% Plot distances
figure;  
plot(1:length(NeuronsPlot),mediansPlot(:,1))
hold on
plot(1:length(NeuronsPlot),mediansPlot(:,2),'r')
set(gca,'XTick',1:length(NeuronsPlot),'XTickLabel',NeuronsPlot);

clearvars H T outperm vectorN vectorDistBtwnNeuV NperNeuV1 NperNeuV2 vector1 vector2


