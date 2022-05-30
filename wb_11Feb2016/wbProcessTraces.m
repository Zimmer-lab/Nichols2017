function wbstruct=wbProcessTraces(wbstruct,options)
%wbstruct=wbProcessTraces(wbstruct,options)
%general wrapper for trace processing
%
%

if nargin<1 || isempty(wbstruct)
    [wbstruct,wbstructFileName]=wbload([],false); 
end

if nargin<2
    options=[];
end
    
    

if ~isfield(options,'saveFlag')
    options.saveFlag=true;
end


if ~isfield(options,'fieldName') || isempty(options.fieldName)
    options.fieldName='deltaFOverF';
end

if ~isfield(options,'processType') || isempty(options.processType)
    options.processType='bc';
end

if ~isfield(options,'processParams') || isempty(options.processParams)
    
    options.processParams.method='exp';
    options.processParams.fminfac=0.9;
    options.processParams.startFrames=1000;
    options.processParams.endFrames=100;
    options.processParams.coop=0;
    options.processParams.looseness=0.1;
    
end

postprocessedFieldName=[options.fieldName '_' options.processType];

switch options.processType
    
    case 'bc'
        

        [wbstruct.(postprocessedFieldName)  wbstruct.([postprocessedFieldName '_suppData'])   ] =bleachcorrect(wbstruct.(options.fieldName),options.processParams);
        wbstruct.([postprocessedFieldName '_options'])=options.processParams;
        
        %simple
        [wbstruct.simple.(postprocessedFieldName)  wbstruct.simple.([postprocessedFieldName '_suppData'])   ] =bleachcorrect(wbstruct.simple.(options.fieldName),options.processParams);
        wbstruct.simple.([postprocessedFieldName '_options'])=options.processParams;
                
end


if options.saveFlag && exist('wbstructFileName','var')
    disp('wbProcessTraces> saving.');
    wbSave(wbstruct,wbstructFileName);    
end


