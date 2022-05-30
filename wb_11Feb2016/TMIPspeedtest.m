disp('>generating TMIPs...'); 
tic
warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
warning('off','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');


TifLink = Tiff(OMEfile, 'r');

TMIP=zeros(height,width,floor(numT/avgTWindow),'uint16');
%for z=1:numZ

    %fprintf('%d...',z-1); 
    
    j=1;
    for tw=1:floor(numT/avgTWindow)
        
        numberImages=min([avgTWindow  numT-(tw-1)*avgTWindow]);  %last batch is longer
        accumImage=zeros(height,width);
        for i=1:numberImages   
            TifLink.setDirectory(j);   
            accumImage=accumImage+double(TifLink.read());
            j=j+1;
        end

        accumImage=accumImage/numberImages;
    
        TMIP(:,:,tw)=uint16(accumImage);
        
    end

%end

TifLink.close();
warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
warning('on','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
toc

figure;imagesc(TMIP(:,:,end));