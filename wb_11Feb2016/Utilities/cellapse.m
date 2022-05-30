function collapsedArray=cellapse(cellArray)
%collapsedArray=cellapse(cellArray)
%
%convert cell array to scalar column array
%

collapsedArray=[];

for i=1:length(cellArray)
    collapsedArray=[collapsedArray; cellArray{i}(:)];
end
