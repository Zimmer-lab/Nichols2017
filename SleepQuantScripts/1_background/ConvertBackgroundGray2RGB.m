%% ConvertBackgroundGrat2RGB
% The current cluster tracker version requires the Background input to be
% RGB. This converts grayscale backgrounds into RGB.

currentB = imread('background.tiff');

[~,~, d] = size(currentB);

if d == 1
    display('Converting to RGB')
    rgbImage = cat(3, currentB, currentB, currentB);
elseif d == 3;
    display('Image is already in RGB');
end

%saves in folder
imwrite(rgbImage,'background.tiff')
