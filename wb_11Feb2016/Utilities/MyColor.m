function colortriple=MyColor(colornamestring,colorrange,mycolormap)
% colortriple=MyColor(colornamestring,colorrange)
%
%RGB values for commonly used colors
%or a value from a colormap range

colortriple=[0 0 0];

if nargin==1
    
    if strcmp(colornamestring,'lb') || strcmp(colornamestring,'lightblue')
        colortriple=[0.7 0.7 1];
    elseif strcmp(colornamestring,'llb') || strcmp(colornamestring,'lightlightblue')
        colortriple=[0.9 0.9 1];
    elseif strcmp(colornamestring,'mlb') || strcmp(colornamestring,'mediumlightblue')
        colortriple=[0.5 0.5 1];
    elseif strcmp(colornamestring,'lr') || strcmp(colornamestring,'lightred')
        colortriple=[1 0.7 0.7];
    elseif strcmp(colornamestring,'lg') || strcmp(colornamestring,'lightgreen')
        colortriple=[0.7 1 0.7];
    elseif strcmp(colornamestring,'ly') || strcmp(colornamestring,'lightyellow')
        colortriple=[0.7 0.7 0.3];        
        
    elseif strcmp(colornamestring,'dg') || strcmp(colornamestring,'darkgreen')
        colortriple=[0 0.7 0];
    elseif strcmp(colornamestring,'dr') || strcmp(colornamestring,'darkred')
        colortriple=[0.7 0 0];
        
    elseif strcmp(colornamestring,'p') || strcmp(colornamestring,'pink')
        colortriple=[199 93 121]/255;      
        
    elseif strcmp(colornamestring,'gray') || strcmp(colornamestring,'grey')
        colortriple=[0.5 0.5 0.5];
    elseif strcmp(colornamestring,'darkgray') || strcmp(colornamestring,'darkgrey')
        colortriple=[0.3 0.3 0.3];
    elseif strcmp(colornamestring,'lightgray') || strcmp(colornamestring,'lightgrey')
        colortriple=[0.8 0.8 0.8];
    elseif strcmp(colornamestring,'r') || strcmp(colornamestring,'red')
        colortriple=[1 0 0];
    elseif strcmp(colornamestring,'g') || strcmp(colornamestring,'green')
        colortriple=[0 1 0];
    elseif strcmp(colornamestring,'k') || strcmp(colornamestring,'black')
        colortriple=[0 0 0];
    elseif strcmp(colornamestring,'w') || strcmp(colornamestring,'white')
        colortriple=[1 1 1];
    elseif strcmp(colornamestring,'b') || strcmp(colornamestring,'blue')
        colortriple=[0 0 1];
    elseif strcmp(colornamestring,'y') || strcmp(colornamestring,'yellow')
        colortriple=[1 1 0];    
    elseif strcmp(colornamestring,'c') || strcmp(colornamestring,'cyan')
        colortriple=[0 1 1];
        
    else
        disp('color> color string not recognized. using black.');
    end
    
elseif nargin==2
    
    %colormap('jet')
    cmap=jet(colorrange); 
    if colorrange==3  %overrwite bad n=3 color mapping for jet
        cmap(3,:)=[1 0 0];
    elseif colorrange==1
        cmap(1,:)=[1 0 0];
    end
    colortriple=cmap(colornamestring,:);
    
elseif nargin==3  %'rg'
        cmap=[(1:(-1/(colorrange-1)):0)', (0:(1/(colorrange-1)):1)', zeros(colorrange,1)];
        colortriple=cmap(colornamestring,:);
else
    colortriple=[0.5 0.5 0.5];
end