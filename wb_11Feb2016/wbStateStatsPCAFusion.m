function wbStateStatsPCAFusion


options.summaryPlot=true;
options.trialPlots=false;
options.trajectoryPlots=false;
options.measureNeuronTraces=true;

groupName={'Stim','CTRL'};

folder={'/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/Stim/&fixed',...
    '/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/NoStim/&fixed'};

outputDir='/Users/skato/Desktop/Dropbox/MyPaperWB';
stats={'Cent','Max','Middle'};

trajType={'Rise','FallSMDV','FallSMB','Rise1','Rise2'};
trajTypeNum=[2 4 4 2 2];

binRes=20;


runExtraNormalizationTestsFlag=false;

%trajHistVec={[-.1:.05:.3],[-.35:0.05:0],[-.35:0.05:0]};

                    
for G=1:numel(groupName);

        cd(folder{G});

        wbSS=load('wbStateStatsStruct.mat');

        folders=listfolders(pwd,true);

        %load PCs
        for d=1:numel(folders)

            pc{d}=wbLoadPCA(folders{d},false);

        end


        for t=1:numel(trajType)


            outputFileName=[outputDir filesep 'StimMagAnalysis-' trajType{t} '-' 'PC1.pdf'];


            if options.trialPlots || options.trajectoryPlots

                if exist(outputFileName,'file');
                    delete(outputFileName);
                end

            end

            outputFileName


            %load cluster data
            clear cl;
            for d=1:numel(folders)

                cd(folders{d});

                if t==1 || t==4 || t==5
                    cl{d}=load(['Quant' filesep 'wbClusterRiseStruct.mat']);
                else
                    cl{d}=load(['Quant' filesep 'wbClusterFallStruct.mat']);
                end
            end

            cd('..');

        

        

        if G==1 && (t==2 || t==3)
            cl{1}.clusterMembership=[1 1 1 1 2 1 1 2 2 2 2 2 2 2 1 1];
            cl{2}.clusterMembership=[1 1 1 1 2 1 1 1 1 2 1 1 2 1 2];
            cl{7}.clusterMembership=[2 2 2 2 2 1 2 1 1 2 1];

        end

        if G==1 
            SMDCluster=[2 1 2 2 2 1 2];
        else
            SMDCluster=[2 2 2 2 1];
        end
            
        if options.trajectoryPlots
            figure('Position',[0 0 800 1000],'Color','w');
        end
        
        clear('stateRangeC1','stateRangeC2','trajC1','trajC2')
        for d=1:numel(folders)

            if options.trialPlots
                subplot(3,3,d);
            end
            
            %get stateRanges from wbStateStatsStruct
            
            
            if t==1
                        stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}   wbSS.stateRunStartIndices{d,trajTypeNum(t)}+(wbSS.stateFrameLengths{d,trajTypeNum(t)})'-1];

            elseif t==2
                        stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d)))'-1];
                        stateRangeC2{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d))))'-1];
            elseif t==3
                        stateRangeC2{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d)))'-1];
                        stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d))))'-1];
            elseif t==4

                stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==1)   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==1)+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==1))'-1];
                stateRangeC2{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==2)   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==2)+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==2))'-1];

            else %t==5

                stateRangeC2{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==1)   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==1) + (wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==1))'-1];
                stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==2)   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==2) + (wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==2))'-1];


            end
            
            
            %get clipped PC ranges
            for RT=1:size(stateRangeC1{d},1)      

                 D.(groupName{G}).(trajType{t}).trajC1.Cent{d}(RT)=abs(mean(pc{d}.pcs(stateRangeC1{d}(RT,1):stateRangeC1{d}(RT,2),1)));
                 D.(groupName{G}).(trajType{t}).trajC1.Max{d}(RT)=max(abs(pc{d}.pcs(stateRangeC1{d}(RT,1):stateRangeC1{d}(RT,2),1)));
                 D.(groupName{G}).(trajType{t}).trajC1.Middle{d}(RT)=abs(pc{d}.pcs(round((stateRangeC1{d}(RT,1)+stateRangeC1{d}(RT,2))/2)));

            end
                      
            if t>1 %clustered transitions
                for RT=1:size(stateRangeC2{d},1)      

                     D.(groupName{G}).(trajType{t}).trajC2.Cent{d}(RT)=mean(pc{d}.pcs(stateRangeC2{d}(RT,1):stateRangeC2{d}(RT,2),1));
                     D.(groupName{G}).(trajType{t}).trajC2.Middle{d}(RT)=abs(pc{d}.pcs(round((stateRangeC2{d}(RT,1)+stateRangeC2{d}(RT,2))/2),1));
                end
            end


            if options.measureNeuronTraces

                 for n=1:size(pc{d}.traces,2)
                    for RT=1:size(stateRangeC1{d},1)      

                     DN.(groupName{G}).(trajType{t}).trajC1.Cent{d}(RT,n)=abs(mean(pc{d}.traces(stateRangeC1{d}(RT,1):stateRangeC1{d}(RT,2),n)));
                     DN.(groupName{G}).(trajType{t}).trajC1.Max{d}(RT,n)=max(abs(pc{d}.traces(stateRangeC1{d}(RT,1):stateRangeC1{d}(RT,2),n)));
                     DN.(groupName{G}).(trajType{t}).trajC1.Middle{d}(RT,n)=abs(pc{d}.traces(round((stateRangeC1{d}(RT,1)+stateRangeC1{d}(RT,2))/2),n));

                    end
                    
                    if t>1 %clustered transitions
                        for RT=1:size(stateRangeC2{d},1)      

                             DN.(groupName{G}).(trajType{t}).trajC2.Cent{d}(RT,n)=abs(mean(pc{d}.traces(stateRangeC2{d}(RT,1):stateRangeC2{d}(RT,2),n)));
                             DN.(groupName{G}).(trajType{t}).trajC2.Middle{d}(RT,n)=abs(pc{d}.traces(round((stateRangeC2{d}(RT,1)+stateRangeC2{d}(RT,2))/2),n));
                        end
                    end   
   
                 end
 
            end
 
 
            %label as NoStim Stim Prestim
            stateRangeC1_NoStim{d}=[];
            stateRangeC1_Stim{d}=[];
            stateRangeC1_PreStim{d}=[];

            for s=1:numel(stats)
                D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}=[];
                D.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}=[];
                D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}=[];
            end

                onset=find(wbSS.stimTimeVector{d},1,'first');
                timeVecMarked=wbSS.stimTimeVector{d};
                timeVecMarked(1:onset-1)=-1;

                
                for RT=1:size(stateRangeC1{d},1)

                    if wbSS.stimTimeVector{d}(stateRangeC1{d}(RT,1))==1
                        stateRangeC1_Stim{d}=[stateRangeC1_Stim{d};  stateRangeC1{d}(RT,:)  ];
                        for s=1:numel(stats)
                             D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}=[D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d} D.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}(RT)];
                        end

                    elseif timeVecMarked(stateRangeC1{d}(RT,1))==-1

                        stateRangeC1_PreStim{d}=[stateRangeC1_PreStim{d};  stateRangeC1{d}(RT,:)  ];   
                        for s=1:numel(stats)
                             D.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}=[D.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d} D.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}(RT)];
                        end

                    else

                        stateRangeC1_NoStim{d}=[stateRangeC1_NoStim{d};  stateRangeC1{d}(RT,:)  ];
                        for s=1:numel(stats)
                             D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}=[D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d} D.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}(RT)];
                        end

                    end
                end
                
              
            if options.measureNeuronTraces
                    

                for s=1:numel(stats)
                    DN.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}=[];
                    DN.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}=[];
                    DN.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}=[];
                end

                onset=find(wbSS.stimTimeVector{d},1,'first');
                timeVecMarked=wbSS.stimTimeVector{d};
                timeVecMarked(1:onset-1)=-1;
                    
                    for RT=1:size(stateRangeC1{d},1)

                        if wbSS.stimTimeVector{d}(stateRangeC1{d}(RT,1))==1
                            for s=1:numel(stats)
                                 DN.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}=...
                                [DN.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}; ...
                                 DN.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}(RT,:)];
                            end

                        elseif timeVecMarked(stateRangeC1{d}(RT,1))==-1

                            for s=1:numel(stats)
                                 DN.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}=...
                                [DN.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}; ...
                                 DN.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}(RT,:)];
                            end

                        else

                            for s=1:numel(stats)
                                 DN.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}=...
                                [DN.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}; ...
                                 DN.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}(RT,:)];
                            end

                        end
                    end
                    
               
                
            end

            
                
                
                
                
                
            %plot trajectories

            if options.trajectoryPlots
            
                PC1=fastsmooth(pc{d}.pcs(:,1),3,1);
                PC2=fastsmooth(pc{d}.pcs(:,2),3,1);

                for RT=1:size(stateRangeC1_NoStim{d},1)   

                    plot(PC1(stateRangeC1_NoStim{d}(RT,1):stateRangeC1_NoStim{d}(RT,2)),  PC2(stateRangeC1_NoStim{d}(RT,1):stateRangeC1_NoStim{d}(RT,2)),'r' );
                    hold on;

                end

                for RT=1:size(stateRangeC1_Stim{d},1)

                    plot(PC1(stateRangeC1_Stim{d}(RT,1):stateRangeC1_Stim{d}(RT,2)),   PC2(stateRangeC1_Stim{d}(RT,1):stateRangeC1_Stim{d}(RT,2)) ,'b' );
                    hold on;

                end


                for RT=1:size(stateRangeC1_PreStim{d},1)

                    plot(PC1(stateRangeC1_PreStim{d}(RT,1):stateRangeC1_PreStim{d}(RT,2)),   PC2(stateRangeC1_PreStim{d}(RT,1):stateRangeC1_PreStim{d}(RT,2)) ,'Color',color('g'));

                end
    if t>1

                for RT=1:size(stateRangeC2{d},1)

                    plot(PC1(stateRangeC2{d}(RT,1):stateRangeC2{d}(RT,2)),   PC2(stateRangeC2{d}(RT,1):stateRangeC2{d}(RT,2)) ,'Color',color('y'));

                end
    end


                xlabel('pc1');
                ylabel('pc2');

                intitle(wbMakeShortTrialname(wbSS.trialName{d}));

                drawnow;
            
            end
        
        end
        
        if options.trajectoryPlots
            export_fig(outputFileName,'-append');
        end

  

    %stat plotting
    if options.trialPlots

        for s=1:numel(stats)

            figure('Position',[0 0  800 1000],'Color','w');
            for d=1:numel(folders)

                subplot(3,3,d);

                plot(ones(length(D.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}),1),D.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d},'g.','MarkerSize',10);
                hold on;
                plot(ones(length(D.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}),1),D.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d},'go','MarkerSize',12);

                hold on;

                plot(2*ones(length(D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}),1),D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d},'g.','MarkerSize',10);
                plot(2*ones(length(D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}),1),D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d},'bo','MarkerSize',12);

                plot(3*ones(length(D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}),1),D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d},'g.','MarkerSize',10);
                plot(3*ones(length(D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}),1),D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d},'ro','MarkerSize',12);

                xlim([0 4]);
                %ylim([-.25 0]);
                intitle(wbMakeShortTrialname(wbSS.trialName{d}));

            end

            %accumulate
            prestim=[];
            stim=[];
            nostim=[];
            all=[];
            for d=1:numel(folders)

                all=[all, D.(groupName{G}).(trajType{t}).trajC1.(stats{s}){d}];
                prestim=[prestim, D.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}];
                stim=[stim, D.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}];
                nostim=[nostim, D.(groupName{G}).(trajType{t}).trajC1_NoStim.(stats{s}){d}];

            end

            %normality tests

            [~, trajC1_PreStim{d}.Pnormality.(stats{s})]=kstest(normalize(detrend(prestim,'constant'),3));
            [~,trajC1_Stim{d}.Pnormality.(stats{s})]=kstest(normalize(detrend(stim,'constant'),3));
            [~,trajC1_NoStim{d}.Pnormality.(stats{s})]=kstest(normalize(detrend(nostim,'constant'),3));


            subplot(3,3,8);


            plot(ones(length(prestim),1),prestim,'g.','MarkerSize',12);
            hold on;
            plot(2*ones(length(stim),1),stim,'b.','MarkerSize',12);
            plot(3*ones(length(nostim),1),nostim,'r.','MarkerSize',12);

            line([0.6 1.4],[mean(prestim) mean(prestim)],'Color','g');
            line([1.6 2.4],[mean(stim) mean(stim)],'Color','b');
            line([2.6 3.4],[mean(nostim) mean(nostim)],'Color','r');

           % ylim([2*trajHistVec{t}(1)-trajHistVec{t}(2) 2*trajHistVec{t}(end)-trajHistVec{t}(end-1)]);
            xlim([0 4]);
            intitle(stats{s});

            %histgrams
            subplot(3,3,9);

    %       histvec=trajHistVec{t};
            [~, histvec]=hist([prestim nostim stim],binRes);
            [prestim_dist]=hist(prestim,histvec);
            [nostim_dist]=hist(nostim,histvec);
            [stim_dist]=hist(stim,histvec);
            bh=bar(histvec,prestim_dist,1,'FaceColor','g','EdgeColor','none');
            ch = get(bh,'child');
            set(ch,'facea',.3);
            hold on;
            bh2=bar(histvec,nostim_dist,0.8,'FaceColor','r','EdgeColor','none');
            ch = get(bh2,'child');
            set(ch,'facea',.3);
            bh3=bar(histvec,stim_dist,0.6,'FaceColor','b','EdgeColor','none');
            ch = get(bh3,'child');
            set(ch,'facea',.3);

            %xlim([2*trajHistVec{t}(1)-trajHistVec{t}(2) 2*trajHistVec{t}(end)-trajHistVec{t}(end-1)]);

            legend({['pN=' num2str(trajC1_PreStim{d}.Pnormality.(stats{s}))],...
                    ['pN=' num2str(trajC1_NoStim{d}.Pnormality.(stats{s}))],...
                    ['pN=' num2str(trajC1_Stim{d}.Pnormality.(stats{s}))]});

            mtit([stats{s} '_{PC1} ' trajType{t} ' clusters'  groupName{G}]);
            export_fig(outputFileName,'-append');

        end

    end

    if runExtraNormalizationTestsFlag

        normType={'varNorm','meanNorm'};

        for n=1:2    

            %mean/std normed centroid

            figure('Position',[0 0  800 1000],'Color','w');
            for d=1:numel(folders)



                if n==1
                    baseline(d)=mean(trajC1_PreStim{d}.Cent);
                    stdbase(d)=std(detrend(trajC1_PreStim{d}.Cent,'constant'));
                else
                    baseline(d)=0;
                    stdbase(d)=mean(trajC1_PreStim{d}.Cent);
                end

                subplot(3,3,d);

                plot(ones(length( D.(groupName{G}).(trajType{t}).trajC1{d}.Cent),1),(D.(groupName{G}).(trajType{t}).trajC1{d}.Cent-baseline(d))/stdbase(d),'g.','MarkerSize',10);
                hold on;
                plot(ones(length( D.(groupName{G}).(trajType{t}).trajC1_PreStim{d}.Cent),1),(D.(groupName{G}).(trajType{t}).trajC1_PreStim{d}.Cent-baseline(d))/stdbase(d),'go','MarkerSize',12);

                plot(2*ones(length( D.(groupName{G}).(trajType{t}).trajC1_Stim{d}.Cent),1),(D.(groupName{G}).(trajType{t}).trajC1_Stim{d}.Cent-baseline(d))/stdbase(d),'g.','MarkerSize',10);
                plot(2*ones(length( D.(groupName{G}).(trajType{t}).trajC1_Stim{d}.Cent),1),(D.(groupName{G}).(trajType{t}).trajC1_Stim{d}.Cent-baseline(d))/stdbase(d),'bo','MarkerSize',12);

                plot(3*ones(length( D.(groupName{G}).(trajType{t}).trajC1_NoStim{d}.Cent),1),(D.(groupName{G}).(trajType{t}).trajC1_NoStim{d}.Cent-baseline(d))/stdbase(d),'g.','MarkerSize',10);
                plot(3*ones(length( D.(groupName{G}).(trajType{t}).trajC1_NoStim{d}.Cent),1),(D.(groupName{G}).(trajType{t}).trajC1_NoStim{d}.Cent-baseline(d))/stdbase(d),'ro','MarkerSize',12);

                xlim([0 4]);
                %ylim([-.25 0]);
                intitle(wbMakeShortTrialname(wbSS.trialName{d}));

            end

            %accumulate/stdnorm;
            prestim2=[];
            stim2=[];
            nostim2=[];
            all2=[];
            for d=1:numel(folders)

                all2=[all2, (D.(groupName{G}).(trajType{t}).trajC1{d}.Cent-baseline(d))/stdbase(d)];
                prestim2=[prestim2, (D.(groupName{G}).(trajType{t}).trajC1_PreStim{d}.Cent-baseline(d))/stdbase(d)];
                stim2=[stim2, (D.(groupName{G}).(trajType{t}).trajC1_Stim{d}.Cent-baseline(d))/stdbase(d)];
                nostim2=[nostim2, (D.(groupName{G}).(trajType{t}).trajC1_NoStim{d}.Cent-baseline(d))/stdbase(d)];

            end
            %nostim2(nostim2<0)=[];

            %normality tests
            
            try
           [~, prestimPN]=kstest(normalize(detrend(prestim2,'constant'),3));
            catch
                prestimPN=-1;
            end
            try
           [~, stimPN]=kstest(normalize(detrend(stim2,'constant'),3));
            catch
                stimPN=-1;
            end
            try
           [~, nostimPN]=kstest(normalize(detrend(nostim2,'constant'),3));
            catch
                nostimPN=-1;
            end
               
               

            subplot(3,3,8);

            hold on;
            plot(ones(length(prestim2),1),prestim2,'g.','MarkerSize',12);
            plot(2*ones(length(stim2),1),stim2,'b.','MarkerSize',12);
            plot(3*ones(length(nostim2),1),nostim2,'r.','MarkerSize',12);

            line([0.6 1.4],[mean(prestim2) mean(prestim2)],'Color','g');
            line([2.6 3.4],[mean(nostim2) mean(nostim2)],'Color','r');
            line([1.6 2.4],[mean(stim2) mean(stim2)],'Color','b');

