%% awbNeuron_bin
%Have NeuronResponse loaded and have awbBinned3States just run.

clearvars -except transition binThreeStates

BinSize = 60; %seconds
condition = 'npr1Let';

% Measured period:
% Range = 13:24; %in bins for 30s bins
% Range = 16:24; %in bins for 30s bins
Range = 7:12; %in bins for 30s bins

%Range = 25:36; %in bins for 20s
%Range = 49:72; %in bins for 10s (37:72 is whole 21% period)

% xcentres = (0:0.05:1.8);
% xedges = -0.025:0.05:1.825;

xcentres = (-0.6:0.1:2.8);%AQR and URX
xedges = -0.65:0.1:2.85;

xcentres = (-0.6:0.1:1.9);%AQR and URX
xedges = -0.65:0.1:1.95;

% xcentres = (-0.5:0.8:15);%AQR and RIS ratio
% xedges = -0.9:0.8:15.4;

dataID= {'AQR','AUA','IL2','RMG','URX','RIS'};
loadData= [1,0,0,0,0,0];

%1 = use mean; 2 = ratio, other = sum
DataComb = 1; 


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

%input='deltaFOverF_mean20pc';%.pairsAveraged_mean20pc if awbNeuronFull_peakProcess ran prior (averages pairs)
inputType = 'pairsAveraged_mean20pc';
inputRIS = 'deltaFOverF_bc';

%Data
dataDir ='/Users/nichols/Documents/Imaging/O2neuron_responses';
dataToLoad = {'FullAQRresponses20160922','FullAUAresponses20160921',...
    'FullIL2responses20160921','FullRMGresponses20160922',...
    'FullURXresponses20160921','FullRISresponses20160923'};


indx = find(loadData);

NeuronData = [];
% Binning
FullRecordingLength = 1080; %(in seconds)
%Number of bins
BinNum = FullRecordingLength/BinSize;

% Correct to frames
BinSizeFrames = BinSize*5; %may be slightly off due to rounding. 5 is from the interpolated data frame rate.

clearvars binNeuronResponse NeuronResponse
[recNum,~] =  size(recordingsnpr1Let);
for ii = 1: sum(loadData);
    binNeuronResponse.(dataID{(indx(ii))})=nan(recNum,BinNum);
end

