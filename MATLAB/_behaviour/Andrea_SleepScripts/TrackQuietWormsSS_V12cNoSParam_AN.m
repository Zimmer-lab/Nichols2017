
% Used for identification of quiescent worms (either entirely quiescent (=quiet) or w/o body but w/ head movement, ie. head/body uncoupled (=search)) 
% Function is based on TrackQuietWorms_NewbinnedV12b
% Function is called from ROspd5_MSv112_SSvX.m; output will be saved in
% dats.mat and avg.mat files
% output: wakestateFinal = 1 means quiescent, searchstateExcl = 1 means
% search, AllQuietStates = 1 means quiet (quiescent + search)

% requires the following input: Tracks, StrcksSpd, StrcksEcc, SBinWinSec,
% SampleRate

%Input
% %Load tracks
% DataFileName = '*_als.mat';
% Files = dir(DataFileName);
% load(Files(1).name);

SampleRate = 3;
sParam = 1;

%Get unbinned StrcksSpd, StrcksEcc.
[BinWinSec, StrcksSpd, ~, StrcksEcc, ~, ~, t]=...
spdalsV5_MSv103_AndreaNoRing(sParam, Tracks, 1, SampleRate);

SBinWinSec = 1; %SBinWinSec = QBinning/SampleRate

%%%%%%%
% these parameters may be changed to optimise/adjust analysis

pixelsize=0.0276; %pixelsize in mm

boutsizethreshold = 5; %in bins; default 10

searchboutsizethreshold = 10; % in bins

roamthresh = 0.2; 

posturethresh = 0.2;

SlidingWinSizeSecsQ = 10; % (20)in sec; size of the sliding window from which to count the ratio of fast/slow states. It has to be any multiple of 2 
SlidingWinSizeSecsS = 20;

SmoothEccentWin = 5; %smooth eccentricity over how many bins

%%%%%%%

disp(strcat('... running ', 32, mfilename, ', identifying quiescence periods'));

cutoff_q = 0.02;
cutoff_s = 0.025;
DEccentrThresh = 0.00107;
DEccSearch = 0.0008;
QBinning = 3;

% calculate Qt based on SpdBinning of 3
maxFrames = size(StrcksSpd,2);
BinNum = maxFrames/QBinning; %default 1100; long: 7820
Qt = (SBinWinSec / 2 : SBinWinSec : SBinWinSec * BinNum - (SBinWinSec / 2));

NumTracks = size(Tracks,2);
NumBins = size(Qt,2);
k = ones(1,SmoothEccentWin)/SmoothEccentWin;
dQt = diff(Qt);

SlidingWinSizeBinsQ = SlidingWinSizeSecsQ / SBinWinSec; 
SlidingWinSizeBinsS = SlidingWinSizeSecsS / SBinWinSec;

% with 3fps and speed binning of 3: 1*3 = 3
BinSizeFrames = SBinWinSec * SampleRate;

% preallocation
wormlength = NaN(NumTracks,1);
SBinTrcksSpd = NaN(NumTracks, NumBins);
SBinTrcksSpdSize = NaN(NumTracks,NumBins);
BinTrcksEcc = NaN(NumTracks, NumBins);
DBinSmoothedEccentricityDSt = NaN(size(BinTrcksEcc));
SpdStateQ = NaN(NumTracks,NumBins);
SpdStateS = NaN(NumTracks, NumBins);
EccStateQ = NaN(NumTracks,NumBins); 
EccStateS = NaN(NumTracks, NumBins); 

for m = 1:NumTracks
    SBinTrcksSpd(m,:) = nanmean(reshape(StrcksSpd(m,1 : NumBins * QBinning), QBinning, NumBins));
    BinTrcksEcc(m,:) = nanmean(reshape(StrcksEcc(m,1 : NumBins * QBinning), QBinning, NumBins));
end

