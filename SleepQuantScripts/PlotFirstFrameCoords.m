% get movie information
usemp4 = 0;

if usemp4
    movies=dir('*.mp4');
    filename=movies(1).name;
    disp(filename);
    mv = VideoPlayer(filename,'Verbose',false,'ShowTime',false);
    
    % get first frame of movie
    mv.nextFrame(1-1);
    firstrun = 0;
    fr = mv.getFrameUInt8();
else
    movies=dir('*.avi');
    filename=movies(1).name;
    disp(filename);
    mv = VideoReader(filename);
    
    % get first frame of movie
    fr = read(mv, [1] );
end

% Load first movie track
alsFiles=dir('*_als.mat');
filenameMat=alsFiles(1).name;
disp(filenameMat);
load(filenameMat)

% Get all coordinates for the first frame
AllCoordins =[];

for TrckN = 1: length(Tracks)
    if Tracks(TrckN).Frames(1) == 1
        AllCoordins(TrckN,1:2) = Tracks(TrckN).Path(1,1:2);
    end
end

%Plot first frame with scatter of worm positions
figure; imshow(fr);
hold on; scatter(AllCoordins(:,1),AllCoordins(:,2),'r')
