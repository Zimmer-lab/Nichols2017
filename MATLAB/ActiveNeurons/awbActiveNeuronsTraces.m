% Script for looking into the awbActiveNeurons to see what 
% traces are being called as active in which Q/A bins
% run in one recording folder. This script doesn't save anything.

clear all

%Bin size in seconds
options.BinSize = 60; %make 1080 evenly divisable by this value, i.e. 20, 30, 45, 54, 60, 72

%Thresholds:
options.DerivThreshold = 0.007;

options.FThreshold = 0.5;

%%
awbActiveNeurons; %runs for individual datasets.
awbActiveNeuronsQA;

totalRecordingLength = 1080;
BinNum = totalRecordingLength/options.BinSize;

checkActive = ~isnan(RecordingFractionActiveActBins);
[~, activeBinIndx] = find(checkActive);
checkQuiesce = ~isnan(RecordingFractionActiveQuiBins);
[~, quiesceBinIndx] = find(checkQuiesce);
clearvars checkActive checkQuiesce

qaState = zeros(1,BinNum);
qaState(1,activeBinIndx) = 1; %1 = active bin
qaState(1,quiesceBinIndx) = 2; %1 = active bin
yellow = [255 240 102]/255;
BinSize = (1080/BinNum)*wbstruct.fps;

for traceStartNum = 1:10:120; %doesn't deal elegantly with total number of neurons

    figure; 
    subplot(11,1,1);
    imagesc(qaState)
    set(gca,'xtick',[])
    set(gca,'xticklabel',[])

    for plotNum = 2:11
        trace = wbstruct.simple.deltaFOverF_bc(:,traceStartNum);
        traceActivity = SingleActiveNeurons(:, traceStartNum)';

        subplot(11,1,plotNum);
        plot(trace)
        y1=-0.399;
        h1=6.38;
        for n1= 1:BinNum;
            if traceActivity(1,n1) ==1;
                x1=(n1*(BinSize))-BinSize;
                w1=(BinSize);
                rectangle('Position',[x1,y1,w1,h1],'FaceColor', yellow,'EdgeColor', yellow);
            end
        end
        hold on;
        plot(trace)
        axis tight
        ylabel(wbstruct.simple.ID{1,traceStartNum})

        traceStartNum = traceStartNum+1;
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
        %labeling neurons
        %set(gca,'YLabel',wbstruct.simple.ID{1,traceStartNum+(plotNum-1)})
        
        for n2 = 1:BinNum;
            linePlace = n2*BinSize;
            line('XData', [linePlace linePlace], 'YData', [-1 5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
        end
    end
end

clearvars h1 idx2 n1 n2 trace traceActivity plotNum linePlace x1 y1 yellow w1 traceStartNum totalRecordingLength quiesceBinIdx qaState activeBinIndx BinSize BinNum
