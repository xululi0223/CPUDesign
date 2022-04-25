`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allwoin
    input                          ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    // inst sram interface
    output        inst_sram_en   ,
    output [ 3:0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata
);

reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;

/*********************lab4新增：pre-if阶段信号及延迟槽中断信号*********************/
wire         pre_if_ready_go;
wire         br_stall;
/*********************lab4新增：pre-if阶段信号及延迟槽中断信号*********************/

wire         br_taken;
wire [31:0] br_target;
/*********************lab4修改：将延迟槽中断信号加入bus*********************/
//源代码：assign {br_taken,br_target} = br_bus;
assign {br_stall,br_taken,br_target} = br_bus;
/*********************lab4修改：将延迟槽中断信号加入bus*********************/

wire [31:0] fs_inst;
reg  [31:0] fs_pc;
assign fs_to_ds_bus = {fs_inst ,
                       fs_pc   };

// pre-IF stage
/***************lab4新增：处理pre-if阶段允许输出信号****************/
assign pre_if_ready_go = ~br_stall;
/***************lab4新增：处理pre-if阶段允许输出信号****************/
/***************lab4修改：处理允许传递到if信号****************/
//源代码：assign to_fs_valid     = ~reset;
assign to_fs_valid     = ~reset & pre_if_ready_go;
/***************lab4修改：处理允许传递到if信号****************/
assign seq_pc          = fs_pc + 3'h4;
assign nextpc          = br_taken ? br_target : seq_pc; 

// IF stage
assign fs_ready_go    = 1'b1;
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin; //不复位时，fs_valid为1
assign fs_to_ds_valid =  fs_valid && fs_ready_go;
always @(posedge clk) begin
    if (reset) begin
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;
    end

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  //trick: to make nextpc be 0xbfc00000 during reset 
    end
    else if (to_fs_valid && fs_allowin) begin
        fs_pc <= nextpc;
    end
end

/**********************lab4修改：处理inst-sram使能信号*************************/
//源代码：assign inst_sram_en    = to_fs_valid && fs_allowin;
assign inst_sram_en    = to_fs_valid && fs_allowin && ~br_stall;
/**********************lab4修改：处理inst-sram使能信号*************************/
assign inst_sram_wen   = 4'h0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;

assign fs_inst         = inst_sram_rdata;

endmodule
