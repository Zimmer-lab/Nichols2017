%% vectorDistPermute
%input the two vectors you want to compare, where rows=neurons and
%columns=number of events.

clearvars -except RISE1 RISE2 StateTransQATriggered StateTransTriggered vecInputs count ii iii...
    vec1 vec2 vec3 vec4 vec5 vec6 vec7 Compared Neurons vector1 vector2 nAbove NeuronsResamAll v1EventsAll v2EventsAll...
    N2StateTransQATriggered N2RISE1 N2RISE2 iiii

% %AVA align
% vector1 = TrigCorrected;
% vector2 = TrigCorrecteda;

%vector1 = RISE2;
% vector1 = RISE1;
% vector2 = StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr;%N2StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr;

NeuronsResam = Neurons;

resampleN = 1000000;


%specify lowest N
minEventN = 3;

%disclude these neurons:
NeuronsExclude = {'AQR','URXL','URXR','AUAL','AUAR','IL2DL','IL2DR','AVBL','AVBR','RIBL','RIBR','SIBDL','SIBDR','SIBVL','SIBVR','RIVL','RIVR','SMDDL','SMDDR',...
    'SMDVL','SMDVR','VB02'};

%'RMED','RMEV','RMEL','RMER'

%% disclude neurons:
for neuN = 1:length(NeuronsExclude)
    IndexC = (strfind(NeuronsResam,NeuronsExclude{neuN}));
    if ~isempty(find(not(cellfun('isempty', IndexC))))
        Index(neuN) = find(not(cellfun('isempty', IndexC)));
    end
end
Index(Index==0)=[];

vector1(Index,:)=[];
vector2(Index,:)=[];
NeuronsResam(Index) = [];

%%
%only take neurons with at least an N > minEventN in both conditions
NperNeuV1 = sum(~isnan(vector1),2);
NperNeuV2 = sum(~isnan(vector2),2);
NeuInc = NperNeuV1 > minEventN & NperNeuV2 > minEventN;

% matrices to resample
vector1 = vector1(NeuInc,:);
vector2 = vector2(NeuInc,:);
NeuronsResam = NeuronsResam(NeuInc);

clearvars NperNeuV1 NperNeuV2

[~,v1Events] = size(vector1);
[~,v2Events] = size(vector2);

vector3 = [vector1,vector2];

%resample treats NaNs as missing values so they're given a dummy value of
%20.
vector3(isnan(vector3)) = 20;
[NeuronNum,totalNEvents] = size(vector3);

%% calculate true distance
medians = nanmedian(vector1,2);
medians(:,2) = nanmedian(vector2,2);

vectorDistsTrue = pdist(medians');

% Plot distances
figure;  
plot(1:length(NeuronsResam),medians(:,1))
hold on
plot(1:length(NeuronsResam),medians(:,2),'r')
set(gca,'XTick',1:NeuronNum,'XTickLabel',NeuronsResam);

clearvars medians
%% calculate resampled distances

inputs = {'InputV1', 'InputV2'};

for repN = 1:resampleN;
    for ii = 1:2; %for each input vetcor
        for neuNum = 1:length(NeuronsResam); % for each neuron
            
            %Define number of events to randomly draw
            if ii == 1
                draws = v1Events;
            else
                draws = v2Events;
            end
                        
            %Redraw nReps number of times and find the median. This will be a repetition of the
            %median of one event. Repeat nReps, and do it for each
            %experiment for this input vector.
            
            %random sample of with replacement
            resamples.(inputs{ii})(neuNum,:) = randsample(vector3(neuNum,:),draws,true);
            
        end
        % calculate median
        resamples.(inputs{ii})(resamples.(inputs{ii})==20)=NaN;
        medians(:,ii) = nanmedian(resamples.(inputs{ii}),2);
    end
    vectorDists(repN,1) = pdist(medians');
    
%     figure; plot(nanmedian(resamples.InputV2,2))
%     hold on; plot(nanmedian(resamples.InputV1,2),'r')
%     title(mat2str(vectorDists(repN,1)))
end

%% Caluclate pvalue Accounts for possibility of value being at either end.
if vectorDistsTrue < mean(vectorDists)
    pValue = sum(vectorDists <= vectorDistsTrue)/length(vectorDists);
    display(pValue);
else
    pValue = sum(vectorDists >= vectorDistsTrue)/length(vectorDists);
    display(pValue);
end

[histD,xValues] = hist(vectorDists,100);
histD = histD/length(vectorDists);

%% Plot figure
figure; bar(xValues,histD);
hold on
plot([vectorDistsTrue vectorDistsTrue],ylim,'r')
line1 = ['Resampling Results, p-Value:', mat2str(pValue)];
line2 = ['Num events, v1:', mat2str(v1Events), ' v2:',mat2str(v2Events)];
title({line1;line2});
xlabel('pdist');
ylabel('Fraction');
% Note P value may be close to zero or 1.

sum(vectorDists >= vectorDistsTrue)
NeuronsResam = NeuronsResam';
