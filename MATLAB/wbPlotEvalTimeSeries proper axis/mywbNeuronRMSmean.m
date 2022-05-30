
MainDir = pwd;

FolderList = mywbGetDataFolders;

NumDataSets = length(FolderList);

ResampledFrames = 5400; %use for 5 fps (1080s total recording time)

BinSize = 100;
NumBins = ResampledFrames/BinSize;

tvRes = 0:0.2:1079.8; %resampled time vector

MNrmsBinTraces = zeros(NumDataSets,NumBins);

rmsBinTracesAcc = [];

for i = 1:NumDataSets
    
    cd(FolderList{i})
    
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
        
        MNrmsBinTraces(i,:) = mean(rmsBinTraces,2);
        
    
    cd(MainDir)
    
end


%%

%BinVec = 0001:0.02:1;

BinVec = logspace(0,1,15); %log

BinVec(:)=BinVec(:)-1

N =[];

[NumAllNeurons, ~] = size(rmsBinTracesAcc);

for iii = 1:NumBins
    

    
N(iii,:) = hist(rmsBinTracesAcc(:,iii),BinVec); %/NumAllNeurons;


end

figure; imagesc(flipud(N'))

figure; plot(mean(rmsBinTracesAcc));

figure; plot(rmsBinTracesAcc');

figure;
            plot(mean(rmsBinTracesAcc), 'k');
            hold on
            plot(min(rmsBinTracesAcc), 'color', [0.4 0.4 0.4]);
            hold on
            plot(max(rmsBinTracesAcc), 'color', [0.4 0.4 0.4]);
