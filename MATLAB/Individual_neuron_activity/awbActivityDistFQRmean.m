%% Based off awbActivityDistFQR
% similar to awbActivityDist but seperates between forward, reverse and quiescent
% rather than active and quiescent.

% script to bin data into 1 second bins and then run a histogram on this.
clear

%xcentres = (0:0.06:3.5);

% xcentres = (-0.5:0.05:3.5);
% logon = 0;

%LOG!
xcentres = logspace(-4,0.7); %logspace(-3,0.7)
logon = 1;
saveflag = 0;
SubplotSaveflag =0;

%Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
%Neurons ={'URXL','URXR','IL2DL','IL2DR', 'AUAL','AUAR','RMGL','RMGR'};
%Neurons ={'RIS','RMED','RMEV','RIML','AVBL'};
%Neurons ={'SMDVL','SMDVR'};
Neurons ={'RIS'};

ResultsStructFilename = 'ActivityDistFQR_FFL_RRH_RIS';

FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:length(Neurons)
    inputData{nn} = strcat(Neurons{nn});
end

%preallocate matrices
for neuNum = 1:length(Neurons);
    BinnedQuiesce.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
    BinnedForward.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
    BinnedReverse.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
    
    MeanQuiesce.(inputData{neuNum}) = nan(1,NumDataSets);
    MeanForward.(inputData{neuNum}) = nan(1,NumDataSets);
    MeanReverse.(inputData{neuNum}) = nan(1,NumDataSets);
end

MainDir = pwd;

for recNum = 1:NumDataSets %Folder loop
    
    cd(FolderList{recNum});
    wbload;
    
    % load QuiesceState
    awbQuiLoad
    
    % calculates quiescent and active range
    calculateQuiescentRange
    
    for neuNum = 1:length(Neurons)
        %get neuron trace
        Trace = wbgettrace(Neurons{neuNum});
        if ~isnan(Trace)
            % Get quiescent or active trace
            QuTrace = Trace(rangeQ);
            ForTrace = Trace(RangeForwardFL);
            RevTrace = Trace(RangeReversalRH);
            
            %get histogram for neuron in Quiescent states and normalise by the number
            %of timepoints
            if ~isempty(QuTrace)
                BinnedQuiesce.(inputData{neuNum})(:,recNum) = (histc(QuTrace,xcentres))/(length(rangeQ));
            else
                BinnedQuiesce.(inputData{neuNum})(:,recNum) = nan(length(xcentres),1);
            end
            %get for Active states
            %BinnedForward.(inputData{neuNum})(:,recNum) = (histc(ForTrace,xcentres))/(length(ForTrace));
            %BinnedReverse.(inputData{neuNum})(:,recNum) = (histc(RevTrace,xcentres))/(length(RevTrace));
            
            % Get means of each neuron
            MeanQuiesce.(inputData{neuNum})(1,recNum) = mean(QuTrace);
            MeanForward.(inputData{neuNum})(1,recNum) = mean(ForTrace);
            MeanReverse.(inputData{neuNum})(1,recNum) = mean(RevTrace);
        end
    end
    cd(MainDir)
end