%% Script to find given neuron transitions (rise or fall), within a given range and to compare state transitions to this point.

%Note!!! The first neuron will be what the script triggers of.
Neurons1 = {'AVAL','AQR','URXL','URXR','IL2DL','IL2DR','AVAL','AVAR','RIML','RIMR','RIS','AVEL','AVER','AIBL','AIBR','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR', 'RMGL', 'RMGR', 'AUAL', 'AUAR'}'; 

%For the triggered neuron would you like to trigger off the rise or fall?:
options.TrigNeuronPolarity1 = 1; %1 = Rise, 0 = Fall.

options.LowTime1 = 600;     % (seconds) range in which to look for the state
options.HighTime1 = 800;    % transitions. Note that 0 will be corrected to be the
                            % first time point.
                            
options.version.awbStateTransNeu = 'v3_20160125';
%%
wbload;

if ~exist('Neurons','var');
    Neurons =Neurons1;
end
clearvars Neurons1

if ~isfield(options,'TrigNeuronPolarity');
    options.TrigNeuronPolarity =options.TrigNeuronPolarity1;
end
options = rmfield(options, 'TrigNeuronPolarity1');

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

%% Finding the start of a rise and of falls.
%Find rises
Rise = diff(StateTrans.StateValue' == 2); %makes t point at (start of rise - 1) =1, does this between rows, not across coloums so need to correct for this with '
Rise = Rise'; %Switch matrix back to normal configuration.
Rise(Rise<0) = 0; %This stops the next find sentence from finding -1 values (i.e. ends of rises). Therefore it only finds the start of the rise-1.

RiseStarts=nan(length(Neurons), 50); %May cause problems if there are more transitions than 50

for aaa = 1:length(Neurons) %need to do this for each row separately.
    Transitions=find(Rise(aaa,:),'1'); %values will be the t-point of rises of each neuron.
    if length(Transitions)>0
        RiseStarts(aaa,1:length(Transitions)) = Transitions;
    end
    aaa = aaa+1;
end
RiseStarts = RiseStarts+1; %Corrects for that before the values were (start of rise - 1).

%Find falls
Fall = diff(StateTrans.StateValue' == 4); %makes t point at (start of rise - 1) =1, does this between rows, not across coloums so need to correct for this with '
Fall = Fall'; %Switch matrix back to normal configuration.
Fall(Fall<0) = 0; %This stops the next find sentence from finding 1 values (i.e. ends of falls). Therefore it only finds the start of the rise-1.

FallStarts=nan(length(Neurons), 50); %May cause problems if there are more transitions than 50
aaa=1;
for aaa = 1:length(Neurons) %need to do this for each row separately.
    Transitions=find(Fall(aaa,:),'1'); %values will be the t-point of rises of each neuron.
    if length(Transitions)>0
        FallStarts(aaa,1:length(Transitions)) = Transitions;
    end
    aaa = aaa+1;
end
FallStarts = FallStarts+1; %Corrects for that before the values were start of rise-1.
clearvars aaa Rise Fall Transitions

%The output of this part is 2 matrices RiseStarts and FallStarts with all
%the rise/fall starts (in frames) for each neuron.

%% Find closest state tranisition of specified neurons.
%Works in seconds so that different datasets can be averaged

%finds closest transition for each rise/fall for the trigger neuron (1st
%neuron in 'Neurons1' or 'Neurons' in batch version).

%Uses either trigger neuron rise or fall as input by TrigNeuronPolarity.
TrigNeuronStart = [];
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
    
%Find rises triggered by trigger neuron rise/fall
aaaa =1;
for aaaa = 1:length(TrigNeuronStart) %for each triggered neuron rise.
    tmp2 = abs(RiseStarts-(TrigNeuronStart(1,aaaa))); %Creates tmp matrix with values of how far away a transition is.
    ii=1;
    for ii =1: length(Neurons); %for each neuron finds the closest rise.
        if sum(RiseStarts(ii,:))~=0; % takes care of neurons that are not in the dataset.
            [idx1 idx2] = min(tmp2(ii,:)); %index of closest value
            StateTrans.ClosestRise(ii,aaaa)= (RiseStarts(ii,idx2))-(TrigNeuronStart(1,aaaa)); %closest value
        else
            StateTrans.ClosestRise(ii,aaaa)= NaN; %closest value if the neuron isn't in the dataset.
        end
    end
end
clearvars tmp2 aaaa 

%Find falls triggered by trigger neuron rise/fall
aaaa =1;
for aaaa = 1:length(TrigNeuronStart) %for each triggered neuron rise.
    tmp4 = abs(FallStarts-(TrigNeuronStart(1,aaaa))); %Creates tmp matrix with values of how far away a transition is.
    ii=1;
    for ii =1: length(Neurons); %for each neuron finds the closest fall.
        if sum(FallStarts(ii,:))~=0; % takes care of neurons that are not in the dataset.
            [idx1 idx2] = min(tmp4(ii,:)); %index of closest value
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
end

