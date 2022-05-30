% This script needs to be run in a WBI folder and will write out the
% Quiescent states. The wbTraceStateAnnotator needs to be run beforehand to make sure the VB02,
%AVAL and extra neuron traces  are annotated properly. Used to be called
%annikaPhasePlot but no extraNeurons and a consecutive size put onto active
%as well as the Q state
clear all;

%options:

Qoptions.extraNeurons = {'SMDDL','SMDDR','SMDVL','SMDVR','RIVL','RIVR'}; %%,'RID','RMED','RMEL','RMER','RMEV'
Qoptions.ConsecutiveBinSize = 5; %in seconds

%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
%could change so AVAL/R and VB02 are in the extra neurons options. This
%would also get around the two cases where there aren't these neurons.
wbload;

vb02=wbgettrace('VB02',wbstruct);
if isnan(vb02);
    disp(['No VB2 neuron in this datatset'])
    return
end

aval=wbgettrace('AVAL',wbstruct);
if isnan(aval);
    disp(['No AVAL neuron in this datatset'])
    return
end
smddl=wbgettrace('SMDDL',wbstruct);

vbLOW=wbFourStateTraceAnalysis(wbstruct,'useSaved','VB02')==1;

%%
avaLOW=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==1;

instQuiesceSimple=vbLOW & avaLOW; % instaQuiesce = Instaneous Quiescence.

num3=1;

%excluding neuron IDs of neurons not in dataset.
[NeuronList, SimpleIDindx] = wbListIDs;

NumNeurons = length(NeuronList);
Qoptions.extraNeuronsFound ={};

for num1 = 1:(length(Qoptions.extraNeurons));
    NeuronAFindIndx = strfind(NeuronList,Qoptions.extraNeurons{num1});
    cnt=0;
    NeuronAIndx = [];
    for iA = 1:NumNeurons
        
        if ~isempty(NeuronAFindIndx{iA})
            
            if NeuronAFindIndx{iA} == 1
            
                cnt = cnt + 1;
                
                NeuronAIndx(cnt) = SimpleIDindx(iA);
           
            end
            
        end
        
    end
    
    if isempty(NeuronAIndx);
        disp(['Did not find ' Qoptions.extraNeurons{num1}])
    else
       disp(['Found ' Qoptions.extraNeurons{num1}])
       Qoptions.extraNeuronsFound{num3} = Qoptions.extraNeurons{num1};
       num3=num3+1;
    end
    clearvars NeuronAIndx
end
    
%adds effect of other neurons
  instQuiesce = instQuiesceSimple;
for num2 = 1:(length(Qoptions.extraNeuronsFound));
    extraNeuronsRISE.(Qoptions.extraNeuronsFound{num2})(:,1)=wbFourStateTraceAnalysis(wbstruct,'useSaved',Qoptions.extraNeuronsFound{num2})==2;
    instQuiesce = instQuiesce & ~extraNeuronsRISE.(Qoptions.extraNeuronsFound{num2});
end

%%
ConseqQuiscence; % runs script which has a minimum size for the quiescent bouts

%%
ConseqActive;  % runs script which has a minimum size for the active bouts

%Note as the quiescent bout threshold is looked at first there will be some
%cases especailly at the start or the end that a small active bout followed
%by a small quiescent bout will be turned into a longer active bout.


%%
clearvars -except instQuiesce QuiesceBout Qoptions; %instQuiesceSimple
dateRun = datestr(now);
Qoptions.Notes = 'Run on awbQAstate';
save ([strcat(pwd,'/Quant/QuiescentState.mat')]);

