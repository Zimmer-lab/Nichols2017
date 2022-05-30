function wbstruct=wba(folder,options)
%WBA Whole Brain Analyzer
%
%wbstruct = wb(folder,options)
%
%Saul's Whole Brain hyperstack analyzer
%
%leave arguments empty to run on current folder
%
%options:
%.numPixels
%.numPixelsBonded
%.thresholdMargin
%.Rmax
%.sliceWidthMax
%.blobSafetyMargin
%.globalMovieFlag
%.quantFlag
%.blobDetectFlag
%
%runs on a folder already processed by the imageJ plugin
%WholeBrainAnalyzer
%v0.3 20131015 first release shared with others in the lab.
%v0.31 201310310 fix multiple-children in one Z plane issue
%
%
%Saul Kato


%ALGO PARAMETERS
%

if nargin<2 || ~isfield(options,'numPixels')
   numPixels=50;  %max pixel distance between slices
   options.numPixels=numPixels;
else numPixels=options.numPixels; 
end

if nargin<2 || ~isfield(options,'numPixelsBonded')
   numPixelsBonded=100;  %max pixel distance between slices
   options.numPixelsBonded=numPixelsBonded;
else numPixelsBonded=options.numPixelsBonded; 
end

if nargin<2 || ~isfield(options,'thresholdMargin')
   thresholdMargin=500;  %peak finder threshold
   options.thresholdMargin=thresholdMargin;
else thresholdMargin=options.thresholdMargin; 
end

if nargin<2 || ~isfield(options,'Rmax')
   Rmax=7;  %max pixel distance between slices
   options.Rmax=Rmax;
else Rmax=options.Rmax; 
end

if nargin<2 || ~isfield(options,'sliceWidthMax')
   sliceWidthMax=2;  %max number of slice hops that a blob can bond across. 1 corresponds to 3-slice max traversal for a neuron
   options.sliceWidthMax=sliceWidthMax;
else sliceWidthMax=options.sliceWidthMax; 
end

if nargin<2 || ~isfield(options,'blobSafetyMargin')
   blobSafetyMargin=0.75; %extra pixel buffer between adjacent blobs, doesn't have to be an integer
   options.blobSafetyMargin=blobSafetyMargin;
else blobSafetyMargin=options.blobSafetyMargin; 
end

%DO NOT USE THIS FLAG FOR NOW.  wbbatch does not properly treat it.
if nargin<2 || ~isfield(options,'globalMovieFlag')  %use Movie already in workspace for quantification
    options.globalMovieFlag=true;
end
    
if nargin<2 || ~isfield(options,'quantFlag')  %for debugging purposes, skip quantification section
    options.quantFlag=true;
end

if nargin<2 || ~isfield(options,'blobDetectFlag')  %for debugging purposes, skip blob detection section
    options.blobDetectFlag=1;
end

if nargin<2 || ~isfield(options,'maxPlotWidth')  
    options.maxPlotWidth=3000;
end

if nargin<2 || ~isfield(options,'excludePlanes')  
    options.excludePlanes=[];  
end

if nargin<2 || ~isfield(options,'Rbackground')  
    Rbackground=16;   %radius of background subtraction
    options.Rbackground=Rbackground;  
else Rbackground=options.Rbackground;
end
    
if nargin<2 || ~isfield(options,'localTrackingDamping')  
    options.LocalTrackingDamping=1;  
end


%% subplot fn overloading
%
make_it_tight = true;
subplot = @(m,n,p) subtightplot (m, n, p, [0 0], [0 0], [0 0]);
if ~make_it_tight,  clear subplot;  end

%% Load data
%

if nargin<1
    folder=pwd;
end


if nargin<2 || ~isfield(options,'outputFolder')  %for debugging purposes, skip blob detection section
    options.outputFolder=folder;
end

%load metadata file if it exists
if ~isempty(dir([folder '/meta.mat']))
     metadata=load([folder '/meta.mat']);
else
     disp('wb: no meta.mat file in this folder.');
     metadata.fps=3;
     metadata.stimulus=[];
end

if ~isfield(metadata,'stimulus')
    metadata.stimulus=[];
end

metadata

