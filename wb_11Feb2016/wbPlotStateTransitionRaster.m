function wbPlotStateTransitionRaster(wbstruct,transitionTypes,neuronListOrNames)

if nargin<1 || isempty(wbstruct)
    [wbstruct,wbstructFileName]=wbload([],false);
end

if nargin<2 || isempty(transitionTypes)
    transitionTypes='AllRises';
end

if nargin<3 || isempty(neuronListOrNames)
    %neuronList='all';
    neuronListOrNames={'AVAR','AVAL','RIMR','RIML'};
end

%convert descriptive transitionTypes string into numbers
if ischar(transitionTypes)

    if strcmp(transitionTypes,'AllRises')
       transitionTypes=[1 6 8];
    elseif strcmp(transitionTypes,'AllGood')
        transitionTypes=[1 3 4 6 8 10];
    else
       disp('wbGetTransitions> did not recognize transitionTypes. using AllRises.');
       transitionTypes=[1 6 8];
    end
end

if ischar(neuronListOrNames)
    
    if strcmp(neuronListOrNames,'all');
        neuronList=1:wbstruct.simple.nn;
    end
elseif iscell(neuronListOrNames)
    
    for i=1:length(neuronListOrNames)
        [trace, neuronNumber, simpleNeuronNumber(i)] = wbgettrace(neuronListOrNames{i},wbstruct); 
    end
    neuronList=simpleNeuronNumber;
end


[traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved');

transitionHeatmap=zeros(size(traceColoring,1),length(neuronList));

size(transitionHeatmap)

for i=1:length(neuronListOrNames)
    for j=1:length(transitionTypes)
        transitionHeatmap(transitionListCellArray{neuronList(i),j},i)=1;
    end
end

figure;

renderBinaryMatrix(transitionHeatmap,neuronListOrNames);
ylim([0 length(neuronList)+1]);
xlim([0 size(traceColoring,1)]);

export_fig('wbStateTransitionTraces.pdf');