# notes on 6.175

## lab 0

```bash
$ apt-get install iverilog tcl-dev
```

## lab 1

组合逻辑电路的速度取决于它最长的输入-输出路径
Do better: Sequential Circuits; Circuits with state.

8-bit ripple-carry adder: slow

8-bit carry-select adder

`valueOf`: `numeric type -> Integer`

Polymorphism in BSV: the implementation of the hardware changes automatically based on compile time configuration.
