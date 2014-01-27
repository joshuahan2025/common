%[mu, sigma, xi, g] = fitGaussianModeToCDF(samples, varargin) fits a Gaussian to the lower half of the first mode of the sample distribution
% The fit is performed on the PDF of the samples, calculated using kernel density.
%
% Inputs:
%         samples : data points
%
% Outputs:
%              mu : mean of the Gaussian
%           sigma : standard deviation of the Gaussian
%              xi : sample space vector
%               g : Gaussian calculated on xi

% Francois Aguet, 05/24/2012

function [mu, sigma, xi, g] = fitGaussianModeToPDF(samples, varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addParamValue('Display', false, @islogical);
ip.parse(varargin{:});

opts = optimset('Jacobian', 'off', ...
    'MaxFunEvals', 1e4, ...
    'MaxIter', 1e4, ...
    'Display', 'off', ...
    'TolX', 1e-8, ...
    'Tolfun', 1e-8);

pct = prctile(samples, [0 99.9]);
xi = linspace(pct(1), pct(2), 1000);
[pdf,xi] = ksdensity(samples,xi);


A0 = 0.5;
%HE - This seems to give more reliable initialization.
[mu0,sigma0] = robustMean(samples(:),1,2);

p = lsqnonlin(@cost, [A0 mu0 sigma0], [0 -Inf 0], [1 Inf Inf], opts, xi, pdf);

A = p(1);
mu = p(2);
sigma = p(3);
g = exp(-(xi-mu).^2/(2*sigma^2)) / sqrt(2*pi)/sigma;

if ip.Results.Display
    figure;
    hold on;
    plot(xi, pdf, 'k-');
    plot(xi, A*g, 'r');
end



function v = cost(p, xi, pdf)
A = p(1);
mu = p(2);
sigma = p(3);

g = A*exp(-(xi-mu).^2/(2*sigma^2)) / sqrt(2*pi)/sigma;
v = g - pdf;
T = find(xi>mu+sigma, 1, 'first');
v(T:end) = 0;
