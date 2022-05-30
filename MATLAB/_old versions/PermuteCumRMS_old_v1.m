%% Resampling of the cumulative sum of RMS.
% This script is used to statiscally compare data using permutation to
% compare the means of the mean of each genotype/condition. It is built on
% 'PermuteExperimentN'.

%clear all

%Number of repeats:
options.extraExclusionList = {'BAGL','BAGR','AQR','URXL','URXR'};

%%%%%%%%%%%%%%%%%%%%
%For binning and x axis of histograms.
xcentres = (0:0.03:1.4); 

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

    %Make rangeQ
    %calculates positions of runs, i.e. QUIESCENT bout run starts
    %and ends.
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
    
    % resampling loop which slides the rangeQ and rangeA over the whole
    % recording
    for resampleN = 1:length(wbstruct.tv);
        currentRangeQ = str2num(options.rangeQ) + resampleN;
        
        %replace value with a low number if value goes over the end of the number of frames.
        if sum(currentRangeQ > length(wbstruct.tv)) > 0;
            indexToReplace = find(currentRangeQ > length(wbstruct.tv));
            currentRangeQ(indexToReplace) = currentRangeQ(indexToReplace) - length(wbstruct.tv);
        end
        
        % running RMS calculation for quiescent periods
        QuTraces = wbstruct.simple.deltaFOverF_bc(currentRangeQ,IncludedNeurons);
        QuiesceAnalysed = rms(QuTraces);
        
        % Make Active range
        fullRange = 1:length(wbstruct.tv);
        currentRangeA = fullRange;
        currentRangeA(currentRangeQ) = [];
        
        % running RMS calculation for active periods
        AcTraces = wbstruct.simple.deltaFOverF_bc(currentRangeA,IncludedNeurons);
        ActiveAnalysed = rms(AcTraces);
        
        NeuronNum = length(ActiveAnalysed);
        
        %calculate histgrams
        BinnedQuiesceAnalysed.(inputData{recNum}){resampleN} =(histc(QuiesceAnalysed,xcentres))/NeuronNum;
        BinnedActiveAnalysed.(inputData{recNum}){resampleN} =(histc(ActiveAnalysed,xcentres))/NeuronNum;
    end
    
    cd(MainDir)
end

%%
% Find the probability of the actual difference between the real means
for nn = 1:NumDataSets
    trueDistances(nn) = sum(cumsum(BinnedQuiesceAnalysed.(inputData{nn}){end}) - cumsum(BinnedActiveAnalysed.(inputData{nn}){end})); %CHECK end
end

% Find the probability of the actual difference between the resampled means
for nn = 1:NumDataSets
    for nnn = 1:(length(BinnedQuiesceAnalysed.(inputData{nn}))-1);
    sampleDistances(nn,nnn) = sum(cumsum(BinnedQuiesceAnalysed.(inputData{nn}){nnn}) - cumsum(BinnedActiveAnalysed.(inputData{nn}){nnn})); %CHECK end
    end
end

%reshape
[r, c] = size(sampleDistances);
AllSampleDistances = reshape(sampleDistances,1,(r*c));

%%
%Accounts for possibility of value being at either end.
if mean(trueDistances(1,:)) < mean(AllSampleDistances)
    pValue = sum(bootstatDifs <= realMean)/length(bootstatDifs);
    display(pValue);
else
    pValue = sum(AllSampleDistances >= mean(trueDistances(1,:)))/length(AllSampleDistances);
    display(pValue);
end

%%
[histD,xValues] = hist(AllSampleDistances,100);
histD = histD/length(AllSampleDistances);

%Plot figure
figure; bar(xValues,histD);
hold on
for bb =1:NumDataSets
    plot([trueDistances(1,bb) trueDistances(1,bb)],ylim,'b')
end
plot([mean(trueDistances(1,:)) mean(trueDistances(1,:))],ylim,'r')

line1 = ['Resampling Results, p-Value:', mat2str(pValue)];
title({line1});
xlabel('distance between Quiescent and Active RMS cumsum');
ylabel('Fraction');
% Note P value may be close to zero or 1.

clearvars r c recNum bootsam bootstat jj nExperiments inputs iii idx CurrTrackN 

%%

for nn = 1:NumDataSets
    FullRealDataQ(nn,:) = BinnedQuiesceAnalysed.(inputData{nn}){end};
    FullRealDataA(nn,:) = BinnedActiveAnalysed.(inputData{nn}){end};
end

%%
figure; plot(mean(FullRealDataQ))
hold on
plot(mean(FullRealDataA),'r')

figure; plot(cumsum((FullRealDataQ')),'b')
hold on
plot(cumsum((FullRealDataA')),'r')


