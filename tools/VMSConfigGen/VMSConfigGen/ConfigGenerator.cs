using System;
using System.Collections.Generic;
using System.Text;
using System.Linq;
using Newtonsoft.Json.Linq;

namespace VMSConfigGen
{       
    internal class ConfigGenerator
    {                                                                                
        Dictionary<Levels, List<string>> _selectedOptions;
        
        public ConfigGenerator(Dictionary<string, List<string>> parameters)
        {
            _selectedOptions = CreateDictionaryWithAllTheOptionsSelected(parameters);
        }             

        public JObject CreateConfiguration()
        {
            JObject result = new JObject();
            var node =  CreateChildLevel(0, "VMS");
            result["VMS"] = node;
            return result;
        }

        private JContainer CreateChildLevel(int level, string parentValue)
        {            
            if (level == 3)
            {
                JArray array = new JArray();
                foreach (var option in _selectedOptions[(Levels)level])
                {
                    if (Rules.IsValidCombination(level, option, parentValue))
                    {
                        array.Add(option);
                    }
                }
                return array;
            }
            else
            {
                JObject result = new JObject();
                foreach (var option in _selectedOptions[(Levels)level])
                {
                    if (Rules.IsValidCombination(level, option, parentValue))
                    {
                        var node = CreateChildLevel(level +1, option);
                        if (node.Count != 0)
                        {
                            result[option] = node;
                        }
                    }
                }
                return result;
            }            
        }

        private Dictionary<Levels, List<string>> CreateDictionaryWithAllTheOptionsSelected(Dictionary<string, List<string>> parameters)
        {
            var result = new Dictionary<Levels, List<string>>();
            foreach (var level in Enum.GetValues(typeof(Levels)))
            {
                var name = level.ToString();
                var content = parameters.ContainsKey(name) ? parameters[name] : Parameters.AcceptedParameters[name];

                result.Add((Levels)level, content);
            }            

            return result;
        }
    }
}
