function [Sxx, Sxy, Syx, Syy]=corrDcor(X,Y,flag,outputMode)
% Verified: [Sxx, Sxy, Syx, Syy]=corrDcor(X,Y,flag,outputMode)
% outputMode = 'full','singleX','XY'
% [N,n_x] = size(X);
% 
% XY = whiten([X,Y]);
% S1 = XY'*XY/(N-1);
% S1(isnan(S1))=0;
% S = real(S1.*asin(S1)+sqrt(1-S1.^2)-S1.*asin(S1/2)-sqrt(4-S1.^2)+1);
% S = S/(1+pi/3-sqrt(3)); S = sqrt(S).*sign(S1);
% 
% Sxx = S(1:n_x,1:n_x);
% Sxy = S(1:n_x,n_x+1:end);
% Syy = S(n_x+1:end,n_x+1:end);
% Syx = Sxy';
% if rank(Sxx)<size(Sxx,1)
%     Sxx=Sxx+(1e-10)*eye(size(Sxx,1));
% end
% 
% if rank(Syy)<size(Syy,1)
%     Syy=Syy+(1e-10)*eye(size(Syy,1));
% end  

if nargin==2
    flag = 'dcor';
    outputMode = 'full';
elseif nargin == 3
    outputMode = 'full';
end

disp(' distance correlation starts to run');
[N,n_x] = size(X);
n_y = size(Y,2);


if strcmpi(flag,'dcor')==1
    Xx = [X,Y];%whiten([X,Y]); Whitened or not, the result would be the same
elseif strcmpi(flag,'ranked dcor')==1
    Xx = rankVec([X,Y]);
end

A_X = zeros(N^2,n_x+n_y);
nor_X = zeros(n_x+n_y,1); 
parfor i =1:n_x+n_y
    A_X(:,i) = distanceMatrix1D(Xx(:,i));
    nor_X(i) = A_X(:,i)'*A_X(:,i);
end
nor_X = sqrt(nor_X);
% A_X = reshape(A_X,n_x+n_y,[]);

disp('distance matrix has been constructed');  
dcor = zeros((n_x+n_y)^2,1);

shmkey = sprintf('shmA_X_%04d_X',randi(9999,1,1));
shmA_X = shmobject(shmkey,A_X);
clear A_X;

parfor k =1:(n_x+n_y)^2
%     disp(k);
    robj = shmref(shmkey);

    i = ceil(k/(n_x+n_y));
    j = k-(i-1)*(n_x+n_y);
    % case 1 single X
    if strcmpi(outputMode,'singleX') == 1
        if i >n_x || j>n_x
            continue;
        end
    end
    % case 2 X Y interaction term
    if strcmpi(outputMode,'XY') == 1
        if i>n_x || j<=n_x
            continue;
        end
    end
    
    if j<=i
        continue;
    else
        dcor(k) = robj.data(:,i)'*robj.data(:,j)/(nor_X(i)*nor_X(j));
%         dcor(k) = robj.data(:,i)*robj.data(:,j)'/sqrt((robj.data(i,:)*robj.data(i,:)')*...
%             (robj.data(j,:)*robj.data(j,:)'));
%         dcor(k) = A_X(i,:)*A_X(j,:)'/sqrt((A_X(i,:)*A_X(i,:)')*...
%             (A_X(j,:)*A_X(j,:)'));
    end
    delete(robj);
end
delete(shmA_X);

dcor = reshape(dcor,n_x+n_y,n_x+n_y);
dcor = dcor.^(1/2);

disp('distance correlation matrix is constructed');

uni = (range([X,Y])==0);
dcor = dcor + dcor'+diag(ones(n_x+n_y,1));
dcor(uni,:)=0;
dcor(:,uni)=0;
Sxx = dcor(1:n_x,1:n_x);
Sxy = dcor(1:n_x,n_x+1:n_x+n_y);
Syx = Sxy';
Syy = dcor(n_x+1:n_x+n_y,n_x+1:n_x+n_y);

if rank(Sxx)<size(Sxx,1)
    Sxx=Sxx+(1e-10)*eye(size(Sxx,1));
end

if rank(Syy)<size(Syy,1)
    Syy=Syy+(1e-10)*eye(size(Syy,1));
end  
[~,sys] = memory;
fprintf(1,'Physical Memory Available: %d\n', sys.PhysicalMemory.Available);

end


