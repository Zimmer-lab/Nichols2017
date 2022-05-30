%% calculateQuiescentRange
%calculates quiescent and active range
WakeToQuB = ~[true;diff(QuiesceBout(:))~=1 ];
QuBToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

QuBRunStart=find(WakeToQuB,'1');
QuBRunEnd=find(QuBToWake,'1');

if QuiesceBout(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
    QuBRunStart(2:end+1)=QuBRunStart;
    QuBRunStart(1)=1;
end

if QuiesceBout(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
    QuBRunEnd(length(QuBRunEnd)+1,1)=length(QuiesceBout);
end

QuRangebuild = char.empty;
if ~isempty(QuBRunStart)
    if QuBRunStart(1)==0; %can't start at a 0.
        QuBRunStart(1)=1;
    end

    QuRangebuild = strcat(QuRangebuild, num2str(QuBRunStart(1)),':',num2str(QuBRunEnd(1)));

    for num1= 2:length(QuBRunStart);
        QuRangebuild = strcat(QuRangebuild,',', num2str(QuBRunStart(num1)),':',num2str(QuBRunEnd(num1)));
    end
else
    QuRangebuild = 0; %gets around if there is no quiescence
end
rangeQStr=strcat('[', QuRangebuild, ']');

fullRange = 1:length(wbstruct.tv);

rangeQ = [str2num(rangeQStr)];
rangeA = fullRange;
rangeA(rangeQ) = [];

% rangeAt = zeros(1,fullRange);
% rangeAt(rangeQ) = 1;
% rangeQt = zeros(1,fullRange);
% rangeQt(rangeA) = 1;
%figure; subplot(2,1,1); imagesc(rangeQt); subplot(2,1,2); imagesc(rangeAt)

% Make ranges for the 3 states.
%for the active range it is split into reversal (rise or high AVA) and
%forward (other)
fullRange = 1:length(wbstruct.tv);

avaRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
avaHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
avaFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

avaRISEHIGHFALL = avaRISE + avaHIGH +avaFALL;

indexNotForward = [find(avaRISEHIGHFALL)',rangeQ];
RangeForward = fullRange;
RangeForward(indexNotForward) = [];

indexNotReversal = [RangeForward,rangeQ];
RangeReversal = fullRange;
RangeReversal(indexNotReversal) = [];

%Find Reversal and Forward brain states (updated to make Forward AVA
%FALL and LOW, and Reversal RISE and HIGH)
avaRISEHIGH = avaRISE + avaHIGH;

indexNotForwardFL = [find(avaRISEHIGH)',rangeQ];
RangeForwardFL = fullRange;
RangeForwardFL(indexNotForwardFL) = [];

indexNotReversalRH = [RangeForwardFL,rangeQ];
RangeReversalRH = fullRange;
RangeReversalRH(indexNotReversalRH) = [];
        
clearvars QuRangebuild QuiesceBout WakeToQuB QuBToWake Qoptions instQuiesce...
     avaRISEHIGHFALL indexNotForward indexNotReversal indexNotReversalRH indexNotForwardFL

    


