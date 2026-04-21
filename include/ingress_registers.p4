/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "macro.p4"

Register<bit<32>, bit<12>>(size=1<<12,initial_value=1) seq_reg;         //record the data-pkt seq
RegisterAction<bit<32>, bit<12>, bit<32>>(seq_reg) seq_get= {
    void apply(inout bit<32> value, out bit<32> result){
        result=value;
        if(ig_md.seq==value){
            value=value+1;
        }
    }
};
RegisterAction<bit<32>, bit<12>, bit<32>>(seq_reg) back_seq_reg= {
    void apply(inout bit<32> value){
        value=ig_md.seq+1;
    }
};
action do_back_seq_reg(){
    back_seq_reg.execute(ig_md.hash_idx);
}
RegisterAction<bit<32>, bit<12>, bit<32>>(seq_reg) nack_compare_reg= {       //to filter NACK
    void apply(inout bit<32> value,out bit<32> result){
        if(ig_md.nack_seq>value){
            result = 1;
        }else{
            result = 0;
        }
    }
};
action do_compare_nack_seq(){
    ig_md.nack_compare_result=nack_compare_reg.execute(ig_md.hash_idx);
}

Register<bit<32>, bit<12>>(size=1<<12,initial_value=0) ack_seq_reg;         //record the data-pkt seq
RegisterAction<bit<32>, bit<12>, bit<32>>(ack_seq_reg) ack_seq_record= {
    void apply(inout bit<32> value){
        value=hdr.tcp.ack_no;
    }
};
RegisterAction<bit<32>, bit<12>, bit<32>>(ack_seq_reg) ack_seq_compare= {
    void apply(inout bit<32> value,out bit<32> result){
        if(ig_md.seq>value){
            result=0;
        }else{
            result=1;
        }
    }
};
action do_record_ack_seq(){
    ack_seq_record.execute(ig_md.hash_idx);
}
action do_compare_ack_seq(){
    ig_md.ack_compare_result=ack_seq_compare.execute(ig_md.hash_idx);
}


Register<bit<32>, bit<12>>(size=1<<12,initial_value=1) recir_seq_reg;         //record the data-pkt seq
RegisterAction<bit<32>, bit<12>, bit<32>>(recir_seq_reg) incre_recir_seq= {
    void apply(inout bit<32> value){
        if(ig_md.seq>value || ig_md.seq==value){
            value=value+1;
        }
        //else: ret-pkt
    }
};
RegisterAction<bit<32>, bit<12>, bit<32>>(recir_seq_reg) update_recir_seq= {
    void apply(inout bit<32> value, out bit<32> result){
        if(ig_md.seq>value || ig_md.seq==value){
            // result=ig_md.seq-value;
            result=value;
            value=ig_md.seq+1;
        }else{
            result=0;
        }
    }
};

// Register<bit<32>, bit<1>>(size=1,initial_value=0) used_buffer_reg;         //record the data-pkt seq
// RegisterAction<bit<32>, bit<1>, bit<32>>(used_buffer_reg) incre_used_recir_buffer= {
//     void apply(inout bit<32> value){
//         value=value+1;
//     }
// };
// RegisterAction<bit<32>, bit<1>, bit<32>>(used_buffer_reg) reduce_used_recir_buffer= {
//     void apply(inout bit<32> value,out bit<32> result){
//         value=value-1;
//         result=value;
//     }
// };
// RegisterAction<bit<32>, bit<1>, bit<32>>(used_buffer_reg) get_used_recir_buffer= {
//     void apply(inout bit<32> value,out bit<32> result){
//         result=value;
//     }
// };



Register<bit<32>, bit<1>>(size=1,initial_value=1) seq_compare;         //compare the size of seq and seq_reg
RegisterAction<bit<32>, bit<1>, bit<32>>(seq_compare) seq_compare_action= {
    void apply(inout bit<32> value, out bit<32> result){
        if(ig_md.dif_seq<MAX_VALUE){    //1:>;0:<
            result=1;
        }else{
            result=0;
        }
    }
};

Register<bit<32>, bit<12>>(size=1<<12,initial_value=0) ret_state_reg;         //ret state
RegisterAction<bit<32>, bit<12>, bit<32>>(ret_state_reg) reset_ret_state= {
    void apply(inout bit<32> value){
        value=0;
    }
};
RegisterAction<bit<32>, bit<12>, bit<32>>(ret_state_reg) set_ret_state= {
    void apply(inout bit<32> value, out bit<32> result){
        result=value;
        if(ig_md.seq_compare==1){
            value=1;
        }
        
    }
};
// RegisterAction<bit<32>, bit<12>, bit<32>>(ret_state_reg) update_ret_state= {
//     void apply(inout bit<32> value, out bit<32> result){
//         result=value;
//         if(ig_md.dif_seq==0){
//             value=0;
//         }else if(ig_md.seq_compare==1){
//             value=1;
//         }
//     }
// };
action do_reset_ret_state(){
    reset_ret_state.execute(ig_md.hash_idx);
}
action do_set_ret_state(){
    ig_md.ret_state=set_ret_state.execute(ig_md.hash_idx);
}
// action do_update_ret_state(){
//     ig_md.ret_state=update_ret_state.execute(ig_md.hash_idx);
// }

