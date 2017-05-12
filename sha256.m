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
length64 = de2bi(length64,8,'left-msb');
length64 = reshape(length64,1,size(length64,1)*size(length64,2));
data = [data length64];

%Parse the message into N 512-bit blocks
%Need make loop
block512Start = 1;
block512End = 512;

%Parse the 512-bit block into 16 32-bit blocks
%We use the big-endian convention throughout, so within each
%32-bit word, the left-most bit is stored in the most significant bit position.
blockBin = zeros(16,32);
blockDec = zeros(64,1);
for i = 0:15
    blockBin(i+1,:) = data([block512Start + 32*i : block512Start + 32*i + 31]);
    blockDec(i+1) = bi2de(blockBin(i+1,:),'left-msb');
end

%Expansion data step

%Make 16 32-bit words to 64 32-bit words
for i= 16:63
    % (w[i-14] rightrotate  7) xor  (w[i-14] rightrotate  18) xor  (w[i-14] rightshift  3)
    s0_7 = bin(bitror(fi(blockDec(i - 14),0,32,0),7));
    s0_18 = bin(bitror(fi(blockDec(i - 14),0,32,0),18));
    s0_3 = bin(bitror(fi(blockDec(i - 14),0,32,0),3));
    s0 = xor(xor(s0_7,s0_18),s0_3);
    s0 = bi2de(s0);
    
    %(w[i-2] rightrotate  17) xor  (w[i-2] rightrotate  19) xor  (w[i-2] rightshift  10)
    s1_17 = bin(bitror(fi(blockDec(i - 14),0,32,0),17));
    s1_19 = bin(bitror(fi(blockDec(i - 14),0,32,0),19));
    s1_10 = bin(bitror(fi(blockDec(i - 14),0,32,0),10));
    s1 = xor(xor(s1_17,s1_19),s1_10);
    s1 = bi2de(s1);
    
    blockDec(i) = blockDec(i - 15) + s0 + blockDec(i - 6) + s1;
end

hash = mod(size(data,2),512);
end