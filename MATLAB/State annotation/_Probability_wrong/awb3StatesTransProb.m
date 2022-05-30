
clear all

awb3States

%% Transition probability binned by neuron activity.
clearvars -except iThreeStates ThreeStates transition transitionData tv tvi NumDataSets
condition = 'npr1Let';

minTimepoints = 20;
bRange = 1:1800; %to max -1 e.g. 5399 not 5400. 300=1m 2400:3599 is 8m to 12m
cutoffs = -0.25:0.25:2; %(edges)
checkBinning = 1;

% Pick neurons
dataID= {'AQR','AUA','IL2','RMG','URX','RIS'};
loadData= [0,0,0,0,0,1]; % 0 = don't include, 1= include

% 1 mean; 2 /RIS; 3 multiple neurons /RIS; 4 = sum
DataComb = 1;

%should change so this is automatically generated as at the moment it is
%only set up for np-1 let.
recordingsnpr1Let = {'AN20140731a_ZIM575_Let_6m_O2_21_s_1TF_50um_1120_';...
    'AN20140731b_ZIM575_Let_6m_O2_21_s_1TF_50um_1120_';...
    'AN20140731d_ZIM575_Let_6m_O2_21_s_1TF_50um_1240_';...
    'AN20140731e_ZIM575_Let_6m_O2_21_s_1TF_50um_1400_';...
    'AN20140731f_ZIM575_Let_6m_O2_21_s_1TF_50um_1400_';...
    'AN20140731g_ZIM575_Let_6m_O2_21_s_1TF_50um_1400_';...
    'AN20140731i_ZIM575_Let_6m_O2_21_s_1TF_50um_1540_';...
    'AN20140731j_ZIM575_Let_6m_O2_21_s_1TF_50um_1540_';...
    'AN20140731k_ZIM575_Let_6m_O2_21_s_1TF_50um_1540_';...
    'AN20151112a_ZIM1027_ilnpr1_NGM1mMTF_1310_Let_';...
    'AN20151112b_ZIM1027_ilnpr1_NGM1mMTF_1310_Let_'};

%Neuron data
dataDir ='/Users/nichols/Documents/Imaging/URX_responses';
dataToLoad = {'FullAQRresponses20160922','FullAUAresponses20160921',...
    'FullIL2responses20160921','FullRMGresponses20160922',...
    'FullURXresponses20160921','FullRISresponses20160923'};

indx = find(loadData);
inputType = 'pairsAveraged_mean20pc';
inputRIS = 'deltaFOverF_bc';

% Correct to frames
%RangeFrames = Range*5; %may be slightly off due to rounding. 5 is from the interpolated data frame rate.
[recNum,~] =  size(recordingsnpr1Let);
clearvars selectNeuronResponse 
comNeuronResponse1 = NaN(NumDataSets,5400,sum(loadData));
dim = 0;

