function hash = sha256(data,count)

%Read file - non-translatable to vhdl
%fid=fopen('sha256.m','r');
%[data,count]=fread(fid);
%fclose(fid);
%data = uint8('abc').'
%count = 3
data = de2bi(data,8,'left-msb');
data = reshape(data.',1,size(data,1)*size(data,2));

%The initial hash value H is the following sequence of 32-bit words (which are
%obtained by taking the fractional parts of the square roots of the first eight primes):
H = [
    '6a09e667'; 'bb67ae85'; '3c6ef372'; 'a54ff53a';
    '510e527f'; '9b05688c'; '1f83d9ab'; '5be0cd19'
    ];

H = de2bi(hex2dec(H),'left-msb');

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

K = de2bi(hex2dec(K),'left-msb');

%Prepairing step

%Append the bit "1" to the end of the message, and then k zero bits, 
%where k is the smallest non-negative solution to the equation l+1+k = 448 mod 512
% l is message length
data = [data 1];
remainder = mod(size(data,2),512);
zerosnumber = 448 - remainder;

%corner case
if zerosnumber == -1
    zerosnumber = 511;    
end
data = [data zeros(1,zerosnumber)];

%To this append the 64-bit block which is equal to the number l written in binary
length64 = de2bi(count*8,64,'left-msb');
data = [data length64];

%Parse the message into N 512-bit blocks
block512Start = 1;

while block512Start < size(data,2)
    
%Parse the 512-bit block into 16 32-bit blocks
%We use the big-endian convention throughout, so within each
%32-bit word, the left-most bit is stored in the most significant bit position.
block = zeros(64,32);
for i = 0:15
    block(i+1,:) = data([block512Start + 32*i : block512Start + 32*i + 31]);
end

%Expansion data step

%Make 16 32-bit words to 64 32-bit words
for i= 17:64
    % (w[i-14] rightrotate  7) xor  (w[i-14] rightrotate  18) xor  (w[i-14] rightshift  3)
    s0_7 = circshift(block(i - 15,:),7);
    s0_18 = circshift(block(i - 15,:),18);
    s0_3 = rightshift(block(i - 15,:),3);
    s0 = xor(xor(s0_7,s0_18),s0_3);
    
    %(w[i-1] rightrotate  17) xor  (w[i-1] rightrotate  19) xor  (w[i-1] rightshift  10)
    s1_17 = circshift(block(i - 2,:),17);
    s1_19 = circshift(block(i - 2,:),19);
    s1_10 = rightshift(block(i - 2,:),10);
    s1 = xor(xor(s1_17,s1_19),s1_10);

    b1_s0 = addmod232(block(i - 16, :), s0);
    b2_s1 = addmod232(block(i - 7, :), s1);
    block(i, :) =  addmod232(b1_s0,b2_s1);
end

%Initialize registers
regs = zeros(8,32);
regs(1,:) = H(1,:); %a
regs(2,:) = H(2,:); %b
regs(3,:) = H(3,:); %c
regs(4,:) = H(4,:); %d
regs(5,:) = H(5,:); %e
regs(6,:) = H(6,:); %f
regs(7,:) = H(7,:); %g
regs(8,:) = H(8,:); %h

%Essential step

for i = 1:64
    s1_ = sum1(regs(5,:));
    ch_ = ch(regs(5,:),regs(6,:),regs(7,:));
    t1_ = t1(regs(8,:),s1_,ch_,K(i,:),block(i,:));
    s0_ = sum0(regs(1,:));
    ma_ = ma(regs(1,:),regs(2,:),regs(3,:));
    t2_ = t2(s0_,ma_);
    
    regs(8,:) = regs(7,:);
    regs(7,:)=  regs(6,:);
    regs(6,:) = regs(5,:);
    regs(5,:) = addmod232(regs(4,:),t1_);
    regs(4,:) = regs(3,:);
    regs(3,:) = regs(2,:);
    regs(2,:) = regs(1,:);
    regs(1,:) = addmod232(t1_,t2_);
end
H(1,:) = addmod232(H(1,:),regs(1,:));
H(2,:) = addmod232(H(2,:),regs(2,:));
H(3,:) = addmod232(H(3,:),regs(3,:));
H(4,:) = addmod232(H(4,:),regs(4,:));
H(5,:) = addmod232(H(5,:),regs(5,:));
H(6,:) = addmod232(H(6,:),regs(6,:));
H(7,:) = addmod232(H(7,:),regs(7,:));
H(8,:) = addmod232(H(8,:),regs(8,:));

block512Start = block512Start + 512;
end
hash = dec2hex(bin2dec(num2str(reshape(H.',4,[])','%1d')))';
%hash = H;
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
addmod232 = de2bi(mod(bi2de(a,'left-msb')+bi2de(b,'left-msb'),4294967296),32,'left-msb');
end

%Right shifting
function shifted = rightshift(data,bits)
shifted = [zeros(1,bits) data(1,1:size(data,2)-bits)];
end
