function wbstruct=wba(folder,options,extraOptions)
%WBA Whole Brain Analyzer
%
%V3 with TMIP generation and dynamic (local) tracking
%
%wbstruct = wb(folder,options)
%
%Saul's Whole Brain hyperstack analyzer
%
%leave arguments empty to run on current folder
%
%options:
%.numPixelsd
%.numPixelsBonded
%.thresholdMargin
%.Rmax
%.sliceWidthMax
%.blobSafetyMargin
%.globalMovieFlag
%.quantFlag
%.blobDetectFlag
%
%
%Saul Kato


chigh=20000;  %absolute brightness for now
clow=500;

if nargin<1 || isempty(folder)
    folder=pwd;
end

if ~wbCheckForDataFolder(folder) return; end;

if nargin<3
    extraOptions=[];
end

if (nargin<2 || isempty(options)) && exist([folder filesep 'wboptions.mat'],'file')==2
    options=load([folder filesep 'wboptions.mat']);
    disp('wba> using wboptions.mat');
else 
    disp('wba> No wboptions.mat found.  Creating one from default template.');
    options=wbcreatedefaultwboptionsfile;
end

options.maxTBlobBindingDeviation=5;
options.maxTBlobThreadFusionDist=5;


%% DEBUG FLAGS


%wbbatch does not handle this flag now
if ~isfield(options,'globalMovieFlag')  %use Movie already in workspace for quantification
    options.globalMovieFlag=true;
end

if ~isfield(options,'motionCorrectionFlag')  %first perform global motion correction
    options.motionCorrectionFlag=false;
end

if ~isfield(options,'createTMIPsFlag')  %create new TMIPs
    options.createTMIPsFlag=false;
end

if ~isfield(options,'makeMoviesFlag')  %make movies along the way
    if ~isfield(extraOptions,'makeMoviesFlag') 
       options.makeMoviesFlag=true;
    else
       options.makeMoviesFlag=extraOptions.makeMoviesFlag;
    end
end

wbClearResults;

if ~isfield(options,'blobDetectFlag')  %for debugging purposes, skip blob detection section
    options.blobDetectFlag=false;
end

if ~isfield(options,'createMasksFlag')  %for debugging purposes, skip quantification section
    options.createMasksFlag=false;
end

if ~isfield(options,'quantFlag')  %for debugging purposes, skip quantification section
    options.quantFlag=true;
end

plotMasksFlag=true;

verboseFlag=false;

%% PARSE ARGS (ALGO PARAMS)

if ~isfield(options,'interpolateMaskMotionFlag')
     options.interpolateMaskMotionFlag=true; %in frames
end

if ~isfield(options,'smoothingTWindow')
     smoothingTWindow=100; %in frames
     options.smoothingTWindow=smoothingTWindow;
else smoothingTWindow=options.smoothingTWindow; 
end

if ~isfield(options,'maxTBlobBindingDist')
     maxTBlobBindingDist=5;  %in pixels
     options.maxTBlobBindingDist=maxTBlobBindingDist;
else maxTBlobBindingDist=options.maxTBlobBindingDist; 
end

if ~isfield(options,'maxTBlobAccel')
     maxTBlobAccel=5;  %in pixels
     options.maxTBlobAccel=maxTBlobAccel;
else maxTBlobAccel=options.maxTBlobAccel; 
end

if ~isfield(options,'minBlobSpacing')
    options.minBlobSpacing=5;
end

if ~isfield(options,'moCoTimeStep')
    options.moCoTimeStep=10;
end

if ~isfield(options,'medFiltWidth')
    options.medFiltWidth=1;
end

if ~isfield(options,'radiusOfInfluence')
    options.radiusOfInfluence=20;
end

if ~isfield(options,'minThreadLength')
     minThreadLength=5; 
     options.minThreadLength=minThreadLength;
else minThreadLength=options.minThreadLength; 
end

if ~isfield(options,'numPixels')
     numPixels=50;  %max pixel distance between slices
     options.numPixels=numPixels;
else numPixels=options.numPixels; 
end

if ~isfield(options,'numPixelsBonded')
   options.numPixelsBonded=100;  %max pixel distance between slices
end

if ~isfield(options,'thresholdMargin')
   options.thresholdMargin=500;  %peak finder threshold
end

if ~isfield(options,'Rmax')
   Rmax=7;  %max pixel distance between slices
   options.Rmax=Rmax;
else Rmax=options.Rmax; 
end

if ~isfield(options,'sliceWidthMax')
   sliceWidthMax=2;  %max number of slice hops that a blob can bond across. 1 corresponds to 3-slice max traversal for a neuron
   options.sliceWidthMax=sliceWidthMax;
else sliceWidthMax=options.sliceWidthMax; 
end

if ~isfield(options,'blobSafetyMargin')
   blobSafetyMargin=0.5; %extra pixel buffer between adjacent blobs, doesn't have to be an integer
   options.blobSafetyMargin=blobSafetyMargin;
else blobSafetyMargin=options.blobSafetyMargin; 
end

if ~isfield(options,'maxPlotWidth')  
    options.maxPlotWidth=3000;
end

if ~isfield(options,'Rbackground')  
    Rbackground=16;   %radius of background subtraction
    options.Rbackground=Rbackground;  
else Rbackground=options.Rbackground;
end
    


% if ~isfield(options,'localTrackingDamping')  
%     options.LocalTrackingDamping=0.2;  
% end

if ~isfield(options,'outputMovieQuality')  %for extra movie output
    options.outputMovieQuality=100;
end

%% subplot fn overloading
%
make_it_tight = true;
subplot = @(m,n,p) subtightplot (m, n, p, [0 0], [0 0], [0 0]);
if ~make_it_tight,  clear subplot;  end

%% Load metadata
%

if nargin<2 || ~isfield(options,'outputFolder')  %for debugging purposes, skip blob detection section
    options.outputFolder=folder;
end

%load metadata file if it exists
if ~isempty(dir([folder '/meta.mat']))
     metadata=load([folder '/meta.mat']);
else
     disp('wba> no meta.mat file in this folder.  Creating one.');
     metadata.fileInfo=wbaddOMEmetadata(folder);
     metadata.fps=3;
     metadata.stimulus=[];
     metadata.smoothingWindow=smoothingTWindow;
end

if ~isfield(metadata,'stimulus')
    metadata.stimulus=[];
end

if ~isfield(metadata,'fps')
    disp('wba> no fps field in meta.mat.');
    if ~isfield(metadata,'totalTime')
        disp('wba> no totalTime field in meta.mat. setting fps to 3.');
        metadata.fps=3;
        metadata.totalTime=NaN;
    else
        numFrames=metadata.fileInfo.numT;
        metadata.fps=numFrames/metadata.totalTime;
        disp(['wba> inferring fps from total time: ' num2str(metadata.fps)]);
    end    
elseif ~isfield(metadata,'totalTime')
    metadata.totalTime=NaN;
end

trialname=folder(max(strfind(folder,'/'))+1:end);
displayname=strrep(trialname,'_','\_');


if strcmp(metadata.noseDirection,'North') || strcmp(metadata.noseDirection,'South')
    width=metadata.fileInfo.width;
    height=metadata.fileInfo.height;
else
    height=metadata.fileInfo.width;
    width=metadata.fileInfo.height;
end

%% Make Quant folder

warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir([options.outputFolder '/Quant']);
warning('on','MATLAB:MKDIR:DirectoryExists');


%% Run Motion Correction
if options.motionCorrectionFlag  || ~exist([folder filesep 'Quant' filesep 'wbmoco.mat'],'file')
    
    disp('wba> computing global motion correction.');
    moCoDrift=wbMotionCorrection(folder,options.moCoTimeStep);
    
else
    load([folder filesep 'Quant' filesep 'wbmoco.mat'])  %load moCoDrift struct
end



%% Generate TMIPs if necessary

if options.createTMIPsFlag || ~exist([folder '/TMIPs'],'dir')
    
    disp('wba> creating TMIPs.');
      
    fi=wbOMETMIP(folder,smoothingTWindow);
%     width=fi.width;
%     height=fi.height;
%     numZ=fi.numZ;
%     numTW=fi.numTW;
   
end

if options.smoothingTWindow~=wbGetTMIPsmoothingTWindow(folder)
    disp('smoothingTwindow does not match TMIPs.  Regenerating TMIPs');
    wbDeleteTMIPs;
    wbOMETMIP(folder,smoothingTWindow);
end

%% validate ExcludeZPlanes choice

if sum(metadata.excludeZPlanes) && ~ismember(metadata.fileInfo.numZ,metadata.excludeZPlanes)
    disp('wba> currently only supports excludeZPlanes that include the last plane. Quitting');
    if (ismac) MacOSNotify('Analysis not attemped.  Bad excludeZPlanes field.','Whole Brain Analyzer','','Submarine'); end
    return;
end

%% Load TMIPS into memory, with proper rotation

