function wbpcastruct=wbpca(wbstructOrFolder,options)
%wbpcastruct=WBPCA(wbstruct,options)
%options:
%
% options.integrateDerivComponents (true);
% options.derivFlag (false)
% options.preNormFlag (false)
% options.saveFlag (true)
% options.plotFlag (true)
% options.phasePlotsFlag (true)
% options.timeColoring=[];
% options.plotExclusions ([])
% options.savePDFFlag (true)
% options.savePDFCopyDirectory ('')
% options.range  (all)
% options.numPCs (10)

if nargin<1
    wbstructOrFolder=pwd;
end

if ischar(wbstructOrFolder)
    dataFolder=wbstructOrFolder;
    wbstruct=wbload(dataFolder);
else
    dataFolder=pwd;
    wbstruct=wbstructOrFolder;
end

if nargin<2
    options=[];
end


if ~isfield(options,'ghostTrajectoryRange')
    options.ghostTrajectoryRange=[];
end

if ~isfield(options,'derivRegFlag')
    options.derivRegFlag=true;
end

if ~isfield(options,'usePrecomputedDerivs')
    options.usePrecomputedDerivs=true;
end
 
if ~isfield(options,'integrateDerivComponents')
   options.integrateDerivComponents=true;
end

if ~isfield(options,'smoothFlag')
   options.smoothFlag=true;
end

if ~isfield(options,'smoothingWindow')
   options.smoothingWindow=10;
end

if ~isfield(options,'offsetFlag')
    options.offsetFlag=false;
end

if ~isfield(options,'timeColoringOverlay')
    options.timeColoringOverlay=[];
end

if ~isfield(options,'lineWidth')
    options.lineWidth=1;
end

if ~isfield(options,'plotSplitFigures')
    options.plotSplitFigures=false;
end

if ~isfield(options,'extraExclusionList')
    wbpcastruct.exclusionList=[]; 
else
    if iscell(options.extraExclusionList)     

        for nn=1:length(options.extraExclusionList)   
            [~, neuronsToExclude(nn)] = wbgettrace(options.extraExclusionList{nn},wbstruct);
        end
        wbpcastruct.exclusionList=neuronsToExclude(~isnan(neuronsToExclude));
        
    else
        wbpcastruct.exclusionList=options.extraExclusionList;
    end
end

if ~isfield(options,'derivFlag')
   options.derivFlag=false;
end

if ~isfield(options,'preNormFlag')
   options.preNormFlag=false;
end

if ~isfield(options,'saveFlag')
   options.saveFlag=true;
end

if ~isfield(options,'plotFlag')
   options.plotFlag=true;
end

if ~isfield(options,'phasePlotsFlag')
   options.phasePlotsFlag=true;
end

if ~isfield(options,'phasePlot3DFlag')
   options.phasePlot3DFlag = false;
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

if ~isfield(options,'phasePlot3DShowIntegratedComponents')
   options.phasePlot3DShowIntegratedComponents=false;
end

if ~isfield(options,'coloredPhasePlotsFlag')
   options.coloredPhasePlotsFlag=true;
end

if ~isfield(options,'plotExclusions')
   options.plotExclusions=[];
end

if ~isfield(options,'plotStimulus')
   options.plotStimulus=true;
end

if ~isfield(options,'plotGhostTrajectory')
   options.plotGhostTrajectory=true;
end

if ~isfield(options,'plotNumComps')
   options.plotNumComps=5;
end

if ~isfield(options,'plotType')
   options.plotType=1;
end

if ~isfield(options,'savePDFFlag')
   options.savePDFFlag=true;
end

if ~isfield(options,'savePDFCopyDirectory')
   options.savePDFCopyDirectory='';
end

if ~isfield(options,'numBars')
    options.numBars=10;
end

if ~isfield(options,'VAFYLim')
    options.VAFYLim=80;
end    
   

