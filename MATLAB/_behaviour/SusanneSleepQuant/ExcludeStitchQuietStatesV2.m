
% exclude quiet states if shorter than 10 bins (= 10sec or 30 frames) and
% stitch together stretches that are not further apart than 30 bins

% in a first step exclude phases that are too short; in a second step
% stitch together the remaining phases that are close together

% temporarily remove NaN's from wakestate matrix (borders of stretches of
% 0's are determined using difference to neighbour - presence of NaN might
% interfere with identification of some stretches) = wakestate_temp

% minDuration = 10, InterDuration = 30 per default;


function [wakestateFinal] = ExcludeStitchQuietStatesV2(wakestate, NumTracks, NumBins, minDuration, InterDuration)

wakestate_temp = wakestate;
wakestate_temp(isnan(wakestate)) = 1;
dwakestate = NaN(NumTracks, NumBins);
wakestateFinal = wakestate;


for j = 1:size(wakestate_temp, 1)
    
    dwakestate(j,:) = diff([1 wakestate_temp(j,:)]);
    startIndex = find(dwakestate(j,:) < 0);
    if isempty(startIndex)
       continue
       j = j+1;
    end
    endIndex = find(dwakestate(j,:) > 0)-1;
    
    % calculate length of each individual stretch and identify those below
    % threshold (i.e. below 11 bins)
    duration = (endIndex(1,:)-startIndex(1,:))+1;  
    stringIndex = (duration < minDuration);
    keepIndex = (duration >= minDuration);
    startIndexC = startIndex(stringIndex);
    endIndexC = endIndex(stringIndex);
    startIndexK = startIndex(keepIndex);
    endIndexK = endIndex(keepIndex);
      
    % remove stretches below threshold by changing 0 to 1 in wakestate matrix
    for jj = 1:size(startIndexC,2)

        wakestateFinal(j,startIndexC(jj):endIndexC(jj)) = 1; 

    end
    
    % find stretches of quiet phases that are not further apart than 30
    % bins and not interrupted by a search period; then stitch those
    % together (from empirical observation it appears that these periods
    % are more likely to be one rather than separate periods)
    for m = 1:size(startIndexK,2)-1
        
        InterBoutDuration(1,m) = (startIndexK(1,m+1)-endIndexK(1,m));
      
        if InterBoutDuration(m) <= InterDuration 
           wakestateFinal(j,endIndexK(m):startIndexK(m+1)) = 0;
        end
            
    end
end
    

 
        
        
        
        
        
        
        
        
        
        