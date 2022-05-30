function wbMakeMoCoMovie(mainfolder,options)

if nargin<2
    options=[];
end

if nargin<1 
    mainfolder=pwd;
end

options.autoScale=false;
options.getScaleFromFirstFrame=false;
options.maxPlotWidth=10000;
options.outputDir='.';

if ~isfield(options,'movieQuality')
    options.movieQuality=100;
end

if ~isfield(options,'drawMoCoMarker')
    options.drawMoCoMarker=true;
end

if ~isfield(options,'frameRate')
    options.frameRate=200;
end

if ~isfield(options,'palette')
    options.palette=hot(256);
end

if ~isfield(options,'movieType')
    options.movieType='mov'; %'mp4'
end

if ~isfield(options,'textLabels')
    options.textLabels=true;
end

trialname=mainfolder(max(strfind(mainfolder,'/'))+1:end);
displayname=strrep(trialname,'_','\_');

%load Zmovies
ZMovie=wbloadmovies(mainfolder);

if isempty(ZMovie)
     return;
end   
    
    
width=size(ZMovie{1},2);
height=size(ZMovie{1},1);
numT=size(ZMovie{1},3);

%load metadata
if ~isempty(dir([mainfolder '/meta.mat']))
     metadata=load([mainfolder '/meta.mat']);
else
     disp('wbMakeMoCoMovie> no meta.mat file in this folder. Quitting.');
     return;
end


%compute validZs and numZ
validZs=1:length(ZMovie);
numZ=length(validZs);

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
    disp('wbMakeMontageMovie> computing dynamic range of movie.');
    chigh=0;
    clow=20000;
    for z=validZs    
        frameMax=max(ZMovie{z}(:));
        chigh=max([frameMax chigh]);

        frameMin=min(ZMovie{z}(ZMovie{z}>0));
        clow=min([clow frameMin]);
    end
end

disp('wbMakeMontageMovie> rendering movie');

%setup figure


figure('Position',[0 0 min([1.0*numZ*width options.maxPlotWidth]) 2*height]);


%setup output movie directory and files
%mkdir(options.outputDir);
movieOutName=[options.outputDir filesep 'MoCo-' wbMakeShortTrialname(trialname)];



%create movie object for saving

%MATLAB built-in method
% videoOutObj=VideoWriter([options.outputDir filesep movieOutName],options.movieType);
% videoOutObj.FrameRate=options.frameRate;
% if strcmp(options.movieType,'MPEG-4')
%     videoOutObj.Quality=options.movieQuality;
% end
% open(videoOutObj);


%VideoUtils
videoOutObj= VideoRecorder([options.outputDir filesep movieOutName], 'Format',  options.movieType,'Size',[min([round(1.0*numZ*width) options.maxPlotWidth]) 2*height]);




%% load Mo Co data if available

if options.drawMoCoMarker
    try
        moCo=load([mainfolder filesep 'Quant' filesep 'wbmoco.mat']);
    catch me
        moCo.moCoDrift=wbMotionCorrection(mainfolder);
    end
        
end


for z=validZs
    moCoX(z)=ceil(width/2);
    moCoY(z)=ceil(height/2);
end

moCoOriginX=moCoX;
moCoOriginY=moCoY;

if isfield(moCo.moCoDrift,'tform')
    IMREGTMODE=true;
else
    IMREGTMODE=false;
end



%%  Make montage

for t=1:numT
    
    
    if t==1
        
        MontageFrame=[];
        
        for z=validZs
             ZMovieFrame=squeeze(ZMovie{z}(:,:,t)) ;
             MontageFrame=[MontageFrame [ZMovieFrame ; ZMovieFrame]];
        end
        
    else
        
        MontageFrame=[];
        
        for z=validZs
             ZMovieFrame=squeeze(ZMovie{z}(:,:,t)) ;

             if IMREGTMODE
                shiftedZMovieFrame=imwarp(ZMovieFrame,moCo.moCoDrift.tform(t-1,z));
             else
                shiftedZMovieFrame= circshift( ZMovieFrame, [round(moCoOriginY(z)-moCoY(z)) round(moCoOriginX(z)-moCoX(z))] )   ;
             end
             
             %should black out wrapped around areas
%              shiftedZMovieFrame(1:round(moCoX(n,z)),:)=0;
%              shiftedZMovieFrame(:,1:round(moCoY(n,z)))=0;
% 
%              shiftedZMovieFrame(end+round(moCoX(n,z)):end,:)=0;
%              shiftedZMovieFrame(:,end+round(moCoY(n,z)):end)=0;
%     size(ZMovieFrame)
%     size(shiftedZMovieFrame)

             MontageFrame=[MontageFrame [ZMovieFrame ; shiftedZMovieFrame]];

        end
    
    
    
    end

    clf;
    colormap(options.palette);
    axis ij;
    imagesc(MontageFrame,[clow chigh]);
    axis tight;
    axis off;
    set(gca,'LooseInset',get(gca,'TightInset'))   
    set(gca,'position',[0 0 1 1],'units','normalized');
    
    hold on;
    
    
    
    if options.drawMoCoMarker
            for z=validZs
                ex(moCoX(z)+(z-1)*width,moCoY(z),14,color(z,length(validZs)));  
                moCoX(z)=moCoX(z)+moCo.moCoDrift.Xinterp(t,z);
                moCoY(z)=moCoY(z)+moCo.moCoDrift.Yinterp(t,z);
            end
    end
    
    
    
    %compose shift
    
    
    if options.textLabels
        
        %text: zplane
        for z=validZs;
            text(z*width-floor(width/2),height-10,['Z' num2str(z,2)],'Color','w','FontSize',9);
        end

        %text: title and clow chigh
        text(5,30,[displayname '            range:' num2str(clow) '-' num2str(chigh)],'Color','w','FontSize',9,'HorizontalAlignment','left');

        %text: frame count
        text(numZ*width-5,30,[num2str(t) '/' num2str(numT)],'Color','w','FontSize',9,'HorizontalAlignment','right');
    
    end
    
    drawnow;
    
    %write out video frame
    
    if strcmp(options.movieType,'Grayscale AVI')
        imtemp=png_cdata(gcf);   %still legacy use of hardcopy
        framestruct=im2frame(imtemp(:,:,1),jet(256));  
    else
        framestruct=getframe(gcf);
        %framestruct=im2frame(imtemp,jet(256));
    end
    

    %MATLAB built-in
    %writeVideo(videoOutObj,framestruct.cdata);
    
    %VideoUtils
    videoOutObj.addFrame(framestruct.cdata);

end

%close save movie

%close(videoOutObj);
clear videoOutObj;

disp('wbMakeMoCoMovie complete.');


%send notification of completion via OS notification systems.
try
    MacOSNotify('Make MoCo Movie Completed.','Whole Brain Analyzer','','Glass')
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