[TMIPMovie,numZ,numTW,validZs]=wbloadTMIPs(folder,metadata);
  
%% Make montage of first smoothed frame
% MontageFrame1=[];
% for z=validZs
%     MontageFrame1=[MontageFrame1 squeeze(TMIPMovie{z}(:,:,1))];
% end
% 
% figure('Position',[ 0 0 1200 800]);
% imagesc(MontageFrame1);

%% Find Blobs and Blob Threads (and movies)

if options.blobDetectFlag || evalin('base','~exist(''tblobs'',''var'')')
    
    if evalin('base','~exist(''tblobs'',''var'')')
         disp('no tblobs in base.  running blobDetection anyway even though blobDetectFlag=false.');
    end  

    %% Find Blobs [spatiotemporal bumps] (get Tblobs from TMIPs)
    %
    disp('wba> finding blobs in spacetime.');
    tic
    
    twCenterTime=((1:numTW)-1)*smoothingTWindow+smoothingTWindow/2;

    for z=validZs
        
        for tw=1:numTW
            
                
            frame=squeeze(TMIPMovie{z}(:,:,tw));
            
            if verLessThan('matlab','8.1')    
                 threshold=round(median(double(frame(:))))+options.thresholdMargin;
            else
                 threshold=median(frame(:))+options.thresholdMargin;
            end
            
            filt=ones(1,1);
            
            federatedcenters=FastPeakFindSK(frame,threshold,filt,options.minBlobSpacing,options.medFiltWidth);
        
            if ~isempty(federatedcenters)
                xi=federatedcenters.y' ;
                yi=federatedcenters.x' ;
            else
                xi=[];
                yi=[];
            end
            
            tblobs(z,tw).x=xi;  
            tblobs(z,tw).y=yi;
            tblobs(z,tw).n=length(tblobs(z,tw).x);
    
        end
        
    end
    
    toc  
    %% sum up MoCoDrifts to make globalDrifts
    
    globalDriftX=zeros(length(validZs),numTW);
    globalDriftY=zeros(length(validZs),numTW);
    cumGlobalDriftX=zeros(length(validZs),numTW);
    cumGlobalDriftY=zeros(length(validZs),numTW);
        
    for z=validZs
        for tw=2:numTW-1
            globalDriftX(z,tw)=sum(moCoDrift.Xinterp(twCenterTime(tw-1)+1:twCenterTime(tw),z));
            globalDriftY(z,tw)=sum(moCoDrift.Yinterp(twCenterTime(tw-1)+1:twCenterTime(tw),z));
            
            cumGlobalDriftX(z,tw)=sum(moCoDrift.Xinterp(1:twCenterTime(tw),z));
            cumGlobalDriftY(z,tw)=sum(moCoDrift.Yinterp(1:twCenterTime(tw),z));
            
        end
        globalDriftX(z,tw+1)=sum(moCoDrift.Xinterp(twCenterTime(tw)+1:end,z));
        globalDriftY(z,tw+1)=sum(moCoDrift.Yinterp(twCenterTime(tw)+1:end,z));
        
        
        cumGlobalDriftX(z,tw+1)=sum(moCoDrift.Xinterp(1:end,z));
        cumGlobalDriftY(z,tw+1)=sum(moCoDrift.Yinterp(1:end,z));
    end

    
    %% Plot Blob Mo Co Movie

    if options.makeMoviesFlag
        
        disp('wba> making blob motion correction movie.');
        tic
        %set up output movie directory and files
        movieOutName=[options.outputFolder filesep 'Quant' filesep 'BlobMoCoMovie-' wbMakeShortTrialname(trialname) '.mp4'];
        setupOutputMovie(movieOutName); %local function

        figure('Position',[0 0 min([1.1*numZ*width options.maxPlotWidth]) 2.2*height]);
        for tw=1:numTW

            for z=validZs
                subtightplot(2,numZ,z,[.005 .005]);
                hold off;
                movieZframe=squeeze(TMIPMovie{z}(:,:,tw));
    %             chigh=max(movieZframe(:));
    
                clow=min(movieZframe(movieZframe>0));
                chigh=min([max(movieZframe(:)) 10*median(movieZframe(:))]);
    
                imagesc(squeeze(TMIPMovie{z}(:,:,tw)),[clow chigh]);

                colormap(hot(256));
                axis off;
                hold on;

                plot(tblobs(z,tw).x,tblobs(z,tw).y,'g+','MarkerSize',3,'LineStyle','none');

                textur(['Z' num2str(z)]);
                
                
                subtightplot(2,numZ,numZ+z,[.005 .005]);
                hold off;
                
                
                movieZframe=squeeze(TMIPMovie{z}(:,:,tw));
                imagesc(zeros(size(squeeze(TMIPMovie{z}(:,:,tw)))),[clow chigh]);
                colormap(hot(256));
                axis off;
                hold on;
                if tw>1
                    plot(tblobs(z,tw-1).x-cumGlobalDriftX(z,tw-1),tblobs(z,tw-1).y-cumGlobalDriftY(z,tw-1),'b+','MarkerSize',3,'LineStyle','none');
                end
                plot(tblobs(z,tw).x-cumGlobalDriftX(z,tw),tblobs(z,tw).y-cumGlobalDriftY(z,tw),'g+','MarkerSize',3,'LineStyle','none');
                textur(['Z' num2str(z)]);
                
                
            end    
            

            mtit(['TW' num2str(tw)],'color','k');
            drawnow;

            %write out video frame
            framestruct=im2frame(png_cdata(gcf),jet(256));

            writeVideo(videoOutObj,framestruct.cdata);

            %old way to write out frame
            %export_fig([options.outputFolder '/Quant/BlobtrackingMovie/wb-blobs-t' num2str(tw,'%02d')],'-tif','-a1');

        end 

        close(videoOutObj);  %close BlobMovie
        toc

    end
  
    
    %% Connecting blobs and clean up blob timelines
    
    disp('wba> connecting tblobs / pruning / adding phantom blobs.');
    tic

    for z=validZs
                
        %%initialize tparents, parentlessTag, mindist, and deltaX and deltaY fields
        for tw=1:numTW
            tblobs(z,tw).tparents=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).mindist=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).deltaX=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).deltaY=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).localDriftX=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).localDriftY=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).parentlessTag=zeros(tblobs(z,tw).n,1);   
        end
        
        tblobs(z,1).parentlessTag=ones(tblobs(z,tw).n,1);  
        
        %%compute local drift by
        %%finding nearest neighbors one time step ago and measuring
        %%distances
        for tw=2:numTW

            for j=1:tblobs(z,tw).n
                
                dist=zeros(tblobs(z,tw-1).n,1);
                
                %compute distance to every blob in the last time step in
                %the same z slice
                
                for k=1:tblobs(z,tw-1).n
                    dist(k)=sqrt((tblobs(z,tw).x(j)-tblobs(z,tw-1).x(k)).^2+...
                        (tblobs(z,tw).y(j)-tblobs(z,tw-1).y(k)).^2);
                end
                
                %check that Tblob is not too far or acceleration is not too
                %great
                
                [min_dist min_dist_index]=min(dist);
                
                if min_dist<maxTBlobBindingDist  

                    %compute acceleration
%                     if tw>2
%                         dist_accel=sqrt ( ((tblobs(z,tw).y(j)-tblobs(z,tw-1).y(min_dist_index)) - tblobs(z,tw-1).deltaY(j)).^2+...
%                                           ((tblobs(z,tw).x(j)-tblobs(z,tw-1).x(min_dist_index)) - tblobs(z,tw-1).deltaX(j)).^2 ...
%                                         );
%                     else
%                         dist_accel=0;
%                     end
                    
                    %check if acceleration of blob position isn't too fast
%                     if dist_accel<maxTBlobAccel
                         [tblobs(z,tw).mindist(j) tblobs(z,tw).tparents(j)]=min(dist);  %make a t parent link
                         tblobs(z,tw).deltaY(j)= (tblobs(z,tw).y(j)-tblobs(z,tw-1).y(min_dist_index));
                         tblobs(z,tw).deltaX(j)=  (tblobs(z,tw).x(j)-tblobs(z,tw-1).x(min_dist_index));                        
%                         
%                     else
%                         
%                         tblobs(z,tw).tparents(j)=NaN;  %create an orphan
%                         tblobs(z,tw).parentlessTag(j)=2;
%                         tblobs(z,tw).mindist(j)=Inf;
%                         tblobs(z,tw).deltaY(j)= 0;
%                         tblobs(z,tw).deltaX(j)= 0;
%                         
%                     end
                else
                    tblobs(z,tw).tparents(j)=NaN;  %create an orphan
                    tblobs(z,tw).parentlessTag(j)=1;  %2
                    tblobs(z,tw).mindist(j)=Inf;
                    tblobs(z,tw).deltaY(j)= NaN;
                    tblobs(z,tw).deltaX(j)= NaN;
                end
            end
    
            %compute global drift based on centers
