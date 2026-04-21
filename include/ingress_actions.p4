/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif


#include "macro.p4"
action init_md(){
    ;
}

action set_normal_pkt(){        //for egress parser
    hdr.bridged_md.setValid();
    hdr.bridged_md.pkt_type=PKT_TYPE_NORMAL;
}

action forward_port(PortId_t pid) {
    set_normal_pkt();
    ig_tm_md.ucast_egress_port = pid;
}

action drop(bit<3> ctl) {
    ig_dprsr_md.drop_ctl = ctl; // Drop packet.
}

action recir(PortId_t pid){
    set_normal_pkt();
    ig_tm_md.ucast_egress_port=pid;
}
action nop() {}

Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_crc32;
action get_hash_flow_idx() {
    ig_md.flow_idx = (bit<32>)hash_crc32.get({ ig_md.addr_1, ig_md.addr_2,ig_md.app_port});
    // ig_md.flow_idx = ig_md.flow_idx |+| 1;
}

action forward_queue(QueueId_t qid) {
    ig_tm_md.qid=qid;
}

Hash<bit<QID_WIDTH>>(HashAlgorithm_t.CRC8) hash_crc8;
action allocate_queue(){//for recir
    ig_md.queue_id= (QueueId_t)hash_crc8.get({ ig_md.addr_1, ig_md.addr_2,ig_md.app_port});
    // ig_md.queue_id= ig_md.queue_id+(QueueId_t)(QID_OFFSET);
}

action mirror_to_trigger_NACK(MirrorId_t ing_ses){
    ig_dprsr_md.mirror_type=MIRROR_TYPE_I2E;
    ig_md.ing_mir_ses=ing_ses;      //for dprsr
    ig_md.pkt_type=PKT_TYPE_MIRROR; //for dprsr
}

action mirror_to_send(MirrorId_t ing_ses){
    ig_dprsr_md.mirror_type=MIRROR_TYPE_I2E_2;
    ig_md.ing_mir_ses=ing_ses;
    ig_md.pkt_type=PKT_TYPE_MIRROR_2;
}

action do_dif_action(){
    ig_md.dif_seq=ig_md.seq-ig_md.seq_reg;
}
