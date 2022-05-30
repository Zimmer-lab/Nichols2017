% This script needs to be run in a WBI folder and will write out the
% Quiescent states. The AVA threshold might need to be changed. The
% wbTraceStateAnnotator needs to be run beforehand to make sure the VB02,
%AVAL and extra neuron traces  are annotated properly.
clear all;

%options:

Qoptions.extraNeurons = {'SMMDL','SMDDR','SMDVL','SMDVR','RIVL','RIVR','RID','RMED','RMEL','RMER','RMEV'};
Qoptions.ConsecutiveBinSize = 5; %in seconds


%%%%%%%%%%%%%%%%% DON'T NEED TO CHANGE BELOW HERE %%%%%%%%%%%%%%%%%
%could change so AVAL/R and VB02 are in the extra neurons options. This
%would also get around the two cases where there aren't these neurons.

wbload;
wbLoadPCA;

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
vbQUIET= vbLOW; %if vb2 is classed as LOW, (and it is not above threshold??) then it is quiet.

avaTHRES=aval<.6;
avaLOW=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==1;
avaQUIET=avaTHRES & avaLOW;%if AVAL is classed as LOW, and it is below threshold X, then it is Quiet.

%plot(line([0 4300], [0.27 0.27]),'k'); %plots threshold line.

instQuiesceSimple=vbQUIET & avaQUIET; % instaQuiesce = Instaneous Quiescence.

num3=1;

%excluding neuron IDs of neurons not in dataset.
[NeuronList, SimpleIDindx] = wbListIDs;

NumNeurons = length(NeuronList);
    
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
    
instQuiesce = instQuiesceSimple;
for num2 = 1:(length(Qoptions.extraNeuronsFound));
    extraNeuronsRISE.(Qoptions.extraNeuronsFound{num2})(:,1)=wbFourStateTraceAnalysis(wbstruct,'useSaved',Qoptions.extraNeuronsFound{num2})==2;
    instQuiesce = instQuiesce & ~extraNeuronsRISE.(Qoptions.extraNeuronsFound{num2});
end

%%
fwdrun=wbFourStateTraceAnalysis(wbstruct,'useSaved','VB02')==2;
Reversal1=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
Reversal2=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;

Reversal = Reversal1 | Reversal2;
 
%%
ConseqQuiscence; % runs script which has a minimum size for the quiescent bouts

%%
figure;
plot(vb02, 'b');
hold on;
plot(aval, 'r');
hold on;
plot(smddl, 'g');
h2= plot((QuiesceBout), 'k');
h3=plot((instQuiesce-0.1), 'r');
set(h2, 'LineWidth', 3); 
set(h3, 'LineWidth', 3); 

%%

tpc1 = cumsum(wbPCAstruct.pcsFullRange(:,1));
tpc2 = cumsum(wbPCAstruct.pcsFullRange(:,2));
tpc3 = cumsum(wbPCAstruct.pcsFullRange(:,3));




PhasePlotFig = figure;
subplot(1,2,1);
color_line3(cumsum(wbPCAstruct.pcsFullRange(:,1)),cumsum(wbPCAstruct.pcsFullRange(:,2)),cumsum(wbPCAstruct.pcsFullRange(:,3)),double(2*Reversal+QuiesceBout));
xlabel('cumsum(PC1)');ylabel('cumsum(PC2)');zlabel('cumsum(PC3)');

subplot(1,2,2);
color_line3((wbPCAstruct.pcsFullRange(:,1)),(wbPCAstruct.pcsFullRange(:,2)),(wbPCAstruct.pcsFullRange(:,3)),double(2*Reversal+QuiesceBout));
xlabel('PC1');ylabel('PC2');zlabel('PC3');
grid on;
cameratoolbar;

%%
clearvars -except instQuiesce QuiesceBout Qoptions; %instQuiesceSimple
dateRun = datestr(now);
save ([strcat(pwd,'/Quant/QuiescentState.mat')]);

