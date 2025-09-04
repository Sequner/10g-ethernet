from cocotb.types import Range, LogicArray

def scrambler(data_in, offset=0):
    scr = 0
    for i in range(len(data_in)):
        if (i % 66) == offset or (i % 66) == (offset+1):
            continue
        bit = (scr >> 57 & 1) ^ (scr >> 38 & 1) ^ data_in[i]
        scr = (scr << 1) + bit
        data_in[i] = bit

def descrambler(data_in):
    scr = 0
    for i in range(len(data_in)):
        bit = (scr >> 57 & 1) ^ (scr >> 38 & 1) ^ data_in[i]
        scr = (scr << 1) + data_in[i]
        data_in[i] = bit

def contains(small, big):
    for i in range(len(big)-len(small)+1):
        for j in range(len(small)):
            if big[i+j] != small[j]:
                break
        else:
            return True
    return False