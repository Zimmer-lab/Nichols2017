function img=MexiHat2D(im_width,hat_width)
%img=MexiHat2D(im_width,hat_width)
%make image of radial mexihat
%
%Saul Kato
%

hat_width=hat_width/2;

    img=zeros(im_width,im_width);
    
    for i=1:im_width
        for j=1:i
            
            r=sqrt((i-im_width/2-1/2)^2+(j-im_width/2-1/2)^2);
            
            val=2/sqrt(3)/sqrt(hat_width)/sqrt(sqrt(pi))*(1-r^2/hat_width^2)*exp(-r^2/2/hat_width^2);
     
            
            img(i,j)=val;          
            img(j,i)=val;
        end
    end
    
    
    img=img/max(img(:));  %could remove max for performance
    
    
end