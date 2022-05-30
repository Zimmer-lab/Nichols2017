function wbMakeMontageMovieForWB4D(mainfolder)

if nargin<1 
    mainfolder=pwd;
end

options.movieQuality=100;
options.movieType='Grayscale AVI';
%options.movieType='MPEG-4';
options.textLabels=false;
options.palette=gray(256);
options.frameRate=20;
wbMakeMontageMovie(mainfolder,options);

end