%           globalDriftX(z,tw)=nanmean(tblobs(z,tw).deltaX);
%           globalDriftY(z,tw)=nanmean(tblobs(z,tw).deltaY);        
            
            %compute local drift
            for j=1:tblobs(z,tw).n
                
                %compute distances of all blobs in frame
                distInFrame=zeros(tblobs(z,tw).n,1);
                for k=1:tblobs(z,tw).n
                    distInFrame(k)= sqrt((tblobs(z,tw).x(j)-tblobs(z,tw).x(k)).^2+...
                        (tblobs(z,tw).y(j)-tblobs(z,tw).y(k)).^2);
                end
                
                nearbyNeurons=find( distInFrame  <  options.radiusOfInfluence );
                
                tblobs(z,tw).localDriftX(j)=nanmean(tblobs(z,tw).deltaX(nearbyNeurons));
                tblobs(z,tw).localDriftY(j)=nanmean(tblobs(z,tw).deltaY(nearbyNeurons));
            end
    
        end
               
        %% now do a second pass to find jumps minimizing deviance from globalDrift
        
        for tw=2:numTW
            
            for j=1:tblobs(z,tw).n
                
                %compute globaldrift-adjusted distance to every blob in the last time step in
                %the same z slice
                dist_GlobalDriftAdjusted=zeros(tblobs(z,tw-1).n,1);               
                for k=1:tblobs(z,tw-1).n
                    dist_GlobalDriftAdjusted(k)=sqrt((tblobs(z,tw).x(j)-tblobs(z,tw-1).x(k) -  globalDriftX(z,tw) ).^2+...
                        (tblobs(z,tw).y(j)-tblobs(z,tw-1).y(k) - globalDriftY(z,tw)).^2);
                end
                
                
                %check that Tblob is not too far 
                
                [min_dist_GlobalDriftAdjusted min_dist_index_GlobalDriftAdjusted]=min(dist_GlobalDriftAdjusted);
                
                if min_dist_GlobalDriftAdjusted<options.maxTBlobBindingDeviation
                    
                    [tblobs(z,tw).mindist(j) tblobs(z,tw).tparents(j)]=min(dist_GlobalDriftAdjusted);  %make a t parent link
                    tblobs(z,tw).deltaY(j)= (tblobs(z,tw).y(j)-tblobs(z,tw-1).y(min_dist_index_GlobalDriftAdjusted));
                    tblobs(z,tw).deltaX(j)= (tblobs(z,tw).x(j)-tblobs(z,tw-1).x(min_dist_index_GlobalDriftAdjusted));  
                else
                    tblobs(z,tw).tparents(j)=NaN;  %create an orphan
                    tblobs(z,tw).parentlessTag(j)=1;  %2
                    tblobs(z,tw).mindist(j)=Inf;
                    tblobs(z,tw).deltaY(j)= 0;
                    tblobs(z,tw).deltaX(j)= 0;
                    
                end
                
                
                
            end   
            
        end        
   
        %%remove pointback vectors that point to same parent, mark them with NaNs
        tblobs(z,1).parentlessTag=ones(tblobs(z,1).n,1);  %all t=1 tblobs have no parents
        tblobs(z,1).markedForDeath=zeros(tblobs(z,1).n,1);
        
        for tw=2:numTW

            tblobs(z,tw).markedForDeath=zeros(tblobs(z,tw).n,1);    
            for j=1:tblobs(z,tw).n
                matches=ismember(tblobs(z,tw).tparents,tblobs(z,tw).tparents(j));
                if sum(matches)>1
          %     disp(['double detected for ' num2str(j)])
                    matchindices=find(matches);
                    [~,nearestmatch]=min(tblobs(z,tw).mindist(matches));
                    matchindices(nearestmatch)=[]; %dont kill the link that is shortest
                    tblobs(z,tw).tparents(matchindices)=NaN;   %but kill all others.
                    tblobs(z,tw).parentlessTag(matchindices)=1;
                end
            end
        end
  
        %now that there are no parents with multiple children we can assign
        %children to blobs to make a doubly linked list
        
        for tw=1:numTW
            tblobs(z,tw).tchild=zeros(size(tblobs(z,tw).x));
        end
        
        for tw=2:numTW
           
           for j=1:tblobs(z,tw).n
                if ~isnan( tblobs(z,tw).tparents(j) )
                    tblobs(z,tw-1).tchild( tblobs(z,tw).tparents(j) ) = j;  %doubly linked list
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

        for tw=2:numTW
            tblobs(z,tw-1).childlessTag=zeros(tblobs(z,tw-1).n,1);    
            for j=1:tblobs(z,tw-1).n
                if ~sum(ismember(tblobs(z,tw).tparents,j))
                    if (tw==2 && verboseFlag) disp([num2str(j) ' in slice ' num2str(tw-1) ' is childless.']); end
                    tblobs(z,tw-1).childlessTag(j)=1;
                end
            end
        end
        
        if tw>1
            tblobs(z,tw).childlessTag=ones(tblobs(z,tw).n,1);  %all t=end tlobs have no children
        end
        
        if numTW==1
            tblobs(z,1).childlessTag=ones(tblobs(z,1).n,1); %take care of numTW=1 case
        end
        
        %%kill isolated blobs
        killIsolatedBlobs=0;
        
%         if numTW==1
%             killIsolatedBlobs=0;  %don't kill isolated blobs if there is only one timewindow in dataset
%         else
%             killIsolatedBlobs=1;
%         end
%         
%         if killIsolatedBlobs


%  
%             for tw=1:numTW 
%                 for j=1:tblobs(z,tw).n
%                     tblobs(z,tw).markedForDeath(tblobs(z,tw).childlessTag>0 & tblobs(z,tw).parentlessTag>0)=1;
%                 end
%             end
% 
%         end
%       
        %%grow phantom blobs on all childless blobs or merge to parentless blob
        
        for tw=1:numTW
            tblobs(z,tw).phantomTag=zeros(tblobs(z,tw).n,1);
            tblobs(z,tw).nPhantoms=0;
        end
        
        for tw=2:numTW
                for j=1:(tblobs(z,tw-1).n + tblobs(z,tw-1).nPhantoms) %iterate over all blobs in last tw, regular and phantom
                    if tblobs(z,tw-1).childlessTag(j)==1  %here is a blob with no child, so try to link to parentless blobs, otherwise create new
                        
                        
                        %look for the globaldrift-adjusted closest parentless non-phantom blob in next timeWindow
                        dist_Forward_GlobalDriftAdjusted=inf(tblobs(z,tw).n,1);   %initialize to Infs
                        parentlessIndices=find(tblobs(z,tw).parentlessTag);
                        
%disp(['parentlessIndices: z:' num2str(z) ' tw:' num2str(tw) ' : ' num2str(length(parentlessIndices))]);

                        for k=parentlessIndices
                            dist_Forward_GlobalDriftAdjusted(k)=sqrt((tblobs(z,tw).x(k)-tblobs(z,tw-1).x(j) -  globalDriftX(z,tw) ).^2+...
                                (tblobs(z,tw).y(k)-tblobs(z,tw-1).y(j) - globalDriftY(z,tw)).^2);
                        end
                        [min_dist_Forward_GlobalDriftAdjusted min_dist_Forward_index_GlobalDriftAdjusted]=min(dist_Forward_GlobalDriftAdjusted);
            
                        if min_dist_Forward_GlobalDriftAdjusted<options.maxTBlobThreadFusionDist  %if closest blob is below thresh
                        
if (z==1 && verboseFlag)
    disp(['found a parentless blob to connect to: tw:' num2str(tw) ' z:' num2str(z)]);
