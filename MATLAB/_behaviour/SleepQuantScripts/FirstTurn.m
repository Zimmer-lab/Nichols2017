% First turn response

FirstStimulus = [1560 360];%6min start and width of first stimulus in seconds

StimStartBin = FirstStimulus(1)/SBinWinSec;

firstRepsonseM = AllTurnStartsBinned(:,StimStartBin:(StimStartBin+(FirstStimulus(2)/SBinWinSec)));

FirstResponseBin = NaN(NumTracks,1);

for TrackN =1:NumTracks
    turnIndexBin = find(firstRepsonseM(TrackN,:)>0);
    if ~isempty(turnIndexBin);
        FirstResponseBin(TrackN,1) = turnIndexBin(1,1);
    else
        FirstResponseBin(TrackN,1) = NaN;
    end
end