%% MakePhasePlotHeatMapMovie
%ONLY WORM MOVIE
% Input
% quantDir ='/Users/nichols/Dropbox/Annika Lab/imaging data/npr1_2_Let/AN20140731d_ZIM575_Let_6m_O2_21_s_1TF_50um_1240_';
% cd(quantDir);

clear all

FolderName = 'WormHeadMovie_3rdFrame'; 

pixelsize = 3.23; %um

%% 
MainDir = strcat(pwd,strcat('/_',FolderName));

wbload;

%%
%makes subfolder for movie files
if exist(strcat('_',FolderName),'dir') < 1;
    mkdir(strcat('_',FolderName));
end

%get tiffs
%cd('/Users/nichols/Desktop/_movieMaking');
basename = '*.tif';
flnms=dir(basename); %create structure from filenames

imageStack = [];

for stackN =1:2;
    RawImageName = flnms(stackN).name;
    info = imfinfo(RawImageName);
    numberOfImages = length(info);
    if stackN == 1;
        for k = 1:numberOfImages
            currentImage = imread(RawImageName, k, 'Info', info);
            imageStack(:,:,k) = currentImage;
        end
    elseif stackN == 2;
        currImageLength = (length(imageStack));
        for k = 1:numberOfImages
            currentImage = imread(RawImageName, k, 'Info', info);
            imageStack(:,:,(k+currImageLength)) = currentImage;
        end
    end
end
[rowS,colS,planeS]=size(imageStack);

samplerate = wbstruct.fps;


%% Labeling state
stateName = {'Awake','Quiescent  '};

load(strcat(pwd,'/Quant/QuiescentState.mat'));

Cforward = [53 185 228]/255;
Creversal = [249 178 17]/255;
Cquiescence = [41 75 154]/255;

recessmap2 = [Creversal;Cforward];

%%
[~,~,NumFrames] = size(imageStack);
count = 1;

count = 401;

scrrensize = [1,1,1200,350];
%get(0,'Screensize');

for Frame = 1203:3:NumFrames; %total recording    
    % Create figure
    figure1 = figure;
    hold on;

    set(gcf, 'Position', scrrensize);
    set(gcf,'PaperPositionMode','auto');
    
    % find current second 
    seconds = floor(Frame/samplerate);
    
    %MAY NEED TO CHANGE!
    %imagesc(flipud(fliplr(imageStack(:,:,Frame)')));
    imagesc(fliplr(flipud(imageStack(1:512,:,Frame)')));
    %set(0,'defaultFontSize', 16)
    set(0,'defaultAxesFontSize',16)
    
    axis off
   
%     hold on; 
%     h= text(520,35,'Fluorescence (a.u.)  ','Fontsize',16,'Color','k');
%     set(h, 'rotation', 90)
    
    set(gca, 'PlotBoxAspectRatio',[1 colS/rowS 1]);
    colormap(gray)
    caxis([0,70000]);
    
    % Plot scale bar 10um
    hold on;
    line('XData', [10, (10+((pixelsize)*10))], 'YData', [133, 133],'color',[0.99,0.99,0.99],'LineStyle', '-','Linewidth',5);
    text(15,125,'10um','Fontsize',16,'Color',[0.99,0.99,0.99],'FontWeight','bold')
    
    %Plot seconds and oxygen
    hold on
    text(10,34,['Time: ',num2str(seconds),'s'],'Fontsize',16,'Color',[0.99,0.99,0.99],'FontWeight','bold');
    if seconds < 360
        oxCon = 'Oxygen: 10%';
    elseif seconds > 720
        oxCon = 'Oxygen: 10%';
    else
        oxCon = 'Oxygen: 21%';
    end
    
    %State colour labeling 
    text(10, 12,stateName{(QuiesceBout(Frame)+1)},'Fontsize',16,'Color',recessmap2((QuiesceBout(Frame)+1),:),'FontWeight','bold');
    
    text(10,23,oxCon,'Fontsize',16,'Color',[0.99,0.99,0.99],'FontWeight','bold');

    count1= num2str(count);
    count=count+1;
    
    filename = strcat(MainDir,'/MovieS2_',count1,'.tiff');
    print('-dtiff','-r100', filename);
    
    close all
end