if ~isfield(metadata,'fps')
    disp('wb: no fps field in meta.mat.');
    if ~isfield(metadata,'totalTime')
        disp('wb: no totalTime field in meta.mat. setting fps to 3.');
        metadata.fps=3;
        metadata.totalTime=NaN;
    else
        
        %get number of frames from the length of the first Stabilized
        %ZMovie
        
        if ~exist([folder filesep 'StabilizedZMovies' filesep 'Stabilized_Z1.tif'],'file')
            
            disp('no StabilizedZMovie found.  Quitting.');
            return;
     
        else
        
            numframes=length(imfinfo('StabilizedZMovies/Stabilized_Z1.tif'));
            metadata.fps=numframes/metadata.totalTime;
            disp(['wb: inferring fps from total time: ' num2str(metadata.fps)]);
            
        end
        
    end    
elseif ~isfield(metadata,'totalTime')
    metadata.totalTime=NaN;
end

%load ZMIPS
trialname=folder(max(strfind(folder,'/'))+1:end);
fnames=dir([folder '/ZMIPS/*.tif']);
displayname=strrep(trialname,'_','\_');    
   
if length(fnames)==0
    disp('No ZMIPS folder found.  I need a ZMIPs folder.  Quitting.');
    return;
end


for i=1:length(fnames)
    I(i)=tiffread2([folder '/ZMIPs/' fnames(i).name]);
end
width=I(1).width;
height=I(1).height;

%rotate matrices so nose always points north.  will eventually move this
%to Fiji process.
% if metadata.orientation=='W' || metadata.orientation=='S'
%     %rotate I matrices 180
%     for i=1:length(fnames)
%         I(i).data=rot90(I(i).data,2);
%     end
%     disp('wb: rotating imagedata matrices to follow nose-North convention.');
% end


warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir([options.outputFolder '/Quant']);
warning('on','MATLAB:MKDIR:DirectoryExists');

%% Find and plot blobs
%

if options.blobDetectFlag
    
    figure('Position',[0 0 min([0.9*length(I)*I(1).width options.maxPlotWidth]) I(1).height]);
    MIPMontage=[];
    blobs.x=[];blobs.y=[];blobs.z=[];blobs.FMEDpeak=[];blobs.Mx=[];blobs.My=[];
    blobs.indexDivZ=[];

    
    for i=1:length(I)
        MIPMontage=[MIPMontage I(i).data];

        subplot(1,length(I),i);
        imagesc(I(i).data);
        colormap(hot(256));
        axis off;
        threshold=median(I(i).data(:))+thresholdMargin;
        filt=ones(3,3);
        
