function [Oresponse1Wake,...
    Oresponse1Sleep,...
    LRresponse1Wake,...
    LRresponse1Sleep,...
    FractionActiveSleep,...
    FractionActiveWake,...
    FractionMotionSleep,...
    FractionMotionWake] = ...
    ROSpdQuantV3_AN(SBinTrcksSpdSize,BinTrcksO,BinTrcksLR,...
    BinTrcksSR,wakestate,motionstate,t,NumBins,NumTracks,BinWinSec,...
    SBinWinSec,ConditionalBinSec1,AlsBinSec,OBasalBinSec1,...
    OResponseBin1,LRBasalBinSec1,LRResponseBin1,BehaviorstateBin)

%Make matrices
SpdSleep = NaN(NumTracks,NumBins);

SpdWake  = NaN(NumTracks,NumBins);

OSleep = NaN(NumTracks,NumBins);

OWake = NaN(NumTracks,NumBins);

LRSleep = NaN(NumTracks,NumBins);

LRWake = NaN(NumTracks,NumBins);

SRSleep = NaN(NumTracks,NumBins);

SRWake = NaN(NumTracks,NumBins);


FollowingStateSleep = NaN(NumTracks,NumBins);

FollowingStateWake = NaN(NumTracks,NumBins);


FollowingMotionStateSleep = NaN(NumTracks,NumBins);

FollowingMotionStateWake = NaN(NumTracks,NumBins);



ConditionalBinFr = floor(ConditionalBinSec1 / SBinWinSec);


AlsBinFr = floor(AlsBinSec / SBinWinSec);

