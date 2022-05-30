function wbMakePhasePlot3DMovie(wbpcastruct,wbstruct,options)

if nargin<1 || isempty(wbpcastruct)
    wbpcastruct=load('Quant/wbpcastruct.mat');
end

if nargin<2 || isempty(wbstruct)
    [wbstruct wbstructFileName]=wbload([],false);
end


if nargin<3
    options=[];
end

if ~isfield(options,'cameraViewParamsFile')
    options.cameraViewParamsFile=[];
end

if ~isfield(options,'smoothFlag')
    options.smoothFlag=true;  %smooth derivs after computation
end

if ~isfield(options,'smoothingWindow')
    options.smoothingWindow=5;
end

if ~isfield(options,'frameRate')
    options.frameRate=20;
end

if ~isfield(options,'outputDirectory')
    options.outputDirectory=pwd;
end

if ~isfield(options,'neuronString')
    options.neuronString='AVAL';
end

if ~isfield(options,'timeColoringFlag')
    options.timeColoringFlag=false;
    
end

if ~options.timeColoringFlag
   
    options.timeColoring=zeros(size(wbstruct.tv));
    
else
    if ~isfield(options,'timeColoring')
        options.timeColoring=wbgettimecoloring(wbstruct,options.neuronString,@traceDerivIsPositive);
    end
end


if ~isfield(options,'stimColoringFlag')
    options.stimColoringFlag=false;
end

if options.stimColoringFlag
    options.stimColoring=wbgetstimcoloring(wbstruct);
else
    options.stimColoring=zeros(size(options.timeColoring));
end

if ~isfield(options,'width')
    options.width=1000;
end

if ~isfield(options,'height')
    options.height=800;
end

if ~isfield(options,'frameRange')
    options.frameRange=[1 size(wbpcastruct.pcs,1)];
end

if ~isfield(options,'trajectoryCurrentTimeMarkerSize')
    options.trajectoryCurrentTimeMarkerSize=6;
end

if ~isfield(options,'plotGhostTrajectory')
    options.plotGhostTrajectory=true;
end

if ~isfield(options,'trajectoryColor');
    options.trajectoryColor='b';
end

if ~isfield(options,'ghostTrajectoryColor')
    options.ghostTrajectoryColor=[0.5 0.5 0.5];
end

if ~isfield(options,'pcsToPlot')
    options.pcsToPlot=[1 2 3];
end

if ~isfield(options,'integrateDerivComponents')
   options.integrateDerivComponents=true;
end

if ~isfield(options,'wiggleCameraFlag')
    options.wiggleCameraFlag=true;
end

if ~isfield(options,'plotWallProjectionsFlag')
    options.plotWallProjectionsFlag=true;
end

if ~isfield(options,'backgroundColor')
    options.backgroundColor='white';
end

if ~isfield(options,'cameraView')
    options.cameraView=[-27 34];
end

if ~isfield(options,'boundingBoxLimits')
    options.boundingBoxLimits=[];
end

if ~isfield(options,'gridFlag')
    options.gridFlag=true;
end
if ~isfield(options,'outputMovieQuality')
    options.outputMovieQuality=100;
end

pc1=wbpcastruct.pcs(:,options.pcsToPlot(1));
pc2=wbpcastruct.pcs(:,options.pcsToPlot(2));
pc3=wbpcastruct.pcs(:,options.pcsToPlot(3));

if options.integrateDerivComponents

    pc1=detrend(cumsum(pc1),'linear');
    pc2=detrend(cumsum(pc2),'linear');
    pc3=detrend(cumsum(pc3),'linear');

end

%apply smoothing
if options.smoothFlag
    pc1=fastsmooth(pc1,options.smoothingWindow,3,1);
    pc2=fastsmooth(pc2,options.smoothingWindow,3,1);
    pc3=fastsmooth(pc3,options.smoothingWindow,3,1);
end

if ~isfield(options,'lineWidth')
    options.lineWidth=3;
end

if ~isfield(options,'xWall')
    options.xWall=1.1*[min(pc1) max(pc1)];  %.06;
end

if ~isfield(options,'yWall')
    options.yWall=1.1*[min(pc2) max(pc2)]; %.05;
end

if ~isfield(options,'zWall')
    options.zWall=1.1*[min(pc3) max(pc3)];  %-.03;
end



figure('Position',[0 0 options.width options.height]);
whitebg(options.backgroundColor);  %set figure to black

set(gcf,'Color',options.backgroundColor);
 