end                   
                            %connect the blob in the last time window to this blob
                            tblobs(z,tw-1).childlessTag(j)=0;
                            tblobs(z,tw-1).tchild(j)= min_dist_Forward_index_GlobalDriftAdjusted ;
                            tblobs(z,tw).parentlessTag(min_dist_Forward_index_GlobalDriftAdjusted)=0;
                            tblobs(z,tw).tparents(min_dist_Forward_index_GlobalDriftAdjusted)=j;
                          
                        else %create a phantom blob
                            
                            tblobs(z,tw).nPhantoms=tblobs(z,tw).nPhantoms+1;
                            tblobs(z,tw).phantomTag=[tblobs(z,tw).phantomTag ; 1];
                            tblobs(z,tw).deltaX=[tblobs(z,tw).deltaX ; globalDriftX(z,tw)];
                            tblobs(z,tw).deltaY=[tblobs(z,tw).deltaY ; globalDriftY(z,tw)];                 
                            tblobs(z,tw).x=[tblobs(z,tw).x ; tblobs(z,tw-1).x(j)+globalDriftX(z,tw)];  
                            tblobs(z,tw).y=[tblobs(z,tw).y ; tblobs(z,tw-1).y(j)+globalDriftY(z,tw)];

                            tblobs(z,tw).childlessTag=[tblobs(z,tw).childlessTag ; 1];
                            tblobs(z,tw).parentlessTag=[tblobs(z,tw).parentlessTag ; 0];
                            tblobs(z,tw).tparents=[tblobs(z,tw).tparents ; j]; %point back to j blob in last time window

                            tblobs(z,tw-1).childlessTag(j)=0;
                            tblobs(z,tw-1).tchild(j)=tblobs(z,tw).nPhantoms+tblobs(z,tw).n;
                            
        %                   tblobs(z,tw).Tx(j)=tblobs(z,tw).x(j)+globalDriftX(z,tw)+(tw-1)*size(TMIPMovie{z},2);
        %                   tblobs(z,tw).Ty(j)=yi(j);
        %                   tblobs(z,tw).mindist(newIndex)=;
                            tblobs(z,tw).tchild=[tblobs(z,tw).tchild ; 0];
                        
                        end

                    end
                end
         end
 

    end
    toc
    
    assignin('base','tblobs',tblobs); %debug code
    
    if killIsolatedBlobs
        disp(['wba> culling lone blobs leaving: ' num2str(blobThreads.n) '.']);
    end
    
    
    %% Plot Blob movie

    if options.makeMoviesFlag
        
        disp('wba> making blob movie.');
        tic
        %set up output movie directory and files
        movieOutName=[options.outputFolder filesep 'Quant' filesep 'BlobTrackingMovie-' wbMakeShortTrialname(trialname) '.mp4'];
        setupOutputMovie(movieOutName); %local function

        figure('Position',[0 0 min([1.1*numZ*width options.maxPlotWidth]) 1.1*height]);
        for tw=1:numTW

            for z=validZs
                subtightplot(1,numZ,z,[.005 .005]);
                hold off;
                movieZframe=squeeze(TMIPMovie{z}(:,:,tw));
    %             chigh=max(movieZframe(:));
                chigh=min([max(movieZframe(:)) 10*median(movieZframe(:))]);
                clow=min(movieZframe(movieZframe>0));
    
    
    
                imagesc(squeeze(TMIPMovie{z}(:,:,tw)),[clow chigh]);

                colormap(hot(256));
                axis off;
                hold on;
                for j=1:tblobs(z,tw).n

                    if tblobs(z,tw).parentlessTag(j)
                        plot(tblobs(z,tw).x(j),tblobs(z,tw).y(j),'gx','MarkerSize',5);
    text(tblobs(z,tw).x(j),tblobs(z,tw).y(j),[' ' num2str(j)],'Color','g','FontSize',9);
                    else
    text(tblobs(z,tw).x(j),tblobs(z,tw).y(j),[' ' num2str(j)],'Color','w','FontSize',9);

                        plot([tblobs(z,tw).x(j) tblobs(z,tw).x(j)-2*tblobs(z,tw).localDriftX(j)  ],[ tblobs(z,tw).y(j) tblobs(z,tw).y(j)-2*tblobs(z,tw).localDriftY(j)   ],'b');
                        plot([tblobs(z,tw-1).x(tblobs(z,tw).tparents(j)) tblobs(z,tw).x(j)],[   tblobs(z,tw-1).y(tblobs(z,tw).tparents(j)) tblobs(z,tw).y(j)],'g');


                        if tblobs(z,tw).childlessTag(j)
                            plot(tblobs(z,tw).x(j),tblobs(z,tw).y(j),'mx','MarkerSize',3);                    
                        else
                            plot(tblobs(z,tw).x(j),tblobs(z,tw).y(j),'g+','MarkerSize',3);
                        end

                    end


                end



                %plot phantom blobs in blue
                for j=( (1:tblobs(z,tw).nPhantoms) + tblobs(z,tw).n)

    text(tblobs(z,tw).x(j),tblobs(z,tw).y(j),[' ' num2str(j)],'Color','c','FontSize',10,'HorizontalAlignment','Right');

                    plot([tblobs(z,tw-1).x(tblobs(z,tw).tparents(j)) tblobs(z,tw).x(j)],[   tblobs(z,tw-1).y(tblobs(z,tw).tparents(j)) tblobs(z,tw).y(j)],'g');           
                    plot(tblobs(z,tw).x(j),tblobs(z,tw).y(j),'c+','MarkerSize',3);
                end         

                textur(['Z' num2str(z)]);
            end    

            mtit(['TW' num2str(tw)],'color','k');
            drawnow;

            %write out video frame
            framestruct=im2frame(png_cdata(gcf),jet(256));

            writeVideo(videoOutObj,framestruct.cdata);

            %old way to write out frame
            %export_fig([options.outputFolder '/Quant/BlobtrackingMovie/wb-blobs-t' num2str(tw,'%02d')],'-tif','-a1');

        end 

        close(videoOutObj);  %close BlobMovie
        toc

    end
    
    %% Make Blob threads [Blobs connected in time]
    %
    % all parentless blobs start a thread, so this is easy, just count them up

    disp('wba> assembling blobThreads.');
    tic
    blobThreads=[];
    k=1;
    for z=validZs
        for tw=1:numTW
            for j=1:tblobs(z,tw).n+tblobs(z,tw).nPhantoms
                if tblobs(z,tw).parentlessTag(j)
                    blobThreads.z(k)=z;
                    blobThreads.t(k)=tw; %starting timewindow
                    blobThreads.j(k)=j;  %starting tblob number
                    blobThreads.x0(k)=tblobs(z,tw).x(j);  %starting x pos
                    blobThreads.y0(k)=tblobs(z,tw).y(j);  %starting y pos
 
                    k=k+1;
                end
            end
        end
    end
    
    if isempty(blobThreads)
        disp('No Blob Threads found! Try a parameter change, like setting thresholdMargin to 0.  Quitting.');
        beep; pause(.1); beep;
        return;
    end
    
    disp(['wba> initial blobThreads count: ' num2str(length(blobThreads.z))]);
    
    %compute length of all blobThreads by walking down chain. 
    for i=1:length(blobThreads.z)
        blobThreads.length(i)=1;
        thisblob_t=blobThreads.t(i);
        thisblob_z=blobThreads.z(i);
        thisblob_j=blobThreads.j(i);
        blobThreads.jSequence{i}=thisblob_j;
        markedForDeath(i)=tblobs(thisblob_z,thisblob_t).markedForDeath(thisblob_j);
        
        try
            
        while ~tblobs(thisblob_z,thisblob_t).childlessTag(thisblob_j);
             thisblob_j=tblobs(thisblob_z,thisblob_t).tchild(thisblob_j);

             thisblob_t=thisblob_t+1;
             blobThreads.length(i)=blobThreads.length(i)+1;
             blobThreads.jSequence{i}=[blobThreads.jSequence{i} thisblob_j];
        end  
        
        catch
            
            i

            
            return;
        end
    end

    
    blobThreads.n=length(blobThreads.length);

    blobThreads.length(logical(markedForDeath))=[];
    blobThreads.z(logical(markedForDeath))=[];
    blobThreads.t(logical(markedForDeath))=[];
    blobThreads.x0(logical(markedForDeath))=[];  %starting x pos
    blobThreads.y0(logical(markedForDeath))=[];  %starting y pos
    blobThreads.j(logical(markedForDeath))=[];

    blobThreads.jSequence(logical(markedForDeath))=[];
    
    blobThreads.n=length(blobThreads.length);


    %FOR NOW, kill blobThreads shorter than a certain length

    blobThreads.z(blobThreads.length<minThreadLength)=[];
    blobThreads.t(blobThreads.length<minThreadLength)=[];
    blobThreads.j(blobThreads.length<minThreadLength)=[];
    blobThreads.jSequence(blobThreads.length<minThreadLength)=[];
    blobThreads.x0(blobThreads.length<minThreadLength)=[];  %starting x pos
    blobThreads.y0(blobThreads.length<minThreadLength)=[];  %starting y pos
    
    blobThreads.length(blobThreads.length<minThreadLength)=[];
    blobThreads.n=length(blobThreads.length);

    toc
    
    disp(['wba> culled short blobThreads < ' num2str(minThreadLength) ' leaving: ' num2str(blobThreads.n) '.']);

    if blobThreads.n==0
        disp('wba> no blobThreads left.  Try a parameter change.  Quitting.');
        return;
    end
    



    %compute brightness for tblobs   
    for z=validZs
        
        for tw=1:numTW
            tblobs(z,tw).TMIPval=zeros(tblobs(z,tw).n,1);
            for j=1:tblobs(z,tw).n
                tblobs(z,tw).TMIPval(j)=TMIPMovie{z}(tblobs(z,tw).y(j),tblobs(z,tw).x(j),1);  %brightness in frame 1
            end
        end
    end


    assignin('base','tblobs',tblobs);
    
    
    %compute brightness for blobThreads 
    
    for i=1:blobThreads.n

