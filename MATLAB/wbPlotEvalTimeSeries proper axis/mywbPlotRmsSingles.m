MainDir = pwd;

FolderList = mywbGetDataFolders;

NumDataSets = length(FolderList);

ResampledFrames = 5400; %use for 5 fps (1080s total recording time)

BinSize = 100;
NumBins = ResampledFrames/BinSize;

tvRes = 0:0.2:1079.8; %resampled time vector

MNrmsBinTraces = zeros(NumDataSets,NumBins);

rmsBinTracesAcc = [];


load('Quant/wbstruct.mat','simple');

        NeuronATraces = simple.deltaFOverF;
        
        [NumFrames, NumTraces] = size(NeuronATraces);
        
        %interpolate timeseries
        
        ResdeltaFOverF = NaN(ResampledFrames,NumTraces);

        
        for ii = 1:NumTraces
            
            ResdeltaFOverF(:,ii) = interp1(simple.tv, NeuronATraces(:,ii),tvRes,'linear','extrap');
            
        end
        
        
        
        
        %caluculate RMS
        
        
        ReshResdeltaFOverF = reshape(ResdeltaFOverF,[BinSize,NumBins,NumTraces]);
        
        rmsBinTraces = rms(ReshResdeltaFOverF);
        
       
        rmsBinTraces = reshape(rmsBinTraces,[NumBins,NumTraces]);
       
        rmsBinTracesAcc = [rmsBinTracesAcc; rmsBinTraces'];
        
        %%%MNrmsBinTraces(i,:) = mean(rmsBinTraces,2);
        
    
    cd(MainDir)



%%

BinVec = 0:0.02:1.5;

N =[];

[NumAllNeurons, ~] = size(rmsBinTracesAcc);

for iii = 1:NumBins
    

    
N(iii,:) = hist(rmsBinTracesAcc(:,iii),BinVec); %/NumAllNeurons;


end

figure; imagesc(flipud(N'))

figure; plot(mean(rmsBinTracesAcc));

Bintv = 0:20:1060;

figure;
for iii=1:size(rmsBinTracesAcc,2)
    plot((Bintv),rmsBinTracesAcc);
end
    xlim([0 1060]);
    ylim([0 2.2]);
    set(gca,'FontSize',16)
    xlabel('Time (s)', 'FontSize',16);
    ylabel('RMS', 'FontSize',16);
    line('XData', [360 360], 'YData', [-1 2.5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    line('XData', [720 720], 'YData', [-1 2.5], 'color', [0.6 0.6 0.6], 'LineStyle', '-')
    set(gcf,'color','w');

% figure;
%             plot(mean(rmsBinTracesAcc), 'k');
%             hold on
%             plot(min(rmsBinTracesAcc), 'color', [0.4 0.4 0.4]);
%             hold on
%             plot(max(rmsBinTracesAcc), 'color', [0.4 0.4 0.4]);
