function [Sxx, Sxy, Syx, Syy]=corrMICnoParfor(X,Y)
% [Sxx, Sxy, Syx, Syy]=corrMIC(X,Y)
% notice: make sure there is no single column which are constant, or
% when apply java, it would be removed automatically, which results to some
% error.
str = which('corrMIC');
emiCCApath = str(1:end-9);
n_x = size(X,2);
n_y = size(Y,2);
X=whiten(X);
Y=whiten(Y);
temp = [1:(n_x+n_y); [X Y]]';

str = tempname;
objname = [str,'.csv'];% to avoid the file deleted incorrectly when using parfor
dataname = objname;%[pwd,'\',objname];
csvwrite(objname,temp);

MIC = zeros(n_x+n_y);
P_value = zeros(n_x+n_y);
command =['java -jar ',[emiCCApath,'MINE.jar '],dataname,' -allPairs cv=0 exp=0.55 c=5 gc = 100'];
system(command);
filename = strcat(objname,',allpairs,cv=0.0,B=n^0.55,Results.csv');
status = strcat(objname,',allpairs,cv=0.0,B=n^0.55,Status.txt');

fid = fopen(filename);
a1 = textscan(fid,'%s');
results = zeros(size(a1{1,1},1),8);

for i1 = 11:size(a1{1,1},1)
    results(i1-10,:)=str2num(a1{1,1}{i1,1});
    MIC(results(i1-10,1),results(i1-10,2)) = results(i1-10,3);
end

MIC = MIC + eye(size(MIC)) + MIC';
fclose('all');
delete(filename,status);

Sxx = MIC(1:n_x,1:n_x);
Sxy = MIC(1:n_x,n_x+1:n_x+n_y);
Syy = MIC(n_x+1:n_x+n_y,n_x+1:n_x+n_y);
delete(objname);   
Sxx(isnan(Sxx))=0;
Sxy(isnan(Sxy))=0;
Syy(isnan(Syy))=0;
Syx = Sxy';
if rank(Sxx)<size(Sxx,1)
    Sxx=Sxx+(1e-10)*eye(size(Sxx,1));
end

if rank(Syy)<size(Syy,1)
    Syy=Syy+(1e-10)*eye(size(Syy,1));
end  
end