%        blobThreads.avgPeak(i)=0;
%         for len=1:blobThreads.length(i)
%                blobThreads.avgPeak(i)=blobThreads.avgPeak(i)+tblobs(blobThreads.z(i),blobThreads.t(i)+len-1).TMIPval(blobThreads.jSequence{i}(len));
%         end
%        blobThreads.avgPeak(i)=blobThreads.avgPeak(i)/len;

        %try just frame 1 brightness for now
%         i
%         blobThreads.z(i)
%         blobThreads.t(i)
%         blobThreads.j(i)
%         size(tblobs)
%         tblobs(  blobThreads.z(i)  , blobThreads.t(i) ).n
%         size(tblobs(  blobThreads.z(i)  , blobThreads.t(i) ).TMIPval)
        blobThreads.avgPeak(i)=tblobs(  blobThreads.z(i)  , blobThreads.t(i) ).TMIPval( blobThreads.j(i) );

    end

    %
    %sort blobThreads by median brightness and save out inverse order
    %

    disp('wba> sorting blobThreads.');
    tic
    
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
    
    assignin('base','tblobs',tblobs);
    assignin('base','blobThreads',blobThreads);
    assignin('base','blobThreads_sorted',blobThreads_sorted);
    
    toc
    
    
    %compute all inter blobThread time-averaged pixel distances computed
    %for overlapping time slices
    %THIS IS NOT CURRENTLY VERIFIED AND NOT USED.  WHere are the Nans coming from?
    
%     disp('>wba computing inter-blobThread distances.');
%     tic
%     
%      blobThreads_sorted.distance=zeros(blobThreads_sorted.n);
%      for i=1:blobThreads_sorted.n
%          for j=1:(i-1)
% 
%               %compute overlapping times
%               tOccupancyI=zeros(numTW,1);
%               tOccupancyJ=zeros(numTW,1);
%               tOccupancyI(blobThreads_sorted.t(i):blobThreads_sorted.t(i)+blobThreads_sorted.length(i)-1)=1;
%               tOccupancyJ(blobThreads_sorted.t(j):blobThreads_sorted.t(j)+blobThreads_sorted.length(j)-1)=1;
%               
%               tOccupancyBoth=tOccupancyI & tOccupancyJ;
%               
%               %compute average distance across those overlapping times
%               blobThreads_sorted.distance(i,j)=0;
%               for k=blobThreads_sorted.t(i):blobThreads_sorted.t(i)+blobThreads_sorted.length(i)-1
%                   if tOccupancyBoth(k)
%                       thisZi=blobThreads_sorted.z(i);
%                       thisZj=blobThreads_sorted.z(j);
%                       thisJi=blobThreads_sorted.jSequence{i}(k-blobThreads_sorted.t(i)+1);
%                       thisJj=blobThreads_sorted.jSequence{j}(k-blobThreads_sorted.t(j)+1);
%                       
%                       blobThreads_sorted.distance(i,j)=blobThreads_sorted.distance(i,j)+...
%                          sqrt( (tblobs(thisZi,k ).x(thisJi) -  tblobs(thisZj,k ).x(thisJj)  )^2  + ...
%                                (tblobs(thisZi,k ).y(thisJi) -  tblobs(thisZj,k ).y(thisJj)  )^2 );
%                   end
%               end
%               
%               %no overlap in time gets an Inf distance
%               
%               blobThreads_sorted.distance(i,j)=blobThreads_sorted.distance(i,j)/sum(tOccupancyBoth(k));
%               blobThreads_sorted.distance(j,i)=blobThreads_sorted.distance(i,j);
%          end
%      end
% %     
%     toc



    %
    %bond blobThreads (find spatial parents and children)
    %
    
    disp('wba> bonding blobThreads.');
    tic

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
    
    toc
    
    disp('wba> assembling and extrapolating blobThreads position.');
    tic
    %blobThread_sorted position-in-time data
    for b=1:blobThreads_sorted.n   
        for tw=1:numTW  
            thisZ=blobThreads_sorted.z(b);
            endt=blobThreads_sorted.t(b)+blobThreads_sorted.length(b)-1;
            thisjSequence=blobThreads_sorted.jSequence{b};
            if  tw<blobThreads_sorted.t(b)
                
                %extrapolate x and y positions of blobThreads backwards in time
                                     
                cumDriftX=sum(globalDriftX(thisZ,tw+1:blobThreads_sorted.t(b)));
                cumDriftY=sum(globalDriftY(thisZ,tw+1:blobThreads_sorted.t(b)));            
                blobThreads_sorted.x(tw,b)=round(tblobs(thisZ,blobThreads_sorted.t(b)).x(thisjSequence(1) )-cumDriftX);
                blobThreads_sorted.y(tw,b)=round(tblobs(thisZ,blobThreads_sorted.t(b)).y(thisjSequence(1) )-cumDriftY);
                
            elseif tw>blobThreads_sorted.t(b)+blobThreads_sorted.length(b)-1
                
                %extrapolate x and y positions of blobThreads forwards in time
                
                cumDriftX=sum(globalDriftX(thisZ,blobThreads_sorted.t(b)+blobThreads_sorted.length(b)-1:tw));
                cumDriftY=sum(globalDriftY(thisZ,blobThreads_sorted.t(b)+blobThreads_sorted.length(b)-1:tw));
                blobThreads_sorted.x(tw,b)=round(tblobs(thisZ,endt).x( thisjSequence(end) )+cumDriftX);
                blobThreads_sorted.y(tw,b)=round(tblobs(thisZ,endt).y( thisjSequence(end) )+cumDriftY);
                
            else
                 
                blobThreads_sorted.x(tw,b)=round(tblobs(thisZ,tw).x( thisjSequence( tw-blobThreads_sorted.t(b) + 1 ) ));
                blobThreads_sorted.y(tw,b)=round(tblobs(thisZ,tw).y( thisjSequence( tw-blobThreads_sorted.t(b) + 1 ) ));
                
            end
        end
    end
       
    toc
    %% Plot blobThreads timelines
        
    if options.makeMoviesFlag
        disp('wba> plotting blothThreads timelines.');
        tic
        warning('off','MATLAB:MKDIR:DirectoryExists');
        mkdir([options.outputFolder filesep 'Quant' filesep 'BlobThreads']);
        warning('on','MATLAB:MKDIR:DirectoryExists');

        figure('Position',[0 0 min([1.1*numTW*width options.maxPlotWidth]) 1.1*height]);

        for z=validZs

           montageZ=[];
           for tw=1:numTW
                montageZ=[montageZ squeeze(TMIPMovie{z}(:,:,tw))];
           end
    %        chigh=max(montageZ(:)); 
           chigh=min([max(montageZ(:)) 10*median(montageZ(:))]);
           clow=min(montageZ(montageZ>0));
           hold off;
           imagesc(montageZ,[clow chigh]);
           colormap(hot(256));
           axis off;
           hold on;         

           %subtightplot(1,22,t,[.005 .005]);
           for n=1:blobThreads_sorted.n
                if blobThreads_sorted.z(n)==z
                    for tw=blobThreads_sorted.t(n):blobThreads_sorted.t(n)+blobThreads_sorted.length(n)-1
                        plot(blobThreads_sorted.x(tw,n)+ (tw-1)*width,blobThreads_sorted.y(tw,n),'g+');
                    end
                    for tw=blobThreads_sorted.t(n):blobThreads_sorted.t(n)+blobThreads_sorted.length(n)-2
                        line([blobThreads_sorted.x(tw,n)+(tw-1)*width  blobThreads_sorted.x(tw+1,n)+ (tw)*width   ],[blobThreads_sorted.y(tw,n) blobThreads_sorted.y(tw+1,n)],'Color','b');
                    end
                end
           end
           title(['blobThreads time history for Z' num2str(z)]);
           drawnow;     
           export_fig([options.outputFolder '/Quant/BlobThreads/wb-blobTHREADS-Z' num2str(z)],'-tif','-a1');
        end
        toc
    end
    
    
    %% Compute instantaneous interblob distances
    
    disp('wba> computing interblob distances and spatial labeling.');
    tic
    blobs_sorted.instdistance=zeros(length(blobThreads_sorted.x0),length(blobThreads_sorted.y0),numTW);
    
    for tw=1:numTW
        for i=1:length(blobThreads_sorted.x0)
            for j=1:(i-1)
                
                blobThreads_sorted.instdistance(i,j,tw)=sqrt((blobThreads_sorted.x(tw,i)-blobThreads_sorted.x(tw,j))^2 + (blobThreads_sorted.y(tw,i)-blobThreads_sorted.y(tw,j))^2);
                blobThreads_sorted.instdistance(j,i,tw)=blobThreads_sorted.instdistance(i,j,tw);
            end
        end
    end   
    
    %% Compute parent neuron relabeling (neuronlookup) by spatial position
    
    bt_spatialindex=zeros(size(blobThreads.parentlist));
    for i=1:length(blobThreads.parentlist)
        %compute spatial index %head to tail
        bt_spatialindex(i)=blobThreads_sorted.x0(blobThreads.parentlist(i))+width*numZ*(blobThreads_sorted.y0(blobThreads.parentlist(i))-1)+width*(blobThreads_sorted.z(blobThreads.parentlist(i))-1); 
    end
    [sortvals, neuronlookup]=sort(bt_spatialindex,'ascend');
    nn=length(neuronlookup);
    
    toc
    %% Make Neuron Tracking movies labeled by brightness plus other used
    %blobs plus global drift
    if options.makeMoviesFlag
        disp('wba> making Neuron Tracking Movie.');
        tic
        thisOptions.validZs=validZs;
        thisOptions.maxPlotWidth=options.maxPlotWidth;
        thisOptions.intensityRange=[clow chigh];
        thisOptions.trialName=trialname;
        thisOptions.outputFolder=options.outputFolder;
        thisOptions.outputMovieQuality=options.outputMovieQuality;

        wbMakeNeuronTrackingMovie(TMIPMovie,blobThreads,blobThreads_sorted,neuronlookup,thisOptions)
        toc
    end

    %% Plot blobThreads at time 1
    
