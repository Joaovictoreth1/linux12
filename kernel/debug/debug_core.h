/* SPDX-License-Identifier: GPL-2.0-only /
/

debug_core.h - Private implementation headers between the kernel

           debugger core and the debugger front end code.


Created by: Jason Wessel jason.wessel@windriver.com

Copyright (c) 2009 Wind River Systems, Inc. All Rights Reserved.
*/

#ifndef DEBUG_CORE_H
#define DEBUG_CORE_H

/* STREAMING_CHUNK:Forward declarations and core structures... */
struct pt_regs;
struct task_struct;

/

struct kgdb_state - Describes the current state of a KGDB debug session

@ex_vector:		Exception vector number

@signo:		Signal number corresponding to the exception

@err_code:		Error code associated with the exception

@cpu:		CPU number where the exception occurred

@pass_exception:	Flag to indicate if exception should be passed on

@thr_query:		Thread query state

@threadid:		Current thread ID for the debug session

@kgdb_usethreadid:	KGDB specific thread ID usage

@linux_regs:		Pointer to CPU registers at the time of exception

@send_ready:		Atomic flag to indicate readiness to send/receive data
*/
struct kgdb_state {
int			ex_vector;
int			signo;
int			err_code;
int			cpu;
int			pass_exception;
unsigned long		thr_query;
unsigned long		threadid;
long			kgdb_usethreadid;
struct pt_regs		*linux_regs;
atomic_t		*send_ready;
};

/* STREAMING_CHUNK:Exception states and CPU flags... /
/ Exception state values (Bitmask for CPU synchronization) /
#define DCPU_WANT_MASTER	0x1 / Waiting to become a master kgdb cpu /
#define DCPU_NEXT_MASTER	0x2 / Transition from one master cpu to another /
#define DCPU_IS_SLAVE		0x4 / Slave cpu enter exception /
#define DCPU_WANT_BT		0x8 / Slave cpu should backtrace then clear flag */

/

struct debuggerinfo_struct - Core debugger state tracking per-CPU

@debuggerinfo:	Pointer to architecture-specific debug information

@task:		Pointer to the current task struct

@exception_state:	Current state of the CPU (uses DCPU_* flags)

@ret_state:		Return state from the debugger

@irq_depth:		Depth of the IRQ stack at the time of entry

@enter_kgdb:		Flag to signal entry into KGDB

@rounding_up:	Internal flag for transition logic
*/
struct debuggerinfo_struct {
void			*debuggerinfo;
struct task_struct	*task;
int			exception_state;
int			ret_state;
int			irq_depth;
int			enter_kgdb;
bool			rounding_up;
};

extern struct debuggerinfo_struct kgdb_info[];

/* STREAMING_CHUNK:Kernel debug core breakpoint routines... /
/

Note: Modern Linux Kernel coding style discourages the use of 'extern'

for function declarations in headers.
*/
int dbg_remove_all_break(void);
int dbg_set_sw_break(unsigned long addr);
int dbg_remove_sw_break(unsigned long addr);
int dbg_activate_sw_breakpoints(void);
int dbg_deactivate_sw_breakpoints(void);

/* polled character access to i/o module */
int dbg_io_get_char(void);

/* STREAMING_CHUNK:GDB/KDB Interface constants and functions... /
/ stub return value for switching between the gdbstub and kdb */
#define DBG_PASS_EVENT -12345

/* Switch from one cpu to another */
#define DBG_SWITCH_CPU_EVENT -123456

/* Global state variables (extern is required here) */
extern int dbg_switch_cpu;
extern int dbg_kdb_mode;

/* gdbstub interface functions */
int gdb_serial_stub(struct kgdb_state *ks);
void gdbstub_msg_write(const char *s, int len);

/* gdbstub functions used for kdb <-> gdbstub transition */
int gdbstub_state(struct kgdb_state *ks, char *cmd);

/* STREAMING_CHUNK:Conditional compilation for KDB support... */
#ifdef CONFIG_KGDB_KDB
int kdb_stub(struct kgdb_state *ks);
int kdb_parse(const char *cmdstr);
int kdb_common_init_state(struct kgdb_state ks);
int kdb_common_deinit_state(void);
void kdb_dump_stack_on_cpu(int cpu);
#else / ! CONFIG_KGDB_KDB */
static inline int kdb_stub(struct kgdb_state ks)
{
return DBG_PASS_EVENT;
}
#endif / CONFIG_KGDB_KDB */

#endif /* DEBUG_CORE_H */
