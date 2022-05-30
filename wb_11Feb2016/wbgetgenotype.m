function out=wbgetgenotype(foldername)

    underscorePositions=strfind(foldername,'_');
    out=foldername(underscorePositions(1)+1:underscorePositions(2)-1);

end