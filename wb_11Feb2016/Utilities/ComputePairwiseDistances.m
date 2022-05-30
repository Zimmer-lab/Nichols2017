function pd=ComputePairwiseDistances(pts)
%pts is column time series
%

T=size(pts,1);
dist3=zeros(T);

for t2=1:T
    for t1=1:(t2-1)
                dist3(t1,t2)= norm ( pts(t1,:) - pts(t2,:) );
    end
end

dist3_nozeros=dist3(dist3>0);
pd=dist3_nozeros(:);

end