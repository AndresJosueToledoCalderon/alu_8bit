`timescale 100ns / 1ps

`include "cla_8bits.sv"
 
module Alu_8bits(
    input  wire [7:0] A,  // entrada de A 8bit
    input  wire [7:0] B,  // entrada de B 8bit
    input  wire [2:0] op, // codigo para seleccionar operacion
    input  wire   sh_sel, // seleccion de que numero A o B se hace el shift
    output reg  [7:0] Y, // resultado de las operaciones
    output reg        C, // carry out
    output reg        Z, // si es cero
    output reg        N, // si es negativo
    output reg        V  // si hay overflow
    );
    // numero que elige para las operaciones de shift [Elegir A o B]
    wire [7:0] S = sh_sel ? A : B; // se shiftea A o  B ?

    // definicion de variables intermedias para las salidas
    // de la suma, resta y el carry correspondiente a cada una
    wire [7:0] sum_out, diff_out;
    wire sum_carry, diff_carry;

    // suma: Cin = 0, no hay carry in
    // se instacia el carry look ahead para la suma
    cla_8bits cla_sum (
        .A(A), // asignar a A CLA, el A del input de la ALU que viene de los switches.
        .B(B), // lo mismo para B, a CLA el input de la ALU
        .Cin(1'b0), // carry igual a 0
        .Sum(sum_out), // asignar a la suma de CLA la suma de la ALU, es decir Sum
                       // "empuja" (da el valor) de la suma realizada a sum_out
        .Cout(sum_carry)
    );

    // resta: A + (~B + 1) Cin = 1, se usa carry in para calcular la resta
    // instacia para la resta con el carry look ahead adder
    wire [7:0] B_comp = ~B; // B complemento
    cla_8bits cla_diff (
        .A(A), // asignar a A CLA, el A del input de la ALU
        .B(B_comp), // asignar a B de la CLA, el complemento de B de la entrada de ALU 
        .Cin(1'b1), // carry igual a 1
        .Sum(diff_out), // asignar a la resta de CLA la resta de la ALU, es decir Sum
                       // "empuja" (da el valor) de la resta realizada a diff_out
        .Cout(diff_carry)
    );
    
    // bloque combinacional
    always @* begin
        Y = 8'h00; // definir Y, resultado con 8 bits, valores por defecto = 0
        C = 1'b0;  // definir carry out salida 1 bit, valore por defecto = 0
        V = 1'b0;  // definir salida overflow 1 bit, valor por defecto 0

        case (op)
            3'b000: begin // suma
                Y = sum_out;   // se asigna el resultado de la suma a la salida y
                C = sum_carry; // se asigna el carry de la suma
                V = A[7] ~^ B[7] ? 1'b0 : (A[7] ^ Y[7]); 
                // overflow solo si A y B tienen el mismo signo y difiere el signo del resultado
                // overflow si el signo de Y difiere del signo de A/B
                // V = (A[7] != Y[7]);
                // si no, V=0
            end

            3'b100: begin // resta (A - B)
                Y = diff_out; // se asgina el resultado de la resta a la salida
                C = diff_carry; // se asigna el carry out si hay
                V = (A[7] ^ B[7]) & (A[7] ^ Y[7]);
                // (A[7] ^ B[7]) detecta que A y B tenían signos distintos.
                // (A[7] ^ Y[7]) detecta que el resultado Y cambió de signo respecto a A.
                // solo si ambas condiciones son verdaderas -> V = 1. 
            end
            // operacion AND y carry = 0
            3'b010: begin Y = A & B; C = 1'b0; end
            
            // operacion OR y carry = 0
            3'b110: begin Y = A | B; C = 1'b0; end
            
            // shift a la derecha logico 1 posicion
            3'b001: begin C = S[0]; Y = S >> 1; end
            
            // shift a la izquierda logico 1 posicion
            3'b101: begin C = S[7]; Y = S << 1; end
            
            // shift a la derecha aritmetico
            3'b011: begin C = S[0]; Y = $signed(S) >>> 1; end
            
            // sin operacion, solo pasa S (numero seleccionado A o B)
            3'b111: begin Y = S; C = 1'b0; end
            
            // caso no valido Y = 0 y Carry  = 0
            default: begin Y = 8'h00; C = 1'b0; end
        endcase
        
        // flags de cero o negativo
        Z = (Y == 8'b0);
        N = Y[7];
    end
       
endmodule


