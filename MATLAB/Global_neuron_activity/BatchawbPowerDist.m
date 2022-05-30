%% BatchawbPowerDist
% This script will calculate the RMS (or another analysis i.e. mean) of all neurons from many datasets.
% To plot run PlotPowerDists
%use & in front of folder name to exclude that folder from analysis.
clear all

ResultsStructFilename = 'PowerDist20161005_mean_24bins'; %This structure will be saved in the top folder.

xcentres = (0:0.06:1.4); %For binning and x axis of histograms.
                         %Data needs to be binned as to average across 
                         %datasets number of neurons falling into RMS bins is calculated.

Analysis = @mean; %put in function e.g. @rms @mean 

options.extraExclusionList = {'BAGL','BAGR','AQR','URXL','URXR','IL2DL','IL2DR'};

plotflag = 0; % 0 is off, 1 is on, this is for the awbPowerDist individual plots.
        
QuiesceBoutFlag = 1; % 0 is off and will calculate the analysis for the range specificed. 1 is on, will calculate range automatically from the QuiescentState.m

options.rangeSeconds = [1:1080];  % i.e. [1:100,200:400] % in seconds so it can be compared across recordings.

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
MainDir = pwd;

FolderList = mywbGetDataFolders;
 
NumDataSets = length(FolderList);

PowerDistributions = struct;
PowerDistributions.bins = xcentres;
PowerDistributions.Analysis = Analysis;

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), '');
 
for i = 1:NumDataSets %Folder loop
    
    load(ResultsStructFilename);

    cd(FolderList{i})
    
    awbPowerDist; %runs for individual datasets.
    
    NameO1 = 'ExpID';   

    if isfield(PowerDistributions, (NameO1)) >0.5;
        count = length(PowerDistributions.(NameO1))+1;
    else
        count=1;
    end

    PowerDistributions.(NameO1){count}= wbstruct.trialname;
    
    if QuiesceBoutFlag == 1; %saves for either the QuiesceBoutFlag on or off (i.e. Range) conditions. 
        PowerDistributions.BinnedQuiesceAnalysed(count,:)= BinnedQuiesceAnalysed(1,:);
        PowerDistributions.BinnedActiveAnalysed(count,:)= BinnedActiveAnalysed(1,:);
    else
        PowerDistributions.BinnedRangeAnalysed(count,:)= BinnedRangeAnalysed(1,:);
    end
    
    PowerDistributions.NeuronNum(count,1)= NeuronNum(1,1);
    
    cd(MainDir)
    dateRun = datestr(now);
    save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'PowerDistributions','dateRun','Analysis'); 
    
end

if QuiesceBoutFlag == 1; %plots for either the QuiesceBoutFlag on or off (i.e. Range) conditions.
    figure;plot(xcentres,mean(PowerDistributions.BinnedQuiesceAnalysed),'b',xcentres,mean(PowerDistributions.BinnedActiveAnalysed),'r')
else
    figure;plot(xcentres,mean(PowerDistributions.BinnedRangeAnalysed),'g')
end
    clearvars -except PowerDistributions NumDataSets xcentres
