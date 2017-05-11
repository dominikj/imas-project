function hash = sha256()

%Read file
fid=fopen('sha256.m','r');
[data,count]=fread(fid);
fclose(fid);
data = de2bi(data,8);
data = reshape(data,1,size(data,1)*size(data,2));

%Prepairing step

%Append the bit "1" to the end of the message, and then k zero bits, 
%where k is the smallest non-negative solution to the equation l+1+k = 448 mod 512
% l is message length
remainder = mod(size(data,2),512);
zerosnumber = 448 - remainder - 1;
data = [data 1];
data = [data zeros(1,zerosnumber)];

%To this append the 64-bit block which is equal to the number l written in binary
length64 = typecast(count,'uint8');
length64 = de2bi(length64,8);
length64 = reshape(length64,1,size(length64,1)*size(length64,2));
data = [data length64];
hash = mod(size(data,2),512);
end