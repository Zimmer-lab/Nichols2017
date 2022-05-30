function  timeColoring=wbConvertFourToSixStateColoring(timeColoring4State,TRM,TFM,CRS,CFS,clusterKeys)

if ~exist('clusterKeys','var') || isempty(clusterKeys)
    clusterKeys=[1 1];
end


            if clusterKeys(1)==2
                CRS.clusterMembership=3-CRS.clusterMembership;
            end
            
            if clusterKeys(2)==2
                CRS.clusterMembership=3-CRS.clusterMembership;
            end
            
                

            clusterRiseColoring=zeros(size(timeColoring4State));
            clusterFallColoring=zeros(size(timeColoring4State));
            
            for k=1:size(TRM,1)
                
                  
                  if ~isnan(TRM(k,4)) && ~isnan(TRM(k,3))
                         clusterRiseColoring(max([1 TRM(k,3)]): ...
                         min([size(timeColoring4State,1)  TRM(k,4)]))=  ...
                         CRS.clusterMembership(k);
                  end

            end


            for k=1:min([size(TFM,1) length(CFS.clusterMembership)])
                
                  if ~isnan(TFM(k,4)) && ~isnan(TFM(k,3))
                      
                         clusterFallColoring(max([1 min([TFM(k,3) length(clusterFallColoring)])]): ...
                          min([size(timeColoring4State,1)  TFM(k,4)]))=   ...
                          CFS.clusterMembership(k);
                  end

            end

            cR=(clusterRiseColoring-1).* (timeColoring4State==2);
            
            cR(cR>0)=cR(cR>0)+2;
            cF=(clusterFallColoring-1).* (timeColoring4State==4);
            cF(cF>0)=cF(cF>0)+1;

            timeColoring=timeColoring4State+cR+cF;

%           %force colormap
%           timeColoring(1)=0;timeColoring(2)=8;
        

end