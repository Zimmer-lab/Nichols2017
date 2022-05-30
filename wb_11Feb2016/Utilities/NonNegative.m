function traces_out=NonNegative(traces)

traces_out=zeros(size(traces));

for i=1:size(traces,2)
    traces_out(:,i)=traces(:,i)-min(traces(:,i));
end

end