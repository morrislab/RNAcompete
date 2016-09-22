function [N m iqr new_m new_iqr] = quantileNormNaN(X, nomedian)
%function N = quantileNormNaN(X)
%
%  Affine transforms the columns of X so that they all have the same median
%  and IQR.  The new common median and IQR are the geometric mean of the
%  original values
%
%function N = quantileNormNaN(X, nomedian)
%
%  If nomedian != 0, then does not change the median


if nargin == 1 | nomedian == 0
    for ii = 1:size(X,2)
        x = X(:,ii);
        x_not_nan = x(find(~isnan(x)));
        m(ii) = median(x_not_nan);
        iqr(ii) = prctile(x_not_nan,75)-prctile(x_not_nan,25);    
    end
    new_m = exp(nanmean(log(m)));
    new_iqr = exp(nanmean(log(iqr)));

    N = zeros(size(X));
    for ii = 1:size(X,2)
        v = (X(:,ii) - m(ii)) * new_iqr / iqr(ii) + new_m;
        N(:,ii) = v;
    end
else
    for ii = 1:size(X,2)
        x = X(:,ii);
        x_not_nan = x(find(~isnan(x)));
        iqr(ii) = prctile(x_not_nan,75)-prctile(x_not_nan,25);    
    end
    new_iqr = exp(nanmean(log(iqr)));

    N = zeros(size(X));
    for ii = 1:size(X,2)
        v = X(:,ii)* new_iqr / iqr(ii);
        N(:,ii) = v;
    end
end    