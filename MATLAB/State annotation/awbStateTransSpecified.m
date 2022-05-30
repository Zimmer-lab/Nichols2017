%% State transition for a specified AVA event

Neurons = {'AQR','URXL','URXR','IL2DL','IL2DR','AVAL','AVAR','RIML','RIMR','VB02','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR'}'; 

AVALriseStart = 280; %in frames 
% for AN20140731i AVAL is at 280.

%%
StateTrans.Neurons = Neurons;

wbload;
ii=1; 
for ii= 1:length(Neurons);
     i=1; %this part finds the simpleID number of the neuron.
     SimpleN = 0;
     for i= 1:length(wbstruct.simple.ID);
         if ~isempty(wbstruct.simple.ID{1,i})
            if strcmp(wbstruct.simple.ID{1,i},Neurons{ii}) == 1;
                SimpleN = i;
            end
         end
     end

    %gets state values
    if ~exist('sc')
        sc=wbFourStateTraceAnalysis(wbstruct,'useSaved');
    end

    %gets state values for specified neurons
    if SimpleN == 0;
        disp(strcat( StateTrans.Neurons{ii},' is not in this dataset'))
        StateTrans.StateValue(ii,:) = NaN(length(wbstruct.simple.deltaFOverF),1); 
    else
    StateTrans.StateValue(ii,:) = sc(:,SimpleN);
    end
end

figure;imagesc(StateTrans.StateValue(:,(AVALriseStart-100):AVALriseStart+100));
set(gca,'YTick',1:length(StateTrans.Neurons),'YTickLabel',StateTrans.Neurons)
clearvars SimpleN i ii sc

%% Specify event

%Find closest state tranisition of specified neurons.
%Works in seconds so that different datasets can be averaged

NeuronStateTrans = NaN(length(Neurons),50); %can be max of 50 transitions.

i=1;
for i =1: length(Neurons); 
    %finds state transitions
    if isnan(StateTrans.StateValue(i,1)); % takes care of neurons that are not in the dataset.
        NeuronStateTrans(i,1:length(NeuronStateTrans)) = NaN; % need this as LengthMatrix creates indices for the NaNs.
    else
        BasetoRise = diff(StateTrans.StateValue(i,:)); %gives a 1 at value prior to the change in state.
        LengthMatrix(1,:)=find(BasetoRise,'0'); % finds state changes, NOTE this is the last t of a run. i.e. the state jumps from one state in this timepoint to a new state in the next timepoint
        NeuronStateTrans(i,1:length(LengthMatrix))= LengthMatrix(1,1:length(LengthMatrix));  
    end 
    clearvars LengthMatrix
end

%finds closest transition
ii=1;
tmp = abs(NeuronStateTrans-(AVALriseStart-1)); %the minus 1 corrects for that in the LengthMatrix, it finds the t point before the state change.
for ii =1: length(StateTrans.Neurons); 
    if sum(StateTrans.StateValue(i,:))~=0; % takes care of neurons that are not in the dataset.
        [idx1 idx2] = min(tmp(ii,:)); %index of closest value
        StateTrans.ClosestTrans(ii,1)= NeuronStateTrans(ii,idx2); %closest value
    else
        StateTrans.ClosestTrans(ii,1)= NaN; %closest value if the neuron isn't in the dataset.
    end
end

StateTrans.RelativeTrans= StateTrans.ClosestTrans-(AVALriseStart-1);

% can use plotting tools in awbStateTransBatch.
