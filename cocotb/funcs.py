from cocotb.binary import BinaryValue

def scrambler(data_in):
    scr = BinaryValue(value='1'*58, n_bits=58).integer
    for i in range(len(data_in)):
        if i % 66 == 63:
            data_in[i] = 1
        elif i % 66 == 62:
            data_in[i] = 0
        else:
            bit = (scr >> 57 & 1) ^ (scr >> 38 & 1) ^ data_in[i]
            scr = (scr << 1) + bit
            data_in[i] = bit

def reverse_by_block(data_in, block_size=66):
    for i in range(int(len(data_in)/block_size)):
        data_in[i*block_size:(i+1)*block_size] = \
        data_in[i*block_size:(i+1)*block_size][::-1]