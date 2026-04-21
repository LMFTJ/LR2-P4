#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

control get_flow_idx(
    inout header_t hdr,
    inout ingress_metadata_t ig_md
){
    apply{
        if(hdr.tcp.flags==0x00||hdr.tcp.flags==0x01){
            ig_md.addr_1=hdr.ipv4.src_addr;
            ig_md.addr_2=hdr.ipv4.dst_addr;
            ig_md.app_port=hdr.tcp.src_port;
        }else if(hdr.tcp.flags==0x10||hdr.tcp.flags==0x11){
            ig_md.addr_1=hdr.ipv4.dst_addr;
            ig_md.addr_2=hdr.ipv4.src_addr;
            ig_md.app_port=hdr.tcp.dst_port;
        }else{}
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
#include "ingress_registers.p4"
#include "ingress_actions.p4"
#include "ingress_tables.p4"
    apply {
        
        get_flow_idx.apply(hdr,ig_md);
        get_hash_flow_idx();
        // ig_md.flow_idx=0;   //warning: flow_idx need to change!!!!!!!!!!
        ig_md.hash_idx=(bit<12>)(ig_md.flow_idx & 0xfff);
        allocate_queue();//get recir queue

        //read pkt header info

        // pkt classfy
        if((hdr.tcp.flags==0x00)&&ig_intr_md.ingress_port>IN_OR_OUT_PORT){//DATA from Inter-DC
            ig_md.seq=hdr.tcp.seq_no;
            ig_md.seq_reg=seq_get.execute(ig_md.hash_idx);
            do_dif_action();
            ig_md.seq_compare=seq_compare_action.execute(0);
            if(ig_md.dif_seq==0){
                forward_DATA.apply();   
            }else if(ig_md.seq_compare==1){
                recir_DATA.apply();
                // recir((bit<9>)RECIRC_PORT);
            }

            if(ig_intr_md.ingress_port==(bit<9>)(RECIRC_PORT) || ig_intr_md.ingress_port==(bit<9>)(RECIRC_PORT2)){ //recir process note:must be in the same pipe!!!
                if(ig_md.dif_seq==0){
                    // do_reduce_and_get_used_recir_buffer();   //recir buffer -1
                    // ig_md.used_buffer=reduce_used_recir_buffer.execute(0);
                    // hdr.tcp.ack_no=ig_md.used_buffer;       //recir buffer -> pkt
                                                            //backup
                }else{
                    if(ig_md.seq_compare==1){

                    }else{
                        drop(0x1);
                        // reduce_used_recir_buffer.execute(0); //recir buffer -1
                    }
                }
            }
            else{ //new coming data pkt
                if(ig_md.dif_seq==0){                       //in-order
                    // forward_port(136);
                    // ig_md.used_buffer=get_used_recir_buffer.execute(0);
                    // hdr.tcp.ack_no=ig_md.used_buffer;        //track  used buffer
                    incre_recir_seq.execute(ig_md.hash_idx);//update recir_register
                    // do_reset_ret_state();
                                                            //backup
                }else{
                    if(ig_md.seq_compare==1){               //out-of-order
                        //compare seq with recir_seq to decide NACK trigger
                        ig_md.recir_seq_reg=update_recir_seq.execute(ig_md.hash_idx);   //update recir_register and get last recir_register value
                        if(ig_md.recir_seq_reg!=0){                                     //seq >= recir_register
                            ig_md.ret_result=ig_md.seq-ig_md.recir_seq_reg;             //calculate difference
                        }
                        if(ig_md.ret_result!=0){                                        //seq > recir_register     
                            mirror_to_trigger_NACK(4);                                  //mirror NAK to source
                            // debug_reg1_action.execute(0);
                        }

                        // allocate_queue();//get recir queue
                        // ig_md.queue_id=(QueueId_t)1;//for test
                        ig_tm_md.qid=ig_md.queue_id;
                        // recir((bit<9>)RECIRC_PORT);

                        // incre_used_recir_buffer.execute(0); //recir buffer +1
                    }else{
                        drop(0x1);
                    }
                }
            }
        }
        else if((hdr.tcp.flags==0x00)&&ig_intr_md.ingress_port<IN_OR_OUT_PORT){     //DATA from Intra-DC
            ig_md.seq=hdr.tcp.seq_no;
            do_compare_ack_seq();                           //seq vs ack_register
            if(ig_md.ack_compare_result==1){                //retransmission pkt detected
                // do_reset_ret_state();
                // reset_ret_state.execute(ig_md.hash_idx);
                do_back_seq_reg();
                nack_seq_reset.execute(ig_md.hash_idx);     //reset ret_register
                nack_seq2_reset.execute(ig_md.hash_idx);
                nack_seq3_reset.execute(ig_md.hash_idx);
                forward_port(EGRESS_PORT);
            }else{
                ig_md.seq_reg=seq_get.execute(ig_md.hash_idx);
                do_dif_action();        //calculate the difference
                ig_md.seq_compare=seq_compare_action.execute(0);    //differ the '>' and '<'
                if(ig_md.dif_seq==0){                       //in-order
                    forward_port(EGRESS_PORT);
                    do_reset_ret_state();
                    
                }else{  //usigned type can't differ '<' and '>'
                    do_set_ret_state();     
                    if(ig_md.seq_compare==1){               //out-of-order
                        drop(0x1);
                        // do_set_ret_state();                 
                        if(ig_md.ret_state==0){
                            mirror_NAK.apply();             //mirror NAK to source
                        }
                    }else{                                  //check specific retransmited pkt triggered by NACK
                        do_read_nack_reg();
                        if(ig_md.nack_reg_value==0){
                            forward_port(EGRESS_PORT);
                            mirror_to_send(5);
                            // debug_reg2_action.execute(0);
                        }else{
                            do_read_nack_reg2();
                            if(ig_md.nack_reg_value==0){
                                forward_port(EGRESS_PORT);
                                mirror_to_send(5);
                                // debug_reg3_action.execute(0);
                            }else{
                                do_read_nack_reg3();
                                if(ig_md.nack_reg_value==0){
                                    forward_port(EGRESS_PORT);
                                    mirror_to_send(5);
                                    // debug_reg3_action.execute(0);
                                }else{
                                    drop(0x1);
                                }
                                
                            }
                        }
                    }
                }                
            }


        }
        else if(hdr.tcp.flags==0x10){                       // ACK
            do_record_ack_seq();                            //record ACK seq to check retransmission pkt
            if(ig_intr_md.ingress_port>IN_OR_OUT_PORT){
                forward_ACK.apply();                   
            }else if(ig_intr_md.ingress_port<IN_OR_OUT_PORT){
                forward_port(EGRESS_PORT);

                                                            //recover
            }else{}
        }
        else if(hdr.tcp.flags==0x11){                       //NACK
            // debug_reg1_action.execute(0);
            if(ig_intr_md.ingress_port>IN_OR_OUT_PORT){     //from Inter-DC
                ig_md.nack_seq=hdr.tcp.ack_no;
                do_compare_nack_seq();                      //nack_seq vs seq_register
                if(ig_md.nack_compare_result==1){
                    drop(0x1);
                }else{
                    ig_md.seq=hdr.tcp.seq_no;               //the ret range
                    do_record_nack_reg();                   //record the nack seq
                    if(ig_md.nack_reg_value!=0){
                        do_record_nack_reg2();
                        if(ig_md.nack_reg_value!=0){
                            do_record_nack_reg3();
                            if(ig_md.nack_reg_value!=0){
                                error_reg_action.execute(0);
                            }
                        }
                    }
                    forward_NAK.apply();                    
                }
                                                            //go back

            }else if(ig_intr_md.ingress_port<IN_OR_OUT_PORT){
                forward_port(EGRESS_PORT);
                                                            //go back
            }else{}
        }
        else{
            // error_reg_action.execute(0);                 //unkonwn packet
        }
    }
}
