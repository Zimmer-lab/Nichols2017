%% Script to find given neuron transitions (rise or fall), within a given range and to compare state transitions to this point.

%Note!!! The first neuron will be what the script triggers of.
Neurons1 = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR','AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR','RIBL', 'RIBR','SIBDL','SIBDR','SIBVL','SIBVR', 'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02',}';

%For the triggered neuron would you like to trigger off the rise or fall?:
options.TrigNeuronPolarity1 = 1; %1 = Rise, 0 = Fall.

options.LowTime1 = 0;     % (seconds) range in which to look for the state
options.HighTime1 = 360;    % transitions. Note that 0 will be corrected to be the
% first time point.

options.version.awbStateTransNeu = 'v4_20161019'; %added find Q prior to state transisition

%Would you like to specify a requirement of quiescence range prior to trigger neuron event:
options.priorQuiesceFlag1 = 1; %1 = On, 0 = Off
options.priorQuiesceSec1 = 20; %in seconds (note this will be from -5 seconds so there is
%leeway around the end of the quiescence.
%%
wbload;

if ~exist('Neurons','var');
    Neurons =Neurons1;
end
clearvars Neurons1

% check if batch version is being used
presets = {'TrigNeuronPolarity','priorQuiesceFlag','priorQuiesceSec','LowTime','HighTime'};
for nPre = 1:length(presets)
    if ~isfield(options,presets{nPre});
        options.(presets{nPre}) =options.([presets{nPre},num2str(1)]);
    end
    options = rmfield(options, ([presets{nPre},num2str(1)]));
end

%convert to frames
LowFrame = round(options.LowTime*wbstruct.fps);
HighFrame = round(options.HighTime*wbstruct.fps);

%if LowTime is 0, must correct so that the first t-point is 1.
if LowFrame(1,1) ==0;
    LowFrame(1,1)= 1;
end

%% Finding the start of a rise and of falls.
awbFindTransitions

%The output of this part is 2 matrices RiseStarts and FallStarts with all
%the rise/fall starts (in frames) for each neuron.

%% Find closest state transition of specified neurons.
%Works in seconds so that different datasets can be averaged

%finds closest transition for each rise/fall for the trigger neuron (1st
%neuron in 'Neurons1' or 'Neurons' in batch version).

%Uses either trigger neuron rise or fall as input by TrigNeuronPolarity.
if options.TrigNeuronPolarity == 1;
    %trigger from trigger neuron rises
    tmp1 = RiseStarts(1,:);
    TrigNeuronStart = tmp1(1,~isnan(tmp1));
    clearvars tmp1
else
    %trigger from trigger neuron falls
    tmp1 = FallStarts(1,:);
    TrigNeuronStart = tmp1(1,~isnan(tmp1));
    clearvars tmp1
end

% Remove transitions of the trigger neuron which are outside range specified.
indices = find((abs(TrigNeuronStart))<LowFrame);
TrigNeuronStart(indices) = [];
indices = find((abs(TrigNeuronStart))>HighFrame);
TrigNeuronStart(indices) = [];
clearvars indices

%% If finding Quiescence/Active state before transition
priorQuiesceFrames = ceil(options.priorQuiesceSec*wbstruct.fps);

if options.priorQuiesceFlag == 1;
    load(strcat(pwd,'/Quant/QuiescentState.mat'));
    % Remove transitions of the trigger neuron which are not preceded by Xseconds of Quiescence.
    toRemove=[];
    for counter= 1:length(TrigNeuronStart); % for each triggered neuron start
        frameToCheck = TrigNeuronStart(1,counter)-floor(5*wbstruct.fps);
        %note problem with Q not ending with first event frame. Added 5s of leeway.
        Removal=[];
        
        if frameToCheck-priorQuiesceFrames >0
            if  sum(QuiesceBout((frameToCheck-priorQuiesceFrames):frameToCheck,1)) < priorQuiesceFrames;
                Removal = (counter);
            end
            % Note that "frameToCheck-priorQuiesceFrames >0" makes sure
            % that only if there is enough frames prior to the event will it be
            % counted.
        else
            Removal = counter;
        end
        
        if Removal>0;
            if isempty(toRemove);
                toRemove =counter;
            else
                toRemove =horzcat(toRemove,counter);
            end
        end
    end
    
    TrigNeuronStart(toRemove) = [];
end

clearvars priorQuiesceFrames frameToCheck counter Removal
%%

%Find rises triggered by trigger neuron rise/fall
for aaaa = 1:length(TrigNeuronStart) %for each triggered neuron rise.
    tmp2 = abs(RiseStarts-(TrigNeuronStart(1,aaaa))); %Creates tmp matrix with values of how far away a transition is.
    ii=1;
    for ii =1: length(Neurons); %for each neuron finds the closest rise.
        if sum(RiseStarts(ii,:))~=0; % takes care of neurons that are not in the dataset.
            [idx1, idx2] = min(tmp2(ii,:)); %index of closest value
            StateTrans.ClosestRise(ii,aaaa)= (RiseStarts(ii,idx2))-(TrigNeuronStart(1,aaaa)); %closest value
        else
            StateTrans.ClosestRise(ii,aaaa)= NaN; %closest value if the neuron isn't in the dataset.
        end
    end
end
clearvars tmp2 aaaa

%Find falls triggered by trigger neuron rise/fall
for aaaa = 1:length(TrigNeuronStart) %for each triggered neuron rise.
    tmp4 = abs(FallStarts-(TrigNeuronStart(1,aaaa))); %Creates tmp matrix with values of how far away a transition is.
    ii=1;
    for ii =1: length(Neurons); %for each neuron finds the closest fall.
        if sum(FallStarts(ii,:))~=0; % takes care of neurons that are not in the dataset.
            [idx1, idx2] = min(tmp4(ii,:)); %index of closest value
            StateTrans.ClosestFall(ii,aaaa)= (FallStarts(ii,idx2))-(TrigNeuronStart(1,aaaa)); %closest value
        else
            StateTrans.ClosestFall(ii,aaaa)= NaN; %closest value if the neuron isn't in the dataset.
        end
    end
end
clearvars tmp4 aaaa idx1 idx2 ii

%convert frames into seconds in order to be able to average across
%datasets.
if isfield(StateTrans,'ClosestRise');
    StateTrans.ClosestRise = StateTrans.ClosestRise/wbstruct.fps;
    StateTrans.ClosestFall = StateTrans.ClosestFall/wbstruct.fps;
    StateTrans.TrigNeuRiseStartsSec = RiseStarts(1,:)/wbstruct.fps;
end

%% Find events that qualify for RISE1 or RISE2
% RISE1 = prior AVA of at least 3s
% RISE2 = prior AVA of at below 3s

trigNeuRiseStarts = find(isfinite(RiseStarts(1,:)));

%find low states
trigNeuLOW = StateTrans.StateValue(1,:) == 1;
lowRegions = regionprops(trigNeuLOW,'BoundingBox');

LOWstart = (subsref([lowRegions.BoundingBox],struct('type','()','subs',{{1 1:4:length(lowRegions)*4}}))+0.5);
LOWlength = subsref([lowRegions.BoundingBox],struct('type','()','subs',{{1 3:4:length(lowRegions)*4}}));

%note this is not the actual end but rather the first time point of the
%RISE. Used below.
LOWend = (LOWstart+LOWlength);

for ii = 1:max(trigNeuRiseStarts);
    priorLOWpos = find(LOWend == RiseStarts(1,ii));
    if ~isempty(priorLOWpos)
        %in seconds
        StateTrans.priorTrigLow(:,ii) = LOWlength(1,priorLOWpos)/wbstruct.fps;
    else
        StateTrans.priorTrigLow(:,ii) = 0;
    end
end

%% Find if prior Q and how many seconds if so.

if ~exist('QuiesceBout')
    load(strcat(pwd,'/Quant/QuiescentState.mat'));
end

if sum(QuiesceBout) > 0;
    %find Quiescent states
    QRegions = regionprops(QuiesceBout','BoundingBox');
    
    Qstart = (subsref([QRegions.BoundingBox],struct('type','()','subs',{{1 1:4:length(QRegions)*4}}))+0.5);
    Qlength = subsref([QRegions.BoundingBox],struct('type','()','subs',{{1 3:4:length(QRegions)*4}}));
    
    %note this is not the actual end but rather the first time point of the
    %RISE. Used below.
    Qend = (Qstart+Qlength);
    
    %increase range as there are some Q->R which have some prior SMDD
    %activity. Using 15s as threshold
    QendRange = [];
    for qNum = 1:length(Qend)
        QendRange(qNum,:) = round(Qend(qNum)-15*wbstruct.fps):Qend(qNum);
    end
    
    StateTrans.priorTrigQ = NaN(1,50);
    for ii = 1:max(trigNeuRiseStarts);
        priorQpos = find(sum(QendRange == RiseStarts(1,ii),2));
        
        if ~isempty(priorQpos)
            %in seconds
            StateTrans.priorTrigQ(:,ii) = Qlength(1,priorQpos)/wbstruct.fps;
        else
            %gives 0 for events where there is no prior Q
            StateTrans.priorTrigQ(:,ii) =0;
        end
    end
    
else
    %gives 0 for events where there is no prior Q
    StateTrans.priorTrigQ = NaN(1,50);
    for ii = 1:max(trigNeuRiseStarts);
        StateTrans.priorTrigQ(:,ii) =0;
    end
    
end

clearvars QuiesceBout