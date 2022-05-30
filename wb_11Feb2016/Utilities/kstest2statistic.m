function ts=kstest2statistic(x1,x2)
%wrapper for kolmogorov-smirnoff test statistic, 2 sample.
%

[~,~,ts]=kstest2(x1,x2,'tail','larger');

end