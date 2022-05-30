function outStruct=ReorderClusters(inStruct)
%outStruct=ReorderClusters(inStruct)
%
%reorder output from kmeans clustering by ascending cluster size
%
%EXAMPLE USAGE:
%[outStruct.clusterMembership,outStruct.clusterCenters,...
% outStruct.intraDistanceSums,outStruct.distancesToCentroid]...
% = kmeans(inputValues',options.maxClusters);
%outStruct=ReorderClusters(outStruct);

    outStruct=inStruct;

    numClusters=length(unique(inStruct.clusterMembership));
    
    
    %count cluster sizes
    for i=1:numClusters
        clusterSize(i) =  sum(outStruct.clusterMembership==i);
    end
    
    %sort cluster sizes
    [sortVal sortIndex]=sort(clusterSize,'ascend');
    
    %reorder
    for i=1:numClusters
        outStruct.clusterMembership(inStruct.clusterMembership==i)=sortIndex(i);
    end
    
    outStruct.clusterCenters=inStruct.clusterCenters(sortIndex);
    outStruct.intraDistanceSums=inStruct.intraDistanceSums(sortIndex);
    outStruct.distancesToCentroid=inStruct.distancesToCentroid(:,sortIndex);

end

