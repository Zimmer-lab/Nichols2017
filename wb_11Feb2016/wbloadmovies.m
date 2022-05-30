function ZMovie=wbloadmovies(folder,metadata,globalMovieFlag)
%ZMovie=wbloadmovies(zmoviefolders,metadata,globalMovieFlag)
%load OME tiff movies into memory with proper transformation into
%canonical worm orientation
%
%if globalMovieFlag is set,
%1) will try to load ZMovie from base workspace 
%2) will save ZMovie to base workspace
%
        if nargin<1
            folder=pwd;
        end
    
        if nargin<3
            globalMovieFlag=true;
        end
    
        if nargin<2
            if exist([folder filesep 'meta.mat'],'file')==2
                disp('wbloadmovies> loading metadata from meta.mat file.');
                metadata=load([folder filesep 'meta.mat']);
            else
                disp('wbloadmovies> no metadata or meta.mat file found.  quitting.');
                return;
            end
        end
       
        if globalMovieFlag && evalin('base','exist(''ZMovie'',''var'')==1');
            disp('wbloadmovies> using ZMovie already in workspace.');
            ZMovie=evalin('base', 'ZMovie');
            
        else     
            
            warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
            warning('off','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');

            omefiles=dir([folder filesep '*.ome.tif*']);  %support ome.tiff and ome.tif

            if length(omefiles)==0
                disp('wbloadmovies> No OME TIFFs found in this directory. Nothing to load.');
                ZMovie=[];
                return;
            end;
            
            for i=1:length(omefiles)
                OMEfile{i}=omefiles(i).name;
            end

            if ~isfield(metadata,'fileInfo')
                disp('wbloadmovies> no fileInfo in metadata.  running wbaddOMEmetadata.');
                metadata.fileInfo=wbaddOMEmetadata;
            end

            validZs=1:metadata.fileInfo.numZ;
            if isfield(metadata,'excludeZPlanes')
                    excludeZPlanes=metadata.excludeZPlanes(metadata.excludeZPlanes<=metadata.fileInfo.numZ);  %handling of bad z planes
                    if excludeZPlanes ~= 0
                        validZs(excludeZPlanes)=[];
                        numExcludedPlanes=length(excludeZPlanes);
                    else
                        numExcludedPlanes=0;
                    end
            end
            
            disp(['wbloadmovies> loading ' OMEfile{1}]); 
            TifLink(1) = Tiff(OMEfile{1}, 'r');

            numT=metadata.fileInfo.numT;

            if strcmp(metadata.noseDirection,'North') || strcmp(metadata.noseDirection,'South')
                width=metadata.fileInfo.width;
                height=metadata.fileInfo.height;
            else
                height=metadata.fileInfo.width;
                width=metadata.fileInfo.height;
            end

            
            for z=validZs
                ZMovie{z}=zeros(height,width,numT,'uint16');
            end
            
            numValidZ=validZs(end);
            
            j=1;
            k=1;
            for t=1:numT
                for z=validZs %allZs

                        TifLink(k).setDirectory(j);  

                        thisImage=TifLink(k).read();
                        
                     
                        if strcmp(metadata.wormSideUp,'Right')

                            if strcmp(metadata.noseDirection,'North')
                                ZMovie{numValidZ-z+1}(:,:,t)=thisImage(:,end:-1:1);
                            elseif strcmp(metadata.noseDirection,'South')           
                                ZMovie{numValidZ-z+1}(:,:,t)=thisImage(end:-1:1,:);
                            elseif strcmp(metadata.noseDirection,'West')
                                %tempImage=thisImage(end:-1:1,:)';
                                ZMovie{numValidZ-z+1}(:,:,t)=thisImage';                    
                            else  %East noseDirection              
                                ZMovie{numValidZ-z+1}(:,:,t)=thisImage(end:-1:1,end:-1:1)';
                            end


                        else %wormSideUp Left

                            if strcmp(metadata.noseDirection,'North')
                                ZMovie{z}(:,:,t)=thisImage;
                            elseif strcmp(metadata.noseDirection,'South')           
                                ZMovie{z}(:,:,t)=thisImage(end:-1:1,end:-1:1);
                            elseif strcmp(metadata.noseDirection,'West')
                                ZMovie{z}(:,:,t)=thisImage(end:-1:1,:)';
                            else  %East noseDirection
                                tempImage=thisImage(end:-1:1,:)';
                                ZMovie{z}(:,:,t)=tempImage(end:-1:1,end:-1:1);
                            end

                        end

                        j=j+1;
                end
                j=j+numExcludedPlanes;  %skip excludedPlanes

                if j>metadata.fileInfo.numTotalFramesInFile(k) &&  k<length(omefiles) %move to next OME File
                      TifLink(k).close();
                      j=1;    %reset within-OMEfile directory counter
                      k=k+1;  %increment OMEfile counter

                      if t<numT
                          fprintf('\n'); 
                          disp(['wbloadmovies> loading ' OMEfile{k}]); 
                          TifLink(k) = Tiff(OMEfile{k}, 'r');
                      end
                end

                if (mod(t,100)==0) fprintf('%d..',t); end
            end

            fprintf('%d.\n',t);

            warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
            warning('on','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
            if globalMovieFlag
                assignin('base','ZMovie',ZMovie);
            end

        end

        
end  %main