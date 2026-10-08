/* SPDX-License-Identifier: GPL-2.0-or-later /
/

CCI cache coherent interconnect support

Copyright (C) 2013 ARM Ltd.
*/

#ifndef __LINUX_ARM_CCI_H
#define __LINUX_ARM_CCI_H

#include <linux/errno.h>
#include <linux/types.h>

#include <asm/arm-cci.h>

struct device_node;

#ifdef CONFIG_ARM_CCI
bool cci_probed(void);
#else
static inline bool cci_probed(void)
{
return false;
}
#endif

#ifdef CONFIG_ARM_CCI400_PORT_CTRL
int cci_ace_get_port(struct device_node *dn);
int cci_disable_port_by_cpu(u64 mpidr);
int __cci_control_port_by_device(struct device_node *dn, bool enable);
int __cci_control_port_by_index(u32 port, bool enable);
#else
static inline int cci_ace_get_port(struct device_node *dn)
{
return -ENODEV;
}

static inline int cci_disable_port_by_cpu(u64 mpidr)
{
return -ENODEV;
}

static inline int __cci_control_port_by_device(struct device_node *dn,
bool enable)
{
return -ENODEV;
}

static inline int __cci_control_port_by_index(u32 port, bool enable)
{
return -ENODEV;
}
#endif

void cci_enable_port_for_self(void);

/

cci_disable_port_by_device() - Disable a CCI port by device node

@dev: device node pointer
*/
#define cci_disable_port_by_device(dev) 

__cci_control_port_by_device(dev, false)

/

cci_enable_port_by_device() - Enable a CCI port by device node

@dev: device node pointer
*/
#define cci_enable_port_by_device(dev) 

__cci_control_port_by_device(dev, true)

/

cci_disable_port_by_index() - Disable a CCI port by index

@dev: port index
*/
#define cci_disable_port_by_index(dev) 

__cci_control_port_by_index(dev, false)

/

cci_enable_port_by_index() - Enable a CCI port by index

@dev: port index
*/
#define cci_enable_port_by_index(dev) 

__cci_control_port_by_index(dev, true)

#endif /* __LINUX_ARM_CCI_H */
