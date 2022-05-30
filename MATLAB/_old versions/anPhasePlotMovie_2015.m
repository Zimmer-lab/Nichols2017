%%Making phaseplot movie

MainDir = '/Users/nichols/Documents/Conferences and presentations/Conferences/2016_Berlin EWM/PhasePlotMovies/AN20140731e/'
%%

wbload;
wbLoadPCA;
load([strcat(pwd,'/Quant/QuiescentState.mat')]);

Reversal1=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
Reversal2=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;

Reversal = Reversal1 | Reversal2;

%%
paleblue = [0.8  0.93  1]; %255
forestgreen = [0 153 0]/255;
burntorange = [225 115 0]/255;
yellow = [255 240 102]/255;
purple = [76 0 103]/255;

recessmap = [204 74 51; 40 110 180;254 178 76;];
recessmap = recessmap/255;

count=0;
tpc1 = cumsum(wbPCAstruct.pcsFullRange(:,1));
tpc2 = cumsum(wbPCAstruct.pcsFullRange(:,2));
tpc3 = cumsum(wbPCAstruct.pcsFullRange(:,3));

for i= 1:20:length(wbPCAstruct.pcsFullRange);

PhasePlotFig = figure;
axes1 = axes('Parent',PhasePlotFig,'PlotBoxAspectRatio',[1 1 1.14383284246014],...
    'DataAspectRatio',[1.42857142857143 1 1.14285714285714],...
    'CameraViewAngle',11.8579000764014,...
    'CameraUpVector',[0.46411159907395 0.313731153038431 1.01966106969471],...
    'CameraTarget',[0.699010479327831 0.309062316442623 0.225990458594726],...
    'CameraPosition',[-22.7479752158005 -15.5406813057506 13.4257310537242]);
color_line3(tpc1,tpc2,tpc3,double(2*Reversal+QuiesceBout),'LineWidth',1.8);
xlabel('TPC1', 'FontSize',16);ylabel('TPC2', 'FontSize',16);zlabel('TPC3', 'FontSize',16);

%%%deriv
% color_line3((wbPCAstruct.pcsFullRange(:,1)),(wbPCAstruct.pcsFullRange(:,2)),(wbPCAstruct.pcsFullRange(:,3)),double(2*Reversal+QuiesceBout),'LineWidth',1.8);
% xlabel('PC1', 'FontSize',16);ylabel('PC2', 'FontSize',16);zlabel('PC3', 'FontSize',16);


colormap(recessmap);
grid on;
cameratoolbar;

hold on;
scatter3(tpc1(i,1),tpc2(i,1),tpc3(i,1),70,'k','fill');

set(PhasePlotFig,'Position', [253 68 909 712]);

count=count+1;

count1= num2str(count);

filename = [strcat(MainDir,'/PhasePlotMovie_',count1,'.tiff')];

print('-dtiff','-r300', filename); 

close all;
end