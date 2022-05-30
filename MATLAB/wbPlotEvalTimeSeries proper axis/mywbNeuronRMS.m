
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
       load('Quant/wbstruct.mat','exclusionList')

        NeuronATraces = simple.deltaFOverF_bc;
        
        %%%%If using _bc
        NeuronATraces(:,exclusionList)=[];
        %%%%%%
        
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
        
        
        figure; plot(ResdeltaFOverF);

        figure;
            plot(mean(ResdeltaFOverF'), 'k');
            hold on
            plot(min(ResdeltaFOverF'), 'color', [0.4 0.4 0.4]);
            hold on
            plot(max(ResdeltaFOverF'), 'color', [0.4 0.4 0.4]);
    
    cd(MainDir)
    
end



%%

BinVec = 0:0.1:1.5;

N =[];

[NumAllNeurons, ~] = size(rmsBinTracesAcc);

for iii = 1:NumBins
    

    
N(iii,:) = hist(rmsBinTracesAcc(:,iii),BinVec); %/NumAllNeurons;


end

figure; imagesc(flipud(N'))

figure; plot(mean(rmsBinTracesAcc));

figure; plot(rmsBinTracesAcc');

figure;
            plot(mean(rmsBinTracesAcc'), 'k');
            hold on
            plot(min(rmsBinTracesAcc'), 'color', [0.4 0.4 0.4]);
            hold on
            plot(max(rmsBinTracesAcc'), 'color', [0.4 0.4 0.4]);
