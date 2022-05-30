%% INCOMPLETE had problems sizing the subplots

MainDir = strcat(pwd,'/_movie');

%makes subfolder for movie files
if exist('_movie','dir') < 1;
    mkdir('_movie');
end

basename      = '*.avi';
flnms=dir(basename); %create structure from filenames

RawMovieName = flnms.name;
FileInfo = VideoReader(RawMovieName);

c = linspace(1,150,length(Tracks.WormCoordinates));
count=0;

%%
[~, deepestFolder, ~] = fileparts(pwd);

load(strcat(deepestFolder,'_track.mat'));

%Sliding window for speed 
SlideBin = 1; %in seconds must be divisible by 0.2.
fps = 5;

%Remove this border amount (no sliding window there)
Border = floor((SlideBin/2)*fps); %CAREFUL FLOOR may not work well for every SlideBin size. Does for 1s

for iii = (Border+1):(length(Tracks.WormSpeed)-Border);
    SlideSpeed(1,iii-Border) = mean(Tracks.WormSpeed((iii-Border):(iii+Border)));
end
clearvars iii fps deepestFolder Border 
%%

for Frame = 1:150;
    %get current frame
    Mov = read(FileInfo, Frame);
    
    %plot current frame
    figure;

    h=subplot(2,1,1);
    imagesc(Mov)
    hold on
    scatter(Tracks.WormCoordinates(1,Frame),Tracks.WormCoordinates(2,Frame),20,c(Frame))
    set(h,'position',[3 86 680 500]);

    
    subplot(2,1,2)
    plot(SlideSpeed);
    hold on;
    if Frame >= 3
        scatter(SlideSpeed(1,Frame-3),Frame-3,'filled')
    end
    
    count=count+1;

    count1= num2str(count);

    filename = [strcat(MainDir,'/PharnyxTrackMovie_',count1,'.tiff')];

    print('-dtiff','-r300', filename); 
    close all
end

