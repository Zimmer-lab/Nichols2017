%%awbPCspeed

wbload;
awbQuiLoad
load(strcat(pwd,'/Quant/wbPCAstruct.mat'));
calculateQuiescentRange
%%
if ~exist('Variance')
    Variance = 100;
end

cumsumVE = cumsum(varianceExplained);
NumPCsToInclude = find(cumsumVE >= (Variance-0.000001),1);
disp(NumPCsToInclude)

ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

Reversal = ReversalRISE | ReversalHIGH | ReversalFALL;

fullRange = 1:length(wbstruct.tv);

rangeF = fullRange;
rangeF([rangeQ,find(Reversal)']) = [];

rangeR = fullRange;
rangeR([rangeQ,rangeF]) = [];


% test =zeros(1:fullRange,1);
% test(rangeF)=1;

allPCspeed = pcsFullRange(:,1:NumPCsToInclude);
allPCspeed = sum(abs(allPCspeed),2);

QPCspeed = pcsFullRange(rangeQ,1:NumPCsToInclude);
QPCspeed = sum(abs(QPCspeed),2);

FPCspeed = pcsFullRange(rangeF,1:NumPCsToInclude);
FPCspeed = sum(abs(FPCspeed),2);

RPCspeed = pcsFullRange(rangeR,1:NumPCsToInclude);
RPCspeed = sum(abs(RPCspeed),2);

xedges = 0:0.002:1;
% figure; plot(allPCspeed)

allPCspeedBin = histc(allPCspeed,xedges);
allPCspeedBin = allPCspeedBin/length(fullRange);

% figure; plot(xedges,allPCspeedBin,'k')
% xlim([0,1])
% xlabel('PC speed')
% ylabel('Fraction')
% 
% QPCspeedBin=histc(QPCspeed,xedges);
% QPCspeedBin = QPCspeedBin/length(rangeQ);
% 
% FPCspeedBin=histc(FPCspeed,xedges);
% FPCspeedBin = FPCspeedBin/length(rangeF);
% 
% RPCspeedBin=histc(RPCspeed,xedges);
% RPCspeedBin = RPCspeedBin/length(rangeR);
% 
% figure; 
% plot(xedges,FPCspeedBin,'k')
% hold on
% plot(xedges,RPCspeedBin,'r')
% hold on
% plot(xedges,QPCspeedBin,'b')
% xlabel('PC speed')
% ylabel('Fraction')
% legend('Foward','Reverse','Quiescent')
% xlim([0,1])

%
awbQuiLoad
WakeToQu = ~[true;diff(QuiesceBout(:))~=1 ];
QuToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

QuRunStart=find(WakeToQu,'1');
QuRunEnd=find(QuToWake,'1');

if QuiesceBout(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
    QuRunStart(2:end+1)=QuRunStart;
    QuRunStart(1)=1;
end

if QuiesceBout(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
    QuRunEnd(length(QuRunEnd)+1,1)=length(instQuiesce);
end

%Figure plotting

paleblue = [0.8  0.93  1]; %255

numBouts = length(QuRunStart);
y1=0;
h1=0.8;

% figure;
% for n1= 1:numBouts;
%     x1=(QuRunStart(n1));%/wbstruct.fps;
%     w1=(QuRunEnd(n1)-QuRunStart(n1));%/wbstruct.fps;
%     rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
% end
% hold on;
% plot(allPCspeed)