%%interactive prompts
if nargin<1   
    reply = input('[S]tandard or [d]eriv:','s');
    if strcmp(reply,'d')
         disp('doing PCA on derivatives.');
         options.derivFlag=true;
    end

    
    if options.derivFlag
        reply = input('[R]egularized deriv. or [t]raditional:','s');
        
        if strcmp(reply,'t');
            disp('using traditional deriv (pre-smoothed differencing).');
            options.derivRegFlag=false;
        else
            
            reply = input('Use [P]recomputed reg. deriv. or [r]ecompute:','s');
            if strcmp(reply,'r')
                options.usePrecomputedDerivs=false;
            else
                options.usePrecomputedDerivs=true;
            end
     
        end
        
        reply = input('Show integrated PC timeseries [Y/n]:','s');
        if strcmp(reply,'n');
            disp('not integrating PCs.');
            options.integrateDerivComponents=false;
        end

        reply = input('Show [D]erivs or [i]ntegrated PCs on 3D phase plot:','s');
        if strcmp(reply,'i')
             disp('Plotting integrated components on 3D phase plot.');
             options.phasePlot3DShowIntegratedComponents=true;
        end
    end
    
    reply = input('[U]nsmoothed or [s]moothed PCs:','s');
    if strcmp(reply,'s')
         disp(['smoothing applied with options.smoothingWindow=' num2str(options.smoothingWindow)]);
         options.smoothFlag=true;
    else
        disp('(traditional deriv. is still pre-smoothed.)');
    end
    
    reply = input('Use [C]ovariance or co[r]relation:','s');
    if strcmp(reply,'r')
         disp('doing PCA on correlation.');
         options.preNormFlag=true;
    end
    
    reply = input('Use [S]tandard or [o]ffset estimator:','s');
    if strcmp(reply,'o')
         disp('doing offset PCA.');
         options.offsetFlag=true;
         
    end
    
    

    
end

if nargin<1 || isempty(wbstructOrFolder)
    wbstruct=wbload([],false);
end


flagstr=[];
if (options.derivFlag) flagstr=[flagstr '-deriv']; end  %this must be the first flag for proper parsing by wbPlotPCADouble (tbd)
if (options.preNormFlag) flagstr=[flagstr '-pn']; end
if (options.smoothFlag) flagstr=[flagstr '-sm']; end
if (options.offsetFlag) flagstr=[flagstr '-of']; end

%exclusions flagstr
excString=num2str(options.plotExclusions); excString(excString==' ')=[];
if ~isempty(options.plotExclusions), flagstr=[flagstr '-exc(' excString ')']; end

numN=wbstruct.nn;
numT=length(wbstruct.tv);

if nargin<2 || ~isfield(options,'range')  %analysis Range
   options.range=1:length(wbstruct.tv);
else
    flagstr=[flagstr '-[' num2str(options.range(1))  '-' num2str(options.range(end)) ']' ];
end

%% plotting options

if nargin<2 || ~isfield(options,'plotTimeRange')  
   options.plotTimeRange=options.range;
else
    flagstr=[flagstr '-view[' num2str(options.plotTimeRange(1))  '-' num2str(options.plotTimeRange(end)) ']' ];
end


if isempty(options.ghostTrajectoryRange)
    options.ghostTrajectoryRange=options.range;
end

%%SET default color
if nargin<2 || ~isfield(options,'timeColoring')
    
   options.timeColoring=10*ones(size(options.range),'uint8');
   options.timeColoring(1)=0;
   options.timeColoring(2)=255;
end

plotTimeRangeRel=options.plotTimeRange - options.range(1) + 1;


%%

if options.preNormFlag
    pretraces=normalize(wbstruct.deltaFOverF(options.range,:),-3);
    disp('normalizing.');
else
    pretraces=wbstruct.deltaFOverF(options.range,:);

end

%replace NaNs with zeros 
pretraces(isnan(pretraces(:)))=0;

pretraces=detrend(pretraces,'linear');



%compute derivative (dPCA) if flag on
if options.derivFlag 
    if options.derivRegFlag
        if options.usePrecomputedDerivs
             if isfield(wbstruct,'derivs')
                 traces=wbstruct.derivs.traces;
             else
                 disp('No precomputed derivs found in wbstruct.  Will recompute.');
                 traces=derivReg(pretraces);
             end          
        else
             traces=derivReg(pretraces);   
        end
        
        if options.smoothFlag
            disp('bro')
            traces=fastsmooth(traces,options.smoothingWindow,3,1);
        end
          
    else
        if options.smoothFlag
            traces=fastsmooth(deriv(detrend(fastsmooth(pretraces,5,3,1),'constant')),options.smoothingWindow,3,1);
        else
            traces=deriv(detrend(fastsmooth(pretraces,5,3,1),'constant'));
        end
    end
