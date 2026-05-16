*********************************************************
## Paper title：LR2: Accelerating Long-Distance RDMA Recovery via In-Network retransmission Decoupling
### Published conference: IEEE INFOCOM 2026
*********************************************************

### Introduction

This is an open P4-based pragrammable program for conference paper.

ASIC architecture: `Tofino 1`

SDE: `bf-sde-9.2.0`


### Directory Structure

The entire processing logic of the P4 program is modularized and stored within the `include` folder:

* **`main.p4`**: The top-level configuration file of the pipeline, which sequentially declares and assembles the complete Parser, SwitchIngress, SwitchEgress, and Deparser.
* **`include/headers.p4`**: Defines the protocol headers of network packets (Ethernet, VLAN, IPv4, TCP, UDP, etc.), as well as custom metadata structures (e.g., `ingress_metadata_t`, `egress_metadata_t`, and `mirror_h`) used to pass information between different stages of the pipeline.
* **`include/parser.p4`**: Contains the packet extraction state machines for both ingress and egress stages. In addition to parsing regular data headers, it can specifically identify and parse mirrored packets and recirculated packets triggered internally by the system.
* **`include/ingress.p4`**: Implements the core forwarding logic for data packets. The module first calculates the flow index via a hash function, then accesses stateful registers to verify the packet sequence, and finally executes normal forwarding, active dropping, or triggers NACK mirroring based on the matching results.
* **`include/ingress_registers.p4`**: Defines all the Stateful ALUs required by the system. These hardware registers are utilized to maintain key states such as sequence numbers (`seq_reg`), ACK records (`ack_seq_reg`), and recirculation pointers (`recir_seq_reg`) during high-speed forwarding.
* **`include/egress.p4`**: Controls the logic of the egress pipeline. Its key processing logic involves intercepting mirrored packets sent from the Ingress and modifying the relevant headers to "disguise" them as NACK control signals sent by the receiver.
* **`include/ingress_tables.p4`**: Defines the fundamental packet forwarding match tables (e.g., `forward_DATA`, `forward_ACK`, `forward_NAK`) to assign the correct output ports for the processed packets.
