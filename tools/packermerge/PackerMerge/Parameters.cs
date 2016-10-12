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
using System.Linq;
using System.Threading.Tasks;

namespace PackerMerge
{
    public class Parameters
    {
        private const string AddInputFlag = "-i:";
        private const string SetOutputFlag = "-o:";

        private readonly List<string> _inputFiles;
        public string OutputFile { get; private set; }

        public IEnumerable<string> InputFiles
        {
            get
            {
                return _inputFiles;
            }
        }

        public Parameters()
        {
            _inputFiles = new List<string>();
            OutputFile = "template.json";
        }

        public void Process( IEnumerable<string> args)
        {
            foreach (var arg in args)
            {
                if (!string.IsNullOrEmpty(arg))
                {
                    if (arg.StartsWith(AddInputFlag))
                    {
                        ProcessAddInputFlag(arg.Substring(AddInputFlag.Length));
                    }
                    else if (arg.StartsWith(SetOutputFlag))
                    {
                        ProcessSetOutputFlag(arg.Substring(SetOutputFlag.Length));
                    }
                }
            }
        }

        private void ProcessAddInputFlag(string arg)
        {
            var input = arg.Split(',');
            foreach (var entry in input)
            {
                _inputFiles.Add(entry);
            }
        }

        private void ProcessSetOutputFlag(string arg)
        {
            OutputFile = arg;
        }
    }
}