Register<pair, bit<12>>(size=1<<12) nack_seq_reg;    //record the NACK seq
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg) nack_seq_record= {
    void apply(inout pair value, out bit<32> result){
        if(value.first==0){
            result=0;
            value.first=ig_md.nack_seq;
            value.second=ig_md.seq;
        }else{
            result=1;   //error: exceed
        }
    }
};
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg) nack_seq_read= {
    void apply(inout pair value, out bit<32> result){
        if(ig_md.seq==value.first){
            result=0;
            if(value.second==1){  //ok
                value.first=0;
                value.second=0;
            }else{
                value.first=value.first+1;
                value.second=value.second-1;
            }     
        }else{
            result=1;
        }
    }
};
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg) nack_seq_reset= {
    void apply(inout pair value){
        value.first=0;
        value.second=0;
    }
};
Register<pair, bit<12>>(size=1<<12) nack_seq_reg2;    //record the NACK seq
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg2) nack_seq2_record= {
    void apply(inout pair value, out bit<32> result){
        if(value.first==0){
            result=0;
            value.first=ig_md.nack_seq; //record the NACK no 
            value.second=ig_md.seq;
        }else{
            result=1;   //error: exceed
        }
    }
};
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg2) nack_seq2_read= {
    void apply(inout pair value, out bit<32> result){
        if(ig_md.seq==value.first){
            result=0;
            if(value.second==1){  //ok
                value.first=0;
                value.second=0;
            }else{
                value.first=value.first+1;
                value.second=value.second-1;
            }
        }else{
            result=1;
        }
    }
};
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg2) nack_seq2_reset= {
    void apply(inout pair value){
        value.first=0;
        value.second=0;
    }
};
Register<pair, bit<12>>(size=1<<12) nack_seq_reg3;    //record the NACK seq
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg3) nack_seq3_record= {
    void apply(inout pair value, out bit<32> result){
        if(value.first==0){
            result=0;
            value.first=ig_md.nack_seq; //record the NACK no 
            value.second=ig_md.seq;
        }else{
            result=1;   //error: exceed
        }
    }
};
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg3) nack_seq3_read= {
    void apply(inout pair value, out bit<32> result){
        if(ig_md.seq==value.first){
            result=0;
            if(value.second==1){  //ok
                value.first=0;
                value.second=0;
            }else{
                value.first=value.first+1;
                value.second=value.second-1;
            }
        }else{
            result=1;
        }
    }
};
RegisterAction<pair, bit<12>, bit<32>>(nack_seq_reg3) nack_seq3_reset= {
    void apply(inout pair value){
        value.first=0;
        value.second=0;
    }
};
action do_read_nack_reg(){
    ig_md.nack_reg_value=nack_seq_read.execute(ig_md.hash_idx);
}
action do_read_nack_reg2(){
    ig_md.nack_reg_value=nack_seq2_read.execute(ig_md.hash_idx);
}
action do_read_nack_reg3(){
    ig_md.nack_reg_value=nack_seq3_read.execute(ig_md.hash_idx);
}
action do_record_nack_reg(){
    ig_md.nack_reg_value=nack_seq_record.execute(ig_md.hash_idx);
}
action do_record_nack_reg2(){
    ig_md.nack_reg_value=nack_seq2_record.execute(ig_md.hash_idx);
}
action do_record_nack_reg3(){
    ig_md.nack_reg_value=nack_seq3_record.execute(ig_md.hash_idx);
}

Register<bit<1>,bit<1>>(size=1,initial_value=0) error_reg;
RegisterAction<bit<1>,bit<1>,bit<1>>(error_reg) error_reg_action={
    void apply(inout bit<1>value,out bit<1> result){
        value=1;
        result=value;
    }
};


// Register<bit<32>,bit<1>>(size=1,initial_value=0) debug_reg1;
// RegisterAction<bit<32>,bit<1>,bit<32>>(debug_reg1) debug_reg1_action={
//     void apply(inout bit<32>value,out bit<32> result){
//         value=value+1;
//         result=value;
//     }
// };

// Register<bit<32>,bit<1>>(size=1,initial_value=0) debug_reg2;
// RegisterAction<bit<32>,bit<1>,bit<32>>(debug_reg2) debug_reg2_action={
//     void apply(inout bit<32>value,out bit<32> result){
//         value=value+1;
//         result=value;
//     }
// };

// Register<bit<32>,bit<1>>(size=1,initial_value=0) debug_reg3;
// RegisterAction<bit<32>,bit<1>,bit<32>>(debug_reg3) debug_reg3_action={
//     void apply(inout bit<32>value,out bit<32> result){
//         value=value+1;
//         result=value;
//     }
// };