%             if n==1
%                 ylim([-4 8]);
%                 histvec=[-4:1:8];
% 
%             else
%     %             ylim([-.4 0.05]);
%                  histvec=[0:.1:1.6];
% 
%             end

            xlim([0 4]);
            intitle(normType{n});

            subplot(3,3,9);

            [~,histvec]=hist([prestim2 nostim2 stim2],binRes);
            [prestim2_dist]=hist(prestim2,histvec);
            [nostim2_dist]=hist(nostim2,histvec);
            [stim2_dist]=hist(stim2,histvec);
            bh=bar(histvec,prestim2_dist,1,'FaceColor','g','EdgeColor','none');
            ch = get(bh,'child');
            set(ch,'facea',.3);
            hold on;
            bh2=bar(histvec,nostim2_dist,0.8,'FaceColor','r','EdgeColor','none');
            ch = get(bh2,'child');
            set(ch,'facea',.3);
            bh3=bar(histvec,stim2_dist,0.6,'FaceColor','b','EdgeColor','none');
            ch = get(bh3,'child');
            set(ch,'facea',.3);

            legend({['pN=' num2str(prestimPN)],...
                    ['pN=' num2str(stimPN)],...
                    ['pN=' num2str(nostimPN)]});


%             if n==1
%                xlim([-4.5 8.5]);
%             else
%                xlim([0 1.6]);
%             end

            mtit([ normType{n} ' centroid(PC1) ' trajType{t} ' clusters Mag ' groupName{G}]);
            export_fig(outputFileName,'-append');


        end %n

      end
    
    end %G
    
