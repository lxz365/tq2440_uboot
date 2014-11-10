/*
 * (C) Copyright 2000-2012
 *
 * (C) Copyright 2012 luoqindong <luoqindong123@163.com>

 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */


#include <common.h>
#include <asm/setup.h>
#include <asm/mach-types.h>
#include <asm/proc/system.h>


#define LINUX_KERNEL_OFFSET			0x8000
#define LINUX_PARAM_OFFSET			0x100
#define LINUX_PAGE_SIZE				0x00001000
#define LINUX_PAGE_SHIFT			12
#define LINUX_ZIMAGE_MAGIC			0x016f2818
#define	SDRAM_START					0x30000000
#define SDRAM_SIZE					0x04000000

typedef 	void (*boot_linux_t)(ulong, ulong, ulong);

int nand_read_ll(unsigned char *buf, unsigned long start_addr, int size);
extern int nand_read_ll_lcd(unsigned char*, unsigned long, int);


/*
 * clean and invalidate I & D cache
 */
static __inline void cpu_arm920_cache_clean_invalidate_all(void)
{
	unsigned long r1, r3;
	__asm{
		mov		r1, #0		
		mov		r1, #7 << 5			  	/* 8 segments */
cache_clean_loop1:		
		orr		r3, r1, #63UL << 26	  	/* 64 entries */
cache_clean_loop2:	
		mcr		p15, 0, r3, c7, c14, 2	/* clean & invalidate D index */
		subs	r3, r3, #1 << 26
		bcs		cache_clean_loop2		/* entries 64 to 0 */
		subs	r1, r1, #1 << 5
		bcs		cache_clean_loop1		/* segments 7 to 0 */
		mcr		p15, 0, r1, c7, c5, 0	/* invalidate I cache */
		mcr		p15, 0, r1, c7, c10, 4	/* drain WB */
	}
}

/*
 * clean and invalidate I & D cache
 */
void cache_clean_invalidate(void)
{
	cpu_arm920_cache_clean_invalidate_all();
}

/*
 * invalidate I & D TLBs
 */
static __inline void cpu_arm920_tlb_invalidate_all(void)
{
	unsigned long r0;

	__asm{
		mov	r0, #0
		mcr	p15, 0, r0, c7, c10, 4	/* drain WB */
		mcr	p15, 0, r0, c8, c7, 0	/* invalidate I & D TLBs */
	}
}

/*
 * invalidate mmu table entry
 */
void tlb_invalidate(void)
{
	cpu_arm920_tlb_invalidate_all();
}

/*
 * clean and invalidate I & D cache ,mmu table, and then boot linux zImage
 * a0	must be zero
 * a1	machine type
 * a2   linux zImage addr
 */
void  call_linux(ulong a0, ulong a1, ulong a2)
{
	ulong ip;
	boot_linux_t boot_linux = (boot_linux_t)a2;

 	local_irq_disable();
	cache_clean_invalidate();
	tlb_invalidate();

	__asm
	{
		mov	ip, #0
		mcr	p15, 0, ip, c13, c0, 0		/* zero PID 				*/
		mcr	p15, 0, ip, c7, c7, 0		/* invalidate I,D caches 	*/
		mcr	p15, 0, ip, c7, c10, 4		/* drain write buffer 		*/
		mcr	p15, 0, ip, c8, c7, 0		/* invalidate I,D TLBs 		*/
		mrc	p15, 0, ip, c1, c0, 0		/* get control register 	*/
		bic	ip, ip, #0x0001				/* disable MMU 				*/
		mcr	p15, 0, ip, c1, c0, 0		/* write control register 	*/
	}

	boot_linux(a0, a1, a2);
}


/*
 * set linux command line argument
 * pram_base: base address of linux paramter
 */
static void setup_linux_param(ulong param_base)
{
	struct param_struct *params = (struct param_struct *)param_base; 
	char *linux_cmd;

	memset(params, 0, sizeof(struct param_struct));

	params->u1.s.page_size = LINUX_PAGE_SIZE;
	params->u1.s.nr_pages = (SDRAM_SIZE >> LINUX_PAGE_SHIFT);

	/* set linux command line */
	linux_cmd = getenv ("bootargs");
	if (linux_cmd == NULL) {
		printf("Wrong magic: could not found linux command line\n");
	} else {
		memcpy(params->commandline, linux_cmd, strlen(linux_cmd) + 1);
	}
}

/*
 * boot zImage
 * setup linux parameter , command line, and the boot linux from addr 
 * addr : base address of linux zImage
 */
int boot_zimage(ulong addr)
{
	int ret __attribute__((unused));
	ulong boot_mem_base;	/* base address of bootable memory 嘎唱? */
	ulong to;
	ulong mach_type;

	boot_mem_base = SDRAM_START;
	to = addr;

	if (*(ulong *)(to + 9*4) != LINUX_ZIMAGE_MAGIC) {
		printf("Warning: this binary is not compressed linux kernel image\n");
		printf("zImage magic = 0x%08lx\n", *(ulong *)(to + 9*4));
	} else {
		printf("zImage magic = 0x%08lx\n", *(ulong *)(to + 9*4));
	}

	/* Setup linux parameters and linux command line */
	setup_linux_param(boot_mem_base + LINUX_PARAM_OFFSET);

	/* Get machine type */
	mach_type = MACH_TYPE_TQ2440;

	printf("\nnow, booting linux......\n");	
	call_linux(0, mach_type, to);

	return 0;	
}

int do_boot_zimage (cmd_tbl_t *cmdtp, int flag, int argc, char *argv[])
{
	ulong boot_addr;

	if (argc < 2) {
		printf ("Usage:\n%s\n", cmdtp->usage);
		return 1;
	}

	boot_addr = simple_strtoul(argv[1], NULL, 16);
	printf ("## Starting linux at 0x%08lX ...\n", boot_addr);
    boot_zimage(boot_addr);
    return 0;

}

U_BOOT_CMD(
	boot_zimage, 2,	0, do_boot_zimage,
	"boot_zimage - boot Linux's zImage from ram\n",
	"addr \n"
	" - boot linux's zImage from ram addr\n"
);

