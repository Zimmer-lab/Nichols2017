%% BatchawbNeuronfull
% This script retrieves the full range of a neuron of interest for all
% recordings in a folder. It has to extrapolate in order to compare them.
%use & in front of folder name to exclude that folder from analysis.
clear all;

NeIDs={'RIS'}; %'Name', will have to run twice to get both L and R. ID is recording in the NeuronResponse struct.

%Change this to input new info

condition = 'npr1Prelet'; %i.e.npr1Post

ResultsStructFilename = 'FullRISresponses20161124'; %Name of new struct, you can add different conditions to the same struct.

MasterFolder = '/Users/nichols/Documents/Imaging/O2neuron_responses'; %Where new struct is saved

% If you want to use non-bleach corrected traces (bc) you can do this in the awbNeuronFull search for: FINDME
%Don't forget to change it back!

%% %%%%%%%%%%%%%%%
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
    
    for ii =1:length(NeIDs);
        NeID= NeIDs{ii};
        awbNeuronFull;
    end
    cd(MainDir);
end

%% New F0
%condition = 'npr1Let';
FzeroRange = 730:790; %in sec
FzeroRange =(FzeroRange)*5;
[~,c] = size(NeuronResponse.(condition).rawF);
for NeuronNum = 1:c;
    data = NeuronResponse.(condition).rawF(FzeroRange,NeuronNum);
    newFzero(NeuronNum) = mean(data((data<prctile(data,20)),1));
    NeuronResponse.(condition).deltaFOverF_mean20pc(:,NeuronNum) = (NeuronResponse.(condition).rawF(:,NeuronNum)-newFzero(1,NeuronNum))/newFzero(1,NeuronNum);
end

%%
% for ii = 1:12;
%     figure; plot(NeuronResponse.(condition).deltaFOverF_mean20pc(:,ii))
% end


%% Find pairs and average them
[r,~] = size(NeuronResponse.(condition).ExpID);

datePosition = strfind(NeuronResponse.(condition).ExpID,'201');
RecordNames = {};

for iii = 1:r;
    CurrDatePosition = datePosition{iii,1}(1,1);
    RecordNames{iii,1} = NeuronResponse.(condition).ExpID{iii}(CurrDatePosition:(CurrDatePosition+8));
end

[rr,~]= size(RecordNames);
strMat = [];
for jj =1:rr;
    strA = RecordNames{jj,1};
    for iii =1:rr;
        strB = RecordNames{iii,1};
        strMat(jj,iii) = strcmp(strA,strB);
    end
end

L=bwlabel(strMat,4); %label connected periods of motion = motion bouts
expStats= {};
expStats=regionprops(L,'BoundingBox'); %create structure that contains duration and start / end of connected periods
[nRecordings, ~] = size(expStats);

nNeuronsPerRecording = [];
for iii = 1:nRecordings;
    nNeuronsPerRecording(iii,1) = expStats(iii, 1).BoundingBox(1,4);
end
clear expStats L strMat strB strA RecordNames CurrDatePosition datePosition rr

NeuronResponse.(condition).cumnNeuronsPerRecording = cumsum(nNeuronsPerRecording);

%% Get the real means for each recording
startingNeuron = 1;
NeuronResponse.(condition).pairsAveraged_raw = [];
for jj = 1:nRecordings;
    if length(startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))>1
        NeuronResponse.(condition).pairsAveraged_raw(jj,:) = mean((NeuronResponse.(condition).rawF(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(jj)+1;
    else
        NeuronResponse.(condition).pairsAveraged_raw(jj,:) = NeuronResponse.(condition).rawF(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj));
        startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(jj)+1;
    end
end
clear startingNeuron cumnNeuronsPerRecording

save (([strcat(MasterFolder,'/',ResultsStructFilename) '.mat']), 'NeuronResponse');
clearvars -except NeuronResponse