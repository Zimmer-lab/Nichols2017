function stats=wbstats(wbstruct,statType,options)

      
    if nargin<3
        options=[];
    end
  
    if nargin<2
        statType='all'
    end
    
    if nargin<1 || isempty(wbstruct)
        wbstruct=wbload;
        if isempty(wbstruct)
            stats=[];
            return;
        end
    end
    
    stats=[];

    if ~isfield(options,'saveFlag')
        options.saveFlag=true;
    end 
    
    if ~isfield(options,'outputDir')
        options.outputDir=[pwd filesep 'Quant/Distributions'];
    end 
    
    flagstr=[];


    traces=wbstruct.deltaFOverF;

    %compute stimulus epoch ranges
%     period1=time2frame(wbstruct.tv,[ 0 wbstruct.stimulus.switchtimes(1)]);
%     period2=time2frame(wbstruct.tv,[ wbstruct.stimulus.switchtimes(1) wbstruct.stimulus.switchtimes(2)]);
%     period3=time2frame(wbstruct.tv,[ wbstruct.stimulus.switchtimes(2) wbstruct.tv(end)]);
% 
% 
%     p1=period1(1):period1(2);
%     p2=period2(1):period2(2);
%     p3=period3(1):period3(2);

    if strcmp(statType,'stdevtimeseries')
        ComputeStDevTimeSeries;
    end
    
    if strcmp(statType,'all')
        ComputeRMSDist;
    end
    
    if options.saveFlag
        clear wbstruct;
        save([options.outputDir filesep 'wbstats.mat']);
    end
    
%% RMS  
    function ComputeRMSDist
         for i=1:wbstruct.nn
             RMS(i)=sqrt(sum((traces(:,i)-mean(traces(:,i))).^2)/size(traces,1));
         end

         stats.RMS=RMS;
    end

%% Power(StDev)
    function ComputeStDevTimeSeries
    
    for i=1:wbstruct.nn
        powertrace(:,i)=(traces(:,i)-mean(traces(:,i)) ).^2;
        powertrace_p1(:,i)=(traces(p1,i)-mean(traces(p1,i)) ).^2;
        powertrace_p2(:,i)=(traces(p2,i)-mean(traces(p2,i)) ).^2;
        powertrace_p3(:,i)=(traces(p3,i)-mean(traces(p3,i)) ).^2;

    end
    
    stats.stdevtrace=sqrt(sum(powertrace,2))/wbstruct.nn;

    stats.stdevtrace_p1=sqrt(sum(powertrace_p1,2))/wbstruct.nn;
    stats.stdevtrace_p2=sqrt(sum(powertrace_p2,2))/wbstruct.nn;
    stats.stdevtrace_p3=sqrt(sum(powertrace_p3,2))/wbstruct.nn;

    figure('Position',[0 0 1024 600]);

    plot(wbstruct.tv,stats.stdevtrace);
    hold on;
    %plot(wbstruct.tv(1:3254),[stats.stdevtrace_p1;  stats.stdevtrace_p2],'r');

    ylim([0 1.1*max(stats.stdevtrace)]);
    xlim([0 wbstruct.tv(end)]);

    wbplotstimulus(wbstruct,1,[],1.05*max(stats.stdevtrace));

    set(gca,'XTick',0:60:wbstruct.tv(end));
    title(['avg. stdev vs. time: ' wbstruct.displayname]);
    xlabel('time (s)');
    ylabel('StDev (\DeltaF/F_0)');
    mkdir('Quant/Distributions/');
    export_fig(['Quant/Distributions/AvgStdevVsTime-' wbstruct.trialname '.pdf']);

end

%% power (var) distribution

%{
    function ComputeVar


    for i=1:wbstruct.nn
        MSEperiod1(i)= sum(  ( detrend(traces(period1(1):period1(2),i))-mean(traces(:,i))).^2) / (period1(2)-period1(1));
        MSEperiod2(i)= sum(  ( detrend(traces(period2(1):period2(2),i))-mean(traces(:,i))) .^2) / (period2(2)-period2(1));
        MSEperiod3(i)= sum(  ( detrend(traces(period3(1):period3(2),i))-mean(traces(:,i))) .^2) / (period3(2)-period3(1));


    end

    bins=[.001 .0018 .0031 .0056 .01 .018 .031 .056 .1 .18 .31 .56 1];
    [distP1,P1x]=hist(MSEperiod1,bins);
    [distP2,P2x]=hist(MSEperiod2,bins);
    [distP3,P3x]=hist(MSEperiod3,bins);


    figure('Position',[0 0 600 600]);
    semilogx(P1x,distP1,'b.-','MarkerSize',12,'LineWidth',3);
    hold on;
    semilogy(P2x,distP2,'r.-','MarkerSize',12,'LineWidth',3);
    legend('epoch1','epoch2');
    ylabel('number of neurons');
    xlabel('log((\DeltaF/F_0)^2))');
    title(['variance distribution: ' wbstruct.displayname]);

    export_fig(['Quant/VarDistQuiescentArousal-logbin-' wbstruct.trialname '.pdf']);


    linbins=[0:.1:.7];
    [distP1,P1x]=hist(MSEperiod1,linbins);
    [distP2,P2x]=hist(MSEperiod2,linbins);

    figure('Position',[200 200 600 600]);
    plot(P1x,distP1,'b.-','MarkerSize',12,'LineWidth',3);
    hold on;
    plot(P2x,distP2,'r.-','MarkerSize',12,'LineWidth',3);
    legend('quiescent','aroused');
    ylabel('number of neurons');
    xlabel('(\DeltaF/F_0)^2');
    title(['variance distribution: ' wbstruct.displayname]);

    export_fig(['Quant/Distributions/VarDistP1-linbin-' wbstruct.trialname '.pdf']);


end

%}

