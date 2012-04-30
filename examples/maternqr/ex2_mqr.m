% Tests RBF-QR to show that it can avoid the ill-conditioning
% associated with a small shape parameter
rbfsetup
global GAUSSQR_PARAMETERS
GAUSSQR_PARAMETERS.ERROR_STYLE = 4; % Relative RMS
useSplines = GAUSSQR_PARAMETERS.SPLINE_TOOLBOX_AVAILABLE;

% The range of N values to consider
Nvec = [10,20,40];
% The spacing choice for the points
spaceopt = 'cheb';
% The order (smoothness) of the kernel
beta = 1;
% The  range of kernel shape parameters to consider
epvec =  logspace(-1,2,20);
% The length of the domain
L = 1;
% The embedding width for nonhomogeneous functions (must be <.5)
embed_cushion = .1;
% The number of evenly spaced points at which to sample error
NN = 100;

% This is the function we are interested in considering
% Depending on which function consider, it will choose embedding
fopt = 1;
switch fopt
    case 1
        yf = @(x) sin(2*pi*x/L) + 1;
        fstr = 'u(x) = sin(2\pi{x}/L)+1';
        embed = embed_cushion;
    case 2
        yf = @(x) sin(2*pi*x/L);
        fstr = 'u(x) = sin(2\pi{x}/L)';
        embed = 0;
    case 3
        yf = @(x) 30*x.^2.*(L-x).^2.*sin(2*pi*x/L).^4;
        fstr = 'u(x) = 30x^2(L-x)^2sin(2\pi{x}/L)^4';
        embed = 0;
    case 4
        yf = @(x) 1./(1+(x/L).^2);
        fstr = 'u(x) = 1/(1+(x/L)^2)';
        embed = embed_cushion;
    case 5
        yf = @(x) 1./(1+(x/L).^2)-(1-.5*(x/L));
        fstr = 'u(x) = 1/(1+(x/L)^2)+.5(x/L)-1';
        embed = 0;
    case 6
        yf = @(x) sinh(3/L*x)./(1+cosh(3/L*x));
        fstr = 'u(x) = sinh(3x/L)./(1+cosh(3x/L))';
        embed = embed_cushion;
    case 7
        fstr = 'y(x)=cos(x)+e^{-(x-1)^2}-e^{-(x+1)^2}';
        yf = @(x) cos(x)+exp(-(x-1).^2)-exp(-(x+1).^2);
        embed = embed_cushion;
    otherwise
        error('This function does not exist')
end

% Selecting some points in the domain, not including the boundary
aa = embed*L; bb = (1-embed)*L;
xx = pickpoints(aa,bb,NN);
yy = yf(xx);

% Set up the error vectors to store the results
errvec = zeros(length(Nvec),length(epvec));
errvecd = zeros(length(Nvec),length(epvec));
if useSplines
    errvecs = zeros(length(Nvec),1);
end

% Don't care about warnings, yet
warning off

i = 1;
for N=Nvec
    K_solve = zeros(N);
    K_eval = zeros(NN,N);
    
    if embed==0
    % Don't consider the homogeneous end points because they are fixed
        [x,spacestr] = pickpoints(aa,bb,N+2,spaceopt);
        x = x(2:end-1);
    else
        [x,spacestr] = pickpoints(aa,bb,N,spaceopt);
    end
    y = yf(x);
    
    k = 1;
    for ep=epvec
        MQR = mqr_solve(x,y,L,ep,beta);
        yp = mqr_eval(MQR,xx);
        errvec(i,k) = errcompute(yp,yy);
        
        for j=1:N
            K_solve(:,j) = cmatern(x,x(j),L,ep,beta);
            K_eval(:,j) = cmatern(xx,x(j),L,ep,beta);
        end
        b = K_solve\y;
        yp = K_eval*b;
        errvecd(i,k) = errcompute(yp,yy);
        k = k+1;
    end
        
    if useSplines
        sp = spapi(beta+1,x,y);
        yp = fnval(sp,xx);
        errvecs(i) = errcompute(yp,yy);
    end
    
    i = i+1;
end

warning off

loglog(epvec,errvecd(1,:),'-bx')
hold on
loglog(epvec,errvecd(2,:),'-g+')
loglog(epvec,errvecd(3,:),'-r^')
loglog(epvec,errvec(1,:),'b','LineWidth',3)
loglog(epvec,errvec(2,:),'g','LineWidth',3)
loglog(epvec,errvec(3,:),'r','LineWidth',3)
if useSplines
    loglog(epvec,errvecs(1)*ones(size(epvec)),'--b','LineWidth',2)
    loglog(epvec,errvecs(2)*ones(size(epvec)),'--g','LineWidth',2)
    loglog(epvec,errvecs(3)*ones(size(epvec)),'--r','LineWidth',2)
end
hold off
xlabel('\epsilon')
ylabel('average error')
ptsstr=strcat(', x\in[',num2str(aa),',',num2str(bb),'],');
title(strcat(fstr,ptsstr,spacestr))
legend('N=10 (Direct)','N=20 (Direct)','N=40 (Direct)','N=10 (QR)','N=20 (QR)','N=40 (QR)', 'Location', 'NorthWest');
