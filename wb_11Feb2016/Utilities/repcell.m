function cellvecout=repcell(cellvec,nreps)
%repeat the individal cells of a row vector of cells
%
if nargin<2
    nreps=2;
end

for i=1:size(cellvec,2)
    for j=1:nreps
        cellvecout{nreps*(i-1)+j}=cellvec{i};
    end
end