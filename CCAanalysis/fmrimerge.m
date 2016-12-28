function [TimeCourse,listing]=fmrimerge(directory)

listing=dir(directory);
k=strfind(directory,'/');
k1=strfind(directory,'\');
k=sort([k,k1],'ascend');
path=directory(1:k(end));
T = numel(listing);

nii=load_untouch_nii([path,listing(1).name]);
sz=size(nii.img);
TimeCourse=zeros([T,sz]);
TimeCourse(1,:,:,:)=nii.img;
for ti=1:T
%     if rem(ti,100)==0
%         disp(ti);
%     end
    nii=load_untouch_nii([path,listing(ti).name]);
    TimeCourse(ti,:,:,:)=nii.img;
end 
end