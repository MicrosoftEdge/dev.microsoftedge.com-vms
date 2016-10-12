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
using Newtonsoft.Json.Linq;

namespace PackerMerge
{
    public static class CombinatorStrategyAdd
    {
        public static PackerTemplate Combine(PackerTemplate current, PackerTemplate extraData)
        {
            if (extraData.Variables != null)
            {
                MergeVariables(current, extraData);
            }

            if (extraData.Builders != null)
            {
                MergeBuilders(current, extraData);
            }

            if (extraData.Provisioners != null)
            {
                MergeProvisioners(current, extraData);
            }

            if (extraData.Postprocessors != null)
            {
                MergePostprocessors(current, extraData);
            }


            return current;
        }

        private static void MergeVariables(PackerTemplate current, PackerTemplate extraData)
        {
            if (current.Variables == null)
            {
                current.Variables = extraData.Variables.DeepClone();
            }
            else
            {
                foreach (var variable in extraData.Variables)
                {
                    current.Variables.Add(variable);
                }
            }
        }

        private static void MergeBuilders(PackerTemplate current, PackerTemplate extraData)
        {
            if (current.Builders == null)
            {
                current.Builders = extraData.Builders.DeepClone();
            }
            else
            {
                foreach (var builderRight in extraData.Builders)
                {
                    var type = builderRight.type;
                    foreach (var builderLeft in current.Builders)
                    {
                        var typeLeft = builderLeft.type;

                        if (type == typeLeft)
                        {
                            MergeInto(builderLeft, builderRight);
                        }
                    }
                }
            }
        }

        private static void MergeProvisioners(PackerTemplate current, PackerTemplate extraData)
        {
            if (current.Provisioners == null)
            {
                current.Provisioners = extraData.Provisioners.DeepClone();
            }
            else
            {
                foreach (var provisioner in extraData.Provisioners)
                {
                    current.Provisioners.Add(provisioner);
                }
            }
        }

        private static void MergePostprocessors(PackerTemplate current, PackerTemplate extraData)
        {
            if (current.Postprocessors == null)
            {
                current.Postprocessors = extraData.Postprocessors.DeepClone();
            }
            else
            {
                foreach (var postProcessor in extraData.Postprocessors)
                {
                    current.Provisioners.Add(postProcessor);
                }
            }
        }

        public static void MergeInto(this JContainer left, JToken right)
        {
            foreach (var rightChild in right.Children<JProperty>())
            {
                var rightChildProperty = rightChild;
                var leftProperty = left.SelectToken(rightChildProperty.Name);

                if (leftProperty == null)
                {
                    left.Add(rightChild);
                }
                else
                {
                    var leftObject = leftProperty as JObject;
                    if (leftObject == null)
                    {
                        var leftParent = (JProperty)leftProperty.Parent;

                        if (leftParent.Value.GetType() == typeof(JArray))
                        {
                            leftParent.Value = JToken.FromObject(leftParent.Value.Concat(rightChildProperty.Value));
                        }
                        else
                        {
                            leftParent.Value = rightChildProperty.Value;
                        }
                    }

                    else
                        MergeInto(leftObject, rightChildProperty.Value);
                }
            }
        }
    }
}
