function fi=wbDownSampleImageSequence(mainFolder,smoothingWindow,targetFolder)
%fi=wbMakeTMIPsFromImageSequence(mainFolder,smoothingWindow)
%create TMIPs from a set of OME tif files and save into TMIPs directories with Z
%subdirectories
%
%fi is file info

if nargin<1
    mainFolder=pwd;
end

if nargin<2
    smoothingWindow=100;
end

[parentFolder, mainFolderName, ~]=fileparts(mainFolder);

if nargin<3
    targetFolder=[parentFolder filesep mainFolderName '-' num2str(smoothingWindow) 'xDownsample'];
end

%get OME file info, this takes an unreasonably long time.
% omefiles=dir([mainFolder filesep '*.ome.tif*']);
% 
% if length(omefiles)==0
%     disp('No OME TIFFs found in this directory.');
%     return
% end


tifFiles=dir([mainFolder filesep '*.tif']);
tifFileNames_sorted=sort_nat({tifFiles.name});  %natural sorting

%load one .tif file
oneFrame(:,:)=imread([mainFolder filesep tifFileNames_sorted{1}]);
    
    
% for i=1:length(omefiles)
%     
%     OMEfile{i}=omefiles(i).name;
%     reader(i) = bfGetReaderSK(OMEfile{i});   
%     omeMeta = reader(i).getMetadataStore();
%     fi.widthInFile(i) = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
%     fi.heightInFile(i) = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
%     fi.numZInFile(i) = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
%     fi.numTInFile(i) = omeMeta.getPixelsSizeT(0).getValue();
%     fi.numTotalFramesInFile(i) = reader(i).getImageCount();
    
%end

%fi.numTotalFrames=sum(fi.numTotalFramesInFile);
% fi.width=fi.widthInFile(1);
% fi.height=fi.heightInFile(1);
% fi.numZ=fi.numZInFile(1);
% fi.numT=sum(fi.numTInFile);
% fi.numTW = ceil(fi.numT/smoothingWindow);

fi.numTotalFrames=length(tifFiles);
fi.numT=fi.numTotalFrames;
fi.numZ=1;
fi.width=size(oneFrame,2);
fi.height=size(oneFrame,1);
fi.numTW=ceil(fi.numT/smoothingWindow);

disp(['w=wbDownSampleImageSequence> generating ' num2str(fi.numTW) ' TMIPs...']); 
tic
% warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
% warning('off','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
% 
% disp(['wbOMETMIP> loading ' OMEfile{1}]); 
% TifLink(1) = Tiff(OMEfile{1}, 'r');
% 
% warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
% warning('on','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
% 



warning('off','MATLAB:MKDIR:DirectoryExists');

mkdir(targetFolder);

% for z=1:fi.numZ
%     thisZFolder{z}=[parentFolder filesep mainFolderName 'TMIPs' filesep 'Z' num2str(z,'%02d')];
%     mkdir(thisZFolder{z});
% end

warning('on','MATLAB:MKDIR:DirectoryExists');

k=1;
%j=1; 
frameCount=1;

for tw=1:fi.numTW
     fprintf('%d.',tw); 
     numberImages=min([smoothingWindow  fi.numT-(tw-1)*smoothingWindow]);  %last batch is longer
     for i=1:numberImages   
         
          for z=1:fi.numZ
              
              if (i==1) accumImage{z}=zeros(fi.height,fi.width); end       
              
              %TifLink(k).setDirectory(j);   
              %thisImage=double(TifLink(k).read());
              
              thisImage=double(imread([mainFolder filesep tifFileNames_sorted{frameCount} ]));

              frameCount=frameCount+1;
             
              accumImage{z}=accumImage{z}+thisImage;
%               j=j+1;  %increment image# within-OMEfiledirectory
%               if j>fi.numTotalFramesInFile(k) &&  k<length(omefiles)  %move to next OME File                  
%                   TifLink(k).close();
%                   j=1;    %reset within-OMEfile directory counter
%                   k=k+1;  %increment OMEfile counter                      
%                   disp(''); disp(['>loading ' OMEfile{k}]); 
%                   TifLink(k) = Tiff(OMEfile{k}, 'r');
%               end
        end

     end
     
     numMaxDigits=ceil( log10( fi.numTW));
     %normalize sum and save out
     for z=1:fi.numZ
          accumImage{z}=accumImage{z}/numberImages;
          imwrite(uint16(accumImage{z}),[targetFolder filesep 'TW' num2str(smoothingWindow) '-Z' num2str(z,'%02d') '-T' num2str(tw,['%0' num2str(numMaxDigits) 'd']) '.tif'] ,'TIFF','Compression','LZW');
     end
     
end

% TifLink(k).close();
disp(' ');
toc

end



