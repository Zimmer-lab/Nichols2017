%% awbBinned3States
% This script finds the state transitions for the 3 states
% (reversal, forward and quiescent phases) in bins for the length of the
% recording. then use awbNeuron_bin.
clear all

BinSize = 30; %seconds

cd('/Users/nichols/Dropbox/_Analysing sets/npr1_2_Let')
%%
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:NumDataSets
    inputData{nn} = strcat('dataset', num2str(nn));
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
    
    clearvars QuRangebuild QuBRunStart QuBRunEnd QuiesceBout WakeToQuB QuBToWake Qoptions instQuiesce
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
    
    threeStates.(inputData{recNum}) = nan(1,length(wbstruct.tv));
    %0=REVERSAL 1=FORWARD 2=QUIESCENCE
    threeStates.(inputData{recNum})(RangeReversal) = 0;
    threeStates.(inputData{recNum})(RangeForward) = 1;
    threeStates.(inputData{recNum})(str2num(options.rangeQ)) = 2;
    
    %% Binning
    FullRecordingLength = 1080; %(in seconds)
    %Number of bins
    BinNum = FullRecordingLength/BinSize;
    
    % Correct to frames
    BinSizeFrames = BinSize*wbstruct.fps; %may be slightly off due to rounding.
    
    TimePoint1 =1;
    for EpochNum = 1:BinNum;
        TimePoint2 = round(EpochNum*BinSizeFrames);
        EpochRange = TimePoint1:TimePoint2;
        data = threeStates.(inputData{recNum})(EpochRange);
        lastOfRun=find(diff(data));
        allTransitions = data(lastOfRun);
        allTransitions(end+1) = data(end);
        
        binThreeStates{recNum,EpochNum} = allTransitions;
        TimePoint1 = TimePoint2;
    end
    clearvars EpochNum EpochRange TimePoint1 TimePoint2 BinSizeFrames BinSizeFramesRounded
    
    cd(MainDir)
end

%% Find certain transitions
%those with [] will find only that type of transition while those without
%brackets will find instances which contain that sequence somewhere (e.g.
%'1 2' will find: [1 2], [1 2 1], [0 1 2])
%0=REVERSAL 1=FORWARD 2=QUIESCENCE

transitions  = {'[1 2]','[1 0]','1','1 0','1 2','1','0 1','2 1'};
transType = {'FQ','FR','aFa','aFRa','aFQa','F','aRFa','aQFa'};

for tNum = 1:length(transitions)
    %preallocate
    transition.(transType{tNum}) = nan(NumDataSets,BinNum);
    for recNum = 1:NumDataSets
        for binN = 1:BinNum
            if tNum == 6;
                if length(binThreeStates{recNum,binN}) == 1 && sum(strfind(mat2str(binThreeStates{recNum,binN}),(transitions{tNum}))) >=1;
                    transition.(transType{tNum})(recNum,binN)= 1;
                else
                    transition.(transType{tNum})(recNum,binN)= 0;
                end
            else
                if strfind(mat2str(binThreeStates{recNum,binN}),(transitions{tNum})) >=1;
                    transition.(transType{tNum})(recNum,binN)= 1;
                else
                    transition.(transType{tNum})(recNum,binN)= 0;
                end
            end
        end
    end
end
clearvars tNum recNum binN ans
