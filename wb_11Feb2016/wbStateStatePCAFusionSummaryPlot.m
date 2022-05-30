

stats={'Cent','Middle','Max'};

colors={'g','b','r'};
colorsL={'lg','lb','lr'};

normalization={'Fold change','magnitude'};
nI=1;

normFunc={@geomean,@mean};

range={[0 3],[-.2 .5]};

c;

hw=.4;

figure('Color','w','Position',[0 0 1000 600]);

   
for s=1:numel(stats)
    
   subtightplot(numel(stats),1,s,[.15 .05],[.1 .1],[.05 .05]);
       
   dist{1}=cellapse(D.Stim.Rise.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(dist{1});
   dist{1}=dist{1}/sf;
   dist{2}=cellapse(D.Stim.Rise.trajC1_Stim.(stats{s}))/sf;
   dist{3}=cellapse(D.Stim.Rise.trajC1_NoStim.(stats{s}))/sf;

   dist{4}=cellapse(D.Stim.Rise1.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(dist{4});
   dist{4}=dist{4}/sf;
   dist{5}=cellapse(D.Stim.Rise1.trajC1_Stim.(stats{s}))/sf;
   dist{6}=cellapse(D.Stim.Rise1.trajC1_NoStim.(stats{s}))/sf;
   
   dist{7}=cellapse(D.Stim.Rise2.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(dist{7});
   dist{7}=dist{7}/sf;
   dist{8}=cellapse(D.Stim.Rise2.trajC1_Stim.(stats{s}))/sf;
   dist{9}=cellapse(D.Stim.Rise2.trajC1_NoStim.(stats{s}))/sf;
   
   dist{10}=cellapse(D.Stim.FallSMDV.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(dist{10});
   dist{10}=dist{10}/sf;
   dist{11}=cellapse(D.Stim.FallSMDV.trajC1_Stim.(stats{s}))/sf;
   dist{12}=cellapse(D.Stim.FallSMDV.trajC1_NoStim.(stats{s}))/sf;
   
   dist{13}=cellapse(D.Stim.FallSMB.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(dist{13});
   dist{13}=dist{13}/sf;
   dist{14}=cellapse(D.Stim.FallSMB.trajC1_Stim.(stats{s}))/sf;
   dist{15}=cellapse(D.Stim.FallSMB.trajC1_NoStim.(stats{s}))/sf;
   
   
   %CONTROLS
   
   distc{1}=cellapse(D.CTRL.Rise.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(distc{1});
   distc{1}=distc{1}/sf;
   distc{2}=cellapse(D.CTRL.Rise.trajC1_Stim.(stats{s}))/sf;
   distc{3}=cellapse(D.CTRL.Rise.trajC1_NoStim.(stats{s}))/sf;

   distc{4}=cellapse(D.CTRL.Rise1.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(distc{4});
   distc{4}=distc{4}/sf;
   distc{5}=cellapse(D.CTRL.Rise1.trajC1_Stim.(stats{s}))/sf;
   distc{6}=cellapse(D.CTRL.Rise1.trajC1_NoStim.(stats{s}))/sf;
   
   
   distc{7}=cellapse(D.CTRL.Rise2.trajC1_PreStim.(stats{s}));

   sf=normFunc{nI}(distc{7});
   distc{7}=distc{7}/sf;
   distc{8}=cellapse(D.CTRL.Rise2.trajC1_Stim.(stats{s}))/sf;
   
%    if s==3
%       distc{8};
%       distc{8}(distc{8}<0)=[];
%    end
   
   distc{9}=cellapse(D.CTRL.Rise2.trajC1_NoStim.(stats{s}))/sf;
   
   distc{10}=cellapse(D.CTRL.FallSMDV.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(distc{10});
   distc{10}=distc{10}/sf;
   distc{11}=cellapse(D.CTRL.FallSMDV.trajC1_Stim.(stats{s}))/sf;
   distc{12}=cellapse(D.CTRL.FallSMDV.trajC1_NoStim.(stats{s}))/sf;
   
   distc{13}=cellapse(D.CTRL.FallSMB.trajC1_PreStim.(stats{s}));
   sf=normFunc{nI}(distc{13});
   distc{13}=distc{13}/sf;
   distc{14}=cellapse(D.CTRL.FallSMB.trajC1_Stim.(stats{s}))/sf;
   distc{15}=cellapse(D.CTRL.FallSMB.trajC1_NoStim.(stats{s}))/sf;
   
   sh=.3;
   
   
   refDistInd=[1 1 4 4 7 7 10 10 13 13];
   %compute P Values
   k=1;
   for i=[2 3 5 6 8 9 11 12 14 15]
       
       D.sampleSize=numel(dist{i});
       D.empDist=[dist{refDistInd(k)}; dist{i}];
       opt.testStatisticFunction=normFunc{nI};
       opt.plotFlag=false;
       D.acceptLevel=mean(dist{i});       
       opt.numSamples=100000;
       pTemp=SigTest('bootstrap',D,opt);
       pValue(k)=min([pTemp 1-pTemp]);
       if pValue(k)==0
           pValue(k)=1/opt.numSamples;
       end
       k=k+1;
       
   end
   
   for i=1:15
          nValue(i)=numel(dist{i});
   end
          
   %compute P Values CTRL
   k=1;
   for i=[2 3 5 6 8 9 11 12 14 15]
       
       DC.sampleSize=numel(distc{i});
       DC.empDist=[distc{refDistInd(k)}; distc{i}];
       opt.testStatisticFunction=normFunc{nI};
       opt.plotFlag=false;
       DC.acceptLevel=mean(distc{i});       
       opt.numSamples=100000;
       
       pTemp=SigTest('bootstrap',DC,opt);
       
       pValueC(k)=min([pTemp 1-pTemp]);
       if pValueC(k)==0
           pValueC(k)=1/opt.numSamples;
       end
       k=k+1;
       
   end
   
   for i=1:15
          nValueC(i)=numel(distc{i});
   end
   
   
   
   
   
   
   
   
   plotSpread(dist,'xValues',[1 2 3 5 6 7 9 10 11 13 14 15 17 18 19],...
       'distributionColors',{'g','b','r','g','b','r','g','b','r','g','b','r','g','b','r'});
   plotSpread(distc,'xValues',-sh+[1 2 3 5 6 7 9 10 11 13 14 15 17 18 19],...
       'distributionColors',{color('lg'),color('lb'),color('lr'),...
       color('lg'),color('lb'),color('lr'),...
       color('lg'),color('lb'),color('lr'),...
       color('lg'),color('lb'),color('lr'),...
       color('lg'),color('lb'),color('lr')});
   
   hold on;
   
   
   for i=1:3
       line([i-hw i+hw]-sh,[mean(distc{i}) mean(distc{i})],'Color',color(colorsL{i}));
   end
   
   for i=4:6
       line([i-hw i+hw]+1-sh,[mean(distc{i}) mean(distc{i})],'Color',color(colorsL{i-3}));
   end
   
   for i=7:9
       line([i-hw i+hw]+2-sh,[mean(distc{i}) mean(distc{i})],'Color',color(colorsL{i-6}));
   end
   
   for i=10:12
       line([i-hw i+hw]+3-sh,[mean(distc{i}) mean(distc{i})],'Color',color(colorsL{i-9}));
   end
   
   for i=13:15
       line([i-hw i+hw]+4-sh,[mean(distc{i}) mean(distc{i})],'Color',color(colorsL{i-12}));
   end
   
   
   
   for i=1:3
       line([i-hw i+hw],[mean(dist{i}) mean(dist{i})],'Color',color(colors{i}));
   end
   
   for i=4:6
       line([i-hw i+hw]+1,[mean(dist{i}) mean(dist{i})],'Color',color(colors{i-3}));
   end
   
   for i=7:9
       line([i-hw i+hw]+2,[mean(dist{i}) mean(dist{i})],'Color',color(colors{i-6}));
   end
   
   for i=10:12
       line([i-hw i+hw]+3,[mean(dist{i}) mean(dist{i})],'Color',color(colors{i-9}));
   end
   
   for i=13:15
       line([i-hw i+hw]+4,[mean(dist{i}) mean(dist{i})],'Color',color(colors{i-12}));
   end
   
   
   hline; 
   yl=range{nI};
   ylim(yl); 
   topliney=yl(2);
   subline1y=yl(1) -  0.15*(yl(2)-yl(1));
   subline2y=yl(1) -  0.25*(yl(2)-yl(1));
   subline3y=yl(1) -  0.35*(yl(2)-yl(1));
   subline4y=yl(1) -  0.45*(yl(2)-yl(1));
   subline5y=yl(1) -  0.55*(yl(2)-yl(1));
   
   ylabel(normalization{nI});
   set(gca,'xTick',[1 2 3 5 6 7 9 10 11 13 14 15 17 18 19]);
   set(gca,'xTickLabel',{'Pre','4%','21%','Pre','4%','21%','Pre','4%','21%','Pre','4%','21%','Pre','4%','21%'});
   set(gca,'TickLength',[.01 .01]);
   text(2,topliney,'Rise','HorizontalAlignment','center');
   text(6,topliney,'Rise1','HorizontalAlignment','center');
   text(10,topliney,'Rise2','HorizontalAlignment','center');
   text(14,topliney,'FallSMDV+','HorizontalAlignment','center');
   text(18,topliney,'FallSMB+','HorizontalAlignment','center');
   %write in pValues
   
   pos=[2 3 6 7 10 11 14 15 18 19];
   for k=1:10
       text(pos(k),subline2y,['p<' num2str(pValue(k),2)],'HorizontalAlignment','center');

   end
   
   pos=[1 2 3 5 6 7 9 10 11 13 14 15 17 18 19];
   for k=1:15
       text(pos(k),subline3y,['n=' num2str(nValue(k),2)],'HorizontalAlignment','center');
   end
               
   pos=[2 3 6 7 10 11 14 15 18 19];
   for k=1:10
       text(pos(k),subline4y,['p<' num2str(pValueC(k),2)],'HorizontalAlignment','center','Color',[0.5 0.5 0.5]);

   end
   
   pos=[1 2 3 5 6 7 9 10 11 13 14 15 17 18 19];
   for k=1:15
       text(pos(k),subline5y,['n=' num2str(nValueC(k),2)],'HorizontalAlignment','center','Color',[0.5 0.5 0.5]);
   end
               
   
   
   
   proplot;
   title(['stat: ' stats{s}]);
   
end

export_fig('MagEffectSummary.pdf');

%% mag effects for individual neuron traces

groupName={'Stim','CTRL'};

folder={'/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/Stim/&fixed',...
    '/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/AnalyzedWholeBrainDatasets/NoStim/&fixed'};

outputDir='/Users/skato/Desktop/Dropbox/MyPaperWB';
stats={'Cent','Max','Middle'};

trajType={'Rise','FallSMDV','FallSMB','Rise1','Rise2'};
trajTypeNum=[2 4 4 2 2];

options.measureNeuronTraces=true;
if options.measureNeuronTraces
    
    s=1;
    
    for G=1:numel(groupName)
        
        cd(folder{G});
        folders=listfolders(pwd,true);
        
        for t=1:numel(trajType)
            
            figure('Position',[0 0 1200 800]);
         
            for d=1:numel(folders)

                 pc{d}=wbLoadPCA(folders{d},false);

                
                
                 subplot(numel(folders),1,d);
                 if ~isempty(DN.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}) && ~isempty(DN.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d})
                     ppcOptions.externalCoeffs=(mean(abs(DN.(groupName{G}).(trajType{t}).trajC1_Stim.(stats{s}){d}),1) - mean(abs(DN.(groupName{G}).(trajType{t}).trajC1_PreStim.(stats{s}){d}),1))';
                 else
                     ppcOptions.externalCoeffs=zeros(size(pc{d}.coeffs(:,1)));
                 end
                 ppcOptions.plotNumComps=1;
                 ppcOptions.plotSections={'coeffs'};
                 ppcOptions.subPlotFlag=true;
                 wbPlotPCA(folders{d},pc{d},ppcOptions);
                 ylabel(['d' num2str(d)]);
                 ylim([-0.05 .05]);
            end
            
            mtit([groupName{G} ' - ' trajType{t}]);
            
            if exist('MagEffectIndivNeurons.pdf','file') && G==1 && t==1
                export_fig([outputDir filesep 'MagEffectIndivNeurons.pdf']);
            else             
                export_fig([outputDir filesep 'MagEffectIndivNeurons.pdf'],'-append');
            end
            close;
        end
    end
    
end



