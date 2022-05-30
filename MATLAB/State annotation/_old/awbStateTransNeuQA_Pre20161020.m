%State transitions from Q to A and A to Q.

Neurons1 = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR','AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR','RIBL', 'RIBR','SIBDL','SIBDR','SIBVL','SIBVR', 'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02',}'; 

% 'AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR',
%NeuronsIncluded CHECK

options.LowTime1 = 0;     % (seconds) range in which to look for the state
options.HighTime1 = 1080;    % transitions. Note that 0 will be corrected to be the
                            % first time point.
                            
%Remove transitions that are more than X seconds away from the trigger neuron
options.ThresholdDistance1 = 15; %seconds. 10 is used in Kato et al.

%%                            
options.version.awbStateTransNeuQA = 'v2_20160408'; 
%added find Q prior to state transisition
%Added fall ends

wbload;
if ~exist('Neurons','var');
    Neurons =Neurons1;
end
clearvars Neurons1

if ~isfield(options,'ThresholdDistance');
    options.ThresholdDistance =options.ThresholdDistance1;
end
options = rmfield(options, 'ThresholdDistance1');

if ~isfield(options,'LowTime');
    options.LowTime =options.LowTime1;
end
options = rmfield(options, 'LowTime1');

if ~isfield(options,'HighTime');
    options.HighTime =options.HighTime1;
end
options = rmfield(options, 'HighTime1');

%convert to frames
LowFrame = round(options.LowTime*wbstruct.fps);
HighFrame = round(options.HighTime*wbstruct.fps);

%if LowTime is 0, must correct so that the first t-point is 1.
if LowFrame(1,1) ==0;
    LowFrame(1,1)= 1;
end

%% State extractions
awbStateTransExtract;

%% Finding the start of a rise and of falls.
awbFindTransitions;

%% Find Q to A transitions
load(strcat(pwd,'/Quant/QuiescentState.mat'));
options.thresholdSeconds = 20; %in seconds

AllAtoQTransitionValues = ~[true;diff(QuiesceBout(:))~=1 ];
AllQtoATransitionValues = ~[true;diff(QuiesceBout(:))~=-1 ];

% Find frames at which it has swapped from Active to Quiescent or other
% direction
AllAtoQTransitionFrames=find(AllAtoQTransitionValues,'1');
AllQtoATransitionFrames=find(AllQtoATransitionValues,'1');

AtoQtransition = nan(length(AllAtoQTransitionFrames),1);
QtoAtransition = nan(length(AllQtoATransitionFrames),1);

%Find transitions that have at least Xseconds of either Q or A prior, 
%and Xseconds of either Q or A after transition
totalRecodringFrames = length(wbstruct.simple.deltaFOverF);
for iiii = 1:length(AllAtoQTransitionFrames);
    %For Active to Quiescent
    TransitionFrame = AllAtoQTransitionFrames(iiii);
    RangeStart = TransitionFrame - floor(options.thresholdSeconds*wbstruct.fps); %prior to change
    RangeEnd = TransitionFrame + floor(options.thresholdSeconds*wbstruct.fps); %after change
    if RangeStart >0 && RangeEnd < (totalRecodringFrames+1)
        if 0 == mean(QuiesceBout(RangeStart:(TransitionFrame-1),1)) && 1 == mean(QuiesceBout(TransitionFrame:RangeEnd,1)); 
            AtoQtransition(iiii,1) = AllAtoQTransitionFrames(iiii,1);
        end
    end
end

for iiii = 1:length(AllQtoATransitionFrames);
    %For Quiescent to Active
    TransitionFrame = AllQtoATransitionFrames(iiii);
    RangeStart = TransitionFrame - floor(options.thresholdSeconds*wbstruct.fps); %prior to change
    RangeEnd = TransitionFrame + floor(options.thresholdSeconds*wbstruct.fps); %after change
    if RangeStart >0 && RangeEnd < (totalRecodringFrames+1)
        if  1 == mean(QuiesceBout(RangeStart:(TransitionFrame-1),1)) && 0 == mean(QuiesceBout(TransitionFrame:RangeEnd,1));
            QtoAtransition(iiii,1) = AllQtoATransitionFrames(iiii,1);
        end
    end
