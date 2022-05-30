%% Post processing of NeuronResponse
% adds:
% deltaFOverF_mean20pc_peak
% pairsAveraged_peak
% pairsAveraged_mean20pc


%sustained = last 5mins of stim
% PeakStart = 420; % PeakEnd = 720;

%AQR npr1 Let and Pre
%PeakRange = 367:377;

%AQR N2 Let
PeakRange = 374:384;

%AQR N2 PreLet
% PeakStart = 378; % PeakEnd = 388;

%AQR sustained
% 420:720


%AQR N2 Let (old: used for Recess 2015)
% PeakStart = 375; % PeakEnd = 385;

%URX
% PeakStart = 366; % PeakEnd = 375;


%PeakRange = 366:375;
%PeakRange = 360:480;
%PeakRange = 420:720;

input={'N2Let','N2PreLet','npr1Let','npr1PreLet'};%
input={'N2Let'};%


for conNum = 1:length(input);
    condition = input{conNum};
    NeuronResponse.(condition).deltaFOverF_mean20pc_peak = mean(NeuronResponse.(condition).deltaFOverF_mean20pc(PeakRange*5,:));
    
    [nRecordings,~] = size(NeuronResponse.(condition).cumnNeuronsPerRecording);
    startingNeuron = 1;
    NeuronResponse.(condition).pairsAveraged_peak = [];
    for jj = 1:nRecordings;
        if length(startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))>1
            NeuronResponse.(condition).pairsAveraged_peak(jj,:) = mean((NeuronResponse.(condition).deltaFOverF_mean20pc_peak(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
            NeuronResponse.(condition).pairsAveraged_mean20pc(jj,:) = mean((NeuronResponse.(condition).deltaFOverF_mean20pc(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj))'));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');

            startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(jj)+1;
        else
            NeuronResponse.(condition).pairsAveraged_peak(jj,:) = NeuronResponse.(condition).deltaFOverF_mean20pc_peak(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj));
            NeuronResponse.(condition).pairsAveraged_mean20pc(jj,:) = NeuronResponse.(condition).deltaFOverF_mean20pc(:,startingNeuron:NeuronResponse.(condition).cumnNeuronsPerRecording(jj));%Get all the data points:nanmean((CollectedTrksInfo.SleepTrcks(startingTrack:cumNTracksPerExp(jj),:))');
            startingNeuron = NeuronResponse.(condition).cumnNeuronsPerRecording(jj)+1;
        end
    end
    clear startingNeuron cumnNeuronsPerRecording
    
    
end

%% Figure

condition =  'npr1Let';
data = NeuronResponse.(condition).deltaFOverF_bc;

figure
x0=10;
y0=10;
width=1400;
height=2000;
set(gcf,'units','points','position',[x0,y0,width,height])

[~,r] =size(data);
for ii = 1:r;
    subplot(ceil(r/2),2,ii)
    plot(data(:,ii))
end
text(0.5, 1,condition,'HorizontalAlignment','center','VerticalAlignment', 'top','FontSize',30)
