module mips_cpu_bus_tb ();

  logic clk;
  logic reset;
  logic active;
  logic [31:0] register_v0;

  logic [31:0] address;
  logic write;
  logic read;
  logic waitrequest;
  logic [31:0] writedata;
  logic [3:0] byteenable;
  logic [31:0] readdata;

  initial begin
    $dumpfile("mips_cpu_bus_tb.vcd");
    $dumpvars(0, mips_cpu_bus_tb);

    clk = 0;
    #1;
    repeat (256) begin
      #2 clk = !clk;
    end
    $finish;
  end

  initial begin
    reset = 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
  end

  mips_cpu_bus mips_cpu_bus (
      .clk(clk),
      .reset(reset),
      .active(active),
      .register_v0(register_v0),
      .address(address),
      .write(write),
      .read(read),
      .waitrequest(waitrequest),
      .writedata(writedata),
      .byteenable(byteenable),
      .readdata(readdata)
  );

  cpu_ram cpu_ram (
      .clk(clk),
      .read(read),
      .write(write),
      .byteenable(byteenable),
      .address(address),
      .writedata(writedata),
      .waitrequest(waitrequest),
      .readdata(readdata)
  );

endmodule