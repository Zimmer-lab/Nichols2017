function traceVals=wbEvalTraces(wbstructOrTraces,evalType,evalParams,neuronSubset,options)
%compute something about all traces in a wbstruct, or an array of traces
%usually a scalar value but sometimes a vector
%
evalTypes={'rms','rms_detrended','rms_offset','rms_detrended_offset',...
         'pcaloading','signed_dpcaloading','pcamaxloading','powerspectrum','tta'};

if nargin<1
   [wbstructOrTraces wbstructFileName]=wbload([],false);
end

if nargin<4
    neuronSubset=[];
end

% argument overloading
if strcmp(wbstructOrTraces,'?') || strcmp(wbstructOrTraces,'list')
   traceVals=evalTypes;
   return;
end
 
if nargin<5
    options=[];
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'useExclusionListFlag')
    options.useExclusionListFlag=true;
end

if ~isfield(options,'range')
    options.range=[];  
end

if ~isfield(options,'useLabeledOnlyFlag');
    options.useLabeledOnlyFlag=false;
end

if options.useExclusionListFlag && isstruct(wbstructOrTraces)
    exclusionList=wbstructOrTraces.exclusionList;
else
    exclusionList=[];
end

if ~exist('evalType');
    evalType='rms';
end


if isstruct(wbstructOrTraces) %wbstructOrTraces is a wbstruct
    
    wbstruct=wbstructOrTraces;
    
    if isempty(neuronSubset)
        
        traces=wbstructOrTraces.(options.fieldName);
        traces(:,exclusionList)=[];
    
    else
        
        [traces,traceSimpleIndices]=wbGetTraces(wbstruct,options.useLabeledOnlyFlag,options.fieldName,neuronSubset);
        
    end

else

    traces=wbstructOrTraces;
    
end



if ~isempty(options.range)
    traces=traces(options.range,:);
end
    



numTraces=size(traces,2);

traceVals=zeros(numTraces,1);

switch evalType
    
    case 'rms'
        
        traceVals=rms(zeronan(detrend(traces,'constant')));
        
    case 'rms_detrended'
        
        traceVals=rms(zeronan(detrend(traces,'linear')));
        
    case 'rms_offset'
        
        
        traceVals=rmsOffset(zeronan(detrend(traces,'constant')));
        
    case 'rms_detrended_offset'
        
        traceVals=rmsOffset(zeronan(detrend(traces,'linear')));
        
    case 'powerspectrum'     %vector output
        
        traceVals=zeros(size(traces,1),numTraces);
        for n=1:numTraces
            traceVals(:,n)=abs(fft(zeronan(detrend(traces(:,n),'linear')))).^2;
        end

    case 'tta'

           if ~isempty(evalParams{1})
               transitionKeyFrame=evalParams{1};
           else
               transitionKeyFrame=1000;       
           end
        
           if length(evalParams)>1 && ~isempty(evalParams{2})
               transitionTypes=evalParams{2};
           else
               transitionTypes=[]; %see transitionTypes from wbFourStateTraceAnalysis        
           end
        

           if length(evalParams)>2 && ~isempty(evalParams{3})
               neuronSigns=evalParams{3};
           else
               neuronSigns=[];
           end           
           
           if length(evalParams)>3 && ~isempty(evalParams{4})
               riseThresh=evalParams{4};
           else
               riseThresh=.05;
           end

           if length(evalParams)>4 && ~isempty(evalParams{5})
               fallThresh=evalParams{5};
           else
                fallThresh=-.3;
           end
           
           if length(evalParams)>5 &&~isempty(evalParams{6})
               threshType=evalParams{6};
           else
               threshType='rel';
           end
           

           

           
           %get all transitions

 
           [traceColoring, transitionListCellArray]=wbFourStateTraceAnalysis(wbstructOrTraces,'useSaved',neuronSubset);

           %find nearest transitions in all other traces
           for i=1:numTraces
               
               if isempty(neuronSigns)
                  transitionIndices=wbGetTransitions(transitionListCellArray,i,transitionTypes);
               else
                  transitionIndices=wbGetTransitions(transitionListCellArray,i,transitionTypes,neuronSigns(i));
               end
               nt=transitionIndices(nearestTo(transitionKeyFrame,transitionIndices))-transitionKeyFrame;
               if isempty(nt)
                   traceVals(i)=size(traces,1);
               else
                   traceVals(i)=nt;
               end
               
           end
               
         
end