%     disp('wba> making blobThread image.');
%     tic
%     for tw=1
%         figure('Position',[0 0 min([0.9*numZ*width options.maxPlotWidth]) height]);
%         zSeq=1;
%         for z=validZs
%             subplot(1,numZ,zSeq);
%             zSeq=zSeq+1;
%             movieZframe=squeeze(TMIPMovie{z}(:,:,tw));
% %             chigh=max(movieZframe(:));
% %             clow=min(movieZframe(movieZframe>0));
%             imagesc(movieZframe,[clow chigh]);
%             colormap(hot(256));
%             axis off;
%             hold on;
%         end
%         zSeq=1;
%         for z=validZs
%             subplot(1,numZ,zSeq);
%             zSeq=zSeq+1;
%             for b=1:nn  
%                 if blobThreads_sorted.z(blobThreads.parentlist(neuronlookup(b)))==z
%                     ex(blobThreads_sorted.x(tw,blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(b))),4,[0 1 0]);
%                     if z==1 && blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(b))) > height-20
%                         text(blobThreads_sorted.x(tw,blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','bottom','HorizontalAlignment','left');
%                     elseif  blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(b))) < height-20  && (z<numZ ||  blobThreads_sorted.x0(blobThreads.parentlist(neuronlookup(b)))<width-30) && z>1
%                         text(blobThreads_sorted.x(tw,blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','top');
%                     else
%                         text(blobThreads_sorted.x(tw,blobThreads.parentlist(neuronlookup(b))),blobThreads_sorted.y(tw,blobThreads.parentlist(neuronlookup(b))),[' ' num2str(b)],'Color',[0 1 0],'VerticalAlignment','bottom','HorizontalAlignment','right');
%                     end
% 
%                 end
%             end         
%         end
%         tightfig;
%         save2pdf([options.outputFolder '/Quant/wb-labeledneurons-tw' num2str(tw) '.pdf']);
%     end
%     toc
    %% Save out data to struct
     
    wbstruct.blobThreads_sorted=blobThreads_sorted;
    wbstruct.blobThreads=blobThreads;
    wbstruct.tblobs=tblobs;

    assignin('base','tblobs',tblobs);
    assignin('base','blobThreads',blobThreads);
    assignin('base','blobThreads_sorted',blobThreads_sorted);
    assignin('base','neuronlookup',neuronlookup);

else %debug- load stuff from base
    tblobs=evalin('base','tblobs');
    blobThreads=evalin('base','blobThreads');
    blobThreads_sorted=evalin('base','blobThreads_sorted');
    nn=length(blobThreads.parentlist);
    neuronlookup=evalin('base','neuronlookup');   

end
   
%% Create Masks

if options.createMasksFlag || evalin('base','~exist(''mask'',''var'')')
    
    if evalin('base','~exist(''mask'',''var'')')
         disp('no mask in base.  running createMasks anyway even though createMasksFlag=false.');
    end  

    disp('wba> making dynamic ROI masks...');
        
    %right now a mask lives forever, not just the duration of the thread
    %
    
    xbound=width;  %size(ZMovie{1},2);  %x and y are reversed in imagedata
    ybound=height;  %size(ZMovie{1},1);  %ZMovies are taller than wide

    %create mask buffer with same yx dimension ordering as ZMovies
    MT=zeros(ybound,xbound,numZ,numTW,'uint16');
    mask_nooverlap=cell(numTW,length(blobThreads_sorted.x0));
        
    disp('wba> mask exclusion (unoptimized version)');
       
    tic;
    
    fprintf(['  ' char(172) '> timeWindow ']);
    
    
    for tw=1:numTW

        % figure('Position',[0 0 1.2*length(I)*I(1).width 1.2*I(1).height]);
        % colormap(hot(256));imagesc(MontageMovie(1).data);
        % tightfig; axis off; drawnow;

        mastermask=uint16(circularmask(Rmax));
        mask=cell(length(blobThreads_sorted.x0),1);
        
        for b=1:length(blobThreads_sorted.x0)
            maskedge_x1=max([1 2+Rmax-blobThreads_sorted.x(tw,b)]);
            maskedge_y1=max([1 2+Rmax-blobThreads_sorted.y(tw,b)]);
            maskedge_x2=min([xbound-blobThreads_sorted.x(tw,b)+Rmax+1  2*Rmax+1]);
            maskedge_y2=min([ybound-blobThreads_sorted.y(tw,b)+Rmax+1 2*Rmax+1]);   
            mask{b}=mastermask(maskedge_x1:maskedge_x2,maskedge_y1:maskedge_y2);
        end

        %
        %remove overlapping pixels for all masks
        %

        fprintf('%d..',tw);
        
       
        for b=1:blobThreads_sorted.n

              mask_blit=ones(size(mask{b}),'uint16');
              ulposx=blobThreads_sorted.x(tw,b)-Rmax;
              ulposy=blobThreads_sorted.y(tw,b)-Rmax;
              dataedge_x1=max([1 ulposx]);
              dataedge_y1=max([1 ulposy]);
              dataedge_x2=min([xbound ulposx+2*Rmax]);
              dataedge_y2=min([ybound ulposy+2*Rmax]);      
              neighbors=find((blobThreads_sorted.instdistance(b,:,tw)>0) .* (blobThreads_sorted.instdistance(b,:,tw)<2*Rmax) );
              neighbors(blobThreads_sorted.z(neighbors)~=blobThreads_sorted.z(b))=[];
        %            h=figure;
        %            imagesc(I(blobs_sorted.z(b)).data);hold on;
        %            
        %            ex(blobs_sorted.x(b),blobs_sorted.y(b),10,'b');
              for n=neighbors
    %               figure(h);
    %               ex(blobs_sorted.x(n),blobs_sorted.y(n),10,'r');
                    b2bvec=[(blobThreads_sorted.x(tw,b) - blobThreads_sorted.x(tw,n)) , (blobThreads_sorted.y(tw,b) - blobThreads_sorted.y(tw,n))];
                    b2bvec=b2bvec/norm(b2bvec);
    %               line([blobs_sorted.x(n), blobs_sorted.x(b) ],[blobs_sorted.y(n), blobs_sorted.y(b) ],'Color','g')
                  for y= dataedge_y1:dataedge_y2 
                      for x= dataedge_x1:dataedge_x2
        %                         line([x, blobs_sorted.x(n) ],[y, blobs_sorted.y(n) ],'Color','r')
                            if sum(b2bvec.*[x-blobThreads_sorted.x(tw,n) y-blobThreads_sorted.y(tw,n) ]) < (blobThreads_sorted.instdistance(b,n,tw)/2 + blobSafetyMargin)
%try
                                mask_blit(x-dataedge_x1+1,y-dataedge_y1+1)=0;
%                                 catch
%                                     tw
%                                     b
%                                     y
%                                     x
%                                     n
%                                     dataedge_x1
%                                     dataedge_y1
%                                     size(mask_blit)
%                                     return;
%                                 end
                            end;  
                      end
                  end

              end  

              mask_nooverlap{tw,b}=mask{b}.*mask_blit;  %used in quantification section

              %fill mask buffer
              MT(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,blobThreads_sorted.z(b),tw)=MT(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,blobThreads_sorted.z(b),tw)+b*mask_nooverlap{tw,b}';
        
        end
             
    end
    fprintf('.\n');
    
    toc;



    disp('wba> background mask creation');
    
    tic
    background.mask=cell(size(blobThreads_sorted.x));
    background.mastermask=uint16(circularmask(Rbackground));        
    
    for tw=1:numTW
    
        %crop masks overlapping image edge
        for b=1:length(blobThreads_sorted.x0)
    
            %mask coordinates
            background.maskedge_x1=max([1 2+Rbackground-blobThreads_sorted.x(tw,b)]);
            background.maskedge_y1=max([1 2+Rbackground-blobThreads_sorted.y(tw,b)]);
            background.maskedge_x2=min([xbound-blobThreads_sorted.x(tw,b)+Rbackground+1  2*Rbackground+1]);
            background.maskedge_y2=min([ybound-blobThreads_sorted.y(tw,b)+Rbackground+1 2*Rbackground+1]);   

            %absolute image coordinates
            background.ulposx=blobThreads_sorted.x(tw,b)-Rbackground;
            background.ulposy=blobThreads_sorted.y(tw,b)-Rbackground;
            background.dataedge_x1=max([1 background.ulposx]);
            background.dataedge_y1=max([1 background.ulposy]);
            background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
            background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]); 

            %blit edge-cropped round mastermask with extracted edge-cropped rectangle from binarized buffer
            background.mask{tw,b}=uint16(background.mastermask(background.maskedge_x1:background.maskedge_x2,background.maskedge_y1:background.maskedge_y2)'   .* ...
                uint16(MT(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,blobThreads_sorted.z(b),tw)==0));
        

        end 
    
    end
    toc
    
    assignin('base','mask',mask);
    assignin('base','mask_nooverlap',mask_nooverlap);
    assignin('base','MT',MT);
    assignin('base','background',background);

