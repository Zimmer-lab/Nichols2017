%% Script to find AQR rises and to compare state transitions to this point.

Neurons1 = {'AQR','URXL','URXR','IL2DL','IL2DR','AVAL','AVAR','RIML','RIMR','RIS','AVEL','AVER','AIBL','AIBR','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR', 'RMGL', 'RMGR', 'AUAL', 'AUAR'}'; 


%CHECK THIS: search for: FINDME
%%
%Find Shift timepoint

wbload;

BasetoRise = diff(StateTrans.StateValue(1,:)); %1 here is AQR as defined by the Neurons input, will need to change script so it checks for AQR
AQRRiseStarts=find(BasetoRise(1,(round(wbstruct.fps*355)):(round(wbstruct.fps*380))),'1'); %first value will be the first state change in AQR which should be the oxygen response (also taking period where there should only be the stim period).

AQRRiseStart = (AQRRiseStarts(1,1))+(round(wbstruct.fps*355));

%% Find closest state tranisition of specified neurons.
%Works in seconds so that different datasets can be averaged

if ~exist('Neurons','var');
    Neurons =Neurons1;
end
NeuronStateTrans = NaN(length(Neurons),50); % 50 here is arbitary, if there are more than 50 neurons will need to increase this.

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
tmp = abs(NeuronStateTrans-(AQRRiseStart-1)); %the minus 1 corrects for that in the LengthMatrix, it finds the t point before the state change.
for ii =1: length(StateTrans.Neurons); 
    if sum(StateTrans.StateValue(i,:))~=0; % takes care of neurons that are not in the dataset. FINDME: should it be i or ii??
        [idx1 idx2] = min(tmp(ii,:)); %index of closest value
        StateTrans.ClosestTrans(ii,1)= NeuronStateTrans(ii,idx2); %closest value
    else
        StateTrans.ClosestTrans(ii,1)= NaN; %closest value if the neuron isn't in the dataset.
    end
end

