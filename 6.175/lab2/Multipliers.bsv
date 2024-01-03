// Reference functions that use Bluespec's '*' operator
function Bit#(TAdd#(n,n)) multiply_unsigned( Bit#(n) a, Bit#(n) b );
    UInt#(n) a_uint = unpack(a);
    UInt#(n) b_uint = unpack(b);
    UInt#(TAdd#(n,n)) product_uint = zeroExtend(a_uint) * zeroExtend(b_uint);
    return pack( product_uint );
endfunction

function Bit#(TAdd#(n,n)) multiply_signed( Bit#(n) a, Bit#(n) b );
    Int#(n) a_int = unpack(a);
    Int#(n) b_int = unpack(b);
    Int#(TAdd#(n,n)) product_int = signExtend(a_int) * signExtend(b_int);
    return pack( product_int );
endfunction

function Bit#(TAdd#(n,1)) add_unsigned( Bit#(n) a, Bit#(n) b );
    UInt#(n) a_uint = unpack(a);
    UInt#(n) b_uint = unpack(b);
    UInt#(TAdd#(n,1)) add_uint = zeroExtend(a_uint) + zeroExtend(b_uint);
    return pack( add_uint );
endfunction

function Bit#(n) signed_shift_right( Bit#(n) p, Integer a );
    Int#(n) num = unpack(p);
    Int#(n) res = num >> a;
    return pack( res );
endfunction

// Multiplication by repeated addition
function Bit#(TAdd#(n,n)) multiply_by_adding( Bit#(n) a, Bit#(n) b );
    Bit#(n) tp = 0;
    Bit#(n) prod = 0;
    for(Integer i = 0; i < valueOf(n); i = i + 1) begin
        Bit#(n) m = (a[i]==0)? 0: b;
        Bit#(TAdd#(n,1)) sum = add_unsigned(m, tp);
        prod[i] = sum[0];
        tp = sum[valueOf(n):1];
    end
    return {tp, prod};
endfunction



// Multiplier Interface
interface Multiplier#( numeric type n );
    method Bool start_ready();
    method Action start( Bit#(n) a, Bit#(n) b );
    method Bool result_ready();
    method ActionValue#(Bit#(TAdd#(n,n))) result();
endinterface



// Folded multiplier by repeated addition
module mkFoldedMultiplier( Multiplier#(n) );
    // You can use these registers or create your own if you want
    Reg#(Bit#(n)) a <- mkRegU();
    Reg#(Bit#(n)) b <- mkRegU();
    Reg#(Bit#(n)) prod <- mkRegU();
    Reg#(Bit#(n)) tp <- mkRegU();
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)+1) );

    // rule mulStep( /* guard goes here */ );
    rule mulStep( i < fromInteger(valueOf(n)) );
        Bit#(n) m = (a[i]==0)? 0: b;
        Bit#(TAdd#(n,1)) sum = add_unsigned(m, tp);
        prod[i] <= sum[0];
        tp <= sum[valueOf(n):1];
        i <= i + 1;
    endrule

    method Bool start_ready();
        return (i == fromInteger(valueOf(n) + 1));
    endmethod

    method Action start( Bit#(n) aIn, Bit#(n) bIn );
            a <= aIn;
            b <= bIn;
            i <= 0;
            prod <= 0;
            tp <= 0;
    endmethod

    method Bool result_ready();
        return (i == fromInteger(valueOf(n)));
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        i <= i + 1;
        return {tp, prod};
    endmethod
endmodule



// Booth Multiplier
module mkBoothMultiplier( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) m_neg <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) m_pos <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) p <- mkRegU;
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)+1) );

    rule mul_step( i < fromInteger(valueOf(n)) );
        Bit#(2) pr = p[1:0];
        Bit#(TAdd#(TAdd#(n,n),1)) t = p;
        case(pr)
            2'b01: t = p + m_pos;
            2'b10: t = p + m_neg;
        endcase
        p <= signed_shift_right(t, 1);
        i <= i + 1;
    endrule

    method Bool start_ready();
        return (i == fromInteger(valueOf(n) + 1));
    endmethod

    method Action start( Bit#(n) m, Bit#(n) r );
        m_pos <= {m, 0};
        m_neg <= {(-m), 0};
        p <= {0, r, 1'b0};
        i <= 0;
    endmethod

    method Bool result_ready();
        return (i == fromInteger(valueOf(n)));
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        i <= i + 1;
        return p[?:1];
    endmethod
endmodule



// Radix-4 Booth Multiplier
module mkBoothMultiplierRadix4( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) m_neg <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) m_pos <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) p <- mkRegU;
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)/2+1) );

    //rule mul_step( /* guard goes here */ );
    rule mul_step( i < fromInteger(valueOf(n)/2) );
        Bit#(TAdd#(TAdd#(n,n),2)) t = p;
        Bit#(3) pr = p[2:0];
        case(pr)
            3'b001: t = p + m_pos;
            3'b010: t = p + m_pos;
            3'b011: t = p + (m_pos << 1);
            3'b100: t = p + (m_neg << 1);
            3'b101: t = p + m_neg;
            3'b110: t = p + m_neg;
        endcase
        p <= signed_shift_right(t, 2);
        i <= i + 1;

    endrule

    method Bool start_ready();
        return i == fromInteger(valueOf(n)/2 + 1);
    endmethod

    method Action start( Bit#(n) m, Bit#(n) r );
        m_pos <= {m[valueOf(n) - 1], m, 0};
        m_neg <= {(-m)[valueOf(n) - 1], -m, 0};
        p <= {0, r, 1'b0};
        i <= 0;
    endmethod

    method Bool result_ready();
        return i == fromInteger(valueOf(n)/2);
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        i <= i + 1;
        return p[2*valueOf(n):1];
    endmethod
endmodule

