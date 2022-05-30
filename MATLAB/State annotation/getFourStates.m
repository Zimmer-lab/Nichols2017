% getFourStates
if ~exist('wbstruct')
    wbload;
end

% load QuiesceState
awbQuiLoad

% calculates quiescent and active range
calculateQuiescentRange

clearvars QuRangebuild QuBRunStart QuBRunEnd QuiesceBout WakeToQuB QuBToWake Qoptions instQuiesce

if ~exist('saveflag')
    saveflag=0;
end

% Make ranges for the 4 states.
%for the active range it is split into reversal (rise or high AVA) and
%forward (other)
fullRange = 1:length(wbstruct.tv);

avaRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
avaHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
avaFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

avaRISEHIGHFALL = avaRISE + avaHIGH + avaFALL;

indexNotForward = [find(avaRISEHIGHFALL)',rangeQ];
RangeForward = fullRange;
RangeForward(indexNotForward) = [];

indexNotReversal = [RangeForward,rangeQ];
RangeReversal = fullRange;
RangeReversal(indexNotReversal) = [];

RangeTurn = find(avaFALL)';

%     figure;
%     visual = zeros([1,length(fullRange)]);
%     visual(rangeQ) = 1;
%     subplot(4,1,1); imagesc(visual)
%     title('quiescent range');
% 
%     visual2 = zeros([1,length(fullRange)]);
%     visual2(RangeForward) = 1;
%     subplot(4,1,2); imagesc(visual2)
%     title('forward range');
% 
%     visual = zeros([1,length(fullRange)]);
%     visual(RangeReversal) = 1;
%     subplot(4,1,3); imagesc(visual)
%     title('reversal range');
%     
%     visual = zeros([1,length(fullRange)]);
%     visual(RangeTurn) = 1;
%     subplot(4,1,4); imagesc(visual)
%     title('turn range');

fourStates = nan(1,length(wbstruct.tv));
%0=REVERSAL 1=FORWARD 2=QUIESCENCE 3=TURN
fourStates(RangeReversal) = 0;
fourStates(RangeForward) = 1; %note that rangeforward also includes range turns, but this will be overwritten.
fourStates(rangeQ) = 2;
fourStates(RangeTurn) = 3;

if saveflag
    save('FourStates.mat', 'fourStates')
end
