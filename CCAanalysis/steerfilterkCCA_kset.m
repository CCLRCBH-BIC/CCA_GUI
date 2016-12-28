function rho=steerfilterkCCA_kset(sttimecourse_dir,mask_dir,X,datamode)
% datamode 1:create file 2: load saved file directly
% X should not be standarized or demeaned
% how to apply contrast to data is still an issue
% the contrast for Xeff is added 
try
    mask_nii=load_untouch_nii(mask_dir);
    mask=mask_nii.img;
    mask=(mask>0.15*max(mask(:)));
catch
    mask=mask_dir;
end
sz=size(mask);
[N,Nreg]=size(X);
X=whiten(X);
ker = kernel(X,1,'linear',0,0);
ker = ker/mean(diag(ker));
mean_ker_row = mean(ker,2);
mean_ker_col = mean(ker,1);
Ky = ker - diag(mean_ker_row)*ones(N) - ones(N)*diag(mean_ker_col) + mean(mean_ker_row);   

if datamode==1
    data=[];
    label=[];
    for i=1:sz(3)
        load([sttimecourse_dir,'\stSmoothSlice',num2str(i),'.mat']);
        filter_tc=reshape(filter_tc,N,[],7);
        temp_mask=mask(:,:,i);
        label=[label;i*ones(7*sum(temp_mask(:)),1)];
        filter_tc=filter_tc(:,temp_mask(:)==1,:);
        data=[data,reshape(filter_tc,N,[])];
    end
%     save([sttimecourse_dir,'\masksteerfiltertc.mat'], 'data', 'label', 'mask','-v7.3');
elseif datamode==2
    load([sttimecourse_dir,'\masksteerfiltertc.mat'], 'data', 'label', 'mask'); 
elseif datamode==3
    data=sttimecourse_dir;
end

data=whiten(data);
ker = kernel(data,1,'linear',0,0);
ker = ker/mean(diag(ker));
mean_ker_row = mean(ker,2);
mean_ker_col = mean(ker,1);
Kx = ker - diag(mean_ker_row)*ones(N) - ones(N)*diag(mean_ker_col) + mean(mean_ker_row);     

k_set=0.2:0.02:0.96;
rho=zeros(numel(k_set),1);
for i=1:numel(k_set)
    k=k_set(i);
    [rho(i),alpha,beta] = kernelCCA(Kx,Ky,k);
end
end