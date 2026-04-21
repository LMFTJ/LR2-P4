/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "macro.p4"

// Register<bit<32>,bit<1>>(size=1,initial_value=0) qdepth_reg;
// RegisterAction<bit<32>,bit<1>,bit<32>>(qdepth_reg) qdepth_reg_action={
//     void apply(inout bit<32>value,out bit<32> result){
//         value=(bit<32>)eg_md.qdepth;
//         result=value;
//     }
// };

// Register<bit<32>,bit<1>>(size=1,initial_value=0) nack_count_reg;
// RegisterAction<bit<32>,bit<1>,bit<32>>(nack_count_reg) nack_count_reg_action={
//     void apply(inout bit<32>value,out bit<32> result){
//         value=value+1;
//         result=value;
//     }
// };

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