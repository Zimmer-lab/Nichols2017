function wbTTAstruct=wbComputeTTAFullMatrix(wbstruct,options)

if nargin<2
    options=[];
end

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end


if ~isfield(options,'useGlobalSigns')
    options.useGlobalSigns=true;
end

if ~isfield(options,'useOnlyIDedNeurons')
    options.useOnlyIDedNeurons=true;
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset=[];
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF_bc';
end 

if ~isfield(options,'timeWindowSize')
    options.timeWindowSize=80;
end

if ~isfield(options,'saveData')
    options.saveData=true;
end

%load data
[traceColoring, transitionListCellArray,transitionPreRunLengthListArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved');


[traces,keyNeuronIndex]=wbGetTraces(wbstruct,options.useOnlyIDedNeurons,options.fieldName,options.neuronSubset);


wbTTAstruct.fps=wbstruct.fps;

numTraces=length(keyNeuronIndex);
frameStartRel=-floor((wbstruct.fps*options.timeWindowSize)/2);
frameEndRel=floor((wbstruct.fps*options.timeWindowSize)/2);

traces_padded=[nan(frameEndRel,numTraces) ; traces ; nan(frameEndRel,numTraces)];

if isnumeric(options.neuronSubset)
    wbTTAstruct.neuronLabels=wbListIDs(wbstruct,~options.useOnlyIDedNeurons,options.neuronSubset);
else %iscell options.neuronSubset
    wbTTAstruct.neuronLabels=options.neuronSubset;
end

wbTTAstruct.neuronIndexSubset=keyNeuronIndex;
wbTTAstruct.traceMatrix=cell(numTraces);
wbTTAstruct.traceTV=cell(numTraces);
wbTTAstruct.delayDistributionMatrix=cell(numTraces);
wbTTAstruct.delayMeanMatrix=zeros(numTraces);
wbTTAstruct.delayStDevMatrix=zeros(numTraces);

if options.useGlobalSigns
   
    globalMaps=wbMakeGlobalMaps;
    neuronSigns=cellapse(values(globalMaps.Sign,wbTTAstruct.neuronLabels))';
    wbTTAstruct.neuronSigns=neuronSigns;       
    
else

    [~, ~, loading]=wbSortTraces(wbstruct.simple.(options.fieldName),'signed_pcaloading1');
    neuronSigns=sign(loading);
    wbTTAstruct.neuronSigns=neuronSigns(keyNeuronIndex(1:numTraces));

end



for nref=1:numTraces %column is ref neuron
    
    
    neuronSign=wbTTAstruct.neuronSigns(nref);
    
    
    [refTransitions,~,refNeuronPreRunLengths]=wbGetTransitions(transitionListCellArray,...
        keyNeuronIndex(nref),options.transitionTypes,neuronSign,transitionPreRunLengthListArray);

    [refTransitionsNEG,~,refNeuronPreRunLengthsNEG]=wbGetTransitions(transitionListCellArray,...
        keyNeuronIndex(nref),options.transitionTypes,-neuronSign,transitionPreRunLengthListArray);


    wbTTAstruct.refNeuronPreRunLengths{nref}=refNeuronPreRunLengths;
    wbTTAstruct.refNeuronPreRunLengthsNEG{nref}=refNeuronPreRunLengths;
    
    numRefTransitions=length(refTransitions);
    numRefTransitionsNEG=length(refTransitionsNEG);

    

    out_DelayDistribution=zeros(numRefTransitions,numTraces);
    out_TTAtraces=zeros(length(frameStartRel:frameEndRel),numRefTransitions,numTraces); 
    
    out_DelayDistributionNEG=zeros(numRefTransitions,numTraces);
    out_TTAtracesNEG=zeros(length(frameStartRel:frameEndRel),numRefTransitions,numTraces); 
    
    for n=1:numTraces
        for t=1:numRefTransitions
            out_TTAtraces(:,t,n)=traces_padded( frameEndRel + refTransitions(t)+ (frameStartRel:frameEndRel),n);   
        end
        for t=1:numRefTransitionsNEG
            out_TTAtracesNEG(:,t,n)=traces_padded( frameEndRel + refTransitionsNEG(t)+ (frameStartRel:frameEndRel),n);   

            
        end
        wbTTAstruct.traceMatrix{n,nref}=out_TTAtraces(:,:,n);
        wbTTAstruct.traceMatrix{n,nref}=out_TTAtracesNEG(:,:,n);

        wbTTAstruct.traceTV{n,nref}=((frameStartRel:frameEndRel)/wbstruct.fps)';
    end
    

    %compute delay distributions

    for n=1:numTraces  %row is delayed neuron
        
        neuronSign=wbTTAstruct.neuronSigns(n);
        
        transitionIndices=wbGetTransitions(transitionListCellArray...
               ,keyNeuronIndex(n),options.transitionTypes,neuronSign);
           
        transitionIndicesNEG=wbGetTransitions(transitionListCellArray...
               ,keyNeuronIndex(n),options.transitionTypes,-neuronSign);
      
        if length(transitionIndices)>0

            for t=1:numRefTransitions
                   out_DelayDistribution(t,n)=transitionIndices(nearestTo(refTransitions(t),transitionIndices)) - refTransitions(t);
            end   
            
        else
               out_DelayDistribution(:,n)=NaN;
        end      
        
        
        if length(transitionIndicesNEG)>0

            for t=1:numRefTransitions
                   out_DelayDistributionNEG(t,n)=transitionIndicesNEG(nearestTo(refTransitions(t),transitionIndicesNEG)) - refTransitions(t);
            end   
            
        else
               out_DelayDistributionNEG(:,n)=NaN;
        end    
        
        wbTTAstruct.delayDistributionMatrix{n,nref}=out_DelayDistribution(:,n);
        wbTTAstruct.delayDistributionMatrixNEG{n,nref}=out_DelayDistributionNEG(:,n);
        
        oDD=out_DelayDistribution(:,n);
        
        wbTTAstruct.delayMeanMatrix(n,nref)=mean(oDD(oDD<options.timeWindowSize/2 & oDD>-options.timeWindowSize/2));
        wbTTAstruct.delayPosOnlyMeanMatrix(n,nref)=mean(oDD(oDD<options.timeWindowSize/2 & oDD>0));
        wbTTAstruct.delayNegOnlyMeanMatrix(n,nref)=mean(oDD(oDD<0 & oDD>-options.timeWindowSize/2));
        wbTTAstruct.delayStDevMatrix(n,nref)=std(oDD(oDD<options.timeWindowSize/2 & oDD>-options.timeWindowSize/2));
        
    end

   
end

%sort matrix by closest activation
wbTTAstruct.sortedNeuronIndices=[];
wbTTAstruct.tv=(frameStartRel:frameEndRel)/wbstruct.fps;

if options.saveData
    if strcmp(options.transitionTypes,'SignedAllFalls')
        save(['Quant' filesep 'wbTTAFallStruct.mat'],'-struct','wbTTAstruct');
    else
        save(['Quant' filesep 'wbTTARiseStruct.mat'],'-struct','wbTTAstruct');
    end
end


end %main