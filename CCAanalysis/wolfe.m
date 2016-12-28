function [alphas,success] = wolfe(f,d,X0,flag)

if exist('flag','var')==0
    flag = 'weak';
end

if strcmpi(flag,'strong')==1
    RHO = 0.01;   % a bunch of constants for line searches
    SIG = 0.5;    % RHO and SIG are the constants in the Wolfe conditions
    INT = 0.1;% don't reevaluate within 0.1 of the limit of the current bracket
    EXT = 3.0;    % extrapolate maximum 3 times the current bracket
    Niter = 20;
    k = 0;
    red = 1;alpham = 2;
    fun = @(alpha) f(X0+alpha*d);
    f1 = fun(0);
    d1 = Grad(@(alp) fun(alp),0);           % this is the slope alpham;%
    z1 = red/(1-d1); %alpham                    % initial step is red/(|s|+1)

    f2 = fun(z1);d2 = Grad(@(alp) fun(alp),z1);
    f3 = f1; d3 = d1; z3 = -z1;
    limit=-1;success = 0;
    while k<Niter
        k = k+1;
        while (f2 > f1+z1*RHO*d1) | (d2 > -SIG*d1)
            limit = z1;                                % tighten the bracket
            if f2 > f1
                z2 = z3 - (0.5*d3*z3*z3)/(d3*z3+f2-f3);        % quadratic fit
            else
                A = 6*(f2-f3)/z3+3*(d2+d3);                        % cubic fit
                B = 3*(f3-f2)-z3*(d3+2*d2);
                z2 = (sqrt(B*B-A*d2*z3*z3)-B)/A;
            end
            if isnan(z2) | isinf(z2)
                z2 = z3/2;           % if we had a numerical problem then bisect
            end
            z2 = max(min(z2, INT*z3),(1-INT)*z3);%don't accept too close to limit
            z1 = z1 + z2;                                % update the step

            f2 = fun(z1);d2 = Grad(@(alp) fun(alp),z1);
            z3 = z3-z2;              % z3 is now relative to the location of z2
        end
        if d2 > SIG*d1
            success = 1;break;
        end
        A = 6*(f2-f3)/z3+3*(d2+d3);         % make cubic extrapolation
        B = 3*(f3-f2)-z3*(d3+2*d2);
        z2 = -d2*z3*z3/(B+sqrt(B*B-A*d2*z3*z3));
        if ~isreal(z2) | isnan(z2) | isinf(z2) | z2 < 0%num prob or wrong sign?
            if limit < -0.5                         % if we have no upper limit
                z2 = z1 * (EXT-1);          % the extrapolate the maximum amount
            else
                z2 = (limit-z1)/2;
            end
        elseif (limit > -0.5) & (z2+z1 > limit) % extraplation beyond max?
            z2 = (limit-z1)/2;
        elseif (limit < -0.5) & (z2+z1 > z1*EXT)% extrapolation beyond limit
            z2 = z1*(EXT-1.0);                    % set to extrapolation limit
        elseif z2 < -z3*INT
            z2 = -z3*INT;
        elseif (limit > -0.5) & (z2 < (limit-z1)*(1.0-INT))%too close to limit?
            z2 = (limit-z1)*(1.0-INT);
        end
        f3 = f2; d3 = d2; z3 = -z2;
        z1 = z1 + z2;
        f2 = fun(z1);d2 = Grad(@(alp) fun(alp),z1);
    end

    if success == 0
        % Backtracking line search
        rho = 0.5;
        cval = 0.1;    
        z1 = 1;
        fxk = f(X0); gk = Grad(f,X0);
        while 1
            xk1 = X0+z1*d;
            fxk1 = f(xk1);
            if fxk1 <= fxk+cval*z1*gk'*d;
                break;
            else
                z1 = rho*z1;
            end
        end  
    end
elseif strcmpi(flag,'weak')==1
    % Backtracking line search
    rho = 0.5;
    cval = 0.1;    
    z1 = 1;
    fxk = f(X0); gk = Grad(f,X0);
    while 1
        xk1 = X0+z1*d;
        fxk1 = f(xk1);
        if fxk1 <= fxk+cval*z1*gk'*d;
            break;
        else
            z1 = rho*z1;
        end
    end  
end
alphas = z1;
end