%% PlotWormHead
% For figure

%second to plot:
secToPlot = 370;

%time frame to MIP
secRange = 60;

%Frame to plot
Frame = round(secToPlot*wbstruct.fps);
frameRange = round(secRange*wbstruct.fps);

MainDir = strcat(pwd,strcat('/_',FolderName));

%% get tiffs
cd('/Users/nichols/Desktop/_movieMaking');
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
        currImageLength = (length(imageStack)+1);
        for k = 1:numberOfImages
            %currImageLength:(currImageLength+numberOfImages);
            currentImage = imread(RawImageName, k, 'Info', info);
            imageStack(:,:,(k+currImageLength)) = currentImage;
        end
    end
end

%% secRange

% Get maximum intensity projection.
mip = max(imageStack(:,:,Frame:(Frame+frameRange)), [], 3);

fig = figure;
imagesc(fliplr(mip')); %rot90
caxis([0,70000])
colorbar
colormap(jet)
axis off
[rowS,colS,planeS]=size(imageStack);
set(gca, 'PlotBoxAspectRatio',[1 colS/rowS 1]);
%set(fig,'Position', [200 200 600 400]);

line('XData', [10, (10+((pixelsize)*10))], 'YData', [105, 105],'color','w','LineStyle', '-','Linewidth',4);
text(10,120,'10um','Fontsize',10,'Color','w')

% calulate seconds
hold on
text(10,15,strcat(num2str(secToPlot),'-',num2str(secToPlot+secRange),'s'),'Fontsize',10,'Color','w');

filename = strcat(MainDir,'/Fig_',num2str(secToPlot),'.ai');
print (gcf,'-depsc', '-r300', sprintf(filename));

