function outputArray=GetField(cellarray,fieldName)
%outputArray=GetField(cellarray,fieldName)
%get a cell array of field values from a cell array of structs
%

for i=1:length(cellarray)
    
    if isfield(cellarray{i},fieldName)
        
        outputArray{i}=cellarray{i}.(fieldName);
    else
        outputArray{i}=[];
    end
end