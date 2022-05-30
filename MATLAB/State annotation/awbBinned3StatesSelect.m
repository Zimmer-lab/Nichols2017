%%
% This script is similair to awbBinned3States with awbNeuron_Bin but
% instead finds a transition and finds neuron levels in a selected region
% prior to the transition.

% run this section then go below to change parameters.

% This script finds the state transitions for the 3 states
% (reversal, forward and quiescent phases)
clear all
cd('/Users/nichols/Dropbox/_Analysing sets/npr1_2_Let')

awb3States

%% Comparing transitions to prior neuron activity.
% For every transition type X which occurs within Range get the
% preceding activty of neurons A (BC)

%seconds size of bin prior to transition where neuron activty will be measured
selectSize = 10; 
condition = 'npr1Let';

Range = 10.2:360; %in seconds 480:720
xedges = -0.6:0.1:6.8;

% Pick neurons
dataID= {'AQR','AUA','IL2','RMG','URX','RIS'};
loadData= [0,0,0,0,0,1]; % 0 = don't include, 1= include

% 1 mean; 2 /RIS; 3 multiple neurons /RIS; 4 = sum
DataComb = 1;


%should change so this is automatically generated as at the moment it is
%only set up for npr-1 let.
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
RangeFrames = Range*5; %may be slightly off due to rounding. 5 is from the interpolated data frame rate.
selectSizeFrames  = round(selectSize*5);
[recNum,~] =  size(recordingsnpr1Let);
clearvars selectNeuronResponse 
RevCopyNR = NaN(NumDataSets,5400,sum(loadData));
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
        
        for tTNum = 1:length(transType)
            selectNeuronResponse.(transType{tTNum}).(dataID{ii}) = NaN(NumDataSets,100);
        end
        
        for recNum = 1:NumDataSets
            if ~isempty(find(ExIDpos == recNum))
                
                for tTNum = 1:3%length(transType);
                    for tNum = 1:sum(~cellfun(@isempty,transitionData.(transType{tTNum})(recNum,:)));
                        
                        %only look at transitions in correct range
                        if  (min(RangeFrames) <= transitionData.(transType{tTNum}){recNum,tNum}) && ...
                                (max(RangeFrames) >= transitionData.(transType{tTNum}){recNum,tNum})
                            selectRange = (transitionData.(transType{tTNum}){recNum,tNum}-selectSizeFrames):(transitionData.(transType{tTNum}){recNum,tNum});
                            
                            if ii == 6;
                                input = inputRIS;
                                selectNeuronResponse.(transType{tTNum}).(dataID{ii})(recNum,tNum) = (nanmean(NeuronResponse.(condition).(input)(selectRange,find(ExIDpos == recNum))));

                            else
                                input = inputType;
                                selectNeuronResponse.(transType{tTNum}).(dataID{ii})(recNum,tNum) = (nanmean(NeuronResponse.(condition).(input)(find(ExIDpos == recNum),selectRange)'));
                            end
                        end
                    end
                end
                if ii == 6
                    input = inputRIS;
                    RevCopyNR(recNum,:,dim+1) = NeuronResponse.(condition).(input)(:,find(ExIDpos == recNum));
                else
                    input = inputType;
                    RevCopyNR(recNum,:,dim+1) = NeuronResponse.(condition).(input)(find(ExIDpos == recNum),:)';
                end
            end
        end
        % if using multiple neurons this adds then to the next dimension of
        % RevCopyNR
        dim = dim+1;
    end
end

% Histogram 
clearvars selectNeuronResponse3D NeuronResponseCombined 
%create multidimensional array
for tTNum = 1:length(transType);
    for ii =1:sum(loadData);
        selectNeuronResponse3D.(transType{tTNum})(:,:,ii) = (selectNeuronResponse.(transType{tTNum}).(dataID{indx(ii)}));
    end
end

for tTNum = 1:length(transType);
    if DataComb == 1
        NeuronResponseCombined.(transType{tTNum}) = nanmeanD(selectNeuronResponse3D.(transType{tTNum}),3);
    elseif DataComb == 3
        [~,~,D] = size(selectNeuronResponse3D.(transType{tTNum}));
        selectNeuronResponse3Db.(transType{tTNum}) = nanmeanD(selectNeuronResponse3D.(transType{tTNum})(:,:,1:(D-1)),3);
        NeuronResponseCombined.(transType{tTNum}) = (selectNeuronResponse3Db.(transType{tTNum})(:,:,1))./(selectNeuronResponse3D.(transType{tTNum})(:,:,2));

    elseif DataComb == 2
        NeuronResponseCombined.(transType{tTNum}) = (selectNeuronResponse3D.(transType{tTNum})(:,:,1))./(selectNeuronResponse3D.(transType{tTNum})(:,:,2));
        
    else
        NeuronResponseCombined.(transType{tTNum}) = nansumD(selectNeuronResponse3D.(transType{tTNum}),3);
    end
end
    
figure
color = 'b';

for tTNum = 1:2%length(transType);
    if tTNum == 3;
        color = 'k';
    end
    histNeu.(transType{tTNum}) = histc(NeuronResponseCombined.(transType{tTNum})(find(isfinite(NeuronResponseCombined.(transType{tTNum})))),xedges);
    %histNeu.(transType{tTNum}) = histc(selectNeuronResponse.(transType{tTNum}).(dataID{ii})(find(selectNeuronResponse.(transType{tTNum}).(dataID{ii}))),xedges);
    plot(xedges,histNeu.(transType{tTNum}),color)
    hold on
    color = 'r';
    ylabel('counts')
    %ylim([0,10]);
end

if DataComb ==1
    typeA ='mean';
elseif DataComb ==2
    typeA = 'Neuron - RIS';
elseif DataComb ==3
    typeA = 'Neurons - RIS';
else
    typeA = 'sum';
end
title([condition,' ',dataID{find(loadData)},' ',typeA,' ',mat2str(selectSize),'sec bin'])

%% Binned event counts
x1edges = 0:300:5400;
test = reshape(transitionData.FQ,11*8,1);
test2 = cell2mat(test);
hist1 = histc(test2,x1edges);

test = reshape(transitionData.FR,11*14,1);
test2 = cell2mat(test);
hist2 = histc(test2,x1edges);

figure; 
plot(x1edges,hist1)
hold on
plot(x1edges,hist2,'r')


%% for working out reversal bins vs neuron activity bins
bRange = 2400:3599; %to max -1 e.g. 5399 not 5400. 300=1m 2400:3599 is 8m to 12m
histBinLength = length(bRange);
binsize =300; %frames
x1edges = min(bRange):binsize:max(bRange);
binNum = (histBinLength)/binsize;

reversalEvents = [transitionData.FR,transitionData.QR];


% Get binnned neuron response data
[~,~,D]= size(RevCopyNR);
if DataComb == 1
    NeuronData = nanmeanD(RevCopyNR,3);
elseif DataComb == 3
    transientNeuMean = nanmeanD(RevCopyNR(:,:,1:(D-1)),3);
    NeuronData = (transientNeuMean)./(RevCopyNR(:,:,D));
elseif DataComb == 2
        NeuronData = (RevCopyNR(:,:,1))./(RevCopyNR(:,:,2));
else 
    NeuronData = RevCopyNR;
end


clearvars BinnedRevsersalData BinnedNeuronData

for ii = 1:NumDataSets
    dummyVector = zeros(1,5400);
    dummyVector(1,cell2mat(reversalEvents(ii,:)))=1;
    BinnedRevsersalData(ii,:) = sum(reshape(dummyVector(1,bRange),binsize,binNum));
    
    BinnedNeuronData(ii,:) = nanmean(reshape(NeuronData(ii,bRange),binsize,binNum));
end

% Make single vector
sBinnedNeuronData = reshape(BinnedNeuronData,binNum*NumDataSets,1);
sBinnedRevsersalData = reshape(BinnedRevsersalData,binNum*NumDataSets,1);
%test2 = ([transitionData.FR,transitionData.QR]);

figure; scatter(sBinnedNeuronData,sBinnedRevsersalData)
