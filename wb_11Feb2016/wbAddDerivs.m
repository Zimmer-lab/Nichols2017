function wbstruct=wbAddDerivs(wbstructOrFile,options)

    if nargin<1
        wbstructOrFile=[];
    end
    
    if nargin<2
        options=[];
    end
    
    if isempty(wbstructOrFile)
        [wbstruct wbstructFileName] = wbload([],false);
    elseif ischar(wbstructOrFile)
        [wbstruct wbstructFileName] = wbload(wbstructOrFile,false);
    end
    
    if ~isfield(options,'alpha')
        options.alpha=.0001;
    end
    
    if ~isfield(options,'numIter')
        options.numIter=10;
    end
    
    if ~isfield(options,'fieldName')
        options.fieldName='deltaFOverF_bc';
    end
    
    if ~isfield(wbstruct,'simple')
        if exist('wbstructFileName','var')
            wbMakeSimpleStruct(wbstructFileName);
            wbstruct=wbload(wbstructFileName,false);
        else
            disp('no wbstruct file specified. doing nothing for now.');
            return;
        end
    end
        
    traces=wbstruct.simple.(options.fieldName);
    
    wbstruct.simple.derivs.traces=wbDeriv(traces,'reg',options.alpha,options.numIter);
    
    wbstruct.simple.derivs.alpha=options.alpha;
    wbstruct.simple.derivs.numIter=options.numIter;

    wbstruct.simple.derivs.dateDerivsRan=datestr(now);
    
    if exist('wbstructFileName','var')
        wbSave(wbstruct,wbstructFileName);
    end
    
    disp(['derivatives saved to ' wbstructFileName]);
    
end