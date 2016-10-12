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

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace PackerMerge
{
    public class PackerTemplate
    {

        public dynamic Variables { get; set; }

        public dynamic Builders { get; set; }

        public dynamic Provisioners { get; set; }

        public dynamic Postprocessors { get; set; }

        public static PackerTemplate ReadFrom(string file)
        {
            var template = new PackerTemplate();
            dynamic jsonData = JObject.Parse(File.ReadAllText(file));
            template.Variables = jsonData.variables;
            template.Builders = jsonData.builders;
            template.Provisioners = jsonData.provisioners;
            template.Postprocessors = jsonData.postprocessors;
            return template;
        }

        public void SaveTo(string file)
        {
            JObject template = new JObject();
            if (Variables != null) template.Add("variables", Variables);
            if (Builders != null) template.Add("builders", Builders);
            if (Provisioners != null) template.Add("provisioners", Provisioners);
            if (Postprocessors != null) template.Add("post-processors", Postprocessors);

            var json = JsonConvert.SerializeObject(template,
                Formatting.Indented,
                new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });

            File.WriteAllText(file, json);
        }
    }
}
