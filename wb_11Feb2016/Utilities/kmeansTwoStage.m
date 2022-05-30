function [clusterMembership, clusterCenters]=kmeansTwoStage(inputData,numClusterStage1,numClusterStage2,distanceMeasure)
%
%do kmeans on two stages


    [s1.membership,s1.clusCenters,s1.intraDistSums,s1.distsToCentroid]= ...
                        kmeans(inputData,numClusterStage1,'Distance',distanceMeasure,'emptyaction','drop','Replicates',10);  
                    
    final.clusterMembership=zeros(1,numClusterStage1*numClusterStage2);
    final.clusterCenters=[];
    
    for i=1:numClusterStage1
        
        thisInputData=inputData(s1.membership==i,:);
        
        [s2.membership,s2.clusCenters,s2.intraDistSums,s2.distsToCentroid]= ...
            kmeans(thisInputData,numClusterStage2,'Distance',distanceMeasure,'emptyaction','drop','Replicates',10);  
                           
        final.clusterMembership(s1.membership==i)    =   numClusterStage2*(i-1)+s2.membership;
        final.clusterCenters=  [ final.clusterCenters;  s2.clusCenters];
        
    end
    
    clusterMembership=final.clusterMembership';
    clusterCenters=final.clusterCenters';

end