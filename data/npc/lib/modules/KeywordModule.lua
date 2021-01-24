if not KeywordModule then
    function KeywordModule()
        _module = {
            npcHandler = nil
        }
        -- Add it to the parseable module list.
        Modules.parseableModules["module_keywords"] = _module

        function _module:init(handler)
            self.npcHandler = handler
            return true
        end

        -- Parses all known parameters.
        function _module:parseParameters()
            local ret = NpcSystem.getParameter("keywords")
            if ret then
                self:parseKeywords(ret)
            end
        end

        function _module:parseKeywords(data)
            local n = 1
            for keys in string.gmatch(data, "[^;]+") do
                local i = 1

                local keywords = {}
                for temp in string.gmatch(keys, "[^,]+") do
                    keywords[#keywords + 1] = temp
                    i = i + 1
                end

                if i ~= 1 then
                    local reply = NpcSystem.getParameter("keyword_reply" .. n)
                    if reply then
                        self:addKeyword(keywords, reply)
                    else
                        print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "Parameter '" .. "keyword_reply" .. n .. "' missing. Skipping...")
                    end
                else
                    print("[Warning : " .. Npc():getName() .. "] NpcSystem:", "No keywords found for keyword set #" .. n .. ". Skipping...")
                end

                n = n + 1
            end
        end

        function _module:addKeyword(keywords, reply)
            self.npcHandler.keywordHandler:addKeyword(keywords, StdModule.say, {npcHandler = self.npcHandler, onlyFocus = true, text = reply, reset = true})
        end

    end
end