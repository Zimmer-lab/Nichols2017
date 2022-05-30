function wbPhasePlotGrid(folder,options)

if nargin<2
    options=[];
end

if ~isfield(options,'view')
    options.view=[0 0 90];
end

if ~isfield(options,'trajectoryColor')
    options.trajectoryColor=[0.8 0.8 0.8];
end

if ~isfield(options,'multiView')
    options.multiView=false;
end

if ~isfield(options,'outputDir')
    options.outputDir=pwd;
end

if ~isfield(options,'neuronOverlay')
    options.neuronOverlay='labeled';
end

if ~isfield(options,'backgroundColor')
    options.backgroundColor='w';
end

if ~isfield(options,'nCols')
    options.nCols=6;
end

if ~isfield(options,'nRows')
    options.nRows=[];
end


if ~isfield(options,'textX')
    options.textX=200;
end

if ~isfield(options,'textY')
    options.textY=50;
end

if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end

if ~isfield(options,'subPlotNumbers')
    options.subPlotNumbers=[];
end

if ~isfield(options,'lineWidth')
    options.lineWidth=2;
end


if ~isfield(options,'addTitle')
    options.addTitle=false;
end


if ~isfield(options,'refColorPlot')
    options.refColorPlot=false;
end

if ~isfield(options,'ballColors')
    options.ballColors={[0.9 0 0],[32 159 32]/255};
end

if ~isfield(options,'ballSize')
    options.ballSize=6;
end


if nargin<1 || isempty(folder)
    folder=pwd;
end


if exist([folder filesep 'Quant' filesep 'wbstruct.mat'],'file')==2  %% one dataset

    folders={pwd};
     
else
    

    folders=listfolders(folder,true);

end

if ~options.subPlotFlag
   handles.fig=figure('Position',[0 0 1000 1400],'Name','wbPhasePlotGrid','Color',options.backgroundColor);
end

PPoptions.interactiveMode=false;
PPoptions.subPlotFlag=true;
PPoptions.backgroundColor=options.backgroundColor;
PPoptions.phasePlot3DView=options.view;
PPoptions.colorBy='constant';
PPoptions.phasePlot3DMainColors{1}= options.trajectoryColor;

PPoptions.lineWidth=options.lineWidth;
PPoptions.overlayBallSize=options.ballSize;

x_marg=.03;

for f=1:length(folders)
    
    
    cd(folders{f});
    %wbstruct{f}=wbload(folders{f},false);
    wbPCAstruct{f}=wbLoadPCA(folders{f},false);
    PPoptions.wbstruct=wbload(folders{f},false);
    
    if options.multiView
        
        subtightplot(length(folders),3,3*f-2,[.05 x_marg],[.05 .05],[.18 .01]);
        PPoptions.phasePlot3DView=[0 0 90];
        wbPhasePlot3D(wbPCAstruct{f},PPoptions);
        axis square;


        subtightplot(length(folders),3,3*f-1,[.05 x_marg],[.05 .05],[.18 .01]);
        PPoptions.phasePlot3DView=[0 90 0];
        wbPhasePlot3D(wbPCAstruct{f},PPoptions);
        axis square;

        subtightplot(length(folders),3,3*f-0,[.05 x_marg],[.05 .05],[.18 .01]);
        PPoptions.phasePlot3DView=[90 0 0];
        wbPhasePlot3D(wbPCAstruct{f},PPoptions);
        axis square;
    
    else  %single view
        
        
        
        if  strcmp(options.neuronOverlay,'labeled')
            
            neurons=AlphaSort(wbListIDs(PPoptions.wbstruct,false));
            
            if isempty(options.nRows)
                options.nRows=ceil(numel(neurons)/options.nCols);
            end
            
            PPoptions.timeColoring=ones(size(PPoptions.wbstruct.tv));  

            
            
            if isempty(options.subPlotNumbers)
                options.subPlotNumbers=1:(numel(neurons)+1);
            end
            
            n0=0;
            
            if options.refColorPlot
                n0=1;
                
                PP0options=PPoptions;
                subtightplot(options.nRows,options.nCols,options.subPlotNumbers(1));
                %PP0options.fourColorMap=[.2 .2 .8;.8 .2 .2;.2 .8 .2;[255 204 0]/255];
                PP0options.colorBy='6-state';
                PP0options.stateColoring=6;
                PP0options.lineWidth=1.5;
                PP0options.plotTrajectory=true;
                PP0options.plotGhostTrajectory=false;
                PP0options.timeColoring=[];
                
                %PP0options.phasePlot2DView=1;
                PP0options.convertToImage=false;
                
                %2 is "rise state"
                wbPhasePlot3D(wbPCAstruct{f},PP0options);
                
                axis square;
                axis off;
                xlabel('');
                ylabel('');
                drawnow;

                ConvertToImage([],[],[1 1 1],true);
            end
                
                       
            for n=1:numel(neurons)

                
                subtightplot(options.nRows,options.nCols,options.subPlotNumbers(n+n0));
               
                PPoptions.subPlotFlag=true;
                PPoptions.fourColorMap=[.2 .2 .8;.8 .2 .2;[25 165 2]/255;[255 204 0]/255];
                PPoptions.lineWidth=0.5;
                PPoptions.plotTrajectory=false;
                PPoptions.plotGhostTrajectory=true;
                PPoptions.timeColoringOverlayColor=options.ballColors;
                PPoptions.overlayMarker={'o','o'};
                PPoptions.phasePlot2DView=1;
                PPoptions.timeColoringOverlay{1}(:,1)=(wbFourStateTraceAnalysis(PPoptions.wbstruct,'useSaved',neurons{n})==2);
                PPoptions.timeColoringOverlay{1}(:,2)=(wbFourStateTraceAnalysis(PPoptions.wbstruct,'useSaved',neurons{n})==4);
%                 %2 is "rise state"
                PPoptions.convertToImage=false;

                wbPhasePlot3D(wbPCAstruct{f},PPoptions);

                axis square;
                axis off;
                xlabel('');
                ylabel('');
                drawnow;
                ConvertToImage([],[],[1 1 1],true);
                text(options.textX,options.textY,neurons{n},'HorizontalAlignment','center');

            end
            
            
        end
        
    end
        
    drawnow;
    
    if options.addTitle
        mtit(wbMakeShortTrialname(PPoptions.wbstruct.trialname));
    end
end


export_fig([options.outputDir filesep 'PhasePlotGrid-'  wbMakeShortTrialname(PPoptions.wbstruct.trialname) '.pdf'],'-painters','-nocrop','-pdf');

cd(folder);