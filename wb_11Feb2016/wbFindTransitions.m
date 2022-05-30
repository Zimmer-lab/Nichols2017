function transitionIndices=wbFindTransitions(wbstruct,neuronStringOrNumber,options)
% transitionIndices=wbFindTransitions(wbstruct,neuronString,transitionType,traceFunctionHandle,functionParams)

if nargin<1
    [wbstruct wbstructFileName]=wbload([],false);
end

if nargin<2 || isempty(neuronStringOrNumber)
    neuronStringOrNumber='AVAL';
end

if nargin<3
    options=[];
end

if ~isfield(options,'transitionTypes')
    options.transitionTypes=1;
end



trace = wbgettrace(neuronStringOrNumber,wbstruct);
    
switch transitionType
    
    case 'onset'
        
        traceD=traceFunctionHandle(trace,functionParams);
        traceD=traceD(:); %force column
        traceDshift=[traceD(1); traceD(1:end-1)];
        diffshiftTrace=traceD-traceDshift;        
        transitionIndices=find(diffshiftTrace>0);
        
        
        
        
    otherwise
        
        disp(['wbFindTransitions: transitionType ' transitionType '  not recognized.']);
        
end