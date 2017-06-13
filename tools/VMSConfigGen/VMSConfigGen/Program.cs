using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace VMSConfigGen
{
    public class Program
    {
        static void Main(string[] args)
        {
            var parameters = new Parameters();
            var result = Parameters.TryToConvertToParameters(args);
            if (result.success)
            {
                Console.WriteLine("Parameters validated successfully. Generating the file...");
                var generator = new ConfigGenerator(result.output);
                var configuration = generator.CreateConfiguration();

                string fileName = "VMSConfig.json";
                File.WriteAllText(fileName, configuration.ToString());
                Console.WriteLine(string.Format("File created: {0}\\{1}", Directory.GetCurrentDirectory(), fileName));
            }
            else
            {
                LogError(result.errors);
            }
        }

        private static void LogError(List<string> errors)
        {
            var errorMessage = new StringBuilder();
            errorMessage.AppendFormat("The next paramters are incorrect: {0} \n", string.Join(",", errors));
            errorMessage.AppendLine("Accepted values are:");
            foreach (var key in Parameters.AcceptedParameters.Keys)
            {
                errorMessage.AppendFormat("For {0} : {1} \n", key, string.Join(" ", Parameters.AcceptedParameters[key].ToArray()));
            }
            errorMessage.AppendLine("Format example: C:\\VMSConfigGen\\VMSConfigGen>dotnet run mac msedge");

            Console.Write(errorMessage.ToString());
        }
    }
}