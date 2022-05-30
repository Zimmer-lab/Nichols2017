function [xOut,yOut]=Stepify(x,y)
%convert a plot into a stairstepped version
%good for making outlined bar plots 
%
        
        %triplicate y with zero edges
        y=repmat(y,3,1);
        y=y(:)';
        yOut=[0 , y , 0];
        
        %triplicate shift x
        delta=(x(2)-x(1))/2;
        x=repmat(x,3,1);
        x(1,:)=x(1,:)-delta;
        x(3,:)=x(3,:)+delta;
        
        x=x(:)';
        xOut=[x(1)-delta , x , x(end)+delta];
        
end