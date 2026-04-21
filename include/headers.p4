#ifndef _HEADERS_
#define _HEADERS_
#include "macro.p4"

typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;
const pkt_type_t PKT_TYPE_MIRROR_2 =3;

#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;
const mirror_type_t MIRROR_TYPE_I2E_2 =3;

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0801;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}
header mirror_h {
    pkt_type_t pkt_type;
    bit<32> nack_seq;
    bit<32> nack_num;
}

@flexible
header mirror_bridged_metadata_h {
    pkt_type_t pkt_type;
}

struct header_t {
    mirror_bridged_metadata_h bridged_md;
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;

    // Add more headers here.
}
struct pair {
    bit<32>     first;
    bit<32>     second;
}

struct ingress_metadata_t {
    bit<32> flow_idx;
    bit<12> hash_idx;
    ipv4_addr_t addr_1; //calculate hash_idx for data or ack/nack
    ipv4_addr_t addr_2;
    mac_addr_t mac_addr_1;
    mac_addr_t mac_addr_2;
    bit<16> app_port;   //determine flow

    bit<32> seq;
    bit<32> seq_reg;
    bit<32> recir_seq_reg;
    bit<32> dif_seq;
    bit<32> seq_compare;
    bit<32> ret_state;

    bit<32> ack_compare_result;
    bit<32> nack_seq;
    bit<32> nack_compare_result;
    
    bit<32> ret_result;

    PortId_t port_id;
    QueueId_t queue_id;

    bit<32> nack_reg_value;
    // bit<19> qdepth;

    bit<32> used_buffer;

    //mirror
    MirrorId_t ing_mir_ses; //ingress mirror session ID
    pkt_type_t pkt_type;
}

struct egress_metadata_t {
    ipv4_addr_t addr_1; //calculate hash_idx for data or ack/nack
    ipv4_addr_t addr_2;
    mac_addr_t mac_addr_1;
    mac_addr_t mac_addr_2;
    
    bit<32> nack_seq;   //for mirror
    bit<32> ret_result;

    //mirror
    pkt_type_t pkt_type;

    bit<19> qdepth;
}
struct empty_header_t {}

struct empty_metadata_t {}
#endif /* _HEADERS_ */
