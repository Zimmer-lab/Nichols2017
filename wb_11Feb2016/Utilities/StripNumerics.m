function [outCellArray, nOrig]=StripNumerics(cellArray)

nOrig=[];
j=1;
for i=1:length(cellArray)
    if ~strcmp(num2str(str2num(cellArray{i})),cellArray{i})
        outCellArray{j}=cellArray{i};
        j=j+1;
        nOrig=[nOrig i];
    end
end