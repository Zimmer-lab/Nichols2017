%% Resampling of the cumulative sum of activity.
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'PermuteExperimentN'.
clear all

%Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
Neurons = {'AVAR','RIML','RIMR','VB02','VA01','RMED'};
%Number of repeats:
resamplingNum = 1000000;

%For binning and x axis of histograms.
xcentres = (0:0.06:3.5);

%%
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:NumDataSets
    inputData{nn} = strcat('dataset', num2str(nn));
end

%Make dynamic names for neuron datasets
inputDataNeuron =Neurons;

MainDir = pwd;

for recNum = 1:NumDataSets %Folder loop
    
    cd(FolderList{recNum});
    wbload;
    
    %% load QuiescentState
    masterfolder = pwd;
    cd ([strcat(masterfolder,'/Quant')]);
    num2 = exist('QuiescentState.mat', 'file');
    if gt(1,num2);
        X=['No QuiescentState file in folder: ', wbstruct.trialname, ', please run awbQAstateClassifier or specify own range'];
        disp(X)
        return
    end
    load('QuiescentState.mat');
    cd(masterfolder);
    
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
    
    rangeQLengths = QuBRunEnd - QuBRunStart;
    
    %find order of smallest to largest Qbouts
    [QboutsDescending,I] = sort(rangeQLengths,'descend');
    %descendingQBoutStarts = (QuBRunStart(I));
    
    fullRange = 1:length(wbstruct.tv);
    % resampling loop which slides the rangeQ and rangeA over the whole
    % recording
    
    for neuNum = 1:length(Neurons)
        %get neuron trace
        Trace = wbgettrace(Neurons{neuNum});
        if ~isnan(Trace)
            for resampleN = 1:resamplingNum; %length(wbstruct.tv);
                %find random frame for first sit.
                firstPosition = randperm(length(wbstruct.tv),1);
                
                currentRangeQ = firstPosition:(firstPosition+QboutsDescending(1));
                
                resampledBoutStarts = firstPosition;
                
                %replace value with a low number if value goes over the end of the number of frames.
                if sum(currentRangeQ > length(wbstruct.tv)) > 0;
                    indexToReplace = find(currentRangeQ > length(wbstruct.tv));
                    currentRangeQ(indexToReplace) = currentRangeQ(indexToReplace) - length(wbstruct.tv);
                end
                
                for boutN = 2:length(QboutsDescending);
                    %find possible positions to put the starting point of the next
                    %bout.
                    startMaskedBouts = (resampledBoutStarts(1:(boutN-1)) - QboutsDescending(boutN));
                    endMaskedBouts = resampledBoutStarts(1:(boutN-1));
                    
                    maskedPositions = [];
                    for earlierBoutNum = 1:length(startMaskedBouts);
                        maskedPositions = [maskedPositions,startMaskedBouts(earlierBoutNum):endMaskedBouts(earlierBoutNum)];
                    end
                    
                    %replace value with a high number if value goes over the start of the number of frames.
                    if sum(maskedPositions < 1) > 0;
                        indexToReplace = find(maskedPositions < 1);
                        maskedPositions(indexToReplace) = maskedPositions(indexToReplace) + length(wbstruct.tv);
                    end
                    
                    currentPossibleRangeQ = fullRange;
                    currentPossibleRangeQ([currentRangeQ,maskedPositions]) = [];
                    
                    nextPositionI = randperm(length(currentPossibleRangeQ),1);
                    nextPosition = currentPossibleRangeQ(nextPositionI);
                    currentRangeQ = [currentRangeQ, nextPosition:(nextPosition+QboutsDescending(boutN))];
                    resampledBoutStarts = [resampledBoutStarts, nextPosition];
                    
                    %replace value with a low number if value goes over the end of the number of frames.
                    if sum(currentRangeQ > length(wbstruct.tv)) > 0;
                        indexToReplace = find(currentRangeQ > length(wbstruct.tv));
                        currentRangeQ(indexToReplace) = currentRangeQ(indexToReplace) - length(wbstruct.tv);
                    end
                    
                end
                
                if length(str2num(options.rangeQ)) ~= length(currentRangeQ);
                    disp('RANGES NOT EQUAL!!!')
                end
                
                %Get quiescent or active trace
                QuTrace = Trace(currentRangeQ);
                
                % Make Active range
                currentRangeA = fullRange;
                currentRangeA(currentRangeQ) = [];
                
                ActTrace = Trace(currentRangeA);
                
                %get histogram for neuron in Quiescent states and normalise by the number
                %of timepoints
                BinnedQuiesce.(inputData{recNum}).(inputDataNeuron{neuNum})(:,resampleN) = (histc(QuTrace,xcentres))/(length(currentRangeQ));
                
                %get for Active states
                BinnedActive.(inputData{recNum}).(inputDataNeuron{neuNum})(:,resampleN) = (histc(ActTrace,xcentres))/(length(ActTrace));
            end
            %%  Get true quiescent or active trace
            QuTrace = Trace([str2num(options.rangeQ)]);
            
            fullRange = 1:length(wbstruct.tv);
            RangeActive = fullRange;
            RangeActive([str2num(options.rangeQ)]) = [];
            
            ActTrace = Trace(RangeActive);
            
            BinnedQuiesceTrue.(inputData{recNum}).(inputDataNeuron{neuNum}) =(histc(QuTrace,xcentres))/(length(str2num(options.rangeQ)));
            BinnedActiveTrue.(inputData{recNum}).(inputDataNeuron{neuNum}) =(histc(ActTrace,xcentres))/(length(ActTrace));
        end
    end
    cd(MainDir)
