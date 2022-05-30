function BackgroundProduction_V4(frameinterval)

    basename      = '*.avi';
    background    = CreateBackgroundImage(basename,frameinterval);

    % -- save background as mat file
    bg_string = sprintf('background_frameinterval_%d.mat',frameinterval);
    save(bg_string, 'background');
    % -- save background as tiff file
    imwrite(background,'background.tiff');
end

