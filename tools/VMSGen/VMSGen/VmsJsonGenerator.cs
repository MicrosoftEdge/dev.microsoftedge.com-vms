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

using Newtonsoft.Json.Linq;

namespace VMSGen
{
    using Model;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;

    public class VmsJsonGenerator
    {
        const string DomainCdn = "https://az792536.vo.msecnd.net";
        const string ReleaseNotesUrl = "https://az792536.vo.msecnd.net/vms/release_notes_license_terms_8_1_15.pdf";
        private readonly string _rootPath;
        private readonly string _buildId;
        private readonly dynamic _vms;

        public VmsJsonGenerator(dynamic config)
        {
            _buildId = config.Build;
            _rootPath = config.OutputPath;
            _vms = config.VMS;

            if (string.IsNullOrEmpty(_buildId)) throw new NullReferenceException("'Build' cannot be null.");
            if (string.IsNullOrEmpty(_rootPath)) throw new NullReferenceException("'OutputPath' cannot be null.");

            var vmsJtoken = _vms as JToken;
            if (vmsJtoken == null || !vmsJtoken.HasValues) throw new NullReferenceException("'VMS' cannot be null.");
        }

        public VMS CreateVms()
        {
            var resultVms = new VMS { Id = _buildId, ReleaseNotes = ReleaseNotesUrl, Active = true, Version = _buildId };
            resultVms.SoftwareList = new List<Software>();
            var osList = new List<OS>();

            foreach (var osName in _vms)
            {
                var softwareList = new List<Software>();

                foreach (var softwareName in osName.Value)
                {
                    GenerateSoftwareList(softwareList, softwareName);
                    if (softwareName.Name == "VirtualBox")
                    {
                        dynamic a = new JObject();
                        a.Vagrant = softwareName.Value;
                        GenerateSoftwareList(softwareList, ((JContainer)a).First);
                    }
                }

                foreach (var softwareItem in softwareList)
                {
                    MergeSoftwareItems(resultVms.SoftwareList, softwareItem);
                    // resultVms.SoftwareList.AddRange(softwareList.ToArray());                    
                }                
            }

            return resultVms;
        }

        private void MergeSoftwareItems(List<Software> softwareList, Software softwareItem)
        {
            var software = softwareList.FirstOrDefault(x => x.SoftwareName == softwareItem.SoftwareName);

            if (software == null)
            {
                softwareList.Add(softwareItem);
            }
            else
            {
                foreach (var browser in softwareItem.VMS)
                {
                    if (software.VMS.SingleOrDefault(vms => AreTheSameBrowserValues(vms, browser)) == null)
                    {
                        software.VMS.Add(browser);
                    }
                }
            }
        }

        private static bool AreTheSameBrowserValues(Browser vms, Browser browser)
        {
            return vms.BrowserName == browser.BrowserName
                && vms.Build == browser.Build
                && vms.OSVersion == browser.OSVersion
                && vms.Version == browser.Version;
        }


        private void GenerateSoftwareList(List<Software> softwareList, dynamic softwareName)
        {
            var software = new Software { SoftwareName = softwareName.Name };
            var browserList = new List<Browser>();

            foreach (var browserVersion in softwareName.Value)
            {
                foreach (var osVersion in browserVersion.Value)
                {
                    var browser = CreateBrowser(software, browserVersion.Name, osVersion.ToString());
                    browserList.Add(browser);
                }
            }
            software.VMS = browserList.ToArray();
            software.OsList = GetOSList(software);
            softwareList.Add(software);
        }

        private string[] GetOSList(Software software)
        {
            switch (software.SoftwareName)
            {
                case "VirtualBox":
                    return new[] { "Windows", "Mac", "Linux" };

                case "Vagrant":
                    return new[] { "Windows", "Mac", "Linux" };

                case "VMware":
                    return new[] { "Windows", "Mac" };

                case "Parallels":
                    return new[] { "Mac" };

                default:
                    return new[] { "Windows" };
            }
        }

        private Browser CreateBrowser(Software software, string browserVersionName, string osVersion)
        {
            var browser = new Browser { Version = browserVersionName.ToLower(), BrowserName = browserVersionName, OSVersion = osVersion, Build = _buildId };
            var relativePath = $"{software.SoftwareName}\\{browser.Version}";
            var absolutePath = Path.Combine(_rootPath, "VMBuild_" + _buildId, relativePath);
            var filters = new[] { $"{browser.BrowserName}.{browser.OSVersion}*.zip", $"{browser.BrowserName}.{browser.OSVersion}*.0??" };
            var fileList = new List<Model.File>();
            var filesMultipart = GetFileList(_buildId, software, browserVersionName, browser, absolutePath, filters[1]);

            fileList.AddRange(GetFileList(_buildId, software, browserVersionName, browser, absolutePath, filters[0]));
            fileList.AddRange(filesMultipart);

            browser.Files = fileList.ToArray();
            return browser;
        }

        private static List<Model.File> GetFileList(string buildId, Software software, string browserVersion, Browser browser, string absolutePath, string fileFilter)
        {
            if (!Directory.Exists(absolutePath)) return new List<Model.File>();

            var files = Directory.GetFiles(absolutePath, fileFilter);

            var fileList = new List<Model.File>();

            foreach (var file in files)
            {
                var fileZip = new Model.File { Name = Path.GetFileName(file) };
                fileZip.Url = $"{DomainCdn}/vms/VMBuild_{buildId}/{software.SoftwareName}/{browserVersion}/{fileZip.Name}";
                fileZip.MD5 = $"{DomainCdn}/vms/md5/VMBuild_{buildId}/{fileZip.Name}.md5.txt";

                fileList.Add(fileZip);
            }

            Console.WriteLine($"Processed {files.Count()} files ({fileFilter.Substring(fileFilter.Length - 3, 3)}) in {absolutePath}");

            return fileList;
        }
    }
}