end %t

base('D',D);
if options.measureNeuronTraces
    base('DN',DN);
end


% if options.measureNeuronTraces
%     
%     
%     base('DN',DN);
% 
% 
% 
%     for t=1:numEVs
% 
%         if ~options.subPlotFlag
%             if ~options.plotSplitFigures
%                 axes('Position',[.53 .5-.45*t/numEVs .4 .18/numEVs]);
%             else
%                 subtightplot(numEVs,1,t,[0.04 0.05],[.1 .1],[.1 .1]);  %.08
%             end
%         end
% 
% 
%         hold on;
%         %subplot(options.plotNumComps,1,nn);
% 
%         %sort coeffs
%         if strcmp(options.coeffSortMethod,'magnitude')
%             [~, coeffSortIndex]=sort(abs(forPlotting.coeffs(:,t)),1,'descend');
%         else  %pca top loading, signed
%             [~,coeffSortIndex,~,eAD]=wbSortTraces(wbstruct.simple.derivs.traces,options.coeffSortMethod,[],options.coeffSortParam);
% 
%         end
% 
%         coeffSign=sign(forPlotting.coeffs(coeffSortIndex,t));     
% 
%         if options.horizontalCoeffPlotFlag
%             %handles.bar=barh(forPlotting.coeffs(coeffSortIndex,nn));
% 
%             handles.bar(1)=barh(find(coeffSign>0),forPlotting.coeffs(coeffSortIndex(coeffSign>0),t),'FaceColor',options.barColor{1});
%             hold on;
%             handles.bar(2)=barh(find(coeffSign<0),forPlotting.coeffs(coeffSortIndex(coeffSign<0),t),'FaceColor',options.barColor{2});
% 
%             xlabel(['PC' num2str(t)]);
%             ylim([0 length(forPlotting.neuronLabels)+1]);
%             set(gca,'YTick',1:length(forPlotting.neuronLabels));
%             set(gca,'YTickLabel',forPlotting.neuronLabels(coeffSortIndex));                
%         else
% 
%             handles.bar(1)=bar(find(coeffSign>0),forPlotting.coeffs(coeffSortIndex(coeffSign>0),t),'FaceColor',options.barColor{1});
%             hold on;
%             handles.bar(2)=bar(find(coeffSign<0),forPlotting.coeffs(coeffSortIndex(coeffSign<0),t),'FaceColor',options.barColor{2});
% 
%             ylabel(['PC' num2str(t)]);
%             xlim([0 length(forPlotting.neuronLabels)+1]);
% 
%             set(gca,'XTick',1:length(forPlotting.neuronLabels));
%             set(gca,'XTickLabel',forPlotting.neuronLabels(coeffSortIndex));
%         end
% 
% 
%        % set(get(handles.bar,'children'),'FaceVertexCData',(-coeffSign+1)/2+0.5);
%         set(handles.bar,'EdgeColor','none');
%         caxis([-1 1]);
% 
%         coeffLabels=forPlotting.neuronLabels(coeffSortIndex);
%         if options.rotateCoeffLabelsFlag && ~options.horizontalCoeffPlotFlag
% 
%             if verLessThan('matlab','8.4')
%                % <=R2014a
%                rotateXLabels(gca,90);
%             else
%                % >R2014a
%                set(gca, 'XTickLabelRotation', 90);
%             end
% 
%         end
% 
%         if options.drawCoeffSeparators
% 
% 
%                sepX=find(diff(eAD{2}));
%                hline(sepX+0.5);
% 
%          end
%     end
% 
% 
%     if (options.plotSplitFigures)
%         mtit([wbstruct.displayname ' -' flagstr]);
%     end
% 
% end