else 
    if options.smoothFlag
        disp('yo')
        traces=fastsmooth(pretraces,options.smoothingWindow,3,1);
    else
        traces=pretraces;
    end
      
end

%WB specific: exclude neurons that are marked for exclusion


if isfield(wbstruct,'exclusionList')
    wbpcastruct.exclusionList=[wbpcastruct.exclusionList wbstruct.exclusionList];
    traces(:,wbpcastruct.exclusionList)=[];
    numN=size(traces,2);
end


traces=detrend(traces,'constant');
%compute
tic
if options.offsetFlag %offset PCA

%     [pcs.COEFF,pcs.LATENT,pcs.EXPLAINED] = pcacov(covOffset(traces));  %across time
  [pcs.COEFF,pcs.LATENT]=eig(covOffset(traces));
  pcs.LATENT=diag(pcs.LATENT);
  pcs.LATENT=pcs.LATENT(end:-1:1);
  pcs.COEFF=pcs.COEFF(:,end:-1:1);
  pcs.EXPLAINED=pcs.LATENT*100/sum(pcs.LATENT);
     pcs.PC=zeros(length(traces(:,1)),length(pcs.EXPLAINED));
     for j=1:length(pcs.EXPLAINED)

         for i=1:length(pcs.EXPLAINED)
            pcs.PC(:,j)=  pcs.PC(:,j) + pcs.COEFF(i,j)*traces(:,i);
         end
 
     end
    
    pcs.PCCOEFF_D2=normalize(pcs.PC,-3)/50;
    pcs.EXPLAINED_D1=pcs.EXPLAINED;
    pcs.PC_D1=normalize(pcs.PC,-3);
    
     
