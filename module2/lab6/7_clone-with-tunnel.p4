#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4     = 0x0800;
const bit<16> TYPE_MYTUNNEL = 0x1212;   // EtherType custom per il tunnel

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

struct intrinsic_metadata_t {
    bit<4>  mcast_grp;
    bit<4>  egress_rid;
    bit<16> mcast_hash;
    bit<32> lf_field_list;
}

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header myTunnel_t {
    bit<16> proto_id;
    bit<16> dst_id;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    intrinsic_metadata_t intrinsic_metadata;
}

struct headers {
    ethernet_t ethernet;
    myTunnel_t myTunnel;
    ipv4_t     ipv4;
}

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4:     parse_ipv4;
            TYPE_MYTUNNEL: parse_myTunnel;
            default:       accept;
        }
    }

    state parse_myTunnel {
        packet.extract(hdr.myTunnel);
        transition select(hdr.myTunnel.proto_id) {
            TYPE_IPV4: parse_ipv4;
            default:   accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

control ingress(inout headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    /* ---------- AZIONI ---------- */

    action drop() {
        mark_to_drop();
    }

    action forward(egressSpec_t port) {
        standard_metadata.egress_spec = port;
    }

    action set_nhop(macAddr_t dstAddr, egressSpec_t port) {
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    /* INCAPSULAMENTO */
    action encap_tunnel(bit<16> dst_id, egressSpec_t port) {
        hdr.myTunnel.setValid();
        hdr.myTunnel.proto_id = TYPE_IPV4;
        hdr.myTunnel.dst_id   = dst_id;

        hdr.ethernet.etherType = TYPE_MYTUNNEL;
        standard_metadata.egress_spec = port;
    }

    /* ---------- TABELLE ---------- */

    // Forward normale
    table ipv4_forward {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            forward;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    // Incapsulamento (edge switch)
    table tunnel_encap {
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        actions = {
            encap_tunnel;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    // Forward tunnel
    table tunnel_forward {
        key = {
            hdr.myTunnel.dst_id: exact;
        }
        actions = {
            forward;
            drop;
        }
        size = 1024;
        default_action = drop();
    }

    apply {

        /* 🚇 PACCHETTI TUNNEL */
        if (hdr.myTunnel.isValid()) {
            tunnel_forward.apply();
        }

        /* 📦 PACCHETTI IPv4 NORMALI */
        else if (hdr.ipv4.isValid()) {

            // prova a incapsulare (edge)
            tunnel_encap.apply();

            // se NON incapsulato → forwarding normale
            if (!hdr.myTunnel.isValid()) {
                ipv4_forward.apply();
            }
        }
    }
}

control egress(inout headers hdr,
               inout metadata meta,
               inout standard_metadata_t standard_metadata) {
    apply {}
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);

        if (hdr.myTunnel.isValid()) {
            packet.emit(hdr.myTunnel);
        }

        if (hdr.ipv4.isValid()) {
            packet.emit(hdr.ipv4);
        }
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

V1Switch(
    ParserImpl(),
    verifyChecksum(),
    ingress(),
    egress(),
    computeChecksum(),
    DeparserImpl()
) main;