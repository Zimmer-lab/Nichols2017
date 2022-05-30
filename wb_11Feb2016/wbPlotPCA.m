function [coeffLabels]=wbPlotPCA(wbstructOrFolder,wbpcastruct,options)

coeffLabels=[];

dataFolder=pwd;

%parse input
if nargin<1
    wbstructOrFolder='.';
end

if nargin<2
    wbpcastruct=[];
end

if nargin<3
    options=[];
end

%options defaults

if ~isfield(options,'plotSections')
    options.plotSections={'TPC','pareto','coeffs','phaseplot3D'};
end

if ~isfield(options,'subPlotFlag')
    options.subPlotFlag=false;
end

%coeff options
if  ~isfield(options,'horizontalCoeffPlotFlag')
    options.horizontalCoeffPlotFlag=false;
end

if  ~isfield(options,'rotateCoeffLabelsFlag')
    options.rotateCoeffLabelsFlag=true;
end

if ~isfield(options,'drawCoeffSeparators')
    options.drawCoeffSeparators=false;
end

if ~isfield(options,'externalCoeffs')
    options.externalCoeffs=[];
end

if ~isfield(options,'coeffSortMethod')
    options.coeffSortMethod='magnitude';
end

if ~isfield(options,'coeffSortParam')
    options.coeffSortParam=[];
end

if ~isfield(options,'barColor')
    options.barColor={MyColor('r'),MyColor('b')};
end


%TPC options
if ~isfield(options,'integrateDerivComponents')
   options.integrateDerivComponents=true;
end

if ~isfield(options,'plotNumComps')
   options.plotNumComps=5;
end

%pareto options
if ~isfield(options,'computeVAFOfPreNorm');
    options.computeVAFOfPreNorm=true;
end

if ~isfield(options,'numBars')
    options.numBars=10;
end

if ~isfield(options,'VAFYLim')
    options.VAFYLim=80;
end    

%phaseplot3D options
if ~isfield(options,'ghostTrajectoryRange')
    options.ghostTrajectoryRange=[];
else
    options.ghostTrajectoryRange=options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end);
end


if ~isfield(options,'smoothFlag')
   options.smoothFlag=false;
end

if ~isfield(options,'smoothingWindow')
   options.smoothingWindow=3;
end

if ~isfield(options,'offsetFlag')
    options.offsetFlag=false;
end

if ~isfield(options,'timeColoring')
   options.timeColoring=[];
end

if ~isfield(options,'timeColoringColorMap')
   options.timeColoringColorMap=[0 0 1;1 0 0;0 1 0;1 1 0];
end

if ~isfield(options,'timeColoringOverlay')
    options.timeColoringOverlay=[];
end

if ~isfield(options,'timeColoringOverlayColor') 
     options.timeColoringOverlayColor=[];
end
 
if ~isfield(options,'timeColoringOverlayLegend') 
    options.timeColoringOverlayLegend={};
end

if ~isfield(options,'timeColoringShiftBalls') 
    options.timeColoringShiftBalls=true;
end

if ~isfield(options,'lineWidth')
    options.lineWidth=1;
end

if ~isfield(options,'stimulusPlotSyle')
    options.stimulusPlotSyle='solid';  %solid bars or lines
end

if ~isfield(options,'plotSplitFigures')
    options.plotSplitFigures=false;
end

if ~isfield(options,'phasePlotsFlag')
   options.phasePlotsFlag=true;
end

if ~isfield(options,'phasePlot3DMainColor')
    options.phasePlot3DMainColor = 'b';
end

if ~isfield(options,'phasePlot3DFlag')
   options.phasePlot3DFlag = true;
end

if ~isfield(options,'phasePlot3DView')
    options.phasePlot3DView=[-15 16];
end

if ~isfield(options,'phasePlot3DFlipZ')
    options.phasePlot3DFlipZ=false;
end

if ~isfield(options,'phasePlot3DLimits')
    options.phasePlot3DLimits=[];
end

if ~isfield(options,'phasePlot3DDualMode')
    options.phasePlot3DDualMode=false;
end

if ~isfield(options,'phasePlot3DShowIntegratedComponents')
   options.phasePlot3DShowIntegratedComponents=false;
end

if ~isfield(options,'coloredPhasePlotsFlag')
   options.coloredPhasePlotsFlag=true;
end

if ~isfield(options,'plotPCExclusions')
   options.plotPCExclusions=[];
end

if ~isfield(options,'plotStimulus')
   options.plotStimulus=true;