else %regular PCA

    [pcs.PCCOEFF_D1, pcs.PC_D1, pcs.LATENT_D1, pcs.TSQUARED_D1, pcs.EXPLAINED_D1, pcs.MU_D1] = pca(traces);  %across time

    pcs
    
    [pcs.PCCOEFF_D2, pcs.PC_D2, pcs.LATENT_D2, pcs.TSQUARED_D2, pcs.EXPLAINED_D2, pcs.MU_D2] = pca(traces'); %across neuron

    pcs
  % pcs.PCCOEFF_D2=pcs.PC_D1;
end
toc




% roll your own PCA

% tic
%  [pcs_m2.COEFF,pcs_m2.LATENT,pcs_m2.EXPLAINED] = pcacov(cov(traces));  %across time
%  
%  pcs_m2.PC=zeros(length(traces(:,1)),length(pcs_m2.EXPLAINED));
%  for j=1:length(pcs_m2.EXPLAINED)
%      
%      for i=1:length(pcs_m2.EXPLAINED)
%         pcs_m2.PC(:,j)=  pcs_m2.PC(:,j) + pcs_m2.COEFF(i,j)*traces(:,i);
%      end
%  
%  end
% toc
%figure;plot(pcs_m2.PC(:,1));hold on;plot(pcs_m2.PC(:,2)+1,'r');


assignin('base','pcs',pcs)
%assignin('base','pcms',pcs_m2)

%deprecated princomp matlab function- this is totally equivalent so don't bother,
%just here for reference
%[a.pcvectors1 a(tr).pcscores1]=princomp(a);
%[a.pcvectors2 a(tr).pcscores2]=princomp(a');

%this is the same as looking at the coeffs.
% for t=1:numT
% %     %project traces onto first pcs  (do i need to explicitly norm pc's?) 
%      hts.PCproj(t,1)=  dot(traces(t,:),hts.PC_D2(:,1));
%      hts.PCproj(t,2)=  dot(traces(t,:),hts.PC_D2(:,2));    
% end
% 

%save out wbpcastruct
wbpcastruct.pcs=pcs;
wbpcastruct.dateRan=datestr(now);
wbpcastruct.options=options;

if options.saveFlag
    save([dataFolder filesep 'Quant' filesep 'wbpcastruct' flagstr '.mat'],'wbpcastruct');
    save([dataFolder filesep 'Quant' filesep 'wbpcastruct' flagstr '-' strrep(strrep(datestr(now),':','-'),' ','-') '.mat'],'wbpcastruct');
end


%% PLOT SECTION
%


if (options.plotFlag) 
    
    %Component time series
    %
    
    if (options.plotSplitFigures)
        figure('Position',[0 0 1500 100*options.plotNumComps ]);   
    else
        figure('Position',[0 0 1000 800 ]); 
        subplot(2,2,1);
    end

    
    %exclude components
    forPlotting.pcs.PCCOEFF_D2=pcs.PCCOEFF_D2;
    forPlotting.pcs.PCCOEFF_D2(:,options.plotExclusions)=[];
    
    xlim([ wbstruct.tv(options.plotTimeRange(1)) wbstruct.tv(options.plotTimeRange(end))]);

    for nn=1:options.plotNumComps
        hline(options.plotNumComps-nn+1);
        hold on;
        
        if options.integrateDerivComponents && options.derivFlag
            if ~isfield(options,'componentTimeColoring')
                plot(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+1200*detrend(cumsum(forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,nn)),'linear')/1.5/2000,'LineWidth',options.lineWidth);
            else
                line_handle=color_line2(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+1200*detrend(cumsum(forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,nn)),'linear')/1.5/2000,plotTimeRangeRel);
                set(line_handle,'LineWidth',options.lineWidth);
            end            
        else
            if ~isfield(options,'componentTimeColoring')
                plot(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+12*forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,nn)/1.5,'LineWidth',options.lineWidth);
            else
                line_handle=color_line2(wbstruct.tv(options.plotTimeRange),(options.plotNumComps-nn+1)+12*forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,nn)/1.5,plotTimeRangeRel);
                set(line_handle,'LineWidth',options.lineWidth);
            end
        end

        
    end
     
    xlabel('time (s)');
    ylim([0 options.plotNumComps+1]);
    
    if options.derivFlag
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
    set(gca,'XTick',0:30:wbstruct.tv(options.plotTimeRange(end)));
    if options.plotStimulus
          wbplotstimulus(wbstruct);
    end

    box off;
    
    if (options.plotSplitFigures)
        title([wbstruct.displayname ' -' flagstr]);
    end
    
    if (options.savePDFFlag) && (options.plotSplitFigures)
       export_fig([dataFolder filesep 'Quant' filesep 'pca-' wbstruct.trialname '-' num2str(options.plotNumComps) 'PCs-' flagstr  '.pdf']);
       if ~isempty(options.savePDFCopyDirectory)
            export_fig([options.savePDFCopyDirectory filesep 'pca-' wbstruct.trialname '-' num2str(options.plotNumComps) 'PCs-' flagstr '.pdf']);
       end
    end

    %VAF Pareto Plot
    %
    if (options.plotSplitFigures)
        figure;
    else
        subplot(2,2,3);   
    end
    
    %exclude components     
    forPlotting.pcs.EXPLAINED_D1=pcs.EXPLAINED_D1;
    forPlotting.pcs.EXPLAINED_D1(options.plotExclusions)=[];
    forPlotting.numN=options.numBars; %numN-length(options.plotExclusions);
    
    bar(forPlotting.pcs.EXPLAINED_D1(1:options.numBars)','FaceColor',[0.6 0.6 0.6]);
    hold on;
    plot(0:forPlotting.numN,[0; cumsum(forPlotting.pcs.EXPLAINED_D1(1:options.numBars))],'.-','MarkerSize',14,'LineWidth',2);

    ylim([0 options.VAFYLim]);xlim([0 options.numBars+0.5]);
    xlabel('PC');ylabel('variance explained (%)');
    box off;
    
    if (options.plotSplitFigures)
        mtit([wbstruct.displayname ' -' flagstr]);
    end
    
    if (options.savePDFFlag) && (options.plotSplitFigures)
        export_fig([dataFolder filesep 'Quant' filesep 'pca-' wbstruct.trialname '-vafs-' flagstr '.pdf']);
        if ~isempty(options.savePDFCopyDirectory)
            export_fig([options.savePDFCopyDirectory filesep 'pca-' wbstruct.trialname '-vafs-' flagstr '.pdf']);
        end
    end
  
    
    forPlotting.pcs.PCCOEFF_D2=pcs.PCCOEFF_D2;
    forPlotting.pcs.PCCOEFF_D2(:,options.plotExclusions)=[];
    forPlotting.pcs.PC_D1=pcs.PC_D1;
    forPlotting.pcs.PC_D1(:,options.plotExclusions)=[];
            
    
    if options.phasePlot3DShowIntegratedComponents
        
        forPlotting.pcs.PC_D1=detrend(cumsum(forPlotting.pcs.PC_D1),'linear');
        
    end
    
    %VAF pareto plot ALL components
    if (options.plotSplitFigures)
        figure;
    else
        subplot(2,2,4);   
    end
    
    plot(forPlotting.pcs.EXPLAINED_D1','r.-','MarkerSize',14,'LineWidth',2);
    hold on;
    plot(0:length(forPlotting.pcs.EXPLAINED_D1'),[0; cumsum(forPlotting.pcs.EXPLAINED_D1)],'.-','MarkerSize',14,'LineWidth',2);

    ylim([0 max(cumsum(forPlotting.pcs.EXPLAINED_D1))]);xlim([0 length(forPlotting.pcs.EXPLAINED_D1')+0.5]);
    hline(100);
    xlabel('PC');ylabel('variance explained (%)');
    box off;
    
    
    
    if (options.plotSplitFigures)
        
        if (options.phasePlotsFlag) 
            if (options.phasePlot3DFlag)
                nr=3;
                f=figure('Position',[0 0 1200 1500]);   
            else
                nr=1;
                f=figure('Position',[0 0 1200 300]);
            end

            whiteSpaceMargin=.25;

            if options.plotGhostTrajectory
                lim=(1+whiteSpaceMargin)*max([ max([forPlotting.pcs.PCCOEFF_D2(:,1); forPlotting.pcs.PCCOEFF_D2(:,2); forPlotting.pcs.PCCOEFF_D2(:,3)]) ...
                -min([forPlotting.pcs.PCCOEFF_D2(:,1);forPlotting.pcs.PCCOEFF_D2(:,2);forPlotting.pcs.PCCOEFF_D2(:,3)]) ...
                ]);
            else
                lim=(1+whiteSpaceMargin)*max([ max([forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,1),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,2),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,3)]) ...
                    -min([forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,1),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,2),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,3)]) ...
                    ]);
            end


            subplot(nr,3,1);
            if options.plotGhostTrajectory
                plot(forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),1),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),2),'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);
            end    
            hold on;
            color_line2(forPlotting.pcs.PC_D1(plotTimeRangeRel,1),forPlotting.pcs.PC_D1(plotTimeRangeRel,2),double(options.timeColoring(options.plotTimeRange)));
            %plot(forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,1),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,2));
            
            
            xlim([-lim lim]); ylim([-lim lim]);
            intitle('2 vs. 1');


            subplot(nr,3,2);
            if options.plotGhostTrajectory
                plot(forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),1),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),3),'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);
            end    
            hold on;
            color_line2(forPlotting.pcs.PC_D1(plotTimeRangeRel,1),forPlotting.pcs.PC_D1(plotTimeRangeRel,3),double(options.timeColoring(options.plotTimeRange)));
            %plot(forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,1),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,3));
            xlim([-lim lim]); ylim([-lim lim]);
            intitle('3 vs. 1');


            subplot(nr,3,3);
            if options.plotGhostTrajectory
                plot(forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),2),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),3),'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);
            end    
            hold on;
            %plot(forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,2),forPlotting.pcs.PCCOEFF_D2(plotTimeRangeRel,3));
            color_line2(forPlotting.pcs.PC_D1(plotTimeRangeRel,2),forPlotting.pcs.PC_D1(plotTimeRangeRel,3),double(options.timeColoring(options.plotTimeRange)));
            xlim([-lim lim]); ylim([-lim lim]);
            intitle('3 vs. 2');


            
            if (options.phasePlot3DFlag)
                subplot(nr,3,4:9);
                if options.plotGhostTrajectory
                        plot3(forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),1),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),2),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),3),'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',2);
                end
                color_line3(forPlotting.pcs.PC_D1(plotTimeRangeRel,1),forPlotting.pcs.PC_D1(plotTimeRangeRel,2),forPlotting.pcs.PC_D1(plotTimeRangeRel,3),double(options.timeColoring(options.plotTimeRange)),'LineStyle','-','Marker','none','LineWidth',3);
                grid on;
                
            end

            if (options.plotSplitFigures)
                mtit([wbstruct.displayname ' -' flagstr]);
            end

        end
    else %options.plotSplitFigures=false
        
        subplot(2,2,2);
        if options.plotGhostTrajectory
            plot3(forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),1),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),2),forPlotting.pcs.PC_D1(options.ghostTrajectoryRange(1):options.ghostTrajectoryRange(end),3),'Color',[0.5 0.5 0.5],'LineStyle','-','Marker','none','LineWidth',1);
        end
        options.timeColoring(options.plotTimeRange(1))=0;
        options.timeColoring(options.plotTimeRange(end))=1;
         color_line3(forPlotting.pcs.PC_D1(plotTimeRangeRel,1),forPlotting.pcs.PC_D1(plotTimeRangeRel,2),forPlotting.pcs.PC_D1(plotTimeRangeRel,3),double(options.timeColoring(options.plotTimeRange)),'LineStyle','-','Marker','none','LineWidth',options.lineWidth);
        hold on;
        
