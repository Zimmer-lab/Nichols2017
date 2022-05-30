%% Resampling of the cumulative sum of RMS or mean.
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'PermuteExperimentN'.
%run time: ~11h for 11 recordings and 1million reps.
clear all

%Number of repeats:
options.extraExclusionList = {'BAGL','BAGR','AQR','URXL','URXR','IL2DL','IL2DR'};

resamplingNum = 1000000;

%%%%%%%%%%%%%%%%%%%%
%For binning and x axis of histograms.
%xcentres = (0:0.03:1.4);
xcentres = (0:0.06:1.4);

%analysis = @rms;
analysis = @mean;
%%
FolderList = mywbGetDataFolders;
NumDataSets = length(FolderList);

%Make dynamic names for datasets
inputData ={};
for nn = 1:NumDataSets
    inputData{nn} = strcat('dataset', num2str(nn));
end

MainDir = pwd;

for recNum = 1:NumDataSets %Folder loop
    %load(ResultsStructFilename);
    
    cd(FolderList{recNum});
    wbload;
    
    %load QuiescentState
    awbQuiLoad
    
    %make array with the simple neuron numbers to exclude.
    numExclude=length(options.extraExclusionList);
    num4=1;
    ExcludedNeurons=[];
    for num3 = 1:numExclude;
        aaa = mywbFindNeuron(options.extraExclusionList{num3});
        if ~isempty(aaa);
            ExcludedNeurons(1,num4) = aaa;
            num4=num4+1;
        end
    end
    [~,NeuronN] =size(wbstruct.simple.deltaFOverF_bc);
    %Note: if running a dataset and dimensions don't match then check to see
    %if the wbstruct.simple _bc and normal deltaFOverF dimensions are the same.
    %Else you might need to run wbProcessTraces.
    IncludedNeurons = 1:NeuronN;
    IncludedNeurons(:,ExcludedNeurons) = [];
    
    calculateQuiescentRange
    
    rangeQLengths = QuBRunEnd - QuBRunStart;
    
    %find order of smallest to largest Qbouts
    [QboutsDescending,I] = sort(rangeQLengths,'descend');
    
    fullRange = 1:length(wbstruct.tv);
    
    % resampling loop which slides the rangeQ and rangeA over the whole
    % recording
    
    % Generate resampling ranges
    resampleN = 1;
    restartLoopt = 0;
    while resampleN <= resamplingNum; %length(wbstruct.tv);
        restartLoop = 0;
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
            if sum(currentRangeQ > length(wbstruct.tv)) > 0;
                indexToReplace = find(currentRangeQ > length(wbstruct.tv));
                currentRangeQ(indexToReplace) = currentRangeQ(indexToReplace) - length(wbstruct.tv);
            end
        end
        
        % catches occasions where the bouts aren't placed well.
        if restartLoop
            continue
        end
        
        if length(rangeQ) ~= length(currentRangeQ);
            disp('RANGES NOT EQUAL!!!')
        end
        
        % running analysis calculation for quiescent periods
        QuTraces = wbstruct.simple.deltaFOverF_bc(currentRangeQ,IncludedNeurons);
        QuiesceAnalysed = analysis(QuTraces);
        
        % Make Active range
        currentRangeA = fullRange;
        currentRangeA(currentRangeQ) = [];
        
        % running analysis calculation for active periods
        AcTraces = wbstruct.simple.deltaFOverF_bc(currentRangeA,IncludedNeurons);
        ActiveAnalysed = analysis(AcTraces);
        
        NeuronNum = length(ActiveAnalysed);
        
        %calculate histgrams
        BinnedQuiesceAnalysed =(histc(QuiesceAnalysed,xcentres))/NeuronNum;
        BinnedActiveAnalysed =(histc(ActiveAnalysed,xcentres))/NeuronNum;
        
        % Find the difference between the resampled means
        sampleDistances(recNum,resampleN) = sum(cumsum(BinnedQuiesceAnalysed) - cumsum(BinnedActiveAnalysed)); %CHECK end

        %% True values
        % running RMS calculation for quiescent periods
        QuTraces = wbstruct.simple.deltaFOverF_bc(rangeQ,IncludedNeurons);
        QuiesceAnalysed = analysis(QuTraces);
        
        % Make true Active range
        currentRangeA = fullRange;
        currentRangeA(rangeQ)= [];
        
        % running analysis calculation for active periods
        AcTraces = wbstruct.simple.deltaFOverF_bc(currentRangeA,IncludedNeurons);
        ActiveAnalysed = analysis(AcTraces);
        
        NeuronNum = length(ActiveAnalysed);
        BinnedQuiesceTrue.(inputData{recNum}) =(histc(QuiesceAnalysed,xcentres))/NeuronNum;
        BinnedActiveTrue.(inputData{recNum}) =(histc(ActiveAnalysed,xcentres))/NeuronNum;
        resampleN = resampleN+1;
    end
    disp(['Redid placement ',num2str(restartLoopt), 'times']);
    cd(MainDir)
end

%% Find the difference between the real means
for nn = 1:NumDataSets
    trueDistances(nn) = sum(cumsum(BinnedQuiesceTrue.(inputData{nn})) - cumsum(BinnedActiveTrue.(inputData{nn}))); %CHECK end
end

%% Resampled mean distances
meanSampleDistances = nanmean(sampleDistances);
meantrueDistances = nanmean(trueDistances);

%% Hist and cumsum plots
for nn = 1:NumDataSets
    FullRealDataQ(nn,:) = BinnedQuiesceTrue.(inputData{nn});
    FullRealDataA(nn,:) = BinnedActiveTrue.(inputData{nn});
end

figure; plot(mean(FullRealDataQ))
hold on
plot(mean(FullRealDataA),'r')

figure; plot(cumsum((FullRealDataQ')),'b')
hold on
plot(cumsum((FullRealDataA')),'r')

%% p values
[histD,xValues] = hist(meanSampleDistances,100);
histD = histD/length(meanSampleDistances);

if meantrueDistances < mean(meanSampleDistances)
    %     pValue = sum(bootstatDifs <= realMean)/length(bootstatDifs);
    %     display(pValue);
    disp('fix pvalue')
else
    pValue = sum(meanSampleDistances >= meantrueDistances)/length(meanSampleDistances);
end

%Plot figure
figure; bar(xValues,histD);
hold on
plot([meantrueDistances meantrueDistances],ylim,'r')

line1 = ['Resampling Results, p-Value:', mat2str(pValue)];
title({line1});
xlabel('distance between Quiescent and Active RMS cumsum');
ylabel('Fraction');
% Note P value may be close to zero or 1.

clearvars -except dateRun trueDistances sampleDistances Neurons xcentres resamplingNum pValue analysis...
    BinnedQuiesceAnalysed BinnedActiveAnalysed meanSampleDistances meantrueDistances NumDataSets inputData