%% PCACov and Corr  Period 1 and Period 2

%{
    function ComputePCACov
disp('bfdb')
%         if derivFlag  
%             flagstr=[flagstr '-deriv'];
%             traces1=fastsmooth(deriv( traces(period1(1):period1(end),:) ),3,3,1);
%             traces2=fastsmooth(deriv( traces(period2(1):period2(end),:) ),3,3,1);
%             traces3=fastsmooth(deriv( traces(period3(1):period3(end),:) ),3,3,1);
%         else
%             traces1=traces(period1(1):period1(end),:) ;
%             traces2=traces(period2(1):period2(end),:) ;
%             traces3=traces(period3(1):period3(end),:) ;
%         end


        V1=cov(detrend(traces1));
        V2=cov(detrend(traces2));
        V3=cov(detrend(traces3));

        R1=V1./(sqrt(diag(V1))*(sqrt(diag(V1)))');
        R2=V2./(sqrt(diag(V2))*(sqrt(diag(V2)))');
        R3=V3./(sqrt(diag(V3))*(sqrt(diag(V3)))');

        [PCACorr_COEFF_V1, PCACorr_LATENT_V1, PCACorr_EXPLAINED_V1] = pcacov(R1);
        [PCACorr_COEFF_V2, PCACorr_LATENT_V2, PCACorr_EXPLAINED_V2] = pcacov(R2);
        [PCACorr_COEFF_V3, PCACorr_LATENT_V3, PCACorr_EXPLAINED_V3] = pcacov(R3);

        [PCACov_COEFF_V1, PCACov_LATENT_V1, PCACov_EXPLAINED_V1] = pcacov(V1);
        [PCACov_COEFF_V2, PCACov_LATENT_V2, PCACov_EXPLAINED_V2] = pcacov(V2);
        [PCACov_COEFF_V3, PCACov_LATENT_V3, PCACov_EXPLAINED_V3] = pcacov(V3);

        PCp1=zeros(size(p1,2),5);
        PCp2=zeros(size(p2,2),5);
        PCp3=zeros(size(p3,2),5);

        PCRp1=zeros(size(p1,2),5);
        PCRp2=zeros(size(p2,2),5);
        PCRp3=zeros(size(p3,2),5);


        for j=1:5
            for i=1:size(V1,1)   
                PCp1(:,j)=PCp1(:,j)+PCACov_COEFF_V1(i,j)*normalize(traces1(:,i),1); 
                PCp2(:,j)=PCp2(:,j)+PCACov_COEFF_V2(i,j)*normalize(traces2(:,i),1); 
                PCp3(:,j)=PCp3(:,j)+PCACov_COEFF_V2(i,j)*normalize(traces3(:,i),1); 

                PCRp1(:,j)=PCRp1(:,j)+PCACorr_COEFF_V1(i,j)*normalize(traces1(:,i),1); 
                PCRp2(:,j)=PCRp2(:,j)+PCACorr_COEFF_V2(i,j)*normalize(traces2(:,i),1);   
                PCRp3(:,j)=PCRp3(:,j)+PCACorr_COEFF_V2(i,j)*normalize(traces3(:,i),1);   

            end
        end

        %
        figure('Position',[0 0 800 600]);
        subtightplot(2,2,1,[.1 .02],.1, .06);

        % bar(.85:1:9.85,PCACorr_EXPLAINED_V1(1:10),.38,'FaceColor',[0.5 0.5 0.9]);
        hold on;
        % bar(1.25:1:10.25,PCACorr_EXPLAINED_V2(1:10)',.38,'FaceColor',[0.9 0.5 0.5]);

        plot(cumsum(PCACorr_EXPLAINED_V1(1:10)),'b.-','MarkerSize',12);
        plot(cumsum(PCACorr_EXPLAINED_V2(1:10)),'r.-','MarkerSize',12);
        plot(cumsum(PCACorr_EXPLAINED_V3(1:10)),'g.-','MarkerSize',12);

        legend({'quiescent','aroused','quiescent2'},'Location','SouthEast');
        title(['PCA on Corr ' flagstr]);
        xlim([0.5 10.5]);
        set(gca,'XTick',1:10);
        ylabel('%VAF');
        xlabel('PC#');

        subtightplot(2,2,2,[.05 .02],.1, .06);
        hold on;
        for i=1:5
            plot(wbstruct.tv(p1),-PCRp1(:,i)/3+i,'b');
        end
        xlim([wbstruct.tv(p1(1)) wbstruct.tv(p1(end))]);
        set(gca,'YDir','reverse');
        ylabel('PC#');
        set(gca,'YTick',1:5);
        ylim([-1 6]);
        xlabel('time (s)');
        text(10,-.5,'quiescence PCs');

        subtightplot(2,2,3,[.05 .02],.1, .06);
        hold on;
        for i=1:5
            plot(wbstruct.tv(p2),-PCRp2(:,i)/3+i,'r');
        end
        xlim([wbstruct.tv(p2(1)) wbstruct.tv(p2(end))]);
        set(gca,'YDir','reverse');
        set(gca,'YTick',[]) 
        ylim([-1 6]);
        xlabel('time (s)');
        text(wbstruct.tv(p2(1))+10,-.5,'arousal PCs');

        subtightplot(2,2,4,[.05 .02],.1, .06);
        hold on;
        for i=1:5
            plot(wbstruct.tv(p3),-PCRp3(:,i)/3+i,'g');
        end
        xlim([wbstruct.tv(p3(1)) wbstruct.tv(p3(end))]);
        set(gca,'YDir','reverse');
        set(gca,'YTick',[]) 
        ylim([-1 6]);
        xlabel('time (s)');
        text(wbstruct.tv(p3(1))+10,-.5,'quiescence2 PCs');

        export_fig(['Quant/PCACorr3Periods-' wbstruct.trialname flagstr '.pdf']);

        %
        figure('Position',[0 0 800 600]);
        subtightplot(2,2,1,[.1 .02],.1, .06);

        % bar(.85:1:9.85,PCACov_EXPLAINED_V1(1:10),.38,'FaceColor',[0.5 0.5 0.9]);
        hold on;
        % bar(1.25:1:10.25,PCACov_EXPLAINED_V2(1:10)',.38,'FaceColor',[0.9 0.5 0.5]);

        plot(cumsum(PCACov_EXPLAINED_V1(1:10)),'b.-','MarkerSize',12);
        plot(cumsum(PCACov_EXPLAINED_V2(1:10)),'r.-','MarkerSize',12);
        plot(cumsum(PCACov_EXPLAINED_V3(1:10)),'g.-','MarkerSize',12);

        legend({'quiescent','aroused','quiescent2'},'Location','SouthEast');
        title(['PCA on Cov ' flagstr ]);
        xlim([0.5 10.5]);
        set(gca,'XTick',1:10);
        ylabel('%VAF');
        xlabel('PC#');

        subtightplot(2,2,2,[.05 .02],.1, .06);
        hold on;
        for i=1:5
            plot(wbstruct.tv(p1),-PCp1(:,i)/3+i,'b');
        end
        xlim([wbstruct.tv(p1(1)) wbstruct.tv(p1(end))]);
        set(gca,'YDir','reverse');
        ylabel('PC#');
        set(gca,'YTick',1:5);
        ylim([-1 6]);
        xlabel('time (s)');
        text(10,-.5,'quiescence PCs');

        subtightplot(2,2,3,[.05 .02],.1, .06);
        hold on;
        for i=1:5
            plot(wbstruct.tv(p2),-PCp2(:,i)/3+i,'r');
        end
        xlim([wbstruct.tv(p2(1)) wbstruct.tv(p2(end))]);
        set(gca,'YDir','reverse');
        set(gca,'YTick',[]) 
        ylim([-1 6]);
        xlabel('time (s)');
        text(wbstruct.tv(p2(1))+10,-.5,'arousal PCs');

        subtightplot(2,2,4,[.05 .02],.1, .06);
        hold on;
        for i=1:5
            plot(wbstruct.tv(p3),-PCp3(:,i)/3+i,'g');
        end
        xlim([wbstruct.tv(p3(1)) wbstruct.tv(p3(end))]);
        set(gca,'YDir','reverse');
        set(gca,'YTick',[]) 
        ylim([-1 6]);
        xlabel('time (s)');
        text(wbstruct.tv(p3(1))+10,-.5,'quiescence2 PCs');


        export_fig(['Quant/PCACov3Periods-' wbstruct.trialname flagstr '.pdf']);
    end

%}

end %main