%         size(forPlotting.pcs.PC_D1)
%         size(options.timeColoringOverlay)
%         size(plotTimeRangeRel)
%         size(options.range)
         if isfield(options,'timeColoringOverlay') && ~isempty(options.timeColoringOverlay)
             plot3(forPlotting.pcs.PC_D1(logical(options.timeColoringOverlay(options.range)),1),forPlotting.pcs.PC_D1(logical(options.timeColoringOverlay(options.range)),2),...
                 forPlotting.pcs.PC_D1(logical(options.timeColoringOverlay(options.range)),3),'Color','g','LineWidth',options.lineWidth,'LineStyle','.','Marker','o','MarkerSize',4);
         end
         if ~isempty(options.phasePlot3DLimits)
             xlim(options.phasePlot3DLimits(1:2));
             ylim(options.phasePlot3DLimits(3:4));
             zlim(options.phasePlot3DLimits(5:6));
             
         end
        grid on;
        
        if isfield(options,'colormap')
            colormap(options.colormap);
        else
            colormap(jet(256));
        end
        xlabel('PC1');
        ylabel('PC2');
        zlabel('PC3');
        view(options.phasePlot3DView);
        if isfield(options,'phasePlot3DFlipZ') && options.phasePlot3DFlipZ
            set(gca,'zdir','reverse');
        end
    end
        
    mtit([wbstruct.displayname ' -' flagstr],'fontsize',12,'color','k');

        
    if (options.savePDFFlag)
        save2pdf([dataFolder filesep 'Quant' filesep 'pca-' wbstruct.trialname '-phaseplots' flagstr '.pdf']);
        saveas(gcf, [dataFolder filesep 'Quant' filesep 'pca-' wbstruct.trialname '-phaseplots' flagstr '.fig'], 'fig');
        if ~isempty(options.savePDFCopyDirectory)
            save2pdf([options.savePDFCopyDirectory filesep 'pca-' wbstruct.trialname '-phaseplots' flagstr '.pdf']);
            saveas(gcf, [options.savePDFCopyDirectory filesep 'pca-' wbstruct.trialname '-phaseplots' flagstr '.fig'], 'fig');

        end
    end
    
    end
    
end







% if options.coloredPhasePlotsFlag
%    
% end;






%testing wbcpa
% figure;
% jpcainput(1).A=pcs.PCCOEFF_D2(:,1:2:29);
% jpcainput(2).A=pcs.PCCOEFF_D2(:,2:2:30);
% %jpcainput(3).A=traces(:,81:120);
% jPCA(jpcainput);

