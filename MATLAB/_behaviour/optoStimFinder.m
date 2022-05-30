% optoStimFinder
basename      = '*.avi';
frameinterval = 1;

flnms=dir(basename); %create structure from filenames
[nummovs, ~] = size(flnms);

firstmoviename=flnms(1).name;
FileInfo=VideoReader(firstmoviename);
m = FileInfo.Width;
n = FileInfo.Height;

if strcmp(FileInfo.VideoFormat,'RGB24')
    
    cdatasum = zeros(n,m,3,'double'); %for 24-bit movies
    
else
    cdatasum = zeros(n,m,'double');   %for 8-bit movies
    
end;

cnt=0;

for currentmov = 1:nummovs;

RawMovieName = flnms(currentmov).name;
FileInfo = VideoReader(RawMovieName);

disp(strcat('... calculating intensities for movie', 32 ,RawMovieName));

for Frame = 1:frameinterval:FileInfo.NumberOfFrames
%for Frame = 1800:frameinterval:3000%FileInfo.NumberOfFrames

    %progress = 100*round(Frame / FileInfo.NumberOfFrames);
    %fprintf('%d / %d -- [%.2f] \n',Frame,FileInfo.NumberOfFrames,progress);
    fprintf('%d \n',cnt);
    cnt=cnt+1;
    
    Mov = read(FileInfo, Frame);
    try
        grayScaleImage = rgb2gray(Mov);
    catch
        grayScaleImage = Mov;
    end
    
    upperintsovertime(Frame,1) = prctile(double(grayScaleImage(:)),80);

end

end

