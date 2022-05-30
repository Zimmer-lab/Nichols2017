clear all

MainDir = pwd;
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%time vector extrapolated
tvi = ((0:5399)/5)';
tv = (0:0.2:1079.8);

%Preallocate: ipcsFullRange = struct(NumDataSets)
Variance = 100;


for recNum = 1:NumDataSets %Number of Data Sets
    
    cd(FolderList{recNum})
    
    wbload;
    load(strcat(pwd,'/Quant/wbPCAstruct.mat'));
    awbQuiLoad
    calculateQuiescentRange
    
    tvo =wbstruct.tv; %time vector original
    [~,numberPCs] = size(pcsFullRange);
    for pcNum = 1:numberPCs
        ipcsFullRange{recNum}(:,pcNum) = interp1(tvo,pcsFullRange(:,pcNum),tvi);
    end
    
    cumsumVE = cumsum(varianceExplained);
    NumPCsToInclude(1,recNum) = find(cumsumVE >= (Variance-0.000001),1);
    disp(NumPCsToInclude)
    
    ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
    ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
    ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;
    
    Reversal = ReversalRISE | ReversalHIGH | ReversalFALL;
    
    fullRange = 1:length(wbstruct.tv);
    rangeQall{recNum} = rangeQ;
    
    rangeF{recNum} = fullRange;
    rangeF{recNum}([rangeQ,find(Reversal)']) = [];
    
    rangeR{recNum} = fullRange;
    rangeR{recNum}([rangeQ,rangeF{recNum}]) = [];
    
    allPCspeed{recNum} = pcsFullRange(:,1:NumPCsToInclude(1,recNum));
    allPCspeed{recNum} = sum(abs(allPCspeed{recNum}),2);
    
    QPCspeed{recNum} = pcsFullRange(rangeQ,1:NumPCsToInclude(1,recNum));
    QPCspeed{recNum} = sum(abs(QPCspeed{recNum}),2);
    
    FPCspeed{recNum} = pcsFullRange(rangeF{recNum},1:NumPCsToInclude(1,recNum));
    FPCspeed{recNum} = sum(abs(FPCspeed{recNum}),2);
    
    RPCspeed{recNum} = pcsFullRange(rangeR{recNum},1:NumPCsToInclude(1,recNum));
    RPCspeed{recNum} = sum(abs(RPCspeed{recNum}),2);
    
    AllFps(1,recNum) = wbstruct.fps;
    cd(MainDir)
end

%%

for recNum = 1:NumDataSets %Number of Data Sets
xedges = 0:0.002:1;

% allPCspeedBin = histc(allPCspeed{recNum},xedges);
% allPCspeedBin = allPCspeedBin/length(fullRange);
% 
% figure; plot(xedges,allPCspeedBin,'k')
% xlim([0,1])
% xlabel('PC speed')
% ylabel('Fraction')

QPCspeedBin=histc(QPCspeed{recNum},xedges);
QPCspeedBin = QPCspeedBin/length(rangeQall{recNum});

FPCspeedBin=histc(FPCspeed{recNum},xedges);
FPCspeedBin = FPCspeedBin/length(rangeF{recNum});

RPCspeedBin=histc(RPCspeed{recNum},xedges);
RPCspeedBin = RPCspeedBin/length(rangeR{recNum});

figure;
plot(xedges,FPCspeedBin,'k')
hold on
plot(xedges,RPCspeedBin,'r')
hold on
plot(xedges,QPCspeedBin,'b')
xlabel('PC speed')
ylabel('Fraction')
legend('Foward','Reverse','Quiescent')
xlim([0,1])

end
%%
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

figure;
for n1= 1:numBouts;
    x1=(QuRunStart(n1));%/wbstruct.fps;
    w1=(QuRunEnd(n1)-QuRunStart(n1));%/wbstruct.fps;
    rectangle('Position',[x1,y1,w1,h1],'FaceColor', paleblue,'EdgeColor', paleblue);
end
hold on;

plot(allPCspeed)




% Variance = 100;
%
% cumsumVE = cumsum(varianceExplained);
% NumPCsToInclude = find(cumsumVE >= Variance,1);
% disp(NumPCsToInclude)
%%
figure;
for recNum = 1:NumDataSets %Number of Data Sets
    
    allPCspeed = ipcsFullRange{:};
    allPCspeed = sum(abs(allPCspeed),2);
    
    xedges = 0:0.01:1.5;
    
    AllspeedBin=histc(allPCspeed,xedges);
    AllspeedBin = AllspeedBin/5400;
    
    plot(xedges,AllspeedBin)
    hold on;
end
