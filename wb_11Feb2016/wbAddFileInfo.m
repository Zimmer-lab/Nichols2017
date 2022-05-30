function fileInfo=wbAddFileInfo(mainFolder,saveToMetaFlag)

    if nargin<2
        saveToMetaFlag=true;
    end
    
    if nargin<1
        mainFolder=pwd;
    end

    omefiles=dir([mainFolder filesep '*.ome.tif*']);
    
    if ~isempty(omefiles)
        
        fileInfo.numFiles=length(omefiles);


        for i=1:length(omefiles)
            fileInfo.filenames{i}=omefiles(i).name;
            reader(i) = bfGetReaderSK([mainFolder filesep fileInfo.filenames{i}]); % modified external reader function

            %OME API calls
            omeMeta = reader(i).getMetadataStore();

            fileInfo.widthInFile(i) = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
            fileInfo.heightInFile(i) = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
            fileInfo.numZInFile(i) = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
            fileInfo.numTInFile(i) = omeMeta.getPixelsSizeT(0).getValue(); % number of Time points
            fileInfo.numCInFile(i) = omeMeta.getPixelsSizeC(0).getValue(); % number of channels
            fileInfo.numTotalFramesInFile(i) = reader(i).getImageCount();

        end

        fileInfo.numTotalFrames=sum(fileInfo.numTotalFramesInFile);

        fileInfo.width=fileInfo.widthInFile(1);
        fileInfo.height=fileInfo.heightInFile(1);
        fileInfo.numZ=fileInfo.numZInFile(1);
        fileInfo.numT=sum(fileInfo.numTInFile);
        fileInfo.numC=fileInfo.numCInFile(1);
   
    else  %image sequence
        
        tifFiles=dir([mainFolder filesep '*.tif']);
        tifFileNames_sorted=sort_nat({tifFiles.name});  %natural sorting

        %load one .tif file
        oneFrame(:,:)=imread( tifFileNames_sorted{1});
    
        fileInfo.numTotalFrames=length(tifFiles);
        fileInfo.numT=fileInfo.numTotalFrames;
        fileInfo.numZ=1;
        fileInfo.width=size(oneFrame,2);
        fileInfo.height=size(oneFrame,1);
        
        smoothingWindow=wbGetTMIPsmoothingTWindow;
        fileInfo.numTW=ceil(fileInfo.numT/smoothingWindow);


    end
    
    if saveToMetaFlag
        
        if ~exist([mainFolder filesep 'meta.mat'],'file')
            save([mainFolder filesep 'meta.mat'],'fileInfo');
        else
            save([mainFolder filesep 'meta.mat'],'fileInfo','-append');
        end
    
    else
        

end 