else %debug, load from base workspace

    mask=evalin('base','mask');
    mask_nooverlap=evalin('base','mask_nooverlap');
    MT=evalin('base','MT');
    background=evalin('base','background');
%     options.createMasksFlag=false;
    xbound=width;  %size(ZMovie{1},2);  %x and y are reversed in imagedata
    ybound=height;  %size(ZMovie{1},1);  %ZMovies are taller than wide

end

%% Plot Mask Movie

if options.makeMoviesFlag

    disp('wba> making Mask Movies.');
    tic
    
    options.outputFolder=pwd;
    options.maxPlotWidth=3000;

    %setup output movie directory and files
    movieOutName=[options.outputFolder filesep 'Quant' filesep 'MaskMovie-' wbMakeShortTrialname(trialname) '.mp4'];
    setupOutputMovie(movieOutName); %local function

    figure('Position',[0 0 min([1.2*numZ*width options.maxPlotWidth]) 1.2*height]);
    for tw=1:numTW
        for z=1:numZ
            subtightplot(1,numZ,z);
            hold off;
            imagesc(squeeze(MT(:,:,z,tw)));
            cm=jet(256);
            cm(1,:)=[0 0 0];
            colormap(cm);
            axis off;
            hold on;
            for n=1:blobThreads_sorted.n
                if blobThreads_sorted.z(n)==z
                    plot(blobThreads_sorted.x(tw,n),blobThreads_sorted.y(tw,n),'g+');
                end
            end
        end
        drawnow;
        
        %write out video frame
        framestruct=im2frame(png_cdata(gcf),jet(256));
        writeVideo(videoOutObj,framestruct.cdata);

    end
    
    %close MaskMovie
    close(videoOutObj);
    toc
end

%% Quantify Movies

