%pharynxTracker
% For tracking of fluorescent pharynxes of npr-1 worms in clumps.
% Input: in a folder have inverted avi (predominantly white). Creates
% background image by iteslf.

%% Notes
% Could improve by adding convex hull function in case of splitting of
% pharynx.

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
    
    %Get centroid position of biggest area.
     if NUM > 1
         [Areas, ~] = size(STATS);
         AreaSizes = NaN(Areas, 1);
         for ii = 1:Areas;
            AreaSizes(ii,1) = STATS(ii,1).Area;
         end
     [~,LargestArea] = max(AreaSizes);
     LargestCentroid = STATS(LargestArea,1).Centroid;
     
     elseif NUM < 0.7 %in case there is no centroid.
     Tracks.WormCoordinates(1:2,Frame) = [NaN;NaN];
     
     else
     LargestCentroid = STATS.Centroid;
     
     end
     
    %figure; imagesc(L)
    %hold on
    %scatter(LargestCentroid(1,1),LargestCentroid (1,2), 'g','filled');

    %Get centroid position
    Tracks.WormCoordinates(1:2,Frame) = LargestCentroid;


end

%%
%Get speed (based on centroid position)
PosChange =diff(Tracks.WormCoordinates');
DistChange = sqrt(PosChange(:,1).^2 + PosChange(:,2).^2);
Tracks.WormSpeed = DistChange/0.2; %distance travelled/time

CurrentFolder = pwd;
[~, deepestFolder, ~] = fileparts(pwd);

save (([strcat(CurrentFolder,'/',deepestFolder,'_track') '.mat']),'Tracks', 'LevelThresh','Levelbackground');

figure;plot(Tracks.WormSpeed)
title(deepestFolder)

%clearvars STATS Tracks LevelThresh Levelbackground CurrentFolder deepestFolder L NUM BW Movsubtract flnms Mov MovieName FileInfo background