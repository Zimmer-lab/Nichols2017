
% generate animated plot of red line moving along heatmap and save to movie

% open heatmap figure and assign graphics object handle
heatmap = figure(1);

% draw red line at start point
ylimit = ylim;
hold on
ml = line('XData',[1 1],'YData',[ylimit(1,1) ylimit(1,2)],'Color','r','linewidth',5);
hold off
axis manual

% define number of loops depending on length of recording
% 0908astarved = 2366; 1029dfasted = 2204;
XD = 1:1:2366; % endpoint = number of timepoints as in wbstruct.tv;
%check length seconds?)

% preallocate movie structure
loops = length(XD);
M(loops) = struct('cdata',[],'colormap',[]);


for k = 1:length(XD)
    
    ml.XData = [XD(1,k) XD(1,k)];
    drawnow
    M(k) = getframe(heatmap);
    
end
    
% save movie structure to video file
v = VideoWriter('AnimatedHeatmapStarved_recolor2.mp4','MPEG-4');
open(v)
writeVideo(v,M);
close(v)








    
