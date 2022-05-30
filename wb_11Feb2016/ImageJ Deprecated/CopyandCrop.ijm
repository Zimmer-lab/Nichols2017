macro "Der Copy And Crop Action Tool - B30C00fT0f20C" { 

print("\\Clear");  // clear log window
print("Running Crop and Copy.");

//run("Red Hot");

dir = getDirectory("Choose a Directory to Analyze");
print(dir);
list = getFileList(dir);

//get crop coords
if (File.exists(dir+"Overviews/globalCoords.txt"))
{
      print(">[2/5] found globalCoords.txt. Loading cropping and orientation information.");
	  filestring=File.openAsString(dir+"Overviews/globalCoords.txt"); 
	  vals=split(filestring); 
      x=parseInt(vals[0]);
	  y=parseInt(vals[1]);
      w=parseInt(vals[2]);
	  h=parseInt(vals[3]);
	  AVQuadrant=parseInt(vals[4]);
      print("Read selection bounds: "+x+" "+y+" "+w+" "+h+", Anterio-ventral Quadrant="+AVQuadrant);
}


//exclude non .tif files
k=0;
newlist = newArray(list.length);
for (i=0; i < list.length; i++)  {
	if (endsWith(list[i], ".tif")) {
	newlist[k] = list[i];
	k=k+1;
	}
}
dirOriginals=dir;

list = Array.trim(newlist, k);
if (list.length==0) {
    print(">No .tifs found in this directory. Checking for Originals subfolder.");
    list = getFileList(dir+"/Originals");
    dirOriginals=dir+"/Originals";
    //exclude non .tif files
    k=0;
    newlist = newArray(list.length);
    for (i=0; i < list.length; i++)  {
	  if (endsWith(list[i], ".tif")) {
 	  newlist[k] = list[i];
 	  k=k+1;
 	  }
    }  
    if (list.length==0)  {
      print("Quitting.");
      exit;
    }
    list = Array.trim(newlist, k);
}


//find highest Z slice and T index and check for correct number of files
Zmax=0;
Tmax=0;
Znum=newArray(list.length);
Tnum=newArray(list.length);


for (i=0; i < list.length; i++)  {
	//print(list[i]);
	//find the next non-numerical character after Z. indexOf does not support wildcards/regular expressions.  in future use matches().
	letterZpos=indexOf(list[i],"Z");
	letterTpos=indexOf(list[i],"T",letterZpos);
	if (letterTpos==-1) letterTpos=list.length;	
	letterCpos=indexOf(list[i],"C",letterZpos);
	if (letterCpos==-1) letterCpos=list.length;	
	letter_pos=indexOf(list[i],"_",letterZpos);
	if (letter_pos==-1) letter_pos=list.length;
	letterDotTifpos=indexOf(list[i],".tif",letterZpos);
	endZnumpos=minOf(letterTpos,minOf(letterCpos,minOf(letter_pos,letterDotTifpos)));
	Znum[i]=substring(list[i],letterZpos+1,endZnumpos);
	if (parseInt(Znum[i])>parseInt(Zmax)) {
		Zmax=Znum[i];
	}
	//find the next non-numerical character after T. indexOf does not support wildcards/regular expressions.  in future use matches().
	letterTpos=indexOf(list[i],"T");	
	letterCpos=indexOf(list[i],"C",letterTpos);
	if (letterCpos==-1) letterCpos=list.length;		
	letterZpos=indexOf(list[i],"Z",letterTpos);
	if (letterZpos==-1) letterZpos=list.length;			
	letter_pos=indexOf(list[i],"_",letterTpos);
	if (letter_pos==-1) letter_pos=list.length;			
	letterDotpos=indexOf(list[i],".",letterTpos);	
	endTnumpos=minOf(letterCpos,minOf(letterZpos,minOf(letter_pos,letterDotpos)));
	Tnum[i]=substring(list[i],letterTpos+1,endTnumpos);
	if (parseInt(Tnum[i])>parseInt(Tmax)) {
		Tmax=Tnum[i];
	}	
}
Tnumcharlength=endTnumpos-letterTpos;
Zmax=parseInt(Zmax);
Tmax=parseInt(Tmax);
print(">Max Z-slice found is "+Zmax+".");
print(">Max T-frame found is "+Tmax+".");
tifnumChecksum=Zmax*Tmax;

if (tifnumChecksum==list.length)
	print(">Total # of .tifs ("+list.length+") is consistent.");
else
{
	print(">Total # of .tifs ("+list.length+") is inconsistent. A future version of this software might deal with this. Quitting.");
	exit;
}







print(">[2/6] Copying cropped and rotated .tifs into Z-slice folders.  This will almost double the size of the dataset, for now.");

//make folders
//pad the folder name with zeros
maxZchars=lengthOf(toString(Zmax));
destDir=newArray(Zmax);
paddedZ=newArray(Zmax);
for (z=0; z<Zmax; z++) {
	padding="000";  //assumes that there are no more than 999 Z planes, easy to fix
	paddedZ[z]=padding+toString(z+1);
	paddedZ[z]=substring(paddedZ[z],lengthOf(paddedZ[z])-maxZchars,lengthOf(paddedZ[z]));
	destDir[z]=dir+"Z"+paddedZ[z];
	File.makeDirectory(destDir[z]); 
}

//copy files into Z-folders
print(".");
setBatchMode(true);
//for (i=0; i < list.length; i++) File.copy(dir+list[i],destDir[Znum[i]-1]+"/"+list[i]);
for (i=0; i < list.length; i++) {
	open(dirOriginals+"/"+list[i]);
	makeRectangle(x,y,w,h);
	run("Crop");
//	if (rotFlag==1) run("Rotate 90 Degrees Left");
	saveAs("Tiff", destDir[Znum[i]-1]+"/"+list[i]);  //Z folder
	//saveAs("Tiff", destDir[Znum[i]-1]+"/"+list[i]);
	if (i%100==0)  print("\\Update:processing..."+i+"/"+list.length);
	close();
}
setBatchMode(false);
print("\\Update:processed "+list.length+"/"+list.length+".");
