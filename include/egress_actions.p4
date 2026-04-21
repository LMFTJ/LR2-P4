/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "macro.p4"

action nack_construct_NACK(){    //mirror pkt -> NACK
    hdr.tcp.ack_no=eg_md.nack_seq;

}

action data_construct_NACK(){    //mirror pkt -> NACK
    hdr.tcp.flags=0x11;
    hdr.tcp.ack_no=eg_md.nack_seq;
    hdr.tcp.seq_no=eg_md.ret_result;
    hdr.tcp.dst_port=hdr.tcp.src_port;
    
    //swap ether and ip addr
    hdr.ipv4.dst_addr=eg_md.addr_1;
    hdr.ethernet.dst_addr=eg_md.mac_addr_1;
    hdr.ipv4.src_addr=eg_md.addr_2;
    hdr.ethernet.src_addr=eg_md.mac_addr_2;
}