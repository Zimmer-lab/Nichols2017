%% awbActivityDist
% script to bin data into 1 second bins and then run a histogram on this.

% To normalise data either: 1. bin into seconds and then
% divide by number of timepoints.
% or 2. divide by number of timepoints.

clear all

xcentres = (0:0.06:3.5);

%Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
Neurons ={'URXL','URXR','IL2DL','IL2DR', 'AUAL','AUAR','RMGL','RMGR'};
Neurons ={'RIS'};
%figure; hist(trace,100)
%%
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
    BinnedActive.(inputData{neuNum}) = nan(length(xcentres),NumDataSets);
end


MainDir = pwd;

for recNum = 1:NumDataSets %Folder loop
    
    cd(FolderList{recNum});
    wbload;
    
    %% load QuiesceState
    masterfolder = pwd;
    cd ([strcat(masterfolder,'/Quant')]);
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
    
    
    for neuNum = 1:length(Neurons)
        %get neuron trace
        Trace = wbgettrace(Neurons{neuNum});
        if ~isnan(Trace)
            %% Get quiescent or active trace
            QuTrace = Trace([str2num(options.rangeQ)]);
            
            fullRange = 1:length(wbstruct.tv);
            RangeActive = fullRange;
            RangeActive([str2num(options.rangeQ)]) = [];
            
            ActTrace = Trace(RangeActive);
            
            %get histogram for neuron in Quiescent states and normalise by the number
            %of timepoints
            BinnedQuiesce.(inputData{neuNum})(:,recNum) = (histc(QuTrace,xcentres))/(length(str2num(options.rangeQ)));
            
            %get for Active states
            BinnedActive.(inputData{neuNum})(:,recNum) = (histc(ActTrace,xcentres))/(length(ActTrace));
        end
    end
    cd(MainDir)
end
%%
for neuNum = 1:length(Neurons)
    figure; plot(mean(BinnedQuiesce.(inputData{neuNum})'))
    hold on
    plot(mean(BinnedActive.(inputData{neuNum})'),'r')
    title(inputData{neuNum})
    
    figure; plot(cumsum(BinnedQuiesce.(inputData{neuNum})))
    hold on
    plot(cumsum(BinnedActive.(inputData{neuNum})),'r')
    title(inputData{neuNum})
end

%% find distances
distances = nan(NumDataSets,length(Neurons));

for neuNum = 1:length(Neurons)
    for recNum = 1:NumDataSets
        distances(recNum,neuNum) = sum(cumsum(BinnedActive.(inputData{neuNum})(:,recNum)) - cumsum(BinnedQuiesce.(inputData{neuNum})(:,recNum)));
    end
%     yaxe = ones(NumDataSets,1);
%     figure; scatter(yaxe,(distances(:,neuNum)));
%     title(inputData{neuNum})

end

