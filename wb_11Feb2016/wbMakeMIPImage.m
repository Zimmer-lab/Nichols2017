function wbMakeMIPImage(mainfolder,options)

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

if ~isfield(options,'palette')
    options.palette=hot(256);
end

if ~isfield(options,'drawColorbar')
    options.drawColorbar=false;
end



if ~isfield(options,'drawMoCoMarker')
    options.drawMoCoMarker=false;
end

if ~isfield(options,'addMaskImage')
    options.addMaskImage=false;
end

if ~isfield(options,'singleZ')
    options.singleZ=[];
end


if ~isfield(options,'frameNumber')
    options.frameNumber=1;
end

if ~isfield(options,'showTitle')
    options.showTitle=false;
end


if ~isfield(options,'showFrameNumber')
    options.showFrameNumber=false;
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
if ~isempty(options.singleZ)
    validZs=options.singleZ;
else    
    validZs=1:length(ZMovie);
end
    
numZ=length(validZs);

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



%setup figure
if strcmp(options.orientation,'horizontal')
    figure('Position',[0 0 height width]);
else
    figure('Position',[0 0 width height]);
end

%setup output movie directory and files
%mkdir(options.outputDir);
imageOutName=[options.outputDir filesep 'MIPImage-' wbMakeShortTrialname(trialname)];



%% load Mo Co data if available

if options.drawMoCoMarker
    try
        moCo=load([mainfolder filesep 'Quant' filesep 'wbmoco.mat']);
    catch me
        moCo.moCoDrift=wbMotionCorrection;
    end
        
end

%%  Make MIP

moCoY=round(height/2);
moCoX=round(width/2);
ZFrame=zeros(height,width,numZ);

    
t=options.frameNumber
    
    
for z=validZs
     ZFrame(:,:,z)=squeeze(ZMovie{z}(:,:,t));
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
axis image;
axis off;
set(gca,'LooseInset',get(gca,'TightInset'))   
set(gca,'position',[0 0 1 1],'units','normalized');

hold on;

if options.drawMoCoMarker
    ex(moCoY,moCoX,14,'g');
    moCoY=moCoY+moCo.moCoDrift.Yinterp(t,1);
    moCoX=moCoX+moCo.moCoDrift.Xinterp(t,1);
end
   
    
%text: title and clow chigh
if options.showTitle
   %text(5,30,[ wbMakeShortTrialname(trialname) ' range:' num2str(clow) '-' num2str(chigh)],'Color','w','FontSize',9,'HorizontalAlignment','left');
   text(5,30,wbMakeShortTrialname(trialname),'Color','w','FontSize',9,'HorizontalAlignment','left');

end

%text: frame count
if options.showFrameNumber
   text(width-5,30,[num2str(t) '/' num2str(numT)],'Color','w','FontSize',9,'HorizontalAlignment','right');
end


if options.drawColorbar
    colorbar('EastOutside');
end

drawnow;

    
    
    
end %main