for idx = 1:NumTracks
    
    wormlength(idx)=mode(Tracks(idx).MajorAxes);
    
    % normalize speed to worm size
    SBinTrcksSpdSize(idx,:) = SBinTrcksSpd(idx,:)/(wormlength(idx)*pixelsize);
    
    % smooth eccentricity and calculate dEcc/dt
    BinSmoothedEccentricity = convn(BinTrcksEcc(idx,:),k,'same');
    DBinSmoothedEccentricityDSt(idx,:) = [NaN abs(diff(BinSmoothedEccentricity)./dQt)]; 
   
    % exclude tracks that have very low speed over their entire length
    if nanmean(SBinTrcksSpdSize(idx,:)) > 0.006

        for sldidxQ = 1+SlidingWinSizeBinsQ/2 : NumBins-SlidingWinSizeBinsQ/2

            if Tracks(idx).NumFrames > (SlidingWinSizeBinsQ*BinSizeFrames)

            SpdStateQ(idx,sldidxQ)=numel(...
                find(...
                SBinTrcksSpdSize(idx, sldidxQ - SlidingWinSizeBinsQ / 2:sldidxQ + SlidingWinSizeBinsQ / 2) > cutoff_q))/...
                sum(isfinite(SBinTrcksSpdSize(idx,sldidxQ - SlidingWinSizeBinsQ / 2:sldidxQ + SlidingWinSizeBinsQ/2)));

            EccStateQ(idx,sldidxQ)=numel(...
                find(...
                DBinSmoothedEccentricityDSt(idx,sldidxQ-SlidingWinSizeBinsQ/2:sldidxQ+SlidingWinSizeBinsQ/2) > DEccentrThresh))/...
                sum(isfinite(DBinSmoothedEccentricityDSt(idx,sldidxQ-SlidingWinSizeBinsQ/2:sldidxQ+SlidingWinSizeBinsQ/2)));

            end
        end

        for sldidxS = 1+SlidingWinSizeBinsS/2 : NumBins-SlidingWinSizeBinsS/2

            if Tracks(idx).NumFrames > (SlidingWinSizeBinsS*BinSizeFrames)

            SpdStateS(idx,sldidxS)=numel(...
                find(...
                SBinTrcksSpdSize(idx, sldidxS - SlidingWinSizeBinsS / 2:sldidxS + SlidingWinSizeBinsS / 2) > cutoff_s))/...
                sum(isfinite(SBinTrcksSpdSize(idx,sldidxS - SlidingWinSizeBinsS / 2:sldidxS + SlidingWinSizeBinsS/2)));

            EccStateS(idx,sldidxS)=numel(...
                find(...
                DBinSmoothedEccentricityDSt(idx,sldidxS-SlidingWinSizeBinsS/2:sldidxS+SlidingWinSizeBinsS/2) > DEccSearch))/...
                sum(isfinite(DBinSmoothedEccentricityDSt(idx,sldidxS-SlidingWinSizeBinsS/2:sldidxS+SlidingWinSizeBinsS/2)));
            end
        end
    end
        
    
end



SpeedHigh = SpdStateQ > roamthresh;
SpeedLow = SpdStateS < roamthresh;


PostureHigh = EccStateQ > posturethresh;
PostureS = EccStateS > posturethresh;


active = zeros(NumTracks, NumBins);
search = zeros(NumTracks, NumBins);
active = SpeedHigh | PostureHigh; % logical OR: worm is classified active if either speed or DEccentricity cross threshold
search = SpeedLow & PostureS; % state in which worm shows strong head movement at low/none speed

A = zeros(NumTracks, NumBins);
S = zeros(NumTracks, NumBins);


for i = 1:NumTracks
    
    A(i,:)=bwlabel(active(i,:));
    
    activestats(i).activestats=regionprops(A(i,:),'Area','BoundingBox','Centroid');
    BoutlengthsBins{i} = [activestats(i).activestats.Area];
    
    
    currenttrackbouts = [activestats(i).activestats.BoundingBox];
    MotionBoutsBins{i} = ceil(currenttrackbouts(1:4:end));
   
    
    
    %-- identify search state
    S(i,:) = bwlabel(search(i,:));
    
    searchstats(i).searchstats = regionprops(S(i,:),'Area','BoundingBox','Centroid');
    SearchBoutlengthsBins{i} = [searchstats(i).searchstats.Area];
    
    currenttrackbouts = [searchstats(i).searchstats.BoundingBox];
    SearchMotionBoutsBins{i} = ceil(currenttrackbouts(1:4:end));
    
    
end



wakestate = NaN(NumTracks,NumBins);

wakestate(isfinite(SpdStateQ))=0;

motionstate = NaN(NumTracks,NumBins);

motionstate(isfinite(SpdStateQ))=0;

%EDIT ANNIKA 2016/08/12: this replaces the faulty way of calling motionstate
%before which 1.only allocated quiescnence to bouts below
%540frames.
motionstate(isfinite(SpdStateQ)) = double(active(isfinite(SpdStateQ)));


%-- initialize search state
searchstate = NaN(NumTracks,NumBins);
%-- set length of track = 0
searchstate(isfinite(SpdStateQ))=0;

allboutlengths =[];

