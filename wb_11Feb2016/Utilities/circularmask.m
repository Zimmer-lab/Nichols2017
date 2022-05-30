function mask=circularmask(radius,masksize)
%Saul Kato
%Make a binary circular mask of given radius into a mask of a given size
%if no masksize is specified,
%resulting image is (2*ceil(radius)+1) by (2*ceil(radius)+1) pixels 
%

if nargin<1
    radius=10;
end

radius_int=ceil(radius);

if nargin<2
    masksize=[2*radius_int+1 2*radius_int+1];
end

if numel(masksize)==1
    masksize=[masksize masksize];
end

mask=zeros(masksize);
center_x=masksize(1)/2+0.5;
center_y=masksize(2)/2+0.5;

for x=1:masksize(1)   
    for y=1:masksize(2)
        
        if (x-center_x)^2+(y-center_y)^2<=radius^2
            mask(x,y)=1;
        end
    end
end


%figure;
%imagesc(mask);