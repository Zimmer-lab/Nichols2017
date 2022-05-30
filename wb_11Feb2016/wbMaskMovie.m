% plot Masks from MT

options.outputFolder=pwd;
numZ=10;
width=126;
height=429;
options.maxPlotWidth=3000;

warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir([options.outputFolder filesep 'Quant' filesep 'MaskMovie']);
warning('on','MATLAB:MKDIR:DirectoryExists');

figure('Position',[0 0 min([1.2*numZ*width options.maxPlotWidth]) 1.2*height]);
for t=1:22
    for z=1:numZ
        subtightplot(1,numZ,z,[0.005 0.005]);
        hold off;
        imagesc(squeeze(MT(:,:,z,t)),[0 400]);
        
        cm=jet(256);
        cm(1,:)=[0 0 0];
        colormap(cm);
        axis off;
        hold on;

    end
    drawnow;
    export_fig([options.outputFolder '/Quant/MaskMovie/mask-T' num2str(t) '.tif']);
end
