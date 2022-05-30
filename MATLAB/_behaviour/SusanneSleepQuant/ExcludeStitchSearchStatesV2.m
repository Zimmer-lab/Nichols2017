

% stitch together stretches of search phases if their distance is less or
% equal 15 bins; then, make sure that quiet and search phases are mutually
% exclusive by removing search if quiet is true at the same point in time
% (or don't? search & quiet are determined using partially overlapping
% criteria, might thus represent partially overlapping states... -- for the 
% sake of keeping potentially useful data searchstate will not be overwritten
% (for the time being) when coinciding with quiet but data are saved in separate 
% matrix = searchstateExcl)

% in a first step stitch together phases that are close together, then
% create searchstateExcl that doesn't contain any overlapping periods with
% quiet states; in a second step remove search phases that are too short
% from both searchstate and searchstateExcl matrices

% InterSDuration = 15, minDuration = 16 per default;


function [searchstateExcl, searchstateFinal] = ExcludeStitchSearchStatesV2(wakestateFinal, searchstate, NumTracks, NumBins, InterSDuration, minDuration)


searchstate_temp = searchstate;
searchstate_temp(isnan(searchstate)) = 0;
dsearchstate = NaN(NumTracks, NumBins);
% initialize searchstate of data not overlapping with wakestate
searchstateExcl = searchstate;
searchstateFinal = searchstate;

for j = 1:size(searchstate_temp, 1)
    
    dsearchstate(j,:) = diff([1 searchstate_temp(j,:)]);
    startIndexS = find(dsearchstate(j,:) > 0);
    if isempty(startIndexS)
       continue
       j = j+1;
    end
    endIndexS = find(dsearchstate(j,:) < 0)-1;
    endIndexS(:,1) = [];

    
    for m = 1:size(startIndexS,2)-1
        
        InterSBoutDuration(1,m) = (startIndexS(1,m+1)-endIndexS(1,m));
      
        if InterSBoutDuration(m) <= InterSDuration 
           searchstateExcl(j,endIndexS(m):startIndexS(m+1)) = 1; 
           searchstateFinal(j,endIndexS(m):startIndexS(m+1)) = 1;
           searchstate_temp(j,endIndexS(m):startIndexS(m+1)) = 1;
        end
            
    end
    
    % find bins for which both quiet and search state are true
    quietNsearch = (wakestateFinal(j,:)==0 & searchstateFinal(j,:) ==1);
    bins = find(quietNsearch == 1);

    % change search to 0 if there is a quiet state at the same time  
    searchstateExcl(j,bins) = 0;
   
end


% exclude search periods below time threshold (16 bins) from
% searchstate and searchstateExcl matrix


searchstateExcl_temp = searchstateExcl;
searchstateExcl_temp(isnan(searchstateExcl)) = 0;
dsearchstate2 = NaN(NumTracks, NumBins);
dsearchstateExcl = NaN(NumTracks, NumBins);

for j = 1:size(searchstateExcl_temp, 1)
    
    % find start and end indices of searchstateExcl
    dsearchstateExcl(j,:) = diff([1 searchstateExcl_temp(j,:)]);
    startIndexSE = find(dsearchstateExcl(j,:) > 0);
    if isempty(startIndexSE)
       continue
       j = j+1;
    end
    endIndexSE = find(dsearchstateExcl(j,:) < 0)-1;
    endIndexSE(:,1) = [];
    
    % find start and end indices of searchstateFinal
    dsearchstate2(j,:) = diff([1 searchstate_temp(j,:)]);
    startIndexS2 = find(dsearchstate2(j,:) > 0);
    if isempty(startIndexS2)
        continue
    end;
    endIndexS2 = find(dsearchstate2(j,:) < 0)-1;
    endIndexS2(:,1) = [];
    
    % determine duration, start and end of bouts in searchstateExcl
    durationE = (endIndexSE(1,:)-startIndexSE(1,:))+1;  
    stringIndexE = (durationE < minDuration);
    startIndexSC = startIndexSE(stringIndexE);
    endIndexSC = endIndexSE(stringIndexE);
    % find start indices of periods to remove in searchstate (not excl) matrix
    duration = (endIndexS2(1,:)-startIndexS2(1,:))+1;
    stringIndex = (duration < minDuration);
    startIndexS2C = startIndexS2(stringIndex);
    endIndexS2C = endIndexS2(stringIndex);
      
    % remove stretches below threshold 
    for jj = 1:size(startIndexSC,2)

        searchstateExcl(j,startIndexSC(jj):endIndexSC(jj)) = 0; 

    end
    
    for kk = 1:size(startIndexS2C,2)
        
        searchstateFinal(j,startIndexS2C(kk):endIndexS2C(kk)) = 0;
    end
    
end