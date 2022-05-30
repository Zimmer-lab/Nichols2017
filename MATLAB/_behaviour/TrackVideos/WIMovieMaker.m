%% WormImages movie maker
TrackNumbers = 5:10;
filename = 'CX13663_O2_11long_9m_c_20160724b_Z4_full_adults_A1_201607241318_mjpeg_mp4.mp4';


for aa = 1:length(TrackNumbers);
    currentTrackNum = TrackNumbers(aa);
    lowI = Tracks(1,currentTrackNum).Frames(1,1);
    highI = Tracks(1,currentTrackNum).Frames(1,end);
    
    [~, trackmoviename, ~] = fileparts(filename);
    
    close all
    samplerate = 3;
    trackmovie = VideoWriter([trackmoviename 'Trackno' num2str(currentTrackNum)]);
    open(trackmovie);
    for iii = (lowI+60):(highI-60)
        
        figure(1);
        map = ([1, 1, 1; 0, 0, 0]);
        colormap(map)
        imagesc(Tracks(1, currentTrackNum).WormImages{1, iii},[0,1])
        [r,c] = size(Tracks(1, currentTrackNum).WormImages{1, iii});
        axis([-5 35 -5 35])
        
        hold on
        if FWS(currentTrackNum,round(iii/(1*samplerate))) == 1;
            col = 'r';
        elseif FWS(currentTrackNum,round(iii/(1*samplerate))) == 0;
            col = 'b';
        else
            col = 'w';
        end
        scatter(26,29,200,col,'filled')
        text(27,29,'FinalWakeState')
        
        hold on
        if aAllMotionState(currentTrackNum,round(iii/(5*samplerate))) == 1;
            col = 'r';
        elseif aAllMotionState(currentTrackNum,round(iii/(5*samplerate))) == 0;
            col = 'b';
        else
            col = 'w';
        end
        scatter(26,26,200,col,'filled')
        text(27,26,'MotionState TM')
        
        
        if ceil(iii/3) == floor(iii/3)
            seconds = iii/3;
            text(26,23,strcat(num2str(seconds),'sec'));
            prevseconds = seconds;
        else
            text(26,23,strcat(num2str(prevseconds),'sec'));
        end
        
        videoframe=getframe(gcf);
        writeVideo(trackmovie,videoframe);
        hold off
    end
    close(trackmovie);
    clearvars trackmovie
end
