/***********************************************************************\
*                                reason.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module core.sys.windows.reason;

private import core.sys.windows.w32api, core.sys.windows.windef;

static assert (_WIN32_WINNT >= 0x501,
  "core.sys.windows.reason is only available on WindowsXP and later");


enum : DWORD {
	SHTDN_REASON_MAJOR_OTHER           = 0x00000000,
	SHTDN_REASON_MAJOR_HARDWARE        = 0x00010000,
	SHTDN_REASON_MAJOR_OPERATINGSYSTEM = 0x00020000,
	SHTDN_REASON_MAJOR_SOFTWARE        = 0x00030000,
	SHTDN_REASON_MAJOR_APPLICATION     = 0x00040000,
	SHTDN_REASON_MAJOR_SYSTEM          = 0x00050000,
	SHTDN_REASON_MAJOR_POWER           = 0x00060000,
	SHTDN_REASON_MAJOR_LEGACY_API      = 0x00070000
}

enum : DWORD {
	SHTDN_REASON_MINOR_OTHER,
	SHTDN_REASON_MINOR_MAINTENANCE,
	SHTDN_REASON_MINOR_INSTALLATION,
	SHTDN_REASON_MINOR_UPGRADE,
	SHTDN_REASON_MINOR_RECONFIG,
	SHTDN_REASON_MINOR_HUNG,
	SHTDN_REASON_MINOR_UNSTABLE,
	SHTDN_REASON_MINOR_DISK,
	SHTDN_REASON_MINOR_PROCESSOR,
	SHTDN_REASON_MINOR_NETWORKCARD,
	SHTDN_REASON_MINOR_POWER_SUPPLY,
	SHTDN_REASON_MINOR_CORDUNPLUGGED,
	SHTDN_REASON_MINOR_ENVIRONMENT,
	SHTDN_REASON_MINOR_HARDWARE_DRIVER,
	SHTDN_REASON_MINOR_OTHERDRIVER,
	SHTDN_REASON_MINOR_BLUESCREEN,
	SHTDN_REASON_MINOR_SERVICEPACK,
	SHTDN_REASON_MINOR_HOTFIX,
	SHTDN_REASON_MINOR_SECURITYFIX,
	SHTDN_REASON_MINOR_SECURITY,
	SHTDN_REASON_MINOR_NETWORK_CONNECTIVITY,
	SHTDN_REASON_MINOR_WMI,
	SHTDN_REASON_MINOR_SERVICEPACK_UNINSTALL,
	SHTDN_REASON_MINOR_HOTFIX_UNINSTALL,
	SHTDN_REASON_MINOR_SECURITYFIX_UNINSTALL,
	SHTDN_REASON_MINOR_MMC,         // = 0x00000019
	SHTDN_REASON_MINOR_TERMSRV         = 0x00000020
}

enum : DWORD {
	SHTDN_REASON_FLAG_USER_DEFINED     = 0x40000000,
	SHTDN_REASON_FLAG_PLANNED          = 0x80000000
}
