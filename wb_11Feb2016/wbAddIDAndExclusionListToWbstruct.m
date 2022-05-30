function wbAddIDAndExclusionListToWbstruct

     wbstruct=wbload;
     
     load('ID.mat');
     wbstruct.ID=ID;
     
     load('exclusionList.mat');
     wbstruct.exclusionList=exclusionList;
     
     save('Quant/wbstruct','-struct','wbstruct');
     
end