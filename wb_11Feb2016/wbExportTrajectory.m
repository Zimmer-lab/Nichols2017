
options.smoothingWindow=3;
options.scaleFactor=1000;

pc=wbLoadPCA;

xyz= fastsmooth(pc.pcs(:,1:3),options.smoothingWindow,3,1);


for i=1:3
    xyz(:,i)=options.scaleFactor*xyz(:,i)/(max(xyz(:,i))-min(xyz(:,i)));
end

%swap y and z
xyz=[xyz(:,1) , xyz(:,3), xyz(:,2)];

fxyz=[(1:size(xyz,1))' , xyz     ];

dlmwrite('traj3d.txt',fxyz,'delimiter',',','precision','%.6f');