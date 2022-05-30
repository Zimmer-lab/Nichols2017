function [neuronString simpleNeuronNumber]=wbListIDsOLD(wbstruct,includeUnlabeledFlag,neuronSimpleIndicesSubset,rawIDFlag)
%[neuronString simpleNeuronNumber]=wbListIDs(wbstruct,includeUnlabeledFlag,neuronSimpleIndicesSubset,rawIDFlag)
%relies on .simple
%

if nargin<1 || isempty(wbstruct) 
    wbstruct=wbload([],'false');
end

if nargin<2 || isempty(includeUnlabeledFlag)
    includeUnlabeledFlag=false;
end

if nargin<3
    neuronSimpleIndicesSubset=[];
end

if nargin<4
    rawIDFlag=false;
end


% if nargin<1
%     disp('wbListIDs> using wbstruct in workspace.');
%     wbstruct=evalin('base','wbstruct');
% end


if rawIDFlag
    
    if isfield(wbstruct,'ID')

        j=1;

        if isempty(neuronSimpleIndicesSubset)
            iterationVector=1:length(wbstruct.ID);
        else
            iterationVector=(neuronSimpleIndicesSubset(:))';  %force row vector
        end

        for i=iterationVector


            if ~isempty(wbstruct.ID{i}) && ~strcmp(wbstruct.ID{i}{1},'---') 
                neuronString{j}=wbstruct.ID{i}{1};
                simpleNeuronNumber(j)=i;
                j=j+1;
            elseif includeUnlabeledFlag
                neuronString{j}=num2str(i);
                simpleNeuronNumber(j)=i;
                j=j+1;
            end

        end

    else

        disp('wbListIDs> no ID field in wbstruct');
        neuronString=[];
        simpleNeuronNumber=[];
    end
    

    
    
else

    if isfield(wbstruct,'simple') &&  isfield(wbstruct.simple,'ID')

        j=1;

        if isempty(neuronSimpleIndicesSubset)
            iterationVector=1:length(wbstruct.simple.ID);
        else
            iterationVector=(neuronSimpleIndicesSubset(:))';  %force row vector
        end

        for i=iterationVector


            if ~isempty(wbstruct.simple.ID{i}) && ~strcmp(wbstruct.simple.ID{i}{1},'---') 
                neuronString{j}=wbstruct.simple.ID{i}{1};
                simpleNeuronNumber(j)=i;
                j=j+1;
            elseif includeUnlabeledFlag
                neuronString{j}=num2str(i);
                simpleNeuronNumber(j)=i;
                j=j+1;
            end

        end

    else
        if  isfield(wbstruct,'simple')
            disp('wbListIDs> no .simple sub-struct in wbstruct');
        else
            disp('wbListIDs> no IDs in wbstruct.simple');
        end
        neuronString=[];
        simpleNeuronNumber=[];
    end

end





end