% Remove transitions that are more than X seconds away from the trigger neuron
% transition.
[idx3, idx4]= size(StateTransTriggered.ClosestRise);
ClosestRiseThres= StateTransTriggered.ClosestRise;
aaa=1;
for aaa= 1:idx3;
    indices = find((abs(StateTransTriggered.ClosestRise))>options.ThresholdDistance);
    ClosestRiseThres(indices) = NaN;
end
clearvars indices aaa    


NeuronNum = length(StateTransTriggered.Neurons);

    NeuronsPlot = StateTransTriggered.Neurons; %StateTransQATriggered.Neurons, testN, NeuronsMedSorted.(NameO3)
    toPlot = ClosestRiseThres; %StateTransTriggered.ClosestTransThres;
    %toPlot = test;
    
    figure;  
    set(0,'DefaultFigureColormap',cbrewer('div','RdBu',64));
    heatmap(toPlot, 1:37, NeuronsPlot, [], 'NaNColor', [0 0 0], 'ShowAllTicks', true, 'MinColorValue', -15, 'MaxColorValue', 15); %'TickAngle', 45,'TickFontSize', 6
    caxis([-15 15]);
    set(gca,'YTick',1:NeuronNum,'YTickLabel',NeuronsPlot);
    where = pwd;
    [~,remain] = strtok(where);
    title(remain)