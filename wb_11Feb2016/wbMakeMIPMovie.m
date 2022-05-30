function wbMakeMIPMovie(mainfolder,options)

if nargin<2
    options=[];
end


options.autoScale=false;
options.getScaleFromFirstFrame=false;
options.maxPlotWidth=10000;
options.outputDir='.';

if ~isfield(options,'orientation')
    options.orientation='horizontal';
end

if ~isfield(options,'drawMoCoMarker')
    options.drawMoCoMarker=true;
end

if ~isfield(options,'showTitle')
    options.showTitle=false;
end

if ~isfield(options,'showFrameCount')
    options.showFrameCount=true;
end

if ~isfield(options,'showTimer')
    options.showTimer=true;
end

if ~isfield(options,'movieQuality')
    options.movieQuality=100;
end


if ~isfield(options,'flipVertical')
    options.flipVertical=false;
end


if ~isfield(options,'movieType')
    options.movieType='MPEG-4';  %or "Grayscale AVI"
end

if ~isfield(options,'palette')
    options.palette=hot(256);
end

if ~isfield(options,'timeRange')
    options.timeRange=[];
end

if ~isfield(options,'frameRange')
    options.frameRange=[];
end

if ~isfield(options,'frameRate')
    options.frameRate=20;
end


if ~isfield(options,'frameStep')
    options.frameStep=1;
end

if ~isfield(options,'movieOutName')
    options.movieOutName=[];
end

if ~isfield(options,'cropBoxRelative')
    options.cropBoxRelative=[];
end


if nargin<1 
    mainfolder=pwd;
end

trialname=mainfolder(max(strfind(mainfolder,'/'))+1:end);
displayname=strrep(trialname,'_','\_');

%load Zmovies
ZMovie=wbloadmovies(mainfolder);
width=size(ZMovie{1},2);
height=size(ZMovie{1},1);
numT=size(ZMovie{1},3);
validZs=1:length(ZMovie);
numZ=length(validZs);

if isempty(options.cropBoxRelative)
    edgeL=1;
    edgeR=width;
    edgeT=1;
    edgeB=height;
else
    edgeL=1+round(options.cropBoxRelative(2)*width);
    edgeR=round(width*options.cropBoxRelative(4));
    edgeT=1+round(options.cropBoxRelative(1)*height);
    edgeB=round(height*options.cropBoxRelative(3));
end

%load metadata
if ~isempty(dir([mainfolder '/meta.mat']))
     metadata=load([mainfolder '/meta.mat']);
else
     disp('wbMakeMontageMovie> no meta.mat file in this folder. Quitting.');
     return;
end


%get global brightness dynamic range
chigh=20000;
clow=1000;

if options.getScaleFromFirstFrame
    chigh=0;
    clow=20000;
    for z=validZs    
        frameMax=max(max(ZMovie{z}(:,:,1)));
        chigh=max([frameMax chigh]);

        frameMin=min(min(ZMovie{z}(ZMovie{z}(:,:,1)>0)));
        clow=min([clow frameMin]);
    end
end

if options.autoScale %this takes time.
    disp('wbMakeMIPMovie> computing dynamic range of movie.');
    chigh=0;
    clow=20000;
    for z=validZs    
        frameMax=max(ZMovie{z}(:));
        chigh=max([frameMax chigh]);

        frameMin=min(ZMovie{z}(ZMovie{z}>0));
        clow=min([clow frameMin]);
    end
end

disp('wbMakeMIPMovie> rendering movie');

%setup figure
if strcmp(options.orientation,'horizontal')
    figure('Position',[0 0 height width]);
else
    figure('Position',[0 0 width height]);
end

%setup output movie directory and files
%mkdir(options.outputDir);

if isempty(options.movieOutName)
    movieOutName=[options.outputDir filesep 'MIPMovie-' wbMakeShortTrialname(trialname)];
else
    movieOutName=[options.outputDir filesep options.movieOutName];
end


%create movie object for saving
videoOutObj=VideoWriter([options.outputDir filesep movieOutName],options.movieType);
videoOutObj.FrameRate=options.frameRate;
videoOutObj.Quality=options.movieQuality;
open(videoOutObj);


%% load Mo Co data if available

if options.drawMoCoMarker
    try
        moCo=load([mainfolder filesep 'Quant' filesep 'wbmoco.mat']);
    catch me
        moCo.moCoDrift=wbMotionCorrection(mainfolder);
    end
        
end


%% setup frame range

if isempty(options.frameRange)
    if isempty(options.timeRange)
        frameRange=1:options.frameStep:numT;
    else
        frameRange=(options.timeRange(1)/totalTime*numT+1):options.frameStep:(options.timeRange(1)/totalTime*numT+1);
    end
else
    frameRange=options.frameRange(1):options.frameStep:options.frameRange(end);
end


%%  Make MIP

for z=validZs
        moCoX(z)=round( width /2);
        moCoY(z)=round( height /2);
end


ZFrame=zeros(edgeB-edgeT+1,edgeR-edgeL+1,numZ);


for t=frameRange
    
    if options.flipVertical
        for z=validZs
             ZFrame(:,:,z)=squeeze(ZMovie{z}(edgeT:edgeB,edgeR:-1:edgeL,t));
        end        
        
    else
        for z=validZs
             ZFrame(:,:,z)=squeeze(ZMovie{z}(edgeT:edgeB,edgeL:edgeR,t));
        end
    end
    
    MIPFrame=max(ZFrame,[],3);
    
    clf;
    colormap(options.palette);
    axis ij;
    if strcmp(options.orientation,'horizontal')
        imagesc(MIPFrame',[clow chigh]);
    else
        imagesc(MIPFrame,[clow chigh]);
    end
    axis tight;
    axis off;
    set(gca,'LooseInset',get(gca,'TightInset'))   
    set(gca,'position',[0 0 1 1],'units','normalized');
    
    hold on;
    
    if options.drawMoCoMarker
        for z=validZs
                ex(moCoY(z),moCoX(z),14,color(z,length(validZs)));
                moCoX(z)=moCoX(z)+moCo.moCoDrift.Xinterp(t,z);
                moCoY(z)=moCoY(z)+moCo.moCoDrift.Yinterp(t,z);
        end
    end

    %text: title and clow chigh
    if options.showTitle
       %text(5,30,[ wbMakeShortTrialname(trialname) ' range:' num2str(clow) '-' num2str(chigh)],'Color','w','FontSize',9,'HorizontalAlignment','left');
       text(5,30,wbMakeShortTrialname(trialname),'Color','w','FontSize',9,'HorizontalAlignment','left');

    end
    
    if options.showFrameCount
       text(width-5,30,[num2str(t) '/' num2str(numT)],'Color','w','FontSize',9,'HorizontalAlignment','right');
    end
    
    if options.showTimer
       secondsElapsed=floor(t/numT*metadata.totalTime);
       text(5,9,[num2str(secondsElapsed) ' s'],'Color',[.9 .9 .9],'FontSize',13,'HorizontalAlignment','left');
    end
    
    drawnow;
    

    
    %write out video frame
    
    if strcmp(options.movieType,'Grayscale AVI')
        imtemp=png_cdata(gcf);    %still legacy
        framestruct=im2frame(imtemp(:,:,1),jet(256));
    else
        
        framestruct=getframe(gcf);
    end
    
    writeVideo(videoOutObj,framestruct.cdata);
    

end

%close save movie
close(videoOutObj);

disp('wbMakeMIPMovie> complete.');


%send notification of completion via OS notification systems.
try
    MacOSNotify('Make MIP Movie Completed.','Whole Brain Analyzer','','Glass')
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

