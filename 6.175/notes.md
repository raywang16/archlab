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

## lab 2

`TAdd#(m,n)`: add of `numeric type`

`pack` and `unpack` are built-in functions that convert to and from `Bit#(n)` respectively.

`UInt#(n)`, `Int#(n)`
`zeroExtend()`, `signExtend()`

modules must be explicitly instantiated using the `<-` notation。

**值方法** (Value method) 能让调用者从被调用模块中获取数据。例如，寄存器的 _read 就是值方法。

值方法的实现内不能调用本模块内的子模块的动作方法和动作值方法，因为这会改变模块内的数据/状态（比如不能写寄存器和 Wire ），换句话说，无论你是否调用值方法，都不会对被调用模块当前和将来的执行轨迹造成影响。

值方法可以有隐式条件，如果隐式条件不满足，则调用它的规则不激活。

**动作方法** (Action method) 能让调用者通过参数把数据给被调用模块（也可以没有参数）。例如，寄存器的 _write 就是动作方法。动作方法不会返回数据给调用者。

动作方法可以有隐式条件，如果隐式条件不满足，则调用它的规则不激活。

**动作值方法** (ActionValue Method) 既允许向模块传入参数作为数据（也可以不带参数）、修改被调用模块的状态，又允许获取模块内的状态/数据。

动作值方法可以有隐式条件，如果隐式条件不满足，则调用它的规则不激活。

`TLog#(n)`: `ceil(log2(n))`