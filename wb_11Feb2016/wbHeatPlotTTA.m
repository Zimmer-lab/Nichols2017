function wbHeatPlotTTA(refNeuron,wbstructOrCellArray,options)
%wbHeatPlotTTA(refNeuron,wbstruct,options)


if nargin<1
    refNeuron={'AVAL'};
end

if ~iscell(refNeuron)
    refNeuron={refNeuron};
end

if nargin<2 || isempty(wbstructOrCellArray)
    wbstruct={wbload([],false)};
else
    for i=1:length(wbstructOrCellArray)
        wbstruct{i}=wbload(wbstructOrCellArray{i});
    end
end

if nargin<3
    options=[];
end

if ~isfield(options,'sorting');    
    options.sorting=[];    
end

if ~isfield(options,'timeWindow');
    options.timeWindow=30;
end

if ~isfield(options,'savePDFFlag');    
    options.savePDFFlag=true;    
end

if ~isfield(options,'neuronSubset');    
    options.neuronSubset=[];    
end

if ~isfield(options,'neuronSigns');    
    options.neuronSigns=[];    
end


if ~isfield(options,'transitionTypes');    
    options.transitionTypes='SignedAllRises';    
end


%saveFIGFlag

for i=1:length(wbstruct)

    [traceColoring, transitionListCellArray,transitionPreRunLengthListArray]=wbFourStateTraceAnalysis(wbstruct{i},'useSaved',refNeuron{i});
    [refTrace,~, ~] = wbgettrace(refNeuron{i},wbstruct{i});
    [transitions,transitionsType]=wbGetTransitions(transitionListCellArray,1,options.transitionTypes,[],transitionPreRunLengthListArray);
    transitionTimes{i}=transitions/wbstruct{i}.fps;
    HPoptions.numTransitionsInTrial(i)=length(transitionTimes{i});
end

allTransitionTimes=cellapse(transitionTimes);

%reorder transitionTimes by clustering

if isempty(options.sorting)
    options.sorting=1:length(allTransitionTimes);
end






%transitionTimes=transitionTimes([1 2 3 6 9 10 12 14 18 20 24 25 26 4 5 7 8 11 13 15 16 17 19 21 22 23]);


    
    %HPoptions.neuronSubset={'rmev','rmer','rmed','AIBR','AIBL','AVAL','AVAR','RIMR','RIML','OLQVL','OLQDL','OLQVR','OLQDR'};
    HPoptions.neuronSubset=options.neuronSubset;
    
    %HPoptions.neuronSigns=[-1 -1 -1 1 1 1 1 1 1 1 1 1 1];
    HPoptions.neuronSigns=options.neuronSigns;
    
    HPoptions.sorting=options.sorting;  %clarify this
    
    HPoptions.rangeLimits=[(allTransitionTimes(options.sorting)-options.timeWindow/2),...
                           (allTransitionTimes(options.sorting)+options.timeWindow/2)];
  
    HPoptions.timeZeros=allTransitionTimes(options.sorting);

    HPoptions.saveFIGFlag=false;
    HPoptions.savePDFFlag=options.savePDFFlag;
    
    HPoptions.titlePrefix='TTA';
    
    HPoptions.clusterLabels=options.clusterLabels;
    
    wbHeatPlot(wbstruct,HPoptions);


    
end