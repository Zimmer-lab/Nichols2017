function wbstruct=wba2(folder,options)
%WBA Whole Brain Analyzer
%
%V2 with deformation analysis
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
timeMotionSmoothingWindow=100; %in frames
maxTemporalBindingDistance=5;  %in pixels
minThreadLength=22; 


%DEBUG FLAGS
%wbbatch does not handle this flag now
if nargin<2 || ~isfield(options,'globalMovieFlag')  %use Movie already in workspace for quantification
    options.globalMovieFlag=true;
end

if nargin<2 || ~isfield(options,'blobDetectFlag')  %for debugging purposes, skip blob detection section
    options.blobDetectFlag=true;
end

if nargin<2 || ~isfield(options,'createMasksFlag')  %for debugging purposes, skip quantification section
    options.createMasksFlag=true;
end

if nargin<2 || ~isfield(options,'quantFlag')  %for debugging purposes, skip quantification section
    options.quantFlag=true;
end

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
   blobSafetyMargin=0.5; %extra pixel buffer between adjacent blobs, doesn't have to be an integer
   options.blobSafetyMargin=blobSafetyMargin;
else blobSafetyMargin=options.blobSafetyMargin; 
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
    options.LocalTrackingDamping=0.2;  
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

if ~isfield(metadata,'fps')
    disp('wb: no fps field in meta.mat.');
    if ~isfield(metadata,'totalTime')
        disp('wb: no totalTime field in meta.mat. setting fps to 3.');
        metadata.fps=3;
        metadata.totalTime=NaN;
    else
        %get number of frames from number of tifs in Montages folder
        numframes=length(dir([folder '/Montages/*.tif']));
        metadata.fps=numframes/metadata.totalTime;
        disp(['wb: inferring fps from total time: ' num2str(metadata.fps)]);
    end    
elseif ~isfield(metadata,'totalTime')
    metadata.totalTime=NaN;
end

trialname=folder(max(strfind(folder,'/'))+1:end);
displayname=strrep(trialname,'_','\_');

%load ZMIPS
% disp('>loading ZMIPs...'); 
% fnames=dir([folder '/ZMIPS/*.tif']);    
% for i=1:length(fnames)
%     I(i)=tiffread2([folder '/ZMIPs/' fnames(i).name]);
% end
% width=I(1).width;
% height=I(1).height;


%load TMIPS

zmoviefiles=dir( [folder '/SmoothStabZMovies/*.tif']);
      
