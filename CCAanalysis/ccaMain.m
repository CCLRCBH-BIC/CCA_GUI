function [Cor,Alp,Beta,Statistic,opt_Yind]=ccaMain(X,Y,mask,C,flag,mode)
%% [Cor,Alp,Beta,Statistic,opt_Yind]=ccaMain(X,Y,mask,C,flag,mode)
% example:
%   Cor=ccaMain(X,reshape(simu_data,278,32,32),[],[0;-1;1;0],'Pearson','sum');
% Y size: NoofObservation, X, Y, Z
% mask is a binary classification, size: X, Y,Z
% flag: 'pearson','docr','MIC'
% mode: 'simple','sum','dominance','Single voxel',[phi,p]
[~,Nconst]=size(C);
siz = size(Y);
if isempty(mask)==1
    mask = ones(siz(2:end));
end
if isempty(flag)
    flag='Pearson';
end
if isempty(C)
    C=zeros(size(X,2),1);
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
Statistic = zeros([siz(2)*siz(3),NoofSlice,Nconst]);
Alp = cell(siz(2)*siz(3),NoofSlice);
Beta = cell(siz(2)*siz(3),NoofSlice);
opt_Yind = cell(siz(2)*siz(3),NoofSlice);

n=1;
cent=2*n^2+2*n+1;nvox=(2*n+1)^2;
for i = 1:NoofSlice
    disp(['slice ',num2str(i),': calculating correlation matrix.']);
    temp_Y = reshape(Y(:,:,:,i),siz(1),[]);
    temp_mask = squeeze(mask(:,:,i));temp_mask = temp_mask(:);
    [Sxx,Sxy_active,~,Syy_active] = corrCombo(X,temp_Y(:,temp_mask(:)==1),flag);
    Sxy = zeros(N_X,N_voxperslice);
    Syy = zeros(N_voxperslice);
    Sxy(:,temp_mask(:)==1)=Sxy_active;
    Syy(temp_mask(:)==1,temp_mask(:)==1) = Syy_active;
    shmkey_Sxy = [flag,'GMshmkey_Sxy']; shmkey_Syy = [flag,'GMshmkey_Syy']; 
    shmkey_Y = [flag,'GMshmkey_Y'];   
    shmobj_Sxy = shmobject(shmkey_Sxy,Sxy);
    shmobj_Syy = shmobject(shmkey_Syy,Syy);
    shmobj_Y = shmobject(shmkey_Y,temp_Y);  
    disp(['slice ',num2str(i),': CCA is running.']);
    parfor q = 1:N_voxperslice %% can be parfor
        robj_Y = shmref(shmkey_Y);
        robj_Sxy = shmref(shmkey_Sxy);
        robj_Syy = shmref(shmkey_Syy);        
        [x_ind,y_ind] = ind2sub(siz(2:3),q);
        if temp_mask(q) == 0 || min(y_ind,x_ind)<=n || x_ind>siz(2)-n || y_ind>siz(3)-n
        else
%             neigh = neighbor(siz(2:3),[y_ind,x_ind],'index');
%             neigh = neigh(temp_mask(neigh)==1);  
            [ix,iy]=meshgrid(x_ind-n:x_ind+n,y_ind-n:y_ind+n);
            neigh = sub2ind(siz(2:3),ix(:),iy(:));neigh=neigh([cent,1:cent-1,cent+1:nvox]);
            neigh = neigh(temp_mask(neigh)==1);  
            
            S = struct('Sxx',Sxx,'Sxy',robj_Sxy.data(:,neigh),'Syx',robj_Sxy.data(:,neigh)','Syy',robj_Syy.data(neigh,neigh));
            try
                [cor,alp,beta,statistic,opt_yind]=ccaCombo(X,robj_Y.data(:,neigh),C,S,flag,mode);
                Cor(q,i)=cor;Alp{q,i}=alp;Beta{q,i}=beta;Statistic(q,i,:)=statistic;opt_Yind{q,i}=opt_yind;
            catch
                disp('nonbrain region');
            end
        end
        delete(robj_Y);delete(robj_Sxy);delete(robj_Syy);   
    end
end

end
    
