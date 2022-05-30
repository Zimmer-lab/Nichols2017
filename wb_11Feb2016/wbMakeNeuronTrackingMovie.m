function movieOutName=wbMakeNeuronTrackingMovie(TMIPMovie,blobThreads,blobThreads_sorted,neuronlookup,options)

    if nargin<5
        options=[];
    end
    
    if ~isfield(options,'dataFolder')
        options.dataFolder=pwd;
    end
        
    if nargin<4 || isempty(neuronlookup)
        wbstruct=wbload(options.dataFolder,false);
        neuronlookup=wbstruct.neuronlookup;
    end
    
    if nargin<3  || isempty(blobThreads_sorted)
        blobThreads_sorted=wbstruct.blobThreads_sorted;
    end
    
    if nargin<2  || isempty(blobThreads)
        blobThreads=wbstruct.blobThreads;
    end
    
    if nargin<1  || isempty(TMIPMovie)
        [TMIPMovie,~,~,~]=wbloadTMIPs(pwd,wbstruct.metadata);
    end
    
    numZ=length(TMIPMovie);
    numTW=size(TMIPMovie{1},3);
    height=size(TMIPMovie{1},1);
    width=size(TMIPMovie{1},2);

    nn=length(neuronlookup);

    
    if ~isfield(options,'useSimpleNumbers')
        options.useSimpleNumbers=true;  %add simple numbering if available
    end
    
    
    if ~isfield(options,'showChildrenBlobs')
        options.showChildrenBlobs=true;
    end

    if ~isfield(options,'validZs');
        options.validZs=1:numZ;
    end

    if ~isfield(options,'maxPlotWidth');
        options.maxPlotWidth=3000;
    end

    if ~isfield(options,'intensityRange');
        options.intensityRange=[500 20000];
    end

    if ~isfield(options,'trialName');
        if exist('wbstruct','var')
            options.trialName=wbstruct.trialname;
        else
            options.trialName='';
        end
    end

    if ~isfield(options,'saveDir');
        options.saveDir=[pwd filesep 'Quant'];
    end

    if ~isfield(options,'outputMovieQuality')
       options.outputMovieQuality=100;
    end

    if ~isfield(options,'outputMovieFrameRate')
       options.outputMovieFrameRate=30;
    end

    if options.useSimpleNumbers
        flagstr='-Simple';
    else
        flagstr=[];
    end

    %Make Neuron Tracking movies labeled by brightness plus other used
    %blobs plus global drift
    


    figure('Position',[0 0 min([1.2*numZ*width options.maxPlotWidth]) 1.2*height]);

    %setup output movie directory and files
    movieOutName=[options.saveDir filesep 'NeuronTrackingMovie'  flagstr '-' wbMakeShortTrialname(options.trialName) '.mp4'];
    videoOutObj=wbSetupOutputMovie(movieOutName,options.outputMovieQuality,options.outputMovieFrameRate,[min([1.2*numZ*width options.maxPlotWidth]) 1.2*height]); %external function

   
%   cumDriftX=zeros(numZ,numTW);
%   cumDriftY=zeros(numZ,numTW);
    
    parentColor='g';
    
    if options.showChildrenBlobs
        childColor='b';
    else
        childColor='none';
    end
    
    for tw=1:numTW         
         for z=options.validZs
            subtightplot(1,numZ,z);
            hold off;
            movieZframe=squeeze(TMIPMovie{z}(:,:,tw));
            imagesc(movieZframe,options.intensityRange);
            colormap(hot(256));
            axis off;
            hold on;
            
            
            if options.showChildrenBlobs
            
            
                for n=1:blobThreads_sorted.n
                    if blobThreads_sorted.z(n)==z

                        if blobThreads_sorted.parent(n)==-1;  %this is a parent blob
                            thisColor=parentColor;
                            showFlag=true;

                            if options.useSimpleNumbers && exist('wbstruct','var') && isfield(wbstruct,'simple')

                                neuronNumber=find(blobThreads.parentlist==n);
                                neuronLabel=num2str(find(neuronlookup(wbstruct.simple.nOrig)==neuronNumber));
                                if isempty(neuronLabel)
                                    showFlag=false;
                                end
                            else
                                neuronLabel=num2str(find(neuronlookup==find(blobThreads.parentlist==n)));
                            end

                        else

                            thisColor=childColor;
                            showFlag=true;

                            if ~options.showChildrenBlobs
                                showFlag=false;
                            end

                            try
                                neuronLabel=num2str(find(neuronlookup==find(blobThreads.parentlist==blobThreads_sorted.parent(n))));
                            catch
                                neuronLabel='x';
                            end
                        end   

                        if showFlag

                            %plot all blobThreads (parents and children)
                            plot(blobThreads_sorted.x(tw,n),blobThreads_sorted.y(tw,n),'Marker','+','Color',thisColor);


                            %numerical labels       
                            if  blobThreads_sorted.y(tw,n) < height-20  && (z<numZ ||  blobThreads_sorted.x(tw,n)<width-30)
                               text(blobThreads_sorted.x(tw,n),blobThreads_sorted.y(tw,n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','top');
                            else
                               text(blobThreads_sorted.x(tw,n),blobThreads_sorted.y(tw,n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','bottom','HorizontalAlignment','right');
                            end

                        end

                    end
                end
            
            else
                
                 for n=1:wbstruct.nn
                    if wbstruct.nz(n)==z

                          thisColor=parentColor;
                          showFlag=true;

                          if options.useSimpleNumbers && exist('wbstruct','var') && isfield(wbstruct,'simple')

                             %neuronNumber=find(blobThreads.parentlist==n);
                             neuronLabel=num2str(find(wbstruct.simple.nOrig==n));
                             if isempty(neuronLabel)
                                showFlag=false;
                             end
                          else
                                neuronLabel=num2str(n); %find(neuronlookup==find(blobThreads.parentlist==n)));
                          end


                        if showFlag

                            %plot neurons
                            plot(wbstruct.nx(tw,n),wbstruct.ny(tw,n),'Marker','+','Color',thisColor);


                            %numerical labels       
                            if  wbstruct.ny(tw,n) < height-20  && (z<numZ ||  wbstruct.nx(tw,n) < width-30)
                               text(wbstruct.nx(tw,n),wbstruct.ny(tw,n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','top');
                            else
                               text(wbstruct.nx(tw,n),wbstruct.ny(tw,n),[' ' neuronLabel],'Color',thisColor,'VerticalAlignment','bottom','HorizontalAlignment','right');
                            end

                        end

                    end
                end
                
            end
                              
%             %plot global drift in middle of field
%             if tw==1
%                 ex(width/2,height/2,8,'b');
%             else
%                 cumDriftX(z,tw)=globalDriftX(z,tw)+cumDriftX(z,tw-1);
%                 cumDriftY(z,tw)=globalDriftY(z,tw)+cumDriftY(z,tw-1);
%                 for i=2:tw
%                     ex(width/2+cumDriftX(z,i-1),height/2+cumDriftY(z,i-1),1,'g');
%                 end
%                 ex(width/2+cumDriftX(z,i),height/2+cumDriftY(z,i),8,'b');
%             end
     
        end
        drawnow;    
        %write out video frame
        
        %legacy
%        framestruct=im2frame(png_cdata(gcf),jet(256));
%        writeVideo(videoOutObj,framestruct.cdata);
        
        framestruct=getframe(gcf);
        videoOutObj.addFrame(framestruct.cdata);

    end %for tw
    
    clear videoOutObj;
    %close(videoOutObj);    
    
end %main
    
    