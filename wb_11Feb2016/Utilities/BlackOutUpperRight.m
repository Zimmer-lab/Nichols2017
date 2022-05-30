function BlackOutUpperRight(numRows,width,colr)

if nargin<3
    colr='k';
end

for i=1:numRows
    rectangle('Position',[i-.5,i-.5,width-i+1.5,1],'FaceColor',colr,'EdgeColor','none');
end
    
end