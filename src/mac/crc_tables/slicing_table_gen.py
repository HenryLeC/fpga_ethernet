poly = 0xEDB88320

tables = [[0] * 256, [0] * 256, [0] * 256, [0] * 256]

for i in range(256):
    crc = i
    for j in range(8):
        crc = (crc >> 1) ^ ((crc & 1) * poly)
    tables[0][i] = crc

for i in range(256):
    for k in range(1, 4):
        tables[k][i] = (tables[k - 1][i] >> 8) ^ tables[0][tables[k - 1][i] & 0xFF]

if __name__ == "__main__":
    for i in range(4):
        with open(f"crc_lookup_{i}.hex", "w") as f:
            for j in range(256):
                f.write(f"{tables[i][j]:08x}\n")