cd(dataDir)
for ii = 1:length(dataID)
    if loadData(ii) == 1;
        load(dataToLoad{ii});
        
        %% run to get .pairsAveraged_mean20pc
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
        clearvars startingNeuron cumnNeuronsPerRecording
        
        % Get the recording number position 
        ExIDpaired = unique(NeuronResponse.(condition).ExpID);
        ExIDpos = nan(length(ExIDpaired),1);
        for recNum = 1:length(recordingsnpr1Let);
            for IDnum = 1:length(ExIDpaired);
                if strfind(recordingsnpr1Let{recNum},ExIDpaired{IDnum});
                    ExIDpos(IDnum,1) = recNum;
                end
            end
        end
        
        %Bin data  
        TimePoint1 =1;
        for EpochNum = 1:BinNum;
            TimePoint2 = floor(EpochNum*BinSizeFrames);
            EpochRange = TimePoint1:TimePoint2;
            if ii == 6;
                input = inputRIS;
                binNeuronResponse.(dataID{ii})(ExIDpos,EpochNum) = (nanmean(NeuronResponse.(condition).(input)(EpochRange,:)));
            else
                input = inputType;
                binNeuronResponse.(dataID{ii})(ExIDpos,EpochNum) = (nanmean(NeuronResponse.(condition).(input)(:,EpochRange)'));

            end
            TimePoint1 = TimePoint2+1;
        end
        %clearvars ExIDpaired EpochNum TimePoint1 TimePoint2
        clearvars EpochNum EpochRange TimePoint1 TimePoint2 BinSizeFramesRounded NeuronResponse
    end
end


%% Histogram of the occurances

clearvars binNeuronResponseCombined3D binNeuronResponseCombined binnedOccurance binnedProbability
%create multidimensional array
for ii =1:sum(loadData);
    binNeuronResponseCombined3D(:,:,ii) = (binNeuronResponse.(dataID{indx(ii)}));
end

if DataComb == 1
    binNeuronResponseCombined = nanmeanD(binNeuronResponseCombined3D,3);
elseif DataComb == 2
    %binNeuronResponseCombined3D(:,:,2) = -(binNeuronResponseCombined3D(:,:,2));
    binNeuronResponseCombined = (binNeuronResponseCombined3D(:,:,1))./(binNeuronResponseCombined3D(:,:,2));
% elseif DataComb == 2
%     binNeuronResponseCombined3D(:,:,2) = -(binNeuronResponseCombined3D(:,:,2));
%     binNeuronResponseCombined = nansumD(binNeuronResponseCombined3D,3);
else
    binNeuronResponseCombined = nansumD(binNeuronResponseCombined3D,3);
end
%%
[r,c] = size(binNeuronResponseCombined(:,Range));
rBinNeuRes = reshape(binNeuronResponseCombined(:,Range),1,r*c);

transitions  = {'[1 2]','[1 0]','1','1 0','1 2','1','0 1','2 1'};
transType = {'FQ','FR','aFa','aFRa','aFQa','F','aRFa','aQFa'};

for tNum = 1:length(transType);
    binnedOccurance.(transType{tNum}) = [];
    binnedProbability.(transType{tNum}) = [];
end

for tNum = 1:length(transType);
    [r,c] = size(transition.(transType{tNum})(:,Range));
    currTransData = reshape(transition.(transType{tNum})(:,Range),1,r*c);
    currTransDataAllF = reshape(transition.(transType{3})(:,Range),1,r*c);
    
    for bin = 1:length(xcentres);
        NumSensoryInBin(1,bin) = sum((xedges(bin)< rBinNeuRes) & (rBinNeuRes < xedges(bin+1)));
        %occurance is the number of events
        binnedOccurance.(transType{tNum})(1,bin) = (sum(currTransData((xedges(bin)< rBinNeuRes) & (rBinNeuRes < xedges(bin+1)))));%
        %same as occurance but normalised to the number of all forward
        %events
        binnedProbability.(transType{tNum})(1,bin) = (sum(currTransData((xedges(bin)< rBinNeuRes) & (rBinNeuRes < xedges(bin+1))))...
            /sum(currTransDataAllF((xedges(bin)< rBinNeuRes) & (rBinNeuRes < xedges(bin+1)))));%/nNeuronResponseInBin;
    end
end

%% Plot only FQ and FR
figure;
subplot(2,2,1)
plot(binnedOccurance.FQ)
hold on
plot(binnedOccurance.FR,'r')
hold on
plot(binnedOccurance.aFa,'g')
title('non-normalised only FQ, FR');

subplot(2,2,2)
plot(binnedProbability.FQ)
hold on
plot(binnedProbability.FR,'r')
hold on
plot(binnedProbability.aFa,'g')
title('normalised only FQ, FR');

% any bin which has a FQ or FR event (e.g. includes RFQ and QFQ events)
subplot(2,2,3)
plot(binnedOccurance.aFQa)
hold on
plot(binnedOccurance.aFRa,'r')
hold on
plot(binnedOccurance.aFa,'g')
title('non-normalised *FQ*, *FR*');
% hold on
% plot(binnedOccurance.F,'k')

subplot(2,2,4)
plot(binnedProbability.aFQa)
hold on
plot(binnedProbability.aFRa,'r')
hold on
plot(binnedProbability.aFa,'g')
title('normalised *FQ*, *FR*');
% hold on
% plot(binnedProbability.F,'k')

if DataComb ==1
    typeA ='mean';
elseif DataComb ==2
    typeA = 'Neuron - RIS';
else
    typeA = 'sum';
end
text(-4.5, 2.54,[condition,' ',dataID{find(loadData)},' ',typeA,' ',BinSize],'FontSize',12)%,'HorizontalAlignment','center','VerticalAlignment', 'top','FontSize',12)

sum(NumSensoryInBin)
