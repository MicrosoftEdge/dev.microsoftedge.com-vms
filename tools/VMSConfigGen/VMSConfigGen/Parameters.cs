using System;
using System.Collections.Generic;
using System.Text;
using System.Linq;

namespace VMSConfigGen
{
    internal class Parameters
    {              
        public static Dictionary<string, List<string>> AcceptedParameters = new Dictionary<string, List<string>>
        {            
            { "OS", new List<string> (Enum.GetNames(typeof(OSs)))},
            { "VM", new List<string> (Enum.GetNames(typeof(VMs)))},
            { "Browser", new List<string> (Enum.GetNames(typeof(Browsers)))},
            { "WinVersion", new List<string> (Enum.GetNames(typeof(WinVersions)))}
        };              

        public static (bool success, Dictionary<string, List<string>> output, List<string> errors) TryToConvertToParameters(string[] parameters)
        {
            var wrongParameters = new List<string>();
            var output = new Dictionary<string, List<string>>();
;            foreach (var param in parameters)
            {
                bool paramFound = false;                
                foreach (var key in AcceptedParameters.Keys)
                {
                    var element = AcceptedParameters[key].Find(x => x.ToLower() == param.ToLower());
                    if (!string.IsNullOrEmpty(element))
                    {
                        if (!output.ContainsKey(key))
                        {
                            output.Add(key, new List<string>());
                        }
                        output[key].Add(element);
                        paramFound = true;
                        break;
                    }
                }

                if (!paramFound)
                {                    
                    wrongParameters.Add(param);
                }
            }

            return (!wrongParameters.Any(), output, wrongParameters);
        }

    }
}
