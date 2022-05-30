%% awbNeuronFull
%This script retrieves the full range of a neuron of interest. This will be
%done automatically for all recordings in a folder if you use the batch
%version (BatchawbNeuronFull).

%Define the neuron of interest
NeID1='AQR'; %'Name' or Number (with no ')

condition1 = 'N2Let'; %i.e.npr1Post for npr-1 postlethargus recordings.

ResultsStructFilename1 = 'FullURXresponses_AN20150226j_ZIM504_1mMTFNGM_Let_O2_21_s_1705_'; %Name of new struct

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
options.version.awbNeuronFull = 'v2_20160421';
%added f0
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
NeuronF =wbgettrace(NeID);
%NeuronF =wbgettrace(NeID, wbstruct,'deltaFOverF'); %FINDME: Use for non-bc traces

NameO1 = char(strcat('ExpID_',condition));
NameO2 = char(strcat('NeID_',condition));
NameO3 = char(strcat('ExdeltaFOverF_',condition));
NameO4 = char(strcat('Fzero_',condition));

CurrentDirectory = pwd;

cd(MasterFolder);

if exist([ResultsStructFilename '.mat']) == 2
    load(ResultsStructFilename);
else
    NeuronResponse = struct;
end

cd(CurrentDirectory);

if isfield(NeuronResponse, (NameO2)) >0.5;
    count = length(NeuronResponse.(NameO2))+1;
else
    count=1;
end

tvi = ((0:5399)/5)'; %time vector extrapolated
tvo =wbstruct.tv; %time vector original

%Checks if neuron is in this dataset
if isnan(NeuronF);
    disp(['No ' NeID ' neuron in this datatset'])
    clearvars -except MainDir ResultsStructFilename FolderList NumDataSets NeID condition MasterFolder NeuronResponse
    return
end

NeuronResponse.tv= (0:0.2:1079.8);

NeuronResponse.(NameO1){count}= wbstruct.trialname;

NeuronResponse.(NameO2){count}= NeID;

NeuronResponse.(NameO3)(:,count)=interp1(tvo,NeuronF(:,1),tvi); %'extrap'

%get F0 of neurons

%find ID number of neuron of interest
[~,idx1] = size(wbstruct.simple.ID);
for i = 1: idx1
    [~,idx2] = size(wbstruct.simple.ID{1,i});
    if idx2 < 2;
        if iscell(wbstruct.simple.ID{1,i})
            if ~isempty(wbstruct.simple.ID{1,i}{1})
                if cell2mat(strfind(wbstruct.simple.ID{1,i}, NeID)) ==1
                    IDnum = i;
                end
            end
        else
            if cell2mat(strfind(wbstruct.simple.ID{1,i}, NeID)) ==1
            IDnum = i;
            end
        end
    end
end

if exist('IDnum');
    NeuronResponse.(NameO4)(:,count)= wbstruct.simple.f0(1,IDnum);
end

dateRun = datestr(now);
save (([strcat(MasterFolder,'/',ResultsStructFilename) '.mat']), 'NeuronResponse','dateRun', 'options'); 

clearvars -except MainDir ResultsStructFilename FolderList NumDataSets NeID condition MasterFolder NeuronResponse
