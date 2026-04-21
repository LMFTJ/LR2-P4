/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "macro.p4"

table forward_ACK {
    key = {
        hdr.ipv4.src_addr:exact;
        hdr.ipv4.dst_addr:exact;
    }
    actions = { forward_port; nop; }

    size = 8;
}
table forward_NAK {
    key = {
        hdr.ipv4.src_addr:exact;
        hdr.ipv4.dst_addr:exact;
    }
    actions = { forward_port; nop; }

    size = 8;
}
table forward_DATA {
    key = {
        hdr.ipv4.src_addr:exact;
        hdr.ipv4.dst_addr:exact;
    }
    actions = { forward_port; nop; }

    size = 8;
}

table recir_DATA {
    key = {
        ig_md.hash_idx[0:0]: exact;
    }
    actions = { recir; nop; }

    size = 2;
}

table mirror_NAK{
        key = {
        hdr.ipv4.src_addr:exact;
        hdr.ipv4.dst_addr:exact;
    }
    actions = { mirror_to_trigger_NACK; nop; }

    size = 8;
}