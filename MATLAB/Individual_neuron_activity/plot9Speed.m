%This script will take the first 9 tracks which go over the defined period
%and plot the speed and stimuli for these. Works on one loaded als file.

%Can change these two parameters
PreStim=540; %in frames
PostStim=1620; %in frames


speed=NaN(2160,9);
StimStart=4680; %in frames
count=1;
TrackN=15;


while count<=9; 
        if ((find(Tracks(TrackN).Frames==(StimStart-PreStim)))>=1) & ((find(Tracks(TrackN).Frames==(StimStart+PostStim-1)))>=1);
            speed(:,count)=Tracks(TrackN).Speed(4140:6299);
            TrackN=TrackN+1;
            count=count+1;
        else
            TrackN=TrackN+1;
        end
end


figure;
for wormnum = 1:9
    subplot(3,3,wormnum);
    plot(speed(:,wormnum));
    axis([1 2160 0 0.2]); %Can change axis here if needed
    xlabel('Time (frames)','FontSize',13);
    ylabel('Speed','FontSize',13);
    line('XData', [PreStim PreStim], 'YData', [-1 2.5], 'LineStyle', '-')
    line('XData', [(PreStim+1080) (PreStim+1080)], 'YData', [-1 2.5], 'LineStyle', '-')
    line('XData', [0 5000], 'YData', [0.008 0.008], 'LineStyle', '-')
end