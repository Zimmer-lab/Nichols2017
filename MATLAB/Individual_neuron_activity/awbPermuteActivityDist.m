%% Resampling of the cumulative sum of activity.
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'PermuteExperimentN'.
clear all

%Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
%Neurons = {'AVAR','RIML','RIMR','VB02','VA01','RMED'};

%AQ
Neurons = {'ALA','RIS','AFDL','AFDR','RID','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR',...
    'SMDDL','SMDDR','ASKL','ASKR'};

%Number of repeats:
resamplingNum = 1;

%For binning and x axis of histograms.
xcentres = (0:0.06:3.5);

%LOG!
xcentres = logspace(-3,0.7);
logon = 1;

%%
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:NumDataSets
    inputData{nn} = strcat('dataset', num2str(nn));
end


%Preallocate
for neuNum = 1:length(Neurons)
    sampleDistances.(Neurons{neuNum}) = single(nan(NumDataSets,resamplingNum));
    trueDistances = nan(NumDataSets,length(Neurons));
end

MainDir = pwd;

for recNum = 1:NumDataSets %Folder loop
    tic
    cd(FolderList{recNum});
    wbload;
    
    %% load QuiescentState
    awbQuiLoad
    
    %% calculates quiescent and active range
    calculateQuiescentRange
    
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
                
                if length(rangeQ) ~= length(currentRangeQ);
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
                BinnedQuiesce = (histc(QuTrace,xcentres))/(length(currentRangeQ));
                
                %get for Active states
                BinnedActive = (histc(ActTrace,xcentres))/(length(ActTrace));
                
                % Find the sum of the differences between the resampled means
                sampleDistances.(Neurons{neuNum})(recNum,resampleN) = sum(cumsum(BinnedActive) - cumsum(BinnedQuiesce));
            end
            %%  Get true quiescent or active trace
            QuTrace = Trace(rangeQ);
            
            fullRange = 1:length(wbstruct.tv);
            RangeActive = fullRange;
            RangeActive(rangeQ) = [];
            
            ActTrace = Trace(RangeActive);
            
            BinnedQuiesceTrue =(histc(QuTrace,xcentres))/(length(rangeQ));
            BinnedActiveTrue =(histc(ActTrace,xcentres))/(length(ActTrace));
            
            trueDistances(recNum,neuNum) = sum(cumsum(BinnedActiveTrue) - cumsum(BinnedQuiesceTrue));
            
        end
    end
    toc
    cd(MainDir)
end

%% Mean distances
meanSampleDistances = nan(length(Neurons),resamplingNum);
for neuNum = 1:length(Neurons)
    if isfield(sampleDistances, Neurons{neuNum})
        meanSampleDistances(neuNum,:) = nanmean(sampleDistances.(Neurons{neuNum}));
    end
end

%% Real p values
for neuNum = 1:length(Neurons)
    
    [histD1,xValues1] = hist(meanSampleDistances(neuNum,:),100);
    histD1 = histD1/length(meanSampleDistances(neuNum));
    
    %Plot figure
    figure; bar(xValues1,histD1);
    hold on
    plot([mean(trueDistances(:,neuNum)) mean(trueDistances(:,neuNum))],ylim,'r')
    title([Neurons{neuNum}]);
    xlabel('distance between Quiescent and Active RMS cumsum');
    ylabel('Fraction');
    
    
%     if mean(trueDistances(:,neuNum)) < mean(meanSampleDistances(neuNum,:))
         pValue.(Neurons{neuNum}) = sum(meanSampleDistances(neuNum,:) <= nanmean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
%         disp(pValue);
%     else
%         pValue.(Neurons{neuNum}) = sum(meanSampleDistances(neuNum,:) >= nanmean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
%     end
end

%
%save ('/Users/nichols/Dropbox/_Analysing sets/npr1_2_Let/ResamplingActivityDistAQnpr1LetLog20161104.mat', 'trueDistances','sampleDistances','Neurons','xcentres','resamplingNum','pValue','-v7.3');

