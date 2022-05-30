function TTAPairStruct=wbComputeTTAPair(wbstruct,neuron1,neuron2,options)
% old: [out_TTAtraces,out_TTAtv,out_DelayDistribution,keyNeuronIndex]=wbComputeTTA(wbstruct,options)

if nargin<4
    options=[];
end

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end 

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end 

if ~isfield(options,'timeWindowSize')
    options.timeWindowSize=20;
end 

if ~isfield(options,'FSAParams')
    posThresh=.05;
    negThresh=-.3;
    threshType='rel';
    options.FSAParams={posThresh,negThresh,threshType};
end

if ~isfield(options,'neuron1Sign')
    options.neuron1Sign=0;
end

if ~isfield(options,'neuron2Sign')
    options.neuron2Sign=0;
end

%[traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstruct,options.FSAParams{1},options.FSAParams{2},options.FSAParams{3});

[traceColoring, transitionListCellArray, transitionPreRunListArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved');

[trace1,~, neuronIndex1]=wbgettrace(neuron1,wbstruct);
[trace2,~, neuronIndex2]=wbgettrace(neuron2,wbstruct);


[transitions1 transitionsType1 transitionsPreRunLength1]=wbGetTransitions(transitionListCellArray,neuronIndex1,options.transitionTypes,options.neuron2Sign,transitionPreRunListArray);
[transitions2 transitionsType2 transitionsPreRunLength2]=wbGetTransitions(transitionListCellArray,neuronIndex2,options.transitionTypes,options.neuron1Sign,transitionPreRunListArray);

numTransitions=length(transitions1);

frameStartRel=-floor((wbstruct.fps*options.timeWindowSize)/2);
frameEndRel=floor((wbstruct.fps*options.timeWindowSize)/2);

%extract transition-triggered traces
trace1_padded=[nan(frameEndRel,1) ; trace1 ; nan(frameEndRel,1)];
trace2_padded=[nan(frameEndRel,1) ; trace2 ; nan(frameEndRel,1)];

out_TTAtraces1=zeros(length(frameStartRel:frameEndRel),numTransitions);
out_TTAtraces2=zeros(length(frameStartRel:frameEndRel),numTransitions);

for t=1:numTransitions
    out_TTAtraces1(:,t)=trace1_padded( frameEndRel + transitions1(t)+ (frameStartRel:frameEndRel));
    out_TTAtraces2(:,t)=trace2_padded( frameEndRel + transitions1(t)+ (frameStartRel:frameEndRel));

end

out_TTAtv=(frameStartRel:frameEndRel)/wbstruct.fps;


%compute delay distribution
for t=1:numTransitions

   if length(transitions2)>0
       out_DelayDistributionFrames(t)=transitions2(nearestTo(transitions1(t),transitions2)) - transitions1(t);
       out_DelayDistribution(t)=(transitions2(nearestTo(transitions1(t),transitions2)) - transitions1(t))/wbstruct.fps;
       out_PrecedingStateLength(t)=transitionsPreRunLength2( nearestTo(transitions1(t),transitions2)  );
   else
       out_DelayDistribution(t)=NaN;
       out_DelayDistributionFrames(t)=NaN;
       out_PrecedingStateLength(t)=NaN;
   end
   
end

TTAPairStruct.fps=wbstruct.fps;
TTAPairStruct.TTAtraces1=out_TTAtraces1;
TTAPairStruct.TTAtraces2=out_TTAtraces2;
TTAPairStruct.TTAtv=out_TTAtv;
TTAPairStruct.delayDistribution=out_DelayDistribution;
TTAPairStruct.delayDistributionFrames=out_DelayDistributionFrames;
TTAPairStruct.precedingStateLength2=out_PrecedingStateLength;