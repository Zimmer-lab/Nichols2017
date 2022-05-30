function PlayWormtrackParameters_MSv109(sParam, filename, currenttrackno, spdfigaxis, Tracks, St, SBinTrcksSpd, SBinWinSec, xMovWinPos)

    LargeReversalThreshold = sParam.LargeReversalThreshold;
    SmallReversalThreshold = sParam.SmallReversalThreshold;

    xValuesDisplayed = sParam.xValuesDisplayed;
    samplerate = sParam.samplerate;

	function zoomAxis(currentX, maxX)
		newSize = axis;
		newSize(1) = floor(currentX / maxX) * maxX;
		newSize(2) = (floor(currentX / maxX) + 1) * maxX;
		axis(newSize);
	end

	function plotWormAttribute(attributeName)
		plot((1 + offset) : (length(CurrentTrack.(attributeName)) + offset), ...
            CurrentTrack.(attributeName), 'k', 'LineWidth', 1);
		xlabel('Frame');
		ylabel(attributeName);
		hold on;

        if sParam.plotColors
            for polRevInd = 1:NumPolReversals
                turnstart = CurrentTrack.polishedReversals(polRevInd,1);
                turnend = CurrentTrack.polishedReversals(polRevInd,2);

                plotThis = 1;
                if CurrentTrack.polishedReversals(polRevInd,4) == 2
                    PlottingCol = 'r';
                elseif CurrentTrack.polishedReversals(polRevInd,4) == 1
                    PlottingCol = 'g';
                elseif  CurrentTrack.polishedReversals(polRevInd,4) == 0
                    plotThis = 0;
                    %PlottingCol = 'c';
                end;
                if plotThis
                    plot(turnstart + offset : turnend + offset, ...
                        CurrentTrack.(attributeName)(turnstart:turnend), ...
                        PlottingCol, 'LineWidth', 2);
                end;
            end;

            if sParam.plotOldReversals
                for reversalIndex = 1:NumReversals;
                    turnstart = CurrentTrack.Reversals(reversalIndex,1);
                    turnend = CurrentTrack.Reversals(reversalIndex,2);

                    plotThis = 1;
                    if CurrentTrack.Reversals(reversalIndex,3) > LargeReversalThreshold
                        PlottingCol = [255/255, 150/255, 150/255];
                    elseif CurrentTrack.Reversals(reversalIndex,3) > SmallReversalThreshold
                        PlottingCol = [125/255, 255/255, 160/255];
                    elseif  CurrentTrack.Reversals(reversalIndex,3) <= SmallReversalThreshold
                        %PlottingCol = [125/255, 255/255, 230/255];
                        plotThis = 0;
                    end;

                    if plotThis
                        plot(turnstart + offset : turnend + offset, ...
                            CurrentTrack.(attributeName)(turnstart:turnend), ...
                            ':', 'color', PlottingCol, 'LineWidth', 1);
                    end;
                end;
            end;

            for omegaIndexS = 1:NumOmegasS;
                turnstart = CurrentTrack.OmegaTransShallow(omegaIndexS,1);
                turnend = CurrentTrack.OmegaTransShallow(omegaIndexS,2);
                plot(turnstart + offset : turnend + offset, ...
                    CurrentTrack.(attributeName)(turnstart:turnend), ...
                    'color', [0/255 150/255 255/255], 'LineWidth', 2);
            end;

            for omegaIndexD = 1:NumOmegasD;
                turnstart = CurrentTrack.OmegaTransDeep(omegaIndexD,1);
                turnend = CurrentTrack.OmegaTransDeep(omegaIndexD,2);
                plot(turnstart + offset : turnend + offset, ...
                    CurrentTrack.(attributeName)(turnstart:turnend), ...
                    'b', 'LineWidth', 2);
            end;
        end;

        plot(frameOfVideo,CurrentTrack.(attributeName)(frameOfTrack), ...
            'o', 'MarkerEdgeColor', 'k', ...
			'MarkerFaceColor', [.49 1 .63], 'MarkerSize',10);
		hold off;
	end
    
	[~, trackmoviename, ~] = fileparts(filename);
	
    if sParam.useMP4
        mv = VideoPlayer(filename, 'Verbose', false, 'ShowTime', false);
    else
        mv = VideoReader(filename);
    end;
    
	
    trackmovie = VideoWriter([sParam.movieSubFolder '\' trackmoviename 'PWTPTrackno' num2str(currenttrackno)]);

	CurrentTrack = Tracks(currenttrackno);

	CurrentPathX = uint16(round(CurrentTrack.SmoothX));
	CurrentPathY = uint16(round(CurrentTrack.SmoothY));

	trackfig = figure('Color', [1 1 1], 'Position', xMovWinPos);

	open(trackmovie);

	[~, NumOfBinnedFrames] = size(St);

	%-- if the centroid of the worm is too close to the edge of the actual
    %-- area the movie has to its border, then do not use 50 as range any more, but only
    %-- as much space as there is left.
    plotDistanceFromCenter = 50;
    if round(min(CurrentTrack.Path(:,1))) < 50
        plotDistanceFromCenter = round(min(CurrentTrack.Path(:,1))) - 1;
    end;
    
	firstRun = 1;
    for frameOfTrack = 1:CurrentTrack.NumFrames;
		frameOfVideo = CurrentTrack.Frames(1)+frameOfTrack-1;
		offset = frameOfVideo - frameOfTrack;
		if sParam.useMP4
            %-- move to first frame of interest within movie
            if firstRun
                %-- VideoPlayer starts with FrameNumber 0 ... all frames are
                %-- shifted by 1.
                mv.nextFrame(frameOfVideo-1);
                firstRun = 0;
            end;
            %-- get image information at current frame and immediately move
            %-- to the next one for the next iteration.
            fr = mv.getFrameUInt8();
            mv.nextFrame();
        else
            fr = read(mv, frameOfVideo);
        end;

        %-- plot smoothed positions black onto path
        for idx = 1:CurrentTrack.NumFrames;
            fr(CurrentPathY(idx),CurrentPathX(idx),3) = 0;
            fr(CurrentPathY(idx),CurrentPathX(idx),2) = 0;
            fr(CurrentPathY(idx),CurrentPathX(idx),1) = 0;
        end;
        
        if sParam.plotColors
            %-- plot reversals red / green onto path
            [NumPolReversals, ~] = size(CurrentTrack.polishedReversals);
            for idx = 1: NumPolReversals;
                for idxx = CurrentTrack.polishedReversals(idx,1):CurrentTrack.polishedReversals(idx,2);
                    if CurrentTrack.polishedReversals(idx,4) == 2
                        fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 0;
                        fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 0;
                        fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 255;
                    end;
                    if CurrentTrack.polishedReversals(idx,4) == 1
                        fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 0;
                        fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 255;
                        fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 0;
                    end;
                    %if CurrentTrack.polishedReversals(idx,4) == 0
                        %fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 255;
                        %fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 255;
                        %fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 0;
                    %end;
                end;
            end;
            
            %-- plot old reversals onto path
            if sParam.plotOldReversals
                [NumReversals, ~] = size(CurrentTrack.Reversals);
                for idx = 1: NumReversals;
                    for idxx = CurrentTrack.Reversals(idx,1) : CurrentTrack.Reversals(idx,2);
                        if CurrentTrack.Reversals(idx,3) > LargeReversalThreshold
                            fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 150;
                            fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 150;
                            fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 255;
                        end;
                        if CurrentTrack.Reversals(idx,3) <= LargeReversalThreshold & CurrentTrack.Reversals(idx,3) > SmallReversalThreshold
                            fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 160;
                            fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 255;
                            fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 125;
                        end;
                        %if CurrentTrack.Reversals(idx,3) <= SmallReversalThreshold
                            %fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 230;
                            %fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 255;
                            %fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 125;
                        %end;
                    end;
                end;
            end;

            %-- plot turns blue onto path
            [NumOmegasS, ~] = size(CurrentTrack.OmegaTransShallow);
            for idx = 1: NumOmegasS;
                for idxx = CurrentTrack.OmegaTransShallow(idx,1):CurrentTrack.OmegaTransShallow(idx,2);
                    fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 255;
                    fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 150;
                    fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 0;
                end;
            end;

            [NumOmegasD, ~] = size(CurrentTrack.OmegaTransDeep);
            for idx = 1: NumOmegasD;
                for idxx = CurrentTrack.OmegaTransDeep(idx,1):CurrentTrack.OmegaTransDeep(idx,2);
                    fr(CurrentPathY(idxx),CurrentPathX(idxx),3) = 255;
                    fr(CurrentPathY(idxx),CurrentPathX(idxx),2) = 0;
                    fr(CurrentPathY(idxx),CurrentPathX(idxx),1) = 0;
                end;
            end;
        end;
        
        %-- cut out a window around the worm and display it
		cptrx = uint16(round(CurrentTrack.Path(frameOfTrack,1) - plotDistanceFromCenter : CurrentTrack.Path(frameOfTrack,1) + 50));
		cptry = uint16(round(CurrentTrack.Path(frameOfTrack,2) - plotDistanceFromCenter : CurrentTrack.Path(frameOfTrack,2) + 50));

        wormwindow = fr(cptry, cptrx, :);
		subplot(8, 2, [1 3 5]);
		image(wormwindow);
		axis off;
		axis image;

		%-- plot speed
		currentBin = floor(frameOfVideo / (samplerate * SBinWinSec)) + 1;
		if currentBin <= NumOfBinnedFrames
			subplot(8, 2, 2);
			axis(spdfigaxis);
			plot(St, SBinTrcksSpd(currenttrackno,:), 'k');
			xlabel('Seconds into source video');
			ylabel('Speed');
			hold on;
			plot(St(currentBin),SBinTrcksSpd(currenttrackno,currentBin), ...
                'o', 'MarkerEdgeColor', 'k', ...
				'MarkerFaceColor', [.49 1 .63], 'MarkerSize', 10);
			hold off;

			subplot(8, 2, [7 8]);
			plot(St,SBinTrcksSpd(currenttrackno,:),'k');
			xlabel('Seconds into source video');
			ylabel('Speed');
			hold on;
			plot(St(currentBin), SBinTrcksSpd(currenttrackno,currentBin), ...
                'o', 'MarkerEdgeColor', 'k' , ...
				'MarkerFaceColor', [.49 1 .63], 'MarkerSize', 10);
			hold off;
			zoomAxis(St(currentBin), xValuesDisplayed / samplerate);
        end;

		%-- plot eccentricity
		subplot(8, 2, 4);
		plotWormAttribute('Eccentricity');
		subplot(8, 2, [9 10]);
		plotWormAttribute('Eccentricity');
		zoomAxis(frameOfVideo, xValuesDisplayed);

		%-- plot angular speed
		subplot(8, 2, 6);
		plotWormAttribute('AngSpeed');
		subplot(8, 2, [11 12]);
		plotWormAttribute('AngSpeed');
		zoomAxis(frameOfVideo, xValuesDisplayed);

		%-- plot direction360
		subplot(8, 2, 8);
		plotWormAttribute('Direction360');
		subplot(8, 2, [13 14]);
		plotWormAttribute('Direction360');
		zoomAxis(frameOfVideo, xValuesDisplayed);
        
		%-- save a screenshot
		videoframe = getframe(gcf);
		writeVideo(trackmovie, videoframe);
    end;

	close(trackmovie);
end
