function [TMIPMovie,numZ,numTW,validZs]=wbloadTMIPs(folder,metadata)

    if nargin<1
        folder=pwd;
    end
        
    if nargin<2
        if exist([folder filesep 'meta.mat'],'file')==2
            disp('wbloadTMIPs> loading metadata from meta.mat file.');
            metadata=load([folder filesep 'meta.mat']);
        else
            disp('wbloadTMIPs> no metadata or meta.mat file found.  quitting.');
            return;
        end
    end

    zmoviefolders=listfolders([folder filesep 'TMIPs']);
    disp('wbloadTMIPs> loading TMIPs.'); 

    warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
    warning('off','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');

    if strcmp(metadata.noseDirection,'North') || strcmp(metadata.noseDirection,'South')
        width=metadata.fileInfo.width;
        height=metadata.fileInfo.height;
    else
        height=metadata.fileInfo.width;
        width=metadata.fileInfo.height;
    end

    validZs=1:length(zmoviefolders);
    if isfield(metadata,'excludeZPlanes')
        excludeZPlanes=metadata.excludeZPlanes(metadata.excludeZPlanes<=length(zmoviefolders));
        if excludeZPlanes ~= 0
           validZs(excludeZPlanes)=[];
        end
    end

    %numExcludedPlanes=length(excludeZPlanes);

    numberImages=0;
    
    for z=validZs

        ZFiles=dir([folder filesep 'TMIPs' filesep zmoviefolders{z} filesep '*.tif']);
        numberImages=length(ZFiles);
        TMIPMovie{z}=zeros(height,width,numberImages,'uint16');  
        
    end
    
    if numberImages==0
        disp('No TMIPs found. You need to add a TMIPs folder or generate them.');
        TMIPMovie=[];
        numZ=0;
        numTW=0;
        return;
    end
    
    numValidZ=validZs(end);
    
    for z=validZs

        %fprintf('%d...',z-1); 

        ZFiles=dir([folder filesep 'TMIPs' filesep zmoviefolders{z} filesep '*.tif']);

        numberImages=length(ZFiles);

        
        for i=1:numberImages
            FileTif=[folder filesep 'TMIPs' filesep zmoviefolders{z} filesep ZFiles(i).name];
            TifLink = Tiff(FileTif, 'r');
            TifLink.setDirectory(1);   

            thisImage=TifLink.read();
            
            if ~isequal(size(thisImage),[metadata.fileInfo.height metadata.fileInfo.width])
                disp('wbloadTMIPs> metadata fileInfo does not match OME dimensions.  Please regenerate fileInfo data in wb.');
                beep; pause(.1); beep;
            end

            if strcmp(metadata.wormSideUp,'Right')
                
                if strcmp(metadata.noseDirection,'North')
                    TMIPMovie{numValidZ-z+1}(:,:,i)=thisImage(:,end:-1:1);
                elseif strcmp(metadata.noseDirection,'South')           
                    TMIPMovie{numValidZ-z+1}(:,:,i)=thisImage(end:-1:1,:);
                elseif strcmp(metadata.noseDirection,'West')
                    %tempImage=thisImage(:,:)';
                    TMIPMovie{numValidZ-z+1}(:,:,i)=thisImage';                    
                else  %East noseDirection              
                    TMIPMovie{numValidZ-z+1}(:,:,i)=thisImage(end:-1:1,end:-1:1)';
                end
                
                
            else %wormSideUp Left
                
                if strcmp(metadata.noseDirection,'North')
                    TMIPMovie{z}(:,:,i)=thisImage;
                elseif strcmp(metadata.noseDirection,'South')           
                    TMIPMovie{z}(:,:,i)=thisImage(end:-1:1,end:-1:1);
                elseif strcmp(metadata.noseDirection,'West')
                    TMIPMovie{z}(:,:,i)=thisImage(end:-1:1,:)';
                else  %East noseDirection
                    tempImage=thisImage(end:-1:1,:)';
                    TMIPMovie{z}(:,:,i)=tempImage(end:-1:1,end:-1:1);
                end
                
            end
            
            TifLink.close();
        end

    end

    numTW=numberImages;
    numZ=length(validZs);

    warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
    warning('on','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');

    assignin('base','TMIPMovie',TMIPMovie);

end