cd(dataDir)
for ii = 1:length(dataID)
    if loadData(ii) == 1;
        load(dataToLoad{ii});
        
        % run to get .pairsAveraged_mean20pc
        [nRecordings,~] = size(NeuronResponse.(condition).cumnNeuronsPerRecording);
        startingNeuron = 1;
        for jj = 1:nRecordings;
            if length(startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))>1
                NeuronResponse.(condition).pairsAveraged_mean20pc(jj,:) = mean((NeuronResponse.(condition).deltaFOverF_mean20pc(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
                startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(jj)+1;
            else
                NeuronResponse.(condition).pairsAveraged_mean20pc(jj,:) = NeuronResponse.(condition).deltaFOverF_mean20pc(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
                startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(jj)+1;
            end
        end
        clearvars startingNeuron cumnNeuronsPerRecording jj
        
        % Get the recording number position (not all neurons are in all
        % recordings)
        ExIDpaired = unique(NeuronResponse.(condition).ExpID);
        ExIDpos = nan(length(ExIDpaired),1);
        for recNum = 1:length(recordingsnpr1Let);
            for IDnum = 1:length(ExIDpaired);
                if strfind(recordingsnpr1Let{recNum},ExIDpaired{IDnum});
                    ExIDpos(IDnum,1) = recNum;
                end
            end
        end
                
        for recNum = 1:NumDataSets
            if 1 >= (sum(ExIDpos == recNum))
                if ii == 6
                    input = inputRIS;
                    comNeuronResponse1(recNum,:,dim+1) = NeuronResponse.(condition).(input)(:,find(ExIDpos == recNum));
                else
                    input = inputType;
                    comNeuronResponse1(recNum,:,dim+1) = NeuronResponse.(condition).(input)(find(ExIDpos == recNum),:)';
                end
            end
        end
        % if using multiple neurons this adds then to the next dimension of
        % RevCopyNR
        dim = dim+1;
    end
end
clearvars dim inputType inputRIS recNum Range recordingsnpr1Let dataToLoad...
    dataID dataDir NeuronResponse ExIDpaired ExIDpos condition ii indx input nRecordings...
    nRecordings IDnum
%% for working out reversal bins vs neuron activity bins

% Get binnned neuron response data
[~,~,D]= size(comNeuronResponse1);
if DataComb == 1
    NeuronData = nanmeanD(comNeuronResponse1,3);
elseif DataComb == 3
    transientNeuMean = nanmeanD(comNeuronResponse1(:,:,1:(D-1)),3);
    NeuronData = (transientNeuMean)./(comNeuronResponse1(:,:,D));
elseif DataComb == 2
    NeuronData = (comNeuronResponse1(:,:,1))./(comNeuronResponse1(:,:,2));
else
    NeuronData = comNeuronResponse1;
end

clearvars idxOverCutoff D TransProbData transAll

for ii = 1:NumDataSets
    dataset{ii} = ['dataset',num2str(ii)];
end

TransProbDataN= NaN(NumDataSets,(length(cutoffs)-1));

for recNum = 1:NumDataSets
    transAll = NaN(3,3,(length(cutoffs)-1));
    for cutoff = 1:(length(cutoffs)-1);
        idxOverCutoff{cutoff,:} = find(...
        ((cutoffs(1,cutoff) < (NeuronData(recNum,1:5399))) + ...
        ((NeuronData(recNum,1:5399)) <= cutoffs(1,cutoff+1)))-1);
        
        fullrange = zeros(1,5399);
        fullrange(idxOverCutoff{cutoff,:})=1;
        
        L = logical(fullrange);
        stats = regionprops(L,'BoundingBox');
        trans = NaN(3,3,length(stats));
        addedBout = 1;
        
        for ii = 1: length(stats)
            %from BB https://au.mathworks.com/matlabcentral/answers/86370-finding-the-finite-state-transition-probability-matrix-of-a-markov-chain-with-one-fixed-state
            % trans = full(sparse(x(1:end-1)+1, x(2:end)+1, 1));
            % trans = bsxfun(@rdivide, trans, sum(trans,2));
            
            statsRead = stats(ii,1).BoundingBox;
            startBout = statsRead(1,1) +0.5; %0.5 corrects to timepoint
            lengthBout = statsRead(1,3)-1;
                        
            %!!!CHANGE!!! IGNORING data which starts outside of range but continues inside.....
            %only look at transitions in correct range
                
            endBout = startBout+lengthBout;
            %get start if start is earlier than range
            if (min(bRange) >= startBout) && (min(bRange) < endBout)
                startBout = min(bRange);
            end

            %get end if end is later than end of range
            if (max(bRange) > startBout) && (max(bRange) <= endBout)
                endBout = max(bRange);
            end

            %exclude cases where it doesn't fall within the range.
            if (min(bRange) <= startBout) && (max(bRange) >= endBout)
                % enter x data
                x = [[0,1,2,0],iThreeStates(recNum,startBout:endBout)];
                %had to add the the 0,1,2,0 dummy at the start so all transitions would
                %be looked at.

                % make transition matrix
                transDummy = full(sparse(x(1:end-1)+1, x(2:end)+1, 1));

                % take away dummy transitions
                if x(5) == 0
                    dummyBase = [1,1,0;0,0,1;1,0,0];
                elseif x(5) == 1
                    dummyBase = [0,2,0;0,0,1;1,0,0];
                elseif x(5) == 2
                    dummyBase = [0,1,1;0,0,1;1,0,0];
                end
                trans(:,:,addedBout) = transDummy - dummyBase;
                addedBout = addedBout+1;
            end
        end
        if ~isempty(trans)
            transSum(:,:,cutoff) = nansumD(trans,3);
            [~,~,dim] = size(transSum);
            transSumCutoff = reshape(nansum(nansum(transSum)),1,dim);
            
            if transSumCutoff(1,cutoff) > minTimepoints
                transAll(:,:,cutoff) = bsxfun(@rdivide, transSum(:,:,cutoff), sum(transSum(:,:,cutoff),2));
            end
        end
    end
    [~,~,dim] = size(transSum);
    transInter = reshape(nansum(nansum(transSum)),1,dim);
    TransProbDataN(recNum,1:length(transInter)) = transInter;
    
    TransProbData.(dataset{recNum}) = transAll;
    
    %check binning across all recordings
    if checkBinning == 1
        fullrange = zeros(length(cutoffs)-1,5399);
        
        for cutoff = 1:(length(cutoffs)-1);
            fullrange(cutoff,idxOverCutoff{cutoff,:})=1;
        end
        figure; imagesc(fullrange);
    end
end


%note that the num of timepoints are not equal to the full timepoints as
%transitions below 3(?) are not included

clearvars -except minTimepoints DataComb NumDataSets TransProbData TransProbDataN cutoffs dataset iThreeStates tv tvi comNeuronResponse1

%% Get mean transitions!
clearvars All
for cutoff = 1:(length(cutoffs)-1);
    for recNum =1: NumDataSets
        dummyCutOff(:,:,recNum) = TransProbData.(dataset{recNum})(:,:,cutoff);
    end
    All(:,:,cutoff) =  nanmeanD(dummyCutOff,3); %TransProbData.
end

for recNum = 1%:NumDataSets
    %TransProbData.(dataset{recNum})
    %xx(recNum) = TransProbData.(dataset{recNum})(2,1,:);
    xx = All(2,1,:);

    [~,~,dim] = size(xx);
    xxx= reshape(xx,1,dim);

    figure; plot(cutoffs(1:(end-1)),xxx,'r');
    
    %xx = TransProbData.(dataset{recNum})(2,3,:);
    xx = All(2,3,:);

    [~,~,dim] = size(xx);
    xxx= reshape(xx,1,dim);

    hold on; plot(cutoffs(1:(end-1)),xxx,'b')
end

clearvars -except minTimepoints DataComb NumDataSets TransProbData TransProbDataN cutoffs dataset iThreeStates tv tvi comNeuronResponse1

% Getting out data across recordings for Prism.
clearvars  FRprobi FRprob FQprobi FQprob
for recNum = 1:NumDataSets
    FRprobi = TransProbData.(dataset{recNum})(2,1,:);
    [~,~,dim] = size(FRprobi);
    FRprob(recNum,:) = reshape(FRprobi,1,dim);
    
    FQprobi = TransProbData.(dataset{recNum})(2,3,:);
    [~,~,dim] = size(FQprobi);
    FQprob(recNum,:) = reshape(FQprobi,1,dim);
end
clearvars  FRprobi FQprobi

%%
figure;
for ii =1:NumDataSets
    plot(cumsum((FRprob(ii,:))/nansum((FRprob(ii,:)))),'r')
    hold on
    plot(cumsum((FQprob(ii,:))/nansum((FQprob(ii,:)))),'b')
    hold on
end

figure;
    plot(cumsum(nanmean(FRprob)/nansum(nanmean(FRprob))),'r')
    hold on
    plot(cumsum(nanmean(FQprob)/nansum(nanmean(FQprob))),'b')
