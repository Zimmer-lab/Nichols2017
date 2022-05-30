function [sortedCellArray,sortIndex]=AlphaSort(cellArray,rule)

if nargin<2
    rule='numbersLast';
end

numericLogical=false(1,length(cellArray));
numericsOnly=[];
numericsOnlyRevLookup=[];
j=1;
for i=1:length(cellArray)
    
    if str2num(cellArray{i})==str2num(num2str(str2num(cellArray{i})))  %check for numerica
        numericLogical(i)=true;
        numericsOnly(j)=str2num(cellArray{i});
        numericsOnlyRevLookup(j)=i;
        j=j+1;
    end
    
end

%sort numbers


%sort alphas

alphasOnly=cellArray(~numericLogical);
alphasOnlyIndex=find(~numericLogical);
[alphasOnlySortedCellArray, alphasOnlySortIndex]=sort(alphasOnly);

alphasOnlyRevLookup=[];
for j=1:length(alphasOnly)
    
    alphasOnlyRevLookup(j) = alphasOnlyIndex( alphasOnlySortIndex(j));   
end

%sort numerics
numericsOnlySortCellArray=[];
[numericsOnlySorted, numericsOnlySortIndex]=sort(numericsOnly,'ascend');

for i=1:length(numericsOnlySorted)
    numericsOnlySortCellArray{i}=num2str(numericsOnlySorted(i));
end

%put back together

if strcmp(rule,'numbersLast')
    
    sortedCellArray=[alphasOnlySortedCellArray numericsOnlySortCellArray];
    
    sortIndex=[alphasOnlyRevLookup  numericsOnlyRevLookup(numericsOnlySortIndex)];
    
else
    
    disp('AlphaSort> this branch not yet implemented.');
    sortedCellArray=[];
    sortIndex=[];
    
end