%% awb3States
%Finds certain transition types and generates a matrix with FQR state on a
%5fps time vector

clear all
%cd('/Users/nichols/Dropbox/_Analysing sets/npr1_2_Let')

FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:NumDataSets
    inputData{nn} = strcat('dataset', num2str(nn));
end

%time vector intrapolated
tvi = ((0:5399)/5)';
tv = (0:0.2:1079.8);

MainDir = pwd;
for recNum = 1:NumDataSets %Folder loop
    
    cd(FolderList{recNum});
    wbload;
    
    % load QuiesceState
    awbQuiLoad
    
    % calculates quiescent and active range
    calculateQuiescentRange
    
    clearvars QuRangebuild QuBRunStart QuBRunEnd QuiesceBout WakeToQuB QuBToWake Qoptions instQuiesce
    
    % Make ranges for the 3 states.
    %for the active range it is split into reversal (rise or high AVA) and
    %forward (other)
    fullRange = 1:length(wbstruct.tv);
    
    avaLOW=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==1;
    avaRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
    avaHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
    avaFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

%     avaRISEHIGH = avaRISE + avaHIGH;
%     disp('using Reversal as: AVA rise + high');
%     
    avaRISEHIGH = avaRISE + avaHIGH + avaFALL;
    disp('using Reversal as: AVA fall + rise + high');
% %     
%     avaRISEHIGH = avaRISE + avaHIGH + avaLOW;
%     disp('using Reversal as: AVA rise + high + low');
    
    indexNotForward = [find(avaRISEHIGH)',rangeQ];
    RangeForward = fullRange;
    RangeForward(indexNotForward) = [];
    
    indexNotReversal = [RangeForward,rangeQ];
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
    threeStates.(inputData{recNum})(rangeQ) = 2;
    
    tvo =wbstruct.tv; %time vector original
    
    iThreeStates(recNum,:) = interp1(tvo,threeStates.(inputData{recNum}),tvi,'nearest');
    cd(MainDir)
end

iThreeStates = round(iThreeStates);

%% Find certain transitions
%0=REVERSAL 1=FORWARD 2=QUIESCENCE

transitions  = {'[1 2]','[1 0]','[2 0]','[2 1]','[0 1]','[0 2]'};
transType = {'FQ','FR','QR','QF','RF','RQ'};

%Get transition timepoints
indxA={};

for tNum = 1: length(transType);
    transitionData.(transType{tNum}) = cell(NumDataSets,1);
end

for recNum = 1:NumDataSets
    indxA{recNum,1} = find(diff(iThreeStates(recNum,:)));
    
    for tTNum  = 1:length(transType);
        count = 1;
        for tNum = 1:length(indxA{recNum,1});
            
            %get transition types e.g. [1 2]
            transition{recNum,tNum}= [iThreeStates(recNum,indxA{recNum,1}(tNum)),iThreeStates(recNum,(indxA{recNum,1}(tNum)+1))];
            
            %get indices for certain transition types determined by
            %'transitions'
            if strfind(mat2str(transition{recNum,tNum}),(transitions{tTNum})) >=1;
                transitionData.(transType{tTNum}){recNum,count} = indxA{recNum,1}(1,tNum);
                count = count+1;
            end
        end
    end
end

clearvars -except iThreeStates ThreeStates transition transType transitions transitionData tv tvi NumDataSets