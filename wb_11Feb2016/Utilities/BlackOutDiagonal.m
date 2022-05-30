function BlackOutDiagonal(numRows,colr)

if nargin<2
    colr='k';
end

for i=1:numRows
    rectangle('Position',[i-.5,i-.5,1,1],'FaceColor',colr,'EdgeColor','none');
end
    
end