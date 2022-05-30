%%% Individual neuron function, i.e. RMS, mean, mode etc

NeuronIDs1 = {'AVAL','AVAR','RMER','RIML','RIMR'}; 
Analysis1 =@rms; 

%%
%this part checks for options if running the batch version.
if exist('options','var')
    if ~isfield(options,'Analysis1');
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
NameO1 = 'ExpID'; 
NameO2 = 'Full';  %Full as in whole dataset as opposed to just Quiescent or Awake as in original script.
IndividualAnalysis.NeuronIDs = options.NeuronIDs;


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
    else
        neuron = wbgettrace(neu1);
        IndividualAnalysis.(NameO2)(num1,1) = options.Analysis(neuron(:,1)); 
    end
    clearvars NeuronAIndx
    
end

%figure;bar(IndividualAnalysis.Full);

%save ([strcat(pwd,'/Quant/IndividualPowerDist.mat')], 'IndividualAnalysis', 'options','dateRun'); 
