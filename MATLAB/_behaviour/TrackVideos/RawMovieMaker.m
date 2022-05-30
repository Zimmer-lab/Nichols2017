%% Worm movie maker
TrackNumbers = 17;
filename = 'CX13663_O2_11long_6mShifts_20160718_Z2_full_adults_A2201607181719_mjpeg_mp4.mp4';
fullTrack = 0; %1 yes, 0 no then define time range below
load('CX13663_O2_11long_6mShifts_20160718_Z2_full_adults_A2201607181719_mjpeg_v2_tracks_als.mat');

% inframes
startT = 10*3;
endT = 40*3;

useMP4 = 1;

samplerate = 3;


%%
% Note you may need to change the worm box dimensions

pixelsize = 0.0276; %pixelsize in mm

if useMP4 == 1;
    mv = VideoPlayer(filename, 'Verbose', false, 'ShowTime', false);
else
    mv = VideoReader(filename);
end;

for aa = 1:length(TrackNumbers);
    currentTrackNum = TrackNumbers(aa);
    CurrentTrack = Tracks(currentTrackNum);
    
    if fullTrack == 1;
        lowI = (Tracks(1,currentTrackNum).Frames(1,1))+60;
        highI = (Tracks(1,currentTrackNum).Frames(1,end))-60;
    else
        lowI = startT;
        highI = endT;
    end
    
    [~, trackmoviename, ~] = fileparts(filename);
    
    close all
    samplerate = 3;
    trackmovie = VideoWriter([trackmoviename 'Trackno' num2str(currentTrackNum)]);
    
    %Movie frame rate (3 = realtime if sample rate is 3).
    trackmovie.FrameRate = 9;
    open(trackmovie);
    firstRun = 1;
    %%
    for currentframe = lowI:highI
        
        if useMP4 ==1;
            %-- move to first frame of interest within movie
            if firstRun
                %-- VideoPlayer starts with FrameNumber 0 ... all frames are
                %-- shifted by 1.
                mv.nextFrame(currentframe-1);
                firstRun = 0;
            end;
            %-- get image information at current frame and immediately move
            %-- to the next one for the next iteration.
            fr = mv.getFrameUInt8();
            mv.nextFrame();
        else
            fr = read(mv, currentframe);
        end;
        
        %Worm box dimensions
        cptrx = uint16(round(CurrentTrack.Path(currentframe,1)-30:CurrentTrack.Path(currentframe,1)+70));
        cptry = uint16(round(CurrentTrack.Path(currentframe,2)-30:CurrentTrack.Path(currentframe,2)+70));
        
        wormwindow = fr(cptry,cptrx,:);
        
        figure(1);
        
        image(wormwindow);
        axis off;
        axis image;
        
        hold on
        
        % calulate seconds
        if ceil(currentframe/3) == floor(currentframe/3)
            seconds = currentframe/3;
            text(10,90,strcat(num2str(seconds),'sec'),'Fontsize',16);
            prevseconds = seconds;
        else
            text(10,90,strcat(num2str(prevseconds),'sec'),'Fontsize',16);
        end
        
        hold on
        
        %Plot scale bar
        line('XData', [50, (50+(1/pixelsize))], 'YData', [95, 95],'color','k','LineStyle', '-','Linewidth',5);
        text(50,90,'1mm','Fontsize',16)
        
        speed = trackmovie.FrameRate/samplerate;
        text(10,95,strcat('Speed: x',num2str(speed)),'Fontsize',16)
        
        videoframe=getframe(gcf);
        writeVideo(trackmovie,videoframe);
        hold off
    end
    %%
    close(trackmovie);
    clearvars trackmovie
end
