function BackgroundProduction_V5(frameinterval)

    basename      = '*.avi';
    [backgroundMax] = CreateBackgroundImageMax(basename,frameinterval);

    % -- save background as mat file
    bg_string = sprintf('backgroundMax_frameinterval_%d.mat',frameinterval);
    save(bg_string, 'backgroundMax');
    % -- save background as tiff file
    imwrite(backgroundMax,'background.tiff');

end

