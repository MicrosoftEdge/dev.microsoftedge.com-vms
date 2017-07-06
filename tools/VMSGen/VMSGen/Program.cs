// --------------------------------------------------------------
//
//  dev.microsoftedge.com -VMs
//  Copyright(c) Microsoft Corporation. All rights reserved.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files(the ""Software""),
//  to deal in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions :
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
//  OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// --------------------------------------------------------------

using Microsoft.CSharp.RuntimeBinder;

namespace VMSGen
{
    using Model;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Linq;
    using System;
    using System.IO;
    using System.Linq;

    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                var file = args.Length == 2 ? args[1] : "vmgen.json";

                var config = GetConfig(file);
                var generator = new VmsJsonGenerator(config);
                var vms = generator.CreateVms();
                CreateOutputFile(config.OutputPath.ToString(), vms);

                Merge(config.OutputPath.ToString(), vms);
            }
            catch (Exception e)
            {
                Console.WriteLine($"ERROR: {e.Message}");
            }
        }

        private static void Merge(string path, VMS vms)
        {
            var originPath = Path.Combine(path, "vms.json");
            var generatedPath = Path.Combine(path, $"vms_{vms.Version}.json");
            var ouputPath = Path.Combine(path, $"vms.json");

            if (!System.IO.File.Exists(originPath))
            {
                System.IO.File.Copy(generatedPath, ouputPath);
                return;
            }

            var origin = System.IO.File.ReadAllText(originPath);
            var jsonOrigin = JsonConvert.DeserializeObject<VMS>(origin);
            var generated = System.IO.File.ReadAllText(generatedPath);
            var jsonGenerated = JsonConvert.DeserializeObject<VMS>(generated);

            MergeInto(jsonOrigin, jsonGenerated);

            string json = JsonConvert.SerializeObject(jsonOrigin, Formatting.Indented, new JsonSerializerSettings
            {
                NullValueHandling = NullValueHandling.Ignore
            });
            System.IO.File.WriteAllText(ouputPath, json);
        }

        private static void MergeInto(VMS left, VMS right)
        {
            left.Id = right.Id;
            left.Version = right.Version;

            foreach (var softListRight in right.SoftwareList)
            {
                var softListLeft = left.SoftwareList.FirstOrDefault(x => x.SoftwareName == softListRight.SoftwareName);

                if (softListLeft == null)
                {
                    left.SoftwareList.Add(softListRight);
                }
                else
                {
                    foreach (var item in softListRight.VMS)
                    {
                        var softListLeftVMS = softListLeft.VMS.FirstOrDefault(x => x.Version == item.Version && x.OSVersion == item.OSVersion);

                        if (softListLeftVMS != null)
                        {
                            softListLeft.VMS.Remove(softListLeftVMS);
                        }

                        softListLeft.VMS.Add(item);
                    }
                }
            }
        }

        private static dynamic GetConfig(string file)
        {
            var input = System.IO.File.ReadAllText(file);
            return JsonConvert.DeserializeObject(input);
        }

        private static void CreateOutputFile(string path, VMS vms)
        {
            var fileName = $"vms_{vms.Version}.json";
            var fileFullPath = Path.Combine(path, fileName);

            string json = JsonConvert.SerializeObject(vms,
                Formatting.Indented,
                new JsonSerializerSettings
                {
                    NullValueHandling = NullValueHandling.Ignore
                });
            System.IO.File.WriteAllText(fileFullPath, json);

            Console.WriteLine($"{fileFullPath} created");
        }
    }
}
