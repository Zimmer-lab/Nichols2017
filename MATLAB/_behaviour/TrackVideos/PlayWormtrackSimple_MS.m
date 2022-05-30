function PlayWormtrackSimple(filename,currenttrackno,spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec,aAllMotionState,aAllEccen,aAllSpeed,useMP4)

samplerate = 3;

[~, trackmoviename, ~] = fileparts(filename);

if useMP4 == 1;
    mv = VideoPlayer(filename, 'Verbose', false, 'ShowTime', false);
else
    mv = VideoReader(filename);
end;


trackmovie = VideoWriter([trackmoviename 'PWTPTrackno' num2str(currenttrackno)]);



CurrentTrack = Tracks(currenttrackno);


CurrentPathX=uint16(round(CurrentTrack.SmoothX));

CurrentPathY=uint16(round(CurrentTrack.SmoothY));


trackfig=figure('Color',[1 1 1],'Position',[1 1 1500 1200]);


open(trackmovie);

cntplt = 1;

[~, NumOfBinnedFrames] = size(St);
firstRun = 1;


for cnt= 1:CurrentTrack.NumFrames;
    
  
    
currentframe = CurrentTrack.Frames(1)+cnt-1;
Bincurrentframe = round(currentframe/15);
if Bincurrentframe == 0;
    Bincurrentframe =1;
end

display(currentframe)

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
        
cptrx = uint16(round(CurrentTrack.Path(cnt,1)-50:CurrentTrack.Path(cnt,1)+50));

cptry = uint16(round(CurrentTrack.Path(cnt,2)-50:CurrentTrack.Path(cnt,2)+50));

wormwindow = fr(cptry,cptrx,:);

subplot(5, 1, [1 2]);


    image(wormwindow);
    
    axis off;
    axis image;
    
% if cnt == 1
%     
%     subplot(5, 1, 3); %axis(spdfigaxis);
% 
%     plot(aAllSpeed(currenttrackno,:),'k');
% 
%     hold on;
%         
%     plot  (Bincurrentframe,aAllSpeed(currenttrackno,Bincurrentframe),'o','MarkerEdgeColor','k',...
%                 'MarkerFaceColor',[.49 1 .63],...
%                 'MarkerSize',10);            
%     hold off;
%     
% end
% 
% if cnt == ((cntplt * samplerate * SBinWinSec) - round(samplerate * SBinWinSec / 2))  && cntplt <= NumOfBinnedFrames
% 
%   
%     
%     subplot(5, 1, 3);
% 
%     plot(SBinTrcksSpd(currenttrackno,:),'k');
% 
%     hold on;
%     
%     plot  (Bincurrentframe,SBinTrcksSpd(currenttrackno,Bincurrentframe),'o','MarkerEdgeColor','k',...
%                 'MarkerFaceColor',[.49 1 .63],...
%                 'MarkerSize',10);
%             
%     cntplt=cntplt+1;
%             
%     hold off;
%            
% end

    subplot(5, 1, 3);

    plot(SBinTrcksSpd(currenttrackno,:),'k');

    hold on;
    
    plot  (Bincurrentframe,SBinTrcksSpd(currenttrackno,Bincurrentframe),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
    cntplt=cntplt+1;
            
    hold off;
            

strfr = Tracks(currenttrackno).Frames(1);
endfr = Tracks(currenttrackno).Frames(end);

subplot(5, 1, 4);

plot(aAllEccen(currenttrackno,:),'k');


hold on;

%     for idx = 1: NumOmegas;
%         
%         turnstart = CurrentTrack.OmegaTrans(idx,1);
%         turnend = CurrentTrack.OmegaTrans(idx,2);
%        
%         plot(turnstart:turnend,CurrentTrack.Eccentricity(turnstart:turnend), 'b');
%         
%     end
%     
%     for idx = 1: NumReversals;
%         
%         turnstart = CurrentTrack.Reversals(idx,1);
%         turnend = CurrentTrack.Reversals(idx,2);
%        
%         plot(turnstart:turnend,CurrentTrack.Eccentricity(turnstart:turnend), 'g');
%         
%     end
    
    plot  (Bincurrentframe,aAllEccen(currenttrackno,Bincurrentframe),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
           
            
 hold off;


subplot(5, 1, 5);
%%
% plot(CurrentTrack.AngSpeed,'k');
% 
%  hold on;
% 
%      plot  (currentframe,CurrentTrack.AngSpeed(cnt),'o','MarkerEdgeColor','k',...
%                 'MarkerFaceColor',[.49 1 .63],...
%                 'MarkerSize',10);
%             
%  hold off;

 %Replaced with motionstate
 plot(aAllMotionState(currenttrackno,:),'k');

 hold on;
     %adapt currentframe to binned
     plot  (Bincurrentframe,aAllMotionState(currenttrackno,Bincurrentframe),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
 hold off;
 


videoframe=getframe(gcf);

writeVideo(trackmovie,videoframe);

end

close(trackmovie);