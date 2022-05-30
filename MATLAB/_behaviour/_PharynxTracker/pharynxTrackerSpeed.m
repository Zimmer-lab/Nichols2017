MainDir = pwd;
 
FolderList = mywbGetDataFolders; %to exclude a dataset put & symbol in front of foldername
 
NumDataSets = length(FolderList);
 
 
for ii = 1:NumDataSets
    
    cd(FolderList{ii})
    
    [~, deepestFolder, ~] = fileparts(pwd);
    
    load(strcat(deepestFolder,'_track.mat'));
    
    Speed(ii,:) = Tracks.WormSpeed;
    
    cd(MainDir)

    %% Use the reshape function for databinning
    binning = 5; %!!!!!!!!!!!!! 25 %Frames therefore 5 sec. Note Let assays bin for 5 seconds.... but binning = 15.

    BinWin = binning;

    Len = length(Tracks.WormSpeed);

    BinNum = floor(Len/BinWin); 

    BinSpeed(ii,:) = sum(reshape(Tracks.WormSpeed(1:BinNum*BinWin),BinWin,BinNum));

    
end


CurrentFolder = pwd;
[~, deepestFolder, ~] = fileparts(pwd);

save (([strcat(CurrentFolder,'/',deepestFolder,'_track') '.mat']),'Speed','BinSpeed','binning');

clearvars BinNum BinWin CurrentFolder FolderList Len LevelThresh Levelbackground MainDir NumDataSets deepestFolder ii

%% Plotting

toPlot = BinSpeed;
[L,~] =size(toPlot);

for ii = 1:L
    BinnedSpeed(ii,:) = hist(toPlot(ii,:),100);
end

BinnedSpeed=BinnedSpeed/300;

figure;plot(mean(BinnedSpeed))

theMean = mean(mean(toPlot))

hold on
plot(mean(BinnedSpeed),'r')

figure;imagesc(BinSpeed);
caxis([0 200]);

 
%% Quiescence

%categorization parameters for speed:
cutoff = 15; % above which speed the worm is considered to be engaged in a motion bout
%roamthresh = 0.35; 

Active = BinSpeed > cutoff;

figure;imagesc(Active);

means = mean(Active');
mean(mean(means))