disp('>loading SmoothStabZmovies...'); 
tic
warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
warning('off','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
for z=1:length(zmoviefiles)
    fprintf('%d...',z-1); 
    FileTif=[folder '/SmoothStabZMovies/' zmoviefiles(z).name];
    InfoImage=imfinfo(FileTif);
    mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    NumberImages=length(InfoImage);
    SmoothStabZMovie{z}=zeros(nImage,mImage,NumberImages,'uint16');
    TifLink = Tiff(FileTif, 'r');
    for i=1:NumberImages   
        TifLink.setDirectory(i);   
        SmoothStabZMovie{z}(:,:,i)=TifLink.read();
    end
    TifLink.close();
end

width=InfoImage(1).Width
height=InfoImage(1).Height
numZ=length(SmoothStabZMovie);


warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
warning('on','MATLAB:tifflib:TIFFReadDirectory:libraryWarning');
toc

%%Make montage of first smoothed frame
MontageFrame1=[];
for z=1:length(zmoviefiles)
    MontageFrame1=[MontageFrame1 squeeze(SmoothStabZMovie{z}(:,:,1))];
end

numT=size(SmoothStabZMovie{1},3);
numZ=length(SmoothStabZMovie);


%% Make Quant folder

warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir([options.outputFolder '/Quant']);
warning('on','MATLAB:MKDIR:DirectoryExists');

%% Find and plot blobs
%



if options.blobDetectFlag

    
    
    %
    % find blobs-in-time (TMIP blobs)
    %
    disp('finding blobs in timespace.');
    tic



    for z=1:numZ
        
        for t=1:numT
            
            frame=squeeze(SmoothStabZMovie{z}(:,:,t));
            threshold=median(frame(:))+thresholdMargin;
            filt=ones(1,1);
            
            federatedcenters=FastPeakFindSK(squeeze(SmoothStabZMovie{z}(:,:,t)),threshold,filt,Rmax-1,5);
        
            if ~isempty(federatedcenters)
                xi=federatedcenters.y';
                yi=federatedcenters.x';
            else
                xi=[];
                yi=[];
            end
            
            tblobs(z,t).x=xi;  
            tblobs(z,t).y=yi;
            tblobs(z,t).Tx=xi+(t-1)*size(SmoothStabZMovie{z},2);
            tblobs(z,t).Ty=yi;

%         blobs(i).indexDivZ{i}=(1:length(xi))+sum(blobs(i).numblobsinZ(1:i-1));
     
            tblobs(z,t).n=length(tblobs(z,t).x);
    
        end
        
    end
        
    %
    % clean up blob timelines
    %
    disp(['connecting tblobs and pruning Threads.']);
    for z=1:numZ
        
        %%find nearest neighbors one time step ago
        tblobs(z,1).tparents=zeros(tblobs(z,t).n,1);
        tblobs(z,1).mindist=zeros(tblobs(z,t).n,1);

        for t=2:numT
            tblobs(z,t).tparents=zeros(tblobs(z,t).n,1);
            tblobs(z,t).mindist=zeros(tblobs(z,t).n,1);
            
            for j=1:tblobs(z,t).n
                
                dist=zeros(tblobs(z,t-1).n,1);
                
                %compute distance to every blob in the last time step in
                %the same z slice
                
                for k=1:tblobs(z,t-1).n
                    dist(k)=sqrt((tblobs(z,t).x(j)-tblobs(z,t-1).x(k)).^2+...
                        (tblobs(z,t).y(j)-tblobs(z,t-1).y(k)).^2);
                end
                
                if min(dist)<maxTemporalBindingDistance
                    [tblobs(z,t).mindist(j) tblobs(z,t).tparents(j)]=min(dist);  %make a parent link
                else
                    tblobs(z,t).tparents(j)=NaN;  %create an orphan
                    tblobs(z,t).parentlessTag(j)=2;
                    tblobs(z,t).mindist(j)=Inf;
                end
            end
        end

        %%remove pointback vectors that point to same parent, mark them with NaNs
        tblobs(z,1).parentlessTag=ones(tblobs(z,1).n,1);  %all t=1 tblobs have no parents
        tblobs(z,1).markedForDeath=zeros(tblobs(z,1).n,1);
        
        for t=2:numT
            tblobs(z,t).parentlessTag=zeros(tblobs(z,t).n,1);   
            tblobs(z,t).markedForDeath=zeros(tblobs(z,t).n,1);    
            for j=1:tblobs(z,t).n
                matches=ismember(tblobs(z,t).tparents,tblobs(z,t).tparents(j));
                if sum(matches)>1
          %     disp(['double detected for ' num2str(j)])
                    matchindices=find(matches);
                    [~,nearestmatch]=min(tblobs(z,t).mindist(matches));
                    matchindices(nearestmatch)=[]; %dont kill the link that is shortest
                    tblobs(z,t).tparents(matchindices)=NaN;   %but kill all others.
                    tblobs(z,t).parentlessTag(matchindices)=1;
                end
            end
        end
        
        %now that there are no parents with multiple children we can assign
        %children to blobs to make a doubly linked list
        
        for t=2:numT
            tblobs(z,t-1).child=zeros(size(tblobs(z,t-1).x));
        end
        
        for t=2:numT
           
           for j=1:tblobs(z,t).n
                if ~isnan( tblobs(z,t).tparents(j) )
                    tblobs(z,t-1).tchild( tblobs(z,t).tparents(j) ) = j;  %doubly linked list
                end
           end
        end
        
        %moved this up.
        %%break nearest-neighbor temporal links that are too long
%         for t=2:numT
%             for j=1:tblobs(z,t).n;
%                 if tblobs(z,t).mindist(j) > maxTemporalBindingDistance
%                     %disp(['distant neighbor found at t' num2str(t) ', neuron ' num2str(j)]);
% 
%                     tblobs(z,t).tparents(j)=NaN;  %create an orphan
%                     tblobs(z,t).parentlessTag(j)=2;
%                     
%                 end
%             end
%         end


        %%tag childless blobs

        for t=2:numT
            tblobs(z,t-1).childlessTag=zeros(tblobs(z,t-1).n,1);    
            for j=1:tblobs(z,t-1).n
                if ~sum(ismember(tblobs(z,t).tparents,j))
                    %disp([num2str(j) ' in slice ' num2str(t-1) ' is childless.']);
                    tblobs(z,t-1).childlessTag(j)=1;
                end
            end
        end
        tblobs(z,t).childlessTag=ones(tblobs(z,t).n,1);  %all t=end tlobs have no children
        
        %%kill isolated blobs
        killIsolatedBlobs=1;
        if killIsolatedBlobs
 
            for t=1:numT 
                for j=1:tblobs(z,t).n
                    tblobs(z,t).markedForDeath(tblobs(z,t).childlessTag>0 & tblobs(z,t).parentlessTag>0)=1;
                end
            end

        end
            
    end
    toc
    
    %plot blob movie
    
    %
    warning('off','MATLAB:MKDIR:DirectoryExists');
    mkdir([options.outputFolder filesep 'Quant' filesep 'BlobtrackingMovie']);
    warning('on','MATLAB:MKDIR:DirectoryExists');

    figure('Position',[0 0 min([1.1*numZ*width options.maxPlotWidth]) 1.1*height]);
    for t=1:22
        
        for z=1:numZ
            subtightplot(1,numZ,z,[.005 .005]);
            hold off;
            movieZframe=squeeze(SmoothStabZMovie{z}(:,:,t));
            chigh=max(movieZframe(:));
            clow=min(movieZframe(movieZframe>0));
            imagesc(squeeze(SmoothStabZMovie{z}(:,:,t)),[clow chigh]);
 
            colormap(hot(256));
            axis off;
            hold on;
            for j=1:tblobs(z,t).n
                plot(tblobs(z,t).x(j),tblobs(z,t).y(j),'g+');
            end
        end
        drawnow;
        export_fig([options.outputFolder '/Quant/BlobtrackingMovie/wb-blobTHREADS-t' num2str(t)],'-tif','-a1');
       % save2pdf([options.outputFolder '/Quant/BlobtrackingMovie/wb-blobTHREADS-t' num2str(t) '.pdf']);

    end 
    
    %
    % make Blob threads
    %
    % all parentless blobs start a thread, so this is easy, just count them up

    blobThreads=[];
    k=1;
    for z=1:numZ
        for t=1:numT
            for j=1:tblobs(z,t).n
                if tblobs(z,t).parentlessTag(j)
                    blobThreads.z(k)=z;
                    blobThreads.t(k)=t;
                    blobThreads.j(k)=j;
                    blobThreads.x0(k)=tblobs(z,t).x(j);  %starting x pos
                    blobThreads.y0(k)=tblobs(z,t).y(j);  %starting y pos
                    blobThreads.Mx0(k)=blobThreads.x0(k)+(z-1)*width;
                    blobThreads.My0(k)=blobThreads.y0(k);
 
                    k=k+1;
                end
            end
        end
    end

    %compute length of all blobThreads by walking down chain.  and kill single blobs
    for i=1:length(blobThreads.z)
        blobThreads.length(i)=1;
        thisblob_t=blobThreads.t(i);
        thisblob_z=blobThreads.z(i);
        thisblob_j=blobThreads.j(i);
        blobThreads.jSequence{i}=thisblob_j;
        markedForDeath(i)=tblobs(thisblob_z,thisblob_t).markedForDeath(thisblob_j);
        

        while ~tblobs(thisblob_z,thisblob_t).childlessTag(thisblob_j);
             thisblob_j=tblobs(thisblob_z,thisblob_t).tchild(thisblob_j);

             thisblob_t=thisblob_t+1;
             blobThreads.length(i)=blobThreads.length(i)+1;
             blobThreads.jSequence{i}=[blobThreads.jSequence{i} thisblob_j];
        end  
    end

    blobThreads.n=length(blobThreads.length);
    
    
    
    disp(['culling lone blobs.']);

    blobThreads.length(logical(markedForDeath))=[];
    blobThreads.z(logical(markedForDeath))=[];
    blobThreads.t(logical(markedForDeath))=[];
    blobThreads.x0(logical(markedForDeath))=[];  %starting x pos
    blobThreads.y0(logical(markedForDeath))=[];  %starting y pos
    blobThreads.j(logical(markedForDeath))=[];
    blobThreads.Mx0(logical(markedForDeath))=[];
    blobThreads.My0(logical(markedForDeath))=[];
    blobThreads.jSequence(logical(markedForDeath))=[];
    
    blobThreads.n=length(blobThreads.length);

    %FOR NOW, kill blobThreads that aren't full time length

    
    disp(['culling short BlobThreads < ' num2str(minThreadLength) '.']);

    blobThreads.z(blobThreads.length<minThreadLength)=[];
    blobThreads.t(blobThreads.length<minThreadLength)=[];
    blobThreads.j(blobThreads.length<minThreadLength)=[];
    blobThreads.jSequence(blobThreads.length<minThreadLength)=[];
    blobThreads.x0(blobThreads.length<minThreadLength)=[];  %starting x pos
    blobThreads.y0(blobThreads.length<minThreadLength)=[];  %starting y pos
    blobThreads.Mx0(blobThreads.length<minThreadLength)=[];
    blobThreads.My0(blobThreads.length<minThreadLength)=[];
    
    blobThreads.length(blobThreads.length<minThreadLength)=[];
    blobThreads.n=length(blobThreads.length);
%     

    %compute brightness for tblobs and blobThreads
    for z=1:numZ
        for t=1:numT
            for j=1:tblobs(z,t).n
                tblobs(z,t).TMIPval(j)=SmoothStabZMovie{z}(tblobs(z,t).y(j),tblobs(z,t).x(j),1);  %brightness in frame 1
            end
        end
    end


    for i=1:blobThreads.n

%        blobThreads.avgPeak(i)=0;
%         for len=1:blobThreads.length(i)
%                blobThreads.avgPeak(i)=blobThreads.avgPeak(i)+tblobs(blobThreads.z(i),blobThreads.t(i)+len-1).TMIPval(blobThreads.jSequence{i}(len));
%         end
%        blobThreads.avgPeak(i)=blobThreads.avgPeak(i)/len;

        %try just frame 1 brightness for now
        blobThreads.avgPeak(i)=tblobs(  blobThreads.z(i)  , blobThreads.t(i) ).TMIPval( blobThreads.j(i) );

    end

    %
    %sort blobThreads by median brightness and save out reverse order
    %

    [blobThreads_sorted.avgPeak blobThreads.sortorder]=sort(blobThreads.avgPeak,2,'descend');
    
    for i=1:blobThreads.n
             blobThreads.revorder(blobThreads.sortorder(i))=i;
    end

    blobThreads_sorted.z=blobThreads.z(blobThreads.sortorder);
    blobThreads_sorted.t=blobThreads.t(blobThreads.sortorder);    
    blobThreads_sorted.j=blobThreads.j(blobThreads.sortorder);
    blobThreads_sorted.length=blobThreads.length(blobThreads.sortorder);
    blobThreads_sorted.jSequence=blobThreads.jSequence(blobThreads.sortorder);
    blobThreads_sorted.n=blobThreads.n;
    blobThreads_sorted.x0=blobThreads.x0(blobThreads.sortorder);  %starting x pos
    blobThreads_sorted.y0=blobThreads.y0(blobThreads.sortorder);  %starting y pos
    blobThreads_sorted.Mx0=blobThreads.Mx0(blobThreads.sortorder);
    blobThreads_sorted.My0=blobThreads.My0(blobThreads.sortorder);
    
    assignin('base','tblobs',tblobs);
    assignin('base','blobThreads',blobThreads);
    assignin('base','blobThreads_sorted',blobThreads_sorted);
    
    %compute all inter blobThread time-averaged pixel distances computed
    %for overlapping time slices
    %THIS IS NOT CURRENTLY VERIFIED AND NOT USED.  WHere are the Nans coming from?
     blobThreads_sorted.distance=zeros(blobThreads_sorted.n);
     for i=1:blobThreads_sorted.n
         for j=1:(i-1)

              %compute overlapping times
              tOccupancyI=zeros(numT,1);
              tOccupancyJ=zeros(numT,1);
              tOccupancyI(blobThreads_sorted.t(i):blobThreads_sorted.t(i)+blobThreads_sorted.length(i)-1)=1;
              tOccupancyJ(blobThreads_sorted.t(j):blobThreads_sorted.t(j)+blobThreads_sorted.length(j)-1)=1;
              
              tOccupancyBoth=tOccupancyI & tOccupancyJ;
              
              %compute average distance across those overlapping times
              blobThreads_sorted.distance(i,j)=0;
              for k=blobThreads_sorted.t(i):blobThreads_sorted.t(i)+blobThreads_sorted.length(i)-1
                  if tOccupancyBoth(k)
                      thisZi=blobThreads_sorted.z(i);
                      thisZj=blobThreads_sorted.z(j);
                      thisJi=blobThreads_sorted.jSequence{i}(k-blobThreads_sorted.t(i)+1);
                      thisJj=blobThreads_sorted.jSequence{j}(k-blobThreads_sorted.t(j)+1);
                      
                      blobThreads_sorted.distance(i,j)=blobThreads_sorted.distance(i,j)+...
                         sqrt( (tblobs(thisZi,k ).x(thisJi) -  tblobs(thisZj,k ).x(thisJj)  )^2  + ...
                               (tblobs(thisZi,k ).y(thisJi) -  tblobs(thisZj,k ).y(thisJj)  )^2 );
                  end
              end
              
              %no overlap in time gets an Inf distance
              
              blobThreads_sorted.distance(i,j)=blobThreads_sorted.distance(i,j)/sum(tOccupancyBoth(k));
              blobThreads_sorted.distance(j,i)=blobThreads_sorted.distance(i,j);
         end
     end
%     
    %
    %bond blobThreads (find spatial parents and children)
    %

    Rmax2=Rmax^2; 

    blobThreads_sorted.parent=zeros(1,blobThreads_sorted.n);
    blobThreads_sorted.parent(1)=-1;
    blobThreads.parentlist=1;
    blobThreads_sorted.children=cell(5000,1);
   

    %greedy algorithm: start with brightest blob and find all neighboring close blobs
    for b=1:blobThreads_sorted.n;   
        if (blobThreads_sorted.parent(b)==0)  
            blobThreads.parentlist=[blobThreads.parentlist b]; %create a new parent and add it to the list
            
            blobThreads_sorted.parent(b)=-1;  %this denotes a parent
        end

        
        for sw=1:sliceWidthMax  %run through all neighbors
            checkslices=[(blobThreads_sorted.z(b)-sw)*find((blobThreads_sorted.z(b)-sw) > 0) ...
                         (blobThreads_sorted.z(b)+sw)*find(blobThreads_sorted.z(b)+sw < numZ+1)];

                    

            for thisslice=checkslices
                    numPointsToCheck=sum(blobThreads.z==thisslice);
                    PointIndicesToCheck=find(blobThreads.z==thisslice);
                    PointIndicesToCheck_sorted=find(blobThreads_sorted.z==thisslice);
                    
                 
                    
                    for point=1:numPointsToCheck               
                        thisblobThread=PointIndicesToCheck(point);
                        thisblobThread_sorted=PointIndicesToCheck_sorted(point);
%                        if (blobThreads.x0(thisblobThread)-blobThreads_sorted.x0(b))^2+(blobThreads.y0(thisblobThread)-blobThreads_sorted.y0(b))^2<=Rmax2

                        if (blobThreads_sorted.x0(thisblobThread_sorted)-blobThreads_sorted.x0(b))^2+(blobThreads_sorted.y0(thisblobThread_sorted)-blobThreads_sorted.y0(b))^2<=Rmax2

                            %add this blob to children list
                            if (blobThreads_sorted.parent(thisblobThread_sorted)==0)
                                blobThreads_sorted.parent(thisblobThread_sorted)=b;
                                blobThreads_sorted.children{b}=[blobThreads_sorted.children{b} thisblobThread_sorted];
                            end
                        end
                        
                    end
            end
        end         
        
    end
    
    nn=length(blobThreads.parentlist);
    
    
    %blobThread_sorted position-in-time data
    for b=1:blobThreads_sorted.n   
        for t=1:numT  
            thisZ=blobThreads_sorted.z(b);
            endt=blobThreads_sorted.t(b)+blobThreads_sorted.length(b)-1;
            thisjSequence=blobThreads_sorted.jSequence{b};
            if  t<blobThreads_sorted.t(b)
                
                blobThreads_sorted.x(t,b)=tblobs(thisZ,blobThreads_sorted.t(b)).x(thisjSequence(1) );
                blobThreads_sorted.y(t,b)=tblobs(thisZ,blobThreads_sorted.t(b)).y(thisjSequence(1) );
                
            elseif t>blobThreads_sorted.t(b)+blobThreads_sorted.length(b)-1
                
                blobThreads_sorted.x(t,b)=tblobs(thisZ,endt).x( thisjSequence(end));
                blobThreads_sorted.y(t,b)=tblobs(thisZ,endt).y( thisjSequence(end));
                
            else
                
                
                blobThreads_sorted.x(t,b)=tblobs(thisZ,t).x( thisjSequence( t-blobThreads_sorted.t(b) + 1 ) );
                blobThreads_sorted.y(t,b)=tblobs(thisZ,t).y( thisjSequence( t-blobThreads_sorted.t(b) + 1 ) );
                
            end
        end
    end
    
    
    %plot blobThreads timelines
    warning('off','MATLAB:MKDIR:DirectoryExists');
    mkdir([options.outputFolder filesep 'Quant' filesep 'BlobThreads']);
    warning('on','MATLAB:MKDIR:DirectoryExists');

    figure('Position',[0 0 min([1.1*numT*width options.maxPlotWidth]) 1.1*height]);
    

    for z=1:numZ
        
       montageZ=[];
       for t=1:22
            montageZ=[montageZ squeeze(SmoothStabZMovie{z}(:,:,t))];
       end
       chigh=max(montageZ(:)); 
       clow=min(montageZ(montageZ>0));
       hold off;
       imagesc(montageZ,[clow chigh]);
       colormap(hot(256));
       axis off;
       hold on;      

        
     
       %subtightplot(1,22,t,[.005 .005]);
       for n=1:blobThreads_sorted.n
            if blobThreads_sorted.z(n)==z
                for t=blobThreads_sorted.t(n):blobThreads_sorted.t(n)+blobThreads_sorted.length(n)-1
                    plot(blobThreads_sorted.x(t,n)+ (t-1)*width,blobThreads_sorted.y(t,n),'g+');
                end
                for t=blobThreads_sorted.t(n):blobThreads_sorted.t(n)+blobThreads_sorted.length(n)-2
                    line([blobThreads_sorted.x(t,n)+(t-1)*width  blobThreads_sorted.x(t+1,n)+ (t)*width   ],[blobThreads_sorted.y(t,n) blobThreads_sorted.y(t+1,n)],'Color','b');
                end
            end
       end
       
       drawnow;
       export_fig([options.outputFolder '/Quant/BlobThreads/wb-blobTHREADS-Z' num2str(z)],'-tif','-a1');
    end
    
    
    
    
    %compute instantaneous  interblob distances
    blobs_sorted.instdistance=zeros(length(blobThreads_sorted.x0),length(blobThreads_sorted.y0),numT);
    
    for t=1:numT
        for i=1:length(blobThreads_sorted.x0)
            for j=1:(i-1)
                
                blobThreads_sorted.instdistance(i,j,t)=sqrt((blobThreads_sorted.x(t,i)-blobThreads_sorted.x(t,j))^2 + (blobThreads_sorted.y(t,i)-blobThreads_sorted.y(t,j))^2);
                blobThreads_sorted.instdistance(j,i,t)=blobThreads_sorted.instdistance(i,j,t);
            end
        end
    end
    
    
    %generate neuron movies labeled by brightness plus other blobs
    warning('off','MATLAB:MKDIR:DirectoryExists');
    mkdir([options.outputFolder filesep 'Quant' filesep 'NeuronTrackingMovie']);
    warning('on','MATLAB:MKDIR:DirectoryExists');
  
    figure('Position',[0 0 min([1.2*numZ*width options.maxPlotWidth]) 1.2*height]);
    for t=1:22
        for z=1:numZ
            subtightplot(1,numZ,z);
            hold off;
            movieZframe=squeeze(SmoothStabZMovie{z}(:,:,t));
            chigh=max(movieZframe(:));
            clow=min(movieZframe(movieZframe>0));
            imagesc(movieZframe,[clow chigh]);
            colormap(hot(256));
            axis off;
            hold on;

            for n=1:blobThreads_sorted.n
                if blobThreads_sorted.z(n)==z
                    plot(blobThreads_sorted.x(t,n),blobThreads_sorted.y(t,n),'g+');
                             
%                      if  blobThreads_sorted.y(t,n) < height-20  && (z<numZ ||  blobThreads_sorted.x(t,n)<width-30)
%                             text(blobThreads_sorted.x(t,n),blobThreads_sorted.y(t,n),[' ' num2str(n)],'Color',[0 1 0],'VerticalAlignment','top');
%                         else
%                             text(blobThreads_sorted.x(t,n),blobThreads_sorted.y(t,n),[' ' num2str(n)],'Color',[0 1 0],'VerticalAlignment','bottom','HorizontalAlignment','right');
%                      end
                
                end
            end
            
            for b=1:nn
                 if blobThreads_sorted.z(blobThreads.parentlist(b))==z
                     ex(blobThreads_sorted.x(t,blobThreads.parentlist(b)),blobThreads_sorted.y(t,blobThreads.parentlist(b)),4,[0 1 0]);
                 end
            end
            
            for b=1:nn
                if blobThreads_sorted.z(blobThreads.parentlist(b))==z
                    ex(blobThreads_sorted.x(t,blobThreads.parentlist(b)),blobThreads_sorted.y(t,blobThreads.parentlist(b)),4,[0 1 0]);
                    if  blobThreads_sorted.y(t,blobThreads.parentlist(b)) < height-20  && (z<numZ ||  blobThreads_sorted.x(t,blobThreads.parentlist(b))<width-30)
                        text(blobThreads_sorted.x(t,blobThreads.parentlist(b)),blobThreads_sorted.y(t,blobThreads.parentlist(b)),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
                    else
                        text(blobThreads_sorted.x(t,blobThreads.parentlist(b)),blobThreads_sorted.y(t,blobThreads.parentlist(b)),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','bottom','HorizontalAlignment','right');
                    end
                end
            end
%             
        end
        drawnow;
        export_fig([options.outputFolder '/Quant/NeuronTrackingMovie/wb-neurontrackingbybrightness-T' num2str(t)],'-tif','-a1');
    end
    
    
    %Re-label parent neurons by spatial position
    bt_spatialindex=zeros(size(blobThreads.parentlist));
    for i=1:length(blobThreads.parentlist)
        %compute spatial index
        bt_spatialindex(i)=blobThreads_sorted.x0(blobThreads.parentlist(i))+width*(blobThreads_sorted.y0(blobThreads.parentlist(i))-1)+width*height*(blobThreads_sorted.z(blobThreads.parentlist(i))-1); 
    end
    [sortvals neuronlookup]=sort(bt_spatialindex,'ascend');
    nn=length(neuronlookup);


    %
    %plot MIPmontage with numerically labeled neurons [BLOB THREADS]
    %

%    figure('Position',[0 0 min([1.2*length(I)*I(1).width options.maxPlotWidth]) 1.2*I(1).height]);
%     imagesc(MontageFrame1);
%     colormap(hot(256));
%     axis off;
%     hold on;
%     highlight=[]; %[126 41];
% 
%     for b=1:nn  
%         ex(blobThreads_sorted.Mx0(blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.My0(blobThreads.parentlist(neuronlookup(b))),4,[0 1 0]);
%         text(blobThreads_sorted.Mx0(blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.My0(blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
%         for i=1:length(highlight)
%             if highlight(i)==b
%                 ex(blobThreads_sorted.Mx0(blobThreads.parentlist(b)),blobThreads_sorted.My0(blobThreads.parentlist(b)),4,[0 1 0]);
%                 text(blobThreads_sorted.Mx0(blobThreads.parentlist(b)),blobThreads_sorted.My0(blobThreads.parentlist(b)),[num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
%              
%             end
%         end
%     end
%     tightfig;
%     save2pdf([options.outputFolder '/Quant/wb-labeledneurons-THREADS.pdf']);
%     
    %plot blobThreads at time 1
    for t=1
        figure('Position',[0 0 min([0.9*numZ*width options.maxPlotWidth]) height]);
        for z=1:numZ
            subplot(1,numZ,z);
            movieZframe=squeeze(SmoothStabZMovie{z}(:,:,t));
            chigh=max(movieZframe(:));
            clow=min(movieZframe(movieZframe>0));
            imagesc(movieZframe,[clow chigh]);
            colormap(hot(256));
            axis off;
            hold on;

            for b=1:nn  
                if blobThreads_sorted.z(blobThreads.parentlist(neuronlookup(b)))==z
                    ex(blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup(b))),4,[0 1 0]);
                    if z==1 && blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup(b))) > height-20
                        text(blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','bottom','HorizontalAlignment','left');
                    elseif  blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup(b))) < height-20  && (z<numZ ||  blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup(b)))<width-30) && z>1
                        text(blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
                    else
                        text(blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','bottom','HorizontalAlignment','right');
                    end

                end
            end
 
            
        end
        tightfig;
        save2pdf([options.outputFolder '/Quant/wb-labeledneurons-THREADS-t' num2str(t) '.pdf']);
    end
    
    
    wbstruct.blobThreads_sorted=blobThreads_sorted;
    wbstruct.blobThreads=blobThreads;
    wbstruct.tblobs=tblobs;

    assignin('base','tblobs',tblobs);
    assignin('base','blobThreads',blobThreads);
    assignin('base','blobThreads_sorted',blobThreads_sorted);
    assignin('base','neuronlookup',neuronlookup);

else %blobDetectFlag
   
    %debug- load stuff from base
    tblobs=evalin('base','tblobs');
    blobThreads=evalin('base','blobThreads');
    blobThreads_sorted=evalin('base','blobThreads_sorted');
    nn=length(blobThreads.parentlist);
    neuronlookup=evalin('base','neuronlookup');
    
end

%% Create Masks



if options.createMasksFlag

    disp('>making dynamic ROI masks...');
    
    
    %right now a mask lives forever, not just the duration of the thread
    %
    
    xbound=width;  %size(ZMovie{1},2);  %x and y are reversed in imagedata
    ybound=height;  %size(ZMovie{1},1);  %ZMovies are taller than wide

    %create mask buffer with same yx dimension ordering as ZMovies
    MT=zeros(ybound,xbound,numZ,numT,'uint16');
    mask_nooverlap=cell(numT,length(blobThreads_sorted.x0));
        
    for t=1:numT

        % figure('Position',[0 0 1.2*length(I)*I(1).width 1.2*I(1).height]);
        % colormap(hot(256));imagesc(MontageMovie(1).data);
        % tightfig; axis off; drawnow;

        mastermask=uint16(circularmask(Rmax));
        mask=cell(length(blobThreads_sorted.x0),1);
        
        for b=1:length(blobThreads_sorted.x0)
            maskedge_x1=max([1 2+Rmax-blobThreads_sorted.x(t,b)]);
            maskedge_y1=max([1 2+Rmax-blobThreads_sorted.y(t,b)]);
            maskedge_x2=min([xbound-blobThreads_sorted.x(t,b)+Rmax+1  2*Rmax+1]);
            maskedge_y2=min([ybound-blobThreads_sorted.y(t,b)+Rmax+1 2*Rmax+1]);   
            mask{b}=mastermask(maskedge_x1:maskedge_x2,maskedge_y1:maskedge_y2);
        end

        %
        %remove overlapping pixels for all masks
        %

        disp('>mask exclusion (unoptimized version)');
        tic
        for b=1:blobThreads_sorted.n

              mask_blit=ones(size(mask{b}),'uint16');
              ulposx=blobThreads_sorted.x(t,b)-Rmax;
              ulposy=blobThreads_sorted.y(t,b)-Rmax;
              dataedge_x1=max([1 ulposx]);
              dataedge_y1=max([1 ulposy]);
              dataedge_x2=min([xbound ulposx+2*Rmax]);
              dataedge_y2=min([ybound ulposy+2*Rmax]);      
              neighbors=find((blobThreads_sorted.instdistance(b,:,t)>0) .* (blobThreads_sorted.instdistance(b,:,t)<2*Rmax) );
              neighbors(blobThreads_sorted.z(neighbors)~=blobThreads_sorted.z(b))=[];
        %            h=figure;
        %            imagesc(I(blobs_sorted.z(b)).data);hold on;
        %            
        %            ex(blobs_sorted.x(b),blobs_sorted.y(b),10,'b');
              for n=neighbors
    %               figure(h);
    %               ex(blobs_sorted.x(n),blobs_sorted.y(n),10,'r');
                    b2bvec=[(blobThreads_sorted.x(t,b) - blobThreads_sorted.x(t,n)) , (blobThreads_sorted.y(t,b) - blobThreads_sorted.y(t,n))];
                    b2bvec=b2bvec/norm(b2bvec);
    %               line([blobs_sorted.x(n), blobs_sorted.x(b) ],[blobs_sorted.y(n), blobs_sorted.y(b) ],'Color','g')
                  for y= dataedge_y1:dataedge_y2 
                      for x= dataedge_x1:dataedge_x2
        %                         line([x, blobs_sorted.x(n) ],[y, blobs_sorted.y(n) ],'Color','r')
                            if dot(b2bvec,[x-blobThreads_sorted.x(t,n) y-blobThreads_sorted.y(t,n) ]) < (blobThreads_sorted.instdistance(b,n,t)/2 + blobSafetyMargin)
                                mask_blit(x-dataedge_x1+1,y-dataedge_y1+1)=0;
                            end;  
                      end
                  end

              end  

              mask_nooverlap{t,b}=mask{b}.*mask_blit;  %used in quantification section


              if (mod(b,100)==0) fprintf([num2str(b) '...']); 
              end

              %fill mask buffert
              MT(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,blobThreads_sorted.z(b),t)=MT(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,blobThreads_sorted.z(b),t)+b*mask_nooverlap{t,b}';

        end
        
        
    end

    toc


    
    disp('>background mask creation');
    tic
    background.mask=cell(size(blobThreads_sorted.x));
    
        background.mastermask=uint16(circularmask(Rbackground));
        
    
    for t=1:numT
    
        %crop masks overlapping image edge
        for b=1:length(blobThreads_sorted.x0)
    
            %mask coordinates
            background.maskedge_x1=max([1 2+Rbackground-blobThreads_sorted.x(t,b)]);
            background.maskedge_y1=max([1 2+Rbackground-blobThreads_sorted.y(t,b)]);
            background.maskedge_x2=min([xbound-blobThreads_sorted.x(t,b)+Rbackground+1  2*Rbackground+1]);
            background.maskedge_y2=min([ybound-blobThreads_sorted.y(t,b)+Rbackground+1 2*Rbackground+1]);   

            %absolute image coordinates
            background.ulposx=blobThreads_sorted.x(t,b)-Rbackground;
            background.ulposy=blobThreads_sorted.y(t,b)-Rbackground;
            background.dataedge_x1=max([1 background.ulposx]);
            background.dataedge_y1=max([1 background.ulposy]);
            background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
            background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]); 

            %blit edge-cropped round mastermask with extracted edge-cropped rectangle from binarized buffer
            background.mask{t,b}=uint16(background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)'   .* ...
                uint16(MT(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,blobThreads_sorted.z(b),t)==0));
        

        end 
    
    end
    toc
    
    assignin('base','mask_nooverlap',mask_nooverlap);
    assignin('base','MT',MT);
    assignin('base','background',background);

else
    
    %debug, load from base workspace


    mask_nooverlap=evalin('base','mask_nooverlap');
    MT=evalin('base','MT');
    background=evalin('base','background');
    options.createMasksFlag=false;
    xbound=width;  %size(ZMovie{1},2);  %x and y are reversed in imagedata
    ybound=height;  %size(ZMovie{1},1);  %ZMovies are taller than wide

end





%
%plot mask movie
%

plotMasksFlag=false;

    if plotMasksFlag

    options.outputFolder=pwd;
    numZ=10;
    width=126;
    height=429;
    options.maxPlotWidth=3000;

    warning('off','MATLAB:MKDIR:DirectoryExists');
    mkdir([options.outputFolder filesep 'Quant' filesep 'MaskMovie']);
    warning('on','MATLAB:MKDIR:DirectoryExists');

    figure('Position',[0 0 min([1.2*numZ*width options.maxPlotWidth]) 1.2*height]);
    for t=1:22
        for z=1:numZ
            subtightplot(1,numZ,z);
            hold off;
            imagesc(squeeze(MT(:,:,z,t)));
            cm=jet(256);
            cm(1,:)=[0 0 0];
            colormap(cm);
            axis off;
            hold on;
            for n=1:blobThreads_sorted.n
                    if blobThreads_sorted.z(n)==z
                        plot(blobThreads_sorted.x(t,n),blobThreads_sorted.y(t,n),'g+');
                    end
            end

        end
        drawnow;
        export_fig([options.outputFolder '/Quant/MaskMovie/mask-T' num2str(t)],'-tif','-a1');
    end

end

%% Quantify Movies


%%load Movies

if (options.quantFlag)

    zmoviefiles=dir( [folder '/StabilizedZMovies/*.tif']);

    %using new Tif library for loading
    if options.globalMovieFlag && evalin('base','exist(''ZMovie'',''var'')==1');
        disp('>using ZMovie already in workspace.');
        ZMovie=evalin('base', 'ZMovie');
%         if size(ZMovie{1},1)~=size(I(1).data,1) || size(ZMovie{1},2)~=size(I(1).data,2)
%             disp('Zmovie dimensions do not match other data.  Please clear. Quitting.');
%             return;
%         end
           
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

    %%Quantification
    %
    %
   
    disp('>quantifying ZMovies...');

    
    xbound=size(ZMovie{1},2);
    ybound=size(ZMovie{1},1);
    
    f_parents=zeros(length(ZMovie),length(blobThreads.parentlist));
    f_bonded=zeros(length(ZMovie),length(blobThreads.parentlist));
    f_background=zeros(length(ZMovie),length(blobThreads.parentlist));
  
    tic
    for frame=1:size(ZMovie{1},3);

       t=1 + floor((frame-1)/timeMotionSmoothingWindow);
       
       for b=1:nn
 
           
          ulposx=blobThreads_sorted.x(t,blobThreads.parentlist(b))-Rmax;
          ulposy=blobThreads_sorted.y(t,blobThreads.parentlist(b))-Rmax;
          dataedge_x1=max([1 ulposx]);
          dataedge_y1=max([1 ulposy]);
          dataedge_x2=min([xbound ulposx+2*Rmax]);
          dataedge_y2=min([ybound ulposy+2*Rmax]);

          %count pixels within mask 
          cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
          cropframe_masked=(mask_nooverlap{t,blobThreads.parentlist(b)}').*cropframe;
          allquantpixels=cropframe_masked(:);            
          
          [vals, ~]=sort(cropframe_masked(:),'descend');  %sort pixels by brightness          
          f_parents(frame,b)=mean(vals(1:numPixels));  %take the mean of the brightest pixels      


          %background subtraction,just parent frame for now
           background.ulposx=blobThreads_sorted.x(t,blobThreads.parentlist(b))-Rbackground;
           background.ulposy=blobThreads_sorted.y(t,blobThreads.parentlist(b))-Rbackground;
           background.dataedge_x1=max([1 background.ulposx]);
           background.dataedge_y1=max([1 background.ulposy]);
           background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
           background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]);

          % count background pixels
           background.cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);   
           background.cropframe_masked=(background.mask{t,blobThreads.parentlist(b)}).*background.cropframe;          
           [background.vals, ~]=sort(background.cropframe_masked(:),'descend');  %sort pixels by brightness
           f_background(frame,b)=mean(background.vals);  %take the mean of all background pixels      

          
          %quantify children+parent

          for bb=1:length(blobThreads_sorted.children{blobThreads.parentlist(b)}) %quantify multi  

               ulposx=blobThreads_sorted.x(t,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
               ulposy=blobThreads_sorted.y(t,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
               dataedge_x1=max([1 ulposx]);
               dataedge_y1=max([1 ulposy]);
               dataedge_x2=min([xbound ulposx+2*Rmax]);
               dataedge_y2=min([ybound ulposy+2*Rmax]);

               cropframechild=ZMovie{blobThreads_sorted.z(blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
               cropframe_add=(mask_nooverlap{t,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb)}').*cropframechild;
               allquantpixels=[allquantpixels; cropframe_add(:)]; 
             
          end

          [vals, ~]=sort(allquantpixels,'descend');  %sort pixels by brightness
          f_bonded(frame,b)=mean(vals(1:numPixelsBonded));
          
          
       end  
       
       if (mod(frame,100)==0) fprintf('%d...',frame); end

       
    end
    fprintf('%d.\n',frame);
    toc
    
    deltaFOverFNoBackSub=zeros(size(f_parents));
    deltaFOverF=zeros(size(f_parents));

    for i=1:nn
        deltaFOverFNoBackSub(:,i)=f_bonded(:,neuronlookup(i))/mean(f_bonded(:,neuronlookup(i)))-1;
        deltaFOverF(:,i)=(f_bonded(:,neuronlookup(i))-f_background(:,neuronlookup(i)))/mean(f_bonded(:,neuronlookup(i))-f_background(:,neuronlookup(i)))-1;
    end
    
    figure;
    imagesc(deltaFOverF');
    tightfig;
    export_fig([options.outputFolder '/Quant/heatmap-' trialname '.pdf']);
    

    %write out quantification process data
    wbstruct.f_parents=f_parents;
    
    wbstruct.f_bonded=f_bonded; 
    wbstruct.f_background=f_background;
    
    wbstruct.mask=mask;
    wbstruct.mask_nooverlap=mask_nooverlap;
    wbstruct.mask_background=background.mask;
    wbstruct.numZ=numZ;
    wbstruct.MT=MT;
    wbstruct.deltaFOverF=deltaFOverF;
    wbstruct.deltaFOverFNoBackSub=deltaFOverFNoBackSub;
    
    wbstruct.fps=metadata.fps;
    wbstruct.stimulus=metadata.stimulus;
    wbstruct.totalTime=metadata.totalTime;

    wbstruct.tv=(0:(size(ZMovie{1},3)-1))/wbstruct.fps;
    wbstruct.trialname=trialname;
    wbstruct.displayname=displayname;

    wbstruct.options=options;
    wbstruct.dateRan=datestr(now);

    wbstruct.nn=nn;
    wbstruct.neuronlookup=neuronlookup;
    wbstruct.nx=blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup));
    wbstruct.ny=blobThreads_sorted.y0(blobThreads.parentlist(neuronlookup));
    wbstruct.nz=blobThreads_sorted.z(blobThreads.parentlist(neuronlookup));

    wbstruct.exclusionList=[];
    
    save([options.outputFolder '/Quant/wbstruct.mat'],'wbstruct');
    save([options.outputFolder '/Quant/wbstruct2-r' num2str(options.Rmax) '-p' num2str(options.numPixels)  '-pb' num2str(options.numPixelsBonded)  '-th' num2str(options.thresholdMargin) '-sm' num2str(options.blobSafetyMargin) '-sl' num2str(options.sliceWidthMax) '-' strrep(strrep(datestr(now),':','-'),' ','-') '.mat'],'wbstruct');

    options.saveDir=[options.outputFolder '/Quant'];

    options.fieldName2='deltaFOverFNoBackSub';
    wbgridplot2(wbstruct,options);
    

%% end new stuff
    
    
    
    
    
    
end



end

%OLD STUFF
%{
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
        if size(ZMovie{1},1)~=height || size(ZMovie{1},2)~=width
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

          %count pixels within mask [LT]
          cropframe=ZMovie{blobs_sorted.z(blobs.parentlist(b))}( round(centroidDeltaY(b)) + (dataedge_y1:dataedge_y2), round(centroidDeltaX(b)) + (dataedge_x1:dataedge_x2) ,frame);
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
    export_fig([options.outputFolder '/Quant/heatmap-' trialname '.pdf']);
    

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
    wbgridplot2(wbstruct,options);

    
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

%}
