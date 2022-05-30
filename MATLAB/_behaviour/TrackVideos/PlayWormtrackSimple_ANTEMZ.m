function PlayWormtrackSimple_ANTEMZ(filename,currenttrackno,spdfigaxis,Tracks,St,SBinTrcksSpd,SBinWinSec,aAllFinalWakeState,aAllMotionState,useMP4)

samplerate = 3;
pixelsize = 0.0276; %pixelsize in mm

[~, trackmoviename, ~] = fileparts(filename);

if useMP4 == 1;
    mv = VideoPlayer(filename, 'Verbose', false, 'ShowTime', false);
else
    mv = VideoReader(filename);
end;


wormlength(currenttrackno)=mode(Tracks(currenttrackno).MajorAxes);
% normalize speed to worm size
SBinTrcksSpdSize(currenttrackno,:) = SBinTrcksSpd(currenttrackno,:)/(wormlength(currenttrackno)*pixelsize);


trackmovie = VideoWriter([trackmoviename 'PWTPTrackno' num2str(currenttrackno)]);


CurrentTrack = Tracks(currenttrackno);

% CurrentPathX=uint16(round(CurrentTrack.SmoothX));
% CurrentPathY=uint16(round(CurrentTrack.SmoothY));


trackfig=figure('Color',[1 1 1],'Position',[1 1 1500 1200]);

open(trackmovie);

%cntplt = 1;

[~, NumOfBinnedFrames] = size(St);
firstRun = 1;


for cnt= 1:CurrentTrack.NumFrames;
    
    currentframe = CurrentTrack.Frames(1)+cnt-1;
    
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
    
    
    cptrx = uint16(round(CurrentTrack.Path(cnt,1)-80:CurrentTrack.Path(cnt,1)+80));
    
    cptry = uint16(round(CurrentTrack.Path(cnt,2)-80:CurrentTrack.Path(cnt,2)+80));
    
    wormwindow = fr(cptry,cptrx,:);
    
    subplot(5, 1, [1 2]);
    
    
    image(wormwindow);
    
    axis off;
    axis image;
    
%     if cnt == 1
%         
%         subplot(5, 1, 3); axis(spdfigaxis);
%         
%         plot(St,SBinTrcksSpdSize(currenttrackno,:),'k');
%         
%         hold on;
%         
%         
%         plot  (St(cnt),SBinTrcksSpdSize(currenttrackno,cnt),'o','MarkerEdgeColor','k',...
%             'MarkerFaceColor',[.49 1 .63],...
%             'MarkerSize',10);
%         hold off;
%         
%     end
%     
% %     if cnt == (((cnt/samplerate) * SBinWinSec) - round(samplerate * SBinWinSec))  && cnt <= NumOfBinnedFrames
% %         %((cnt * samplerate * SBinWinSec) - round(samplerate * SBinWinSec /
% %         %2))
        
    cntplt = round(currentframe/(samplerate * SBinWinSec));
    
    if cntplt == 0;
        cntplt = 1;
    end
        
        subplot(5, 1, 3);
        
        plot(St,SBinTrcksSpdSize(currenttrackno,:),'k');
        axis tight
        
        hold on;
        
        plot  (St(cntplt),SBinTrcksSpdSize(currenttrackno,cntplt),'o','MarkerEdgeColor','k',...
            'MarkerFaceColor',[.49 1 .63],...
            'MarkerSize',10);
        xlim([0,max(find(~isnan(SBinTrcksSpdSize(currenttrackno,:))))]);
        
        hold off;
        
%     end
    
    strfr = Tracks(currenttrackno).Frames(1);
    endfr = Tracks(currenttrackno).Frames(end);
    
    
%     %% Eccen
%     subplot(5, 1, 4);
%     plot(CurrentTrack.Eccentricity,'k');
%     
%     hold on;
%     plot  (currentframe,CurrentTrack.Eccentricity(cnt),'o','MarkerEdgeColor','k',...
%         'MarkerFaceColor',[.49 1 .63],...
%         'MarkerSize',10);
%     xlim([0,max(find(~isnan(CurrentTrack.Eccentricity)))]);
%     
%     hold off;
%     subplot(5, 1, 5);
    
        %% Eccen
    subplot(5, 1, 4);
    plot(St, aAllFinalWakeState(currenttrackno,:),'k');
    
    hold on;
    plot  (St(cntplt),aAllFinalWakeState(currenttrackno,cntplt),'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',[.49 1 .63],...
        'MarkerSize',10);
    xlim([0,max(find(~isnan(aAllFinalWakeState(currenttrackno,:))))]);
    ylabel('WakeState');
    
    hold off;
    subplot(5, 1, 5);
    %%
    %Replaced with motionstate
    plot(St, aAllMotionState(currenttrackno,:),'k');
    
    hold on;
    
    plot  (St(cntplt),aAllMotionState(currenttrackno,cntplt),'o','MarkerEdgeColor','k',...
        'MarkerFaceColor',[.49 1 .63],...
        'MarkerSize',10);
    xlim([0,max(find(~isnan(aAllMotionState(currenttrackno,:))))]);
    ylabel('MotionState');

    hold off;
    
    videoframe=getframe(gcf);
    
    writeVideo(trackmovie,videoframe);
    
end

close(trackmovie);