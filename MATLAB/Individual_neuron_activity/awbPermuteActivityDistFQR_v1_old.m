%% Resampling of the cumulative sum of activity between differences of the FRQ.
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'PermuteExperimentN'.
clear all

Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
%Neurons = {'AVAR','RIML','RIMR','VB02','VA01','RMED'};
Neurons = {'AVAL','RIS','VB02'};
%Number of repeats:
resamplingNum = 100;

%'F' for forward, 'R' for reverse
State2 = 'R'; 

%For binning and x axis of histograms.
%xcentres = (0:0.06:3.5); old analysis

xcentres = (-0.5:0.05:3.5);

%%
State1 = 'Q'; %haven't added to change this from Q.

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
    
    % resampling loop which slides the rangeQ and range(F/R) over the
    % recording area which covers those two states
    
    fullRange2States = 1:length(wbstruct.tv);

    
    
    for neuNum = 1:length(Neurons)
        %get neuron trace
        TraceAll = wbgettrace(Neurons{neuNum});
        
        if ~isnan(TraceAll)
            %Only get quiescent and State2 (i.e. forward or reverse) periods of
            %the trace.
            Trace = TraceAll;
            if State2 == 'F'
                Trace(RangeReversal) = [];
            elseif State2 == 'R'
                Trace(RangeForward) = [];
            else
                disp('Confused about State2 input!')
                return
            end

        
            for resampleN = 1:resamplingNum; %length(wbstruct.tv);
                %find random frame for first sit.
                firstPosition = randperm(length(Trace),1);
                
                currentRangeQ = firstPosition:(firstPosition+QboutsDescending(1));
                
                resampledBoutStarts = firstPosition;
                
                %replace value with a low number if value goes over the end of the number of frames.
                if sum(currentRangeQ > length(fullRange2States)) > 0;
                    indexToReplace = find(currentRangeQ > length(fullRange2States));
                    currentRangeQ(indexToReplace) = currentRangeQ(indexToReplace) - length(fullRange2States);
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
                        maskedPositions(indexToReplace) = maskedPositions(indexToReplace) + length(fullRange2States);
                    end
                    
                    currentPossibleRangeQ = fullRange2States;
                    currentPossibleRangeQ([currentRangeQ,maskedPositions]) = [];
                    
                    %% testing figures
                    test = ones(length(fullRange2States),1);
                    test(currentRangeQ) = 2;
                    figure; imagesc(test)
                    %%
                    
                    if length(currentPossibleRangeQ) <1
                        disp('no place to put next bout')
                    end
                    
                    nextPositionI = randperm(length(currentPossibleRangeQ),1);
                    nextPosition = currentPossibleRangeQ(nextPositionI);
                    currentRangeQ = [currentRangeQ, nextPosition:(nextPosition+QboutsDescending(boutN))];
                    resampledBoutStarts = [resampledBoutStarts, nextPosition];
                    
                    %replace value with a low number if value goes over the end of the number of frames.
                    if sum(currentRangeQ > length(fullRange2States)) > 0;
                        indexToReplace = find(currentRangeQ > length(fullRange2States));
                        currentRangeQ(indexToReplace) = currentRangeQ(indexToReplace) - length(fullRange2States);
                    end
                    
                end
                
                if length(rangeQ) ~= length(currentRangeQ);
                    disp('RANGES NOT EQUAL!!!')
                end
                
                %Get quiescent or active trace
                QuTrace = Trace(currentRangeQ);
                
                % Make Active range
                currentRangeA = fullRange2States;
                currentRangeA(currentRangeQ) = [];
                
                ActTrace = Trace(currentRangeA);
                
                %get histogram for neuron in Quiescent states and normalise by the number
                %of timepoints
                BinnedQuiesce = (histc(QuTrace,xcentres))/(length(currentRangeQ));
                
                %get for Active states
                BinnedActive = (histc(ActTrace,xcentres))/(length(ActTrace));
                
                % Find the sum of the differences between the resampled
                % means 
                % absolute!!!
                sampleDistances.(Neurons{neuNum})(recNum,resampleN) = sum(abs(cumsum(BinnedActive) - cumsum(BinnedQuiesce)));
                        
                
%                 figure; plot(cumsum(BinnedActive),'r')
%                 hold on; plot(cumsum(BinnedQuiesce),'b')
%                 title([Neurons{neuNum}]);
            end
            %%  Get true quiescent or active trace
            QuTrace = TraceAll(rangeQ);
            
            %Only get quiescent and State2 (i.e. forward or reverse) periods of
            %the trace.
            if State2 == 'F'
                RangeState2 = RangeForward;
            elseif State2 == 'R'
                RangeState2 = RangeReversal;
            end
            ActTrace = TraceAll(RangeState2);
            
            BinnedQuiesceTrue =(histc(QuTrace,xcentres))/(length(rangeQ));
            BinnedActiveTrue =(histc(ActTrace,xcentres))/(length(ActTrace));
            
%             figure; plot(cumsum(BinnedActiveTrue),'r')
%             hold on; plot(cumsum(BinnedQuiesceTrue),'b')
%             title([Neurons{neuNum}]);
            
            trueDistances(recNum,neuNum) = sum(abs(cumsum(BinnedActiveTrue) - cumsum(BinnedQuiesceTrue)));
            
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
    
    
    if mean(trueDistances(:,neuNum)) < mean(meanSampleDistances(neuNum,:))
        pValue.(Neurons{neuNum}) = sum(meanSampleDistances(neuNum,:) <= nanmean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
        display(pValue);
        disp('fix pvalue')
    else
        pValue.(Neurons{neuNum}) = sum(meanSampleDistances(neuNum,:) >= nanmean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
    end
end

%
%save ('/Users/nichols/Dropbox/_Analysing sets/npr1_2_Let/ResamplingActivityDistALLnpr1Let.mat', 'trueDistances','sampleDistances','Neurons','xcentres','resamplingNum','pValue','-v7.3');

