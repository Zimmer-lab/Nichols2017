%% awbAnalysisAverage
% works on loaded RMSaverage
AnalysisAverage = AnalysisAverage;

%min-max (within bins)
% for recNum = 1:NumDatasets
% normA(:,recNum) = AnalysisAverage.Average(:,recNum) - min(AnalysisAverage.Average(:,recNum));
% normA(:,recNum) = normA(:,recNum) ./ max(normA(:,recNum));
% end

%[bins, NumDatasets] = size(AnalysisAverage.Average);

saveFlag =0;

%% Blue to white colormap
G = (linspace(1,1,100)) .';
R = (linspace(0,1,100)) .';

myGmap = horzcat(R,R,G);
%myGmap = horzcat(zeros(size(G)), zeros(size(G)), G);
% test=jet;
% myGmap = [test(1:9,1),test(1:9,2:3)];

% % %%
% % figure('Color',[1 1 1]);
% % imagesc(AnalysisAverage.Average')
% % wbMpColorbarHandle =colorbar;
% % %ylabel(wbMpColorbarHandle,'min to max','Fontsize', 12);
% % wbMpColorbarHandle
% % caxis([0.15,0.35]);
% % ylabel('Recording #','Fontsize', 12);
% % xlabel('Time (min)','Fontsize', 12);
% % set(gca,'Fontsize',12)
% % colormap jet
% % 
% % hold on
% % 
% % line('XData', [6.5 6.5], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
% % line('XData', [12.5 12.5], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
% % %RMSaverage or AnalysisAverage
% % hold on;
% % x0=10;
% % y0=10;
% % width=600;
% % height=150;
% % set(gcf,'units','points','position',[x0,y0,width,height])
% % set(gcf,'PaperPositionMode','auto')
% % 
% % if saveFlag
% %     print (gcf,'-depsc', '-r300', sprintf('MeanAverages.ai'));
% % end
%% Log scale
% x=linspace(-.005, .005, 100);
% [X,Y] = meshgrid(x,x);
% data = 1./sqrt(X.^2 + Y.^2);
% myscale=[1e2 1e4];
 set(0,'DefaultAxesFontSize',10)
 saveFlag=1;
 %%
for ii =1;%:2;
    myscale=[0.15 0.3];
    % linear plot
    figure
    imagesc(AnalysisAverage.Average') %pcolor cuts last row.
    shading flat
    caxis(myscale)
    colorbar
  
    colormap(jet)

    if ii ==2;
        colormap(myGmap)
    end
   
    hold on
    
    line('XData', [6.5, 6.5], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
    line('XData', [12.5, 12.5], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
    %RMSaverage or AnalysisAverage
    hold on;
    x0=10;
    y0=10;
    width=600;
    height=150;
    set(gcf,'units','points','position',[x0,y0,width,height])
    set(gcf,'PaperPositionMode','auto')
    
    if saveFlag
        if ii ==1;
            print (gcf,'-depsc', '-r300', sprintf('MeanAveragesJetlinear.ai'));
%         else
%             print (gcf,'-depsc', '-r300', sprintf('MeanAveragesBlueWlinear.ai'));
        end
    end
end

% % log plot
% figure
% %myscale=[0.15, 0.3];
% pcolor(log10(AnalysisAverage.Average'))
% shading flat
% colormap((jet)) %flipud
% caxis(myscale)
% h=colorbar;
% ticks_wanted=unique([myscale(1),get(h,'YTick'),myscale(2)]);
% caxis(log10(myscale))
% set(h,'YTick',log10(ticks_wanted));
% set(h,'YTickLabel',ticks_wanted);
% 
% hold on
% 
% line('XData', [7 7], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
% line('XData', [13 13], 'YData', [0 (length(AnalysisAverage.Average)+0.5)],'color','k','LineStyle', '-')
% %RMSaverage or AnalysisAverage
% hold on;
% x0=10;
% y0=10;
% width=600;
% height=150;
% set(gcf,'units','points','position',[x0,y0,width,height])
% set(gcf,'PaperPositionMode','auto')
% 
% if saveFlag
%     print (gcf,'-depsc', '-r300', sprintf('MeanAveragesBWlog.ai'));
% end