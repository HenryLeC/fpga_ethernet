"""
Author: Henry LeCompte

This file is very ugly but it implements code generation for linear feedback shift registers

Currently it only supports fibonacci style polynomials but this is easily modified for galois.
It first represents the lfsr as a transfer matrix in the form introduced here
https://apps.dtic.mil/sti/tr/pdf/ADA212351.pdf
and then applies the matrix to the current state at each input bit.
The code then simplifies the expressions and outputs the bit operations required to implement
the lfsr combinationally and the expression for the new state.

The code for simplifying the bitwise expressions is not at all robust and was programmed in an afternoon.
"""

from typing import Literal, Sequence
import collections


class GF2_Sym:
    def __init__(
        self,
        name: str | int | None,
        left: "GF2_Sym",
        right: "GF2_Sym",
        op: Literal["XOR", "AND"],
    ):
        self.name = name
        self.left = left
        self.right = right
        self.op = op

        # print(self)
        self.simplify()

        # print(self)
        # print("--------------")

    def xor_simplify(self):
        if not self.all_xor():
            return

        elements = self.__repr__().split("^")
        counter = collections.Counter(elements)

        most_common = counter.most_common()
        valid_terms = [x for x in most_common if x[1] & 1]

        valid_terms = sorted(valid_terms, key=lambda x: x[0])

        if len(valid_terms) == 1:
            self.name = valid_terms[0][0]
            return

        self.name = None
        self.op = "XOR"
        self.left = GF2_Sym(valid_terms[0][0], None, None, None)
        self.right = GF2_Sym(valid_terms[1][0], None, None, None)
        current = self

        for elem, _ in valid_terms[2:]:
            left = GF2_Sym(current.right.name, None, None, None)
            right = GF2_Sym(elem, None, None, None)
            new = GF2_Sym(None, left, right, "XOR")
            current.right = new
            current = current.right

    def simplify(self):
        if self.name is not None:
            return
        if type(self.left.name) is None:
            self.left.simplify()
        if type(self.right.name) is None:
            self.right.simplify()

        if self.op == "AND":
            if self.left.name == 0 or self.right.name == 0:
                self.name = 0
                self.left = None
                self.right = None
                return
            if self.left.name == 1 and self.right.name == 1:
                self.name = 1
                self.left = None
                self.right = None
                return
            if self.left.name == 1:
                self.name = self.right.name
                self.op = self.right.op
                self.left = self.right.left
                self.right = self.right.right
                return
            if self.right.name == 1:
                self.name = self.left.name
                self.op = self.left.op
                self.right = self.left.right
                self.left = self.left.left
                return
        if self.op == "XOR":
            if self.left.name == 0:
                self.name = self.right.name
                self.op = self.right.op
                self.left = self.right.left
                self.right = self.right.right
                return
            if self.right.name == 0:
                self.name = self.left.name
                self.op = self.left.op
                self.right = self.left.right
                self.left = self.left.left
                return

        if type(self.left.name) is int and type(self.right.name) is int:
            if self.op == "XOR":
                self.name = self.left.name ^ self.right.name
            else:
                self.name = self.left.name & self.right.name

    def all_xor(self):
        if self.op == "AND":
            return False
        if type(self.name) is str:
            return True
        if type(self.name) is int:
            return False
        return self.left.all_xor() & self.right.all_xor()

    def __repr__(self):
        if self.name is not None:
            return str(self.name)
        return (
            # "("
            self.left.__repr__()
            + ("&" if self.op == "AND" else "^")
            + self.right.__repr__()
            # + ")"
        )


class GF2:
    def __init__(self, data: Sequence[Sequence[int | GF2_Sym]]):
        self.data = data
        for i in data:
            for idx, x in enumerate(i):
                if type(x) is int:
                    if x != 0 and x != 1:
                        raise Exception("GF2 cannot contain elements other than 0 or 1")
                    i[idx] = GF2_Sym(x, None, None, None)

    def __repr__(self):
        return self.data.__repr__()

    @classmethod
    def multiply(cls, left: "GF2", right: "GF2"):
        rows = len(left.data)
        cols = len(right.data[0])
        result = cls([[0] * cols for _ in range(rows)])
        for i in range(rows):
            for j in range(cols):
                result.data[i][j] = GF2.multiply_row_col(
                    left.data[i], [x[j] for x in right.data]
                )
        return result

    @staticmethod
    def multiply_row_col(left: Sequence[int | GF2_Sym], right: Sequence[int | GF2_Sym]):
        assert len(left) == len(right)
        result = GF2_Sym(None, left[0], right[0], "AND")
        for i in range(1, len(left)):
            result = GF2_Sym(
                None, result, GF2_Sym(None, left[i], right[i], "AND"), "XOR"
            )
        result.xor_simplify()
        return result


lfsr_width = 58
data_width = 64

polynomial = 0x400008000000001


states = GF2(
    [
        [
            GF2_Sym(f"s[{lfsr_width - 1 - i}]", None, None, None)
            for i in range(lfsr_width)
        ]
        + [
            GF2_Sym("i[0]", None, None, None),
        ]
    ]
)

transition = GF2(
    [
        [int(i == j + 1) for j in range(lfsr_width - 1)]
        + [(polynomial >> (lfsr_width - i)) & 1]
        for i in range(lfsr_width)
    ]
    + [([0] * (lfsr_width - 1)) + [1]]
)

print(len(transition.data), "x", len(transition.data[0]))

history = []

for i in range(1, data_width + 1):
    # print(states.data)
    states = GF2.multiply(states, transition)
    print(f"out[{i - 1}] =", states.data[0][-1])
    states.data[0].append(GF2_Sym(f"i[{i}]", None, None, None))

print("---------")
print(states.data[0][:-1])
