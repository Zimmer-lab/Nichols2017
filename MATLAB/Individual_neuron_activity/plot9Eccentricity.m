%This script will take the first 9 tracks which go over the defined period
%and plot the derivative of the eccentricity and stimuli for these. Works on one loaded als file.

%Can change these two parameters
PreStim=540; %in frames
PostStim=1620; %in frames


eccentricity=NaN(2160,9);
StimStart=4680; %in frames
count=1;
TrackN=20;


while count<=9; 
        if ((find(Tracks(TrackN).Frames==(StimStart-PreStim)))>=1) & ((find(Tracks(TrackN).Frames==(StimStart+PostStim-1)))>=1);
            eccentricity(:,count)=Tracks(TrackN).Eccentricity(4140:6299);
            TrackN=TrackN+1;
            count=count+1;
        else
            TrackN=TrackN+1;
        end
end

Diffeccentricity=diff(eccentricity);

figure;
for wormnum = 1:9
    subplot(3,3,wormnum);
    plot(Diffeccentricity(:,wormnum));
    axis([1 2160 0 0.2]); %Can change axis here if needed
    line('XData', [PreStim PreStim], 'YData', [-1 2.5], 'LineStyle', '-')
    line('XData', [(PreStim+1080) (PreStim+1080)], 'YData', [-1 2.5], 'LineStyle', '-')
    line('XData', [0 5000], 'YData', [0.0009 0.0009], 'LineStyle', '-')
end