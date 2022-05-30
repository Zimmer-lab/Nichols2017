clear all

FigureN =7;

MainDir = pwd;
 
FolderList = mywbGetDataFolders; %to exclude a dataset put & symbol in front of foldername
 
NumDataSets = length(FolderList);
 
for i = 1:4;
    datasetN =i;
    
    cd(FolderList{datasetN});
    
    %% TotalPharynxTracks Modified
    % makes a image with the coordinates colour labelled on top of the 
    % background image.

    %load backgroud
    background = imread('background.tiff');

    %load worm coordinates
    flnms=dir('*_track.mat'); %create structure from filenames
    load(flnms.name);

    %%

    SlideSpeedQuiClass

%%
    %INPUT:
    colourScheme = SlideSpeed; %SlideSpeed or Active
    %TIME: linspace(1,150,length(Tracks.WormCoordinates));

    figure(FigureN);
    subplot(2,2,i)
    imagesc(background)
    hold on;
    %scatter(Tracks.WormCoordinates(1,1:end),Tracks.WormCoordinates(2,1:end),5,colourScheme)
    z = zeros(size(Tracks.WormCoordinates(2,3:1497)));
    surface([Tracks.WormCoordinates(1,3:1497);Tracks.WormCoordinates(1,3:1497)],[Tracks.WormCoordinates(2,3:1497);Tracks.WormCoordinates(2,3:1497)],[z;z],[colourScheme;colourScheme],...
            'facecol','no',...
            'edgecol','interp',...
            'linew',2);
    caxis([0,50]); %Speed
    %caxis([-0.2,1.2]); %Q classification
    
    %saves in current directory
    %[~, deepestFolder, ~] = fileparts(pwd)
    %filename = [strcat(pwd,'/PharnyxTracks_',deepestFolder,'.tiff')];
    %print('-dtiff','-r300', filename); 

    clearvars background deepestFolder filename;
    
    cd(MainDir);
    
end