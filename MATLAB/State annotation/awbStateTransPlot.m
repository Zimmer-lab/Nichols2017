%% awbStateTransPlot %%%%%%%%%%%%%%%%%%%%%%%%
% IMPROVEMENTS: add grey instead of black for neurons not in recording.

% DATA transformation and plotting,
% got through each section as needed

suffixes = {'ClosestRise_Act2Qui','ClosestFall_Act2Qui','ClosestFallEnd_Act2Qui','ClosestRise_Qui2Act','ClosestFall_Qui2Act', 'ClosestFallEnd_Qui2Act'};
suffixes1 = {'ClosestRise_Act2Qui','ClosestFall_Act2Qui','ClosestRise_Qui2Act','ClosestFall_Qui2Act'};
suffixes2 = {'ClosestTransArise_Act2Qui','ClosestTransAfall_Act2Qui','ClosestTransArise_Qui2Act','ClosestTransAfall_Qui2Act'};
suffixes3 = {'ClosestTransArise_Qui2Act_evoked','ClosestTransArise_Qui2Act_Astart', 'ClosestTransArise_Qui2Act_Bstart'};


%% Add polarity to neuron names
inputData = Neurons;

NeuronsPolarity = inputData; 

for bbb = 1:length(inputData);
    % if you can find StateTransQATriggered.Neurons{bbb} in
    % options.NegPolarity add a "-" to end of name 
    matches =strfind(options.NegPolarity,inputData{bbb});
    Truematch = any(horzcat(matches{:}));
    if Truematch > 0;
        NeuronsPolarity(bbb,:) = strcat(NeuronsPolarity(bbb,:),'-');
    else
        NeuronsPolarity(bbb,:) = strcat(NeuronsPolarity(bbb,:),'+');
    end
end

clearvars matches Truematch bbb inputData

%% Remove neurons data when there is less than a N of 3
% for aa = 1:4;
%     NameO3 = suffixes{aa};
%     [idx3, idx4]= size(StateTransQATriggered.(NameO3));
%     for aaa= 1:idx3;
%         if sum(~isnan(StateTransQATriggered.(NameO3)(aaa,:)),2) < 3;
%         StateTransQATriggered.(NameO3)(aaa,1:idx4) =NaN;
%         end
%     end
% end
% clearvars aa idx3 idx4 


%% Seperate into RISE1 and RISE2
% takes out prior Q and evoked tarnsitions!
Neurons = StateTransTriggered.Neurons;

