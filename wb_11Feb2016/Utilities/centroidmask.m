function [maskx,masky]=centroidmask(masksize)
%Saul Kato
%Make a double-valued centroid x and y mask of given radius into a mask of a given size
%if no masksize is specified,
%resulting image is (2*ceil(radius)+1) by (2*ceil(radius)+1) pixels 
%


if numel(masksize)==1
    masksize=[masksize masksize];
end

mask=zeros(masksize);


center_x=masksize(1)/2+0.5;  %0.5 is for pixel perfection
center_y=masksize(2)/2+0.5;

for x=1:masksize(1)   
    for y=1:masksize(2)
        
            maskx(x,y)=center_x-x;
            masky(x,y)=center_y-y;
            
    end
end


%figure;
%imagesc(mask);