end

if ~isfield(options,'plotGhostTrajectory')
   options.plotGhostTrajectory=false;
end

if ~isfield(options,'plotType')
   options.plotType=1;
end

if ~isfield(options,'savePDFFlag')
   options.savePDFFlag=false;
end

if ~isfield(options,'savePDFCopyDirectory')
   options.savePDFCopyDirectory='';
end

if ~isfield(options,'combinePDFFlag')
    options.combinePDFFlag=true;
end

if ~isfield(options,'saveViewButton')
    options.saveViewButton=true;
end

%load wbstruct and wbpcastruct
if ischar(wbstructOrFolder)
    dataFolder=wbstructOrFolder;
    [wbstruct,wbstructFileName]=wbload(wbstructOrFolder,false);
else  %wbstruct is a struct
    wbstruct=wbstructOrFolder;
end

if isempty(wbpcastruct)
    wbpcastruct=wbLoadPCA(wbstructOrFolder);
end

dateRan=wbpcastruct.dateRan;

if isfield(wbpcastruct,'flagstr')
    flagstr=wbpcastruct.flagstr;
end

%prepare components

if ~isempty(options.externalCoeffs)
    forPlotting.coeffs=options.externalCoeffs;
else 
    forPlotting.coeffs=wbpcastruct.coeffs;
end
forPlotting.coeffs(:,options.plotPCExclusions)=[];


if ~isempty(options.externalCoeffs)
    
    options.fieldName='deltaFOverF';
    options.preNormalizationType='peak';
    
    if ~isfield(options,'neuronSubset')
        options.neuronSubset=1:size(options.externalCoeffs,2);
    end
    

    [~,simpleIndices]=wbGetTraces(wbstruct,[],[],options.neuronSubset);

    pretraces0=wbstruct.simple.(options.fieldName)(:,simpleIndices);
    pretraces0(isnan(pretraces0(:)))=0;
    pretraces0=detrend(pretraces0,'linear');
    
    pretraces1= wbstruct.simple.derivs.traces(:,simpleIndices);
    
    if strcmpi(options.preNormalizationType,'peak')

        traces=pretraces1.*repmat(1./max(abs(pretraces0),[],1),size(pretraces1,1),1);                
        
    else
        traces=pretraces1;
    end
    
    
    forPlotting.pcs=zeros(size(wbpcastruct.pcs));
    forPlotting.pcsFullRangeProjections=zeros(size(wbpcastruct.pcsFullRangeProjections));
    
    %reproject time series
    

    for j=1:size(options.externalCoeffs,1)
         
         for i=1:size(options.externalCoeffs,2)
            forPlotting.pcsFullRange(:,j)=forPlotting.pcsFullRange(:,j) + options.externalCoeffs(j,i)*traces(:,i);
            forPlotting.pcsFullRange(:,j)=forPlotting.pcsFullRange(:,j) + options.externalCoeffs(j,i)*traces(:,i);
         end
    end   
else
    forPlotting.pcs=wbpcastruct.pcs;
    if isfield(wbpcastruct,'pcsFullRange')
        forPlotting.pcsFullRange=wbpcastruct.pcsFullRange;
    else
        forPlotting.pcsFullRange=wbpcastruct.pcs;
    end
    
end



forPlotting.pcs(:,options.plotPCExclusions)=[];


forPlotting.varianceExplained=wbpcastruct.varianceExplained;
forPlotting.varianceExplained(options.plotPCExclusions)=[];

forPlotting.numN=options.numBars; %numN-length(options.plotExclusions);
 
if ~isempty(options.externalCoeffs)
    forPlotting.neuronLabels=wbpcastruct.neuronIDs;
else
    forPlotting.neuronLabels=wbpcastruct.neuronIDs;
end

if options.phasePlot3DShowIntegratedComponents

    forPlotting.pcs=detrend(cumsum(forPlotting.pcs),'linear');

end

%apply smoothing
if options.smoothFlag
    forPlotting.pcs=fastsmooth(forPlotting.pcs,options.smoothingWindow,3,1);
end


%more options, those whose defaults are wbpcastruct-dependent

if ~isfield(options,'plotTimeRange')  
    options.plotTimeRange=wbpcastruct.options.range;
else
    flagstr=[flagstr '-show[' num2str(options.plotTimeRange(1))  '-' num2str(options.plotTimeRange(end)) ']' ];
end

%%Set default color

