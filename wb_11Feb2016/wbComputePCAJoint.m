function out_struct=wbComputePCAJoint(wbFolderCellArray,options)

if nargin<1 || isempty(wbFolderCellArray)
    wbFolderCellArray=listfolders(pwd);
end

if nargin<2
    options=[];
end


if ~isfield(options,'dimRedType')
    options.dimRedType='PCA';
end

if ~isfield(options,'plotFlag')
    options.plotFlag='false';
end

if ~isfield(options,'numOffsetSteps');
   options.numOffsetSteps=1;
end

if ~isfield(options,'extraExclusionList')
    options.extraExclusionList=[];
end

if ~isfield(options,'fieldName')
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'range')
    options.range=[];
end

if ~isfield(options,'derivFlag')
    options.derivFlag=true;
end

if ~isfield(options,'derivRegFlag')
    options.derivRegFlag=true;
end

if ~isfield(options,'usePrecomputedDerivs')
    options.usePrecomputedDerivs=true;
end

if ~isfield(options,'preNormalizationType')
    options.preNormalizationType='peak';
end

if ~isfield(options,'saveFlag')
    options.saveFlag='true';
end

flagstr=[];

commonIDs=wbListIDsInCommon(wbFolderCellArray);


% for f=1:length(wbFolderCellArray)
%     
%     thisIDs=wbListIDs(wbFolderCellArray{f});    
%     options.extraExclusionList=thisIDs(~ismember(thisIDs,commonIDs));
%     
% end

%create concatenated trace array
CPCAoptions.extraExclusionList=options.extraExclusionList;
CPCAoptions.plotFlag=options.plotFlag;
CPCAoptions.derivFlag=options.derivFlag;
CPCAoptions.saveFlag=options.saveFlag;

%remove excluded neurons
for i=1:numel(CPCAoptions.extraExclusionList)
    commonIDs=commonIDs(~strcmp(commonIDs,CPCAoptions.extraExclusionList{i}));
end
CPCAoptions.neuronSubset=commonIDs;


disp('concatenating traces.');
timeColoringConcat=[];
tracesConcat=[];
for i=1:length(wbFolderCellArray);
    wbstruct{i}=wbload(wbFolderCellArray{i},false);
    [~,simpleIndices]=wbGetTraces(wbstruct{i},false,[],commonIDs);
    
    if isempty(options.range)
        pretraces0=wbstruct{i}.simple.(options.fieldName)(:,simpleIndices);
    else
        pretraces0=wbstruct{i}.simple.(options.fieldName)(options.range,simpleIndices);
    end
    pretraces0(isnan(pretraces0(:)))=0;
    pretraces0=detrend(pretraces0,'linear');
    
    pretraces1= wbstruct{i}.simple.derivs.traces(:,simpleIndices);
    
    if strcmpi(options.preNormalizationType,'peak')

        traces=pretraces1.*repmat(1./max(abs(pretraces0),[],1),size(pretraces1,1),1);   
        if i==1
            flagstr=[flagstr '-normPeak'];
        end
        
    end
    
    timeColoring=wbFourStateTraceAnalysis(wbstruct{i},'useSaved','AVAL');  %use pre-saved thresholds

    
    tracesConcat=[tracesConcat; traces ];
    
    timeColoringConcat=[timeColoringConcat; timeColoring];
end

CPCAoptions.timeColoring=timeColoringConcat;
CPCAoptions.flagstrOverride=flagstr;
size(tracesConcat)
disp('computing joint PCA.');
out_struct=wbComputePCA(tracesConcat,CPCAoptions);