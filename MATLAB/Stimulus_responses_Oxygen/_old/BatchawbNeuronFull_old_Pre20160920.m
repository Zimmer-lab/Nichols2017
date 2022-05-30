%% BatchawbNeuronfull
% This script retrieves the full range of a neuron of interest for all
% recordings in a folder. It has to extrapolate in order to compare them.


%use & in front of folder name to exclude that folder from analysis.
clear all;

NeID='URXR'; %'Name', will have to run twice to get both L and R. ID is recording in the NeuronResponse struct.

%Change this to input new info

condition = 'npr1Let'; %i.e.npr1Post

ResultsStructFilename = 'FullURXresponses20160421'; %Name of new struct, you can add different conditions to the same struct.

MasterFolder = '/Users/nichols/Documents/Imaging/URX_responses'; %Where new struct is saved

% If you want to use non-bleach corrected traces (bc) you can do this in the awbNeuronFull search for: FINDME
%Don't forget to change it back!

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

MainDir = pwd;

cd(MasterFolder);

if exist([ResultsStructFilename '.mat']) == 2
    load(ResultsStructFilename);
else
    NeuronResponse = struct;
end

cd(MainDir);

save (([strcat(MasterFolder,'/',ResultsStructFilename) '.mat']), '');
 
for i = 1:NumDataSets;
    cd(MasterFolder);
    load(ResultsStructFilename);
    cd(MainDir);

    cd(FolderList{i});
    
    awbNeuronFull;

    cd(MainDir);
    
end

save (([strcat(MasterFolder,'/',ResultsStructFilename) '.mat']), 'NeuronResponse'); 
    clearvars -except NeuronResponse
