%% PlotWormHead
% For figure updated 2017/02/03 for ease of access.
% NOT FINISHED WANT TO update to take in original ome
%Need to use a MIP of the ome with: "ome.tiff" ending

% Input:
%second to plot:
secToPlot = 370;

%time frame to MIP
secRange = 60;

%Search end for MAXs omes (make sure these are the only in the folder, will load all):
basename = '*.tiff';


%%
%Frame to plot
Frame = round(secToPlot*wbstruct.fps);
frameRange = round(secRange*wbstruct.fps);

MainDir = strcat(pwd,strcat('/_',FolderName));

% get tiffs

flnms=dir(basename); %create structure from filenames

pixelsize = 3.23; %um/pixel
  
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
        currImageLength = (length(imageStack)+1);
        for k = 1:numberOfImages
            %currImageLength:(currImageLength+numberOfImages);
            currentImage = imread(RawImageName, k, 'Info', info);
            imageStack(:,:,(k+currImageLength)) = currentImage;
        end
    end
    
    j = 0;
fname = sprintf('cropped_sequence%.4d.bmp',j);
image4d = imread(fname);
image4d(:,:,:,601) = 0;
for j = 1 : 600
  fname = sprintf('cropped_sequence%.4d.bmp',j);
  image4d(:,:,:,j+1) = imread(fname);
end

end

%% secRange

% Get maximum intensity projection.
mip = max(imageStack(:,:,Frame:(Frame+frameRange)), [], 3);

fig = figure;
% change orientation:
imagesc(fliplr(mip')); %rot90, or fliplr or flipud

caxis([0,70000])
colorbar
colormap(jet)
axis off
[rowS,colS,planeS]=size(imageStack);
set(gca, 'PlotBoxAspectRatio',[1 colS/rowS 1]);
%set(fig,'Position', [200 200 600 400]);

% Plot scale bar 10um
line('XData', [10, (10+((pixelsize)*10))], 'YData', [105, 105],'color','w','LineStyle', '-','Linewidth',4);
text(10,120,'10um','Fontsize',10,'Color','w')


% calulate seconds
hold on
text(10,15,strcat(num2str(secToPlot),'-',num2str(secToPlot+secRange),'s'),'Fontsize',10,'Color','w');

filename = strcat('/Fig_',num2str(secToPlot),'.ai');
print (gcf,'-depsc', '-r300', sprintf(filename));