end
clearvars AllAtoQTransitionFrames AllQtoATransitionFrames TransitionFrame AllAtoQTransitionValues AllQtoATransitionValues iiii

%Remove nans
AtoQtransition(isnan(AtoQtransition(:,1)),:)=[];
QtoAtransition(isnan(QtoAtransition(:,1)),:)=[];

%% Remove transitions of state transition which are outside range specified.
indices = find((abs(AtoQtransition))<LowFrame);
AtoQtransition(indices) = [];
indices = find((abs(AtoQtransition))>HighFrame);
AtoQtransition(indices) = [];
clearvars indices

indices = find((abs(QtoAtransition))<LowFrame);
QtoAtransition(indices) = [];
indices = find((abs(QtoAtransition))>HighFrame);
QtoAtransition(indices) = [];
clearvars indices
%% Find closest rises and falls

dataSetID = {AtoQtransition,QtoAtransition};
suffixes = {'ClosestRise_Act2Qui','ClosestFall_Act2Qui','ClosestFallEnd_Act2Qui','ClosestRise_Qui2Act','ClosestFall_Qui2Act', 'ClosestFallEnd_Qui2Act'};
transitionData = {RiseStarts,FallStarts, FallEnds};

for iiiii = 1:2;
    dataSet1 = dataSetID{iiiii};
    for transtypes = 1:3;
        if iiiii ==2;
            transtypesN = transtypes+3;
        else
            transtypesN = transtypes;
        end
        NameO1 = suffixes{transtypesN};
        transDataSet = transitionData{transtypes};

        %Find rises/fall starts and ends triggered by state transition
        for aaaa = 1:length(dataSet1) %for each triggered neuron rise.
            tmp2 = abs(transDataSet-(dataSet1(aaaa,1))); %Creates tmp matrix with values of how far away a transition is.
            ii=1;
            for ii = 1:length(Neurons); %for each neuron finds the closest rise.
                if sum(transDataSet(ii,:))~=0; % takes care of neurons that are not in the dataset.
                    [idx1, idx2] = min(tmp2(ii,:)); %index of closest value
                    StateTrans.(NameO1)(ii,aaaa)= (transDataSet(ii,idx2))-(dataSet1(aaaa,1)); %closest value
                else
                    StateTrans.(NameO1)(ii,aaaa)= NaN; %closest value if the neuron isn't in the dataset.
                end
            end
        end
    clearvars tmp2 aaaa idx1 idx2 ii dataSet
    end
end

%convert frames into seconds in order to be able to average across
%datasets.
if isfield(StateTrans,'ClosestRise_Act2Qui');
    StateTrans.ClosestRise_Act2Qui = StateTrans.ClosestRise_Act2Qui/wbstruct.fps;
    StateTrans.ClosestFall_Act2Qui = StateTrans.ClosestFall_Act2Qui/wbstruct.fps;
    StateTrans.ClosestFallEnd_Act2Qui = StateTrans.ClosestFallEnd_Act2Qui/wbstruct.fps;
end
if isfield(StateTrans,'ClosestRise_Qui2Act');
    StateTrans.ClosestRise_Qui2Act = StateTrans.ClosestRise_Qui2Act/wbstruct.fps;
    StateTrans.ClosestFall_Qui2Act = StateTrans.ClosestFall_Qui2Act/wbstruct.fps;
    StateTrans.ClosestFallEnd_Qui2Act = StateTrans.ClosestFallEnd_Qui2Act/wbstruct.fps;
end

%% Take out frames which are outside the threshold distance from the state transition
%suffixes = {'ClosestRise_Act2Qui','ClosestFall_Act2Qui','ClosestRise_Qui2Act','ClosestFall_Qui2Act'};
for bbb = 1:6;
    NameO3 = suffixes{bbb};
    if isfield(StateTrans,NameO3)
        [idx3, idx4]= size(StateTrans.(NameO3));
        aaa=1;
        for aaa= 1:idx3;
            indices = find((abs(StateTrans.(NameO3)))>options.ThresholdDistance);
            StateTrans.(NameO3)(indices) = NaN;
        end
        clearvars indices aaa
%         figure;boxplot(StateTrans.(NameO3)','orientation', 'horizontal');
%         set(gca,'YTick',1:length(StateTrans.Neurons),'YTickLabel',StateTrans.Neurons)
    end
end
