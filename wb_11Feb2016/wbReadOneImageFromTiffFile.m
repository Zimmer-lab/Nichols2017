function imout=wbReadOneImageFromTiffFile(TIFFfile,totalZ,totalT,totalC,z,t,c,order)
%adds file open and close wrappers to wbReadOneImageFromTiffObj()

    if nargin<8
         order='xyztc';   %order is msb
    end

    TIFFobj = Tiff(TIFFfile, 'r');    
    
    imout=wbReadOneImageFromTiffObj(TIFFobj,totalZ,totalT,totalC,z,t,c,order);

    TIFFobj.close();
    
    if nargout<1
        figure;
        imagesc(imout);
    end

end
