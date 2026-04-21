#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

control swap_addr(
    inout header_t hdr,
    inout egress_metadata_t eg_md
){
    apply{
        eg_md.mac_addr_1=hdr.ethernet.src_addr;
        eg_md.mac_addr_2=hdr.ethernet.dst_addr;
        eg_md.addr_1=hdr.ipv4.src_addr;
        eg_md.addr_2=hdr.ipv4.dst_addr;
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_oport_md){
#include "egress_registers.p4"
#include "egress_actions.p4"
    apply{
        // eg_md.qdepth=eg_intr_md.enq_qdepth;
        // qdepth_reg_action.execute(0);//
        if(eg_md.pkt_type==PKT_TYPE_NORMAL){
            ;
        }else if(eg_md.pkt_type==PKT_TYPE_MIRROR){
            // nack_count_reg_action.execute(0);
            if(hdr.tcp.flags==0x11){    //nack
                nack_construct_NACK();
                // debug_reg1_action.execute(0);
            }else{                      //data
                swap_addr.apply(hdr,eg_md);
                data_construct_NACK();
                // debug_reg1_action.execute(0);
            }
            
        }else if(eg_md.pkt_type==PKT_TYPE_MIRROR_2){
            // debug_reg1_action.execute(0);
            ;   //no need to change
        }
        else{
            ;   //unkonwn pkt type!
        }
    }
}