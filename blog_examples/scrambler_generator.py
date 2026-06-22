import numpy as np

inputs = 64
states = 58
descramble = True

poly = 0x400008000000001

# inputs = 4
# states = 3
# poly = 0b1011
# descramble = True

assert poly >> states == 1, "Polynomial must be states + 1 bits and have top bit set"

mat = np.diag([1] * (inputs + states - 1), 1)

mat[:, 0] = [
    1 if (poly << (inputs - 1) >> i) & 1 else 0 for i in range(inputs + states)
]

if not descramble:
    mat[:, inputs] = mat[:, 0]

mat = np.linalg.matrix_power(mat, inputs) % 2

print(mat)

print(
    f"""module {"de" if descramble else ""}scrambler_gen(
    input wire [{inputs + states - 1}:0] data_in,
    output wire [{inputs + states - 1}:0] data_out
);"""
)

for i in range(inputs + states):
    print(
        f"assign data_out[{i}] = "
        + " ^ ".join([f"data_in[{j}]" for j in range(inputs + states) if mat[j, i]])
        + ";"
    )
print("endmodule")
