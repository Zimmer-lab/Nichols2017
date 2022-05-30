function [V,A]=wbPhasePlot3DVolume(X,Y,Z,timeColoring,voxRes,interpSteps,colorMap)
%compute voxelization of phase trajectories
%
if nargin<6
    interpSteps=10;
end

if isscalar(voxRes)
    voxRes=[voxRes voxRes voxRes];
end

kernelDiam=3;
r=floor(kernelDiam/2);

kernel=GaussBall3D(kernelDiam,2);


A=zeros(voxRes);
V=zeros([voxRes 3]);

if ~iscell(X)  X={X}; end
if ~iscell(Y)  Y={Y}; end
if ~iscell(Z)  Z={Z}; end

xLim=[min(X{1}) max(1.00001*X{1})];
yLim=[min(Y{1}) max(1.00001*Y{1})];
zLim=[min(Z{1}) max(1.00001*Z{1})];

xEdge= (xLim(2)-xLim(1)) /(voxRes(1)-2*r);
yEdge= (yLim(2)-yLim(1)) /(voxRes(2)-2*r);
zEdge= (zLim(2)-zLim(1)) /(voxRes(3)-2*r);

lastX=NaN;
lastY=NaN;
lastZ=NaN;

r2=2*r;

for d=1:length(X)
     
    for t=1:(length(X{d})-1)
        if timeColoring(t)
            for i=1:interpSteps

                fr=(i-1)/interpSteps;
                newX=floor((  (1-fr)*X{d}(t)+fr*X{d}(t+1) - xLim(1))/ xEdge) +1;
                newY=floor((  (1-fr)*Y{d}(t)+fr*Y{d}(t+1) - yLim(1))/ yEdge) +1;
                newZ=floor((  (1-fr)*Z{d}(t)+fr*Z{d}(t+1) - zLim(1))/ zEdge) +1;


                if (newX ~= lastX) || (newY ~= lastY) || (newZ ~= lastZ)

                    %add a voxel  
                    %V(r+newX,r+newY,r+newZ)=timeColoring{d}(t);

                    A(newX:newX+r2,newY:newY+r2,newZ:newZ+r2)=max(A(newX:newX+r2,newY:newY+r2,newZ:newZ+r2),kernel);

                   % V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,:)=colorMap(1+ timeColoring{d}(t) );
    %                 V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,1)=V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,1).*A(newX:newX+r2,newY:newY+r2,newZ:newZ+r2);
    %                 V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,2)=V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,2).*A(newX:newX+r2,newY:newY+r2,newZ:newZ+r2);
    %                 V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,3)=V(newX:newX+r2,newY:newY+r2,newZ:newZ+r2,3).*A(newX:newX+r2,newY:newY+r2,newZ:newZ+r2);
    % 
    %                 
                    lastX=newX;
                    lastY=newY;
                    lastZ=newZ;      

                end

            end
        end
        
    end
end



    function VG=GaussBall3D(diam,sigma)
        
        
       x=-floor(diam/2):floor(diam/2);
       y=-floor(diam/2):floor(diam/2);
       z=-floor(diam/2):floor(diam/2);
        
       [XP,YP,ZP]=meshgrid(x,y,z);
       F=mvnpdf([XP(:) YP(:) ZP(:) ],[],[sigma sigma sigma]);
       VG=reshape(F,diam,diam,diam);
        
        
    end



end



    
% 
% %volumetric testing
% 
%     %Add paths
% %     functionname='render.m';
% %     functiondir=which(functionname);
% %     functiondir=functiondir(1:end-length(functionname));
% %     addpath(functiondir); 
% %     addpath([functiondir '/SubFunctions']);
% 
% clear options;
%     % Load data
%     load('ExampleData/TestVolume.mat'); V=data.volumes(1).volume_original;
%     % Type of rendering
%     options.RenderType = 'shaded';
%     % color and alpha table
%     options.AlphaTable=[0 0 0 0 0 1 1 1 1 1];
%     
%     %options.AlphaTable=[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
%     
%     options.ColorTable=[1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0;1 0 0]; 
%     % Viewer Matrix
%     options.Mview=makeViewMatrix([0 0 0],[0.25 0.25 0.25],[0 0 0]);
%     % Render and show image
%     figure,
%     I = render(V,options);
%     imshow(I);