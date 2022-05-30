%% awbNeuResponseMaxDeriv
% Find mean of the top 5% frames of the derivative of neurons from
% a NeuronResponse structure.

%start at 365 to 367 for AQR npr1
RangeStartS = 360; %in seconds
RangeEndS = 385;

%360 to 380 for URX
%360 to 385 for AQR
%%
%options.version.awbNeuResponseMaxDeriv = 'v1_20160425';

%convert into frames
RangeStartF = round(RangeStartS*5); %The datasets are interpolated onto 5fps
RangeEndF =round(RangeEndS*5);

%gets the sub fields for each condition
names1 = fieldnames(NeuronResponse);
namesIndel= strncmp(names1, 'ExdeltaFOverF', 8);
index = find(namesIndel == 1);

%This next part finds the mean max derivative for each neuron in that NeuronResponse datasets.

for iii=1:4; % 4 conditions, not most elegant %length(index)
    ID = index(iii);
    NameI = char(names1(ID));
    
    %get derivatives
    changeF= deriv(NeuronResponse.(NameI)(RangeStartF:RangeEndF,:));
    %find 95 percentile value
    prctileValue = prctile(changeF,95);
    [~,idx2]=size(prctileValue);
    
    for ii = 1:idx2; %find indices of top 5% of deriv values and average them
        indexTopFive = find(changeF(:,ii) > prctileValue(:,ii));
        topFiveDeriv.(NameI)(:,ii) = mean(changeF(indexTopFive,ii));
    end
end
clearvars -except NeuronResponse topFiveDeriv