%% Resampling of the cumulative sum of activity between differences of the FRQ.
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'PermuteExperimentN'.
clear all

%Neurons = {'AVAL','AVAR','RIML','RIMR','VB02','VA01','RIS','RMED','RMER','RMEL','RMEV','AVEL','AVER','AIBL','AIBR','AVBL','AVBR','RIBL','RIBR','URYDL','URYDR','URYVL','URYVR','OLQDL','OLQDR','OLQVL','OLQVR','ALA','RIVL','RIVR','AFDL','AFDR','RID','SIBVL','SIBVR','SIBDL','SIBDR','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR','SMDDL','SMDDR','SMDVL','SMDVR','ASKL','ASKR'};
%Neurons = {'AVAR','RIML','RIMR','VB02','VA01','RMED'};

%Number of repeats:
resamplingNum = 1000000;

%'F' for forward, 'R' for reverse, 'A' for both
State2 = 'A';

%For binning and x axis of histograms.
%xcentres = (0:0.06:3.5); old analysis

%xcentres = (-0.5:0.05:3.5);

%LOG!
xcentres = logspace(-3,0.7);
logon = 1;

if State2 == 'F'
    %FQ
    Neurons = {'VB02','RIS','RMED','RMER','RMEL','RMEV','AVBL','AVBR','RIBL','RIBR',...
        'SIBVL','SIBVR','SIBDL','SIBDR'};

elseif State2 == 'R'
    %RQ
    Neurons = {'AVAL','AVAR','RIML','RIMR','VA01','AVEL','AVER','AIBL','AIBR',...
        'URYDL','URYDR','URYVL','URYVR','OLQDR','RIVL','RIVR','SMDVL','SMDVR'};

elseif State2 == 'A'
    Neurons ={'SMDVL','SMDVR'};
else
    disp('Confused about State2 input!')
    return
end

