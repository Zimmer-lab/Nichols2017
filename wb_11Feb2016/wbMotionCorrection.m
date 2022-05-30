function moCoDrift=wbMotionCorrection(mainfolder,timeStep,medFiltWidth,moCoMethod,verboseFlag)

if nargin<5
   verboseFlag=true;
end

if nargin<4 || isempty(moCoMethod)
   moCoMethod='translation';  %rigid will add rotation
end

if nargin<3 || isempty(medFiltWidth)
   medFiltWidth=3;
end

if nargin<2 || isempty(timeStep)
    timeStep=10;
end

if nargin<1 
    mainfolder=pwd;
end

%load Zmovies
ZMovie=wbloadmovies(mainfolder); %this will, by default, try find a movie in the workspace.

width=size(ZMovie{1},2);
height=size(ZMovie{1},1);
numT=size(ZMovie{1},3);
validZs=1:length(ZMovie);
numZ=length(validZs);


%pre filter
disp('wbMotionCorrection> median filtering movie.');
tic
if medFiltWidth>0
    for z=1:length(ZMovie)
        for t=1:numT

            ZMovie{z}(:,:,t)=medfilt2(ZMovie{z}(:,:,t),[medFiltWidth medFiltWidth]);
            
        end
    end
end
toc


%load metadata
if ~isempty(dir([mainfolder '/meta.mat']))
     metadata=load([mainfolder '/meta.mat']);
else
     disp('wbMotionCorrection> no meta.mat file in this folder. Quitting.');
     return;
end

    
%% Image registration
disp('wbMotionCorrection> Processing movie.');

%for imregtform routine
[optimizer,metric] = imregconfig('monomodal');  %configure image registration
optimizer.GradientMagnitudeTolerance=1.000000e-04;
optimizer.MinimumStepLength=1.000000e-05;
optimizer.MaximumStepLength=6.250000e-02;
optimizer.MaximumIterations=100;   %4x from 1 iteration
optimizer.RelaxationFactor=5.000000e-01;


moCoDrift.timeStep=timeStep;
moCoDrift.T=zeros(length(1:moCoDrift.timeStep:numT),1);
moCoDrift.X=zeros(length(1:moCoDrift.timeStep:numT),numZ);
moCoDrift.Y=zeros(length(1:moCoDrift.timeStep:numT),numZ);
moCoDrift.Xinterp=zeros(numT,numZ);
moCoDrift.Yinterp=zeros(numT,numZ);


tic
   
for z=1:numZ

    j=1;
    for t=1:timeStep:numT-moCoDrift.timeStep


        im1=squeeze(ZMovie{z}(:,:,t));
        im2=squeeze(ZMovie{z}(:,:,t+timeStep));

        if strcmp(moCoMethod,'rigid')

            tform=imregtform(im2,im1,'rigid',optimizer,metric,'PyramidLevels',3,'DisplayOptimization',false);
            moCoDrift.X(j,z)=-tform.T(3,1);
            moCoDrift.Y(j,z)=-tform.T(3,2);
            moCoDrift.tForm(j,z)=tform;

        else %image translation only

            [output,~] = dftregistration(fft2(im1),fft2(im2),10);
            moCoDrift.X(j,z)=-output(4);
            moCoDrift.Y(j,z)=-output(3);

        end

        moCoDrift.T(j)=t;

        j=j+1;
    end

    if verboseFlag 
        fprintf('%d..',z);
    end

    moCoDrift.Xinterp(:,z)=interp1(moCoDrift.T,moCoDrift.X(:,z),1:numT,'linear',0)/timeStep;
    moCoDrift.Yinterp(:,z)=interp1(moCoDrift.T,moCoDrift.Y(:,z),1:numT,'linear',0)/timeStep;
    
end

toc 


if ~exist([mainfolder filesep 'Quant']), mkdir([mainfolder filesep 'Quant']); end

save([mainfolder filesep 'Quant' filesep 'wbmoco.mat'],'moCoDrift');

%send notification of completion via OS notification system and console.
try
    MacOSNotify('Motion Correction calculations completed.','Whole Brain Analyzer','','Glass');
end
disp(' wbMotionCorrection> complete.');