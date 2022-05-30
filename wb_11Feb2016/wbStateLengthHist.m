%wbStateLengthHist
flagstr=[];

nr=1;nc=4;
referenceHistoDir='/Users/skato/Desktop/Dropbox/MyPaperWB/PaperFinalData/NoStim';
options.colorTrials=false;
options.referenceHisto=true;
options.barOutline=true;
options.computePValues=true;
options.showPValues=true;

if options.colorTrials
    flagstr=[flagstr '-coloredTrials'];
end
   
if options.referenceHisto
    flagstr=[flagstr '-vsN2'];
end

ss=load('wbStateStatsStruct.mat');

stateName={'LOW','RISE','HIGH','FALL'};

clear stateLengthHist
edges=[0:1:21];
for d=1:5
    for state=1:4

         stateLengthHist{state}(d,:)=histc(ss.stateLengths{d,state},edges);

    end
    
end


if options.referenceHisto
    ssRef=load([referenceHistoDir filesep 'wbStateStatsStructRIML.mat']);
    for d=1:5
        for state=1:4
             stateLengthHistRef{state}(d,:)=histc(ssRef.stateLengths{d,state},edges);

        end

    end
end


figure('Position',[0 0 800 150],'Color','w');

for state=1:4

    subplot(nr,nc,state);
    
    cumSLH=sum(stateLengthHist{state},1)'/sum(sum(stateLengthHist{state}));
        
    if options.referenceHisto
        cumSLHRef=sum(stateLengthHistRef{state},1)'/sum(sum(stateLengthHistRef{state}));
        
        if options.barOutline
            cumSLHRef(end-1)=0;
            [x,y]=Stepify([edges(1:end-1)+0.5 edges(end)+2],cumSLHRef');
            plot(x,y,'b');
        else
        
            bar([edges(1:end-1)+0.5 edges(end)+2],cumSLHRef,1,'b','EdgeColor','none');
        end
    end
    hold on;
    
    if options.colorTrials
        
        bar([edges(1:end-1)+0.5 edges(end)+2],stateLengthHist{state}'/sum(sum(stateLengthHist{state})),2,'stacked','EdgeColor','none');
    else
        
        if options.barOutline
            cumSLH(end-1)=0;
            [x,y]=Stepify([edges(1:end-1)+0.5 edges(end)+2 ],cumSLH');
            plot(x,y,'r');
        else
            bar([edges(1:end-1)+0.5 edges(end)+2],cumSLH,1,'r','EdgeColor','none');
        end

    end
    
    
    
    
    hold on;
            
        
    if options.referenceHisto && ~options.barOutline

            cumOverlap=min([cumSLH, cumSLHRef],[],2);
            cumOverlap(~logical(cumSLH))=0;
            cumOverlap(~logical(cumSLHRef))=0;        
            bar([edges(1:end-1)+0.5 edges(end)+2],cumOverlap,1,'FaceColor',[0.3 0 0.3],'EdgeColor','none');      
    end
    
    
    if state==4
        legend({'WT','AVA::HisCl'},'Location','East');
    end
    
    ylim([0 1.1*max([cumSLH;cumSLHRef])]);
    if state==1 
        ylabel('fraction');
    end
    proplot;
    xlim([0 22]);
    set(gca,'XTick',[0:2:20 21.5]);
    set(gca,'XTickLabel','0||4||8||12||16||20|');
    textul([' ' num2str(stateName{state}) ' phase']);

    %compute pvalues
    %traditional ks
    [~,pValue0,~]=kstest2(ss.stateLengths{d,state},ssRef.stateLengths{d,state});
    
    %bootstrap ks
    SToptions.numSamples=1000000;
    SToptions.testStatisticFunction=@(x)kstest2statistic(x,ssRef.stateLengths{d,state});
    testType='permutation';
    D.empDist=[ss.stateLengths{d,state},ssRef.stateLengths{d,state}];
    D.acceptLevel=kstest2statistic(ss.stateLengths{d,state},ssRef.stateLengths{d,state});
    D.sampleSize=length(ss.stateLengths{d,state});
    thisPValue=SigTest(testType,D,SToptions);
    thisPValue=max([thisPValue  1/SToptions.numSamples]);
                
    
    %median ks
    %SToptions.numSamples=100000;
    SToptions.testStatisticFunction=@median;
    testType='permutation';
    D.empDist=[ss.stateLengths{d,state},ssRef.stateLengths{d,state}];
    D.acceptLevel=median(ss.stateLengths{d,state});
    D.sampleSize=length(ss.stateLengths{d,state});
    pValue2=SigTest(testType,D,SToptions);
    pValue2=max([pValue2  1/SToptions.numSamples]);
                

    
    if options.showPValues
        textur({['p(ks)=' num2str(pValue0)],['p(ks_{boot})=' num2str(thisPValue)],['p(med)=' num2str(pValue2)]});
        
    end
    
end

xlabel('state duration (s)');

%R2R and F2F intervals
edges2=[0:2:80];

R2RIntervals=[];
F2FIntervals=[];
for d=1:5
    R2RIntervals=[R2RIntervals diff(ss.transitionTimes{d})'];
    F2FIntervals=[F2FIntervals diff(ss.transitionFallTimes{d})'];
end
cumR2R=histc(R2RIntervals,edges2);
cumF2F=histc(F2FIntervals,edges2);

cumR2R=cumR2R/sum(cumR2R);
cumF2F=cumF2F/sum(cumF2F);


if options.referenceHisto

    R2RIntervalsRef=[];
    F2FIntervalsRef=[];
    for d=1:5
        R2RIntervalsRef=[R2RIntervalsRef diff(ssRef.transitionTimes{d})'];
        F2FIntervalsRef=[F2FIntervalsRef diff(ssRef.transitionFallTimes{d})'];
    end
    cumR2RRef=histc(R2RIntervalsRef,edges2);
    cumF2FRef=histc(F2FIntervalsRef,edges2);
    
    
    cumR2RRef=cumR2RRef/sum(cumR2RRef);
    cumF2FRef=cumF2FRef/sum(cumF2FRef);
end


% subplot(6,1,5);
% 
%     if options.barOutline
%         [x,y]=Stepify([edges2(1:end-1)+0.5 edges2(end)+2],cumR2R);
%         plot(x,y,'r');
%     else
%         bar([edges2(1:end-1)+0.5 edges2(end)+2],cumR2R,1,'r','EdgeColor','none');
%     end
%     hold on;
% 
%     if options.referenceHisto   
%         if options.barOutline
%             [x,y]=Stepify([edges2(1:end-1)+0.5 edges2(end)+2],cumR2RRef);
%             plot(x,y,'b');
%         else
%             bar([edges2(1:end-1)+0.5 edges2(end)+2],cumR2RRef,1,'b','EdgeColor','none');
%         end     
%     end
% 
% 
% 
%     xlabel('interval (s)');
%     ylabel('fraction');
% 
%     proplot;
%     xlim([0 80]);
%     ylim([0 1.1*max([cumR2R cumR2RRef])]);
% 
%     intitle('rise-to-rise');
% 
%     %compute pvalues
%     [~,pValue,~]=kstest2(R2RIntervals,R2RIntervalsRef);
%     textur(['p(ks)=' num2str(pValue)]);
% 
%     NudgeAxis(gca,0,-.03);
%     
% 
% subplot(6,1,6);
% 
% 
%     if options.barOutline
%         [x,y]=Stepify([edges2(1:end-1)+0.5 edges2(end)+2],cumF2F);
%         plot(x,y,'r');
%     else
%         bar([edges2(1:end-1)+0.5 edges2(end)+2],cumR2R,1,'r','EdgeColor','none');
%     end
%     hold on;
%     if options.referenceHisto   
%         if options.barOutline
%             [x,y]=Stepify([edges2(1:end-1)+0.5 edges2(end)+2],cumF2FRef);
%             plot(x,y,'b');
%         else
%             bar([edges2(1:end-1)+0.5 edges2(end)+2],cumF2FRef,1,'b','EdgeColor','none');
%         end     
%     end
% 
%     xlabel('interval (s)');
%     ylabel('fraction');
% 
%     proplot;
%     xlim([0 80]);
%     ylim([0 1.1*max([cumF2F cumF2FRef])]);
% 
%     intitle('fall-to-fall');
% 
%     %compute pvalues
%     [~,pValue,~]=kstest2(F2FIntervals,F2FIntervalsRef);
%     textur(['p(ks)=' num2str(pValue,3)]);
% 
%     
%     
%     
%     NudgeAxis(gca,0,-.03);




export_fig(['StateDurationHistograms' flagstr '.pdf']);