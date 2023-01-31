function [Cor,Alp,Beta,Statistic,opt_Yind]=ccaMainCube(X,Y,mask,C,flag,mode,nneigh)
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
if exist('nneigh','var')==0 || isempty(nneigh)
    nneigh=1;
end
if numel(siz)<3
    error('ccaMain: at least one slice should be considered');
elseif numel(siz)==3
    siz = [siz,1];
    Y = reshape(Y,siz); mask = reshape(mask,siz(2:end));
end
Cor = zeros(size(mask));
Statistic = cell(size(mask));
Alp = cell(size(mask));
Beta = cell(size(mask));
opt_Yind = cell(size(mask));

fMRIdata = parallel.pool.Constant(Y);
Design = parallel.pool.Constant(X);
voxel_ind = find(mask(:)>0);
voxel_ind = reshape(voxel_ind,1,numel(voxel_ind));
tic
parfor i = voxel_ind
    [ix,iy,iz] = ind2sub(siz(2:end),i);
    temp_mask = zeros(siz(2:end));
    temp_mask(max([ix-nneigh,1]):min([ix+nneigh,siz(2)]),max([iy-nneigh,1]):min([iy+nneigh,siz(3)]),...
        max([iz-nneigh,1]):min([iz+nneigh,siz(4)])) = 1;
    temp_mask(ix,iy,iz) = 0;
    Y = [fMRIdata.Value(:,ix,iy,iz),fMRIdata.Value(:,temp_mask>0)];
    [Sxx,Sxy,Syx,Syy] = corrCombo(Design.Value,Y,flag);
    if Syy(1,1)~=0
        S = struct('Sxx',Sxx,'Sxy',Sxy,'Syx',Syx,'Syy',Syy);
        [cor,alp,beta,statistic,opt_yind]=ccaCombo(X,Y,C,S,flag,mode);
        Cor(i)=cor;Alp{i}=alp;Beta{i}=beta;Statistic{i}=statistic;opt_Yind{i}=opt_yind;
    end
end
toc
end

