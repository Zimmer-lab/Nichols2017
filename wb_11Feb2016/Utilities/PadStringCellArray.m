function cellArrayOut=PadStringCellArray(cellArray,numSpaces)

spaces=[];
for i=1:numSpaces
    spaces=[spaces ' '];
end

cellArrayOut=cell(size(cellArray));

for i=1:length(cellArray)
    cellArrayOut{i}=[spaces cellArray{i}];
end


end