function indices=FindCells(cellarray,subsetarray)
%find the indices of a subset cell array of a larger array
%currently crashes if there are cells in the subsetarray not in cellarray

indices = cellfun(@(x) find(strcmp(cellarray,x)),subsetarray);

end