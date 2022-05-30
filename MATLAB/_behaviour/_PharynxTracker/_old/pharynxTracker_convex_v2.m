%pharynxTracker
% For tracking of fluorescent pharynxes of npr-1 worms in clumps.
% Input: in a folder have inverted avi (predominantly white). Creates
% background image by iteslf.

options.version = 'pharynxTracker_convex_v2';

%% Notes on v2
% Improved tracking by using convex hull and getting the centroid of this.
% This is important as the 20x recordings often have the pharynx in two
% parts. This also works very similiar, if not better, for the clumping
% animals. Also, improved so that only objects that are 30pixels from the
% centroid of the largest area are included.

% %% Create background Image
% %-- frameinterval used for creating background image
% frameinterval = 10;
% 
% BackgroundProduction_V4(frameinterval);

%% Read movie and track centroid coordinates of pharynx
flnms=dir('*.avi'); %create structure from filenames

MovieName =(flnms.name);

FileInfo = VideoReader(MovieName);

%Read background image
background = imread('background.tiff');

%imshow(background);
Levelbackground = 0.001; %%%Level = 0.1;
BW = ~im2bw(background, Levelbackground);

Tracks.WormCoordinates1 = nan(2,FileInfo.NumberOfFrames);

%%
for Frame = 1:FileInfo.NumberOfFrames;
    %Get frame
    Mov.cdata = read(FileInfo, Frame);
    
    %subtract the background from the frame
    %the image becomes inverted with this operation
    Movsubtract = imsubtract(background, Mov.cdata); 
    %figure; imagesc(Mov.cdata)
    
    % Convert frame to a binary image using auto thresholding
    LevelThresh = 0.08; % above 0.06 was good on test movie. % used 0.08 for everything

    BW = im2bw(Movsubtract, LevelThresh);
    %figure; imagesc(BW)
    
    % Identify all objects
    [L,NUM] = bwlabel(BW);
    STATS = regionprops(L, {'Area', 'Centroid', 'Eccentricity', 'MajorAxisLength', 'ConvexHull','Perimeter'});
    %figure; imagesc(L)
    
    %%only including areas above a certain size (5 pixels).
    BigAreas  = 1:NUM;
    LargestCentroid = 1;
    
    %Find largest centroid:
     if NUM > 1
         [Areas, ~] = size(STATS);
         AreaSizes = NaN(Areas, 1);
         for ii = 1:Areas;
            AreaSizes(ii,1) = STATS(ii,1).Area;
         end
     [~,LargestArea] = max(AreaSizes);
     LargestCentroid = STATS(LargestArea,1).Centroid;    
     BigAreas(AreaSizes < 5) = [];
     end

     %Find areas within allowed distance of the first. 30pixels
     rangeXY = 30;
     IncObjectDist = [];
        
     for ii = 1:NUM;
         if  LargestCentroid(1,1)+rangeXY > STATS(ii,1).Centroid(1,1)... 
             && STATS(ii,1).Centroid(1,1) > LargestCentroid(1,1)-rangeXY...
             && LargestCentroid(1,2)+rangeXY > STATS(ii,1).Centroid(1,2)...
             && STATS(ii,1).Centroid(1,2) > LargestCentroid(1,2)-rangeXY
                IncObjectDist = [IncObjectDist, ii];
         end
     end
     
     %See if object satifys both the min area size and min distance from
     %largest centroid.
     Satisfys = ismember(IncObjectDist,BigAreas);
     IncObjectDistArea = IncObjectDist(Satisfys);
     
     
    if NUM == 0; %in case there is no centroid.
       Tracks.WormCoordinates(1:2,Frame) = [NaN;NaN];
       disp(strcat('No centroid at frame:',mat2str(Frame)));
    end
    
        
    if NUM > 1;
        ConHullPoints =[];
        [~,NUMobj] = size(IncObjectDistArea);
        for n = 1:NUMobj
            ConHullPoints = [ConHullPoints; (STATS((IncObjectDistArea(n)), 1).ConvexHull)];
        end
        ConHull = convhull(ConHullPoints(:,1),ConHullPoints(:,2));    
        x =  ConHullPoints(:,1);
        y = ConHullPoints(:,2);
        [GEOM, ~, ~] = polygeom(x(ConHull),y(ConHull)); %must be in correct order.    
        
        %Get centroid position convex area.
        Centroid = [GEOM(1,2),GEOM(1,3)];
    else
        Centroid = STATS(1,1).Centroid;
    end
    
%     figure; plot(x(ConHull),y(ConHull),'r-',x,y,'b*') 
%     hold on
%     scatter(GEOM(1,2),GEOM(1,3),'k','filled')

     
%     figure; imagesc(L)
%     hold on
%     scatter(Centroid(1,1),Centroid (1,2), 'g','filled');

    %Get centroid position
    Tracks.WormCoordinates(1:2,Frame) = Centroid;


end

%%
%Get speed (based on centroid position)
PosChange =diff(Tracks.WormCoordinates');
DistChange = sqrt(PosChange(:,1).^2 + PosChange(:,2).^2);
Tracks.WormSpeed = DistChange/0.2; %distance travelled/time

CurrentFolder = pwd;
[~, deepestFolder, ~] = fileparts(pwd);

save (([strcat(CurrentFolder,'/',deepestFolder,'_track') '.mat']),'Tracks', 'LevelThresh','Levelbackground','options');

figure;
hold on;
plot(Tracks.WormSpeed,'b')
title(deepestFolder)

%clearvars STATS Tracks LevelThresh Levelbackground CurrentFolder deepestFolder L NUM BW Movsubtract flnms Mov MovieName FileInfo background