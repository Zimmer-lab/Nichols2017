%% awbNeuronPeak
% This script will take a specified subset (e.g. the stimulus period) of all the "ExdeltaFOverF" 
% (extrapolated deltaFOverF of a neuron) from BatchawbNeuronFull. This is
% then saved in the NeuronResponse structure. It can only be run once of
% a NeuronResponse structure.
% peak of URX... is from 366 to 375s
% the tv is X = (sec + 0.2)/0.2


%%
ResultsStructFilename = 'FullAQRresponses20160421.mat'; %File name from which you are extracting a peak response.

PeakResultsStructFilename = 'SustainedAQRresponses20160421.mat'; %File name to which you want to save peak response.

MasterFolder = '/Users/nichols/Documents/Imaging/URX_responses/_mat_data';%pwd; %'/Users/nichols/Documents/Imaging/AQR responses';

%Peak values in seconds
PeakStart = 420;
PeakEnd = 720;

%% Other examples:
%sustained = last 5mins of stim
% PeakStart = 420; % PeakEnd = 720;

%AQR npr1 Let and Pre
% PeakStart = 367; % PeakEnd = 377;

%AQR N2 Let
% PeakStart = 374; % PeakEnd = 384;

%AQR N2 PreLet
% PeakStart = 378; % PeakEnd = 388;

%AQR N2 Let (used for Recess 2015)
% PeakStart = 375; % PeakEnd = 385;

%URX
% PeakStart = 366; % PeakEnd = 375;
%%

cd(MasterFolder);

load(ResultsStructFilename);

names = fieldnames(NeuronResponse);

namesIndel= strncmp(names, 'ExdeltaFOverF', 8);
index = find(namesIndel == 1);

P1 = round(PeakStart+0.2)/0.2;
P2 = round(PeakEnd+0.2)/0.2;

%This next copies the desired peak response into a new field of the
%results struct and also creates a mean of those.

for i=1:length(index); 
    ID = index(i);
    NameI = char(names(ID));
    NameO1 = char(strcat(names(ID),'_Peak'));
    NameO2 = char(strcat(names(ID),'_Peak_mean'));
    
    NeuronResponse.(NameO1) = NeuronResponse.(NameI)(P1:P2,1:end);
    NeuronResponse.(NameO2) = mean(NeuronResponse.(NameO1));
end
 
OriginalData = ResultsStructFilename;
save (([strcat(MasterFolder,'/','peak_',PeakResultsStructFilename)]), 'NeuronResponse','PeakStart', 'PeakEnd','OriginalData');