% Seperate into tracks satisfying prior lethargic/awake criteria.
for i = 1:NumTracks
    
    %Find tracks which statisfy the prior lethargic behaviour criteria.
    if sum(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2))) == 0
        
        SpdSleep(i,AlsBinFr(1):AlsBinFr(2)) = SBinTrcksSpdSize(i,AlsBinFr(1):AlsBinFr(2));
        
        OSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksO(i,AlsBinFr(1):AlsBinFr(2));
        
        LRSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksLR(i,AlsBinFr(1):AlsBinFr(2));
        
        SRSleep(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksSR(i,AlsBinFr(1):AlsBinFr(2));
        
        FollowingStateSleep(i,AlsBinFr(1):AlsBinFr(2)) = wakestate(i,AlsBinFr(1):AlsBinFr(2));
        
        FollowingMotionStateSleep(i,AlsBinFr(1):AlsBinFr(2)) = motionstate(i,AlsBinFr(1):AlsBinFr(2));
    end

    %Find tracks which statisfy the prior awake behaviour criteria.
    if sum(~(wakestate(i,ConditionalBinFr(1):ConditionalBinFr(2))==1))==0
        
        SpdWake(i,AlsBinFr(1):AlsBinFr(2)) = SBinTrcksSpdSize(i,AlsBinFr(1):AlsBinFr(2));
        
        OWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksO(i,AlsBinFr(1):AlsBinFr(2));
        
        LRWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksLR(i,AlsBinFr(1):AlsBinFr(2));
        
        SRWake(i,AlsBinFr(1):AlsBinFr(2)) = BinTrcksSR(i,AlsBinFr(1):AlsBinFr(2));
        
        FollowingStateWake(i,AlsBinFr(1):AlsBinFr(2)) = wakestate(i,AlsBinFr(1):AlsBinFr(2));
        
        FollowingMotionStateWake(i,AlsBinFr(1):AlsBinFr(2)) = motionstate(i,AlsBinFr(1):AlsBinFr(2));

    end
end


mnspdWake=nanmean(SpdWake);
%strspdWake=nansterr(SpdWake);

mnOWake=nanmean(OWake)/BinWinSec;
%strOWake=nansterr(OWake)/BinWinSec;

mnLRWake=nanmean(LRWake)/BinWinSec;
%strLRWake=nansterr(LRWake)/BinWinSec;

mnSRWake=nanmean(SRWake)/BinWinSec;
%strSRWake=nansterr(SRWake)/BinWinSec;



mnspdSleep=nanmean(SpdSleep);
%strspdSleep=nansterr(SpdSleep);

mnOSleep=nanmean(OSleep)/BinWinSec;
%strOSleep=nansterr(OSleep)/BinWinSec;

mnLRSleep=nanmean(LRSleep)/BinWinSec;
%strSleep=nansterr(LRSleep)/BinWinSec;

mnSRSleep=nanmean(SRSleep)/BinWinSec;
%strSRSleep=nansterr(SRSleep)/BinWinSec;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tOBasalBinIdx1=zeros(1,2);

tOResponseBinIdx1=zeros(1,2);

tOBasalBinIdx1(1) = find(t<=OBasalBinSec1(1),1,'last');

tOBasalBinIdx1(2) = find(t>=OBasalBinSec1(2),1,'first');

tOResponseBinIdx1(1) = find(t<=OResponseBin1(1),1,'last');

tOResponseBinIdx1(2) = find(t>=OResponseBin1(2),1,'first');



OResponseRate1Wake = nanmean(mnOWake(tOResponseBinIdx1(1):tOResponseBinIdx1(2)));

OBasalRate1Wake = nanmean(mnOWake(tOBasalBinIdx1(1):tOBasalBinIdx1(2)));

Oresponse1Wake = OResponseRate1Wake - OBasalRate1Wake; 


OResponseRate1Sleep = nanmean(mnOSleep(tOResponseBinIdx1(1):tOResponseBinIdx1(2)));

OBasalRate1Sleep = nanmean(mnOSleep(tOBasalBinIdx1(1):tOBasalBinIdx1(2)));

Oresponse1Sleep = OResponseRate1Sleep - OBasalRate1Sleep; 


tLRBasalBinIdx1=zeros(1,2);

tLRResponseBinIdx1=zeros(1,2);

tLRBasalBinIdx1(1) = find(t<=LRBasalBinSec1(1),1,'last');

tLRBasalBinIdx1(2) = find(t>=LRBasalBinSec1(2),1,'first');

tLRResponseBinIdx1(1) = find(t<=LRResponseBin1(1),1,'last');

tLRResponseBinIdx1(2) = find(t>=LRResponseBin1(2),1,'first');


LRResponseRate1Wake = nanmean(mnLRWake(tLRResponseBinIdx1(1):tLRResponseBinIdx1(2)));

LRBasalRate1Wake = nanmean(mnLRWake(tLRBasalBinIdx1(1):tLRBasalBinIdx1(2)));

LRresponse1Wake = LRResponseRate1Wake - LRBasalRate1Wake; 


LRResponseRate1Sleep = nanmean(mnLRSleep(tLRResponseBinIdx1(1):tLRResponseBinIdx1(2)));

LRBasalRate1Sleep = nanmean(mnLRSleep(tLRBasalBinIdx1(1):tLRBasalBinIdx1(2)));

LRresponse1Sleep = LRResponseRate1Sleep - LRBasalRate1Sleep; 

%%%%%%%%%%%%%%%%%%%%%%%%%%

tBehaviorstateBinIdx(1) =  find(t<=BehaviorstateBin(1),1,'last');

tBehaviorstateBinIdx(2) =  find(t>=BehaviorstateBin(2),1,'first');


FractionActiveSleep = nanmean(nanmean(FollowingStateSleep(:,tBehaviorstateBinIdx(1):tBehaviorstateBinIdx(2))'));  %some students use old nanmean function without dimension input argument

FractionActiveWake = nanmean(nanmean(FollowingStateWake(:,tBehaviorstateBinIdx(1):tBehaviorstateBinIdx(2))'));  

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MotionState
FractionMotionSleep = FollowingMotionStateSleep(:,tBehaviorstateBinIdx(1):tBehaviorstateBinIdx(2));
FractionMotionWake = FollowingMotionStateWake(:,tBehaviorstateBinIdx(1):tBehaviorstateBinIdx(2));

 end
