function hash = sha256()

%Read file - non-translatable to vhdl
fid=fopen('sha256.m','r');
[data,count]=fread(fid);
fclose(fid);
data = de2bi(data,8);
data = reshape(data,1,size(data,1)*size(data,2));

%The initial hash value H is the following sequence of 32-bit words (which are
%obtained by taking the fractional parts of the square roots of the first eight primes):
H = [
    '6a09e667'; 'bb67ae85'; '3c6ef372'; 'a54ff53a';
    '510e527f'; '9b05688c'; '1f83d9ab'; '5be0cd19'
    ];

H = de2bi(hex2dec(H));

%A sequence of constant rounds K
K = [
        '428a2f98'; '71374491'; 'b5c0fbcf'; 'e9b5dba5'; 
        '3956c25b'; '59f111f1'; '923f82a4'; 'ab1c5ed5';
        'd807aa98'; '12835b01'; '243185be'; '550c7dc3'; 
        '72be5d74'; '80deb1fe'; '9bdc06a7'; 'c19bf174';
        'e49b69c1'; 'efbe4786'; '0fc19dc6'; '240ca1cc';
        '2de92c6f'; '4a7484aa'; '5cb0a9dc'; '76f988da';
        '983e5152'; 'a831c66d'; 'b00327c8'; 'bf597fc7';
        'c6e00bf3'; 'd5a79147'; '06ca6351'; '14292967';
        '27b70a85'; '2e1b2138'; '4d2c6dfc'; '53380d13'; 
        '650a7354'; '766a0abb'; '81c2c92e'; '92722c85';
        'a2bfe8a1'; 'a81a664b'; 'c24b8b70'; 'c76c51a3'; 
        'd192e819'; 'd6990624'; 'f40e3585'; '106aa070';
        '19a4c116'; '1e376c08'; '2748774c'; '34b0bcb5'; 
        '391c0cb3'; '4ed8aa4a'; '5b9cca4f'; '682e6ff3';
        '748f82ee'; '78a5636f'; '84c87814'; '8cc70208'; 
        '90befffa'; 'a4506ceb'; 'bef9a3f7'; 'c67178f2'
    ];

K = de2bi(hex2dec(K));

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
block = zeros(64,32);
for i = 0:15
    block(i+1,:) = data([block512Start + 32*i : block512Start + 32*i + 31]);
end

%Expansion data step

%Make 16 32-bit words to 64 32-bit words
for i= 16:64
    % (w[i-14] rightrotate  7) xor  (w[i-14] rightrotate  18) xor  (w[i-14] rightshift  3)
    s0_7 = circshift(block(i - 14,:),7);
    s0_18 = circshift(block(i - 14,:),18);
    s0_3 = rightshift(block(i - 14,:),3);
    s0 = xor(xor(s0_7,s0_18),s0_3);
    
    %(w[i-1] rightrotate  17) xor  (w[i-1] rightrotate  19) xor  (w[i-1] rightshift  10)
    s1_17 = circshift(block(i - 1,:),17);
    s1_19 = circshift(block(i - 1,:),19);
    s1_10 = rightshift(block(i - 1,:),10);
    s1 = xor(xor(s1_17,s1_19),s1_10);
    
    block(i, :) = block(i - 15, :) + s0 + block(i - 6, :) + s1;
end

%Initialize registers
regs = zeros(8,1);
regs(1) = H(1);
regs(2) = H(2);
regs(3) = H(3);
regs(4) = H(4);
regs(5) = H(5);
regs(6) = H(6);
regs(7) = H(7);
regs(8) = H(8);

hash = mod(size(data,2),512);
end

%Logical functions are needed in SHA-256

%(a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
function s0 = sum0(data)
    s0_2 = circshift(data,2);
    s0_13 = circshift(data,13);
    s0_22 = circshift(data,22);
    s0 = xor(xor(s0_2,s0_13),s0_22);
end

%(e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
function s1 = sum1(data)
    s1_6 = circshift(data,6);
    s1_11 = circshift(data,11);
    s1_25 = circshift(data,25);
    s1 = xor(xor(s1_6,s1_11),s1_25);
end

%(e and f) xor ((not e) and g)
function ch = ch(e,f,g)
    e_and_f = and(e,f);
    not_e = not(e);
    not_e_and_g = and(not_e,g);
    ch = xor(e_and_f,not_e_and_g);
end

%(e and f) xor ((not e) and g)
function ma = ma(a,b,c)
    a_and_b = and(a,b);
    a_and_c = and(a,c);
    b_and_c = and(b,c);
    ma = xor(a_and_b,xor(a_and_c,b_and_c));
end

%h + s1 + ch + k[i] + w[i]
function t1 = t1(h,s1,ch,ki,wi)
   h_s1 = addmod232(h,s1);
   h_s1_ch = addmod232(h_s1,ch);
   h_s1_ch_ki = addmod232(h_s1_ch,ki);
   t1 = addmod232(h_s1_ch_ki,wi);
end

%s0 + maj
function t2 = t2(s0,ma)
t2 = addmod232(s0,ma);
end

%Addition in 2^32 finite field
function addmod232 = addmod232(a,b)
addmod232 = de2bi(mod(bi2de(a)+bi2de(b),4294967296));
end

%Right shifting
function shifted = rightshift(data,bits)
shifted = [zeros(1,bits) data(1,1:size(data,2)-bits)];
end
