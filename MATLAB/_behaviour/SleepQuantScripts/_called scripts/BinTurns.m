function [BinnedTurns] = BinTurns(BinningFactor, TurningMatrix)
%BinTurns returns the binned truning matrix of data input
%   Detailed explanation goes here

[NumTracks, NumInputBins] = size(TurningMatrix);

NumBins = floor(NumInputBins/BinningFactor);

BinnedTurns = NaN(NumTracks,NumBins);

for i = 1:NumTracks
    
    BinnedTurns(i,:) = nansum(reshape(TurningMatrix(i,1:BinningFactor*NumBins),BinningFactor,NumBins));
    
    
%     for ii = 1:NumBins
%     
%     
% 
%         BinnedTurns(i,ii) = nansum(TurningMatrix(i,ii*BinningFactor-BinningFactor+1:ii*BinningFactor));
% 
% 
%     end
    
end




end