colormap([0 0 1;1 0 0;0 1 0;1 1 0]);



                
 %plot3(pc1,pc2,pc3,'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);
hold on;

 xd=[];
 yd=[];zd=[];
 xd2=[];
 yd2=[];zd2=[];
 xd3=[];
 yd3=[];zd3=[];
 
% h=plot3(wbpcastruct.pcs.PC_D1(1,1),wbpcastruct.pcs.PC_D1(1,2),-wbpcastruct.pcs.PC_D1(1,3),'Color',[.5 .5 .5],'Marker','none','LineWidth',2);
%cm=([0.5 0.5 0.5; 0 1 0;0.5 0.5 0.5; ;1 0 0]);
%colormap(cm);
plot3(0,0,0);
xlabel(['PC' num2str(options.pcsToPlot(1))]);
ylabel(['PC' num2str(options.pcsToPlot(2))]);
zlabel(['PC' num2str(options.pcsToPlot(3))]);

%ghost trajectory
if options.plotGhostTrajectory
    h.ghostTrajectory=plot3(pc1,pc2,pc3,'Color',options.ghostTrajectoryColor,'LineWidth',1);
end


if options.plotWallProjectionsFlag
    h1=plot3(pc1(1),options.yWall,pc3(1),'Color',[.5 .5 0],'Marker','.','MarkerSize',3);
    h2=plot3(options.xWall,pc2(1),pc3(1),'Color',[.5 .5 0],'Marker','.','MarkerSize',3);
    h3=plot3(pc1(1),pc2(1),options.zWall,'Color',[.5 .5 0],'Marker','.','MarkerSize',3);
end


fullColoring= options.timeColoring+options.stimColoring;
fullColoring(1)=min(fullColoring);
fullColoring(2)=max(fullColoring);

if ~options.timeColoringFlag
    colormap(color(options.trajectoryColor));
end


t=options.frameRange(1)+1;
h=color_line3(pc1(options.frameRange(1):t),pc2(options.frameRange(1):t),pc3(options.frameRange(1):t),fullColoring(options.frameRange(1):t),'LineStyle','-','Marker','.','LineWidth',options.lineWidth);
%current time circle
h0=plot3(pc1(1),pc2(1),pc3(1),'Color',[0 1 0],'Marker','.','MarkerSize',options.trajectoryCurrentTimeMarkerSize,'LineWidth',options.lineWidth);
h00=plot3(pc1(1),pc2(1),pc3(1),'Color',[0 1 0],'Marker','o','MarkerSize',options.trajectoryCurrentTimeMarkerSize,'LineWidth',options.lineWidth);

ywall=options.yWall;
xwall=options.xWall;
zwall=options.zWall;

ylim(ywall);
xlim(xwall);
zlim(zwall);
 
 if options.gridFlag
    grid on;
 end 
 
 
movieOutName=[options.outputDirectory filesep 'PhasePlot3D-' wbMakeShortTrialname(wbstruct.trialname) '.mp4'];
setupOutputMovie(movieOutName); %local function
        
if ~isempty(options.cameraViewParamsFile)
            %cameratoolbar;

    cameraViewParams=load(options.cameraViewParamsFile);
    fn=fieldnames(cameraViewParams);
   
    
    for i=1:length(fn)
        set(gca,fn{i},cameraViewParams.(fn{i}));
    end
    
end



for t=(options.frameRange(1)+1):options.frameRange(end)
           if options.wiggleCameraFlag
                view([-abs(mod(t/2,2*options.cameraView(1))-options.cameraView(1))+2*options.cameraView(1),options.cameraView(2)]);
           end
           
           if options.plotWallProjectionsFlag
           
               xd=[xd;pc1(t)];
               yd=[yd ; ywall(2)];
               zd=[zd; pc3(t)];
               set(h1,'XData',xd);
               set(h1,'YData',yd);
               set(h1,'ZData',zd);
           
               xd2=[xd2; xwall(1)];
               yd2=[yd2 ;pc2(t)];
               zd2=[zd2; pc3(t)];                      
               set(h2,'XData',xd2);
               set(h2,'YData',yd2);
               set(h2,'ZData',zd2);

               xd3=[xd3; pc1(t)];
               yd3=[yd3 ; pc2(t)];
               zd3=[zd3; zwall(1)];                      
               set(h3,'XData',xd3);
               set(h3,'YData',yd3);
               set(h3,'ZData',zd3);
       
           end

%             set(h,'XData',pc1(options.frameRange(1):t));
%             set(h,'YData',pc2(options.frameRange(1):t));
%             set(h,'ZData',pc3(options.frameRange(1):t));
%             set(h,'CData',fullColoring(options.frameRange(1):t));
           delete(h)
           
           %plot trajectory

           h=color_line3(pc1(options.frameRange(1):t),pc2(options.frameRange(1):t),pc3(options.frameRange(1):t),double(fullColoring(options.frameRange(1):t)),'LineStyle','-','Marker','.','LineWidth',options.lineWidth);

           %plot current time marker (green circle)
           set(h0,'XData',pc1(t));
           set(h0,'YData',pc2(t));
           set(h0,'ZData',pc3(t));
           set(h00,'XData',pc1(t));
           set(h00,'YData',pc2(t));
           set(h00,'ZData',pc3(t));
   drawnow; 

   %write out video frame
   framestruct=im2frame(png_cdata(gcf),jet(256));
   writeVideo(videoOutObj,framestruct.cdata);

end %frame render loop

%close Movie
close(videoOutObj);


    %embedded function
    function setupOutputMovie(movieOutName)
            %create movie object for saving
            videoOutObj=VideoWriter(movieOutName,'MPEG-4');
            videoOutObj.FrameRate=options.frameRate;
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

    
