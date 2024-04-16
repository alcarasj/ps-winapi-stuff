param(
    [Parameter(Mandatory)]
    [string]$TargetPnpDeviceFriendlyName
)

Function Update-DeviceDrivers([string]$targetPnpDeviceInstanceId)
{
     $UpdateDeviceDriversSource = @"
using System;
using System.Runtime.InteropServices;
namespace DeviceDrivers
{
    public static class UpdateDrivers
    {
        public enum DIOD
        {
            None = (0),
            CANCEL_REMOVE = (0x00000004),
            INHERIT_CLASSDRVS = (0x00000002)
        }

        public enum DICD
        {
            None = (0),
            GENERATE_ID = (0x00000001),
            INHERIT_CLASSDRVS = (0x00000002)
        }

        public enum SPDIT
        {
            None = (0),
            SPDIT_COMPATDRIVER = (0x00000002),
            SPDIT_CLASSDRIVER = (0x00000001)
        }

        [StructLayout(LayoutKind.Sequential)]
        public class SP_DEVINFO_DATA
        {
            public Int32 cbSize = Marshal.SizeOf(typeof(SP_DEVINFO_DATA));
            public Guid ClassGuid;
            public Int32 DevInst;
            public IntPtr Reserved;
        }

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

        [DllImport("Setupapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr SetupDiGetClassDevs(
            IntPtr DeviceInfoSet,
            IntPtr Enumerator,
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

        public static void GetDeviceInformationSet(string targetPnpDeviceInstanceId)
        {
            int error = 0;
            IntPtr hDevSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);
            SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();
            bool bRet = SetupDiOpenDeviceInfo(hDevSet, targetPnpDeviceInstanceId, IntPtr.Zero, 0, deviceInfoData);
            if (bRet == false)
            {
                Console.WriteLine("Error: " + Marshal.GetLastWin32Error());
                return;
            }

            bRet = SetupDiBuildDriverInfoList(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER);
            if (bRet == false)
            {
                Console.WriteLine("Error: " + Marshal.GetLastWin32Error());
                return;
            }
            int driverItr = 0;
            bool bResult = true;
            while (bResult)
            {
                SP_DRVINFO_DATA driverInfoData = new SP_DRVINFO_DATA();
                driverInfoData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DATA));
                bRet = SetupDiEnumDriverInfo(hDevSet, deviceInfoData, SPDIT.SPDIT_COMPATDRIVER, driverItr, driverInfoData);
                if (bRet == false)
                {
                    Console.WriteLine("Error: " + Marshal.GetLastWin32Error());
                    return;
                }

                int requiredSize = 0;
                SP_DRVINFO_DETAIL_DATA driverInfoDetailData = new SP_DRVINFO_DETAIL_DATA();
                driverInfoDetailData.cbSize = Marshal.SizeOf(typeof(SP_DRVINFO_DETAIL_DATA));
                int dataSize = Marshal.SizeOf(driverInfoDetailData);

                bRet = SetupDiGetDriverInfoDetail(hDevSet, deviceInfoData, driverInfoData, driverInfoDetailData, dataSize, out requiredSize);
                if (bRet == false)
                {
                    error = Marshal.GetLastWin32Error();
                    //122 - ERROR_INSUFFICIENT_BUFFER, expected error
                    if (error != 122)
                    {
                        Console.WriteLine("Error: " + Marshal.GetLastWin32Error());
                    }
                }

                Console.WriteLine(deviceInfoData.ClassGuid);
                Console.WriteLine(driverInfoData.MfgName);
                Console.WriteLine(driverInfoData.Description);
                Console.WriteLine(driverInfoData.ProviderName);
                Console.WriteLine(driverInfoDetailData.DrvDescription);
                Console.WriteLine(driverInfoDetailData.HardwareID);
                driverItr++;
            }
        }
    }
}
"@
    Add-Type -TypeDefinition $UpdateDeviceDriversSource -Language CSharp
    [DeviceDrivers.UpdateDrivers]::GetDeviceInformationSet($targetPnpDeviceInstanceId)
}

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$pnpDevice = Get-PnpDevice -FriendlyName $TargetPnpDeviceFriendlyName
Update-DeviceDrivers($pnpDevice.InstanceId)