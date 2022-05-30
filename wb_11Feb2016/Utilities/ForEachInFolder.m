function [outputCellArray,filesRan]=ForEachInFolder(folder,regExp,functionHandleSequenceCellArray)
%outputCellArray=ForEachInFolder(folder,regExp,functionHandleSequenceCellArray)
%
%run a cascade of functions on each file matching regExp in a folder
%and coallate results in a cell array
%
%each function must be able to accept the output from the previous function
%
%
%Saul Kato 10/8/2014
%

fileList=dir(folder);
j=1;
for i=1:length(fileList)
    if regexpi(fileList(i).name,regExp)
        filesToBeRun{j}=fileList(i).name;
        j=j+1;
    end
   
end


for i=1:length(filesToBeRun)
    
    newInput=filesToBeRun{i};
    
    %run a cascade of functions
    for f=1:length(functionHandleSequenceCellArray)
        
        this_function_handle=functionHandleSequenceCellArray{f};
        tmp=this_function_handle(newInput);
        clear newInput;
        newInput=tmp;
    end
        
    outputCellArray{i}=newInput;       
    
end

filesRan=filesToBeRun;

end