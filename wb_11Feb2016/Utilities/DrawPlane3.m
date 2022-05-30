function handle=DrawPlane3(normVec,point,xLim,yLim,zOffset,colr)

if nargin<1
    normalVec=[1 1 1];
end

if nargin<2
    point=[0 0 0];
end

if nargin<3 || isempty(xLim)
    xLim=[-.1 .1];
end

if nargin<4  || isempty(yLim)
    yLim=[-.1 .1];
end

if nargin<5 || isempty(zOffset)
    zOffset=0;  %offset of the plane in _unrotated_ space
end

if nargin<6
    colr=[0.3 0 0];
end

normVec=(normVec(:))';  %force normVec into row vector


origNorm=[0 0 1];
origX=[xLim(1) xLim(1) xLim(2) xLim(2)];
origY=[yLim(1) yLim(2) yLim(2) yLim(1)];
origZ=[zOffset zOffset zOffset zOffset];

costheta = dot(normVec,origNorm)/(norm(origNorm)*norm(normVec));

rotAxis = cross(normVec,origNorm);

if norm(rotAxis)>0
    
    rotAxis = rotAxis/norm(rotAxis);

    c=costheta;
    s=-sqrt((1-costheta*costheta));
    
    C=1-costheta;
    x=rotAxis(1);
    y=rotAxis(2);
    z=rotAxis(3);

    rmat = [[ x*x*C+c    x*y*C-z*s  x*z*C+y*s ];
            [ y*x*C+z*s  y*y*C+c    y*z*C-x*s ];
            [ z*x*C-y*s  z*y*C+x*s  z*z*C+c   ]];

else
    rmat=diag([1 1 1]);
end
    
for i=1:4 
    nuPoint=rmat*([origX(i) origY(i) origZ(i)])';
    X(i)=nuPoint(1)+point(1);
    Y(i)=nuPoint(2)+point(2);
    Z(i)=nuPoint(3)+point(3);
end          

handle=fill3(X,Y,Z,colr,'FaceAlpha',0.3);

% %Find all coefficients of plane equation    
% A = normVec(1); B = normVec(2); C = normVec(3);
% D = -dot(normVec,point);
% %Decide on a suitable showing range
% [X,Z] = meshgrid(xLim,yLim);
% Y = (A * X + C * Z + D)/ (-B);
% reOrder = [1 2  4 3];
% handle=patch(X(reOrder),Y(reOrder),Z(reOrder),colr);
% alpha(0.3);

