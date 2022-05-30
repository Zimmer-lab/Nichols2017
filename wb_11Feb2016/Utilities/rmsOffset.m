function rms_offset=rmsOffset(traces,offsetSize,relFlag)
%rms_offset=rmsOffset(traces)
%compute estimate of power using offset method to denoise
%
%traces is a matrix of timeseries column vectors

if nargin<3
    relFlag=false;
end

    T=size(traces,1);
    n=size(traces,2);
    
    traces_shifted=zeros(T,1);
    rms_offset=zeros(1,n);


    for i=1:n
        
        %created shifted version
        traces_shifted=[traces(2:end,i); traces(end,i)];
        rms_offset(i)=sqrt( dot(traces_shifted,traces) / T );  
        
        if relFlag %relative computation
            rms_no_offset(i)=sqrt( dot(traces,traces) / T );  
            rms_offset(i)=rms_offset(i)-rms_no_offset(i); 
        end
    end
    
end