function outvector=zero2nan(vector)
%replace zeros with nans
    outvector=vector;
    outvector(vector==0)=NaN;
end
