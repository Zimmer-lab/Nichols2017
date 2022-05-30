%%
%get F0 of neurons

%find ID number of neuron of interest
[~,idx1] = size(wbstruct.simple.ID);
for i = 1: idx1
    if cell2mat(strfind(wbstruct.simple.ID{i}, 'AQR')) ==1
        IDnum = i;
    end
end

NameO4 = char(strcat('Fzero_',condition));

NeuronResponse.(NameO4)(:,count)= wbstruct.simple.f0(1,IDnum);

