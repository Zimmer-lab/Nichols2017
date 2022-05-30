function outvector=zeronan(vector)
%replace nans with zeros
    outvector=zeros(size(vector));
    outvector(~isnan(vector))=vector(~isnan(vector));

end
