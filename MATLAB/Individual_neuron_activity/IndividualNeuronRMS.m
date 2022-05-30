%%% Individual neuron function, i.e. RMS, mean, mode etc for Quiesce vs Active

NeuronIDs1 = {'AVAL','AVAR','RMER','RIML','RIMR', 'AVFL', 'AVFR', 'RIS', 'AIBL', 'AIBR', 'VA01'}; 
Analysis1 =@rms; 

%%
% version 2 (2016/03/17 updated to deal with recordings with no Q).

%this part checks for options if running the batch version.
if exist('options','var')
    if ~isfield(options,'Analysis');
        options.Analysis =Analysis1;
    end

    if ~isfield(options,'NeuronIDs');
     options.NeuronIDs =NeuronIDs1;
    end
else
    options.Analysis =Analysis1;
    options.NeuronIDs =NeuronIDs1;    
end

wbload;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);
NameO1 = 'ExpID'; 
NameO2 = 'Quiescent'; 
NameO3 = 'Active'; 
IndividualAnalysis.NeuronIDs = options.NeuronIDs;

%% Work out the runs
WakeToQu = ~[true;diff(QuiesceBout(:))~=1 ];
QuToWake = ~[true;diff(QuiesceBout(:))~=-1 ];

QuRunStart=find(WakeToQu,'1');
QuRunEnd=find(QuToWake,'1');

if instQuiesce(1,1)==1; % adds a run start at tv=1 if there is Quiescence there
    QuRunStart(2:end+1)=QuRunStart;
    QuRunStart(1)=1;
end

if instQuiesce(end,1)==1;  % adds a run end at tv=end if there is Quiescence there
    QuRunEnd(length(QuRunEnd)+1,1)=length(instQuiesce);
end
%% Create vector of Quiescent and Active ranges
%calculates positions of runs, i.e. QUIESCENT bout run starts
%and ends.
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

%builds the options.range for the QUIESCENT bouts.
    
Qrangebuild = char.empty;

if ~isempty(QuBRunStart)
    if QuBRunStart(1)==0; %can't start at a 0.
        QuBRunStart(1)=1;
    end
    Qrangebuild = strcat(Qrangebuild, num2str(QuBRunStart(1)),':',num2str(QuBRunEnd(1)));
else
end   

for num1= 2:length(QuBRunStart);
    Qrangebuild = horzcat(Qrangebuild,' ', num2str(QuBRunStart(num1)),':',num2str(QuBRunEnd(num1)));
end
Qrangebuild = strcat('[',Qrangebuild,']');
%     calculates positions of runs, i.e. ACTIVE bout run starts
%     and ends.

ActBRunStart=find(QuBToWake,'1');
ActBRunEnd=find(WakeToQuB,'1');

    if QuiesceBout(1,1)==0; % adds a run start at tv=1 if it is ACTIVE there
        ActBRunStart(2:end+1)=ActBRunStart;
        ActBRunStart(1)=1;
        ActBRunStart=ActBRunStart';
    end

    if QuiesceBout(end,1)==0;  % adds a run end at tv=end if there is ACTIVITY there
        ActBRunEnd(length(ActBRunEnd)+1,1)=length(QuiesceBout);
    end
%     %makes into seconds
%     ActBRunStart = round(ActBRunStart/wbstruct.fps);
%     ActBRunEnd = round(ActBRunEnd/wbstruct.fps);
%builds the options.range for the ACTIVE bouts.
ActRangebuild = char.empty;

if ActBRunStart(1)==0; %can't start at a 0.
ActBRunStart(1)=1;
end

ActRangebuild = strcat(ActRangebuild, num2str(ActBRunStart(1)),':',num2str(ActBRunEnd(1)));

for num1= 2:length(ActBRunStart);
    ActRangebuild = horzcat(ActRangebuild,' ', num2str(ActBRunStart(num1)),':',num2str(ActBRunEnd(num1)));
end
ActRangebuild = strcat('[',ActRangebuild,']');

%%
%only getting analysis of neuron IDs in the dataset.
%%%FIXED wbgettrace error where it gets also non excluded labelled neurons.

[NeuronList, SimpleIDindx] = wbListIDs;
NumNeurons = length(NeuronList);
num1=1;
IndividualAnalysis.(NameO1){1} = wbstruct.trialname;

for num1 = 1:length(options.NeuronIDs);
    
    neu1 = options.NeuronIDs{num1};
    testifexcludedID = strfind(NeuronList,neu1);
    NeuronPresent = 0;
    for iA = 1:NumNeurons %see if neuron is in the simple ID list.
        if testifexcludedID{iA} == 1
            NeuronPresent = 1;
        end   
    end
    
    if NeuronPresent == 0;
        IndividualAnalysis.(NameO2)(num1,1) = NaN;
        IndividualAnalysis.(NameO3)(num1,1) = NaN;
    else
        neuron = wbgettrace(neu1);
        IndividualAnalysis.(NameO2)(num1,1) = options.Analysis(neuron([str2num(Qrangebuild)],1)); 
        IndividualAnalysis.(NameO3)(num1,1) = options.Analysis(neuron([str2num(ActRangebuild)],1));
    end
    clearvars NeuronAIndx
    
end

%figure;bar(IndividualAnalysis.Quiescent);
%figure;bar(IndividualAnalysis.Active);

%save ([strcat(pwd,'/Quant/PowerDistributions.mat')], 'ActiveDist','QuiescentDist', 'options','dateRun'); %ACTIVE bout values
