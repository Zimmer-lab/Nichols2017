function wbRiseClusterPRL(folder,cutoff)

    if nargin<1
       folder=pwd;
    end
    
    if nargin<2
        cutoff=10;
    end

    
    if exist([folder filesep 'Quant' filesep 'wbClusterRiseStruct.mat'],'file')         
        CRS=load([folder filesep 'Quant' filesep 'wbClusterRiseStruct.mat']);        
    end
    

    if exist([folder filesep 'Quant' filesep 'wbClusterRiseStruct.mat'],'file')  && isfield(CRS,'clusterMembership')
               
        PRLclusterMembership=2*ones(size(CRS.clusterMembership));

        PRLclusterMembership(CRS.inputValuesSupp>cutoff)=1;


    else
        
        SS=load([folder filesep 'wbStateStatsStruct.mat']);
        
        PRLclusterMembership=2*ones(size(SS.stateRunStartIndices{2}));

        
        PRLs=ones(size(PRLclusterMembership));
        
        
        for i=1:length(SS.stateRunStartIndices{2})
            
            if SS.traceColoring{1}(SS.stateRunStartIndices{2}(i)-1) == 1
                priorStateIndex=find(SS.stateRunStartIndices{1}<SS.stateRunStartIndices{2}(i),1,'last');
                
                if ~isempty(priorStateIndex)
                    PRLs(i) = SS.stateFrameLengths{1}(priorStateIndex);
                else
                    PRLs(i)=SS.stateRunStartIndices{2}(i)-1;
                end
            end
            
        end
        
        
        
        PRLclusterMembership(PRLs>cutoff)=1;
        
        
        
    end
        
    
    CRS.PRL.clusterMembership=PRLclusterMembership;
    CRS.PRL.cutoff=cutoff;

    save([folder filesep 'Quant' filesep 'wbClusterRiseStruct.mat'],'-struct','CRS');
    
end