if options.summaryPlot
    
   for s=1:numel(stats)
    
    
       
       mean1A=cellapse(D.Stim.Rise.trajC1_PreStim.(stats{s}))
       mean2A=cellapse(D.Stim.Rise.trajC1_Stim.(stats{s}))
       mean3A=cellapse(D.Stim.Rise.trajC1_NoStim.(stats{s}))
   
    
   end

end



%%  basic branching bundle probability comparison


groupName={'Stim','CTRL'};

folder={'/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/Stim/&fixed',...
    '/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/NoStim/&fixed'};

outputDir='/Users/skato/Desktop/Dropbox/MyPaperWB';

trajType={'Rise','Fall'};
trajTypeNum=[2 4];

figure('Position',[0 0 400 400],'Color','w');
        
for t=1:numel(trajType)


    outputFileName=[outputDir filesep 'StimMagAnalysis-' trajType{t} '-' 'PC1.pdf'];
    
    if exist(outputFileName,'file');
        delete(outputFileName);
    end

    for G=1:numel(groupName);


        cd(folder{G}');

        wbSS=load('wbStateStatsStruct.mat');

        folders=listfolders(pwd,true);


        %load cluster data
        clear cl;
        for d=1:numel(folders)

            cd(folders{d});
            
            if t==1
                cl{d}=load(['Quant' filesep 'wbClusterRiseStruct.mat']);
            else
                cl{d}=load(['Quant' filesep 'wbClusterFallStruct.mat']);
            end
        end

        cd('..');
        

        
        if G==1 && (t==2 || t==3)
            cl{1}.clusterMembership=[1 1 1 1 2 1 1 2 2 2 2 2 2 2 1 1];
            cl{2}.clusterMembership=[1 1 1 1 2 1 1 1 1 2 1 1 2 1 2];
            cl{7}.clusterMembership=[2 2 2 2 2 1 2 1 1 2 1];

        end

        if G==1 
            SMDCluster=[2 1 2 2 2 1 2];
        else
            SMDCluster=[2 2 2 2 1];
        end
            
        
        
    
        %count all 1 and 2 clusters during stim
        
        
        HIstimC1.(groupName{G})=[];
        HIstimC2.(groupName{G})=[];
        LOstimC1.(groupName{G})=[];
        LOstimC2.(groupName{G})=[];
        
        for d=1:numel(folders)
            
            onset=find(wbSS.stimTimeVector{d},1,'first');
            timeVecMarked=wbSS.stimTimeVector{d};
            timeVecMarked(1:onset-1)=-1;

            startIndices=wbSS.stateRunStartIndices{d,trajTypeNum(t)}(:);

            clusterMembership=cl{d}.clusterMembership(:);  % 1 or 2


              if t==2
                  keyCluster=SMDCluster(d);
              else
                  keyCluster=2;
              end
              
              %stim proportion
              LOstimC1.(groupName{G})= [HIstimC1.(groupName{G}) sum(timeVecMarked(startIndices)==1 & clusterMembership==keyCluster)];
              LOstimC2.(groupName{G})= [HIstimC2.(groupName{G}) sum(timeVecMarked(startIndices)==1 & clusterMembership==3-keyCluster)];


              %nostim proportion
              HIstimC1.(groupName{G})= [LOstimC1.(groupName{G}) sum(timeVecMarked(startIndices)==0 & clusterMembership==keyCluster)];
              HIstimC2.(groupName{G})= [LOstimC2.(groupName{G}) sum(timeVecMarked(startIndices)==0 & clusterMembership==3-keyCluster)];

 
        end
        

              
         end

    G=1;
    HIcontrol(t)=sum(HIstimC1.(groupName{G}))/ ...
          ( sum(HIstimC1.(groupName{G})) + ...
           sum(HIstimC2.(groupName{G})) );


    LOcontrol(t)=sum(LOstimC1.(groupName{G}))/ ...
          ( sum(LOstimC1.(groupName{G})) + ...
           sum(LOstimC2.(groupName{G})) );

%     NumPtsLOControl(t)=( sum(HIstimC1.(groupName{G})) + ...
%            sum(HIstimC2.(groupName{G})) );
%        
%     NumPtsHIControl(t)=( sum(HIstimC1.(groupName{G})) + ...
%            sum(HIstimC2.(groupName{G})) );
    
    G=2;
    HIstim(t)=sum(HIstimC1.(groupName{G}))/ ...
          ( sum(HIstimC1.(groupName{G})) + ...
           sum(HIstimC2.(groupName{G})) );

    LOstim(t)=sum(LOstimC1.(groupName{G}))/ ...
          ( sum(LOstimC1.(groupName{G})) + ...
           sum(LOstimC2.(groupName{G})) );

    NumPtsHIStim(t)=( sum(HIstimC1.(groupName{G})) + ...
           sum(HIstimC2.(groupName{G})) );
       
    NumPtsLOStim(t)=( sum(LOstimC1.(groupName{G})) + ...
           sum(LOstimC2.(groupName{G})) );
       
       
    subtightplot(2,1,t,[.05 .1],[.05 .05],[.15 .05]);
    bar([1 2],[LOcontrol(t) LOstim(t)]);

    hold on;
    bar([4 5],[HIcontrol(t) HIstim(t)]);


    set(gca,'xTick',[1 2 4 5]);
    set(gca,'XTickLabel',{'CTRL','STIM','CTRL','STIM'});
    ylabel([trajType{t} ' branch proportion']);
    ylim([0 0.75]);
text(1.5,0.7,'4%O2 periods','HorizontalAlignment','Center');
        text(4.5,0.7,'21%O2 periods','HorizontalAlignment','Center');
box off;


end
export_fig('clusterStimBiasShift.pdf');


figure('Position',[0 0 400 400],'Color','w');
     
for t=1:2
    
    subtightplot(2,2,1+2*(t-1),[.05 .1],[.05 .05],[.15 .05]);
    
    D.numPts=NumPtsLOStim(t);
    D.refProportion=LOcontrol(t);
    D.measuredProportion=LOstim(t);
    opt.plotFlag=true;
    SigTest('SingleProb',D,opt);
    
    
    subtightplot(2,2,2+2*(t-1),[.05 .1],[.05 .05],[.15 .05]);
    
    D.numPts=NumPtsHIStim(t);
    D.refProportion=HIcontrol(t);
    D.measuredProportion=HIstim(t);
    
    SigTest('SingleProb',D,opt);
    
    
end
export_fig('clusterStimBiasShift.pdf','-append');


end

%
%         clear('stateRangeC1','stateRangeC2','trajC1','trajC2')
%         for d=1:numel(folders)
% 
%                 
%             subplot(3,3,d);
% 
%             %get stateRanges from wbStateStatsStruct
%                        
% if t==1
%             stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}   wbSS.stateRunStartIndices{d,trajTypeNum(t)}+(wbSS.stateFrameLengths{d,trajTypeNum(t)})'-1];
% 
% elseif t==2
%             stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d)))'-1];
%             stateRangeC2{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d))))'-1];
% else
%             stateRangeC2{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==SMDCluster(d)))'-1];
%             stateRangeC1{d}=[wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))   wbSS.stateRunStartIndices{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d)))+(wbSS.stateFrameLengths{d,trajTypeNum(t)}(cl{d}.clusterMembership==(3-SMDCluster(d))))'-1];
%     
% end
% 
%           
% 
%             for RT=1:size(stateRangeC1{d},1)      
% 
%                  trajC1{d}.Cent(RT)=mean(pc{d}.pcs(stateRangeC1{d}(RT,1):stateRangeC1{d}(RT,2),1));
%                  trajC1{d}.Max(RT)=min(pc{d}.pcs(stateRangeC1{d}(RT,1):stateRangeC1{d}(RT,2),1));
%                  trajC1{d}.Middle(RT)=min(pc{d}.pcs(round((stateRangeC1{d}(RT,1)+stateRangeC1{d}(RT,2))/2),1));
% 
%             end
%             
% if t>1           
%             for RT=1:size(stateRangeC2{d},1)      
% 
%                  trajC2{d}.Cent(RT)=mean(pc{d}.pcs(stateRangeC2{d}(RT,1):stateRangeC2{d}(RT,2),1));
%                  trajC2{d}.Middle(RT)=min(pc{d}.pcs(round((stateRangeC2{d}(RT,1)+stateRangeC2{d}(RT,2))/2),1));
%             end
% end
% 
% 
%             %label as NoStim Stim Prestim
%             stateRangeC1_NoStim{d}=[];
%             stateRangeC1_Stim{d}=[];
%             stateRangeC1_PreStim{d}=[];
% 
%             for s=1:numel(stats)
%                 trajC1_Stim{d}.(stats{s})=[];
%                 trajC1_PreStim{d}.(stats{s})=[];
%                 trajC1_NoStim{d}.(stats{s})=[];
%             end
% 
%             onset=find(wbSS.stimTimeVector{d},1,'first');
%             timeVecMarked=wbSS.stimTimeVector{d};
%             timeVecMarked(1:onset-1)=-1;
% 
%             for RT=1:size(stateRangeC1{d},1)
% 
%                 if wbSS.stimTimeVector{d}(stateRangeC1{d}(RT,1))==1
%                     stateRangeC1_Stim{d}=[stateRangeC1_Stim{d};  stateRangeC1{d}(RT,:)  ];
%                     for s=1:numel(stats)
%                          trajC1_Stim{d}.(stats{s})=[trajC1_Stim{d}.(stats{s}) trajC1{d}.(stats{s})(RT)];
%                     end
% 
%                 elseif timeVecMarked(stateRangeC1{d}(RT,1))==-1
% 
%                     stateRangeC1_PreStim{d}=[stateRangeC1_PreStim{d};  stateRangeC1{d}(RT,:)  ];   
%                     for s=1:numel(stats)
%                          trajC1_PreStim{d}.(stats{s})=[trajC1_PreStim{d}.(stats{s}) trajC1{d}.(stats{s})(RT)];
%                     end
% 
%                 else
% 
%                     stateRangeC1_NoStim{d}=[stateRangeC1_NoStim{d};  stateRangeC1{d}(RT,:)  ];
%                     for s=1:numel(stats)
%                          trajC1_NoStim{d}.(stats{s})=[trajC1_NoStim{d}.(stats{s}) trajC1{d}.(stats{s})(RT)];
%                     end
% 
%                 end
%             end
% 
% 
%         end %d
     


