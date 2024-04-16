Function Update-DeviceDrivers
{
     $UpdateDeviceDrivers = @"
using System;
using System.Runtime.InteropServices;
namespace DeviceDrivers
{
    public static class ChangeAudioDriver
    {
        public enum DIOD
        {
            None = (0),
            CANCEL_REMOVE = (0x00000004),
            // If this flag is specified and the device had been marked for pending removal, the OS cancels the pending removal. 
            INHERIT_CLASSDRVS = (0x00000002)
            //the resulting device information element inherits the class driver list, if any
        }

        public enum DICD
        {
            None = (0),
            GENERATE_ID = (0x00000001), // create unique device instance key
            INHERIT_CLASSDRVS = (0x00000002)  // inherit class driver list
        }

        public enum SPDIT
        {
            None = (0),
            SPDIT_COMPATDRIVER = (0x00000002), // Build a list of compatible drivers
            SPDIT_CLASSDRIVER = (0x00000001)  // Build a list of class drivers
        }

        public enum DI_FLAGS
        {
             DI_FLAGSEX_INSTALLEDDRIVER = (0x04000000),
             DI_FLAGSEX_ALLOWEXCLUDEDDRVS = (0x00000800)
        }

        [StructLayout(LayoutKind.Sequential)]
        public class SP_DEVINFO_DATA
        {
            /// <summary>
            /// Size of the structure, in bytes. 
            /// </summary>
            public Int32 cbSize = Marshal.SizeOf(typeof(SP_DEVINFO_DATA));

            /// <summary>
            /// GUID of the device interface class. 
            /// </summary>
            public Guid ClassGuid;

            /// <summary>
            /// Handle to this device instance. 
            /// </summary>
            public Int32 DevInst;

            /// <summary>
            /// Reserved; do not use. 
            /// </summary>
            public IntPtr Reserved;
        }

        // 64 bit: Pack=4
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack=4)]
        public class SP_DRVINFO_DATA
        {
            public Int32 cbSize;
            public Int32 DriverType;
            public IntPtr Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String Description;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String MfgName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public String ProviderName;
            public System.Runtime.InteropServices.ComTypes.FILETIME DriverDate;
            public Int64 DriverVersion;
        }

        // 64 bit: Pack=8
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 8)]
        public class SP_DRVINFO_DETAIL_DATA
        {
            public Int32 cbSize;
            public System.Runtime.InteropServices.ComTypes.FILETIME InfDate;
            public Int32 CompatIDsOffset;
            public Int32 CompatIDsLength;
            public IntPtr Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string SectionName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string InfFileName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
            public string DrvDescription;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 1)]
            public string HardwareID;
        }

        // 64 bit: Pack=8
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode, Pack = 8)]
        public class SP_DEVINSTALL_PARAMS
        {
            public Int32 cbSize;
            public Int32 Flags;
            public DI_FLAGS FlagsEx;
            public IntPtr hwndParent;
            public IntPtr InstallMsgHandler;
            public IntPtr InstallMsgHandlerContext;
            public IntPtr FileQueue;
            public UIntPtr ClassInstallReserved;
            public Int32 Reserved;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string DriverPath;
        }

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr SetupDiGetClassDevs(
            IntPtr DeviceInfoSet,
            IntPtr Enumerator
            IntPtr hwndParent,
            int Flags
            );

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiOpenDeviceInfo(
            IntPtr ClassGuid,
            string device,
            IntPtr handleToWindow,
            DIOD flag,
            SP_DEVINFO_DATA deviceInfoData
            );

        [DllImport("Setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public extern static IntPtr SetupDiCreateDeviceInfoList
            (
            IntPtr ClassGuid,
            IntPtr hwndParent
            );
        
        [DllImport("Setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public extern static IntPtr SetupDiGetClassDevsW 
            (
            IntPtr ClassGuid,
            IntPtr hwndParent
            );

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiBuildDriverInfoList(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SPDIT DriverType
            );

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiEnumDriverInfo(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SPDIT DriverType,
            int MemberIndex,
            [In, Out] SP_DRVINFO_DATA DriverInfoData
            );

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiGetDriverInfoDetail(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DRVINFO_DATA DriverInfoData,
            [In, Out] SP_DRVINFO_DETAIL_DATA DriverInfoDetailData,
            int DriverInfoDetailDataSize,
            out int RequiredSize
            );

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool SetupDiSetDeviceInstallParams(
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DEVINSTALL_PARAMS DeviceInstallParams
            );

        [DllImport("Newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool DiInstallDevice(
            IntPtr hwndParent,
            IntPtr DeviceInfoSet,
            SP_DEVINFO_DATA DeviceInfoData,
            SP_DRVINFO_DATA DriverInfoData,
            int Flags,
            out bool rebootRequired            
            );

		[DllImport("Newdev.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool DiInstallDriver
        (
            [In] IntPtr hwndParent,
            [In] string FullInfPath,
            [In] uint Flags,
            [Out] bool NeedReboot
        );

        public static GetDeviceInformationSet()
        {

        }
    }
}
"@
    Add-Type -TypeDefinition $UpdateDeviceDrivers -Language CSharp
}


