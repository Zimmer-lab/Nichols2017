function imout=wbReadOneImageFromTiffObj(TIFFobj,totalZ,totalT,totalC,z,t,c,order)
%reads a single image from a multiplane TIFF, using LibTIFF
%

    if nargin<7
         order='xyztc';   %iteration order is left to right for z-t-c
    end

    frameNum=ComputeTiffDirectoryNumber(totalZ,totalT,totalC,z,t,c,order);

    TIFFobj.setDirectory(frameNum);
    
    imout=TIFFobj.read();
    

 
    %subfunctions
    
    function frameNum=ComputeTiffDirectoryNumber(totalZ,totalT,totalC,z,t,c,order)

        if strcmp(order,'xyztc')

            frameNum=(c-1)*totalZ*totalT + (t-1)*totalZ + z;

        end


    end
    
end


