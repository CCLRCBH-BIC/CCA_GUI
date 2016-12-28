function [Cor,Alp,Beta,Statistic,opt_Yind]=ccaMainCube(X,Y,mask,C,flag,mode)
%% [Cor,Alp,Beta,Statistic,opt_Yind]=ccaMain(X,Y,mask,C,flag,mode)
% example:
%   Cor=ccaMain(X,reshape(simu_data,278,32,32),[],[0;-1;1;0],'Pearson','sum');
% Y size: NoofObservation, X, Y, Z
% mask is a binary classification, size: X, Y,Z
% flag: 'pearson','docr','MIC'
% mode: 'simple','sum','dominance','Single voxel',[phi,p]

siz = size(Y);
if isempty(mask)==1
    mask = ones(siz(2:end));
end
if isempty(flag)
    flag='Pearson';
end
if isempty(C)
    C=zeros(size(X,2),1);C(1)=1;
end

if numel(siz)<3
    error('ccaMain: at least one slice should be considered');
elseif numel(siz)==3
    siz = [siz,1];
    Y = reshape(Y,siz); mask = reshape(mask,siz(2:end));
end
N_X = size(X,2);
N_voxperslice = siz(2)*siz(3);

NoofSlice = siz(end);
Cor = zeros(siz(2)*siz(3),NoofSlice);
Statistic = cell(siz(2)*siz(3),NoofSlice);
Alp = cell(siz(2)*siz(3),NoofSlice);
Beta = cell(siz(2)*siz(3),NoofSlice);
opt_Yind = cell(siz(2)*siz(3),NoofSlice);

n=1;
for i = 2:NoofSlice-1
    temp_Y = reshape(Y(:,:,:,i-1:i+1),siz(1),[]);
    temp_mask = squeeze(mask(:,:,i-1:i+1));temp_mask = temp_mask(:);
    shmkey_Y = [flag,'GMshmkey_Y'];   
    shmobj_Y = shmobject(shmkey_Y,temp_Y);  
    disp(['slice ',num2str(i),': CCA is running.']);
    parfor q = 1:N_voxperslice %% can be parfor
%         disp(q);
        robj_Y = shmref(shmkey_Y);  
        [x_ind,y_ind] = ind2sub(siz(2:3),q);
        if temp_mask(q) == 0 || min(y_ind,x_ind)<=n || x_ind>siz(2)-n || y_ind>siz(3)-n
        else
            [ix,iy,iz]=meshgrid(x_ind-n:x_ind+n,y_ind-n:y_ind+n,1:3);
            neigh = sub2ind([siz(2:3),3],ix,iy,iz);neigh=neigh([14,1:13,15:27]);
            neigh = neigh(temp_mask(neigh)==1);  
            [Sxx,Sxy,Syx,Syy] = corrCombo(X,robj_Y.data(:,neigh),flag);
            if Syy(1,1)~=0
                S = struct('Sxx',Sxx,'Sxy',Sxy,'Syx',Syx,'Syy',Syy);
                [cor,alp,beta,statistic,opt_yind]=ccaCombo(X,robj_Y.data(:,neigh),C,S,flag,mode);
                Cor(q,i)=cor;Alp{q,i}=alp;Beta{q,i}=beta;Statistic{q,i}=statistic;opt_Yind{q,i}=opt_yind;
            end
        end
        delete(robj_Y);
    end
end

end
    