for i = 1:NumTracks
    
	if Tracks(i).NumFrames > (boutsizethreshold + SlidingWinSizeBinsS) * BinSizeFrames 
        bouts = (MotionBoutsBins{i});
        [~, numbouts] = size(bouts);

        boutlengths = BoutlengthsBins{i};

        allboutlengths=[allboutlengths [BoutlengthsBins{i}]];

        for ii = 1:numbouts
            % TAKEN OUT ANNIKA 2016/08/12: motionstate(i,bouts(ii):bouts(ii)+boutlengths(ii))=1;
        
            if boutlengths(ii) > boutsizethreshold
                %AN20160714: added -1 to correct the track length.
                wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii)-1)=1;

            else
                if bouts(ii) <= 1+SlidingWinSizeBinsS/2 + Tracks(i).Frames(1)/BinSizeFrames
                    %AN20160714: added -1 to correct the track length.
                    wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii)-1)=NaN;
                end

                if bouts(ii)+boutlengths(ii) >= Tracks(i).Frames(end)/BinSizeFrames - SlidingWinSizeBinsS/2 %!
                    %AN20160714: added -1 to correct the track length.
                    wakestate(i,bouts(ii):bouts(ii)+boutlengths(ii)-1)=NaN;
                end

            end
        end

    else
        wakestate(i,:) = NaN;

    end

    %-- identiy true search state bouts
	if Tracks(i).NumFrames > (searchboutsizethreshold + SlidingWinSizeBinsS) * BinSizeFrames 
        searchBouts = (SearchMotionBoutsBins{i});
        [~, numbouts] = size(searchBouts);

        boutlengths = SearchBoutlengthsBins{i};

        for ii = 1:numbouts
        
            if boutlengths(ii) > searchboutsizethreshold
                searchstate(i,searchBouts(ii):searchBouts(ii)+boutlengths(ii))=1;

            else
                if searchBouts(ii) <= 1+SlidingWinSizeBinsS/2 + Tracks(i).Frames(1)/BinSizeFrames
                    searchstate(i,searchBouts(ii):searchBouts(ii)+boutlengths(ii))=NaN;
                end

                if searchBouts(ii)+boutlengths(ii) >= Tracks(i).Frames(end)/BinSizeFrames - SlidingWinSizeBinsS/2
                    searchstate(i,searchBouts(ii):searchBouts(ii)+boutlengths(ii))=NaN;
                end

            end
        end

    else
        searchstate(i,:) = NaN;

    end

    
end

% work on identification of quiet states by excluding stretches that are
% too short and stitching together nearby stretches; same for search
% phases, but additionally make sure that search and quiet are mutually
% exclusive
[wakestateFinal] = ExcludeStitchQuietStatesV2(wakestate, NumTracks, NumBins, 10, 30);
[searchstateExcl, searchstateFinal] = ExcludeStitchSearchStatesV2(wakestateFinal, searchstate, NumTracks, NumBins, 15, 16);

wakestateFinal(wakestateFinal == 0) = 2;
wakestateFinal(wakestateFinal == 1) = 0;
wakestateFinal(wakestateFinal == 2) = 1;


% add quiet and search states in new matrix
AllQuietStates = NaN(NumTracks, NumBins);

for z = 1:NumTracks
    
    AllQuietStates(z,:) = wakestateFinal(z,:) + searchstateExcl(z,:);
    
end

AllQuietStates(AllQuietStates == 2) = 1;


%%
% [mnQuiet, ~] = getNaNAvg_MSv101.NaNMeanSterr(wakestateFinal);
% 
% [mnSearchQuiet, ~] = getNaNAvg_MSv101.NaNMeanSterr(searchstateExcl);
% 
% [mnAllQuiet, ~] = getNaNAvg_MSv101.NaNMeanSterr(AllQuietStates);


clearvars z pixelsize boutsizethreshold searchboutsizethreshold roamthresh...
posturethresh SlidingWinSizeSecsQ SlidingWinSizeSecsS SmoothEccentWin...
cutoff_q cutoff_s DEccentrThresh DEccSearch QBinning maxFrames BinNum...
Qt NumBins k dQt SlidingWinSizeBinsQ SlidingWinSizeBinsS PostureHigh...
S PostureS EccStateQ EccStateS SpdStateQ SpdStateS SpeedHigh SpeedLow StrcksEcc...
StrcksSpd active activestats allboutlengths boutlengths bouts currenttrackbouts...
searchBouts searchstate searchstateExcl sldidxQ sldidxS t 










