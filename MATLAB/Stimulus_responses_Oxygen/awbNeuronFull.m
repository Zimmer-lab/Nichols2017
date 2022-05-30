%% awbNeuronFull
%This script retrieves the full range of a neuron of interest. This will be
%done automatically for all recordings in a folder if you use the batch
%version (BatchawbNeuronFull).

%Define the neuron of interest
NeID1='RIS'; %'Name' or Number (with no ')

condition1 = 'npr1Let'; %i.e.npr1Post for npr-1 postlethargus recordings.

ResultsStructFilename1 = 'FullRISresponses_20161124'; %Name of new struct

MasterFolder1 = '/Users/nichols/Documents/Imaging/URX_responses'; %Where new struct is saved

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
% NOTES for improvement:
% Include so it will go over folders in a condition and get both R and L
% neurons
% 
% Define the range to measure (in seconds into the experiment).
% T1=0;
% T2=1079.8;
% Also, check that only non-exluced IDs are taken into account.

%%
options.version.awbNeuronFull = 'v3_20160920';
%added f0, recalculation of raw data trace.
%% make compatible with batch version
if ~exist('NeID','var');
    NeID =NeID1;
end
clearvars NeID1;

if ~exist('condition','var');
    condition =condition1;
end
clearvars condition1;

if ~exist('ResultsStructFilename','var');
    ResultsStructFilename =ResultsStructFilename1;
end
clearvars ResultsStructFilename1;

if ~exist('MasterFolder','var');
    MasterFolder =MasterFolder1;
end
clearvars MasterFolder1;
%% 
wbload;
%NeuronF =wbgettrace(NeID);
%NeuronF =wbgettrace(NeID, wbstruct,'deltaFOverF'); %FINDME: Use for non-bc traces

Neuron = NeID;
% Get simple neuron ID number
[~, rw] = size(wbstruct.simple.ID);
NeuronIdx = [];
for ii = 1: rw;
    idx = strcmp(wbstruct.simple.ID{1,ii}, Neuron);
    if idx == 1;
        NeuronIdx = ii;
        disp(['found neuron: ',Neuron,' at: ',mat2str(NeuronIdx)]); 
    end
end

if isempty(NeuronIdx)
    disp(['Did not find ',Neuron]);
    return
end

NeuronF = wbstruct.simple.deltaFOverF(:,NeuronIdx);
NeuronF_bc = wbstruct.simple.deltaFOverF_bc(:,NeuronIdx);

NameO1 = char('ExpID');
NameO2 = char('NeID');
NameO3 = char('deltaFOverF_bc');
NameO4 = char('Fzero');
NameO5 = 'rawF';

CurrentDirectory = pwd;
cd(MasterFolder);

if exist([ResultsStructFilename '.mat']) == 2
    load(ResultsStructFilename);
else
    NeuronResponse = struct;
end

cd(CurrentDirectory);

if isfield(NeuronResponse, (condition)) >0.5;
    count = length(NeuronResponse.(condition).(NameO2))+1;
else
    count=1;
end

tvi = ((0:5399)/5)'; %time vector extrapolated
tvo =wbstruct.tv; %time vector original
NeuronResponse.tv= (0:0.2:1079.8);

%Recalculate raw trace
Fzero = wbstruct.simple.f0(1,NeuronIdx);
NeuronFRaw = (NeuronF_bc*Fzero)+Fzero;

NeuronResponse.(condition).(NameO1){count,1}= wbstruct.trialname;
NeuronResponse.(condition).(NameO2){count,1}= NeID;
NeuronResponse.(condition).(NameO3)(:,count)=interp1(tvo,NeuronF_bc(:,1),tvi); 
NeuronResponse.(condition).(NameO4)(:,count)= Fzero;
NeuronResponse.(condition).(NameO5)(:,count)= interp1(tvo,NeuronFRaw(:,1),tvi);


%%
dateRun = datestr(now);
save (([strcat(MasterFolder,'/',ResultsStructFilename) '.mat']), 'NeuronResponse','dateRun', 'options'); 

clearvars -except MainDir ResultsStructFilename FolderList NumDataSets NeID condition MasterFolder NeuronResponse NeIDs
