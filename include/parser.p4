#include "macro.p4"
#include "util.p4"
// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;

    state start {
        ig_md.flow_idx=0;
        ig_md.hash_idx=0;
        ig_md.addr_1=0;
        ig_md.addr_2=0;
        ig_md.mac_addr_1=0;
        ig_md.mac_addr_2=0;
        ig_md.app_port=0;

        ig_md.seq=0;
        ig_md.seq_reg=0;
        ig_md.recir_seq_reg=0;
        ig_md.dif_seq=0;
        ig_md.seq_compare=0;
        ig_md.ret_state=0;
        ig_md.ack_compare_result=0;
        ig_md.nack_seq=0;
        ig_md.nack_compare_result=0;

        ig_md.ret_result=0;

        ig_md.port_id=0;
        ig_md.queue_id=0;

        ig_md.nack_reg_value=0;

        ig_md.used_buffer=0;

        ig_md.ing_mir_ses=0;
        ig_md.pkt_type=0;

        tofino_parser.apply(pkt,ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_ipv4;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            IP_PROTOCOLS_TCP:parse_tcp;
            IP_PROTOCOLS_UDP:parse_udp;
            default:accept;
        }
    }
    state parse_tcp{
        pkt.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp{
        pkt.extract(hdr.udp);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;
    Checksum() ipv4_checksum;

    apply {
        if(ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E){
            mirror.emit<mirror_h>(ig_md.ing_mir_ses,{ig_md.pkt_type,ig_md.recir_seq_reg,ig_md.ret_result});    //carry the expected seq/reg value
        }else if(ig_dprsr_md.mirror_type==MIRROR_TYPE_I2E_2){
            mirror.emit<mirror_h>(ig_md.ing_mir_ses,{ig_md.pkt_type,ig_md.seq_reg,ig_md.ret_result});
        }

        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});

         pkt.emit(hdr);
    }
}

parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        eg_md.addr_1=0;
        eg_md.addr_2=0;
        eg_md.mac_addr_1=0;
        eg_md.mac_addr_2=0;

        eg_md.nack_seq=0;
        eg_md.ret_result=0;

        eg_md.pkt_type=0;

        eg_md.qdepth=0;

        pkt.extract(eg_intr_md);
        transition parse_metadata;
    }

    state parse_metadata{
        mirror_h mirror_md=pkt.lookahead<mirror_h>();
        eg_md.pkt_type=mirror_md.pkt_type;  //pkt type
        transition select(mirror_md.pkt_type){
            PKT_TYPE_MIRROR:parse_mirror_md;
            PKT_TYPE_MIRROR_2:parse_mirror_md;
            PKT_TYPE_NORMAL:parse_bridged_md;
            default:accept;
        }
    }

    state parse_mirror_md{
        mirror_h mirror_md;
        pkt.extract(mirror_md);
        eg_md.nack_seq=mirror_md.nack_seq;
        eg_md.ret_result=mirror_md.nack_num;
        transition parse_ethernet;
    }

    state parse_bridged_md{
        mirror_bridged_metadata_h bridged_md;
        pkt.extract(bridged_md);    //set invalid
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_ipv4;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            IP_PROTOCOLS_TCP:parse_tcp;
            IP_PROTOCOLS_UDP:parse_udp;
            default:accept;
        }
    }
    state parse_tcp{
        pkt.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp{
        pkt.extract(hdr.udp);
        transition accept;
    }
}

control SwitchEgressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in egress_metadata_t eg_md,
    // in egress_intrinsic_metadata_t eg_intr_md,  //error
    // in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr
    in egress_intrinsic_metadata_for_deparser_t eg_dprse_md

    ) {
    apply {
        pkt.emit(hdr);
    }
}
