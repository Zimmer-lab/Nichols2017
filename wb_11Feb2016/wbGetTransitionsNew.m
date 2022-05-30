function [traceColoring, transitions, runLengths]=wbGetTransitionsNew(wbstructs,refNeuron,neuron,transitionTypeRef,transitionType)

if isstruct(wbstructs)
    wbstructs={wbstructs};
end

if ischar(refNeuron)
    refNeuron=repcell({refNeuron},length(wbstructs));
end

if ischar(neuron)
    neuron=repcell({neuron},length(wbstructs));
end

for d=1:length(wbstructs)

     refNeuronIndex=wbGetSimpleIndex(refNeuron{d},wbstructs{d}); 

     if isnan(refNeuronIndex)
          transitions=nan;
          disp(['wbGetTransitions> no ref neuron '  refNeuron{d} ' in this dataset.']);
          return;
     end

     [~, transitionListCellArray]=wbFourStateTraceAnalysis(wbstructs{d},'useSaved',refNeuron{d});        
     [refTransitions, ~, ~]=wbGetTransitions(transitionListCellArray,1,transitionTypeRef);


     neuronIndex=wbGetSimpleIndex(neuron{d},wbstructs{d});

     if isnan(neuronIndex)
          transitions=nan(size(refTransitions));
          disp(['wbGetTransitions> no neuron ' neuron{d} ' in this dataset.']);
          return;
     end

     [traceColoring{d}, transitionListCellArray, preRunLengthArray,runLengthArray]=wbFourStateTraceAnalysis(wbstructs{d},'useSaved',neuron{d});
     [transitionsNeuron, ~, ~,transitionsRunLength]=wbGetTransitions(transitionListCellArray,1,transitionType,[],preRunLengthArray,runLengthArray);

     
     transitions{d}=nan(size(refTransitions));

     for t=1:length(transitionsNeuron)
         transitions{d}(nearestTo(transitionsNeuron(t),refTransitions))=transitionsNeuron(t);
         runLengths{d}(nearestTo(transitionsNeuron(t),refTransitions))=transitionsRunLength(t);
     end
end
    
    
end