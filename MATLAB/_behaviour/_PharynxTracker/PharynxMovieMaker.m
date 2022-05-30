%Makes a movie of the tracking and plots as red for awake and blue for
%quiescent

clear all

cutoff =3; 
%1.875 for 20x
%3 for 40x

FolderName = 'Smovie';

%From frame:
FrameStart = 550;

%To frame:
FrameEnd = 650;%500;

%start from 0 for counting?
startFlag = 0; 
%ATN!: 3:1497; %1500 is total recording,
%Note: SlideSpeed has 1s sliding window so start at frame =3 to colour properly.

%%
MainDir = strcat(pwd,strcat('/_',FolderName));

samplerate = 5;
pixelsize = 0.00317; %OLD:0.0027;

%makes subfolder for movie files
if exist(strcat('_',FolderName),'dir') < 1;
    mkdir(strcat('_',FolderName));
end

basename      = '*.avi';
flnms=dir(basename); %create structure from filenames

RawMovieName = flnms.name;
FileInfo = VideoReader(RawMovieName);

%Load tracks
[~, deepestFolder, ~] = fileparts(pwd);
load(strcat(deepestFolder,'_track.mat'));

count=372; %ATN!: 0

SlideSpeedQuiClass

%%

for Frame = FrameStart:FrameEnd %ATN!: 3:1497; %1500 is total recording, Note: SlideSpeed has 1s sliding window so start at frame =3 to colour properly.
    %%get current frame
    Mov = read(FileInfo, Frame);
    
    %Determine colour to plot (note that Active is based on SlideSpeed and
    %therefore t=1 for Active is t=3 for Movie.
    if Active(Frame-2) == 1;
        c = [1 0 0];
    else
        c = [0 0 1];
    end
    
    %plot current frame
    %figure; image(Mov)
    %covert to grayscale
    GrayI = rgb2gray(Mov);
    figure; imshow(GrayI);

%     worm_imadjust = imadjust(GrayI);
%     figure, imshow(worm_imadjust);

    caxis([210, 256])
    %cmap = contrast(Mov);
    
    %%
    hold on
    scatter(Tracks.WormCoordinates(1,Frame),Tracks.WormCoordinates(2,Frame),20,c,'filled')
    axis off
    %% !!! Second sctatter point to compare convex tracking
    hold on
    %scatter(Tracks.WormCoordinates(1,Frame),Tracks.WormCoordinates(2,Frame),20,'c*')
    
    %% Plot scale bar 0.1mm
    line('XData', [550, (550+((1/pixelsize)/10))], 'YData', [450, 450],'color','k','LineStyle', '-','Linewidth',5);
    %text(550,430,'0.1mm','Fontsize',16)
    
    %% calulate seconds
    if startFlag == 0
        FrameS = Frame - FrameStart;
    else
        FrameS = Frame;
    end
    
    hold on
        if ceil(FrameS/samplerate) == floor(FrameS/samplerate)
            seconds = FrameS/samplerate;
            text(120,430,strcat(num2str(seconds),'sec'),'Fontsize',20);
            prevseconds = seconds;
        else
            text(120,430,strcat(num2str(prevseconds),'sec'),'Fontsize',20);
        end
    text(120,100,'Lethargus','Fontsize',20)

    
    %%
    count=count+1;
    
    count1= num2str(count);
    
    filename = strcat(MainDir,'/PharnyxTrackMovie_',count1,'.tiff');
    
    print('-dtiff','-r300', filename);
    close all
end

CurrentFolder = pwd;
[~, deepestFolder, ~] = fileparts(pwd);

save (([strcat(MainDir,'/','MovieInfo') '.mat']),'cutoff', 'FrameStart','FrameEnd');


