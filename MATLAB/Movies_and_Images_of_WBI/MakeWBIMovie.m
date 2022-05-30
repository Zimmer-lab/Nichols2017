%% MakeWBIMovie
%input below
clear

FolderName = 'WormHeadMovie_3rdFrame';

plotWidth = [1,450]; %[0,0]==default movie size. Otherwise specifiy [min, max]. In pixels.

%%%% For the following: 0 off, 1 on
%plot only one frame to see how it works?
plotTest = 0;

%Need to flip left/right?
FlipLtoR = 1;

%Need to flip up/down?
FlipUtoD = 1;

%OmeNotInFolder? Add address:
FindOme = 1;

OmeAddress = '/Volumes/groups/zimmer/Annika_Nichols/Imaging/An20140730_ZIM575_Pre_1mM/AN20140730a_ZIM575_PreLet_6m_O2_21_s_1TF_47um_1330_';

%%

pixelsize = 3.23; %um/pixel

MainDir = strcat(pwd,strcat('/_',FolderName));

wbload;

%makes subfolder for movie files
if exist(strcat('_',FolderName),'dir') < 1;
    mkdir(strcat('_',FolderName));
end

%get tiffs
if FindOme
    cd(OmeAddress);
end
basename = '*.tiff';
%create structure from filenames
flnms=dir(basename);

if isempty(flnms)
    display('ATN!: Could not find maximum intensity project (needs to end with .tif)');
    return
end

%load images
imageStack = [];

for stackN =1:length(flnms);
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

[rowS,colS,NumFrames]=size(imageStack);

samplerate = wbstruct.fps;

%plot part of image:
%default:
[IwidthMax, Iheight, ~] = size(imageStack);
%input:
IwidthMin = 1;
if sum(plotWidth ~= [0,0]);
    IwidthMin = plotWidth(1);
    IwidthMax = plotWidth(2);
end

%%
cd(MainDir);
count = 1;

for Frame = 1:3:NumFrames; %total recording
    % Create figure
    figure1 = figure;
    hold on;
    
    % find current second
    seconds = floor(Frame/samplerate);
    
    %plot current frame
    subplot3 = subplot(1,1,1);
    
    %rotate image correctly
    if FlipLtoR && FlipUtoD
        imagesc(rot90(imageStack(IwidthMin:IwidthMax,:,Frame)',2));
    elseif FlipLtoR && ~FlipUtoD
        imagesc(fliplr(imageStack(IwidthMin:IwidthMax,:,Frame)'));
    elseif FlipUtoD && ~FlipLtoR
        imagesc(flipud(imageStack(IwidthMin:IwidthMax,:,Frame)'));
    end
    
    set(0,'defaultAxesFontSize',16)
    axis off
    colormap(gray)
    caxis([0,max(max(max(imageStack)))]); %70000?
    
    % Plot scale bar 10um
    hold on;
    line('XData', [10, (10+((pixelsize)*10))], 'YData', [10, 10],'color','w','LineStyle', '-','Linewidth',5);
    text(10,18,'10um','Fontsize',16,'Color','w')
    
    %Plot seconds and oxygen
    hold on
    text(10,Iheight-22,strcat(num2str(seconds),'s'),'Fontsize',16,'Color','w');
    if seconds < 360
        oxCon = 'Oxygen: 10%';
    elseif seconds > 720
        oxCon = 'Oxygen: 10%';
    else
        oxCon = 'Oxygen: 21%';
    end
    
    text(10,Iheight-10,oxCon,'Fontsize',16,'Color','w');
    
    subimage(subplot3, jet)
    
    set(gcf, 'Position',[0,0,IwidthMax*2,Iheight*2]);
    set(gca,'position',[0 0 1 1],'units','normalized')
    count1= num2str(count);
    count=count+1;
    
    %filename = strcat(MainDir,'/MovieS2_',count1,'.tif');
    filename = strcat('wbiMovie_',count1,'.tif');
    set(gcf, 'InvertHardCopy', 'off');
    set(gcf,'PaperPositionMode','auto')
    print('-dtiff','-r100','-painters', filename);
    
    if plotTest
        return
    end
    close all
end
