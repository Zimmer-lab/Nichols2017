%% awbNeuron_bin
%Have NeuronResponse loaded

clearvars -except NeuronResponse

%seconds
BinSize = 180; 
condition = 'N2Let';

inputType = 'pairsAveraged_mean20pc';

%%
NeuronData = [];
% Binning
FullRecordingLength = 1080; %(in seconds)
%Number of bins
BinNum = FullRecordingLength/BinSize;

% Correct to frames
BinSizeFrames = BinSize*5; %may be slightly off due to rounding. 5 is from the interpolated data frame rate.

[nRecordings,~] =  size(NeuronResponse.(condition).(inputType));

binNeuronResponse=nan(nRecordings,BinNum);

%% run to get .pairsAveraged_mean20pc
startingNeuron = 1;
for recNum = 1:nRecordings;
    if length(startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(recNum))>1
        NeuronResponse.(condition).pairsAveraged_mean20pc(recNum,:) = mean((NeuronResponse.(condition).deltaFOverF_mean20pc(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(recNum))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(recNum)+1;
    else
        NeuronResponse.(condition).pairsAveraged_mean20pc(recNum,:) = NeuronResponse.(condition).deltaFOverF_mean20pc(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(recNum));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
        startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(recNum)+1;
    end
end
clearvars startingNeuron cumnNeuronsPerRecording


%Bin data
TimePoint1 =1;
for EpochNum = 1:BinNum;
    TimePoint2 = floor(EpochNum*BinSizeFrames);
    EpochRange = TimePoint1:TimePoint2;
    
    binNeuronResponse(:,EpochNum) = (nanmean(NeuronResponse.(condition).(inputType)(:,EpochRange)'));
    
    TimePoint1 = TimePoint2+1;
end
clearvars EpochNum recNum EpochRange TimePoint1 TimePoint2 BinSizeFramesRounded
