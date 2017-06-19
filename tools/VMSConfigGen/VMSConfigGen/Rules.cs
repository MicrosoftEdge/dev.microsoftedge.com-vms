using System;
using System.Collections.Generic;
using System.Text;

namespace VMSConfigGen
{
    enum Levels
    {
        OS,
        VM,
        Browser,
        WinVersion
}
    enum WinVersions
    {
        Win7,
        Win81,
        Win10
    }

    enum Browsers
    {
        IE8,
        IE9,
        IE10,
        IE11,
        MSEdge
    }

    enum VMs
    {
        HyperV,
        VirtualBox,
        VMware,
        Parallels,
        VPC
    }

    enum OSs
    {
        Windows,
        Mac
    }

    internal class Rules
    {
        public static readonly bool[,] WinVersionRules =
            {   //Win7, Win81, Win10
                {true, false, false },  //IE8,
                {true, false, false },  //IE9,
                {true, false, false},  //IE10,
                {true, true, false },  //IE11,
                {false, false, true}  //MSEdge
        };

        public static readonly bool[,] VMRules =
            {
               //HyperV, VirtualBox, VMware, Parallels, VPC
                {true, true, true,false, true }, //Windows
                {false, true, true,true, false}  // Mac
        };

        public static bool IsValidCombination(int level, string value, string parentValue)
        {
            bool isValid = true;
            switch (level)
            {
                case 1:
                    VMs vm = (VMs)Enum.Parse(typeof(VMs), value);
                    OSs os = (OSs)Enum.Parse(typeof(OSs), parentValue);
                    isValid = VMRules[(int)os, (int)vm];
                    break;

                case 3:
                    WinVersions version = (WinVersions)Enum.Parse(typeof(WinVersions), value);
                    Browsers browser = (Browsers)Enum.Parse(typeof(Browsers), parentValue);
                    isValid = WinVersionRules[(int)browser, (int)version];
                    break;

                default:
                    break;
            }
            return isValid;
        }
    }
}