% %AQ
% Neurons = {'ALA','RIS','AFDL','AFDR','RID','AVFL','AVFR','AWCL','AWCR','AWBL','AWBR',...
%     'SMDDL','SMDDR','ASKL','ASKR'};


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
    
    % resampling loop which slides the rangeQ and range(F/R) over the
    % recording area which covers those two states
    
    fullRange2All = 1:length(wbstruct.tv);
    
    %Only get quiescent and State2 (i.e. forward or reverse) periods
    fullRange2States = fullRange2All;
    
    %Find Reversal and Forward brain states (updated to make Forward AVA
    %FALL and LOW, and Reversal RISE and HIGH)
    avaRISEHIGH = avaRISE + avaHIGH;

    indexNotForward = [find(avaRISEHIGH)',rangeQ];
    RangeForwardFL = fullRange;
    RangeForwardFL(indexNotForward) = [];
    
    indexNotReversal = [RangeForwardFL,rangeQ];
    RangeReversalRH = fullRange;
    RangeReversalRH(indexNotReversal) = [];
    
    
    if State2 == 'F'
        fullRange2States(RangeReversalRH) = [];
    elseif State2 == 'R'
        fullRange2States(RangeForwardFL) = [];
    elseif State2 == 'A'
        disp('Using full range (Active vs Quiescent)')
    else
        disp('Confused about State2 input!')
        return
    end
    
    %get neuron traces
    for neuNum = 1:length(Neurons)
        
        TraceAll.(Neurons{neuNum}) = wbgettrace(Neurons{neuNum});
        
        if ~isnan(TraceAll.(Neurons{neuNum}))
            %Only get quiescent and State2 (i.e. forward or reverse) periods of
            %the trace.
            Trace.(Neurons{neuNum}) = TraceAll.(Neurons{neuNum});
            if State2 == 'F'
                Trace.(Neurons{neuNum})(RangeReversalRH) = [];
            elseif State2 == 'R'
                Trace.(Neurons{neuNum})(RangeForwardFL) = [];
            elseif State2 == 'A'
            else
                disp('Confused about State2 input!')
                return
            end
        else
            Trace.(Neurons{neuNum}) = NaN;
        end
    end
    
    % Generate resampling ranges
    resampleN = 1;
    restartLoopt = 0;
    while resampleN <= resamplingNum; %length(wbstruct.tv);
        restartLoop = 0;
        %find random frame for first sit.
        firstPosition = randperm(length(fullRange2States),1);
        
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
            
            currentPossibleRangeQ = 1:length(fullRange2States);
            currentPossibleRangeQ([currentRangeQ,maskedPositions]) = [];
            
%                         %% testing figures
%                         test = ones(length(fullRange2States),1);
%                         test(currentRangeQ) = 2;
%                         figure; imagesc(test)
            
            % catches occasions where the bouts aren't placed well.
            if length(currentPossibleRangeQ) <1
                %disp('no place to put next bout')
                restartLoop = 1;
                restartLoopt = restartLoopt +1;
                break
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
        
        % catches occasions where the bouts aren't placed well.
        if restartLoop
            continue
        end
        
        if length(rangeQ) ~= length(currentRangeQ);
            disp('RANGES NOT EQUAL!!!')
        end
        
        for neuNum = 1:length(Neurons)
            if ~isnan(TraceAll.(Neurons{neuNum}))
                %Get quiescent or active trace
                QuTrace = Trace.(Neurons{neuNum})(currentRangeQ);
                
                % Make Active range
                currentRangeA = 1:length(fullRange2States);
                currentRangeA(currentRangeQ) = [];
                
                ActTrace = Trace.(Neurons{neuNum})(currentRangeA);
                
                %get histogram for neuron in Quiescent states and normalise by the number
                %of timepoints
                BinnedQuiesce = (histc(QuTrace,xcentres))/(length(currentRangeQ));
                
                %get for Active states
                BinnedActive = (histc(ActTrace,xcentres))/(length(ActTrace));
                
                % Find the sum of the differences between the resampled
                % means
                sampleDistances.(Neurons{neuNum})(recNum,resampleN) = sum((cumsum(BinnedActive) - cumsum(BinnedQuiesce)));

                % absolute????!!!
                %sampleDistances.(Neurons{neuNum})(recNum,resampleN) = sum(abs(cumsum(BinnedActive) - cumsum(BinnedQuiesce)));
                
                %                 figure; plot(cumsum(BinnedActive),'r')
                %                 hold on; plot(cumsum(BinnedQuiesce),'b')
                %                 title([Neurons{neuNum}]);
                
            end
        end

        resampleN = resampleN+1;
    end
    disp(['Redid placement ',num2str(restartLoopt), 'times']);
    
    %%  Get true quiescent or active trace
    for neuNum = 1:length(Neurons)
        if ~isnan(TraceAll.(Neurons{neuNum}))
            
            QuTrace = TraceAll.(Neurons{neuNum})(rangeQ);
            
            %Only get quiescent and State2 (i.e. forward or reverse) periods of
            %the trace.
            if State2 == 'F'
                RangeState2 = RangeForwardFL;
            elseif State2 == 'R'
                RangeState2 = RangeReversalRH;
            elseif State2 == 'A'
                RangeState2 = rangeA;
            end
            ActTrace = TraceAll.(Neurons{neuNum})(RangeState2);
            
            BinnedQuiesceTrue =(histc(QuTrace,xcentres))/(length(rangeQ));
            BinnedActiveTrue =(histc(ActTrace,xcentres))/(length(ActTrace));
            
%                         figure; plot(cumsum(BinnedActiveTrue),'r')
%                         hold on; plot(cumsum(BinnedQuiesceTrue),'b')
%                         title([Neurons{neuNum}]);
            
            %Absolute distance
            %trueDistances(recNum,neuNum) = sum(abs(cumsum(BinnedActiveTrue) - cumsum(BinnedQuiesceTrue)));
            trueDistances(recNum,neuNum) = sum((cumsum(BinnedActiveTrue) - cumsum(BinnedQuiesceTrue)));

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
    plot([nanmean(trueDistances(:,neuNum)) nanmean(trueDistances(:,neuNum))],ylim,'r')
    title([Neurons{neuNum}]);
    xlabel('distance between Quiescent and Active RMS cumsum');
    ylabel('Fraction');
    
    
%     if mean(trueDistances(:,neuNum)) < mean(meanSampleDistances(neuNum,:))
         pValue.(Neurons{neuNum}) = sum(meanSampleDistances(neuNum,:) <= nanmean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
%     else
%        pValue.(Neurons{neuNum}) = sum(meanSampleDistances(neuNum,:) >= nanmean(trueDistances(:,neuNum)))/length(meanSampleDistances(neuNum,:));
%     end
end
disp(pValue)
clearvars -except meanSampleDistances dateRun trueDistances trueDistancesAbs sampleDistances Neurons xcentres resamplingNum pValue

%save ('/Users/nichols/Dropbox/_Analysing sets/npr1_2_Let/ResamplingActivityDistFRnpr1LetLog20161206.mat', 'trueDistances','sampleDistances','Neurons','xcentres','resamplingNum','pValue','-v7.3');

