%pharynxTracker
% For tracking of fluorescent pharynxes of npr-1 worms in clumps.
% Input: in a folder have inverted avi (predominantly white). Creates
% background image by iteslf.

%% Create background Image
%-- frameinterval used for creating background image
frameinterval = 10;

BackgroundProduction_V4(frameinterval);

%% Read movie and track centroid coordinates of pharynx
flnms=dir('*.avi'); %create structure from filenames

MovieName =(flnms.name);

FileInfo = VideoReader(MovieName);

%Read background image
background = imread('background.tiff');

%imshow(background);
Levelbackground = 0.001; %%%Level = 0.1;
BW = ~im2bw(background, Levelbackground);

%%
for Frame = 1:FileInfo.NumberOfFrames
    %Get frame
    Mov.cdata = read(FileInfo, Frame);
    
    %subtract the background from the frame
    %the image becomes inverted with this operation
    Movsubtract = imsubtract(background, Mov.cdata); 
    
    % Convert frame to a binary image using auto thresholding
    LevelThresh = 0.08; % above 0.06 was good on test movie.

    BW = im2bw(Movsubtract, LevelThresh);
    %figure; imagesc(BW)
    
    % Identify all objects
    [L,NUM] = bwlabel(BW);
    STATS = regionprops(L, {'Area', 'Centroid', 'Eccentricity', 'MajorAxisLength'});
    
    %Want to get centroid position of biggest.
%     if NUM > 1
%         
%     end
    
    %Get centroid position
    if NUM > 0.7 
        Tracks.WormCoordinates(1:2,Frame) = STATS.Centroid;
    else
        Tracks.WormCoordinates(1:2,Frame) = [NaN;NaN];
    end
end

%Get speed (based on centroid position
Tracks.WormSpeed = abs(diff(sqrt(Tracks.WormCoordinates(1,:).^2 + Tracks.WormCoordinates(2,:).^2)));

CurrentFolder = pwd;
[~, deepestFolder, ~] = fileparts(pwd);

save (([strcat(CurrentFolder,'/',deepestFolder,'_track') '.mat']),'Tracks', 'LevelThresh','Levelbackground');

figure;plot(Tracks.WormSpeed)
title(deepestFolder)

clearvars STATS Tracks LevelThresh Levelbackground CurrentFolder deepestFolder L NUM BW Movsubtract flnms Mov MovieName FileInfo background