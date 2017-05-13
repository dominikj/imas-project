function hash = sha256()

%Read file
fid=fopen('sha256.m','r');
[data,count]=fread(fid);
fclose(fid);
data = de2bi(data,8);
data = reshape(data,1,size(data,1)*size(data,2));

%The initial hash value H is the following sequence of 32-bit words (which are
%obtained by taking the fractional parts of the square roots of the first eight primes):
H = [
    hex2dec('6a09e667');hex2dec('bb67ae85');hex2dec('3c6ef372');
    hex2dec('a54ff53a');hex2dec('510e527f');hex2dec('9b05688c');
    hex2dec('1f83d9ab');hex2dec('5be0cd19')
    ];

H = de2bi(H);

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
    s0_7 = circshift(block(i - 14),7);
    s0_18 = circshift(block(i - 14),18);
    s0_3 = circshift(block(i - 14),3);
    s0 = xor(xor(s0_7,s0_18),s0_3);
    
    %(w[i-2] rightrotate  17) xor  (w[i-2] rightrotate  19) xor  (w[i-2] rightshift  10)
    s1_17 = circshift(block(i - 1),17);
    s1_19 = circshift(block(i - 1),19);
    s1_10 = circshift(block(i - 1),10);
    s1 = xor(xor(s1_17,s1_19),s1_10);
    
    block(i) = block(i - 15) + s0 + block(i - 6) + s1;
end
hash = mod(size(data,2),512);
end

function s0 = sum0(data)
    s0_2 = circshift(data,2);
    s0_13 = circshift(data,13);
    s0_22 = circshift(data,22);
    s0 = xor(xor(s0_2,s0_13),s0_22);
end

function s1 = sum1(data)
    s1_6 = circshift(data,6);
    s1_11 = circshift(data,11);
    s1_25 = circshift(data,25);
    s1 = xor(xor(s1_6,s1_11),s1_25);
end
