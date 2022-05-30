function [clusterMembership, clusterCenters, numClusters]= AssignToCluster1D(values,minSpread,maxRange)
%kmeans on single dimensions
%values is nxk where k is numver of obseravations
options.distanceMeasure='cityblock';
options.numReplicates=10;

if nargin<3
    maxRange=[7 7];
end

if nargin<2 
    minSpread=5;
end

for n=1:size(values,1)
    
   thisValues=values(n,:);
   validIndices=(~isnan(thisValues) & thisValues<maxRange(2) & thisValues>-abs(maxRange(1)));
   thisValues(~validIndices)=[];
   
   if length(thisValues)>1
       
     [c{1}.clusterMembership,c{1}.clusterCenters,c{1}.intraDistanceSums,c{1}.distancesToCentroid] = kmeans(thisValues',1,'Distance',options.distanceMeasure,'Replicates',options.numReplicates,'emptyaction','drop');
     [c{2}.clusterMembership,c{2}.clusterCenters,c{2}.intraDistanceSums,c{2}.distancesToCentroid] = kmeans(thisValues',2,'Distance',options.distanceMeasure,'Replicates',options.numReplicates,'emptyaction','drop');

     clusterMembership(n,:)=zeros(size(values(n,:)));
     
     if abs(c{2}.clusterCenters(2)-c{2}.clusterCenters(1))>minSpread
         
         if c{2}.clusterCenters(2)>c{2}.clusterCenters(1)
             clusterMembership(n,validIndices)=c{2}.clusterMembership;        
         else
             clusterMembership(n,validIndices)=3-c{2}.clusterMembership;             
         end
         
         numClusters(n)=2;
         clusterCenters=c{2}.clusterCenters;
         
     else
         
         clusterMembership(n,validIndices)=1;
         numClusters(n)=1;
         clusterCenters=c{1}.clusterCenters;
         
     end
     
     
   else
        clusterMembership(n,:)=zeros(size(values(n,:)));
        numClusters(n)=1;
        if length(thisValues)==1
            clusterCenters=thisValues;
        else
            clusterCenters=0;
        end
       
   end

     
end