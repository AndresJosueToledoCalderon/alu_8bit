module cla_8bits(
    input  wire [7:0] A, // entrada A de 8bits
    input  wire [7:0] B, // entrada b de 8bits
    input  wire       Cin, // entrada carry 1bit
    output wire [7:0] Sum, // salida de suma total
    output wire       Cout // salida de carryout
 );   
    wire [7:0] G; // generate
    wire [7:0] P; // propagate
    wire [8:0] C; // cadena de carries internos
    
    //    G[i] = A[i] & B[i] -> genera (detecta) un carry en la posición i
    //    P[i] = A[i] ^ B[i] -> propaga un carry existente
    assign G = A & B; // calcular generate, A*B
    assign P = A ^ B; // calcular propagate, A+B
    
    // se inicia el carry con un carry externo
    assign C[0] = Cin;
    //    C[i+1] = G[i] | (P[i] & C[i])
    //    si el bit i genera carry, o si lo propaga y venia de c[i].
    assign C[1] = G[0] | (P[0] & C[0]); // generacion de carry o propagacion de uno
    assign C[2] = G[1] | (P[1] & C[1]); // cada linea hace lo mismo en en su [i] bit
    assign C[3] = G[2] | (P[2] & C[2]);
    assign C[4] = G[3] | (P[3] & C[3]);
    assign C[5] = G[4] | (P[4] & C[4]);
    assign C[6] = G[5] | (P[5] & C[5]);
    assign C[7] = G[6] | (P[6] & C[6]);
    assign C[8] = G[7] | (P[7] & C[7]);
    //    sum[i] = p[i] ^ C[i]
    //    porque p = A+B, y se suma el carry entrante a cada bit
    assign Sum = P ^ C[7:0]; // calculo de suma del CLA
    
    assign Cout = C[8]; // carry out, es el ultimo y por eso c[8]
endmodule
