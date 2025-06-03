
`include "cla_8bits.sv"

module alu_8bits(
    // Puertos requeridos por TinyTapeout
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ena,
    input  logic  [7:0] ui_in,
    input  logic  [7:0] uio_in,
    output logic  [7:0] uo_out,
    output logic  [7:0] uio_out,
    output logic  [7:0] uio_oe
);

    // ------------------------------------------------------------
    // 1) Mapeo de “inputs comunes” ui_in / uio_in a señales internas
    // ------------------------------------------------------------
    // Para que TinyTapeout genere el netlist sin error, aquí “consumimos”:
    //   - ui_in: lo usamos completo como operando A.
    //   - uio_in: lo usamos completo como operando B.
    //   - op        = ui_in[2:0]
    //   - sh_sel    = ui_in[3]
    //
    // (Dejamos el resto de bits de ui_in[7:4] solo para silenciar warnings.)
    wire [7:0] A      = ui_in;
    wire [7:0] B      = uio_in;
    wire [2:0] op     = ui_in[2:0];
    wire       sh_sel = ui_in[3];

    // ------------------------------------------------------------
    // 2) Instanciación del CLA para suma y resta (usando B o ~B)
    // ------------------------------------------------------------
    wire [7:0] sum_out, diff_out;
    wire       sum_carry, diff_carry;

    // Suma: Cin = 0
    cla_8bits cla_sum (
        .A   (A),
        .B   (B),
        .Cin (1'b0),
        .Sum (sum_out),
        .Cout(sum_carry)
    );

    // Resta: A + (~B) + 1 → Cin = 1
    wire [7:0] B_comp = ~B;
    cla_8bits cla_diff (
        .A   (A),
        .B   (B_comp),
        .Cin (1'b1),
        .Sum (diff_out),
        .Cout(diff_carry)
    );

    // ------------------------------------------------------------
    // 3) Lógica de shifts (elige A o B según sh_sel)
    // ------------------------------------------------------------
    wire [7:0] S = sh_sel ? A : B;

    // ------------------------------------------------------------
    // 4) Señales internas de bandera y resultado
    // ------------------------------------------------------------
    logic [7:0] Y;  // Resultado final de la ALU
    logic        C; // Carry out
    logic        Z; // Zero flag
    logic        N; // Negative flag
    logic        V; // Overflow flag

    // ------------------------------------------------------------
    // 5) Bloque combinacional que implementa las operaciones
    // ------------------------------------------------------------
    always @* begin
        // Valores por defecto:
        Y = 8'h00;
        C = 1'b0;
        V = 1'b0;

        case (op)
            3'b000: begin // Suma
                Y = sum_out;
                C = sum_carry;
                // Overflow si A y B mismo signo, y signo de Y distinto
                V = (A[7] ~^ B[7]) ? 1'b0 : (A[7] ^ Y[7]);
            end

            3'b100: begin // Resta (A - B)
                Y = diff_out;
                C = diff_carry;
                // Overflow si A y B signos distintos, y signo de Y distinto de A
                V = (A[7] ^ B[7]) & (A[7] ^ Y[7]);
            end

            3'b010: begin // AND
                Y = A & B;
                C = 1'b0;
                V = 1'b0;
            end

            3'b110: begin // OR
                Y = A | B;
                C = 1'b0;
                V = 1'b0;
            end

            3'b001: begin // Shift right lógico 1
                C = S[0];
                Y = S >> 1;
                V = 1'b0;
            end

            3'b101: begin // Shift left lógico 1
                C = S[7];
                Y = S << 1;
                V = 1'b0;
            end

            3'b011: begin // Shift right aritmético
                C = S[0];
                Y = $signed(S) >>> 1;
                V = 1'b0;
            end

            3'b111: begin // Pasa S sin operación
                Y = S;
                C = 1'b0;
                V = 1'b0;
            end

            default: begin // Caso no válido
                Y = 8'h00;
                C = 1'b0;
                V = 1'b0;
            end
        endcase

        // Flags de cero y negativo
        Z = (Y == 8'b0);
        N = Y[7];
    end

    // ------------------------------------------------------------
    // 6) Mapear la salida Y hacia uo_out (puerto común de salida)
    // ------------------------------------------------------------
    assign uo_out = Y;

    // ------------------------------------------------------------
    // 7) Outputs bidireccionales “apagados” (señales no usadas)
    // ------------------------------------------------------------
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // ------------------------------------------------------------
    // 8) Señales de entrada que no usamos (rst_n, ena, ui_in[7:4], uio_in)
    //    — una sola línea “_unused_ok” según recomendación TinyTapeout,
    //    para silenciar todos los warnings UNUSEDSIGNAL.
    // ------------------------------------------------------------
    wire _unused_ok = &{
        1'b0,
        rst_n,          // no usamos reset
        ena,            // no usamos enable
        ui_in[7:4],     // bits superiores de ui_in, no usados en la ALU
        uio_in,         // no usamos uio_in como bidireccional real en la lógica
        1'b0
    };

endmodule


