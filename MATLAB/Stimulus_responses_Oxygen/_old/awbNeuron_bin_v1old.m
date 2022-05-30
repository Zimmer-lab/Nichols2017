%% awbNeuron_bin
%Have NeuronResponse loaded and have awbBinned3States just run.

BinSize = 30; %seconds
condition = 'npr1Let';

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
input = 'pairsAveraged_mean20pc';

%Data
dataDir ='/Users/nichols/Documents/Imaging/URX_responses';
dataToLoad = {'FullAQRresponses20160922','FullAUAresponses20160921',...
'FullIL2responses20160921','FullRMGresponses20160922','FullURXresponses20160921'};

dataID= {'AQR','AUA','IL2','RMG','URX'};

loadData= [1,1,0,0,0];

multipleData = @mean; %mean or sum

NeuronData = [];
% Binning
FullRecordingLength = 1080; %(in seconds)
%Number of bins
BinNum = FullRecordingLength/BinSize;

% Correct to frames
BinSizeFrames = BinSize*5; %may be slightly off due to rounding. 5 is from the interpolated data frame rate.

cd(dataDir)
for ii = 1:length(dataID)
    if loadData(ii) == 1;
        load(dataToLoad{ii};
        %run to get .pairsAveraged_mean20pc
        awbNeuronFull_peakProcess
        
        if isempty(NeuronData)
            NeuronData = NeuronResponse.(condition).(input); %orientation: num recording by timepoints
        else
            NeuronData = NeuronData NeuronResponse.(condition).(input); %orientation: num recording by timepoints
        end
    end
end

NeuronData = NeuronResponse.(condition).(input); %orientation: num recording by timepoints

[recNum,~] =  size(NeuronResponse.(condition).(input));
binNeuronResponse=nan(recNum,BinNum);

TimePoint1 =1;
for EpochNum = 1:BinNum;
    TimePoint2 = floor(EpochNum*BinSizeFrames);
    EpochRange = TimePoint1:TimePoint2;
    
    binNeuronResponse(:,EpochNum) = (nanmean(NeuronData(:,EpochRange)'));
    TimePoint1 = TimePoint2+1;
end
clearvars EpochNum EpochRange TimePoint1 TimePoint2 BinSizeFrames BinSizeFramesRounded

%%
%Range = 13:24; %in bins for 30s bins

Range = 13:24; %in bins

xcentres = (0:0.2:1.8);%AQR and URX

%% Histogram of the occurances
[r,c] = size(binNeuronResponse(:,Range));
rBinNeuRes = reshape(binNeuronResponse(:,Range),1,r*c);

transitions  = {'[1 2]','[1 0]','1','1 0','1 2'};
transType = {'FQ','FR','aFa','aFRa','aFQa'};

for tNum = 1:length(transType);
    binnedOccurance.(transType{tNum}) = [];
    binnedProbability.(transType{tNum}) = [];
end

xedges = -0.1:0.2:1.9;
for tNum = 1:length(transType);
    [r,c] = size(transition.(transType{tNum})(:,Range));
    currTransData = reshape(transition.(transType{tNum})(:,Range),1,r*c);
    currTransDataAllF = reshape(transition.(transType{3})(:,Range),1,r*c);
    
    for bin = 1:length(xcentres);
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
plot(binnedProbability.FQ)
hold on
plot(binnedProbability.FR,'r')
hold on
plot(binnedProbability.aFa,'g')

figure;
plot(binnedOccurance.FQ)
hold on
plot(binnedOccurance.FR,'r')
hold on
plot(binnedOccurance.aFa,'g')

%% any bin whihc has a FQ or FR event (e.g. includes RFQ and QFQ events)
figure;
plot(binnedProbability.aFQa)
hold on
plot(binnedProbability.aFRa,'r')
hold on
plot(binnedProbability.aFa,'g')

figure;
plot(binnedOccurance.aFQa)
hold on
plot(binnedOccurance.aFRa,'r')
hold on
plot(binnedOccurance.aFa,'g')