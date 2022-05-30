%% Finding the start of a rise and of falls.
%Find rises
Rise = diff(StateTrans.StateValue' == 2); %makes t point at (start of rise - 1) =1, does this between rows, not across coloums so need to correct for this with '
Rise = Rise'; %Switch matrix back to normal configuration.
Rise(Rise<0) = 0; %This stops the next find sentence from finding -1 values (i.e. ends of rises). Therefore it only finds the start of the rise-1.

RiseStarts=nan(length(Neurons), 50); %May cause problems if there are more transitions than 50

for aaa = 1:length(Neurons) %need to do this for each row separately.
    Transitions=find(Rise(aaa,:),'1'); %values will be the t-point of rises of each neuron.
    if ~isempty(Transitions)
        RiseStarts(aaa,1:length(Transitions)) = Transitions;
    end
end
RiseStarts = RiseStarts+1; %Corrects for that before the values were (start of rise - 1).

%Find falls
Fall = diff(StateTrans.StateValue' == 4); %makes t point at (start of rise - 1) =1, does this between rows, not across coloums so need to correct for this with '
Fall = Fall'; %Switch matrix back to normal configuration.
Fall(Fall<0) = 0; %This stops the next find sentence from finding 1 values (i.e. ends of falls). Therefore it only finds the start of the rise-1.

FallStarts=nan(length(Neurons), 50); %May cause problems if there are more transitions than 50
for aaa = 1:length(Neurons) %need to do this for each row separately.
    Transitions=find(Fall(aaa,:),'1'); %values will be the t-point of rises of each neuron.
    if ~isempty(Transitions)
        FallStarts(aaa,1:length(Transitions)) = Transitions;
    end
end
FallStarts = FallStarts+1; %Corrects for that before the values were start of rise-1.
clearvars aaa Rise Fall Transitions

%The output of this part is 2 matrices RiseStarts and FallStarts with all
%the rise/fall starts (in frames) for each neuron.

%% Find fall ends
Fall = diff(StateTrans.StateValue' == 4); %makes t point at (start of rise - 1) =1, does this between rows, not across coloums so need to correct for this with '
Fall = Fall'; %Switch matrix back to normal configuration.
Fall(Fall>0) = 0; %This stops the next find sentence from finding 1 values (i.e. starts of falls). Therefore it only finds the start of the rise-1.
Fall =abs(Fall); %makes the fall ends =1.

FallEnds=nan(length(Neurons), 50); %May cause problems if there are more transitions than 50

for aaa = 1:length(Neurons) %need to do this for each row separately.
    Transitions=find(Fall(aaa,:),'1'); %values will be the t-point of rises of each neuron.
    if ~isempty(Transitions)
        FallEnds(aaa,1:length(Transitions)) = Transitions;
    end
end
FallEnds = FallEnds+1; %Corrects for that before the values were start of rise-1.
clearvars aaa Rise Fall Transitions

%The output of this part is 1 matrix FallEnds with all
%the fall ends (in frames) for each neuron.