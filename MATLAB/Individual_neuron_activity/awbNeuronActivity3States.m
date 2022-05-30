%%
% This script finds an analysis (e.g. mean or rms) for neurons in the
% reversal, forward and quiescent phases.
clear all

Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
%Neurons = {'AVAL','AVAR','AVBL','AVBR','VB02','VA01','RIS','ASKR'};%,'RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
Neurons = {'RIS','RMED','RMEV','RMEL','RMER'};
analysis = @mean;
%%
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

NumNeurons =length(Neurons);

%Make dynamic names for datasets
inputDataNeuron ={};
for nn = 1:NumNeurons
    inputDataNeuron{nn} = strcat(Neurons{nn});
end

%preallocate matrices
for neuNum = 1:NumNeurons;
    AnalysedQuiesce = nan(NumNeurons,NumDataSets);
    AnalysedReversal = nan(NumNeurons,NumDataSets);
    AnalysedForward = nan(NumNeurons,NumDataSets);
end

MainDir = pwd;
%%
for recNum = 1:NumDataSets %Folder loop
    
    cd(FolderList{recNum});
    wbload;
    
    %% load QuiesceState
    masterfolder = pwd;
    cd (strcat(masterfolder,'/Quant'));
    num2 = exist('QuiescentState.mat', 'file');
    if gt(1,num2);
        X=['No QuiescentState file in folder: ', wbstruct.trialname, ', please run awbQAstateClassifier or specify own range'];
        disp(X)
        return
    end
    load('QuiescentState.mat');
    cd (masterfolder);
    
    %% calculates quiescent and active range
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
    
    QuRangebuild = char.empty;
    if ~isempty(QuBRunStart)
        if QuBRunStart(1)==0; %can't start at a 0.
            QuBRunStart(1)=1;
        end
        
        QuRangebuild = strcat(QuRangebuild, num2str(QuBRunStart(1)),':',num2str(QuBRunEnd(1)));
        
        for num1= 2:length(QuBRunStart);
            QuRangebuild = strcat(QuRangebuild,',', num2str(QuBRunStart(num1)),':',num2str(QuBRunEnd(num1)));
        end
    else
        QuRangebuild = 0; %gets around if there is no quiescence
    end
    options.rangeQ=strcat('[', QuRangebuild, ']');
     
    %% Make ranges for the 3 states.
    %for the active range it is split into reversal (rise or high AVA) and
    %forward (other)
    fullRange = 1:length(wbstruct.tv);
    
    avaRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
    avaHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
    
    avaRISEHIGH = avaRISE + avaHIGH;
    
    indexNotForward = [find(avaRISEHIGH)',str2num(options.rangeQ)];
    RangeForward = fullRange;
    RangeForward(indexNotForward) = [];
    
    indexNotReversal = [RangeForward,str2num(options.rangeQ)];
    RangeReversal = fullRange;
    RangeReversal(indexNotReversal) = [];

%     figure;
%     visual = zeros([1,length(fullRange)]);
%     visual([str2num(options.rangeQ)]) = 1;
%     subplot(3,1,1); imagesc(visual)
%     title('quiescent range');
%     
%     visual2 = zeros([1,length(fullRange)]);
%     visual2(RangeForward) = 1;
%     subplot(3,1,2); imagesc(visual2)
%     title('forward range');
%     
%     visual = zeros([1,length(fullRange)]);
%     visual(RangeReversal) = 1;
%     subplot(3,1,3); imagesc(visual)
%     title('reversal range');

    for neuNum = 1:length(Neurons)
        %get neuron trace
        Trace = wbgettrace(Neurons{neuNum});
        if ~isnan(Trace)
            %get mean for neuron in all 3 states
            AnalysedQuiesce(neuNum,recNum) = analysis(Trace(str2num(options.rangeQ)));
            AnalysedReversal(neuNum,recNum) = analysis(Trace(RangeReversal));
            AnalysedForward(neuNum,recNum) = analysis(Trace(RangeForward));
        end
    end
    cd(MainDir)
end
