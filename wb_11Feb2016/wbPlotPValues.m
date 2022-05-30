function wbPlotPValues(pValueStruct,options)


    plot_intervalband = @(x,lower,upper,colr) set(fill([x,x(end:-1:1)],[upper,lower(end:-1:1)],colr),'EdgeColor',colr);

    if nargin<2
        options=[];
    end
    
    if ~isfield(options,'savePDFFlag')
        options.savePDFFlag=true;
    end   
    
    if ~isfield(options,'plotLogScale')
        options.plotLogScale=true;
    end    
    
    if ~isfield(options,'showMeanTrace')
        options.showMeanTrace=true;
    end
    
    if ~isfield(options,'meanTraceColor') || isempty(options.meanTraceColor)
        options.meanTraceColor='k';
    end
    

    if ~isfield(options,'binningFactor')
        options.binningFactor=1;
    end

    if ~isfield(options,'showTitle')
        options.showTitle=true;
    end
    
    if ~isfield(options,'showSEMBars')
        options.showSEMBars=true;
    end
    
    if ~isfield(options,'showSEMBand')
        options.showSEMBand=true;
    end
    
    if ~isfield(options,'showPhaseColorRects')
        options.showPhaseColorRects=true;
    end
    
    if  ~isfield(options,'showIndividualTraces')
         options.showIndividualTraces=false;
    end
    
    
    if ~isfield(options,'transitionType')      
        trajType=pValueStruct.options.transitionType;
    else
        trajType=options.transitionType;
    end
    
    minPValue=1/pValueStruct.options.bootstrap.numIterations;

    if strcmpi(trajType,'rise')
        tnChoice=1;
    elseif strcmpi(trajType,'fall')
        tnChoice=2;
    else  %both
        tnChoice=[1 2];
    end

    trajTypes={'Rise','Fall'};
    
    for tn=tnChoice
    
        trajType=trajTypes{tn};
    
        if ~options.subPlotFlag
            figure('Position',[0 0 800 600]);
        end

    
    
        for d=1:numel(pValueStruct.wbDir)

            for i=1:numel(pValueStruct.pValue{d}.(trajType))
                pClean{d}=pValueStruct.pValue{d}.(trajType){i};
                pClean{d}(pClean{d}==0)=minPValue;

                if options.showIndividualTraces
                    if options.plotLogScale
                        semilogy(pValueStruct.tvec{d},pClean{d},'Color',color(i,numel(pValueStruct.options.pcSelection)));
                    else
                        plot(pValueStruct.tvec{d},pValueStruct.pValue{d}.(trajType){i},'Color',color(+i,numel(wbDir)*numel(pValueStruct.options.pcSelection)));
                    end
                    hold on;

                end


            end

        end
    
    
        if options.showMeanTrace

            pValueInterp(:,1)=pClean{1};

            tvecMean=pValueStruct.tvec{1};

            for d=2:numel(pValueStruct.wbDir)

                pValueInterp(:,d)=interp1(pValueStruct.tvec{d},pClean{d},pValueStruct.tvec{1});       

            end
            pValueMean=geomean(pValueInterp,2);


        end
        

        %bin data
        [pValueMeanBinned,tvecMeanBinned]=BinData(pValueMean,tvecMean,options.binningFactor);
        for i=1:size(pValueInterp,2);
            [pValueInterpBinned(:,i)]=BinData(pValueInterp(:,i),tvecMean,options.binningFactor);
        end
        
        pValueSEM=geostd(pValueInterpBinned,1,2)/sqrt(numel(pValueStruct.wbDir));

                
        
        if options.showMeanTrace

            if options.plotLogScale
                semilogy(tvecMeanBinned,pValueMeanBinned,'Color','k');
            else
                plot( tvecMeanBinned,pValueMeanBinned,'Color','k');
            end
            hold on;

        end
    
        if options.showSEMBand


            if options.binningFactor==1 %then drop last point
                

                 plot_intervalband(tvecMeanBinned(1:end-1)',(pValueMeanBinned(1:end-1)./pValueSEM(1:end-1))', (pValueMeanBinned(1:end-1).*pValueSEM(1:end-1))',color('lb'));
            else
                 plot_intervalband(tvecMeanBinned',(pValueMeanBinned./pValueSEM)', (pValueMeanBinned.*pValueSEM)' ,color('lb'));
            end
        end
        

        if options.showMeanTrace

            if options.plotLogScale
                semilogy(tvecMeanBinned,pValueMeanBinned,'Color',options.meanTraceColor);
            else
                plot( tvecMeanBinned,pValueMeanBinned,'Color',options.meanTraceColor);
            end

        end
        
        if options.showSEMBars
            
            for i=1:length(tvecMeanBinned)
                
                line([tvecMeanBinned(i) tvecMeanBinned(i)],[(pValueMeanBinned(i)./pValueSEM(i)), (pValueMeanBinned(i).*pValueSEM(i))' ],'Color','k');
                
            end         
            
            
        end
        
        if options.showPhaseColorRects
            
            if tn==2
               colorCycle={'y','b','r','g'};
            else
               colorCycle={'r','g','y','b'}; 
            end
            j=0;
            for i=pValueStruct.options.phaseRange(1):0.25:pValueStruct.options.phaseRange(2)               
                rectangle('Position',[i 10^-5 .25 .4*10^-5],'EdgeColor','none','FaceColor',colorCycle{1+mod(j,4)});
                j=j+1;
            end
        
        
            
        end          
    
    

    
        hline(0.5);

        if isempty(pValueStruct.options.neuronSelection)

    %     legend(cellfun(@num2str,pValueStruct.options.pcSelection,'UniformOutput',false),'Location','SouthWest');
    %     else
    %         legend(cellapse(pValueStruct.options.neuronSelection)','Location','SouthWest');
    %     end
        end

        vline((pValueStruct.options.phaseRange(1):0.25:pValueStruct.options.phaseRange(2)),[0.5 0.5 0.5]);

%         vline([0 0.25 0.5 0.75 1],'k'); 


        hline(0.5);
        xlim([pValueStruct.options.phaseRange(1) pValueStruct.options.phaseRange(2)]);

        ylabel('p-Value');
        xlabel('phase');
        set(gca,'XTick', pValueStruct.options.phaseRange(1):0.25:pValueStruct.options.phaseRange(2));

        
        
        if floor(pValueStruct.options.phaseRange(2)) - floor(pValueStruct.options.phaseRange(1)) > 3
            
            for j=floor(pValueStruct.options.phaseRange(1)): (pValueStruct.options.phaseRange(2))
                text(j+0.625,0.9,upper(trajType(1)),'HorizontalAlignment','center');
            end
            
        elseif floor(pValueStruct.options.phaseRange(2)) - floor(pValueStruct.options.phaseRange(1)) > 1

            for j=floor(pValueStruct.options.phaseRange(1)): (pValueStruct.options.phaseRange(2))
                text(j+0.625,0.000025,upper(trajType),'HorizontalAlignment','center');
            end

        end

        proplot;

    %     if strcmpi(trajType,'fall')        
    %         set(gca,'XTickLabel',{'-pi','RISE','-pi/2','HIGH','0','FALL','pi/2','LOW','pi'})
    %         set(gca,'fontname','symbol')
    %     else
    %         set(gca,'XTickLabel',{'-pi','FALL','-pi/2','LOW','0','RISE','pi/2','HIGH','pi'})        
    %     end

        if options.showTitle
            
            if numel(pValueStruct.wbDir)>1
                title([trajType ' trajectories ' pValueStruct.flagstr ' multi-trial']);
            else

                title([trajType ' trajectories ' pValueStruct.flagstr ' ' wbMakeShortTrialname(pValueStruct.trialname{1})]);
            end
        
        end


        if options.savePDFFlag
            
            if numel(pValueStruct.wbDir)>1
                export_fig(['PvalueVsTime-' upper(trajType)  'Cluster ' pValueStruct.flagstr '-pr['  num2str(pValueStruct.options.phaseRange(1)) '-' num2str(pValueStruct.options.phaseRange(2)) ']-multitrial.pdf'])
            else
                export_fig(['PvalueVsTime-' upper(trajType)  'Cluster ' pValueStruct.flagstr '-pr['  num2str(pValueStruct.options.phaseRange(1)) '-' num2str(pValueStruct.options.phaseRange(2)) ']-'  wbMakeShortTrialname(pValueStruct.trialname{1}) '.pdf'])
            end

        end

    end

end