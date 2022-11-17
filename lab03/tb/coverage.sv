module coverage(alu_bfm bfm);

import alu_pkg::*;
	
//------------------------------------------------------------------------------
// Covergroups
//------------------------------------------------------------------------------

covergroup op_cov;

    option.name = "cg_op_cov";

    all_ops : coverpoint bfm.opTbExclusive {
        // #A1 test all operations
        bins A1_single_cycle[] = {[CMD_INV_tb : CMD_SUB_tb], CMD_RST_tb};
    }
    
    all_ops_twice_a_row : coverpoint bfm.opTbExclusive{
	    // #A2 two operations in row
        bins A2_twoops[]       = ([CMD_INV_tb : CMD_SUB_tb] [* 2]);
    }
    
    rst_after_ops : coverpoint bfm.opTbExclusive{
	    // #A3 reset after all operations
	    bins A3_rst_after_ops[] = ([CMD_INV_tb : CMD_SUB_tb] => CMD_RST_tb);
    } 
    
    ops_after_rst : coverpoint bfm.opTbExclusive{
	    // #A3 reset after all operations
	    bins A4_ops_after_rst[] = (CMD_RST_tb => [CMD_INV_tb : CMD_SUB_tb]);
    }
endgroup


// Covergroup checking for min and max arguments of the ALU
covergroup zeros_or_ones_on_ops with function sample(logic [7:0] word);

    option.name = "cg_zeros_or_ones_on_ops";

    all_ops : coverpoint bfm.opTbExclusive {
        ignore_bins null_ops = {CMD_RST_tb, CMD_INV_tb, CMD_NOP_tb};
    }

    input_val: coverpoint word {
        bins zeros = {'h00};
        bins others= {['h01:'hFE]};
        bins ones  = {'hFF};
    }
    

    B_op_00_FF: cross input_val, all_ops {

        // #B1 simulate all zero input for all the operations

        bins B1_add_00          = binsof (all_ops) intersect {CMD_ADD_tb} && binsof (input_val.zeros);

        bins B1_and_00          = binsof (all_ops) intersect {CMD_AND_tb} && binsof (input_val.zeros);

        bins B1_xor_00          = binsof (all_ops) intersect {CMD_XOR_tb} && binsof (input_val.zeros);

        bins B1_or_00           = binsof (all_ops) intersect {CMD_OR_tb}  && binsof (input_val.zeros);
	    
	    bins B1_sub_00          = binsof (all_ops) intersect {CMD_SUB_tb} && binsof (input_val.zeros);

        // #B2 simulate all one input for all the operations

        bins B2_add_FF          = binsof (all_ops) intersect {CMD_ADD_tb} && binsof (input_val.ones);

        bins B2_and_FF          = binsof (all_ops) intersect {CMD_AND_tb} && binsof (input_val.ones);

        bins B2_xor_FF          = binsof (all_ops) intersect {CMD_XOR_tb} && binsof (input_val.ones);

        bins B2_or_FF           = binsof (all_ops) intersect {CMD_OR_tb}  && binsof (input_val.ones);

        bins B2_sub_FF          = binsof (all_ops) intersect {CMD_SUB_tb} && binsof (input_val.ones);


        ignore_bins others_only = binsof(input_val.others);
    }

endgroup


//------------------------------------------------------------------------------
// Coverage
//------------------------------------------------------------------------------

op_cov oc;
zeros_or_ones_on_ops z_or_o;

initial begin : coverage
    oc = new();
	z_or_o = new();
	
	fork
    forever begin : sample_ops
        @(posedge bfm.clk);
        oc.sample();
	    
    end
    
    forever begin : sample_values
	    @(posedge bfm.done);
	    foreach(bfm.inputWords[i])
		    z_or_o.sample(bfm.inputWords[i][8:1]);
    end
    join
end : coverage	
	
	
endmodule : coverage