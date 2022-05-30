function omat=fixnan(mat)
%omat=fixnan(mat)
%remove NaN values from matrix by selecting value above NaN areas within column
%(assumes columns are timeseries)
%Saul Kato
%121101
%
%updated 1301028 to check first row for NaNs and make them zeros and do NaN
%blocks
%

%old way
% omat=mat;
% nans_in_firstrow=find(isnan(mat(1,:)));
% mat(1,nans_in_firstrow)=0;
% nans=find(isnan(mat));
% while sum(sum(isnan(omat)))>0
%     omat(nans)=omat(nans-1);
% end


%fill in all nans
for i=1:size(mat,2)
    
    if isnan(mat(1,i)) mat(1,i)=0; end
    
    for t=2:size(mat,1)
        
        if isnan(mat(t,i)) mat(t,i)=mat(t-1,i); end
    end
end

omat=mat;