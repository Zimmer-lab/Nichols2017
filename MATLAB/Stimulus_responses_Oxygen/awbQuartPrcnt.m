%% awbQuartPrcnt
% Finds the 25 percentile for each of the NeuronResponses. 
% Need to have NeuronResponse loaded.

%%
options.version.awbQuartPrcnt = 'v1_20160421';
%gets the sub fields for each condition
names1 = fieldnames(NeuronResponse);
namesIndel= strncmp(names1, 'ExdeltaFOverF', 8);
index = find(namesIndel == 1);

%This next part finds the 25 percentile for each neuron in that NeuronResponse datasets.

for i=1:4; % 4 conditions, not most elegant %length(index)
    ID = index(i);
    NameI = char(names1(ID));
    
    [~,idx1] = size(NeuronResponse.(NameI));
    for iii= 1:idx1
        pcFzero.(NameI)(1,iii)= prctile(NeuronResponse.(NameI)(1:5400,iii),25);
    end
end

%% Substracts the 25 percentile value from peak values

for i=1:4; % 4 conditions, not most elegant %length(index)
    ID = index(i);
    NameI = char(names1(ID));
    NameS = char(strcat(names1(ID),'_Peak_mean'));
    percentileCorrected.(NameS) = NeuronResponse.(NameS) - pcFzero.(NameI);
end

clearvars names1 NameI idx1 i iii ID index namesIndel
