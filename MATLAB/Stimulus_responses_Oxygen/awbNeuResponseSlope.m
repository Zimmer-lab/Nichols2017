%% awbNeuResponseSlope
% Find slopes of neurons from a NeuronResponse structure.

%start at 365 to 367 for AQR npr1
SlopeStartS = 365; %in seconds
SlopeEndS = 367;

%%
%convert into frames
SlopeStartF = round(SlopeStartS*5); %The datasets are interpolated onto 5fps
SlopeEndF =round(SlopeEndS*5);

%options.version.awbQuartPrcnt = 'v1_20160421';
%gets the sub fields for each condition
names1 = fieldnames(NeuronResponse);
namesIndel= strncmp(names1, 'ExdeltaFOverF', 8);
index = find(namesIndel == 1);

%This next part finds the slope for each neuron in that NeuronResponse datasets.

SlopeDistance = SlopeEndF -SlopeStartF;
for i=1:4; % 4 conditions, not most elegant %length(index)
    ID = index(i);
    NameI = char(names1(ID));

    changeF= (NeuronResponse.(NameI)(SlopeEndF,:)) - (NeuronResponse.(NameI)(SlopeStartF,:));
    slope.(NameI)(1,:) =changeF/SlopeDistance;
end