end

%%
% Find the actual difference between the real means
for neuNum = 1: length(Neurons);
    for nn = 1:NumDataSets
        if isfield(BinnedActive.(inputData{nn}), inputDataNeuron{neuNum})
            trueDistances(nn,neuNum) = sum(cumsum(BinnedActiveTrue.(inputData{nn}).(inputDataNeuron{neuNum})) - cumsum(BinnedQuiesceTrue.(inputData{nn}).(inputDataNeuron{neuNum})));
            
        end
    end
end
% for neuNum = 1: length(Neurons)
%     sampleDistances.(inputDataNeuron{neuNum}) = nan(recNum,resamplingNum);
% end

% Find the probability of the actual difference between the resampled means
for neuNum = 1:length(Neurons)
    for recNum = 1:NumDataSets
        %         for nnn = 1:(length(BinnedQuiesce.(inputData{recNum}).(inputDataNeuron{neuNum}))-1);
        %             sampleDistances.inputDataNeuron{neuNum}(recNum,nnn) = sum(cumsum(BinnedActive.(inputData{recNum}).(inputDataNeuron{neuNum})) - cumsum(BinnedQuiesce.(inputData{recNum}).(inputDataNeuron{neuNum})));
        %         end
        if isfield(BinnedActive.(inputData{recNum}), inputDataNeuron{neuNum})
            sampleDistances.(inputDataNeuron{neuNum})(recNum,:) = sum(cumsum(BinnedActive.(inputData{recNum}).(inputDataNeuron{neuNum})) - cumsum(BinnedQuiesce.(inputData{recNum}).(inputDataNeuron{neuNum})));
        end
    end
end

%% Mean distances
meanSampleDistances = nan(length(Neurons),resamplingNum);
for neuNum = 1:length(Neurons)
    if isfield(BinnedActive.(inputData{recNum}), inputDataNeuron{neuNum})
        meanSampleDistances(neuNum,:) = mean(sampleDistances.(inputDataNeuron{neuNum}));
    end
end

%% Real p values
for neuNum = 1:length(Neurons)
    
    [histD1,xValues1] = hist(meanSampleDistances(neuNum,:),100);
    histD1 = histD1/length(meanSampleDistances(neuNum));
    
    %Plot figure
    figure; bar(xValues1,histD1);
    hold on
    plot([mean(trueDistances(1,:)) mean(trueDistances(1,:))],ylim,'r')
    title([inputDataNeuron{neuNum}]);
    xlabel('distance between Quiescent and Active RMS cumsum');
    ylabel('Fraction');
    
    
    if mean(trueDistances(neuNum)) < mean(meanSampleDistances(neuNum,:))
        pValue.(inputDataNeuron{neuNum}) = sum(meanSampleDistances(neuNum,:) <= mean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
        display(pValue);
        disp('fix pvalue')
    else
        pValue.(inputDataNeuron{neuNum}) = sum(meanSampleDistances(neuNum,:) >= mean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
    end
end
