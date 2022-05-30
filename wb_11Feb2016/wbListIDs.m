function [neuronString simpleNeuronNumber]=wbListIDs(wbstruct,includeUnlabeledFlag,neuronSimpleIndicesSubset,useRawIDFlag)
%[neuronString simpleNeuronNumber]=wbListIDs(wbstruct,includeUnlabeledFlag,neuronSimpleIndicesSubset,rawIDFlag)
%relies on .simple
%

if nargin<1 || isempty(wbstruct) 
    [wbstruct, wbstructFileName]=wbload([],'false');
end

if nargin<2 || isempty(includeUnlabeledFlag)
    includeUnlabeledFlag=false;
end

if nargin<3
    neuronSimpleIndicesSubset=[];
end

if nargin<4
    useRawIDFlag=false;
end


if useRawIDFlag
    
    if isfield(wbstruct,'ID1')

        if isempty(neuronSimpleIndicesSubset)
             neuronSimpleIndicesSubset=1:wbstruct.simple.nn;
        end
        
        thisSet=wbstruct.ID1(wbstruct.simple.nOrig(neuronSimpleIndicesSubset(:)'));  %force row vector

        if includeUnlabeledFlag
            
           j=1;
           for i=neuronSimpleIndicesSubset
              neuronString{j}=num2str(i);
              j=j+1;         
           end
           

           neuronString(~cellfun('isempty',thisSet))=thisSet(~cellfun('isempty',thisSet));

        else
            
           neuronString=wbstruct.ID1(wbstruct.simple.nOrig(~cellfun('isempty',thisSet)));
           
        end
           simpleNeuronNumber=find(~cellfun('isempty',thisSet));

    else

        disp('wbListIDs> no ID1 field in wbstruct');
        neuronString=[];
        simpleNeuronNumber=[];
    end
 
else %simple IDs
    
    if ~(isfield(wbstruct,'simple') && isfield(wbstruct.simple,'ID1'))
        if exist('wbstructFileName','var')
            %wbstruct=wbMakeSimpleStruct(wbstructFileName);
        else
            %wbstruct=wbMakeSimpleStruct;
        end
        
        disp('wbListIDs> no .simple struct found.');
    end
        
    
    
    if isfield(wbstruct,'simple') &&  isfield(wbstruct.simple,'ID1')

        if isempty(neuronSimpleIndicesSubset)
             neuronSimpleIndicesSubset=1:wbstruct.simple.nn;
        end
        
        thisSet=wbstruct.simple.ID1((neuronSimpleIndicesSubset(:))');  %force row vector

        if includeUnlabeledFlag
            j=1;
           for i=neuronSimpleIndicesSubset
              neuronString{j}=num2str(i);
              j=j+1;
           end

           neuronString(~cellfun('isempty',wbstruct.simple.ID1(neuronSimpleIndicesSubset(:)')))=thisSet(~cellfun('isempty',wbstruct.simple.ID1(neuronSimpleIndicesSubset(:)')));
  
        
        
        else
            neuronString=thisSet(~cellfun('isempty',thisSet));
        end     
            simpleNeuronNumber=find(~cellfun('isempty',thisSet));

    else
        if  ~isfield(wbstruct,'simple')
            disp('wbListIDs> no .simple sub-struct in wbstruct');
        else
            disp('wbListIDs> no ID1 in wbstruct.simple');
        end
        neuronString=[];
        simpleNeuronNumber=[];
    end

end


end