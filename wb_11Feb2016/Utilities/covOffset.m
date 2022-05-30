function mat=covOffset(traces,numOffsetSteps)
%function  mat=covOffset(traces)
%
%
if nargin<2
    numOffsetSteps=1;
end
    
if size(traces,2)<1
    disp('need at least 2 traces');
    mat=1;
    return;
end

T=size(traces,2);
mat=zeros(size(traces,2));

if numOffsetSteps==1

    traces_advanced=traces(2:end,:);
    traces_short=traces(1:end-1,:);

    for i=1:T
        for j=1:i
            %mat(i,j)=dot(traces(1:end-1,i),traces_advanced(:,j))+dot(traces(1:end-1,j),traces_advanced(:,i)); %slow implementation
            mat(i,j)=sum(traces_short(:,i).*traces_advanced(:,j))+sum(traces_short(:,j).*traces_advanced(:,i));
            mat(j,i)=mat(i,j);
        end
        if mod(i,500)==1
            disp(i)
        end
    end

    mat=mat/2/(T-1);

else
    
    
    traces_shifted=zeros(size(traces,1)-numOffsetSteps,size(traces,2) ,numOffsetSteps+1);
      
    
    for i=1:numOffsetSteps+1
        traces_shifted(:,:,i)=traces(i  :end-numOffsetSteps+i-1,  :);
    end 
    
    for i=1:T
       for j=1:i
           for k=1:(numOffsetSteps)     
                
                mat(i,j)=mat(i,j)+   sum( traces_shifted(:,i,1).*traces_shifted(:,j,k+1) ) +  sum(traces_shifted(:,j,1).*traces_shifted(:,i,k+1));
                mat(j,i)=mat(i,j);
           end
       end
    end
    
    mat=mat/2/(T-1)/k;
    
end