%    options.timeColoring=10*ones(size(wbpcastruct.options.range),'uint8');
%    options.timeColoring(1)=0;
%    options.timeColoring(2)=255;
%    

% if isempty(options.ghostTrajectoryRange)
%     options.ghostTrajectoryRange=options.plotTimeRange;
% end

handles=[];

%end options
%% PLOTTING

    if options.phasePlot3DDualMode
        nc=3;
    else
        nc=2;
    end

    %% temporal PCs    
    
    if ~options.subPlotFlag
        
        if (options.plotSplitFigures)
            f=figure('Position',[0 0 1500 100*options.plotNumComps ]);   
        else
            f=figure('Position',[0 0 1200 1000 ]); 
            subtightplot(2,nc,1,[0.05 .05]);

            if wbpcastruct.options.derivFlag
                title('derivative PCs');
            else
                title('regular PCs');
            end
        end
    
    end
    
    %delete old copy of PDFs
    if options.savePDFFlag && options.combinePDFFlag
        
        saveFileName=[dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'];
        if exist(saveFileName,'file')
            delete(saveFileName);   
        end
        
        if ~isempty(options.savePDFCopyDirectory)
            saveCopyFileName=[options.savePDFCopyDirectory filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'];
            if exist(saveCopyFileName,'file')
                delete(saveCopyFileName);
            end
        end        
        
    end
    
    
    if sum(ismember('TPC',options.plotSections))
    
        xlim([ wbstruct.tv(options.plotTimeRange(1)) wbstruct.tv(options.plotTimeRange(end))]);
        ylim([0.5 options.plotNumComps+1]);

        if options.plotStimulus
              wbplotstimulus(wbstruct,[],[],[],options.stimulusPlotSyle);
        end

        if size(forPlotting.pcs,2)<options.plotNumComps
            forPlotting.pcs=[forPlotting.pcs, zeros(size(forPlotting.pcs,1),options.plotNumComps-size(forPlotting.pcs,2))];
        end
        
        for nn=1:options.plotNumComps
            hline(options.plotNumComps-nn+1);
            hold on;

            if options.integrateDerivComponents && wbpcastruct.options.derivFlag
                scaleFactor=1.1*max(abs(detrend(cumsum(forPlotting.pcs(:,1)),'linear')));
                scaleFactorFR=1.1*max(abs(detrend(cumsum(forPlotting.pcsFullRange(:,1)),'linear')));
                if ~isfield(options,'componentTimeColoring')    %main plot line
                    plot(wbstruct.tv,(options.plotNumComps-nn+1)+detrend(cumsum(forPlotting.pcsFullRange(:,nn)),'linear')/scaleFactorFR,'LineWidth',options.lineWidth,'Color',MyColor('gray'));
                    if isfield(options,'plotTimeSubRange')
                        hold on;
                        plot(wbstruct.tv(options.plotTimeSubRange),(options.plotNumComps-nn+1)+detrend(cumsum(forPlotting.pcs(:,nn)),'linear')/scaleFactor,'LineWidth',options.lineWidth,'Color','k');
                    end
                else
                    
                    
                    line_handle=color_line2(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+detrend(cumsum(forPlotting.pcs(:,nn)),'linear')/scaleFactor,options.plotTimeRange);
                    set(line_handle,'LineWidth',options.lineWidth);
                end            
            else
                if ~isfield(options,'componentTimeColoring')  

                    plot(wbstruct.tv,(options.plotNumComps-nn+1)+normalize(forPlotting.pcsFullRangeProjections(:,nn)),'LineWidth',options.lineWidth,'Color',[0.5 0.5 0.5]);
                    hold on;
                    plot(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+normalize(forPlotting.pcs(options.plotTimeRange,nn)),'LineWidth',options.lineWidth,'Color','k');

                else 
                    
                    line_handle=color_line2(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+12*forPlotting.pcs(:,nn)/1.5,options.plotTimeRange);
                    set(line_handle,'LineWidth',options.lineWidth);
                end
            end

        end
     

        xlabel('time (s)');

        if wbpcastruct.options.derivFlag
            if options.integrateDerivComponents
                ylabel('integrated PC(deriv) #');
            else
                ylabel('PC(deriv) #');
            end
        else 
            ylabel('PC#');   
        end

        set(gca,'YTick',1:options.plotNumComps);
        set(gca,'YTickLabel',options.plotNumComps:-1:1);
        SmartTimeAxis([0 wbstruct.tv(options.plotTimeRange(end))]);

        box off;
    
        if (options.plotSplitFigures)
            title([wbstruct.displayname ' ' flagstr]);
        end

        if (options.savePDFFlag) && (options.plotSplitFigures)
              if options.combinePDFFlag

                export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append');
                if ~isempty(options.savePDFCopyDirectory)
                    export_fig([options.savePDFCopyDirectory filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append');
                end

              else

                   export_fig([dataFolder filesep 'Quant' filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) '-' num2str(options.plotNumComps) 'PCs' flagstr  '.pdf']);
                   if ~isempty(options.savePDFCopyDirectory)
                        export_fig([options.savePDFCopyDirectory filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) '-' num2str(options.plotNumComps) 'PCs' flagstr '.pdf']);
                   end
              end

        end

    end
      
    %% VAF Pareto plot
    %
    if ~options.subPlotFlag
        if (options.plotSplitFigures)
            figure;
        else
            subtightplot(2,nc,nc+1,[0.05 .05]); 
            %handles.paretoPlot = axes('Position', [0.12 0.12 0.8 0.8]);
        end
    end
    
    if sum(ismember('pareto',options.plotSections))

        
        if options.computeVAFOfPreNorm  %recompute VAFs on pre-normed dataset
            reconOptions.numComps=min([options.numBars length(forPlotting.varianceExplained) ]);
            reconOptions.plotFlag=false;
            
            cumVarEx=wbReconstructDataset([],wbpcastruct,reconOptions);

            forPlotting.varianceExplained=sort([cumVarEx(1); diff(cumVarEx)'],'descend');
        end
        
        if length(forPlotting.varianceExplained)<options.numBars
            forPlotting.varianceExplained=[forPlotting.varianceExplained; zeros(options.numBars-length(forPlotting.varianceExplained),1)];
        end
        
        bar(forPlotting.varianceExplained(1:options.numBars)','FaceColor',[0.6 0.6 0.6]);
        hold on;
        plot(1:forPlotting.numN,[ cumsum(forPlotting.varianceExplained(1:options.numBars))],'.-','MarkerSize',14,'LineWidth',2,'Color','k');

        ylim([0 options.VAFYLim]);xlim([0 options.numBars+0.5]);
        xlabel('PC');ylabel('variance explained (%)');
        box off;
        set(gca,'Color','w');

        if (options.plotSplitFigures)
            mtit([wbstruct.displayname ' -' flagstr]);
        end


        if ~isfield(wbpcastruct.options,'dimRedType')
            wbpcastruct.options.dimRedType='PCA';
        end


        if (options.savePDFFlag) && (options.plotSplitFigures)
            if options.combinePDFFlag
                export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append','-painters');
                if ~isempty(options.savePDFCopyDirectory)
                    export_fig([options.savePDFCopyDirectory filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-painters','-append');
                end        
            else
                export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) '-vafs' flagstr '.pdf'],'-painters');
                if ~isempty(options.savePDFCopyDirectory)
                    export_fig([options.savePDFCopyDirectory filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) '-vafs' flagstr '.pdf'],'-painters');
                end
            end
        end
    end
    
    if sum(ismember('paretoinset',options.plotSections))

        %VAF pareto plot ALL components INSET
        if (options.plotSplitFigures)
            figure;
            hold on;
            title([wbstruct.displayname ' -' flagstr]);
            ylabel('variance explained (%)');
        else
            %subplot(2,nc,nc+1); 
            handles.paretoInsetPlot=axes('Position', [0.1 0.32 0.1 0.1],'Color','w');

        end

        plot(forPlotting.varianceExplained','r-','MarkerSize',14,'LineWidth',1);
        plot(0:length(forPlotting.varianceExplained'),[0; cumsum(forPlotting.varianceExplained)],'-','MarkerSize',14,'LineWidth',1);

        ylim([0 max([101 max(cumsum(forPlotting.varianceExplained))])]);xlim([0 length(forPlotting.varianceExplained')+0.5]);
        hline(100);
        xlabel('PC');

        box off;
      
    end
      
    %% coefficient bar plots

        
    if sum(ismember('coeffs',options.plotSections))
        
        numEVs=min([ size(forPlotting.coeffs,2) options.plotNumComps ]);
        
        if ~options.subPlotFlag
            if options.plotSplitFigures
                f=figure('Position',[0 0 1500 100*numEVs ]);   
            else
                %subplot(2,nc,nc+2);   
            end   
        end
    
                
        for nn=1:numEVs

            if ~options.subPlotFlag
                if ~options.plotSplitFigures
                    axes('Position',[.53 .5-.45*nn/numEVs .4 .18/numEVs]);
                else
                    subtightplot(numEVs,1,nn,[0.04 0.05],[.1 .1],[.1 .1]);  %.08
                end
            end
            
            
            hold on;
            %subplot(options.plotNumComps,1,nn);

            %sort coeffs
            if strcmp(options.coeffSortMethod,'magnitude')
                [~, coeffSortIndex]=sort(abs(forPlotting.coeffs(:,nn)),1,'descend');
            else  %pca top loading, signed
                [~,coeffSortIndex,~,eAD]=wbSortTraces(wbstruct.simple.derivs.traces,options.coeffSortMethod,[],options.coeffSortParam);

            end
            
            coeffSign=sign(forPlotting.coeffs(coeffSortIndex,nn));     
            
            if options.horizontalCoeffPlotFlag
                %handles.bar=barh(forPlotting.coeffs(coeffSortIndex,nn));

                handles.bar(1)=barh(find(coeffSign>0),forPlotting.coeffs(coeffSortIndex(coeffSign>0),nn),'FaceColor',options.barColor{1},'EdgeColor','none');
                hold on;
                handles.bar(2)=barh(find(coeffSign<0),forPlotting.coeffs(coeffSortIndex(coeffSign<0),nn),'FaceColor',options.barColor{2},'EdgeColor','none');
   
                xlabel(['PC' num2str(nn)]);
                ylim([0 length(forPlotting.neuronLabels)+1]);
                set(gca,'YTick',1:length(forPlotting.neuronLabels));
                set(gca,'YTickLabel',forPlotting.neuronLabels(coeffSortIndex));                
            else
                
                if ~isempty(find(coeffSign>0))
                    handles.bar(1)=bar(find(coeffSign>0),forPlotting.coeffs(coeffSortIndex(coeffSign>0),nn),'FaceColor',options.barColor{1},'EdgeColor','none');
                end
                hold on;
                

                if ~isempty(find(coeffSign<0))
                    handles.bar(2)=bar(find(coeffSign<0),forPlotting.coeffs(coeffSortIndex(coeffSign<0),nn),'FaceColor',options.barColor{2},'EdgeColor','none');
                end
                
                ylabel(['PC' num2str(nn)]);
                xlim([0 length(forPlotting.neuronLabels)+1]);
                
                
                
                
                set(gca,'XTick',1:length(forPlotting.neuronLabels));
                set(gca,'XTickLabel',forPlotting.neuronLabels(coeffSortIndex));
            end
            
            
           % set(get(handles.bar,'children'),'FaceVertexCData',(-coeffSign+1)/2+0.5);
           
            caxis([-1 1]);

            coeffLabels=forPlotting.neuronLabels(coeffSortIndex);
            if options.rotateCoeffLabelsFlag && ~options.horizontalCoeffPlotFlag
                
                if verLessThan('matlab','8.4')
                   % <=R2014a
                   rotateXLabels(gca,90);
                else
                   % >R2014a
                   set(gca, 'XTickLabelRotation', 90);
                end
                
            end
           
            if options.drawCoeffSeparators
               
                 
                   sepX=find(diff(eAD{2}));
                   hline(sepX+0.5);
                
             end
        end


        if (options.plotSplitFigures)
            mtit([wbstruct.displayname ' -' flagstr]);
        end

        if (options.savePDFFlag) && (options.plotSplitFigures)

            if options.combinePDFFlag
                export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append','-painters');
                if ~isempty(options.savePDFCopyDirectory)
                    export_fig([options.savePDFCopyDirectory filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append','-painters');
                end        
            else
                 export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) '-' num2str(options.plotNumComps) 'COEFFs' flagstr  '.pdf'],'-painters');
                 if ~isempty(options.savePDFCopyDirectory)
                        export_fig([options.savePDFCopyDirectory filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) '-' num2str(options.plotNumComps) 'COEFFs' flagstr '.pdf'],'-painters');
                 end
            end               
        end
       
    end
      
    %% 3D phase plot
    
    if sum(ismember('phaseplot3D',options.plotSections))

        
        if ~iscell(options.phasePlot3DView)
            
              options.phasePlot3DView={options.phasePlot3DView};
        end
            
        for vv=1:numel(options.phasePlot3DView)
                
                
            if options.phasePlot3DFlag      


                 theseOptions=options;

                 theseOptions.phasePlot3DView=options.phasePlot3DView{vv};
                 
                 theseOptions.timeColoring={theseOptions.timeColoring};

                 theseOptions.plotClusters=false;
                 theseOptions.interactiveMode=false;
                 theseOptions.subPlot=~options.plotSplitFigures;
                 theseOptions.projectOntoFirstSpace=false;
                 theseOptions.phasePlot3DDualMode=false;
                 if ~options.plotSplitFigures
                      subtightplot(2,nc,2,[0.05 0.05]);
                 end

                 
                 wbPhasePlot3D(forPlotting.pcsFullRange,theseOptions);

            end



            if (options.savePDFFlag) && options.plotSplitFigures
                saveas(gcf, [dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) '-phaseplots' flagstr '.fig'], 'fig');
                if options.combinePDFFlag
                    export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append','-painters');
                    if ~isempty(options.savePDFCopyDirectory)
                        export_fig([options.savePDFCopyDirectory filesep 'PCA-'  wbMakeShortTrialname(wbstruct.trialname) flagstr '.pdf'],'-append','-painters');
                    end        
                else

                    export_fig([dataFolder filesep 'Quant' filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) '-phaseplots' flagstr '.pdf'],'-painters');
                    if ~isempty(options.savePDFCopyDirectory)
                        export_fig([options.savePDFCopyDirectory filesep 'PCA-' wbMakeShortTrialname(wbstruct.trialname) '-phaseplots' flagstr '.pdf'],'-painters');
                    end
                end
            end

        
        end
        
        
        
        
        
        
        
        
    end

    

    %end main
    
    %% Callbacks
    
    function saveViewButtonCallback
        set(handles.saveViewButton,'Visible','off');
        thisview=get(gca,'View');
        %disp(['3D view: ' num2str(thisview(1)) '  ' num2str(thisview(2))]);
        %set(handle.viewText,'String',[num2str(thisview(1)) '  ' num2str(thisview(2))]);
        viewstr=['(' num2str(thisview(1)) '-' num2str(thisview(2)) ')'];
        
        [dataFolder filesep 'Quant' filesep 'PCA-' wbstruct.trialname '-phaseplots' flagstr '-view' viewstr '.pdf']
        
%         save2pdf([dataFolder filesep 'Quant' filesep 'pca-' wbstruct.trialname '-phaseplots' flagstr '-view' viewstr '.pdf']);
%         if ~isempty(options.savePDFCopyDirectory)
%            save2pdf([options.savePDFCopyDirectory filesep 'pca-' wbstruct.trialname '-phaseplots' flagstr '-view' viewstr '.pdf']);
%         end
        
        
        set(handles.saveViewButton,'Visible','on');
        
         cameraViewParams.CameraPosition=get(gca,'CameraPosition');
         cameraViewParams.CameraPositionMode=       get(gca,'CameraPositionMode' );
         cameraViewParams.CameraTarget=      get(gca,'CameraTarget') ;
         cameraViewParams.CameraTargetMode=     get(gca,'CameraTargetMode' );
         cameraViewParams.CameraUpVector=    get(gca,'CameraUpVector') ;
         cameraViewParams.CameraUpVectorMode=    get(gca,'CameraUpVectorMode' );
         cameraViewParams.CameraViewAngle=       get(gca,'CameraViewAngle' );
         cameraViewParams.CameraViewAngleMode=get(gca,'CameraViewAngleMode' );    
        cameraViewParams.View=      get(gca,'View' );
         save('cameraViewParams.mat','-struct','cameraViewParams');
        
        
        
    end
    
    function set3DViewsCallback(plot3D_num)
        
        if options.phasePlot3DDualMode
           
            if ishghandle(handles.plot3D(3-plot3D_num))
                set(handles.plot3D(3-plot3D_num),'CameraPosition',get(handles.plot3D(plot3D_num),'CameraPosition'));
                %set(handles.plot3D(3-plot3D_num),'CameraUpVector',get(handles.plot3D(plot3D_num),'CameraUpVector'));
                %set(handles.plot3D(3-plot3D_num),'CameraTarget',get(handles.plot3D(plot3D_num),'CameraTarget'));
                %set(handles.plot3D(3-plot3D_num),'CameraViewAngle',get(handles.plot3D(plot3D_num),'CameraViewAngle'));
                set(handles.plot3D(3-plot3D_num),'CameraViewAngleMode','auto');
            end
        
        end
    end




end
    



