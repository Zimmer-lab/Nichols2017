%% TotalPharynxTracks 
% makes a image with the coordinates colour labelled on top of the 
% background image.

%load backgroud
background = imread('background.tiff');

%load worm coordinates
flnms=dir('*_track.mat'); %create structure from filenames
load(flnms.name);

SlideSpeedQuiClass

%%
    
colourScheme = SlideSpeed;
%TIME: linspace(1,150,length(Tracks.WormCoordinates));

figure;imagesc(background)
hold on;
%scatter(Tracks.WormCoordinates(1,3:1497),Tracks.WormCoordinates(2,3:1497),20,colourScheme,'none')%'filled'
z = zeros(size(Tracks.WormCoordinates(2,3:1497)));
surface([Tracks.WormCoordinates(1,3:1497);Tracks.WormCoordinates(1,3:1497)],[Tracks.WormCoordinates(2,3:1497);Tracks.WormCoordinates(2,3:1497)],[z;z],[colourScheme;colourScheme],...
        'facecol','no',...
        'edgecol','interp',...
        'linew',4);
caxis([0,50]); 
    
%saves in current directory
[~, deepestFolder, ~] = fileparts(pwd);

filename = [strcat(pwd,'/PharnyxTracks_',deepestFolder,'.tiff')];

%print('-dtiff','-r300', filename); 

clearvars background deepestFolder filename