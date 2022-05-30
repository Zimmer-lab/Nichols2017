function [out_array, inBoundsIndices]=InBounds(array,lo,hi,useNaNs)

if nargin<4
    useNaNs=false;
end

if nargin<3   
    hi=1;    
end

if nargin<2    
    lo=0;    
end

if useNaNs   
    out_array = nan(size(array));
    out_array(array <= hi & array >= lo)=array(array <= hi & array >= lo);   
else
    out_array = array(array <= hi & array >= lo); 
end

inBoundsIndices=find(array <= hi & array >= lo);


end