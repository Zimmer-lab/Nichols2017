function [neuronLabels_out, neuronSigns]=wbSetLabelCaseByNeuronSign(neuronLabels,neuronSigns,wbstruct,wbPCAStruct,options)
%[neuronLabels_out, neuronSigns]=wbSetLabelCaseByNeuronSign(neuronLabels,neuronSigns,wbstruct,wbPCAStruct,options)
%
%set case of a cell array of labels or a singe string label, based on neuron sign

if nargin<5
   options=[];
end

if nargin<4
    wbPCAStruct=wbLoadPCA;
end

if nargin<3
    wbstruct=wbload([],false);
end


if nargin<2
    neuronSigns=[];   
end

neuronLabels_out=upper(neuronLabels);

if ischar(neuronLabels)
    
    neuronLabels={neuronLabels};
    
end


if isempty(neuronSigns)
    
    [neuronSigns]=wbGetNeuronSigns(neuronLabels,[],wbstruct,wbPCAStruct,options);
    
end


for i=1:length(neuronLabels)
    if neuronSigns(i) < 0
        neuronLabels_out{i}=lower(neuronLabels{i});
    end
end

   
end