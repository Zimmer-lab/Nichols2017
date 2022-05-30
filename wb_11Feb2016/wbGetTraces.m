function [traces,traceSimpleIndices,tv,trialnames,f0]=wbGetTraces(wbstructOrRootFolder,labeledOnlyFlag,fieldName,neuronSubset)
%[traces,traceSimpleIndices,tv,trialnames]=wbGetTraces(wbstruct,labeledOnlyFlag,fieldName,neuronSubset)

if nargin<1 || isempty(wbstructOrRootFolder)
    wbstructOrRootFolder=pwd;
end
 
if isstruct(wbstructOrRootFolder)
    wbstruct=wbstructOrRootFolder;
else
    wbstruct=wbload(wbstructOrRootFolder,false);
end

if isstruct(wbstruct)   %not a cell array
    wbstruct={wbstruct};
end
 
if nargin<2
    labeledOnlyFlag=false;
end

if nargin<3 || isempty(fieldName)
    fieldName='deltaFOverF_bc';
end

if nargin<4
    neuronSubset=[];
end

if ischar(neuronSubset)     %handle single string neuronSubset
    neuronSubset={neuronSubset};
end

for i=1:length(wbstruct)
    
    trialnames{i}=wbstruct{i}.trialname;

    if isfield(wbstruct{i},'simple') && strcmp(fieldName,'deltaFOverF_bc')

        traces{i}=wbstruct{i}.simple.deltaFOverF_bc;
        tv{i}=wbstruct{i}.simple.tv;
        
        if isfield(wbstruct{i}.simple,'f0')
            f0{i}=wbstruct{i}.simple.f0;
        end
        
    elseif strcmp(fieldName,'derivs')
        
        traces{i}=wbstruct{i}.simple.derivs.traces;
        tv{i}=wbstruct{i}.tv;
        if isfield(wbstruct{i},'f0')
            f0{i}=wbstruct{i}.f0;
        end        
        
    else

        traces{i}=wbstruct{i}.(fieldName);
        tv{i}=wbstruct{i}.tv;
        traces{i}(:,wbstruct{i}.exclusionList)=[];
        if isfield(wbstruct{i},'f0')
            f0{i}=wbstruct{i}.f0;
        end
    end

    if ~isempty(neuronSubset)

        if isnumeric(neuronSubset)

            traceSimpleIndices{i}=neuronSubset;
            
            traces{i}=traces{i}(:,traceSimpleIndices{i});
            f0{i}=f0{i}(traceSimpleIndices{i});
 

        elseif iscell(neuronSubset)

            traceSimpleIndices{i}=zeros(1,length(neuronSubset));
            traces{i}=zeros(size(traces{i},1),length(neuronSubset));
            
            f0{i}=zeros(1,length(neuronSubset));
            
            for j=1:length(neuronSubset)
                
                [thisTrace, ~, thisSimpleIndex,thisF0] = wbgettrace(neuronSubset{j},wbstruct{i},fieldName);
                traces{i}(:,j)=thisTrace;
                
                traceSimpleIndices{i}(j)=thisSimpleIndex;
                
                f0{i}(j)= thisF0;
            end

        else

            disp('did not understand neuronSubset.  needs to be a string cell array or array of simple indices.');

        end

    elseif labeledOnlyFlag

%         traceSimpleIndices{i}=find(~cellfun(@isempty,wbstruct{i}.simple.ID));
%         %hacky removal of '---' entries
%         for j=1:length(traceSimpleIndices{i})
%             if(strcmp(wbstruct{i}.simple.ID{traceSimpleIndices{i}(j)}{1},'---'))
%                 wbstruct{i}.simple.ID{traceSimpleIndices{i}(j)}=[];
%             end
%         end    

        traceSimpleIndices{i}=find(~cellfun(@isempty,wbstruct{i}.simple.ID1));
        traces{i}=traces{i}(:,~cellfun(@isempty,wbstruct{i}.simple.ID1));
        f0{i}=f0{i}(~cellfun(@isempty,wbstruct{i}.simple.ID1));
        
    else
        traceSimpleIndices{i}=1:size(traces,2);

    end

end


%decellify if only one wbstruct
if length(wbstruct)==1
    traces=traces{1};
    traceSimpleIndices=traceSimpleIndices{1};
    tv=tv{1};
    trialnames=trialnames{1};
    f0=f0{1};
end

end %main