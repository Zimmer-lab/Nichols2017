% getThreeStates
wbload;

% load QuiesceState
awbQuiLoad

% calculates quiescent and active range
calculateQuiescentRange

clearvars QuRangebuild QuBRunStart QuBRunEnd QuiesceBout WakeToQuB QuBToWake Qoptions instQuiesce

% Make ranges for the 3 states.
%for the active range it is split into reversal (rise or high AVA) and
%forward (other)
fullRange = 1:length(wbstruct.tv);

avaRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
avaHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
avaFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

avaRISEHIGH = avaRISE + avaHIGH + avaFALL;

indexNotForward = [find(avaRISEHIGH)',rangeQ];
RangeForward = fullRange;
RangeForward(indexNotForward) = [];

indexNotReversal = [RangeForward,rangeQ];
RangeReversal = fullRange;
RangeReversal(indexNotReversal) = [];

%     figure;
%     visual = zeros([1,length(fullRange)]);
%     visual([str2num(options.rangeQ)]) = 1;
%     subplot(3,1,1); imagesc(visual)
%     title('quiescent range');
%
%     visual2 = zeros([1,length(fullRange)]);
%     visual2(RangeForward) = 1;
%     subplot(3,1,2); imagesc(visual2)
%     title('forward range');
%
%     visual = zeros([1,length(fullRange)]);
%     visual(RangeReversal) = 1;
%     subplot(3,1,3); imagesc(visual)
%     title('reversal range');

threeStates = nan(1,length(wbstruct.tv));
%0=REVERSAL 1=FORWARD 2=QUIESCENCE
threeStates(RangeReversal) = 0;
threeStates(RangeForward) = 1;
threeStates(rangeQ) = 2;

save('ThreeStates.mat', 'threeStates')
