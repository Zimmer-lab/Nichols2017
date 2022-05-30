function TTAstruct=wbComputeTTA(wbstruct,options)


%% parse inputs 
if nargin<2
    options=[];
end

if ~isfield(options,'refNeuron')
    options.refNeuron='AVAL';
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes='SignedAllRises';
end

if ~isfield(options,'neuronSubset')
    options.neuronSubset='topNeurons';
end
    
if ~isfield(options,'delayCutoff')
    options.delayCutoff=10;
end

if ~isfield(options,'neuronSigns')   
    options.neuronSigns=[];
end

if ~isfield(options,'neuronNumGaussians')   
    options.neuronNumGaussians=[];
end

%% load data and run four state analysis

if nargin<1 || isempty(wbstruct)
    wbstruct=wbload([],false);
end

%subset
if ischar(options.neuronSubset) && strcmp(options.neuronSubset(1:10),'topNeurons')
    if isempty(options.neuronSubset(11:end))
        numNeurons=[];
    else
        numNeurons=str2double(options.neuronSubset(11:end));
    end
    thisOptions.useOnlyIDedNeurons=true;  %will use less than 20 if some aren't IDed
    sortType='pcaloading1';
    options.neuronSubset=wbGetTopNeurons(sortType,numNeurons,wbstruct,thisOptions);
    options.neuronSubset
    
    %get neuron signs
    options.fieldName='deltaFOverF';
    [~, ~, loading]=wbSortTraces(wbstruct.simple.(options.fieldName),'signed_pcaloading1');
    [~,traceIndices]=wbGetTraces(wbstruct,[],options.fieldName,options.neuronSubset);
end
    
[~,~,AVASimpleIndex]=wbgettrace('AVAL',wbstruct,options.fieldName);

if isnan(AVASimpleIndex)
    [~,~,AVASimpleIndex]=wbgettrace('AVAR',wbstruct,options.fieldName);
end

if isnan(AVASimpleIndex)
    disp('no AVAs in dataset.  guessing +PC1.');
    AVASign=1;
else
    AVASign=sign(loading(AVASimpleIndex));
end
    
if isempty(options.neuronSigns)
    
    options.neuronSigns=ones(1,length(options.neuronSubset));
    for i=1:length(options.neuronSubset)
        if loading(traceIndices(i))*AVASign < 0
            options.neuronSigns(i)=-1;
        end
    end

end


%handle missing neurons gracefully
[~,neuronSimpleIndicesSubset]=wbGetTraces(wbstruct,true,[],options.neuronSubset);
if ~isempty(options.neuronSigns)
    options.neuronSigns(isnan(neuronSimpleIndicesSubset))=[];
end
if ~isempty(options.neuronNumGaussians)
    options.neuronNumGaussians(isnan(neuronSimpleIndicesSubset))=[];
end
neuronSimpleIndicesSubset(isnan(neuronSimpleIndicesSubset))=[];


%compute TTA

[traceColoring, transitionListCellArray,transitionPreRunLengthListArray]=wbFourStateTraceAnalysis(wbstruct,'useSaved',options.refNeuron);
[refTrace,~, ~] = wbgettrace(options.refNeuron,wbstruct);


[transitions,transitionsType,transitionsPreRunLength]=wbGetTransitions(transitionListCellArray,1,options.transitionTypes,options.neuronSigns,transitionPreRunLengthListArray);


labels=wbListIDs(wbstruct,false,neuronSimpleIndicesSubset);



if ~isempty(options.neuronSigns)
    for i=1:length(labels)
        if options.neuronSigns(i)<1
            labels{i}=lower(labels{i});
        end
    end
end


allSortingLabels={};
values=nan(length(transitions),length(labels));
xPos=zeros(length(transitions),length(labels));

%compute valid delays and positions

transitionOrdering=nan(length(transitions),length(labels));

for k=1:length(transitions)
        

    transitionKeyFrame=transitions(k);
    evalParams{1}=transitionKeyFrame;
    evalParams{2}=options.transitionTypes;
    evalParams{3}=options.neuronSigns;
    
    values(k,:)=wbEvalTraces(wbstruct,'tta',evalParams,labels)/wbstruct.fps;
    
    values(k,abs(values(k,:))>options.delayCutoff)=NaN;  %don't plot very big delays since they are meaningless
    
    theseValues=values(k,:);
    theseValues(isnan(theseValues))=[];
    
    [~,transitionOrdering(k,1:length(theseValues))]=sort(theseValues);
    
    
    
end


%fit Gaussians
gaussFitOptions.range=[-options.delayCutoff options.delayCutoff];
gaussFitOptions.fitMethod='em';
TTAstruct.gaussianFitData=wbGaussFit(num2cell(values,1),gaussFitOptions);


%wirte out data
TTAstruct.transitionsPreRunLength=transitionsPreRunLength;
TTAstruct.transitionOrdering=transitionOrdering;
TTAstruct.labels=labels;
TTAstruct.delays=values;
TTAstruct.AVASign=AVASign;
TTAstruct.options=options;
TTAstruct.transitions=transitions;
TTAstruct.fps=wbstruct.fps;




end