
function NeuronAIndx = mywbFindNeuron(NeuronA)

%returns simpleIDs of neuron classes in the dataset within the current
%datafolder

NeuronAIndx = [];

[NeuronList, SimpleIDindx] = wbListIDs;

NumNeurons = length(NeuronList);

    
    
    NeuronAFindIndx = strfind(NeuronList,NeuronA);
    
    
    cnt=0;
    
    for iA = 1:NumNeurons
        
        if ~isempty(NeuronAFindIndx{iA})
            
            if NeuronAFindIndx{iA} == 1
            
                cnt = cnt + 1;
                
                NeuronAIndx(cnt) = SimpleIDindx(iA);
           
            end
            
        end
        
    end
    
end