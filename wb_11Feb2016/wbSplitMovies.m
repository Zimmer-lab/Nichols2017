function wbSplitMovies(folder,fileInfo,orientation,splitPosition)

    if nargin<1
        folder=pwd;
    end

    omefiles=dir([folder filesep '*.ome.tif*']);  %support ome.tiff and ome.tif
    
    if length(omefiles)==0
        disp('wbSplitMovies> No OME TIFFs found in this directory. Nothing to load.');
        ZMovie=[];
        return;
    end;    

    for i=1:length(omefiles)
        OMEfile{i}=omefiles(i).name;
    end

    if ~exist([folder filesep 'region1'],'dir')
        mkdir([folder filesep 'region1']);
        mkdir([folder filesep 'region2']);
    end

    copyfile('meta.mat',[folder filesep 'region1']);
    copyfile('meta.mat',[folder filesep 'region2']);
    
    disp('wbSplitMovies> splitting.');

    for f=1:length(OMEfile)
        
         TifLinkRead(f) = Tiff(OMEfile{f}, 'r');    

%          TifLinkWrite1(f) = Tiff([folder filesep 'region1' filesep OMEfile{f}], 'w8');   
%          TifLinkWrite2(f) = Tiff([folder filesep 'region2' filesep OMEfile{f}], 'w8');   
         
         numT=fileInfo.numTInFile(f);
         numZ=fileInfo.numZInFile(f);
           
         if strcmp(orientation,'v')
             range1X=1:splitPosition;
             range2X=splitPosition+1:fileInfo.widthInFile(f);
             range1Y=1:fileInfo.heightInFile(f);
             range2Y=1:fileInfo.heightInFile(f);         
         else %'h'
             range1X=1:fileInfo.widthInFile(f);
             range2X=1:fileInfo.widthInFile(f); 
             range1Y=1:splitPosition;
             range2Y=splitPosition+1:fileInfo.heightInFile(f);
         end
         
%          tagstruct.RowsPerStrip=TifLinkRead(f).getTag('RowsPerStrip');
%          tagstruct.Photometric = TifLinkRead(f).getTag('Photometric');
%          tagstruct.BitsPerSample = TifLinkRead(f).getTag('BitsPerSample');
%          tagstruct.SamplesPerPixel = TifLinkRead(f).getTag('SamplesPerPixel');
%          tagstruct.RowsPerStrip = TifLinkRead(f).getTag('RowsPerStrip');
%          tagstruct.PlanarConfiguration =TifLinkRead(f).getTag('PlanarConfiguration');
%          
%          tagstruct1=tagstruct;
%          tagstruct1.ImageLength=length(range1X);
%          tagstruct1.ImageWidth=length(range1Y);
%          
%         TifLinkWrite1(f).setTag(tagstruct1);
         
%          tagstruct2=tagstruct;
%          tagstruct2.ImageLength=length(range2X);
%          tagstruct2.ImageWidth=length(range2Y);
%         TifLinkWrite2(f).setTag(tagstruct2);
        

         subImage1=zeros(length(range1Y),length(range1X),numZ,1,numT,'uint16');
         subImage2=zeros(length(range2Y),length(range2X),numZ,1,numT,'uint16');
       
         j=1;
         for t=1:numT
             for z=1:numZ %allZs
                 TifLinkRead(f).setDirectory(j);  
                 thisImage=TifLinkRead(f).read();

                 subImage1(:,:,z,1,t)=thisImage(range1Y,range1X);
                 subImage2(:,:,z,1,t)=thisImage(range2Y,range2X);
                 
%                  TifLinkWrite1(f).writeDirectory;
%                  TifLinkWrite2(f).writeDirectory;  
%                  
%                  TifLinkWrite1(f).setTag(tagstruct1);
%                  TifLinkWrite2(f).setTag(tagstruct2);
%                  
%                  TifLinkWrite1(f).write(subImage1);
%                  TifLinkWrite2(f).write(subImage2);
%                  


                 j=j+1;
             end
         end
         
         TifLinkRead(f).close();
         disp(['wbSplitMovies> ' num2str(f) '/' num2str(length(OMEfile)) ': reading and splitting done.  saving to OME files.']);
         tic
         bfsave(subImage1,[folder filesep 'region1' filesep OMEfile{f}(1:end-8) '_region1.ome.tiff'],'BigTiff',true,'Compression','LZW');
         bfsave(subImage2,[folder filesep 'region2' filesep OMEfile{f}(1:end-8) '_region2.ome.tiff'],'BigTiff',true,'Compression','LZW');
         
        % bfsave(subImage1,[folder filesep 'region1' filesep OMEfile{f}],'BigTiff',true,'Compression','LZW');
        % bfsave(subImage2,[folder filesep 'region2' filesep OMEfile{f}],'BigTiff',true,'Compression','LZW');
         
         toc
         
       wbAddFileInfo([folder filesep 'region1']);
       wbAddFileInfo([folder filesep 'region2']);      
         
%          TifLinkWrite1(f).close();
%          TifLinkWrite2(f).close();
         
    end


    disp('wbSplitMovies> done.');


    
    
    
    
%     for t=1:numT
%         for z=validZs %allZs
% 
%                 TifLink(k).setDirectory(j);  
% 
%                 thisImage=TifLink(k).read();    
% 
%         end
%     end
    
    
                        
end