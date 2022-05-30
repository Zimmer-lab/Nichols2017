function [BinWinSec, BinTrcksSpd, BinTrcksSpdWght, BinTrcksEcc, BinTrcksEccWght, bintrcknum, t] = spdalsV5_AN(Tracks,BinWin)%this function does not return unbinned data for the purpose of better%memory performance%it uses the reshape function for databinning%generates data arrays of reversal and omega and speed data from Worm Analyzer%'Analyze All Tracks' function. %Reads Tracks structure and returns data arrays with each row corresponding to one track and each column to one frame or bin%NaN if no track at given frame, RingDistance <=RingLimit or tracklenght%<=BinWin%BinWin: Number of frames for each bin%0 if no event, 1/>1 number of reversal initiation events in fram/bin,%AN: modified 2016-07-15. Corrected RingD as per Ingrid and Susanne's%notes. See also notes on spdalsV5OPrefs = struct( 'MaxShortRun', 6, ....            % Maximum length of "short" runs (in seconds)                'SampleRate', 3,...                % Movie frame rate (frames/sec)                'LargeReversalThreshold', 0.4,...  % threshold between small and large reversals                'SmallReversalThreshold', 0.15 );   % threshold between small and non reversalsglobal Prefs;   % Initiallize Preferences (same as in WormAnalyzer)Prefs = struct( 'PlotDirection', 1, ...				'PlotSpeed', 1, ...				'PlotAngSpeed', 1, ...				'SmoothWinSize', 3, ...                        % Size of Window for smoothing track data (in frames)				'StepSize', 3, ...                             % Size of step for calculating changes in X and Y coordinates (in frames): 2 for 4M pixels, 3 for 1M pixels				'SampleRate', 3, ...                           % Movie frame rate (frames/sec)                'TrackFileName', '', ...                       % Trackfile name                'SaveAvgSpeed', 1, ...                         % Save average speed file when avg speed analysis is done                'AvgSpeedFile', '', ...                        % average speed filename                'PlotAvgSpeed', 1, ...                         % Plot avg speed data                'SaveAvgAngSpeed', 0, ...                      % Save average angular speed file when avg speed analysis is done                'AvgAngSpeedFile', 'AngSpeedSheet.txt', ...    % average angular speed filename                'PlotAvgAngSpeed', 0, ...                      % Plot avg ang speed data                'PlotStD', 0, ...                              % Plot Standard Deviations  **Greg**                'AvgSpeedWindow', 1, ...                       % average speed analysis window size, in seconds                'AvgAngSpeedWindow', 3, ...                   % average angular speed analysis window size, in seconds                'SpeedYMax', .35, ...                            % Max speed shown in plot                'SpeedYMin', 0, ...                            % Min speed shown in plot                'SpeedXMax', 75, ...                           % Max time shown in plot (sec *10)                'SpeedXMin', 0, ...                            % Min time shown in plot (sec *10)                 'PirThresh', 20, ...                           % (previously 110) Minimum Angular velocity for identifying a pirouette                'TransThresh', 20, ...                         % For Makoto's update 09-18-05 - threshold for detecting Omegas                'RevTransThresh', 110, ...                     % For Makoto's update 09-18-05 - threshold for detecting Reversals                'RoundThresh', 1.47, ...                       % Cutoff for omega bends                'EccentricityThresh', 0.75, ...                 % Cutoff for omega bends                'MaxRevLen', 6, ...                           % For Makoto's update 09-18-05 - Maximum Reversal Length                'MaxShortRun', 6, ...                          % (Maximum length of "short" runs (in seconds))                'MaxLongRev', 6, ...                          % maximum length of long reversal (in seconds)                    'RingLimit', 40, ...                           % 40 how close the animal has to be to be affected by the ring, 40 for high reversal animals, 45-60 for others                'RingEffectDuration', 20, ...                  % refractory period (in frames) after reversal induced by hitting ring                    'MaxOmegaYValue', 5, ...                       % Max value for Omega bends                'FFSpeed', 6, ...                              % Speed of FF (and RW) track playback                'PixelSize', 1/17.64);                        % Image calibration - pixels/mm mesured in both vertical and horizontal directions) -                                                                % Microscope in Lowest Magnification setting                                                                % (Leica Mic. cal - 68.5, Navatar Lens Min Zoom cal - 36.5,                                                                % Navatar                                                               % Lens Exps (N2)401-404 - 49.2)% Process Pirouettes Data% -----------------------Len = max([Tracks.Frames]);%BinWin = 15;  %number of frames/bin (i.e. 3 frames sec, 180 = 1 min bins)% BinWin = 90BinNum = floor(Len/BinWin);t=(BinWin/2:BinWin:Len)/OPrefs.SampleRate; % time(seconds)BinWinSec=BinWin/OPrefs.SampleRate;               %Bin window in secondsbintrcknum=zeros(1,BinNum);BinTrcksSpd=NaN(length(Tracks),BinNum,'single');BinTrcksSpdWght=NaN(length(Tracks),BinNum,'single');BinTrcksEcc=NaN(length(Tracks),BinNum,'single');BinTrcksEccWght=NaN(length(Tracks),BinNum,'single');for i = 1:length(Tracks)    if Tracks(i).Analyzed && Tracks(i).NumFrames >= BinWin                       trcksSpd=NaN(1,Len,'single');        trcksSpdWght=NaN(1,Len,'single');                trcksEcc=NaN(1,Len,'single');        trcksEccWght=NaN(1,Len,'single');                       trcksSpd(Tracks(i).Frames)=Tracks(i).Speed;        trcksSpdWght(Tracks(i).Frames)=Tracks(i).Speed;                 trcksEcc(Tracks(i).Frames)=Tracks(i).Eccentricity;        trcksEccWght(Tracks(i).Frames)=Tracks(i).Eccentricity;                if ~isempty(Tracks(i).Pirouettes); %set speed to NaN if in Pirouette mode                        [numpiro, ~] = size(Tracks(i).Pirouettes);                        for cnt=1:numpiro;                                strfr=Tracks(i).Frames(Tracks(i).Pirouettes(cnt,1));                ndfr=Tracks(i).Frames(Tracks(i).Pirouettes(cnt,2));                                trcksSpdWght(strfr:ndfr)=NaN;                                trcksEccWght(strfr:ndfr)=NaN;                            end;                    end;                                                                        %remove Reversals and speed data while animals are close to copper ring            RingD = find(Tracks(i).RingDistance <= Prefs.RingLimit & Tracks(i).RingDistance >0);        %% this is WRONG!!!!!%         trcksSpd(Tracks(i).Frames(RingD)-3 : Tracks(i).Frames(RingD)) = NaN;%         trcksSpdWght(Tracks(i).Frames(RingD)-3 : Tracks(i).Frames(RingD)) = NaN;% %         trcksEcc(Tracks(i).Frames(RingD)-3 : Tracks(i).Frames(RingD)) = NaN;%         trcksEccWght(Tracks(i).Frames(RingD)-3 : Tracks(i).Frames(RingD)) = NaN;                        %% this is correct        RingD = [RingD RingD-1 RingD-2 RingD-3];        RingD = RingD(RingD > 0);                trcksSpd(Tracks(i).Frames(RingD)) = NaN;        trcksSpdWght(Tracks(i).Frames(RingD)) = NaN;        trcksEcc(Tracks(i).Frames(RingD)) = NaN;        trcksEccWght(Tracks(i).Frames(RingD)) = NaN;            %         for bns=1:BinNum %bin data%             %             if (Tracks(i).Frames(1) <= (bns*BinWin-BinWin+1)) && (Tracks(i).Frames(end) >= (bns*BinWin)) %bin data only from tracks that are complete over entire bin%               %             %if ~(max(Tracks(i).Frames) < (bns*BinWin-BinWin+1) || min(Tracks(i).Frames) > (bns*BinWin)) %only if track is active in frame%             %                                     BinTrcksSpd(i,:)=mean(reshape(trcksSpd(1:BinNum*BinWin),BinWin,BinNum));                        BinTrcksSpdWght(i,:)=mean(reshape(trcksSpdWght(1:BinNum*BinWin),BinWin,BinNum));                        BinTrcksEcc(i,:)=mean(reshape(trcksEcc(1:BinNum*BinWin),BinWin,BinNum));                        BinTrcksEccWght(i,:)=mean(reshape(trcksEccWght(1:BinNum*BinWin),BinWin,BinNum));                                                           %             end;%         %         end;%         endend bintrcknum = sum(isfinite(BinTrcksSpd));        % trcknum = zeros(1,Len);% % for idx=1:Len %number of tracks in each frame that contribute to raw datasets (excluding those with RingD < RingLimit)%     %     trcknum(idx)=length(trcksSpdWght(isfinite(trcksSpdWght(:,idx))));%    %     % end;