function fileInfo=wbaddOMEmetadata(mainfolder)

    if nargin<1
        mainfolder=pwd;
    end

    omefiles=dir([mainfolder filesep '*.ome.tif*']);
    
    if ~isempty(omefiles)
        
        fileInfo.numFiles=length(omefiles);


        for i=1:length(omefiles)
            fileInfo.filenames{i}=omefiles(i).name;
            reader(i) = bfGetReaderSK(fileInfo.filenames{i}); % modified external reader function

            %OME API calls
            omeMeta = reader(i).getMetadataStore();

            fileInfo.widthInFile(i) = omeMeta.getPixelsSizeX(0).getValue(); % image width, pixels
            fileInfo.heightInFile(i) = omeMeta.getPixelsSizeY(0).getValue(); % image height, pixels
            fileInfo.numZInFile(i) = omeMeta.getPixelsSizeZ(0).getValue(); % number of Z slices
            fileInfo.numTInFile(i) = omeMeta.getPixelsSizeT(0).getValue();
            fileInfo.numCInFile(i) = omeMeta.getPixelsSizeC(0).getValue();
            fileInfo.numTotalFramesInFile(i) = reader(i).getImageCount();

        end

        fileInfo.numTotalFrames=sum(fileInfo.numTotalFramesInFile);

        fileInfo.width=fileInfo.widthInFile(1);
        fileInfo.height=fileInfo.heightInFile(1);
        fileInfo.numZ=fileInfo.numZInFile(1);
        fileInfo.numT=sum(fileInfo.numTInFile);
        fileInfo.numC=fileInfo.numCInFile(1);


        if ~exist([mainfolder filesep 'meta.mat'],'file')
            save([mainfolder filesep 'meta.mat'],'fileInfo');
        else
            save([mainfolder filesep 'meta.mat'],'fileInfo','-append');
        end
    
    else
        fileInfo=[];
    end

end 