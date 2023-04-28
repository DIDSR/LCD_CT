function L=laguerre(x,J)
%function L=laguerre(x,J)
%Calculate the laguerre polynomials
L=zeros(length(x),J+1);
for j=0:J
    combin=factorial(j)./(factorial([0:j]).*factorial(j-[0:j]));    
    for k=0:j
        L(:,j+1)=combin(k+1).*((-x).^k) /factorial(k) + L(:,j+1);
    end
end