%         original FastPeakFind method
%         [cent, cm]=FastPeakFind(I(i).data,threshold,filt);
%         xi=cent(2:2:end); %weird data scheme in FastPeakFind
%         yi=cent(1:2:end);

        %my modified FastPeakFindSK
        
        if ~ismember(i,options.excludePlanes)
            federatedcenters=FastPeakFindSK(I(i).data,threshold,filt,Rmax);
        else
            federatedcenters=[];
        end
        
        if ~isempty(federatedcenters)
            xi=federatedcenters.y';
            yi=federatedcenters.x';
        else
            xi=[];
            yi=[];
        end
        
        hold on;
        plot(xi,yi,'b+')
        blobs.numblobsinZ(i)=length(xi);
        blobs.x=[blobs.x; xi];  
        blobs.y=[blobs.y; yi];
        blobs.z=[blobs.z; i*ones(size(xi))];
        blobs.Mx=[blobs.Mx; xi+(i-1)*size(I(i).data,2)];
        blobs.My=blobs.y;
        blobs.indexDivZ{i}=(1:length(xi))+sum(blobs.numblobsinZ(1:i-1));
        intitle(['Z' num2str(i)]);
    end
    blobs.n=length(blobs.x);

    tightfig;
    save2pdf([options.outputFolder '/Quant/wb-blobcenters.pdf']);

    for b=1:blobs.n
        blobs.FMEDpeak(b,1)=(I(blobs.z(b)).data(blobs.y(b),blobs.x(b)));
    end

    %
    %sort blobs by median brightness
    %

    [blobs_sorted.FMEDpeak blobs.sortorder]= sort(blobs.FMEDpeak,1,'descend');

    for i=1:blobs.n
        blobs.reorder(blobs.sortorder(i))=i;
    end

    blobs_sorted.x=blobs.x(blobs.sortorder);
    blobs_sorted.y=blobs.y(blobs.sortorder);
    blobs_sorted.z=blobs.z(blobs.sortorder);
    blobs_sorted.My=blobs.My(blobs.sortorder);
    blobs_sorted.Mx=blobs.Mx(blobs.sortorder);
    for i=1:length(I)
        if ~numel(blobs.indexDivZ{i})==0
            begindex=blobs.indexDivZ{i}(1);
            endindex=begindex+blobs.numblobsinZ(i)-1;     
            blobs_sorted.indexDivZ{i}=blobs.reorder(begindex:endindex);
        else
            blobs_sorted.indexDivZ{i}=[];
        end
    end

    %compute all interblob pixel distances
    blobs_sorted.distance=zeros(length(blobs_sorted.x),length(blobs_sorted.y));
    for i=1:length(blobs_sorted.x)
        for j=1:(i-1)
            blobs_sorted.distance(i,j)=sqrt((blobs_sorted.x(i)-blobs_sorted.x(j))^2 + (blobs_sorted.y(i)-blobs_sorted.y(j))^2);
            blobs_sorted.distance(j,i)=blobs_sorted.distance(i,j);
        end
    end
    
    %
    %bond blobs (find parents and children)
    %

    Rmax2=Rmax^2; 

    blobs_sorted.parent=zeros(size(blobs_sorted.x));
    blobs_sorted.parent(1)=-1;
    blobs.parentlist=1;
    blobs_sorted.children=cell(2000,1);
   

    %greedy algorithm: start with brightest blob and find all neighboring close blobs
    for b=1:length(blobs_sorted.x);   
        if (blobs_sorted.parent(b)==0)  
            blobs.parentlist=[blobs.parentlist b]; %create a new parent and add it to the list
            
            
            blobs_sorted.parent(b)=-1;  %this denotes a parent
        end

        
        for sw=1:sliceWidthMax  %run through all neighbors
            checkslices=[(blobs_sorted.z(b)-sw)*find((blobs_sorted.z(b)-sw) > 0) ...
                         (blobs_sorted.z(b)+sw)*find(blobs_sorted.z(b)+sw < length(I)+1)];

            for thisslice=checkslices
                    for point=1:blobs.numblobsinZ(thisslice)                  
                        thisblob=blobs.indexDivZ{thisslice}(point);
                        thisblob_sorted=blobs_sorted.indexDivZ{thisslice}(point);

                        if (blobs.x(thisblob)-blobs_sorted.x(b))^2+(blobs.y(thisblob)-blobs_sorted.y(b))^2<=Rmax2
                            
                            %add this blob to children list
                            if (blobs_sorted.parent(thisblob_sorted)==0)
                                blobs_sorted.parent(thisblob_sorted)=b;
                                blobs_sorted.children{b}=[blobs_sorted.children{b} thisblob_sorted];
                            end
                        end
                        
                    end
            end
        end
    end
    
    
    if numel(blobs_sorted.x)==0
        disp('wba> No blobs were found!  Try setting options.thresholdMargin to 0.');
        return;
    end
        
    
    
    %label parent neurons by spatial position
    spatialindex=zeros(size(blobs.parentlist));
    for i=1:length(blobs.parentlist)
        %compute spatial index
        spatialindex(i)=blobs_sorted.x(blobs.parentlist(i))+width*(blobs_sorted.y(blobs.parentlist(i))-1)+width*height*(blobs_sorted.z(blobs.parentlist(i))-1);
    end
    [sortvals neuronlookup]=sort(spatialindex,'ascend');
    nn=length(neuronlookup);

    %plot bonding
    figure('Position',[0 0 min([1.2*length(I)*I(1).width options.maxPlotWidth]) 1.2*I(1).height]);
    imagesc(MIPMontage);
    colormap(hot(256));
    axis off;

    hold on;

    for b=1:length(blobs.parentlist)
        for bb=1:length(blobs_sorted.children{blobs.parentlist(b)})
             line([blobs_sorted.Mx(blobs.parentlist(b)) blobs_sorted.Mx(blobs_sorted.children{blobs.parentlist(b)}(bb))],...
                 [blobs_sorted.My(blobs.parentlist(b)) blobs_sorted.My(blobs_sorted.children{blobs.parentlist(b)}(bb))   ],'Color',color('gray'));
             ex(blobs_sorted.Mx(blobs_sorted.children{blobs.parentlist(b)}(bb)),blobs_sorted.My(blobs_sorted.children{blobs.parentlist(b)}(bb)),4,'g');
        end 
        ex(blobs_sorted.Mx(blobs.parentlist(b)),blobs_sorted.My(blobs.parentlist(b)),8,'g');

    end

    tightfig;
    save2pdf([options.outputFolder '/Quant/wb-bonding.pdf']);

    %
    %plot MIPmontage with numerically labeled neurons
    %

    figure('Position',[0 0 min([1.2*length(I)*I(1).width options.maxPlotWidth]) 1.2*I(1).height]);
    imagesc(MIPMontage);
    colormap(hot(256));
    axis off;
    hold on;
    highlight=[]; %[126 41];

    for b=1:nn  %length(blobs.unsortedparentlist)
        %ex(blobs.Mx(blobs.unsortedparentlist(b)),blobs.My(blobs.unsortedparentlist(b)),4,[0 1 0]);
        %text(blobs.Mx(blobs.unsortedparentlist(b)),blobs.My(blobs.unsortedparentlist(b)),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
        ex(blobs_sorted.Mx(blobs.parentlist(neuronlookup(b))),blobs_sorted.My(blobs.parentlist(neuronlookup(b))),4,[0 1 0]);
        text(blobs_sorted.Mx(blobs.parentlist(neuronlookup(b))),blobs_sorted.My(blobs.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
        for i=1:length(highlight)
            if highlight(i)==b
                ex(blobs_sorted.Mx(blobs.parentlist(b)),blobs_sorted.My(blobs.parentlist(b)),4,[0 1 0]);
                text(blobs_sorted.Mx(blobs.parentlist(b)),blobs_sorted.My(blobs.parentlist(b)),[num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');

                
            end
        end
    end
    tightfig;
    save2pdf([options.outputFolder '/Quant/wb-labeledneurons.pdf']);

    wbstruct.blobs_sorted=blobs_sorted;
    wbstruct.blobs=blobs;

else
    disp('Skipping blob detection. (debug mode)');
    load([folder '/Quant/wbstruct.mat']);
    blobs_sorted=wbstruct.blobs_sorted;
    blobs=wbstruct.blobs;
end

%% Create Masks
%

disp('>making ROI masks...');

% figure('Position',[0 0 1.2*length(I)*I(1).width 1.2*I(1).height]);
% colormap(hot(256));imagesc(MontageMovie(1).data);
% tightfig; axis off; drawnow;

xbound=size(I(1).data,2);  %size(ZMovie{1},2);  %x and y are reversed in imagedata
ybound=size(I(1).data,1);  %size(ZMovie{1},1);  %ZMovies are taller than wide

numZ=length(I);

mastermask=uint16(circularmask(Rmax));
mask=cell(length(blobs_sorted.x),1);
mask_nooverlap=cell(length(blobs_sorted.x),1);
for b=1:length(blobs_sorted.x)
    maskedge_x1=max([1 2+Rmax-blobs_sorted.x(b)]);
    maskedge_y1=max([1 2+Rmax-blobs_sorted.y(b)]);
    maskedge_x2=min([xbound-blobs_sorted.x(b)+Rmax+1  2*Rmax+1]);
    maskedge_y2=min([ybound-blobs_sorted.y(b)+Rmax+1 2*Rmax+1]);   
    mask{b}=mastermask(maskedge_x1:maskedge_x2,maskedge_y1:maskedge_y2);
end

%
%remove overlapping pixels for all masks
%

%create mask buffer with same yx dimension ordering as ZMovies
M=zeros(ybound,xbound,numZ,'uint16');

disp('>mask exclusion (unoptimized version)');
tic
for b=1:length(blobs_sorted.x)

      mask_blit=ones(size(mask{b}),'uint16');
      ulposx=blobs_sorted.x(b)-Rmax;
      ulposy=blobs_sorted.y(b)-Rmax;
      dataedge_x1=max([1 ulposx]);
      dataedge_y1=max([1 ulposy]);
      dataedge_x2=min([xbound ulposx+2*Rmax]);
      dataedge_y2=min([ybound ulposy+2*Rmax]);      
      neighbors=find((blobs_sorted.distance(b,:)>0) .* (blobs_sorted.distance(b,:)<2*Rmax) );
      neighbors(blobs_sorted.z(neighbors)~=blobs_sorted.z(b))=[];
%            h=figure;
%            imagesc(I(blobs_sorted.z(b)).data);hold on;
%            
%            ex(blobs_sorted.x(b),blobs_sorted.y(b),10,'b');
      for n=neighbors
%               figure(h);
%               ex(blobs_sorted.x(n),blobs_sorted.y(n),10,'r');
           b2bvec=[(blobs_sorted.x(b) - blobs_sorted.x(n)) , (blobs_sorted.y(b) - blobs_sorted.y(n))];
           b2bvec=b2bvec/norm(b2bvec);
%               line([blobs_sorted.x(n), blobs_sorted.x(b) ],[blobs_sorted.y(n), blobs_sorted.y(b) ],'Color','g')
          for y= dataedge_y1:dataedge_y2 
              for x= dataedge_x1:dataedge_x2
%                         line([x, blobs_sorted.x(n) ],[y, blobs_sorted.y(n) ],'Color','r')
                    if dot(b2bvec,[x-blobs_sorted.x(n) y-blobs_sorted.y(n) ]) < (blobs_sorted.distance(b,n)/2 + blobSafetyMargin)
                        mask_blit(x-dataedge_x1+1,y-dataedge_y1+1)=0;
                    end;  
              end
          end

      end  

      mask_nooverlap{b}=mask{b}.*mask_blit;


      if (mod(b,100)==0) fprintf([num2str(b) '...']); end
      
      %fill mask buffer
      M(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,blobs_sorted.z(b))=M(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,blobs_sorted.z(b))+b*mask_nooverlap{b}';
    

end

toc

%
%create background mask
%

disp('>background mask creation');
tic

background.mastermask=uint16(circularmask(Rbackground));
background.mask=cell(length(blobs_sorted.x),1);
%crop masks overlapping image edge
for b=1:length(blobs_sorted.x)
    
    %mask coordinates
    background.maskedge_x1=max([1 2+Rbackground-blobs_sorted.x(b)]);
    background.maskedge_y1=max([1 2+Rbackground-blobs_sorted.y(b)]);
    background.maskedge_x2=min([xbound-blobs_sorted.x(b)+Rbackground+1  2*Rbackground+1]);
    background.maskedge_y2=min([ybound-blobs_sorted.y(b)+Rbackground+1 2*Rbackground+1]);   
    
    %absolute image coordinates
    background.ulposx=blobs_sorted.x(b)-Rbackground;
    background.ulposy=blobs_sorted.y(b)-Rbackground;
    background.dataedge_x1=max([1 background.ulposx]);
    background.dataedge_y1=max([1 background.ulposy]);
    background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
    background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]); 
    
    
    
    %blit edge-cropped round mastermask with extracted edge-cropped rectangle from binarized buffer
    background.mask{b}=background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)'   .* ...
        uint16(M(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,blobs_sorted.z(b))==0);
    
   
end
toc

%
%write out neuron position and label data
%
wbstruct.nn=nn;
wbstruct.neuronlookup=neuronlookup;
wbstruct.nx=blobs_sorted.x(blobs.parentlist(neuronlookup));
wbstruct.ny=blobs_sorted.y(blobs.parentlist(neuronlookup));
wbstruct.nz=blobs_sorted.z(blobs.parentlist(neuronlookup));




%% Load movies
%

if (options.quantFlag)
    
    maindir=folder;
    zmoviefiles=dir( [folder '/StabilizedZMovies/*.tif']);

    %using new Tif library for loading
    if options.globalMovieFlag && evalin('base','exist(''ZMovie'',''var'')==1');
        disp('>using ZMovie already in workspace.');
        ZMovie=evalin('base', 'ZMovie');
        if size(ZMovie{1},1)~=size(I(1).data,1) || size(ZMovie{1},2)~=size(I(1).data,2)
            disp('Zmovie dimensions do not match other data.  Please clear. Quitting.');
            return;
        end
           
    else       
        disp('>loading Zmovies...'); 
        tic
        warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
        warning('off','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
        for z=1:length(zmoviefiles)
            fprintf('%d...',z-1); 
            FileTif=[folder '/StabilizedZMovies/' zmoviefiles(z).name];
            InfoImage=imfinfo(FileTif);
            mImage=InfoImage(1).Width;
            nImage=InfoImage(1).Height;
            NumberImages=length(InfoImage);
            ZMovie{z}=zeros(nImage,mImage,NumberImages,'uint16');
            TifLink = Tiff(FileTif, 'r');
            for i=1:NumberImages   
                TifLink.setDirectory(i);   
                ZMovie{z}(:,:,i)=TifLink.read();
            end
            TifLink.close();
        end
        

        fprintf('%d.\n',z);
        warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
        warning('on','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
        if options.globalMovieFlag
            assignin('base','ZMovie',ZMovie);
            %this will be screwed up by auto-rotator, so I should fix
        end
        toc
    end


    %% Quantify Movies
    %
    %
   
    disp('>quantifying ZMovies...');

    
    f_parents=zeros(length(ZMovie),length(blobs.parentlist));
    f_bonded=zeros(length(ZMovie),length(blobs.parentlist));
    f_background=zeros(length(ZMovie),length(blobs.parentlist));
  
    nolocaltracking.f_parents=zeros(length(ZMovie),length(blobs.parentlist));
    nolocaltracking.f_bonded=zeros(length(ZMovie),length(blobs.parentlist));
    nolocaltracking.f_background=zeros(length(ZMovie),length(blobs.parentlist));
    
    centroidDeltaX=zeros(1,nn);
    centroidDeltaY=zeros(1,nn);
    deltaDeltaX=zeros(1,nn);
    deltaDeltaY=zeros(1,nn);
    
    tic
    for frame=1:size(ZMovie{1},3);

 
       for b=1:nn 
 
           
          ulposx=blobs_sorted.x(blobs.parentlist(b))-Rmax;
          ulposy=blobs_sorted.y(blobs.parentlist(b))-Rmax;
          dataedge_x1=max([1 ulposx]);
          dataedge_y1=max([1 ulposy]);
          dataedge_x2=min([xbound ulposx+2*Rmax]);
          dataedge_y2=min([ybound ulposy+2*Rmax]);

          %count pixels within mask [NLT]
          nolocaltracking.cropframe=ZMovie{blobs_sorted.z(blobs.parentlist(b))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
          nolocaltracking.cropframe_masked=(mask_nooverlap{blobs.parentlist(b)}').*nolocaltracking.cropframe;
          nolocaltracking.allquantpixels=nolocaltracking.cropframe_masked(:);            
          
          [nolocaltracking.vals, ~]=sort(nolocaltracking.cropframe_masked(:),'descend');  %sort pixels by brightness          
          nolocaltracking.f_parents(frame,b)=mean(nolocaltracking.vals(1:numPixels));  %take the mean of the brightest pixels      

          
%           frame
%           b
%           blobs.parentlist(b)
%           blobs_sorted.z(blobs.parentlist(b))
%           centroidDeltaY(b)
%           dataedge_y1
%           dataedge_y2
%           centroidDeltaX(b)
%           dataedge_x1
%           dataedge_x2
%           size(ZMovie{blobs_sorted.z(blobs.parentlist(b))})
          
          %count pixels within mask [LT]
          %cropframe=ZMovie{blobs_sorted.z(blobs.parentlist(b))}( round(centroidDeltaY(b)) + (dataedge_y1:dataedge_y2), round(centroidDeltaX(b)) + (dataedge_x1:dataedge_x2) ,frame);
          cropframe=ZMovie{blobs_sorted.z(blobs.parentlist(b))}( (dataedge_y1:dataedge_y2),  (dataedge_x1:dataedge_x2) ,frame);

          cropframe_masked=(mask_nooverlap{blobs.parentlist(b)}').*cropframe;      
          allquantpixels=cropframe_masked(:);
          
          [vals, ~]=sort(cropframe_masked(:),'descend');  %sort pixels by brightness          
          f_parents(frame,b)=mean(vals(1:numPixels));  %take the mean of the brightest pixels      


          %background subtraction,just parent frame for now
          background.ulposx=blobs_sorted.x(blobs.parentlist(b))-Rbackground;
          background.ulposy=blobs_sorted.y(blobs.parentlist(b))-Rbackground;
          background.dataedge_x1=max([1 background.ulposx]);
          background.dataedge_y1=max([1 background.ulposy]);
          background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
          background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]);

          % count background pixels [NLT]
          nolocaltracking.background.cropframe=ZMovie{blobs_sorted.z(blobs.parentlist(b))}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);   
          nolocaltracking.background.cropframe_masked=(background.mask{blobs.parentlist(b)}).*nolocaltracking.background.cropframe;          
          [nolocaltracking.background.vals, ~]=sort(nolocaltracking.background.cropframe_masked(:),'descend');  %sort pixels by brightness
          nolocaltracking.f_background(frame,b)=mean(nolocaltracking.background.vals);  %take the mean of all background pixels      

          % count background pixels [LT]
% if (round(centroidDeltaY(b)) + (background.dataedge_y1)==1) disp('1Y'); disp(num2str(b)); end
% if (round(centroidDeltaX(b)) + (background.dataedge_x1)==1) disp('1X'); disp(num2str(b)); end

          background.cropframe=ZMovie{blobs_sorted.z(blobs.parentlist(b))}( (background.dataedge_y1:background.dataedge_y2), (background.dataedge_x1:background.dataedge_x2),frame);   
          background.cropframe_masked=(background.mask{blobs.parentlist(b)}).*background.cropframe; 
          
          [background.vals, ~]=sort(background.cropframe_masked(:),'descend');  %sort pixels by brightness
          f_background(frame,b)=mean(background.vals);  %take the mean of all background pixels      
          
          
          %quantify children+parent

          for bb=1:length(blobs_sorted.children{blobs.parentlist(b)}) %quantify multi  
               ulposx=blobs_sorted.x(blobs_sorted.children{blobs.parentlist(b)}(bb))-Rmax;
               ulposy=blobs_sorted.y(blobs_sorted.children{blobs.parentlist(b)}(bb))-Rmax;
               dataedge_x1=max([1 ulposx]);
               dataedge_y1=max([1 ulposy]);
               dataedge_x2=min([xbound ulposx+2*Rmax]);
               dataedge_y2=min([ybound ulposy+2*Rmax]);
                
               %NLT
               nolocaltracking.cropframechild=ZMovie{blobs_sorted.z(blobs_sorted.children{blobs.parentlist(b)}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
               nolocaltracking.cropframe_add=(mask_nooverlap{blobs_sorted.children{blobs.parentlist(b)}(bb)}').*nolocaltracking.cropframechild;
               nolocaltracking.allquantpixels=[nolocaltracking.allquantpixels; nolocaltracking.cropframe_add(:)]; 
               
               %LT
               cropframechild=ZMovie{blobs_sorted.z(blobs_sorted.children{blobs.parentlist(b)}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
               cropframe_add=(mask_nooverlap{blobs_sorted.children{blobs.parentlist(b)}(bb)}').*nolocaltracking.cropframechild;
               allquantpixels=[allquantpixels; cropframe_add(:)]; 
               
               
          end

          %NLT
          [nolocaltracking.vals, ~]=sort(nolocaltracking.allquantpixels,'descend');  %sort pixels by brightness
          nolocaltracking.f_bonded(frame,b)=mean(nolocaltracking.vals(1:numPixelsBonded));
          
          %LT
          [vals, ~]=sort(allquantpixels,'descend');  %sort pixels by brightness
          f_bonded(frame,b)=mean(vals(1:numPixelsBonded));
          
          
          %compute centroid of brightest pix for local tracking testing
          


          [deltaDeltaX(b),deltaDeltaY(b)]=computeCentroidShift(cropframe');

          deltaDeltaX(b)= [deltaDeltaX(b)];
          deltaDeltaY(b)= [deltaDeltaY(b)];
          
          maxDrift=Rbackground/2;
          maxDriftVel=1;
          
          

          
          centroidDeltaX(b)=max([-maxDrift min([centroidDeltaX(b)+(1-options.LocalTrackingDamping)*deltaDeltaX(b)  maxDrift])]); 
          centroidDeltaY(b)=max([-maxDrift min([centroidDeltaY(b)+(1-options.LocalTrackingDamping)*deltaDeltaY(b)  maxDrift])]); 

          %don't drift past the edge.
          centroidDeltaY(b) = max([centroidDeltaY(b) , 1-dataedge_y1]);
          centroidDeltaY(b) = min([centroidDeltaY(b) , height - dataedge_y2 ]);
          
          centroidDeltaX(b) = max([centroidDeltaX(b), 1-dataedge_x1 ]);
          centroidDeltaX(b) = min([centroidDeltaX(b), height-dataedge_x2  ]);
              
              
       end  
       
       if (mod(frame,100)==0) fprintf('%d...',frame); end
       
       
       
       
       
       
    end
    fprintf('%d.\n',frame);
    toc
    
    nolocaltracking.deltaFOverFNoBackSub=zeros(size(nolocaltracking.f_parents));
    nolocaltracking.deltaFOverF=zeros(size(nolocaltracking.f_parents));
    
    deltaFOverFNoBackSub=zeros(size(nolocaltracking.f_parents));
    deltaFOverF=zeros(size(nolocaltracking.f_parents));
    
    
    for i=1:nn
        nolocaltracking.deltaFOverFNoBackSub(:,i)=nolocaltracking.f_bonded(:,neuronlookup(i))/mean(nolocaltracking.f_bonded(:,neuronlookup(i)))-1;
        nolocaltracking.deltaFOverF(:,i)=(nolocaltracking.f_bonded(:,neuronlookup(i))-nolocaltracking.f_background(:,neuronlookup(i)))/mean(nolocaltracking.f_bonded(:,neuronlookup(i))-nolocaltracking.f_background(:,neuronlookup(i)))-1;
      
        deltaFOverFNoBackSub(:,i)=f_bonded(:,neuronlookup(i))/mean(f_bonded(:,neuronlookup(i)))-1;
        deltaFOverF(:,i)=(f_bonded(:,neuronlookup(i))-f_background(:,neuronlookup(i)))/mean(f_bonded(:,neuronlookup(i))-f_background(:,neuronlookup(i)))-1;
        
    end
    figure;
    imagesc(deltaFOverF');
    tightfig;
    export_fig([options.outputFolder '/Quant/heatmap-' trialname '.pdf'],'-a1');
    

    %write out quantification process data
    wbstruct.f_parents=f_parents;
    
    wbstruct.f_bonded=f_bonded; 
    wbstruct.f_background=f_background;
    
    wbstruct.mask=mask;
    wbstruct.mask_nooverlap=mask_nooverlap;
    wbstruct.mask_background=background.mask;
    wbstruct.numZ=length(blobs.indexDivZ);
    wbstruct.M=M;
    wbstruct.deltaFOverF=deltaFOverF;
    wbstruct.deltaFOverFNoBackSub=deltaFOverFNoBackSub;
    
    wbstruct.nolocaltracking=nolocaltracking;
    
    wbstruct.fps=metadata.fps;
    wbstruct.stimulus=metadata.stimulus;
    wbstruct.totalTime=metadata.totalTime;

    wbstruct.tv=(0:(size(ZMovie{1},3)-1))/wbstruct.fps;
    wbstruct.trialname=trialname;
    wbstruct.displayname=displayname;

    wbstruct.options=options;
    wbstruct.dateRan=datestr(now);
    
    options.fieldName2='deltaFOverFNoBackSub';
    wbgridplot(wbstruct,options);

    
end %quantFlag


save([options.outputFolder '/Quant/wbstruct.mat'],'wbstruct');
save([options.outputFolder '/Quant/wbstruct-r' num2str(options.Rmax) '-p' num2str(options.numPixels)  '-pb' num2str(options.numPixelsBonded)  '-th' num2str(options.thresholdMargin) '-sm' num2str(options.blobSafetyMargin) '-sl' num2str(options.sliceWidthMax) '-' strrep(strrep(datestr(now),':','-'),' ','-') '.mat'],'wbstruct');

options.saveDir=[options.outputFolder '/Quant'];


    %nested functions
    
    function [deltaX,deltaY]=computeCentroidShift(imageData)
        
          %make centroid masks
          [xCentroidMask, yCentroidMask]=centroidmask(size(imageData));

          fullArea=sum(imageData(:));              
          deltaX=-sum(sum(double(imageData).*xCentroidMask))/fullArea;    
          deltaY=-sum(sum(double(imageData).*yCentroidMask))/fullArea;

    end

end %function