if (options.quantFlag)

    tic
    ZMovie=wbloadmovies(folder,metadata,options.globalMovieFlag);
    
    if isempty(ZMovie)
        beep;
        disp('No Movies found in this data folder.  Quitting.');
    end
    toc
    
    %% Movie quantification

    disp('wba> quantifying Movie...');
    
    xbound=size(ZMovie{1},2);
    ybound=size(ZMovie{1},1);
    
    f_parents=zeros(length(ZMovie),length(blobThreads.parentlist));
    f_bonded=zeros(length(ZMovie),length(blobThreads.parentlist));
    f_background=zeros(length(ZMovie),length(blobThreads.parentlist));
  
    tic  
    
    if options.interpolateMaskMotionFlag    
        
        %create interpolated blobThreads centers
        twCenterTime=((1:numTW)-1)*smoothingTWindow+smoothingTWindow/2;
        
        bT_xinterp=zeros(size(ZMovie{1},3),length(blobThreads_sorted.z));
        bT_yinterp=zeros(size(ZMovie{1},3),length(blobThreads_sorted.z));
        
        if size(blobThreads_sorted.x,1) ~= length(twCenterTime)
           disp('blobThreads and timewindow mismatch.  You probably need to clear your workspace.  Quitting.');
           return;
        end
        
        if numTW>1
            for bt=1:length(blobThreads_sorted.z)
                bT_xinterp(:,bt)=round(interp1(twCenterTime,blobThreads_sorted.x(:,bt),1:size(ZMovie{1},3),'linear','extrap'));
                bT_yinterp(:,bt)=round(interp1(twCenterTime,blobThreads_sorted.y(:,bt),1:size(ZMovie{1},3),'linear','extrap'));
            end
        else
            for bt=1:length(blobThreads_sorted.z)
                bT_xinterp(:,bt)=blobThreads_sorted.x(:,bt);
                bT_yinterp(:,bt)=blobThreads_sorted.y(:,bt);
            end      
        end
               
        %main quant loop
        for frame=1:size(ZMovie{1},3);

           tw=1 + min([floor((frame-1)/smoothingTWindow) numTW-1]); %which time window are we in?  this method has the last time window stretch.

           for b=1:nn

              ulposx=bT_xinterp(frame,blobThreads.parentlist(b))-Rmax;
              ulposy=bT_yinterp(frame,blobThreads.parentlist(b))-Rmax;
              dataedge_x1=max([1 ulposx]);
              dataedge_y1=max([1 ulposy]);
              dataedge_x2=min([xbound ulposx+2*Rmax]);
              dataedge_y2=min([ybound ulposy+2*Rmax]);

              cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);


              maskcropframe=mask_nooverlap{tw,blobThreads.parentlist(b)}';
               

              %count pixels within mask 
              
              %match mask and cropframe size HACK
              [mcf_xd,mcf_yd]=size(maskcropframe);
              [cf_xd,cf_yd]=size(cropframe);
              yd1=max([1 dataedge_y1-ulposy+1]);
              xd1=max([1 dataedge_x1-ulposx+1]);
              yd2= min([dataedge_y2-ulposy+1 cf_xd mcf_xd]);
              xd2= min([dataedge_x2-ulposx+1 cf_yd mcf_yd]);
              
              
              cropframe_masked=maskcropframe( yd1:yd2,xd1:xd2 ).*cropframe(yd1:yd2,xd1:xd2);
              allquantpixels=cropframe_masked(:);            

              [vals, ~]=sort(cropframe_masked(:),'descend');  %sort pixels by brightness      
              numpix=min([length(vals) numPixels]);
              f_parents(frame,b)=sum(vals(1:numpix))/numpix;  %take the mean of the brightest pixels      
              
              
              %background subtraction,just parent frame for now
               background.ulposx=bT_xinterp(frame,blobThreads.parentlist(b))-Rbackground;
               background.ulposy=bT_yinterp(frame,blobThreads.parentlist(b))-Rbackground;
               background.dataedge_x1=max([1 background.ulposx]);
               background.dataedge_y1=max([1 background.ulposy]);
               background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
               background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]);
                        
               background.cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);   
  
               background.maskcropframe=background.mask{tw,blobThreads.parentlist(b)};


              % count background pixels

              %match mask and cropframe size HACK
              [mcf_xd,mcf_yd]=size(background.maskcropframe);
              [cf_xd,cf_yd]=size(background.cropframe);
              
              yd1=max([1 background.dataedge_y1-background.ulposy+1]);
              xd1=max([1 background.dataedge_x1-background.ulposx+1]);
              yd2= min([background.dataedge_y2-background.ulposy+1  mcf_xd cf_xd]);
              xd2= min([background.dataedge_x2-background.ulposx+1  mcf_yd cf_yd]);
              
              background.cropframe_masked=background.maskcropframe(yd1:yd2,xd1:xd2).*background.cropframe(yd1:yd2,xd1:xd2);          
              [background.vals, ~]=sort(background.cropframe_masked(:),'descend');  %sort pixels by brightness
              f_background(frame,b)=sum(background.vals)/length(background.vals);  %take the mean of all background pixels      

              %quantify children+parent

              for bb=1:length(blobThreads_sorted.children{blobThreads.parentlist(b)}) %quantify multi  

                   ulposx=bT_xinterp(frame,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
                   ulposy=bT_yinterp(frame,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
                   
                   
                   dataedge_x1=max([1 ulposx]);
                   dataedge_y1=max([1 ulposy]);
                   dataedge_x2=min([xbound ulposx+2*Rmax]);
                   dataedge_y2=min([ybound ulposy+2*Rmax]);
                   
                   cropframechild=ZMovie{blobThreads_sorted.z(blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
                   maskcropframe=mask_nooverlap{tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb)}';

                   [mcf_xd,mcf_yd]=size(maskcropframe);
                   [cf_xd,cf_yd]=size(cropframechild);
                   yd1=max([1 dataedge_y1-ulposy+1]);
                   xd1=max([1 dataedge_x1-ulposx+1]);
                   yd2= min([dataedge_y2-ulposy+1 cf_xd mcf_xd]);
                   xd2= min([dataedge_x2-ulposx+1 cf_yd mcf_yd]);
   
                   cropframe_add=maskcropframe( yd1:yd2,xd1:xd2 ).*cropframechild(yd1:yd2,xd1:xd2);
                   allquantpixels=[allquantpixels; cropframe_add(:)]; 

              end

              [vals, ~]=sort(allquantpixels,'descend');  %sort pixels by brightness
                           
%             try
              numpix=min([length(vals) options.numPixelsBonded]);
              f_bonded(frame,b)=sum(vals(1:numpix))/numpix;
%             catch
%                   frame
%                   b
%                   size(f_bonded)
%                   options.numPixelsBonded
%                   size(vals)
%             end            

           end  

           if (mod(frame,100)==0) fprintf('%d..',frame); end

        end        
        
              
    else  %no mask motion interpolation, masks jump discretely between each time window
        
        for frame=1:size(ZMovie{1},3);

           tw=1 + min([floor((frame-1)/smoothingTWindow) numTW-1]); %which time window are we in?

           for b=1:nn

              ulposx=blobThreads_sorted.x(tw,blobThreads.parentlist(b))-Rmax;
              ulposy=blobThreads_sorted.y(tw,blobThreads.parentlist(b))-Rmax;
              dataedge_x1=max([1 ulposx]);
              dataedge_y1=max([1 ulposy]);
              dataedge_x2=min([xbound ulposx+2*Rmax]);
              dataedge_y2=min([ybound ulposy+2*Rmax]);

              %count pixels within mask 
              cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
              cropframe_masked=(mask_nooverlap{tw,blobThreads.parentlist(b)}').*cropframe;
              allquantpixels=cropframe_masked(:);            

              [vals, ~]=sort(cropframe_masked(:),'descend');  %sort pixels by brightness          
              f_parents(frame,b)=sum(vals(1:numPixels))/numPixels;  %take the mean of the brightest pixels      

              %background subtraction,just parent frame for now
               background.ulposx=blobThreads_sorted.x(tw,blobThreads.parentlist(b))-Rbackground;
               background.ulposy=blobThreads_sorted.y(tw,blobThreads.parentlist(b))-Rbackground;
               background.dataedge_x1=max([1 background.ulposx]);
               background.dataedge_y1=max([1 background.ulposy]);
               background.dataedge_x2=min([xbound background.ulposx+2*Rbackground]);
               background.dataedge_y2=min([ybound background.ulposy+2*Rbackground]);

              % count background pixels
               background.cropframe=ZMovie{blobThreads_sorted.z(blobThreads.parentlist(b))}(background.dataedge_y1:background.dataedge_y2,background.dataedge_x1:background.dataedge_x2,frame);   
               background.cropframe_masked=(background.mask{tw,blobThreads.parentlist(b)}).*background.cropframe;          
               [background.vals, ~]=sort(background.cropframe_masked(:),'descend');  %sort pixels by brightness
               f_background(frame,b)=sum(background.vals)/length(background.vals);  %take the mean of all background pixels      

              %quantify children+parent

              for bb=1:length(blobThreads_sorted.children{blobThreads.parentlist(b)}) %quantify multi  

                   ulposx=blobThreads_sorted.x(tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
                   ulposy=blobThreads_sorted.y(tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))-Rmax;
                   dataedge_x1=max([1 ulposx]);
                   dataedge_y1=max([1 ulposy]);
                   dataedge_x2=min([xbound ulposx+2*Rmax]);
                   dataedge_y2=min([ybound ulposy+2*Rmax]);

                   cropframechild=ZMovie{blobThreads_sorted.z(blobThreads_sorted.children{blobThreads.parentlist(b)}(bb))}(dataedge_y1:dataedge_y2,dataedge_x1:dataedge_x2,frame);
                   cropframe_add=(mask_nooverlap{tw,blobThreads_sorted.children{blobThreads.parentlist(b)}(bb)}').*cropframechild;
                   allquantpixels=[allquantpixels; cropframe_add(:)]; 

              end

              [vals, ~]=sort(allquantpixels,'descend');  %sort pixels by brightness

%               try

                numpix=min([length(vals) options.numPixelsBonded]);
                f_bonded(frame,b)=sum(vals(1:numpix))/numpix;
%               catch
%                   frame
%                   b
%                   size(f_bonded)
%                   options.numPixelsBonded
%                   size(vals)
%               end

           end  

           if (mod(frame,100)==0) fprintf('%d..',frame); end

        end
    
    end
  
    fprintf('%d.\n',frame);  %print final frame number.
    toc
    
    deltaFOverFNoBackSub=zeros(size(f_parents));
    deltaFOverF=zeros(size(f_parents));

    
    
    %from f_bonded to deltaFOverF
    for i=1:nn
        f0(i)=nanmean(f_bonded(:,neuronlookup(i)));
        deltaFOverFNoBackSub(:,i)=f_bonded(:,neuronlookup(i))/f0(i)-1;
        deltaFOverF(:,i)=(f_bonded(:,neuronlookup(i))-f_background(:,neuronlookup(i)))/nanmean(f_bonded(:,neuronlookup(i))-f_background(:,neuronlookup(i)))-1;
    end
    
    %write out quantification process data
    
    wbstruct.f0=f0;
    wbstruct.f_parents=f_parents;
    
    wbstruct.ID=cell(1,length(wbstruct.f0)); %create blank ID cell array
    
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

    wbstruct.tv=(0:(size(wbstruct.f_parents,1)-1))'/wbstruct.fps;
    wbstruct.trialname=trialname;
    wbstruct.displayname=displayname;

    wbstruct.options=options;
    wbstruct.dateRan=datestr(now);

    wbstruct.nn=nn;
    wbstruct.neuronlookup=neuronlookup;
    wbstruct.nx=blobThreads_sorted.x(:,blobThreads.parentlist(neuronlookup));
    wbstruct.ny=blobThreads_sorted.y(:,blobThreads.parentlist(neuronlookup));
    wbstruct.nz=blobThreads_sorted.z(blobThreads.parentlist(neuronlookup));
    
    wbstruct.globalDriftX=globalDriftX;
    wbstruct.globalDriftY=globalDriftY;

    wbstruct.exclusionList=[];
    wbstruct.metadata=metadata;

    %strip out instdistance since it is large and is easily recreated
    wbstruct.blobThreads_sorted=rmfield(wbstruct.blobThreads_sorted,'instdistance');
    
    wbstruct=wbMakeSimpleStruct(wbstruct,false,false);
    wbPToptions.processType='bc';
    wbPToptions.saveFlag=false;
    wbstruct=wbProcessTraces(wbstruct,wbPToptions);
    
    assignin('base','wbstruct',wbstruct);
 
    save([options.outputFolder '/Quant/wbstruct.mat'],'-struct','wbstruct');
    save([options.outputFolder '/Quant/wbstruct-r' num2str(options.Rmax) '-p' num2str(options.numPixels)  '-pb' num2str(options.numPixelsBonded)  '-th' num2str(options.thresholdMargin) '-sm' num2str(options.blobSafetyMargin) '-sl' num2str(options.sliceWidthMax) '-' strrep(strrep(datestr(now),':','-'),' ','-') '.mat'],'-struct','wbstruct');
   
    
    %send notification of completion via OS notification systems.
    if (ismac) MacOSNotify('Analysis completed.','Whole Brain Analyzer','','Glass'); end
    
%     try
%         system('/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier -message "Whole Brain Analyzer analysis completed."')
%     catch
%         disp('wba> tried to send complete to MacOS notification center but terminal-notifier 3rd party app failed or not found in Applications directory.');
%     end       

    options.saveDir=[options.outputFolder '/Quant'];
    
    
    %options.fieldName2='deltaFOverFNoBackSub';
    
    
    
    wbHeatPlot(wbstruct);
        
    options.saveFlag=true;
    wbGridPlot(wbstruct,options);
   
 
end %if QuantFlag

    %embedded function
    function setupOutputMovie(movieOutName)
            %create movie object for saving
            videoOutObj=VideoWriter(movieOutName,'MPEG-4');
            videoOutObj.FrameRate=20;
            videoOutObj.Quality=options.outputMovieQuality;
            open(videoOutObj);
    end

end %main

%subfunction for rendering movie frame from figure
function cdata = png_cdata(hfig)
    % Get CDATA from hardcopy using opengl
    % Need to have PaperPositionMode be auto 
    orig_mode = get(hfig, 'PaperPositionMode');
    set(hfig, 'PaperPositionMode', 'auto');
    cdata = hardcopy(hfig, '-Dopengl', '-r0');
    % Restore figure to original state
    set(hfig, 'PaperPositionMode', orig_mode);
end
