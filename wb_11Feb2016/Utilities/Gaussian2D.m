function g=Gaussian2D(im_width, sigma)

g=zeros(im_width); %2D filter matrix

%gaussian filter

for i=-(im_width-1)/2:(im_width-1)/2
    for j=-(im_width-1)/2:(im_width-1)/2
        x0=(im_width+1)/2; %center
        y0=(im_width+1)/2; %center
        x=i+x0; %row
        y=j+y0; %col
        g(y,x)=exp(-((x-x0)^2+(y-y0)^2)/2/sigma/sigma);
    end
end

g=g/sum(g(:));

end

