function PlayWormtrackSimple(filename,currenttrackno,spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec)

samplerate = 3;

% filename = '201205031616.avi';

% currenttrackno = 18;

[~, trackmoviename, ~] = fileparts(filename);

mv = VideoReader(filename);




trackmovie = VideoWriter([trackmoviename 'PWTPTrackno' num2str(currenttrackno)]);



CurrentTrack = Tracks(currenttrackno);

% CurrentPathX=uint16(round(CurrentTrack.Path(:,1)));
% 
% CurrentPathY=uint16(round(CurrentTrack.Path(:,2)));

CurrentPathX=uint16(round(CurrentTrack.SmoothX));

CurrentPathY=uint16(round(CurrentTrack.SmoothY));



trackfig=figure('Color',[1 1 1],'Position',[1 1 1500 1200]);
%=subplot(1, 2, 1);


open(trackmovie);

cntplt = 1;

[~, NumOfBinnedFrames] = size(St);

for cnt= 1:CurrentTrack.NumFrames;
    
  
    
currentframe = CurrentTrack.Frames(1)+cnt-1;

fr = read(mv,currentframe);

% fr(CurrentPathY,CurrentPathX,3)=255;
% fr(CurrentPathY,CurrentPathX,2)=0;
% fr(CurrentPathY,CurrentPathX,1)=0;

% fr(round(CurrentTrack.Path),3)=255;
% fr(round(CurrentTrack.Path),2)=0;
% fr(round(CurrentTrack.Path),1)=0;

% for idx = 1:CurrentTrack.NumFrames;
%     
%     fr(CurrentPathY(idx),CurrentPathX(idx),3)=0;
%     fr(CurrentPathY(idx),CurrentPathX(idx),2)=0;
%     fr(CurrentPathY(idx),CurrentPathX(idx),1)=0;
% end;

%[NumOmegas, ~] = size(CurrentTrack.OmegaTrans);

% for idx = 1: NumOmegas;
%     
%     for idxx = CurrentTrack.OmegaTrans(idx,1):CurrentTrack.OmegaTrans(idx,2);
%         
%       fr(CurrentPathY(idxx),CurrentPathX(idxx),3)=0;
%       
%       fr(CurrentPathY(idxx),CurrentPathX(idxx),2)=0;
%     
%       fr(CurrentPathY(idxx),CurrentPathX(idxx),1)=255;  
%         
%         
%         
%     end
% end


% [NumReversals, ~] = size(CurrentTrack.Reversals);
% 
% for idx = 1: NumReversals;
%     
%     for idxx = CurrentTrack.Reversals(idx,1):CurrentTrack.Reversals(idx,2);
%         
%       fr(CurrentPathY(idxx),CurrentPathX(idxx),3)=0;
%       
%       fr(CurrentPathY(idxx),CurrentPathX(idxx),2)=255;
%     
%       fr(CurrentPathY(idxx),CurrentPathX(idxx),1)=0;  
%         
%         
%         
%     end
% end



cptrx = uint16(round(CurrentTrack.Path(cnt,1)-50:CurrentTrack.Path(cnt,1)+50));

cptry = uint16(round(CurrentTrack.Path(cnt,2)-50:CurrentTrack.Path(cnt,2)+50));

wormwindow = fr(cptry,cptrx,:);

subplot(5, 1, [1 2]);


    image(wormwindow);
    
   

    axis off;
    axis image;
    
  

if cnt == 1
    
    subplot(5, 1, 3); axis(spdfigaxis);

    plot(St,SBinTrcksSpd(currenttrackno,:),'k');

    hold on;
    
    
    
    plot  (St(cntplt),SBinTrcksSpd(currenttrackno,cntplt),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
            
    hold off;
    
end

if cnt == ((cntplt * samplerate * SBinWinSec) - round(samplerate * SBinWinSec / 2))  && cntplt <= NumOfBinnedFrames

  
    
    subplot(5, 1, 3);

    plot(St,SBinTrcksSpd(currenttrackno,:),'k');

    hold on;
    
    plot  (St(cntplt),SBinTrcksSpd(currenttrackno,cntplt),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
    cntplt=cntplt+1;
            
    hold off;
            
    
            
            
end

strfr = Tracks(currenttrackno).Frames(1);
endfr = Tracks(currenttrackno).Frames(end);

subplot(5, 1, 4);

plot(CurrentTrack.Eccentricity,'k');


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
    
    plot  (currentframe,CurrentTrack.Eccentricity(cnt),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
           
            
 hold off;


subplot(5, 1, 5);

plot(CurrentTrack.AngSpeed,'k');

 hold on;


% for idx = 1: NumOmegas;
%         
%         turnstart = CurrentTrack.OmegaTrans(idx,1);
%         turnend = CurrentTrack.OmegaTrans(idx,2);
%        
%         plot(turnstart:turnend,CurrentTrack.AngSpeed(turnstart:turnend), 'b');
%         
%     end
%     
%     for idx = 1: NumReversals;
%         
%         turnstart = CurrentTrack.Reversals(idx,1);
%         turnend = CurrentTrack.Reversals(idx,2);
%        
%         plot(turnstart:turnend,CurrentTrack.AngSpeed(turnstart:turnend), 'g');
%         
%     end

    
    plot  (currentframe,CurrentTrack.AngSpeed(cnt),'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',[.49 1 .63],...
                'MarkerSize',10);
            
 hold off;





videoframe=getframe(gcf);

writeVideo(trackmovie,videoframe);

end

close(trackmovie);