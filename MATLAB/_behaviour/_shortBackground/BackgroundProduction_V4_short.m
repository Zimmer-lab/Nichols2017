function BackgroundProduction_V4_short(frameinterval)

    basename      = '*.avi';
    background    = CreateBackgroundImageShort(basename,frameinterval);

    % -- save background as mat file
    bg_string = sprintf('shortbackground_frameinterval_%d.mat',frameinterval);
    save(bg_string, 'background');
    % -- save background as tiff file
    imwrite(background,'background.tiff');
end