priorTrigLow = reshape(StateTransTriggered.priorTrigLow',1,[]);
priorTrigLow(isnan(priorTrigLow))=[];

TrigRiseStart = reshape(StateTransTriggered.TrigNeuRiseStartsSec',1,[]);
TrigRiseStart(isnan(TrigRiseStart))=[];

priorTrigQ = reshape(StateTransTriggered.priorTrigQ',1,[]);  
priorTrigQ(isnan(priorTrigQ))=[];

RISE1idx = priorTrigLow >= 3;
RISE2idx = priorTrigLow < 3;

notPiorQ = find(priorTrigQ >0);

% Find events in the 360-370 exclusion range (evoked transitions)
evokedTrans = find(TrigRiseStart > 360 & TrigRiseStart < 370);

% heatplot RISE1 RISE2
NeuronNum = length(Neurons);
NeuronsPlot = StateTransTriggered.Neurons; %StateTransQATriggered.Neurons, testN, NeuronsMedSorted.(NameO3)

RISE1idxnEv = RISE1idx;
RISE2idxnEv = RISE2idx;
RISE1idxnEv([evokedTrans,notPiorQ]) = 0;
RISE2idxnEv([evokedTrans,notPiorQ]) = 0;

%plot heatmaps
toPlot = StateTransTriggered.ClosestTransThres(:,RISE1idxnEv);
titlename = 'RISE1';
for ii = 1:2
    [~,numEvents]=size(toPlot);
    figure;  
    set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
    heatmap(toPlot, 1:numEvents, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
    title(titlename)

    toPlot = StateTransTriggered.ClosestTransThres(:,RISE2idxnEv);
    titlename = 'RISE2';
end

%get data
RISE1 = StateTransTriggered.ClosestTransThres(:,RISE1idxnEv);
RISE2 = StateTransTriggered.ClosestTransThres(:,RISE2idxnEv);
Aevoked = StateTransTriggered.ClosestTransThres(:,evokedTrans);

[~,numEvents]=size(Aevoked);
figure;  
set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
heatmap(Aevoked, 1:numEvents, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
title('A class evoked')


%%
clearvars titlename numEvents ii toPlot RISE1idxnEv RISE2idxnEv NeuronNum NeuronsPlot...
    RISE1idx RISE2idx priorTrigQ TrigRiseStart priorTrigLow

%% QA ONLY!: Keep PCA polarity consistent
% Replace rises with falls for negative polarity neurons for Arise
% and falls with rises for negative polarity neurons for Afall 

for aa = 1:4; %1:6???
    NameO3 = suffixes1{aa}; %original names
    NameO4 = suffixes2{aa}; %closest transition suffixes
    %for each trigger type i.e. Act2Qui and Qui2Act
    if mod(aa,2) ==1
        NameO5 = suffixes1{aa+1};
    else
        NameO5 = suffixes1{aa-1}; 
    end

    StateTransQATriggered.(NameO4) = StateTransQATriggered.(NameO3);
    
    for bbb = 1:length(Neurons);
        % if you can find StateTransQATriggered.Neurons{bbb} in
        % options.NegPolarity replace the ClosestRise with the ClosestFall for
        % that neuron. or opposite in the Afall categories.
        matches =strfind(options.NegPolarity,Neurons{bbb});
        Truematch = any(horzcat(matches{:}));
        if Truematch > 0;
        StateTransQATriggered.(NameO4)(bbb,:) = StateTransQATriggered.(NameO5)(bbb,:);
        end
    end
end
clearvars Truematch bbb matches NameO3 NameO4 NameO5 aa

%% QA ONLY!: Seperate QtoA as A or B start, and evoked.
[idx1, numEvents] = size(StateTransQATriggered.ClosestTransAfall_Qui2Act);

% get evoked transitions
TrigNeuTransStartsSec_Qui2Act = reshape(StateTransQATriggered.TrigNeuTransStartsSec_Qui2Act',1,[]);
TrigNeuTransStartsSec_Qui2Act(isnan(TrigNeuTransStartsSec_Qui2Act))=[];

% Find events in the 360-370 exclusion range (evoked transitions)
evokedTrans = find(TrigNeuTransStartsSec_Qui2Act > 360 & TrigNeuTransStartsSec_Qui2Act < 390);

if ~isempty(evokedTrans)
    StateTransQATriggered.ClosestTransArise_Qui2Act_evoked = StateTransQATriggered.ClosestTransArise_Qui2Act(:,evokedTrans);
else
    StateTransQATriggered.ClosestTransArise_Qui2Act_evoked = [];
end

%Find events in the 10% oxygen range
TenpcTransA = find(TrigNeuTransStartsSec_Qui2Act < 360);
TenpcTransB = find(TrigNeuTransStartsSec_Qui2Act > 720);
TenpcTrans = [TenpcTransA, TenpcTransB];
clearvars TenpcTransA TenpcTransB

%Find index of AVA rises
aNeurons = {'AVAL','AVAR'};
for aa = 1:2;
    index = strfind(Neurons, char(aNeurons(aa)));
    NeuronsIdx.a(aa) = find(not(cellfun('isempty', index)));
end
clearvars index

%Find index of VB02 rises
bNeurons = {'VB02'};
index = strfind(Neurons, char(bNeurons(1)));
NeuronsIdx.b(1) = find(not(cellfun('isempty', index)));
clearvars index

categories = {'_Astart','_Bstart'};
indexType = {'a', 'b'};

clearvars transIdx
for aa =1:2;
    transIdx.(indexType{aa}) = [];
end

for bbb = 1:2;
    NameO5 = strcat('ClosestTransArise_Qui2Act',categories{bbb});
    
    %Index nums of the choosen category
    indexCheck = NeuronsIdx.(indexType{bbb});
    
    %Use aRise data for A start and aFall data for B start
    NameO6 = 'ClosestTransArise_Qui2Act';
    if bbb == 2;
        NameO6 = 'ClosestTransAfall_Qui2Act';
    end
    
    for bbbb = 1:numEvents;
        %make index of responding events
        if min(isnan(StateTransQATriggered.(NameO6)(indexCheck,bbbb)))== 0;
            transIdx.(indexType{bbb}) = [transIdx.(indexType{bbb}), bbbb];
        end
    end
    
    % remove o2 response events from the a class events
    if bbb==1
        for bb = 1:length(evokedTrans);
            %Finding index of this event in Astart
            removalIdx = find(transIdx.(indexType{1})==evokedTrans(bb));
            %Removing this event number
            transIdx.(indexType{1})(removalIdx)=[];
        end
    end
    
    StateTransQATriggered.(NameO5)= StateTransQATriggered.(NameO6)(:,transIdx.(indexType{bbb}));
end

clearvars bb bbb bbbb aa NameO5 NameO6 removalIdx check1

%Get only sluggish reversals in 10% oxygen
TenpcAevents = [];
for ii = 1:length(transIdx.a)
    if sum(transIdx.a(ii) == TenpcTrans)
        TenpcAevents = [TenpcAevents,transIdx.a(ii)];
    end
end

StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_TenpcOx = StateTransQATriggered.ClosestTransArise_Qui2Act(:,TenpcAevents);


% Plot Evoked wake, spontaneous B class wake and spont. A class wake
figure;
NeuronNum = length(Neurons);
NeuronsPlot = Neurons; 

for aa =1:3;
    subplot(1,3,aa) 
    toPlot = StateTransQATriggered.(suffixes3{aa});

    heatmap(toPlot, 1:20, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
    caxis([-15 15]);
    title(suffixes3{aa});
    
    clearvars toPlot
end


%% QA ONLY!: Plot Act2Qui fall end

NeuronNum = length(Neurons);
NeuronsPlot = Neurons; 
for aa = 1:6;
    figure;
    toPlot = StateTransQATriggered.(suffixes{aa});
    set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
    heatmap(toPlot, 1:41, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
    title(suffixes{aa});
    [~,c] = size(toPlot);
    xlim([0.5, c+0.5]);
    clearvars toPlot
end


%% QA ONLY!!! Astart with all rises except RIS RMED and RMEV
AstartRises =StateTransQATriggered.ClosestRise_Qui2Act(:,transIdx.a);

%Find index of RIS and RMEV
rNeurons = {'RIS','RMED','RMEV'};
for aa = 1:length(rNeurons);
    index = strfind(Neurons, char(rNeurons(aa)));
    NeuronsIdx.r(aa) = find(not(cellfun('isempty', index)));
end
clearvars index

%Swap RIS and RMEV rises for falls
AstartRises((NeuronsIdx.r),:)=StateTransQATriggered.ClosestFall_Qui2Act(NeuronsIdx.r,transIdx.a);

figure;
toPlot = AstartRises;
set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
heatmap(toPlot, 1:41, Neurons, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
title('ClosestFall_Qui2Act with RIS, RMED and RMEV falls');
[~,c] = size(toPlot);
xlim([0.5, c+0.5]);
clearvars toPlot


%% QA ONLY!!! Bstart with all rises except RIS and RMEV
BstartRise =StateTransQATriggered.ClosestTransArise_Qui2Act_Bstart;

%Swap RIS and RMEV rises for falls
BstartRise((NeuronsIdx.r),:)=StateTransQATriggered.ClosestFall_Qui2Act(NeuronsIdx.r,transIdx.b);

%Take away the two 360-720 QtoA transitions
BstartRise= BstartRise(:,[2:12,14:16]);


%% QA ONLY!!! Sort neurons by median

for aa = 1:4;
    NameO3 = suffixes2{aa}; %CAUTION 2
    medianTrans = nanmedian(StateTransQATriggered.(NameO3)')'; %calculates average

    %sort by active value in descendning order, reorders data.
    [~, idx] =sort(medianTrans,'descend');
    AxisSwap = medianTrans';

    Neurons2 = Neurons'; %StateTransQATriggered.Neurons
    NeuronsMedSorted.(NameO3) = Neurons2(:,idx);

    IndivUnsortedMed = StateTransQATriggered.(NameO3)'; %StateTransTriggered.ClosestTrans';
    IndivSortedMed1 = IndivUnsortedMed(:,idx);
    IndivSortedMed.(NameO3)=IndivSortedMed1';
    clearvars AxisSwap medianTrans Neurons2 IndivUnsortedMed IndivSortedMed1
end

%% Sort neurons by median - 1 dataset input

InputData = AriseTen;
Neurons2 = NeuronsPlot'; %StateTransQATriggered.Neurons'

medianTrans = nanmedian(InputData')'; %calculates median

%sort by active value in descendning order, reorders data.
[~, idx] =sort(medianTrans,'descend');
%AxisSwap = medianTrans';

NeuronIDMedSorted = Neurons2(:,idx);

IndivUnsortedMed = InputData'; %StateTransTriggered.ClosestTrans';
IndivSortedMed1 = IndivUnsortedMed(:,idx);
NeuronMedSorted=IndivSortedMed1';
clearvars AxisSwap medianTrans Neurons2 IndivUnsortedMed IndivSortedMed1

toPlot = NeuronMedSorted;
NeuronsPlot =NeuronIDMedSorted;

toPlot = flipud(toPlot);
NeuronsPlot = fliplr(NeuronsPlot);

%%  heatplot sorted

NeuronNum = length(Neurons);
NeuronsPlot = StateTransQATriggered.Neurons; %StateTransQATriggered.Neurons, testN, NeuronsMedSorted.(NameO3)

for aa = 1:6; %%%CAUTION
    %NameO3 = suffixes2{aa};
    NameO4 = suffixes{aa};
    %NameO5 = suffixes3{aa};
    
    %toPlot = IndivSortedMed.(NameO3);
    %toPlot = IndivSortedMedColVB3.(NameO5);
    toPlot = StateTransQATriggered.ClosestRise_Act2Qui;
    
    figure;  
    set(0,'DefaultFigureColormap',flipud(cbrewer('div','RdBu',64)));
    heatmap(toPlot, 1:37, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
end

%% Sort columns by VB2
neuronInput = Neurons; % NeuronsMedSorted
dataInput = StateTransQATriggered; %if IndivSortedMed see below
suffixInput = suffixes3;

for aa = 1:4;
    NameO3 = suffixInput{aa};

    %Find VB2 index number
    index = strfind(neuronInput, 'VB02'); %will need to add ".(NameO3)" for IndivSortedMed 
    VB2idx = find(not(cellfun('isempty', index)));

    VB2 = dataInput.(NameO3)(VB2idx,1:end);

    %sort by active value in decendning order, reorders data.
    [~, idx5] =sort(VB2,'descend');

    IndivSortedVB2a = dataInput.(NameO3)(:,idx5);
    IndivSortedMedColVB2.(NameO3)=IndivSortedVB2a;
    clearvars AxisSwap medianTrans Neurons2 IndivUnsortedVB2a IndivUnsortedVB2a index
    
    %%for second neuron
        %Find VB2 index number
        index = strfind(neuronInput, 'AIBL'); %will need to add ".(NameO3)" for IndivSortedMed
        VB2idx = find(not(cellfun('isempty', index)));

        VB2 = IndivSortedMedColVB2.(NameO3)(VB2idx,1:end);

        %sort by active value in decendning order, reorders data.
        [~, idx5] =sort(VB2,'descend');

        IndivSortedVB2a = IndivSortedMedColVB2.(NameO3)(:,idx5);
        IndivSortedMedColVB3.(NameO3)=IndivSortedVB2a;
        clearvars AxisSwap medianTrans Neurons2 IndivUnsortedVB2a IndivUnsortedVB2a index
end
clearvars neuronInput suffixInput


%% Sort neurons by neuron
SortNeuron ='URXR+';
InputData = AriseTwentOneAQRURXL; %StateTransTriggered.ClosestTransThres;
NeuronInput = AriseNeu;

%find SortNeuron index number
index = find(ismember(NeuronInput, SortNeuron));

%sort transitions by neuron in descending order, reorders data.
[~, idx] =sort(InputData(index,:),'descend');
 
SortedData=InputData(:,idx);

toPlot = SortedData(1:36,:);
NeuronsPlot = NeuronInput;
NeuronNum = length(NeuronsPlot);

figure;  
set(0,'DefaultFigureColormap',cbrewer('div','RdBu',64));
heatmap(toPlot, 1:120, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
colorbar('northoutside')
title(strcat('Sorted by ', SortNeuron));


%% Add a '+' to each name.
for dd = 1:length(NeuronsPlot);
    NeuronsPlot(dd,1) = strcat(NeuronsPlot(dd,1),'+');
end

%% Correct for Trigger neuron
InputData = StateTransQATriggered.ClosestTransArise_Qui2Act_evoked;
%InputData = StateTransQATriggered.ClosestTransArise_Qui2Act_Astart;
InputData =StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_TenpcOx;
%InputData =AstartRises;
[~,numEvents]= size(InputData);

StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_TenpcOx_AVAcorr = InputData;
%StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr_AllRISE_butRISRME=InputData;
%StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_AVAcorr =InputData;
%StateTransQATriggered.ClosestTransArise_Qui2Act_evoked_AVAcorr = InputData;
for aaa = 1:numEvents;
    if InputData(1,aaa) ~=0;
        StateTransQATriggered.ClosestTransArise_Qui2Act_Astart_TenpcOx_AVAcorr(1:42,aaa)=InputData(1:42,aaa)-InputData(1,aaa);
    end
end

%% Saving StateTransQA
dateRun = datestr(now);
MainDir = pwd;
ResultsStructFilename = 'StateTrans_QAtriggered_0sTo1080s_15sThres_QFon20_';

save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'StateTransQATriggered', 'options','dateRun','Neurons'); 

%% Saving StateTrans
dateRun = datestr(now);
MainDir = pwd;
%ResultsStructFilename = 'StateTrans_AVArisetriggered_0sTo1080s_15sThres_QFoff_';
save (([strcat(MainDir,'/',ResultsStructFilename) '.mat']), 'StateTransTriggered','dateRun', 'options','Neurons','RISE1','RISE2');
