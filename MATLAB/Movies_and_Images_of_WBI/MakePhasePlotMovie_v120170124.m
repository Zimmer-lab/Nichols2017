%% MakePhasePlotHeatMapMovie
% ONLY PHASEPLOT
% Input
% quantDir ='/Users/nichols/Dropbox/Annika Lab/imaging data/npr1_2_Let/AN20140731d_ZIM575_Let_6m_O2_21_s_1TF_50um_1240_';
% cd(quantDir);

clear all

FolderName = 'PhasePlotMovie_3rdFrame_single'; 

% pixelsize = 3.135245; %um %Check?

% HeatMapScale = [-0.2 1.8];%
% 
% DiffTag = false; SmoothWin = 5;
% 
% Method = 'corr'; %'corr' or 'cov'

%% 
MainDir = strcat(pwd,strcat('/_',FolderName));

wbload;
load(strcat(pwd,'/Quant/QuiescentState.mat'));
load(strcat(pwd,'/Quant/wbPCAstruct.mat'));

%fwdrun=wbFourStateTraceAnalysis(wbstruct,'useSaved','VB02')==2;
ReversalRISE=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==2;
ReversalHIGH=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==3;
ReversalFALL=wbFourStateTraceAnalysis(wbstruct,'useSaved','AVAL')==4;

Reversal = ReversalRISE | ReversalHIGH;

turnNeuron = {'SMDDL', 'SMDDR','SMDVL','SMDVR','RIVL','RIVR'}; %
stateName = {'Forward','Quiescence  ','Reversal','Turn'};

turn = NaN(length(wbstruct.simple.tv),1,length(turnNeuron));
for ii = 1:length(turnNeuron)
    if sum(strcmp([wbstruct.simple.ID{:}], turnNeuron{ii})) == 1;
        turn(:,:,ii) = wbFourStateTraceAnalysis(wbstruct,'useSaved',turnNeuron{ii})==2;
    end
end
turnAll = nansumD(turn,3)';

% blue = [0 0 204]/255; %255
% burntorange2 = [255 180 0]/255;
% purple = [76 0 103]/255;
% red = [200 20 0]/255;
% turquoise = [0 153 153]/255;
grey = [153 153 153]/255;

Cforward = [53 185 228]/255;
Creversal = [249 178 17]/255;
Cturn = [179 40 133]/255;
Cquiescence = [41 75 154]/255;

colours = colormap(jet(64));

%with red: recessmap = [turquoise;blue;red;burntorange2;purple;grey];
recessmap = [Cforward;Cquiescence;Creversal;Cturn;grey];

%recessmap = [colours;turquoise;blue;red;burntorange2;purple;grey];

tpc1 = cumsum(pcsFullRange(:,1)); %pcsFullRange
tpc2 = cumsum(pcsFullRange(:,2)); %pcsFullRange
tpc3 = cumsum(pcsFullRange(:,3)); %pcsFullRange

% Derivative
% tpc1 = (pcsFullRange(:,1)); %pcsFullRange
% tpc2 = (pcsFullRange(:,2)); %pcsFullRange
% tpc3 = (pcsFullRange(:,3)); %pcsFullRange

colorm = double(2*ReversalRISE+QuiesceBout);
colorm(find(ReversalHIGH),1) = 2; %with red =3
colorm(find(ReversalFALL)) = 3; %with red =4
[NumFrames,~] = size(colorm);
grayColorm = (ones(NumFrames,1))+3; %with red =4

