%% MakeHeatMap
% Input
% quantDir ='/Users/nichols/Dropbox/Annika Lab/imaging data/npr1_2_Let/AN20140731d_ZIM575_Let_6m_O2_21_s_1TF_50um_1240_';
% cd(quantDir);

clear all

HeatMapScale = [-0.2 1.8];%

DiffTag = false; SmoothWin = 5;

Method = 'corr'; %'corr' or 'cov'

plotStimuliBar = 1;

plotBehaviouralStateBar = 1;


%%
MainDir = pwd;

wbload;
%load(strcat(pwd,'/Quant/QuiescentState.mat'));

[NumFrames,~] = size(wbstruct.deltaFOverF);

Cforward = [53 185 228]/255;
Creversal = [249 178 17]/255;
Cturn = [179 40 133]/255;
Cquiescence = [41 75 154]/255;

if plotBehaviouralStateBar
    ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
    ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
    ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;
    
    Reversal = ReversalRISE | ReversalHIGH;
    
    turnNeuron = {'SMDDL', 'SMDDR','SMDVL','SMDVR','RIVL','RIVR'}; %
    stateName = {'Forward','Quiescence  ','Reversal','Turn'};
    
    turn = NaN(length(wbstruct.simple.tv),1,length(turnNeuron));
    for ii = 1:length(turnNeuron)
        if sum(strcmp([wbstruct.simple.ID{:}], turnNeuron{ii})) == 1;
            turn(:,:,ii) = wbFourStateTraceAnalysis(wbstruct,'useSaved',turnNeuron{ii})==2;
        end
    end
    turnAll = nansumD(turn,3)';
    
    %with red: recessmap = [turquoise;blue;red;burntorange2;purple;grey];
    recessmap = [Cforward;Cquiescence;Creversal;Cturn];
    
    %colorm = double(2*ReversalRISE+QuiesceBout);
    colorm = double(2*ReversalRISE);
    colorm(find(ReversalHIGH),1) = 2; %with red =3
    colorm(find(ReversalFALL)) = 3; %with red =4
        
    figure2 = figure;
    subplot(10,10,1:9);
    imagesc(colorm')
    colormap(recessmap)
    set(gca, 'XTick', [],'YTick', []);
    
end

AllDeltaF = wbstruct.deltaFOverF_bc;
AllDeltaF(:,wbstruct.exclusionList) = [];
AllDeltaF=AllDeltaF';
NanList = sum(isnan(AllDeltaF),2);
AllDeltaF=AllDeltaF(NanList==0,:);

TimeVec = wbstruct.tv';

if DiffTag
    Dt = diff(TimeVec);
    AllDeltaF = moving_average(AllDeltaF,SmoothWin,2);
    AllDeltaF = diff(AllDeltaF,1,2)./(Dt*Dt');
    TimeVec = TimeVec(2:end);
end

[NumTracks, ~] = size(AllDeltaF);

if strcmp(Method,'corr')
    SortMatrix = corrcoef(AllDeltaF');
elseif strcmp(Method,'cov')
    SortMatrix = cov(AllDeltaF');
end


TreeFig = figure;
[H,T,outperm]=dendrogram(linkage(SortMatrix),NumTracks);
close;

AllDeltaFClustered = AllDeltaF(outperm,:);
NeuronIds = 1:NumTracks;

%% Making stimulus vector

if plotStimuliBar
    stimulusV = nan(1,NumFrames);
    %stimulusV(1,1:floor(300*wbstruct.fps)) = 0;
    stimulusV(1,1:floor(wbstruct.stimulus.switchtimes(1,1)*wbstruct.fps)) = 2;
    
    [~,numSwitches] = size(wbstruct.stimulus.switchtimes);
    
    alternateStim =1;
    
    for SwitchN = 1:(numSwitches);
        if SwitchN == numSwitches;
            stimulusV(1,floor(wbstruct.stimulus.switchtimes(1,SwitchN)*wbstruct.fps):end) = alternateStim;
        else
            stimulusV(1,floor(wbstruct.stimulus.switchtimes(1,SwitchN)*wbstruct.fps):...
                floor(wbstruct.stimulus.switchtimes(1,SwitchN+1)*wbstruct.fps)) = alternateStim;
        end
        
        if alternateStim ==1;
            alternateStim =2;
        elseif alternateStim ==2;
            alternateStim =1;
        end
    end
    
    colorm = stimulusV';
    recessmap = [Cquiescence;Creversal];
    
    figure2 = figure;
    subplot(10,10,1:9);
    imagesc(colorm')
    colormap(recessmap)
    set(gca, 'XTick', [],'YTick', []);
end

%%
figure1 = figure
% Heatmap Annika manuscript figure
colormap(jet)

subplot(10,1,2:10);
imagesc(TimeVec, 1:NumTracks, AllDeltaFClustered, HeatMapScale)
xLim = [0,TimeVec(end)];
set(gca, 'YTick', []);
caxis(HeatMapScale)

wbMpColorbarHandle =colorbar;
ylabel(wbMpColorbarHandle,'DF / F0','Fontsize', 12);

ylabel('Neuron #','Fontsize', 12);
xlabel('Time (s)','Fontsize', 12);
set(gca,'Fontsize',12)


%%
print (gcf,'-depsc', '-r200', sprintf(['Heatmap_',Method,'_',wbstruct.trialname,'.ai']));
close all
