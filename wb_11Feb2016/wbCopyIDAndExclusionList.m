function wbCopyIDAndExclusionList(wbstructToFile,wbstructFromFile)

     wbstructTo=wbload(wbstructToFile);
     wbstructFrom=wbload(wbstructFromFile);
     
     wbstructTo.ID=wbstructFrom.ID;
     wbstructTo.exclusionList=wbstructFrom.exclusionList;
     
     save(wbstructToFile,'-struct','wbstructTo');
     
end