function background = CreateBackgroundImage(basename,frameinterval)

%this function adds every "frameinterval" frames and averages to obtain the background
%image from all avi movies in the current working folder
%-----------------------------------------------------------------------
 
flnms=dir(basename); %create structure from filenames
[nummovs, ~] = size(flnms);

firstmoviename=flnms(1).name;
FileInfo=VideoReader(firstmoviename);
m = FileInfo.Width;
n = FileInfo.Height;
%frameinterval = 100;


if strcmp(FileInfo.VideoFormat,'RGB24')
    
    cdatasum = zeros(n,m,3,'double'); %for 24-bit movies
    
else
    cdatasum = zeros(n,m,'double');   %for 8-bit movies
    
end;

cnt=0;

for currentmov = 1:nummovs;

RawMovieName = flnms(currentmov).name;
FileInfo = VideoReader(RawMovieName);

disp(strcat('... calculating background image for movie', 32 ,RawMovieName));

% Mov = aviread(RawMovieName, 1);
 %Movcolormap = Mov.colormap;

for Frame = 1:frameinterval:FileInfo.NumberOfFrames
    
    %progress = 100*round(Frame / FileInfo.NumberOfFrames);
    %fprintf('%d / %d -- [%.2f] \n',Frame,FileInfo.NumberOfFrames,progress);
    fprintf('%d \n',cnt);
    cnt=cnt+1;
    Mov = read(FileInfo, Frame);
    MovX64 = double(Mov)/255;
    cdatasum = cdatasum + MovX64;  
end
end;

fprintf('Background image has been created \n');
cdataaverage = cdatasum./cnt;
background = uint8(round(cdataaverage*255));