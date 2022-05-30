function index=FindClosestPoint(point,points)
%index=FindClosestPoint(point,points)
        
    displacements=points-repmat(point,size(points,1),1);
    distances=sqrt(sum(displacements.^2,2));
    [minDist,index]=min(distances);     
      
end