% AllDeltaF = wbstruct.deltaFOverF_bc;
% AllDeltaF(:,wbstruct.exclusionList) = [];
% AllDeltaF=AllDeltaF';
% NanList = sum(isnan(AllDeltaF),2);
% AllDeltaF=AllDeltaF(NanList==0,:);
% 
% TimeVec = wbstruct.tv';
% 
% if DiffTag
%     Dt = diff(TimeVec);
%     AllDeltaF = moving_average(AllDeltaF,SmoothWin,2);
%     AllDeltaF = diff(AllDeltaF,1,2)./(Dt*Dt');
%     TimeVec = TimeVec(2:end);
% end
% 
% [NumTracks, ~] = size(AllDeltaF);
% 
% if strcmp(Method,'corr')
%     SortMatrix = corrcoef(AllDeltaF');
% elseif strcmp(Method,'cov')
%     SortMatrix = cov(AllDeltaF');
% end
% 
% 
% TreeFig = figure;
% [H,T,outperm]=dendrogram(linkage(SortMatrix),NumTracks);
% close;
% 
% AllDeltaFClustered = AllDeltaF(outperm,:);
% NeuronIds = 1:NumTracks;


%makes subfolder for movie files
if exist(strcat('_',FolderName),'dir') < 1;
    mkdir(strcat('_',FolderName));
end

% %get tiffs
% %cd('/Users/nichols/Desktop/_movieMaking');
% basename = '*.tif';
% flnms=dir(basename); %create structure from filenames
% 
% imageStack = [];
% 
% for stackN =1:2;
%     RawImageName = flnms(stackN).name;
%     info = imfinfo(RawImageName);
%     numberOfImages = length(info);
%     if stackN == 1;
%         for k = 1:numberOfImages
%             currentImage = imread(RawImageName, k, 'Info', info);
%             imageStack(:,:,k) = currentImage;
%         end
%     elseif stackN == 2;
%         currImageLength = (length(imageStack));
%         for k = 1:numberOfImages
%             currentImage = imread(RawImageName, k, 'Info', info);
%             imageStack(:,:,(k+currImageLength)) = currentImage;
%         end
%     end
% end
% [rowS,colS,planeS]=size(imageStack);

samplerate = wbstruct.fps;

%%
count = 1;

for Frame = 1%:3:NumFrames; %total recording    
    % Create figure
    figure1 = figure;
    hold on;
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf,'PaperPositionMode','auto');
    
%     % Heatmap Annika manuscript figure
%     subplot2 = subplot(2,4,[3,4]);
%     colormap(jet)
%     
%     wbMpColorbarHandle =colorbar;
%     ylabel(wbMpColorbarHandle,'DF / F0','Fontsize', 12);
%     %ind2rgb(wbMpColorbarHandle,jet)
% 
%     caxis([-0.2,1.8])
%     colorbar
%     cbfreeze
%     subimage(subplot2, jet)
%     %HeatMapFig2 = figure('Position', [50 0 1500 NumTracks * 15],'Color',[1 1 1]);
% 
%     imagesc(TimeVec, 1:NumTracks, AllDeltaFClustered, HeatMapScale)
%     caxis([-0.2,1.8])
%     
%     ylabel('Neuron #','Fontsize', 12);
%     xlabel('Time (s)','Fontsize', 12);
%     set(gca,'Fontsize',12)
%     %title('neurons clustered according to R matrix');
%     
%     line('XData', [360 360], 'YData', [0 (length(NeuronIds)+0.5)],'color','k','LineStyle', '-')
%     line('XData', [720 720], 'YData', [0 (length(NeuronIds)+0.5)],'color','k','LineStyle', '-')
%     
%     hold on
%     text(0,-5,'Oxygen:','Fontsize',12,'Color','k');
%     hold on; text(165,-5,'10%','Fontsize',12,'Color','k');
%     hold on; text(500,-5,'21%','Fontsize',12,'Color','k');
%     hold on; text(865,-5,'10%','Fontsize',12,'Color','k');
%     
%     hold on; 
%     h= text(1250,60,'\DeltaF/F_0','Fontsize',12,'Color','k');
%     set(h, 'rotation', 90)
    
    % find current second 
    seconds = floor(Frame/samplerate);

%     % draw red line at current frame
%     ylimit = ylim;
%     hold on
%     line('XData',[seconds seconds],'YData',[ylimit(1,1) ylimit(1,2)],'Color','r','linewidth',1.2);
%     hold off
    
%     %plot current frame
%     %subplot3 = subplot(2,2,[3,4]);
%     subplot3 = subplot(2,4,[7,8]);
%     
%     %MAY NEED TO CHANGE!
%     %imagesc(flipud(fliplr(imageStack(:,:,Frame)')));
%     imagesc(fliplr((imageStack(1:450,:,Frame)')));
%     %imagesc(fliplr((imageStack(:,:,Frame)')));
%     
%     axis off
%     caxis([0,70000])
%     colorbar
%     cbfreeze
%     
%     hold on; 
%     h= text(510,120,'Fluorescence (a.u.)  ','Fontsize',12,'Color','k');
%     set(h, 'rotation', 90)
%     
%     set(gca, 'PlotBoxAspectRatio',[1 colS/rowS 1]);
%     colormap(jet)
%     caxis([0,70000]);
    
%     % Plot scale bar 10um
%     hold on;
%     line('XData', [10, (10+((pixelsize)*10))], 'YData', [160, 160],'color','k','LineStyle', '-','Linewidth',8);
%     text(10,175,'10um','Fontsize',12,'Color','k')
    
    
%     subimage(subplot3, jet)

    % Plot phase plot
    subplot1 = subplot(1,1,1,'Parent',figure1,'PlotBoxAspectRatio',[1 1 1]);
    set(gca, 'PlotBoxAspectRatio',[1 1 1])
    set(0,'defaultAxesLineWidth',2)

    %MAY NEED TO CHANGE!
    %view(subplot1,[-17 24]);
    view(subplot1,[-44 66]); %Let 31a

    
    grid(subplot1,'on');
    hold(subplot1,'all');
    
%    color_line3(tpc1,tpc2,tpc3,grayColorm,'LineWidth',2.5);
    color_line3(tpc1,tpc2,tpc3,(ones(length(tpc1),1)),'LineWidth',2.5);
    colormap([0,0,0]);
    
    xlabel('cumsum(PC1) ');ylabel('cumsum(PC2) ');zlabel('cumsum(PC3) ');
%     colormap(recessmap);

    %title(wbstruct.trialname)
    %xlabel('PC1', 'FontSize',16);ylabel('PC2', 'FontSize',16);zlabel('PC3', 'FontSize',16);
    % ylim([-2,1]) %Pre 30a
    % xlim([-0.7,3]) %Pre 30a
    % zlim([-1,1]) %Pre 30a
    
    %MAY NEED TO CHANGE!
    %ylim([-1,1]) %Pre 30a
    xlim([-0.5,3.3]) %Let 31a
    
    %set(gca, 'PlotBoxAspectRatio',[1 1 1])
    grid on;
    
    %darker colouring
    largerT = Frame-50:Frame+50;
    if sum(largerT == 0)
        zeroPos = find(largerT == 0);
        largerT(1:zeroPos) = [];
    end
    if sum(largerT == NumFrames)
        endPos = NumFrames;
        largerT(find(largerT ==endPos):end) = [];
    end
    
    hold on;
    color_line3(tpc1(largerT,1),tpc2(largerT,1),tpc3(largerT,1),colorm(largerT,1),'LineWidth',3);
    caxis([0,5])
    
    %ball
    hold on;
    scatter3(tpc1(Frame,1),tpc2(Frame,1),tpc3(Frame,1),70,'k','fill');
%     
%     %State colour labeling %MAY NEED TO CHANGE!
%     text(3.6, 0.9,stateName{(colorm(Frame)+1)},'Fontsize',16,'Color',recessmap((colorm(Frame)+1),:),'FontWeight','bold');
%     %31a 3.2, 1 %TS 4,3.5
%     
%     %Plot seconds and oxygen
%     hold on
%     text(1.3,2.5,strcat('Time: ', num2str(seconds),'s'),'Fontsize',16,'Color','k'); %31a 1.3,2.5 %TS 2,6
%     if seconds < 360
%         oxCon = 'Oxygen: 10%';
%     elseif seconds > 720
%         oxCon = 'Oxygen: 10%';
%     else
%         oxCon = 'Oxygen: 21%';
%     end
%     
%     text(1.1,2.3,oxCon,'Fontsize',16,'Color','k'); %31a 1.1,2.3 %TS 1.8,5.7

    count1= num2str(count);
    count=count+1;
    
    filename = strcat(MainDir,'/MovieS2_',count1,'.tiff');
    print('-dtiff','-r100', filename);
    %close all
end
